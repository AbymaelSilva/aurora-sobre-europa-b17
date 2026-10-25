extends Node3D

var particles:CPUParticles3D
var intensity:float=0.0

func _ready():
    particles=CPUParticles3D.new()
    particles.amount=48
    particles.lifetime=3.0
    particles.local_coords=false
    particles.emitting=false
    var puff:=SphereMesh.new()
    puff.radius=.5
    puff.height=1.0
    puff.radial_segments=8
    puff.rings=4
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=Color(1,1,1,1)
    mat.vertex_color_use_as_albedo=true
    mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.roughness=1.0
    puff.material=mat
    particles.mesh=puff
    particles.direction=Vector3(0,0,1)
    particles.spread=12.0
    particles.initial_velocity_min=4.0
    particles.initial_velocity_max=8.0
    particles.gravity=Vector3(0,1.5,0)
    particles.scale_amount_min=1.5
    particles.scale_amount_max=4.0
    particles.color=Color(.1,.1,.1,.25)
    add_child(particles)

func set_intensity(value:float):
    intensity=clamp(value,0.0,1.0)
    particles.emitting=intensity>0.05
    particles.color=Color(.1,.1,.1,lerp(.25,.8,intensity))

func from_engine_health(health:float):
    set_intensity(clamp((85.0-health)/85.0,0.0,1.0))
