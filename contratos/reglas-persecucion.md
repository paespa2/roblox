# Contrato de Persecución y Búsqueda (dueño: Santiago)

> **Mecánica de Persecución: Policía Dental y Estrellas de Búsqueda**  
> **Dueño de Reglas y Números:** Santiago (Economía).  
> **Implementación de IA y Patrullas:** Pablo (Sistemas).  
> **Modelos y Efectos:** Andrés (Entorno).

---

## 1. Reglas de Generación de Calor (Estrellas de Búsqueda)

El calor aumenta al realizar actividades clandestinas en las calles del barrio:

| Acción del Jugador | Calor Generado | Explicación |
| :--- | :--- | :--- |
| **Venta en tienda común** | +15 pts | Cada entrega atrae la mirada de los vecinos. |
| **Venta en el Colegio** | +25 pts | Zona escolar altamente vigilada por el Coordinador. |
| **Sobrecarga en vehículo** | +5 pts/segundo | El vehículo lento y chirriante llama la atención. |
| **Disparo de Cauchera de Gomitas** | +20 pts | El impacto genera ruido y alerta patrullas cercanas. |
| **Romper una barricada de retén** | +50 pts (+1 estrella directa) | Evasión forzada en control policial. |

---

## 2. Niveles de Estrellas y Comportamiento Policial

| Nivel (Estrellas) | Umbral de Puntos | Efecto en el Mundo | Consecuencia si te Atrapan |
| :---: | :--- | :--- | :--- |
| ⭐ **1 Estrella** | 50 pts | 1 Patrulla Dental recorre la vía principal con sirena apagada. Cono de visión corto (30 studs). | Advertencia verbal; pierdes 10% de la carga si te detienes. |
| ⭐⭐ **2 Estrellas** | 120 pts | Patrullas activan sirena con sonido de torno de dentista. Persiguen a 22 studs/s. Cono de visión 55 studs. | Confiscación del 50% de la carga del morral (los escondites del vehículo están a salvo). |
| ⭐⭐⭐ **3 Estrellas** | 220 pts | Se activan los **Retenes Dentales** en las carreteras. Patrullas lanzan espuma pegajosa. | **Internado Sin Azúcar (Cárcel).** Confiscación de toda la carga no oculta. Condena: 1 minuto. |
| ⭐⭐⭐⭐ **4 Estrellas** | 350 pts | Persecución total. Patrullas veloces (32 studs/s). Barricadas reforzadas en ambas salidas del barrio. | **Internado Sin Azúcar.** Condena: 2 minutos. Fianza: $100 pesos dulces. |
| ⭐⭐⭐⭐⭐ **5 Estrellas** | 500 pts | Aparición del vehículo blindado del **Comandante Muelas**. | **Internado Sin Azúcar.** Condena: 3 minutos (máximo en Fase 2). Fianza: $250 pesos. |

---

## 3. Mecánica de Enfriamiento y Escondites

- **En la calle abierta:** El calor baja a un ritmo de **-3 pts/segundo** si no estás en la línea de visión de ninguna patrulla.
- **En punto `Escondite` (Callejones oscuros, detrás de la cocina de la abuela, desarmadurías):**  
  El calor baja aceleradamente a **-15 pts/segundo**.
- Si una estrella se enfría por completo, no vuelve a subir a menos que cometas una nueva infracción visible.

---

## 4. Reglas del Internado Sin Azúcar (Cárcel)

Para mantener la diversión y evitar el abandono del juego:
1. **El dinero (`pesos dulces`) NUNCA se pierde.**
2. **Las recetas desbloqueadas y vehículos comprados se conservan.**
3. **Mecanismos para salir del Internado:**
   - **Cumplir condena:** Máximo 3 minutos.
   - **Trabajo comunitario:** Cepillar muelas gigantes en el patio del internado reduce **20 segundos** de condena por muela limpia.
   - **Pagar fianza:** Si tienes saldo, puedes sobornar al enfermero con pesos dulces según las estrellas de captura.
