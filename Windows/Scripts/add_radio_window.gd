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
	_close()


func _on_cancel_pressed() -> void:
	_close()


func _on_cancel() -> void:
	_close()


func _close() -> void:
	hide()
	WindowManager.set_modal_open(false)
