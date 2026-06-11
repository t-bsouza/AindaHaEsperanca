extends Control

@onready var main_menu_container: VBoxContainer = $CenterContainer/MainMenuContainer

@onready var title_label: Label = $CenterContainer/MainMenuContainer/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/MainMenuContainer/SubtitleLabel

@onready var play_button: Button = $CenterContainer/MainMenuContainer/PlayButton
@onready var options_button: Button = $CenterContainer/MainMenuContainer/OptionsButton
@onready var quit_button: Button = $CenterContainer/MainMenuContainer/QuitButton

@onready var options_panel: PanelContainer = $OptionsPanel
@onready var options_title_label: Label = $OptionsPanel/MarginContainer/OptionsVBox/OptionsTitleLabel
@onready var volume_label: Label = $OptionsPanel/MarginContainer/OptionsVBox/VolumeLabel
@onready var volume_slider: HSlider = $OptionsPanel/MarginContainer/OptionsVBox/VolumeSlider
@onready var resolution_label: Label = $OptionsPanel/MarginContainer/OptionsVBox/ResolutionLabel
@onready var resolution_option_button: OptionButton = $OptionsPanel/MarginContainer/OptionsVBox/ResolutionOptionButton
@onready var back_button: Button = $OptionsPanel/MarginContainer/OptionsVBox/BackButton


func _ready() -> void:
	AudioManager.play_menu_music()

	_connect_signals()
	_setup_resolution_options()
	_load_current_settings_into_ui()
	_apply_menu_fonts()
	_show_main_menu()


func _connect_signals() -> void:
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	back_button.pressed.connect(_on_back_pressed)
	volume_slider.value_changed.connect(_on_volume_changed)
	resolution_option_button.item_selected.connect(_on_resolution_selected)


func _setup_resolution_options() -> void:
	resolution_option_button.clear()

	for i in range(SettingsManager.RESOLUTIONS.size()):
		var resolution: Vector2i = SettingsManager.RESOLUTIONS[i]
		resolution_option_button.add_item(
			"%dx%d" % [resolution.x, resolution.y],
			i
		)


func _load_current_settings_into_ui() -> void:
	volume_slider.value = SettingsManager.master_volume
	_update_volume_label(SettingsManager.master_volume)

	resolution_option_button.select(SettingsManager.resolution_index)
	_update_resolution_label()


func _apply_menu_fonts() -> void:
	MenuFontApplier.apply_menu_fonts(
		title_label,
		subtitle_label,
		play_button,
		options_button,
		quit_button,
		options_title_label,
		volume_label,
		resolution_label,
		back_button
	)


func _show_main_menu() -> void:
	main_menu_container.visible = true
	options_panel.visible = false


func _show_options_menu() -> void:
	main_menu_container.visible = false
	options_panel.visible = true


func _on_play_pressed() -> void:
	GameState.start_new_game()


func _on_options_pressed() -> void:
	_show_options_menu()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_back_pressed() -> void:
	_show_main_menu()


func _on_volume_changed(value: float) -> void:
	SettingsManager.set_master_volume(value)
	_update_volume_label(value)


func _on_resolution_selected(index: int) -> void:
	SettingsManager.set_resolution_index(index)
	_update_resolution_label()


func _update_volume_label(value: float) -> void:
	volume_label.text = "Volume: %d%%" % roundi(value * 100.0)


func _update_resolution_label() -> void:
	resolution_label.text = "Resolução: %s" % SettingsManager.get_current_resolution_text()
