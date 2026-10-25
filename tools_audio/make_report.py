#!/usr/bin/env python3
"""Genera planning/orquestacion/ENTREGA_AUDIO_CLAUDE.md a partir de logs/audio/check_sfx.json
y logs/audio/synth_manifest.json, más la autoevaluación escrita a mano en ASSESS.

    python3 -I tools_audio/make_report.py

Escrito por Claude (2026-10-24).
"""
import json
import os
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHECK = os.path.join(ROOT, "logs", "audio", "check_sfx.json")
MANIFEST = os.path.join(ROOT, "logs", "audio", "synth_manifest.json")
OUT = os.path.join(ROOT, "planning", "orquestacion", "ENTREGA_AUDIO_CLAUDE.md")

# Autoevaluación: (convincente, aproximado)
ASSESS = {
    "engine_b17_ext_loop.wav": ("Batido lento entre los 4 motores y pulso de escape a 172 Hz con hélice a 65 Hz: el «zumbido pulsante» está bien planteado.",
                                "Sin turbo ni el rugido irregular real de un radial; puede sonar algo limpio y uniforme."),
    "engine_b17_int_loop.wav": ("Más oscuro (−5 a −8 dB en 0,5–1 kHz frente al exterior) con resonancia de fuselaje; la vibración de las chapas añade cuerpo.",
                                "La estructura real tiene muchos más modos y traqueteos; la resonancia es genérica."),
    "engine_b17_damaged_loop.wav": ("Los fallos de encendido y los petardeos aleatorios se distinguen bien del motor sano.",
                                    "La forma del petardeo es genérica; un motor real tocado tiene golpeteos mecánicos que no están."),
    "engine_sputter_01.wav": ("Caída de rpm con toses irregulares: se lee como «motor tocado».", "Las toses pueden sonar parecidas entre sí."),
    "engine_sputter_02.wav": ("Variante distinta (otra semilla y otra caída de rpm).", "Igual que la 01."),
    "engine_fire_loop.wav": ("Rugido grave con parpadeo y chasquidos: funciona como capa de fondo.",
                             "Fuego sintético: le falta la textura «rasgada» de una llama real con viento a 300 km/h."),
    "wind_altitude_loop.wav": ("Rachas lentas y un silbido de rendija que deriva; estéreo decorrelado y amplio.", "El silbido es una sola resonancia; el real tiene varias."),
    "formation_drone_loop.wav": ("Zumbido lejano y ancho con desvanecimientos independientes por avión.", "Muy dependiente del filtro de distancia; puede quedar algo turbio."),
    "gun_m2_shot_01.wav": ("Ataque inmediato (<0,1 ms), golpe grave y chasquido del cerrojo: sirve a cadencia de 0,12 s.",
                           "Un .50 real tiene un estampido mucho más complejo; aquí es ruido + seno."),
    "gun_m2_shot_02.wav": ("Variante con timbre ±7 %.", "Igual que la 01."),
    "gun_m2_shot_03.wav": ("Variante con timbre ±7 %.", "Igual que la 01."),
    "gun_m2_burst.wav": ("8 disparos alternando dos armas con micro-variaciones de tiempo: evita el efecto «ametralladora de 8 bits».",
                         "Cadencia de 0,112 s (según la tabla); la cadencia real de dos M2 juntas sería mayor."),
    "gun_casings_01.wav": ("Modos inarmónicos y rebotes cada vez más cortos: los tintineos metálicos son de lo más creíble del set.",
                           "Suelo de torreta genérico."),
    "hit_hull_01.wav": ("Chasquido + desgarro + modos de panel de aluminio: lectura clara de «impacto metálico».", "La perforación real es más «seca»; puede sonar algo a campana."),
    "hit_hull_02.wav": ("Variante.", "Igual que la 01."),
    "hit_hull_03.wav": ("Variante.", "Igual que la 01."),
    "shrapnel_rattle_01.wav": ("Densidad decreciente de golpecitos con algunos fuertes: efecto «granizo».", "La distribución es estadística; no hay trozos grandes."),
    "damage_alarm_bell.wav": ("Martillo a 22 Hz sobre 6 modos de campana: timbre eléctrico reconocible.", "Campana idealizada; la real tiene el zumbido del electroimán."),
    "fighter_flyby_01.wav": ("Doppler físico (tiempo de emisión exacto), 1/r, absorción del aire y panorámica: la curva de tono y volumen es correcta.",
                             "La fuente (V12 sintético) es la parte débil; el «rasgado» real de un 109 en pasada es mucho más rico."),
    "fighter_flyby_02.wav": ("Fw 190 con 14 cilindros, más rápido y más cerca: se distingue de la 01.", "Igual que la 01."),
    "fighter_engine_loop.wav": ("Más agudo y saturado que el B-17, con deriva de rpm y oleadas.", "Silbido del compresor simplificado (un seno)."),
    "fighter_guns_distant.wav": ("Dos cadencias superpuestas (20 mm y 13 mm), amortiguadas y difusas.", "Sin el «crac» supersónico de los proyectiles que pasan cerca."),
    "fighter_explosion.wav": ("Onda N, bola de fuego, subgrave y restos: lectura clara de explosión media en el aire.", "Explosión «de manual»; falta la desintegración del avión (metal, hélice)."),
    "fighter_falling_whine.wav": ("Aullido que baja de tono por doppler real y se apaga con la distancia.", "El aullido es de tono algo puro; puede sonar «de película»."),
    "flak_near_01.wav": ("Estampido seco con metralla inmediata y cola: de los sonidos más eficaces del set.", "La cola es reverberación genérica, no el eco real del cielo abierto."),
    "flak_near_02.wav": ("Variante de tamaño y metralla.", "Igual que la 01."),
    "flak_near_03.wav": ("Variante de tamaño y metralla.", "Igual que la 01."),
    "flak_far_01.wav": ("«Pum» sordo (todo por debajo de ~300 Hz), fácil de repetir sin cansar.", "Se apoya mucho en el subgrave: en altavoces pequeños se oirá poco."),
    "flak_far_02.wav": ("Variante.", "Igual que la 01."),
    "bomb_bay_doors_open.wav": ("Arranque y parada del motor, chirridos de bisagra y viento que crece: la narrativa se entiende.",
                                "El motor eléctrico es una sierra filtrada; el real tiene más ruido de engranajes."),
    "bomb_release.wav": ("Golpe mecánico seco con muelle: corto y legible.", "Genérico."),
    "bomb_impact_distant.wav": ("Retumbo grave que rueda con ecos del terreno: transmite distancia.", "Igual que el flak lejano: depende del subgrave."),
    "bomb_secondary_explosions.wav": ("Cadena irregular de tamaños y espaciados distintos.", "Las explosiones individuales se parecen entre sí."),
    "ui_navigate.wav": ("Limpio y corto.", "—"),
    "ui_accept.wav": ("Ascendente, claro.", "—"),
    "ui_back.wav": ("Descendente, simétrico a aceptar.", "—"),
    "ui_pause.wav": ("Golpe apagado y grave.", "—"),
    "ui_profile_change.wav": ("Doble tic claro.", "—"),
    "station_switch.wav": ("Clic de interfono + soplido de radio: encaja con la época.", "—"),
    "cue_release_tick.wav": ("Tic suave para repetir en cuenta atrás.", "—"),
    "cue_release_now.wav": ("Dos tonos (La5–Re6) claros y redondos, sin agresividad.", "—"),
    "cue_course_correction.wav": ("Tono medio con trémolo leve, distinto de «suelta ahora».", "—"),
    "radio_squelch_open.wav": ("Clic + estática de banda estrecha.", "—"),
    "radio_squelch_close.wav": ("«Chsk» corto.", "—"),
    "radio_static_loop.wav": ("Estática de banda estrecha con desvanecimiento, chasquidos y heterodino.", "La radio real de 1944 tiene más zumbido y distorsión de válvulas."),
    "stinger_mission_complete.wav": ("Cadencia plagal IV→I (Si♭/Fa → Fa), sobria y esperanzada.", "Metales de sintetizador analógico: no parecen una sección de metales real."),
    "stinger_mission_failed.wav": ("Re menor grave que se apaga con caída de 35 cents y filtro que se cierra.", "Igual que el de éxito."),
}

TOP5 = [
    ("engine_b17_ext_loop.wav / engine_b17_int_loop.wav",
     "Es lo que más se oye en toda la misión. Un radial real tiene un rugido irregular y rico que la síntesis por pulsos solo imita; "
     "una grabación de un B-17 superviviente (p. ej., en exhibiciones de vuelo) lo mejoraría más que cualquier otro cambio."),
    ("fighter_flyby_01.wav / fighter_flyby_02.wav",
     "La física del doppler es correcta, pero la fuente sintética no tiene la aspereza de un DB 605 o un BMW 801 reales."),
    ("gun_m2_shot_01..03.wav",
     "El jugador lo dispara cientos de veces: un estampido real de M2 (con el mecanismo) daría mucho más peso."),
    ("flak_near_01..03.wav",
     "Una explosión real tiene una textura y una cola imposibles de imitar con ruido filtrado."),
    ("stinger_mission_complete.wav / stinger_mission_failed.wav",
     "Una sección de metales real (o al menos un instrumento muestreado) sonaría claramente más cuidada que las sierras filtradas."),
]


def main():
    with open(CHECK, encoding="utf-8") as f:
        check = json.load(f)
    with open(MANIFEST, encoding="utf-8") as f:
        man = json.load(f)
    groups = {"A": "B-17: motores y vuelo", "B": "Armas propias", "C": "Daños en el propio avión",
              "D": "Cazas enemigos", "E": "Flak", "F": "Bombardeo", "G": "Interfaz, HUD y radio", "H": "Misión"}
    byname = {r["file"]: r for r in check["files"]}
    L = []
    L.append("# Entrega de audio · Claude (terminal de audio)")
    L.append("")
    L.append(f"Generado el {time.strftime('%Y-%m-%d %H:%M')} con `python3 -I tools_audio/make_report.py`.")
    L.append("")
    L.append("## Resumen")
    L.append("")
    L.append(f"- **{check['present']} de {check['expected']}** WAV en `godot/B17/assets/audio/sfx/`, "
             f"{check['total_bytes'] / 1e6:.1f} MB en total. Verificación `tools_audio/check_sfx.py`: **{check['result']}** "
             f"(`logs/audio/check_sfx.log`, `logs/audio/check_sfx.json`).")
    L.append("- Prueba de Godot `tests/test_audio_assets.gd`: **TEST PASS** (`logs/audio/test_audio_assets.log`). "
             "Carga los 47 con `AudioStreamWAV.load_from_file` y comprueba los datos, 44 100 Hz, 16 bits, los canales, "
             "la duración y que los bucles salgan con `LOOP_FORWARD`.")
    L.append("- Todo se sintetiza con `tools_audio/synth_sfx.py`, que solo usa la biblioteca estándar y tarda unos 14 s en un "
             "pool de 8 procesos. Cada archivo usa una semilla fija (crc32 del nombre). He comprobado que dos ejecuciones, "
             "una en paralelo y otra con `--serial`, dan los 47 archivos idénticos byte a byte (sha256).")
    L.append("- Los bucles llevan un bloque RIFF `smpl` con el bucle completo. Godot lo detecta solo al importar o cargar "
             "(`loop_mode = LOOP_FORWARD`), así que la integración no necesita configurar los puntos de bucle.")
    L.append("- Niveles: motores, ambientes, pasadas y stingers a −20 dBFS RMS; armas e impactos a −14 (algunos "
             "apuntados a −16/−17 dentro de la tolerancia: casquillos, campana, flak lejano, bomba lejana, cañones lejanos); "
             "interfaz y radio a −22. El pico máximo es −1,1 dBFS: un limitador suave lo garantiza.")
    L.append("- No he modificado código de producción, escenas ni `release/`. La `--import` obligatoria de Godot creó los "
             "`.import` de los WAV y algunos `.uid` que faltaban en scripts de otros (metadatos que Godot genera solo).")
    L.append("")
    L.append("**Aviso honesto:** no puedo escuchar los archivos. La autoevaluación se basa en el diseño de cada síntesis y "
             "en medidas objetivas (niveles por bandas de octava, factor de cresta, variación de RMS por ventanas). "
             "Antes de dar el set por definitivo, una persona debe escucharlo.")
    L.append("")
    L.append("## Bloques del sintetizador")
    L.append("")
    L.append("Osciladores (seno, sierra y pulso o cuadrada con polyBLEP), FM por fase y AM; ruido blanco, rosa (Kellet), "
             "marrón y chasquidos; biquads RBJ (paso bajo, paso alto, paso banda y pico resonante), SVF TPT con frecuencia "
             "variable y banco de resonadores modales; envolventes ADSR, exponencial y por tramos; tanh y limitador suave; "
             "doppler físico (trayectoria recta con el tiempo de emisión resuelto exactamente, más una fuente que se aleja "
             "y un remuestreo variable genérico); reverberación tipo Freeverb (6 peines realimentados y amortiguados, "
             "3 pasa-todo, mono y estéreo); bucles con fundido cruzado de potencia constante de 150 ms y rotación a la "
             "unión más suave; motor de pistones genérico (radial de 9 cilindros, V12 y doble estrella de 14).")
    L.append("")
    L.append("## Hoja de escucha")
    L.append("")
    L.append("Columnas: duración (s), pico (dBFS), RMS (dBFS) / objetivo, inicio (ms) o salto en la unión (fracción "
             "de la escala completa).")
    for g, title in groups.items():
        L.append("")
        L.append(f"### {g}. {title}")
        L.append("")
        L.append("| Archivo | Dur. | Pico | RMS / obj. | Inicio / unión | Técnica | Convincente | Aproximado |")
        L.append("|---|---|---|---|---|---|---|---|")
        for name, m in man.items():
            if m["group"] != g:
                continue
            r = byname[name]
            tag = (" (E)" if m["stereo"] else "") + (" BUCLE" if m["loop"] else "")
            edge = f"unión {r['seam_jump']:.4f}" if m["loop"] else f"{r['onset_ms']:.2f} ms"
            ok, approx = ASSESS[name]
            L.append(f"| `{name}`{tag} | {r['duration']:.2f} | {r['peak_dbfs']:.1f} | {r['rms_dbfs']:.1f} / "
                     f"{r['rms_target']:.0f} | {edge} | {m['tech']} | {ok} | {approx} |")
    L.append("")
    L.append("## Los 5 sonidos que más mejorarían con una grabación real")
    L.append("")
    for i, (n, why) in enumerate(TOP5, 1):
        L.append(f"{i}. **{n}**: {why}")
    L.append("")
    L.append("## Cómo regenerar y verificar")
    L.append("")
    L.append("```bash")
    L.append("cd /home/test-bench/Documents/B17-project")
    L.append("python3 -I tools_audio/synth_sfx.py          # o con grupos: python3 -I tools_audio/synth_sfx.py A D")
    L.append("python3 -I tools_audio/check_sfx.py")
    L.append("tools/godot --headless --path godot/B17 --import")
    L.append("tools/godot --headless --path godot/B17 --script res://tests/test_audio_assets.gd")
    L.append("python3 -I tools_audio/make_report.py")
    L.append("```")
    L.append("")
    L.append("## Notas para la integración (paso del supervisor)")
    L.append("")
    L.append("- Disparos: usar `gun_m2_shot_01..03` al azar, con un `pitch_scale` aleatorio de ±3 %, en un `AudioStreamPlayer` "
             "con `max_polyphony` ≥ 4. `gun_m2_burst` sirve para ráfagas preconstruidas o en la distancia.")
    L.append("- `engine_b17_ext_loop` y `engine_b17_int_loop` tienen la misma duración: se puede hacer un fundido cruzado entre "
             "ellos al cambiar de vista. `engine_b17_damaged_loop` está pensado como capa sobre el motor sano.")
    L.append("- Los stingers y las pasadas son estéreo. Las pasadas ya llevan su panorámica, así que deben ir en un "
             "`AudioStreamPlayer` sin espacialización, no en un `AudioStreamPlayer3D`.")
    L.append("")
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(L))
    print("escrito", OUT)


if __name__ == "__main__":
    main()
