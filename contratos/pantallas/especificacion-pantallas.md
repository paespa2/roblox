# Especificación y Bocetos de Pantallas (UI) — Santiago (Economía)

> **Contrato de Interfaz**  
> **Dueño:** Santiago (Economía) decide qué muestra cada pantalla, su disposición y sus textos.  
> **Implementación:** Pablo (Sistemas) programa los ScreenGuis / componentes; Andrés (Entorno) provee los iconos y texturas.

---

## 1. Tienda de Mejoras (`UI_Pantalla_Mejoras`)
Permite al jugador reinvertir sus pesos dulces en mejorar su velocidad de cocina, capacidad de bodega o vehículos.

### Componentes y Distribución
- **Encabezado:**
  - Título: `"MEJORAS DEL NEGOCIO"`
  - Saldo actual: `💰 {PesosDulces} pesos dulces`
  - Botón de cierre `[X]`.
- **Pestañas superiores:**
  - `[Cocina]` | `[Vehículos]` | `[Bodega]`
- **Lista de Tarjetas de Mejora:**
  - **Tarjeta Cocina:**
    - Icono: Olla humeante.
    - Nombre: `"Velocidad de Cocina Niv. {NivelActual}"`
    - Efecto actual vs siguiente: `"Tiempo de cocción: {T_Actual}s ➔ {T_Siguiente}s (-15%)"`
    - Botón de acción: `[Comprar por ${Precio}]` (Deshabilitado si saldo insuficiente).
  - **Tarjeta Receta Extra:**
    - Nombre: `"Segunda Olla Clandestina"`
    - Efecto: `"Permite producir 2 recetas simultáneas"`
    - Botón de acción: `[Comprar por $250]`.
  - **Tarjeta Bodega:**
    - Icono: Caja de madera.
    - Nombre: `"Almacén de Ausencia Niv. {NivelActual}"`
    - Efecto: `"Capacidad offline: {Cap_Actual} ➔ {Cap_Siguiente} dulces"`
    - Botón de acción: `[Comprar por ${Precio}]`.

---

## 2. Inventario y Carga (`UI_Pantalla_Inventario`)
Muestra qué mercancía lleva el jugador encima y la carga colocada en su vehículo.

### Componentes y Distribución
- **HUD Inferior / Modal:**
  - Indicador de capacidad del vehículo:  
    `🚗 Carga en Vehículo: {CargaActual}/{CapacidadMax} dulces` (Barra de progreso visual).
    - Color barra: Verde (<70%), Amarillo (70-90%), Rojo (>90% - mayor atracción de patrullas).
- **Cuadrícula de Dulces en Posesión:**
  - Slot por cada dulce:
    - Miniatura del dulce (`Dulce_Bombon`, `Dulce_Chicle`, etc.).
    - Cantidad: `x{Cantidad}`.
    - Valor unitario base: `${ValorVenta}`.
    - Botón rápido: `[Cargar al Vehículo]` / `[Descargar]`.
- **Alerta de Sobrecarga:**
  - Texto dinámico: `"¡Mucho peso! Tu velocidad se reduce en un 20% y las patrullas te detectan más rápido."`

---

## 3. Estrellas de Búsqueda (`UI_HUD_Estrellas`)
Indicador permanente en la esquina superior derecha que muestra el nivel de amenaza de la Policía Dental.

### Componentes Visuales
- **Fila de 5 Estrellas dentales:**
  - Forma: Diente / Muela caricaturesca.
  - Estados:
    - 0 estrellas: Contorno gris transparente (Tranquilo).
    - 1 estrella: Diente amarillo titilante. *"Patrulla en alerta en el barrio"*.
    - 2 estrellas: 2 dientes naranjas. *"Patrullas persiguiendo; conos de visión más amplios"*.
    - 3 estrellas: 3 dientes rojos + sirena dental. *"Retenes bloqueando carreteras; riesgo de Internado Sin Azúcar"*.
    - 4-5 estrellas: Dientes con caries/fuego violeta. *"Aparición del Comandante Muelas"*.
- **Temporizador de enfriamiento:**
  - Anillo o barra que desciende cuando el jugador está escondido en un callejón o punto `Escondite`.

---

## 4. Encargos del Día (`UI_Pantalla_Encargos`)
Panel de objetivos diarios para incentivar la sesión corta (10-15 minutos).

### Componentes y Distribución
- **Encabezado:**
  - Título: `"ENCARGOS DE DOÑA MELCOCHA"`
  - Reloj de reseteo: `⏱ Nuevos encargos en: {HH:MM:SS}`
- **Lista de 3 Misiones Diarias:**
  - **Fila de encargo:**
    - Icono de tarea.
    - Texto descriptivo (ej: *"Entrega 20 bombones en el colegio"*).
    - Barra de progreso: `[ 12 / 20 ] (60%)`.
    - Recompensas visibles: `+30 Pesos` | `+50 Pts Pase`.
    - Estado: `[En curso]` o `[¡Reclamar Recompensa!]` (botón dorado brillante al completar).

---

## 5. Racha Diaria (`UI_Modal_Racha`)
Ventana emergente al iniciar sesión por primera vez en el día.

### Componentes y Distribución
- **Título:** `"CALENDARIO DEL DULCERO"`
- **Subtítulo:** `"Racha actual: {Dias} días seguidos 🔥"`
- **Carrusel de 7 Días:**
  - Día 1: 50 Pesos Dulces. `[Reclamado ✓]`
  - Día 2: 10 Gomitas especiales. `[Reclamado ✓]`
  - Día 3: 150 Pesos Dulces. `[¡HOY! - Botón Reclamar]`
  - Día 4: 1 Comodín de Racha. `[Bloqueado]`
  - Día 5: 300 Pesos Dulces. `[Bloqueado]`
  - Día 6: Receta exclusiva de Dulce Casero. `[Bloqueado]`
  - Día 7: Cofre de Azúcar Dorada. `[Bloqueado]`
- **Comodín semanal:**
  - Mensaje explicativo: `"Tienes 1 comodín disponible: si faltas un día, tu racha no se reinicia."`

---

## 6. Capítulo Actual y Campaña (`UI_Pantalla_Capitulo`)
Ventana que guía el avance del jugador y el paso a la siguiente fase.

### Componentes y Distribución
- **Cabecera del Capítulo:**
  - Título: `"CAPÍTULO 1: EL RECREO"`
  - Ilustración caricaturesca del patio del colegio con el coordinador distraído.
- **Misión Principal para cerrar capítulo:**
  - Objetivo: `"Vende 50 dulces a escondidas en el colegio."`
  - Progreso: `[ 35 / 50 dulces vendidos ]`
- **Recompensa por desbloquear:**
  - Logro: `"Primer bombón"`
  - Desbloquea: `Bicicleta de Reparto` (icono desbloqueable en grande).
- **Consejo de Don Ábaco:**
  - Cuadro de diálogo inferior: *"Vende en la hora del recreo para ganar el doble antes de que toquen el timbre."*
