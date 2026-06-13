extends Button

@onready var scroll_text: Control = $ScrollText
@onready var recycle_bin: TextureButton = $ButtonsContainer/HBoxContainer/RecycleBinButton
@onready var check_box: CheckBox = $CheckBox

static var playlist_button_group: ButtonGroup

func _ready() -> void:
	action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	
	if not playlist_button_group:
		playlist_button_group = ButtonGroup.new()
		playlist_button_group.allow_unpress = true
	button_group = playlist_button_group
	
	toggled.connect(_on_toggled)
	recycle_bin.mouse_entered.connect(_on_recycle_bin_mouse_entered)
	recycle_bin.mouse_exited.connect(_on_recycle_bin_mouse_exited)
	
	_update_visuals(button_pressed)

func _on_toggled(is_pressed: bool) -> void:
	_update_visuals(is_pressed)

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
	queue_free()
