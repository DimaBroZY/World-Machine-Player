extends Control

# @oneready переменные
@onready var music = $MainWindow/AudioStreamPlayer
@onready var curTrack = $MainWindow/CurrentTrack/PanelContainer/CurrentTrackName
@onready var niko = $MainWindow/Objects/Niko
@onready var gramophone = $MainWindow/Objects/Gramophone
@onready var volumeControl = $MainWindow/VolumeControl
@onready var speedControl = $MainWindow/PlaybackSpeedControlNode

# куча переменных
var MUSIC_FILE = preload("res://music/Prelude.mp3")
const PLAY = 0
const PAUSE = 1
var state:int = PAUSE  # стартуем с паузы
var playlist: Array[AudioStream] = []  # Плейлист
var track_names: Array[String] = [] # имена треков
var current_index: int = 0  # Текущий трек
var FOLDER_PATH: String



func _ready() -> void:
	FOLDER_PATH = Settings.get_setting("music_path", "user://music")  # Сначала получаем путь
	Settings.setting_changed.connect(_on_setting_changed)
	
	print("Проверяю путь: ", FOLDER_PATH)  # Для отладки
	load_tracks_from_folder()  # Теперь загружаем треки
	
	if playlist.size() > 0:
		music.stream = playlist[current_index]
		curTrack.text = playlist[current_index].resource_path.get_file().get_basename()
	else:
		music.stream = MUSIC_FILE
		curTrack.text = MUSIC_FILE.resource_path.get_file().get_basename()
	
	music.volume_db = 0
	update_track_name()
	update_state()
	
func nicoAnim():
	if randi_range(1,2) == 1:
		niko.animPlayer.play("Dancing")
	else:
		niko.animPlayer.play("Dance_Sitting")
		
func _on_audio_stream_player_finished() -> void:
	music.play(0.0)
	
func _on_setting_changed(key: String, value):
	if key == "music_path":
		FOLDER_PATH = value
		load_tracks_from_folder()  # Перезагружаем треки с новым путем
		if playlist.size() > 0:
			current_index = 0
			music.stream = playlist[current_index]
			update_track_name()

func load_tracks_from_folder() -> void:
	var dir = DirAccess.open(FOLDER_PATH)
	playlist.clear()
	track_names.clear()  # Очищаем имена
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			print("Найден файл: ", file_name)
			# Поддерживаем как OGG, так и MP3
			if file_name.ends_with(".ogg") or file_name.ends_with(".mp3"):
				var full_path = FOLDER_PATH + "/" + file_name
				var user_path = "user://" + file_name.replace(" ", "_").replace("[", "_").replace("]", "_")
				var resource_path = user_path.replace(".ogg", ".tres").replace(".mp3", ".tres")
				var file = FileAccess.open(full_path, FileAccess.READ)
				if file:
					var buffer = file.get_buffer(file.get_length())
					file.close()
					var user_file = FileAccess.open(user_path, FileAccess.WRITE)
					if user_file:
						user_file.store_buffer(buffer)
						user_file.close()
						
						# Создаем нужный тип стрима в зависимости от расширения
						var stream: AudioStream
						if file_name.ends_with(".ogg"):
							stream = AudioStreamOggVorbis.load_from_buffer(buffer)
						else:  # .mp3
							stream = AudioStreamMP3.new()
							stream.data = buffer
							
						if stream is AudioStream:
							ResourceSaver.save(stream, resource_path)
							playlist.append(stream)
							track_names.append(file_name.get_basename())  # Сохраняем оригинальное имя
							print("Добавлен трек: ", file_name)
						else:
							print("Ошибка: не удалось создать AudioStream для ", user_path)
					else:
						print("Ошибка: не могу записать ", user_path)
				else:
					print("Ошибка: не могу открыть ", full_path)
			file_name = dir.get_next()
		dir.list_dir_end()
		print("Загружено треков: ", playlist.size())
	else:
		print("Ошибка: папка ", FOLDER_PATH, " не открылась")
	if playlist.size() > 0:
		if current_index >= playlist.size():
			current_index = 0
		music.stream = playlist[current_index]
		update_track_name()
		if state == PLAY:
			music.play()
		
func update_track_name() -> void:
	if playlist.size() > 0 and current_index < playlist.size():
		curTrack.text = track_names[current_index]  # Используем оригинальное имя
	else:
		curTrack.text = MUSIC_FILE.resource_path.get_file().get_basename()

func _on_next_track_pressed() -> void:
	if playlist.size() > 0:
		current_index = (current_index + 1) % playlist.size()
		music.stop()
		music.stream = playlist[current_index]
		update_track_name()
		if state == PLAY:
			music.play()
		update_state()
		
func _on_previous_track_pressed() -> void:
	if playlist.size() > 0:
		current_index = (current_index - 1) % playlist.size()
		music.stop()
		music.stream = playlist[current_index]
		update_track_name()
		if state == PLAY:
			music.play()
		update_state()

func _on_play_pause_button_pressed() -> void:
	if state == PLAY:
		state = PAUSE
	else:
		state = PLAY
	update_state()

func update_state() -> void:
	if state == PLAY:
		play_state()
	else:
		pause_state()

func play_state() -> void:
	music.stream_paused = false  # снимаем паузу
	if not music.is_playing():
		music.play()
	$MainWindow/Buttons/PlayPauseButton.texture_normal = preload("res://Assets/Buttons/PauseButton.png")
	$MainWindow/Buttons/PlayPauseButton.texture_hover = preload("res://Assets/Buttons/PauseButton_Hover.png")
	nicoAnim()
	gramophone.animPlayer.play("Playing")

func pause_state() -> void:
	music.stream_paused = true  # ставим на паузу
	$MainWindow/Buttons/PlayPauseButton.texture_normal = preload("res://Assets/Buttons/PlayButton.png")
	$MainWindow/Buttons/PlayPauseButton.texture_hover = preload("res://Assets/Buttons/PlayButton_Hover.png")
	niko.animPlayer.play("Sleeping")
	gramophone.animPlayer.pause()

func _on_stop_button_pressed() -> void:
	music.stop()  # фул стоп
	if state == PLAY:
		state = PAUSE
		$MainWindow/Buttons/PlayPauseButton.texture_normal = preload("res://Assets/Buttons/PlayButton.png")
		$MainWindow/Buttons/PlayPauseButton.texture_hover = preload("res://Assets/Buttons/PlayButton_Hover.png")
	niko.animPlayer.play("Sleeping")
	gramophone.animPlayer.pause()

func _on_speed_control_slide_value_changed(value: float) -> void:
	$MainWindow/PlaybackSpeedControlNode/SpeedValue.text = "Playback Speed: " + str(int(speedControl.speedControlSlide.value)) + "%"
	music.pitch_scale = speedControl.speedControlSlide.value / 100
	niko.animPlayer.speed_scale = speedControl.speedControlSlide.value / 100
	gramophone.animPlayer.speed_scale = speedControl.speedControlSlide.value / 100
	
func _on_volume_control_slide_value_changed(value: float) -> void:
	music.volume_db = volumeControl.volumeControlSlide.value
	$MainWindow/VolumeControl/VolumeValue.text = "Volume: "+ str(int(music.volume_db + 100))  + "%"
	if volumeControl.volumeControlSlide.value == -100:
			music.volume_db = -99999

func _on_reverse_button_pressed() -> void:
	if music.playing == true:
		music.play(0.0)
	else:
		music.stop()

func _on_speed_minus_pressed() -> void:
	music.pitch_scale -= 0.05
	speedControl.speedControlSlide.value = music.pitch_scale * 100

func _on_speed_plus_pressed() -> void:
	music.pitch_scale += 0.05
	speedControl.speedControlSlide.value = music.pitch_scale * 100

func _on_volume_minus_pressed() -> void:
	if music.volume_db >= -100:
		music.volume_db -= 1
		volumeControl.volumeControlSlide.value = music.volume_db
		$MainWindow/VolumeControl/VolumeValue.text = "Volume: "+ str(int(music.volume_db + 100))  + "%"
		if volumeControl.volumeControlSlide.value == -100:
				music.volume_db = -99999

func _on_volume_plus_pressed() -> void:
	if music.volume_db != 1:
		music.volume_db += 1
		volumeControl.volumeControlSlide.value = music.volume_db
		$MainWindow/VolumeControl/VolumeValue.text = "Volume: "+ str(int(music.volume_db + 99)) + "%"
