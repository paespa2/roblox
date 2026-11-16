local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GestorDatos = require(script.Parent.GestorDatos)
local Datos = require(ReplicatedStorage.Shared.Datos)
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)

local CANTIDAD_POR_TANDA = 5

type EstadoCoccion = {
	IdDulce: string,
	Inicio: number,
	Duracion: number,
	Listo: boolean,
}

local coccionesActivas: { [Player]: EstadoCoccion } = {}

local function obtenerPaila(): BasePart?
	local mapa = Workspace:WaitForChild("Mapa", 10)
	if not mapa then
		return nil
	end
	local cocina = mapa:WaitForChild("CocinaInicial", 10)
	if not cocina then
		return nil
	end
	return (
		cocina:FindFirstChild("Paila_Melcocha") or cocina:FindFirstChild("Fogon_Ladrillo")
	) :: BasePart?
end

local function configurarPromptCocina(paila: BasePart)
	local prompt = paila:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "PromptCocina"
		prompt.ObjectText = "Cocina Clandestina"
		prompt.ActionText = "Cocinar / Recoger"
		prompt.HoldDuration = 0.5
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Parent = paila
	end

	prompt.Triggered:Connect(function(player: Player)
		local estado = coccionesActivas[player]

		if not estado then
			local idDulceDefault = "Dulce_Bombon"
			local infoDulce = Datos.Dulces[idDulceDefault]
			if not infoDulce then
				return
			end

			coccionesActivas[player] = {
				IdDulce = idDulceDefault,
				Inicio = os.time(),
				Duracion = infoDulce.TiempoProduccion,
				Listo = false,
			}

			EventosRemotos.CocinaActualizada:FireClient(player, {
				IdDulce = idDulceDefault,
				Duracion = infoDulce.TiempoProduccion,
				Listo = false,
			})

			task.delay(infoDulce.TiempoProduccion, function()
				if
					coccionesActivas[player]
					and coccionesActivas[player].IdDulce == idDulceDefault
				then
					coccionesActivas[player].Listo = true
					EventosRemotos.CocinaActualizada:FireClient(player, {
						IdDulce = idDulceDefault,
						Duracion = 0,
						Listo = true,
					})
				end
			end)
		elseif estado.Listo == true then
			local idDulce = estado.IdDulce
			local infoDulce = Datos.Dulces[idDulce]
			local nombreDulce = if infoDulce then infoDulce.Nombre else idDulce

			GestorDatos.AgregarDulce(player, idDulce, CANTIDAD_POR_TANDA)
			coccionesActivas[player] = nil

			EventosRemotos.CocinaActualizada:FireClient(player, {
				IdDulce = idDulce,
				Duracion = 0,
				Recogido = true,
				Cantidad = CANTIDAD_POR_TANDA,
			})

			print(
				string.format(
					"El Patrón del Dulce: %s recogió %d unidades de %s",
					player.Name,
					CANTIDAD_POR_TANDA,
					nombreDulce
				)
			)
		else
			local restante = math.max(0, estado.Duracion - (os.time() - estado.Inicio))
			print(
				string.format(
					"El Patrón del Dulce: %s, tu tanda está lista en %d segundos",
					player.Name,
					restante
				)
			)
		end
	end)
end

EventosRemotos.SolicitarCocinar.OnServerInvoke = function(player: Player, idDulce: string)
	local datosJugador = GestorDatos.ObtenerDatos(player)
	if not datosJugador then
		return false, "Datos no disponibles"
	end

	if not datosJugador.RecetasDesbloqueadas[idDulce] then
		return false, "Receta bloqueada"
	end

	local infoDulce = Datos.Dulces[idDulce]
	if not infoDulce then
		return false, "Dulce no válido"
	end

	if coccionesActivas[player] and not coccionesActivas[player].Listo then
		return false, "Ya hay una tanda en cocción"
	end

	coccionesActivas[player] = {
		IdDulce = idDulce,
		Inicio = os.time(),
		Duracion = infoDulce.TiempoProduccion,
		Listo = false,
	}

	task.delay(infoDulce.TiempoProduccion, function()
		if coccionesActivas[player] and coccionesActivas[player].IdDulce == idDulce then
			coccionesActivas[player].Listo = true
			EventosRemotos.CocinaActualizada:FireClient(player, {
				IdDulce = idDulce,
				Duracion = 0,
				Listo = true,
			})
		end
	end)

	return true, "Cocción iniciada"
end

Players.PlayerRemoving:Connect(function(player: Player)
	coccionesActivas[player] = nil
end)

local paila = obtenerPaila()
if paila then
	configurarPromptCocina(paila)
	print("El Patrón del Dulce: Sistema de Cocina conectado a la paila")
else
	task.spawn(function()
		local reintentos = 0
		while reintentos < 20 do
			task.wait(1)
			reintentos += 1
			local pailaTardia = obtenerPaila()
			if pailaTardia then
				configurarPromptCocina(pailaTardia)
				print("El Patrón del Dulce: Sistema de Cocina conectado (tardío)")
				break
			end
		end
	end)
end
