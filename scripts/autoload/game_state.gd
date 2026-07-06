extends Node

signal day_changed(new_day: int)
signal time_changed(current_hour: int)
signal diary_updated
signal resources_changed
signal patient_changed(patient: Patient)
signal event_notification(message: String)
signal narrative_event(pages: Array, character_sprite: String)
signal game_over_started

const MAIN_SCENE_PATH  := "res://scenes/main.tscn"
const DIARY_SCENE_PATH := "res://scenes/diary.tscn"
const MENU_SCENE_PATH  := "res://scenes/menu.tscn"

const DISEASES_PATH   := "res://data/characters/diseases.json"
const CHARACTERS_PATH := "res://data/characters/characters.json"
const SCHEDULE_PATH   := "res://data/events/schedule.json"

const _EventManagerScript = preload("res://scripts/managers/event_manager.gd")

const HERB_COLLECT_TIME := 3

var patient_manager: PatientManager
var resource_manager: ResourceManager
var time_manager: TimeManager
var disease_manager: DiseaseManager
var event_manager: Node

var diary_entries: Array[String] = []
var diary_summaries_by_day: Dictionary = {}
var current_day_log: Array[String] = []

var game_finished: bool = false
var final_summary_written: bool = false

# Day 7: survivors with plague come back. We queue them manually.
var _day7_queue: Array[Patient] = []
var _day7_index: int = 0


func _ready() -> void:
	_setup_managers()
	disease_manager.load_from_json(DISEASES_PATH)


func start_new_game() -> void:
	_setup_managers()

	game_finished = false
	final_summary_written = false
	diary_entries.clear()
	diary_summaries_by_day.clear()
	current_day_log.clear()
	_day7_queue.clear()
	_day7_index = 0

	time_manager.reset()
	resource_manager.reset()
	patient_manager.reset()
	patient_manager.load_characters(CHARACTERS_PATH)
	disease_manager.load_from_json(DISEASES_PATH)
	event_manager.reset()
	event_manager.load_schedule(SCHEDULE_PATH)

	get_tree().change_scene_to_file(MAIN_SCENE_PATH)


# ── Time ──────────────────────────────────────────────────────────────────────

func get_current_day() -> int:
	return time_manager.current_day


func get_current_hour() -> int:
	return time_manager.current_hour


func get_day_name(day: int) -> String:
	match day:
		1: return "Segunda-feira"
		2: return "Terça-feira"
		3: return "Quarta-feira"
		4: return "Quinta-feira"
		5: return "Sexta-feira"
		6: return "Sábado"
		7: return "Domingo"
		_: return "Dia %d" % day


func get_current_day_name() -> String:
	return get_day_name(time_manager.current_day)


# ── Accessors ─────────────────────────────────────────────────────────────────

func get_current_patient() -> Patient:
	return patient_manager.current_patient


func get_artemisia() -> int:
	return resource_manager.get_resource(ResourceManager.ARTEMISIA)


func get_valeriana() -> int:
	return resource_manager.get_resource(ResourceManager.VALERIANA)


func get_salvia() -> int:
	return resource_manager.get_resource(ResourceManager.SALVIA)


func get_diary_entries_newest_first() -> Array[String]:
	var entries := diary_entries.duplicate()
	entries.reverse()
	return entries


func get_day_summary(day: int) -> String:
	return str(diary_summaries_by_day.get(day, ""))


func get_hours_remaining_for_patient() -> int:
	return event_manager.get_hours_remaining(time_manager.current_hour)


# ── Player actions ─────────────────────────────────────────────────────────────

func examine_current_patient() -> Array[String]:
	if not patient_manager.has_current_patient():
		return []
	var patient := patient_manager.current_patient

	# Populate symptoms from disease data on first examination
	if patient.symptoms.is_empty() and not patient.disease_name.is_empty():
		var disease_symptoms: Array = disease_manager.get_disease_symptoms(patient.disease_name)
		patient.symptoms.assign(disease_symptoms)

	# Plague adds its own visible symptoms
	if patient.has_plague and not patient.symptoms.has("manchas escuras no pescoço"):
		patient.symptoms.append("manchas escuras no pescoço")

	var symptoms: Array[String] = patient.examine()
	_log("Examinei %s." % patient.patient_name)
	return symptoms


# Returns the outcome string ("good", "bad", "neutral", etc.) if treatment was applied,
# or "" if it could not be applied (no patient, not enough herbs, etc.).
func treat_current_patient(combination: Array) -> String:
	if game_finished:
		return ""
	if not patient_manager.has_current_patient():
		return ""

	var patient := patient_manager.current_patient

	if combination.size() != 3:
		_log("A mistura precisa de exatamente três ervas.")
		return ""

	if not resource_manager.can_apply_combination(combination, patient.resource_multiplier):
		var msg := "Minhas ervas não foram suficientes."
		if patient.resource_multiplier > 1:
			msg = "Preciso do dobro de ervas para tratar %s." % patient.patient_name
		_log(msg)
		add_diary_entry(msg)
		return ""

	resource_manager.consume_combination(combination, patient.resource_multiplier)

	var effect: Dictionary = disease_manager.get_effect(patient, combination)
	var mixture_name: String = str(effect.get("display_name", "mistura desconhecida"))
	var outcome: String = str(effect.get("outcome", "bad"))

	# Terminal patient + bad outcome = instant death
	if patient.is_terminal() and outcome == "bad":
		patient._worsen()
		outcome = "dead_now"

	var state_before := patient.current_health_state
	if outcome != "dead_now":
		patient.apply_treatment(outcome)

	_log_treatment(patient, mixture_name, outcome, state_before, combination)
	_check_plague_cure(patient, outcome)

	patient_manager.resolve_current_patient_as_treated()
	event_manager.clear_active_patient()

	_check_game_over()

	if not game_finished:
		advance_time(3)

	return outcome


func refuse_current_patient() -> void:
	if game_finished or not patient_manager.has_current_patient():
		return
	var refused_name := patient_manager.current_patient.patient_name
	patient_manager.resolve_current_patient_as_refused()
	event_manager.clear_active_patient()
	_log("Recusei atender %s." % refused_name)
	advance_time(1)


func collect_herbs() -> void:
	if game_finished:
		return
	resource_manager.collect_herbs()
	_log("Saí para coletar ervas nos arredores da vila.")
	advance_time(HERB_COLLECT_TIME)


func collect_herbs_from_location(location: String) -> void:
	if game_finished:
		return
	resource_manager.collect_from_location(location)
	var place_name: String = {"porto": "Porto", "floresta": "Floresta", "campo": "Campo"}.get(location, location)
	_log("Fui coletar ervas no %s." % place_name)
	advance_time(HERB_COLLECT_TIME)


func rest() -> void:
	if game_finished:
		return
	_log("Descansai por algumas horas.")
	advance_time(1)


# Called by main.gd after the scene loads to fire events already scheduled
# at the current hour (e.g. the Day 1 tutorial at 08:00).
func check_initial_events() -> void:
	event_manager.check_events(time_manager.current_day, time_manager.current_hour)


func advance_time(hours: int) -> void:
	if game_finished or hours <= 0:
		return

	time_manager.advance_time(hours)

	var day := time_manager.current_day
	var hour := time_manager.current_hour

	if hour < time_manager.night_hour:
		# Fire any scheduled events that just became due
		event_manager.check_events(day, hour)
		# Check if the waiting patient ran out of time
		if not patient_manager.has_current_patient():
			event_manager.check_patient_expiry(hour)

		time_changed.emit(hour)
	# Night is handled via TimeManager signal → _on_night_started


# ── Diary ─────────────────────────────────────────────────────────────────────

func get_diary_title() -> String:
	if game_finished:
		if patient_manager.get_survived_count() == 0:
			return "Game Over"
		return "Fim da Semana"
	return "Diário"


func add_diary_entry(text: String) -> void:
	if text.strip_edges().is_empty():
		return
	diary_entries.append(text)
	diary_updated.emit()


# ── Internal setup ─────────────────────────────────────────────────────────────

func _setup_managers() -> void:
	patient_manager = _get_or_create("PatientManager", PatientManager)
	resource_manager = _get_or_create("ResourceManager", ResourceManager)
	time_manager     = _get_or_create("TimeManager", TimeManager)
	disease_manager  = _get_or_create("DiseaseManager", DiseaseManager)
	var em_node := get_node_or_null("EventManager")
	if em_node == null:
		em_node = _EventManagerScript.new()
		em_node.name = "EventManager"
		add_child(em_node)
	event_manager = em_node

	_connect_once(patient_manager.patient_changed, _on_patient_changed)
	_connect_once(resource_manager.resources_changed, _on_resources_changed)
	_connect_once(time_manager.night_started, _on_night_started)
	_connect_once(time_manager.game_days_finished, _on_game_days_finished)
	var em := event_manager as _EventManagerScript
	if em != null:
		_connect_once(em.tutorial_triggered, _on_tutorial_event)
		_connect_once(em.patient_event_triggered, _on_patient_event)
		_connect_once(em.story_event_triggered, _on_story_event)
		_connect_once(em.narrative_event_triggered, _on_narrative_event)
		_connect_once(em.patient_expired, _on_patient_expired)


func _get_or_create(node_name: String, type) -> Node:
	var existing := get_node_or_null(node_name)
	if existing != null:
		return existing
	var instance: Node = type.new()
	instance.name = node_name
	add_child(instance)
	return instance


func _connect_once(sig: Signal, callable: Callable) -> void:
	if not sig.is_connected(callable):
		sig.connect(callable)


# ── Event handlers ─────────────────────────────────────────────────────────────

func _on_patient_changed(patient: Patient) -> void:
	patient_changed.emit(patient)


func _on_resources_changed(_snap: Dictionary) -> void:
	resources_changed.emit()


func _on_tutorial_event(message: String) -> void:
	add_diary_entry(message)
	event_notification.emit(message)


func _on_narrative_event(pages: Array, character_sprite: String, diary_note: String) -> void:
	if not diary_note.is_empty():
		add_diary_entry(diary_note)
	narrative_event.emit(pages, character_sprite)


func _on_patient_event(event: Dictionary) -> void:
	# Don't spawn a new patient if one is already being seen
	if patient_manager.has_current_patient():
		return

	var patient := patient_manager.spawn_patient_from_event(event, time_manager.current_day)
	if patient == null:
		return

	# If plague has already mutated, ensure the newly spawned patient's plague reflects that
	var em := event_manager as _EventManagerScript
	if em != null and patient.has_plague and em.is_plague_mutated():
		patient.plague_mutated = true

	var expires_in := int(event.get("expires_in", 2))
	var char_id := str(event.get("character_id", ""))
	event_manager.register_active_patient(char_id, time_manager.current_hour, expires_in)

	var hours_str := "%d hora%s" % [expires_in, "s" if expires_in != 1 else ""]
	_log("%s chegou ao consultório. Estará disponível por %s." % [patient.patient_name, hours_str])


func _on_story_event(event: Dictionary) -> void:
	# Story events show a character who gives narrative hints but is not treated
	if patient_manager.has_current_patient():
		return

	var patient := patient_manager.spawn_patient_from_event(event, time_manager.current_day)
	if patient == null:
		return

	var expires_in := int(event.get("expires_in", 2))
	var char_id := str(event.get("character_id", ""))
	event_manager.register_active_patient(char_id, time_manager.current_hour, expires_in)


func _on_patient_expired(char_id: String) -> void:
	patient_manager.resolve_expired_patient(char_id)
	_log("O tempo passou e o visitante foi embora sem ser atendido.")
	_check_game_over()


func _on_night_started(_day: int) -> void:
	_end_day()


func _on_game_days_finished() -> void:
	_end_game()


# ── Day / Game end ─────────────────────────────────────────────────────────────

func _end_day() -> void:
	if game_finished:
		return

	# Mutate plague at end of day 5 so day 6 starts with mutated plague
	if time_manager.current_day == 5:
		event_manager.set_plague_mutated(true)
		_mutate_plague_on_all_patients()

	patient_manager.progress_all_surviving_patients()
	_write_day_summary(time_manager.current_day)
	_check_game_over()

	if game_finished:
		get_tree().change_scene_to_file(DIARY_SCENE_PATH)
		return

	current_day_log.clear()

	if time_manager.current_day >= time_manager.max_days:
		_end_game()
		return

	time_manager.start_next_day()
	day_changed.emit(time_manager.current_day)

	# On day 7, queue up all survivors with active plague
	if time_manager.current_day == 7:
		_prepare_day7_queue()

	get_tree().change_scene_to_file(DIARY_SCENE_PATH)


func _end_game() -> void:
	if game_finished:
		return
	_write_final_summary()
	game_finished = true
	game_over_started.emit()
	get_tree().change_scene_to_file(DIARY_SCENE_PATH)


func return_to_menu() -> void:
	get_tree().change_scene_to_file(MENU_SCENE_PATH)


# ── Day 7 special: survivors with plague come back ─────────────────────────────

func _prepare_day7_queue() -> void:
	# Day 7: plague reaches every surviving, non-recovered character.
	for patient in patient_manager.get_all_surviving_patients():
		if patient.current_health_state != Patient.HealthState.RECOVERED:
			if not patient.has_plague:
				patient.has_plague = true
			patient.plague_mutated = true
	_day7_queue = patient_manager.get_all_characters_for_day7()
	_day7_index = 0
	if not _day7_queue.is_empty():
		_spawn_next_day7_patient()


func _spawn_next_day7_patient() -> void:
	if _day7_index >= _day7_queue.size():
		return
	var patient := _day7_queue[_day7_index]
	_day7_index += 1
	patient_manager.current_patient = patient
	patient.was_treated = false
	patient.was_examined = false
	patient_manager.patient_changed.emit(patient)
	event_manager.register_active_patient("day7_%d" % _day7_index, time_manager.current_hour, 4)


# ── Public queries ─────────────────────────────────────────────────────────────

# Returns Array of Dictionaries with keys: id, display_name, symptoms, recipe_key
# Only includes diseases marked known_to_player in diseases.json.
func get_known_diseases() -> Array:
	return disease_manager.get_known_diseases()


# ── Helpers ────────────────────────────────────────────────────────────────────

func _log(text: String) -> void:
	if text.strip_edges().is_empty():
		return
	current_day_log.append(text)
	add_diary_entry(text)


func _log_treatment(patient: Patient, mixture_name: String, outcome: String, _state_before: Patient.HealthState, combination: Array) -> void:
	var combo_desc: String = resource_manager.describe_combination(combination)

	var result_text := ""
	match outcome:
		"good":
			result_text = "%s melhorou." % patient.patient_name
		"neutral":
			result_text = "O estado de %s se manteve estável." % patient.patient_name
		"postpone":
			result_text = "A mistura parece segurar a doença de %s por algum tempo." % patient.patient_name
		"cure_plague":
			result_text = "A praga de %s foi curada! Mas a doença subjacente permanece." % patient.patient_name
		"bad":
			result_text = "%s piorou com a mistura." % patient.patient_name
		"dead_now":
			result_text = "%s não resistiu à mistura errada no estado terminal." % patient.patient_name
		_:
			result_text = "A mistura teve efeito desconhecido em %s." % patient.patient_name

	_log("Apliquei '%s' (%s) em %s. %s" % [
		mixture_name, combo_desc, patient.patient_name, result_text
	])


func _check_plague_cure(patient: Patient, outcome: String) -> void:
	if outcome == "cure_plague" and patient.auto_heals_after_cure:
		add_diary_entry(patient.cured_dialogue)


func _mutate_plague_on_all_patients() -> void:
	for p in patient_manager.get_all_surviving_patients():
		if p.has_plague:
			p.plague_mutated = true
	add_diary_entry("A praga mudou. Os tratamentos antigos não funcionam mais.")


func _check_game_over() -> void:
	if game_finished:
		return
	# All seen characters are dead → game over
	var seen_count := patient_manager.characters_seen.size()
	if seen_count > 0 and patient_manager.get_survived_count() == 0:
		_write_game_over_summary()
		game_finished = true
		game_over_started.emit()


func _write_day_summary(day: int) -> void:
	var day_name := get_day_name(day)
	var lines: Array[String] = ["Diário — %s" % day_name, ""]

	if current_day_log.is_empty():
		lines.append("O dia passou sem acontecimentos notáveis.")
	else:
		for entry in current_day_log:
			lines.append("• " + entry)

	var survivors := patient_manager.get_survived_names()
	var dead := patient_manager.get_dead_names()

	if not dead.is_empty():
		lines.append("")
		lines.append("Mortos: " + ", ".join(dead))
	if not survivors.is_empty():
		lines.append("Vivos: " + ", ".join(survivors))

	var summary := "\n".join(lines)
	diary_summaries_by_day[day] = summary
	add_diary_entry(summary)


func _write_final_summary() -> void:
	if final_summary_written:
		return
	final_summary_written = true

	var survived := patient_manager.get_survived_names()
	var dead     := patient_manager.get_dead_names()
	var lines: Array[String] = ["Fim da Semana", ""]

	if survived.is_empty():
		lines.append("Ninguém sobreviveu à praga.")
	else:
		lines.append("Sobreviventes: " + ", ".join(survived))

	if not dead.is_empty():
		lines.append("Falecidos: " + ", ".join(dead))

	add_diary_entry("\n".join(lines))


func _write_game_over_summary() -> void:
	if final_summary_written:
		return
	final_summary_written = true
	var dead := patient_manager.get_dead_names()
	var text := "Todos morreram para a praga.\n\nFalecidos: %s" % ", ".join(dead)
	add_diary_entry(text)
