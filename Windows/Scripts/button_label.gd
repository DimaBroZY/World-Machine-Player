extends Button

func _ready():
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))

func _on_mouse_entered():
	for child in get_children():
		if child is Label:
			child.add_theme_color_override("font_color", Color.from_rgba8(167, 167, 167, 255))

func _on_mouse_exited():
	for child in get_children():
		if child is Label:
			child.add_theme_color_override("font_color", Color.from_rgba8(255, 255, 255, 255))
