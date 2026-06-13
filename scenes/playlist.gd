extends Button

signal playlist_selected(playlist_id: String)
signal playlist_deselected
signal playlist_deleted(playlist_id: String)
signal playlist_renamed(playlist_id: String, new_name: String)

enum DisplayMode {
	MAIN,
	SELECT,
}

@onready var scroll_text: Control = $ScrollText
@onready var scroll_label: Label = $ScrollText/label
@onready var recycle_bin: TextureButton = $ButtonsContainer/HBoxContainer/RecycleBinButton
@onready var check_box: CheckBox = $CheckBox
@onready var buttons_container: PanelContainer = $ButtonsContainer

static var playlist_button_group: ButtonGroup

const MINECRAFTIA_FONT := preload("res://Assets/Fonts/Minecraftia-Regular.ttf")

var playlist_id: String = ""
var _display_mode: DisplayMode = DisplayMode.MAIN
var _rename_edit: LineEdit = null
var _pending_name: String = ""
var _pending_active: bool = false
var _suppress_toggle_signals: bool = false
var _pending_select_paths: Array = []
var _was_pressed_before_click: bool = false


func _ready() -> void:
	action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	recycle_bin.mouse_entered.connect(_on_recycle_bin_mouse_entered)
	recycle_bin.mouse_exited.connect(_on_recycle_bin_mouse_exited)
	toggled.connect(_on_toggled)
	pressed.connect(_on_playlist_pressed)
	_apply_configuration()


func configure_for_main(id: String, playlist_name: String, is_active: bool) -> void:
	playlist_id = id
	_display_mode = DisplayMode.MAIN
	_pending_name = playlist_name
	_pending_active = is_active
	if is_node_ready():
		_apply_configuration()


func configure_for_select(id: String, playlist_name: String, source_paths: Array = []) -> void:
	playlist_id = id
	_display_mode = DisplayMode.SELECT
	_pending_name = playlist_name
	_pending_active = false
	_pending_select_paths = source_paths.duplicate()
	if is_node_ready():
		_apply_configuration()


func set_playlist_name(playlist_name: String) -> void:
	_pending_name = playlist_name
	if is_node_ready():
		_set_display_name(playlist_name)


func set_pressed_silent(is_pressed: bool) -> void:
	_suppress_toggle_signals = true
	button_pressed = is_pressed
	_update_visuals(is_pressed)
	_suppress_toggle_signals = false


func _set_display_name(playlist_name: String) -> void:
	if scroll_text is ScrollText:
		(scroll_text as ScrollText).set_track_name(playlist_name)
	else:
		scroll_label.text = playlist_name


func _apply_configuration() -> void:
	if _pending_name.is_empty():
		return
	_set_display_name(_pending_name)
	_apply_display_mode()
	if _display_mode == DisplayMode.MAIN:
		button_pressed = _pending_active
	_update_visuals(button_pressed)
	_apply_select_checkbox_state()


func _apply_select_checkbox_state() -> void:
	if _display_mode != DisplayMode.SELECT:
		return
	check_box.button_pressed = PlaylistManager.playlist_contains_all_tracks(
		playlist_id,
		_pending_select_paths
	)


func is_checkbox_checked() -> bool:
	return check_box.button_pressed


func get_playlist_id() -> String:
	return playlist_id


func _apply_display_mode() -> void:
	match _display_mode:
		DisplayMode.MAIN:
			toggle_mode = true
			if not playlist_button_group:
				playlist_button_group = ButtonGroup.new()
			playlist_button_group.allow_unpress = false
			button_group = playlist_button_group
			check_box.visible = false
			buttons_container.visible = true
		DisplayMode.SELECT:
			toggle_mode = false
			button_group = null
			button_pressed = false
			check_box.visible = true
			check_box.mouse_filter = Control.MOUSE_FILTER_STOP
			buttons_container.visible = false


func _gui_input(event: InputEvent) -> void:
	if _display_mode != DisplayMode.MAIN or _rename_edit != null:
		return
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		_was_pressed_before_click = button_pressed
		if event.double_click:
			_start_rename()


func _start_rename() -> void:
	if _rename_edit != null:
		return

	scroll_text.visible = false
	_rename_edit = LineEdit.new()
	_rename_edit.text = _pending_name
	_rename_edit.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rename_edit.offset_left = scroll_text.offset_left
	_rename_edit.offset_top = scroll_text.offset_top
	_rename_edit.offset_right = scroll_text.offset_right
	_rename_edit.offset_bottom = scroll_text.offset_bottom
	_rename_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rename_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_rename_edit.add_theme_font_override("font", MINECRAFTIA_FONT)
	_rename_edit.add_theme_font_size_override("font_size", 24)
	_rename_edit.add_theme_color_override("font_color", Color.WHITE)
	_rename_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rename_edit.text_submitted.connect(_finish_rename)
	_rename_edit.focus_exited.connect(_finish_rename)
	add_child(_rename_edit)
	_rename_edit.grab_focus()
	_rename_edit.select_all()


func _finish_rename(_new_text: String = "") -> void:
	if _rename_edit == null:
		return

	var new_name := _rename_edit.text.strip_edges()
	if new_name.is_empty():
		new_name = _pending_name
	_pending_name = new_name
	_set_display_name(new_name)
	scroll_text.visible = true
	_rename_edit.queue_free()
	_rename_edit = null
	_update_visuals(button_pressed)
	playlist_renamed.emit(playlist_id, new_name)


func _on_toggled(is_pressed: bool) -> void:
	_update_visuals(is_pressed)


func _on_playlist_pressed() -> void:
	if _suppress_toggle_signals:
		return
	if _display_mode == DisplayMode.SELECT:
		check_box.button_pressed = not check_box.button_pressed
		return
	if _display_mode != DisplayMode.MAIN:
		return
	if _was_pressed_before_click:
		set_pressed_silent(false)
		playlist_deselected.emit()
	else:
		playlist_selected.emit(playlist_id)


func _update_visuals(is_pressed: bool) -> void:
	if is_pressed:
		scroll_text.modulate = Color.BLACK
		check_box.modulate = Color.BLACK
		if recycle_bin.is_hovered():
			recycle_bin.modulate = Color.WHITE
		else:
			recycle_bin.modulate = Color.BLACK
	else:
		scroll_text.modulate = Color.WHITE
		check_box.modulate = Color.WHITE
		recycle_bin.modulate = Color.WHITE


func _on_recycle_bin_mouse_entered() -> void:
	if button_pressed:
		recycle_bin.modulate = Color.WHITE


func _on_recycle_bin_mouse_exited() -> void:
	if button_pressed:
		recycle_bin.modulate = Color.BLACK


func _on_recycle_bin_button_pressed() -> void:
	if _display_mode != DisplayMode.MAIN:
		return
	playlist_deleted.emit(playlist_id)
