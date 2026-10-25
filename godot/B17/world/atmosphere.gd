extends WorldEnvironment

func _ready() -> void:
    var sky_material := ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color(0.28, 0.38, 0.48)
    sky_material.sky_horizon_color = Color(0.70, 0.76, 0.82)
    sky_material.ground_bottom_color = Color(0.75, 0.78, 0.82)
    sky_material.ground_horizon_color = Color(0.70, 0.76, 0.82)
    sky_material.sun_angle_max = 3.0
    var sky := Sky.new()
    sky.sky_material = sky_material
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
    env.ambient_light_energy = 0.5
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.tonemap_exposure = 1.0
    env.fog_enabled = true
    # Lote 8 (1.1.5.1): Reducción del 75% respecto a 0.00010 para visibilidad clara de formación, flak y horizonte
    env.fog_density = 0.000025
    env.fog_light_color = Color(0.75, 0.80, 0.86)
    env.fog_sun_scatter = 0.1
    env.ssao_enabled = true
    env.ssao_radius = 1.2
    env.ssao_intensity = 1.1
    env.adjustment_enabled = true
    env.adjustment_contrast = 1.04
    env.adjustment_saturation = 0.88
    environment = env
