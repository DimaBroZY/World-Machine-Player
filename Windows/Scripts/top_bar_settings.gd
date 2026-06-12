extends PanelContainer

func _on_minimize_button_pressed() -> void:
	get_window().mode = Window.MODE_MINIMIZED


func _on_close_button_pressed() -> void:
	get_window().queue_free()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			get_window().start_drag()
