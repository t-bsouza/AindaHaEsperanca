extends Node2D
@onready var day_label: Label = $CanvasLayer/DiaryPanel/LeftPage/LeftContent/DayLabel
@onready var time_label: Label = $CanvasLayer/DiaryPanel/LeftPage/LeftContent/TimeLabel
@onready var resources_label: Label = $CanvasLayer/DiaryPanel/LeftPage/LeftContent/ResourcesLabel
@onready var patient_label: Label = $CanvasLayer/DiaryPanel/LeftPage/LeftContent/PatientLabel
@onready var symptoms_label: Label = $CanvasLayer/DiaryPanel/LeftPage/LeftContent/SymptomsLabel
@onready var mixture_label: Label = $CanvasLayer/DiaryPanel/LeftPage/LeftContent/MixtureLabel

@onready var diary_button: Button = $CanvasLayer/DiaryPanel/RightPage/rightContent/DiaryButton
@onready var add_artemisia_button: Button = $CanvasLayer/DiaryPanel/RightPage/rightContent/ArtemisiaButton
@onready var add_valeriana_button: Button = $CanvasLayer/DiaryPanel/RightPage/rightContent/ValerianaButton
@onready var add_salvia_button: Button = $CanvasLayer/DiaryPanel/RightPage/rightContent/SalviaButton
@onready var apply_mixture_button: Button = $CanvasLayer/DiaryPanel/RightPage/rightContent/ApplyMixtureButton
@onready var clear_mixture_button: Button = $CanvasLayer/DiaryPanel/RightPage/rightContent/ClearMixtureButton
@onready var refuse_button: Button = $CanvasLayer/DiaryPanel/RightPage/rightContent/RefuseButton
@onready var collect_herbs_button: Button = $CanvasLayer/DiaryPanel/RightPage/rightContent/CollectHerbsButton
@onready var rest_button: Button = $CanvasLayer/DiaryPanel/RightPage/rightContent/RestButton
@onready var back_button: Button = $CanvasLayer/DiaryPanel/RightPage/rightContent/BackButton

@onready var action_menu: CanvasLayer = $CanvasLayer
@onready var world_diary_button: TextureButton = $background/diaryButton

@onready var background_blocker_right = $CanvasLayer/DiaryPanel/BackgroundBlockerRight
@onready var background_blocker_left = $CanvasLayer/DiaryPanel/BackgroundBlockerLeft

@onready var patient_display: Control = $Character
@onready var patient_sprite: TextureRect = $Character/CharacterSprite

@onready var page_1 = $CanvasLayer/DiaryPanel/marca_pagina_pages/page_1
@onready var page_2 = $CanvasLayer/DiaryPanel/marca_pagina_pages/page_2
@onready var page_3 = $CanvasLayer/DiaryPanel/marca_pagina_pages/page_3
@onready var page_4 = $CanvasLayer/DiaryPanel/marca_pagina_pages/page_4
@onready var page_5 = $CanvasLayer/DiaryPanel/marca_pagina_pages/page_5
@onready var page_6 = $CanvasLayer/DiaryPanel/marca_pagina_pages/page_6
@onready var page_7 = $CanvasLayer/DiaryPanel/marca_pagina_pages/page_7

@onready var diary_panel: Control = $CanvasLayer/DiaryPanel

@onready var current_info_container: Control = $CanvasLayer/DiaryPanel/LeftPage/LeftContent
@onready var day_log_container: Control = $CanvasLayer/DiaryPanel/LeftPage/DayLogContainer
@onready var page_back_button: Button = $CanvasLayer/DiaryPanel/LeftPage/DayLogContainer/backPage

@onready var selected_day_label: Label = $CanvasLayer/DiaryPanel/LeftPage/DayLogContainer/SelectedDayLabel
@onready var day_log_label: RichTextLabel = $CanvasLayer/DiaryPanel/LeftPage/DayLogContainer/DayLogLabel

@onready var speech_bubble: PanelContainer = $Character/SpeechBubble
@onready var speech_text: RichTextLabel = $Character/SpeechBubble/MarginContainer/VBoxContainer/SpeechText
@onready var examine_button: Button = $Character/SpeechBubble/MarginContainer/VBoxContainer/ExamineButton


var current_mixture := {
	ResourceManager.ARTEMISIA: 0,
	ResourceManager.VALERIANA: 0,
	ResourceManager.SALVIA: 0,
}

var is_typing_speech := false
var showing_examined_dialogue := false


func _ready() -> void:
	background_blocker_left.gui_input.connect(_on_background_clicked)
	background_blocker_right.gui_input.connect(_on_background_clicked)
	
	action_menu.visible = false
	world_diary_button.pressed.connect(_on_world_diary_pressed)

	diary_button.pressed.connect(_on_diary_pressed)
	add_artemisia_button.pressed.connect(_on_add_artemisia_pressed)
	add_valeriana_button.pressed.connect(_on_add_valeriana_pressed)
	add_salvia_button.pressed.connect(_on_add_salvia_pressed)
	apply_mixture_button.pressed.connect(_on_apply_mixture_pressed)
	clear_mixture_button.pressed.connect(_on_clear_mixture_pressed)
	refuse_button.pressed.connect(_on_refuse_pressed)
	collect_herbs_button.pressed.connect(_on_collect_herbs_pressed)
	rest_button.pressed.connect(_on_rest_pressed)
	back_button.pressed.connect(_on_back_pressed)

	GameState.patient_changed.connect(_on_patient_changed)

	page_1.pressed.connect(func(): _show_day_summary(1))
	page_2.pressed.connect(func(): _show_day_summary(2))
	page_3.pressed.connect(func(): _show_day_summary(3))
	page_4.pressed.connect(func(): _show_day_summary(4))
	page_5.pressed.connect(func(): _show_day_summary(5))
	page_6.pressed.connect(func(): _show_day_summary(6))
	page_7.pressed.connect(func(): _show_day_summary(7))
	
	page_back_button.pressed.connect(_on_page_back_button_pressed)

	patient_sprite.gui_input.connect(_on_patient_sprite_clicked)
	speech_bubble.visible = false

	examine_button.pressed.connect(_on_examine_patient_pressed)
	examine_button.visible = true

	_configure_button_texts()
	_connect_game_state_signals()
	_update_ui()


func _configure_button_texts() -> void:
	add_artemisia_button.text = "Adicionar artemísia"
	add_valeriana_button.text = "Adicionar valeriana"
	add_salvia_button.text = "Adicionar sálvia"
	apply_mixture_button.text = "Aplicar mistura"
	clear_mixture_button.text = "Limpar mistura"
	collect_herbs_button.text = "Coletar ervas"
	rest_button.text = "Descansar"


	
func _on_world_diary_pressed() -> void:
	action_menu.visible = true
	diary_panel.visible = true
	background_blocker_left.visible = true
	background_blocker_right.visible = true

	_show_current_info()
	_update_ui()
	selected_day_label.text = ""
	day_log_label.text = ""
	
	
func _on_patient_changed(_patient = null) -> void:
	showing_examined_dialogue = false

	examine_button.visible = true

	speech_bubble.visible = false

	_update_ui()
	
	
func _update_patient_sprite() -> void:
	var patient := GameState.get_current_patient()

	if patient == null:
		speech_bubble.visible = false
		patient_display.visible = false
		patient_sprite.texture = null
		return

	patient_display.visible = true

	if patient.sprite_path.strip_edges().is_empty():
		return

	var texture := load(patient.sprite_path)

	if texture != null:
		patient_sprite.texture = texture

	if texture == null:
		push_warning("Sprite de paciente não encontrado: %s" % patient.sprite_path)
		patient_display.visible = false
		patient_sprite.texture = null
		return

	patient_sprite.texture = texture
	patient_display.visible = true


func _on_background_clicked(event):
	if event is InputEventMouseButton and event.pressed:
		_close_diary_menu()

func _close_diary_menu() -> void:
	diary_panel.visible = false
	action_menu.visible = false


func _connect_game_state_signals() -> void:
	if not GameState.day_changed.is_connected(_update_ui):
		GameState.day_changed.connect(_update_ui)

	if not GameState.time_changed.is_connected(_update_ui):
		GameState.time_changed.connect(_update_ui)

	if not GameState.resources_changed.is_connected(_update_ui):
		GameState.resources_changed.connect(_update_ui)

	if not GameState.patient_changed.is_connected(_update_ui):
		GameState.patient_changed.connect(_update_ui)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if action_menu.visible:
			_close_diary_menu()
		else:
			_on_back_pressed()


func _update_ui(_value = null) -> void:
	_update_day_and_time_labels()
	_update_resource_label()
	_update_mixture_label()
	_update_patient_panel()


func _update_day_and_time_labels() -> void:
	day_label.text = GameState.get_current_day_name()
	time_label.text = "Horário: %02d:00" % GameState.get_current_hour()


func _update_resource_label() -> void:
	resources_label.text = "Artemísia: %d | Valeriana: %d | Sálvia: %d" % [
		GameState.get_artemisia(),
		GameState.get_valeriana(),
		GameState.get_salvia(),
	]


func _update_patient_panel() -> void:
	var patient := GameState.get_current_patient()

	if patient == null:
		patient_label.text = "Nenhum paciente aguardando."
		symptoms_label.text = ""
		_set_patient_buttons_enabled(false)
		_update_patient_sprite()
		return

	patient_label.text = "Paciente: %s\nEstado: %s" % [
		patient.patient_name,
		patient.get_health_state_text()
	]

	if patient.was_examined:
		symptoms_label.text = "Sintomas: %s\n\n%s" % [
			", ".join(patient.symptoms),
			patient.description
		]
	else:
		symptoms_label.text = "Paciente ainda não examinado."

	_set_patient_buttons_enabled(not patient.was_treated)
	_update_patient_sprite()

func _update_mixture_label() -> void:
	mixture_label.text = "Mistura: %d Artemísia | %d Valeriana | %d Sálvia (%d/3)" % [
		current_mixture[ResourceManager.ARTEMISIA],
		current_mixture[ResourceManager.VALERIANA],
		current_mixture[ResourceManager.SALVIA],
		_get_current_mixture_total(),
	]


func _set_patient_buttons_enabled(enabled: bool) -> void:
	var mixture_total := _get_current_mixture_total()
	var mixture_full := mixture_total >= 3

	var artemisia_in_mixture := int(current_mixture[ResourceManager.ARTEMISIA])
	var valeriana_in_mixture := int(current_mixture[ResourceManager.VALERIANA])
	var salvia_in_mixture := int(current_mixture[ResourceManager.SALVIA])

	add_artemisia_button.disabled = not enabled \
		or mixture_full \
		or artemisia_in_mixture >= GameState.get_artemisia()

	add_valeriana_button.disabled = not enabled \
		or mixture_full \
		or valeriana_in_mixture >= GameState.get_valeriana()

	add_salvia_button.disabled = not enabled \
		or mixture_full \
		or salvia_in_mixture >= GameState.get_salvia()

	apply_mixture_button.disabled = not enabled or mixture_total != 3
	clear_mixture_button.disabled = mixture_total == 0

	refuse_button.disabled = not enabled


func _show_day_summary(day: int) -> void:
	selected_day_label.text = "Diário - %s" % GameState.get_day_name(day)

	var summary := GameState.get_day_summary(day)

	if summary.is_empty():
		day_log_label.text = "O registro deste dia ainda não foi finalizado."
	else:
		day_log_label.text = _remove_diary_title_from_summary(summary)

	current_info_container.visible = false
	day_log_container.visible = true


func _remove_diary_title_from_summary(summary: String) -> String:
	var clean_summary := summary.strip_edges()

	if clean_summary.is_empty():
		return ""

	var lines := clean_summary.split("\n")

	if lines.is_empty():
		return clean_summary

	var first_line := str(lines[0]).strip_edges()

	if first_line.begins_with("Diário - "):
		lines.remove_at(0)

		while not lines.is_empty() and str(lines[0]).strip_edges().is_empty():
			lines.remove_at(0)

		return "\n".join(lines)

	return clean_summary
func _on_patient_sprite_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_show_patient_speech()

func _show_patient_speech() -> void:
	var patient := GameState.get_current_patient()

	if patient == null:
		return

	var text := ""

	if showing_examined_dialogue:
		text = patient.examination_dialogue

		if text.strip_edges().is_empty():
			text = "Tenho sentido %s." % ", ".join(patient.symptoms)

	else:
		text = patient.introduction_dialogue

		if text.strip_edges().is_empty():
			text = "Doutor... não me sinto bem."

	_animate_speech_bubble()

	await get_tree().process_frame

	await _type_patient_text(text)
	
		
func _on_examine_patient_pressed() -> void:
	var patient := GameState.get_current_patient()

	if patient == null:
		return

	GameState.examine_current_patient()

	showing_examined_dialogue = true

	examine_button.visible = false

	var text := patient.examination_dialogue

	if text.strip_edges().is_empty():
		text = "Tenho sentido %s." % ", ".join(patient.symptoms)

	_animate_speech_bubble()

	await get_tree().process_frame

	await _type_patient_text(text)

	_update_ui()
		
	
func _generate_patient_default_speech(patient: Patient) -> String:
	if not patient.symptoms.is_empty():
		return "Doutor... estou sentindo %s." % ", ".join(patient.symptoms)

	return "Doutor... não me sinto bem."

func _animate_speech_bubble() -> void:
	
	speech_bubble.scale = Vector2(0.85, 0.85)
	speech_bubble.modulate.a = 0.0
	speech_bubble.visible = true

	var tween := create_tween()
	tween.tween_property(speech_bubble, "scale", Vector2.ONE, 0.15)
	tween.parallel().tween_property(speech_bubble, "modulate:a", 1.0, 0.15)
	

func _type_patient_text(text: String) -> void:
	if is_typing_speech:
		return

	is_typing_speech = true

	speech_text.text = ""

	for i in range(text.length()):
		#speech_text.text += "[wave amp=5 freq=4]" + text[i] + "[/wave]"
		speech_text.text += text[i]


		await get_tree().process_frame
		speech_bubble.reset_size()

		await get_tree().create_timer(0.025).timeout

	is_typing_speech = false

func _small_bubble_bounce() -> void:
	var original_pos := speech_bubble.position

	var tween := create_tween()
	tween.tween_property(speech_bubble, "position", original_pos + Vector2(0, -6), 0.08)
	tween.tween_property(speech_bubble, "position", original_pos, 0.08)


func _show_current_info() -> void:
	current_info_container.visible = true
	day_log_container.visible = false
	selected_day_label.text = ""
	day_log_label.text = ""
	_update_ui()

func _on_page_back_button_pressed() -> void:
	current_info_container.visible = true
	day_log_container.visible = false
	_update_ui()


func _get_current_mixture_total() -> int:
	return int(current_mixture[ResourceManager.ARTEMISIA]) \
		+ int(current_mixture[ResourceManager.VALERIANA]) \
		+ int(current_mixture[ResourceManager.SALVIA])


func _get_available_herb_amount(herb_name: String) -> int:
	match herb_name:
		ResourceManager.ARTEMISIA:
			return GameState.get_artemisia()
		ResourceManager.VALERIANA:
			return GameState.get_valeriana()
		ResourceManager.SALVIA:
			return GameState.get_salvia()
		_:
			return 0


func _add_herb_to_mixture(herb_name: String) -> void:
	if _get_current_mixture_total() >= 3:
		return

	if not current_mixture.has(herb_name):
		return

	var current_amount_in_mixture := int(current_mixture[herb_name])
	var available_amount := _get_available_herb_amount(herb_name)

	if current_amount_in_mixture >= available_amount:
		return

	current_mixture[herb_name] = current_amount_in_mixture + 1
	_update_ui()


func _clear_mixture() -> void:
	current_mixture[ResourceManager.ARTEMISIA] = 0
	current_mixture[ResourceManager.VALERIANA] = 0
	current_mixture[ResourceManager.SALVIA] = 0
	_update_ui()


func _on_diary_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/diary.tscn")


func _on_add_artemisia_pressed() -> void:
	_add_herb_to_mixture(ResourceManager.ARTEMISIA)


func _on_add_valeriana_pressed() -> void:
	_add_herb_to_mixture(ResourceManager.VALERIANA)


func _on_add_salvia_pressed() -> void:
	_add_herb_to_mixture(ResourceManager.SALVIA)


func _on_apply_mixture_pressed() -> void:
	if _get_current_mixture_total() != 3:
		return

	var treatment_applied := GameState.treat_current_patient_with_combination(current_mixture.duplicate(true))

	if treatment_applied:
		_clear_mixture()
	else:
		_update_ui()


func _on_clear_mixture_pressed() -> void:
	_clear_mixture()


func _on_refuse_pressed() -> void:
	GameState.refuse_current_patient()
	_clear_mixture()


func _on_collect_herbs_pressed() -> void:
	GameState.collect_herbs()
	_update_ui()


func _on_rest_pressed() -> void:
	GameState.rest()
	_clear_mixture()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
