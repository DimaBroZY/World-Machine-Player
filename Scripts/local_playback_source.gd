class_name LocalPlaybackSource
extends PlaybackSource

var _local: LocalPlayer

func _init(local: LocalPlayer) -> void:
	_local = local

func play() -> void:
	if _local.is_paused() or not _local.is_playing():
		_local.play()

func pause() -> void:
	_local.pause()

func stop() -> void:
	_local.stop()

func is_playing() -> bool:
	return _local.is_playing()

func next() -> void: pass

func previous() -> void: pass
