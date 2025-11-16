extends Control

@onready var line_edit = $Content/Panel/FolderPath


func _ready():
	var music_dir = "user://music"
	
	if not DirAccess.dir_exists_absolute(music_dir):
		DirAccess.open("user://").make_dir("music")
	
	line_edit.text = Settings.get_setting("music_path", "user://music")
	line_edit.text_submitted.connect(_on_text_submitted)

func _on_text_submitted(text: String):
	Settings.save_setting("music_path", text)


func _on_folder_button_pressed() -> void:
	OS.shell_open(ProjectSettings.globalize_path(Settings.get_setting("music_path", "user://music")))
