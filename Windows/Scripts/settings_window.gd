extends Control

@onready var line_edit = $Content/PanelManager/HBoxContainer/GeneralPanel/VBoxContainer/PathPanel/FolderPath


func _ready():
	var music_dir = "user://music"
	
	if not DirAccess.dir_exists_absolute(music_dir):
		DirAccess.open("user://").make_dir("music")
	line_edit.text = Settings.get_setting("music_path", "user://music")
	line_edit.text_submitted.connect(_on_text_submitted)

func _on_text_submitted(text: String):
	Settings.save_setting("music_path", text)


func _on_folder_button_pressed() -> void:
	var win := preload("res://Windows/file_explorer.tscn").instantiate()
	var explorer := win.get_node("ExplorerWindow/Content/file_explorer") 
	explorer.folder_only = true
	get_tree().root.add_child(win)
	explorer.done.connect(func(path: String) -> void:
		line_edit.text = path
		Settings.save_setting("music_path", path)
	)
	win.show()
	TintManager.apply_tint_to_scene()
