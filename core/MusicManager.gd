extends Node

const HOVEL_MUSIC_PATH := "res://audio/music/The Hovel.ogg"

var _hovel_music_player: AudioStreamPlayer
var _hovel_music_stream: AudioStream


func _ready() -> void:
	_hovel_music_player = AudioStreamPlayer.new()
	_hovel_music_player.name = "HovelMusicPlayer"
	_hovel_music_player.bus = "Master"
	add_child(_hovel_music_player)


func play_hovel_music() -> void:
	if _hovel_music_player == null:
		return

	if _hovel_music_player.stream == null:
		_hovel_music_stream = load(HOVEL_MUSIC_PATH)
		if _hovel_music_stream == null:
			return
		_hovel_music_player.stream = _hovel_music_stream
		if _hovel_music_stream is AudioStreamOggVorbis:
			_hovel_music_stream.loop = true

	if _hovel_music_player.stream == null:
		return

	if not _hovel_music_player.playing:
		_hovel_music_player.play()


func stop_hovel_music() -> void:
	if _hovel_music_player == null:
		return

	if _hovel_music_player.playing:
		_hovel_music_player.stop()
