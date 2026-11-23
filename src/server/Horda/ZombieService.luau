--!strict
--[[
	ZombieService.luau
	Administra la creación, variantes visuales, registro, daño, recompensas
	y limpieza de zombis de la horda en el servidor.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

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
	BillboardGui: BillboardGui?,
	EsconditeBarraHasta: number,
	UltimoCritico: boolean,
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
): (Model, Humanoid, BasePart, Frame, BillboardGui, boolean)
	local modelo = Instance.new("Model")
	modelo.Name = "Zombi_" .. variante.Id

	local tonoPiel = variarTonoPiel(variante.ColorPiel)
	local usaLuz = false
	local maxLuces = General.MaxLucesDinamicasZombis or 8

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

	-- Desgaste realista / chaleco táctico desgarrado en el pecho
	local harapo = Instance.new("Part")
	harapo.Name = "HarapoPecho"
	harapo.Size = Vector3.new(1.65 * escala, 1.35 * escala, 1.08 * escala)
	harapo.Color = variante.ColorRopa:Lerp(Color3.fromRGB(22, 20, 20), 0.52)
	harapo.Material = Enum.Material.CorrodedMetal
	harapo.CFrame = torso.CFrame * CFrame.new(0.08 * escala, -0.05 * escala, 0)
	harapo.Parent = modelo
	soldarAccesorio(torso, harapo)

	if variante.EsJefe then
		local pechera = Instance.new("Part")
		pechera.Name = "PecheraBlindada"
		pechera.Size = Vector3.new(2.25 * escala, 1.65 * escala, 1.28 * escala)
		pechera.Color = Color3.fromRGB(40, 42, 48)
		pechera.Material = Enum.Material.Metal
		pechera.CFrame = torso.CFrame * CFrame.new(0, 0.1 * escala, 0)
		pechera.Parent = modelo
		soldarAccesorio(torso, pechera)

		for _, signo in ipairs({ -1, 1 }) do
			local hombrera = Instance.new("Part")
			hombrera.Name = if signo < 0 then "HombreraIzq" else "HombreraDer"
			hombrera.Size = Vector3.new(1.15 * escala, 0.75 * escala, 1.25 * escala)
			hombrera.Color = Color3.fromRGB(34, 36, 42)
			hombrera.Material = Enum.Material.CorrodedMetal
			hombrera.CFrame = torso.CFrame * CFrame.new(signo * 1.45 * escala, 0.72 * escala, 0) * CFrame.Angles(0, 0, math.rad(signo * -12))
			hombrera.Parent = modelo
			soldarAccesorio(torso, hombrera)
		end
	end

	local cabeza = Instance.new("Part")
	cabeza.Name = "Head"
	cabeza.Size = Vector3.new(2 * escala, 1 * escala, 1 * escala)
	cabeza.Color = tonoPiel
	cabeza.Material = Enum.Material.Slate
	cabeza.CanCollide = false
	cabeza.CanTouch = true
	cabeza.Anchored = false
	cabeza.Parent = modelo

	local meshCabeza = Instance.new("SpecialMesh")
	meshCabeza.Name = "Mesh"
	meshCabeza.MeshType = Enum.MeshType.Head
	meshCabeza.Scale = Vector3.new(1.25, 1.25, 1.25)
	meshCabeza.Parent = cabeza

	-- Rostro realista estilo Call of Duty Zombies: cuencas oscuras + ojos brillantes con estela (Trail)
	for idxOjo, xOjo in ipairs({ -0.22 * escala, 0.22 * escala }) do
		local cuenca = Instance.new("Part")
		cuenca.Name = "CuencaOjo_" .. idxOjo
		cuenca.Size = Vector3.new(0.28 * escala, 0.22 * escala, 0.1 * escala)
		cuenca.Color = Color3.fromRGB(16, 14, 14)
		cuenca.Material = Enum.Material.SmoothPlastic
		cuenca.CFrame = cabeza.CFrame * CFrame.new(xOjo, 0.12 * escala, -0.54 * escala)
		cuenca.Parent = modelo
		soldarAccesorio(cabeza, cuenca)

		local ojo = Instance.new("Part")
		ojo.Name = "OjoBrillante_" .. idxOjo
		ojo.Size = Vector3.new(0.16 * escala, 0.12 * escala, 0.12 * escala)
		ojo.Color = variante.ColorOjos
		ojo.Material = Enum.Material.Neon
		ojo.CFrame = cabeza.CFrame * CFrame.new(xOjo, 0.12 * escala, -0.57 * escala)
		ojo.Parent = modelo
		soldarAccesorio(cabeza, ojo)

		local attTop = Instance.new("Attachment")
		attTop.Position = Vector3.new(0, 0.04 * escala, 0)
		attTop.Parent = ojo

		local attBot = Instance.new("Attachment")
		attBot.Position = Vector3.new(0, -0.04 * escala, 0)
		attBot.Parent = ojo

		local trail = Instance.new("Trail")
		trail.Attachment0 = attTop
		trail.Attachment1 = attBot
		trail.Lifetime = 0.22
		trail.MinLength = 0.08
		trail.LightEmission = 1
		trail.Color = ColorSequence.new(variante.ColorOjos)
		trail.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.15),
			NumberSequenceKeypoint.new(1, 1),
		})
		trail.Parent = ojo
	end

	-- Mandíbula oscura hundida
	local boca = Instance.new("Part")
	boca.Name = "Mandibula"
	boca.Size = Vector3.new(0.52 * escala, 0.18 * escala, 0.12 * escala)
	boca.Color = Color3.fromRGB(26, 14, 14)
	boca.Material = Enum.Material.SmoothPlastic
	boca.CFrame = cabeza.CFrame * CFrame.new(0, -0.25 * escala, -0.55 * escala)
	boca.Parent = modelo
	soldarAccesorio(cabeza, boca)

	if variante.EsJefe then
		local casco = Instance.new("Part")
		casco.Name = "CascoBlindado"
		casco.Size = Vector3.new(1.36 * escala, 0.72 * escala, 1.38 * escala)
		casco.Color = Color3.fromRGB(32, 34, 38)
		casco.Material = Enum.Material.Metal
		casco.CFrame = cabeza.CFrame * CFrame.new(0, 0.28 * escala, 0.04 * escala)
		casco.Parent = modelo
		soldarAccesorio(cabeza, casco)

		local visor = Instance.new("Part")
		visor.Name = "VisorJefe"
		visor.Size = Vector3.new(0.95 * escala, 0.14 * escala, 0.14 * escala)
		visor.Color = Color3.fromRGB(255, 35, 35)
		visor.Material = Enum.Material.Neon
		visor.CFrame = cabeza.CFrame * CFrame.new(0, 0.14 * escala, -0.62 * escala)
		visor.Parent = modelo
		soldarAccesorio(cabeza, visor)
	end

	-- Brazos articulados con mangas rasgadas
	local brazoIzq = Instance.new("Part")
	brazoIzq.Name = "Left Arm"
	brazoIzq.Size = Vector3.new(1 * escala, 2 * escala, 1 * escala)
	brazoIzq.Color = tonoPiel
	brazoIzq.Material = Enum.Material.Slate
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
	brazoDer.Material = Enum.Material.Slate
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

	-- Efectos visuales realistas para Sabueso Infernal (Zombi de Fuego)
	if variante.EsDeFuego then
		local partesLava = { torso, cabeza, brazoIzq, brazoDer, piernaIzq, piernaDer }
		for _, parte in ipairs(partesLava) do
			parte.Color = Color3.fromRGB(26, 22, 22)
			parte.Material = Enum.Material.Basalt
		end
		harapo.Color = Color3.fromRGB(230, 95, 22)
		harapo.Material = Enum.Material.Neon

		local fuego = Instance.new("Fire")
		fuego.Name = "LavaFire"
		fuego.Heat = 6
		fuego.Size = math.clamp(3.6 * escala, 2.8, 5)
		fuego.Color = Color3.fromRGB(245, 115, 30)
		fuego.SecondaryColor = Color3.fromRGB(140, 40, 12)
		fuego.Parent = torso

		if _lucesDinamicasActivas < maxLuces then
			local luzLava = Instance.new("PointLight")
			luzLava.Name = "LavaAura"
			luzLava.Color = Color3.fromRGB(255, 110, 25)
			luzLava.Range = 12 * escala
			luzLava.Brightness = 1.6
			luzLava.Parent = torso
			usaLuz = true
		end
	end

	-- Efectos visuales realistas para Espectro Criogénico (Hielo)
	if variante.EsDeHielo then
		cabeza.Color = Color3.fromRGB(145, 170, 185)
		brazoIzq.Color = Color3.fromRGB(145, 170, 185)
		brazoDer.Color = Color3.fromRGB(145, 170, 185)
		torso.Color = Color3.fromRGB(32, 42, 54)
		piernaIzq.Color = Color3.fromRGB(24, 30, 38)
		piernaDer.Color = Color3.fromRGB(24, 30, 38)

		local nieblaHielo = Instance.new("ParticleEmitter")
		nieblaHielo.Name = "EscarchaAura"
		nieblaHielo.Color = ColorSequence.new(Color3.fromRGB(170, 230, 255))
		nieblaHielo.Size = NumberSequence.new(0.8, 1.5)
		nieblaHielo.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.45),
			NumberSequenceKeypoint.new(1, 1),
		})
		nieblaHielo.Rate = 8
		nieblaHielo.Lifetime = NumberRange.new(0.6, 1.1)
		nieblaHielo.Speed = NumberRange.new(1, 2.5)
		nieblaHielo.Parent = torso

		if not usaLuz and _lucesDinamicasActivas < maxLuces then
			local luzHielo = Instance.new("PointLight")
			luzHielo.Name = "IceAura"
			luzHielo.Color = Color3.fromRGB(110, 220, 255)
			luzHielo.Range = 10 * escala
			luzHielo.Brightness = 1.2
			luzHielo.Parent = torso
			usaLuz = true
		end
	end

	-- Efectos visuales realistas para Coloso Radiactivo (Tóxico)
	if variante.EsToxico then
		local emisorVeneno = Instance.new("ParticleEmitter")
		emisorVeneno.Name = "ToxicSparks"
		emisorVeneno.Color = ColorSequence.new(Color3.fromRGB(130, 255, 80))
		emisorVeneno.Rate = 8
		emisorVeneno.Lifetime = NumberRange.new(0.6, 1.1)
		emisorVeneno.Speed = NumberRange.new(1.2, 3.0)
		emisorVeneno.Size = NumberSequence.new(0.5, 1.1)
		emisorVeneno.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.35),
			NumberSequenceKeypoint.new(1, 1),
		})
		emisorVeneno.Parent = torso

		if not usaLuz and _lucesDinamicasActivas < maxLuces then
			local luzToxica = Instance.new("PointLight")
			luzToxica.Name = "ToxicAura"
			luzToxica.Color = Color3.fromRGB(130, 255, 80)
			luzToxica.Range = 11 * escala
			luzToxica.Brightness = 1.2
			luzToxica.Parent = torso
			usaLuz = true
		end
	end

	if usaLuz then
		_lucesDinamicasActivas += 1
	end

	-- Articulaciones Motor6D (postura ligeramente encorvada hacia adelante)
	local elevacionTorso = math.max(0.22, (escala - 1.0) * 1.05 + 0.22)
	crearMotor6D(
		"RootJoint",
		hrp,
		torso,
		CFrame.new(0, elevacionTorso, 0) * CFrame.Angles(math.rad(-10), 0, 0),
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
	humanoid.MaxSlopeAngle = 89
	humanoid.UseJumpPower = true
	humanoid.JumpPower = 55
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

	-- Barra de vida táctica (oculta por defecto para zombis normales, visible 3s al recibir daño; fija para Jefes)
	local bbg = Instance.new("BillboardGui")
	bbg.Name = "BarraVidaZombi"
	bbg.Size = if variante.EsJefe then UDim2.fromOffset(160, 34) else UDim2.fromOffset(105, 22)
	bbg.StudsOffset = Vector3.new(0, 2.35 * escala, 0)
	bbg.AlwaysOnTop = false
	bbg.MaxDistance = if variante.EsJefe then 120 else 50
	bbg.Enabled = variante.EsJefe == true
	bbg.Parent = cabeza

	local lblNombre = Instance.new("TextLabel")
	lblNombre.Size = UDim2.new(1, 0, 0, 14)
	lblNombre.BackgroundTransparency = 1
	lblNombre.Font = Enum.Font.GothamBold
	lblNombre.Text = if variante.EsJefe then ("☠ " .. string.upper(variante.Nombre)) else variante.Nombre
	lblNombre.TextColor3 = if variante.EsJefe then Color3.fromRGB(255, 95, 95) else Color3.fromRGB(235, 235, 235)
	lblNombre.TextSize = if variante.EsJefe then 12 else 10
	lblNombre.TextStrokeTransparency = 0.25
	lblNombre.Parent = bbg

	local fondoBarra = Instance.new("Frame")
	fondoBarra.Size = UDim2.new(1, 0, 0, if variante.EsJefe then 7 else 5)
	fondoBarra.Position = UDim2.fromOffset(0, 16)
	fondoBarra.BackgroundColor3 = Color3.fromRGB(18, 16, 18)
	fondoBarra.BorderSizePixel = 0
	fondoBarra.Parent = bbg

	local cornerFondo = Instance.new("UICorner")
	cornerFondo.CornerRadius = UDim.new(0, 2)
	cornerFondo.Parent = fondoBarra

	local rellenoBarra = Instance.new("Frame")
	rellenoBarra.Name = "Relleno"
	rellenoBarra.Size = UDim2.fromScale(1, 1)
	rellenoBarra.BackgroundColor3 = if variante.EsJefe then Color3.fromRGB(235, 45, 55) else Color3.fromRGB(195, 42, 48)
	rellenoBarra.BorderSizePixel = 0
	rellenoBarra.Parent = fondoBarra

	local cornerRelleno = Instance.new("UICorner")
	cornerRelleno.CornerRadius = UDim.new(0, 2)
	cornerRelleno.Parent = rellenoBarra

	return modelo, humanoid, hrp, rellenoBarra, bbg, usaLuz
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
			local doble = if Workspace:GetAttribute("LazarusPuntosDobles") == true then 2 else 1
			local recompensaBase = registro.Variante.RecompensaPesos or (General.PuntosPorBaja or 60)
			local bonoCrit = if registro.UltimoCritico then 40 else 0
			local recompensaTotal = (recompensaBase + bonoCrit) * doble
			local famaBaja = if registro.Variante.EsJefe then 3 else 1

			GestorDatos.AgregarPesos(atacante, recompensaTotal)
			GestorDatos.AgregarFama(atacante, famaBaja)
			GestorDatos.AgregarDulce(
				atacante,
				"Dulce_Gomita",
				General.MunicionDropPorMuerte
			)
			atacante:SetAttribute(
				"PuntosLazarusAcumulados",
				(tonumber(atacante:GetAttribute("PuntosLazarusAcumulados")) or 0) + recompensaTotal
			)
			if registro.UltimoCritico then
				atacante:SetAttribute(
					"HordaCriticos",
					(tonumber(atacante:GetAttribute("HordaCriticos")) or 0) + 1
				)
			end
			HordeSession.RegistrarBaja(atacante, recompensaTotal, famaBaja, registro.UltimoCritico)

			EventosRemotos.ZombieEventoVisual:FireClient(atacante, {
				Tipo = "Muerte",
				Modelo = registro.Modelo,
				Posicion = registro.HRP.Position,
				VarianteId = registro.Variante.Id,
				EsCritico = registro.UltimoCritico,
				Puntos = recompensaTotal,
				EsJefe = registro.Variante.EsJefe == true,
			})
		end

		if registro.Variante.EsJefe == true then
			local bindDrop = script.Parent.Parent:FindFirstChild("SpawnDropLazarus")
			if bindDrop and bindDrop:IsA("BindableEvent") then
				bindDrop:Fire(registro.HRP.Position, nil)
			end
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
	local modelo, humanoid, hrp, barraVida, bbgVida, usaLuz = construirRigZombi(variante, escala)

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
	modelo:SetAttribute("EsJefe", variante.EsJefe == true)
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
		BillboardGui = bbgVida,
		EsconditeBarraHasta = 0,
		UltimoCritico = false,
	}

	local ultimaVidaValida = vidaFinal
	local revirtiendoVida = false
	local aplicandoBonoDanio = false

	table.insert(
		registro.Conexiones,
		humanoid.HealthChanged:Connect(function(nuevaVida: number)
			if revirtiendoVida or aplicandoBonoDanio or registro.Muerto then
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

				local danioBase = ultimaVidaValida - nuevaVida
				local esCritico = (danioBase >= 42) or (modelo:GetAttribute("UltimoImpactoCritico") == true)
				modelo:SetAttribute("UltimoImpactoCritico", nil)
				registro.UltimoCritico = esCritico
				registro.UltimoAtacante = playerCreator

				local esInsta = Workspace:GetAttribute("LazarusInstaKill") == true
				local mult = 1.0
				if playerCreator:GetAttribute("ArmaPotenciada") == true then
					mult *= 2.2
				end
				if playerCreator:GetAttribute("PerkDobleDisparo") == true then
					mult *= 1.35
				end

				local danioExtra = if esInsta and nuevaVida > 0
					then nuevaVida
					elseif mult > 1.0 and nuevaVida > 0 then (danioBase * (mult - 1.0))
					else 0

				if danioExtra > 0 then
					aplicandoBonoDanio = true
					local vidaTrasBono = math.max(0, nuevaVida - danioExtra)
					humanoid.Health = vidaTrasBono
					aplicandoBonoDanio = false
					nuevaVida = vidaTrasBono
				end

				ultimaVidaValida = math.max(0, nuevaVida)

				-- Puntos estilo CoD por cada impacto + notificación visual de hitmarker
				local doble = if Workspace:GetAttribute("LazarusPuntosDobles") == true then 2 else 1
				local ptsImpacto = (General.PuntosPorImpacto or 10) * doble
				GestorDatos.AgregarPesos(playerCreator, ptsImpacto)
				playerCreator:SetAttribute(
					"PuntosLazarusAcumulados",
					(tonumber(playerCreator:GetAttribute("PuntosLazarusAcumulados")) or 0) + ptsImpacto
				)

				EventosRemotos.ZombieEventoVisual:FireClient(playerCreator, {
					Tipo = "Impacto",
					Modelo = modelo,
					Posicion = hrp.Position,
					VarianteId = variante.Id,
					EsCritico = esCritico,
					EsMuerte = nuevaVida <= 0,
					Puntos = ptsImpacto,
				})

				if registro.BillboardGui and registro.BillboardGui.Parent and not variante.EsJefe then
					registro.BillboardGui.Enabled = true
					local momentoMostrar = os.clock() + 3.0
					registro.EsconditeBarraHasta = momentoMostrar
					task.delay(3.05, function()
						if
							not registro.Muerto
							and registro.BillboardGui
							and registro.BillboardGui.Parent
							and os.clock() >= registro.EsconditeBarraHasta
						then
							registro.BillboardGui.Enabled = false
						end
					end)
				end
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

	return true
end

EventosRemotos.AtropellarZombi.OnServerEvent:Connect(function(player: Player, modeloZombi: Instance, danio: number)
	if modeloZombi and modeloZombi:IsA("Model") and typeof(danio) == "number" then
		local danioSeguro = math.clamp(danio, 10, 100)
		ZombieService.AplicarDanio(modeloZombi, danioSeguro, player, "AtropelloVehiculo")
		local hrpZ = modeloZombi:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrpZ then
			local char = player.Character
			local hrpP = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrpP then
				local dir = (hrpZ.Position - hrpP.Position).Unit
				hrpZ.AssemblyLinearVelocity = dir * (danioSeguro * 0.8) + Vector3.new(0, 15, 0)
			end
		end
	end
end)

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
