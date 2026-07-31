using Godot;
using ManagedBass;
using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

public partial class AudioManager : Node
{
	[Signal] public delegate void TrackChangedEventHandler(string title);
	[Signal] public delegate void BufferingChangedEventHandler(bool isBuffering);
	[Signal] public delegate void StationUnavailableEventHandler(bool isUnavailable);
	[Signal] public delegate void StationUnsupportedEventHandler(bool isUnsupported);
	[Signal] public delegate void LocalTrackFinishedEventHandler();

	private static readonly Regex StreamTitleRegex =
		new(@"StreamTitle='(.*?)';", RegexOptions.Compiled);

	private const float DefaultFrequency = 44100f;

	private int _streamChannel;
	private int _localChannel;
	private bool _isInitialized;

	private bool _isActive;
	private bool _isSwitching;
	private bool _isBuffering;
	private bool _userPaused;

	private string _currentUrl = "";
	private string _pendingUrl;
	private int _connectGeneration;
	private float _volume = 1.0f;

	private string _localPath = "";
	private float _localPitch = 1.0f;
	private float _localBaseFrequency = DefaultFrequency;
	private bool _localUserPaused;

	private SyncProcedure _metaSync;
	private SyncProcedure _stallSync;
	private SyncProcedure _endSync;
	private SyncProcedure _localEndSync;

	static AudioManager()
	{
		NativeLibrary.SetDllImportResolver(typeof(Bass).Assembly, ResolveNative);
	}

	private static IntPtr ResolveNative(string libraryName, Assembly assembly, DllImportSearchPath? searchPath)
	{
		if (libraryName != "bass")
			return IntPtr.Zero;

		string fileName = OperatingSystem.IsWindows() ? "bass.dll" : "libbass.so";
		foreach (string path in BuildNativeCandidates(fileName, assembly))
		{
			if (File.Exists(path) && NativeLibrary.TryLoad(path, out IntPtr handle))
			{
				GD.Print($"BASS: нативная либа загружена из {path}");
				return handle;
			}
		}

		GD.PrintErr("BASS: bass.dll/.so не найден ни в одном из путей:\n  " +
			string.Join("\n  ", BuildNativeCandidates(fileName, assembly)));
		return IntPtr.Zero;
	}

	private static IEnumerable<string> BuildNativeCandidates(string fileName, Assembly assembly)
	{
		yield return Path.Combine(AppContext.BaseDirectory, fileName);
		yield return Path.Combine(Path.GetDirectoryName(assembly.Location) ?? "", fileName);
		yield return Path.Combine(Directory.GetCurrentDirectory(), fileName);
		yield return Path.Combine(OS.GetExecutablePath().GetBaseDir(), fileName);
	}

	public override void _Ready()
	{
		Bass.Configure(Configuration.NetTimeOut, 10000);
		Bass.Configure(Configuration.NetPreBuffer, 25);

		_isInitialized = Bass.Init(-1, (int)DefaultFrequency, DeviceInitFlags.Default);
		if (!_isInitialized)
		{
			GD.PrintErr($"Ошибка инициализации BASS: {Bass.LastError}");
			return;
		}

		GD.Print("BASS успешно инициализирован!");
		LoadBassPlugins();
	}

	private void LoadBassPlugins()
	{
		LoadBassPlugin("bassflac");
		LoadBassPlugin("bassopus");
	}

	private void LoadBassPlugin(string baseName)
	{
		string fileName = OperatingSystem.IsWindows() ? $"{baseName}.dll" : $"lib{baseName}.so";
		foreach (string path in BuildNativeCandidates(fileName, typeof(Bass).Assembly))
		{
			if (!File.Exists(path))
				continue;

			int pluginHandle = Bass.PluginLoad(path);
			if (pluginHandle != 0)
			{
				GD.Print($"BASS plugin loaded: {path}");
				return;
			}

			GD.PrintErr($"BASS plugin failed ({baseName}): {path} ({Bass.LastError})");
			return;
		}

		GD.PrintErr($"BASS plugin not found: {fileName}");
	}

	// ================= radio API =================

	public bool IsActive() => _isActive;

	public bool IsSwitching() => _isSwitching;

	public string GetCurrentUrl() => _currentUrl;

	public bool IsPaused()
	{
		if (_streamChannel == 0) return false;
		return Bass.ChannelIsActive(_streamChannel) == PlaybackState.Paused;
	}

	public void SetStation(string url)
	{
		if (url == _currentUrl && !_isSwitching && _streamChannel != 0)
			return;

		if (_isSwitching)
		{
			_pendingUrl = url;
			return;
		}

		_currentUrl = url;
		if (_isActive)
			Connect();
	}

	public void StartRadio()
	{
		if (_isActive) return;
		_isActive = true;
		Connect();
	}

	public void ResumeRadio()
	{
		_userPaused = false;
		if (_streamChannel != 0 && !_isBuffering)
			Bass.ChannelPlay(_streamChannel, false);
	}

	public void PauseRadio()
	{
		_userPaused = true;
		if (_streamChannel != 0)
			Bass.ChannelPause(_streamChannel);
	}

	public void StopRadio()
	{
		if (!_isActive) return;
		_isActive = false;
		_isSwitching = false;
		_pendingUrl = null;
		_connectGeneration++;
		FreeStreamChannel();
		EmitSignal(SignalName.BufferingChanged, false);
		EmitSignal(SignalName.StationUnavailable, false);
	}

	// ================= local API =================

	public bool HasLocalTrack() => _localChannel != 0;

	public string GetLocalPath() => _localPath;

	public bool LoadLocalTrack(string path)
	{
		FreeLocalChannel();
		_localPath = "";

		string resolved = ResolveFilePath(path);
		if (string.IsNullOrEmpty(resolved) || !File.Exists(resolved))
		{
			GD.PrintErr($"Local: файл не найден: {path}");
			return false;
		}

		int channel = Bass.CreateStream(resolved, 0, 0, BassFlags.Default);
		if (channel == 0)
		{
			GD.PrintErr($"Local: не удалось открыть {resolved}: {Bass.LastError}");
			return false;
		}

		_localChannel = channel;
		_localPath = resolved;
		_localUserPaused = false;
		var info = Bass.ChannelGetInfo(channel);
		_localBaseFrequency = info.Frequency > 0 ? info.Frequency : DefaultFrequency;
		AttachLocalEndSync(channel);
		ApplyLocalAttributes();
		return true;
	}

	public void PlayLocal()
	{
		if (_localChannel == 0) return;
		_localUserPaused = false;
		Bass.ChannelPlay(_localChannel, false);
	}

	public void PauseLocal()
	{
		_localUserPaused = true;
		if (_localChannel != 0)
			Bass.ChannelPause(_localChannel);
	}

	public void StopLocal()
	{
		_localUserPaused = false;
		FreeLocalChannel();
		_localPath = "";
	}

	public bool IsLocalPlaying()
	{
		if (_localChannel == 0) return false;
		return Bass.ChannelIsActive(_localChannel) == PlaybackState.Playing;
	}

	public bool IsLocalPaused()
	{
		if (_localChannel == 0) return false;
		return Bass.ChannelIsActive(_localChannel) == PlaybackState.Paused;
	}

	public double GetLocalPosition()
	{
		if (_localChannel == 0) return 0.0;
		long bytes = Bass.ChannelGetPosition(_localChannel, PositionFlags.Bytes);
		return Bass.ChannelBytes2Seconds(_localChannel, bytes);
	}

	public double GetLocalLength()
	{
		if (_localChannel == 0) return 0.0;
		long bytes = Bass.ChannelGetLength(_localChannel, PositionFlags.Bytes);
		return Bass.ChannelBytes2Seconds(_localChannel, bytes);
	}

	public void SeekLocal(double seconds)
	{
		if (_localChannel == 0) return;
		long bytes = Bass.ChannelSeconds2Bytes(_localChannel, Math.Max(0.0, seconds));
		Bass.ChannelSetPosition(_localChannel, bytes, PositionFlags.Bytes);
	}

	public void SetLocalPitch(float scale)
	{
		_localPitch = Mathf.Clamp(scale, 0.05f, 4.0f);
		ApplyLocalPitch();
	}

	public float GetLocalPitch() => _localPitch;

	// ================= shared =================

	public void SetVolume(float linear01)
	{
		_volume = Mathf.Clamp(linear01, 0.0f, 1.0f);
		if (_streamChannel != 0)
			Bass.ChannelSetAttribute(_streamChannel, ChannelAttribute.Volume, _volume);
		if (_localChannel != 0)
			Bass.ChannelSetAttribute(_localChannel, ChannelAttribute.Volume, _volume);
	}

	private void Connect()
	{
		if (string.IsNullOrEmpty(_currentUrl))
		{
			_isActive = false;
			return;
		}

		_isSwitching = true;
		_connectGeneration++;
		int generation = _connectGeneration;
		string url = _currentUrl;

		FreeStreamChannel();
		EmitSignal(SignalName.BufferingChanged, true);
		EmitSignal(SignalName.StationUnavailable, false);
		EmitSignal(SignalName.StationUnsupported, false);

		Task.Run(() =>
		{
			string request = url + "\r\nUser-Agent: WorldMachinePlayer";
			int channel = Bass.CreateStream(request, 0, BassFlags.Default, null);
			CallDeferred(nameof(OnConnectResult), channel, generation, url);
		});
	}

	private void OnConnectResult(int channel, int generation, string url)
	{
		if (generation != _connectGeneration || url != _currentUrl)
		{
			if (channel != 0)
				Bass.StreamFree(channel);
			return;
		}

		if (channel == 0)
		{
			var error = Bass.LastError;
			GD.PrintErr($"Радио: не удалось подключиться к {url}: {error}");
			EmitSignal(SignalName.BufferingChanged, false);
			if (error == Errors.FileFormat)
				EmitSignal(SignalName.StationUnsupported, true);
			else
				EmitSignal(SignalName.StationUnavailable, true);
			FinishSwitching();
			if (_isActive)
				ScheduleReconnect(generation);
			return;
		}

		_streamChannel = channel;
		AttachStreamSyncs(channel, generation);
		Bass.ChannelSetAttribute(channel, ChannelAttribute.Volume, _volume);

		if (!_userPaused)
			Bass.ChannelPlay(channel, false);

		EmitSignal(SignalName.BufferingChanged, false);
		EmitSignal(SignalName.StationUnavailable, false);
		GD.Print($"Радио подключено: {url}");
		FinishSwitching();
	}

	private void FinishSwitching()
	{
		_isSwitching = false;
		if (_pendingUrl != null)
		{
			string next = _pendingUrl;
			_pendingUrl = null;
			SetStation(next);
		}
	}

	private void AttachStreamSyncs(int channel, int generation)
	{
		_metaSync = (h, ch, data, user) =>
		{
			IntPtr ptr = Bass.ChannelGetTags(ch, TagType.META);
			string meta = DecodeMetadataString(ptr);
			if (!string.IsNullOrEmpty(meta))
				CallDeferred(nameof(OnMetadataReceived), meta);
		};
		Bass.ChannelSetSync(channel, SyncFlags.MetadataReceived, 0, _metaSync);

		_stallSync = (h, ch, data, user) =>
		{
			CallDeferred(nameof(OnStalledChanged), data == 0);
		};
		Bass.ChannelSetSync(channel, SyncFlags.Stalled, 0, _stallSync);

		_endSync = (h, ch, data, user) =>
		{
			CallDeferred(nameof(OnConnectionEnded), generation);
		};
		Bass.ChannelSetSync(channel, SyncFlags.End, 0, _endSync);
	}

	private void AttachLocalEndSync(int channel)
	{
		_localEndSync = (h, ch, data, user) =>
		{
			CallDeferred(nameof(OnLocalTrackEnded));
		};
		Bass.ChannelSetSync(channel, SyncFlags.End, 0, _localEndSync);
	}

	private void OnLocalTrackEnded()
	{
		if (_localChannel == 0)
			return;
		EmitSignal(SignalName.LocalTrackFinished);
	}

	private void OnMetadataReceived(string raw)
	{
		string title = raw;
		var match = StreamTitleRegex.Match(raw);
		if (match.Success)
			title = match.Groups[1].Value;
		EmitSignal(SignalName.TrackChanged, title);
	}

	private async void ScheduleReconnect(int generation)
	{
		if (!_isActive || generation != _connectGeneration)
			return;

		const double retryDelaySeconds = 3.0;
		GD.Print($"Радио: повторное подключение через {retryDelaySeconds}с ({_currentUrl})");

		var timer = GetTree().CreateTimer(retryDelaySeconds);
		await ToSignal(timer, SceneTreeTimer.SignalName.Timeout);

		if (!_isActive || generation != _connectGeneration || _isSwitching)
			return;

		Connect();
	}

	private static string DecodeMetadataString(IntPtr ptr)
	{
		if (ptr == IntPtr.Zero)
			return string.Empty;

		int length = 0;
		while (Marshal.ReadByte(ptr, length) != 0)
			length++;
		if (length == 0)
			return string.Empty;

		byte[] data = new byte[length];
		Marshal.Copy(ptr, data, 0, length);

		if (IsValidUtf8(data))
			return Encoding.UTF8.GetString(data);

		try
		{
			return Encoding.GetEncoding(932).GetString(data);
		}
		catch (Exception)
		{
			return Encoding.Latin1.GetString(data);
		}
	}

	private static bool IsValidUtf8(byte[] data)
	{
		try
		{
			var decoder = Encoding.UTF8.GetDecoder();
			decoder.Fallback = DecoderFallback.ExceptionFallback;
			int charCount = decoder.GetCharCount(data, 0, data.Length);
			var chars = new char[charCount];
			decoder.GetChars(data, 0, data.Length, chars, 0);
			return true;
		}
		catch (DecoderFallbackException)
		{
			return false;
		}
	}

	private void OnStalledChanged(bool isStalled)
	{
		_isBuffering = isStalled;
		EmitSignal(SignalName.BufferingChanged, isStalled);
	}

	private async void OnConnectionEnded(int generation)
	{
		if (generation != _connectGeneration || !_isActive || _isSwitching)
			return;

		GD.PrintErr($"Радио: соединение разорвано, переподключаюсь через 1.5с ({_currentUrl})");
		EmitSignal(SignalName.BufferingChanged, true);

		var timer = GetTree().CreateTimer(1.5);
		await ToSignal(timer, SceneTreeTimer.SignalName.Timeout);

		if (generation == _connectGeneration && _isActive && !_isSwitching)
			Connect();
	}

	private void ApplyLocalAttributes()
	{
		ApplyLocalPitch();
		if (_localChannel != 0)
			Bass.ChannelSetAttribute(_localChannel, ChannelAttribute.Volume, _volume);
	}

	private void ApplyLocalPitch()
	{
		if (_localChannel == 0) return;
		Bass.ChannelSetAttribute(_localChannel, ChannelAttribute.Frequency, _localBaseFrequency * _localPitch);
	}

	private static string ResolveFilePath(string path)
	{
		if (string.IsNullOrWhiteSpace(path))
			return "";

		if (path.StartsWith("res://", StringComparison.Ordinal) ||
			path.StartsWith("user://", StringComparison.Ordinal))
			return ProjectSettings.GlobalizePath(path);

		return path;
	}

	private void FreeStreamChannel()
	{
		if (_streamChannel == 0) return;
		Bass.ChannelStop(_streamChannel);
		Bass.StreamFree(_streamChannel);
		_streamChannel = 0;
		_isBuffering = false;
	}

	private void FreeLocalChannel()
	{
		if (_localChannel == 0) return;
		Bass.ChannelStop(_localChannel);
		Bass.StreamFree(_localChannel);
		_localChannel = 0;
	}

	public override void _ExitTree()
	{
		_connectGeneration++;
		FreeStreamChannel();
		FreeLocalChannel();
		if (_isInitialized)
			Bass.Free();
		base._ExitTree();
	}
}
