extends Node

signal setting_changed(key: String, value)

var config = ConfigFile.new()
var config_path = "user://settings.cfg"

func _ready():
	load_settings()

func save_setting(key: String, value):
	config.set_value("settings", key, value)
	config.save(config_path)
	setting_changed.emit(key, value)
	
func get_setting(key: String, default_value = ""):
	return config.get_value("settings", key, default_value)

func load_settings():
	config.load(config_path)
