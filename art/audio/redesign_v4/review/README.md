# Revisión A/B contextual v4

No se ha reproducido audio ni realizado escucha humana. A = banco anterior respaldado;
B = candidato contextual. Cada pareja tiene el mismo RMS y margen de pico, sin limitador.
`*_AB.wav`: A, pausa intencionada de 600 ms, B. `*_10x.wav`: diez vueltas continuas
para evaluar unión, repetición y fatiga. Los archivos de revisión no son el banco activo.
No contienen M2. El volumen RMS comparable no garantiza igual sonoridad percibida.

Escuchar manualmente primero motor exterior/interior, flak cercano y cambio de puesto.
Comprobar ruido ajeno, transitorios, textura y cansancio; después evaluar la mezcla en misión.
Los bucles del banco incluyen smpl; los 10x son archivos lineales sin bucle.
`levels.json` documenta las ganancias y hashes A/B. Regenerar con:
`python3 -I tools_audio/review_contextual_set.py`.
