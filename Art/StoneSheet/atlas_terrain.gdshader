shader_type canvas_item;
render_mode unshaded;

uniform sampler2D sheet : source_color, filter_nearest, repeat_disable;
uniform vec4 base_region;
uniform vec4 top_left;
uniform vec4 top_right;
uniform vec4 bottom_left;
uniform vec4 bottom_right;
uniform sampler2D outline : filter_nearest, repeat_disable;
uniform vec4 outline_region = vec4(0.0, 0.0, 1.0, 1.0);
uniform bool preserve_outline = false;
uniform bool direct_texture = false;
uniform bool art_flip_h = false;
uniform vec3 backing_color : source_color = vec3(0.13, 0.17, 0.24);
varying vec4 item_color;

void vertex() {
	item_color = COLOR;
}

void fragment() {
	vec2 dimensions = vec2(textureSize(sheet, 0));
	vec2 point = clamp((UV * dimensions - base_region.xy) / base_region.zw, vec2(0.0), vec2(1.0));
	vec4 region;
	if (direct_texture) {
		region = top_left;
	} else if (point.y < 0.5) {
		region = point.x < 0.5 ? top_left : top_right;
	} else {
		region = point.x < 0.5 ? bottom_left : bottom_right;
	}
	vec2 art_point = vec2(art_flip_h ? 1.0 - point.x : point.x, point.y);
	vec2 sample_uv = (region.xy + vec2(0.5) + art_point * (region.zw - vec2(1.0))) / dimensions;
	vec4 art = texture(sheet, sample_uv);
	float alpha = art.a;
	if (preserve_outline) {
		float mask = texture(outline, outline_region.xy + point * outline_region.zw).a;
		COLOR = vec4(mix(backing_color, art.rgb, alpha), mask) * item_color;
	} else {
		COLOR = vec4(art.rgb, alpha) * item_color;
	}
}
