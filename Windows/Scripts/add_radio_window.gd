extends Window

signal station_confirmed(station_name: String, url: String)

@onready var name_field: TextEdit = $AddRadioWindow/Layout/Main/ScrollContainer/VBoxContainer/NameText
@onready var url_field: TextEdit = $AddRadioWindow/Layout/Main/ScrollContainer/VBoxContainer/Url
@onready var ok_button: Button = $AddRadioWindow/Layout/Main/ButtonsContainer/Buttons/OkButton
@onready var cancel_button: Button = $AddRadioWindow/Layout/Main/ButtonsContainer/Buttons/CancelButton
@onready var close_button: Button = $AddRadioWindow/Layout/TopBar/HBox/CloseButton


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
	visible = true
	WindowManager.set_modal_open(true)


func _on_ok_pressed() -> void:
	var station_name: String = name_field.text.strip_edges()
	var station_url: String = url_field.text.strip_edges()
	if station_name.is_empty() or station_url.is_empty():
		return
	station_confirmed.emit(station_name, station_url)
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
