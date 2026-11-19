--!strict
--[[
	HordeSession.luau
	Máquina de estados centralizada, identificador de sesión monotónico
	y registro estricto de participantes cooperativos de la horda.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Datos = require(ReplicatedStorage.Shared.Datos)
local GestorDatos = require(script.Parent.Parent.GestorDatos)

local ConfigZombis = Datos.Zombis
local General = ConfigZombis.General

export type EstadoHorda =
	"Inactiva"
	| "Preparando"
	| "CuentaRegresiva"
	| "EnCurso"
	| "OleadaCompletada"
	| "Finalizando"

export type RolJugador = "Participante" | "Eliminado" | "Espectador"

export type RegistroParticipante = {
	Jugador: Player,
	Vivo: boolean,
	Eliminado: boolean,
	Bajas: number,
	OleadasSobrevividas: number,
	PesosGanados: number,
	FamaGanada: number,
	Conexiones: { RBXScriptConnection },
}

export type ResumenFinalJugador = {
	Bajas: number,
	OleadasSobrevividas: number,
	PesosGanados: number,
	FamaGanada: number,
	Rol: RolJugador,
}

local TRANSICIONES_VALIDAS: { [EstadoHorda]: { [EstadoHorda]: boolean } } = {
	Inactiva = { Preparando = true },
	Preparando = { CuentaRegresiva = true, Finalizando = true },
	CuentaRegresiva = { EnCurso = true, Finalizando = true },
	EnCurso = { OleadaCompletada = true, Finalizando = true },
	OleadaCompletada = { EnCurso = true, Finalizando = true },
	Finalizando = { Inactiva = true },
}

local HordeSession = {}

local _estado: EstadoHorda = "Inactiva"
local _sesionId = 0
local _participantes: { [Player]: RegistroParticipante } = {}
local _inicializado = false

local _onParticipantesCambiados: (() -> ())? = nil
local _onEstadoCambiado: ((EstadoHorda) -> ())? = nil

local function jugadorEstaVivo(player: Player): boolean
	if not player:IsDescendantOf(Players) then
		return false
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	return hrp ~= nil and hrp:IsA("BasePart") and hum ~= nil and hum.Health > 0
end

local function limpiarEfectosTemporalesJugador(player: Player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") and item:GetAttribute("EsArmaHorda") == true then
				item:Destroy()
			end
		end
	end

	local char = player.Character
	if not char then
		return
	end

	for _, item in ipairs(char:GetChildren()) do
		if item:IsA("Tool") and item:GetAttribute("EsArmaHorda") == true then
			item:Destroy()
		end
	end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then
		for _, nombreEfecto in ipairs({
			"QuemaduraFuegoZombi",
			"CongelamientoHieloZombi",
			"VenenoToxicoZombi",
		}) do
			local ef = hrp:FindFirstChild(nombreEfecto)
			if ef then
				ef:Destroy()
			end
		end
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum and hum:GetAttribute("RalentizadoPorHielo") then
		local velOrig = hum:GetAttribute("VelocidadOriginalHielo")
		hum:SetAttribute("RalentizadoPorHielo", nil)
		hum:SetAttribute("VelocidadOriginalHielo", nil)
		if typeof(velOrig) == "number" and hum.Health > 0 then
			hum.WalkSpeed = velOrig
		end
	end
end

local function desconectarRegistro(reg: RegistroParticipante)
	for _, conn in ipairs(reg.Conexiones) do
		if conn.Connected then
			conn:Disconnect()
		end
	end
	table.clear(reg.Conexiones)
end

local function emitirCambioEstado(nuevo: EstadoHorda)
	if _onEstadoCambiado then
		task.spawn(_onEstadoCambiado, nuevo)
	end
end

local function emitirCambioParticipantes()
	if _onParticipantesCambiados then
		task.spawn(_onParticipantesCambiados)
	end
end

function HordeSession.EstablecerCallbackParticipantes(cb: (() -> ())?)
	_onParticipantesCambiados = cb
end

function HordeSession.EstablecerCallbackEstado(cb: ((EstadoHorda) -> ())?)
	_onEstadoCambiado = cb
end

function HordeSession.Inicializar()
	if _inicializado then
		return
	end
	_inicializado = true

	Players.PlayerRemoving:Connect(function(player: Player)
		local reg = _participantes[player]
		if not reg then
			return
		end
		desconectarRegistro(reg)
		_participantes[player] = nil
		if HordeSession.EstaActiva() then
			emitirCambioParticipantes()
		end
	end)
end

function HordeSession.ObtenerSesionId(): number
	return _sesionId
end

function HordeSession.EsSesionActiva(sesionId: number): boolean
	return sesionId > 0
		and sesionId == _sesionId
		and _estado ~= "Inactiva"
		and _estado ~= "Finalizando"
end

function HordeSession.ObtenerEstado(): EstadoHorda
	return _estado
end

function HordeSession.EstaActiva(): boolean
	return _estado ~= "Inactiva"
end

function HordeSession.TransicionarEstado(nuevoEstado: EstadoHorda): boolean
	if _estado == nuevoEstado then
		return true
	end
	local permitidas = TRANSICIONES_VALIDAS[_estado]
	if not permitidas or not permitidas[nuevoEstado] then
		warn(
			string.format(
				"[HordeSession] Transición inválida rechazada: %s -> %s",
				_estado,
				nuevoEstado
			)
		)
		return false
	end
	_estado = nuevoEstado
	emitirCambioEstado(nuevoEstado)
	return true
end

function HordeSession.IniciarSesion(_iniciador: Player): (boolean, number, string?)
	if _estado ~= "Inactiva" then
		return false, 0, "Ya hay una horda activa en este momento."
	end

	if not HordeSession.TransicionarEstado("Preparando") then
		return false, 0, "No se pudo preparar la sesión de horda."
	end

	-- Limpiar cualquier residuo defensivo antes de capturar participantes
	for _, regViejo in pairs(_participantes) do
		desconectarRegistro(regViejo)
	end
	table.clear(_participantes)

	local vivos: { Player } = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if jugadorEstaVivo(p) then
			table.insert(vivos, p)
		end
	end

	if #vivos == 0 then
		_estado = "Finalizando"
		_estado = "Inactiva"
		emitirCambioEstado("Inactiva")
		return false, 0, "No hay jugadores vivos para iniciar la horda."
	end

	_sesionId += 1
	local sesionActual = _sesionId

	for _, p in ipairs(vivos) do
		local reg: RegistroParticipante = {
			Jugador = p,
			Vivo = true,
			Eliminado = false,
			Bajas = 0,
			OleadasSobrevividas = 0,
			PesosGanados = 0,
			FamaGanada = 0,
			Conexiones = {},
		}

		local char = p.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			table.insert(
				reg.Conexiones,
				hum.Died:Connect(function()
					if _sesionId ~= sesionActual then
						return
					end
					if not reg.Eliminado then
						reg.Vivo = false
						reg.Eliminado = true
						limpiarEfectosTemporalesJugador(p)
						emitirCambioParticipantes()
					end
				end)
			)
		end

		-- Asegurar que el estado vivo refleje muerte aunque desaparezca su Character
		table.insert(
			reg.Conexiones,
			p.CharacterRemoving:Connect(function()
				if _sesionId ~= sesionActual then
					return
				end
				if not reg.Eliminado then
					reg.Vivo = false
					reg.Eliminado = true
					limpiarEfectosTemporalesJugador(p)
					emitirCambioParticipantes()
				end
			end)
		)

		_participantes[p] = reg
	end

	return true, sesionActual, nil
end

function HordeSession.FinalizarSesion(_motivo: string): { [Player]: ResumenFinalJugador }?
	if _estado == "Inactiva" or _estado == "Finalizando" then
		return nil
	end

	_estado = "Finalizando"
	emitirCambioEstado("Finalizando")

	local resumenes: { [Player]: ResumenFinalJugador } = {}

	-- Recompensa final por supervivencia y limpieza de participantes válidos
	for player, reg in pairs(_participantes) do
		if player:IsDescendantOf(Players) then
			if reg.OleadasSobrevividas > 0 then
				local premioPesos = reg.OleadasSobrevividas
					* (General.BonoSupervivenciaPesosPorOleada or 15)
				local premioFama = reg.OleadasSobrevividas
					* (General.BonoSupervivenciaFamaPorOleada or 1)
				if GestorDatos.AgregarPesos(player, premioPesos) then
					reg.PesosGanados += premioPesos
				end
				if GestorDatos.AgregarFama(player, premioFama) then
					reg.FamaGanada += premioFama
				end
			end

			resumenes[player] = {
				Bajas = reg.Bajas,
				OleadasSobrevividas = reg.OleadasSobrevividas,
				PesosGanados = reg.PesosGanados,
				FamaGanada = reg.FamaGanada,
				Rol = if reg.Eliminado then "Eliminado" else "Participante",
			}
			limpiarEfectosTemporalesJugador(player)
		end
		desconectarRegistro(reg)
	end

	table.clear(_participantes)
	_sesionId += 1
	_estado = "Inactiva"
	emitirCambioEstado("Inactiva")

	return resumenes
end

function HordeSession.EsParticipante(player: Player?): boolean
	if not player then
		return false
	end
	return _participantes[player] ~= nil
end

function HordeSession.EsParticipanteVivo(player: Player?): boolean
	if not player then
		return false
	end
	local reg = _participantes[player]
	if not reg or reg.Eliminado or not reg.Vivo then
		return false
	end
	return jugadorEstaVivo(player)
end

function HordeSession.ObtenerParticipantes(): { Player }
	local lista: { Player } = {}
	for player, _ in pairs(_participantes) do
		if player:IsDescendantOf(Players) then
			table.insert(lista, player)
		end
	end
	return lista
end

function HordeSession.ObtenerParticipantesVivos(): { Player }
	local lista: { Player } = {}
	for player, _ in pairs(_participantes) do
		if HordeSession.EsParticipanteVivo(player) then
			table.insert(lista, player)
		end
	end
	return lista
end

function HordeSession.ContarParticipantesVivos(): number
	return #HordeSession.ObtenerParticipantesVivos()
end

function HordeSession.ContarParticipantesTotales(): number
	local total = 0
	for player, _ in pairs(_participantes) do
		if player:IsDescendantOf(Players) then
			total += 1
		end
	end
	return total
end

function HordeSession.ObtenerRolJugador(player: Player): RolJugador
	local reg = _participantes[player]
	if not reg then
		return "Espectador"
	end
	if reg.Eliminado or not reg.Vivo then
		return "Eliminado"
	end
	return "Participante"
end

function HordeSession.RegistrarBaja(player: Player, pesos: number, fama: number)
	local reg = _participantes[player]
	if not reg then
		return
	end
	reg.Bajas += 1
	reg.PesosGanados += pesos
	reg.FamaGanada += fama
end

function HordeSession.RegistrarOleadaCompletada(player: Player, pesos: number, fama: number)
	local reg = _participantes[player]
	if not reg or reg.Eliminado then
		return
	end
	reg.OleadasSobrevividas += 1
	reg.PesosGanados += pesos
	reg.FamaGanada += fama
end

return HordeSession
