# Guía de Desarrollo para Agentes de IA (AI Handbook)

Esta guía está diseñada para que cualquier modelo de Inteligencia Artificial (Antigravity, Claude Code, Cursor, GitHub Copilot u otros agentes autónomos) comprenda de inmediato la arquitectura, las convenciones y las restricciones del repositorio **El Patrón del Dulce**.

---

## 1. Contexto Rápido del Proyecto

- **Juego:** *El Patrón del Dulce*
- **Género:** Tycoon de acción + Supervivencia de Hordas + Economía de dulces clandestinos.
- **Motor:** Roblox (Luau estricto).
- **Herramienta de Sincronización:** **Rojo** (`default.project.json`).
- **Persistencia de Datos:** **ProfileService** mediante [src/server/GestorDatos.luau](file:///c:/Users/dadada/Desktop/EL%20PATRON%20DEL%20DULCE/roblox/src/server/GestorDatos.luau).

---

## 2. Reglas Inquebrantables para la IA

### ⚠️ Regla 1: Manejo Seguro de Hilos y Temporizadores
**NUNCA** invoques `task.cancel(hilo)` directamente sin comprobar que el hilo no esté actualmente en ejecución ni esté muerto:
```luau
-- ❌ INCORRECTO (provoca error 'cannot cancel thread'):
local function cerrar()
    if miTimer then task.cancel(miTimer) end
end

-- ✅ CORRECTO (Patrón seguro en Luau):
local function cancelarMiTimer()
    if miTimer then
        local h = miTimer
        miTimer = nil
        if coroutine.running() ~= h and coroutine.status(h) ~= "dead" then
            task.cancel(h)
        end
    end
end
```
Asimismo, en `task.delay`, limpia la referencia antes de invocar el callback:
```luau
miTimer = task.delay(duracion, function()
    miTimer = nil
    callback()
end)
```

### ⚠️ Regla 2: Acceso a Eventos Remotos
**NUNCA** hagas `ReplicatedStorage:WaitForChild("EventosRemotos"):WaitForChild("MiEvento")` de forma suelta en scripts de cliente o servidor.
**SIEMPRE** importa el broker unificado:
```luau
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)
-- Si el evento no existe en la carpeta aún, la metatabla lo crea automáticamente sin arrojar nil.
EventosRemotos.MiEvento:FireServer(...)
```

### ⚠️ Regla 3: No Inventar Asset IDs de Roblox
**NUNCA** inventes identificadores numéricos ficticios de tipo `rbxassetid://123456789` para animaciones, mallas (`MeshId`) o sonidos.
- Si necesitas animaciones: Usa el controlador procedural de [ZombieAnimationController.luau](file:///c:/Users/dadada/Desktop/EL%20PATRON%20DEL%20DULCE/roblox/src/client/Horda/ZombieAnimationController.luau) o sondea IDs ya existentes en [src/shared/Datos/](file:///c:/Users/dadada/Desktop/EL%20PATRON%20DEL%20DULCE/roblox/src/shared/Datos/).
- Si necesitas sonidos: Usa activos integrados de Roblox (`rbxasset://sounds/...`) o IDs verificados del proyecto.

### ⚠️ Regla 4: Autoridad del Servidor (Server-Authoritative)
- Ningún cliente puede modificar su dinero, inventario, vida o progreso directamente.
- Toda acción de compra, disparo, daño o avance debe validarse en el servidor (`src/server/`).

---

## 3. Guía Paso a Paso para Agregar Nuevas Características

### A. ¿Cómo agregar un nuevo tipo de Zombi?
1. Abre [src/shared/Datos/Zombis.luau](file:///c:/Users/dadada/Desktop/EL%20PATRON%20DEL%20DULCE/roblox/src/shared/Datos/Zombis.luau).
2. Añade la nueva variante a la tabla `Tipos`:
   ```luau
   Zombis.Tipos.Acido = {
       Nombre = "Zombi Ácido",
       VidaBase = 120,
       VelocidadBase = 14,
       DanoBase = 18,
       ColorPiel = Color3.fromRGB(80, 160, 60),
       RecompensaPesos = 30,
   }
   ```
3. En [src/server/Horda/ZombieService.luau](file:///c:/Users/dadada/Desktop/EL%20PATRON%20DEL%20DULCE/roblox/src/server/Horda/ZombieService.luau), maneja cualquier habilidad especial (ej. explosión al morir en el estado `Dead`).

### B. ¿Cómo agregar un nuevo Perk o Ventaja?
1. Agrega los datos del Perk en `src/shared/Datos/Zombis.luau` bajo `Zombis.Ventajas`.
2. Crea el modelo físico de la máquina expendedora con un `ProximityPrompt` en la escena.
3. Conecta la compra al servidor para deducir pesos y aplicar el buff al jugador en `GestorDatos`.

### C. ¿Cómo agregar una nueva Dulce-Arma?
1. Registra el arma en [src/shared/Datos/Armas.luau](file:///c:/Users/dadada/Desktop/EL%20PATRON%20DEL%20DULCE/roblox/src/shared/Datos/Armas.luau) con sus estadísticas (daño, cadencia, capacidad, alcance, precio).
2. Configura los efectos visuales y sonido de disparo.
3. [SistemaArmas.server.luau](file:///c:/Users/dadada/Desktop/EL%20PATRON%20DEL%20DULCE/roblox/src/server/SistemaArmas.server.luau) se encargará automáticamente del cálculo de raycast y aplicación de daño a enemigos y zombis.

---

## 4. Comandos de Verificación Recomendados

Antes de dar por concluida cualquier tarea:
```bash
# 1. Comprobar que no hay errores de sintaxis ni variables no usadas
selene src

# 2. Formatear el código según las reglas del proyecto
stylua src

# 3. Validar que la compilación con Rojo genere el archivo rbxl sin discrepancias
rojo build -o ElPatronDelDulce.rbxl
```
