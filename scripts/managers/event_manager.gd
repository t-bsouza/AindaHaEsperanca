class_name EventManager
extends Node

signal tutorial_triggered(message: String)
signal patient_event_triggered(event: Dictionary)
signal story_event_triggered(event: Dictionary)
signal narrative_event_triggered(pages: Array, character_sprite: String, diary_note: String)
signal patient_expired(character_id: String)

const SCHEDULE_PATH := "res://data/events/schedule.json"

var _schedule: Dictionary = {}
var _triggered_ids: Array[String] = []

var _active_patient_char_id: String = ""
var _active_patient_expiry_hour: int = -1
var _plague_mutated: bool = false


func reset() -> void:
	_triggered_ids.clear()
	_active_patient_char_id = ""
	_active_patient_expiry_hour = -1
	_plague_mutated = false


func load_schedule(path: String = SCHEDULE_PATH) -> void:
	var data := JsonDataLoader.load_json(path)
	_schedule = data.get("schedule", {})


func set_plague_mutated(value: bool) -> void:
	_plague_mutated = value


func is_plague_mutated() -> bool:
	return _plague_mutated


# Called by GameState whenever time advances. Triggers any events scheduled
# at or before current_hour that haven't fired yet this day.
func check_events(day: int, current_hour: int) -> void:
	var day_events: Array = _schedule.get(str(day), [])

	for event in day_events:
		var event_hour := int(event.get("hour", -1))
		var event_id := str(event.get("id", ""))

		if event_hour > current_hour:
			continue
		if _triggered_ids.has(event_id):
			continue

		_triggered_ids.append(event_id)
		_fire_event(event)


# Called after time advances to check if the waiting patient ran out of time.
func check_patient_expiry(current_hour: int) -> void:
	if _active_patient_char_id.is_empty():
		return
	if _active_patient_expiry_hour < 0:
		return
	if current_hour >= _active_patient_expiry_hour:
		var char_id := _active_patient_char_id
		_active_patient_char_id = ""
		_active_patient_expiry_hour = -1
		patient_expired.emit(char_id)


func register_active_patient(char_id: String, arrival_hour: int, expires_in: int) -> void:
	_active_patient_char_id = char_id
	_active_patient_expiry_hour = arrival_hour + expires_in


func clear_active_patient() -> void:
	_active_patient_char_id = ""
	_active_patient_expiry_hour = -1


func get_hours_remaining(current_hour: int) -> int:
	if _active_patient_expiry_hour < 0:
		return 0
	return max(0, _active_patient_expiry_hour - current_hour)


func _fire_event(event: Dictionary) -> void:
	var type := str(event.get("type", ""))

	match type:
		"tutorial":
			tutorial_triggered.emit(str(event.get("message", "")))
		"patient":
			patient_event_triggered.emit(event)
		"story":
			story_event_triggered.emit(event)
		"narrative":
			var pages: Array = event.get("pages", [])
			var sprite := str(event.get("character_sprite", ""))
			var note := str(event.get("diary_note", ""))
			narrative_event_triggered.emit(pages, sprite, note)
