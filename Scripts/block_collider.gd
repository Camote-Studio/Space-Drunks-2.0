extends Area2D
@export var push_strength : float = 30.0
@onready var warning_label: Label = $warning_label 



func _ready() -> void:
	$"../warning_timer".start()

func _on_body_entered(body: Node2D) -> void:
	if not (body.is_in_group("player") or body.is_in_group("player_2")):
		return 
	var push_dir := (body.global_position - global_position).normalized()
	
	body.global_position -= push_dir * push_strength
	$warning_label.global_position = body.global_position
	$warning_label.visible = true

func _on_warning_timer_timeout() -> void:
	$warning_label.visible = false
