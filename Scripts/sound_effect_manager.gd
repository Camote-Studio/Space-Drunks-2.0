extends Node
var music_player: AudioStreamPlayer

func _ready():
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.bus = "Music"  
	music_player.autoplay = false
	music_player.stream = load("res://Assets/music/Hideki Naganuma - JACK DA FUNK - Bomb Rush Cyberfunk OST.mp3") 
	music_player.play()
