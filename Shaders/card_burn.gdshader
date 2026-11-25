shader_type canvas_item;
render_mode unshaded;

uniform float burn_progress : hint_range(0.0, 1.0) = 0.0;
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
// One unit is one pixel in the project's 320x180 logical viewport.
// The 60x80 card texture is displayed at its native size.
uniform float pixel_size : hint_range(1.0, 8.0, 1.0) = 1.0;
// Map each Control's vertices into the parent card's normalized coordinates.
uniform vec2 card_size = vec2(60.0, 80.0);
uniform vec2 element_origin = vec2(0.0);
uniform vec2 element_x = vec2(1.0, 0.0);
uniform vec2 element_y = vec2(0.0, 1.0);
varying vec2 card_uv;

float edge_noise(float column) {
	return fract(sin(column * 91.731) * 43758.5453);
}

void vertex() {
	card_uv = (element_origin + element_x * VERTEX.x + element_y * VERTEX.y) / max(card_size, vec2(1.0));
}

void fragment() {
	// COLOR contains this TextureRect's texture and preserves its alpha.
	vec4 source = COLOR;
	float grid = max(pixel_size, 1.0);
	// Both TextureRects use the same card-space grid, including the smaller artwork.
	vec2 cell = floor(card_uv * card_size / grid);
	vec2 pixel_center = (cell + 0.5) * grid;
	float noise = edge_noise(cell.x);
	float boundary = (1.055 - burn_progress * 1.16) * card_size.y + (noise - 0.5) * 8.0 * grid;
	boundary = floor(boundary / grid) * grid;
	float distance_to_edge = boundary - pixel_center.y;
	if (distance_to_edge < 0.0 || source.a < 0.01) {
		discard;
	}
	// A crisp two-pixel rim replaces the smoothly graded burn edge.
	float edge = 1.0 - step(grid * 2.0, distance_to_edge);
	float whiten = clamp(flash_amount + edge, 0.0, 1.0);
	COLOR = vec4(mix(source.rgb, vec3(1.0), whiten), source.a);
}
