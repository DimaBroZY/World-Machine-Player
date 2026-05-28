extends Node

signal setting_changed(key: String, value)

var config := ConfigFile.new()
var config_path := "user://settings.cfg"

func _ready():
	load_settings()

func save_setting(key: String, value):
	var err = config.load(config_path)
	if err != OK:
		print("Ошибка загрузки конфига:", err)
	config.set_value("settings", key, value)
	err = config.save(config_path)
	if err != OK:
		print("Ошибка сохранения конфига:", err)
	emit_signal("setting_changed", key, value)
	
func get_setting(key: String, default_value = null):
	if config.has_section_key("settings", key):
		return config.get_value("settings", key, default_value)
	return default_value

func load_settings():
	config.load(config_path)
