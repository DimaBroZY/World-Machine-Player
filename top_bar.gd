extends PanelContainer


var moving := false 
var mouse_start: Vector2i
var settings_window = null

func _on_minimize_button_pressed() -> void:
	get_window().mode = Window.MODE_MINIMIZED

func _on_close_button_pressed() -> void:
	get_tree().quit()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == 1:
		if !moving:
			mouse_start = get_viewport().get_mouse_position()
		moving = event.is_pressed()

func _process(_delta: float) -> void:
	if moving:
		var mouse_now := Vector2i(get_viewport().get_mouse_position())
		get_window().position += mouse_now - mouse_start


func _on_one_shot_settings_button_pressed() -> void:
	if settings_window != null and is_instance_valid(settings_window):
		settings_window.show()
		return
	
	# Загружаем сцену с Window как корневой нодой
	settings_window = preload("res://Windows/settings_window.tscn").instantiate()
	
	# Добавляем Window в дерево сцен
	get_tree().root.add_child(settings_window)
	
	settings_window.close_requested.connect(func(): 
		settings_window.queue_free()
		settings_window = null
	)
	settings_window.show()
