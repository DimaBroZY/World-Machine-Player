using System;
using Godot;
using DiscordRPC;
using Button = DiscordRPC.Button;
public partial class DiscordRpcBridge : Node
{
	private const string ClientId = "1532451406554988654";
	private static readonly Button[] Buttons =
	{
		new Button { Label = "WMP Website", Url = "https://dimabrozy.github.io/World-Machine-Player/" }
	};

	private DiscordRpcClient _client;
	private string _title = "";
	private string _artist = "";
	private double _durationSeconds = 0;

	public override void _Ready()
	{
		_client = new DiscordRpcClient(ClientId);
		_client.Initialize();
	}
	
	private bool IsEnabled()
	{
		var settings = GetNode("/root/Settings");
		return (bool)settings.Call("get_setting", "discord_rpc_enabled", true);
	}

	public void UpdateNowPlaying(string title, string artist, double durationSeconds = 0)
	{
		if (!IsEnabled()) return;
		_title = title;
		_artist = artist;
		_durationSeconds = durationSeconds;
		SetPlaying(true, 0.0);
	}
	
	public void SetPlaying(bool isPlaying, double positionSeconds = 0)
	{
		if (_client == null || !IsEnabled()) return;

		var presence = new RichPresence
		{
			Type = ActivityType.Listening,
			Details = _title,
			State = isPlaying ? _artist : $"{_artist} — на паузе",
			Buttons = Buttons
		};

		if (isPlaying)
		{
			var start = DateTime.UtcNow.AddSeconds(-positionSeconds);
			var ts = new Timestamps { Start = start };
			if (_durationSeconds > 0)
				ts.End = start.AddSeconds(_durationSeconds);
			presence.Timestamps = ts;
		}

		_client.SetPresence(presence);
	}

	public void SetStopped() => _client?.ClearPresence();

	public override void _ExitTree() => _client?.Dispose();
}
