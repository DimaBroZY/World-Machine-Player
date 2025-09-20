extends PanelContainer

var moving := false 
var mouse_start: Vector2i

#func _on_minimize_button_pressed() -> void:
	#get_window().mode = Window.MODE_MINIMIZED


func _on_close_button_pressed() -> void:
	get_window().queue_free()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == 1:
		if !moving:
			mouse_start = get_viewport().get_mouse_position()
		moving = event.is_pressed()

func _process(_delta: float) -> void:
	if moving:
		var mouse_now := Vector2i(get_viewport().get_mouse_position())
		get_window().position += mouse_now - mouse_start
