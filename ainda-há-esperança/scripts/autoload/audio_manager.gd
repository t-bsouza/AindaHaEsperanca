extends Node

const MENU_MUSIC_PATH := "res://data/audio/music/game_theme.ogg"

var music_player: AudioStreamPlayer


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Master"
	add_child(music_player)

	play_menu_music()


func play_menu_music() -> void:
	if music_player == null:
		return

	if music_player.playing:
		return

	var stream := load(MENU_MUSIC_PATH)

	if stream == null:
		push_warning("Música do menu não encontrada: %s" % MENU_MUSIC_PATH)
		return

	music_player.stream = stream
	music_player.play()


func stop_music() -> void:
	if music_player == null:
		return

	music_player.stop()