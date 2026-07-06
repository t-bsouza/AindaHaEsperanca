class_name PatientManager
extends Node

signal patient_changed(patient: Patient)
signal queue_empty

const CHARACTERS_PATH := "res://data/characters/characters.json"

var current_patient: Patient = null

# Tracks every character that appeared, keyed by character_id.
# Allows checking if someone survived across days.
var characters_seen: Dictionary = {}
var dead_characters: Array[String] = []
var cured_characters: Array[String] = []

var _character_db: Dictionary = {}


func reset() -> void:
	current_patient = null
	characters_seen.clear()
	dead_characters.clear()
	cured_characters.clear()
	patient_changed.emit(null)


func load_characters(path: String = CHARACTERS_PATH) -> void:
	var data := JsonDataLoader.load_json(path)
	_character_db = data.get("characters", {})


func spawn_patient_from_event(event: Dictionary, day: int = 1) -> Patient:
	var char_id := str(event.get("character_id", ""))

	if char_id.is_empty():
		push_warning("PatientManager: evento sem character_id")
		return null

	var char_data: Dictionary = _character_db.get(char_id, {})

	# Recover a persistent patient if we've seen them before (health state persists)
	if characters_seen.has(char_id):
		var existing: Patient = characters_seen[char_id]
		if existing.is_dead():
			return null
		# Apply day-specific dialogue override if available
		_apply_day_dialogues(existing, char_data, day)
		current_patient = existing
		current_patient.was_treated = false
		current_patient.was_examined = false
		patient_changed.emit(current_patient)
		return current_patient

	if char_data.is_empty():
		push_warning("PatientManager: personagem não encontrado: %s" % char_id)
		return null

	var patient := Patient.from_dict(char_data)
	_apply_day_dialogues(patient, char_data, day)
	characters_seen[char_id] = patient
	current_patient = patient
	patient_changed.emit(current_patient)
	return patient


func _apply_day_dialogues(patient: Patient, char_data: Dictionary, day: int) -> void:
	var day_dialogues: Dictionary = char_data.get("day_dialogues", {})
	var override: Dictionary = day_dialogues.get(str(day), {})
	if override.has("introduction_dialogue"):
		patient.introduction_dialogue = str(override["introduction_dialogue"])
	if override.has("examination_dialogue"):
		patient.examination_dialogue = str(override["examination_dialogue"])


func dismiss_current_patient() -> void:
	current_patient = null
	patient_changed.emit(null)
	queue_empty.emit()


func resolve_current_patient_as_treated() -> void:
	if current_patient == null:
		return

	var char_id := _find_char_id(current_patient)

	if current_patient.current_health_state == Patient.HealthState.DEAD:
		if not dead_characters.has(char_id):
			dead_characters.append(char_id)
	elif current_patient.current_health_state == Patient.HealthState.RECOVERED:
		if not cured_characters.has(char_id):
			cured_characters.append(char_id)

	current_patient = null
	patient_changed.emit(null)


func resolve_current_patient_as_refused() -> void:
	if current_patient == null:
		return
	if current_patient.current_health_state != Patient.HealthState.RECOVERED:
		current_patient._worsen()
	current_patient = null
	patient_changed.emit(null)


func resolve_expired_patient(char_id: String) -> void:
	if characters_seen.has(char_id):
		var patient: Patient = characters_seen[char_id]
		if patient.current_health_state != Patient.HealthState.RECOVERED:
			patient._worsen()
		if patient.is_dead() and not dead_characters.has(char_id):
			dead_characters.append(char_id)

	if current_patient != null:
		var current_id := _find_char_id(current_patient)
		if current_id == char_id:
			current_patient = null
			patient_changed.emit(null)


func has_current_patient() -> bool:
	return current_patient != null


func progress_all_surviving_patients() -> void:
	for char_id in characters_seen:
		var patient: Patient = characters_seen[char_id]
		if patient.is_alive():
			patient.progress_disease()
			if patient.is_dead() and not dead_characters.has(char_id):
				dead_characters.append(char_id)


func get_all_surviving_patients() -> Array[Patient]:
	var result: Array[Patient] = []
	for char_id in characters_seen:
		var patient: Patient = characters_seen[char_id]
		if patient.is_alive():
			result.append(patient)
	return result


func get_dead_count() -> int:
	return dead_characters.size()


func get_survived_count() -> int:
	var alive := 0
	for char_id in characters_seen:
		var patient: Patient = characters_seen[char_id]
		if patient.is_alive():
			alive += 1
	return alive


func get_dead_names() -> Array[String]:
	var names: Array[String] = []
	for char_id in dead_characters:
		if characters_seen.has(char_id):
			names.append(characters_seen[char_id].patient_name)
	return names


func get_survived_names() -> Array[String]:
	var names: Array[String] = []
	for char_id in characters_seen:
		var patient: Patient = characters_seen[char_id]
		if patient.is_alive():
			names.append(patient.patient_name)
	return names


func is_character_dead(char_id: String) -> bool:
	return dead_characters.has(char_id)


func get_patient_by_char_id(char_id: String) -> Patient:
	return characters_seen.get(char_id, null)


func get_all_characters_for_day7() -> Array[Patient]:
	var result: Array[Patient] = []
	for char_id in characters_seen:
		var patient: Patient = characters_seen[char_id]
		if patient.is_alive() and patient.current_health_state != Patient.HealthState.RECOVERED:
			result.append(patient)
	return result


func _find_char_id(patient: Patient) -> String:
	for char_id in characters_seen:
		if characters_seen[char_id] == patient:
			return char_id
	return ""
