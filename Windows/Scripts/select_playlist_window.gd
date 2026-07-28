extends Window

const PLAYLIST_ITEM := preload("res://scenes/playlist.tscn")

@onready var playlists_container: VBoxContainer = $SelectPlaylistWindow/Layout/Main/ScrollContainer/VBoxContainer
@onready var ok_button: Button = $SelectPlaylistWindow/Layout/Main/ButtonsContainer/Buttons/OkButton
@onready var cancel_button: Button = $SelectPlaylistWindow/Layout/Main/ButtonsContainer/Buttons/CancelButton
@onready var close_button: Button = $SelectPlaylistWindow/Layout/TopBar/HBox/CloseButton

var pending_track_paths: Array[String] = []


func _ready() -> void:
	exclusive = true
	visible = false
	close_requested.connect(_on_cancel)
	ok_button.pressed.connect(_on_ok_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	for connection: Dictionary in close_button.pressed.get_connections():
		close_button.pressed.disconnect(connection["callable"])
	close_button.pressed.connect(_on_cancel_pressed)
	PlaylistManager.playlists_changed.connect(_refresh_playlists)
	PlaylistManager.playlist_renamed.connect(_on_playlist_renamed)


func _on_playlist_renamed(playlist_id: String, new_name: String) -> void:
	for child: Node in playlists_container.get_children():
		if child.has_method("get_playlist_id") and child.get_playlist_id() == playlist_id:
			child.set_playlist_name(new_name)
			break


func open_with_tracks(source_paths: Array) -> void:
	pending_track_paths.clear()
	for source_path: Variant in source_paths:
		var normalized_path := str(source_path)
		if not normalized_path.is_empty():
			pending_track_paths.append(normalized_path)

	_refresh_playlists()
	WindowManager.set_modal_open(true)
	show()
	grab_focus()
	TintManager.apply_tint_to_scene()


func _refresh_playlists() -> void:
	for child: Node in playlists_container.get_children():
		child.queue_free()

	for playlist: Dictionary in PlaylistManager.playlists:
		var item: Button = PLAYLIST_ITEM.instantiate()
		playlists_container.add_child(item)
		item.configure_for_select(
			str(playlist.get("id", "")),
			str(playlist.get("name", "Playlist")),
			pending_track_paths
		)


func _collect_selected_playlist_ids() -> Array[String]:
	var selected_ids: Array[String] = []
	for child: Node in playlists_container.get_children():
		if not child.has_method("is_checkbox_checked"):
			continue
		if child.is_checkbox_checked():
			selected_ids.append(child.get_playlist_id())
	return selected_ids


func _on_ok_pressed() -> void:
	var selected_ids := _collect_selected_playlist_ids()
	for playlist: Dictionary in PlaylistManager.playlists:
		var playlist_id := str(playlist.get("id", ""))
		if selected_ids.has(playlist_id):
			PlaylistManager.add_tracks_to_playlist(playlist_id, pending_track_paths)
		else:
			PlaylistManager.remove_tracks_from_playlist(playlist_id, pending_track_paths)
	close_animation()


func _on_cancel_pressed() -> void:
	close_animation()


func _on_cancel() -> void:
	close_animation()


func _close() -> void:
	hide()
	WindowManager.set_modal_open(false)

func close_animation():
	var win := get_window()

	var start_pos := win.position
	var screen_size := DisplayServer.screen_get_size()
	var offscreen_y := screen_size.y + 150

	var tween := create_tween()

	tween.tween_property(
		win,
		"position",
		start_pos + Vector2i(0, -100),
		0.25
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		win,
		"position",
		Vector2i(start_pos.x, offscreen_y),
		0.3
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


	await tween.finished

	_close()
