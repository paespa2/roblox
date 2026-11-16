# Lista de eventos (dueño: Pablo)
| Nombre | Dirección | Parámetros | Qué hace |
| --- | --- | --- | --- |
| `DatosActualizados` | Servidor -> Cliente | `datos: PerfilJugador` | Envía al cliente su información de perfil completa al cambiar o iniciar |
| `SolicitarDatos` | Cliente -> Servidor | ninguno | Retorna los datos actuales del perfil del jugador |
| `SolicitarCocinar` | Cliente -> Servidor | `idDulce: string` | Solicita iniciar la cocción de una receta desbloqueada |
| `CocinaActualizada` | Servidor -> Cliente | `info: { IdDulce: string, Duracion: number, Listo: boolean?, Recogido: boolean?, Cantidad: number? }` | Notifica al cliente sobre el estado de la cocción |
| `VentaCompletada` | Servidor -> Cliente | `resumen: { Tienda: string, PesosGanados: number, DulcesVendidos: number }` | Notifica al cliente cuando se completa una venta exitosa en una tienda |
