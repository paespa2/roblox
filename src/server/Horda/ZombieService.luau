--!strict
--[[
	ZombieService.luau
	Administra la creación, variantes visuales, registro, daño, recompensas
	y limpieza de zombis de la horda en el servidor.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Datos = require(ReplicatedStorage.Shared.Datos)
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)
local GestorDatos = require(script.Parent.Parent.GestorDatos)
local UtilidadesMapaHorda = require(script.Parent.UtilidadesMapaHorda)

local ConfigZombis = Datos.Zombis

export type EstadoZombi = "Idle" | "Detecting" | "Chasing" | "Attacking" | "Stunned" | "Dead"

export type RegistroZombi = {
	Id: number,
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
	ObjetivoActual: Player?,
	UltimoRecalculoRuta: number,
	UltimaPosObjetivoRuta: Vector3?,
	WaypointsActuales: { PathWaypoint }?,
	IndiceWaypoint: number,
	UltimaPosComprobada: Vector3,
	UltimoChequeoAtasco: number,
	Muerto: boolean,
	UltimoAtacante: Player?,
	Conexiones: { RBXScriptConnection },
	BillboardVida: Frame?,
}

local ZombieService = {}

local _zombisActivos: { [Model]: RegistroZombi } = {}
local _contadorId = 0
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

local function construirRigZombi(variante: any, escala: number): (Model, Humanoid, BasePart, Frame)
	local modelo = Instance.new("Model")
	modelo.Name = "Zombi_" .. variante.Id

	local tonoPiel = variarTonoPiel(variante.ColorPiel)

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

	-- Harapos / parches deteriorados en torso
	local harapo = Instance.new("Part")
	harapo.Name = "HarapoPecho"
	harapo.Size = Vector3.new(1.5 * escala, 1.3 * escala, 1.08 * escala)
	harapo.Color = variante.ColorRopa:Lerp(Color3.new(0.1, 0.1, 0.1), 0.45)
	harapo.Material = Enum.Material.CorrodedMetal
	harapo.CFrame = torso.CFrame * CFrame.new(0.15 * escala, -0.1 * escala, 0)
	harapo.Parent = modelo
	soldarAccesorio(torso, harapo)

	local cabeza = Instance.new("Part")
	cabeza.Name = "Head"
	cabeza.Size = Vector3.new(1.2 * escala, 1.2 * escala, 1.2 * escala)
	cabeza.Color = tonoPiel
	cabeza.Material = Enum.Material.SmoothPlastic
	cabeza.CanCollide = false
	cabeza.CanTouch = true
	cabeza.Anchored = false
	cabeza.Parent = modelo

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

		local luzCristal = Instance.new("PointLight")
		luzCristal.Color = variante.ColorOjos
		luzCristal.Range = 9
		luzCristal.Brightness = 1.6
		luzCristal.Parent = cristal
	end

	-- Efectos visuales de Lava Zombie (fuego y texturas ardientes en todas las extremidades)
	if variante.EsDeFuego then
		local texturaLava = variante.TexturaLava or "rbxassetid://102118326"
		local partesLava = { torso, cabeza, brazoIzq, brazoDer, piernaIzq, piernaDer }
		local caras = {
			Enum.NormalId.Front,
			Enum.NormalId.Back,
			Enum.NormalId.Left,
			Enum.NormalId.Right,
			Enum.NormalId.Top,
			Enum.NormalId.Bottom,
		}

		for _, parte in ipairs(partesLava) do
			parte.Color = Color3.fromRGB(22, 22, 22)
			parte.Material = Enum.Material.Basalt

			for _, cara in ipairs(caras) do
				-- Preservar la cara frontal aterradora en la cabeza
				if parte == cabeza and cara == Enum.NormalId.Front and (idCara and idCara ~= "") then
					continue
				end
				local dec = Instance.new("Decal")
				dec.Name = "LavaDecal"
				dec.Texture = texturaLava
				dec.Face = cara
				dec.Parent = parte
			end

			local fuego = Instance.new("Fire")
			fuego.Name = "LavaFire"
			fuego.Heat = 9
			fuego.Size = math.clamp(4.5 * escala, 3, 7)
			fuego.Color = Color3.fromRGB(240, 130, 40)
			fuego.SecondaryColor = Color3.fromRGB(150, 60, 20)
			fuego.Parent = parte
		end

		local luzLava = Instance.new("PointLight")
		luzLava.Name = "LavaAura"
		luzLava.Color = Color3.fromRGB(255, 115, 30)
		luzLava.Range = 14 * escala
		luzLava.Brightness = 2.2
		luzLava.Parent = torso
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
		CFrame.new(0, -0.6 * escala, 0)
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

	-- Humanoid y Animator oficiales
	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.RigType = Enum.HumanoidRigType.R6
	humanoid.AutomaticScalingEnabled = false
	humanoid.BreakJointsOnDeath = false
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.Parent = modelo

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

	return modelo, humanoid, hrp, rellenoBarra
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
	for _, conn in ipairs(registro.Conexiones) do
		if conn.Connected then
			conn:Disconnect()
		end
	end
	table.clear(registro.Conexiones)
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

	-- Desactivar colisiones para no estorbar durante animación de muerte
	for _, desc in ipairs(registro.Modelo:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.CanCollide = false
			desc.CanTouch = false
		end
	end
	registro.HRP.Anchored = true

	-- Efecto de llamarada final al morir si es Zombi de Fuego
	if registro.Variante and registro.Variante.EsDeFuego then
		for _, desc in ipairs(registro.Modelo:GetDescendants()) do
			if desc:IsA("Fire") then
				desc.Size = 10
				desc.Heat = 16
			end
		end
	end

	reproducirSonidoEnParte(registro.HRP, ConfigZombis.Sonidos.MuerteZombi, 0.7, 0.72)

	-- Recompensar al atacante o sobrevivientes
	local atacante = registro.UltimoAtacante
	if atacante and atacante:IsDescendantOf(Players) then
		GestorDatos.AgregarPesos(atacante, registro.Variante.RecompensaPesos)
		local datos = GestorDatos.ObtenerDatos(atacante)
		if datos then
			datos.Fama += 1
		end
		-- Reponer munición dulce para sostener combate continuo
		GestorDatos.AgregarDulce(
			atacante,
			"Dulce_Gomita",
			ConfigZombis.General.MunicionDropPorMuerte
		)
	end

	if _onZombiMuertoCallback then
		task.spawn(_onZombiMuertoCallback, registro)
	end

	task.delay(ConfigZombis.General.TiempoDespawnMuerto, function()
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
	varianteForzada: any?
): RegistroZombi?
	local variante = varianteForzada or elegirVarianteParaOleada(numeroOleada)
	local escala = variante.Escala
	local modelo, humanoid, hrp, barraVida = construirRigZombi(variante, escala)

	_contadorId += 1
	local idZombi = _contadorId

	local vidaFinal = math.round(configOleada.VidaBase * variante.MultiplicadorVida)
	local velocidadFinal = configOleada.VelocidadBase * variante.MultiplicadorVelocidad
	local danioFinal = math.round(configOleada.DanioBase * variante.MultiplicadorDanio)

	humanoid.MaxHealth = vidaFinal
	humanoid.Health = vidaFinal
	humanoid.WalkSpeed = velocidadFinal

	modelo:SetAttribute("EsZombie", true)
	modelo:SetAttribute("IdZombi", idZombi)
	modelo:SetAttribute("VarianteId", variante.Id)
	modelo:SetAttribute("EsDeFuego", variante.EsDeFuego == true)
	modelo:SetAttribute("EstadoIA", "Detecting")
	modelo:SetAttribute("VelocidadBase", velocidadFinal)
	modelo:SetAttribute("UltimoGolpe", 0)

	local carpetaZombis = UtilidadesMapaHorda.ObtenerCarpetaZombis()
	modelo:PivotTo(CFrame.new(posicion))
	modelo.Parent = carpetaZombis

	-- Autoridad de físicas en el servidor
	pcall(function()
		for _, desc in ipairs(modelo:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc:SetNetworkOwner(nil)
			end
		end
	end)

	emitirEfectoAparicion(hrp, variante.ColorOjos)
	if game:GetService("RunService"):IsRunning() and #Players:GetPlayers() > 0 then
		pcall(function()
			EventosRemotos.ZombieEventoVisual:FireAllClients({
				Tipo = "Aparicion",
				Posicion = posicion,
				VarianteId = variante.Id,
			})
		end)
	end

	local registro: RegistroZombi = {
		Id = idZombi,
		Modelo = modelo,
		Humanoid = humanoid,
		HRP = hrp,
		Variante = variante,
		Estado = "Detecting",
		VelocidadBase = velocidadFinal,
		DanioAtaque = danioFinal,
		CooldownAtaque = configOleada.CooldownAtaque,
		UltimoAtaque = 0,
		AturdidoHasta = 0,
		ObjetivoActual = nil,
		UltimoRecalculoRuta = 0,
		UltimaPosObjetivoRuta = nil,
		WaypointsActuales = nil,
		IndiceWaypoint = 1,
		UltimaPosComprobada = posicion,
		UltimoChequeoAtasco = os.clock(),
		Muerto = false,
		UltimoAtacante = nil,
		Conexiones = {},
		BillboardVida = barraVida,
	}

	table.insert(
		registro.Conexiones,
		humanoid.HealthChanged:Connect(function(nuevaVida: number)
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
			procesarMuerteZombi(registro)
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
	if not registro or registro.Muerto then
		return false
	end
	if cantidad <= 0 then
		return false
	end

	if atacante then
		registro.UltimoAtacante = atacante
	end

	-- Reacción de impacto (Stunned breve + feedback visual/sonoro)
	local ahora = os.clock()
	registro.Modelo:SetAttribute("UltimoGolpe", ahora)
	if registro.Humanoid.Health > cantidad then
		registro.Estado = "Stunned"
		registro.Modelo:SetAttribute("EstadoIA", "Stunned")
		registro.AturdidoHasta = ahora + ConfigZombis.General.DuracionAturdimientoGolpe
		registro.Humanoid.WalkSpeed = registro.VelocidadBase * 0.25
	end

	reproducirSonidoEnParte(registro.HRP, ConfigZombis.Sonidos.Golpe, 0.55, 0.88)
	registro.Humanoid:TakeDamage(cantidad)

	EventosRemotos.ZombieEventoVisual:FireAllClients({
		Tipo = "Impacto",
		Modelo = modeloZombi,
		Posicion = registro.HRP.Position,
	})

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
