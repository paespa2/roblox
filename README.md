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
- **🚗 Tráfico y Transporte Público:**
  - Red de transporte urbano con paradas de taxi (Don Libardo), chiva tradicional, tráfico vehicular sincronizado y cebras peatonales.

---

## 📂 Estructura del Proyecto

El código fuente está organizado siguiendo una estricta separación modular con **Rojo**:

```
roblox/
├── default.project.json       # Configuración de compilación de Rojo
├── docs/                      # Documentación técnica y guías de IA
│   ├── ARQUITECTURA.md        # Arquitectura modular, persistencia y eventos remotos
│   ├── SISTEMA_HORDAS_ZOMBIS.md # Especificación del modo supervivencia y oleadas
│   └── GUIA_PARA_IA.md        # Manual para agentes de Inteligencia Artificial
├── src/
│   ├── client/                # Lógica del cliente (HUD, animaciones, entradas)
│   │   ├── Horda/             # Controlador de Dante, interfaz de oleadas y animaciones
│   │   ├── HUDEstrellas.client.luau
│   │   ├── HUDPrincipal.client.luau
│   │   └── ...
│   ├── server/                # Lógica autoritativa del servidor
│   │   ├── Horda/             # HordeService, WaveManager, ZombieAI, ZombieService
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
- [Especificación del Sistema de Zombis y Hordas](docs/SISTEMA_HORDAS_ZOMBIS.md)
- [Guía de Desarrollo y Convenciones para Agentes de IA](docs/GUIA_PARA_IA.md)
