class_name MainFontApplier
extends RefCounted

const TEXT_COLOR := Color(0.93, 0.91, 0.84, 1.0)

const DAY_LABEL_SIZE := 30
const TIME_LABEL_SIZE := 18
const RESOURCE_LABEL_SIZE := 17
const PATIENT_LABEL_SIZE := 19
const SYMPTOMS_LABEL_SIZE := 17
const MIXTURE_LABEL_SIZE := 16
const SELECTED_DAY_LABEL_SIZE := 24
const DAY_LOG_LABEL_SIZE := 18
const SPEECH_TEXT_SIZE := 18
const BUTTON_TEXT_SIZE := 17
const BOOKMARK_TEXT_SIZE := 16


static func apply_main_fonts(
	day_label: Label,
	time_label: Label,
	resources_label: Label,
	patient_label: Label,
	symptoms_label: Label,
	mixture_label: Label,
	selected_day_label: Label,
	day_log_label: RichTextLabel,
	speech_text: RichTextLabel,
	action_buttons: Array[Button],
	bookmark_buttons: Array[Button]
) -> void:
	GameFontApplier.load_fonts()

	GameFontApplier.apply_label_font(day_label, GameFontApplier.title_font, DAY_LABEL_SIZE, TEXT_COLOR)
	GameFontApplier.apply_label_font(time_label, GameFontApplier.body_font, TIME_LABEL_SIZE, TEXT_COLOR)
	GameFontApplier.apply_label_font(resources_label, GameFontApplier.body_font, RESOURCE_LABEL_SIZE, TEXT_COLOR)
	GameFontApplier.apply_label_font(patient_label, GameFontApplier.body_font, PATIENT_LABEL_SIZE, TEXT_COLOR)
	GameFontApplier.apply_label_font(symptoms_label, GameFontApplier.body_font, SYMPTOMS_LABEL_SIZE, TEXT_COLOR)
	GameFontApplier.apply_label_font(mixture_label, GameFontApplier.body_font, MIXTURE_LABEL_SIZE, TEXT_COLOR)

	GameFontApplier.apply_label_font(selected_day_label, GameFontApplier.title_font, SELECTED_DAY_LABEL_SIZE, TEXT_COLOR)

	GameFontApplier.apply_rich_text_font(day_log_label, GameFontApplier.body_font, DAY_LOG_LABEL_SIZE, TEXT_COLOR)
	GameFontApplier.apply_rich_text_font(speech_text, GameFontApplier.speech_font, SPEECH_TEXT_SIZE, TEXT_COLOR)

	_apply_action_button_fonts(action_buttons)
	_apply_bookmark_fonts(bookmark_buttons)


static func _apply_action_button_fonts(buttons: Array[Button]) -> void:
	for button in buttons:
		GameFontApplier.apply_button_font(
			button,
			GameFontApplier.button_font,
			BUTTON_TEXT_SIZE,
			TEXT_COLOR
		)


static func _apply_bookmark_fonts(bookmark_buttons: Array[Button]) -> void:
	var index := 1

	for button in bookmark_buttons:
		button.text = str(index)

		GameFontApplier.apply_button_font(
			button,
			GameFontApplier.bookmark_font,
			BOOKMARK_TEXT_SIZE,
			TEXT_COLOR
		)

		index += 1