extends AnimationPlayer

func _ready() -> void:
	play("loading_screen")

func _on_animation_finished(anim_name: StringName) -> void:
	play("loading_screen")
