shader_type canvas_item;

void fragment() {
	vec2 uv = UV;
	vec2 c = vec2(0.5, 0.5);
	float r = 0.5;
	if (distance(uv, c) > r) {
		discard;
	}
	COLOR = texture(TEXTURE, uv);
}
