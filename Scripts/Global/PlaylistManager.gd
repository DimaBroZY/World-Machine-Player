extends Node

signal playlists_changed
signal playlist_renamed(playlist_id: String, new_name: String)
signal playlist_tracks_changed(playlist_id: String)
signal active_playlist_changed(playlist_id: String)

const PLAYLISTS_FILE: String = "user://playlists.json"

var playlists: Array[Dictionary] = []
var active_playlist_id: String = ""


func _ready() -> void:
	load_playlists()
	if playlists.is_empty():
		create_playlist("Playlist 1")


func load_playlists() -> void:
	playlists.clear()
	active_playlist_id = ""

	if not FileAccess.file_exists(PLAYLISTS_FILE):
		return

	var file := FileAccess.open(PLAYLISTS_FILE, FileAccess.READ)
	if file == null:
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	var saved_playlists: Variant = parsed.get("playlists", [])
	if typeof(saved_playlists) == TYPE_ARRAY:
		for entry: Variant in saved_playlists:
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var tracks: Array[String] = []
			var saved_tracks: Variant = entry.get("tracks", [])
			if typeof(saved_tracks) == TYPE_ARRAY:
				for track_path: Variant in saved_tracks:
					tracks.append(str(track_path))
			playlists.append({
				"id": str(entry.get("id", "")),
				"name": str(entry.get("name", "Playlist")),
				"tracks": tracks,
			})

	active_playlist_id = str(parsed.get("active_playlist_id", ""))
	if not active_playlist_id.is_empty() and not _has_playlist(active_playlist_id):
		active_playlist_id = ""


func save_playlists() -> void:
	var serialized_playlists: Array = []
	for playlist: Dictionary in playlists:
		serialized_playlists.append({
			"id": str(playlist.get("id", "")),
			"name": str(playlist.get("name", "Playlist")),
			"tracks": playlist.get("tracks", []),
		})

	var data := {
		"playlists": serialized_playlists,
		"active_playlist_id": active_playlist_id,
	}
	var file := FileAccess.open(PLAYLISTS_FILE, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func create_playlist(name: String) -> String:
	var playlist_id := "%d_%d" % [Time.get_unix_time_from_system(), randi()]
	playlists.append({
		"id": playlist_id,
		"name": name,
		"tracks": [],
	})
	save_playlists()
	playlists_changed.emit()
	return playlist_id


func rename_playlist(playlist_id: String, new_name: String) -> void:
	var playlist := get_playlist(playlist_id)
	if playlist.is_empty():
		return
	playlist["name"] = new_name.strip_edges()
	save_playlists()
	playlist_renamed.emit(playlist_id, new_name.strip_edges())


func delete_playlist(playlist_id: String) -> void:
	var delete_index := -1
	for index: int in range(playlists.size()):
		if str(playlists[index].get("id", "")) == playlist_id:
			delete_index = index
			break
	if delete_index < 0:
		return

	playlists.remove_at(delete_index)
	if active_playlist_id == playlist_id:
		active_playlist_id = ""
		active_playlist_changed.emit(active_playlist_id)
	save_playlists()
	playlists_changed.emit()


func clear_active_playlist() -> void:
	if active_playlist_id.is_empty():
		return
	active_playlist_id = ""
	save_playlists()
	active_playlist_changed.emit(active_playlist_id)


func set_active_playlist(playlist_id: String) -> void:
	if not _has_playlist(playlist_id):
		return
	if active_playlist_id == playlist_id:
		return
	active_playlist_id = playlist_id
	save_playlists()
	active_playlist_changed.emit(playlist_id)


func get_playlist(playlist_id: String) -> Dictionary:
	for playlist: Dictionary in playlists:
		if str(playlist.get("id", "")) == playlist_id:
			return playlist
	return {}


func get_active_playlist() -> Dictionary:
	return get_playlist(active_playlist_id)


func get_playlist_track_paths(playlist_id: String) -> Array[String]:
	var playlist := get_playlist(playlist_id)
	var tracks: Array[String] = []
	var saved_tracks: Variant = playlist.get("tracks", [])
	if typeof(saved_tracks) == TYPE_ARRAY:
		for track_path: Variant in saved_tracks:
			tracks.append(str(track_path))
	return tracks


func add_tracks_to_playlist(playlist_id: String, source_paths: Array) -> void:
	var playlist := get_playlist(playlist_id)
	if playlist.is_empty():
		return

	var tracks: Array = playlist.get("tracks", [])
	for source_path: Variant in source_paths:
		var normalized_path := str(source_path)
		if normalized_path.is_empty() or tracks.has(normalized_path):
			continue
		tracks.append(normalized_path)
	playlist["tracks"] = tracks
	save_playlists()
	playlist_tracks_changed.emit(playlist_id)


func remove_tracks_from_playlist(playlist_id: String, source_paths: Array) -> void:
	var playlist := get_playlist(playlist_id)
	if playlist.is_empty():
		return

	var tracks: Array = playlist.get("tracks", [])
	var changed: bool = false
	for source_path: Variant in source_paths:
		var normalized_path := str(source_path)
		if normalized_path.is_empty():
			continue
		var track_index := tracks.find(normalized_path)
		if track_index >= 0:
			tracks.remove_at(track_index)
			changed = true
	if not changed:
		return
	playlist["tracks"] = tracks
	save_playlists()
	playlist_tracks_changed.emit(playlist_id)


func playlist_contains_all_tracks(playlist_id: String, source_paths: Array) -> bool:
	if source_paths.is_empty():
		return false
	var playlist_paths := get_playlist_track_paths(playlist_id)
	for source_path: Variant in source_paths:
		if not playlist_paths.has(str(source_path)):
			return false
	return true


func get_next_playlist_name() -> String:
	var index := playlists.size() + 1
	var candidate := "Playlist %d" % index
	while _playlist_name_exists(candidate):
		index += 1
		candidate = "Playlist %d" % index
	return candidate


func _has_playlist(playlist_id: String) -> bool:
	return not get_playlist(playlist_id).is_empty()


func _playlist_name_exists(name: String) -> bool:
	for playlist: Dictionary in playlists:
		if str(playlist.get("name", "")) == name:
			return true
	return false
