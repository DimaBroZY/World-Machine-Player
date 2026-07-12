extends Node

signal stations_changed()

const STATIONS_FILE: String = "user://radio_stations.json"
const DEFAULT_STATIONS: Array[Dictionary] = [
	{"name": "LoFi (Lofi 24/7)", "url": "http://usa9.fastcast4u.com/proxy/jamz?mp=/1"},
	{"name": "Vaporwaves (SomaFM)", "url": "https://ice3.somafm.com/vaporwaves-128-mp3"},
	{"name": "Radio «GamePlay»", "url": "https://c22.radioboss.fm:8144/GamePlay"},
]

var stations: Array[Dictionary] = []


func _ready() -> void:
	_load_stations()


func _load_stations() -> void:
	if not FileAccess.file_exists(STATIONS_FILE):
		stations = DEFAULT_STATIONS.duplicate(true)
		_save_stations()
		return

	var file: FileAccess = FileAccess.open(STATIONS_FILE, FileAccess.READ)
	if file == null:
		stations = DEFAULT_STATIONS.duplicate(true)
		return

	var json_text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(json_text)
	if not (parsed is Array):
		stations = DEFAULT_STATIONS.duplicate(true)
		return

	var loaded: Array[Dictionary] = []
	for entry_variant: Variant in (parsed as Array):
		if entry_variant is Dictionary:
			var entry: Dictionary = entry_variant as Dictionary
			if entry.has("name") and entry.has("url"):
				loaded.append({"name": str(entry["name"]), "url": str(entry["url"])})

	stations = loaded


func _save_stations() -> void:
	var file: FileAccess = FileAccess.open(STATIONS_FILE, FileAccess.WRITE)
	if file == null:
		print("Cannot write radio stations: ", STATIONS_FILE)
		return
	file.store_string(JSON.stringify(stations, "\t"))
	file.close()


func add_station(station_name: String, url: String) -> void:
	stations.append({"name": station_name, "url": url})
	_save_stations()
	stations_changed.emit()


func remove_station(index: int) -> void:
	if index < 0 or index >= stations.size():
		return
	stations.remove_at(index)
	_save_stations()
	stations_changed.emit()


func get_stations() -> Array[Dictionary]:
	return stations
