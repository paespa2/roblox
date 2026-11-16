# Tablero de Tareas — Fase 2 (Persecución y Policía Dental)
**Coordinador de Fase:** Pablo (@paespa2 - Sistemas)  
**Integrantes:** Pablo (@paespa2 - Sistemas), Andrés (@Andresbrt - Entorno), Santiago (@ThiagoDO7 - Economía)

---

## 📌 Estado del Tablero

### 🟢 HECHO (Completado)
- [x] **[Pablo - Sistemas]** Sistema de calor y estrellas de búsqueda (0 a 5) en servidor (`GestorDatos.luau` y `SistemaPersecucion.server.luau`).
- [x] **[Pablo - Sistemas]** Interfaz permanente `UI_HUD_Estrellas` con 5 dientes caricaturescos (`HUDEstrellas.client.luau`), animaciones de alerta y barra de enfriamiento.
- [x] **[Pablo - Sistemas]** Conexión con los escondites de Andrés (`Workspace.Puntos.Escondites`), visuales 3D y lógica de enfriamiento continuo.
- [x] **[Pablo - Sistemas]** Retenes de la Policía Dental (`Workspace.Puntos.Retenes`) con sirena de advertencia y confiscación de carga con teleport al consultorio al ser detectado.
- [x] **[Pablo - Sistemas]** Incremento dinámico de calor policial al concretar ventas en `SistemaVentas.server.luau`.
- [x] **[Pablo - Sistemas]** Primera arma del juego: Cauchera de Gomitas (`Arma_CaucheraGomitas`), consumo de munición de golosinas, disparo con física y aturdimiento de 1 segundo a retenes (`SistemaArmas.server.luau`).
- [x] **[Pablo - Sistemas]** Contrato de eventos actualizado en `contratos/lista-de-eventos.md` (`EstrellasActualizadas`, `AlertaPolicia`, `CargaConfiscada`, `DispararArma`).

---

### 🟡 EN CURSO (En Desarrollo)
- [ ] **[Andres - Entorno]** Modelado 3D definitivo de la patrulla dental (`Vehiculo_PatrullaDental`) y vallas de retenes.
- [ ] **[Andres - Entorno]** Partículas personalizadas de confeti, crema y humo para impactos de cauchera.
- [ ] **[Santiago - Economía]** Ajuste fino de la tasa de calor según la zona de venta (más calor cerca al colegio o alcaldía).

---

### ⚪ POR HACER (Backlog Inmediato)
- [ ] **[Santiago - Economía]** Plan de pruebas de Fase 2 (huida exitosa, enfriamiento en escondite y uso de cauchera).
- [ ] **[Los Tres]** Auditoría formal de Fase 2 antes del paso a Fase 3 (Rutina Diaria).
