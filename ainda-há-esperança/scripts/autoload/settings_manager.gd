extends Node

signal settings_changed

const DEFAULT_VOLUME := 0.7
const DEFAULT_RESOLUTION_INDEX := 1

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(960, 540),
	Vector2i(1152, 648),
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]

var master_volume: float = DEFAULT_VOLUME
var resolution_index: int = DEFAULT_RESOLUTION_INDEX


func _ready() -> void:
	apply_settings()


func set_master_volume(value: float) -> void:
	master_volume = clamp(value, 0.0, 1.0)
	_apply_volume()
	settings_changed.emit()


func set_resolution_index(value: int) -> void:
	resolution_index = clamp(value, 0, RESOLUTIONS.size() - 1)
	_apply_resolution()
	settings_changed.emit()


func get_current_resolution() -> Vector2i:
	return RESOLUTIONS[resolution_index]


func get_current_resolution_text() -> String:
	var resolution := get_current_resolution()
	return "%dx%d" % [resolution.x, resolution.y]


func apply_settings() -> void:
	_apply_volume()
	_apply_resolution()


func _apply_volume() -> void:
	var bus_index := AudioServer.get_bus_index("Master")

	if bus_index < 0:
		return

	if master_volume <= 0.0:
		AudioServer.set_bus_volume_db(bus_index, -80.0)
	else:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(master_volume))


func _apply_resolution() -> void:
	var resolution := get_current_resolution()

	DisplayServer.window_set_size(resolution)

	var screen_size := DisplayServer.screen_get_size()
	var centered_position := Vector2i(
		(screen_size.x - resolution.x) / 2,
		(screen_size.y - resolution.y) / 2
	)

	DisplayServer.window_set_position(centered_position)