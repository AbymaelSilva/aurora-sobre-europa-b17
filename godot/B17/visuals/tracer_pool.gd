extends Node3D

@export var capacity:int=48
@export var lifetime:float=0.28

var emitted := 0
var dropped := 0
var peak_active := 0

var meshes:Array[MeshInstance3D]=[]
var velocities:Array[Vector3]=[]
var ages:PackedFloat32Array=PackedFloat32Array()

func _ready():
    var box:=BoxMesh.new()
    box.size=Vector3(.20,.20,3.0)
    var mat:=StandardMaterial3D.new()
    mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_color=Color(1,.75,.3)
    mat.emission_enabled=true
    mat.emission=Color(1,.6,.2)
    mat.emission_energy_multiplier=4.0
    for i in range(clampi(capacity,1,256)):
        var m:=MeshInstance3D.new()
        m.mesh=box
        m.material_override=mat
        m.visible=false
        m.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(m)
        meshes.append(m)
        velocities.append(Vector3.ZERO)
        ages.append(lifetime)

    var flash_mesh := SphereMesh.new()
    flash_mesh.radius = 0.35
    flash_mesh.height = 0.7
    flash_mesh.radial_segments = 6
    flash_mesh.rings = 3
    for i in range(24):
        var m := MeshInstance3D.new()
        m.mesh = flash_mesh
        m.material_override = mat
        m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        m.visible = false
        add_child(m)
        flashes.append(m)
        flash_ages.append(1.0)

func fire(origin:Vector3,velocity:Vector3)->bool:
    for i in range(meshes.size()):
        if ages[i]>=lifetime:
            meshes[i].position=origin
            velocities[i]=velocity
            ages[i]=0.0
            meshes[i].visible=true
            if velocity.length()>0.01:
                var dir:Vector3=velocity.normalized()
                var up:Vector3=Vector3.UP if absf(dir.dot(Vector3.UP))<0.99 else Vector3.FORWARD
                meshes[i].basis=Basis.looking_at(dir,up)
            var camera := get_viewport().get_camera_3d()
            var width := 1.0
            if camera != null: width = clampf(camera.global_position.distance_to(origin) * 0.008, 1.0, 12.0)
            meshes[i].scale = Vector3(width, width, 1.0)
            emitted += 1
            peak_active = maxi(peak_active, active_count())
            return true
    dropped += 1
    return false

func advance(delta:float)->void:
    for i in range(flashes.size()):
        flash_ages[i] += maxf(delta, 0.0)
        flashes[i].visible = flash_ages[i] < 0.045
    for i in range(meshes.size()):
        if ages[i]<lifetime:
            ages[i]+=maxf(delta,0.0)
            meshes[i].position+=velocities[i]*maxf(delta,0.0)
        if ages[i]>=lifetime:
            meshes[i].visible=false

func active_count()->int:
    var n:int=0
    for age in ages:
        if age<lifetime:
            n+=1
    return n

func reset()->void:
    for i in range(flashes.size()):
        flash_ages[i] = 1.0
        flashes[i].visible = false
    emitted = 0
    dropped = 0
    peak_active = 0
    for i in range(meshes.size()):
        ages[i]=lifetime
        meshes[i].visible=false

# Separate 24-slot muzzle pool, 45 ms; no lights, audio or per-shot allocations.
var flashes: Array[MeshInstance3D] = []
var flash_ages: Array[float] = []

func flash(origin: Vector3) -> void:
    for i in range(flashes.size()):
        if flash_ages[i] >= 0.045:
            flashes[i].global_position = origin
            flash_ages[i] = 0.0
            flashes[i].visible = true
            return

func set_frozen(frozen: bool) -> void:
    for i in range(meshes.size()): meshes[i].visible = not frozen and ages[i] < lifetime
    for i in range(flashes.size()): flashes[i].visible = not frozen and flash_ages[i] < 0.045
