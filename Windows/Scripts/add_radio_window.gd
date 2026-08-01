extends Window

signal station_confirmed(station_name: String, url: String)

@onready var name_field: TextEdit = $AddRadioWindow/Main/ScrollContainer/VBoxContainer/NameText
@onready var url_field: TextEdit = $AddRadioWindow/Main/ScrollContainer/VBoxContainer/Url
@onready var ok_button: Button = $AddRadioWindow/Main/ButtonsContainer/Buttons/OkButton
@onready var cancel_button: Button = $AddRadioWindow/Main/ButtonsContainer/Buttons/CancelButton
@onready var close_button: Button = $AddRadioWindow.get_node("%CloseButton")
@onready var status_label: Label = _create_status_label()

var _pending_name: String = ""
var _url_regex: RegEx = _make_url_regex()


func _make_url_regex() -> RegEx:
	var regex := RegEx.new()
	regex.compile("^https?://[^\\s/$.?#].[^\\s]*$")
	return regex


func _create_status_label() -> Label:
	var label := $AddRadioWindow/Main/StatusLabel
	label.add_theme_color_override("font_color", Color.WHITE)
	label.name = "StatusLabel"
	return label


func _ready() -> void:
	exclusive = true
	visible = false
	close_requested.connect(_on_cancel)
	ok_button.pressed.connect(_on_ok_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	for connection: Dictionary in close_button.pressed.get_connections():
		close_button.pressed.disconnect(connection["callable"])
	close_button.pressed.connect(_on_cancel_pressed)


func open_dialog() -> void:
	name_field.text = ""
	url_field.text = ""
	status_label.text = ""
	visible = true
	WindowManager.set_modal_open(true)

func _show_success(text: String) -> void:
	status_label.add_theme_color_override("font_color", Color.GREEN)
	status_label.text = text

func _show_error(text: String) -> void:
	status_label.add_theme_color_override("font_color", Color.INDIAN_RED)
	status_label.text = text


func _on_ok_pressed() -> void:
	var station_name: String = name_field.text.strip_edges()
	var station_url: String = url_field.text.strip_edges()
	if station_name.is_empty() or station_url.is_empty():
		_show_error("Fill in both fields")
		return
	if _url_regex.search(station_url) == null:
		_show_error("Incorrect URL (need http:// or https://)")
		return

	_pending_name = station_name
	ok_button.disabled = true
	status_label.add_theme_color_override("font_color", Color.WHITE)
	status_label.text = "Station check..."

	if AudioManager.StationTestResult.is_connected(_on_station_test_result):
		AudioManager.StationTestResult.disconnect(_on_station_test_result)
	AudioManager.StationTestResult.connect(_on_station_test_result, CONNECT_ONE_SHOT)
	AudioManager.TestStation(station_url)


func _on_station_test_result(url: String, is_valid: bool, is_unsupported: bool) -> void:
	ok_button.disabled = false
	if is_valid:
		station_confirmed.emit(_pending_name, url)
		_show_success("Station added successfully")
		close_animation()
	elif is_unsupported:
		_show_error("Stream format not supported")
	else:
		_show_error("Failed to connect (unavailable)")


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
