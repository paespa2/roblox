local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ProfileService = require(ReplicatedStorage.Packages.ProfileService)
local PlantillaPerfil = require(ReplicatedStorage.Shared.Datos.PlantillaPerfil)
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)
local Datos = require(ReplicatedStorage.Shared.Datos)

type PerfilJugador = PlantillaPerfil.PerfilJugador

local NOMBRE_ALMACEN = "DatosJugadores_v1"
local AlmacenPerfiles = ProfileService.GetProfileStore(NOMBRE_ALMACEN, PlantillaPerfil)
if RunService:IsStudio() then
	AlmacenPerfiles = AlmacenPerfiles.Mock
end

local GestorDatos = {}
GestorDatos.PesosModificados = Instance.new("BindableEvent")
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
	if perfilesCargados[player] then
		return
	end

	local clavePerfil = "Jugador_" .. player.UserId
	local exito, perfil = pcall(function()
		return AlmacenPerfiles:LoadProfileAsync(clavePerfil)
	end)

	if exito and perfil ~= nil then
		perfil:AddUserId(player.UserId)
		perfil:Reconcile()
		if not perfil.Data.VehiculosComprados then
			perfil.Data.VehiculosComprados =
				{ ["Vehiculo_Bicicleta"] = true, ["Vehiculo_Moto"] = true }
		else
			perfil.Data.VehiculosComprados["Vehiculo_Moto"] = true
			perfil.Data.VehiculosComprados["Vehiculo_Bicicleta"] = true
		end
		if
			not perfil.Data.VehiculoEquipado
			or perfil.Data.VehiculoEquipado == "Vehiculo_Bicicleta"
		then
			perfil.Data.VehiculoEquipado = "Vehiculo_Moto"
		end
		perfil:ListenToRelease(function()
			perfilesCargados[player] = nil
			player:Kick("Tu sesión fue abierta en otro servidor. Por favor vuelve a entrar.")
		end)

		if player:IsDescendantOf(Players) == true then
			perfilesCargados[player] = perfil
			sincronizarCliente(player)
			print("El Patrón del Dulce: Perfil cargado exitosamente para " .. player.Name)
		else
			perfil:Release()
		end
	else
		warn(
			"El Patrón del Dulce: Error al cargar perfil para "
				.. player.Name
				.. ": "
				.. tostring(perfil)
		)
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
	GestorDatos.PesosModificados:Fire(player, perfil.Data.PesosDulces, perfil.Data)
	return true
end

function GestorDatos.AgregarFama(player: Player, cantidad: number): boolean
	local perfil = perfilesCargados[player]
	if not perfil or cantidad <= 0 then
		return false
	end
	perfil.Data.Fama += math.floor(cantidad)
	sincronizarCliente(player)
	return true
end

function GestorDatos.TieneArma(player: Player, idArma: string): boolean
	local perfil = perfilesCargados[player]
	if not perfil then
		return false
	end
	if idArma == "Arma_CaucheraGomitas" then
		return true
	end
	local desbloqueadas = perfil.Data.ArmasDesbloqueadas
	return desbloqueadas ~= nil and desbloqueadas[idArma] == true
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

function GestorDatos.TieneMejora(player: Player, idMejora: string): boolean
	local perfil = perfilesCargados[player]
	if not perfil then
		return false
	end
	if not perfil.Data.MejorasCompradas then
		perfil.Data.MejorasCompradas = {}
	end
	return perfil.Data.MejorasCompradas[idMejora] == true
end

function GestorDatos.ComprarMejora(player: Player, idMejora: string): (boolean, string)
	local perfil = perfilesCargados[player]
	if not perfil then
		return false, "Perfil no disponible"
	end
	if not perfil.Data.MejorasCompradas then
		perfil.Data.MejorasCompradas = {}
	end
	if perfil.Data.MejorasCompradas[idMejora] then
		return false, "Ya posees esta mejora"
	end

	local infoMejora = Datos.Mejoras[idMejora]
	if not infoMejora then
		return false, "Mejora no encontrada en el catálogo"
	end

	if infoMejora.Nivel > 1 then
		local mejoraAnterior = string.gsub(
			idMejora,
			"_" .. tostring(infoMejora.Nivel) .. "$",
			"_" .. tostring(infoMejora.Nivel - 1)
		)
		if not perfil.Data.MejorasCompradas[mejoraAnterior] then
			return false, "Debes adquirir el nivel anterior primero"
		end
	end

	if perfil.Data.PesosDulces < infoMejora.Precio then
		return false, "Saldo insuficiente de pesos dulces"
	end

	perfil.Data.PesosDulces -= infoMejora.Precio
	perfil.Data.MejorasCompradas[idMejora] = true
	sincronizarCliente(player)
	return true, "Mejora comprada con éxito"
end

function GestorDatos.TieneVehiculo(player: Player, idVehiculo: string): boolean
	local perfil = perfilesCargados[player]
	if not perfil then
		return false
	end
	if not perfil.Data.VehiculosComprados then
		perfil.Data.VehiculosComprados = { ["Vehiculo_Bicicleta"] = true }
	end
	return perfil.Data.VehiculosComprados[idVehiculo] == true
end

function GestorDatos.ComprarVehiculo(player: Player, idVehiculo: string): (boolean, string)
	local perfil = perfilesCargados[player]
	if not perfil then
		return false, "Perfil no disponible"
	end
	if not perfil.Data.VehiculosComprados then
		perfil.Data.VehiculosComprados = { ["Vehiculo_Bicicleta"] = true }
	end
	if perfil.Data.VehiculosComprados[idVehiculo] then
		return false, "Ya posees este vehículo"
	end

	local infoVehiculo = Datos.Vehiculos[idVehiculo]
	if not infoVehiculo then
		return false, "Vehículo no encontrado en el catálogo"
	end

	if perfil.Data.PesosDulces < infoVehiculo.Precio then
		return false, "Saldo insuficiente de pesos dulces"
	end

	perfil.Data.PesosDulces -= infoVehiculo.Precio
	perfil.Data.VehiculosComprados[idVehiculo] = true
	perfil.Data.VehiculoEquipado = idVehiculo
	sincronizarCliente(player)
	return true, "Vehículo comprado y equipado con éxito"
end

function GestorDatos.EquiparVehiculo(player: Player, idVehiculo: string): (boolean, string)
	local perfil = perfilesCargados[player]
	if not perfil then
		return false, "Perfil no disponible"
	end
	if not GestorDatos.TieneVehiculo(player, idVehiculo) then
		return false, "No posees este vehículo aún"
	end
	perfil.Data.VehiculoEquipado = idVehiculo
	sincronizarCliente(player)
	return true, "Vehículo equipado"
end

function GestorDatos.ObtenerMultiplicadorTiempoCocina(player: Player): number
	local perfil = perfilesCargados[player]
	if not perfil or not perfil.Data.MejorasCompradas then
		return 1.0
	end

	if perfil.Data.MejorasCompradas["Mejora_Cocina_Velocidad_2"] then
		local mejora = Datos.Mejoras["Mejora_Cocina_Velocidad_2"]
		return 1.0 - (mejora and mejora.Valor or 0.30)
	elseif perfil.Data.MejorasCompradas["Mejora_Cocina_Velocidad_1"] then
		local mejora = Datos.Mejoras["Mejora_Cocina_Velocidad_1"]
		return 1.0 - (mejora and mejora.Valor or 0.15)
	end

	return 1.0
end

function GestorDatos.ObtenerCapacidadCarga(player: Player): number
	local perfil = perfilesCargados[player]
	local idVehiculo = (perfil and perfil.Data.VehiculoEquipado) or "Vehiculo_Bicicleta"
	local vehiculo = Datos.Vehiculos[idVehiculo]
	return (vehiculo and vehiculo.CapacidadCarga) or 20
end

function GestorDatos.CalcularEstrellas(puntosCalor: number): number
	local configPersecucion = Datos.Persecucion
	if not configPersecucion or not configPersecucion.Estrellas then
		return 0
	end
	for nivel = 5, 1, -1 do
		local info = configPersecucion.Estrellas[nivel]
		if info and puntosCalor >= info.UmbralPuntos then
			return nivel
		end
	end
	return 0
end

function GestorDatos.ObtenerPuntosCalor(player: Player): number
	local perfil = perfilesCargados[player]
	return (perfil and perfil.Data.PuntosCalor) or 0
end

function GestorDatos.ObtenerEstrellas(player: Player): number
	local perfil = perfilesCargados[player]
	return (perfil and perfil.Data.EstrellasBusqueda) or 0
end

function GestorDatos.EstablecerEstrellas(player: Player, estrellas: number): number
	local perfil = perfilesCargados[player]
	if not perfil then
		return 0
	end
	local nuevas = math.clamp(estrellas, 0, 5)
	perfil.Data.EstrellasBusqueda = nuevas
	sincronizarCliente(player)
	return nuevas
end

function GestorDatos.AgregarCalor(player: Player, deltaPuntos: number): (number, number)
	local perfil = perfilesCargados[player]
	if not perfil then
		return 0, 0
	end
	local puntosActuales = perfil.Data.PuntosCalor or 0
	local nuevosPuntos = math.clamp(puntosActuales + deltaPuntos, 0, 600)
	perfil.Data.PuntosCalor = nuevosPuntos

	local estrellasActuales = perfil.Data.EstrellasBusqueda or 0
	local nuevasEstrellas = GestorDatos.CalcularEstrellas(nuevosPuntos)
	perfil.Data.EstrellasBusqueda = nuevasEstrellas

	sincronizarCliente(player)

	if nuevasEstrellas > estrellasActuales then
		local mensaje = string.format(
			"¡Alerta! Subiste a %d estrella(s) de búsqueda. La patrulla dental vigila la zona.",
			nuevasEstrellas
		)
		EventosRemotos.AlertaPolicia:FireClient(player, mensaje, nuevasEstrellas)
	end

	return nuevosPuntos, nuevasEstrellas
end

function GestorDatos.EnfriarCalor(player: Player, deltaPuntos: number): (number, number)
	local perfil = perfilesCargados[player]
	if not perfil then
		return 0, 0
	end
	local puntosActuales = perfil.Data.PuntosCalor or 0
	local nuevosPuntos = math.clamp(puntosActuales - deltaPuntos, 0, 600)
	perfil.Data.PuntosCalor = nuevosPuntos

	local nuevasEstrellas = GestorDatos.CalcularEstrellas(nuevosPuntos)
	perfil.Data.EstrellasBusqueda = nuevasEstrellas

	sincronizarCliente(player)
	return nuevosPuntos, nuevasEstrellas
end

function GestorDatos.ModificarEstrellas(player: Player, delta: number): number
	local perfil = perfilesCargados[player]
	if not perfil then
		return 0
	end
	local actuales = perfil.Data.EstrellasBusqueda or 0
	local nuevas = math.clamp(actuales + delta, 0, 5)
	perfil.Data.EstrellasBusqueda = nuevas
	if nuevas == 0 then
		perfil.Data.PuntosCalor = 0
	else
		local config = Datos.Persecucion.Estrellas[nuevas]
		if config then
			perfil.Data.PuntosCalor = config.UmbralPuntos
		end
	end
	sincronizarCliente(player)
	return nuevas
end

function GestorDatos.ConfiscarCarga(player: Player): number
	local perfil = perfilesCargados[player]
	if not perfil then
		return 0
	end
	local total = 0
	for _, cant in pairs(perfil.Data.Inventario) do
		total += cant
	end
	perfil.Data.Inventario = {}
	perfil.Data.EstrellasBusqueda = 0
	perfil.Data.PuntosCalor = 0
	sincronizarCliente(player)
	return total
end

function GestorDatos.ConfiscarCargaPorcentaje(player: Player, porcentaje: number): number
	local perfil = perfilesCargados[player]
	if not perfil then
		return 0
	end
	local factor = math.clamp(porcentaje, 0, 1)
	local totalConfiscado = 0
	for idDulce, cantidad in pairs(perfil.Data.Inventario) do
		local aQuitar = math.ceil(cantidad * factor)
		if aQuitar > 0 then
			local restante = math.max(0, cantidad - aQuitar)
			totalConfiscado += (cantidad - restante)
			if restante > 0 then
				perfil.Data.Inventario[idDulce] = restante
			else
				perfil.Data.Inventario[idDulce] = nil
			end
		end
	end
	sincronizarCliente(player)
	return totalConfiscado
end

function GestorDatos.ConquistarTienda(player: Player, idTienda: string): boolean
	local perfil = perfilesCargados[player]
	if not perfil then
		return false
	end
	if not perfil.Data.TiendasConquistadas then
		perfil.Data.TiendasConquistadas = {}
	end
	if not perfil.Data.TiendasConquistadas[idTienda] then
		perfil.Data.TiendasConquistadas[idTienda] = true
		sincronizarCliente(player)
		return true
	end
	return false
end

function GestorDatos.ObtenerTiendasConquistadas(player: Player): { [string]: boolean }
	local perfil = perfilesCargados[player]
	if not perfil or not perfil.Data.TiendasConquistadas then
		return {}
	end
	return perfil.Data.TiendasConquistadas
end

function GestorDatos.DesbloquearReceta(player: Player, idReceta: string): boolean
	local perfil = perfilesCargados[player]
	if not perfil then
		return false
	end
	if not perfil.Data.RecetasDesbloqueadas then
		perfil.Data.RecetasDesbloqueadas = { ["Dulce_Bombon"] = true }
	end
	if not perfil.Data.RecetasDesbloqueadas[idReceta] then
		perfil.Data.RecetasDesbloqueadas[idReceta] = true
		sincronizarCliente(player)
		return true
	end
	return false
end

function GestorDatos.TieneReceta(player: Player, idReceta: string): boolean
	local perfil = perfilesCargados[player]
	if not perfil or not perfil.Data.RecetasDesbloqueadas then
		return idReceta == "Dulce_Bombon"
	end
	return perfil.Data.RecetasDesbloqueadas[idReceta] == true
end

function GestorDatos.VaciarCargaDulces(player: Player): number
	local perfil = perfilesCargados[player]
	if not perfil or not perfil.Data.Inventario then
		return 0
	end
	local total = 0
	for idDulce, cantidad in pairs(perfil.Data.Inventario) do
		if cantidad > 0 then
			total += cantidad
			perfil.Data.Inventario[idDulce] = 0
		end
	end
	if total > 0 then
		sincronizarCliente(player)
	end
	return total
end

function GestorDatos.EstaEnInternado(player: Player): boolean
	local perfil = perfilesCargados[player]
	return (perfil and (perfil.Data.CondenaInternado or 0) > 0) or false
end

function GestorDatos.ObtenerCondenaInternado(player: Player): number
	local perfil = perfilesCargados[player]
	return (perfil and perfil.Data.CondenaInternado) or 0
end

function GestorDatos.EstablecerCondenaInternado(player: Player, segundos: number)
	local perfil = perfilesCargados[player]
	if not perfil then
		return
	end
	perfil.Data.CondenaInternado = math.max(0, segundos)
	sincronizarCliente(player)
end

function GestorDatos.ReducirCondenaInternado(player: Player, segundos: number): number
	local perfil = perfilesCargados[player]
	if not perfil then
		return 0
	end
	local actual = perfil.Data.CondenaInternado or 0
	local nueva = math.max(0, actual - segundos)
	perfil.Data.CondenaInternado = nueva
	sincronizarCliente(player)
	return nueva
end

function GestorDatos.PagarFianza(player: Player): (boolean, string)
	local perfil = perfilesCargados[player]
	if not perfil then
		return false, "Perfil no disponible"
	end
	local condena = perfil.Data.CondenaInternado or 0
	if condena <= 0 then
		return false, "No estás cumpliendo condena"
	end

	local estrellas = perfil.Data.EstrellasBusqueda or 3
	local infoEstrella = Datos.Persecucion.Estrellas[estrellas] or Datos.Persecucion.Estrellas[3]
	local fianza = (infoEstrella and infoEstrella.FianzaPesos) or 50

	if perfil.Data.PesosDulces < fianza then
		return false, string.format("Necesitas $%d pesos para pagar la fianza", fianza)
	end

	perfil.Data.PesosDulces -= fianza
	perfil.Data.CondenaInternado = 0
	perfil.Data.PuntosCalor = 0
	perfil.Data.EstrellasBusqueda = 0
	sincronizarCliente(player)
	return true, "Fianza pagada con éxito. ¡Quedas en libertad!"
end

function GestorDatos.ObtenerCapitulo(player: Player): number
	local perfil = perfilesCargados[player]
	if perfil and perfil.Data then
		return perfil.Data.CapituloActual or 1
	end
	return 1
end

function GestorDatos.AvanzarCapitulo(player: Player, nuevoCapitulo: number): boolean
	local perfil = perfilesCargados[player]
	if not perfil or not perfil.Data then
		return false
	end

	local capActual = perfil.Data.CapituloActual or 1
	if nuevoCapitulo > capActual then
		perfil.Data.CapituloActual = nuevoCapitulo
		sincronizarCliente(player)
		return true
	end
	return false
end

function GestorDatos.ObtenerPasoTutorial(player: Player): number
	local perfil = perfilesCargados[player]
	if perfil and perfil.Data then
		return perfil.Data.PasoTutorial or 0
	end
	return 0
end

function GestorDatos.EstablecerPasoTutorial(player: Player, paso: number)
	local perfil = perfilesCargados[player]
	if perfil and perfil.Data then
		perfil.Data.PasoTutorial = paso
		if paso >= 5 then
			perfil.Data.TutorialCompletado = true
		end
		sincronizarCliente(player)
	end
end

function GestorDatos.Iniciar()
	EventosRemotos.SolicitarDatos.OnServerInvoke = function(player: Player)
		local perfil = perfilesCargados[player]
		if perfil then
			return perfil.Data
		end
		return nil
	end

	EventosRemotos.SolicitarCompraMejora.OnServerInvoke = function(player: Player, idMejora: string)
		if typeof(idMejora) ~= "string" then
			return false, "Petición inválida"
		end
		return GestorDatos.ComprarMejora(player, idMejora)
	end

	EventosRemotos.SolicitarCompraVehiculo.OnServerInvoke = function(
		player: Player,
		idVehiculo: string
	)
		if typeof(idVehiculo) ~= "string" then
			return false, "Petición inválida"
		end
		return GestorDatos.ComprarVehiculo(player, idVehiculo)
	end

	EventosRemotos.SolicitarEquiparVehiculo.OnServerInvoke = function(
		player: Player,
		idVehiculo: string
	)
		if typeof(idVehiculo) ~= "string" then
			return false, "Petición inválida"
		end
		return GestorDatos.EquiparVehiculo(player, idVehiculo)
	end

	EventosRemotos.SolicitarPagarFianza.OnServerInvoke = function(player: Player)
		return GestorDatos.PagarFianza(player)
	end

	EventosRemotos.CepillarMuela.OnServerInvoke = function(player: Player)
		if not GestorDatos.EstaEnInternado(player) then
			return false, "No estás en el internado"
		end
		local reduccion = Datos.Persecucion.Internado.ReduccionPorCepilladoSegundos or 20
		local restante = GestorDatos.ReducirCondenaInternado(player, reduccion)
		return true,
			string.format("¡Muela cepillada! Redujiste %ds. Restan %ds.", reduccion, restante)
	end

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(alEntrarJugador, player)
	end

	Players.PlayerAdded:Connect(alEntrarJugador)
	Players.PlayerRemoving:Connect(alSalirJugador)
end

return GestorDatos
