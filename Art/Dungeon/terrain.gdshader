shader_type canvas_item;
render_mode unshaded;

uniform sampler2D sheet : source_color, filter_nearest, repeat_disable;
uniform bool hide_solid = false;
uniform float stone_repeat_size = 512.0;
uniform vec4 stone_region = vec4(31.0, 336.0, 103.0, 106.0);
uniform vec4 moss_region = vec4(145.0, 327.0, 104.0, 115.0);
uniform vec4 ivy_region = vec4(259.0, 330.0, 89.0, 112.0);
uniform vec4 spike_region = vec4(30.0, 813.0, 116.0, 77.0);
varying vec2 map_position;
varying vec4 item_color;

void vertex() {
	map_position = VERTEX;
	item_color = COLOR;
}

void fragment() {
	vec2 atlas_cell = floor(UV * 3.0);
	vec2 atlas_uv = clamp(fract(UV * 3.0), vec2(0.0), vec2(1.0));
	vec2 tile_uv = fract(map_position / stone_repeat_size);
	bool spike = atlas_cell.x == 1.0 && atlas_cell.y == 0.0;
	vec2 cell = floor(map_position / stone_repeat_size);
	float choice = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
	vec4 region = choice < 0.10 ? ivy_region : (choice < 0.25 ? moss_region : stone_region);
	if (spike) {
		region = spike_region;
		tile_uv = atlas_uv;
	}
	vec2 sheet_uv = (region.xy + vec2(0.5) + tile_uv * (region.zw - vec2(1.0))) / vec2(textureSize(sheet, 0));
	vec4 art = texture(sheet, sheet_uv);
	vec3 surface = mix(vec3(0.25, 0.29, 0.38), art.rgb, art.a);
	if (spike) {
		surface = mix(surface, vec3(1.0, 0.40, 0.23), 0.40);
	}
	// The original atlas is a silhouette mask; tile cells and collision data stay intact.
	COLOR = vec4(surface, texture(TEXTURE, UV).a * item_color.a * ((hide_solid && !spike) ? 0.0 : 1.0));
}
