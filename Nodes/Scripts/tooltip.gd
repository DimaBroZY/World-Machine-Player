class_name Tooltip
extends PanelContainer

@export_multiline var custom_text: String = "Tooltip Text"

var _label: Label

func _ready() -> void:
	# отключаем при старте
	hide()
	top_level = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Визуальный стиль
	var style = StyleBoxFlat.new()
	style.bg_color = Color.BLACK
	style.border_color = Color.WHITE
	style.border_width_bottom = 3
	style.border_width_top = 3
	style.border_width_left = 3
	style.border_width_right = 3
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	add_theme_stylebox_override("panel", style)
	
	# Текст
	_label = Label.new()
	_label.text = custom_text
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_font_size_override("font_size", 18)
	
	# Шрифт
	var font = load("res://Assets/Fonts/Minecraftia-Regular.ttf")
	if font:
		_label.add_theme_font_override("font", font)
		
	add_child(_label)
	
	# Привязка к ноде
	var parent = get_parent()
	if parent != null:
		if parent.has_signal("mouse_entered"):
			parent.connect("mouse_entered", Callable(self, "_on_parent_mouse_entered"))
		if parent.has_signal("mouse_exited"):
			parent.connect("mouse_exited", Callable(self, "_on_parent_mouse_exited"))

func _process(_delta: float) -> void:
	if visible:
		global_position = get_global_mouse_position() + Vector2(15, 15)

func _on_parent_mouse_entered() -> void:
	if custom_text.strip_edges() != "":
		_label.text = custom_text 
		show()

func _on_parent_mouse_exited() -> void:
	hide()
