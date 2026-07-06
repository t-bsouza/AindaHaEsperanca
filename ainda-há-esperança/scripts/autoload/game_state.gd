extends Node

signal day_changed(new_day: int)
signal time_changed(current_hour: int)
signal diary_updated
signal resources_changed
signal family_changed
signal patient_changed(patient: Patient)
signal game_over_started

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const DIARY_SCENE_PATH := "res://scenes/diary.tscn"
const MENU_SCENE_PATH := "res://scenes/menu.tscn"

const PATIENTS_JSON_PATH := "res://data/characters/patients.json"
const FAMILY_JSON_PATH := "res://data/characters/family.json"
const DISEASES_JSON_PATH := "res://data/characters/diseases.json"

const REQUIRED_HERB_TOTAL := 3

var patient_manager: PatientManager
var resource_manager: ResourceManager
var time_manager: TimeManager
var family_manager: FamilyManager
var disease_manager: DiseaseManager

var diary_entries: Array[String] = []
var diary_summaries_by_day: Dictionary = {}

var current_day_actions: Array[String] = []
var current_day_patient_results: Array[String] = []

var game_finished: bool = false
var final_summary_written: bool = false

var current_patient_examined: bool = false

func _ready() -> void:
	_setup_managers()
	_load_static_data()


func start_new_game() -> void:
	_setup_managers()

	game_finished = false
	final_summary_written = false

	diary_entries.clear()
	diary_summaries_by_day.clear()
	current_day_actions.clear()
	current_day_patient_results.clear()

	time_manager.reset()
	resource_manager.reset()
	patient_manager.reset()
	patient_manager.load_total_campaign_patients(PATIENTS_JSON_PATH)
	family_manager.reset()
	disease_manager.load_from_json(DISEASES_JSON_PATH)

	_load_patients_for_current_day()

	resources_changed.emit()
	family_changed.emit()

	get_tree().change_scene_to_file(MAIN_SCENE_PATH)


func get_current_day() -> int:
	return time_manager.current_day


func get_day_name(day: int) -> String:
	match day:
		1:
			return "Segunda-feira"
		2:
			return "Terça-feira"
		3:
			return "Quarta-feira"
		4:
			return "Quinta-feira"
		5:
			return "Sexta-feira"
		6:
			return "Sábado"
		7:
			return "Domingo"
		_:
			return "Dia desconhecido"


func get_current_day_name() -> String:
	return get_day_name(get_current_day())


func get_current_hour() -> int:
	return time_manager.current_hour


func get_current_patient() -> Patient:
	return patient_manager.current_patient


func get_resources() -> Dictionary:
	return resource_manager.get_snapshot()


func get_family() -> Dictionary:
	return family_manager.get_snapshot()


func get_artemisia() -> int:
	return resource_manager.get_resource(ResourceManager.ARTEMISIA)


func get_valeriana() -> int:
	return resource_manager.get_resource(ResourceManager.VALERIANA)


func get_salvia() -> int:
	return resource_manager.get_resource(ResourceManager.SALVIA)


func get_diary_title() -> String:
	if game_finished:
		if patient_manager.get_survived_count() <= 0:
			return "Game Over"

		if patient_manager.get_dead_count() <= 0:
			return "Vitória"

		return "Fim da Semana"

	return "Diário"


func get_diary_entries_newest_first() -> Array[String]:
	var entries := diary_entries.duplicate()
	entries.reverse()
	return entries


func get_day_summary(day: int) -> String:
	return str(diary_summaries_by_day.get(day, ""))


func treat_current_patient_with_combination(combination: Dictionary) -> bool:
	if game_finished:
		return false

	if not patient_manager.has_current_patient():
		return false

	if not resource_manager.is_valid_herb_combination(combination, REQUIRED_HERB_TOTAL):
		var invalid_message := "Tentei preparar uma mistura, mas errei a proporção. Preciso usar exatamente três porções de ervas."
		current_day_actions.append(invalid_message)
		add_diary_entry(invalid_message)
		return false

	if not resource_manager.has_herb_combination(combination):
		var insufficient_message := "Tentei preparar uma mistura, mas minhas ervas não foram suficientes."
		current_day_actions.append(insufficient_message)
		add_diary_entry(insufficient_message)
		return false

	if not resource_manager.consume_herb_combination(combination):
		var consume_error_message := "Tentei preparar a mistura, mas algo deu errado ao separar as ervas."
		current_day_actions.append(consume_error_message)
		add_diary_entry(consume_error_message)
		return false

	var patient := patient_manager.current_patient
	var effect_data := disease_manager.get_effect_for_combination(patient.disease_name, combination)

	var mixture_name := str(effect_data.get("display_name", "mistura desconhecida"))
	var outcome := str(effect_data.get("outcome", "bad"))

	var result := patient_manager.treat_current_patient_with_herbs(mixture_name, outcome)

	current_day_actions.append(
		"Preparei %s para %s usando %s." % [
			mixture_name,
			patient.patient_name,
			resource_manager.describe_herb_combination(combination),
		]
	)

	_register_patient_result(patient, result)
	_check_early_game_over()

	if not game_finished:
		advance_time(3)

	return true


func refuse_current_patient() -> void:
	if game_finished:
		return

	if not patient_manager.has_current_patient():
		return

	var patient := patient_manager.current_patient
	patient_manager.refuse_current_patient()

	current_day_actions.append("Recusei atender %s." % patient.patient_name)
	current_day_patient_results.append(
		"%s partiu sem tratamento, e não sei se sobreviverá à noite." % patient.patient_name
	)

	advance_time(1)


func collect_herbs() -> void:
	if game_finished:
		return

	resource_manager.collect_herbs()

	current_day_actions.append(
		"Saí para coletar ervas nos arredores da vila e trouxe um pouco de cada planta."
	)

	advance_time(2)


func rest() -> void:
	if game_finished:
		return

	current_day_actions.append("Tentei descansar por algumas horas antes de continuar.")
	advance_time(2)


func advance_time(hours: int) -> void:
	if game_finished:
		return

	time_manager.advance_time(hours)


func end_day() -> void:
	if game_finished:
		return

	patient_manager.progress_all_patients()
	_register_waiting_patients_at_day_end()
	_write_day_summary(time_manager.current_day)
	_check_early_game_over()

	if game_finished:
		get_tree().change_scene_to_file(DIARY_SCENE_PATH)
		return

	current_day_actions.clear()
	current_day_patient_results.clear()

	if time_manager.current_day >= time_manager.max_days:
		end_game()
		return

	time_manager.start_next_day()
	_load_patients_for_current_day()

	get_tree().change_scene_to_file(DIARY_SCENE_PATH)


func end_game() -> void:
	if game_finished:
		return

	_write_final_week_summary()
	game_finished = true
	game_over_started.emit()

	get_tree().change_scene_to_file(DIARY_SCENE_PATH)


func return_to_menu_after_game_over() -> void:
	get_tree().change_scene_to_file(MENU_SCENE_PATH)


func add_diary_entry(text: String) -> void:
	if text.strip_edges().is_empty():
		return

	diary_entries.append(text)
	diary_updated.emit()


func _setup_managers() -> void:
	patient_manager = get_node_or_null("PatientManager") as PatientManager
	if patient_manager == null:
		patient_manager = PatientManager.new()
		patient_manager.name = "PatientManager"
		add_child(patient_manager)

	resource_manager = get_node_or_null("ResourceManager") as ResourceManager
	if resource_manager == null:
		resource_manager = ResourceManager.new()
		resource_manager.name = "ResourceManager"
		add_child(resource_manager)

	time_manager = get_node_or_null("TimeManager") as TimeManager
	if time_manager == null:
		time_manager = TimeManager.new()
		time_manager.name = "TimeManager"
		add_child(time_manager)

	family_manager = get_node_or_null("FamilyManager") as FamilyManager
	if family_manager == null:
		family_manager = FamilyManager.new()
		family_manager.name = "FamilyManager"
		add_child(family_manager)

	disease_manager = get_node_or_null("DiseaseManager") as DiseaseManager
	if disease_manager == null:
		disease_manager = DiseaseManager.new()
		disease_manager.name = "DiseaseManager"
		add_child(disease_manager)

	_connect_signal_once(patient_manager.patient_changed, _on_patient_changed)
	_connect_signal_once(patient_manager.queue_empty, _on_queue_empty)
	_connect_signal_once(resource_manager.resources_changed, _on_resources_changed)
	_connect_signal_once(time_manager.day_changed, _on_day_changed)
	_connect_signal_once(time_manager.time_changed, _on_time_changed)
	_connect_signal_once(time_manager.night_started, _on_night_started)
	_connect_signal_once(time_manager.game_days_finished, _on_game_days_finished)
	_connect_signal_once(family_manager.family_changed, _on_family_changed)


func _connect_signal_once(source_signal: Signal, callable: Callable) -> void:
	if not source_signal.is_connected(callable):
		source_signal.connect(callable)


func _load_static_data() -> void:
	disease_manager.load_from_json(DISEASES_JSON_PATH)
	family_manager.load_from_json(FAMILY_JSON_PATH)


func _load_patients_for_current_day() -> void:
	patient_manager.load_patients_from_json(time_manager.current_day, PATIENTS_JSON_PATH)


func _on_patient_changed(patient: Patient) -> void:
	patient_changed.emit(patient)

func examine_current_patient() -> Array[String]:
	if not patient_manager.has_current_patient():
		return []

	var patient := patient_manager.current_patient

	var symptoms := patient.examine()

	current_day_actions.append(
		"Examinei %s." % patient.patient_name
	)

	return symptoms


func _on_queue_empty() -> void:
	var message := "Atendi todos os pacientes que chegaram até mim."

	if not current_day_actions.has(message):
		current_day_actions.append(message)


func _on_resources_changed(_resources: Dictionary) -> void:
	resources_changed.emit()


func _on_family_changed(_members: Dictionary) -> void:
	family_changed.emit()


func _on_day_changed(new_day: int) -> void:
	day_changed.emit(new_day)


func _on_time_changed(new_hour: int) -> void:
	time_changed.emit(new_hour)


func _on_night_started(_day_finished: int) -> void:
	end_day()


func _on_game_days_finished() -> void:
	end_game()


func _register_patient_result(patient: Patient, result: Patient.HealthState) -> void:
	current_day_patient_results.append(
		GameNarrativeService.build_patient_treatment_result_text(patient, result)
	)


func _register_waiting_patients_at_day_end() -> void:
	for patient in patient_manager.get_unresolved_patients():
		if patient.current_health_state == Patient.HealthState.DEAD:
			current_day_patient_results.append("%s não resistiu enquanto aguardava atendimento." % patient.patient_name)
		else:
			current_day_patient_results.append("%s terminou o dia ainda aguardando, em estado incerto." % patient.patient_name)


func _write_day_summary(day_finished: int) -> void:
	var text := GameNarrativeService.build_day_summary(
		get_day_name(day_finished),
		current_day_actions,
		current_day_patient_results
	)

	diary_summaries_by_day[day_finished] = text
	add_diary_entry(text)


func _write_final_week_summary() -> void:
	if final_summary_written:
		return

	final_summary_written = true

	var stats := patient_manager.get_final_statistics()
	var survived_count := int(stats["survived"])
	var dead_count := int(stats["dead"])
	var total_count := int(stats["total"])

	var dead_patient_names := patient_manager.get_dead_patient_names()
	var survived_patient_names := patient_manager.get_survived_patient_names()

	var text := GameNarrativeService.build_final_week_summary(
		survived_count,
		dead_count,
		total_count,
		dead_patient_names,
		survived_patient_names
	)

	add_diary_entry(text)


func _check_early_game_over() -> void:
	if game_finished:
		return

	var total_campaign_patients := patient_manager.get_total_campaign_patients_count()

	if total_campaign_patients <= 0:
		return

	if patient_manager.get_dead_count() < total_campaign_patients:
		return

	_write_game_over_summary()
	game_finished = true
	game_over_started.emit()


func _write_game_over_summary() -> void:
	if final_summary_written:
		return

	final_summary_written = true

	var dead_count := patient_manager.get_dead_count()
	var total_count := patient_manager.get_total_campaign_patients_count()
	var dead_patient_names := patient_manager.get_dead_patient_names()

	var text := GameNarrativeService.build_game_over_summary(
		dead_count,
		total_count,
		dead_patient_names
	)

	add_diary_entry(text)
