extends PanelContainer

var _window_restore_pos: Vector2i
var _restore_animation_pending := false
var _last_mode: int

func _ready() -> void:
	_last_mode = get_window().mode

func _process(_delta):
	_check_window_mode()

func _check_window_mode():
	var win := get_window()

	if win.mode != _last_mode:
		_last_mode = win.mode

		if win.mode == Window.MODE_WINDOWED:
			if _restore_animation_pending:
				restore_animation()

func _on_minimize_button_pressed() -> void:
	minimize_animation()

func _on_close_button_pressed() -> void:
	close_animation()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			get_window().start_drag()

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

	tween.parallel().tween_property(
		self,
		"modulate:a",
		0.0,
		0.25
	)

	await tween.finished

	get_window().queue_free()

func minimize_animation():
	var win := get_window()

	_window_restore_pos = win.position
	_restore_animation_pending = true

	var screen_size := DisplayServer.screen_get_size()
	var offscreen_y := screen_size.y + 100

	var tween := create_tween()

	tween.tween_property(
		win,
		"position",
		_window_restore_pos + Vector2i(0, -100),
		0.25
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		win,
		"position",
		Vector2i(_window_restore_pos.x, offscreen_y),
		0.3
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await tween.finished

	win.mode = Window.MODE_MINIMIZED

func restore_animation():
	_restore_animation_pending = false

	var win := get_window()

	var screen_size := DisplayServer.screen_get_size()
	var offscreen_y := screen_size.y + 100

	win.position = Vector2i(
		_window_restore_pos.x,
		offscreen_y
	)

	await get_tree().process_frame

	var tween := create_tween()

	tween.tween_property(
		win,
		"position",
		_window_restore_pos,
		0.3
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
