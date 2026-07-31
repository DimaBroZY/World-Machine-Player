class_name RadioStreamer
extends Node

signal track_changed(title: String)
signal buffering_changed(is_buffering: bool)
signal station_unavailable(is_unavailable: bool)

func setup(_player: AudioStreamPlayer) -> void:
	pass


func _ready() -> void:
	AudioManager.TrackChanged.connect(func(title: String) -> void:
		track_changed.emit(title)
	)
	AudioManager.BufferingChanged.connect(func(is_buffering: bool) -> void:
		buffering_changed.emit(is_buffering)
	)
	AudioManager.StationUnavailable.connect(func(is_unavailable: bool) -> void:
		station_unavailable.emit(is_unavailable)
	)

func is_active() -> bool:
	return AudioManager.IsActive()


func is_paused() -> bool:
	return AudioManager.IsPaused()


func is_switching() -> bool:
	return AudioManager.IsSwitching()


func get_current_url() -> String:
	return AudioManager.GetCurrentUrl()


func set_station(url: String) -> void:
	AudioManager.SetStation(url)


func start() -> void:
	AudioManager.StartRadio()


func resume() -> void:
	AudioManager.ResumeRadio()


func pause() -> void:
	AudioManager.PauseRadio()


func stop() -> void:
	AudioManager.StopRadio()
