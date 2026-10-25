# Catálogo de Propuestas de Jugabilidad — Complejidad MEDIO y ALTO
## Simulador B-17 Flying Fortress «Aurora sobre Europa»

Este documento contiene el desglose técnico de mejoras de jugabilidad evaluadas y clasificadas según su complejidad técnica en Godot 4.7.2.

---

## 1.1.2.0 Propuestas de Complejidad MEDIO
*Requieren ampliar sistemas lógicos existentes, nuevos estados de simulación o interactividad adicional en cabina, sin rehacer el motor gráfico ni requerir assets masivos externos.*

### 1.1.2.1 · MEDIO — Gestión de Emergencias de Motores y Extintores
* **Descripción:** Al recibir impacto crítico en un motor (humo denso o fuego), el jugador puede aplicar contramedidas desde cabina de piloto:
  * Desconectar suministro de combustible y embanderar hélice (*feathering*) del motor afectado para reducir resistencia aerodinámica.
  * Disparar el sistema de extintores de CO2 del ala para sofocar el incendio antes de que alcance el tanque de combustible.
  * Compensar timón de dirección para contrarrestar el empuje asimétrico al volar con 3 o 2 motores.
* **Impacto en jugabilidad:** Transforma las alertas de daño de motor en decisiones activas de supervivencia en lugar de desgaste pasivo de salud.

### 1.1.2.2 · MEDIO — Tránsito entre Múltiples Puestos de Ametralladoras
* **Descripción:** Actualmente el puesto de artillero cubre únicamente la torreta dorsal superior. Esta mejora permite ciclar entre las principales estaciones de defensa histórica:
  * **Torreta Dorsal Superior:** Arco de 360° para amenazas altas.
  * **Torreta de Cola (*Tail Gunner*):** Arco trasero estrecho crucial contra ataques de las 6 en punto.
  * **Torreta de Bola Ventral (*Ball Turret*):** Hemisferio inferior para cazas que atacan desde abajo.
* **Impacto en jugabilidad:** El jugador puede cambiar al puesto donde el aviso de amenaza señale el peligro inminente, aprovechando los anclajes de `visuals/combat_mounts.gd`.

### 1.1.2.3 · MEDIO — Escoltas P-51D con Combate Activo y Solicitud por Radio
* **Descripción:** Los 16 Mustang P-51 actualmente realizan pasadas de cobertura visual. Esta mejora permite:
  * Asignar daño real al fuego de los P-51 contra los cazas de la Luftwaffe en su sector.
  * Comando de radio del piloto para solicitar «cobertura cercana» sobre un sector bajo asedio intenso, haciendo que una patrulla de 4 Mustangs persiga activamente a los atacantes más cercanos.
* **Impacto en jugabilidad:** Sensación real de coordinación táctica con los «Little Friends».

### 1.1.2.4 · MEDIO — Impactos de Metralla de Flak con Daño a Instrumentos
* **Descripción:** Las detonaciones cercanas de artillería antiaérea (flak) lanzan metralla que puede causar averías secundarias:
  * Rotura de cristales en la cabina o visor con efecto visual de grietas.
  * Descalibración momentánea del indicador de altitud o brújula.
  * Daño al mecanismo automático de suelta del visor Norden, exigiendo cálculo manual del retículo.
* **Impacto en jugabilidad:** Hace que atravesar la alfombra de flak sobre el objetivo sea mucho más tenso e inmersivo.

---

## 1.1.3.0 Propuestas de Complejidad ALTO
*Involucran modificaciones profundas en el núcleo de físicas, modelos de deformación/destrucción procedural, flujos de persistencia entre misiones o IAs avanzadas de nueva doctrina.*

### 1.1.3.1 · ALTO — Daño Estructural Dinámico y Rotura Procedural
* **Descripción:**
  * Pérdida física de piezas ante impactos críticos: secciones de ala partidas, empenaje de cola desprendido o motores arrancados del encastre.
  * Alteración directa y no lineal del modelo aerodinámico en `core/flight.gd`: pérdida de sustentación asimétrica, pérdida parcial de control de alerones y tendencia al giro incontrolado si no se mantiene trim compensatorio continuo.
  * Animación procedural de descenso en barrena y eyección de paracaídas para tripulantes de bombarderos derribados en la formación.
* **Impacto en jugabilidad:** Representación cinematográfica cruda y visceral del combate aéreo de 1945.

### 1.1.3.2 · ALTO — Modo Campaña «Tour de 25 Misiones» y Estado de Tripulación
* **Descripción:**
  * Sistema de persistencia con guardado en disco del B-17 y su tripulación con nombre propio (Piloto, Copiloto, Navegante, Bombardero y 6 Artilleros).
  * Estados individuales: Fatiga de combate, heridas que reducen la precisión o velocidad de reacción, condecoraciones y marcas de derribos/misiones pintadas en el fuselaje (*nose art tally*).
  * 25 misiones históricas progresivas (Francia ocupada, Ruhr, Bremen, Schweinfurt y Berlín) con diferente meteorología, oposición de caza y densidad de defensas antiaéreas.
* **Impacto en jugabilidad:** Conexión emocional con la tripulación y rejugabilidad a largo plazo.

### 1.1.3.3 · ALTO — Mando Táctico de Escuadrilla (*Combat Wing Command*)
* **Descripción:** El jugador asume el rol de *Flight Lead* (Líder de Formación) sobre los 300 aviones:
  * Ordenar mediante menú de radio formaciones dinámicas: «Caja Cerrada» (*Tight Box* para maximizar fuego cruzado de ametralladoras) o «Caja Abierta» (*Loose Box* para dispersar y minimizar bajas por salvas de flak).
  * Asignar altitud escalonada por alas (*High Wing* / *Low Wing*) para evitar turbulencias o atravesar bancos de nubes.
* **Impacto en jugabilidad:** Eleva el juego de simulación individual a mando de combate aéreo estratégico a gran escala.

### 1.1.3.4 · ALTO — Cazas a Reacción Históricos (Me 262 Schwalbe) y Cohetes R4M
* **Descripción:**
  * Incorporación de interceptores Me 262 con turborreactores Junkers Jumo 004, capaces de pasadas a más de 800 km/h que desbordan la velocidad de giro de las torretas convencionales.
  * Disparo de salvas de cohetes aire-aire R4M de 55 mm desde fuera del alcance defensivo de las ametralladoras de calibre .50.
* **Impacto en jugabilidad:** Añade un enfrentamiento de clímax histórico al final de la guerra con dinámicas de combate completamente distintas.
