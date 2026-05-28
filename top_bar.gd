extends PanelContainer


var moving := false 
var mouse_start: Vector2i
var menu_window = null

func _on_minimize_button_pressed() -> void:
	get_window().mode = Window.MODE_MINIMIZED

func _on_close_button_pressed() -> void:
	get_tree().quit()

func _on_one_shot_menu_button_pressed() -> void:
		if menu_window != null and is_instance_valid(menu_window):
			menu_window.show()
			return
	
		# Загружаем сцену с Window как корневой нодой
		menu_window = preload("res://Windows/menu_window.tscn").instantiate()
	
		# Добавляем Window в дерево сцен
		get_tree().root.add_child(menu_window)
	
		menu_window.close_requested.connect(func(): 
			menu_window.queue_free()
			menu_window = null
		)
		menu_window.show()
		TintManager.apply_tint_to_scene()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == 1:
		if !moving:
			mouse_start = get_viewport().get_mouse_position()
		moving = event.is_pressed()

func _process(_delta: float) -> void:
	if moving:
		var mouse_now := Vector2i(get_viewport().get_mouse_position())
		get_window().position += mouse_now - mouse_start
