using System;
using System.IO;
using Windows.Media;
using Windows.Media.Playback;
using System.Runtime.InteropServices;
using Windows.Storage;
using Windows.Storage.Streams;
using System.Threading.Tasks;

namespace WorldMachinePlayer.Smtc; 

public enum SmtcButton { Play, Pause, Next, Previous, Stop }

public static class SmtcService
{
	public static event Action<SmtcButton>? ButtonPressed;

	private static MediaPlayer? _player;
	private static SystemMediaTransportControls? _smtc;
	
	[DllImport("shell32.dll", CharSet = CharSet.Unicode)]
	private static extern int SetCurrentProcessExplicitAppUserModelID(string appId);
	
	public static void Initialize()
	{
		if (_smtc != null) 
			return;
		const string AppId = "DimaBroZY.WorldMachinePlayer";
		const string AppName = "World Machine Player";
		SetCurrentProcessExplicitAppUserModelID(AppId);
		StartMenuShortcutHelper.EnsureShortcut(AppId, AppName);
		  
		_player = new MediaPlayer();
		_player.CommandManager.IsEnabled = false; 

		_smtc = _player.SystemMediaTransportControls;
		_smtc.IsEnabled = true;
		_smtc.IsPlayEnabled = true;
		_smtc.IsPauseEnabled = true;
		_smtc.IsNextEnabled = true;
		_smtc.IsPreviousEnabled = true;
		_smtc.DisplayUpdater.Type = MediaPlaybackType.Music;
		_smtc.DisplayUpdater.Update();

		_smtc.ButtonPressed += OnButtonPressed;
	}

	private static void OnButtonPressed(SystemMediaTransportControls s, SystemMediaTransportControlsButtonPressedEventArgs e)
	{
		var mapped = e.Button switch
		{
			SystemMediaTransportControlsButton.Play => SmtcButton.Play,
			SystemMediaTransportControlsButton.Pause => SmtcButton.Pause,
			SystemMediaTransportControlsButton.Next => SmtcButton.Next,
			SystemMediaTransportControlsButton.Previous => SmtcButton.Previous,
			SystemMediaTransportControlsButton.Stop => SmtcButton.Stop,
			_ => (SmtcButton?)null
		};
		if (mapped.HasValue) ButtonPressed?.Invoke(mapped.Value);
	}

	public static async void UpdateMetadata(string title, string artist, string absoluteImagePath = "")
	{
		if (_smtc == null) return;
	   
		var updater = _smtc.DisplayUpdater;
		updater.Type = MediaPlaybackType.Music;
	   
		var props = updater.MusicProperties;
		props.Title = title;
		props.Artist = artist;

		if (!string.IsNullOrEmpty(absoluteImagePath))
		{
			// Меняем прямые слэши Godot на обратные системные слэши Windows
			string winPath = absoluteImagePath.Replace('/', '\\');

			if (File.Exists(winPath))
			{
				try
				{
					StorageFile file = await StorageFile.GetFileFromPathAsync(winPath);
					updater.Thumbnail = RandomAccessStreamReference.CreateFromFile(file);
				}
				catch (Exception ex)
				{
					Console.WriteLine($"[SMTC Error] Ошибка загрузки обложки: {ex.Message}");
				}
			}
			else
			{
				Console.WriteLine($"[SMTC Error] Файл обложки не найден по пути: {winPath}");
			}
		}

		updater.Update();
	}

	public static void SetPlaybackStatus(bool isPlaying) =>
		(_smtc ?? throw new InvalidOperationException()).PlaybackStatus =
			isPlaying ? MediaPlaybackStatus.Playing : MediaPlaybackStatus.Paused;

	public static void SetStopped()
	{
		if (_smtc != null) _smtc.PlaybackStatus = MediaPlaybackStatus.Stopped;
	}
}
