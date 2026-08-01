class_name LocalPlayer
extends Node

signal track_finished


func _ready() -> void:
	AudioManager.LocalTrackFinished.connect(func() -> void:
		track_finished.emit()
	)


func load_track(source_path: String) -> bool:
	return AudioManager.LoadLocalTrack(source_path)


func crossfade_to(source_path: String, duration: float = 2.0) -> bool:
	return AudioManager.CrossfadeToLocal(source_path, duration)


func play() -> void:
	AudioManager.PlayLocal()


func pause() -> void:
	AudioManager.PauseLocal()


func stop() -> void:
	AudioManager.StopLocal()


func is_playing() -> bool:
	return AudioManager.IsLocalPlaying()


func is_paused() -> bool:
	return AudioManager.IsLocalPaused()


func has_track() -> bool:
	return AudioManager.HasLocalTrack()


func get_current_path() -> String:
	return AudioManager.GetLocalPath()


func get_position() -> float:
	return float(AudioManager.GetLocalPosition())


func get_length() -> float:
	return float(AudioManager.GetLocalLength())


func seek(seconds: float) -> void:
	AudioManager.SeekLocal(seconds)


func set_pitch(scale: float) -> void:
	AudioManager.SetLocalPitch(scale)


func get_pitch() -> float:
	return AudioManager.GetLocalPitch()
