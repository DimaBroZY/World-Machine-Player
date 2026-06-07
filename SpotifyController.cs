using Godot;
using System;
using System.Diagnostics;
using System.IO;
using System.Threading;
using System.Threading.Tasks;

/// <summary>
/// Управляет процессом librespot.exe, который регистрирует виртуальное
/// Spotify Connect устройство "World Machine Player".
/// Аудио поток (PCM s16le, 44100Hz, stereo) читается из stdout
/// и отправляется в AudioStreamGeneratorPlayback в Godot.
/// </summary>
public partial class SpotifyController : Node
{
	// Сигналы для GDScript
	[Signal] public delegate void LibrespotReadyEventHandler();
	[Signal] public delegate void LibrespotErrorEventHandler(string message);
	[Signal] public delegate void TrackChangedEventHandler(string title, string artist);
	[Signal] public delegate void PlaybackStartedEventHandler();
	[Signal] public delegate void PlaybackPausedEventHandler();

	// Путь к librespot.exe рядом с проектом (или рядом с .exe экспорта)
	private const string LibrespotBinary = "librespot.exe";

	// Имя устройства, которое появится в Spotify
	private const string DeviceName = "World Machine Player";

	// Параметры PCM потока (librespot default)
	private const int SampleRate = 44100;
	private const int Channels = 2;
	// Размер буфера чтения: 4096 сэмплов * 2 байта * 2 канала
	private const int ReadBufferSize = 4096 * 2 * Channels;

	private Process _librespotProcess;
	private Thread _readerThread;
	private bool _isRunning = false;
	private AudioStreamGeneratorPlayback _playback;
	private string _username = "";
	private string _password = "";

	// Очередь аудио данных, передаётся из потока в основной поток
	private readonly System.Collections.Generic.Queue<float[]> _audioQueue =
		new System.Collections.Generic.Queue<float[]>();
	private readonly object _queueLock = new object();

	public override void _Ready()
	{
		GD.Print("SpotifyController: инициализация...");
		// Загружаем сохранённые учётные данные при старте
		_username = (string)Settings.Call("get_setting", "spotify_username") ?? "";
		_password = (string)Settings.Call("get_setting", "spotify_password") ?? "";

		if (!string.IsNullOrEmpty(_username) && !string.IsNullOrEmpty(_password))
		{
			StartLibrespot(_username, _password);
		}
	}

	public override void _Process(double delta)
	{
		// Отправляем накопленные аудио-фреймы в генератор
		if (_playback == null || !_isRunning) return;

		lock (_queueLock)
		{
			while (_audioQueue.Count > 0)
			{
				var frames = _audioQueue.Dequeue();
				// Каждые 2 float = один стерео фрейм
				for (int i = 0; i + 1 < frames.Length; i += 2)
				{
					_playback.PushFrame(new Vector2(frames[i], frames[i + 1]));
				}
			}
		}
	}

	public override void _ExitTree()
	{
		StopLibrespot();
	}

	/// <summary>
	/// Вызывается из GDScript когда пользователь вводит логин/пароль в настройках.
	/// </summary>
	public void StartWithCredentials(string username, string password)
	{
		_username = username;
		_password = password;
		Settings.Call("save_setting", "spotify_username", username);
		// Пароль тоже сохраняем (хранится в user:// данных игры)
		Settings.Call("save_setting", "spotify_password", password);

		StopLibrespot();
		StartLibrespot(username, password);
	}

	/// <summary>
	/// Подключает AudioStreamGeneratorPlayback для вывода PCM звука.
	/// GDScript должен передать playback после вызова play() на AudioStreamPlayer.
	/// </summary>
	public void SetPlayback(AudioStreamGeneratorPlayback playback)
	{
		_playback = playback;
		GD.Print("SpotifyController: AudioStreamGeneratorPlayback подключён.");
	}

	public void StopLibrespot()
	{
		_isRunning = false;
		try
		{
			if (_librespotProcess != null && !_librespotProcess.HasExited)
			{
				_librespotProcess.Kill();
				_librespotProcess.Dispose();
				_librespotProcess = null;
				GD.Print("SpotifyController: librespot остановлен.");
			}
		}
		catch (Exception e)
		{
			GD.PrintErr($"SpotifyController: ошибка при остановке librespot: {e.Message}");
		}

		_readerThread?.Join(1000);
		_readerThread = null;
	}

	private void StartLibrespot(string username, string password)
	{
		// Ищем librespot.exe рядом с проектом или рядом с запущенным .exe
		string binaryPath = FindLibrespotBinary();
		if (binaryPath == null)
		{
			string msg = "librespot.exe не найден! Положи его рядом с игрой.";
			GD.PrintErr("SpotifyController: " + msg);
			CallDeferred("emit_signal", SignalName.LibrespotError, msg);
			return;
		}

		// Аргументы для librespot:
		// --backend pipe  — выводить PCM в stdout
		// --bitrate 320   — максимальное качество
		// --name          — имя устройства в Spotify
		// --disable-audio-cache — не кэшировать треки на диск
		// --emit-sink-events   — событие при pause/play (в stderr)
		string args = $"-n \"{DeviceName}\" " +
					  $"-u \"{username}\" " +
					  $"-p \"{password}\" " +
					  $"--backend pipe " +
					  $"--bitrate 320 " +
					  $"--disable-audio-cache " +
					  $"--emit-sink-events";

		try
		{
			var psi = new ProcessStartInfo
			{
				FileName = binaryPath,
				Arguments = args,
				UseShellExecute = false,
				CreateNoWindow = true,         // никакого окна!
				RedirectStandardOutput = true, // читаем PCM из stdout
				RedirectStandardError = true,  // читаем события из stderr
			};
			// ВАЖНО: stdout будет бинарным PCM, отключаем буферизацию
			psi.StandardOutputEncoding = null;

			_librespotProcess = new Process { StartInfo = psi };
			_librespotProcess.ErrorDataReceived += OnStderrLine;
			_librespotProcess.Start();
			_librespotProcess.BeginErrorReadLine();

			_isRunning = true;

			// Запускаем отдельный поток для чтения PCM из stdout
			_readerThread = new Thread(ReadPcmLoop) { IsBackground = true, Name = "LibrespotPCMReader" };
			_readerThread.Start();

			GD.Print($"SpotifyController: librespot запущен (PID {_librespotProcess.Id})");
			GD.Print($"SpotifyController: устройство '{DeviceName}' должно появиться в Spotify!");
			CallDeferred("emit_signal", SignalName.LibrespotReady);
		}
		catch (Exception e)
		{
			string msg = $"Не удалось запустить librespot: {e.Message}";
			GD.PrintErr("SpotifyController: " + msg);
			CallDeferred("emit_signal", SignalName.LibrespotError, msg);
		}
	}

	private void ReadPcmLoop()
	{
		// Читаем raw PCM (signed 16-bit little-endian, 44100Hz, stereo) из stdout
		var stream = _librespotProcess.StandardOutput.BaseStream;
		byte[] rawBuffer = new byte[ReadBufferSize];

		while (_isRunning)
		{
			try
			{
				int bytesRead = stream.Read(rawBuffer, 0, rawBuffer.Length);
				if (bytesRead == 0)
				{
					// librespot закрыл поток — вероятно завершился
					break;
				}

				// Конвертируем bytes → float[-1..1] и складываем в очередь
				int sampleCount = bytesRead / 2; // каждый сэмпл = 2 байта (int16)
				float[] floatSamples = new float[sampleCount];
				for (int i = 0; i < sampleCount; i++)
				{
					short s = (short)(rawBuffer[i * 2] | (rawBuffer[i * 2 + 1] << 8));
					floatSamples[i] = s / 32768.0f;
				}

				lock (_queueLock)
				{
					// Не даём очереди разрастись больше нужного
					if (_audioQueue.Count < 100)
						_audioQueue.Enqueue(floatSamples);
				}
			}
			catch (Exception e)
			{
				if (_isRunning)
					GD.PrintErr($"SpotifyController: ошибка чтения PCM: {e.Message}");
				break;
			}
		}

		GD.Print("SpotifyController: поток чтения PCM завершён.");
	}

	private void OnStderrLine(object sender, DataReceivedEventArgs e)
	{
		if (string.IsNullOrEmpty(e.Data)) return;
		GD.Print($"[librespot] {e.Data}");

		// librespot пишет события в stderr, парсим их
		string line = e.Data.ToLower();

		if (line.Contains("loading track") || line.Contains("track changed"))
		{
			// Попытаемся вытащить название трека из лога
			CallDeferred("emit_signal", SignalName.TrackChanged, "Spotify Track", "");
		}
		else if (line.Contains("playback started") || line.Contains("sink: started"))
		{
			CallDeferred("emit_signal", SignalName.PlaybackStarted);
		}
		else if (line.Contains("playback paused") || line.Contains("sink: stopped"))
		{
			CallDeferred("emit_signal", SignalName.PlaybackPaused);
		}
	}

	private string FindLibrespotBinary()
	{
		// 1. Рядом с исполняемым файлом игры (для экспорта)
		string exeDir = System.AppContext.BaseDirectory;
		string candidate1 = Path.Combine(exeDir, LibrespotBinary);
		if (File.Exists(candidate1)) return candidate1;

		// 2. Рядом с папкой res:// проекта (для разработки в редакторе)
		string projectDir = ProjectSettings.GlobalizePath("res://");
		string candidate2 = Path.Combine(projectDir, LibrespotBinary);
		if (File.Exists(candidate2)) return candidate2;

		// 3. В текущей рабочей директории
		string candidate3 = Path.Combine(Directory.GetCurrentDirectory(), LibrespotBinary);
		if (File.Exists(candidate3)) return candidate3;

		return null;
	}

	/// <summary>Проверить, запущен ли librespot прямо сейчас.</summary>
	public bool IsRunning()
	{
		return _isRunning && _librespotProcess != null && !_librespotProcess.HasExited;
	}

	/// <summary>Вернуть имя устройства для отображения в UI.</summary>
	public string GetDeviceName() => DeviceName;

	/// <summary>Проверить, есть ли сохранённые учётные данные.</summary>
	public bool HasCredentials()
	{
		string u = (string)Settings.Call("get_setting", "spotify_username") ?? "";
		string p = (string)Settings.Call("get_setting", "spotify_password") ?? "";
		return !string.IsNullOrEmpty(u) && !string.IsNullOrEmpty(p);
	}
}
