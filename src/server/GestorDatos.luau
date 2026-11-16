local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileService = require(ReplicatedStorage.Packages.ProfileService)
local PlantillaPerfil = require(ReplicatedStorage.Shared.Datos.PlantillaPerfil)
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)

type PerfilJugador = PlantillaPerfil.PerfilJugador

local NOMBRE_ALMACEN = "DatosJugadores_v1"
local AlmacenPerfiles = ProfileService.GetProfileStore(NOMBRE_ALMACEN, PlantillaPerfil)

local GestorDatos = {}
local perfilesCargados: { [Player]: any } = {}

local function actualizarLeaderstats(player: Player, datos: PerfilJugador)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		local nuevoLeaderstats = Instance.new("Folder")
		nuevoLeaderstats.Name = "leaderstats"
		nuevoLeaderstats.Parent = player
		leaderstats = nuevoLeaderstats

		local pesos = Instance.new("IntValue")
		pesos.Name = "Pesos"
		pesos.Value = datos.PesosDulces
		pesos.Parent = leaderstats

		local fama = Instance.new("IntValue")
		fama.Name = "Fama"
		fama.Value = datos.Fama
		fama.Parent = leaderstats
	else
		local pesos = leaderstats:FindFirstChild("Pesos") :: IntValue?
		if pesos then
			pesos.Value = datos.PesosDulces
		end
		local fama = leaderstats:FindFirstChild("Fama") :: IntValue?
		if fama then
			fama.Value = datos.Fama
		end
	end
end

local function sincronizarCliente(player: Player)
	local perfil = perfilesCargados[player]
	if perfil then
		actualizarLeaderstats(player, perfil.Data)
		EventosRemotos.DatosActualizados:FireClient(player, perfil.Data)
	end
end

local function alEntrarJugador(player: Player)
	local clavePerfil = "Jugador_" .. player.UserId
	local perfil = AlmacenPerfiles:LoadProfileAsync(clavePerfil)

	if perfil ~= nil then
		perfil:AddUserId(player.UserId)
		perfil:Reconcile()
		perfil:ListenToRelease(function()
			perfilesCargados[player] = nil
			player:Kick("Tu sesión fue abierta en otro servidor. Por favor vuelve a entrar.")
		end)

		if player:IsDescendantOf(Players) == true then
			perfilesCargados[player] = perfil
			sincronizarCliente(player)
		else
			perfil:Release()
		end
	else
		player:Kick("No se pudieron cargar tus datos. Vuelve a intentarlo en unos momentos.")
	end
end

local function alSalirJugador(player: Player)
	local perfil = perfilesCargados[player]
	if perfil ~= nil then
		perfil:Release()
	end
end

function GestorDatos.ObtenerDatos(player: Player): PerfilJugador?
	local perfil = perfilesCargados[player]
	if perfil then
		return perfil.Data
	end
	return nil
end

function GestorDatos.AgregarPesos(player: Player, cantidad: number): boolean
	local perfil = perfilesCargados[player]
	if not perfil or cantidad <= 0 then
		return false
	end
	perfil.Data.PesosDulces += cantidad
	sincronizarCliente(player)
	return true
end

function GestorDatos.QuitarPesos(player: Player, cantidad: number): boolean
	local perfil = perfilesCargados[player]
	if not perfil or cantidad <= 0 then
		return false
	end
	if perfil.Data.PesosDulces < cantidad then
		return false
	end
	perfil.Data.PesosDulces -= cantidad
	sincronizarCliente(player)
	return true
end

function GestorDatos.AgregarDulce(player: Player, idDulce: string, cantidad: number): boolean
	local perfil = perfilesCargados[player]
	if not perfil or cantidad <= 0 then
		return false
	end
	local actual = perfil.Data.Inventario[idDulce] or 0
	perfil.Data.Inventario[idDulce] = actual + cantidad
	sincronizarCliente(player)
	return true
end

function GestorDatos.QuitarDulce(player: Player, idDulce: string, cantidad: number): boolean
	local perfil = perfilesCargados[player]
	if not perfil or cantidad <= 0 then
		return false
	end
	local actual = perfil.Data.Inventario[idDulce] or 0
	if actual < cantidad then
		return false
	end
	local nuevo = actual - cantidad
	if nuevo <= 0 then
		perfil.Data.Inventario[idDulce] = nil
	else
		perfil.Data.Inventario[idDulce] = nuevo
	end
	sincronizarCliente(player)
	return true
end

function GestorDatos.Iniciar()
	EventosRemotos.SolicitarDatos.OnServerInvoke = function(player: Player)
		local perfil = perfilesCargados[player]
		if perfil then
			return perfil.Data
		end
		return nil
	end

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(alEntrarJugador, player)
	end

	Players.PlayerAdded:Connect(alEntrarJugador)
	Players.PlayerRemoving:Connect(alSalirJugador)
end

return GestorDatos
