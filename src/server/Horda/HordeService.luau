--!strict
--[[
	HordeService.luau
	Coordina el NPC Dante cerca del spawn inicial, la validación de interacciones,
	el inicio seguro de eventos de horda y el ciclo general de supervivencia.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local StarterPack = game:GetService("StarterPack")
local Workspace = game:GetService("Workspace")

local Datos = require(ReplicatedStorage.Shared.Datos)
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)
local GestorDatos = require(script.Parent.Parent.GestorDatos)
local UtilidadesMapaHorda = require(script.Parent.UtilidadesMapaHorda)
local WaveManager = require(script.Parent.WaveManager)
local ZombieService = require(script.Parent.ZombieService)

local ConfigZombis = Datos.Zombis
local ConfigDante = ConfigZombis.Dante

local HordeService = {}

local _modeloDante: Model? = nil
local _hrpDante: BasePart? = nil
local _promptDante: ProximityPrompt? = nil
local _debounceInteraccion: { [Player]: number } = {}
local _lockInicio = false

local function crearMotor6D(
	nombre: string,
	part0: BasePart,
	part1: BasePart,
	c0: CFrame,
	c1: CFrame
): Motor6D
	local motor = Instance.new("Motor6D")
	motor.Name = nombre
	motor.Part0 = part0
	motor.Part1 = part1
	motor.C0 = c0
	motor.C1 = c1
	motor.Parent = part0
	return motor
end

local function soldarPieza(padre: BasePart, pieza: BasePart)
	pieza.Anchored = false
	pieza.CanCollide = false
	pieza.CanTouch = false
	pieza.Massless = true
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = padre
	weld.Part1 = pieza
	weld.Parent = padre
end

local function construirModeloDante(
	posicionSpawn: Vector3,
	mirarHacia: Vector3
): (Model, BasePart, ProximityPrompt)
	local carpetaSistema = UtilidadesMapaHorda.ObtenerCarpetaSistema()
	local previo = carpetaSistema:FindFirstChild("NPC_Dante")
	if previo then
		previo:Destroy()
	end

	local modelo = Instance.new("Model")
	modelo.Name = "NPC_Dante"

	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(2, 2, 1)
	hrp.Transparency = 1
	hrp.CanCollide = false
	hrp.Anchored = true -- Anclado para que Dante mantenga su puesto firme sin ser empujado
	hrp.Parent = modelo
	modelo.PrimaryPart = hrp

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Color = Color3.fromRGB(24, 24, 30) -- Gabardina urbana oscura
	torso.Material = Enum.Material.Fabric
	torso.CanCollide = false
	torso.Anchored = false
	torso.Parent = modelo

	-- Camisa interior carmesí y solapas de gabardina
	local camisaInterior = Instance.new("Part")
	camisaInterior.Name = "CamisaCarmesi"
	camisaInterior.Size = Vector3.new(0.65, 1.75, 1.06)
	camisaInterior.Color = Color3.fromRGB(145, 28, 42)
	camisaInterior.Material = Enum.Material.SmoothPlastic
	camisaInterior.CFrame = torso.CFrame
	camisaInterior.Parent = modelo
	soldarPieza(torso, camisaInterior)

	local cuelloAbrigo = Instance.new("Part")
	cuelloAbrigo.Name = "CuelloGabardina"
	cuelloAbrigo.Size = Vector3.new(2.2, 0.45, 1.2)
	cuelloAbrigo.Color = Color3.fromRGB(32, 32, 40)
	cuelloAbrigo.Material = Enum.Material.Fabric
	cuelloAbrigo.CFrame = torso.CFrame * CFrame.new(0, 0.85, 0.08)
	cuelloAbrigo.Parent = modelo
	soldarPieza(torso, cuelloAbrigo)

	-- Cinturón táctico con emblema dorado
	local cinturon = Instance.new("Part")
	cinturon.Name = "Cinturon"
	cinturon.Size = Vector3.new(2.08, 0.28, 1.08)
	cinturon.Color = Color3.fromRGB(16, 16, 20)
	cinturon.Material = Enum.Material.Leather
	cinturon.CFrame = torso.CFrame * CFrame.new(0, -0.82, 0)
	cinturon.Parent = modelo
	soldarPieza(torso, cinturon)

	local hebilla = Instance.new("Part")
	hebilla.Name = "EmblemaDorado"
	hebilla.Size = Vector3.new(0.45, 0.26, 0.14)
	hebilla.Color = Color3.fromRGB(235, 180, 50)
	hebilla.Material = Enum.Material.Metal
	hebilla.CFrame = cinturon.CFrame * CFrame.new(0, 0, -0.52)
	hebilla.Parent = modelo
	soldarPieza(torso, hebilla)

	-- Cabeza, cabello oscuro estilizado y gafas oscuras misteriosas
	local cabeza = Instance.new("Part")
	cabeza.Name = "Head"
	cabeza.Size = Vector3.new(1.2, 1.2, 1.2)
	cabeza.Color = Color3.fromRGB(218, 178, 148)
	cabeza.Material = Enum.Material.SmoothPlastic
	cabeza.CanCollide = false
	cabeza.Anchored = false
	cabeza.Parent = modelo

	local cabello = Instance.new("Part")
	cabello.Name = "Cabello"
	cabello.Size = Vector3.new(1.28, 0.55, 1.32)
	cabello.Color = Color3.fromRGB(22, 22, 26)
	cabello.Material = Enum.Material.SmoothPlastic
	cabello.CFrame = cabeza.CFrame * CFrame.new(0, 0.52, 0.05)
	cabello.Parent = modelo
	soldarPieza(cabeza, cabello)

	local gafas = Instance.new("Part")
	gafas.Name = "GafasOscuras"
	gafas.Size = Vector3.new(1.0, 0.28, 0.18)
	gafas.Color = Color3.fromRGB(15, 15, 20)
	gafas.Material = Enum.Material.Glass
	gafas.Reflectance = 0.25
	gafas.CFrame = cabeza.CFrame * CFrame.new(0, 0.12, -0.58)
	gafas.Parent = modelo
	soldarPieza(cabeza, gafas)

	-- Brazos y mangas de gabardina
	local brazoIzq = Instance.new("Part")
	brazoIzq.Name = "Left Arm"
	brazoIzq.Size = Vector3.new(1, 2, 1)
	brazoIzq.Color = Color3.fromRGB(28, 28, 34)
	brazoIzq.Material = Enum.Material.Fabric
	brazoIzq.CanCollide = false
	brazoIzq.Anchored = false
	brazoIzq.Parent = modelo

	local manoIzq = Instance.new("Part")
	manoIzq.Name = "ManoIzq"
	manoIzq.Size = Vector3.new(0.95, 0.45, 0.95)
	manoIzq.Color = Color3.fromRGB(218, 178, 148)
	manoIzq.Material = Enum.Material.SmoothPlastic
	manoIzq.CFrame = brazoIzq.CFrame * CFrame.new(0, -0.78, 0)
	manoIzq.Parent = modelo
	soldarPieza(brazoIzq, manoIzq)

	local brazoDer = Instance.new("Part")
	brazoDer.Name = "Right Arm"
	brazoDer.Size = Vector3.new(1, 2, 1)
	brazoDer.Color = Color3.fromRGB(28, 28, 34)
	brazoDer.Material = Enum.Material.Fabric
	brazoDer.CanCollide = false
	brazoDer.Anchored = false
	brazoDer.Parent = modelo

	local manoDer = Instance.new("Part")
	manoDer.Name = "ManoDer"
	manoDer.Size = Vector3.new(0.95, 0.45, 0.95)
	manoDer.Color = Color3.fromRGB(218, 178, 148)
	manoDer.Material = Enum.Material.SmoothPlastic
	manoDer.CFrame = brazoDer.CFrame * CFrame.new(0, -0.78, 0)
	manoDer.Parent = modelo
	soldarPieza(brazoDer, manoDer)

	-- Piernas (pantalón urbano oscuro)
	local piernaIzq = Instance.new("Part")
	piernaIzq.Name = "Left Leg"
	piernaIzq.Size = Vector3.new(1, 2, 1)
	piernaIzq.Color = Color3.fromRGB(18, 20, 26)
	piernaIzq.Material = Enum.Material.SmoothPlastic
	piernaIzq.CanCollide = false
	piernaIzq.Anchored = false
	piernaIzq.Parent = modelo

	local piernaDer = Instance.new("Part")
	piernaDer.Name = "Right Leg"
	piernaDer.Size = Vector3.new(1, 2, 1)
	piernaDer.Color = Color3.fromRGB(18, 20, 26)
	piernaDer.Material = Enum.Material.SmoothPlastic
	piernaDer.CanCollide = false
	piernaDer.Anchored = false
	piernaDer.Parent = modelo

	-- Luz sutil carmesí para identificarlo fácilmente cerca del spawn
	local luzPresencia = Instance.new("PointLight")
	luzPresencia.Name = "LuzDante"
	luzPresencia.Color = Color3.fromRGB(255, 85, 85)
	luzPresencia.Range = 14
	luzPresencia.Brightness = 1.2
	luzPresencia.Parent = torso

	-- Articulaciones Motor6D
	crearMotor6D("RootJoint", hrp, torso, CFrame.identity, CFrame.identity)
	crearMotor6D("Neck", torso, cabeza, CFrame.new(0, 1.0, 0), CFrame.new(0, -0.6, 0))
	crearMotor6D("Left Shoulder", torso, brazoIzq, CFrame.new(-1.5, 0.5, 0), CFrame.new(0, 0.5, 0))
	crearMotor6D("Right Shoulder", torso, brazoDer, CFrame.new(1.5, 0.5, 0), CFrame.new(0, 0.5, 0))
	crearMotor6D("Left Hip", torso, piernaIzq, CFrame.new(-0.5, -1.0, 0), CFrame.new(0, 1.0, 0))
	crearMotor6D("Right Hip", torso, piernaDer, CFrame.new(0.5, -1.0, 0), CFrame.new(0, 1.0, 0))

	-- Humanoid y Animator
	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.RigType = Enum.HumanoidRigType.R6
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false
	humanoid.AutomaticScalingEnabled = false
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.Parent = modelo

	local animator = Instance.new("Animator")
	animator.Parent = humanoid

	local carpetaAnims = Instance.new("Folder")
	carpetaAnims.Name = "Animaciones"
	carpetaAnims.Parent = humanoid
	for nombreAnim, animId in pairs(ConfigZombis.Animaciones.Dante) do
		local anim = Instance.new("Animation")
		anim.Name = nombreAnim
		anim.AnimationId = animId
		anim.Parent = carpetaAnims
	end

	-- Resplandor / Highlight distintivo (ocultado por paredes para no verse a través del mapa)
	local highlight = Instance.new("Highlight")
	highlight.Name = "AuraDante"
	highlight.FillColor = Color3.fromRGB(190, 45, 55)
	highlight.FillTransparency = 0.7
	highlight.OutlineColor = Color3.fromRGB(255, 220, 80)
	highlight.OutlineTransparency = 0.1
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Adornee = modelo
	highlight.Parent = modelo

	-- Rótulo superior sobre Dante (visible solo en proximidad a la Cocina, máx 35 studs)
	local bbg = Instance.new("BillboardGui")
	bbg.Name = "RotuloDante"
	bbg.Size = UDim2.fromOffset(230, 56)
	bbg.StudsOffset = Vector3.new(0, 3.2, 0)
	bbg.AlwaysOnTop = false
	bbg.MaxDistance = ConfigDante.DistanciaMaxRotulo or 35
	bbg.Parent = cabeza

	local marcoLbl = Instance.new("Frame")
	marcoLbl.Size = UDim2.fromScale(1, 1)
	marcoLbl.BackgroundColor3 = Color3.fromRGB(22, 18, 26)
	marcoLbl.BackgroundTransparency = 0.15
	marcoLbl.Parent = bbg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = marcoLbl

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(220, 60, 75)
	stroke.Thickness = 1.8
	stroke.Parent = marcoLbl

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.FredokaOne
	lbl.Text = "🕶️ DANTE\n(Evento Horda de Zombis)"
	lbl.TextColor3 = Color3.fromRGB(255, 225, 220)
	lbl.TextSize = 13
	lbl.Parent = marcoLbl

	-- ProximityPrompt de interacción
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PromptDante"
	prompt.ObjectText = ConfigDante.Nombre
	prompt.ActionText = "Hablar con Dante"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = ConfigDante.DuracionHoldPrompt
	prompt.MaxActivationDistance = ConfigDante.DistanciaInteraccion
	prompt.RequiresLineOfSight = ConfigDante.RequiereLineaVision
	prompt.Parent = torso

	local dirMirar = (mirarHacia - posicionSpawn) * Vector3.new(1, 0, 1)
	local cfFinal = if dirMirar.Magnitude > 0.1
		then CFrame.lookAt(posicionSpawn, posicionSpawn + dirMirar.Unit)
		else CFrame.new(posicionSpawn)

	modelo:PivotTo(cfFinal)
	modelo.Parent = carpetaSistema

	return modelo, hrp, prompt
end

local function asegurarMunicionInicialParaHorda()
	local minMunicion = ConfigZombis.General.MunicionMinimaAlIniciar
	for _, player in ipairs(Players:GetPlayers()) do
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

local function actualizarPromptDante()
	if not _promptDante then
		return
	end
	if WaveManager.EstaActiva() then
		_promptDante.ActionText = "Horda en curso..."
		_promptDante.Enabled = false
	else
		_promptDante.ActionText = "Hablar con Dante"
		_promptDante.Enabled = true
	end
end

local function obtenerUbicacionCocinaAbuela(): (Vector3, Vector3)
	local mapa = Workspace:FindFirstChild("Mapa")
	local edificio = mapa and mapa:FindFirstChild("Edificio_CocinaInicial")
	local cocina = edificio and edificio:FindFirstChild("Cocina de la Abuela")
	if cocina then
		local piso = cocina:FindFirstChild("Piso") :: BasePart?
		local dintel = cocina:FindFirstChild("Dintel") :: BasePart?
		if piso and dintel then
			-- Parado dentro de la cocina sobre el piso, mirando hacia la puerta principal
			local pos = Vector3.new(piso.Position.X, piso.Position.Y + 3.5, piso.Position.Z + 10)
			local mirar = Vector3.new(dintel.Position.X, pos.Y, dintel.Position.Z)
			return pos, mirar
		end
	end
	return Vector3.new(85, 63.0, -70), Vector3.new(85, 63.0, -57.5)
end

local function generarDanteEnCocinaAbuela()
	local posDante, mirarHacia = obtenerUbicacionCocinaAbuela()
	local modelo, hrp, prompt = construirModeloDante(posDante, mirarHacia)

	_modeloDante = modelo
	_hrpDante = hrp
	_promptDante = prompt

	prompt.Triggered:Connect(function(player: Player)
		local ahora = os.clock()
		local ultimo = _debounceInteraccion[player] or 0
		if (ahora - ultimo) < 1.0 then
			return
		end
		_debounceInteraccion[player] = ahora

		if WaveManager.EstaActiva() or _lockInicio then
			EventosRemotos.MostrarDialogoNPC:FireClient(player, {
				Nombre = ConfigDante.Nombre,
				Titulo = ConfigDante.Titulo,
				Icono = "🕶️",
				Mensaje = "¡La horda ya está en marcha! Concéntrate en sobrevivir a los zombis.",
				EsNotificacionEfimera = true,
			})
			return
		end

		local char = player.Character
		local pHrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not pHrp or not pHrp:IsA("BasePart") or not hum or hum.Health <= 0 then
			return
		end

		if (pHrp.Position - hrp.Position).Magnitude > (ConfigDante.DistanciaInteraccion + 4) then
			return
		end

		-- Orientar a Dante suavemente hacia el jugador que inicia la conversación
		local dirJugador = (pHrp.Position - hrp.Position) * Vector3.new(1, 0, 1)
		if dirJugador.Magnitude > 0.2 then
			hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + dirJugador.Unit)
		end

		EventosRemotos.DanteInteraccion:FireClient(player, {
			Nombre = ConfigDante.Nombre,
			Titulo = ConfigDante.Titulo,
			Dialogos = ConfigDante.Dialogos,
			PosicionDante = hrp.Position,
		})
	end)

	print(
		string.format(
			"[HordeService] NPC Dante ubicado dentro de la Cocina de la Abuela en (%.1f, %.1f, %.1f)",
			posDante.X,
			posDante.Y,
			posDante.Z
		)
	)
end

local function prepararPlantillaEspadaHorda(): Tool?
	local existente = ServerStorage:FindFirstChild("EspadaHordaTemplate")
	if existente and existente:IsA("Tool") then
		return existente
	end

	local nombresCandidatos = {
		"Minecraft Diamond Sword",
		"Espada del rey",
		"Classic Sword",
		"Classic Error Sword",
	}

	-- Prioridad 1: Buscar en StarterPack (donde el jugador la colocó) y moverla a ServerStorage
	for _, nombre in ipairs(nombresCandidatos) do
		local enStarter = StarterPack:FindFirstChild(nombre)
		if enStarter and enStarter:IsA("Tool") then
			enStarter.Name = "EspadaHordaTemplate"
			enStarter.Parent = ServerStorage
			return enStarter
		end
	end

	-- Prioridad 2: Buscar en Workspace y clonar como plantilla en ServerStorage
	for _, nombre in ipairs(nombresCandidatos) do
		local enWorkspace = Workspace:FindFirstChild(nombre)
		if enWorkspace and enWorkspace:IsA("Tool") then
			local clon = enWorkspace:Clone()
			clon.Name = "EspadaHordaTemplate"
			clon.Parent = ServerStorage
			return clon
		end
	end

	return nil
end

local function configurarInstakillEspada(espada: Tool, player: Player)
	local handle = espada:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		return
	end

	local ultimoGolpePorZombi: { [Model]: number } = {}
	handle.Touched:Connect(function(hit: BasePart)
		if espada.Parent ~= player.Character then
			return
		end
		local modeloZombi = ZombieService.EsZombi(hit)
		if not modeloZombi then
			return
		end

		local ahora = os.clock()
		if ultimoGolpePorZombi[modeloZombi] and (ahora - ultimoGolpePorZombi[modeloZombi]) < 0.2 then
			return
		end
		ultimoGolpePorZombi[modeloZombi] = ahora

		-- Instakill garantizado a cualquier zombi de la horda
		ZombieService.AplicarDanio(modeloZombi, 999999, player, "EspadaHorda")
	end)
end

local function entregarEspadaAJugador(player: Player)
	local plantilla = prepararPlantillaEspadaHorda()
	if not plantilla then
		warn("[HordeService] No se encontró ninguna espada plantilla para la horda.")
		return
	end

	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return
	end

	-- Evitar duplicados
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") and item:GetAttribute("EsEspadaHorda") == true then
				item:Destroy()
			end
		end
	end
	if char then
		for _, item in ipairs(char:GetChildren()) do
			if item:IsA("Tool") and item:GetAttribute("EsEspadaHorda") == true then
				item:Destroy()
			end
		end
	end

	local espada = plantilla:Clone()
	espada.Name = "Espada Horda"
	espada:SetAttribute("EsEspadaHorda", true)
	espada.CanBeDropped = false
	configurarInstakillEspada(espada, player)

	if backpack then
		espada.Parent = backpack
		task.defer(function()
			if hum and hum.Parent and hum.Health > 0 and espada.Parent then
				hum:EquipTool(espada)
			end
		end)
	end
end

local function entregarEspadaATodos()
	for _, player in ipairs(Players:GetPlayers()) do
		entregarEspadaAJugador(player)
	end
end

local function retirarEspadasDeTodos()
	for _, player in ipairs(Players:GetPlayers()) do
		local backpack = player:FindFirstChildOfClass("Backpack")
		if backpack then
			for _, item in ipairs(backpack:GetChildren()) do
				if item:IsA("Tool") and item:GetAttribute("EsEspadaHorda") == true then
					item:Destroy()
				end
			end
		end
		local char = player.Character
		if char then
			for _, item in ipairs(char:GetChildren()) do
				if item:IsA("Tool") and item:GetAttribute("EsEspadaHorda") == true then
					item:Destroy()
				end
			end
		end
	end
end

function HordeService.Iniciar()
	prepararPlantillaEspadaHorda()
	WaveManager.EstablecerCallbacksCiclo(entregarEspadaATodos, retirarEspadasDeTodos)
	WaveManager.Inicializar()
	generarDanteEnCocinaAbuela()

	-- Validación en el servidor al confirmar inicio de horda desde la UI de Dante
	EventosRemotos.SolicitarIniciarHorda.OnServerInvoke = function(
		player: Player
	): (boolean, string)
		if _lockInicio or WaveManager.EstaActiva() then
			return false, "Ya hay una horda activa en este momento."
		end

		local char = player.Character
		local pHrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not pHrp or not pHrp:IsA("BasePart") or not hum or hum.Health <= 0 then
			return false, "Debes estar vivo para iniciar la horda."
		end

		if
			_hrpDante
			and (pHrp.Position - _hrpDante.Position).Magnitude
				> ConfigDante.DistanciaMaxConfirmacion
		then
			return false, "Estás demasiado lejos de Dante para comenzar la horda."
		end

		_lockInicio = true
		asegurarMunicionInicialParaHorda()
		WaveManager.IniciarHorda()
		actualizarPromptDante()
		_lockInicio = false

		return true, ConfigDante.DialogoInicio
	end

	-- Sincronizar estado si un jugador entra cuando ya hay una oleada en curso
	Players.PlayerAdded:Connect(function(player: Player)
		player.CharacterAdded:Connect(function()
			task.wait(0.4)
			if WaveManager.EstaActiva() then
				entregarEspadaAJugador(player)
			end
		end)

		-- Comando de ayuda en chat: /dante para teletransportarse frente a Dante en la Cocina de la Abuela
		player.Chatted:Connect(function(mensaje: string)
			local cmd = string.lower(mensaje)
			if cmd == "/dante" or cmd == "/iradante" or cmd == "/horda" or cmd == "/cocina" then
				local char = player.Character
				local pHrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
				if pHrp and _hrpDante then
					pHrp.CFrame = _hrpDante.CFrame
						* CFrame.new(0, 0, -5)
						* CFrame.Angles(0, math.rad(180), 0)
					print(
						string.format(
							"[HordeService] Teletransportado %s hacia Dante en la Cocina de la Abuela",
							player.Name
						)
					)
				end
			end
		end)

		task.delay(1.5, function()
			if not player:IsDescendantOf(Players) then
				return
			end
			EventosRemotos.EstadoHordaActualizado:FireClient(player, {
				Estado = WaveManager.ObtenerEstado(),
				Oleada = WaveManager.ObtenerOleadaActual(),
				ZombisRestantes = 0,
				TotalOleada = 0,
				Mensaje = "",
				TiempoRestante = 0,
			})
		end)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		_debounceInteraccion[player] = nil
	end)

	-- Vigilancia ligera para reactivar el prompt de Dante cuando termina una horda
	task.spawn(function()
		local ultimoEstadoActivo = false
		while true do
			task.wait(0.5)
			local activo = WaveManager.EstaActiva()
			if activo ~= ultimoEstadoActivo then
				ultimoEstadoActivo = activo
				actualizarPromptDante()
			end
		end
	end)
end

return HordeService
