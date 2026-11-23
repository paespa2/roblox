--!strict
--[[
	HordeSession.luau
	Máquina de estados centralizada, identificador de sesión monotónico
	y registro estricto de participantes cooperativos de la horda.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Datos = require(ReplicatedStorage.Shared.Datos)
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)
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
	Abatido: boolean,
	TiempoAbatidoFin: number,
	AutoReviviendo: boolean,
	Bajas: number,
	TirosCriticos: number,
	OleadasSobrevividas: number,
	PesosGanados: number,
	FamaGanada: number,
	PromptRevivir: ProximityPrompt?,
	BillboardRevivir: BillboardGui?,
	Conexiones: { RBXScriptConnection },
}

export type ResumenFinalJugador = {
	Bajas: number,
	TirosCriticos: number,
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

local function limpiarEstadoAbatido(player: Player, reg: RegistroParticipante)
	reg.Abatido = false
	reg.TiempoAbatidoFin = 0
	reg.AutoReviviendo = false
	if reg.PromptRevivir then
		pcall(function()
			reg.PromptRevivir:Destroy()
		end)
		reg.PromptRevivir = nil
	end
	if reg.BillboardRevivir then
		pcall(function()
			reg.BillboardRevivir:Destroy()
		end)
		reg.BillboardRevivir = nil
	end
	player:SetAttribute("HordaAbatido", nil)
	player:SetAttribute("HordaAbatidoFin", nil)

	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		pcall(function()
			hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
		end)
		if hum.Health > 0 then
			hum.WalkSpeed = if player:GetAttribute("PerkVelocidad") == true then 22 else 16
			hum.JumpPower = 50
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
	return typeof(sesionId) == "number" and sesionId > 0
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

	local function todosAbatidosOEliminados(): (boolean, { { Player: Player, Reg: RegistroParticipante } })
		local abatidos: { { Player: Player, Reg: RegistroParticipante } } = {}
		for pItem, rItem in pairs(_participantes) do
			if pItem:IsDescendantOf(Players) and not rItem.Eliminado and rItem.Vivo then
				if not rItem.Abatido then
					return false, abatidos
				end
				table.insert(abatidos, { Player = pItem, Reg = rItem })
			end
		end
		return #abatidos > 0, abatidos
	end

	local function empujarZombisCercanos(centro: Vector3)
		local carpeta = Workspace:FindFirstChild("HordaSistema")
		if not carpeta then
			return
		end
		for _, inst in ipairs(carpeta:GetDescendants()) do
			if inst:IsA("Model") and inst:GetAttribute("EsZombie") == true then
				local zHrp = inst:FindFirstChild("HumanoidRootPart")
				if zHrp and zHrp:IsA("BasePart") then
					local delta = zHrp.Position - centro
					if delta.Magnitude <= 18 and delta.Magnitude > 0.1 then
						zHrp.AssemblyLinearVelocity = delta.Unit * 45 + Vector3.new(0, 18, 0)
					end
				end
			end
		end
	end

	local function entrarEstadoAbatido(p: Player, reg: RegistroParticipante, hum: Humanoid)
		if reg.Abatido or reg.Eliminado or _sesionId ~= sesionActual then
			return
		end
		local duracion = General.DuracionAbatidoSegundos or 30
		reg.Abatido = true
		reg.TiempoAbatidoFin = os.clock() + duracion

		hum.Health = 20
		hum.WalkSpeed = 4
		hum.JumpPower = 0
		p:SetAttribute("HordaAbatido", true)
		p:SetAttribute("HordaAbatidoFin", reg.TiempoAbatidoFin)

		local char = p.Character
		local head = char and char:FindFirstChild("Head")
		local torsoOrHrp = (char and char:FindFirstChild("Torso")) or (char and char:FindFirstChild("HumanoidRootPart"))

		if head and head:IsA("BasePart") then
			local bbg = Instance.new("BillboardGui")
			bbg.Name = "RotuloAbatidoHorda"
			bbg.Size = UDim2.fromOffset(220, 46)
			bbg.StudsOffset = Vector3.new(0, 2.8, 0)
			bbg.AlwaysOnTop = true
			bbg.MaxDistance = 120
			bbg.Parent = head

			local marco = Instance.new("Frame")
			marco.Size = UDim2.fromScale(1, 1)
			marco.BackgroundColor3 = Color3.fromRGB(28, 10, 12)
			marco.BackgroundTransparency = 0.2
			marco.Parent = bbg

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 6)
			corner.Parent = marco

			local stroke = Instance.new("UIStroke")
			stroke.Color = Color3.fromRGB(255, 55, 65)
			stroke.Thickness = 2
			stroke.Parent = marco

			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.fromScale(1, 1)
			lbl.BackgroundTransparency = 1
			lbl.Font = Enum.Font.GothamBold
			lbl.Text = "➕ ABATIDO — MANTÉN [E] PARA REVIVIR"
			lbl.TextColor3 = Color3.fromRGB(255, 220, 220)
			lbl.TextScaled = true
			lbl.Parent = marco

			reg.BillboardRevivir = bbg
		end

		if torsoOrHrp and torsoOrHrp:IsA("BasePart") then
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "PromptRevivirHorda"
			prompt.ObjectText = p.Name
			prompt.ActionText = "Revivir Aliado (+$200)"
			prompt.KeyboardKeyCode = Enum.KeyCode.E
			prompt.HoldDuration = General.TiempoRevivirSegundos or 3.0
			prompt.MaxActivationDistance = 9
			prompt.RequiresLineOfSight = false
			prompt.Parent = torsoOrHrp
			reg.PromptRevivir = prompt

			prompt.Triggered:Connect(function(rescatador: Player)
				if _sesionId ~= sesionActual or not reg.Abatido or reg.Eliminado then
					return
				end
				if rescatador == p or not HordeSession.EsParticipanteVivo(rescatador) or HordeSession.EstaAbatido(rescatador) then
					return
				end

				limpiarEstadoAbatido(p, reg)
				pcall(function()
					hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
				end)
				hum.Health = hum.MaxHealth

				local doble = if Workspace:GetAttribute("LazarusPuntosDobles") == true then 2 else 1
				local pts = (General.PuntosPorRevivir or 200) * doble
				GestorDatos.AgregarPesos(rescatador, pts)
				rescatador:SetAttribute(
					"PuntosLazarusAcumulados",
					(tonumber(rescatador:GetAttribute("PuntosLazarusAcumulados")) or 0) + pts
				)
				for _, part in ipairs(Players:GetPlayers()) do
					EventosRemotos.Notificacion:FireClient(
						part,
						"➕ ¡ALIADO REANIMADO!",
						string.format("%s revivió a %s (+$%d Pesos).", rescatador.Name, p.Name, pts)
					)
				end
				emitirCambioParticipantes()
			end)
		end

		emitirCambioParticipantes()

		-- Verificar si todo el equipo cayó
		local todosCaidos, listaAbatidos = todosAbatidosOEliminados()
		if todosCaidos then
			local hayAutoRevivir = false
			for _, item in ipairs(listaAbatidos) do
				if item.Player:GetAttribute("PerkRegeneracion") == true then
					hayAutoRevivir = true
					if not item.Reg.AutoReviviendo then
						item.Reg.AutoReviviendo = true
						local pAuto = item.Player
						local rAuto = item.Reg
						EventosRemotos.Notificacion:FireClient(
							pAuto,
							"⚡ ¡ELIXIR REGENERADOR!",
							"Auto-reanimación activada... ¡Aguanta 3.5 segundos!"
						)
						task.delay(3.5, function()
							if _sesionId ~= sesionActual or not rAuto.Abatido or rAuto.Eliminado then
								return
							end
							if pAuto:GetAttribute("PerkRegeneracion") ~= true then
								return
							end
							pAuto:SetAttribute("PerkRegeneracion", false)
							limpiarEstadoAbatido(pAuto, rAuto)
							local cAuto = pAuto.Character
							local hAuto = cAuto and cAuto:FindFirstChildOfClass("Humanoid")
							local hrpAuto = cAuto and cAuto:FindFirstChild("HumanoidRootPart")
							if hAuto then
								pcall(function()
									hAuto:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
								end)
								hAuto.Health = hAuto.MaxHealth
							end
							if hrpAuto and hrpAuto:IsA("BasePart") then
								empujarZombisCercanos(hrpAuto.Position)
							end
							EventosRemotos.Notificacion:FireClient(
								pAuto,
								"⚡ ¡AUTO-REANIMACIÓN ACTIVADA!",
								"Volviste al combate y empujaste a la horda."
							)
							emitirCambioParticipantes()
						end)
					end
				end
			end

			if not hayAutoRevivir then
				for _, item in ipairs(listaAbatidos) do
					local rElim = item.Reg
					local pElim = item.Player
					rElim.Eliminado = true
					rElim.Vivo = false
					limpiarEstadoAbatido(pElim, rElim)
					local cElim = pElim.Character
					local hElim = cElim and cElim:FindFirstChildOfClass("Humanoid")
					if hElim then
						hElim.Health = 0
					end
				end
				emitirCambioParticipantes()
				return
			end
		end

		-- Temporizador de desangrado
		task.delay(duracion + 0.1, function()
			if _sesionId ~= sesionActual or not reg.Abatido or reg.Eliminado then
				return
			end
			reg.Eliminado = true
			reg.Vivo = false
			limpiarEstadoAbatido(p, reg)
			hum.Health = 0
			emitirCambioParticipantes()
		end)
	end

	for _, p in ipairs(vivos) do
		p:SetAttribute("HordaCriticos", 0)
		p:SetAttribute("PuntosLazarusAcumulados", 0)
		p:SetAttribute("HordaAbatido", nil)
		p:SetAttribute("HordaAbatidoFin", nil)

		local reg: RegistroParticipante = {
			Jugador = p,
			Vivo = true,
			Eliminado = false,
			Abatido = false,
			TiempoAbatidoFin = 0,
			AutoReviviendo = false,
			Bajas = 0,
			TirosCriticos = 0,
			OleadasSobrevividas = 0,
			PesosGanados = 0,
			FamaGanada = 0,
			PromptRevivir = nil,
			BillboardRevivir = nil,
			Conexiones = {},
		}

		local char = p.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			pcall(function()
				hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
			end)

			table.insert(
				reg.Conexiones,
				hum.HealthChanged:Connect(function(nuevaVida: number)
					if _sesionId ~= sesionActual or reg.Eliminado then
						return
					end
					if reg.Abatido then
						if nuevaVida < 20 then
							hum.Health = 20
						end
						return
					end
					if nuevaVida <= 1 then
						entrarEstadoAbatido(p, reg, hum)
					end
				end)
			)

			table.insert(
				reg.Conexiones,
				hum.Died:Connect(function()
					if _sesionId ~= sesionActual then
						return
					end
					if not reg.Eliminado then
						reg.Vivo = false
						reg.Eliminado = true
						limpiarEstadoAbatido(p, reg)
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
					limpiarEstadoAbatido(p, reg)
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
				TirosCriticos = reg.TirosCriticos,
				OleadasSobrevividas = reg.OleadasSobrevividas,
				PesosGanados = reg.PesosGanados,
				FamaGanada = reg.FamaGanada,
				Rol = if reg.Eliminado then "Eliminado" else "Participante",
			}
			limpiarEstadoAbatido(player, reg)
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

function HordeSession.EstaAbatido(player: Player?): boolean
	if not player then
		return false
	end
	local reg = _participantes[player]
	return reg ~= nil and reg.Abatido and not reg.Eliminado
end

function HordeSession.ContarAbatidos(): number
	local total = 0
	for player, reg in pairs(_participantes) do
		if player:IsDescendantOf(Players) and reg.Abatido and not reg.Eliminado then
			total += 1
		end
	end
	return total
end

function HordeSession.RegistrarBaja(player: Player, pesos: number, fama: number, esCritico: boolean?)
	local reg = _participantes[player]
	if not reg then
		return
	end
	reg.Bajas += 1
	if esCritico then
		reg.TirosCriticos += 1
	end
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
