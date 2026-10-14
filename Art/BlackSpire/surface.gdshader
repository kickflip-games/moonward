shader_type canvas_item;
render_mode unshaded;
uniform sampler2D sheet : source_color, filter_nearest, repeat_disable;
uniform vec4 region;
uniform vec4 bounds;
uniform bool dangerous = false;
uniform vec4 danger_color : source_color = vec4(0.96,0.55,0.36,1.0);
varying vec2 local_point;
varying vec4 tint;
void vertex(){local_point=VERTEX;tint=COLOR;}
void fragment(){
 vec2 p=local_point-bounds.xy;
 vec2 sz=region.zw;
 // Source pixels always occupy two world pixels; repetition/cropping, never stretching.
 vec2 pixel=mod(floor(p/2.0),sz);
 vec4 art=texture(sheet,(region.xy+pixel+vec2(.5))/vec2(textureSize(sheet,0)));
 if(dangerous){
  float tip=1.0-smoothstep(0.0,0.28,p.y/max(bounds.w,1.0));
  COLOR=vec4(mix(danger_color.rgb,vec3(.98,.77,.55),tip*.35),1.0)*tint;
 }else{
  COLOR=vec4(mix(vec3(.145,.133,.255),art.rgb,art.a),1.0)*tint;
 }
}
