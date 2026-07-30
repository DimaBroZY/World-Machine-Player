using System;
using Windows.Media;
using Windows.Media.Playback;
namespace WorldMachinePlayer.Smtc;
using System.Runtime.InteropServices;

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
		if (_smtc != null) return;
		
		try 
		{
			SetCurrentProcessExplicitAppUserModelID("DimaBroZY.WorldMachinePlayer");
		}
		catch {}
		
		_player = new MediaPlayer();
		_player.CommandManager.IsEnabled = false; 

		_smtc = _player.SystemMediaTransportControls;
		_smtc.IsEnabled = true;
		_smtc.IsPlayEnabled = true;
		_smtc.IsPauseEnabled = true;
		_smtc.IsNextEnabled = true;
		_smtc.IsPreviousEnabled = true;
		
		_smtc.DisplayUpdater.Type = MediaPlaybackType.Music;
		_smtc.DisplayUpdater.AppMediaId = "DimaBroZY.WorldMachinePlayer"; 
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

	public static void UpdateMetadata(string title, string artist)
	{
		if (_smtc == null) return;
		var props = _smtc.DisplayUpdater.MusicProperties;
		props.Title = title;
		props.Artist = artist;
		_smtc.DisplayUpdater.Update();
	}

	public static void SetPlaybackStatus(bool isPlaying) =>
		(_smtc ?? throw new InvalidOperationException()).PlaybackStatus =
			isPlaying ? MediaPlaybackStatus.Playing : MediaPlaybackStatus.Paused;

	public static void SetStopped()
	{
		if (_smtc != null) _smtc.PlaybackStatus = MediaPlaybackStatus.Stopped;
	}
}
