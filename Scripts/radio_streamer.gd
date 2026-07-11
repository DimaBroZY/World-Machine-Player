class_name RadioStreamer
extends Node

signal track_changed(title: String)
signal buffering_changed(is_buffering: bool)
signal station_unavailable(is_unavailable: bool)

const DEFAULT_STREAM_URL := "http://stream.zeno.fm/3u1qndyk8rhvv"
const CONNECT_TIMEOUT := 10.0

var _stream_url: String = DEFAULT_STREAM_URL
var _pending_url: String = ""
var _switching := false
var _teardown_generation := 0
var _connect_generation := 0
var _orphaned_streams: Array[IcyHttpStream] = []
var _unavailable := false

var _http: IcyHttpStream
var _decoder: IcyAudioDecoder
var _player: AudioStreamPlayer
var _stream: AudioStreamGenerator
var _timer: Timer
var _active := false
var _user_paused := false
var _is_buffering := false


func setup(player: AudioStreamPlayer) -> void:
	_player = player
	_stream = player.stream as AudioStreamGenerator
	if _stream == null:
		push_error("RadioPlayer.stream must be AudioStreamGenerator")

	_timer = Timer.new()
	_timer.one_shot = false
	_timer.ignore_time_scale = true
	add_child(_timer)


func is_active() -> bool:
	return _active


func is_paused() -> bool:
	return _player != null and _player.stream_paused


func is_switching() -> bool:
	return _switching


func get_current_url() -> String:
	return _stream_url


func set_station(url: String) -> void:
	if url == _stream_url and not _switching and _decoder != null:
		return

	if _switching:
		_pending_url = url
		return

	_stream_url = url
	if _active:
		_switching = true
		buffering_changed.emit(true)
		_teardown_connection()


func start() -> void:
	if _active:
		return
	_active = true
	buffering_changed.emit(true)
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
	_switching = false
	_pending_url = ""
	_teardown_connection()
	if _player:
		_player.stop()
	buffering_changed.emit(false)
	_set_unavailable(false)


func _exit_tree() -> void:
	_teardown_generation += 1
	_active = false
	_switching = false
	_pending_url = ""
	_timer.stop()
	_clear_decoder()
	if _http:
		_http.set_audio_decoder(null)
		_http.cancel_request()
		_orphan_stream(_http)
		_http = null


func _teardown_connection() -> void:
	_teardown_generation += 1
	var generation := _teardown_generation
	_do_teardown(generation)
	_on_teardown_finished()


func _do_teardown(generation: int) -> void:
	_timer.stop()
	_clear_decoder()
	_is_buffering = false
	_connect_generation += 1

	if _switching and _player:
		_player.stop()

	if _http == null:
		return

	if generation != _teardown_generation:
		return

	var http := _http
	if http.connection_closed.is_connected(_on_connection_closed):
		http.connection_closed.disconnect(_on_connection_closed)

	http.set_audio_decoder(null)
	_orphan_stream(http)
	_http = null

	if http.has_method("is_requesting") and http.is_requesting():
		WorkerThreadPool.add_task(func():
			http.cancel_request()
		)


func _orphan_stream(stream: IcyHttpStream) -> void:
	if stream in _orphaned_streams:
		return

	_orphaned_streams.append(stream)
	var on_closed := func(_r = null) -> void:
		_orphaned_streams.erase(stream)
	stream.connection_closed.connect(on_closed, CONNECT_ONE_SHOT | CONNECT_DEFERRED)


func _clear_decoder() -> void:
	if _decoder:
		if _decoder.buffering_started.is_connected(_on_buffering_started):
			_decoder.buffering_started.disconnect(_on_buffering_started)
		if _decoder.buffering_finished.is_connected(_on_buffering_finished):
			_decoder.buffering_finished.disconnect(_on_buffering_finished)
	_decoder = null


func _on_teardown_finished() -> void:
	_decoder = null
	if _switching:
		_switching = false
		if not _pending_url.is_empty():
			var next_url := _pending_url
			_pending_url = ""
			set_station(next_url)
			return
		if _active:
			_connect()


func _ensure_http() -> IcyHttpStream:
	if _http == null:
		_http = IcyHttpStream.new()
		_http.connection_opened.connect(_on_connection_opened, CONNECT_DEFERRED)
		_http.connection_closed.connect(_on_connection_closed, CONNECT_DEFERRED)
		_http.metadata_received.connect(_on_metadata_received, CONNECT_DEFERRED)
	return _http


func _connect() -> void:
	_set_unavailable(false)
	_connect_generation += 1
	var generation := _connect_generation
	var http := _ensure_http()
	var headers: PackedStringArray = ["User-Agent: WorldMachinePlayer"]
	http.request(_stream_url, 5.0, false, headers)
	_watch_connect_timeout(generation)


func _watch_connect_timeout(generation: int) -> void:
	await get_tree().create_timer(CONNECT_TIMEOUT).timeout
	if generation != _connect_generation or not _active or _decoder != null:
		return
	push_warning("Radio: connection timed out for " + _stream_url)
	buffering_changed.emit(false)
	_set_unavailable(true)


func _set_unavailable(value: bool) -> void:
	if _unavailable == value:
		return
	_unavailable = value
	station_unavailable.emit(value)


func _abort_connection() -> void:
	_teardown_generation += 1


func _on_connection_opened() -> void:
	_set_unavailable(false)
	_connect_generation += 1
	var headers := _http.get_response_headers_as_dictionary()
	var mime := _http.get_content_mime_type()

	if mime != "audio/mpeg":
		push_error("Radio: unsupported stream format: " + mime)
		_http.cancel_request()
		_active = false
		buffering_changed.emit(false)
		return

	_decoder = IcyMp3AudioDecoder.new()
	if headers.has("icy-br"):
		_decoder.set_bitrate_hint(int(headers["icy-br"]))

	var sample_rate := _parse_sample_rate(headers)
	if sample_rate > 0:
		_stream.mix_rate = sample_rate

	_decoder.stream_info_ready.connect(_on_stream_info_ready)
	_decoder.buffering_started.connect(_on_buffering_started)
	_decoder.buffering_finished.connect(_on_buffering_finished)

	_player.play()
	_player.stream_paused = _user_paused
	_decoder.set_playback(_player.get_stream_playback())
	_http.set_audio_decoder(_decoder)

	_timer.wait_time = 0.1
	if not _timer.timeout.is_connected(_on_timer_timeout):
		_timer.timeout.connect(_on_timer_timeout)
	_timer.start()


func _parse_sample_rate(headers: Dictionary) -> int:
	var info := str(headers.get("Ice-Audio-Info", ""))
	for part in info.split(";"):
		if part.begins_with("samplerate="):
			return int(part.get_slice("=", 1))
	return 0


func _on_stream_info_ready() -> void:
	var rate: int = _decoder.get_stream_sample_rate()
	if rate != int(_stream.mix_rate):
		_stream.mix_rate = rate

	var max_frames := int(_stream.mix_rate * _stream.buffer_length)
	var frames := int(_stream.mix_rate / 2)
	_decoder.set_buffer_thresholds(frames, max_frames)

	_timer.wait_time = _stream.buffer_length / 4.0

	_is_buffering = false
	buffering_changed.emit(false)


func _on_timer_timeout() -> void:
	if _decoder:
		_decoder.process_audio()


func _on_connection_closed(_result) -> void:
	_clear_decoder()

	if _active and is_inside_tree() and not _switching:
		push_warning("Radio: connection closed, reconnecting")
		buffering_changed.emit(true)
		await get_tree().create_timer(1.5).timeout
		if _active and is_inside_tree() and not _switching:
			_connect()


func _on_metadata_received(metadata: String) -> void:
	track_changed.emit(metadata)


func _on_buffering_started() -> void:
	_is_buffering = true
	buffering_changed.emit(true)
	if _player:
		_player.stream_paused = true


func _on_buffering_finished() -> void:
	_is_buffering = false
	buffering_changed.emit(false)
	if not _user_paused and _player:
		_player.stream_paused = false
