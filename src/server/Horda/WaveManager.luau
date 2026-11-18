--!strict
--[[
	WaveManager.luau
	Administra el ciclo de oleadas progresivas, cuenta regresiva, distribución
	de apariciones y finalización de hordas al estilo Call of Duty Zombies.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Datos = require(ReplicatedStorage.Shared.Datos)
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)
local GestorDatos = require(script.Parent.Parent.GestorDatos)
local UtilidadesMapaHorda = require(script.Parent.UtilidadesMapaHorda)
local ZombieService = require(script.Parent.ZombieService)
local ZombieAI = require(script.Parent.ZombieAI)

local ConfigZombis = Datos.Zombis
local General = ConfigZombis.General

export type EstadoHorda = "Inactiva" | "CuentaRegresiva" | "EnCurso" | "OleadaCompletada"

local WaveManager = {}

local _estado: EstadoHorda = "Inactiva"
local _oleadaActual = 0
local _zombisPorGenerar = 0
local _totalOleadaActual = 0
local _hiloCiclo: thread? = nil

local function hayAlgunJugadorVivo(): boolean
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			return true
		end
	end
	return false
end

local function notificarEstado(mensaje: string?, tiempoRestante: number?)
	local vivos = ZombieService.ContarZombisVivos()
	local restantes = vivos + _zombisPorGenerar

	EventosRemotos.EstadoHordaActualizado:FireAllClients({
		Estado = _estado,
		Oleada = _oleadaActual,
		ZombisRestantes = restantes,
		TotalOleada = _totalOleadaActual,
		Mensaje = mensaje or "",
		TiempoRestante = tiempoRestante or 0,
	})
end

local function barajarLista(lista: { Vector3 }): { Vector3 }
	local copia = table.clone(lista)
	for i = #copia, 2, -1 do
		local j = math.random(1, i)
		copia[i], copia[j] = copia[j], copia[i]
	end
	return copia
end

local function ejecutarOleada(numeroOleada: number)
	if _estado == "Inactiva" then
		return
	end

	_oleadaActual = numeroOleada
	local configOleada = ConfigZombis.ObtenerConfigOleada(numeroOleada)
	_zombisPorGenerar = configOleada.Cantidad
	_totalOleadaActual = configOleada.Cantidad
	_estado = "EnCurso"

	notificarEstado(string.format("OLEADA %d", numeroOleada), 0)
	print(
		string.format(
			"[WaveManager] Iniciando Oleada %d | Zombis: %d | Velocidad: %.1f (%s)",
			numeroOleada,
			configOleada.Cantidad,
			configOleada.VelocidadBase,
			configOleada.EtiquetaVelocidad
		)
	)

	-- Cola de generación escalonada respetando el límite simultáneo
	local indicePunto = 0
	local puntosValidos = barajarLista(
		UtilidadesMapaHorda.ObtenerPuntosAparicionZombis(
			ConfigZombis.PuntosAparicionRespaldo,
			General.DistanciaMinSpawnJugador,
			General.DistanciaMaxSpawnJugador
		)
	)

	while _zombisPorGenerar > 0 and _estado == "EnCurso" do
		if not hayAlgunJugadorVivo() then
			WaveManager.DetenerHorda("Todos los sobrevivientes han caído")
			return
		end

		local vivosAhora = ZombieService.ContarZombisVivos()
		if vivosAhora < General.MaxZombisSimultaneos then
			if #puntosValidos == 0 or indicePunto >= #puntosValidos then
				puntosValidos = barajarLista(
					UtilidadesMapaHorda.ObtenerPuntosAparicionZombis(
						ConfigZombis.PuntosAparicionRespaldo,
						General.DistanciaMinSpawnJugador,
						General.DistanciaMaxSpawnJugador
					)
				)
				indicePunto = 0
			end

			if #puntosValidos > 0 then
				indicePunto += 1
				local posSpawn = puntosValidos[indicePunto]
				ZombieService.GenerarZombi(posSpawn, numeroOleada, configOleada)
				_zombisPorGenerar -= 1
				notificarEstado("", 0)
			end
		end

		task.wait(General.IntervaloSpawnSegundos)
	end

	-- Esperar hasta que TODOS los zombis de esta oleada mueran
	while _estado == "EnCurso" do
		if not hayAlgunJugadorVivo() then
			WaveManager.DetenerHorda("Todos los sobrevivientes han caído")
			return
		end

		local vivos = ZombieService.ContarZombisVivos()
		if vivos == 0 and _zombisPorGenerar == 0 then
			break
		end
		task.wait(0.35)
	end

	if _estado ~= "EnCurso" then
		return
	end

	-- Oleada completada
	_estado = "OleadaCompletada"
	notificarEstado("TODOS LOS ENEMIGOS ELIMINADOS", General.TiempoEntreOleadas)

	-- Premio de supervivencia por completar oleada
	local bonoPesos = 25 + (numeroOleada * 15)
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			GestorDatos.AgregarPesos(player, bonoPesos)
			local datos = GestorDatos.ObtenerDatos(player)
			if datos then
				datos.Fama += 2
			end
		end
	end

	task.wait(1.8)
	if _estado ~= "OleadaCompletada" then
		return
	end

	-- Descanso antes de la siguiente oleada
	local descanso = math.max(1, General.TiempoEntreOleadas - 2)
	for seg = descanso, 1, -1 do
		if _estado ~= "OleadaCompletada" then
			return
		end
		notificarEstado("OLEADA COMPLETADA", seg)
		task.wait(1)
	end

	if _estado == "OleadaCompletada" then
		ejecutarOleada(numeroOleada + 1)
	end
end

function WaveManager.EstaActiva(): boolean
	return _estado ~= "Inactiva"
end

function WaveManager.ObtenerEstado(): EstadoHorda
	return _estado
end

function WaveManager.ObtenerOleadaActual(): number
	return _oleadaActual
end

function WaveManager.IniciarHorda()
	if _estado ~= "Inactiva" then
		return
	end

	_estado = "CuentaRegresiva"
	_oleadaActual = 0
	_zombisPorGenerar = 0
	_totalOleadaActual = 0

	ZombieAI.Iniciar()

	_hiloCiclo = task.spawn(function()
		for seg = General.CuentaRegresivaInicial, 1, -1 do
			if _estado ~= "CuentaRegresiva" then
				return
			end
			notificarEstado("LA HORDA SE ACERCA...", seg)
			task.wait(1)
		end

		if _estado == "CuentaRegresiva" then
			ejecutarOleada(1)
		end
	end)
end

function WaveManager.DetenerHorda(motivo: string?)
	if _estado == "Inactiva" then
		return
	end

	_estado = "Inactiva"
	_zombisPorGenerar = 0
	_totalOleadaActual = 0

	if _hiloCiclo and coroutine.running() ~= _hiloCiclo then
		task.cancel(_hiloCiclo)
	end
	_hiloCiclo = nil

	ZombieAI.Detener()
	ZombieService.LimpiarTodosZombis()
	notificarEstado(motivo or "Horda finalizada", 0)
	_oleadaActual = 0

	print("[WaveManager] Horda finalizada: " .. tostring(motivo or "Reset"))
end

function WaveManager.Inicializar()
	ZombieService.EstablecerCallbackMuerte(function(_registro)
		if _estado == "EnCurso" then
			notificarEstado("", 0)
		end
	end)

	Players.PlayerRemoving:Connect(function()
		task.defer(function()
			if _estado ~= "Inactiva" and #Players:GetPlayers() == 0 then
				WaveManager.DetenerHorda("Sin jugadores en el servidor")
			end
		end)
	end)
end

return WaveManager
