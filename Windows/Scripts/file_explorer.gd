extends Node

@export var folder_only := false

@onready var cont = $ScrollContainer/VBoxContainer/container
@onready var pinned = $pinned/pinned_container
@onready var Npath = $path

var path:String = ""
var file:bool = false
var limited = []

signal done(path:String)

func _ready():
	path = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
	set_layout()
	for i in FileExplorerAutoload.pinned:
		add_pinned_button(i)
	
func add_pinned_button(arr:Array):
	var nBut = Button.new()
	nBut.text = arr[0]
	nBut.custom_maximum_size = Vector2i(140,-1)
	nBut.custom_minimum_size = Vector2i(140,-1)
	pinned.add_child(nBut)
	nBut.pressed.connect(to_dir.bind(arr[1]))
	
func to_dir(new_path:String):
	path = new_path
	set_layout()
	
func open_folder(folder_name:String):
	if file:
		path = path.get_base_dir()
	path = path + "/" + folder_name
	set_layout()

func open_file(file_name:String):
	if folder_only:
		return
	if file:
		path = path.get_base_dir()
	path = path + "/" + file_name
	Npath.text = path
	file = true
		
	file = true 

func set_layout():
	var dir = DirAccess.open(path)
	if dir == null:
		Npath.text = path
		return

	file = false
	Npath.text = path
	for i in cont.get_children(): i.queue_free()

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		var nBut = Button.new()
		nBut.text = file_name
		nBut.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nBut.alignment = HORIZONTAL_ALIGNMENT_CENTER
		nBut.custom_maximum_size = Vector2i(445,-1)
		nBut.custom_minimum_size = Vector2i(445,-1)
		cont.add_child(nBut)
		if dir.current_is_dir():
			nBut.pressed.connect(open_folder.bind(file_name))
			nBut.icon = preload("res://Assets/Icons/Folder.png")
			nBut.expand_icon = true
		else:
			nBut.pressed.connect(open_file.bind(file_name))
			if limited.size() > 0:
				if !file_name.gex_extesion() in limited: nBut.queue_free()

		file_name = dir.get_next()

func _on_up_pressed() -> void:
	if file: path.get_base_dir()
	path = path.get_base_dir()
	set_layout()


func _on_path_text_submitted(new_text: String) -> void:
	if new_text.is_absolute_path() and DirAccess.dir_exists_absolute(new_text):
		path = new_text
		set_layout()
	else:
		Npath.text = path
	

func _on_open_pressed() -> void:
	var result_path := path
	if folder_only and file:
		result_path = path.get_base_dir()
	emit_signal("done", result_path)
	close_animation()

func _on_cancel_pressed() -> void:
	close_animation()

func _on_pin_pressed() -> void:
	var npath = path
	if file: npath = npath.get_base_dir()
	var nam = npath.get_file()
	FileExplorerAutoload.pinned.append([nam,npath])
	add_pinned_button([nam,npath])
	
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
	
