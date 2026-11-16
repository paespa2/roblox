# Simulación de Economía y Progresión — Santiago (Economía)

> **Documento de Balance y Curva de Progresión (Capítulos 1 a 4)**  
> **Objetivo:** Garantizar que cada sesión de juego dure entre 10 y 20 minutos, que el bucle enganche sin estancar al jugador y que las metas de tiempo se cumplan.

---

## 1. Metas de Tiempo por Capítulo (Según Documento de Diseño)

| Capítulo | Título | Mecánica Principal | Tiempo Estimado de Juego | Pesos Acumulados Necesarios |
| :--- | :--- | :--- | :--- | :--- |
| **Cap. 1** | El Recreo | Cocina manual en olla, venta a pie en el patio | **5 minutos** | ~50 pesos |
| **Cap. 2** | La Esquina | Control de 3 tiendas de barrio con bicicleta | **15 minutos** | ~250 pesos |
| **Cap. 3** | La Cocina de la Abuela | Fabricación de arequipe y panelita, compra de moto | **30 minutos** | ~650 pesos |
| **Cap. 4** | La Ruta | Evasión de retenes de Policía Dental con escondites | **60 minutos** | ~1,500 pesos |

---

## 2. Métricas de Producción y Ganancia (Pesos por Minuto - PPM)

### Capítulo 1 (El Recreo)
- **Receta activa:** `Dulce_Bombon` (Tiempo producción: 5s, Valor venta base: $1 peso).
- **Producción teórica:** 12 bombones por minuto = **$12 pesos/minuto** brutos.
- **Logro de cierre:** `"Primer bombón"` (Vender 50 bombones).
- **Tiempo real estimado:**  
  - 50 bombones / 12 por minuto ≈ 4.1 minutos de producción.
  - + 1 minuto de traslados a la tienda del colegio = **~5.1 minutos**. *(Cumple perfectamente la meta de 5 min)*.
- **Premio de cierre:** Desbloqueo de `Vehiculo_Bicicleta` (Capacidad: 20 dulces, velocidad x1.6).

### Capítulo 2 (La Esquina)
- **Recetas activas:** `Dulce_Bombon` + `Dulce_Chicle` ($1 peso, 8s) + `Dulce_Gomita` ($2 pesos, 12s).
- **Capacidad con Bicicleta:** 20 unidades por viaje.
- **Ganancia por viaje completo:**
  - 10 Bombones + 10 Gomitas = (10 x $1) + (10 x $2) = $30 pesos por viaje.
  - Multiplicador de Don Ábaco (1.1x): **$33 pesos por viaje**.
- **Duración del viaje:** 1.5 minutos (ida, venta, vuelta).
- **Ritmo de ganancia (PPM):** **~$22 pesos/minuto**.
- **Meta económica del capítulo:**
  - Comprar `Mejora_Cocina_Velocidad_1` ($50 pesos) + `Mejora_Bodega_Capacidad_1` ($75 pesos) + cuota de 3 tiendas ($100 pesos) = $225 pesos.
  - Tiempo necesario: 225 / 22 ≈ **10.2 minutos** (+ tiempos de menú = **~12 a 15 minutos**). *(Cumple la meta)*.
- **Logro de cierre:** `"Dueño de la cuadra"` (Controlar 3 tiendas).
- **Premio de cierre:** Primera cocina clandestina.

### Capítulo 3 (La Cocina de la Abuela)
- **Nuevas recetas:** `Dulce_Arequipe` ($5 pesos, 25s) y `Dulce_Panelita` ($6 pesos, 30s).
- **Ritmo de ganancia con recetas caseras:** **~$45-50 pesos/minuto**.
- **Meta económica del capítulo:**
  - Comprar `Vehiculo_Moto` ($150 pesos).
  - Comprar `Mejora_Cocina_Velocidad_2` ($180 pesos) + `Mejora_Cocina_RecetaExtra_1` ($250 pesos).
  - Total reinversión: $580 pesos.
  - Tiempo necesario: 580 / 48 ≈ **12.5 minutos** dedicados a compras + misiones de recetas = **~25 a 30 minutos acumulados**. *(Cumple la meta)*.
- **Logro de cierre:** `"Receta secreta"` (Dominar 3 recetas caseras).
- **Premio de cierre:** Moto con 1 compartimiento secreto (escondite).

### Capítulo 4 (La Ruta)
- **Mecánica agregada:** Retenes de la Policía Dental y riesgo de confiscación.
- **Vehículo:** `Vehiculo_Moto` (Capacidad 60 dulces, velocidad 28 studs/s).
- **Ganancia por viaje exitoso:** Hasta **$250 pesos** por viaje a tiendas distantes (`Tienda_TerminalRuta` a 1.3x).
- **Factor de riesgo:** Con 10 entregas limpias requeridas para el logro `"Ni una caries"`, el jugador genera entre $1,500 y $2,000 pesos.
- **Tiempo estimado:** 10 entregas de 4-5 minutos cada una = **~45 a 55 minutos**. *(Cumple la meta de 60 minutos)*.

---

## 3. Balance del Castigo por Confiscación (Policía Dental)
Para evitar que el jugador se frustre y abandone el juego:
1. **Regla de oro:** El dinero ya ganado (`pesos dulces`) **NUNCA** se confisca.
2. **Pérdida al ser empalagado:**
   - Solo se pierde la carga actual del vehículo que no esté en el `Escondite`.
   - Con la moto (1 escondite), el 25% de la carga más valiosa queda a salvo automáticamente.
3. **Tiempo de espera en Internado:** Máximo 1 minuto por estrella (máximo total 3 minutos en fase 1). Las tareas de cepillado gigante reducen 20 segundos por tarea.
