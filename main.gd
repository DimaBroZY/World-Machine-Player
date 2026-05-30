extends Control

# я DimaBroZY и я долбаеб

@onready var music: AudioStreamPlayer = $MainWindow/AudioStreamPlayer
@onready var curTrack: ScrollText = $MainWindow/CurrentTrack/PanelContainer/ScrollerControl
@onready var loadingInfo: Label = $MainWindow/LoadingInfo
@onready var niko = $MainWindow/Objects/Niko
@onready var gramophone = $MainWindow/Objects/Gramophone
@onready var volumeControl = $MainWindow/VolumeControl
@onready var speedControl = $MainWindow/PlaybackSpeedControlNode
@onready var nextTrack =$MainWindow/CurrentTrack/NextTrack
@onready var previousTrack = $MainWindow/CurrentTrack/PreviousTrack


var MUSIC_FILE: AudioStream = preload("res://music/Prelude.mp3")

const PLAY: int = 0
const PAUSE: int = 1
const MUSIC_CACHE_VERSION: int = 1
const MUSIC_CACHE_FILE: String = "user://music_cache.json"
const MUSIC_CACHE_DIR: String = "user://music_cache"
const MUSIC_FOLDER_SCAN_INTERVAL: float = 5.0
const MIN_FILE_AGE_SECONDS: int = 2
const STREAM_CACHE_RADIUS: int = 1
const SUPPORTED_AUDIO_EXTENSIONS: Array[String] = ["ogg", "mp3", "flac", "opus"]
const LOCK_TIME: float = 0.5

var state: int = PAUSE
var playlist: Array[Dictionary] = []
var current_index: int = 0
var FOLDER_PATH: String
var _music_cache: Dictionary = {}
var _stream_cache: Dictionary = {}
var _is_loading_tracks: bool = false
var _last_music_scan_ok: bool = false
var _stream_cache_refresh_queued: bool = false


func _ready() -> void:
	loadingInfo.visible = false
	FOLDER_PATH = str(Settings.get_setting("music_path", "user://music"))
	Settings.setting_changed.connect(_on_setting_changed)

	_create_folder_scan_timer()

	music.volume_db = 0
	await load_tracks_from_folder(true)
	update_state()


func nicoAnim() -> void:
	if randi_range(1, 2) == 1:
		niko.animPlayer.play("Dancing")
	else:
		niko.animPlayer.play("Dance_Sitting")


func _on_audio_stream_player_finished() -> void:
	music.play(0.0)


func _on_setting_changed(key: String, value: Variant) -> void:
	if key == "music_path":
		FOLDER_PATH = str(value)
		current_index = 0
		await load_tracks_from_folder(true)
		update_state()


func _create_folder_scan_timer() -> void:
	var folder_scan_timer: Timer = Timer.new()
	folder_scan_timer.wait_time = MUSIC_FOLDER_SCAN_INTERVAL
	folder_scan_timer.one_shot = false
	folder_scan_timer.autostart = false
	folder_scan_timer.timeout.connect(_on_folder_scan_timer_timeout)
	add_child(folder_scan_timer)
	folder_scan_timer.start()


func _on_folder_scan_timer_timeout() -> void:
	await load_tracks_from_folder(true)


func load_tracks_from_folder(show_loading: bool = true) -> void:
	if _is_loading_tracks:
		return

	_is_loading_tracks = true
	_ensure_music_cache_dir()
	_music_cache = _load_music_cache()

	var previous_source_path: String = _get_current_track_value("source_path")
	var previous_resource_path: String = _get_current_track_value("resource_path")
	var changed_sources: Dictionary = {}
	var scanned_tracks: Array[Dictionary] = _scan_music_folder()

	if not _last_music_scan_ok:
		_hide_loading_info()
		_is_loading_tracks = false
		if playlist.is_empty():
			_load_fallback_track()
		return

	var existing_sources: Dictionary = {}
	for file_info: Dictionary in scanned_tracks:
		existing_sources[str(file_info["source_path"])] = true

	_cleanup_missing_tracks(existing_sources)

	var refreshed_playlist: Array[Dictionary] = []
	var imported_count: int = 0

	for file_info: Dictionary in scanned_tracks:
		var source_path: String = str(file_info["source_path"])
		var cached_track: Dictionary = {}
		if _music_cache.has(source_path):
			cached_track = _music_cache[source_path] as Dictionary

		var needs_import: bool = _track_needs_import(cached_track, file_info)
		if needs_import and not bool(file_info["ready"]):
			if cached_track.is_empty():
				continue
			var pending_track: Dictionary = cached_track.duplicate()
			refreshed_playlist.append(pending_track)
			continue

		var track: Dictionary
		if needs_import:
			if not cached_track.is_empty():
				_drop_cached_stream(str(cached_track.get("resource_path", "")))

			imported_count += 1
			changed_sources[source_path] = true
			if show_loading:
				_show_loading_info(imported_count)
				await get_tree().process_frame

			track = _import_track(file_info)
			if track.is_empty():
				continue

			_music_cache[source_path] = track
			await get_tree().process_frame
		else:
			track = _updated_track_from_cache(cached_track, file_info)
			_music_cache[source_path] = track

		refreshed_playlist.append(track)

	playlist = refreshed_playlist
	_remove_orphan_cache_files()
	_save_music_cache()
	_apply_playlist_after_refresh(previous_source_path, previous_resource_path, changed_sources)
	_hide_loading_info()
	_is_loading_tracks = false


func _scan_music_folder() -> Array[Dictionary]:
	var found_tracks: Array[Dictionary] = []
	_last_music_scan_ok = false

	var dir: DirAccess = DirAccess.open(FOLDER_PATH)
	if dir == null:
		print("Music folder cannot be opened: ", FOLDER_PATH)
		return found_tracks

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and _is_supported_audio_file(file_name):
			var source_path: String = _join_path(FOLDER_PATH, file_name)
			var file_size: int = _get_file_size(source_path)
			if file_size > 0:
				var modified_time: int = int(FileAccess.get_modified_time(source_path))
				found_tracks.append({
					"source_path": source_path,
					"file_name": file_name,
					"name": file_name.get_basename(),
					"extension": file_name.get_extension().to_lower(),
					"size": file_size,
					"modified_time": modified_time,
					"ready": _is_file_ready(modified_time),
				})
		file_name = dir.get_next()
	dir.list_dir_end()

	_last_music_scan_ok = true
	return found_tracks


func _is_supported_audio_file(file_name: String) -> bool:
	var extension: String = file_name.get_extension().to_lower()
	return SUPPORTED_AUDIO_EXTENSIONS.has(extension)


func _is_file_ready(modified_time: int) -> bool:
	if modified_time <= 0:
		return true

	var current_time: int = int(Time.get_unix_time_from_system())
	return current_time - modified_time >= MIN_FILE_AGE_SECONDS


func _get_file_size(path: String) -> int:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return -1

	var file_size: int = int(file.get_length())
	file.close()
	return file_size


func _load_music_cache() -> Dictionary:
	var entries: Dictionary = {}
	if not FileAccess.file_exists(MUSIC_CACHE_FILE):
		return entries

	var file: FileAccess = FileAccess.open(MUSIC_CACHE_FILE, FileAccess.READ)
	if file == null:
		return entries

	var json_text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(json_text)
	if not (parsed is Dictionary):
		return entries

	var cache_data: Dictionary = parsed as Dictionary
	if int(cache_data.get("cache_version", 0)) != MUSIC_CACHE_VERSION:
		return entries

	var tracks_variant: Variant = cache_data.get("tracks", [])
	if not (tracks_variant is Array):
		return entries

	var cached_tracks: Array = tracks_variant as Array
	for track_variant: Variant in cached_tracks:
		if track_variant is Dictionary:
			var track: Dictionary = track_variant as Dictionary
			var source_path: String = str(track.get("source_path", ""))
			if not source_path.is_empty():
				entries[source_path] = track

	return entries


func _save_music_cache() -> void:
	var cached_tracks: Array[Dictionary] = []
	for track: Dictionary in playlist:
		cached_tracks.append(track)

	var cache_data: Dictionary = {
		"cache_version": MUSIC_CACHE_VERSION,
		"folder_path": FOLDER_PATH,
		"tracks": cached_tracks,
	}

	var file: FileAccess = FileAccess.open(MUSIC_CACHE_FILE, FileAccess.WRITE)
	if file == null:
		print("Cannot write music cache: ", MUSIC_CACHE_FILE)
		return

	file.store_string(JSON.stringify(cache_data, "\t"))
	file.close()


func _track_needs_import(cached_track: Dictionary, file_info: Dictionary) -> bool:
	if cached_track.is_empty():
		return true

	var resource_path: String = str(cached_track.get("resource_path", ""))
	if resource_path.is_empty() or not FileAccess.file_exists(resource_path):
		return true

	if int(cached_track.get("size", -1)) != int(file_info["size"]):
		return true

	if int(cached_track.get("modified_time", -1)) != int(file_info["modified_time"]):
		return true

	return false


func _updated_track_from_cache(cached_track: Dictionary, file_info: Dictionary) -> Dictionary:
	var track: Dictionary = cached_track.duplicate()
	var source_path: String = str(file_info["source_path"])

	track["source_path"] = source_path
	track["file_name"] = str(file_info["file_name"])
	track["name"] = str(file_info["name"])
	track["extension"] = str(file_info["extension"])
	track["size"] = int(file_info["size"])
	track["modified_time"] = int(file_info["modified_time"])

	if not track.has("resource_path") or str(track["resource_path"]).is_empty():
		track["resource_path"] = _get_cache_resource_path(file_info)

	if track.has("cached_path"):
		_delete_cached_path(str(track["cached_path"]), source_path)
		track.erase("cached_path")

	_delete_legacy_cache_files(file_info)
	return track


func _import_track(file_info: Dictionary) -> Dictionary:
	var source_path: String = str(file_info["source_path"])
	var file_name: String = str(file_info["file_name"])
	var resource_path: String = _get_cache_resource_path(file_info)
	var buffer: PackedByteArray = _read_file_buffer(source_path)

	if buffer.is_empty():
		print("Cannot read audio file: ", source_path)
		return {}

	var stream: AudioStream = _create_audio_stream(file_name, buffer)
	if stream == null:
		print("Cannot create AudioStream for: ", source_path)
		return {}

	var save_error: int = ResourceSaver.save(stream, resource_path)
	if save_error != OK:
		print("Cannot save cached stream: ", resource_path, " error: ", save_error)
		return {}

	_delete_legacy_cache_files(file_info)

	return {
		"source_path": source_path,
		"resource_path": resource_path,
		"file_name": file_name,
		"name": str(file_info["name"]),
		"extension": str(file_info["extension"]),
		"size": int(file_info["size"]),
		"modified_time": int(file_info["modified_time"]),
	}


func _read_file_buffer(path: String) -> PackedByteArray:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return PackedByteArray()

	var buffer: PackedByteArray = file.get_buffer(file.get_length())
	file.close()
	return buffer


func _create_audio_stream(file_name: String, buffer: PackedByteArray) -> AudioStream:
	var extension: String = file_name.get_extension().to_lower()
	var stream: AudioStream = null

	if extension == "ogg":
		stream = AudioStreamOggVorbis.load_from_buffer(buffer)
	elif extension == "mp3":
		stream = AudioStreamMP3.load_from_buffer(buffer)
	elif extension == "opus":
		var opus_stream: AudioStreamOpus = AudioStreamOpus.new()
		opus_stream.data = buffer
		stream = opus_stream
	elif extension == "flac":
		var flac_stream: AudioStreamFLAC = AudioStreamFLAC.new()
		flac_stream.data = buffer
		stream = flac_stream

	return stream


func _cleanup_missing_tracks(existing_sources: Dictionary) -> void:
	var cached_sources: Array = _music_cache.keys()
	for source_variant: Variant in cached_sources:
		var source_path: String = str(source_variant)
		if not existing_sources.has(source_path):
			var track: Dictionary = _music_cache[source_path] as Dictionary
			_delete_cached_track(track)
			_music_cache.erase(source_path)


func _delete_cached_track(track: Dictionary) -> void:
	var source_path: String = str(track.get("source_path", ""))
	var resource_path: String = str(track.get("resource_path", ""))
	_drop_cached_stream(resource_path)
	_delete_cached_path(resource_path, source_path)
	_delete_cached_path(str(track.get("cached_path", "")), source_path)


func _delete_legacy_cache_files(file_info: Dictionary) -> void:
	var source_path: String = str(file_info["source_path"])
	var file_name: String = str(file_info["file_name"])
	var legacy_audio_path: String = "user://" + file_name.replace(" ", "_").replace("[", "_").replace("]", "_")
	var legacy_resource_path: String = legacy_audio_path.get_basename() + ".tres"

	_delete_cached_path(legacy_audio_path, source_path)
	_delete_cached_path(legacy_resource_path, source_path)


func _delete_cached_path(path: String, source_path: String = "") -> void:
	if path.is_empty():
		return

	if not path.begins_with("user://"):
		return

	if not source_path.is_empty() and path == source_path:
		return

	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _remove_orphan_cache_files() -> void:
	var valid_paths: Dictionary = {}
	for track: Dictionary in playlist:
		var resource_path: String = str(track.get("resource_path", ""))
		if not resource_path.is_empty():
			valid_paths[resource_path] = true

	var dir: DirAccess = DirAccess.open(MUSIC_CACHE_DIR)
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			var cache_path: String = _join_path(MUSIC_CACHE_DIR, file_name)
			if not valid_paths.has(cache_path):
				_drop_cached_stream(cache_path)
				DirAccess.remove_absolute(cache_path)
		file_name = dir.get_next()
	dir.list_dir_end()


func _apply_playlist_after_refresh(previous_source_path: String, previous_resource_path: String, changed_sources: Dictionary) -> void:
	if playlist.is_empty():
		current_index = 0
		if music.stream != MUSIC_FILE:  
			_load_fallback_track()
			if state == PLAY:
				music.play()
		return

	var same_track_found: bool = false
	var found_index: int = -1
	if not previous_source_path.is_empty():
		found_index = _find_track_index_by_source(previous_source_path)
		if found_index != -1:
			same_track_found = true
			current_index = found_index

	if not same_track_found:
		current_index = int(clamp(current_index, 0, playlist.size() - 1))

	var next_resource_path: String = _get_current_track_value("resource_path")
	var should_reload: bool = (
		not same_track_found
		or changed_sources.has(previous_source_path)
		or next_resource_path != previous_resource_path
		or music.stream == null
	)

	if should_reload:
		var should_resume: bool = state == PLAY
		music.stop()
		_load_current_track()
		if should_resume:
			music.play()
	else:
		update_track_name()
		_queue_stream_cache_refresh()


func _load_current_track() -> void:
	if playlist.is_empty():
		_load_fallback_track()
		return

	current_index = int(clamp(current_index, 0, playlist.size() - 1))
	var resource_path: String = _get_current_track_value("resource_path")
	var stream: AudioStream = _get_or_load_stream(resource_path)

	if stream != null:
		music.stream = stream
	else:
		print("Cached stream is missing or invalid: ", resource_path)
		music.stream = MUSIC_FILE

	update_track_name()
	_queue_stream_cache_refresh()


func _load_fallback_track() -> void:
	music.stop()
	music.stream = MUSIC_FILE
	_stream_cache.clear()
	update_track_name()


func _get_or_load_stream(resource_path: String) -> AudioStream:
	if resource_path.is_empty():
		return null

	var cached_stream: Variant = _stream_cache.get(resource_path, null)
	if cached_stream is AudioStream:
		return cached_stream as AudioStream

	if not FileAccess.file_exists(resource_path):
		return null

	var resource: Resource = ResourceLoader.load(resource_path, "", ResourceLoader.CACHE_MODE_REPLACE)
	if not (resource is AudioStream):
		return null

	var stream: AudioStream = resource as AudioStream
	_stream_cache[resource_path] = stream
	return stream


func _drop_cached_stream(resource_path: String) -> void:
	if resource_path.is_empty():
		return

	_stream_cache.erase(resource_path)


func _queue_stream_cache_refresh() -> void:
	if _stream_cache_refresh_queued:
		return

	_stream_cache_refresh_queued = true
	call_deferred("_refresh_stream_cache")


func _refresh_stream_cache() -> void:
	_stream_cache_refresh_queued = false

	if playlist.is_empty():
		_stream_cache.clear()
		return

	var wanted_paths: Dictionary = {}
	for offset: int in range(-STREAM_CACHE_RADIUS, STREAM_CACHE_RADIUS + 1):
		var track_index: int = _wrap_track_index(current_index + offset)
		if track_index == -1:
			continue

		var resource_path: String = _get_track_resource_path(track_index)
		if resource_path.is_empty():
			continue

		wanted_paths[resource_path] = true
		_get_or_load_stream(resource_path)

	_prune_stream_cache(wanted_paths)


func _prune_stream_cache(wanted_paths: Dictionary) -> void:
	var cached_paths: Array = _stream_cache.keys()
	for path_variant: Variant in cached_paths:
		var resource_path: String = str(path_variant)
		if not wanted_paths.has(resource_path):
			_stream_cache.erase(resource_path)


func _wrap_track_index(track_index: int) -> int:
	if playlist.is_empty():
		return -1

	var playlist_size: int = playlist.size()
	return ((track_index % playlist_size) + playlist_size) % playlist_size


func _get_track_resource_path(track_index: int) -> String:
	if track_index < 0 or track_index >= playlist.size():
		return ""

	var track: Dictionary = playlist[track_index]
	return str(track.get("resource_path", ""))


func update_track_name() -> void:
	if playlist.size() > 0 and current_index < playlist.size():
		var track: Dictionary = playlist[current_index]
		curTrack.set_track_name(str(track.get("name", MUSIC_FILE.resource_path.get_file().get_basename())))
	else:
		curTrack.set_track_name(MUSIC_FILE.resource_path.get_file().get_basename())


func _find_track_index_by_source(source_path: String) -> int:
	for index: int in range(playlist.size()):
		var track: Dictionary = playlist[index]
		if str(track.get("source_path", "")) == source_path:
			return index

	return -1


func _get_current_track_value(key: String) -> String:
	if current_index < 0 or current_index >= playlist.size():
		return ""

	var track: Dictionary = playlist[current_index]
	return str(track.get(key, ""))


func _get_cache_resource_path(file_info: Dictionary) -> String:
	var source_path: String = str(file_info["source_path"])
	var file_name: String = str(file_info["file_name"])
	var safe_name: String = _sanitize_cache_file_name(file_name.get_basename())
	var path_hash: int = int(abs(source_path.hash()))
	return _join_path(MUSIC_CACHE_DIR, safe_name + "_" + str(path_hash) + ".tres")


func _sanitize_cache_file_name(file_name: String) -> String:
	var result: String = file_name
	var invalid_characters: Array[String] = ["\\", "/", ":", "*", "?", "\"", "<", ">", "|", "[", "]", " "]
	for character: String in invalid_characters:
		result = result.replace(character, "_")

	if result.is_empty():
		return "track"

	return result


func _join_path(base_path: String, file_name: String) -> String:
	if base_path.ends_with("/") or base_path.ends_with("\\"):
		return base_path + file_name

	return base_path + "/" + file_name


func _ensure_music_cache_dir() -> void:
	if not DirAccess.dir_exists_absolute(MUSIC_CACHE_DIR):
		DirAccess.make_dir_recursive_absolute(MUSIC_CACHE_DIR)



func _show_loading_info(count: int) -> void:
	var all_files_count = DirAccess.get_files_at(FOLDER_PATH)
	var files_count = 0
	for f in all_files_count:
		if f.get_extension().to_lower() in str([SUPPORTED_AUDIO_EXTENSIONS]):
			files_count += 1
	
	loadingInfo.text = "Loading: " + str(count) + " / " + str(files_count)
	loadingInfo.visible = true


func _hide_loading_info() -> void:
	loadingInfo.visible = false

func _await_track_skip()-> void:
	nextTrack.disabled = true
	previousTrack.disabled = true
	await get_tree().create_timer(LOCK_TIME).timeout
	nextTrack.disabled = false
	previousTrack.disabled = false
	
func _on_next_track_pressed() -> void:
	if playlist.size() > 0:
		current_index = (current_index + 1) % playlist.size()
		music.stop()
		_load_current_track()
		update_state()
		_await_track_skip()

func _on_previous_track_pressed() -> void:
	if playlist.size() > 0:
		current_index = (current_index - 1 + playlist.size()) % playlist.size()
		music.stop()
		_load_current_track()
		update_state()
		nextTrack.disabled = true
		_await_track_skip()
		

func update_state() -> void:
	if state == PLAY:
		play_state()
	else:
		pause_state()


func play_state() -> void:
	music.stream_paused = false
	if not music.is_playing():
		music.play()
	$MainWindow/Buttons/PlayButton.position = Vector2(87.5, 130)
	$MainWindow/Buttons/PauseButton.position = Vector2(87.5, 0)
	nicoAnim()
	gramophone.animPlayer.play("Playing")


func pause_state() -> void:
	music.stream_paused = true
	$MainWindow/Buttons/PlayButton.position = Vector2(87.5, 0)
	$MainWindow/Buttons/PauseButton.position = Vector2(87.5, 130)
	niko.animPlayer.play("Sleeping")
	gramophone.animPlayer.pause()


func _on_stop_button_pressed() -> void:
	music.stop()
	if state == PLAY:
		state = PAUSE
	niko.animPlayer.play("Sleeping")
	gramophone.animPlayer.pause()
	update_state()


func _on_speed_control_slide_value_changed(_value: float) -> void:
	$MainWindow/PlaybackSpeedControlNode/SpeedValue.text = "Playback Speed: " + str(int(speedControl.speedControlSlide.value)) + "%"
	music.pitch_scale = speedControl.speedControlSlide.value / 100
	niko.animPlayer.speed_scale = speedControl.speedControlSlide.value / 100
	gramophone.animPlayer.speed_scale = speedControl.speedControlSlide.value / 100


func _on_volume_control_slide_value_changed(_value: float) -> void:
	music.volume_db = volumeControl.volumeControlSlide.value
	$MainWindow/VolumeControl/VolumeValue.text = "Volume: " + str(int(music.volume_db + 100)) + "%"
	if volumeControl.volumeControlSlide.value == -100:
		music.volume_db = -99999


func _on_reverse_button_pressed() -> void:
	if music.playing == true:
		music.play(0.0)
	else:
		music.stop()


func _on_speed_minus_pressed() -> void:
	music.pitch_scale -= 0.05
	speedControl.speedControlSlide.value = music.pitch_scale * 100


func _on_speed_plus_pressed() -> void:
	music.pitch_scale += 0.05
	speedControl.speedControlSlide.value = music.pitch_scale * 100


func _on_volume_minus_pressed() -> void:
	if music.volume_db >= -100:
		music.volume_db -= 1
		volumeControl.volumeControlSlide.value = music.volume_db
		$MainWindow/VolumeControl/VolumeValue.text = "Volume: " + str(music.volume_db + 100) + "%"
		if volumeControl.volumeControlSlide.value == -100:
			music.volume_db = -99999


func _on_volume_plus_pressed() -> void:
	if music.volume_db != 1:
		music.volume_db += 1
		volumeControl.volumeControlSlide.value = music.volume_db
		$MainWindow/VolumeControl/VolumeValue.text = "Volume: " + str(music.volume_db + 99) + "%"


func _on_play_button_pressed() -> void:
	state = PLAY
	update_state()


func _on_pause_button_pressed() -> void:
	state = PAUSE
	update_state()
