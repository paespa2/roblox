--!strict
--[[
	HordeAtmosphere.luau
	Atmósfera nocturna realista estilo Call of Duty Zombies, niebla de ronda especial,
	viñeta de sangre por daño, sacudida de cámara, hitmarkers en retícula y sangre 3D.
]]

local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local HordeAtmosphere = {}

local _hordaActiva = false
local _enRondaEspecial = false
local _originalGuardado = false
local _origClockTime = 14
local _origBrightness = 2
local _origAmbient = Color3.fromRGB(128, 128, 128)
local _origOutdoorAmbient = Color3.fromRGB(128, 128, 128)
local _origExposure = 0

local _atmosfera: Atmosphere? = nil
local _colorCorr: ColorCorrectionEffect? = nil
local _bloom: BloomEffect? = nil
local _hiloRelampagos: thread? = nil

local _screenGui: ScreenGui
local _bordesSangre: { { Frame: Frame, BaseAlpha: number } } = {}
local _nukeFlash: Frame
local _hitmarkerContenedor: Frame
local _hitmarkerTicks: { Frame } = {}
local _hitmarkerFadeThread: thread? = nil

local _saludActual = 100
local _saludMax = 100
local _ultimaSalud = 100
local _trauma = 0

local function reproducirSonidoLocal(soundId: string, volumen: number, pitch: number?)
	local s = Instance.new("Sound")
	s.SoundId = soundId
	s.Volume = volumen
	s.PlaybackSpeed = pitch or 1.0
	s.Parent = SoundService
	pcall(function()
		s:Play()
	end)
	Debris:AddItem(s, 2.5)
end

local function guardarLightingOriginal()
	if _originalGuardado then
		return
	end
	_originalGuardado = true
	_origClockTime = Lighting.ClockTime
	_origBrightness = Lighting.Brightness
	_origAmbient = Lighting.Ambient
	_origOutdoorAmbient = Lighting.OutdoorAmbient
	_origExposure = Lighting.ExposureCompensation
end

local function asegurarEfectosLighting(): (Atmosphere, ColorCorrectionEffect, BloomEffect)
	if not _atmosfera or not _atmosfera.Parent then
		local prev = Lighting:FindFirstChild("HordaAtmosfera")
		if prev then
			prev:Destroy()
		end
		local atm = Instance.new("Atmosphere")
		atm.Name = "HordaAtmosfera"
		atm.Density = 0.15
		atm.Offset = 0.1
		atm.Color = Color3.fromRGB(35, 38, 46)
		atm.Decay = Color3.fromRGB(16, 14, 18)
		atm.Glare = 0.15
		atm.Haze = 2.0
		atm.Parent = Lighting
		_atmosfera = atm
	end

	if not _colorCorr or not _colorCorr.Parent then
		local prev = Lighting:FindFirstChild("HordaColorCorrection")
		if prev then
			prev:Destroy()
		end
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "HordaColorCorrection"
		cc.Saturation = 0
		cc.Contrast = 0
		cc.TintColor = Color3.new(1, 1, 1)
		cc.Parent = Lighting
		_colorCorr = cc
	end

	if not _bloom or not _bloom.Parent then
		local prev = Lighting:FindFirstChild("HordaBloom")
		if prev then
			prev:Destroy()
		end
		local bl = Instance.new("BloomEffect")
		bl.Name = "HordaBloom"
		bl.Intensity = 0.2
		bl.Size = 16
		bl.Threshold = 1.15
		bl.Parent = Lighting
		_bloom = bl
	end

	return _atmosfera :: Atmosphere, _colorCorr :: ColorCorrectionEffect, _bloom :: BloomEffect
end

local function detenerHiloRelampagos()
	if _hiloRelampagos then
		local h = _hiloRelampagos
		_hiloRelampagos = nil
		if coroutine.running() ~= h then
			pcall(task.cancel, h)
		end
	end
end

local function iniciarHiloRelampagos()
	detenerHiloRelampagos()
	_hiloRelampagos = task.spawn(function()
		while _hordaActiva and _enRondaEspecial do
			task.wait(math.random(6, 13))
			if not _hordaActiva or not _enRondaEspecial then
				break
			end
			local prevBright = Lighting.Brightness
			Lighting.Brightness = prevBright + 1.8
			if _colorCorr and _colorCorr.Parent then
				_colorCorr.Brightness = 0.18
			end
			reproducirSonidoLocal("rbxasset://sounds/collide.wav", 0.35, 0.35)
			task.wait(0.08)
			if _colorCorr and _colorCorr.Parent then
				TweenService:Create(_colorCorr, TweenInfo.new(0.45), { Brightness = 0 }):Play()
			end
			TweenService:Create(Lighting, TweenInfo.new(0.45), { Brightness = prevBright }):Play()
		end
	end)
end

local function aplicarAtmosferaHorda(activa: boolean, esRondaEspecial: boolean)
	if not activa then
		if not _hordaActiva then
			return
		end
		_hordaActiva = false
		_enRondaEspecial = false
		detenerHiloRelampagos()

		if _originalGuardado then
			TweenService:Create(Lighting, TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				ClockTime = _origClockTime,
				Brightness = _origBrightness,
				Ambient = _origAmbient,
				OutdoorAmbient = _origOutdoorAmbient,
				ExposureCompensation = _origExposure,
			}):Play()
		end

		if _atmosfera and _atmosfera.Parent then
			local atm = _atmosfera
			local t = TweenService:Create(atm, TweenInfo.new(1.5), { Density = 0 })
			t:Play()
			t.Completed:Connect(function()
				if not _hordaActiva and atm.Parent then
					atm:Destroy()
				end
			end)
		end
		if _colorCorr and _colorCorr.Parent then
			local cc = _colorCorr
			local t = TweenService:Create(cc, TweenInfo.new(1.5), {
				Saturation = 0,
				Contrast = 0,
				TintColor = Color3.new(1, 1, 1),
			})
			t:Play()
			t.Completed:Connect(function()
				if not _hordaActiva and cc.Parent then
					cc:Destroy()
				end
			end)
		end
		if _bloom and _bloom.Parent then
			local bl = _bloom
			local t = TweenService:Create(bl, TweenInfo.new(1.5), { Intensity = 0 })
			t:Play()
			t.Completed:Connect(function()
				if not _hordaActiva and bl.Parent then
					bl:Destroy()
				end
			end)
		end
		_originalGuardado = false
		return
	end

	guardarLightingOriginal()
	local eraEspecial = _enRondaEspecial
	local recienActivada = not _hordaActiva
	_hordaActiva = true
	_enRondaEspecial = esRondaEspecial

	local atm, cc, bl = asegurarEfectosLighting()

	if recienActivada then
		TweenService:Create(Lighting, TweenInfo.new(2.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			ClockTime = 22.8,
			Brightness = 0.75,
			Ambient = Color3.fromRGB(22, 24, 30),
			OutdoorAmbient = Color3.fromRGB(36, 40, 50),
			ExposureCompensation = -0.25,
		}):Play()
		TweenService:Create(bl, TweenInfo.new(1.6), { Intensity = 0.45, Size = 18 }):Play()
	end

	if esRondaEspecial then
		TweenService:Create(atm, TweenInfo.new(1.8), {
			Density = 0.62,
			Offset = 0.18,
			Color = Color3.fromRGB(85, 28, 22),
			Decay = Color3.fromRGB(45, 12, 12),
			Haze = 3.4,
		}):Play()
		TweenService:Create(cc, TweenInfo.new(1.8), {
			Saturation = -0.15,
			Contrast = 0.20,
			TintColor = Color3.fromRGB(242, 198, 192),
		}):Play()
		if not eraEspecial or recienActivada then
			iniciarHiloRelampagos()
		end
	else
		detenerHiloRelampagos()
		TweenService:Create(atm, TweenInfo.new(1.8), {
			Density = 0.48,
			Offset = 0.1,
			Color = Color3.fromRGB(35, 38, 46),
			Decay = Color3.fromRGB(16, 14, 18),
			Haze = 2.2,
		}):Play()
		TweenService:Create(cc, TweenInfo.new(1.8), {
			Saturation = -0.22,
			Contrast = 0.16,
			TintColor = Color3.fromRGB(225, 228, 238),
		}):Play()
	end
end

local function construirInterfazFX()
	local previo = PlayerGui:FindFirstChild("UI_HordaAtmosfera")
	if previo then
		previo:Destroy()
	end

	_screenGui = Instance.new("ScreenGui")
	_screenGui.Name = "UI_HordaAtmosfera"
	_screenGui.ResetOnSpawn = false
	_screenGui.IgnoreGuiInset = true
	_screenGui.DisplayOrder = 15
	_screenGui.Parent = PlayerGui

	local configBordes = {
		{ Pos = UDim2.fromScale(0, 0), Size = UDim2.new(1, 0, 0.24, 0), Rot = 90 },
		{ Pos = UDim2.fromScale(0, 0.76), Size = UDim2.new(1, 0, 0.24, 0), Rot = -90 },
		{ Pos = UDim2.fromScale(0, 0), Size = UDim2.new(0.18, 0, 1, 0), Rot = 0 },
		{ Pos = UDim2.fromScale(0.82, 0), Size = UDim2.new(0.18, 0, 1, 0), Rot = 180 },
	}
	table.clear(_bordesSangre)
	for idx, bCfg in ipairs(configBordes) do
		local borde = Instance.new("Frame")
		borde.Name = "BordeSangre_" .. idx
		borde.Position = bCfg.Pos
		borde.Size = bCfg.Size
		borde.BackgroundColor3 = Color3.fromRGB(135, 10, 14)
		borde.BackgroundTransparency = 1
		borde.BorderSizePixel = 0
		borde.ZIndex = 2
		borde.Parent = _screenGui

		local grad = Instance.new("UIGradient")
		grad.Rotation = bCfg.Rot
		grad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.05),
			NumberSequenceKeypoint.new(0.45, 0.45),
			NumberSequenceKeypoint.new(1, 1),
		})
		grad.Parent = borde

		table.insert(_bordesSangre, { Frame = borde, BaseAlpha = 0 })
	end

	_nukeFlash = Instance.new("Frame")
	_nukeFlash.Name = "FlashNuke"
	_nukeFlash.Size = UDim2.fromScale(1, 1)
	_nukeFlash.BackgroundColor3 = Color3.fromRGB(255, 245, 215)
	_nukeFlash.BackgroundTransparency = 1
	_nukeFlash.BorderSizePixel = 0
	_nukeFlash.ZIndex = 20
	_nukeFlash.Parent = _screenGui

	_hitmarkerContenedor = Instance.new("Frame")
	_hitmarkerContenedor.Name = "HitmarkerReticle"
	_hitmarkerContenedor.AnchorPoint = Vector2.new(0.5, 0.5)
	_hitmarkerContenedor.Position = UDim2.fromScale(0.5, 0.5)
	_hitmarkerContenedor.Size = UDim2.fromOffset(42, 42)
	_hitmarkerContenedor.BackgroundTransparency = 1
	_hitmarkerContenedor.Visible = false
	_hitmarkerContenedor.ZIndex = 12
	_hitmarkerContenedor.Parent = _screenGui

	table.clear(_hitmarkerTicks)
	local angulos = { 45, 135, -45, -135 }
	local offsets = {
		Vector2.new(-8, -8),
		Vector2.new(8, -8),
		Vector2.new(-8, 8),
		Vector2.new(8, 8),
	}
	for i = 1, 4 do
		local tick = Instance.new("Frame")
		tick.Name = "Tick_" .. i
		tick.AnchorPoint = Vector2.new(0.5, 0.5)
		tick.Position = UDim2.new(0.5, offsets[i].X, 0.5, offsets[i].Y)
		tick.Size = UDim2.fromOffset(10, 2)
		tick.Rotation = angulos[i]
		tick.BackgroundColor3 = Color3.new(1, 1, 1)
		tick.BorderSizePixel = 0
		tick.Parent = _hitmarkerContenedor
		table.insert(_hitmarkerTicks, tick)
	end
end

local function mostrarHitmarker(esCritico: boolean, esMuerte: boolean)
	if _hitmarkerFadeThread then
		local h = _hitmarkerFadeThread
		_hitmarkerFadeThread = nil
		if coroutine.running() ~= h then
			pcall(task.cancel, h)
		end
	end

	local color = if esCritico or esMuerte
		then Color3.fromRGB(255, 65, 65)
		else Color3.fromRGB(245, 245, 245)
	local tamano = if esCritico or esMuerte then UDim2.fromOffset(52, 52) else UDim2.fromOffset(38, 38)

	_hitmarkerContenedor.Size = tamano
	_hitmarkerContenedor.Visible = true
	for _, tick in ipairs(_hitmarkerTicks) do
		tick.BackgroundColor3 = color
		tick.BackgroundTransparency = 0
	end

	TweenService:Create(_hitmarkerContenedor, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(32, 32),
	}):Play()

	local pitch = if esCritico then 2.3 elseif esMuerte then 1.45 else 1.85
	reproducirSonidoLocal("rbxasset://sounds/electronicpingshort.wav", if esCritico then 0.55 else 0.4, pitch)

	_hitmarkerFadeThread = task.delay(0.12, function()
		for _, tick in ipairs(_hitmarkerTicks) do
			TweenService:Create(tick, TweenInfo.new(0.1), { BackgroundTransparency = 1 }):Play()
		end
		task.wait(0.11)
		_hitmarkerContenedor.Visible = false
		_hitmarkerFadeThread = nil
	end)
end

local function emitirSangre3D(posicion: Vector3, esMuerte: boolean)
	local anchor = Instance.new("Part")
	anchor.Name = "BloodBurstFX"
	anchor.Size = Vector3.new(0.4, 0.4, 0.4)
	anchor.Position = posicion
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Parent = Workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(115, 10, 14), Color3.fromRGB(45, 4, 6))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(0.25, 0.55)
	emitter.Speed = NumberRange.new(6, 16)
	emitter.SpreadAngle = Vector2.new(85, 85)
	emitter.Acceleration = Vector3.new(0, -32, 0)
	emitter.Rate = 0
	emitter.Parent = anchor
	emitter:Emit(if esMuerte then 16 else 8)

	Debris:AddItem(anchor, 0.85)
end

local function dispararFlashNuke()
	_nukeFlash.BackgroundTransparency = 0.08
	_trauma = math.min(1, _trauma + 0.85)
	reproducirSonidoLocal("rbxasset://sounds/collide.wav", 0.9, 0.45)
	TweenService:Create(_nukeFlash, TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	}):Play()
end

local function vincularPersonaje(character: Model)
	local hum = character:WaitForChild("Humanoid", 5)
	if not hum or not hum:IsA("Humanoid") then
		return
	end
	_saludActual = hum.Health
	_saludMax = math.max(1, hum.MaxHealth)
	_ultimaSalud = _saludActual

	hum.HealthChanged:Connect(function(nuevaSalud: number)
		_saludMax = math.max(1, hum.MaxHealth)
		if nuevaSalud < _ultimaSalud and _hordaActiva then
			local perdida = _ultimaSalud - nuevaSalud
			_trauma = math.min(1, _trauma + math.clamp(perdida / 45, 0.18, 0.55))
		end
		_ultimaSalud = nuevaSalud
		_saludActual = nuevaSalud
	end)
end

function HordeAtmosphere.Iniciar()
	construirInterfazFX()

	if LocalPlayer.Character then
		task.spawn(vincularPersonaje, LocalPlayer.Character)
	end
	LocalPlayer.CharacterAdded:Connect(vincularPersonaje)

	RunService.RenderStepped:Connect(function(dt: number)
		local tiempo = os.clock()

		-- Viñeta de sangre por salud baja / daño durante horda
		local ratio = if _saludMax > 0 then math.clamp(_saludActual / _saludMax, 0, 1) else 1
		local abatido = LocalPlayer:GetAttribute("HordaAbatido") == true
		local transparenciaObjetivo = 1
		if _hordaActiva and (ratio < 0.75 or abatido) then
			local intensidad = if abatido
				then 0.82
				else math.clamp((0.75 - ratio) / 0.65, 0, 0.85)
			if ratio < 0.35 or abatido then
				local pulso = (math.sin(tiempo * 6.5) * 0.5 + 0.5) * 0.18
				intensidad = math.clamp(intensidad + pulso, 0, 0.92)
			end
			transparenciaObjetivo = 1 - intensidad
		end
		for _, bordeInfo in ipairs(_bordesSangre) do
			local actual = bordeInfo.Frame.BackgroundTransparency
			bordeInfo.Frame.BackgroundTransparency = actual + (transparenciaObjetivo - actual) * math.clamp(dt * 10, 0, 1)
		end

		-- Sacudida de cámara por trauma
		if _trauma > 0.005 then
			local cam = Workspace.CurrentCamera
			if cam then
				local mag = _trauma * _trauma * 0.85
				local rx = (math.random() - 0.5) * 2 * math.rad(mag * 2.2)
				local ry = (math.random() - 0.5) * 2 * math.rad(mag * 2.2)
				local rz = (math.random() - 0.5) * 2 * math.rad(mag * 3.0)
				cam.CFrame = cam.CFrame * CFrame.Angles(rx, ry, rz)
			end
			_trauma = math.max(0, _trauma - dt * 2.4)
		else
			_trauma = 0
		end
	end)

	local evEstado = EventosRemotos.EstadoHordaActualizado
	if evEstado and evEstado:IsA("RemoteEvent") then
		evEstado.OnClientEvent:Connect(function(datosEstado: any)
			if typeof(datosEstado) ~= "table" then
				return
			end
			local estado = tostring(datosEstado.Estado or "Inactiva")
			local activa = estado ~= "Inactiva" and estado ~= "Finalizando"
			aplicarAtmosferaHorda(activa, datosEstado.EsRondaEspecial == true)
		end)
	end

	local evVisual = EventosRemotos.ZombieEventoVisual
	if evVisual and evVisual:IsA("RemoteEvent") then
		evVisual.OnClientEvent:Connect(function(evento: any)
			if typeof(evento) ~= "table" then
				return
			end
			if evento.Tipo == "Impacto" or evento.Tipo == "Muerte" then
				mostrarHitmarker(evento.EsCritico == true, evento.EsMuerte == true or evento.Tipo == "Muerte")
				if typeof(evento.Posicion) == "Vector3" then
					emitirSangre3D(evento.Posicion, evento.EsMuerte == true or evento.Tipo == "Muerte")
				end
			elseif evento.Tipo == "PowerUp" and evento.PowerUpId == "KABOOM" then
				dispararFlashNuke()
			elseif evento.Tipo == "Ataque" then
				_trauma = math.min(1, _trauma + 0.4)
			end
		end)
	end

	task.spawn(function()
		local fnEstado = EventosRemotos.ObtenerEstadoHorda
		if fnEstado and fnEstado:IsA("RemoteFunction") then
			local ok, payload = pcall(function()
				return fnEstado:InvokeServer()
			end)
			if ok and typeof(payload) == "table" then
				local estado = tostring((payload :: any).Estado or "Inactiva")
				local activa = estado ~= "Inactiva" and estado ~= "Finalizando"
				aplicarAtmosferaHorda(activa, (payload :: any).EsRondaEspecial == true)
			end
		end
	end)
end

return HordeAtmosphere

