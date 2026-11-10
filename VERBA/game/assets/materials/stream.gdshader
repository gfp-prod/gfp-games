shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque;

// A cold woodland creek, not an opaque turquoise test-ribbon.
// Underlying photographed gravel and banks remain partially visible.
varying vec3 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    float long_ripple = sin(world_pos.z * 1.65 + world_pos.x * .82 - TIME * 1.12);
    float small_ripple = sin(world_pos.z * 4.8 - world_pos.x * 2.2 + TIME * 1.9);
    float slow_sheen = sin(world_pos.z * .43 + world_pos.x * .19 - TIME * .37);
    float ripple = (long_ripple * .024 + small_ripple * .011 + slow_sheen * .015);
    vec3 peaty_water = vec3(.092, .157, .158);
    vec3 cool_reflection = vec3(.045, .064, .061);
    ALBEDO = peaty_water + cool_reflection * (.5 + .5 * slow_sheen) + vec3(ripple);
    ROUGHNESS = .18;
    METALLIC = .00;
    SPECULAR = .45;
    ALPHA = .67 + .025 * small_ripple;
}
