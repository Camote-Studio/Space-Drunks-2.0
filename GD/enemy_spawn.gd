extends Area2D
const ENEMY = preload("res://TSCN/enemie_1.tscn")
var enemy_spawn = false
var random = RandomNumberGenerator.new()
var spawn_finished = false 

func _ready() -> void:
	$spawn_timer.play()
	
func spawn_enemies():
	if enemy_spawn and not spawn_finished: 
		var enemy_instance = pig_scene.instantiate()
		enemy_instance.position = Vector2(random.randi_range(90, 600), random.randi_range(790, 790))
		print("Enemy spawned at position: ", enemy_instance.position)
		add_child(enemy_instance)


func _on_spawn_timer_timeout() -> void:
	pass # Replace with function body.
