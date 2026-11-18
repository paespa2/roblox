--!strict
--[[
	DanteController.luau
	Controlador cliente para la interfaz de diálogo con opciones de Dante
	y su animación procedural/Animator (Idle, Conversación y orientación).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)
local Datos = require(ReplicatedStorage.Shared.Datos)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ConfigZombis = Datos.Zombis

local DanteController = {}

local _dialogoAbierto = false
local _paginas: { string } = {}
local _paginaActual = 1
local _posDante: Vector3? = nil
local _enviandoInicio = false

local _screenGui: ScreenGui
local _marcoDialogo: Frame
local _lblNombre: TextLabel
local _lblTexto: TextLabel
local _lblPagina: TextLabel
local _btnSiguiente: TextButton
local _btnComenzar: TextButton
local _btnAhoraNo: TextButton
local _btnCerrar: TextButton

-- Referencias de animación de Dante
local _motorCuelloDante: Motor6D? = nil
local _motorBrazoDerDante: Motor6D? = nil
local _motorBrazoIzqDante: Motor6D? = nil
local _motorRootDante: Motor6D? = nil
local _trackIdleDante: AnimationTrack? = nil
local _trackTalkDante: AnimationTrack? = nil

local function reproducirSonidoUI(soundId: string, volumen: number?)
	if soundId == "" then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = soundId
	s.Volume = volumen or 0.45
	s.Parent = SoundService
	pcall(function()
		s:Play()
	end)
	task.delay(1.5, function()
		if s.Parent then
			s:Destroy()
		end
	end)
end

local function cerrarDialogo()
	if not _dialogoAbierto then
		return
	end
	_dialogoAbierto = false

	if _trackTalkDante and _trackTalkDante.IsPlaying then
		_trackTalkDante:Stop(0.2)
	end
	if _trackIdleDante and not _trackIdleDante.IsPlaying then
		_trackIdleDante:Play(0.2)
	end

	local tween = TweenService:Create(
		_marcoDialogo,
		TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = UDim2.new(0.5, 0, 1, 180) }
	)
	tween:Play()
	tween.Completed:Connect(function()
		if not _dialogoAbierto then
			_marcoDialogo.Visible = false
		end
	end)
end

local function actualizarVistaPagina()
	local total = #_paginas
	_lblTexto.Text = _paginas[_paginaActual] or ""
	_lblPagina.Text = string.format("Página %d de %d", _paginaActual, total)

	local esUltima = _paginaActual >= total
	_btnSiguiente.Visible = not esUltima
	_btnComenzar.Visible = esUltima
	_btnAhoraNo.Visible = esUltima
end

local function abrirDialogo(info: {
	Nombre: string?,
	Titulo: string?,
	Dialogos: { string }?,
	PosicionDante: Vector3?,
})
	if _dialogoAbierto then
		return
	end

	_paginas = info.Dialogos or ConfigZombis.Dante.Dialogos
	_paginaActual = 1
	_posDante = info.PosicionDante
	_enviandoInicio = false
	_dialogoAbierto = true

	local tituloCompleto = (info.Nombre or "Dante")
	if info.Titulo then
		tituloCompleto = string.format("%s — %s", tituloCompleto, info.Titulo)
	end
	_lblNombre.Text = tituloCompleto
	actualizarVistaPagina()

	if _trackIdleDante and _trackIdleDante.IsPlaying then
		_trackIdleDante:Stop(0.2)
	end
	if _trackTalkDante and not _trackTalkDante.IsPlaying then
		_trackTalkDante:Play(0.2)
	end

	_marcoDialogo.Visible = true
	_marcoDialogo.Position = UDim2.new(0.5, 0, 1, 180)
	TweenService:Create(
		_marcoDialogo,
		TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 1, -76) }
	):Play()

	reproducirSonidoUI(ConfigZombis.Sonidos.AlertaUI, 0.45)
end

local function construirInterfaz()
	local previo = PlayerGui:FindFirstChild("UI_Dialogo_Dante")
	if previo then
		previo:Destroy()
	end

	_screenGui = Instance.new("ScreenGui")
	_screenGui.Name = "UI_Dialogo_Dante"
	_screenGui.ResetOnSpawn = false
	_screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	_screenGui.Parent = PlayerGui

	_marcoDialogo = Instance.new("Frame")
	_marcoDialogo.Name = "MarcoDialogoDante"
	_marcoDialogo.Size = UDim2.fromOffset(560, 148)
	_marcoDialogo.AnchorPoint = Vector2.new(0.5, 1)
	_marcoDialogo.Position = UDim2.new(0.5, 0, 1, 180)
	_marcoDialogo.BackgroundColor3 = Color3.fromRGB(22, 20, 28)
	_marcoDialogo.BackgroundTransparency = 0.05
	_marcoDialogo.Visible = false
	_marcoDialogo.Parent = _screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = _marcoDialogo

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(220, 60, 75)
	stroke.Thickness = 2
	stroke.Parent = _marcoDialogo

	-- Avatar simbólico de Dante
	local marcoAvatar = Instance.new("Frame")
	marcoAvatar.Size = UDim2.fromOffset(66, 66)
	marcoAvatar.Position = UDim2.fromOffset(14, 18)
	marcoAvatar.BackgroundColor3 = Color3.fromRGB(36, 24, 32)
	marcoAvatar.Parent = _marcoDialogo

	local cornerAv = Instance.new("UICorner")
	cornerAv.CornerRadius = UDim.new(0, 12)
	cornerAv.Parent = marcoAvatar

	local strokeAv = Instance.new("UIStroke")
	strokeAv.Color = Color3.fromRGB(235, 180, 60)
	strokeAv.Thickness = 1.5
	strokeAv.Parent = marcoAvatar

	local iconoAv = Instance.new("TextLabel")
	iconoAv.Size = UDim2.fromScale(1, 1)
	iconoAv.BackgroundTransparency = 1
	iconoAv.Font = Enum.Font.FredokaOne
	iconoAv.Text = "🕶️"
	iconoAv.TextSize = 38
	iconoAv.Parent = marcoAvatar

	_lblNombre = Instance.new("TextLabel")
	_lblNombre.Size = UDim2.new(1, -135, 0, 24)
	_lblNombre.Position = UDim2.fromOffset(92, 12)
	_lblNombre.BackgroundTransparency = 1
	_lblNombre.Font = Enum.Font.FredokaOne
	_lblNombre.Text = "Dante — Vigía de las Sombras"
	_lblNombre.TextColor3 = Color3.fromRGB(255, 195, 110)
	_lblNombre.TextSize = 16
	_lblNombre.TextXAlignment = Enum.TextXAlignment.Left
	_lblNombre.Parent = _marcoDialogo

	_lblTexto = Instance.new("TextLabel")
	_lblTexto.Size = UDim2.new(1, -110, 0, 56)
	_lblTexto.Position = UDim2.fromOffset(92, 38)
	_lblTexto.BackgroundTransparency = 1
	_lblTexto.Font = Enum.Font.GothamMedium
	_lblTexto.Text = ""
	_lblTexto.TextColor3 = Color3.fromRGB(242, 242, 248)
	_lblTexto.TextSize = 14
	_lblTexto.TextWrapped = true
	_lblTexto.TextXAlignment = Enum.TextXAlignment.Left
	_lblTexto.TextYAlignment = Enum.TextYAlignment.Top
	_lblTexto.Parent = _marcoDialogo

	_lblPagina = Instance.new("TextLabel")
	_lblPagina.Size = UDim2.fromOffset(120, 24)
	_lblPagina.Position = UDim2.new(0, 16, 1, -34)
	_lblPagina.BackgroundTransparency = 1
	_lblPagina.Font = Enum.Font.GothamBold
	_lblPagina.Text = "Página 1 de 3"
	_lblPagina.TextColor3 = Color3.fromRGB(165, 170, 190)
	_lblPagina.TextSize = 11
	_lblPagina.TextXAlignment = Enum.TextXAlignment.Left
	_lblPagina.Parent = _marcoDialogo

	_btnCerrar = Instance.new("TextButton")
	_btnCerrar.Size = UDim2.fromOffset(26, 26)
	_btnCerrar.AnchorPoint = Vector2.new(1, 0)
	_btnCerrar.Position = UDim2.new(1, -10, 0, 10)
	_btnCerrar.BackgroundColor3 = Color3.fromRGB(52, 56, 72)
	_btnCerrar.Font = Enum.Font.GothamBold
	_btnCerrar.Text = "X"
	_btnCerrar.TextColor3 = Color3.fromRGB(240, 240, 250)
	_btnCerrar.TextSize = 13
	_btnCerrar.Parent = _marcoDialogo

	local cornerC = Instance.new("UICorner")
	cornerC.CornerRadius = UDim.new(0, 6)
	cornerC.Parent = _btnCerrar

	_btnSiguiente = Instance.new("TextButton")
	_btnSiguiente.Size = UDim2.fromOffset(120, 30)
	_btnSiguiente.AnchorPoint = Vector2.new(1, 1)
	_btnSiguiente.Position = UDim2.new(1, -14, 1, -12)
	_btnSiguiente.BackgroundColor3 = Color3.fromRGB(50, 95, 185)
	_btnSiguiente.Font = Enum.Font.FredokaOne
	_btnSiguiente.Text = "Siguiente >"
	_btnSiguiente.TextColor3 = Color3.fromRGB(255, 255, 255)
	_btnSiguiente.TextSize = 13
	_btnSiguiente.Parent = _marcoDialogo

	local cornerSig = Instance.new("UICorner")
	cornerSig.CornerRadius = UDim.new(0, 8)
	cornerSig.Parent = _btnSiguiente

	_btnAhoraNo = Instance.new("TextButton")
	_btnAhoraNo.Name = "BotonAhoraNo"
	_btnAhoraNo.Size = UDim2.fromOffset(115, 32)
	_btnAhoraNo.AnchorPoint = Vector2.new(1, 1)
	_btnAhoraNo.Position = UDim2.new(1, -195, 1, -12)
	_btnAhoraNo.BackgroundColor3 = Color3.fromRGB(55, 60, 76)
	_btnAhoraNo.Font = Enum.Font.FredokaOne
	_btnAhoraNo.Text = "AHORA NO"
	_btnAhoraNo.TextColor3 = Color3.fromRGB(220, 225, 238)
	_btnAhoraNo.TextSize = 13
	_btnAhoraNo.Visible = false
	_btnAhoraNo.Parent = _marcoDialogo

	local cornerNo = Instance.new("UICorner")
	cornerNo.CornerRadius = UDim.new(0, 8)
	cornerNo.Parent = _btnAhoraNo

	_btnComenzar = Instance.new("TextButton")
	_btnComenzar.Name = "BotonComenzarHorda"
	_btnComenzar.Size = UDim2.fromOffset(170, 32)
	_btnComenzar.AnchorPoint = Vector2.new(1, 1)
	_btnComenzar.Position = UDim2.new(1, -14, 1, -12)
	_btnComenzar.BackgroundColor3 = Color3.fromRGB(190, 42, 58)
	_btnComenzar.Font = Enum.Font.FredokaOne
	_btnComenzar.Text = "COMENZAR HORDA"
	_btnComenzar.TextColor3 = Color3.fromRGB(255, 245, 240)
	_btnComenzar.TextSize = 13
	_btnComenzar.Visible = false
	_btnComenzar.Parent = _marcoDialogo

	local cornerCom = Instance.new("UICorner")
	cornerCom.CornerRadius = UDim.new(0, 8)
	cornerCom.Parent = _btnComenzar

	local strokeCom = Instance.new("UIStroke")
	strokeCom.Color = Color3.fromRGB(255, 180, 90)
	strokeCom.Thickness = 1.5
	strokeCom.Parent = _btnComenzar

	_btnCerrar.MouseButton1Click:Connect(function()
		reproducirSonidoUI(ConfigZombis.Sonidos.AlertaUI, 0.35)
		cerrarDialogo()
	end)

	_btnAhoraNo.MouseButton1Click:Connect(function()
		reproducirSonidoUI(ConfigZombis.Sonidos.AlertaUI, 0.35)
		cerrarDialogo()
	end)

	_btnSiguiente.MouseButton1Click:Connect(function()
		if _paginaActual < #_paginas then
			_paginaActual += 1
			reproducirSonidoUI(ConfigZombis.Sonidos.AlertaUI, 0.4)
			actualizarVistaPagina()
		end
	end)

	_btnComenzar.MouseButton1Click:Connect(function()
		if _enviandoInicio then
			return
		end
		_enviandoInicio = true
		_btnComenzar.Text = "INICIANDO..."

		task.spawn(function()
			local exito, respuesta = EventosRemotos.SolicitarIniciarHorda:InvokeServer()
			if exito then
				_lblTexto.Text = tostring(respuesta)
				_btnComenzar.Visible = false
				_btnAhoraNo.Visible = false
				reproducirSonidoUI(ConfigZombis.Sonidos.InicioOleada, 0.65)
				task.delay(1.8, cerrarDialogo)
			else
				_lblTexto.Text = tostring(respuesta)
				_btnComenzar.Text = "COMENZAR HORDA"
				_enviandoInicio = false
			end
		end)
	end)
end

local function vincularModeloDante(modelo: Model)
	local hrp = modelo:WaitForChild("HumanoidRootPart", 5)
	local torso = modelo:WaitForChild("Torso", 5)
	local hum = modelo:WaitForChild("Humanoid", 5)
	if not hrp or not torso or not hum or not hum:IsA("Humanoid") then
		return
	end

	_motorRootDante = hrp:FindFirstChild("RootJoint") :: Motor6D?
	_motorCuelloDante = torso:FindFirstChild("Neck") :: Motor6D?
	_motorBrazoIzqDante = torso:FindFirstChild("Left Shoulder") :: Motor6D?
	_motorBrazoDerDante = torso:FindFirstChild("Right Shoulder") :: Motor6D?

	local animator = hum:FindFirstChildOfClass("Animator")
	local carpetaAnims = hum:FindFirstChild("Animaciones")
	if animator and carpetaAnims then
		local animIdle = carpetaAnims:FindFirstChild("Idle")
		if animIdle and animIdle:IsA("Animation") and animIdle.AnimationId ~= "" then
			_trackIdleDante = animator:LoadAnimation(animIdle)
			_trackIdleDante.Looped = true
			_trackIdleDante:Play()
		end
		local animTalk = carpetaAnims:FindFirstChild("Talk")
		if animTalk and animTalk:IsA("Animation") and animTalk.AnimationId ~= "" then
			_trackTalkDante = animator:LoadAnimation(animTalk)
			_trackTalkDante.Looped = true
		end
	end
end

function DanteController.Iniciar()
	construirInterfaz()

	local eventoDante = EventosRemotos.DanteInteraccion
	if not eventoDante then
		local f = ReplicatedStorage:WaitForChild("EventosRemotos", 10)
		eventoDante = f and f:WaitForChild("DanteInteraccion", 10) :: RemoteEvent?
	end
	if eventoDante and eventoDante:IsA("RemoteEvent") then
		eventoDante.OnClientEvent:Connect(abrirDialogo)
	else
		warn("[DanteController] No se pudo conectar DanteInteraccion RemoteEvent")
	end

	local sistema = Workspace:WaitForChild("HordaSistema", 10)
	if sistema then
		local dante = sistema:FindFirstChild("NPC_Dante")
		if dante and dante:IsA("Model") then
			vincularModeloDante(dante)
		end
		sistema.ChildAdded:Connect(function(child)
			if child.Name == "NPC_Dante" and child:IsA("Model") then
				vincularModeloDante(child)
			end
		end)
	end

	RunService.RenderStepped:Connect(function()
		local t = os.clock()

		-- Cerrar diálogo automáticamente si el jugador se aleja demasiado
		if _dialogoAbierto and _posDante then
			local char = LocalPlayer.Character
			local pHrp = char and char:FindFirstChild("HumanoidRootPart")
			local pHum = char and char:FindFirstChildOfClass("Humanoid")
			if
				not pHrp
				or not pHrp:IsA("BasePart")
				or not pHum
				or pHum.Health <= 0
				or (pHrp.Position - _posDante).Magnitude
					> (ConfigZombis.Dante.DistanciaInteraccion + 6)
			then
				cerrarDialogo()
			end
		end

		-- Animación procedural de Dante cuando no hay AnimationTrack externo asignado
		if
			_motorRootDante
			and not (_trackIdleDante and _trackIdleDante.IsPlaying)
			and not (_trackTalkDante and _trackTalkDante.IsPlaying)
		then
			local respiracion = math.sin(t * 2.0) * 0.04
			_motorRootDante.Transform = CFrame.new(0, respiracion, 0)

			if _motorCuelloDante then
				if _dialogoAbierto then
					_motorCuelloDante.Transform = CFrame.Angles(math.sin(t * 4.5) * 0.08, 0, 0)
				else
					_motorCuelloDante.Transform = CFrame.Angles(0, math.sin(t * 0.9) * 0.16, 0)
				end
			end

			if _motorBrazoDerDante then
				if _dialogoAbierto then
					_motorBrazoDerDante.Transform =
						CFrame.Angles(math.rad(32) + math.sin(t * 5.0) * 0.18, 0, math.rad(8))
				else
					_motorBrazoDerDante.Transform =
						CFrame.Angles(math.sin(t * 1.6) * 0.05, 0, math.rad(4))
				end
			end

			if _motorBrazoIzqDante then
				_motorBrazoIzqDante.Transform =
					CFrame.Angles(-math.sin(t * 1.6) * 0.05, 0, math.rad(-4))
			end
		end
	end)
end

return DanteController
