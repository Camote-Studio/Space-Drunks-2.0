extends Node
var sound_efect_player: AudioStreamPlayer

func _ready():
	sound_efect_player = AudioStreamPlayer.new()
	add_child(sound_efect_player)
	sound_efect_player.bus = "SoundEffect"  
	sound_efect_player.autoplay = false
func _play_sound_effect(stream :AudioStreamPlayer2D, pitch: float =1.0):
	stream.stop()
	stream.pitch_scale =pitch
	stream.play()
