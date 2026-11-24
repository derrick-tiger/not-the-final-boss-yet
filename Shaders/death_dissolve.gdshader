shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float spread : hint_range(0.0, 80.0) = 32.0;
uniform float whiten : hint_range(0.0, 1.0) = 1.0;
uniform vec2 frame_size = vec2(64.0);
uniform vec2 frame_origin = vec2(-32.0);
uniform float rows = 32.0;
uniform vec4 sprite_tint : source_color = vec4(1.0);

varying float flake_alpha;
varying float flake_white;

float chunk_random(vec2 cell) {
	return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	// Each quad carries its center in COLOR.rg and its row in COLOR.b.
	vec2 center = frame_origin + COLOR.rg * frame_size;
	float seed = chunk_random(COLOR.rg * frame_size);
	// Jitter stays within its row, preserving the top-to-bottom order.
	float delay = (COLOR.b + seed * 0.75 / rows) * 0.55;
	float life = clamp((progress - delay) / 0.45, 0.0, 1.0);
	float angle = chunk_random(COLOR.gr * frame_size + 17.0) * 6.283185;
	vec2 direction = vec2(cos(angle), sin(angle));
	float spin = (seed - 0.5) * 3.0 * life;
	mat2 rotation = mat2(vec2(cos(spin), sin(spin)), vec2(-sin(spin), cos(spin)));
	VERTEX = center + rotation * (VERTEX - center);
	VERTEX += direction * spread * mix(0.45, 1.0, seed) * life;
	flake_alpha = 1.0 - smoothstep(0.35, 1.0, life);
	flake_white = smoothstep(0.0, 0.15, life) * whiten;
	// Metadata must not tint the texture.
	COLOR = sprite_tint;
}

void fragment() {
	COLOR = vec4(mix(COLOR.rgb, vec3(1.0), flake_white), COLOR.a * flake_alpha);
}
