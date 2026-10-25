shader_type spatial;
render_mode cull_back;
uniform sampler2D farmland_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 world_position;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    vec2 uv = world_position.xz/1200.0;
    vec3 color = texture(farmland_texture, uv).rgb;
    // Modulación amplia para que las repeticiones distantes resulten menos uniformes.
    float variation = 0.94 + 0.06 * sin(world_position.x * 0.00032) * cos(world_position.z * 0.00027);
    color *= variation;

    // Manto invernal de nieve europea continua (Invierno de 1944)
    vec3 snow_color = vec3(0.92, 0.94, 0.97);
    float snow_coverage = clamp(0.72 + 0.20 * sin(world_position.x * 0.0016 + world_position.z * 0.0012) + 0.08 * cos(world_position.x * 0.0035), 0.65, 0.95);
    color = mix(color, snow_color, snow_coverage);

    // Cauce fluvial transformado en río helado con tonos azulados pálidos y alta reflectividad
    float river_x = 430.0 + 180.0 * sin(world_position.z * 0.0012) + 50.0 * sin(world_position.z * 0.0047);
    float river = 1.0 - smoothstep(35.0, 48.0, abs(world_position.x - river_x));
    vec3 ice_color = vec3(0.70, 0.80, 0.86);
    color = mix(color, ice_color, river);

    ALBEDO = color;
    METALLIC = mix(0.0, 0.18, river);
    ROUGHNESS = mix(0.90, 0.22, river);
}
