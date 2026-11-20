# Arquitectura Técnica — El Patrón del Dulce

Este documento describe la arquitectura modular, los patrones de diseño y los estándares de ingeniería implementados en **El Patrón del Dulce**, un juego de acción y tycoon para Roblox desarrollado en Luau moderno con sincronización bidireccional mediante **Rojo**.

---

## 1. Filosofía de Diseño y Principios

1. **Separación de Responsabilidades (SoC):**
   - **Servidor (`src/server`):** Toda la lógica de negocio, economía, persistencia (`ProfileService`), validación de combate, IA enemiga y generación de instancias autoritativas reside exclusivamente en el servidor.
   - **Cliente (`src/client`):** Presentación visual, captura de entrada de usuario (`UserInputService`, `ContextActionService`), interfaces (`ScreenGui`), animaciones del cliente, efectos de partículas, interpolación (`TweenService`) y predicción visual sin autorización de cambios de estado críticos.
   - **Compartido (`src/shared`):** Definiciones de configuración inmutable (`Datos`), catálogo de armas, recetas de dulces, vehículos, misiones y el contrato de red unificado (`EventosRemotos`).

2. **Cero Fugas de Memoria y Ciclo de Vida Seguro:**
   - Desconexión explícita de `RBXScriptConnection` al destruir objetos.
   - Cancelación segura de subprocesos (`task.delay`, `task.spawn`) verificando `coroutine.running() ~= thread` y `coroutine.status(thread) ~= "dead"` para evitar excepciones de tipo `cannot cancel thread`.

3. **Tolerancia a Fallos de Red y Asincronía:**
   - `EventosRemotos.luau` actúa como un broker resiliente con fallback dinámico mediante metatablas (`__index`), garantizando que llamadas a eventos de red nunca devuelvan `nil` aunque el servidor aún no haya instanciado la réplica física.

---

## 2. Mapeo de Proyecto con Rojo (`default.project.json`)

El archivo `default.project.json` define la jerarquía de compilación para Roblox Studio:

```json
{
  "name": "el-patron-del-dulce",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "Shared": { "$path": "src/shared" },
      "Packages": { "$path": "Packages" }
    },
    "ServerScriptService": {
      "Server": { "$path": "src/server" }
    },
    "StarterPlayer": {
      "StarterPlayerScripts": {
        "Client": { "$path": "src/client" }
      }
    }
  }
}
```

---

## 3. Capa de Red y Comunicación (`src/shared/Eventos/EventosRemotos.luau`)

Todos los intercambios cliente-servidor se canalizan a través del módulo `EventosRemotos`. Los eventos se crean de forma perezosa y segura tanto en cliente como en servidor bajo la carpeta física `ReplicatedStorage.EventosRemotos`.

### Catálogo de Eventos Principales

| Nombre | Tipo | Origen → Destino | Propósito |
|---|---|---|---|
| `SolicitarDatos` | `RemoteFunction` | Cliente → Servidor | Obtiene el perfil de datos del jugador al entrar. |
| `DatosActualizados` | `RemoteEvent` | Servidor → Cliente | Notifica cambios en balance de pesos, fama, nivel o estrellas. |
| `SolicitarCocinar` | `RemoteFunction` | Cliente → Servidor | Inicia la producción de caramelos en la Cocina. |
| `CocinaActualizada` | `RemoteEvent` | Servidor → Cliente | Estado de los calderos e inventario de producción. |
| `DispararArma` | `RemoteFunction` | Cliente → Servidor | Validación de disparo con raycast, daño y munición. |
| `AlertaPolicia` | `RemoteEvent` | Servidor → Cliente | Activa notificaciones de búsqueda y patrullas de policía. |
| `DanteInteraccion` | `RemoteEvent` | Servidor → Cliente | Abre la interfaz de diálogo de Dante para hordas. |
| `SolicitarIniciarHorda` | `RemoteFunction` | Cliente → Servidor | Petición para activar el evento de supervivencia. |
| `HordaOleadaIniciada` | `RemoteEvent` | Servidor → Cliente | Notifica número de oleada, zombis y temporizador. |
| `HordaActualizada` | `RemoteEvent` | Servidor → Cliente | Informa zombis restantes en tiempo real. |
| `HordaFinalizada` | `RemoteEvent` | Servidor → Cliente | Transmite victoria, derrota, oleada alcanzada y recompensas. |
| `ZombieEventoVisual` | `RemoteEvent` | Servidor → Cliente | Señales visuales de zombis (animaciones, golpes, rugidos). |
| `ObtenerDatosMapaGPS` | `RemoteFunction` | Cliente → Servidor | Distribuye los 505 bloques geométricos del mapa urbano para radar y GPS. |

---

## 4. Persistencia y Gestión de Datos (`src/server/GestorDatos.luau`)

- Implementado sobre el patrón **ProfileService**.
- Respaldo de perfiles en `DataStoreService` con manejo automático de sesiones activas (Session Locking).
- Si la API de DataStore no está habilitada en Roblox Studio, conmuta automáticamente a un almacén volátil en memoria para permitir pruebas y desarrollo sin interrupciones.
- Esquema de datos centralizado en [src/shared/Datos/PlantillaPerfil.luau](file:///c:/Users/dadada/Desktop/EL%20PATRON%20DEL%20DULCE/roblox/src/shared/Datos/PlantillaPerfil.luau).

---

## 5. Estructura de Módulos del Sistema

```
src/
├── client/                     # Controladores y vistas de cliente
│   ├── Horda/                  # Módulos del modo supervivencia
│   │   ├── DanteController.luau             # Diálogo 3D con NPC Dante y cámara cinemática
│   │   ├── HordeUI.luau                     # Interfaz visual de oleadas y zombis restantes
│   │   └── ZombieAnimationController.luau   # Fallbacks procedurales de animación
│   ├── Vehiculos/              # Control vehicular interactivo
│   │   └── VehiculoController.luau          # Manejo de inputs, físicas World Line, banking, audio y luces
│   ├── HUDEstrellas.client.luau             # Notificaciones de persecución policial
│   ├── HUDPrincipal.client.luau             # Barra de estadísticas, dinero y banners
│   ├── SistemaMapaGPS.client.luau           # Minimapa adaptable (P/M/G), radar y GPS 3D en la calle
│   ├── ControlArmas.client.luau             # Manejo de armas, mira y recarga
│   ├── ControlVehiculoTeclado.client.luau   # Bootstrap del cliente de vehículos
│   └── SistemaHordaCliente.client.luau      # Bootstrap del cliente de hordas
├── server/                     # Servicios y controladores autoritativos
│   ├── Horda/                  # Lógica del modo zombis (Call of Duty Zombies)
│   │   ├── HordeService.luau                # Spawn de Dante, validación y ciclo general
│   │   ├── WaveManager.luau                 # Progresión de rondas, escalado y temporización
│   │   ├── ZombieService.luau               # Fábrica de zombis, vida, daño y pooling
│   │   ├── ZombieAI.luau                    # Máquina de estados y PathfindingService
│   │   └── UtilidadesMapaHorda.luau         # Generación y validación de puntos de spawn
│   ├── Vehiculos/              # Lógica autoritativa de vehículos
│   │   ├── ModelosVehiculos.luau            # Fábrica 3D procedural de motos y bicis con ruedas verticales
│   │   └── VehiculosService.luau            # Ciclo de vida, física autoritativa, red y montaje
│   ├── SistemaArmas.server.luau             # Registro de impactos y cálculo de daño
│   ├── SistemaCocina.server.luau            # Minijuego de cocina y recetas
│   ├── SistemaMapaServidor.server.luau      # Escaneo autoritativo y entrega de geometría cartográfica
│   ├── SistemaMisionFincas.server.luau      # NPCs de misiones para fincas y tycoon exterior
│   ├── SistemaPersecucion.server.luau       # Patrullas de policía dental y estrellas
│   ├── SistemaVehiculos.server.luau         # Bootstrap del servidor de vehículos
│   └── SistemaHordaZombis.server.luau       # Bootstrap del servidor de hordas
└── shared/                     # Configuraciones inmutables y contratos
    ├── Datos/                  # Tablas de datos de armas, zombis, mejoras, vehículos
    │   ├── Zombis.luau                      # Configuración de oleadas, stats y Dante
    │   ├── PuntosMapa.luau                  # Catálogo de POIs, coordenadas y categorías GPS
    │   ├── Vehiculos.luau                   # Estadísticas, velocidades y precios de vehículos
    │   └── ...
    ├── ConstructorR6.luau      # Ensamblador procedimental de humanoides R6 (ASCII puro)
    └── Eventos/
        └── EventosRemotos.luau              # Módulo de transporte remoto unificado
```

---

## 6. Estándares de Código y Directrices para IA

1. **Tipado Estricto de Luau:** Usar `--!strict` siempre que sea posible.
2. **Uso de Herramientas Oficiales:**
   - Formatear con `stylua`.
   - Validar calidad con `selene src`.
   - Compilar con `rojo build -o ElPatronDelDulce.rbxl`.
3. **Manejo Seguro de Hilos:** Nunca invocar `task.cancel(t)` directamente sin verificar `coroutine.running() ~= t`.
4. **Instanciación Visual:** Todo modelo o accesorio generado proceduralmente debe soldarse con `WeldConstraint` y tener partes no motrices con `CanCollide = false`, `Massless = true` y `Anchored = false`.
