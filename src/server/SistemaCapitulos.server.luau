local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GestorDatos = require(script.Parent.GestorDatos)
local _Datos = require(ReplicatedStorage.Shared.Datos)
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)

type InfoCapitulo = {
	Numero: number,
	Nombre: string,
	Descripcion: string,
	MetaPesos: number,
	TiendasRequeridas: number?,
	PremioLogro: string,
	PremioFama: number,
	MensajeCompletado: string,
	Desbloquea: string,
}

local CAPITULOS: { [number]: InfoCapitulo } = {
	[1] = {
		Numero = 1,
		Nombre = "El Recreo",
		Descripcion = "Vende bombones en el patio escolar y reúne $50 pesos dulces.",
		MetaPesos = 50,
		TiendasRequeridas = 0,
		PremioLogro = "Primer Bombón",
		PremioFama = 2,
		MensajeCompletado = "¡Completaste el Capítulo 1! El portón del colegio está abierto y tienes tu bicicleta lista para recorrer el barrio.",
		Desbloquea = "Bicicleta y Salida al Barrio",
	},
	[2] = {
		Numero = 2,
		Nombre = "La Esquina",
		Descripcion = "Abastece las 3 primeras tiendas del barrio y reúne $150 pesos dulces.",
		MetaPesos = 150,
		TiendasRequeridas = 3,
		PremioLogro = "Dueño de la Cuadra",
		PremioFama = 5,
		MensajeCompletado = "¡Completaste el Capítulo 2! Ahora las tiendas del barrio son tus aliadas y te generan ingresos pasivos automáticos.",
		Desbloquea = "Ingresos Pasivos y Recetas Caseras",
	},
	[3] = {
		Numero = 3,
		Nombre = "La Cocina de la Abuela",
		Descripcion = "Domina las recetas caseras (Gomitas y Panelitas) y acumula $280 pesos dulces.",
		MetaPesos = 280,
		TiendasRequeridas = 3,
		PremioLogro = "Receta Secreta",
		PremioFama = 10,
		MensajeCompletado = "¡Completaste el Capítulo 3! Ya dominas las recetas de la abuela y tienes la potencia de la Moto Mensajera para entregas rápidas.",
		Desbloquea = "Moto de Reparto y Rutas de Montaña",
	},
	[4] = {
		Numero = 4,
		Nombre = "La Ruta Peligrosa",
		Descripcion = "Abastece las tiendas de la montaña burlando los retenes policiales y acumula $450 pesos.",
		MetaPesos = 450,
		TiendasRequeridas = 5,
		PremioLogro = "Ni Una Caries",
		PremioFama = 15,
		MensajeCompletado = "¡Completaste el Capítulo 4! Has burlado los puestos de control de la Policía Dental y desbloqueaste la Pistola de Crema.",
		Desbloquea = "Pistola de Crema y Escondites en Vehículos",
	},
	[5] = {
		Numero = 5,
		Nombre = "La Banda de los Golosos",
		Descripcion = "Recluta repartidores de barrio, conquista 5 tiendas y reúne $700 pesos dulces.",
		MetaPesos = 700,
		TiendasRequeridas = 5,
		PremioLogro = "Los Golosos",
		PremioFama = 20,
		MensajeCompletado = "¡Completaste el Capítulo 5! Creaste tu banda de repartidores automáticos y desbloqueaste la Bodega Clandestina.",
		Desbloquea = "Bodega de Repartidores Tycoon",
	},
	[6] = {
		Numero = 6,
		Nombre = "La Guerra del Azúcar",
		Descripcion = "Defiende tus rutas de entrega contra la Banda del Chicle y reúne $1.000 pesos dulces.",
		MetaPesos = 1000,
		TiendasRequeridas = 6,
		PremioLogro = "Aquí Mando Yo",
		PremioFama = 30,
		MensajeCompletado = "¡Completaste el Capítulo 6! La Banda del Chicle huyó de tu territorio. Desbloqueaste el Cañón de Confeti.",
		Desbloquea = "Cañón de Confeti y Control de Territorios",
	},
	[7] = {
		Numero = 7,
		Nombre = "Finca La Melcocha",
		Descripcion = "Adquiere tu primera finca cañaduzal en la cordillera y acumula $1.600 pesos.",
		MetaPesos = 1600,
		TiendasRequeridas = 6,
		PremioLogro = "Finca La Melcocha",
		PremioFama = 40,
		MensajeCompletado = "¡Completaste el Capítulo 7! Levantaste la mansión dulce en la montaña y desbloqueaste el Campero Willys Blindado.",
		Desbloquea = "Campero Willys Blindado y Cosecha Diaria",
	},
	[8] = {
		Numero = 8,
		Nombre = "El Puente Aéreo",
		Descripcion = "Exporta cargamentos de dulces a otras regiones y reúne $2.600 pesos.",
		MetaPesos = 2600,
		TiendasRequeridas = 6,
		PremioLogro = "Sin Fronteras",
		PremioFama = 50,
		MensajeCompletado = "¡Completaste el Capítulo 8! La Avioneta Dulcera cruza los cielos y dominas los Dulces Legendarios.",
		Desbloquea = "Avioneta Dulcera y Dulces Legendarios",
	},
	[9] = {
		Numero = 9,
		Nombre = "El Más Buscado",
		Descripcion = "Sobrevive a la cacería de 5 estrellas del Comandante Muelas y reúne $4.000 pesos.",
		MetaPesos = 4000,
		TiendasRequeridas = 6,
		PremioLogro = "Cinco Estrellas",
		PremioFama = 75,
		MensajeCompletado = "¡Completaste el Capítulo 9! Derrotaste al Comandante Muelas en la gran persecución. Estás listo para el Renacimiento.",
		Desbloquea = "Renacimiento y Prestigio del Patrón",
	},
	[10] = {
		Numero = 10,
		Nombre = "La Leyenda del Patrón",
		Descripcion = "Completa tu primer Renacimiento: pasa el imperio a tu heredero con ganancias multiplicadas x2.",
		MetaPesos = 6000,
		TiendasRequeridas = 6,
		PremioLogro = "El Patrón del Dulce",
		PremioFama = 150,
		MensajeCompletado = "¡ERES LA LEYENDA DEL DULCE! Completaste la campaña máxima. El imperio reina para siempre en Villa Almíbar.",
		Desbloquea = "Modo Infinito y Multiplicador Permanente x2",
	},
}

local function sincronizarObjetivoCliente(player: Player)
	local datos = GestorDatos.ObtenerDatos(player)
	if not datos then
		return
	end
	local capNum = datos.CapituloActual or 1
	local capInfo = CAPITULOS[capNum] or CAPITULOS[10]

	local tiendasConquistadas = GestorDatos.ObtenerTiendasConquistadas(player)
	local conteoTiendas = 0
	for _ in pairs(tiendasConquistadas) do
		conteoTiendas += 1
	end

	local progresoStr = string.format("Pesos: $%d / $%d", datos.PesosDulces or 0, capInfo.MetaPesos)
	if (capInfo.TiendasRequeridas or 0) > 0 then
		progresoStr = progresoStr
			.. string.format(" | Tiendas: %d/%d", conteoTiendas, capInfo.TiendasRequeridas)
	end

	EventosRemotos.ObjetivoMisionActualizado:FireClient(player, {
		Capitulo = capInfo.Numero,
		Titulo = string.format(
			"📋 MISIÓN: CAPÍTULO %d — %s",
			capInfo.Numero,
			capInfo.Nombre:upper()
		),
		Descripcion = capInfo.Descripcion,
		Progreso = progresoStr,
		Porcentaje = math.clamp((datos.PesosDulces or 0) / capInfo.MetaPesos, 0, 1),
	})
end

local function verificarProgresionCapitulos(player: Player)
	local datos = GestorDatos.ObtenerDatos(player)
	if not datos then
		return
	end
	local capNum = datos.CapituloActual or 1
	local capInfo = CAPITULOS[capNum]
	if not capInfo or capNum >= 10 then
		sincronizarObjetivoCliente(player)
		return
	end

	local pesos = datos.PesosDulces or 0
	local tiendas = GestorDatos.ObtenerTiendasConquistadas(player)
	local conteoTiendas = 0
	for _ in pairs(tiendas) do
		conteoTiendas += 1
	end

	local cumplePesos = pesos >= capInfo.MetaPesos
	local cumpleTiendas = conteoTiendas >= (capInfo.TiendasRequeridas or 0)

	if cumplePesos and cumpleTiendas then
		-- Avanzar capítulo
		local siguienteCap = capNum + 1
		GestorDatos.AvanzarCapitulo(player, siguienteCap)
		datos.Fama += capInfo.PremioFama

		-- Desbloquear recompensas según el nuevo capítulo alcanzado
		if siguienteCap == 3 then
			GestorDatos.DesbloquearReceta(player, "Dulce_Gomita")
			GestorDatos.DesbloquearReceta(player, "Dulce_Panelita")
		elseif siguienteCap == 4 then
			GestorDatos.DesbloquearReceta(player, "Dulce_Arequipe")
			GestorDatos.DesbloquearReceta(player, "Dulce_Bocadillo")
			datos.ArmasDesbloqueadas["Arma_PistolaCrema"] = true
		elseif siguienteCap == 5 then
			GestorDatos.DesbloquearReceta(player, "Dulce_ManjarBlanco")
			datos.ArmasDesbloqueadas["Arma_BombaConfeti"] = true
		elseif siguienteCap == 6 then
			GestorDatos.DesbloquearReceta(player, "Dulce_MelcochaCanela")
			datos.ArmasDesbloqueadas["Arma_CanonConfeti"] = true
		elseif siguienteCap == 7 then
			GestorDatos.DesbloquearReceta(player, "Dulce_ChocotejaAndina")
			datos.VehiculosDesbloqueados["Vehiculo_CamperoWillys"] = true
		elseif siguienteCap == 8 then
			GestorDatos.DesbloquearReceta(player, "Dulce_ManjarDorado")
			datos.VehiculosDesbloqueados["Vehiculo_AvionetaDulcera"] = true
		elseif siguienteCap == 9 then
			GestorDatos.DesbloquearReceta(player, "Dulce_CoronaDelPatron")
		elseif siguienteCap == 10 then
			datos.MultiplicadorRenacimiento = (datos.MultiplicadorRenacimiento or 1) * 2
		end

		-- Premiar con Logro oficial
		EventosRemotos.LogroDesbloqueado:FireClient(player, {
			Nombre = capInfo.PremioLogro,
			Fama = capInfo.PremioFama,
		})

		-- Diálogo estático felicitatorio con [X]
		EventosRemotos.MostrarDialogoNPC:FireClient(player, {
			Nombre = "Doña Melcocha",
			Titulo = string.format("¡Capítulo %d Completado!", capNum),
			Icono = "👵",
			Mensaje = capInfo.MensajeCompletado,
		})

		print(
			string.format(
				"El Patrón del Dulce: ¡%s completó el Capítulo %d y avanzó al Capítulo %d!",
				player.Name,
				capNum,
				siguienteCap
			)
		)
	end

	sincronizarObjetivoCliente(player)
end

-- Escuchar cambios en pesos y eventos del jugador
GestorDatos.PesosModificados.Event:Connect(function(player: Player)
	verificarProgresionCapitulos(player)
end)

Players.PlayerAdded:Connect(function(player: Player)
	task.wait(2.0)
	sincronizarObjetivoCliente(player)
end)

for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		task.wait(1.5)
		sincronizarObjetivoCliente(p)
	end)
end

print("El Patrón del Dulce: Sistema de Capítulos 1 a 5 y Objetivos Tycoon Inicializado")
