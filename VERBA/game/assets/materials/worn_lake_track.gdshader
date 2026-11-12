shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley;

// Grounded, irregular walkable footpath. Existing subdivided mesh stays the
// same, with soft mineral shoulders and two shallow travel ruts.
// This is color/opacity only; terrain height, collisions and navigation
// remain entirely under the existing world terrain.
uniform sampler2D path_photograph : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D river_silt : source_color, repeat_enable, filter_linear_mipmap;

varying vec3 ground_location;

float hash2(vec2 xy) {
	vec3 p = fract(vec3(xy.xyx) * .1031);
	p += dot(p,p.yzx+19.19);
	return fract((p.x+p.y)*p.z);
}
float noise2(vec2 xy) {
	vec2 p=floor(xy);
	vec2 f=fract(xy);
	f=f*f*(3.0-2.0*f);
	return mix(mix(hash2(p),hash2(p+vec2(1.0,0.0)),f.x),
	           mix(hash2(p+vec2(0.0,1.0)),hash2(p+vec2(1.0,1.0)),f.x),f.y);
}
void vertex() {
	ground_location=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}
void fragment() {
	float roughness=noise2(ground_location.xz*1.4);
	float wear=noise2(ground_location.xz*.35);
	float shoulder=min(UV.x,1.0-UV.x);
	float edge_displacement=(roughness-.5)*.095;
	float edge_mask=smoothstep(.022,.20,shoulder+edge_displacement);
	// A track with two subtle compacted ruts, rather than a flat clay ribbon.
	float ruts=exp(-pow((UV.x-.28)/.087,2.0))+
	           exp(-pow((UV.x-.72)/.087,2.0));
	vec3 earth=texture(path_photograph,vec2(UV.x*2.4,UV.y)).rgb;
	vec3 fines=texture(river_silt,vec2(UV.x*2.3,UV.y*.76)).rgb;
	vec3 pigment=mix(earth,fines,.13+wear*.25);
	pigment*=vec3(.64,.60,.52);
	pigment*=1.0-ruts*(.052+wear*.035);
	// Moisture darkens the deeper ruts; organic margins disappear into soil.
	pigment*=.94+.10*roughness;
	ALBEDO=clamp(pigment,vec3(.025),vec3(.75));
	ROUGHNESS=.99;
	SPECULAR=.18;
	ALPHA=edge_mask;
}