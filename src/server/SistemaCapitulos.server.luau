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
		MensajeCompletado = "¡Completaste el Capítulo 2! Ahora las tiendas del barrio son tus aliadas y te generan ingresos pasivos automáticos cada 30s.",
		Desbloquea = "Ingresos Pasivos y Recetas Caseras",
	},
	[3] = {
		Numero = 3,
		Nombre = "La Cocina de la Abuela",
		Descripcion = "Domina las recetas caseras (Gomitas y Panelitas) y compra la Moto de Reparto ($150).",
		MetaPesos = 250,
		TiendasRequeridas = 3,
		PremioLogro = "Receta Secreta",
		PremioFama = 10,
		MensajeCompletado = "¡Completaste el Capítulo 3! Ya dominas las recetas de la abuela y tienes la potencia de la Moto para entregas masivas.",
		Desbloquea = "Moto de Reparto y Ruta de Montaña",
	},
	[4] = {
		Numero = 4,
		Nombre = "La Ruta Peligrosa",
		Descripcion = "Abastece las tiendas de la montaña burlando los 6 retenes policiales y sobrevive a una Redada Dental.",
		MetaPesos = 400,
		TiendasRequeridas = 5,
		PremioLogro = "Ni Una Caries",
		PremioFama = 15,
		MensajeCompletado = "¡Completaste el Capítulo 4! Has burlado los puestos de control de la Policía Dental y desbloqueaste la Pistola de Crema.",
		Desbloquea = "Pistola de Crema y Rutas Altas",
	},
	[5] = {
		Numero = 5,
		Nombre = "El Patrón del Barrio",
		Descripcion = "Conquista las 6 tiendas de Villa Almíbar y acumula $500 pesos dulces.",
		MetaPesos = 500,
		TiendasRequeridas = 6,
		PremioLogro = "Los Golosos",
		PremioFama = 25,
		MensajeCompletado = "¡ERES EL PATRÓN DEL DULCE! Todas las tiendas del municipio dependen de tu dulce clandestino. ¡Alcanzaste la gloria máxima!",
		Desbloquea = "Estatus de Leyenda y Corona Dorada",
	},
}

local function sincronizarObjetivoCliente(player: Player)
	local datos = GestorDatos.ObtenerDatos(player)
	if not datos then
		return
	end
	local capNum = datos.CapituloActual or 1
	local capInfo = CAPITULOS[capNum] or CAPITULOS[5]

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
	if not capInfo or capNum >= 5 then
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

		-- Desbloquear recompensas asociadas
		if siguienteCap == 3 then
			GestorDatos.DesbloquearReceta(player, "Dulce_Gomita")
			GestorDatos.DesbloquearReceta(player, "Dulce_Panelita")
		elseif siguienteCap == 4 then
			GestorDatos.DesbloquearReceta(player, "Dulce_Arequipe")
			datos.ArmasDesbloqueadas["Arma_PistolaCrema"] = true
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
