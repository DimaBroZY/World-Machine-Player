class_name LocalPlaybackSource
extends PlaybackSource

var _main: Control

func _init(main_node: Control) -> void:
	_main = main_node

func play() -> void:
	_main.music.stream_paused = false
	if not _main.music.is_playing():
		_main.music.play()

func pause() -> void:
	_main.music.stream_paused = true

func stop() -> void:
	_main.music.stop()

func is_playing() -> bool:
	return _main.music.is_playing() and not _main.music.stream_paused

func next() -> void:
	_main._on_next_track_pressed()

func previous() -> void:
	_main._on_previous_track_pressed()
