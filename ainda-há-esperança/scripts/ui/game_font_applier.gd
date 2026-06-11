class_name GameFontApplier
extends RefCounted

const FONT_TITLE_PATH := "res://data/fonts/CinzelDecorative-Regular.ttf"
const FONT_BUTTON_PATH := "res://data/fonts/Cinzel-VariableFont_wght.ttf"
const FONT_BODY_PATH := "res://data/fonts/Almendra-Regular.ttf"
const FONT_SPEECH_PATH := "res://data/fonts/IMFellEnglish-Regular.ttf"
const FONT_BOOKMARK_PATH := "res://data/fonts/IMFellEnglish-Regular.ttf"

static var title_font: FontFile
static var button_font: FontFile
static var body_font: FontFile
static var speech_font: FontFile
static var bookmark_font: FontFile


static func load_fonts() -> void:
	if title_font == null:
		title_font = load(FONT_TITLE_PATH)

	if button_font == null:
		button_font = load(FONT_BUTTON_PATH)

	if body_font == null:
		body_font = load(FONT_BODY_PATH)

	if speech_font == null:
		speech_font = load(FONT_SPEECH_PATH)

	if bookmark_font == null:
		bookmark_font = load(FONT_BOOKMARK_PATH)


static func apply_label_font(
	label: Label,
	font: FontFile,
	size: int,
	color: Color
) -> void:
	if label == null or font == null:
		return

	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)


static func apply_button_font(
	button: Button,
	font: FontFile,
	size: int,
	color: Color
) -> void:
	if button == null or font == null:
		return

	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", size)

	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", color)
	button.add_theme_color_override("font_pressed_color", color)
	button.add_theme_color_override("font_focus_color", color)
	button.add_theme_color_override("font_hover_pressed_color", color)

	var disabled_color := Color(color.r, color.g, color.b, 0.45)
	button.add_theme_color_override("font_disabled_color", disabled_color)


static func apply_rich_text_font(
	rich_text: RichTextLabel,
	font: FontFile,
	size: int,
	color: Color
) -> void:
	if rich_text == null or font == null:
		return

	rich_text.add_theme_font_override("normal_font", font)
	rich_text.add_theme_font_override("bold_font", font)
	rich_text.add_theme_font_override("italics_font", font)
	rich_text.add_theme_font_override("bold_italics_font", font)

	rich_text.add_theme_font_size_override("normal_font_size", size)
	rich_text.add_theme_font_size_override("bold_font_size", size)
	rich_text.add_theme_font_size_override("italics_font_size", size)
	rich_text.add_theme_font_size_override("bold_italics_font_size", size)

	rich_text.add_theme_color_override("default_color", color)
	rich_text.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)