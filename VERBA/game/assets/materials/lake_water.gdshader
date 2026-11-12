shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque, diffuse_burley;

varying vec3 world_pos;
void vertex() {
	world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}
void fragment() {
	// Shallow mineral lake: dark peaty interior and cool sky-lit edges.
	// Two nonparallel fine ripples, never a bright swimming-pool blue.
	float longwave=sin(world_pos.x*.43+world_pos.z*.30-TIME*.67);
	float crosswave=sin(world_pos.z*1.24-world_pos.x*.72+TIME*.52);
	float fine=sin(world_pos.x*3.27+world_pos.z*1.92-TIME*1.13);
	float drift=.022*longwave+.011*crosswave+.004*fine;
	vec3 peat=vec3(.059,.094,.097);
	vec3 steel=vec3(.109,.143,.138);
	ALBEDO=mix(peat,steel,.31+.18*longwave)+vec3(drift);
	ROUGHNESS=.57;
	METALLIC=0.0;
	SPECULAR=.17;
	ALPHA=.94+.011*fine;
}
