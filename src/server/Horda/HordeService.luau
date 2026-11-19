--!strict
--[[
	HordeService.luau
	Coordina el NPC Dante cerca del spawn inicial, la validación de interacciones,
	el inicio seguro de sesiones de horda y la sincronización con jugadores nuevos.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Datos = require(ReplicatedStorage.Shared.Datos)
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)
local HordeSession = require(script.Parent.HordeSession)
local UtilidadesMapaHorda = require(script.Parent.UtilidadesMapaHorda)
local WaveManager = require(script.Parent.WaveManager)

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
	for _, desc in ipairs(carpetaSistema:GetDescendants()) do
		if desc.Name == "NPC_Dante" and desc:IsA("Model") then
			desc:Destroy()
		end
	end

	local modelo = Instance.new("Model")
	modelo.Name = "NPC_Dante"

	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(2, 2, 1)
	hrp.Transparency = 1
	hrp.CanCollide = false
	hrp.Anchored = true
	hrp.Parent = modelo
	modelo.PrimaryPart = hrp

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Color = Color3.fromRGB(24, 24, 30)
	torso.Material = Enum.Material.Fabric
	torso.CanCollide = false
	torso.Anchored = false
	torso.Parent = modelo

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

	local luzPresencia = Instance.new("PointLight")
	luzPresencia.Name = "LuzDante"
	luzPresencia.Color = Color3.fromRGB(255, 85, 85)
	luzPresencia.Range = 14
	luzPresencia.Brightness = 1.2
	luzPresencia.Parent = torso

	crearMotor6D("RootJoint", hrp, torso, CFrame.identity, CFrame.identity)
	crearMotor6D("Neck", torso, cabeza, CFrame.new(0, 1.0, 0), CFrame.new(0, -0.6, 0))
	crearMotor6D("Left Shoulder", torso, brazoIzq, CFrame.new(-1.5, 0.5, 0), CFrame.new(0, 0.5, 0))
	crearMotor6D("Right Shoulder", torso, brazoDer, CFrame.new(1.5, 0.5, 0), CFrame.new(0, 0.5, 0))
	crearMotor6D("Left Hip", torso, piernaIzq, CFrame.new(-0.5, -1.0, 0), CFrame.new(0, 1.0, 0))
	crearMotor6D("Right Hip", torso, piernaDer, CFrame.new(0.5, -1.0, 0), CFrame.new(0, 1.0, 0))

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

	local highlight = Instance.new("Highlight")
	highlight.Name = "AuraDante"
	highlight.FillColor = Color3.fromRGB(190, 45, 55)
	highlight.FillTransparency = 0.7
	highlight.OutlineColor = Color3.fromRGB(255, 220, 80)
	highlight.OutlineTransparency = 0.1
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Adornee = modelo
	highlight.Parent = modelo

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

local function actualizarPromptDante()
	if not _promptDante then
		return
	end
	if HordeSession.EstaActiva() then
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

		if HordeSession.EstaActiva() or _lockInicio then
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

local function conectarJugador(player: Player)
	player.Chatted:Connect(function(mensaje: string)
		local cmd = string.lower(mensaje)
		if cmd == "/dante" or cmd == "/iradante" or cmd == "/horda" or cmd == "/cocina" then
			local char = player.Character
			local pHrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if pHrp and _hrpDante then
				pHrp.CFrame = _hrpDante.CFrame
					* CFrame.new(0, 0, -5)
					* CFrame.Angles(0, math.rad(180), 0)
			end
		end
	end)

	task.delay(1.5, function()
		if not player:IsDescendantOf(Players) then
			return
		end
		EventosRemotos.EstadoHordaActualizado:FireClient(
			player,
			WaveManager.ConstruirPayloadParaJugador(player, "", 0)
		)
	end)
end

function HordeService.Iniciar()
	UtilidadesMapaHorda.ConfigurarCollisionGroups()
	WaveManager.Inicializar()
	generarDanteEnCocinaAbuela()

	HordeSession.EstablecerCallbackEstado(function(_nuevoEstado)
		actualizarPromptDante()
	end)

	EventosRemotos.ObtenerEstadoHorda.OnServerInvoke = function(player: Player)
		return WaveManager.ConstruirPayloadParaJugador(player, "", 0)
	end

	EventosRemotos.SolicitarIniciarHorda.OnServerInvoke = function(
		player: Player
	): (boolean, string)
		if _lockInicio or HordeSession.EstaActiva() then
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
		local exito, errMsg = WaveManager.IniciarHorda(player)
		actualizarPromptDante()
		_lockInicio = false

		if not exito then
			return false, errMsg or "No se pudo iniciar la horda."
		end
		return true, ConfigDante.DialogoInicio
	end

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(conectarJugador, player)
	end
	Players.PlayerAdded:Connect(conectarJugador)
	Players.PlayerRemoving:Connect(function(player: Player)
		_debounceInteraccion[player] = nil
	end)
end

return HordeService
