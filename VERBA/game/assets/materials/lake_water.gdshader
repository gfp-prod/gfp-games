shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque, diffuse_burley;

// Dark shallow lake, iron-grey sky reflections, scattered peaty ripples.
// Local geology is visible at the shore; no tropical blue transparency.
varying vec3 world_pos;
float lake_distance(vec2 p) {
	vec2 d=(p-vec2(79.0,-60.0))/vec2(20.0,15.0);
	return length(d)*(1.0+.085*sin(p.x*.17+p.y*.05)+
	    .052*cos(p.y*.31)+.028*sin(p.x*.61+p.y*.20));
}
void vertex() {
	world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}
void fragment() {
	vec2 p=world_pos.xz;
	float large=sin(p.x*.43+p.y*.30-TIME*.49);
	float diagonal=sin(p.y*1.24-p.x*.72+TIME*.36);
	float capillary=sin(p.x*3.27+p.y*1.92-TIME*.74);
	float wave=.5+.5*(.63*large+.27*diagonal+.10*capillary);
	float coast=lake_distance(p);
	float shallows=smoothstep(.78,1.01,coast);
	float edge=1.0-smoothstep(.0,.065,abs(coast-.985));
	float narrow_foam=edge*(.10+.10*max(0.0,diagonal));
	vec3 peat=vec3(.047,.075,.079);
	vec3 reflecting_sky=vec3(.13,.167,.163);
	vec3 shallow_mud=vec3(.122,.132,.111);
	vec3 water=mix(peat,reflecting_sky,wave*.53);
	water=mix(water,shallow_mud,shallows*.24);
	water+=vec3(.035,.045,.041)*narrow_foam;
	ALBEDO=water;
	ROUGHNESS=.44;
	METALLIC=0.0;
	SPECULAR=.36;
	ALPHA=.947;
}
