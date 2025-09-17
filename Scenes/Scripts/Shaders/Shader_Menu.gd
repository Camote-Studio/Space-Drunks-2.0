extends Node2D


const _TRANSITION_DURATION: float = 0.38

var _transition_progress: float = 1.0



func _ready() -> void:
    var mat: ShaderMaterial = self.material
    if mat:
        mat.set_shader_parameter("screen_size", get_viewport().get_visible_rect().size)
    _simple_menu_transition()
    #_on_timer_timeout()

#func _on_timer_timeout() -> void:
    #_simple_menu_transition()


func _simple_menu_transition() -> void:
    get_tree().root.gui_disable_input = true
    var next_transition_progress: float = 1 if _transition_progress == 0 else 0
    var tw: Tween = create_tween().set_trans(Tween.TRANS_QUART). \
            set_ease(Tween.EASE_OUT)
    tw.tween_method(_change_transition_progress, _transition_progress,
            next_transition_progress,_TRANSITION_DURATION)
    tw.tween_callback(get_tree().root.set_disable_input.bind(false))
    _transition_progress = next_transition_progress


func _change_transition_progress(progress: float) -> void:
    var mat := get_material()  # o get("material")
    if mat:
        mat.set_shader_parameter("transition_progress", progress)
