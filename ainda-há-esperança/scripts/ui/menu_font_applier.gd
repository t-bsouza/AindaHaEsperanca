class_name MenuFontApplier
extends RefCounted

const TEXT_COLOR := Color(0.93, 0.91, 0.84, 1.0)

const TITLE_SIZE := 46
const SUBTITLE_SIZE := 20
const BUTTON_SIZE := 20
const OPTIONS_TITLE_SIZE := 34
const OPTIONS_LABEL_SIZE := 20


static func apply_menu_fonts(
	title_label: Label,
	subtitle_label: Label,
	play_button: Button,
	options_button: Button,
	quit_button: Button,
	options_title_label: Label,
	volume_label: Label,
	resolution_label: Label,
	back_button: Button
) -> void:
	GameFontApplier.load_fonts()

	GameFontApplier.apply_label_font(
		title_label,
		GameFontApplier.title_font,
		TITLE_SIZE,
		TEXT_COLOR
	)

	GameFontApplier.apply_label_font(
		subtitle_label,
		GameFontApplier.body_font,
		SUBTITLE_SIZE,
		TEXT_COLOR
	)

	GameFontApplier.apply_button_font(
		play_button,
		GameFontApplier.button_font,
		BUTTON_SIZE,
		TEXT_COLOR
	)

	GameFontApplier.apply_button_font(
		options_button,
		GameFontApplier.button_font,
		BUTTON_SIZE,
		TEXT_COLOR
	)

	GameFontApplier.apply_button_font(
		quit_button,
		GameFontApplier.button_font,
		BUTTON_SIZE,
		TEXT_COLOR
	)

	GameFontApplier.apply_label_font(
		options_title_label,
		GameFontApplier.title_font,
		OPTIONS_TITLE_SIZE,
		TEXT_COLOR
	)

	GameFontApplier.apply_label_font(
		volume_label,
		GameFontApplier.body_font,
		OPTIONS_LABEL_SIZE,
		TEXT_COLOR
	)

	GameFontApplier.apply_label_font(
		resolution_label,
		GameFontApplier.body_font,
		OPTIONS_LABEL_SIZE,
		TEXT_COLOR
	)

	GameFontApplier.apply_button_font(
		back_button,
		GameFontApplier.button_font,
		BUTTON_SIZE,
		TEXT_COLOR
	)