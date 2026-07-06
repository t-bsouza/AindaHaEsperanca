extends Node2D

@onready var day_label: Label       = $CanvasLayer/DiaryPanel/LeftPage/LeftContent/DayLabel
@onready var time_label: Label      = $CanvasLayer/DiaryPanel/LeftPage/LeftContent/TimeLabel
@onready var resources_label: Label = $CanvasLayer/DiaryPanel/LeftPage/LeftContent/ResourcesLabel
@onready var patient_label: Label   = $CanvasLayer/DiaryPanel/LeftPage/LeftContent/PatientLabel
@onready var symptoms_label: Label  = $CanvasLayer/DiaryPanel/LeftPage/LeftContent/SymptomsLabel
@onready var mixture_label: Label   = $CanvasLayer/DiaryPanel/LeftPage/LeftContent/MixtureLabel

@onready var diary_button: Button         = $CanvasLayer/DiaryPanel/RightPage/rightContent/DiaryButton
@onready var add_artemisia_button: Button = $CanvasLayer/DiaryPanel/RightPage/rightContent/ArtemisiaButton
@onready var add_valeriana_button: Button = $CanvasLayer/DiaryPanel/RightPage/rightContent/ValerianaButton
@onready var add_salvia_button: Button    = $CanvasLayer/DiaryPanel/RightPage/rightContent/SalviaButton
@onready var apply_mixture_button: Button = $CanvasLayer/DiaryPanel/RightPage/rightContent/ApplyMixtureButton
@onready var clear_mixture_button: Button = $CanvasLayer/DiaryPanel/RightPage/rightContent/ClearMixtureButton
@onready var refuse_button: Button        = $CanvasLayer/DiaryPanel/RightPage/rightContent/RefuseButton
@onready var collect_herbs_button: Button = $CanvasLayer/DiaryPanel/RightPage/rightContent/CollectHerbsButton
@onready var rest_button: Button          = $CanvasLayer/DiaryPanel/RightPage/rightContent/RestButton
@onready var back_button: Button          = $CanvasLayer/DiaryPanel/RightPage/rightContent/BackButton

@onready var action_menu: CanvasLayer           = $CanvasLayer
@onready var world_diary_button: TextureButton  = $background/diaryButton

@onready var background_blocker_right = $CanvasLayer/DiaryPanel/BackgroundBlockerRight
@onready var background_blocker_left  = $CanvasLayer/DiaryPanel/BackgroundBlockerLeft

@onready var patient_display: Control  = $Character
@onready var patient_sprite: TextureRect = $Character/CharacterSprite

@onready var page_1: Button = $CanvasLayer/DiaryPanel/marca_pagina_pages/page_1
@onready var page_2: Button = $CanvasLayer/DiaryPanel/marca_pagina_pages/page_2
@onready var page_3: Button = $CanvasLayer/DiaryPanel/marca_pagina_pages/page_3
@onready var page_4: Button = $CanvasLayer/DiaryPanel/marca_pagina_pages/page_4
@onready var page_5: Button = $CanvasLayer/DiaryPanel/marca_pagina_pages/page_5
@onready var page_6: Button = $CanvasLayer/DiaryPanel/marca_pagina_pages/page_6
@onready var page_7: Button = $CanvasLayer/DiaryPanel/marca_pagina_pages/page_7

@onready var diary_panel: Control           = $CanvasLayer/DiaryPanel
@onready var current_info_container: Control  = $CanvasLayer/DiaryPanel/LeftPage/LeftContent
@onready var day_log_container: Control       = $CanvasLayer/DiaryPanel/LeftPage/DayLogContainer
@onready var page_back_button: Button         = $CanvasLayer/DiaryPanel/LeftPage/DayLogContainer/backPage
@onready var selected_day_label: Label        = $CanvasLayer/DiaryPanel/LeftPage/DayLogContainer/SelectedDayLabel
@onready var day_log_label: RichTextLabel     = $CanvasLayer/DiaryPanel/LeftPage/DayLogContainer/DayLogLabel

@onready var speech_bubble: PanelContainer   = $Character/SpeechBubble
@onready var speech_text: RichTextLabel      = $Character/SpeechBubble/MarginContainer/VBoxContainer/SpeechText
@onready var examine_button: Button          = $Character/SpeechBubble/MarginContainer/VBoxContainer/ExamineButton

# Ordered mixture: up to 3 herb names in sequence
var current_mixture: Array[String] = []

var _is_typing := false
var _showing_examined_dialogue := false

var _in_narrative: bool = false
var _narrative_pages: Array[String] = []
var _narrative_page_index: int = 0
var _narrative_character_sprite: String = ""

var _showing_departure: bool = false
var _departure_text: String = ""

# Narratives queued while departure or another narrative is already active.
var _pending_narratives: Array = []

var _herb_popup: Control = null


func _ready() -> void:
	background_blocker_left.gui_input.connect(_on_background_clicked)
	background_blocker_right.gui_input.connect(_on_background_clicked)

	action_menu.visible = false
	world_diary_button.pressed.connect(_on_world_diary_pressed)

	diary_button.pressed.connect(_on_diary_pressed)
	add_artemisia_button.pressed.connect(func(): _add_herb(ResourceManager.ARTEMISIA))
	add_valeriana_button.pressed.connect(func(): _add_herb(ResourceManager.VALERIANA))
	add_salvia_button.pressed.connect(func(): _add_herb(ResourceManager.SALVIA))
	apply_mixture_button.pressed.connect(_on_apply_mixture_pressed)
	clear_mixture_button.pressed.connect(_on_clear_mixture_pressed)
	refuse_button.pressed.connect(_on_refuse_pressed)
	collect_herbs_button.pressed.connect(_on_collect_herbs_pressed)
	rest_button.pressed.connect(_on_rest_pressed)
	back_button.pressed.connect(_on_back_pressed)

	page_1.pressed.connect(func(): _show_day_summary(1))
	page_2.pressed.connect(func(): _show_day_summary(2))
	page_3.pressed.connect(func(): _show_day_summary(3))
	page_4.pressed.connect(func(): _show_day_summary(4))
	page_5.pressed.connect(func(): _show_day_summary(5))
	page_6.pressed.connect(func(): _show_day_summary(6))
	page_7.pressed.connect(func(): _show_day_summary(7))
	page_back_button.pressed.connect(_on_page_back_pressed)

	patient_sprite.gui_input.connect(_on_patient_sprite_clicked)
	examine_button.pressed.connect(_on_examine_pressed)

	speech_bubble.visible = false
	patient_display.visible = false

	GameState.patient_changed.connect(_on_patient_changed)
	GameState.time_changed.connect(_update_ui)
	GameState.day_changed.connect(_update_ui)
	GameState.resources_changed.connect(_update_ui)
	GameState.event_notification.connect(_on_event_notification)
	GameState.narrative_event.connect(_on_narrative_event)

	_configure_button_labels()
	_apply_game_fonts()
	_update_ui()
	_build_herb_popup()

	# Fire any events already scheduled at the current hour (e.g. Day 1 tutorial)
	GameState.check_initial_events()


func _configure_button_labels() -> void:
	add_artemisia_button.text = "Artemísia"
	add_valeriana_button.text = "Valeriana"
	add_salvia_button.text    = "Sálvia"
	apply_mixture_button.text = "Aplicar mistura (3h)"
	clear_mixture_button.text = "Limpar"
	collect_herbs_button.text = "Coletar ervas (3h)"
	rest_button.text          = "Descansar (1h)"
	refuse_button.text        = "Recusar (1h)"
	diary_button.text         = "Receituário"
	examine_button.text       = "Examinar"


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if action_menu.visible:
			_close_diary_menu()
		else:
			_on_back_pressed()


# ── Diary panel ───────────────────────────────────────────────────────────────

func _on_world_diary_pressed() -> void:
	action_menu.visible = true
	diary_panel.visible = true
	background_blocker_left.visible = true
	background_blocker_right.visible = true
	_show_current_info()
	_update_ui()


func _on_background_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close_diary_menu()


func _close_diary_menu() -> void:
	diary_panel.visible = false
	action_menu.visible = false


func _show_current_info() -> void:
	current_info_container.visible = true
	day_log_container.visible = false
	selected_day_label.text = ""
	day_log_label.text = ""


func _show_day_summary(day: int) -> void:
	var summary: String = GameState.get_day_summary(day)
	selected_day_label.text = "Diário — %s" % GameState.get_day_name(day)
	day_log_label.text = summary if not summary.is_empty() else "Este dia ainda não foi registrado."
	current_info_container.visible = false
	day_log_container.visible = true


func _on_page_back_pressed() -> void:
	_show_current_info()
	_update_ui()


func _on_diary_pressed() -> void:
	_show_receituario()


# ── UI update ─────────────────────────────────────────────────────────────────

func _update_ui(_value = null) -> void:
	_update_labels()
	_update_patient_panel()
	_update_mixture_label()
	_update_action_buttons()
	_update_patient_sprite()


func _update_labels() -> void:
	day_label.text  = GameState.get_current_day_name()
	time_label.text = "Horário: %02d:00" % GameState.get_current_hour()
	resources_label.text = "Artemísia: %d  |  Valeriana: %d  |  Sálvia: %d" % [
		GameState.get_artemisia(),
		GameState.get_valeriana(),
		GameState.get_salvia(),
	]


func _update_patient_panel() -> void:
	var patient: Patient = GameState.get_current_patient()

	if patient == null:
		patient_label.text   = "Nenhum visitante aguardando."
		symptoms_label.text  = ""
		return

	var hours_left: int = GameState.get_hours_remaining_for_patient()
	var time_info  := ""
	if hours_left > 0:
		time_info = "  [parte em %dh]" % hours_left

	var plague_tag := ""
	if patient.has_plague:
		plague_tag = "  ⚠ PRAGA ATIVA"

	patient_label.text = "%s%s%s\nEstado: %s" % [
		patient.patient_name,
		plague_tag,
		time_info,
		patient.get_health_state_text(),
	]

	if patient.was_examined:
		var disease_hint := ""
		if patient.has_plague:
			disease_hint = "\n[A praga bloqueia o tratamento da doença subjacente.]"
		symptoms_label.text = "Sintomas: %s%s" % [
			", ".join(patient.symptoms),
			disease_hint,
		]
	else:
		symptoms_label.text = "Paciente ainda não examinado."


func _update_mixture_label() -> void:
	var slot_display: Array[String] = ["—", "—", "—"]
	var herb_labels := {
		ResourceManager.ARTEMISIA: "Artemísia",
		ResourceManager.VALERIANA: "Valeriana",
		ResourceManager.SALVIA:    "Sálvia",
	}
	for i in current_mixture.size():
		slot_display[i] = herb_labels.get(current_mixture[i], "?")

	mixture_label.text = "Mistura: [%s] → [%s] → [%s]  (%d/3)" % [
		slot_display[0], slot_display[1], slot_display[2], current_mixture.size()
	]


func _update_action_buttons() -> void:
	if _in_narrative:
		add_artemisia_button.disabled = true
		add_valeriana_button.disabled = true
		add_salvia_button.disabled    = true
		apply_mixture_button.disabled = true
		clear_mixture_button.disabled = true
		refuse_button.disabled        = true
		collect_herbs_button.disabled = true
		rest_button.disabled          = true
		examine_button.text    = "Continuar"
		examine_button.visible = true
		return

	if _showing_departure:
		add_artemisia_button.disabled = true
		add_valeriana_button.disabled = true
		add_salvia_button.disabled    = true
		apply_mixture_button.disabled = true
		clear_mixture_button.disabled = true
		refuse_button.disabled        = true
		collect_herbs_button.disabled = true
		rest_button.disabled          = true
		examine_button.text    = "Dispensar"
		examine_button.visible = true
		return

	var patient: Patient = GameState.get_current_patient()
	var has_patient: bool = patient != null
	var already_treated: bool = has_patient and patient.was_treated
	var is_story: bool = has_patient and patient.is_story_only

	var mixture_full: bool = current_mixture.size() >= 3
	var mixture_ready: bool = current_mixture.size() == 3

	var can_add_herb: bool = has_patient and not already_treated and not is_story and not mixture_full
	add_artemisia_button.disabled = not can_add_herb or GameState.get_artemisia() <= 0
	add_valeriana_button.disabled = not can_add_herb or GameState.get_valeriana() <= 0
	add_salvia_button.disabled    = not can_add_herb or GameState.get_salvia()    <= 0

	apply_mixture_button.disabled = not (has_patient and not already_treated and not is_story and mixture_ready)
	clear_mixture_button.disabled = current_mixture.is_empty()

	refuse_button.disabled = not (has_patient and not already_treated and not is_story)

	examine_button.text    = "Examinar"
	examine_button.visible = has_patient and not patient.was_examined

	collect_herbs_button.disabled = has_patient and not already_treated
	rest_button.disabled          = has_patient and not already_treated


func _update_patient_sprite() -> void:
	# Don't touch visibility during narrative or departure — those modes manage it.
	if _in_narrative or _showing_departure:
		return

	var patient: Patient = GameState.get_current_patient()

	if patient == null:
		patient_display.visible = false
		patient_sprite.texture  = null
		return

	if patient.sprite_path.strip_edges().is_empty():
		patient_display.visible = false
		return

	var tex := load(patient.sprite_path) as Texture2D
	if tex == null:
		patient_display.visible = false
		return

	patient_sprite.texture  = tex
	patient_display.visible = true


# ── Event notification (tutorial / story narrative) ───────────────────────────

func _on_event_notification(message: String) -> void:
	if message.strip_edges().is_empty():
		return
	# Show in symptoms area when diary is open, or animate in speech bubble
	# if the panel is not currently open we just let it sit in the diary log.
	if action_menu.visible:
		symptoms_label.text = message


# ── Patient interaction ───────────────────────────────────────────────────────

func _on_patient_changed(_patient = null) -> void:
	_showing_examined_dialogue = false
	if not _in_narrative and not _showing_departure:
		speech_bubble.visible = false
	_clear_mixture()
	_update_ui()


func _on_patient_sprite_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_show_patient_speech(false)


func _on_examine_pressed() -> void:
	if _in_narrative:
		_narrative_continue()
		return
	if _showing_departure:
		_end_departure()
		return

	var patient: Patient = GameState.get_current_patient()
	if patient == null:
		return

	GameState.examine_current_patient()
	_showing_examined_dialogue = true
	examine_button.visible = false
	_show_patient_speech(true)
	_update_ui()


func _show_patient_speech(use_examined: bool) -> void:
	var patient: Patient = GameState.get_current_patient()
	if patient == null:
		return

	var text := ""
	if use_examined or _showing_examined_dialogue:
		text = patient.examination_dialogue
		if text.strip_edges().is_empty():
			text = "Sinto %s." % ", ".join(patient.symptoms)
	else:
		text = patient.introduction_dialogue
		if text.strip_edges().is_empty():
			text = "Doutor... não me sinto bem."

	_animate_speech_bubble()
	_type_text_async(text)


func _animate_speech_bubble() -> void:
	speech_bubble.scale    = Vector2(0.85, 0.85)
	speech_bubble.modulate.a = 0.0
	speech_bubble.visible  = true

	var tween := create_tween()
	tween.tween_property(speech_bubble, "scale", Vector2.ONE, 0.15)
	tween.parallel().tween_property(speech_bubble, "modulate:a", 1.0, 0.15)


func _type_text_async(text: String) -> void:
	if _is_typing:
		return
	_is_typing = true
	speech_text.text = ""

	for ch in text:
		if not _is_typing:
			break
		speech_text.text += ch
		await get_tree().process_frame
		speech_bubble.reset_size()
		await get_tree().create_timer(0.02).timeout

	_is_typing = false


# ── Mixture ───────────────────────────────────────────────────────────────────

func _add_herb(herb: String) -> void:
	if current_mixture.size() >= 3:
		return
	current_mixture.append(herb)
	_update_ui()


func _clear_mixture() -> void:
	current_mixture.clear()
	_update_ui()


func _on_apply_mixture_pressed() -> void:
	if current_mixture.size() != 3:
		return

	# Capture combination before treat so we can build departure text after patient is cleared.
	var combo := current_mixture.duplicate()

	# Set flag before calling treat — patient_changed fires synchronously inside treat,
	# and _on_patient_changed checks this flag before hiding the speech bubble.
	_showing_departure = true

	var outcome: String = GameState.treat_current_patient(combo)
	if not outcome.is_empty():
		_clear_mixture()
		# Only show departure for outcomes where the patient leaves on their own feet.
		if outcome != "dead_now" and outcome != "bad":
			_departure_text = _generate_departure_text(combo, outcome)
			_show_departure_speech()
		else:
			_showing_departure = false
			_update_ui()
	else:
		_showing_departure = false
		_update_ui()


func _on_clear_mixture_pressed() -> void:
	_clear_mixture()


# ── Action buttons ────────────────────────────────────────────────────────────

func _on_refuse_pressed() -> void:
	GameState.refuse_current_patient()
	_clear_mixture()


func _on_collect_herbs_pressed() -> void:
	_herb_popup.visible = true


func _on_rest_pressed() -> void:
	GameState.rest()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


# ── Herb collection popup ─────────────────────────────────────────────────────

func _build_herb_popup() -> void:
	# Full-screen dimming backdrop that blocks input
	var root := ColorRect.new()
	root.color = Color(0.0, 0.0, 0.0, 0.55)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP

	# CenterContainer fills the backdrop and centers the panel inside it
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 20)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Onde coletar ervas?  (3 horas)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	var locations: Array[Array] = [
		["porto",    "Porto       (+2 Artemísia, +1 Sálvia)"],
		["floresta", "Floresta  (+2 Valeriana, +1 Sálvia)"],
		["campo",    "Campo     (+2 Sálvia, +1 Artemísia)"],
	]
	for loc in locations:
		var btn := Button.new()
		btn.text = loc[1]
		btn.pressed.connect(_on_collect_location.bind(loc[0]))
		vbox.add_child(btn)

	vbox.add_child(HSeparator.new())

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancelar"
	cancel_btn.pressed.connect(_close_herb_popup)
	vbox.add_child(cancel_btn)

	root.visible = false
	action_menu.add_child(root)
	_herb_popup = root


func _close_herb_popup() -> void:
	_herb_popup.visible = false


func _on_collect_location(location: String) -> void:
	_close_herb_popup()
	GameState.collect_herbs_from_location(location)


# ── Narrative mode ────────────────────────────────────────────────────────────

func _on_narrative_event(pages: Array, character_sprite: String) -> void:
	if pages.is_empty():
		return

	# If another state is already consuming the speech bubble, queue for later.
	if _in_narrative or _showing_departure:
		_pending_narratives.append({"pages": pages.duplicate(), "sprite": character_sprite})
		return

	_in_narrative = true
	_narrative_pages.clear()
	for p in pages:
		_narrative_pages.append(str(p))
	_narrative_page_index = 0
	_narrative_character_sprite = character_sprite

	# Close the diary panel so the speech bubble (in the 2D world, behind CanvasLayer) is visible.
	_close_diary_menu()

	# Always show the container so the speech bubble (child of patient_display) is visible.
	patient_sprite.texture = null
	if not character_sprite.is_empty():
		var tex := load(character_sprite) as Texture2D
		if tex != null:
			patient_sprite.texture = tex
	patient_display.visible = true

	examine_button.text = "Continuar"
	examine_button.visible = true
	_animate_speech_bubble()
	_type_text_async(_narrative_pages[0])


func _narrative_continue() -> void:
	if _is_typing:
		_is_typing = false
		speech_text.text = _narrative_pages[_narrative_page_index]
		return
	_narrative_page_index += 1
	if _narrative_page_index >= _narrative_pages.size():
		_end_narrative()
		return
	_animate_speech_bubble()
	_type_text_async(_narrative_pages[_narrative_page_index])


func _end_narrative() -> void:
	_in_narrative = false
	_narrative_pages.clear()
	_narrative_page_index = 0
	_narrative_character_sprite = ""
	speech_bubble.visible = false
	examine_button.text = "Examinar"

	# Fire the next queued narrative, if any; otherwise restore normal UI.
	if not _pending_narratives.is_empty():
		var next: Dictionary = _pending_narratives.pop_front()
		_on_narrative_event(next.get("pages", []), next.get("sprite", ""))
	else:
		var patient: Patient = GameState.get_current_patient()
		if patient == null:
			patient_display.visible = false
		_update_ui()


# ── Departure dialogue ────────────────────────────────────────────────────────

func _show_departure_speech() -> void:
	patient_display.visible = true
	speech_text.text = _departure_text
	speech_bubble.visible = true
	examine_button.text    = "Dispensar"
	examine_button.visible = true


func _end_departure() -> void:
	_showing_departure = false
	_departure_text    = ""
	speech_bubble.visible   = false
	examine_button.text     = "Examinar"
	patient_display.visible = false

	# Fire the next queued narrative, if any; otherwise restore normal UI.
	if not _pending_narratives.is_empty():
		var next: Dictionary = _pending_narratives.pop_front()
		_on_narrative_event(next.get("pages", []), next.get("sprite", ""))
	else:
		_update_ui()


func _generate_departure_text(combination: Array, outcome: String) -> String:
	var a := combination.count(ResourceManager.ARTEMISIA)
	var v := combination.count(ResourceManager.VALERIANA)
	var s := combination.count(ResourceManager.SALVIA)

	var taste_options: Array[String]
	if a == 1 and v == 1 and s == 1:
		taste_options = [
			"Que sabor exótico... floral, amargo e temperado ao mesmo tempo.",
			"Nunca tomei nada assim. Um gosto bem exótico, difícil de descrever.",
			"É tudo ao mesmo tempo: flores, amargor, tempero. Muito exótico.",
		]
	elif a >= v and a >= s:
		taste_options = [
			"Gosto floral, levemente refrescante. Quase chá de flor silvestre.",
			"Tem um frescor floral. Melhor do que eu esperava de um remédio.",
			"Floral e refrescante. Lembra chá de flores do campo.",
		]
	elif v >= a and v >= s:
		taste_options = [
			"Que amargo, pelo amor de Deus. Como o senhor aguenta tomar isso?",
			"Horrível. Muito amargo e ruim. Mas vai que funciona...",
			"Amargo demais. Faz a boca torcer só de lembrar.",
		]
	else:
		taste_options = [
			"Lembra tempero de cozinha. Esquisito num remédio.",
			"Gosto forte de erva e tempero. Não esperava isso.",
			"Parece um caldo bem temperado. Curioso num remédio.",
		]

	var taste: String = taste_options[randi() % taste_options.size()]

	var feeling: String
	match outcome:
		"good":         feeling = "Me sinto melhor. Obrigado, Doutor."
		"neutral":      feeling = "Esperemos que funcione. Obrigado."
		"postpone":     feeling = "Algo mudou, mas não sei explicar. Obrigado."
		"cure_plague":  feeling = "A praga... algo está diferente. Obrigado, Doutor."
		_:              feeling = "Obrigado, Doutor."

	return taste + " " + feeling


# ── Receituário ────────────────────────────────────────────────────────────────

func _show_receituario() -> void:
	var known: Array = GameState.get_known_diseases()
	var lines: Array[String] = []
	for disease in known:
		var dname: String = str(disease.get("display_name", ""))
		var recipe: String = _recipe_key_to_text(str(disease.get("recipe_key", "")))
		var syms: Array = disease.get("symptoms", [])
		lines.append("• %s" % dname)
		lines.append("  Mistura: %s" % recipe)
		if not syms.is_empty():
			lines.append("  Sintomas: %s" % ", ".join(syms))
		lines.append("")

	selected_day_label.text = "Receituário"
	day_log_label.text = "\n".join(lines) if not lines.is_empty() else "Nenhuma doença registrada ainda."
	current_info_container.visible = false
	day_log_container.visible = true


func _recipe_key_to_text(key: String) -> String:
	var parts := key.split("|")
	var names: Array[String] = []
	for code in parts:
		match code:
			"A": names.append("Artemísia")
			"V": names.append("Valeriana")
			"S": names.append("Sálvia")
			_:   names.append(code)
	return " → ".join(names)


# ── Fonts ─────────────────────────────────────────────────────────────────────

func _apply_game_fonts() -> void:
	MainFontApplier.apply_main_fonts(
		day_label,
		time_label,
		resources_label,
		patient_label,
		symptoms_label,
		mixture_label,
		selected_day_label,
		day_log_label,
		speech_text,
		_get_action_buttons(),
		_get_bookmark_buttons()
	)


func _get_action_buttons() -> Array[Button]:
	return [
		diary_button,
		add_artemisia_button,
		add_valeriana_button,
		add_salvia_button,
		apply_mixture_button,
		clear_mixture_button,
		refuse_button,
		collect_herbs_button,
		rest_button,
		back_button,
		page_back_button,
		examine_button,
	]


func _get_bookmark_buttons() -> Array[Button]:
	return [page_1, page_2, page_3, page_4, page_5, page_6, page_7]
