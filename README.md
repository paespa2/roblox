# 🍬 El Patrón del Dulce

**El Patrón del Dulce** es un juego de acción, tycoon y supervivencia en Roblox ambientado en una vibrante ciudad clandestina de dulces. Los jugadores producen caramelos en la Cocina de la Abuela, evaden a la Policía Dental, adquieren vehículos y mejoras, completan misiones de campaña y sobreviven a desafiantes hordas de zombis inspiradas en el modo supervivencia de *Call of Duty Zombies*.

---

## 🚀 Características Principales

- **🏭 Economía Clandestina & Tycoon:**
  - Cocina interactiva con recetas de dulces, calderos y puntos de venta urbanos.
  - Gestión de almacén, camiones de reparto y sistema de niveles/fama.
- **🚔 Sistema de Persecución & Policía Dental:**
  - Sistema de búsqueda por estrellas (dientes picados).
  - Patrullas policiales con conos de visión, redadas y cárcel (*Internado Sin Azúcar*).
- **🧟 Modo Supervivencia de Hordas (Estilo CoD Zombies):**
  - NPC **Dante** ubicado dentro de la Cocina de la Abuela para activar las oleadas.
  - Progresión matemática de rondas con dificultad incremental (salud, velocidad y densidad de hordas).
  - Inteligencia artificial avanzada con `PathfindingService`, detección visual y máquina de estados finita (`Idle`, `Detecting`, `Chasing`, `Attacking`, `Stunned`, `Dead`).
  - Animaciones procedurales integradas con fallback automático en caso de falta de assets externos.
  - HUD interactivo con conteo en tiempo real de oleadas y zombis restantes.
- **🔫 Sistema de Dulce-Armas:**
  - Armas temáticas de confitería (Chicle-Pistola, Escopeta de Caramelo, etc.) con validación de disparos en servidor, raycasting y recarga.
- **🛵 Sistema de Vehículos y Conducción Urbana:**
  - Motos y bicicletas de reparto con arquitectura modular (`ModelosVehiculos`, `VehiculosService`, `VehiculoController`).
  - Físicas estables en coordenadas de mundo con propulsión `LinearVelocity` en modo Line y giro `AngularVelocity`.
  - Llantas cilíndricas verticales con esferas de física interna, estabilizador giroscópico e inclinación dinámica (*banking*) en curvas.
  - Efectos reactivos: audio dinámico de motor, luces LED frontales, luz trasera de freno, pito/bocina (`[H]`), invocación/guardado (`[V]`) y pedaleo procedural.
- **🚗 Tráfico y Transporte Público:**
  - Red de transporte urbano con paradas de taxi (Don Libardo), chiva tradicional, tráfico vehicular sincronizado y cebras peatonales.
- **🗺️ Sistema de Cartografía, Minimapa Adaptable y GPS 3D:**
  - Minimapa radar en tiempo real con 3 tamaños configurables (`[P]` Pequeño, `[M]` Mediano, `[G]` Grande) mediante animación con `TweenService` y redimensionado interactivo libre con tirador (`⤢`).
  - Mapa táctico panorámico (`[M]`) con buscador en vivo, filtros por categorías y cálculo dinámico de distancias.
  - Navegación GPS tridimensional con trazado de caminos de neón sobre el asfalto (`PathfindingService`) y detección de llegada.
- **🌾 Misiones de Fincas Exteriores (Tycoon Gateway):**
  - NPCs de misión con historia y reputación (Don Efraín, Doña Carmenza, Capataz Ramiro) ensamblados con `ConstructorR6` para desbloquear el acceso a fincas cafeteras y cañaverales.

---

## 📂 Estructura del Proyecto

El código fuente está organizado siguiendo una estricta separación modular con **Rojo**:

```
roblox/
├── default.project.json       # Configuración de compilación de Rojo
├── docs/                      # Documentación técnica y guías de IA
│   ├── ARQUITECTURA.md        # Arquitectura modular, persistencia y eventos remotos
│   ├── SISTEMA_VEHICULOS.md   # Sistema de motos, bicicletas, físicas y conducción
│   ├── SISTEMA_HORDAS_ZOMBIS.md # Especificación del modo supervivencia y oleadas
│   ├── SISTEMA_MAPA_GPS.md    # Minimapa adaptable, radar y GPS 3D
│   └── GUIA_PARA_IA.md        # Manual para agentes de Inteligencia Artificial
├── src/
│   ├── client/                # Lógica del cliente (HUD, animaciones, entradas)
│   │   ├── Horda/             # Controlador de Dante, interfaz de oleadas y animaciones
│   │   ├── Vehiculos/         # Controlador de vehículos, físicas y entradas de teclado
│   │   ├── HUDEstrellas.client.luau
│   │   ├── HUDPrincipal.client.luau
│   │   └── ...
│   ├── server/                # Lógica autoritativa del servidor
│   │   ├── Horda/             # HordeService, WaveManager, ZombieAI, ZombieService
│   │   ├── Vehiculos/         # ModelosVehiculos, VehiculosService autoritativo
│   │   ├── GestorDatos.luau   # Persistencia de perfiles con ProfileService
│   │   ├── SistemaArmas.server.luau
│   │   ├── SistemaCocina.server.luau
│   │   └── ...
│   └── shared/                # Configuraciones inmutables y contratos de red
│       ├── Datos/             # Catálogos de zombis, armas, mejoras, vehículos
│       └── Eventos/
│           └── EventosRemotos.luau # Broker de red centralizado con fallback
```

---

## 🛠️ Requisitos Previos e Instalación

1. **Herramientas necesarias:**
   - [Git](https://git-scm.com/)
   - [Rokit](https://github.com/rojo-rbx/rokit) (gestor de herramientas para Roblox)
   - [Roblox Studio](https://create.roblox.com/)

2. **Instalación de la cadena de herramientas:**
   ```bash
   rokit install
   ```

3. **Iniciar el servidor de sincronización de Rojo:**
   ```bash
   rojo serve
   ```
   *Luego, pulsa "Connect" en el plugin de Rojo dentro de Roblox Studio.*

4. **Compilar el archivo de lugar independiente (`.rbxl`):**
   ```bash
   rojo build -o ElPatronDelDulce.rbxl
   ```

---

## 🔍 Control de Calidad y Formato

El repositorio cuenta con estándares estrictos de formato y análisis estático:

- **Linter (Selene):**
  ```bash
  selene src
  ```
- **Formateador (StyLua):**
  ```bash
  stylua --check src
  ```

---

## 📖 Documentación Adicional

- [Arquitectura Técnica Completa](docs/ARQUITECTURA.md)
- [Sistema de Vehículos y Conducción Urbana](docs/SISTEMA_VEHICULOS.md)
- [Sistema de Cartografía, Minimapa Adaptable y GPS 3D](docs/SISTEMA_MAPA_GPS.md)
- [Especificación del Sistema de Zombis y Hordas](docs/SISTEMA_HORDAS_ZOMBIS.md)
- [Guía de Desarrollo y Convenciones para Agentes de IA](docs/GUIA_PARA_IA.md)
