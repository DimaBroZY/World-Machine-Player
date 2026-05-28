extends Node

@export var click_sound_press: AudioStream
@export var click_sound_release: AudioStream

var player: AudioStreamPlayer

func _ready():
	
	player = AudioStreamPlayer.new()
	add_child(player)
	player.volume_db = -10

func _input(event):
	if event is InputEventMouseButton and event.button_index == 1:
		if event.pressed:
			if click_sound_press:
				player.stream = click_sound_press
				player.play()
		else:
			if click_sound_release:
				player.stream = click_sound_release
				player.play()
