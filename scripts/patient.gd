class_name Patient
extends Node

@export var patient_name: String = ""
@export var age: int = 0
@export var occupation: String = ""

@export var disease_name: String = ""
@export var symptoms: Array[String] = []
@export var severity: int = 0

@export var has_plague: bool = false
@export var plague_mutated: bool = false
@export var plague_postponed: bool = false
@export var resource_multiplier: int = 1
@export var is_story_only: bool = false
@export var auto_heals_after_cure: bool = false

@export_multiline var introduction_dialogue: String = ""
@export_multiline var examination_dialogue: String = ""
@export_multiline var death_dialogue: String = ""
@export_multiline var cured_dialogue: String = ""

var sprite_path: String = ""
var arrival_hour: int = -1
var expires_at_hour: int = -1
var was_examined: bool = false
var was_treated: bool = false
var plague_treated: bool = false

enum HealthState {
	WAITING,
	STABLE,
	WEAK,
	CRITICAL,
	TERMINAL,
	DEAD,
	RECOVERED,
}

var current_health_state: HealthState = HealthState.WAITING


static func from_dict(data: Dictionary) -> Patient:
	var p := Patient.new()

	p.patient_name = str(data.get("name", ""))
	p.age = int(data.get("age", 0))
	p.occupation = str(data.get("occupation", ""))

	p.has_plague = bool(data.get("has_plague", false))
	p.resource_multiplier = int(data.get("resource_multiplier", 1))
	p.is_story_only = bool(data.get("is_story_only", false))
	p.auto_heals_after_cure = bool(data.get("auto_heals_after_cure", false))
	p.sprite_path = str(data.get("sprite", ""))

	p.introduction_dialogue = str(data.get("introduction_dialogue", ""))
	p.examination_dialogue = str(data.get("examination_dialogue", ""))
	p.death_dialogue = str(data.get("death_dialogue", ""))
	p.cured_dialogue = str(data.get("cured_dialogue", ""))

	# Resolve disease: single disease_name or random from disease_options
	var disease_options: Array = data.get("disease_options", [])
	if not disease_options.is_empty():
		p.disease_name = str(disease_options[randi() % disease_options.size()])
	else:
		p.disease_name = str(data.get("disease_name", ""))

	p.severity = int(data.get("severity", 35))
	p.current_health_state = p._state_from_severity(p.severity)

	return p


func _state_from_severity(value: int) -> HealthState:
	if value >= 80:
		return HealthState.TERMINAL
	if value >= 65:
		return HealthState.CRITICAL
	if value >= 45:
		return HealthState.WEAK
	return HealthState.STABLE


func examine() -> Array[String]:
	was_examined = true
	return symptoms


func apply_treatment(outcome: String) -> HealthState:
	was_treated = true

	match outcome:
		"good":
			_improve()
		"neutral":
			pass
		"postpone":
			plague_postponed = true
		"cure_plague":
			has_plague = false
			plague_treated = true
			plague_postponed = false
			if auto_heals_after_cure:
				current_health_state = HealthState.RECOVERED
		"bad", _:
			_worsen()

	return current_health_state


func _improve() -> void:
	match current_health_state:
		HealthState.TERMINAL:
			current_health_state = HealthState.CRITICAL
		HealthState.CRITICAL:
			current_health_state = HealthState.WEAK
		HealthState.WEAK:
			current_health_state = HealthState.STABLE
		HealthState.STABLE, HealthState.WAITING:
			current_health_state = HealthState.RECOVERED


func _worsen() -> void:
	match current_health_state:
		HealthState.WAITING, HealthState.STABLE:
			current_health_state = HealthState.WEAK
		HealthState.WEAK:
			current_health_state = HealthState.CRITICAL
		HealthState.CRITICAL:
			current_health_state = HealthState.TERMINAL
		HealthState.TERMINAL:
			current_health_state = HealthState.DEAD
		HealthState.RECOVERED:
			current_health_state = HealthState.WEAK


func progress_disease() -> void:
	if current_health_state in [HealthState.DEAD, HealthState.RECOVERED]:
		return

	# Postpone effect: skip progression this cycle, then clear flag
	if plague_postponed:
		plague_postponed = false
		return

	_worsen()


func is_dead() -> bool:
	return current_health_state == HealthState.DEAD


func is_alive() -> bool:
	return not is_dead()


func is_terminal() -> bool:
	return current_health_state == HealthState.TERMINAL


func get_health_state_text() -> String:
	match current_health_state:
		HealthState.WAITING:
			return "Aguardando atendimento"
		HealthState.STABLE:
			return "Estável"
		HealthState.WEAK:
			return "Debilitado"
		HealthState.CRITICAL:
			return "Crítico"
		HealthState.TERMINAL:
			return "Terminal"
		HealthState.DEAD:
			return "Morto"
		HealthState.RECOVERED:
			return "Recuperado"

	return "Estado desconhecido"


func get_plague_status_text() -> String:
	if not has_plague:
		return ""
	return "[PRAGA ATIVA]"


func get_summary() -> Dictionary:
	return {
		"name": patient_name,
		"disease": disease_name,
		"has_plague": has_plague,
		"state": current_health_state,
		"state_text": get_health_state_text(),
		"examined": was_examined,
		"treated": was_treated,
	}
