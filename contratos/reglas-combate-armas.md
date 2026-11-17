# Contrato de Combate y Armas Dulces (dueño: Santiago)

> **Mecánica de Combate:** Parodia de acción donde las armas disparan dulces y generan efectos cómicos.  
> **Dueño:** Santiago (Economía) decide daño, alcance, dispersión, tiempos de recarga y costo en mercancía.  
> **Entorno:** Andrés modela las armas en Blender y genera partículas de confeti, crema y espuma.  
> **Sistemas:** Pablo programa el sistema de proyectiles, colisiones y detección de objetivos.

---

## 1. Principio Fundamental de Economía de Combate
- **La munición son tus propios dulces producidos:** Cada disparo consume mercancía de tu inventario.
- **Dilema del jugador:** Disparar te salva de la patrulla pero reduce tu ganancia al llegar a la tienda.
- **Nadie muere:** Quien recibe el impacto queda **"empalagado"** (inmovilizado o cegado temporalmente). Cero sangre, cero violencia explícita.

---

## 2. Catálogo Completo de Armas (Fases 1 a 4 y Campaña)

| Identificador | Tipo | Efecto Mecánico | Duración Efecto | Alcance (Studs) | Munición (Dulce) | Gasto por Disparo | Cadencia (s) | Se Abre En |
| :--- | :--- | :--- | :---: | :---: | :--- | :---: | :---: | :---: |
| `Arma_CaucheraGomitas` | Inicial / Distancia | Aturde al policía o rival | 1.0s | 45 | `Dulce_Gomita` | 1 | 0.8s | Cap. 1 |
| `Arma_PistolaCrema` | Distancia | Tapa parabrisas / ciega patrulla | 4.0s | 60 | `Dulce_Bombon` | 2 | 1.2s | Cap. 4 |
| `Arma_EscopetaChicle` | Corto alcance | Pega al rival al suelo con chicle | 3.0s | 30 | `Dulce_Chicle` | 3 | 1.8s | Cap. 5 |
| `Arma_MinaCaramelo` | Trampa en suelo | Frena en seco al vehículo que la pisa | 2.5s | 5 (radio) | `Dulce_Panelita` | 2 | 3.0s | Cap. 5 |
| `Arma_GranadaGaseosa` | Explosivo | Nube efervescente que empuja a todos | 2.0s | 18 (área) | `Dulce_Arequipe` | 2 | 4.0s | Cap. 6 |
| `Arma_BazucaAlgodon` | Explosivo largo | Cortina rosada que bloquea visión | 5.0s | 90 | `Dulce_Bocadillo` | 3 | 5.0s | Cap. 7 |
| `Arma_DinamitaPinata` | Explosivo pesado | Revienta barricadas de retenes y puertas | Daño estructural | 20 (área) | `Dulce_Bocadillo` | 5 | 8.0s | Cap. 8 |
| `Arma_CanonChiva` | Montado en vehículo | Proyectiles masivos en persecución | Avería temporal | 120 | `Dulce_Bombon` | 10 | 2.5s | Cap. 9 |

---

## 3. Comportamiento contra Patrullas y Retenes (Fase 2)
1. **Pistola de Crema contra Patrullas:**
   - Si impacta el parabrisas de la patrulla dental, esta pierde el control por 4 segundos y reduce su velocidad a 5 studs/s.
   - Da tiempo suficiente para doblar la esquina y entrar a un `Escondite`.
2. **Cauchera de Gomitas contra Policías a pie:**
   - Aturde al oficial por 1 segundo, interrumpiendo su intento de confiscar la carga con el cepillo gigante.
