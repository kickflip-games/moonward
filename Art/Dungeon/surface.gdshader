shader_type canvas_item;
render_mode unshaded;

uniform sampler2D sheet : source_color, filter_nearest, repeat_disable;
uniform vec4 sprite_region = vec4(31.0, 336.0, 103.0, 106.0);
uniform vec4 local_bounds = vec4(-80.0, -16.0, 160.0, 32.0);
uniform vec3 backing_color : source_color = vec3(0.25, 0.29, 0.38);
uniform bool dangerous = false;
uniform bool texture_mask = false;
varying vec2 shape_position;
varying vec4 item_color;

void vertex() {
	shape_position = VERTEX;
	item_color = COLOR;
}

void fragment() {
	vec2 point = clamp((shape_position - local_bounds.xy) / local_bounds.zw, vec2(0.0), vec2(1.0));
	vec2 atlas_uv = (sprite_region.xy + vec2(0.5) + point * (sprite_region.zw - vec2(1.0))) / vec2(textureSize(sheet, 0));
	vec4 art = texture(sheet, atlas_uv);
	vec3 surface = mix(backing_color, art.rgb, art.a);
	if (dangerous) {
		// Warm metal stays distinct from blue stone, including its darkest pixels.
		surface = mix(surface, vec3(1.0, 0.40, 0.23), 0.32);
		surface = max(surface, vec3(0.38, 0.16, 0.12));
	}
	float mask = texture_mask ? texture(TEXTURE, UV).a : 1.0;
	COLOR = vec4(surface * (dangerous ? vec3(1.0) : item_color.rgb), item_color.a * mask);
}
