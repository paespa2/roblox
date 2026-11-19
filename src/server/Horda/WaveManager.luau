--!strict
--[[
	WaveManager.luau
	Administra el ciclo de oleadas progresivas, validación de sesión/participantes,
	generación inteligente con límite de fallos y recompensas en el servidor.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Datos = require(ReplicatedStorage.Shared.Datos)
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)
local GestorDatos = require(script.Parent.Parent.GestorDatos)
local HordeSession = require(script.Parent.HordeSession)
local UtilidadesMapaHorda = require(script.Parent.UtilidadesMapaHorda)
local ZombieService = require(script.Parent.ZombieService)
local ZombieAI = require(script.Parent.ZombieAI)

local ConfigZombis = Datos.Zombis
local General = ConfigZombis.General

local WaveManager = {}

local _oleadaActual = 0
local _zombisPorGenerar = 0
local _totalOleadaActual = 0
local _hiloCiclo: thread? = nil

local function asegurarMunicionInicialParticipantes()
	local minMunicion = General.MunicionMinimaAlIniciar or 25
	for _, player in ipairs(HordeSession.ObtenerParticipantesVivos()) do
		local datos = GestorDatos.ObtenerDatos(player)
		if datos then
			local gomitas = datos.Inventario["Dulce_Gomita"] or 0
			local bombones = datos.Inventario["Dulce_Bombon"] or 0
			local total = gomitas + bombones
			if total < minMunicion then
				GestorDatos.AgregarDulce(player, "Dulce_Gomita", minMunicion - total)
			end
		end
	end
end

local function entregarArmasRonda(numeroOleada: number)
	local ServerStorage = game:GetService("ServerStorage")
	local armasFolder = ServerStorage:FindFirstChild("ArmasHorda")
	if not armasFolder then
		warn("[WaveManager] Carpeta ServerStorage.ArmasHorda no encontrada")
		return
	end

	local participantes = HordeSession.ObtenerParticipantesVivos()
	for _, player in ipairs(participantes) do
		local backpack = player:FindFirstChildOfClass("Backpack")
		local char = player.Character
		if backpack and char then
			for rondaTier, configDesbloqueo in pairs(ConfigZombis.ArmasPorOleada) do
				if numeroOleada >= rondaTier then
					for _, nombreArma in ipairs(configDesbloqueo.Armas) do
						local yaTiene = (backpack:FindFirstChild(nombreArma) ~= nil)
							or (char:FindFirstChild(nombreArma) ~= nil)

						if not yaTiene then
							local plantilla = armasFolder:FindFirstChild(nombreArma)
							if plantilla and plantilla:IsA("Tool") then
								local nuevaArma = plantilla:Clone()
								nuevaArma:SetAttribute("EsArmaHorda", true)
								nuevaArma:SetAttribute("RondaDesbloqueo", rondaTier)
								nuevaArma.CanBeDropped = false
								nuevaArma.Parent = backpack
								print(
									string.format(
										"[WaveManager] Arma '%s' entregada a %s (Ronda %d / Tier %d)",
										nombreArma,
										player.Name,
										numeroOleada,
										rondaTier
									)
								)
							end
						end
					end
				end
			end
		end
	end
end

local function retirarArmasHorda(player: Player)
	local function limpiar(contenedor: Instance?)
		if not contenedor then
			return
		end
		for _, item in ipairs(contenedor:GetChildren()) do
			if item:IsA("Tool") then
				if
					item:GetAttribute("EsArmaHorda") == true
					or table.find(ConfigZombis.NombresArmasHorda, item.Name)
				then
					item:Destroy()
				end
			end
		end
	end

	limpiar(player:FindFirstChildOfClass("Backpack"))
	limpiar(player.Character)
end

function WaveManager.ConstruirPayloadParaJugador(
	player: Player,
	mensaje: string?,
	tiempoRestante: number?,
	resumenFinal: HordeSession.ResumenFinalJugador?
): { [string]: any }
	local estado = HordeSession.ObtenerEstado()
	local vivos = ZombieService.ContarZombisVivos()
	local restantes = vivos + _zombisPorGenerar
	local rol = HordeSession.ObtenerRolJugador(player)

	return {
		Estado = estado,
		Oleada = _oleadaActual,
		ZombisRestantes = restantes,
		TotalOleada = _totalOleadaActual,
		Mensaje = mensaje or "",
		TiempoRestante = tiempoRestante or 0,
		EsParticipante = rol ~= "Espectador",
		Rol = rol,
		ParticipantesVivos = HordeSession.ContarParticipantesVivos(),
		TotalParticipantes = HordeSession.ContarParticipantesTotales(),
		ResumenFinal = resumenFinal,
	}
end

local function notificarATodos(
	mensaje: string?,
	tiempoRestante: number?,
	resumenesPorJugador: { [Player]: HordeSession.ResumenFinalJugador }?
)
	for _, player in ipairs(Players:GetPlayers()) do
		local resumen = resumenesPorJugador and resumenesPorJugador[player] or nil
		local payload = WaveManager.ConstruirPayloadParaJugador(player, mensaje, tiempoRestante, resumen)
		EventosRemotos.EstadoHordaActualizado:FireClient(player, payload)
	end
end

local function obtenerInfoParticipantesSpawn(): { UtilidadesMapaHorda.InfoParticipanteSpawn }
	local lista: { UtilidadesMapaHorda.InfoParticipanteSpawn } = {}
	for _, player in ipairs(HordeSession.ObtenerParticipantesVivos()) do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp and hrp:IsA("BasePart") then
			table.insert(lista, {
				Posicion = hrp.Position,
				LookVector = hrp.CFrame.LookVector,
			})
		end
	end
	return lista
end

local function obtenerPosicionesZombisActivos(): { Vector3 }
	local posList: { Vector3 } = {}
	for _, reg in pairs(ZombieService.ObtenerZombisActivos()) do
		if not reg.Muerto and reg.HRP.Parent then
			table.insert(posList, reg.HRP.Position)
		end
	end
	return posList
end

local function elegirVarianteForzada(numeroOleada: number, restantesPorGenerar: number, total: number): any?
	if numeroOleada >= 10 and restantesPorGenerar == math.max(1, total - 2) then
		for _, v in ipairs(ConfigZombis.Variantes) do
			if v.Id == "ZombiToxico" then
				return v
			end
		end
	elseif numeroOleada >= 6 and restantesPorGenerar == math.max(1, total - 1) then
		for _, v in ipairs(ConfigZombis.Variantes) do
			if v.Id == "ZombiHielo" then
				return v
			end
		end
	elseif numeroOleada >= 3 and restantesPorGenerar == total then
		for _, v in ipairs(ConfigZombis.Variantes) do
			if v.Id == "ZombiLava" then
				return v
			end
		end
	end
	return nil
end

local function seleccionarPuntoAlcanzable(
	candidatos: { Vector3 },
	participantesInfo: { UtilidadesMapaHorda.InfoParticipanteSpawn }
): Vector3?
	if #candidatos == 0 then
		return nil
	end
	if #participantesInfo == 0 then
		return candidatos[1]
	end

	local maxPruebas = math.min(3, #candidatos)
	for idx = 1, maxPruebas do
		local cand = candidatos[idx]
		local mejorDest = participantesInfo[1].Posicion
		local mejorDist = (mejorDest - cand).Magnitude
		for k = 2, #participantesInfo do
			local d = (participantesInfo[k].Posicion - cand).Magnitude
			if d < mejorDist then
				mejorDist = d
				mejorDest = participantesInfo[k].Posicion
			end
		end
		if UtilidadesMapaHorda.ValidarRutaAlcanzable(cand, mejorDest) then
			return cand
		end
	end

	-- Si los candidatos de Pathfinding fallan en zona abierta sin NavMesh completo, usar el mejor candidato espacial
	return candidatos[1]
end

local function ejecutarOleada(numeroOleada: number, sesionId: number)
	if not HordeSession.EsSesionActiva(sesionId) then
		return
	end
	if not HordeSession.TransicionarEstado("EnCurso") then
		return
	end

	_oleadaActual = numeroOleada
	local configOleada = ConfigZombis.ObtenerConfigOleada(numeroOleada)
	_zombisPorGenerar = configOleada.Cantidad
	_totalOleadaActual = configOleada.Cantidad

	-- Entregar arsenal correspondiente a la ronda actual
	entregarArmasRonda(numeroOleada)

	local mensajeInicio = string.format("OLEADA %d", numeroOleada)
	local cfgArmas = ConfigZombis.ArmasPorOleada[numeroOleada]
	if cfgArmas and cfgArmas.Mensaje then
		mensajeInicio = cfgArmas.Mensaje
	end

	notificarATodos(mensajeInicio, 0)
	print(
		string.format(
			"[WaveManager] Sesión #%d | Iniciando Oleada %d | Zombis: %d | Velocidad: %.1f (%s)",
			sesionId,
			numeroOleada,
			configOleada.Cantidad,
			configOleada.VelocidadBase,
			configOleada.EtiquetaVelocidad
		)
	)

	local fallosConsecutivos = 0
	local maxFallos = General.MaxReintentosSpawn or 12

	while _zombisPorGenerar > 0 and HordeSession.EsSesionActiva(sesionId) do
		if HordeSession.ContarParticipantesVivos() == 0 then
			WaveManager.DetenerHorda("Todos los participantes han caído")
			return
		end

		local vivosAhora = ZombieService.ContarZombisVivos()
		if vivosAhora < General.MaxZombisSimultaneos then
			local participantesInfo = obtenerInfoParticipantesSpawn()
			local posicionesZombis = obtenerPosicionesZombisActivos()
			local candidatos = UtilidadesMapaHorda.ObtenerPuntosAparicionZombis(
				ConfigZombis.PuntosAparicionRespaldo,
				participantesInfo,
				posicionesZombis,
				General.DistanciaMinSpawnJugador,
				General.DistanciaMaxSpawnJugador,
				General.DistanciaMinEntreZombis or 5.5
			)

			local posSpawn = seleccionarPuntoAlcanzable(candidatos, participantesInfo)
			if posSpawn then
				local varForzada = elegirVarianteForzada(numeroOleada, _zombisPorGenerar, configOleada.Cantidad)
				local creado = ZombieService.GenerarZombi(posSpawn, numeroOleada, configOleada, sesionId, varForzada)
				if creado then
					_zombisPorGenerar -= 1
					fallosConsecutivos = 0
					notificarATodos("", 0)
				else
					fallosConsecutivos += 1
				end
			else
				fallosConsecutivos += 1
				if fallosConsecutivos >= maxFallos then
					warn("[WaveManager] No se encontraron puntos de aparición válidos tras reintentos; finalizando horda.")
					WaveManager.DetenerHorda("No se encontraron zonas válidas de aparición")
					return
				end
			end
		end

		task.wait(General.IntervaloSpawnSegundos)
	end

	-- Esperar hasta que TODOS los zombis de esta oleada mueran y no queden pendientes
	while HordeSession.EsSesionActiva(sesionId) and HordeSession.ObtenerEstado() == "EnCurso" do
		if HordeSession.ContarParticipantesVivos() == 0 then
			WaveManager.DetenerHorda("Todos los participantes han caído")
			return
		end

		local vivos = ZombieService.ContarZombisVivos()
		if vivos == 0 and _zombisPorGenerar == 0 then
			break
		end
		task.wait(0.35)
	end

	if not HordeSession.EsSesionActiva(sesionId) or HordeSession.ObtenerEstado() ~= "EnCurso" then
		return
	end

	if not HordeSession.TransicionarEstado("OleadaCompletada") then
		return
	end

	notificarATodos("TODOS LOS ENEMIGOS ELIMINADOS", General.TiempoEntreOleadas)

	-- Recompensa únicamente a participantes vivos de la sesión mediante GestorDatos
	local bonoPesos = (General.BonoOleadaBasePesos or 30)
		+ (numeroOleada * (General.BonoOleadaExtraPesos or 15))
	local bonoFama = General.BonoOleadaFama or 2
	local municionExtra = General.MunicionPorOleadaCompletada or 8

	for _, player in ipairs(HordeSession.ObtenerParticipantesVivos()) do
		GestorDatos.AgregarPesos(player, bonoPesos)
		GestorDatos.AgregarFama(player, bonoFama)
		GestorDatos.AgregarDulce(player, "Dulce_Gomita", municionExtra)
		HordeSession.RegistrarOleadaCompletada(player, bonoPesos, bonoFama)
	end

	task.wait(1.8)
	if not HordeSession.EsSesionActiva(sesionId) or HordeSession.ObtenerEstado() ~= "OleadaCompletada" then
		return
	end

	local descanso = math.max(1, General.TiempoEntreOleadas - 2)
	for seg = descanso, 1, -1 do
		if not HordeSession.EsSesionActiva(sesionId) or HordeSession.ObtenerEstado() ~= "OleadaCompletada" then
			return
		end
		notificarATodos("OLEADA COMPLETADA", seg)
		task.wait(1)
	end
end

function WaveManager.RetirarArmasHorda(player: Player)
	retirarArmasHorda(player)
end

function WaveManager.EstaActiva(): boolean
	return HordeSession.EstaActiva()
end

function WaveManager.ObtenerEstado(): HordeSession.EstadoHorda
	return HordeSession.ObtenerEstado()
end

function WaveManager.ObtenerOleadaActual(): number
	return _oleadaActual
end

function WaveManager.IniciarHorda(iniciador: Player): (boolean, string?)
	local ok, sesionId, msgError = HordeSession.IniciarSesion(iniciador)
	if not ok then
		return false, msgError
	end

	_oleadaActual = 0
	_zombisPorGenerar = 0
	_totalOleadaActual = 0

	asegurarMunicionInicialParticipantes()
	if not HordeSession.TransicionarEstado("CuentaRegresiva") then
		WaveManager.DetenerHorda("Error en transición de inicio")
		return false, "No se pudo iniciar la cuenta regresiva."
	end

	ZombieAI.Iniciar(sesionId)

	_hiloCiclo = task.spawn(function()
		for seg = General.CuentaRegresivaInicial, 1, -1 do
			if not HordeSession.EsSesionActiva(sesionId) or HordeSession.ObtenerEstado() ~= "CuentaRegresiva" then
				return
			end
			if HordeSession.ContarParticipantesVivos() == 0 then
				WaveManager.DetenerHorda("Todos los participantes han caído")
				return
			end
			notificarATodos("LA HORDA SE ACERCA...", seg)
			task.wait(1)
		end

		local numeroOleada = 1
		while HordeSession.EsSesionActiva(sesionId) do
			ejecutarOleada(numeroOleada, sesionId)
			if not HordeSession.EsSesionActiva(sesionId) or HordeSession.ObtenerEstado() ~= "OleadaCompletada" then
				break
			end
			numeroOleada += 1
		end
	end)

	return true, nil
end

function WaveManager.DetenerHorda(motivo: string?)
	local estadoActual = HordeSession.ObtenerEstado()
	if estadoActual == "Inactiva" or estadoActual == "Finalizando" then
		return
	end

	_zombisPorGenerar = 0
	_totalOleadaActual = 0

	if _hiloCiclo and coroutine.running() ~= _hiloCiclo and coroutine.status(_hiloCiclo) ~= "dead" then
		task.cancel(_hiloCiclo)
	end
	_hiloCiclo = nil

	ZombieAI.Detener()
	ZombieService.LimpiarTodosZombis()

	-- Retirar todas las armas temporales de horda de todos los jugadores
	for _, player in ipairs(Players:GetPlayers()) do
		retirarArmasHorda(player)
	end

	local resumenes = HordeSession.FinalizarSesion(motivo or "Horda finalizada")
	_oleadaActual = 0

	notificarATodos(motivo or "Horda finalizada", 0, resumenes)
	print("[WaveManager] Horda finalizada: " .. tostring(motivo or "Reset"))
end

function WaveManager.Inicializar()
	HordeSession.Inicializar()
	HordeSession.EstablecerCallbackParticipantes(function()
		if HordeSession.EstaActiva() and HordeSession.ObtenerEstado() ~= "Finalizando" then
			if HordeSession.ContarParticipantesVivos() == 0 then
				WaveManager.DetenerHorda("Todos los participantes han caído")
			else
				notificarATodos("", 0)
			end
		end
	end)

	ZombieService.EstablecerCallbackMuerte(function(_registro)
		if HordeSession.ObtenerEstado() == "EnCurso" then
			notificarATodos("", 0)
		end
	end)
end

return WaveManager
