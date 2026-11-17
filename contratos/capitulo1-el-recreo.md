# Contrato de Campaña: Capítulo 1 — El Recreo (dueño: Santiago)

> **Campaña y Progresión: Capítulo 1**  
> **Dueño:** Santiago (Economía & Progresión).  
> **Objetivo:** Introducir al jugador nuevo al bucle clandestino, cerrar la historia de la escuela y otorgar el primer gran logro con recompensa permanente.

---

## 1. Ficha del Capítulo 1

| Campo | Valor / Especificación |
| :--- | :--- |
| **Nombre del Capítulo** | `Capítulo 1: El Recreo` |
| **Misión Principal** | Vender 50 dulces clandestinos en el Colegio sin que te atrape el Coordinador ni la Policía Dental. |
| **Logro de Cierre** | `Logro_PrimerBombon` ("Primer bombón") |
| **Desbloqueo Permanente** | `Vehiculo_Bicicleta` (Acceso libre en el taller de reparto de la cocina) |
| **Paso al Siguiente Capítulo** | Desbloquea `Capítulo 2: La Esquina` |
| **Tiempo Estimado de Completado** | 5 a 6 minutos de juego continuo |

---

## 2. Evento Periódico: "Hora del Recreo" (Impulso del Capítulo 1)

Para incentivar la venta masiva y enseñar los eventos en tiempo real:
- **Frecuencia:** Cada 60 minutos en punto (ej: 1:00, 2:00, 3:00...).
- **Duración:** 10 minutos (o 3 minutos en sesiones rápidas de prueba).
- **Lugar:** `Tienda_ColegioRecreo` (`Punto_Venta_Colegio`).
- **Efecto de Economía:**
  - El precio de venta de `Dulce_Bombon` y `Dulce_Chicle` sube de **1.0x a 2.0x (Doble ganancia)**.
  - El sonido de la campana del colegio anuncia el inicio: `"¡Tocó el timbre del recreo! Los estudiantes quieren dulce. ¡Vende al doble!"`.

---

## 3. Logros Paralelos Disponibles en Capítulo 1
Insignias opcionales que no bloquean la campaña pero dan metas tempranas:
- `Logro_BuenVecino_Inicial`: Vender tus primeros 20 bombones en la tienda de Don Ábaco.
- `Logro_Fantasma_Nivel1`: Completar 5 entregas seguidas sin generar ni 1 sola estrella de búsqueda.
