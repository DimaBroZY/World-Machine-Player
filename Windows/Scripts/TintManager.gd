extends Node

var current_tint: Color = Color(1, 1, 1, 1)
var rainbow_speed := 0.1
var rainbow_enabled := false
var party_speed := 1
var party_enabled := false
var _hue := 0.0
var _update_timer := 0.0
var _update_interval := 0.05  # обновлять максимум 20 раз в секунду

func _ready():
	var saved_rainbow = Settings.get_setting("rainbow_enabled", false)
	rainbow_enabled = saved_rainbow
	var saved_party = Settings.get_setting("party_enabled", false)
	rainbow_enabled = saved_party

	var saved = Settings.get_setting("tint_color", null)
	if saved == null:
		current_tint = Color(1, 1, 1, 1)
	else:
		if typeof(saved) == TYPE_STRING:
			current_tint = Color(saved)
		else:
			current_tint = saved

	_apply_tint(current_tint)
	Settings.setting_changed.connect(_on_setting_changed)


func _process(delta):
	if rainbow_enabled:
		_update_timer += delta
		if _update_timer >= _update_interval:
			_update_timer = 0.0
			_hue = fmod(_hue + _update_interval * rainbow_speed, 1.0)
			var new_color = Color.from_hsv(_hue, 1.0, 1.0)
			if new_color != current_tint:
				current_tint = new_color
				_apply_tint(current_tint)
				
	if party_enabled:
		_update_timer += delta
		if _update_timer >= _update_interval:
			_update_timer = 0.0
			_hue = fmod(_hue + _update_interval * party_speed, 1.0)
			var new_color = Color.from_hsv(_hue, 1.0, 1.0)
			if new_color != current_tint:
				current_tint = new_color
				_apply_tint(current_tint)


func set_tint(color: Color):
	if rainbow_enabled:
		enable_rainbow(false)
	if party_enabled:
		enable_party(false)
	current_tint = color
	_apply_tint(color)
	Settings.save_setting("tint_color", color.to_html(true))
	Settings.save_setting("rainbow_enabled", false)
	Settings.save_setting("party_enabled", false)


func enable_rainbow(enable: bool):
	if rainbow_enabled == enable:
		return  
	rainbow_enabled = enable
	Settings.save_setting("rainbow_enabled", enable)
	if not enable:
		Settings.save_setting("tint_color", current_tint.to_html(true))

func enable_party(enable: bool):
	if party_enabled == enable:
		return  # Уже в том же состоянии — ничего не делаем
	party_enabled = enable
	Settings.save_setting("party_enabled", enable)
	if not enable:
		Settings.save_setting("tint_color", current_tint.to_html(true))

func _on_setting_changed(key: String, value):
	if key == "tint_color" and not rainbow_enabled and not party_enabled:
		if typeof(value) == TYPE_STRING:
			current_tint = Color(value)
		else:
			current_tint = value
		_apply_tint(current_tint)


func _apply_tint(color: Color):
	var nodes_tintable = get_tree().get_nodes_in_group("tintable")
	for node in nodes_tintable:
		if not node.has_meta("ignore_tint"):
			node.modulate = color

func apply_tint_to_scene():
	var nodes_tintable = get_tree().get_nodes_in_group("tintable")
	for node in nodes_tintable:
		if not node.has_meta("ignore_tint"):
			node.modulate = current_tint
