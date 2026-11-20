# 🛵 Sistema de Vehículos y Conducción Urbana — El Patrón del Dulce

Este documento detalla la arquitectura modular, física de simulación, actuadores rígidos, modelos 3D y controladores del sistema de vehículos (motos y bicicletas de reparto) en **El Patrón del Dulce**.

---

## 1. Visión General y Arquitectura Modular

El sistema de vehículos sigue el estándar de diseño desacoplado del proyecto (similar al módulo de Hordas), separando de forma estricta:
1. **La definición geométrica y constructores de modelos** (`ModelosVehiculos.luau`).
2. **El servicio autoritativo del servidor** (`VehiculosService.luau`).
3. **El controlador interactivo del cliente** (`VehiculoController.luau`).
4. **Los puntos de entrada ligeros** (`SistemaVehiculos.server.luau` y `ControlVehiculoTeclado.client.luau`).

```
roblox/src/
├── client/
│   ├── Vehiculos/
│   │   └── VehiculoController.luau        # Controlador de físicas, cámara, inputs, audio y banking
│   └── ControlVehiculoTeclado.client.luau # Bootstrap cliente
├── server/
│   ├── Vehiculos/
│   │   ├── ModelosVehiculos.luau          # Constructores de fallbacks 3D (motos, bicis)
│   │   └── VehiculosService.luau          # Spawn, propiedad de red, colisiones y ciclo de vida
│   └── SistemaVehiculos.server.luau       # Bootstrap servidor
└── shared/
    └── Datos/
        └── Vehiculos.luau                 # Metadatos, velocidades, aceleraciones y precios
```

---

## 2. Física de Conducción y Actuadores de Restricción

Para evitar los problemas típicos de inestabilidad, derrapes invertidos de `VehicleSeat` nativo y caídas bajo el mapa, el sistema utiliza un modelo de física personalizada impulsado por actuadores de Roblox Physics:

### 2.1 Componentes en el Chasis

| Instancia | Clase | Configuración Clave | Propósito |
|---|---|---|---|
| `DriveAtt` | `Attachment` | Posición en el centro de masa | Punto de anclaje para propulsión y giro. |
| `UprightAtt` | `Attachment` | `Axis = (0, 1, 0)`, `SecondaryAxis = (0, 0, -1)` | Referencia vertical pura para el giroscopio. |
| `DriveLV` | `LinearVelocity` | `RelativeTo = World`, `VelocityConstraintMode = Line` | Impulsa el vehículo hacia adelante en la dirección horizontal del chasis (`forwardDir`). |
| `SteerAV` | `AngularVelocity` | `RelativeTo = World`, `AngularVelocity = (0, yaw, 0)` | Rota el vehículo limpiamente en el eje Y global. |
| `EstabilizadorVertical` | `AlignOrientation` | `AlignType = PrimaryAxisParallel`, `PrimaryAxis = (0, 1, 0)` | Mantiene el chasis erguido y permite inclinación (*banking*) en curvas. |
| `ContrapesoBajo` | `Part` (Soldada) | `Density = 4.0`, masa baja | Baja el centro de masa para evitar vuelcos en giros bruscos. |

### 2.2 Corrección de Llantas y Geometría Vertical

- **Orientación Vertical de Ruedas:** Todas las ruedas cilíndricas (`Enum.PartType.Cylinder`) visuales se posicionan con `Orientation = Vector3.zero`, evitando que se vean acostadas horizontalmente sobre el asfalto.
- **Ruedas Físicas Ocultas:** Dos esferas invisibles (`RuedaFisica`) en la base de cada rueda proporcionan contacto esférico suave con el pavimento sin atorarse en bordillos o desniveles.
- **Despeje de Raycast en Spawn (+1.95 studs):** Al invocar o reaparecer el vehículo, un raycast hacia abajo calcula la cota exacta del pavimento y sitúa el chasis a `+1.95 studs` de altura, garantizando que ninguna parte quede enterrada bajo el mapa.

---

## 3. Controles e Interacción del Jugador

### 3.1 Mapeo de Teclado y Controles

- **`[W]` / `[Flecha Arriba]`:** Acelerar hacia adelante de forma progresiva.
- **`[S]` / `[Flecha Abajo]`:** Frenar y marcha atrás (activa las luces rojas de freno traseras).
- **`[A]` / `[D]` o `[Flechas]`:** Dirección izquierda y derecha con inclinación de chasis realista (*banking* dinámico).
- **`[V]`:** Invocar vehículo frente al jugador o desmontar y guardar en el morral si ya está montado.
- **`[H]`:** Hacer sonar el pito/bocina (`🛵 ¡PII-PII!`) con efecto de sonido y cartel flotante interactivo.
- **`[Espacio]`:** Desmontar de forma segura, expulsando al jugador hacia la derecha (+3.0 studs) para evitar atascarse en la colisión del vehículo.

### 3.2 Efectos Audiovisuales y Ambientales

1. **Audio Dinámico de Motor:** Modula el `PlaybackSpeed` (0.65x a 1.6x) y el `Volume` progresivamente según la velocidad lineal actual.
2. **Luces Reactivas:** Farola frontal proyectada (`SpotLight`) para navegación nocturna y luz trasera de freno (`PointLight` + `Neon`) que se ilumina intensamente al pulsar `[S]`.
3. **Animación Procedural de Pedaleo:** En la bicicleta, el controlador anima las piernas del personaje en tiempo real sincronizando las articulaciones `LeftHip`, `RightHip`, `LeftKnee` y `RightKnee` con el avance de la rueda.
4. **Fricción por Superficie:** Detecta el material del suelo mediante raycast hacia abajo:
   - **Asfalto / Concreto:** 100% velocidad máxima (48 studs/s en moto).
   - **Pasto / Césped:** 75% velocidad máxima.
   - **Arena / Barro:** 55% velocidad máxima.
   - **En el aire:** Apaga la tracción para evitar aceleraciones aéreas no físicas.

---

## 4. Puntos de Interacción en el Mapa

1. **Taller de Reparto (Punto Cocina Inicial):**
   - Cuenta con un `ProximityPrompt` que permite a los nuevos jugadores tomar su bicicleta o moto inicial equipada.
2. **Maestro Tuerca (Mecánico del Barrio):**
   - NPC interactivo ubicado en la zona comercial urbana.
   - Ofrece diálogo de ambientación y abre la interfaz `TiendaMejoras` para comprar y equipar mejores vehículos.
