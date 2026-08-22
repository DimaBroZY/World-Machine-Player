extends Node

@export_file("*.wav") var click_sound_press: String
@export_file("*.wav") var click_sound_release: String


func _ready() -> void:
	if click_sound_press and not click_sound_press.is_empty():
		AudioManager.LoadSFX(click_sound_press)

	if click_sound_release and not click_sound_release.is_empty():
		AudioManager.LoadSFX(click_sound_release)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if click_sound_press and not click_sound_press.is_empty():
				AudioManager.PlaySFX(click_sound_press)
		else:
			if click_sound_release and not click_sound_release.is_empty():
				AudioManager.PlaySFX(click_sound_release)
