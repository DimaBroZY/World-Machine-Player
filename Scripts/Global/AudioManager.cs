using Godot;
using ManagedBass;
using System;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

// Автолоад (см. project.godot -> [autoload] AudioManager).
// Полностью заменяет addons/icy-radio-streamer: BASS сам качает, декодирует
// (mp3/ogg/aac/flac и т.д.) и играет интернет-поток напрямую в звуковое
// устройство, в обход Godot-шного AudioStreamPlayer/AudioStreamGenerator.
//
// Наружу отдаёт тот же набор состояний/сигналов, которым раньше заведовал
// Scripts/radio_streamer.gd поверх IcyHttpStream, так что main.gd можно не трогать.
public partial class AudioManager : Node
{
	[Signal] public delegate void TrackChangedEventHandler(string title);
	[Signal] public delegate void BufferingChangedEventHandler(bool isBuffering);
	[Signal] public delegate void StationUnavailableEventHandler(bool isUnavailable);
	[Signal] public delegate void StationUnsupportedEventHandler(bool isUnsupported);

	private static readonly Regex StreamTitleRegex =
		new(@"StreamTitle='(.*?)';", RegexOptions.Compiled);

	private int _streamChannel = 0;
	private bool _isInitialized = false;

	private bool _isActive = false;      // start()/stop() — радио вообще должно играть
	private bool _isSwitching = false;   // идёт подключение/переподключение к станции
	private bool _isBuffering = false;   // канал застопорился, ждём буфер
	private bool _userPaused = false;    // пользователь поставил на паузу вручную

	private string _currentUrl = "";
	private string _pendingUrl = null;   // set_station() вызвали, пока уже шло подключение
	private int _connectGeneration = 0;  // чтобы не применить результат устаревшего подключения
	private float _volume = 1.0f;

	private SyncProcedure _metaSync;
	private SyncProcedure _stallSync;
	private SyncProcedure _endSync;

	// Срабатывает один раз, до первого обращения к Bass.* - учит .NET находить bass.dll
	static AudioManager()
	{
		NativeLibrary.SetDllImportResolver(typeof(Bass).Assembly, ResolveNative);
	}

	private static IntPtr ResolveNative(string libraryName, Assembly assembly, DllImportSearchPath? searchPath)
	{
		if (libraryName != "bass")
			return IntPtr.Zero;
		string fileName = OperatingSystem.IsWindows() ? "bass.dll" : "libbass.so";
		string[] candidates =
		{
			Path.Combine(AppContext.BaseDirectory, fileName),
			Path.Combine(Path.GetDirectoryName(assembly.Location) ?? "", fileName),
			Path.Combine(Directory.GetCurrentDirectory(), fileName),
			Path.Combine(OS.GetExecutablePath().GetBaseDir(), fileName),
		};
		foreach (var path in candidates)
		{
			if (File.Exists(path) && NativeLibrary.TryLoad(path, out var handle))
			{
				GD.Print($"BASS: нативная либа загружена из {path}");
				return handle;
			}
		}
		GD.PrintErr("BASS: bass.dll/.so не найден ни в одном из путей:\n  " + string.Join("\n  ", candidates));
		return IntPtr.Zero;
	}

	public override void _Ready()
	{
		// таймаут подключения и стартовая преднабуферизация для интернет-потоков
		Bass.Configure(Configuration.NetTimeOut, 10000);
		Bass.Configure(Configuration.NetPreBuffer, 25);

		_isInitialized = Bass.Init(-1, 44100, DeviceInitFlags.Default);
		if (!_isInitialized)
			GD.PrintErr($"Ошибка инициализации BASS: {Bass.LastError}");
		else
			GD.Print("BASS успешно инициализирован!");
	}

	// ================= публичный API для radio_streamer.gd =================

	public bool IsActive() => _isActive;

	public bool IsSwitching() => _isSwitching;

	public string GetCurrentUrl() => _currentUrl;

	public bool IsPaused()
	{
		if (_streamChannel == 0) return false;
		return Bass.ChannelIsActive(_streamChannel) == PlaybackState.Paused;
	}

	// Просто запоминает/меняет станцию. Если радио сейчас активно - переподключается.
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
		FreeChannel();
		EmitSignal(SignalName.BufferingChanged, false);
		EmitSignal(SignalName.StationUnavailable, false);
	}

	public void SetVolume(float linear01)
	{
		_volume = Mathf.Clamp(linear01, 0.0f, 1.0f);
		if (_streamChannel != 0)
			Bass.ChannelSetAttribute(_streamChannel, ChannelAttribute.Volume, _volume);
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

		FreeChannel();
		EmitSignal(SignalName.BufferingChanged, true);
		EmitSignal(SignalName.StationUnavailable, false);
		EmitSignal(SignalName.StationUnsupported, false);

		// BASS.CreateStream(url) — блокирующий вызов (ждёт коннекта или таймаута),
		// поэтому уводим его в фоновый поток и возвращаемся в главный через CallDeferred.
		Task.Run(() =>
		{
			string request = url + "\r\nUser-Agent: WorldMachinePlayer";
			int channel = Bass.CreateStream(request, 0, BassFlags.Default, null);
			CallDeferred(nameof(OnConnectResult), channel, generation, url);
		});
	}

	private void OnConnectResult(int channel, int generation, string url)
	{
		// пока мы ждали — станцию сменили/остановили радио: этот канал больше не нужен
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
		AttachSyncs(channel, generation);
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

	private void AttachSyncs(int channel, int generation)
	{
		// ICY/Shoutcast-метаданные ("StreamTitle='...';") — то же, что раньше парсил GDScript
		_metaSync = (h, ch, data, user) =>
		{
			IntPtr ptr = Bass.ChannelGetTags(ch, TagType.META);
			string meta = DecodeMetadataString(ptr);
			if (!string.IsNullOrEmpty(meta))
				CallDeferred(nameof(OnMetadataReceived), meta);
		};
		Bass.ChannelSetSync(channel, SyncFlags.MetadataReceived, 0, _metaSync);

		// data == 0 -> застряли (буферизуем), data != 0 -> отпустило
		_stallSync = (h, ch, data, user) =>
		{
			CallDeferred(nameof(OnStalledChanged), data == 0);
		};
		Bass.ChannelSetSync(channel, SyncFlags.Stalled, 0, _stallSync);

		// поток внезапно оборвался — пробуем переподключиться сами
		_endSync = (h, ch, data, user) =>
		{
			CallDeferred(nameof(OnConnectionEnded), generation);
		};
		Bass.ChannelSetSync(channel, SyncFlags.End, 0, _endSync);
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

	private void FreeChannel()
	{
		if (_streamChannel != 0)
		{
			Bass.ChannelStop(_streamChannel);
			Bass.StreamFree(_streamChannel);
			_streamChannel = 0;
		}
		_isBuffering = false;
	}

	// Корректное освобождение ресурсов при выходе из игры
	public override void _ExitTree()
	{
		_connectGeneration++; // на случай если фоновый Task.Run ещё не вернулся
		FreeChannel();
		if (_isInitialized)
			Bass.Free();
		base._ExitTree();
	}
}
