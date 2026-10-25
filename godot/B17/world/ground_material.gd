extends RefCounted

static func farmland(tile_meters: float) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_texture = load("res://assets/terrain/farmland_a.png") as Texture2D
    mat.roughness = 1.0
    mat.metallic = 0.0
    mat.uv1_triplanar = true
    mat.uv1_world_triplanar = true
    mat.uv1_scale = Vector3.ONE / maxf(tile_meters, 1.0)
    mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
    return mat

static func rail_yard() -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_texture = load("res://assets/terrain/rail_yard.png") as Texture2D
    mat.roughness = 1.0
    mat.metallic = 0.0
    mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
    return mat
