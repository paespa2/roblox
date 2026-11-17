# Tabla de datos (dueño: Santiago)

> **Contrato de Economía y Parámetros Físicos** — Única fuente de verdad para números, balance y progresión.
> Formato de identificadores: `Tipo_Nombre` (sin tildes ni espacios).

---

## 1. Dulces (Propiedades Económicas y Físicas)
| Identificador | Nivel | ValorVenta (pesos) | TiempoProduccion (s) | PesoUnitario (Kg) | SeAbreEn |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `Dulce_Bombon` | Común | 1 | 5 | **0.05 kg** (50g) | Capítulo 1 |
| `Dulce_Chicle` | Común | 1 | 8 | **0.03 kg** (30g) | Capítulo 1 |
| `Dulce_Gomita` | Común | 2 | 12 | **0.08 kg** (80g) | Capítulo 1 |
| `Dulce_Arequipe` | Casero | 5 | 25 | **0.50 kg** (500g) | Capítulo 3 |
| `Dulce_Panelita` | Casero | 6 | 30 | **0.35 kg** (350g) | Capítulo 3 |
| `Dulce_Bocadillo` | Casero | 8 | 40 | **0.40 kg** (400g) | Capítulo 3 |

---

## 2. Armas (Balística y Costo)
| Identificador | Tipo | Efecto | Duracion (s) | Alcance (Studs) | Vel. Proyectil (Studs/s) | Munición | Gasto | SeAbreEn |
| :--- | :--- | :--- | :---: | :---: | :---: | :--- | :---: | :---: |
| `Arma_CaucheraGomitas` | Inicial / Distancia | Aturdir policía | 1.0 | 45 | 80 | `Dulce_Gomita` | 1 | Cap. 1 |
| `Arma_PistolaCrema` | Distancia | Cegar parabrisas | 4.0 | 60 | 110 | `Dulce_Bombon` | 2 | Cap. 4 |
| `Arma_EscopetaChicle` | Corto alcance | Pegar al piso | 3.0 | 30 | 70 | `Dulce_Chicle` | 3 | Cap. 5 |
| `Arma_MinaCaramelo` | Trampa suelo | Frenar vehículo | 2.5 | 5 | 0 | `Dulce_Panelita` | 2 | Cap. 5 |
| `Arma_GranadaGaseosa` | Explosivo área | Empuje espuma | 2.0 | 18 | 50 | `Dulce_Arequipe` | 2 | Cap. 6 |
| `Arma_BazucaAlgodon` | Explosivo largo | Cortina rosada | 5.0 | 90 | 65 | `Dulce_Bocadillo` | 3 | Cap. 7 |
| `Arma_DinamitaPinata` | Explosivo pesado | Destruir retenes | Estructural | 20 | 40 | `Dulce_Bocadillo` | 5 | Cap. 8 |
| `Arma_CanonChiva` | Vehicular pesado | Avería patrulla | 3.5 | 120 | 130 | `Dulce_Bombon` | 10 | Cap. 9 |

---

## 3. Vehículos (Límites Físicos y Capacidad)
| Identificador | Precio ($) | Capacidad (U) | CargaMaxKg | MasaBaseKg | VelMax (Studs/s) | Escondites | SeAbreEn |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `Vehiculo_Bicicleta` | 0 | 20 unidades | **10.0 kg** | 15 kg | 16 | 0 | Capítulo 1 |
| `Vehiculo_Moto` | 150 | 60 unidades | **40.0 kg** | 120 kg | 28 | 1 | Capítulo 3 |

---

## 4. Mejoras
| Identificador | Tipo | Nivel | Precio (pesos) | Efecto | ValorEfecto |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `Mejora_Cocina_Velocidad_1` | Cocina | 1 | 50 | Reducción tiempo producción | -15% |
| `Mejora_Cocina_Velocidad_2` | Cocina | 2 | 180 | Reducción tiempo producción | -30% |
| `Mejora_Cocina_RecetaExtra_1` | Cocina | 1 | 250 | Segunda receta simultánea | +1 ranura |
| `Mejora_Bodega_Capacidad_1` | Bodega | 1 | 75 | Límite almacenamiento offline | 200 dulces |
| `Mejora_Bodega_Capacidad_2` | Bodega | 2 | 220 | Límite almacenamiento offline | 500 dulces |

---

## 5. Tiendas (Demanda inicial)
| Identificador | NombreBarrio | DulcesQueCompra | MultiplicadorPrecio | DemandaBaseMax |
| :--- | :--- | :--- | :--- | :--- |
| `Tienda_ColegioRecreo` | El Recreo | `Dulce_Bombon`, `Dulce_Chicle` | 1.0x (2.0x en evento Recreo) | 50 |
| `Tienda_EsquinaPaisa` | La Cuadra | `Dulce_Bombon`, `Dulce_Gomita` | 1.0x | 40 |
| `Tienda_DonAbaco` | La Cuadra | `Dulce_Chicle`, `Dulce_Gomita` | 1.1x | 60 |
| `Tienda_LaLadera` | El Alto | `Dulce_Bombon`, `Dulce_Arequipe` | 1.2x | 35 |
| `Tienda_ParqueCentral` | Centro | `Dulce_Arequipe`, `Dulce_Panelita` | 1.25x | 50 |
| `Tienda_TerminalRuta` | La Variante | `Dulce_Panelita`, `Dulce_Bocadillo` | 1.3x | 45 |

---

## 6. Encargos Diarios
| Identificador | Texto | MetaCantidad | DulceRequerido | PremioPesos | PremioPase |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `Encargo_EntregaBombones` | Entrega 20 bombones en el colegio | 20 | `Dulce_Bombon` | 30 | 50 pts |
| `Encargo_VentaGomitas` | Vende 15 gomitas en tiendas del barrio | 15 | `Dulce_Gomita` | 45 | 50 pts |
| `Encargo_EscapadaDental` | Escapa de una patrulla dental con 1 estrella | 1 | - | 50 | 75 pts |
