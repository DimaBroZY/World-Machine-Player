extends Control

# я DimaBroZY и я долбаеб

@onready var music: AudioStreamPlayer = $MainWindow/AudioStreamPlayer
@onready var curTrack: ScrollText = $MainWindow/CurrentTrack/PanelContainer/ScrollerControl
@onready var loadingInfo: Label = $MainWindow/LoadingInfo
@onready var niko = $MainWindow/Objects/Niko
@onready var gramophone = $MainWindow/Objects/Gramophone
@onready var loadingIcon = $MainWindow/Objects/Loading
@onready var volumeControl = $MainWindow/VolumeControl
@onready var speedControl = $MainWindow/PlaybackSpeedControlNode
@onready var nextTrack =$MainWindow/CurrentTrack/NextTrack
@onready var previousTrack = $MainWindow/CurrentTrack/PreviousTrack
@onready var notes: GPUParticles2D = $MainWindow/Objects/Gramophone/Notes
@onready var tracks_container = $MainWindow/CurrentTrack/TrackListPanel/TrackList/ScrollContainer/VBoxContainer
@onready var search_bar = $MainWindow/CurrentTrack/TrackListPanel/TrackList/LineEdit
@onready var local_button: Button = $MainWindow/CurrentTrack/TrackListPanel/PlaylistsAndModes/PlaylistTitleAndButtonsCotainer/ModeButtonsContainer/HBoxContainer/LocalButton
@onready var radio_button: Button = $MainWindow/CurrentTrack/TrackListPanel/PlaylistsAndModes/PlaylistTitleAndButtonsCotainer/ModeButtonsContainer/HBoxContainer/RadioButton
@onready var playlists_container: VBoxContainer = $MainWindow/CurrentTrack/TrackListPanel/PlaylistsAndModes/PlaylistTitleAndButtonsCotainer/PlaylistsScrollContainer/VBoxContainer
@onready var new_playlist_button: Button = $MainWindow/CurrentTrack/TrackListPanel/PlaylistsAndModes/PlaylistTitleAndButtonsCotainer/NewPlaylistButton
@onready var radio_player: AudioStreamPlayer = $MainWindow/RadioPlayer
@onready var play_button: Button = $MainWindow/Buttons/PlayButton
@onready var track_list_root = $MainWindow/CurrentTrack/TrackListPanel/TrackList
@onready var station_list_root = $MainWindow/CurrentTrack/TrackListPanel/StationList
@onready var stations_container = $MainWindow/CurrentTrack/TrackListPanel/StationList/ScrollContainer/VBoxContainer
@onready var stationInfo = $MainWindow/StationInfo
@onready var station_search_bar = $MainWindow/CurrentTrack/TrackListPanel/StationList/LineEdit

const DIRECTORY_WATCHER_SCRIPT = preload("res://addons/directory_watcher/DirectoryWatcher.gd")
const PLAY: int = 0
const PAUSE: int = 1
const MUSIC_CACHE_VERSION: int = 2
const MUSIC_CACHE_FILE: String = "user://music_cache.json"
const MUSIC_CACHE_DIR: String = "user://music_cache"
const MUSIC_CACHE_RESOURCE_EXTENSION: String = "res"
const MUSIC_FOLDER_WATCH_SCAN_DELAY: float = 1.0
const MUSIC_FOLDER_WATCH_SCAN_STEP: int = 20
const MUSIC_FOLDER_REFRESH_DEBOUNCE: float = 2.25
const MIN_FILE_AGE_SECONDS: int = 2
const STREAM_CACHE_RADIUS: int = 1
const SUPPORTED_AUDIO_EXTENSIONS: Array[String] = ["ogg", "mp3", "flac", "opus"]
const LOCK_TIME: float = 0.0
const TRACK_ITEM = preload("res://scenes/trackitem.tscn")
const PLAYLIST_ITEM = preload("res://scenes/playlist.tscn")
const RADIO_STATIONS: Array[Dictionary] = [
	{"name": "MoE LoFi (ZenoFM)", "url": "http://stream.zeno.fm/3u1qndyk8rhvv"},
	{"name": "LoFi (Lofi 24/7)", "url": "http://usa9.fastcast4u.com/proxy/jamz?mp=/1"},
	{"name": "Vaporwaves (SomaFM)", "url": "https://ice3.somafm.com/vaporwaves-128-mp3"},
	{"name": "Phonk (badradio)", "url": "https://s2.radio.co/s2b2b68744/listen"},
	{"name": "Classic (walmradio)", "url": "https://icecast.walmradio.com:8443/classic"},
	{"name": "Radio «GamePlay»", "url": "https://c22.radioboss.fm:8144/GamePlay"},
	{"name": "Vocaloids (Mikupa)", "url": "http://aska.ru-hoster.com:8093/mikuparu"},
	{"name": "Vocaloids (Vocaloid Radio)", "url": "http://curiosity.shoutca.st:8019/stream"},
]


static var mode_button_group: ButtonGroup
var _showing_radio_mode: bool = false
var _local_track_list_cache: Array[Dictionary] = []
var _local_track_list_cache_valid: bool = false
var _rebuilding_playlist_ui: bool = false



var MUSIC_FILE: AudioStream = preload("res://music/Prelude.mp3")

var state: int = PAUSE
var playlist: Array[Dictionary] = []
var current_index: int = 0
var _shuffle_history: Array[int] = []
var _shuffle_pos: int = -1
var FOLDER_PATH: String
var _music_cache: Dictionary = {}
var _stream_cache: Dictionary = {}
var _is_loading_tracks: bool = false
var _last_music_scan_ok: bool = false
var _stream_cache_refresh_queued: bool = false
var _music_folder_watcher
var _music_folder_refresh_queued: bool = false
var _music_folder_refresh_requested: bool = false
var volume_percent: float = 100.0
var full_playlist: Array = []
var search_query: String = ""
var _checked_track_source_path: String = ""

var current_source: PlaybackSource
var _local_source: LocalPlaybackSource
var _radio_source: RadioPlaybackSource
var _radio: RadioStreamer
var _current_station_index: int = 0
var _radio_buffering: bool = false
var _radio_unavailable: bool = false
var _station_search_query: String = ""

func _ready() -> void:
	EventBus.setWorldMachine.connect(_set_world_machine)
	EventBus.noteEnabling.connect(_enable_notes)
	EventBus.highPriority.connect(_set_high_priority)
	loadingInfo.visible = false
	FOLDER_PATH = str(Settings.get_setting("music_path", "user://music"))
	Settings.setting_changed.connect(_on_setting_changed)

	volume_percent = volumeControl.volumeControlSlide.value
	set_volume(volume_percent)
	
	await load_tracks_from_folder(true)

	_setup_mode_buttons()
	_setup_playlist_ui()
	PlaylistManager.playlists_changed.connect(_on_playlists_structure_changed)
	PlaylistManager.playlist_tracks_changed.connect(_on_playlist_tracks_changed)
	PlaylistManager.active_playlist_changed.connect(_on_active_playlist_changed)
	new_playlist_button.pressed.connect(_on_new_playlist_button_pressed)

	_radio = RadioStreamer.new()
	add_child(_radio)
	_radio.setup(radio_player)
	_radio.buffering_changed.connect(func(is_buffering: bool):
		_radio_buffering = is_buffering
		if _showing_radio_mode:
			loadingIcon.visible = is_buffering
			if not is_buffering:
				_refresh_station_list()
		_enable_notes()
		_update_niko_state()
		_update_gramaphone_state()
	)

	_radio.station_unavailable.connect(func(is_unavailable: bool):
		_radio_unavailable = is_unavailable
		if _showing_radio_mode:
			stationInfo.visible = is_unavailable
		_enable_notes()
		_update_niko_state()
		_update_gramaphone_state()
	)
	stationInfo.visible = false
	station_search_bar.text_changed.connect(_on_station_search_text_changed)
	
	_local_source = LocalPlaybackSource.new(self)
	_radio_source = RadioPlaybackSource.new(_radio)
	current_source = _local_source
	_radio.set_station(str(RADIO_STATIONS[_current_station_index]["url"]))

	_apply_active_playlist_filter()
	
	_create_music_folder_watcher()
	update_state()
	_set_world_machine()
	_enable_notes()
	
	# Меняем приоритет при запуске только если он включен в настройках
	if Settings.get_setting("highPriority", false):
		_set_high_priority()

func _set_high_priority() -> void:
	if OS.get_name() == "Windows":
		var is_enabled = Settings.get_setting("highPriority", false)
		var pid = OS.get_process_id()
		
		var priority_level = "High" if is_enabled else "Normal"
		var command = "(Get-Process -Id %d).PriorityClass = '%s'" % [pid, priority_level]
		var args = ["-Command", command]
		
		var output = []
		var exit_code = OS.execute("powershell", args, output, false, true)
		
		if exit_code == 0:
			print("Приоритет процесса успешно изменен на: ", priority_level)
		else:
			print("Не удалось изменить приоритет. Код ошибки: ", exit_code)



func _set_world_machine() -> void:
		if Settings.get_setting("worldMachineTheme") == true:
			niko.material = preload("res://materials/world_machine_material.tres")
			niko.modulate = Color(1.0, 1.0, 1.0, 0.75)
		else:
			niko.material = null
			niko.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _enable_notes() -> void:
	var enabled = Settings.get_setting("noteEnabled")
	if enabled == null:
		enabled = true
		Settings.save_setting("noteEnabled", enabled)
	var radio_blocked := _showing_radio_mode and (_radio_buffering or _radio_unavailable)
	notes.emitting = enabled and (state == PLAY) and not radio_blocked
	
func _update_gramaphone_state() -> void:
	if state != PLAY:
		return
	var radio_blocked := _showing_radio_mode and (_radio_buffering or _radio_unavailable)
	if radio_blocked:
		gramophone.animPlayer.pause()
	else:
		gramophone.animPlayer.play("Playing")
	
func _update_niko_state() -> void:
	if state != PLAY:
		return
	var radio_blocked := _showing_radio_mode and (_radio_buffering or _radio_unavailable)
	if radio_blocked:
		niko.animPlayer.play("Sleeping")
	else:
		nicoAnim()
	
func nicoAnim() -> void:
	if randi_range(1, 2) == 1:
		niko.animPlayer.play("Dancing")
	else:
		niko.animPlayer.play("Dance_Sitting")


func _on_audio_stream_player_finished() -> void:
	if Settings.get_setting("EndOfTrackAction") == false:
		music.play(0.0)
	else:
		_on_next_track_pressed()


func _on_setting_changed(key: String, value: Variant) -> void:
	if key == "music_path":
		FOLDER_PATH = str(value)
		current_index = 0
		_create_music_folder_watcher()
		await load_tracks_from_folder(true)
		update_state()


func _create_music_folder_watcher() -> void:
	if _music_folder_watcher != null:
		_music_folder_watcher.queue_free()
		_music_folder_watcher = null

	if DirAccess.open(FOLDER_PATH) == null:
		return

	_music_folder_watcher = DIRECTORY_WATCHER_SCRIPT.new()
	_music_folder_watcher.scan_delay = MUSIC_FOLDER_WATCH_SCAN_DELAY
	_music_folder_watcher.scan_step = MUSIC_FOLDER_WATCH_SCAN_STEP
	_music_folder_watcher.files_created.connect(_on_music_folder_files_changed)
	_music_folder_watcher.files_modified.connect(_on_music_folder_files_changed)
	_music_folder_watcher.files_deleted.connect(_on_music_folder_files_changed)
	add_child(_music_folder_watcher)
	_music_folder_watcher.add_scan_directory(FOLDER_PATH)


func _on_music_folder_files_changed(files: PackedStringArray) -> void:
	if _contains_supported_audio_file(files):
		_queue_music_folder_refresh()


func _contains_supported_audio_file(paths: PackedStringArray) -> bool:
	for path: String in paths:
		if _is_supported_audio_file(path):
			return true

	return false


func _queue_music_folder_refresh() -> void:
	_music_folder_refresh_requested = true
	if _music_folder_refresh_queued:
		return

	_music_folder_refresh_queued = true
	call_deferred("_run_music_folder_refresh_queue")


func _run_music_folder_refresh_queue() -> void:
	while _music_folder_refresh_requested:
		_music_folder_refresh_requested = false
		await get_tree().create_timer(MUSIC_FOLDER_REFRESH_DEBOUNCE).timeout
		if _is_loading_tracks:
			_music_folder_refresh_requested = true
			await get_tree().process_frame
			continue

		await load_tracks_from_folder(false)

	_music_folder_refresh_queued = false


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
	full_playlist = refreshed_playlist.duplicate()
	_local_track_list_cache_valid = false
	_remove_orphan_cache_files()
	_save_music_cache()
	_apply_playlist_after_refresh(previous_source_path, previous_resource_path, changed_sources)

	_apply_active_playlist_filter(true)

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

	if resource_path.get_extension().to_lower() != MUSIC_CACHE_RESOURCE_EXTENSION:
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
	return _join_path(MUSIC_CACHE_DIR, safe_name + "_" + str(path_hash) + "." + MUSIC_CACHE_RESOURCE_EXTENSION)


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
	#loadingInfo.visible = true
	loadingIcon.visible = true


func _hide_loading_info() -> void:
	#loadingInfo.visible = false
	loadingIcon.visible = false
	
func _await_track_skip()-> void:
	nextTrack.disabled = true
	previousTrack.disabled = true
	await get_tree().create_timer(LOCK_TIME).timeout
	nextTrack.disabled = false
	previousTrack.disabled = false


func _on_next_track_pressed() -> void:
	if _showing_radio_mode:
		return
	if playlist.size() > 0:
		if Settings.get_setting("shuffle"):
			if _shuffle_history.is_empty():
				_shuffle_history.append(current_index)
				_shuffle_pos = 0
			if _shuffle_pos < _shuffle_history.size() - 1:
				_shuffle_pos += 1
				current_index = _shuffle_history[_shuffle_pos]
			else:
				var next_index := randi() % playlist.size()
				if playlist.size() > 1:
					while next_index == current_index:
						next_index = randi() % playlist.size()
				current_index = next_index
				_shuffle_history.append(current_index)
				_shuffle_pos = _shuffle_history.size() - 1
		else:
			current_index = (current_index + 1) % playlist.size()
		music.stop()
		_load_current_track()
		update_state()
		_await_track_skip()


func _on_previous_track_pressed() -> void:
	if _showing_radio_mode:
		return
	if playlist.size() > 0:
		if Settings.get_setting("shuffle") and _shuffle_pos > 0:
			_shuffle_pos -= 1
			current_index = _shuffle_history[_shuffle_pos]
		elif not Settings.get_setting("shuffle"):
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
	current_source.play()
	gramophone.animPlayer.play("Playing")
	_enable_notes()
	_update_niko_state()
	_update_gramaphone_state()

func pause_state() -> void:
	current_source.pause()
	niko.animPlayer.play("Sleeping")
	gramophone.animPlayer.pause()
	play_button.button_pressed = false
	_enable_notes()

func _on_stop_button_pressed() -> void:
	current_source.stop()
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
	notes.speed_scale = speedControl.speedControlSlide.value / 100

func set_volume(percent: float) -> void:
	volume_percent = clamp(percent, 0.0, 100.0)

	music.volume_db = linear_to_db(volume_percent / 100.0)
	radio_player.volume_db = linear_to_db(volume_percent / 100.0)
	
	# синхронизация UI
	volumeControl.volumeControlSlide.value = volume_percent
	$MainWindow/VolumeControl/VolumeValue.text = "Volume: " + str(int(volume_percent)) + "%"

func _on_volume_control_slide_value_changed(value: float) -> void:
	set_volume(value)

	notes.amount = int(round(lerp(1.0, 6.0, volume_percent / 100.0)))

func _on_reverse_button_pressed() -> void:
	if _showing_radio_mode:
		return
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


func percent_to_db(percent: float) -> float:
	if percent <= 0.0:
		return -80.0 
	return linear_to_db(percent / 100.0)

func _on_volume_minus_pressed() -> void:
	set_volume(volume_percent - 5.0)

func _on_volume_plus_pressed() -> void:
	set_volume(volume_percent + 5.0)


func _on_play_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		state = PLAY
		update_state()
	else:
		state = PAUSE
		update_state()



func _setup_mode_buttons() -> void:
	mode_button_group = ButtonGroup.new()
	mode_button_group.allow_unpress = false
	local_button.button_group = mode_button_group
	radio_button.button_group = mode_button_group
	local_button.toggle_mode = true
	radio_button.toggle_mode = true
	local_button.button_pressed = true
	local_button.toggled.connect(_on_local_button_toggled)
	radio_button.toggled.connect(_on_radio_button_toggled)


func _setup_playlist_ui() -> void:
	_refresh_playlist_ui()


func _on_playlists_structure_changed() -> void:
	_refresh_playlist_ui()
	_apply_active_playlist_filter()


func _refresh_playlist_ui() -> void:
	_rebuilding_playlist_ui = true
	for child in playlists_container.get_children():
		child.queue_free()

	for playlist_data: Dictionary in PlaylistManager.playlists:
		var playlist_id := str(playlist_data.get("id", ""))
		var item: Button = PLAYLIST_ITEM.instantiate()
		playlists_container.add_child(item)
		item.configure_for_main(
			playlist_id,
			str(playlist_data.get("name", "Playlist")),
			playlist_id == PlaylistManager.active_playlist_id
		)
		item.playlist_selected.connect(_on_playlist_selected)
		item.playlist_deselected.connect(_on_playlist_deselected)
		item.playlist_deleted.connect(_on_playlist_deleted)
		item.playlist_renamed.connect(_on_playlist_renamed)
	_rebuilding_playlist_ui = false


func _sync_playlist_button_states() -> void:
	for child in playlists_container.get_children():
		if not child.has_method("get_playlist_id") or not child.has_method("set_pressed_silent"):
			continue
		var is_active := str(child.get_playlist_id()) == PlaylistManager.active_playlist_id
		child.set_pressed_silent(is_active)


func _on_new_playlist_button_pressed() -> void:
	PlaylistManager.create_playlist(PlaylistManager.get_next_playlist_name())


func _on_playlist_selected(playlist_id: String) -> void:
	PlaylistManager.set_active_playlist(playlist_id)


func _on_playlist_deselected() -> void:
	if _rebuilding_playlist_ui:
		return
	PlaylistManager.clear_active_playlist()


func _on_playlist_deleted(playlist_id: String) -> void:
	PlaylistManager.delete_playlist(playlist_id)


func _on_playlist_renamed(playlist_id: String, new_name: String) -> void:
	PlaylistManager.rename_playlist(playlist_id, new_name)
	for child in playlists_container.get_children():
		if child.has_method("get_playlist_id") and child.get_playlist_id() == playlist_id:
			child.set_playlist_name(new_name)
			if child.has_method("set_pressed_silent"):
				child.set_pressed_silent(false)
			break
	if PlaylistManager.active_playlist_id == playlist_id:
		PlaylistManager.clear_active_playlist()


func _on_playlist_tracks_changed(playlist_id: String) -> void:
	if PlaylistManager.active_playlist_id == playlist_id:
		_apply_active_playlist_filter(true)


func set_checked_track_source_path(source_path: String) -> void:
	_checked_track_source_path = source_path


func _on_active_playlist_changed(_playlist_id: String) -> void:
	_sync_playlist_button_states()
	_apply_active_playlist_filter()


func _on_local_button_toggled(is_pressed: bool) -> void:
	if not is_pressed:
		return
	if _showing_radio_mode:
		current_source.stop()
		current_source = _local_source
		_showing_radio_mode = false
		loadingIcon.visible = false
		stationInfo.visible = false
		_apply_active_playlist_filter()
		update_track_name()
		if state == PLAY:
			current_source.play()

func _on_radio_button_toggled(is_pressed: bool) -> void:
	if not is_pressed:
		return
	if not _showing_radio_mode:
		current_source.stop()
		current_source = _radio_source
		_showing_radio_mode = true
		_apply_active_playlist_filter()
		_refresh_station_list()

		var station: Dictionary = RADIO_STATIONS[_current_station_index]
		_radio.set_station(str(station["url"]))
		curTrack.set_track_name(str(station["name"]))

		if state == PLAY:
			current_source.play()


func _compute_local_playlist() -> Array[Dictionary]:
	var base_playlist: Array[Dictionary] = []
	if PlaylistManager.active_playlist_id.is_empty():
		base_playlist = full_playlist.duplicate()
	else:
		var track_paths := PlaylistManager.get_playlist_track_paths(PlaylistManager.active_playlist_id)
		for track: Dictionary in full_playlist:
			if track_paths.has(str(track.get("source_path", ""))):
				base_playlist.append(track)

	if search_query.strip_edges() == "":
		return base_playlist

	var filtered_playlist: Array[Dictionary] = []
	for track: Dictionary in base_playlist:
		var track_name := str(track.get("name", "")).to_lower()
		var file_name := str(track.get("file_name", "")).to_lower()
		if search_query in track_name or search_query in file_name:
			filtered_playlist.append(track)
	return filtered_playlist


func _playlists_have_same_tracks(left: Array, right: Array) -> bool:
	if left.size() != right.size():
		return false
	for index: int in range(left.size()):
		if str(left[index].get("source_path", "")) != str(right[index].get("source_path", "")):
			return false
	return true


func _apply_active_playlist_filter(force_refresh: bool = false) -> void:
	if _showing_radio_mode:
		track_list_root.visible = false
		station_list_root.visible = true
		return

	track_list_root.visible = true
	station_list_root.visible = false

	if not playlist.is_empty() and current_index >= 0 and current_index < playlist.size():
		_checked_track_source_path = str(playlist[current_index].get("source_path", ""))
	elif _checked_track_source_path.is_empty() and not playlist.is_empty():
		_checked_track_source_path = str(playlist[current_index].get("source_path", ""))

	var next_playlist := _compute_local_playlist()
	var ui_is_empty := tracks_container.get_child_count() == 0
	if not force_refresh and not ui_is_empty and _playlists_have_same_tracks(playlist, next_playlist):
		return

	playlist = next_playlist
	_local_track_list_cache = next_playlist.duplicate()
	_local_track_list_cache_valid = true
	_shuffle_history.clear()
	_shuffle_pos = -1

	var found_index := _find_track_index_by_source(_checked_track_source_path)
	if found_index >= 0:
		current_index = found_index
	elif not playlist.is_empty():
		current_index = 0
		_checked_track_source_path = str(playlist[0].get("source_path", ""))
	else:
		current_index = 0

	refresh_track_list()


func refresh_track_list() -> void:
	for child in tracks_container.get_children():
		child.queue_free()

	if playlist.is_empty():
		return

	if _checked_track_source_path.is_empty():
		current_index = int(clamp(current_index, 0, playlist.size() - 1))
		_checked_track_source_path = str(playlist[current_index].get("source_path", ""))
	else:
		var found_index := _find_track_index_by_source(_checked_track_source_path)
		if found_index >= 0:
			current_index = found_index
		else:
			current_index = int(clamp(current_index, 0, playlist.size() - 1))
			_checked_track_source_path = str(playlist[current_index].get("source_path", ""))

	for i in range(playlist.size()):
		var track: Dictionary = playlist[i]
		var button: Button = TRACK_ITEM.instantiate()
		tracks_container.add_child(button)
		if button.has_method("setup"):
			button.setup(track, i)
		if button.has_method("set_checkbox_pressed"):
			var source_path := str(track.get("source_path", ""))
			button.set_checkbox_pressed(source_path == _checked_track_source_path)

		var idx := i
		button.pressed.connect(
			func():
				play_track_by_index(idx)
		)


func _sync_track_checkboxes(source_path: String) -> void:
	for child: Node in tracks_container.get_children():
		if child.has_method("get_track_source_path") and child.has_method("set_checkbox_pressed"):
			child.set_checkbox_pressed(child.get_track_source_path() == source_path)


func play_track_by_index(index: int) -> void:
	if index < 0 or index >= playlist.size():
		return

	current_index = index
	_shuffle_history.clear()
	_shuffle_pos = -1
	_checked_track_source_path = str(playlist[index].get("source_path", ""))
	_sync_track_checkboxes(_checked_track_source_path)

	music.stop()

	_load_current_track()

	if state == PLAY:
		music.play()

	update_state()
	
func _on_line_edit_text_changed(text: String) -> void:
	apply_search(text)
	
func apply_search(query: String) -> void:
	search_query = query.to_lower()
	_apply_active_playlist_filter()

func _refresh_station_list() -> void:
	for child in stations_container.get_children():
		child.queue_free()

	for i in range(RADIO_STATIONS.size()):
		var station: Dictionary = RADIO_STATIONS[i]
		var station_name := str(station["name"])

		if not _station_search_query.is_empty() and not station_name.to_lower().contains(_station_search_query):
			continue

		var item: Button = TRACK_ITEM.instantiate()
		stations_container.add_child(item)

		item.setup({"name": station_name, "source_path": ""}, i)

		item.check_box.visible = false
		item.add_to_playlist_button.visible = false
		item.disabled = _radio.is_switching()

		item.pressed.disconnect(Callable(item, "_on_track_pressed"))

		var idx := i
		item.pressed.connect(func():
			_select_station(idx)
		)
		
func _select_station(index: int) -> void:
	if index < 0 or index >= RADIO_STATIONS.size():
		return
	if _radio.is_switching():
		return

	_current_station_index = index
	var station: Dictionary = RADIO_STATIONS[index]
	_radio.set_station(str(station["url"]))
	curTrack.set_track_name(str(station["name"]))
	_refresh_station_list()

	if _showing_radio_mode and state == PLAY and not _radio.is_active():
		_radio.start()

func _on_station_search_text_changed(text: String) -> void:
	_station_search_query = text.to_lower()
	_refresh_station_list()
