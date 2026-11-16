# Tabla de datos (dueño: Santiago)

> **Contrato de Economía** — Única fuente de verdad para números, balance y progresión.
> Formato de identificadores: `Tipo_Nombre` (sin tildes ni espacios).

---

## 1. Dulces
| Identificador | Nivel | ValorVenta (pesos) | TiempoProduccion (s) | SeAbreEn |
| :--- | :--- | :--- | :--- | :--- |
| `Dulce_Bombon` | Común | 1 | 5 | Capítulo 1 |
| `Dulce_Chicle` | Común | 1 | 8 | Capítulo 1 |
| `Dulce_Gomita` | Común | 2 | 12 | Capítulo 1 |
| `Dulce_Arequipe` | Casero | 5 | 25 | Capítulo 3 |
| `Dulce_Panelita` | Casero | 6 | 30 | Capítulo 3 |
| `Dulce_Bocadillo` | Casero | 8 | 40 | Capítulo 3 |

---

## 2. Armas
| Identificador | Tipo | Efecto | Duracion (s) | CostoDulcesPorDisparo | SeAbreEn |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `Arma_CaucheraGomitas` | Inicial / Distancia | Aturde al objetivo | 1 | 1 (`Dulce_Gomita`) | Capítulo 1 |
| `Arma_PistolaCrema` | Distancia | Tapa parabrisas patrulla | 4 | 2 (`Dulce_Bombon`) | Capítulo 4 |

---

## 3. Vehículos
| Identificador | Precio (pesos) | CapacidadCarga | VelocidadMax | Escondites | SeAbreEn |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `Vehiculo_Bicicleta` | 0 | 20 | 16 | 0 | Capítulo 1 |
| `Vehiculo_Moto` | 150 | 60 | 28 | 1 | Capítulo 3 |

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
