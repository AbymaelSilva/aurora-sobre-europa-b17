# Diez tareas de Qwen

Una inferencia local a la vez. Máximo tres correcciones por archivo. Las entregas requieren revisión e integración.

1. `world/rail_target.gd` — Build a railway yard centered at local zero. Use helper func box(at: Vector3, size_value: Vector3, color: Color) -> void. This helper create
2. `world/cloud_layer.gd` — _ready creates 24 cloud SphereMesh instances sharing one SphereMesh radius1 height2 radial_segments12 rings6 and one opaque StandardMaterial
3. `visuals/flak_burst.gd` — Fields age:float=0.0, lifetime:float=4.0, active:bool=false. _ready creates 8 opaque dark spheres sharing one SphereMesh radius1 height2 rad
4. `visuals/markings.gd` — _ready adds two Label3D children at Vector3(-1.4,0.4,3.0),Vector3(1.4,0.4,3.0). Text="AURORA • 01",font_size=48,pixel_size=0.012,modulate=Co
5. `visuals/bomb_body.gd` — _ready creates original olive falling bomb aligned long axis along local Y. SphereMesh body radius0.28,height1.4,radial_segments12,rings6,ma
6. `core/radio_director.gd` — Fields last_phase:String="",message:String="",remaining:float=0.0.
7. `core/debrief.gd` — static func build(phase:String,hull:float,engines:PackedFloat32Array,elapsed:float,bomb_result:String)->Dictionary: return dictionary keys t
8. `ui/navigation_marker.gd` — Fields target_screen:Vector2=Vector2.ZERO,distance_m:float=0.0,show_marker:bool=false. _ready sets mouse_filter=Control.MOUSE_FILTER_IGNORE 
9. `visuals/engine_smoke.gd` — _ready builds 6 spheres sharing SphereMesh radius1 height2 radial_segments8 rings4 and opaque dark StandardMaterial3D roughness1. Each at po
10. `audio/engine_tone.gd` — static func create_stream()->AudioStreamWAV: generate exactly22050 mono samples of signed16bit PCM at22050Hz. For sample index i, t=float(i)

## Resultado verificado por Codex
Los10archivos se generaron en logs/qwen-ten/. Hubo5entregas que agotaron correcciones de sintaxis y varios fallos semánticos; Codex realizó correcciones puntuales. `tests/test_qwen_assets.gd` ejecutado: TEST PASS para los10módulos, incluyendo instanciación, determinismo de nubes, geometría/materiales, visibilidad/expiración/reset de flak, radio, debrief, señal de audio y marcador. Su integración está en game.gd. El results.json original conserva el resultado inicial de Qwen, no el estado final revisado.

El usuario pidió después Agy como coordinador para completar TODOel código. Se entregó escena a Agy con planning/AGY_HANDOFF_READY. Registro y recibo: logs/agy-coordinador/status.json y planning/AGY_RECEPCION.md. Otros10encargos de Claude son un lote separado (claude_qwen_batch.py), con nombres sin colisiones.
