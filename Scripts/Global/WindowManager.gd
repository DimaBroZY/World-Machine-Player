extends Node

var settings_window = null
var theme_window = null
var secret_settings_window = null
var select_playlist_window = null
var add_radio_window = null

const SELECT_PLAYLIST_WINDOW_SCENE := preload("res://Windows/SelectPlaylistWindow.tscn")
const ADD_RADIO_WINDOW_SCENE := preload("res://Windows/AddRadioWindow.tscn")

var _input_blockers: Array[Control] = []
var _modal_open: bool = false


func open_select_playlist_window(source_paths: Array) -> void:
	if select_playlist_window == null or not is_instance_valid(select_playlist_window):
		select_playlist_window = SELECT_PLAYLIST_WINDOW_SCENE.instantiate()
		get_tree().root.add_child(select_playlist_window)

	select_playlist_window.open_with_tracks(source_paths)


func set_modal_open(is_open: bool) -> void:
	if _modal_open == is_open:
		return

	_modal_open = is_open
	if is_open:
		_add_input_blockers()
	else:
		_remove_input_blockers()


func _add_input_blockers() -> void:
	_remove_input_blockers()

	var main_node := get_tree().root.get_node_or_null("Main")
	if main_node is Control:
		_input_blockers.append(_create_blocker(main_node))


func _remove_input_blockers() -> void:
	for blocker: Control in _input_blockers:
		if is_instance_valid(blocker):
			blocker.queue_free()
	_input_blockers.clear()


func _create_blocker(parent: Control) -> Control:
	var blocker := Control.new()
	blocker.name = "ModalInputBlocker"
	blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker.focus_mode = Control.FOCUS_ALL
	parent.add_child(blocker)
	blocker.move_to_front()
	return blocker

func open_add_radio_window() -> void:
	if add_radio_window == null or not is_instance_valid(add_radio_window):
		add_radio_window = ADD_RADIO_WINDOW_SCENE.instantiate()
		get_tree().root.add_child(add_radio_window)
	add_radio_window.open_dialog()
