class_name RadioStreamer
extends Node

signal track_changed(title: String)

const STREAM_URL := "https://radio.loficafe.net/listen/chilling/radio.mp3"

var _http: IcyHttpStream
var _decoder: IcyAudioDecoder
var _player: AudioStreamPlayer
var _stream: AudioStreamGenerator
var _timer: Timer
var _active := false
var _user_paused := false
var _is_buffering := false


func setup(player: AudioStreamPlayer) -> void:
	print("SETUP")
	_player = player
	_stream = player.stream as AudioStreamGenerator
	if _stream == null:
		push_error("RadioPlayer.stream должен быть AudioStreamGenerator — выставь в инспекторе")

	_timer = Timer.new()
	_timer.one_shot = false
	_timer.ignore_time_scale = true
	add_child(_timer)


func is_active() -> bool:
	return _active


func is_paused() -> bool:
	return _player != null and _player.stream_paused


func start() -> void:
	print("START")
	if _active:
		return
	_active = true
	_connect()


func resume() -> void:
	_user_paused = false
	if _player and not _is_buffering:
		_player.stream_paused = false


func pause() -> void:
	_user_paused = true
	if _player:
		_player.stream_paused = true


func stop() -> void:
	if not _active:
		return
	_active = false
	_timer.stop()
	if _http:
		_http.cancel_request()
	if _player:
		_player.stop()
	_decoder = null


func _connect() -> void:
	print("CONNECT")
	_http = IcyHttpStream.new()
	_http.connection_opened.connect(_on_connection_opened)
	_http.connection_closed.connect(_on_connection_closed)
	_http.metadata_received.connect(_on_metadata_received)
	var headers: PackedStringArray = ["User-Agent: WorldMachinePlayer"]
	_http.request(STREAM_URL, 5.0, false, headers)


func _on_connection_opened() -> void:
	print("CONNECTION OPENED")
	var headers := _http.get_response_headers_as_dictionary()
	var mime := _http.get_content_mime_type()
	print("mime: ", mime)

	if mime != "audio/mpeg":
		push_error("Radio: unsupported stream format: " + mime)
		_http.cancel_request()
		_active = false
		return

	_decoder = IcyMp3AudioDecoder.new()
	if headers.has("icy-br"):
		_decoder.set_bitrate_hint(int(headers["icy-br"]))

	var sample_rate := _parse_sample_rate(headers)
	print("parsed sample_rate: ", sample_rate)
	if sample_rate > 0:
		_stream.mix_rate = sample_rate
	print("stream mix_rate now: ", _stream.mix_rate)

	_decoder.stream_info_ready.connect(_on_stream_info_ready)
	_decoder.buffering_started.connect(_on_buffering_started)
	_decoder.buffering_finished.connect(_on_buffering_finished)

	_player.play()
	print("player.play() called, playing=", _player.playing)
	_player.stream_paused = _user_paused
	print("stream_paused set to ", _user_paused)

	var playback = _player.get_stream_playback()
	print("playback object: ", playback)
	_decoder.set_playback(playback)
	_http.set_audio_decoder(_decoder)
	print("decoder attached to http")

	_timer.wait_time = 0.1
	if not _timer.timeout.is_connected(_on_timer_timeout):
		_timer.timeout.connect(_on_timer_timeout)
	_timer.start()
	print("timer started, wait_time=", _timer.wait_time)


func _parse_sample_rate(headers: Dictionary) -> int:
	var info := str(headers.get("Ice-Audio-Info", ""))
	for part in info.split(";"):
		if part.begins_with("samplerate="):
			return int(part.get_slice("=", 1))
	return 0


func _on_stream_info_ready() -> void:
	print("STREAM INFO READY")
	var rate: int = _decoder.get_stream_sample_rate()
	if rate != int(_stream.mix_rate):
		_stream.mix_rate = rate

	var max_frames := int(_stream.mix_rate * _stream.buffer_length)
	var frames := int(_stream.mix_rate / 2)
	_decoder.set_buffer_thresholds(frames, max_frames)

	_timer.wait_time = _stream.buffer_length / 4.0


func _on_timer_timeout() -> void:
	if _decoder:
		_decoder.process_audio()


func _on_connection_closed(_result) -> void:
	print("CONNECTION CLOSED: ", _result)
	if _decoder:
		if _decoder.buffering_started.is_connected(_on_buffering_started):
			_decoder.buffering_started.disconnect(_on_buffering_started)
		if _decoder.buffering_finished.is_connected(_on_buffering_finished):
			_decoder.buffering_finished.disconnect(_on_buffering_finished)

	if _active:
		push_warning("Radio: connection closed, reconnecting")
		await get_tree().create_timer(1.5).timeout
		if _active:
			_connect()


func _on_metadata_received(metadata: String) -> void:
	track_changed.emit(metadata)


func _on_buffering_started() -> void:
	print("BUFFERING STARTED")
	_is_buffering = true
	if _player:
		_player.stream_paused = true


func _on_buffering_finished() -> void:
	print("BUFFERING FINISHED")
	_is_buffering = false
	if not _user_paused and _player:
		_player.stream_paused = false
