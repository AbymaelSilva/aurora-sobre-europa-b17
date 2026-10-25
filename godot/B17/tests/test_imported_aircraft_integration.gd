extends SceneTree
# Revisión independiente de Codex Entrega: modelos realmente activos, no solo recursos existentes.
var failures: PackedStringArray = []
var observed: Dictionary = {}
var scene: Node
const MODEL_DIR := "res://assets/aircraft/models/"

func _initialize() -> void:
    run.call_deferred()

func check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
        print("FAIL: ",message)

func descendants(node: Node) -> Array[Node]:
    var found: Array[Node] = []
    for child in node.get_children():
        found.append(child)
        found.append_array(descendants(child))
    return found

func imported_instances(node: Node, path: String) -> Array[Node3D]:
    var found: Array[Node3D] = []
    for child in descendants(node):
        if child is Node3D and child.scene_file_path==path:
            found.append(child)
    return found

func mesh_inventory(node: Node) -> Dictionary:
    var inventory: Dictionary = {}
    for child in descendants(node):
        if child is MeshInstance3D and child.mesh!=null:
            var key: int = child.mesh.get_instance_id()
            inventory[key] = int(inventory.get(key,0))+1
    return inventory

func permitted_detail(node: Node, stop: Node) -> bool:
    var cursor: Node = node
    while cursor!=null and cursor!=stop:
        if cursor.get_script()!=null and cursor.get_script().resource_path=="res://visuals/bomber_details.gd":
            return true
        cursor = cursor.get_parent()
    return false

func check_model(owner_node: Node3D, model_name: String, rotor_count: int) -> Node3D:
    var path: String = MODEL_DIR+model_name+".glb"
    var instances: Array[Node3D] = imported_instances(owner_node,path)
    check(instances.size()==1,"%s must instantiate exactly one %s (found %d)" % [owner_node.get_path(),model_name,instances.size()])
    if instances.size()!=1:
        return null
    var model: Node3D = instances[0]
    var packed := load(path) as PackedScene
    check(packed!=null,"source scene loads: "+path)
    if packed==null:
        return null
    var canonical: Node3D = packed.instantiate()
    check(mesh_inventory(model)==mesh_inventory(canonical),"active geometry matches imported resource: "+str(owner_node.get_path()))
    canonical.free()
    var rotors: Array = model.find_children("Rotor_*","Node3D",true,false)
    check(rotors.size()==rotor_count,"real rotor count: "+str(owner_node.get_path()))
    var textured: bool = false
    for child in descendants(model):
        if child is MeshInstance3D and child.mesh!=null:
            for surface in range(child.mesh.get_surface_count()):
                var material: Material = child.get_active_material(surface)
                if material is BaseMaterial3D and material.albedo_texture!=null:
                    textured = true
    check(textured,"active imported model has a textured material: "+str(owner_node.get_path()))
    for child in descendants(owner_node):
        if child is MeshInstance3D and child.mesh!=null and not model.is_ancestor_of(child):
            check(permitted_detail(child,owner_node),"duplicate/unassigned geometry outside imported model: "+str(child.get_path()))
    for rotor in rotors:
        check(owner_node.to_local(rotor.global_position).z<0.0,"propeller remains forward in aircraft local -Z")
    return model

func sorted_rotors(model: Node3D, aircraft: Node3D) -> Array:
    var rotors: Array = model.find_children("Rotor_*","Node3D",true,false)
    rotors.sort_custom(func(a: Node3D,b: Node3D) -> bool: return aircraft.to_local(a.global_position).x<aircraft.to_local(b.global_position).x)
    return rotors

func check_engine_mapping(aircraft: Node3D, model: Node3D) -> void:
    var rotors: Array = sorted_rotors(model,aircraft)
    if rotors.size()!=4:
        return
    check(scene.engine_smokes.size()==4,"four active engine smoke trails")
    if scene.engine_smokes.size()!=4:
        return
    scene.sim.flight.yaw = 0.63
    scene.sim.flight.pitch = 0.12
    for damaged in range(4):
        scene.sim.damage.engines = PackedFloat32Array([100,100,100,100])
        scene.sim.damage.engines[damaged] = 0.0
        scene.update_presentation(0.0)
        for i in range(4):
            var smoke = scene.engine_smokes[i]
            check(smoke.intensity>0.8 if i==damaged else smoke.intensity==0.0,"health index %d selects physical engine %d smoke" % [damaged,i])
            var trail_local: Vector3 = aircraft.to_local(smoke.global_position)
            var rotor_local: Vector3 = aircraft.to_local(rotors[i].global_position)
            check(absf(trail_local.x-rotor_local.x)<0.25,"trail %d follows left-to-right rotor local x after yaw/pitch" % i)
    var rotor_before: Array[Vector3] = []
    for rotor in rotors:
        rotor_before.append(aircraft.to_local(rotor.global_position))
    var before: Array[Vector3] = []
    for smoke in scene.engine_smokes:
        before.append(aircraft.to_local(smoke.global_position))
    var shift := Vector3(1.25,0.7,-1.1)
    var original: Vector3 = model.position
    model.position += shift
    scene.update_presentation(0.0)
    for i in range(4):
        var moved: Vector3 = aircraft.to_local(scene.engine_smokes[i].global_position)-before[i]
        var expected: Vector3 = aircraft.to_local(rotors[i].global_position)-rotor_before[i]
        check(moved.distance_to(expected)<0.03,"trail %d derives anchor from live model transform, not constants" % i)
    model.position = original
    scene.restart_mission()

func rotor_angles(bombers: Array[Node3D]) -> Array[float]:
    var values: Array[float] = []
    for aircraft in bombers:
        for rotor in aircraft.find_children("Rotor_*","Node3D",true,false):
            values.append(rotor.rotation.z)
    return values

func check_animation(bombers: Array[Node3D]) -> void:
    scene.sim.paused = true
    scene.update_presentation(0.0)
    var frozen: Array[float] = rotor_angles(bombers)
    check(frozen.size()==24,"six active bombers contain 24 real rotors")
    for aircraft in bombers:
        var engines: Node = aircraft.get_node_or_null("Engines")
        check(engines!=null,"Engines contract exists")
        if engines!=null:
            check(not engines.is_processing(),"Engines stops processing during pause")
    await create_timer(0.06).timeout
    var after: Array[float] = rotor_angles(bombers)
    if frozen.size()==after.size():
        for i in range(frozen.size()):
            check(absf(wrapf(after[i]-frozen[i],-PI,PI))<0.00001,"rotor %d actually frozen in pause" % i)
    scene.sim.paused = false
    scene.update_presentation(0.0)
    var moving: Array[float] = rotor_angles(bombers)
    await create_timer(0.06).timeout
    var advanced: Array[float] = rotor_angles(bombers)
    if moving.size()==advanced.size():
        for i in range(moving.size()):
            check(absf(wrapf(advanced[i]-moving[i],-PI,PI))>0.001,"real rotor %d resumes animation" % i)
    scene.restart_mission()

func run() -> void:
    # Control positivo del inspector: las escenas fuente válidas deben pasar antes de inspeccionar el juego.
    for variant in ["b17g","bf109g","fw190a"]:
        var source := load(MODEL_DIR+variant+".glb") as PackedScene
        check(source!=null,"reference GLB imports: "+variant)
        if source!=null:
            var fixture := Node3D.new()
            fixture.name = "Reference_"+variant
            root.add_child(fixture)
            fixture.add_child(source.instantiate())
            check_model(fixture,variant,4 if variant=="b17g" else 1)
            fixture.free()
    var packed := load("res://game.tscn") as PackedScene
    check(packed!=null,"active game scene loads")
    if packed==null:
        finish()
        return
    scene = packed.instantiate()
    root.add_child(scene)
    scene.set_physics_process(false)
    var leader: Node3D = scene.get_node("Aircraft")
    var bombers: Array[Node3D] = [leader]
    for companion in scene.get_node("Formation").wingmen:
        bombers.append(companion)
    check(bombers.size()==6,"leader plus exactly five wingmen")
    var leader_model: Node3D
    for aircraft in bombers:
        var model: Node3D = check_model(aircraft,"b17g",4)
        if aircraft==leader:
            leader_model = model
    if leader_model!=null:
        check_engine_mapping(leader,leader_model)
        await check_animation(bombers)
    var variants: Dictionary = {}
    check(scene.fighter_visuals.size()==48,"forty-eight active fighter visual slots in interception force")
    for fighter in scene.fighter_visuals:
        var names: Array[String] = []
        for variant in ["bf109g","fw190a"]:
            if imported_instances(fighter,MODEL_DIR+variant+".glb").size()>0:
                names.append(variant)
        check(names.size()==1,"fighter visual uses one imported BF109 or FW190: "+str(fighter.get_path()))
        if names.size()==1:
            var model: Node3D = check_model(fighter,names[0],1)
            variants[names[0]] = true
            if model!=null:
                var rotors: Array = model.find_children("Rotor_*","Node3D",true,false)
                check("rotor" in fighter and rotors.has(fighter.rotor),"fighter.rotor references its actual GLB rotor")
    check(variants.has("bf109g") and variants.has("fw190a"),"both fighter variants are instantiated in active scene")
    if variants.has("bf109g") and variants.has("fw190a"):
        scene.restart_mission()
        for frame in range(60*120):
            scene._physics_process(1.0/60.0)
            if scene.sim.combat.fighters.size()>=2:
                break
        check(scene.sim.combat.fighters.size()>=2,"real first combat wave spawns")
        for i in range(mini(scene.sim.combat.fighters.size(),scene.fighter_visuals.size())):
            if scene.sim.combat.fighters[i]["alive"]:
                var fighter: Node3D = scene.fighter_visuals[i]
                check(fighter.is_visible_in_tree(),"live combat fighter is actually visible")
                check(fighter.global_position.distance_to(scene.sim.combat.fighters[i]["ai"].position)<0.01,"imported fighter follows actual combat AI")
    for player in [scene.engine_audio,scene.gun_audio,scene.flak_audio,scene.bomb_audio]:
        if is_instance_valid(player):
            player.stop()
            player.stream = null
    root.remove_child(scene)
    scene.free()
    scene = null
    for frame in range(6):
        await process_frame
        await physics_frame
    finish()

func finish() -> void:
    if failures.is_empty():
        print("TEST PASS: active imported aircraft, six bombers, real rotors, transform-derived engine mapping and fighter variants")
        quit(0)
    else:
        print("TEST FAIL: imported aircraft integration: %d unmet checks" % failures.size())
        quit(1)
