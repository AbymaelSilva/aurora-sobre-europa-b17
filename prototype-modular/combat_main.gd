extends "res://mission_main.gd"

# Adaptación e integración: Codex. Los cuatro módulos nuevos son de Qwen.
var damage = preload("res://damage_model.gd").new()
var flak = preload("res://flak_model.gd").new()
var flak_damage: float = 8.0
var smoke: MeshInstance3D
var failure_reason: String = ""

func _ready() -> void:
    smoke = MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 2.0
    mesh.height = 4.0
    smoke.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.12,0.12,0.12)
    smoke.material_override = material
    add_child(smoke)
    smoke.visible = false

func _unhandled_input(event: InputEvent) -> void:
    super._unhandled_input(event)
    if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
        damage.reset()
        flak.reset()
        failure_reason = ""
        $FlakVisual.age = 10.0
        $FlakVisual.step(0.0)

func _physics_process(delta: float) -> void:
    var active: bool = not paused and mission.phase not in ["COMPLETADA","FALLIDA"]
    if active:
        flight.speed = move_toward(flight.speed,50.0*damage.thrust_factor(),delta*2.0)
        var in_zone: bool = absf(flight.position.x)<180.0 and flight.position.z < -420.0 and flight.position.z > -850.0
        if flak.step(delta,in_zone):
            $FlakVisual.burst(flight.position+Vector3(0,8,-18))
            damage.apply_damage(flak_damage)
        if damage.destroyed():
            failure_reason = "AVION PERDIDO POR FUEGO ANTIAEREO"
            mission.phase = "FALLIDA"
        $FlakVisual.step(delta)
    super._physics_process(delta)
    $Formation.follow(flight.position,flight.yaw,flight.pitch)
    smoke.visible = damage.engine < 85.0
    smoke.position = flight.position+Vector3(7.0,2.5,8.0).rotated(Vector3.UP,flight.yaw)
    smoke.scale = Vector3.ONE*(1.0+(100.0-damage.engine)/40.0)
    $HUD.label.text += "\nFormacion: 3 bombarderos\nAntiaerea: %d rafagas\nFuselaje: %.0f%% | Motor: %.0f%%\nVelocidad: %.1f m/s" % [flak.bursts,damage.hull,damage.engine,flight.speed]
    if failure_reason != "":
        $HUD.label.text += "\n"+failure_reason
