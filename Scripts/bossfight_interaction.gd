extends Area2D

var is_player_close := false
const UNTITLED := preload("res://dialogues/untitled.dialogue")
var is_dialogue_active := false
@export var next_scene_path: String = "res://Scenes/final_battle_level_1.tscn"

var _scene_change_done := false
var _transitioning := false

func _ready() -> void:
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func _process(_delta: float) -> void:
	if _transitioning:
		return

	if is_player_close \
		and Input.is_action_just_pressed("fired") \
		and not is_dialogue_active:
		Input.action_release("fired")
		DialogueManager.show_dialogue_balloon(UNTITLED)

func _on_area_entered(_area: Area2D) -> void:
	is_player_close = true

func _on_area_exited(_area: Area2D) -> void:
	is_player_close = false

func _on_dialogue_started(_dialogue) -> void:
	is_dialogue_active = true

func _on_dialogue_ended(resource) -> void:
	is_dialogue_active = false
	if resource == UNTITLED and not _scene_change_done:
		_scene_change_done = true
		_transitioning = true
		Input.action_release("fired")
		await get_tree().process_frame
		await get_tree().create_timer(0.05).timeout
		get_tree().change_scene_to_file(next_scene_path)
