shader_type canvas_item;
render_mode unshaded;
uniform float openness=0.0;
void fragment(){
 vec3 low=vec3(.045,.045,.092);
 vec3 high=vec3(.085,.075,.145);
 vec3 sky=mix(low,high,UV.y*.5+openness*.5);
 COLOR=vec4(sky,1.0);
}
