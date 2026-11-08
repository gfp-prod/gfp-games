shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque;
varying vec3 world_pos;
void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
    float r1 = sin((world_pos.z*2.7 + world_pos.x*.8) - TIME*1.45);
    float r2 = sin(world_pos.z*.91 - world_pos.x*3.2 + TIME*.88);
    float shimmer = clamp(r1*.14 + r2*.10, -.15, .15);
    ALBEDO = vec3(.17,.31,.30) + vec3(shimmer*.38,shimmer*.4,shimmer*.48);
    ROUGHNESS = .23;
    METALLIC = .08;
    ALPHA = .80;
}
