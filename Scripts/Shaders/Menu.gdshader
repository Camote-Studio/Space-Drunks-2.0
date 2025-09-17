shader_type canvas_item;

uniform float transition_progress : hint_range(0.0, 1.0, 0.01);
uniform vec2 screen_size = vec2(800.0, 600.0); // valor por defecto

void vertex() {
    // Mueve el nodo desde la derecha fuera de la pantalla hasta su posición original
    VERTEX.x += (1.0 - transition_progress) * screen_size.x;
}

void fragment() {
    COLOR.a *= transition_progress;
}
