class_name RadioPlaybackSource
extends PlaybackSource

var _radio: RadioStreamer

func _init(radio: RadioStreamer) -> void:
	_radio = radio

func play() -> void:
	if _radio.is_active():
		_radio.resume()
	else:
		_radio.start()

func pause() -> void:
	_radio.pause()

func stop() -> void:
	_radio.stop()

func is_playing() -> bool:
	return _radio.is_active() and not _radio.is_paused()

func next() -> void: pass
func previous() -> void: pass
