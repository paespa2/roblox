--!strict
--[[
	ZombieAI.luau
	Máquina de estados finitos (FSM) y navegación con PathfindingService
	para todos los zombis activos en un bucle centralizado optimizado.
]]

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Datos = require(ReplicatedStorage.Shared.Datos)
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)
local ZombieService = require(script.Parent.ZombieService)

type RegistroZombi = ZombieService.RegistroZombi
type EstadoZombi = ZombieService.EstadoZombi

local ConfigZombis = Datos.Zombis.General

local ZombieAI = {}

local _activo = false
local _bucleThread: thread? = nil

local function actualizarEstadoModelo(registro: RegistroZombi, nuevoEstado: EstadoZombi)
	if registro.Estado ~= nuevoEstado then
		registro.Estado = nuevoEstado
		registro.Modelo:SetAttribute("EstadoIA", nuevoEstado)
	end
end

local function esJugadorValido(player: Player?): (boolean, BasePart?, Humanoid?)
	if not player or not player:IsDescendantOf(Players) then
		return false, nil, nil
	end
	local char = player.Character
	if not char then
		return false, nil, nil
	end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hrp:IsA("BasePart") or not hum or hum.Health <= 0 then
		return false, nil, nil
	end
	return true, hrp, hum
end

local function buscarObjetivoMasCercano(
	origen: Vector3,
	radioMaximo: number
): (Player?, BasePart?, number)
	local mejorJugador: Player? = nil
	local mejorHRP: BasePart? = nil
	local mejorDist = radioMaximo

	for _, player in ipairs(Players:GetPlayers()) do
		local valido, pHrp = esJugadorValido(player)
		if valido and pHrp then
			local dist = (pHrp.Position - origen).Magnitude
			if dist <= mejorDist then
				mejorDist = dist
				mejorJugador = player
				mejorHRP = pHrp
			end
		end
	end

	return mejorJugador, mejorHRP, mejorDist
end

local function tieneLineaVistaDirecta(
	origen: Vector3,
	destino: Vector3,
	modeloIgnorar: Model
): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclusiones: { Instance } = { modeloIgnorar }
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			table.insert(exclusiones, p.Character)
		end
	end
	params.FilterDescendantsInstances = exclusiones

	local dir = destino - origen
	local hit = Workspace:Raycast(origen + Vector3.new(0, 1.0, 0), dir, params)
	return hit == nil
end

local function calcularRutaZombi(registro: RegistroZombi, destino: Vector3)
	local path = PathfindingService:CreatePath({
		AgentRadius = 2.0,
		AgentHeight = 5.5,
		AgentCanJump = true,
		AgentCanClimb = false,
		WaypointSpacing = 4.5,
	})

	local ok = pcall(function()
		path:ComputeAsync(registro.HRP.Position, destino)
	end)

	if ok and path.Status == Enum.PathStatus.Success then
		local waypoints = path:GetWaypoints()
		if #waypoints >= 2 then
			registro.WaypointsActuales = waypoints
			registro.IndiceWaypoint = 2
			registro.UltimaPosObjetivoRuta = destino
			return
		end
	end

	-- Si falla el pathfinding completo, limpiar waypoints para usar movimiento de contingencia
	registro.WaypointsActuales = nil
	registro.IndiceWaypoint = 1
	registro.UltimaPosObjetivoRuta = destino
end

local function ejecutarAtaqueZombi(registro: RegistroZombi, objetivo: Player)
	local ahora = os.clock()
	if (ahora - registro.UltimoAtaque) < registro.CooldownAtaque then
		return
	end

	registro.UltimoAtaque = ahora
	actualizarEstadoModelo(registro, "Attacking")
	registro.Modelo:SetAttribute("UltimoAtaque", ahora)
	registro.Humanoid.WalkSpeed = registro.VelocidadBase * 0.15

	local _, targetHrp = esJugadorValido(objetivo)
	if targetHrp then
		local posZombi = registro.HRP.Position
		local posTarget = Vector3.new(targetHrp.Position.X, posZombi.Y, targetHrp.Position.Z)
		if (posTarget - posZombi).Magnitude > 0.1 then
			registro.Humanoid:MoveTo(posZombi)
		end
	end

	-- Ventana de impacto validada en el servidor (un solo impacto por golpe)
	task.delay(ConfigZombis.VentanaImpactoSegundos, function()
		if registro.Muerto or not registro.Modelo.Parent then
			return
		end
		if registro.Estado == "Stunned" or registro.Estado == "Dead" then
			return
		end

		local sigueValido, pHrp, pHum = esJugadorValido(objetivo)
		if not sigueValido or not pHrp or not pHum then
			return
		end

		local distImpacto = (pHrp.Position - registro.HRP.Position).Magnitude
		if distImpacto <= ConfigZombis.RangoImpactoMaximoStuds then
			pHum:TakeDamage(registro.DanioAtaque)
			EventosRemotos.ZombieEventoVisual:FireAllClients({
				Tipo = "Ataque",
				Modelo = registro.Modelo,
				Posicion = pHrp.Position,
			})
		end
	end)
end

local function actualizarZombiIndividual(
	registro: RegistroZombi,
	ahora: number,
	presupuestoRutas: { Restantes: number }
)
	if registro.Muerto or not registro.Modelo.Parent or not registro.HRP.Parent then
		return
	end

	-- 1. Estado Stunned (aturdido tras recibir impacto)
	if registro.Estado == "Stunned" then
		if ahora < registro.AturdidoHasta then
			return
		end
		registro.Humanoid.WalkSpeed = registro.VelocidadBase
		actualizarEstadoModelo(registro, "Detecting")
	end

	-- 2. Esperar fin breve de animación de ataque antes de reanudar persecución
	if registro.Estado == "Attacking" then
		if (ahora - registro.UltimoAtaque) < 0.48 then
			return
		end
		registro.Humanoid.WalkSpeed = registro.VelocidadBase
	end

	-- 3. Validar objetivo actual o detectar uno nuevo
	local objetivoValido, targetHrp = esJugadorValido(registro.ObjetivoActual)
	if not objetivoValido then
		registro.ObjetivoActual = nil
		local nuevoObjetivo, nuevoHrp =
			buscarObjetivoMasCercano(registro.HRP.Position, ConfigZombis.RadioDeteccionStuds)
		registro.ObjetivoActual = nuevoObjetivo
		targetHrp = nuevoHrp
	else
		-- Verificar periódicamente si hay otro jugador mucho más cerca
		local masCercano, masCercanoHrp, distCercano =
			buscarObjetivoMasCercano(registro.HRP.Position, ConfigZombis.RadioDeteccionStuds)
		if masCercano and masCercano ~= registro.ObjetivoActual and targetHrp then
			local distActual = (targetHrp.Position - registro.HRP.Position).Magnitude
			if distCercano + 8 < distActual then
				registro.ObjetivoActual = masCercano
				targetHrp = masCercanoHrp
			end
		end
	end

	if not registro.ObjetivoActual or not targetHrp then
		actualizarEstadoModelo(registro, "Idle")
		registro.Humanoid.WalkSpeed = 0
		return
	end

	local posZombi = registro.HRP.Position
	local posObjetivo = targetHrp.Position
	local distHorizontal = ((posObjetivo - posZombi) * Vector3.new(1, 0, 1)).Magnitude

	-- 4. Verificar si está en rango de ataque
	if
		distHorizontal <= ConfigZombis.RangoAtaqueStuds
		and math.abs(posObjetivo.Y - posZombi.Y) <= 6.0
	then
		ejecutarAtaqueZombi(registro, registro.ObjetivoActual)
		return
	end

	-- 5. Persecución activa
	actualizarEstadoModelo(registro, "Chasing")
	registro.Humanoid.WalkSpeed = registro.VelocidadBase

	-- Persecución directa a corta distancia con línea de vista despejada
	if
		distHorizontal <= 12
		and math.abs(posObjetivo.Y - posZombi.Y) <= 4.0
		and tieneLineaVistaDirecta(posZombi, posObjetivo, registro.Modelo)
	then
		registro.Humanoid:MoveTo(posObjetivo)
		return
	end

	-- 6. Navegación con PathfindingService (limitada por presupuesto y cooldown)
	local necesitaRuta = not registro.WaypointsActuales
		or (registro.UltimaPosObjetivoRuta ~= nil and (posObjetivo - registro.UltimaPosObjetivoRuta).Magnitude > 6.5)
		or ((ahora - registro.UltimoRecalculoRuta) > 1.2)

	-- Detección de atascos
	if (ahora - registro.UltimoChequeoAtasco) >= 1.4 then
		local desplazamiento = (posZombi - registro.UltimaPosComprobada).Magnitude
		registro.UltimaPosComprobada = posZombi
		registro.UltimoChequeoAtasco = ahora
		if desplazamiento < 1.3 then
			registro.Humanoid.Jump = true
			necesitaRuta = true
		end
	end

	if
		necesitaRuta
		and (ahora - registro.UltimoRecalculoRuta) >= 0.45
		and presupuestoRutas.Restantes > 0
	then
		registro.UltimoRecalculoRuta = ahora
		presupuestoRutas.Restantes -= 1
		calcularRutaZombi(registro, posObjetivo)
	end

	local waypoints = registro.WaypointsActuales
	if waypoints and registro.IndiceWaypoint <= #waypoints then
		local wp = waypoints[registro.IndiceWaypoint]
		if wp.Action == Enum.PathWaypointAction.Jump then
			registro.Humanoid.Jump = true
		end

		local distWp = ((wp.Position - posZombi) * Vector3.new(1, 0, 1)).Magnitude
		if distWp < 3.2 and registro.IndiceWaypoint < #waypoints then
			registro.IndiceWaypoint += 1
			wp = waypoints[registro.IndiceWaypoint]
		end

		registro.Humanoid:MoveTo(wp.Position)
	else
		-- Contingencia si no hay navmesh válido cerca del punto: avanzar directo
		registro.Humanoid:MoveTo(posObjetivo)
	end
end

function ZombieAI.Iniciar()
	if _activo then
		return
	end
	_activo = true

	_bucleThread = task.spawn(function()
		while _activo do
			local ahora = os.clock()
			local presupuestoRutas = { Restantes = 4 } -- Máx. 4 cómputos PathfindingService por tick

			for _, registro in pairs(ZombieService.ObtenerZombisActivos()) do
				actualizarZombiIndividual(registro, ahora, presupuestoRutas)
			end

			task.wait(0.1)
		end
	end)
end

function ZombieAI.Detener()
	_activo = false
	if _bucleThread then
		task.cancel(_bucleThread)
		_bucleThread = nil
	end
end

return ZombieAI
