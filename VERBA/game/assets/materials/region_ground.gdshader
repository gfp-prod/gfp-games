shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

// Everything is bundled: no external downloader, no per-biome draw calls.
uniform sampler2D meadow_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D woodland_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D dry_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D packed_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D silt_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D stone_tex : source_color, repeat_enable, filter_linear_mipmap;

varying vec3 world_pos;

float grain(vec2 p) {
	vec2 q = floor(p*0.32);
	return fract(sin(dot(q,vec2(127.1,311.7)))*43758.5453);
}

void vertex() {
	world_pos = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;
	vec2 uv = p * 0.118;
	float variegation = grain(p);
	vec3 meadow = texture(meadow_tex,uv).rgb;
	vec3 woodland = texture(woodland_tex,uv*0.89).rgb;
	vec3 dry_grass = texture(dry_tex,uv*0.95).rgb;
	vec3 earth = texture(packed_tex,uv*1.04).rgb;
	vec3 silt = texture(silt_tex,uv*0.92).rgb;
	vec3 stone = texture(stone_tex,uv*1.10).rgb;

	// Controlled ecotones rather than a uniformly green field: shaded west
	// woodland, amber eastern uplands, worked village ground, cold rock ridge.
	float woodland_zone = (1.0-smoothstep(-30.0,19.0,p.x)) *
			(1.0-smoothstep(34.0,95.0,p.y));
	float dry_zone = smoothstep(27.0,69.0,p.x) *
			(1.0-smoothstep(38.0,104.0,p.y));
	float outer_heath = smoothstep(73.0,114.0,abs(p.x)) * 0.41;
	float plaza = 1.0-smoothstep(8.0,25.0,length(p-vec2(12.0,15.0)));
	float ruined_ridge = (1.0-smoothstep(-70.0,-30.0,p.y)) * 0.53;
	float castle_shale = (1.0-smoothstep(9.0,28.0,length(p-vec2(-49.0,44.0))))*.72;
	float station_stain = 1.0-smoothstep(8.0,15.0,length(p-vec2(-102.0,77.0)));

	float stream_x = -20.0+4.4*sin(p.y*.075)+1.7*sin(p.y*.21);
	float creek_mud = (1.0-smoothstep(2.8,10.0,abs(p.x-stream_x))) *
			(1.0-smoothstep(60.0,87.0,abs(p.y)));
	vec2 lake_axis = (p-vec2(79.0,-60.0))/vec2(20.0,15.0);
	float lake_r = length(lake_axis) *
			(1.0+0.044*sin(p.x*.37)+.031*cos(p.y*.29));
	float shore = 1.0-smoothstep(0.07,0.33,abs(lake_r-1.02));
	float lake_silt = shore*.90;

	vec3 ground = mix(meadow,woodland,clamp(woodland_zone*.80,0.0,1.0));
	ground = mix(ground,dry_grass,clamp(dry_zone*.86+outer_heath,0.0,1.0));
	ground = mix(ground,earth,clamp(plaza*.94+station_stain*.97,0.0,1.0));
	ground = mix(ground,stone,clamp(ruined_ridge*.65+castle_shale*.91,0.0,1.0));
	ground = mix(ground,silt,clamp(creek_mud*.83+lake_silt,0.0,1.0));

	// Gentle mineral/soil pigment variation at a patch scale, not bright noise.
	float blotch = (variegation-.5)*.10;
	vec3 pigment = vec3(.92,.905,.88)+vec3(blotch,blotch*.77,blotch*.48);
	ALBEDO = clamp(ground*pigment,vec3(.035),vec3(.90));
	ROUGHNESS = .97;
	METALLIC = 0.0;
	SPECULAR = .23;
}
