// flash.gdshader — biały/kolorowy flash na sprite'ach bez ruszania modulate
// Użycie: ShaderMaterial z parametrem flash_amount (0.0 = brak, 1.0 = pełny flash)
// i flash_color (domyślnie biały). Tween flash_amount 1→0 po trafieniu.
shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	// Zachowaj alpha oryginału; nakładaj kolor tylko na nieprzezroczyste piksele
	float mask = step(0.01, tex.a);
	COLOR = mix(tex, vec4(flash_color.rgb, tex.a), flash_amount * mask);
}
