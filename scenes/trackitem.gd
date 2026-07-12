extends Button

signal add_to_playlist_requested(source_paths: Array)

@onready var scroll_text: ScrollText = $ScrollText
@onready var scroll_label: Label = $ScrollText/Label
@onready var check_box: CheckBox = $CheckBox
@onready var add_to_playlist_button: TextureButton = $AddToPlaylistButton

var track_source_path: String = ""
var track_index: int = -1
var _ignore_checkbox_sync: bool = false


func setup(track: Dictionary, index: int) -> void:
	track_source_path = str(track.get("source_path", ""))
	track_index = index
	_set_display_name(str(track.get("name", "Unknown Track")))


func _set_display_name(track_name: String) -> void:
	if scroll_text is ScrollText:
		scroll_text.set_track_name(track_name)
	else:
		scroll_label.text = track_name


func _ready() -> void:
	check_box.toggled.connect(_on_check_box_toggled)
	pressed.connect(_on_track_pressed)
	add_to_playlist_button.pressed.connect(_on_add_to_playlist_pressed)


func _on_track_pressed() -> void:
	_apply_single_checkbox_selection()


@warning_ignore("shadowed_variable_base_class")
func _on_check_box_toggled(pressed: bool) -> void:
	if _ignore_checkbox_sync:
		return
	if not pressed and _count_checked_siblings() == 0:
		_ignore_checkbox_sync = true
		check_box.button_pressed = true
		_ignore_checkbox_sync = false


func _on_add_to_playlist_pressed() -> void:
	var selected_paths := _resolve_add_to_playlist_paths()
	if selected_paths.is_empty():
		return
	add_to_playlist_requested.emit(selected_paths)
	WindowManager.open_select_playlist_window(selected_paths)
	get_viewport().set_input_as_handled()


func _resolve_add_to_playlist_paths() -> Array[String]:
	var checked_paths := _collect_checked_source_paths()
	if checked_paths.size() > 1:
		return checked_paths
	if checked_paths.size() == 1 and checked_paths[0] == track_source_path:
		return checked_paths
	if not track_source_path.is_empty():
		return [track_source_path]
	return checked_paths


func _apply_single_checkbox_selection() -> void:
	var container := get_parent()
	if container == null:
		return

	_ignore_checkbox_sync = true
	for child: Node in container.get_children():
		if child == self:
			continue
		if child.has_method("set_checkbox_pressed"):
			child.set_checkbox_pressed(false)
	set_checkbox_pressed(true)
	_ignore_checkbox_sync = false

	var main_node := get_tree().root.get_node_or_null("Main")
	if main_node != null and main_node.has_method("set_checked_track_source_path"):
		main_node.set_checked_track_source_path(track_source_path)


@warning_ignore("shadowed_variable_base_class")
func set_checkbox_pressed(is_pressed: bool) -> void:
	check_box.button_pressed = is_pressed


func _count_checked_siblings() -> int:
	var container := get_parent()
	if container == null:
		return 1 if check_box.button_pressed else 0

	var count := 0
	for child: Node in container.get_children():
		if child.has_method("is_track_checked") and child.is_track_checked():
			count += 1
	return count


func _collect_checked_source_paths() -> Array[String]:
	var selected_paths: Array[String] = []
	var container := get_parent()
	if container == null:
		return selected_paths

	for child: Node in container.get_children():
		if not child.has_method("is_track_checked"):
			continue
		if child.is_track_checked():
			var source_path: String = child.get_track_source_path()
			if not source_path.is_empty():
				selected_paths.append(source_path)
	return selected_paths


func is_track_checked() -> bool:
	return check_box.button_pressed


func get_track_source_path() -> String:
	return track_source_path

func set_selected(is_selected: bool) -> void:
	if is_selected:
		scroll_label.add_theme_color_override("font_color", Color.BLACK)
	else:
		scroll_label.remove_theme_color_override("font_color")
