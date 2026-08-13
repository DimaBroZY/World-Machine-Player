extends Node

@export var click_sound_press: AudioStream
@export var click_sound_release: AudioStream


func _ready() -> void:
	if click_sound_press:
		AudioManager.LoadSFX(click_sound_press.resource_path)

	if click_sound_release:
		AudioManager.LoadSFX(click_sound_release.resource_path)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if click_sound_press:
				AudioManager.PlaySFX(click_sound_press.resource_path)
		else:
			if click_sound_release:
				AudioManager.PlaySFX(click_sound_release.resource_path)
