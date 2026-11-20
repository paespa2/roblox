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
local HordeSession = require(script.Parent.HordeSession)
local ZombieService = require(script.Parent.ZombieService)

type RegistroZombi = ZombieService.RegistroZombi
type EstadoZombi = ZombieService.EstadoZombi

local ConfigZombis = Datos.Zombis.General

local ZombieAI = {}

local _activo = false
local _sesionIdActiva = 0
local _bucleThread: thread? = nil
local _ultimoDanioJugador: { [Player]: number } = {}

local function actualizarEstadoModelo(registro: RegistroZombi, nuevoEstado: EstadoZombi)
	if registro.Estado ~= nuevoEstado then
		registro.Estado = nuevoEstado
		registro.Modelo:SetAttribute("EstadoIA", nuevoEstado)
	end
end

local function esJugadorValido(player: Player?): (boolean, BasePart?, Humanoid?)
	if not player or not HordeSession.EsParticipanteVivo(player) then
		return false, nil, nil
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hrp:IsA("BasePart") or not hum or hum.Health <= 0 then
		return false, nil, nil
	end
	return true, hrp, hum
end

local function construirParamsVisibilidad(): RaycastParams
	local exclusiones: { Instance } = {}
	local sistema = Workspace:FindFirstChild("HordaSistema")
	if sistema then
		table.insert(exclusiones, sistema)
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			table.insert(exclusiones, p.Character)
		end
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = exclusiones
	return params
end

local function tieneLineaVistaDirecta(
	origen: Vector3,
	destino: Vector3,
	params: RaycastParams
): boolean
	local pOrigen = origen + Vector3.new(0, 1.2, 0)
	local pDestino = destino + Vector3.new(0, 1.2, 0)
	local dir = pDestino - pOrigen
	if dir.Magnitude < 0.5 then
		return true
	end
	local hit = Workspace:Raycast(pOrigen, dir, params)
	return hit == nil
end

local function buscarObjetivoMasCercano(
	origen: Vector3,
	radioMaximo: number,
	params: RaycastParams
): (Player?, BasePart?, number)
	local mejorJugador: Player? = nil
	local mejorHRP: BasePart? = nil
	local mejorPuntuacion = math.huge

	for _, player in ipairs(HordeSession.ObtenerParticipantesVivos()) do
		local valido, pHrp = esJugadorValido(player)
		if valido and pHrp then
			local dist = (pHrp.Position - origen).Magnitude
			if dist <= radioMaximo then
				local accesible = tieneLineaVistaDirecta(origen, pHrp.Position, params)
				-- Priorizar distancia y favorecer objetivos con visión directa (+25 studs equivalentes si está tras muro)
				local puntuacion = dist + (if accesible then 0 else 25)
				if puntuacion < mejorPuntuacion then
					mejorPuntuacion = puntuacion
					mejorJugador = player
					mejorHRP = pHrp
				end
			end
		end
	end

	return mejorJugador, mejorHRP, mejorPuntuacion
end

local function orientarSuavementeHacia(hrp: BasePart, destino: Vector3, factor: number)
	local pos = hrp.Position
	local dir = Vector3.new(destino.X - pos.X, 0, destino.Z - pos.Z)
	if dir.Magnitude < 0.15 then
		return
	end
	local cfObjetivo = CFrame.lookAt(pos, pos + dir.Unit)
	hrp.CFrame = hrp.CFrame:Lerp(cfObjetivo, math.clamp(factor, 0.15, 1.0))
end

local function desconectarPathBlocked(registro: RegistroZombi)
	if registro.PathBlockedConn and registro.PathBlockedConn.Connected then
		registro.PathBlockedConn:Disconnect()
	end
	registro.PathBlockedConn = nil
end

local function calcularRutaZombi(registro: RegistroZombi, destino: Vector3)
	desconectarPathBlocked(registro)
	registro.RutaBloqueada = false

	local escala = (registro.Variante and registro.Variante.Escala) or 1.0
	local path = PathfindingService:CreatePath({
		AgentRadius = math.max(2.0, 2.0 * escala),
		AgentHeight = math.max(5.5, 5.5 * escala),
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
			registro.FallosRutaConsecutivos = 0
			registro.PathBlockedConn = path.Blocked:Connect(function(idxBloqueado: number)
				if idxBloqueado >= registro.IndiceWaypoint then
					registro.RutaBloqueada = true
				end
			end)
			return
		end
	end

	registro.WaypointsActuales = nil
	registro.IndiceWaypoint = 1
	registro.UltimaPosObjetivoRuta = destino
	registro.FallosRutaConsecutivos += 1
end

local function buscarDesvioLateralDespejado(
	posZombi: Vector3,
	dirObjetivo: Vector3,
	params: RaycastParams
): Vector3?
	local base = Vector3.new(dirObjetivo.X, 0, dirObjetivo.Z)
	if base.Magnitude < 0.1 then
		return nil
	end
	base = base.Unit
	local cfBase = CFrame.lookAt(Vector3.zero, base)

	for _, anguloDeg in ipairs({ 45, -45, 90, -90, 135 }) do
		local dirPrueba = (cfBase * CFrame.Angles(0, math.rad(anguloDeg), 0)).LookVector
		local hit = Workspace:Raycast(posZombi + Vector3.new(0, 1.5, 0), dirPrueba * 8, params)
		if not hit then
			return posZombi + dirPrueba * 7
		end
	end
	return nil
end

local function debeSaltarObstaculoBajo(
	posZombi: Vector3,
	lookVector: Vector3,
	params: RaycastParams
): boolean
	local dir = Vector3.new(lookVector.X, 0, lookVector.Z)
	if dir.Magnitude < 0.1 then
		return false
	end
	dir = dir.Unit
	local hitBajo = Workspace:Raycast(posZombi + Vector3.new(0, 0.6, 0), dir * 3.5, params)
	if not hitBajo then
		return false
	end
	local hitAlto = Workspace:Raycast(posZombi + Vector3.new(0, 3.8, 0), dir * 3.8, params)
	return hitAlto == nil
end

local function aplicarEfectoEspecialAtaque(
	registro: RegistroZombi,
	pHrp: BasePart,
	pHum: Humanoid,
	sesionId: number
)
	local efecto = registro.Variante and registro.Variante.EfectoEspecial
	if not efecto then
		return
	end

	if efecto.Tipo == "Quemadura" then
		if pHrp:FindFirstChild("QuemaduraFuegoZombi") then
			return
		end
		local fuego = Instance.new("Fire")
		fuego.Name = "QuemaduraFuegoZombi"
		fuego.Size = 2.6
		fuego.Heat = 6
		fuego.Color = Color3.fromRGB(255, 120, 30)
		fuego.SecondaryColor = Color3.fromRGB(180, 50, 15)
		fuego.Parent = pHrp

		local intervalo = efecto.IntervaloTick or 0.8
		local ticks = math.max(1, math.floor((efecto.Duracion or 2.4) / intervalo))
		local danioTick = efecto.DanioPorTick or 3

		task.spawn(function()
			for _ = 1, ticks do
				task.wait(intervalo)
				if not HordeSession.EsSesionActiva(sesionId) or not pHum.Parent or pHum.Health <= 0 then
					break
				end
				pHum:TakeDamage(danioTick)
			end
			if fuego and fuego.Parent then
				fuego:Destroy()
			end
		end)
	elseif efecto.Tipo == "Congelamiento" then
		if not pHrp:FindFirstChild("CongelamientoHieloZombi") then
			local escarcha = Instance.new("Fire")
			escarcha.Name = "CongelamientoHieloZombi"
			escarcha.Size = 2.5
			escarcha.Heat = 5
			escarcha.Color = Color3.fromRGB(85, 255, 255)
			escarcha.SecondaryColor = Color3.fromRGB(0, 190, 255)
			escarcha.Parent = pHrp
			task.delay(efecto.Duracion or 2.0, function()
				if escarcha and escarcha.Parent then
					escarcha:Destroy()
				end
			end)
		end

		if not pHum:GetAttribute("RalentizadoPorHielo") then
			local velocidadOriginal = pHum.WalkSpeed
			pHum:SetAttribute("VelocidadOriginalHielo", velocidadOriginal)
			pHum:SetAttribute("RalentizadoPorHielo", true)
			pHum.WalkSpeed = math.max(6, velocidadOriginal * (efecto.FactorVelocidad or 0.72))
			task.delay(efecto.Duracion or 2.0, function()
				if pHum and pHum.Parent and pHum:GetAttribute("RalentizadoPorHielo") then
					local orig = pHum:GetAttribute("VelocidadOriginalHielo")
					pHum:SetAttribute("RalentizadoPorHielo", nil)
					pHum:SetAttribute("VelocidadOriginalHielo", nil)
					if typeof(orig) == "number" and pHum.Health > 0 then
						pHum.WalkSpeed = orig
					end
				end
			end)
		end
	elseif efecto.Tipo == "Veneno" then
		if pHrp:FindFirstChild("VenenoToxicoZombi") then
			return
		end
		local veneno = Instance.new("ParticleEmitter")
		veneno.Name = "VenenoToxicoZombi"
		veneno.Texture = "rbxassetid://332655294"
		veneno.Color = ColorSequence.new(Color3.fromRGB(113, 255, 61))
		veneno.Rate = 12
		veneno.Lifetime = NumberRange.new(0.6, 1.0)
		veneno.Speed = NumberRange.new(1, 3)
		veneno.Size = NumberSequence.new(0.4, 0.8)
		veneno.Parent = pHrp

		local intervalo = efecto.IntervaloTick or 1.0
		local ticks = math.max(1, math.floor((efecto.Duracion or 3.0) / intervalo))
		local danioTick = efecto.DanioPorTick or 4

		task.spawn(function()
			for _ = 1, ticks do
				task.wait(intervalo)
				if not HordeSession.EsSesionActiva(sesionId) or not pHum.Parent or pHum.Health <= 0 then
					break
				end
				pHum:TakeDamage(danioTick)
			end
			if veneno and veneno.Parent then
				veneno:Destroy()
			end
		end)
	end
end

local function ejecutarAtaqueZombi(registro: RegistroZombi, objetivo: Player)
	local ahora = os.clock()
	if (ahora - registro.UltimoAtaque) < registro.CooldownAtaque then
		return
	end

	local sesionId = registro.SesionId
	if not HordeSession.EsSesionActiva(sesionId) then
		return
	end

	registro.UltimoAtaque = ahora
	registro.ContadorAtaque += 1
	actualizarEstadoModelo(registro, "Attacking")
	registro.Modelo:SetAttribute("ContadorAtaque", registro.ContadorAtaque)
	registro.Humanoid.WalkSpeed = registro.VelocidadBase * 0.12

	local _, targetHrp = esJugadorValido(objetivo)
	if targetHrp then
		orientarSuavementeHacia(registro.HRP, targetHrp.Position, 0.75)
		registro.Humanoid:MoveTo(registro.HRP.Position)
	end

	-- Ventana de impacto validada en el servidor (un solo impacto con verificación de distancia + línea de visión)
	task.delay(ConfigZombis.VentanaImpactoSegundos, function()
		if not HordeSession.EsSesionActiva(sesionId) then
			return
		end
		if registro.Muerto or not registro.Modelo.Parent or not registro.HRP.Parent then
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
		if distImpacto > ConfigZombis.RangoImpactoMaximoStuds then
			return
		end

		local params = construirParamsVisibilidad()
		if not tieneLineaVistaDirecta(registro.HRP.Position, pHrp.Position, params) then
			return
		end

		-- Control de frecuencia de daño cuando múltiples zombis rodean al jugador
		local momentoGolpe = os.clock()
		local cooldownJugador = ConfigZombis.CooldownDanioJugadorSegundos or 0.55
		local ultimoGolpeRecibido = _ultimoDanioJugador[objetivo] or 0
		if (momentoGolpe - ultimoGolpeRecibido) < cooldownJugador then
			return
		end
		_ultimoDanioJugador[objetivo] = momentoGolpe

		pHum:TakeDamage(registro.DanioAtaque)
		aplicarEfectoEspecialAtaque(registro, pHrp, pHum, sesionId)

		EventosRemotos.ZombieEventoVisual:FireClient(objetivo, {
			Tipo = "Ataque",
			Modelo = registro.Modelo,
			Posicion = pHrp.Position,
			VarianteId = registro.Variante.Id,
			EsDeFuego = registro.Variante.EsDeFuego,
			EsDeHielo = registro.Variante.EsDeHielo,
			EsToxico = registro.Variante.EsToxico,
		})
	end)
end

local function actualizarZombiIndividual(
	registro: RegistroZombi,
	ahora: number,
	presupuestoRutas: { Restantes: number },
	paramsVisibilidad: RaycastParams
)
	if registro.Muerto or not registro.Modelo.Parent or not registro.HRP.Parent then
		return
	end
	if not HordeSession.EsSesionActiva(registro.SesionId) then
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

	-- 2. Fin de recuperación de ataque antes de reanudar persecución
	if registro.Estado == "Attacking" then
		if (ahora - registro.UltimoAtaque) < 0.50 then
			return
		end
		registro.Humanoid.WalkSpeed = registro.VelocidadBase
		actualizarEstadoModelo(registro, "Detecting")
	end

	-- 3. Selección de objetivo (exclusivo a participantes vivos + histéresis)
	local objetivoValido, targetHrp = esJugadorValido(registro.ObjetivoActual)
	if not objetivoValido then
		registro.ObjetivoActual = nil
		local nuevoObjetivo, nuevoHrp = buscarObjetivoMasCercano(
			registro.HRP.Position,
			ConfigZombis.RadioDeteccionStuds,
			paramsVisibilidad
		)
		registro.ObjetivoActual = nuevoObjetivo
		targetHrp = nuevoHrp
		registro.UltimoChequeoObjetivo = ahora
	elseif (ahora - registro.UltimoChequeoObjetivo) >= 0.65 then
		registro.UltimoChequeoObjetivo = ahora
		local masCercano, masCercanoHrp = buscarObjetivoMasCercano(
			registro.HRP.Position,
			ConfigZombis.RadioDeteccionStuds,
			paramsVisibilidad
		)
		if masCercano and masCercano ~= registro.ObjetivoActual and masCercanoHrp and targetHrp then
			local distActual = (targetHrp.Position - registro.HRP.Position).Magnitude
			local distCercano = (masCercanoHrp.Position - registro.HRP.Position).Magnitude
			if distCercano + 10 < distActual then
				registro.ObjetivoActual = masCercano
				targetHrp = masCercanoHrp
			end
		end
	end

	if not registro.ObjetivoActual or not targetHrp then
		actualizarEstadoModelo(registro, "Idle")
		registro.Humanoid.WalkSpeed = 0
		registro.Humanoid:MoveTo(registro.HRP.Position)
		return
	end

	local posZombi = registro.HRP.Position
	local posObjetivo = targetHrp.Position
	local distHorizontal = ((posObjetivo - posZombi) * Vector3.new(1, 0, 1)).Magnitude

	-- 4. Verificar si está en rango de ataque con línea de visión despejada
	if
		distHorizontal <= ConfigZombis.RangoAtaqueStuds
		and math.abs(posObjetivo.Y - posZombi.Y) <= 5.5
		and tieneLineaVistaDirecta(posZombi, posObjetivo, paramsVisibilidad)
	then
		ejecutarAtaqueZombi(registro, registro.ObjetivoActual)
		return
	end

	-- 5. Persecución activa
	actualizarEstadoModelo(registro, "Chasing")
	registro.Humanoid.WalkSpeed = registro.VelocidadBase

	-- Persecución directa a corta distancia únicamente si hay línea de visión real despejada
	if
		distHorizontal <= 14
		and math.abs(posObjetivo.Y - posZombi.Y) <= 4.0
		and tieneLineaVistaDirecta(posZombi, posObjetivo, paramsVisibilidad)
	then
		orientarSuavementeHacia(registro.HRP, posObjetivo, 0.25)
		registro.Humanoid:MoveTo(posObjetivo)
		return
	end

	-- 6. Navegación con PathfindingService (presupuesto global + Path.Blocked)
	local necesitaRuta = registro.RutaBloqueada
		or not registro.WaypointsActuales
		or (registro.UltimaPosObjetivoRuta ~= nil and (posObjetivo - registro.UltimaPosObjetivoRuta).Magnitude > 6.5)
		or ((ahora - registro.UltimoRecalculoRuta) > 1.35)

	-- Detección de atasco real y recuperación inteligente
	if (ahora - registro.UltimoChequeoAtasco) >= 1.4 then
		local desplazamiento = (posZombi - registro.UltimaPosComprobada).Magnitude
		registro.UltimaPosComprobada = posZombi
		registro.UltimoChequeoAtasco = ahora
		if desplazamiento < 1.3 then
			if debeSaltarObstaculoBajo(posZombi, registro.HRP.CFrame.LookVector, paramsVisibilidad) then
				registro.Humanoid.Jump = true
			else
				necesitaRuta = true
				registro.RutaBloqueada = true
			end
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
		-- Contingencia segura: nunca atravesar paredes; sondear desvío lateral despejado
		local desvio = buscarDesvioLateralDespejado(posZombi, posObjetivo - posZombi, paramsVisibilidad)
		if desvio then
			registro.Humanoid:MoveTo(desvio)
		elseif tieneLineaVistaDirecta(posZombi, posObjetivo, paramsVisibilidad) and distHorizontal <= 18 then
			registro.Humanoid:MoveTo(posObjetivo)
		else
			registro.Humanoid:MoveTo(posZombi)
		end
	end
end

function ZombieAI.Iniciar(sesionId: number)
	if _activo and _sesionIdActiva == sesionId then
		return
	end
	ZombieAI.Detener()

	_activo = true
	_sesionIdActiva = sesionId
	table.clear(_ultimoDanioJugador)

	_bucleThread = task.spawn(function()
		while _activo and HordeSession.EsSesionActiva(sesionId) do
			local ahora = os.clock()
			local presupuestoRutas = { Restantes = 4 } -- Máx. 4 cómputos PathfindingService por tick
			local paramsVisibilidad = construirParamsVisibilidad()

			for _, registro in pairs(ZombieService.ObtenerZombisActivos()) do
				actualizarZombiIndividual(registro, ahora, presupuestoRutas, paramsVisibilidad)
			end

			task.wait(0.1)
		end
	end)
end

function ZombieAI.Detener()
	_activo = false
	_sesionIdActiva = 0
	table.clear(_ultimoDanioJugador)
	if _bucleThread then
		local h = _bucleThread
		_bucleThread = nil
		if coroutine.running() ~= h then
			pcall(task.cancel, h)
		end
	end
end

return ZombieAI
