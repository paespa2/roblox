--!strict
--[[
	ZombieService.luau
	Administra la creación, variantes visuales, registro, daño, recompensas
	y limpieza de zombis de la horda en el servidor.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Datos = require(ReplicatedStorage.Shared.Datos)
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)
local GestorDatos = require(script.Parent.Parent.GestorDatos)
local HordeSession = require(script.Parent.HordeSession)
local UtilidadesMapaHorda = require(script.Parent.UtilidadesMapaHorda)

local ConfigZombis = Datos.Zombis
local General = ConfigZombis.General

export type EstadoZombi = "Idle" | "Detecting" | "Chasing" | "Attacking" | "Stunned" | "Dead"

export type RegistroZombi = {
	Id: number,
	SesionId: number,
	Modelo: Model,
	Humanoid: Humanoid,
	HRP: BasePart,
	Variante: Datos.VarianteZombi,
	Estado: EstadoZombi,
	VelocidadBase: number,
	DanioAtaque: number,
	CooldownAtaque: number,
	UltimoAtaque: number,
	AturdidoHasta: number,
	InmuneAturdimientoHasta: number,
	ObjetivoActual: Player?,
	UltimoChequeoObjetivo: number,
	UltimoRecalculoRuta: number,
	UltimaPosObjetivoRuta: Vector3?,
	WaypointsActuales: { PathWaypoint }?,
	IndiceWaypoint: number,
	RutaBloqueada: boolean,
	FallosRutaConsecutivos: number,
	UltimaPosComprobada: Vector3,
	UltimoChequeoAtasco: number,
	ContadorAtaque: number,
	ContadorGolpe: number,
	TieneLuzDinamica: boolean,
	Muerto: boolean,
	UltimoAtacante: Player?,
	PathBlockedConn: RBXScriptConnection?,
	Conexiones: { RBXScriptConnection },
	BillboardVida: Frame?,
}

local ZombieService = {}

local _zombisActivos: { [Model]: RegistroZombi } = {}
local _contadorId = 0
local _lucesDinamicasActivas = 0
local _onZombiMuertoCallback: ((RegistroZombi) -> ())? = nil

local function elegirVarianteParaOleada(numeroOleada: number): any
	local disponibles = {}
	local pesoTotal = 0
	for _, variante in ipairs(ConfigZombis.Variantes) do
		if numeroOleada >= variante.OleadaMinima then
			table.insert(disponibles, variante)
			pesoTotal += variante.PesoAparicion
		end
	end

	if #disponibles == 0 then
		return ConfigZombis.Variantes[1]
	end

	local tirada = math.random() * pesoTotal
	local acumulado = 0
	for _, variante in ipairs(disponibles) do
		acumulado += variante.PesoAparicion
		if tirada <= acumulado then
			return variante
		end
	end

	return disponibles[1]
end

local function variarTonoPiel(base: Color3): Color3
	local h, s, v = base:ToHSV()
	local dh = (math.random() - 0.5) * 0.04
	local dv = (math.random() - 0.5) * 0.10
	return Color3.fromHSV(math.clamp(h + dh, 0, 1), s, math.clamp(v + dv, 0.2, 0.9))
end

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

local function soldarAccesorio(padre: BasePart, accesorio: BasePart)
	accesorio.Anchored = false
	accesorio.CanCollide = false
	accesorio.CanTouch = false
	accesorio.Massless = true
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = padre
	weld.Part1 = accesorio
	weld.Parent = padre
end

local function construirRigZombi(
	variante: Datos.VarianteZombi,
	escala: number
): (Model, Humanoid, BasePart, Frame, boolean)
	local modelo = Instance.new("Model")
	modelo.Name = "Zombi_" .. variante.Id

	local tonoPiel = variarTonoPiel(variante.ColorPiel)
	local usaLuz = false
	local maxLuces = General.MaxLucesDinamicasZombis or 6

	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(2 * escala, 2 * escala, 1 * escala)
	hrp.Transparency = 1
	hrp.CanCollide = false
	hrp.CanTouch = true
	hrp.Anchored = false
	hrp.Parent = modelo
	modelo.PrimaryPart = hrp

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2 * escala, 2 * escala, 1 * escala)
	torso.Color = variante.ColorRopa
	torso.Material = Enum.Material.Fabric
	torso.CanCollide = true
	torso.CanTouch = true
	torso.Anchored = false
	torso.Parent = modelo

	-- Harapos / detalle de silueta sin inflar Parts
	local harapo = Instance.new("Part")
	harapo.Name = "HarapoPecho"
	harapo.Size = Vector3.new(1.5 * escala, 1.3 * escala, 1.08 * escala)
	harapo.Color = variante.ColorRopa:Lerp(Color3.new(0.1, 0.1, 0.1), 0.45)
	harapo.Material = Enum.Material.CorrodedMetal
	harapo.CFrame = torso.CFrame * CFrame.new(0.15 * escala, -0.1 * escala, 0)
	harapo.Parent = modelo
	soldarAccesorio(torso, harapo)

	if variante.Id == "BrutoCaramelo" then
		local hombrera = Instance.new("Part")
		hombrera.Name = "HombreraBruto"
		hombrera.Size = Vector3.new(2.55 * escala, 0.55 * escala, 1.25 * escala)
		hombrera.Color = Color3.fromRGB(52, 34, 34)
		hombrera.Material = Enum.Material.Slate
		hombrera.CFrame = torso.CFrame * CFrame.new(0, 0.8 * escala, 0)
		hombrera.Parent = modelo
		soldarAccesorio(torso, hombrera)
	end

	local cabeza = Instance.new("Part")
	cabeza.Name = "Head"
	cabeza.Size = Vector3.new(2 * escala, 1 * escala, 1 * escala)
	cabeza.Color = tonoPiel
	cabeza.Material = Enum.Material.SmoothPlastic
	cabeza.CanCollide = false
	cabeza.CanTouch = true
	cabeza.Anchored = false
	cabeza.Parent = modelo

	local meshCabeza = Instance.new("SpecialMesh")
	meshCabeza.Name = "Mesh"
	meshCabeza.MeshType = Enum.MeshType.Head
	meshCabeza.Scale = Vector3.new(1.25, 1.25, 1.25)
	meshCabeza.Parent = cabeza

	-- Cara 2D personalizada (Very scary face) o fallback procedural
	local idCara = variante.TexturaCara or ConfigZombis.General.TexturaCara
	if idCara and idCara ~= "" then
		local caraDecal = Instance.new("Decal")
		caraDecal.Name = "face"
		caraDecal.Texture = idCara
		caraDecal.Face = Enum.NormalId.Front
		caraDecal.Parent = cabeza
	else
		-- Ojos brillantes amenazantes visibles a distancia
		for _, xOjo in ipairs({ -0.25 * escala, 0.25 * escala }) do
			local ojo = Instance.new("Part")
			ojo.Name = "OjoBrillante"
			ojo.Size = Vector3.new(0.22 * escala, 0.16 * escala, 0.12 * escala)
			ojo.Color = variante.ColorOjos
			ojo.Material = Enum.Material.Neon
			ojo.CFrame = cabeza.CFrame * CFrame.new(xOjo, 0.12 * escala, -0.58 * escala)
			ojo.Parent = modelo
			soldarAccesorio(cabeza, ojo)
		end

		-- Mandíbula deteriorada / expresión amenazante
		local boca = Instance.new("Part")
		boca.Name = "Mandibula"
		boca.Size = Vector3.new(0.58 * escala, 0.16 * escala, 0.12 * escala)
		boca.Color = Color3.fromRGB(30, 18, 18)
		boca.Material = Enum.Material.SmoothPlastic
		boca.CFrame = cabeza.CFrame * CFrame.new(0, -0.26 * escala, -0.57 * escala)
		boca.Parent = modelo
		soldarAccesorio(cabeza, boca)
	end

	-- Brazos articulados con mangas rasgadas
	local brazoIzq = Instance.new("Part")
	brazoIzq.Name = "Left Arm"
	brazoIzq.Size = Vector3.new(1 * escala, 2 * escala, 1 * escala)
	brazoIzq.Color = tonoPiel
	brazoIzq.Material = Enum.Material.SmoothPlastic
	brazoIzq.CanCollide = false
	brazoIzq.CanTouch = true
	brazoIzq.Anchored = false
	brazoIzq.Parent = modelo

	local mangaIzq = Instance.new("Part")
	mangaIzq.Name = "MangaIzq"
	mangaIzq.Size = Vector3.new(1.08 * escala, 0.85 * escala, 1.08 * escala)
	mangaIzq.Color = variante.ColorRopa
	mangaIzq.Material = Enum.Material.Fabric
	mangaIzq.CFrame = brazoIzq.CFrame * CFrame.new(0, 0.55 * escala, 0)
	mangaIzq.Parent = modelo
	soldarAccesorio(brazoIzq, mangaIzq)

	local brazoDer = Instance.new("Part")
	brazoDer.Name = "Right Arm"
	brazoDer.Size = Vector3.new(1 * escala, 2 * escala, 1 * escala)
	brazoDer.Color = tonoPiel
	brazoDer.Material = Enum.Material.SmoothPlastic
	brazoDer.CanCollide = false
	brazoDer.CanTouch = true
	brazoDer.Anchored = false
	brazoDer.Parent = modelo

	local mangaDer = Instance.new("Part")
	mangaDer.Name = "MangaDer"
	mangaDer.Size = Vector3.new(1.08 * escala, 0.75 * escala, 1.08 * escala)
	mangaDer.Color = variante.ColorRopa
	mangaDer.Material = Enum.Material.Fabric
	mangaDer.CFrame = brazoDer.CFrame * CFrame.new(0, 0.6 * escala, 0)
	mangaDer.Parent = modelo
	soldarAccesorio(brazoDer, mangaDer)

	-- Piernas con pantalones desgastados
	local piernaIzq = Instance.new("Part")
	piernaIzq.Name = "Left Leg"
	piernaIzq.Size = Vector3.new(1 * escala, 2 * escala, 1 * escala)
	piernaIzq.Color = variante.ColorPantalon
	piernaIzq.Material = Enum.Material.Fabric
	piernaIzq.CanCollide = false
	piernaIzq.CanTouch = true
	piernaIzq.Anchored = false
	piernaIzq.Parent = modelo

	local piernaDer = Instance.new("Part")
	piernaDer.Name = "Right Leg"
	piernaDer.Size = Vector3.new(1 * escala, 2 * escala, 1 * escala)
	piernaDer.Color = variante.ColorPantalon
	piernaDer.Material = Enum.Material.Fabric
	piernaDer.CanCollide = false
	piernaDer.CanTouch = true
	piernaDer.Anchored = false
	piernaDer.Parent = modelo

	-- Cristales de azúcar contaminada para variantes especiales
	if variante.TieneCristalesDulces then
		local cristal = Instance.new("Part")
		cristal.Name = "CristalAzucar"
		cristal.Size = Vector3.new(0.55 * escala, 0.95 * escala, 0.55 * escala)
		cristal.Color = variante.ColorOjos
		cristal.Material = Enum.Material.Neon
		cristal.Transparency = 0.2
		cristal.CFrame = torso.CFrame
			* CFrame.new(0.65 * escala, 0.85 * escala, 0.25 * escala)
			* CFrame.Angles(math.rad(-20), 0, math.rad(-25))
		cristal.Parent = modelo
		soldarAccesorio(torso, cristal)

		if _lucesDinamicasActivas < maxLuces then
			local luzCristal = Instance.new("PointLight")
			luzCristal.Color = variante.ColorOjos
			luzCristal.Range = 8
			luzCristal.Brightness = 1.4
			luzCristal.Parent = cristal
			usaLuz = true
		end
	end

	-- Efectos visuales optimizados para Zombi de Lava (sin saturar Decals ni luces)
	if variante.EsDeFuego then
		local partesLava = { torso, cabeza, brazoIzq, brazoDer, piernaIzq, piernaDer }
		for _, parte in ipairs(partesLava) do
			parte.Color = Color3.fromRGB(28, 22, 22)
			parte.Material = Enum.Material.Basalt
		end
		harapo.Color = Color3.fromRGB(220, 95, 25)
		harapo.Material = Enum.Material.Neon

		local fuego = Instance.new("Fire")
		fuego.Name = "LavaFire"
		fuego.Heat = 7
		fuego.Size = math.clamp(4.2 * escala, 3, 6)
		fuego.Color = Color3.fromRGB(240, 130, 40)
		fuego.SecondaryColor = Color3.fromRGB(150, 60, 20)
		fuego.Parent = torso

		if not usaLuz and _lucesDinamicasActivas < maxLuces then
			local luzLava = Instance.new("PointLight")
			luzLava.Name = "LavaAura"
			luzLava.Color = Color3.fromRGB(255, 115, 30)
			luzLava.Range = 12 * escala
			luzLava.Brightness = 1.8
			luzLava.Parent = torso
			usaLuz = true
		end
	end

	-- Efectos visuales optimizados para Ice Zombie
	if variante.EsDeHielo then
		local partesHielo = { torso, cabeza, brazoIzq, brazoDer, piernaIzq, piernaDer }
		for _, parte in ipairs(partesHielo) do
			parte.Color = Color3.fromRGB(0, 225, 245)
			parte.Material = Enum.Material.Ice
		end

		local fuegoHielo = Instance.new("Fire")
		fuegoHielo.Name = "IceFire"
		fuegoHielo.Heat = 6
		fuegoHielo.Size = math.clamp(4.0 * escala, 3, 6)
		fuegoHielo.Color = Color3.fromRGB(85, 255, 255)
		fuegoHielo.SecondaryColor = Color3.fromRGB(0, 190, 255)
		fuegoHielo.Parent = torso

		if not usaLuz and _lucesDinamicasActivas < maxLuces then
			local luzHielo = Instance.new("PointLight")
			luzHielo.Name = "IceAura"
			luzHielo.Color = Color3.fromRGB(85, 255, 255)
			luzHielo.Range = 12 * escala
			luzHielo.Brightness = 1.6
			luzHielo.Parent = torso
			usaLuz = true
		end
	end

	-- Efectos visuales optimizados para Toxic Zombie
	if variante.EsToxico then
		local partesToxico = { torso, cabeza, brazoIzq, brazoDer, piernaIzq, piernaDer }
		for _, parte in ipairs(partesToxico) do
			parte.Color = Color3.fromRGB(44, 101, 29)
		end

		local emisorVeneno = Instance.new("ParticleEmitter")
		emisorVeneno.Name = "ToxicSparks"
		emisorVeneno.Texture = "rbxassetid://332655294"
		emisorVeneno.Color = ColorSequence.new(Color3.fromRGB(113, 255, 61))
		emisorVeneno.Rate = 10
		emisorVeneno.Lifetime = NumberRange.new(0.7, 1.3)
		emisorVeneno.Speed = NumberRange.new(1.5, 4)
		emisorVeneno.Size = NumberSequence.new(0.45, 0.9)
		emisorVeneno.Parent = torso

		if not usaLuz and _lucesDinamicasActivas < maxLuces then
			local luzToxica = Instance.new("PointLight")
			luzToxica.Name = "ToxicAura"
			luzToxica.Color = Color3.fromRGB(113, 255, 61)
			luzToxica.Range = 12 * escala
			luzToxica.Brightness = 1.5
			luzToxica.Parent = torso
			usaLuz = true
		end
	end

	if usaLuz then
		_lucesDinamicasActivas += 1
	end

	-- Articulaciones Motor6D (postura ligeramente encorvada hacia adelante)
	crearMotor6D(
		"RootJoint",
		hrp,
		torso,
		CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-10), 0, 0),
		CFrame.new(0, 0, 0)
	)
	crearMotor6D(
		"Neck",
		torso,
		cabeza,
		CFrame.new(0, 1.0 * escala, -0.1 * escala) * CFrame.Angles(math.rad(8), 0, 0),
		CFrame.new(0, -0.5 * escala, 0)
	)
	crearMotor6D(
		"Left Shoulder",
		torso,
		brazoIzq,
		CFrame.new(-1.5 * escala, 0.5 * escala, 0),
		CFrame.new(0, 0.5 * escala, 0)
	)
	crearMotor6D(
		"Right Shoulder",
		torso,
		brazoDer,
		CFrame.new(1.5 * escala, 0.5 * escala, 0),
		CFrame.new(0, 0.5 * escala, 0)
	)
	crearMotor6D(
		"Left Hip",
		torso,
		piernaIzq,
		CFrame.new(-0.5 * escala, -1.0 * escala, 0),
		CFrame.new(0, 1.0 * escala, 0)
	)
	crearMotor6D(
		"Right Hip",
		torso,
		piernaDer,
		CFrame.new(0.5 * escala, -1.0 * escala, 0),
		CFrame.new(0, 1.0 * escala, 0)
	)

	-- Humanoid y Animator oficiales (desactivar estados innecesarios para ahorrar cómputo)
	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.RigType = Enum.HumanoidRigType.R6
	humanoid.AutomaticScalingEnabled = false
	humanoid.BreakJointsOnDeath = false
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	for _, estadoDeshabilitado in ipairs({
		Enum.HumanoidStateType.Seated,
		Enum.HumanoidStateType.Climbing,
		Enum.HumanoidStateType.Swimming,
		Enum.HumanoidStateType.Flying,
		Enum.HumanoidStateType.Ragdoll,
		Enum.HumanoidStateType.FallingDown,
	}) do
		humanoid:SetStateEnabled(estadoDeshabilitado, false)
	end
	humanoid.Parent = modelo

	local grupoColision = General.NombreCollisionGroupZombis or "ZombisHorda"
	for _, desc in ipairs(modelo:GetChildren()) do
		if desc:IsA("BasePart") then
			pcall(function()
				desc.CollisionGroup = grupoColision
			end)
		end
	end

	local animator = Instance.new("Animator")
	animator.Parent = humanoid

	-- Carpeta de Animations preparada para AnimationIds reales
	local carpetaAnims = Instance.new("Folder")
	carpetaAnims.Name = "Animaciones"
	carpetaAnims.Parent = humanoid

	for nombreAnim, animId in pairs(ConfigZombis.Animaciones.Zombi) do
		local anim = Instance.new("Animation")
		anim.Name = nombreAnim
		anim.AnimationId = animId
		anim.Parent = carpetaAnims
	end

	-- Barra de vida compacta y nombre sobre el zombi
	local bbg = Instance.new("BillboardGui")
	bbg.Name = "BarraVidaZombi"
	bbg.Size = UDim2.fromOffset(110, 28)
	bbg.StudsOffset = Vector3.new(0, 2.2 * escala, 0)
	bbg.AlwaysOnTop = false
	bbg.MaxDistance = 55
	bbg.Parent = cabeza

	local lblNombre = Instance.new("TextLabel")
	lblNombre.Size = UDim2.new(1, 0, 0, 14)
	lblNombre.BackgroundTransparency = 1
	lblNombre.Font = Enum.Font.FredokaOne
	lblNombre.Text = variante.Nombre
	lblNombre.TextColor3 = Color3.fromRGB(255, 220, 220)
	lblNombre.TextSize = 11
	lblNombre.TextStrokeTransparency = 0.4
	lblNombre.Parent = bbg

	local fondoBarra = Instance.new("Frame")
	fondoBarra.Size = UDim2.new(1, 0, 0, 7)
	fondoBarra.Position = UDim2.fromOffset(0, 16)
	fondoBarra.BackgroundColor3 = Color3.fromRGB(30, 18, 22)
	fondoBarra.BorderSizePixel = 0
	fondoBarra.Parent = bbg

	local cornerFondo = Instance.new("UICorner")
	cornerFondo.CornerRadius = UDim.new(1, 0)
	cornerFondo.Parent = fondoBarra

	local rellenoBarra = Instance.new("Frame")
	rellenoBarra.Name = "Relleno"
	rellenoBarra.Size = UDim2.fromScale(1, 1)
	rellenoBarra.BackgroundColor3 = Color3.fromRGB(220, 50, 60)
	rellenoBarra.BorderSizePixel = 0
	rellenoBarra.Parent = fondoBarra

	local cornerRelleno = Instance.new("UICorner")
	cornerRelleno.CornerRadius = UDim.new(1, 0)
	cornerRelleno.Parent = rellenoBarra

	return modelo, humanoid, hrp, rellenoBarra, usaLuz
end

local function reproducirSonidoEnParte(
	parte: BasePart,
	soundId: string,
	volumen: number,
	pitch: number?
)
	if soundId == "" or not parte or not parte.Parent then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = soundId
	s.Volume = volumen
	s.PlaybackSpeed = pitch or 1.0
	s.RollOffMaxDistance = 65
	s.Parent = parte
	s:Play()
	task.delay(2.5, function()
		if s.Parent then
			s:Destroy()
		end
	end)
end

local function emitirEfectoAparicion(hrp: BasePart, color: Color3)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "EfectoAparicionZombi"
	emitter.Color = ColorSequence.new(color, Color3.fromRGB(20, 20, 24))
	emitter.Size = NumberSequence.new(1.4, 0.2)
	emitter.Lifetime = NumberRange.new(0.4, 0.9)
	emitter.Speed = NumberRange.new(4, 10)
	emitter.Rate = 0
	emitter.Parent = hrp
	emitter:Emit(20)
	task.delay(1.2, function()
		if emitter.Parent then
			emitter:Destroy()
		end
	end)
end

local function limpiarZombi(registro: RegistroZombi)
	if registro.PathBlockedConn and registro.PathBlockedConn.Connected then
		registro.PathBlockedConn:Disconnect()
	end
	registro.PathBlockedConn = nil
	for _, conn in ipairs(registro.Conexiones) do
		if conn.Connected then
			conn:Disconnect()
		end
	end
	table.clear(registro.Conexiones)
	if registro.TieneLuzDinamica then
		_lucesDinamicasActivas = math.max(0, _lucesDinamicasActivas - 1)
		registro.TieneLuzDinamica = false
	end
	_zombisActivos[registro.Modelo] = nil
	if registro.Modelo.Parent then
		registro.Modelo:Destroy()
	end
end

local function procesarMuerteZombi(registro: RegistroZombi)
	if registro.Muerto then
		return
	end
	registro.Muerto = true
	registro.Estado = "Dead"
	registro.Modelo:SetAttribute("EstadoIA", "Dead")
	registro.Humanoid.WalkSpeed = 0
	pcall(function()
		registro.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
	end)

	if registro.PathBlockedConn and registro.PathBlockedConn.Connected then
		registro.PathBlockedConn:Disconnect()
	end
	registro.PathBlockedConn = nil

	-- Desactivar colisiones para no estorbar durante animación de muerte
	for _, desc in ipairs(registro.Modelo:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.CanCollide = false
			desc.CanTouch = false
		end
	end
	registro.HRP.Anchored = true

	-- Efecto de llamarada final al morir si es Zombi de Fuego o de Hielo
	if registro.Variante and (registro.Variante.EsDeFuego or registro.Variante.EsDeHielo) then
		for _, desc in ipairs(registro.Modelo:GetDescendants()) do
			if desc:IsA("Fire") then
				desc.Size = 9
				desc.Heat = 14
			end
		end
	end

	reproducirSonidoEnParte(registro.HRP, ConfigZombis.Sonidos.MuerteZombi, 0.7, 0.72)

	-- Recompensar únicamente si la sesión sigue activa y el atacante es participante válido
	if HordeSession.EsSesionActiva(registro.SesionId) then
		local atacante = registro.UltimoAtacante
		if not atacante then
			local tagCreator = registro.Humanoid:FindFirstChild("creator")
			if tagCreator and tagCreator:IsA("ObjectValue") and tagCreator.Value and tagCreator.Value:IsA("Player") then
				atacante = tagCreator.Value
				registro.UltimoAtacante = atacante
			end
		end
		if atacante and HordeSession.EsParticipanteVivo(atacante) and atacante:IsDescendantOf(Players) then
			GestorDatos.AgregarPesos(atacante, registro.Variante.RecompensaPesos)
			GestorDatos.AgregarFama(atacante, 1)
			GestorDatos.AgregarDulce(
				atacante,
				"Dulce_Gomita",
				General.MunicionDropPorMuerte
			)
			HordeSession.RegistrarBaja(atacante, registro.Variante.RecompensaPesos, 1)
		end

		if _onZombiMuertoCallback then
			task.spawn(_onZombiMuertoCallback, registro)
		end
	end

	task.delay(General.TiempoDespawnMuerto, function()
		limpiarZombi(registro)
	end)
end

function ZombieService.EstablecerCallbackMuerte(callback: (RegistroZombi) -> ())
	_onZombiMuertoCallback = callback
end

function ZombieService.ObtenerZombisActivos(): { [Model]: RegistroZombi }
	return _zombisActivos
end

function ZombieService.ContarZombisVivos(): number
	local total = 0
	for _, reg in pairs(_zombisActivos) do
		if not reg.Muerto and reg.Modelo.Parent then
			total += 1
		end
	end
	return total
end

function ZombieService.EsZombi(instancia: Instance?): Model?
	if not instancia then
		return nil
	end
	local modelo = if instancia:IsA("Model")
		then instancia
		else instancia:FindFirstAncestorWhichIsA("Model")
	if modelo and modelo:GetAttribute("EsZombie") == true then
		return modelo
	end
	return nil
end

function ZombieService.GenerarZombi(
	posicion: Vector3,
	numeroOleada: number,
	configOleada: any,
	sesionId: number,
	varianteForzada: any?
): RegistroZombi?
	if not HordeSession.EsSesionActiva(sesionId) then
		return nil
	end

	UtilidadesMapaHorda.ConfigurarCollisionGroups()
	local variante = varianteForzada or elegirVarianteParaOleada(numeroOleada)
	local escala = variante.Escala
	local modelo, humanoid, hrp, barraVida, usaLuz = construirRigZombi(variante, escala)

	_contadorId += 1
	local idZombi = _contadorId

	local vidaFinal = math.round(configOleada.VidaBase * variante.MultiplicadorVida)
	local velocidadFinal = configOleada.VelocidadBase * variante.MultiplicadorVelocidad
	local danioFinal = math.round(configOleada.DanioBase * variante.MultiplicadorDanio)
	local cooldownFinal = configOleada.CooldownAtaque * (variante.MultiplicadorCooldownAtaque or 1.0)

	humanoid.MaxHealth = vidaFinal
	humanoid.Health = vidaFinal
	humanoid.WalkSpeed = velocidadFinal
	pcall(function()
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	end)

	modelo:SetAttribute("EsZombie", true)
	modelo:SetAttribute("IdZombi", idZombi)
	modelo:SetAttribute("VarianteId", variante.Id)
	modelo:SetAttribute("EsDeFuego", variante.EsDeFuego == true)
	modelo:SetAttribute("EsDeHielo", variante.EsDeHielo == true)
	modelo:SetAttribute("EsToxico", variante.EsToxico == true)
	modelo:SetAttribute("EstadoIA", "Detecting")
	modelo:SetAttribute("VelocidadBase", velocidadFinal)
	modelo:SetAttribute("ContadorAtaque", 0)
	modelo:SetAttribute("ContadorGolpe", 0)

	local carpetaZombis = UtilidadesMapaHorda.ObtenerCarpetaZombis()
	modelo:PivotTo(CFrame.new(posicion))
	modelo.Parent = carpetaZombis

	-- Autoridad de físicas en el servidor (raíz del ensamblaje)
	pcall(function()
		hrp:SetNetworkOwner(nil)
	end)

	emitirEfectoAparicion(hrp, variante.ColorOjos)
	if RunService:IsRunning() then
		for _, p in ipairs(HordeSession.ObtenerParticipantes()) do
			pcall(function()
				EventosRemotos.ZombieEventoVisual:FireClient(p, {
					Tipo = "Aparicion",
					Posicion = posicion,
					VarianteId = variante.Id,
				})
			end)
		end
	end

	local registro: RegistroZombi = {
		Id = idZombi,
		SesionId = sesionId,
		Modelo = modelo,
		Humanoid = humanoid,
		HRP = hrp,
		Variante = variante,
		Estado = "Detecting",
		VelocidadBase = velocidadFinal,
		DanioAtaque = danioFinal,
		CooldownAtaque = cooldownFinal,
		UltimoAtaque = 0,
		AturdidoHasta = 0,
		InmuneAturdimientoHasta = 0,
		ObjetivoActual = nil,
		UltimoChequeoObjetivo = 0,
		UltimoRecalculoRuta = 0,
		UltimaPosObjetivoRuta = nil,
		WaypointsActuales = nil,
		IndiceWaypoint = 1,
		RutaBloqueada = false,
		FallosRutaConsecutivos = 0,
		UltimaPosComprobada = posicion,
		UltimoChequeoAtasco = os.clock(),
		ContadorAtaque = 0,
		ContadorGolpe = 0,
		TieneLuzDinamica = usaLuz,
		Muerto = false,
		UltimoAtacante = nil,
		PathBlockedConn = nil,
		Conexiones = {},
		BillboardVida = barraVida,
	}

	local ultimaVidaValida = vidaFinal
	local revirtiendoVida = false

	table.insert(
		registro.Conexiones,
		humanoid.HealthChanged:Connect(function(nuevaVida: number)
			if revirtiendoVida or registro.Muerto then
				return
			end

			if nuevaVida < ultimaVidaValida then
				local tagCreator = humanoid:FindFirstChild("creator")
				local playerCreator: Player? = if tagCreator
						and tagCreator:IsA("ObjectValue")
						and tagCreator.Value
						and tagCreator.Value:IsA("Player")
					then tagCreator.Value :: Player
					else registro.UltimoAtacante

				if not playerCreator or not HordeSession.EsParticipanteVivo(playerCreator) then
					revirtiendoVida = true
					humanoid.Health = ultimaVidaValida
					revirtiendoVida = false
					if tagCreator then
						tagCreator:Destroy()
					end
					return
				end

				registro.UltimoAtacante = playerCreator
				ultimaVidaValida = math.max(0, nuevaVida)
			elseif nuevaVida > ultimaVidaValida then
				ultimaVidaValida = nuevaVida
			end

			if registro.BillboardVida and registro.BillboardVida.Parent then
				local ratio = math.clamp(nuevaVida / humanoid.MaxHealth, 0, 1)
				registro.BillboardVida.Size = UDim2.fromScale(ratio, 1)
			end
			if nuevaVida <= 0 and not registro.Muerto then
				procesarMuerteZombi(registro)
			end
		end)
	)

	table.insert(
		registro.Conexiones,
		humanoid.Died:Connect(function()
			if humanoid.Health <= 0 and not registro.Muerto then
				procesarMuerteZombi(registro)
			end
		end)
	)

	_zombisActivos[modelo] = registro
	return registro
end

function ZombieService.AplicarDanio(
	modeloZombi: Model,
	cantidad: number,
	atacante: Player?,
	_idArma: string?
): boolean
	local registro = _zombisActivos[modeloZombi]
	if not registro or registro.Muerto or not HordeSession.EsSesionActiva(registro.SesionId) then
		return false
	end
	if cantidad <= 0 then
		return false
	end
	if not atacante or not HordeSession.EsParticipanteVivo(atacante) then
		return false
	end

	registro.UltimoAtacante = atacante
	local tagExistente = registro.Humanoid:FindFirstChild("creator")
	if tagExistente then
		tagExistente:Destroy()
	end
	local creator = Instance.new("ObjectValue")
	creator.Name = "creator"
	creator.Value = atacante
	creator.Parent = registro.Humanoid

	-- Reacción de impacto con resistencia al aturdimiento por variante
	local ahora = os.clock()
	registro.ContadorGolpe += 1
	registro.Modelo:SetAttribute("ContadorGolpe", registro.ContadorGolpe)

	local resistencia = registro.Variante.ResistenciaAturdimiento or 0
	local duracionStun = General.DuracionAturdimientoGolpe * (1 - resistencia)
	if
		registro.Humanoid.Health > cantidad
		and duracionStun >= 0.06
		and ahora >= registro.InmuneAturdimientoHasta
	then
		registro.Estado = "Stunned"
		registro.Modelo:SetAttribute("EstadoIA", "Stunned")
		registro.AturdidoHasta = ahora + duracionStun
		registro.InmuneAturdimientoHasta = ahora + 0.6 + (resistencia * 1.0)
		registro.Humanoid.WalkSpeed = registro.VelocidadBase * (0.25 + resistencia * 0.45)
	end

	reproducirSonidoEnParte(registro.HRP, ConfigZombis.Sonidos.Golpe, 0.55, 0.88)
	registro.Humanoid:TakeDamage(cantidad)

	for _, p in ipairs(HordeSession.ObtenerParticipantes()) do
		EventosRemotos.ZombieEventoVisual:FireClient(p, {
			Tipo = "Impacto",
			Modelo = modeloZombi,
			Posicion = registro.HRP.Position,
			VarianteId = registro.Variante.Id,
		})
	end

	return true
end

function ZombieService.LimpiarTodosZombis()
	local copia: { RegistroZombi } = {}
	for _, reg in pairs(_zombisActivos) do
		table.insert(copia, reg)
	end
	for _, reg in ipairs(copia) do
		limpiarZombi(reg)
	end
end

return ZombieService
