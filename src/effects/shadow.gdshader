shader_type canvas_item;
uniform bool look_right = true;
uniform float shadow_alpha : hint_range(0.0, 1.0) = 0.5;
uniform float skew_strength : hint_range(0.0, 2.0) = 0.5;

void vertex() {
	VERTEX.x = VERTEX.x * (look_right ? 1.0 : -1.0);

	float xSkewRatio = step(UV.y, .5);
	vec2 skewTransition = vec2(abs(VERTEX.x) * xSkewRatio * skew_strength, 0.0);
	vec2 skewScale = vec2(VERTEX.x, (VERTEX.y + abs(VERTEX.y)) / 2.0);

	VERTEX = skewScale + skewTransition;
}

void fragment() {
	COLOR = vec4(0.0, 0.0, 0.0, shadow_alpha * COLOR.a);
}
