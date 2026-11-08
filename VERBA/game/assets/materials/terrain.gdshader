shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D meadow_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D forest_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D amber_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D silt_tex : source_color, repeat_enable, filter_linear_mipmap;
varying vec3 world_pos;
varying vec3 vertex_tint;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    vertex_tint = COLOR.rgb;
}

void fragment() {
    vec2 uv = world_pos.xz * 0.15;
    vec3 meadow = texture(meadow_tex, uv).rgb;
    vec3 forest = texture(forest_tex, uv * 0.85).rgb;
    vec3 amber = texture(amber_tex, uv).rgb;
    vec3 silt = texture(silt_tex, uv).rgb;
    float forest_factor = (1.0-smoothstep(-24.0, 12.0, world_pos.x)) * 0.72;
    float amber_factor = smoothstep(17.0,35.0,world_pos.x) * (1.0-smoothstep(40.0,62.0,world_pos.z));
    float stream_x = -20.0 + 4.4*sin(world_pos.z*0.075) + 1.7*sin(world_pos.z*0.21);
    float wet_factor = 1.0 - smoothstep(3.0, 10.0, abs(world_pos.x - stream_x));
    vec3 base = mix(meadow, forest, forest_factor);
    base = mix(base, amber, amber_factor * 0.85);
    base = mix(base, silt, wet_factor * 0.88);
    ALBEDO = mix(base, base*vertex_tint, 0.18);
    ROUGHNESS = 0.97;
    METALLIC = 0.0;
}
