using System;
using Godot;
#if WINDOWS_SMTC
using WorldMachinePlayer.Smtc;
#endif

public partial class MediaControlsBridge : Node
{
	[Signal] public delegate void PlayRequestedEventHandler();
	[Signal] public delegate void PauseRequestedEventHandler();
	[Signal] public delegate void NextRequestedEventHandler();
	[Signal] public delegate void PreviousRequestedEventHandler();

	public override void _Ready()
	{
#if WINDOWS_SMTC
		if (OperatingSystem.IsWindows())
		{
			SmtcService.Initialize();
			SmtcService.ButtonPressed += b => CallDeferred(nameof(Dispatch), (int)b);
		}
#endif
	}

#if WINDOWS_SMTC
	private void Dispatch(int button)
	{
		switch ((SmtcButton)button)
		{
			case SmtcButton.Play: EmitSignal(SignalName.PlayRequested); break;
			case SmtcButton.Pause: EmitSignal(SignalName.PauseRequested); break;
			case SmtcButton.Next: EmitSignal(SignalName.NextRequested); break;
			case SmtcButton.Previous: EmitSignal(SignalName.PreviousRequested); break;
		}
	}
#endif

	public void UpdateNowPlaying(string title, string artist, string imagePath = "")
	{
#if WINDOWS_SMTC
		if (OperatingSystem.IsWindows()) 
			SmtcService.UpdateMetadata(title, artist, imagePath);
#endif
	}

	public void SetPlaying(bool isPlaying)
	{
#if WINDOWS_SMTC
		if (OperatingSystem.IsWindows()) SmtcService.SetPlaybackStatus(isPlaying);
#endif
	}

	public void SetStopped()
	{
#if WINDOWS_SMTC
		if (OperatingSystem.IsWindows()) SmtcService.SetStopped();
#endif
	}
}
