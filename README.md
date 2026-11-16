# El Patrón del Dulce

Juego tycoon de acción para Roblox ambientado en una ciudad clandestina de dulces.

## Requisitos previos
- [Git](https://git-scm.com/)
- [Rokit](https://github.com/rojo-rbx/rokit)
- [Roblox Studio](https://create.roblox.com/)

## Inicio rápido
1. Instalar la cadena de herramientas fijadas:
   ```bash
   rokit install
   ```
2. Iniciar el servidor de sincronización de Rojo:
   ```bash
   rojo serve
   ```
3. Conectar el plugin de Rojo en Roblox Studio.

## Comprobación y calidad de código
- **Linter (Selene):**
  ```bash
  selene src
  ```
- **Formateador (StyLua):**
  ```bash
  stylua --check src
  ```
- **Construcción de prueba:**
  ```bash
  rojo build -o ElPatronDelDulce.rbxl
  ```
