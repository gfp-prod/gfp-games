shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

// Old roads are not unbroken grey geometry. Edges physically expose
// the natural terrain, with worn stone, repaired patches and fine fissures.
uniform sampler2D road_stone : source_color, repeat_enable, filter_linear_mipmap;
varying vec3 ground_point;

float noise_hash(vec2 p) {
	return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);
}
float cell_noise(vec2 p) {
	vec2 cell=floor(p);
	vec2 f=fract(p);
	f=f*f*(3.0-2.0*f);
	return mix(mix(noise_hash(cell),noise_hash(cell+vec2(1.0,0.0)),f.x),
		mix(noise_hash(cell+vec2(0.0,1.0)),noise_hash(cell+vec2(1.0,1.0)),f.x),f.y);
}
void vertex() {
	ground_point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}
void fragment() {
	vec2 p=ground_point.xz;
	float coarse=cell_noise(p*.55);
	float fine=cell_noise(p*5.7);
	float shoulder=abs(UV.x-.5)*2.0;
	float irregular=.067*sin(p.x*1.67+p.y*.73)+.035*sin(p.y*3.8);
	// Fragment trimming reveals real ground and makes the road shoulder ragged.
	if (shoulder>.89+irregular) discard;
	vec3 basalt=texture(road_stone,p*.17).rgb;
	float patch=step(.71,cell_noise(p*.26))*step(.42,coarse);
	float fissure_x=abs(sin(p.x*1.1+sin(p.y*.69)*2.4));
	float fissure_z=abs(sin(p.y*.63+sin(p.x*.43)*1.95));
	float cracks=(1.0-smoothstep(.018,.058,fissure_x))*step(.55,coarse);
	cracks+=.65*(1.0-smoothstep(.014,.038,fissure_z))*step(.61,fine);
	vec3 worn=basalt*.49+vec3(.175,.169,.160);
	worn=mix(worn,vec3(.25,.242,.229),patch*.48);
	worn+=vec3(.035,.030,.022)*(coarse-.50);
	worn*=1.0-.45*clamp(cracks,0.0,1.0);
	// Soft earth mixed through the shoulders, rather than clean uniform edges.
	worn=mix(worn,vec3(.32,.309,.276),smoothstep(.64,.9,shoulder)*.39);
	ALBEDO=clamp(worn,vec3(.08),vec3(.57));
	ROUGHNESS=.97;
	SPECULAR=.15;
}
