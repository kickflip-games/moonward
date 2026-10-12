shader_type canvas_item;
render_mode unshaded;

uniform sampler2D top_left : source_color, filter_nearest, repeat_disable;
uniform sampler2D top_right : source_color, filter_nearest, repeat_disable;
uniform sampler2D bottom_left : source_color, filter_nearest, repeat_disable;
uniform sampler2D bottom_right : source_color, filter_nearest, repeat_disable;
uniform sampler2D outline : filter_nearest, repeat_disable;
uniform vec4 outline_region = vec4(0.0, 0.0, 1.0, 1.0);
uniform bool preserve_outline = false;
uniform bool direct_texture = false;
uniform vec3 backing_color : source_color = vec3(0.0667, 0.0471, 0.1059);
varying vec4 item_color;

void vertex() {
	item_color = COLOR;
}

void fragment() {
	vec2 point = clamp(UV, vec2(0.0), vec2(1.0));
	vec4 art;
	if (direct_texture) {
		art = texture(TEXTURE, UV);
	} else if (point.y < 0.5) {
		art = point.x < 0.5 ? texture(top_left, point) : texture(top_right, point);
	} else {
		art = point.x < 0.5 ? texture(bottom_left, point) : texture(bottom_right, point);
	}
	if (preserve_outline) {
		vec3 surface = mix(backing_color, art.rgb, art.a);
		float mask = texture(outline, outline_region.xy + point * outline_region.zw).a;
		COLOR = vec4(surface, mask) * item_color;
	} else {
		COLOR = art * item_color;
	}
}
