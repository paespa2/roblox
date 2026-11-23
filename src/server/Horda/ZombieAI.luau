--!strict
--[[
	ZombieAI.luau
	Máquina de estados finitos (FSM), Seguimiento Predictivo Estilo Pac-Man
	(Blinky, Pinky, Inky, Clyde) y Superador Proactivo de Desniveles/Superficies Planas
	para la Cuadrícula Urbana (Vías, Aceras, Lotes, Plantas Bajas y Terrazas Bajas).
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
local _ultimoSaltoEscalera: { [number]: number } = {}
local _ultimaDirMovimiento: { [number]: Vector3 } = {}

local ROLES_PACMAN = {
	[0] = "Blinky_Cazador",
	[1] = "Pinky_Emboscador",
	[2] = "Inky_Flanqueador",
	[3] = "Clyde_Interceptor",
}

local function obtenerRolPacMan(registro: RegistroZombi): string
	local rol = registro.Modelo:GetAttribute("RolPacMan")
	if typeof(rol) == "string" and rol ~= "" then
		return rol
	end
	local asignado = ROLES_PACMAN[registro.Id % 4] or "Blinky_Cazador"
	registro.Modelo:SetAttribute("RolPacMan", asignado)
	return asignado
end

local function actualizarEstadoModelo(registro: RegistroZombi, nuevoEstado: EstadoZombi)
	if registro.Estado ~= nuevoEstado then
		registro.Estado = nuevoEstado
		registro.Modelo:SetAttribute("EstadoIA", nuevoEstado)
	end
end

local function esJugadorValido(player: Player?): (boolean, BasePart?, Humanoid?)
	if not player or not HordeSession.EsParticipanteVivo(player) or HordeSession.EstaAbatido(player) then
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
	local peatones = Workspace:FindFirstChild("PeatonesCiudad")
	if peatones then
		table.insert(exclusiones, peatones)
	end
	local mapa = Workspace:FindFirstChild("Mapa")
	local vortice = mapa and mapa:FindFirstChild("TormentaVorticeDulce")
	if vortice then
		table.insert(exclusiones, vortice)
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			table.insert(exclusiones, p.Character)
		end
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = exclusiones
	params.IgnoreWater = true
	return params
end

local function tieneLineaVistaDirecta(
	origen: Vector3,
	destino: Vector3,
	params: RaycastParams
): boolean
	local pOrigenAlto = origen + Vector3.new(0, 1.3, 0)
	local pDestinoAlto = destino + Vector3.new(0, 1.3, 0)
	local dirAlto = pDestinoAlto - pOrigenAlto
	if dirAlto.Magnitude < 0.5 then
		return true
	end
	if Workspace:Raycast(pOrigenAlto, dirAlto, params) ~= nil then
		return false
	end

	local pOrigenCintura = origen - Vector3.new(0, 0.5, 0)
	local pDestinoCintura = destino - Vector3.new(0, 0.5, 0)
	local hitCintura = Workspace:Raycast(pOrigenCintura, pDestinoCintura - pOrigenCintura, params)
	return hitCintura == nil
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

local function ajustarPuntoPredictivoEnSuperficie(
	posJugador: Vector3,
	posCandidata: Vector3,
	params: RaycastParams
): Vector3
	local delta = Vector3.new(posCandidata.X - posJugador.X, 0, posCandidata.Z - posJugador.Z)
	local dist = delta.Magnitude
	local puntoFinalXZ = posCandidata

	if dist > 1.0 then
		local dir = delta.Unit
		local hitMuro = Workspace:Raycast(posJugador + Vector3.new(0, 1.5, 0), dir * dist, params)
		if hitMuro then
			local distSegura = math.max(0, (hitMuro.Position - (posJugador + Vector3.new(0, 1.5, 0))).Magnitude - 2.5)
			puntoFinalXZ = posJugador + dir * distSegura
		end
	end

	local hitSuelo = Workspace:Raycast(
		Vector3.new(puntoFinalXZ.X, posJugador.Y + 6.0, puntoFinalXZ.Z),
		Vector3.new(0, -18.0, 0),
		params
	)
	if hitSuelo and hitSuelo.Normal.Y > 0.65 then
		return Vector3.new(puntoFinalXZ.X, hitSuelo.Position.Y + 3.0, puntoFinalXZ.Z)
	end

	return Vector3.new(puntoFinalXZ.X, posJugador.Y, puntoFinalXZ.Z)
end

local function calcularObjetivoPredictivoPacMan(
	registro: RegistroZombi,
	targetHrp: BasePart,
	params: RaycastParams
): Vector3
	local posZombi = registro.HRP.Position
	local posJugador = targetHrp.Position
	local distH = Vector3.new(posJugador.X - posZombi.X, 0, posJugador.Z - posZombi.Z).Magnitude

	if distH <= 11.0 then
		return posJugador
	end

	local rol = obtenerRolPacMan(registro)
	local velRaw = targetHrp.AssemblyLinearVelocity
	local velH = Vector3.new(velRaw.X, 0, velRaw.Z)
	local rapidez = velH.Magnitude
	local dirMov = if rapidez > 1.5
		then velH.Unit
		else Vector3.new(targetHrp.CFrame.LookVector.X, 0, targetHrp.CFrame.LookVector.Z)
	if dirMov.Magnitude < 0.1 then
		dirMov = Vector3.new(0, 0, -1)
	else
		dirMov = dirMov.Unit
	end

	if rol == "Blinky_Cazador" then
		local anticipacion = posJugador + velH * 0.35
		return ajustarPuntoPredictivoEnSuperficie(posJugador, anticipacion, params)
	elseif rol == "Pinky_Emboscador" then
		local tiempoPred = math.clamp(distH / math.max(registro.VelocidadBase, 10), 0.8, 2.8)
		local avance = math.clamp(math.max(rapidez * tiempoPred, 14), 12, 42)
		local puntoEmboscada = posJugador + dirMov * avance
		return ajustarPuntoPredictivoEnSuperficie(posJugador, puntoEmboscada, params)
	elseif rol == "Inky_Flanqueador" then
		local signo = if (registro.Id % 8) < 4 then 1 else -1
		local anguloPinza = math.rad(42 * signo)
		local dirPinza = (CFrame.lookAt(Vector3.zero, dirMov) * CFrame.Angles(0, anguloPinza, 0)).LookVector
		local avancePinza = math.clamp(distH * 0.55, 10, 32)
		local puntoPinza = posJugador + dirPinza * avancePinza
		return ajustarPuntoPredictivoEnSuperficie(posJugador, puntoPinza, params)
	else
		if distH > 20 then
			local proyectado = posJugador + dirMov * math.clamp(distH * 0.6, 14, 36)
			local gridX = math.round(proyectado.X / 40) * 40
			local gridZ = math.round(proyectado.Z / 40) * 40
			local puntoEsquina = Vector3.new(
				proyectado.X * 0.45 + gridX * 0.55,
				posJugador.Y,
				proyectado.Z * 0.45 + gridZ * 0.55
			)
			return ajustarPuntoPredictivoEnSuperficie(posJugador, puntoEsquina, params)
		else
			return ajustarPuntoPredictivoEnSuperficie(posJugador, posJugador + velH * 0.4, params)
		end
	end
end

local function superarDesnivelSuperficiePlana(
	registro: RegistroZombi,
	destinoMovimiento: Vector3,
	ahora: number,
	params: RaycastParams
)
	local hrp = registro.HRP
	local posZombi = hrp.Position
	local dir = Vector3.new(destinoMovimiento.X - posZombi.X, 0, destinoMovimiento.Z - posZombi.Z)
	if dir.Magnitude < 0.2 then
		dir = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
	end
	if dir.Magnitude < 0.1 then
		return
	end
	dir = dir.Unit
	_ultimaDirMovimiento[registro.Id] = dir

	local hitPecho = Workspace:Raycast(posZombi + Vector3.new(0, 0.8, 0), dir * 3.6, params)
	if hitPecho and hitPecho.Normal.Y < 0.5 then
		return
	end
	local hitCintura = Workspace:Raycast(posZombi - Vector3.new(0, 0.6, 0), dir * 3.6, params)
	if hitCintura and hitCintura.Normal.Y < 0.5 then
		return
	end

	local hitPies = Workspace:Raycast(posZombi - Vector3.new(0, 2.65, 0), dir * 3.4, params)
	local hitTobillo = Workspace:Raycast(posZombi - Vector3.new(0, 1.95, 0), dir * 3.4, params)
	local hitEscalon = hitPies or hitTobillo

	local hitSueloActual = Workspace:Raycast(posZombi, Vector3.new(0, -5.0, 0), params)
	local hitSueloAdelante = Workspace:Raycast(
		posZombi + dir * 2.2 + Vector3.new(0, 1.8, 0),
		Vector3.new(0, -5.8, 0),
		params
	)

	local yActual = if hitSueloActual then hitSueloActual.Position.Y else (posZombi.Y - 3.0)
	local yAdelante = if hitSueloAdelante and hitSueloAdelante.Normal.Y > 0.7 then hitSueloAdelante.Position.Y else yActual
	local deltaY = yAdelante - yActual

	if (hitEscalon and deltaY >= 0.08 and deltaY <= 1.65) or (deltaY >= 0.14 and deltaY <= 1.65) then
		local elevacion = math.clamp(deltaY, 0.20, 1.50)
		local ultimoSalto = _ultimoSaltoEscalera[registro.Id] or 0

		if (ahora - ultimoSalto) >= 0.22 then
			_ultimoSaltoEscalera[registro.Id] = ahora
			local velActual = hrp.AssemblyLinearVelocity
			local velSubida = math.max(velActual.Y, math.clamp(10 + elevacion * 6, 11, 18))
			hrp.AssemblyLinearVelocity = Vector3.new(
				dir.X * registro.VelocidadBase,
				velSubida,
				dir.Z * registro.VelocidadBase
			)

			local velHoriz = Vector3.new(velActual.X, 0, velActual.Z).Magnitude
			if velHoriz < registro.VelocidadBase * 0.65 then
				local nuevaPos = Vector3.new(
					posZombi.X + dir.X * 0.55,
					yAdelante + 3.05,
					posZombi.Z + dir.Z * 0.55
				)
				hrp.CFrame = CFrame.lookAt(nuevaPos, nuevaPos + dir)
			end
		end
	end
end

local ANGULOS_CORREDOR = { 0, 40, -40, 85, -85, 130, -130, 180 }

local function elegirCorredorPacMan(
	registro: RegistroZombi,
	posZombi: Vector3,
	posDestinoPredictivo: Vector3,
	params: RaycastParams
): Vector3
	local dirObjetivo = Vector3.new(posDestinoPredictivo.X - posZombi.X, 0, posDestinoPredictivo.Z - posZombi.Z)
	if dirObjetivo.Magnitude < 0.2 then
		return posDestinoPredictivo
	end
	local baseDir = dirObjetivo.Unit
	local cfBase = CFrame.lookAt(Vector3.zero, baseDir)
	local dirAnterior = _ultimaDirMovimiento[registro.Id]

	local mejorPunto = posZombi + baseDir * 8
	local mejorCosto = math.huge

	for _, anguloDeg in ipairs(ANGULOS_CORREDOR) do
		local dirPrueba = (cfBase * CFrame.Angles(0, math.rad(anguloDeg), 0)).LookVector
		local hitMuroAlto = Workspace:Raycast(posZombi + Vector3.new(0, 1.2, 0), dirPrueba * 9.0, params)
		local hitCintura = Workspace:Raycast(posZombi - Vector3.new(0, 0.5, 0), dirPrueba * 9.0, params)
		if not hitMuroAlto and not hitCintura then
			local candidato = posZombi + dirPrueba * 8.5
			local distAlDestino = Vector3.new(
				posDestinoPredictivo.X - candidato.X,
				0,
				posDestinoPredictivo.Z - candidato.Z
			).Magnitude

			local penalizacionReversa = 0
			if dirAnterior and dirPrueba:Dot(dirAnterior) < -0.55 then
				penalizacionReversa = 18
			end

			local costo = distAlDestino + math.abs(anguloDeg) * 0.08 + penalizacionReversa
			if costo < mejorCosto then
				mejorCosto = costo
				mejorPunto = candidato
			end
		end
	end

	return mejorPunto
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
		AgentRadius = math.clamp(1.6 * escala, 1.4, 2.2),
		AgentHeight = math.max(5.0, 5.0 * escala),
		AgentCanJump = true,
		AgentCanClimb = true,
		WaypointSpacing = 4.0,
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

	if registro.Estado == "Stunned" then
		if ahora < registro.AturdidoHasta then
			return
		end
		registro.Humanoid.WalkSpeed = registro.VelocidadBase
		actualizarEstadoModelo(registro, "Detecting")
	end

	if registro.Estado == "Attacking" then
		if (ahora - registro.UltimoAtaque) < 0.50 then
			return
		end
		registro.Humanoid.WalkSpeed = registro.VelocidadBase
		actualizarEstadoModelo(registro, "Detecting")
	end

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
	local posObjetivoReal = targetHrp.Position
	local distHorizontal = ((posObjetivoReal - posZombi) * Vector3.new(1, 0, 1)).Magnitude

	if
		distHorizontal <= ConfigZombis.RangoAtaqueStuds
		and math.abs(posObjetivoReal.Y - posZombi.Y) <= 5.5
		and tieneLineaVistaDirecta(posZombi, posObjetivoReal, paramsVisibilidad)
	then
		ejecutarAtaqueZombi(registro, registro.ObjetivoActual)
		return
	end

	actualizarEstadoModelo(registro, "Chasing")
	registro.Humanoid.WalkSpeed = registro.VelocidadBase

	local destinoPredictivo = calcularObjetivoPredictivoPacMan(registro, targetHrp, paramsVisibilidad)

	if
		math.abs(destinoPredictivo.Y - posZombi.Y) <= 6.5
		and tieneLineaVistaDirecta(posZombi, destinoPredictivo, paramsVisibilidad)
	then
		superarDesnivelSuperficiePlana(registro, destinoPredictivo, ahora, paramsVisibilidad)
		orientarSuavementeHacia(registro.HRP, destinoPredictivo, 0.25)
		registro.Humanoid:MoveTo(destinoPredictivo)
		return
	end

	local necesitaRuta = registro.RutaBloqueada
		or not registro.WaypointsActuales
		or (registro.UltimaPosObjetivoRuta ~= nil and (destinoPredictivo - registro.UltimaPosObjetivoRuta).Magnitude > 7.5)
		or ((ahora - registro.UltimoRecalculoRuta) > 1.25)

	if (ahora - registro.UltimoChequeoAtasco) >= 0.9 then
		local desplazamiento = (posZombi - registro.UltimaPosComprobada).Magnitude
		registro.UltimaPosComprobada = posZombi
		registro.UltimoChequeoAtasco = ahora
		if desplazamiento < 1.1 then
			superarDesnivelSuperficiePlana(registro, destinoPredictivo, ahora, paramsVisibilidad)
			necesitaRuta = true
			registro.RutaBloqueada = true
		end
	end

	if
		necesitaRuta
		and (ahora - registro.UltimoRecalculoRuta) >= 0.45
		and presupuestoRutas.Restantes > 0
	then
		registro.UltimoRecalculoRuta = ahora
		presupuestoRutas.Restantes -= 1
		calcularRutaZombi(registro, destinoPredictivo)
	end

	local waypoints = registro.WaypointsActuales
	if waypoints and registro.IndiceWaypoint <= #waypoints then
		local wp = waypoints[registro.IndiceWaypoint]
		if wp.Action == Enum.PathWaypointAction.Jump then
			registro.Humanoid.Jump = true
		end

		local distWp = ((wp.Position - posZombi) * Vector3.new(1, 0, 1)).Magnitude
		if distWp < 3.4 and registro.IndiceWaypoint < #waypoints then
			registro.IndiceWaypoint += 1
			wp = waypoints[registro.IndiceWaypoint]
		end

		superarDesnivelSuperficiePlana(registro, wp.Position, ahora, paramsVisibilidad)
		orientarSuavementeHacia(registro.HRP, wp.Position, 0.22)
		registro.Humanoid:MoveTo(wp.Position)
	else
		local puntoCorredor = elegirCorredorPacMan(registro, posZombi, destinoPredictivo, paramsVisibilidad)
		superarDesnivelSuperficiePlana(registro, puntoCorredor, ahora, paramsVisibilidad)
		orientarSuavementeHacia(registro.HRP, puntoCorredor, 0.22)
		registro.Humanoid:MoveTo(puntoCorredor)
	end
end

ZombieAI.CalcularObjetivoPredictivoPacMan = calcularObjetivoPredictivoPacMan
ZombieAI.SuperarDesnivelSuperficiePlana = superarDesnivelSuperficiePlana

function ZombieAI.Iniciar(sesionId: number)
	if _activo and _sesionIdActiva == sesionId then
		return
	end
	ZombieAI.Detener()

	_activo = true
	_sesionIdActiva = sesionId
	table.clear(_ultimoDanioJugador)
	table.clear(_ultimoSaltoEscalera)
	table.clear(_ultimaDirMovimiento)

	_bucleThread = task.spawn(function()
		while _activo and HordeSession.EsSesionActiva(sesionId) do
			local ahora = os.clock()
			local presupuestoRutas = { Restantes = 5 }
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
	table.clear(_ultimoSaltoEscalera)
	table.clear(_ultimaDirMovimiento)
	if _bucleThread then
		local h = _bucleThread
		_bucleThread = nil
		if coroutine.running() ~= h then
			pcall(task.cancel, h)
		end
	end
end

return ZombieAI

