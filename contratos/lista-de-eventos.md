# Lista de eventos (dueño: Pablo)
| Nombre | Dirección | Parámetros | Qué hace |
| --- | --- | --- | --- |
| `DatosActualizados` | Servidor -> Cliente | `datos: PerfilJugador` | Envía al cliente su información de perfil completa al cambiar o iniciar |
| `SolicitarDatos` | Cliente -> Servidor | ninguno | Retorna los datos actuales del perfil del jugador |
| `SolicitarCocinar` | Cliente -> Servidor | `idDulce: string` | Solicita iniciar la cocción de una receta desbloqueada |
| `CocinaActualizada` | Servidor -> Cliente | `info: { IdDulce: string, Duracion: number, Listo: boolean?, Recogido: boolean?, Cantidad: number? }` | Notifica al cliente sobre el estado de la cocción |
| `VentaCompletada` | Servidor -> Cliente | `resumen: { Tienda: string, PesosGanados: number, DulcesVendidos: number }` | Notifica al cliente cuando se completa una venta exitosa en una tienda |
| `SolicitarCompraMejora` | Cliente -> Servidor | `idMejora: string` | Solicita comprar una mejora de cocina o bodega a Don Ábaco |
| `SolicitarCompraVehiculo` | Cliente -> Servidor | `idVehiculo: string` | Solicita comprar un nuevo vehículo (ej. Moto) |
| `SolicitarEquiparVehiculo` | Cliente -> Servidor | `idVehiculo: string` | Solicita equipar un vehículo adquirido |
| `AbrirTiendaMejoras` | Servidor -> Cliente | ninguno | Notifica al cliente que abra la UI de mejoras (ej. al hablar con Don Ábaco) |
| `EstrellasActualizadas` | Servidor -> Cliente | `info: { Estrellas: number, Enfriando: boolean, ProgresoEnfriamiento: number? }` | Notifica al cliente su nivel de estrellas de búsqueda y estado de enfriamiento en escondites |
| `AlertaPolicia` | Servidor -> Cliente | `mensaje: string, nivel: number` | Envía advertencias y anuncios de la Policía Dental al jugador |
| `CargaConfiscada` | Servidor -> Cliente | `cantidadConfiscada: number` | Notifica al jugador cuando la Policía Dental le decomisa los dulces transportados |
| `DispararArma` | Cliente -> Servidor | `idArma: string, direccion: Vector3` | Solicita disparar una dulce-arma consumiendo munición de golosinas |
| `SolicitarVehiculo` | Cliente -> Servidor | ninguno | Invoca el vehículo equipado cerca al jugador (atajo tecla V o Maestro Tuerca) |
| `EnviadoAlInternado` | Servidor -> Cliente | `info: { CondenaSegundos: number, FianzaPesos: number, Estrellas: number }` | Notifica al cliente cuando es detenido y enviado al Internado Sin Azúcar |
| `LiberadoDelInternado` | Servidor -> Cliente | ninguno | Notifica al cliente que cumplió su condena o pagó su fianza y queda en libertad |
| `SolicitarPagarFianza` | Cliente -> Servidor | ninguno | Solicita pagar la fianza en pesos dulces para salir de inmediato del internado |
| `CepillarMuela` | Cliente -> Servidor | ninguno | Trabajo comunitario: cepilla una muela gigante reduciendo 20s de condena |
| `MostrarDialogoNPC` | Servidor -> Cliente | `{ Nombre: string, Titulo: string, Icono: string, Mensaje: string }` | Notificación o globo de diálogo emergente de NPC |

