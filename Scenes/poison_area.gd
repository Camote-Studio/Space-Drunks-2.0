extends Node2D

@onready var audio_veneno: AudioStreamPlayer2D = 

func _ready() -> void:
	audio_veneno.play()
