shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

// VERBA art bible: textured, readable landforms with subdued mineral pigments.
// Each biome shares the same physical UV scale. Macro shapes come from
// geography and deterministic low-frequency weathering, not arbitrary noise.
uniform sampler2D meadow_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D woodland_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D dry_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D packed_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D silt_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D stone_tex : source_color, repeat_enable, filter_linear_mipmap;

varying vec3 world_pos;

float hash21(vec2 p) {
	p=fract(p*vec2(.1031,.11369));
	p+=dot(p,p.yx+19.19);
	return fract((p.x+p.y)*p.x);
}
float value_noise(vec2 p) {
	vec2 a=floor(p);
	vec2 f=fract(p);
	f=f*f*(3.0-2.0*f);
	return mix(mix(hash21(a),hash21(a+vec2(1.0,0.0)),f.x),
	           mix(hash21(a+vec2(0.0,1.0)),hash21(a+vec2(1.0,1.0)),f.x),f.y);
}
float region_noise(vec2 p) {
	return value_noise(p*.075)*.55+value_noise(p*.24)*.30+value_noise(p*.71)*.15;
}
void vertex() {
	world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}
void fragment() {
	vec2 p=world_pos.xz;
	float weather=region_noise(p);
	float detail=value_noise(p*1.65);
	vec2 uv=(p+vec2((weather-.5)*.47))* .119;
	vec3 meadow=texture(meadow_tex,uv).rgb;
	vec3 woodland=texture(woodland_tex,uv*.88).rgb;
	vec3 heath=texture(dry_tex,uv*.96).rgb;
	vec3 earth=texture(packed_tex,uv*1.04).rgb;
	vec3 silt=texture(silt_tex,uv*.92).rgb;
	vec3 shale=texture(stone_tex,uv*1.10).rgb;

	// Broad ecological bands with ragged but natural transition edges.
	float edge=(weather-.5)*11.0;
	float west_forest=(1.0-smoothstep(-29.0+edge,22.0+edge,p.x))*
	    (1.0-smoothstep(33.0,95.0,p.y));
	float amber_heath=smoothstep(23.0+edge,72.0+edge,p.x)*
	    (1.0-smoothstep(38.0,104.0,p.y));
	float outlands=smoothstep(73.0,114.0,abs(p.x))*.38;
	float village=1.0-smoothstep(8.0,25.0,length(p-vec2(12.0,15.0)));
	float southern_ridge=(1.0-smoothstep(-72.0,-28.0,p.y))*.47;
	float castle=1.0-smoothstep(9.0,28.0,length(p-vec2(-49.0,44.0)));
	float station=1.0-smoothstep(8.0,15.0,length(p-vec2(-102.0,77.0)));

	float stream=-20.0+4.4*sin(p.y*.075)+1.7*sin(p.y*.21);
	float creek=(1.0-smoothstep(2.8,10.0,abs(p.x-stream)))*
	    (1.0-smoothstep(60.0,87.0,abs(p.y)));
	vec2 lake=(p-vec2(79.0,-60.0))/vec2(20.0,15.0);
	float radius=length(lake)*
	    (1.0+.085*sin(p.x*.17+p.y*.05)+.052*cos(p.y*.31)+.028*sin(p.x*.61+p.y*.20));
	float shore=1.0-smoothstep(.065,.30,abs(radius-1.02));

	vec3 pigment=mix(meadow,woodland,clamp(west_forest*.85,0.0,1.0));
	pigment=mix(pigment,heath,clamp(amber_heath*.83+outlands,0.0,1.0));
	pigment=mix(pigment,earth,clamp(village*.90+station*.96,0.0,1.0));
	pigment=mix(pigment,shale,clamp(southern_ridge*.63+castle*.90,0.0,1.0));
	pigment=mix(pigment,silt,clamp(creek*.84+shore*.88,0.0,1.0));

	// Damp pockets and soil exposure: low-contrast natural breakup,
	// not a tiled green carpet or kaleidoscopic pixel noise.
	float wet=clamp(creek*.49+shore*.60+west_forest*.13,0.0,1.0);
	float uncovered=smoothstep(.58,.90,weather)*(.15+.14*detail);
	pigment=mix(pigment,earth,uncovered*(1.0-wet*.6));
	pigment*=mix(vec3(.88,.90,.89),vec3(.99,.96,.91),weather);
	pigment=mix(pigment,pigment*vec3(.82,.91,.89),wet*.25);
	pigment*=.97+(detail-.5)*.045;
	ALBEDO=clamp(pigment,vec3(.025),vec3(.87));
	METALLIC=0.0;
	ROUGHNESS=.98;
	SPECULAR=.20;
}
