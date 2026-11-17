# Contrato de Rutina Diaria y Retención (dueño: Santiago)

> **Sistemas de Retención Diaria y Semanal (Fase 3)**  
> **Dueño:** Santiago (Economía).  
> **Regla de oro:** *"Los sistemas premian volver, pero no castigan faltar."*

---

## 1. Racha de Entrada Diaria (`Racha_7Dias`)

Ciclo semanal de 7 días. Cada día consecutivo otorga un premio mayor:

| Día | Nombre del Premio | Tipo de Recompensa | Cantidad | Descripción |
| :---: | :--- | :--- | :---: | :--- |
| **Día 1** | Bienvenida | `PesosDulces` | 50 | Impulso inicial para la primera mejora. |
| **Día 2** | Golosinas de la Abuela | `Dulce_Gomita` | 10 | Munición para la cauchera o mercancía valiosa. |
| **Día 3** | Ganancia de Cuadra | `PesosDulces` | 150 | Permite comprar la `Vehiculo_Moto`. |
| **Día 4** | Seguro Dental | `ComodinRacha` | 1 | Protege la racha si un día no puedes jugar. |
| **Día 5** | Reinversión Clandestina | `PesosDulces` | 300 | Financia mejoras de cocina nivel 2. |
| **Día 6** | Dulce Especial | `Dulce_Arequipe` | 8 | Ingreso rápido de alto valor casero. |
| **Día 7** | Cofre del Patrón | `AzucarDorada` + `PesosDulces` | 25 Azúcar + $500 | Premio mayor semanal. |

### Regla del Comodín:
- Si el jugador no entra un día, pero tiene un `ComodinRacha` en su inventario, se consume automáticamente y la racha **NO** se reinicia a 1.

---

## 2. Pool de Encargos Diarios (3 Encargos por Día)

Cada día a las 00:00 UTC (o cada 24 horas) se seleccionan 3 encargos aleatorios:

| Identificador | Otorgado por | Tarea | Requisito | Premio Pesos | Puntos de Pase |
| :--- | :--- | :--- | :---: | :---: | :---: |
| `Encargo_EntregaBombones` | Doña Melcocha | Entrega 20 bombones en el colegio | 20 | 30 | 50 |
| `Encargo_VentaGomitas` | Don Ábaco | Vende 15 gomitas en tiendas del barrio | 15 | 45 | 50 |
| `Encargo_EscapadaDental` | Lola Paleta | Escapa de una patrulla dental con 1 estrella | 1 | 50 | 75 |
| `Encargo_RecetaCasera` | Doña Melcocha | Fabrica 5 panelitas o arequipes en la paila | 5 | 60 | 60 |
| `Encargo_ClienteFiel` | Don Ábaco | Vende mercancía a 3 tiendas distintas en un viaje | 3 | 70 | 80 |

---

## 3. Dulce del Día (Multiplicador Especial)
- Cada día el servidor elige 1 dulce del recetario como el **Dulce del Día**.
- **Efecto:** Todas las tiendas pagan **3.0x (Triple valor)** por ese dulce durante las 24 horas.
- Invita al jugador a cambiar su receta activa en la cocina para aprovechar la demanda.

---

## 4. Producción en Ausencia (Almacenamiento Offline)
- La cocina sigue cocinando mientras el jugador duerme o no está conectado.
- **Tasa de producción offline:** 50% de la velocidad normal.
- **Tope de tiempo:** **8 horas** máximo de acumulación continua.
- Al volver a entrar, una pantalla de bienvenida le muestra los dulces acumulados y se los entrega al instante.
