using Godot;
using ManagedBass;
using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Net;
using System.Net.Sockets;

public partial class AudioManager : Node
{
	[Signal] public delegate void TrackChangedEventHandler(string title);
	[Signal] public delegate void BufferingChangedEventHandler(bool isBuffering);
	[Signal] public delegate void StationUnavailableEventHandler(bool isUnavailable);
	[Signal] public delegate void StationUnsupportedEventHandler(bool isUnsupported);
	[Signal] public delegate void LocalTrackFinishedEventHandler();
	[Signal] public delegate void StationTestResultEventHandler(string url, bool isValid, bool isUnsupported);

	private static readonly Regex StreamTitleRegex =
		new(@"StreamTitle='(.*?)';", RegexOptions.Compiled);

	private const float DefaultFrequency = 44100f;
	private const int LinuxBassConfigLibSsl = 64;

	private int _streamChannel;
	private int _localChannel;
	private readonly Dictionary<string, int> _sfxSamples = new();
	private bool _isInitialized;

	private bool _isActive;
	private bool _isSwitching;
	private bool _isBuffering;
	private bool _userPaused;

	private string _currentUrl = "";
	private string _pendingUrl;
	private int _connectGeneration;
	private float _volume = 1.0f;
	private float _sfxVolume = 0.3f;

	private string _localPath = "";
	private float _localPitch = 1.0f;
	private float _localBaseFrequency = DefaultFrequency;
	private bool _localUserPaused;
	private int _fadeOutChannel;
	private int _fadeOutGeneration;

	private SyncProcedure _metaSync;
	private SyncProcedure _stallSync;
	private SyncProcedure _oggChangeSync;
	private SyncProcedure _endSync;
	private SyncProcedure _localEndSync;

		// BASS_SetConfigPtr is not exposed by ManagedBass 4.0.2 for BASS_CONFIG_LIBSSL,
	// so we call the native function directly. 64 is the documented value of
	// BASS_CONFIG_LIBSSL in the BASS API.
	[DllImport("bass", EntryPoint = "BASS_SetConfigPtr", CallingConvention = CallingConvention.Cdecl)]
	private static extern bool BassSetConfigPtr(int option, IntPtr value);

	public override void _Ready()
	{
		ConfigureBass();

		_isInitialized = Bass.Init(
			-1,
			(int)DefaultFrequency,
			DeviceInitFlags.Default
		);

		if (!_isInitialized)
		{
			GD.PrintErr($"[BASS] Ошибка инициализации: {Bass.LastError}");
			return;
		}

		GD.Print($"[BASS] Инициализирован. Version={Bass.Version}");
		GD.Print($"[BASS] OS={OS.GetName()}");
		GD.Print($"[BASS] NetTimeout={Bass.GetConfig(Configuration.NetTimeOut)}ms");
		GD.Print($"[BASS] NetReadTimeout={Bass.GetConfig(Configuration.NetReadTimeOut)}ms");
		GD.Print($"[BASS] NetPreBuffer={Bass.GetConfig(Configuration.NetPreBuffer)}%");
		GD.Print($"[BASS] NetAgent={Bass.NetAgent}");
		GD.Print($"[BASS] NetProxy={(Bass.NetProxy ?? "<none>")}");

		LoadBassPlugins();
	}

	private void ConfigureBass()
	{
		// Connection timeout: how long BASS waits for the server to answer.
		Bass.Configure(Configuration.NetTimeOut, 15000);

		// Read timeout: how long BASS waits for more data after the connection exists.
		Bass.Configure(Configuration.NetReadTimeOut, 15000);

		// Do not inherit a broken OS proxy configuration on Linux.
		Bass.NetProxy = null;
		Bass.NetAgent = "WorldMachinePlayer/1.0";

		Bass.Configure(Configuration.NetPreBuffer, 25);
		Bass.Configure(Configuration.NetBufferLength, 5000);
		Bass.Configure(Configuration.NetPlaylist, 1);

		GD.Print("[BASS] Network configuration applied");

		if (OperatingSystem.IsLinux())
		{
			ConfigureLinuxSsl();
		}
	}

	private void ConfigureLinuxSsl()
	{
		string sslPath = FindLinuxSslLibrary();

		if (string.IsNullOrEmpty(sslPath))
		{
			GD.PrintErr(
				"[BASS] Не найден libssl.so.3/libssl.so. HTTPS-потоки BASS на Linux могут не работать."
			);
			return;
		}

		try
		{
			IntPtr ptr = Marshal.StringToCoTaskMemUTF8(sslPath);
			try
			{
				bool configured = BassSetConfigPtr(
					LinuxBassConfigLibSsl,
					ptr
				);

				if (!configured)
				{
					GD.PrintErr(
						$"[BASS] Не удалось установить BASS_CONFIG_LIBSSL={sslPath}. LastError={Bass.LastError}"
					);
				}
				else
				{
					GD.Print($"[BASS] HTTPS SSL library: {sslPath}");
				}
			}
			finally
			{
				Marshal.FreeCoTaskMem(ptr);
			}
		}
		catch (Exception ex)
		{
			GD.PrintErr($"[BASS] Ошибка настройки OpenSSL: {ex}");
		}
	}

	private static string FindLinuxSslLibrary()
	{
		var systemCandidates = new[]
		{
			"/usr/lib64/libssl.so.3",
			"/usr/lib/x86_64-linux-gnu/libssl.so.3",
			"/usr/lib/libssl.so.3",
			"/lib64/libssl.so.3",
			"/lib/x86_64-linux-gnu/libssl.so.3"
		};

		foreach (string candidate in systemCandidates)
		{
			if (File.Exists(candidate))
				return candidate;
		}

		// Fallback to a bundled SSL library only when the system one is absent.
		string userDir = ProjectSettings.GlobalizePath("user://binaries");
		string resourceDir = ProjectSettings.GlobalizePath("res://libs");

		var bundledCandidates = new[]
		{
			Path.Combine(userDir, "libssl.so.3"),
			Path.Combine(userDir, "libssl.so"),
			Path.Combine(resourceDir, "libssl.so.3"),
			Path.Combine(resourceDir, "libssl.so")
		};

		foreach (string candidate in bundledCandidates)
		{
			if (File.Exists(candidate))
				return candidate;
		}

		return string.Empty;
	}

	private void LoadBassPlugins()
	{
		LoadBassPlugin("bassflac");
		LoadBassPlugin("bassopus");
		LoadBassPlugin("bass_aac");
	}

	private void LoadBassPlugin(string baseName)
	{
		string userDir = ProjectSettings.GlobalizePath("user://binaries");
		string fileName;

		if (OperatingSystem.IsWindows())
			fileName = $"{baseName}.dll";
		else if (OperatingSystem.IsLinux())
			fileName = $"lib{baseName}.so";
		else
		{
			GD.PrintErr($"[BASS] Неподдерживаемая ОС: {OS.GetName()}");
			return;
		}

		string path = Path.Combine(userDir, fileName);

		if (!File.Exists(path))
		{
			GD.PrintErr($"[BASS] plugin not found: {path}");
			return;
		}

		int pluginHandle = Bass.PluginLoad(path);

		if (pluginHandle != 0)
			GD.Print($"[BASS] plugin loaded: {path}");
		else
			GD.PrintErr($"[BASS] plugin failed: {path} ({Bass.LastError})");
	}

	// ================= radio API =================

	public bool IsActive() => _isActive;
	public bool IsSwitching() => _isSwitching;
	public string GetCurrentUrl() => _currentUrl;

	public bool IsPaused()
	{
		if (_streamChannel == 0)
			return false;

		return Bass.ChannelIsActive(_streamChannel) == PlaybackState.Paused;
	}

	public void SetStation(string url)
	{
		url = url?.Trim() ?? "";

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
		_userPaused = false;

		if (_isActive)
			return;

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
		_userPaused = false;

		if (!_isActive)
			return;

		_isActive = false;
		_isSwitching = false;
		_pendingUrl = null;
		_connectGeneration++;
		FreeStreamChannel();

		EmitSignal(SignalName.BufferingChanged, false);
		EmitSignal(SignalName.StationUnavailable, false);
	}

	public void TestStation(string url)
	{
		url = url?.Trim() ?? "";

		if (string.IsNullOrEmpty(url))
		{
			EmitSignal(SignalName.StationTestResult, url, false, false);
			return;
		}

		Task.Run(() =>
		{
			int channel = 0;
			Errors error = Errors.Unknown;

			try
			{
				channel = Bass.CreateStream(url, 0, BassFlags.Default, null);
				error = channel != 0 ? Errors.OK : Bass.LastError;
			}
			catch (Exception ex)
			{
				GD.PrintErr($"[RADIO TEST] Исключение для {url}: {ex}");
				error = Errors.Unknown;
			}
			finally
			{
				if (channel != 0)
					Bass.StreamFree(channel);
			}

			bool ok = channel != 0;
			bool unsupported = !ok && error == Errors.FileFormat;

			GD.Print(
				$"[RADIO TEST] URL={url} OK={ok} Error={error} Unsupported={unsupported}"
			);

			CallDeferred(
				nameof(EmitStationTestResult),
				url,
				ok,
				unsupported
			);
		});
	}

	private void EmitStationTestResult(string url, bool isValid, bool isUnsupported)
		=> EmitSignal(SignalName.StationTestResult, url, isValid, isUnsupported);

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

	public bool LoadSFX(string path)
	{
		string resourcePath = NormalizeSfxPath(path);

		if (string.IsNullOrEmpty(resourcePath))
		{
			GD.PrintErr($"SFX: пустой путь: {path}");
			return false;
		}

		if (_sfxSamples.ContainsKey(resourcePath))
			return true;

		if (!Godot.FileAccess.FileExists(resourcePath))
		{
			GD.PrintErr($"SFX: ресурс не найден: {resourcePath}");
			return false;
		}

		byte[] data = Godot.FileAccess.GetFileAsBytes(resourcePath);

		if (data == null || data.Length == 0)
		{
			GD.PrintErr($"SFX: не удалось прочитать ресурс: {resourcePath}");
			return false;
		}

		int sample = Bass.SampleLoad(
			data,
			0,
			data.Length,
			16,
			BassFlags.Default
		);

		if (sample == 0)
		{
			GD.PrintErr(
				$"SFX: BASS не смог загрузить {resourcePath}: {Bass.LastError}"
			);
			return false;
		}

		_sfxSamples[resourcePath] = sample;
		GD.Print($"[SFX] Загружен из PCK: {resourcePath}");

		return true;
	}

	public void PlaySFX(string path)
	{
		string resourcePath = NormalizeSfxPath(path);

		if (string.IsNullOrEmpty(resourcePath))
			return;

		if (!_sfxSamples.TryGetValue(resourcePath, out int sample))
		{
			if (!LoadSFX(resourcePath))
				return;

			sample = _sfxSamples[resourcePath];
		}

		int channel = Bass.SampleGetChannel(sample, false);

		if (channel == 0)
		{
			GD.PrintErr(
				$"SFX: не удалось получить канал для {resourcePath}: {Bass.LastError}"
			);
			return;
		}

		Bass.ChannelSetAttribute(
			channel,
			ChannelAttribute.Volume,
			_sfxVolume
		);

		Bass.ChannelPlay(channel, false);
	}

	private static string NormalizeSfxPath(string path)
	{
		if (string.IsNullOrWhiteSpace(path))
			return "";

		path = path.Trim().Replace('\\', '/');

		if (path.StartsWith("res://", StringComparison.Ordinal))
			return path;

		if (path.StartsWith("user://", StringComparison.Ordinal))
			return path;

		return $"res://sfx/{path}";
	}

	public bool CrossfadeToLocal(string path, float durationSeconds)
	{
		string resolved = ResolveFilePath(path);

		if (string.IsNullOrEmpty(resolved) || !File.Exists(resolved))
		{
			GD.PrintErr($"Local: файл не найден: {path}");
			return false;
		}

		int newChannel = Bass.CreateStream(resolved, 0, 0, BassFlags.Default);

		if (newChannel == 0)
		{
			GD.PrintErr($"Local: не удалось открыть {resolved}: {Bass.LastError}");
			return false;
		}

		int durationMs = Mathf.Max(0, (int)(durationSeconds * 1000f));

		if (_fadeOutChannel != 0)
		{
			Bass.ChannelStop(_fadeOutChannel);
			Bass.StreamFree(_fadeOutChannel);
			_fadeOutChannel = 0;
		}

		int oldChannel = _localChannel;

		if (oldChannel != 0)
		{
			_fadeOutChannel = oldChannel;
			Bass.ChannelSlideAttribute(oldChannel, ChannelAttribute.Volume, 0f, durationMs);
		}

		var info = Bass.ChannelGetInfo(newChannel);
		Bass.ChannelSetAttribute(newChannel, ChannelAttribute.Volume, 0f);
		Bass.ChannelPlay(newChannel, false);
		Bass.ChannelSlideAttribute(newChannel, ChannelAttribute.Volume, _volume, durationMs);

		_localChannel = newChannel;
		_localPath = resolved;
		_localUserPaused = false;
		_localBaseFrequency = info.Frequency > 0 ? info.Frequency : DefaultFrequency;
		AttachLocalEndSync(newChannel);
		ApplyLocalPitch();

		_fadeOutGeneration++;
		_ = FreeFadeOutChannelAfter(
			oldChannel,
			durationSeconds + 0.1f,
			_fadeOutGeneration
		);

		return true;
	}

	private async Task FreeFadeOutChannelAfter(int channel, float delaySeconds, int generation)
	{
		if (channel == 0)
			return;

		var timer = GetTree().CreateTimer(delaySeconds);
		await ToSignal(timer, SceneTreeTimer.SignalName.Timeout);

		if (generation != _fadeOutGeneration || channel != _fadeOutChannel)
			return;

		Bass.ChannelStop(channel);
		Bass.StreamFree(channel);
		_fadeOutChannel = 0;
	}

	public void PlayLocal()
	{
		if (_localChannel == 0)
			return;

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

		if (_localChannel != 0)
		{
			Bass.ChannelStop(_localChannel);
			Bass.ChannelSetPosition(_localChannel, 0, PositionFlags.Bytes);
		}
	}

	public bool IsLocalPlaying()
	{
		if (_localChannel == 0)
			return false;

		return Bass.ChannelIsActive(_localChannel) == PlaybackState.Playing;
	}

	public bool IsLocalPaused()
	{
		if (_localChannel == 0)
			return false;

		return Bass.ChannelIsActive(_localChannel) == PlaybackState.Paused;
	}

	public double GetLocalPosition()
	{
		if (_localChannel == 0)
			return 0.0;

		long bytes = Bass.ChannelGetPosition(_localChannel, PositionFlags.Bytes);
		return Bass.ChannelBytes2Seconds(_localChannel, bytes);
	}

	public double GetLocalLength()
	{
		if (_localChannel == 0)
			return 0.0;

		long bytes = Bass.ChannelGetLength(_localChannel, PositionFlags.Bytes);
		return Bass.ChannelBytes2Seconds(_localChannel, bytes);
	}

	public void SeekLocal(double seconds)
	{
		if (_localChannel == 0)
			return;

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
		if (string.IsNullOrWhiteSpace(_currentUrl))
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
			int channel = 0;
			Errors error = Errors.Unknown;

			DiagnoseNetworkEndpoint(url);

			try
			{
				// Do NOT append HTTP headers to the URL. BASS has a dedicated User-Agent config.
				channel = Bass.CreateStream(
					url,
					0,
					BassFlags.Default,
					null
				);

				// LastError MUST be captured on this thread immediately after CreateStream.
				error = channel != 0 ? Errors.OK : Bass.LastError;
			}
			catch (Exception ex)
			{
				GD.PrintErr($"[RADIO] Исключение при подключении к {url}: {ex}");
				error = Errors.Unknown;
			}

			GD.Print(
				$"[RADIO] Connect result: URL={url} Channel={channel} Error={error} OS={OS.GetName()}"
			);

			CallDeferred(
				nameof(OnConnectResult),
				channel,
				(int)error,
				generation,
				url
			);
		});
	}

	private void OnConnectResult(
		int channel,
		int errorCode,
		int generation,
		string url
	)
	{
		Errors error = (Errors)errorCode;

		if (generation != _connectGeneration || url != _currentUrl)
		{
			if (channel != 0)
				Bass.StreamFree(channel);

			return;
		}

		if (channel == 0)
		{
			GD.PrintErr(
				$"[RADIO] Не удалось подключиться:\n" +
				$"  URL: {url}\n" +
				$"  OS: {OS.GetName()}\n" +
				$"  BASS: {Bass.Version}\n" +
				$"  Error: {error} ({errorCode})"
			);

			if (OperatingSystem.IsLinux() && IsHttps(url) && error == Errors.SSL)
			{
				GD.PrintErr(
					"[RADIO] Linux HTTPS: BASS не смог использовать OpenSSL. Проверь libssl.so.3."
				);
			}

			if (error == Errors.Timeout)
			{
				GD.PrintErr(
					"[RADIO] TIMEOUT означает, что сервер не ответил на подключение за NetTimeOut. Это сетевой этап, а не декодирование аудио."
				);
			}
			else if (error == Errors.NoInternet)
			{
				GD.PrintErr(
					"[RADIO] NONET: BASS не смог открыть сетевое соединение. Проверь DNS/маршрутизацию/прокси."
				);
			}
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

		Bass.ChannelSetAttribute(
			channel,
			ChannelAttribute.Volume,
			_volume
		);

		ReadOggTags(channel);

		if (!_userPaused)
			Bass.ChannelPlay(channel, false);

		EmitSignal(SignalName.BufferingChanged, false);
		EmitSignal(SignalName.StationUnavailable, false);
		EmitSignal(SignalName.StationUnsupported, false);

		GD.Print($"[RADIO] Подключено: {url}");
		FinishSwitching();
	}

	private static bool IsHttps(string url)
		=> url.StartsWith("https://", StringComparison.OrdinalIgnoreCase);

	private static void DiagnoseNetworkEndpoint(string url)
	{
		try
		{
			var uri = new Uri(url);
			int port = uri.IsDefaultPort
				? (uri.Scheme.Equals("https", StringComparison.OrdinalIgnoreCase) ? 443 : 80)
				: uri.Port;

			GD.Print($"[RADIO NET] DNS: {uri.Host}");
			IPHostEntry addresses = Dns.GetHostEntry(uri.Host);

			foreach (IPAddress address in addresses.AddressList)
				GD.Print($"[RADIO NET]   {address} ({address.AddressFamily})");

			if (addresses.AddressList.Length == 0)
			{
				GD.PrintErr("[RADIO NET] DNS: хост разрешился в 0 адресов");
				return;
			}

			foreach (IPAddress address in addresses.AddressList)
			{
				using var client = new TcpClient(address.AddressFamily);
				Task connectTask = client.ConnectAsync(address, port);

				if (!connectTask.Wait(TimeSpan.FromSeconds(5)))
				{
					GD.PrintErr($"[RADIO NET] TCP TIMEOUT: {address}:{port}");
					continue;
				}

				if (connectTask.IsFaulted)
				{
					GD.PrintErr($"[RADIO NET] TCP FAIL: {address}:{port}: {connectTask.Exception?.GetBaseException().Message}");
					continue;
				}

				GD.Print($"[RADIO NET] TCP OK: {address}:{port}");
				break;
			}
		}
		catch (Exception ex)
		{
			GD.PrintErr($"[RADIO NET] Диагностика сети не удалась: {ex.GetType().Name}: {ex.Message}");
		}
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

		_oggChangeSync = (h, ch, data, user) =>
		{
			CallDeferred(nameof(OnOggTagsChanged), ch);
		};

		Bass.ChannelSetSync(channel, SyncFlags.OggChange, 0, _oggChangeSync);

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

		GD.Print(
			$"[RADIO] Повторное подключение через {retryDelaySeconds:F1}с: {_currentUrl}"
		);

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
			int systemCodePage = Encoding.Default.CodePage;
			return Encoding.GetEncoding(systemCodePage).GetString(data);
		}
		catch
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

	private void OnOggTagsChanged(int channel)
	{
		if (channel != _streamChannel)
			return;

		ReadOggTags(channel);
	}

	private void ReadOggTags(int channel)
	{
		IntPtr ptr = Bass.ChannelGetTags(channel, TagType.OGG);

		if (ptr == IntPtr.Zero)
			return;

		string artist = null;
		string title = null;

		foreach (string line in ReadNullSeparatedUtf8(ptr))
		{
			int eq = line.IndexOf('=');

			if (eq <= 0)
				continue;

			string key = line.Substring(0, eq);
			string value = line.Substring(eq + 1);

			if (key.Equals("TITLE", StringComparison.OrdinalIgnoreCase))
				title = value;
			else if (key.Equals("ARTIST", StringComparison.OrdinalIgnoreCase))
				artist = value;
		}

		if (string.IsNullOrEmpty(title))
			return;

		string displayTitle = string.IsNullOrEmpty(artist)
			? title
			: $"{artist} - {title}";

		EmitSignal(SignalName.TrackChanged, displayTitle);
	}

	private static IEnumerable<string> ReadNullSeparatedUtf8(IntPtr ptr)
	{
		if (ptr == IntPtr.Zero)
			yield break;

		int offset = 0;

		while (true)
		{
			int start = offset;

			while (Marshal.ReadByte(ptr, offset) != 0)
				offset++;

			int length = offset - start;

			if (length == 0)
				yield break;

			byte[] data = new byte[length];
			Marshal.Copy(ptr + start, data, 0, length);
			yield return Encoding.UTF8.GetString(data);

			offset++;
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

		GD.PrintErr(
			$"[RADIO] Соединение разорвано. Переподключение через 1.5с: {_currentUrl}"
		);

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
		if (_localChannel == 0)
			return;

		Bass.ChannelSetAttribute(
			_localChannel,
			ChannelAttribute.Frequency,
			_localBaseFrequency * _localPitch
		);
	}

	private static string ResolveFilePath(string path)
	{
		if (string.IsNullOrWhiteSpace(path))
			return "";

		if (path.StartsWith("user://", StringComparison.Ordinal))
			return ProjectSettings.GlobalizePath(path);

		if (path.StartsWith("res://", StringComparison.Ordinal))
			return ProjectSettings.GlobalizePath(path);

		return path;
	}

	private void FreeStreamChannel()
	{
		if (_streamChannel == 0)
			return;

		Bass.ChannelStop(_streamChannel);
		Bass.StreamFree(_streamChannel);
		_streamChannel = 0;
		_isBuffering = false;
	}

	private void FreeSFX()
	{
		foreach (int sample in _sfxSamples.Values)
		{
			if (sample != 0)
				Bass.SampleFree(sample);
		}

		_sfxSamples.Clear();
	}

	private void FreeLocalChannel()
	{
		if (_localChannel == 0)
			return;

		Bass.ChannelStop(_localChannel);
		Bass.StreamFree(_localChannel);
		_localChannel = 0;
	}

	public override void _ExitTree()
	{
		_connectGeneration++;
		FreeStreamChannel();
		FreeLocalChannel();
		FreeSFX();

		if (_isInitialized)
			Bass.Free();

		base._ExitTree();
	}
}
