--!strict
--[[
	SistemaModoLazarus.server.luau
	Adaptación integral del mapa, economía de DULCES (🍬) e infraestructura de supervivencia Zombie
	inspirada en "Project Lazarus: ZOMBIES":
	1. 11 Barricadas Defensivas Reparables (6 tablones por acceso en Cocina, Plaza, Colegio, Parque Central, Don Ábaco, Esquina Paisa, Hospital y Finca Norte).
	2. 5 Armas de Pared Neón (Wall-Buys con siluetas de tiza luminosa distribuidas por todo el mapa).
	3. 2 Cajas Misteriosas Lazarus (Mystery Candy Boxes en la Plaza Central y Parque Central con haces de luz al cielo).
	4. 7 Máquinas de Jarabe Perk-a-Cola + Forja Pack-a-Punch TRON (en el Búnker Inicial, Colegio, Esquina Paisa y Hospital San Rafael).
	5. Infraestructura de Cuarentena Zombie: Torres de Reflectores Tácticos, Trincheras y Cristales de Azúcar Corrupta.
	6. Drops Flotantes de Zombis (Kaboom/Nuke, Munición Máxima, Dulces Dobles 2X, Azúcar Letal/Insta-Kill).
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

local GestorDatos = require(script.Parent.GestorDatos)
local ZombieService = require(script.Parent.Horda.ZombieService)
local UtilidadesMapaHorda = require(script.Parent.Horda.UtilidadesMapaHorda)
local Datos = require(ReplicatedStorage.Shared.Datos)
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)

local CARPETA_NOMBRE = "LazarusSupervivencia"
local carpetaLazarus = Workspace:FindFirstChild(CARPETA_NOMBRE)
if carpetaLazarus then
	carpetaLazarus:Destroy()
end
local nuevaCarpeta = Instance.new("Folder")
nuevaCarpeta.Name = CARPETA_NOMBRE
nuevaCarpeta.Parent = Workspace
carpetaLazarus = nuevaCarpeta

local carpetaBarricadas = Instance.new("Folder")
carpetaBarricadas.Name = "BarricadasLazarus"
carpetaBarricadas.Parent = carpetaLazarus

local carpetaEstaciones = Instance.new("Folder")
carpetaEstaciones.Name = "EstacionesLazarus"
carpetaEstaciones.Parent = carpetaLazarus

local carpetaDrops = Instance.new("Folder")
carpetaDrops.Name = "DropsLazarus"
carpetaDrops.Parent = carpetaLazarus

local carpetaInfraestructura = Instance.new("Folder")
carpetaInfraestructura.Name = "InfraestructuraZombie"
carpetaInfraestructura.Parent = carpetaLazarus

local SONIDO_REPARAR = "rbxasset://sounds/switches.wav"
local SONIDO_MADERA = "rbxasset://sounds/collide.wav"
local SONIDO_CAJA = "rbxasset://sounds/electronicpingshort.wav"
local SONIDO_POWERUP = "rbxasset://sounds/victory.wav"

local MAX_TABLONES = 6

type RegistroBarricada = {
	Modelo: Model,
	Centro: BasePart,
	Tablones: { BasePart },
	LabelEstado: TextLabel,
	Prompt: ProximityPrompt,
	CantidadActual: number,
	UltimoAtaqueZombi: number,
}

local barricadasActivas: { RegistroBarricada } = {}

local function reproducirSonido3D(parent: Instance, soundId: string, volume: number?, pitch: number?)
	local snd = Instance.new("Sound")
	snd.SoundId = soundId
	snd.Volume = volume or 0.65
	snd.PlaybackSpeed = pitch or 1.0
	snd.RollOffMaxDistance = 85
	snd.Parent = parent
	snd:Play()
	Debris:AddItem(snd, 4)
end

local function notificarJugador(player: Player, titulo: string, mensaje: string)
	EventosRemotos.Notificacion:FireClient(player, titulo, mensaje)
end

local function obtenerPosSueloSegura(pos: Vector3, offsetY: number): Vector3
	local suelo, ok = UtilidadesMapaHorda.ObtenerPosicionSuelo(pos, offsetY)
	if ok then
		return suelo
	end
	return Vector3.new(pos.X, 61.3 + offsetY, pos.Z)
end

local function crearCartelFlotante(
	adornPart: BasePart,
	titulo: string,
	subtitulo: string,
	colorTexto: Color3,
	offsetStuds: Vector3?
): (BillboardGui, TextLabel)
	local bbg = Instance.new("BillboardGui")
	bbg.Name = "CartelLazarus"
	bbg.Adornee = adornPart
	bbg.Size = UDim2.fromOffset(220, 58)
	bbg.StudsOffset = offsetStuds or Vector3.new(0, 3.8, 0)
	bbg.AlwaysOnTop = false
	bbg.MaxDistance = 85
	bbg.Parent = adornPart

	local fondo = Instance.new("Frame")
	fondo.Size = UDim2.fromScale(1, 1)
	fondo.BackgroundColor3 = Color3.fromRGB(16, 14, 28)
	fondo.BackgroundTransparency = 0.18
	fondo.BorderSizePixel = 0
	fondo.Parent = bbg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = fondo

	local stroke = Instance.new("UIStroke")
	stroke.Color = colorTexto
	stroke.Thickness = 2
	stroke.Parent = fondo

	local lbl = Instance.new("TextLabel")
	lbl.Name = "TextoEstado"
	lbl.Size = UDim2.new(1, -10, 1, -6)
	lbl.Position = UDim2.fromOffset(5, 3)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextColor3 = colorTexto
	lbl.TextScaled = true
	lbl.Text = titulo .. "\n" .. subtitulo
	lbl.Parent = fondo

	return bbg, lbl
end

local function desbloquearYEntregarArma(player: Player, idArma: string, cantidadMunicion: number)
	local datos = GestorDatos.ObtenerDatos(player)
	local infoArma = Datos.Armas[idArma]
	if not datos or not infoArma then
		return
	end
	if not datos.ArmasDesbloqueadas then
		datos.ArmasDesbloqueadas = { ["Arma_CaucheraGomitas"] = true }
	end
	datos.ArmasDesbloqueadas[idArma] = true

	if infoArma.DulceMunicion and cantidadMunicion > 0 then
		GestorDatos.AgregarDulce(player, infoArma.DulceMunicion, cantidadMunicion)
	end

	local bindable = script.Parent:FindFirstChild("EntregarArmasAhora")
	if bindable and bindable:IsA("BindableEvent") then
		bindable:Fire(player)
	end
end

-- ============================================================================
-- 1. BARRICADAS REPARABLES DE VENTANA / ACCESO EN TODO EL MAPA (11 PUNTOS)
-- ============================================================================
local CONFIG_BARRICADAS = {
	{ Nombre = "Barricada_Cocina_Sur", Pos = Vector3.new(78, 62, -260), RotY = 0 },
	{ Nombre = "Barricada_Cocina_Este", Pos = Vector3.new(92, 62, -279), RotY = 90 },
	{ Nombre = "Barricada_Cocina_Oeste", Pos = Vector3.new(66, 62, -279), RotY = 90 },
	{ Nombre = "Barricada_Plaza_Dante", Pos = Vector3.new(69, 62, -218), RotY = 0 },
	{ Nombre = "Barricada_Corredor_Central", Pos = Vector3.new(54, 62, -232), RotY = 45 },
	{ Nombre = "Barricada_Acceso_Colegio", Pos = Vector3.new(-35, 62, -219), RotY = 90 },
	{ Nombre = "Barricada_Parque_Central", Pos = Vector3.new(12, 62, -78), RotY = 0 },
	{ Nombre = "Barricada_Refugio_EsquinaPaisa", Pos = Vector3.new(148, 62, -152), RotY = 45 },
	{ Nombre = "Barricada_Refugio_DonAbaco", Pos = Vector3.new(-148, 62, 152), RotY = -45 },
	{ Nombre = "Barricada_Hospital_SanRafael", Pos = Vector3.new(-385, 62, 325), RotY = 0 },
	{ Nombre = "Barricada_Frontera_FincaNorte", Pos = Vector3.new(0, 62, -345), RotY = 0 },
}

local function actualizarVisualBarricada(reg: RegistroBarricada)
	for i, tablon in ipairs(reg.Tablones) do
		local activo = i <= reg.CantidadActual
		tablon.Transparency = if activo then 0 else 1
		tablon.Material = Enum.Material.WoodPlanks
		tablon.Color = Color3.fromRGB(98, 66, 40)
	end

	reg.Centro.CanCollide = reg.CantidadActual > 0
	if reg.CantidadActual >= MAX_TABLONES then
		reg.LabelEstado.Text = string.format("🪵 BARRICADA INTACTA (%d/%d)\nBloquea el paso de la Horda Zombie", reg.CantidadActual, MAX_TABLONES)
		reg.LabelEstado.TextColor3 = Color3.fromRGB(110, 255, 150)
		reg.Prompt.ActionText = "Barricada Completa (6/6)"
	elseif reg.CantidadActual > 0 then
		reg.LabelEstado.Text = string.format("🪵 BARRICADA DAÑADA (%d/%d)\n[F] Reparar Tablón (+20 🍬 Dulces)", reg.CantidadActual, MAX_TABLONES)
		reg.LabelEstado.TextColor3 = Color3.fromRGB(255, 215, 85)
		reg.Prompt.ActionText = string.format("Reparar Tablón (%d/%d) [+20 🍬]", reg.CantidadActual, MAX_TABLONES)
	else
		reg.LabelEstado.Text = "🚨 ¡BARRICADA ROTA (0/6)!\n[F] Reconstruir Tablón (+20 🍬 Dulces)"
		reg.LabelEstado.TextColor3 = Color3.fromRGB(255, 85, 85)
		reg.Prompt.ActionText = "Reconstruir Barricada (0/6) [+20 🍬]"
	end
end

local function construirBarricadas()
	for _, cfg in ipairs(CONFIG_BARRICADAS) do
		local posSuelo = obtenerPosSueloSegura(cfg.Pos, 0)
		local cfBase = CFrame.new(posSuelo) * CFrame.Angles(0, math.rad(cfg.RotY), 0)

		local modelo = Instance.new("Model")
		modelo.Name = cfg.Nombre
		modelo.Parent = carpetaBarricadas

		local centro = Instance.new("Part")
		centro.Name = "MarcoBarricada"
		centro.Size = Vector3.new(7.4, 5.2, 1.0)
		centro.CFrame = cfBase * CFrame.new(0, 2.6, 0)
		centro.Anchored = true
		centro.Transparency = 1
		centro.CanCollide = true
		centro.Parent = modelo
		modelo.PrimaryPart = centro

		for _, signo in ipairs({ -1, 1 }) do
			local poste = Instance.new("Part")
			poste.Name = "PosteLateral"
			poste.Size = Vector3.new(0.65, 5.5, 0.85)
			poste.CFrame = cfBase * CFrame.new(signo * 3.55, 2.75, 0)
			poste.Anchored = true
			poste.CanCollide = true
			poste.Color = Color3.fromRGB(48, 44, 42)
			poste.Material = Enum.Material.CorrodedMetal
			poste.Parent = modelo
		end

		local tablones: { BasePart } = {}
		for i = 1, MAX_TABLONES do
			local tablon = Instance.new("Part")
			tablon.Name = "Tablon_" .. i
			tablon.Size = Vector3.new(6.8, 0.62, 0.35)
			local alturaY = 0.65 + (i - 1) * 0.78
			local inclinacionZ = math.rad(((i % 2 == 0) and 1 or -1) * 2.5)
			tablon.CFrame = cfBase * CFrame.new(0, alturaY, 0) * CFrame.Angles(0, 0, inclinacionZ)
			tablon.Anchored = true
			tablon.CanCollide = false
			tablon.Color = Color3.fromRGB(98, 66, 40)
			tablon.Material = Enum.Material.WoodPlanks
			tablon.Parent = modelo
			table.insert(tablones, tablon)
		end

		local _, lbl = crearCartelFlotante(
			centro,
			"🪵 BARRICADA INTACTA (6/6)",
			"[F] Reparar Tablón (+20 🍬 Dulces)",
			Color3.fromRGB(110, 255, 150),
			Vector3.new(0, 3.6, 0)
		)

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "PromptRepararBarricada"
		prompt.ObjectText = "Barricada Defensiva Anti-Zombis"
		prompt.ActionText = "Reparar Tablón [+20 🍬 Dulces]"
		prompt.KeyboardKeyCode = Enum.KeyCode.F
		prompt.HoldDuration = 0.35
		prompt.MaxActivationDistance = 11
		prompt.RequiresLineOfSight = false
		prompt.Parent = centro

		local reg: RegistroBarricada = {
			Modelo = modelo,
			Centro = centro,
			Tablones = tablones,
			LabelEstado = lbl,
			Prompt = prompt,
			CantidadActual = MAX_TABLONES,
			UltimoAtaqueZombi = 0,
		}

		prompt.Triggered:Connect(function(player: Player)
			if reg.CantidadActual >= MAX_TABLONES then
				notificarJugador(player, "🪵 Barricada Completa", "Esta barricada ya tiene los 6/6 tablones reforzados.")
				return
			end
			reg.CantidadActual = math.min(MAX_TABLONES, reg.CantidadActual + 1)
			actualizarVisualBarricada(reg)
			reproducirSonido3D(reg.Centro, SONIDO_REPARAR, 0.7, 1.05 + (reg.CantidadActual * 0.04))

			local recompensa = if Workspace:GetAttribute("LazarusPuntosDobles") == true then 40 else 20
			GestorDatos.AgregarPesos(player, recompensa)
			GestorDatos.AgregarFama(player, 1)
			player:SetAttribute(
				"TablonesReparadosLazarus",
				(tonumber(player:GetAttribute("TablonesReparadosLazarus")) or 0) + 1
			)
			notificarJugador(
				player,
				"🔨 ¡Tablón Reparado!",
				string.format("Barricada %d/%d tablones. Ganaste +%d 🍬 Dulces y +1 Fama.", reg.CantidadActual, MAX_TABLONES, recompensa)
			)
		end)

		actualizarVisualBarricada(reg)
		table.insert(barricadasActivas, reg)
	end
end

-- ============================================================================
-- 2. ARMAS DE PARED NEÓN EN LOS REFUGIOS DEL MAPA (5 WALL-BUYS)
-- ============================================================================
local CONFIG_WALLBUYS = {
	{
		Nombre = "WallBuy_PistolaCrema_Cocina",
		Titulo = "🔫 ARMA DE PARED: PISTOLA DE CREMA",
		IdArma = "Arma_PistolaCrema",
		CostoArma = 100,
		CostoMunicion = 50,
		CantidadMunicion = 20,
		Color = Color3.fromRGB(90, 225, 255),
		Pos = Vector3.new(74, 62, -268),
		RotY = 0,
	},
	{
		Nombre = "WallBuy_EscopetaChicle_Plaza",
		Titulo = "💥 ARMA DE PARED: ESCOPETA DE CHICLE",
		IdArma = "Arma_EscopetaChicle",
		CostoArma = 180,
		CostoMunicion = 80,
		CantidadMunicion = 24,
		Color = Color3.fromRGB(255, 75, 195),
		Pos = Vector3.new(63, 62, -212),
		RotY = 45,
	},
	{
		Nombre = "WallBuy_BazucaAlgodon_Colegio",
		Titulo = "🚀 ARMA DE PARED: BAZUCA DE ALGODÓN",
		IdArma = "Arma_BazucaAlgodon",
		CostoArma = 300,
		CostoMunicion = 120,
		CantidadMunicion = 18,
		Color = Color3.fromRGB(255, 150, 45),
		Pos = Vector3.new(-46, 62, -225),
		RotY = 90,
	},
	{
		Nombre = "WallBuy_GranadaGaseosa_DonAbaco",
		Titulo = "💣 ARMA DE PARED: GRANADA DE GASEOSA",
		IdArma = "Arma_GranadaGaseosa",
		CostoArma = 220,
		CostoMunicion = 90,
		CantidadMunicion = 16,
		Color = Color3.fromRGB(80, 255, 160),
		Pos = Vector3.new(-162, 62, 148),
		RotY = 0,
	},
	{
		Nombre = "WallBuy_DinamitaPinata_Hospital",
		Titulo = "🧨 ARMA DE PARED: DINAMITA DE PIÑATA",
		IdArma = "Arma_DinamitaPinata",
		CostoArma = 380,
		CostoMunicion = 150,
		CantidadMunicion = 20,
		Color = Color3.fromRGB(255, 80, 95),
		Pos = Vector3.new(-395, 62, 338),
		RotY = 0,
	},
}

local function construirWallBuys()
	for _, cfg in ipairs(CONFIG_WALLBUYS) do
		local posSuelo = obtenerPosSueloSegura(cfg.Pos, 0)
		local cfBase = CFrame.new(posSuelo) * CFrame.Angles(0, math.rad(cfg.RotY), 0)

		local modelo = Instance.new("Model")
		modelo.Name = cfg.Nombre
		modelo.Parent = carpetaEstaciones

		local muro = Instance.new("Part")
		muro.Name = "MuralTizaNeon"
		muro.Size = Vector3.new(4.6, 4.2, 0.5)
		muro.CFrame = cfBase * CFrame.new(0, 2.1, 0)
		muro.Anchored = true
		muro.CanCollide = true
		muro.Color = Color3.fromRGB(24, 28, 42)
		muro.Material = Enum.Material.Slate
		muro.Parent = modelo
		modelo.PrimaryPart = muro

		local siluetaCuerpo = Instance.new("Part")
		siluetaCuerpo.Name = "SiluetaArma"
		siluetaCuerpo.Size = Vector3.new(2.8, 0.85, 0.62)
		siluetaCuerpo.CFrame = muro.CFrame * CFrame.new(0, 0.3, 0)
		siluetaCuerpo.Anchored = true
		siluetaCuerpo.CanCollide = false
		siluetaCuerpo.Color = cfg.Color
		siluetaCuerpo.Material = Enum.Material.Neon
		siluetaCuerpo.Parent = modelo

		local siluetaCulata = Instance.new("Part")
		siluetaCulata.Name = "SiluetaEmpunadura"
		siluetaCulata.Size = Vector3.new(0.7, 1.1, 0.62)
		siluetaCulata.CFrame = muro.CFrame * CFrame.new(-0.9, -0.5, 0) * CFrame.Angles(0, 0, math.rad(-18))
		siluetaCulata.Anchored = true
		siluetaCulata.CanCollide = false
		siluetaCulata.Color = cfg.Color
		siluetaCulata.Material = Enum.Material.Neon
		siluetaCulata.Parent = modelo

		local luz = Instance.new("PointLight")
		luz.Color = cfg.Color
		luz.Range = 14
		luz.Brightness = 2.2
		luz.Parent = siluetaCuerpo

		crearCartelFlotante(
			muro,
			cfg.Titulo,
			string.format("Arma: 🍬 %d Dulces | Munición (+%d): 🍬 %d", cfg.CostoArma, cfg.CantidadMunicion, cfg.CostoMunicion),
			cfg.Color,
			Vector3.new(0, 3.1, 0)
		)

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "PromptWallBuy"
		prompt.ObjectText = cfg.Titulo
		prompt.ActionText = string.format("Canjear Arma (🍬 %d) / Munición (🍬 %d)", cfg.CostoArma, cfg.CostoMunicion)
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0.25
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = muro

		prompt.Triggered:Connect(function(player: Player)
			local datos = GestorDatos.ObtenerDatos(player)
			if not datos then
				return
			end
			local yaTiene = datos.ArmasDesbloqueadas and datos.ArmasDesbloqueadas[cfg.IdArma] == true
			local costo = if yaTiene then cfg.CostoMunicion else cfg.CostoArma

			if not GestorDatos.QuitarPesos(player, costo) then
				notificarJugador(
					player,
					"🍬 Dulces Insuficientes",
					string.format("Necesitas 🍬 %d Dulces (tienes %d). ¡Cocina, dispara a zombis o repara barricadas!", costo, datos.PesosDulces)
				)
				return
			end

			desbloquearYEntregarArma(player, cfg.IdArma, cfg.CantidadMunicion)
			reproducirSonido3D(muro, SONIDO_CAJA, 0.75, 1.15)
			notificarJugador(
				player,
				"⚡ ¡Arma de Pared Canjeada!",
				string.format("Equipaste %s + %d proyectiles dulces por 🍬 %d Dulces.", Datos.Armas[cfg.IdArma].Nombre, cfg.CantidadMunicion, costo)
			)
		end)
	end
end

-- ============================================================================
-- 3. CAJAS MISTERIOSAS LAZARUS (PLAZA CENTRAL Y PARQUE CENTRAL)
-- ============================================================================
local ARMAS_CAJA_MISTERIOSA = {
	"Arma_PistolaCrema",
	"Arma_EscopetaChicle",
	"Arma_GranadaGaseosa",
	"Arma_BazucaAlgodon",
	"Arma_DinamitaPinata",
	"Arma_CanonChiva",
}

local UBICACIONES_CAJAS_MISTERIOSAS = {
	{ Nombre = "CajaMisteriosaLazarus_Plaza", Pos = Vector3.new(68, 62, -206) },
	{ Nombre = "CajaMisteriosaLazarus_ParqueCentral", Pos = Vector3.new(-12, 62, -78) },
}

local function construirCajasMisteriosas()
	for _, ubicacion in ipairs(UBICACIONES_CAJAS_MISTERIOSAS) do
		local posSuelo = obtenerPosSueloSegura(ubicacion.Pos, 0)
		local cfBase = CFrame.new(posSuelo)

		local modelo = Instance.new("Model")
		modelo.Name = ubicacion.Nombre
		modelo.Parent = carpetaEstaciones

		local cofre = Instance.new("Part")
		cofre.Name = "CofreMisterioso"
		cofre.Size = Vector3.new(5.8, 2.6, 2.8)
		cofre.CFrame = cfBase * CFrame.new(0, 1.3, 0)
		cofre.Anchored = true
		cofre.CanCollide = true
		cofre.Color = Color3.fromRGB(120, 75, 30)
		cofre.Material = Enum.Material.WoodPlanks
		cofre.Parent = modelo
		modelo.PrimaryPart = cofre

		local bordeOro = Instance.new("Part")
		bordeOro.Name = "SignosInterrogacionNeon"
		bordeOro.Size = Vector3.new(6.0, 0.5, 3.0)
		bordeOro.CFrame = cfBase * CFrame.new(0, 2.55, 0)
		bordeOro.Anchored = true
		bordeOro.CanCollide = false
		bordeOro.Color = Color3.fromRGB(255, 215, 45)
		bordeOro.Material = Enum.Material.Neon
		bordeOro.Parent = modelo

		local hazCielo = Instance.new("Part")
		hazCielo.Name = "HazLuzMisterioso"
		hazCielo.Shape = Enum.PartType.Cylinder
		hazCielo.Size = Vector3.new(160, 2.4, 2.4)
		hazCielo.CFrame = cfBase * CFrame.new(0, 82, 0) * CFrame.Angles(0, 0, math.rad(90))
		hazCielo.Anchored = true
		hazCielo.CanCollide = false
		hazCielo.CanQuery = false
		hazCielo.CanTouch = false
		hazCielo.Transparency = 0.74
		hazCielo.Color = Color3.fromRGB(255, 220, 60)
		hazCielo.Material = Enum.Material.Neon
		hazCielo.Parent = modelo

		local hologramaArma = Instance.new("Part")
		hologramaArma.Name = "HologramaRuletaArma"
		hologramaArma.Size = Vector3.new(2.6, 1.1, 0.8)
		hologramaArma.CFrame = cfBase * CFrame.new(0, 4.2, 0)
		hologramaArma.Anchored = true
		hologramaArma.CanCollide = false
		hologramaArma.Color = Color3.fromRGB(255, 230, 80)
		hologramaArma.Material = Enum.Material.Neon
		hologramaArma.Parent = modelo

		local _, lblCaja = crearCartelFlotante(
			cofre,
			"🎁 CAJA MISTERIOSA LAZARUS [ ? ]",
			"Tirada Aleatoria de Arma + Munición: 🍬 150 Dulces",
			Color3.fromRGB(255, 225, 75),
			Vector3.new(0, 4.6, 0)
		)

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "PromptCajaMisteriosa"
		prompt.ObjectText = "🎁 Caja Misteriosa de Dulce-Armas"
		prompt.ActionText = "Girar Caja Misteriosa (🍬 150 Dulces)"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 11
		prompt.RequiresLineOfSight = false
		prompt.Parent = cofre

		local girando = false
		prompt.Triggered:Connect(function(player: Player)
			if girando then
				notificarJugador(player, "🎁 Caja Girando", "Espera a que termine la ruleta actual de la Caja Misteriosa.")
				return
			end
			local COSTO_CAJA = 150
			local datos = GestorDatos.ObtenerDatos(player)
			if not datos or not GestorDatos.QuitarPesos(player, COSTO_CAJA) then
				notificarJugador(player, "🍬 Dulces Insuficientes", "Necesitas 🍬 150 Dulces para girar la Caja Misteriosa.")
				return
			end

			girando = true
			prompt.Enabled = false
			reproducirSonido3D(cofre, SONIDO_CAJA, 0.85, 1.0)

			for paso = 1, 10 do
				local idTemp = ARMAS_CAJA_MISTERIOSA[((paso - 1) % #ARMAS_CAJA_MISTERIOSA) + 1]
				local infoTemp = Datos.Armas[idTemp]
				lblCaja.Text = string.format("🎰 GIRANDO RULETA...\n[ %s ]", infoTemp and infoTemp.Nombre or idTemp)
				hologramaArma.Color = Color3.fromHSV((paso * 0.1) % 1, 0.85, 1)
				hologramaArma.CFrame = cfBase * CFrame.new(0, 3.8 + math.sin(paso * 0.6) * 0.7, 0) * CFrame.Angles(0, math.rad(paso * 36), 0)
				task.wait(0.18)
			end

			local idGanado = ARMAS_CAJA_MISTERIOSA[math.random(1, #ARMAS_CAJA_MISTERIOSA)]
			local infoGanada = Datos.Armas[idGanado]
			desbloquearYEntregarArma(player, idGanado, 30)
			reproducirSonido3D(cofre, SONIDO_POWERUP, 0.85, 1.15)

			lblCaja.Text = string.format("🎁 ¡PREMIO: %s!\n+30 Dulces de Munición", infoGanada.Nombre)
			notificarJugador(
				player,
				"🎁 ¡Caja Misteriosa Lazarus!",
				string.format("¡Obtuviste %s + 30 unidades de munición (%s)!", infoGanada.Nombre, infoGanada.DulceMunicion)
			)

			task.delay(1.5, function()
				lblCaja.Text = "🎁 CAJA MISTERIOSA LAZARUS [ ? ]\nTirada Aleatoria de Arma + Munición: 🍬 150 Dulces"
				prompt.Enabled = true
				girando = false
			end)
		end)
	end
end

local ARMAS_CAJA_TACTICAS = {
	"Uzi",
	"Taper 21",
	"Kinetic",
	"DMR",
	"Rhino spear",
	"Burtan AntiMaterialRifle",
	"Railgun",
}

local function rellenarMunicionArma(tool: Tool): boolean
	local gunServer = tool:FindFirstChild("GunScript_Server")
	local settingMod = tool:FindFirstChild("Setting")
	if not gunServer or not settingMod or not settingMod:IsA("ModuleScript") then
		return false
	end
	local ok, cfg = pcall(require, settingMod)
	if not ok or typeof(cfg) ~= "table" then
		return false
	end
	local ammoVal = gunServer:FindFirstChild("Ammo")
	if ammoVal and ammoVal:IsA("NumberValue") then
		ammoVal.Value = (cfg :: any).AmmoPerClip or 30
	end
	local clipsVal = gunServer:FindFirstChild("Clips")
	if clipsVal and clipsVal:IsA("NumberValue") then
		clipsVal.Value = (cfg :: any).MaxClip or 10
	end
	return true
end

local function entregarArmaCajaMisteriosa(player: Player, nombreArma: string): boolean
	local armasFolder = ServerStorage:FindFirstChild("ArmasHorda")
	local plantilla = armasFolder and armasFolder:FindFirstChild(nombreArma)
	if not plantilla or not plantilla:IsA("Tool") then
		return false
	end
	local backpack = player:FindFirstChildOfClass("Backpack")
	local char = player.Character
	local existente = (char and char:FindFirstChild(nombreArma)) or (backpack and backpack:FindFirstChild(nombreArma))
	if existente and existente:IsA("Tool") then
		rellenarMunicionArma(existente)
		return true
	end
	if backpack then
		local clon = plantilla:Clone()
		clon:SetAttribute("EsArmaHorda", true)
		clon.CanBeDropped = false
		clon.Parent = backpack
		return true
	end
	return false
end

local function construirCajasMisteriosasTacticas()
	for _, ubicacion in ipairs(UBICACIONES_CAJAS_MISTERIOSAS) do
		local posSuelo = obtenerPosSueloSegura(ubicacion.Pos, 0)
		local cfBase = CFrame.new(posSuelo)

		local modelo = Instance.new("Model")
		modelo.Name = ubicacion.Nombre
		modelo.Parent = carpetaEstaciones

		local cofre = Instance.new("Part")
		cofre.Name = "CofreMisterioso"
		cofre.Size = Vector3.new(6.0, 2.6, 2.8)
		cofre.CFrame = cfBase * CFrame.new(0, 1.3, 0)
		cofre.Anchored = true
		cofre.CanCollide = true
		cofre.Color = Color3.fromRGB(68, 52, 36)
		cofre.Material = Enum.Material.WoodPlanks
		cofre.Parent = modelo
		modelo.PrimaryPart = cofre

		for _, xOff in ipairs({ -2.55, 0, 2.55 }) do
			local banda = Instance.new("Part")
			banda.Name = "BandaAcero"
			banda.Size = Vector3.new(0.32, 2.7, 2.95)
			banda.CFrame = cfBase * CFrame.new(xOff, 1.3, 0)
			banda.Anchored = true
			banda.CanCollide = false
			banda.Color = Color3.fromRGB(36, 38, 42)
			banda.Material = Enum.Material.Metal
			banda.Parent = modelo
		end

		local bordeOro = Instance.new("Part")
		bordeOro.Name = "SignosInterrogacionNeon"
		bordeOro.Size = Vector3.new(5.8, 0.25, 2.9)
		bordeOro.CFrame = cfBase * CFrame.new(0, 2.55, 0)
		bordeOro.Anchored = true
		bordeOro.CanCollide = false
		bordeOro.Color = Color3.fromRGB(235, 185, 65)
		bordeOro.Material = Enum.Material.Neon
		bordeOro.Parent = modelo

		local hazCielo = Instance.new("Part")
		hazCielo.Name = "HazLuzMisterioso"
		hazCielo.Shape = Enum.PartType.Cylinder
		hazCielo.Size = Vector3.new(180, 1.8, 1.8)
		hazCielo.CFrame = cfBase * CFrame.new(0, 92, 0) * CFrame.Angles(0, 0, math.rad(90))
		hazCielo.Anchored = true
		hazCielo.CanCollide = false
		hazCielo.CanQuery = false
		hazCielo.CanTouch = false
		hazCielo.Transparency = 0.82
		hazCielo.Color = Color3.fromRGB(255, 205, 80)
		hazCielo.Material = Enum.Material.Neon
		hazCielo.Parent = modelo

		local hologramaArma = Instance.new("Part")
		hologramaArma.Name = "HologramaRuletaArma"
		hologramaArma.Size = Vector3.new(2.6, 0.9, 0.6)
		hologramaArma.CFrame = cfBase * CFrame.new(0, 4.0, 0)
		hologramaArma.Anchored = true
		hologramaArma.CanCollide = false
		hologramaArma.Transparency = 0.35
		hologramaArma.Color = Color3.fromRGB(255, 210, 85)
		hologramaArma.Material = Enum.Material.Neon
		hologramaArma.Parent = modelo

		local _, lblCaja = crearCartelFlotante(
			cofre,
			"🎁 CAJA MISTERIOSA [ ? ]",
			"Arma Táctica Aleatoria: $250 Pesos",
			Color3.fromRGB(255, 215, 85),
			Vector3.new(0, 4.6, 0)
		)

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "PromptCajaMisteriosa"
		prompt.ObjectText = "🎁 Caja Misteriosa"
		prompt.ActionText = "Abrir Caja Misteriosa ($250)"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 11
		prompt.RequiresLineOfSight = false
		prompt.Parent = cofre

		local girando = false
		prompt.Triggered:Connect(function(player: Player)
			if girando then
				notificarJugador(player, "🎁 Caja Girando", "Espera a que termine la ruleta actual de la Caja Misteriosa.")
				return
			end
			local COSTO_CAJA = 250
			local datos = GestorDatos.ObtenerDatos(player)
			if not datos or not GestorDatos.QuitarPesos(player, COSTO_CAJA) then
				notificarJugador(player, "💸 Pesos Insuficientes", "Necesitas $250 Pesos para girar la Caja Misteriosa.")
				return
			end

			girando = true
			prompt.Enabled = false
			reproducirSonido3D(cofre, SONIDO_CAJA, 0.85, 1.0)

			for paso = 1, 10 do
				local nombreTemp = ARMAS_CAJA_TACTICAS[((paso - 1) % #ARMAS_CAJA_TACTICAS) + 1]
				lblCaja.Text = string.format("🎰 SELECCIONANDO ARMA...\n[ %s ]", nombreTemp)
				hologramaArma.Color = Color3.fromHSV((paso * 0.08) % 1, 0.65, 1)
				hologramaArma.CFrame = cfBase * CFrame.new(0, 3.6 + math.sin(paso * 0.6) * 0.6, 0) * CFrame.Angles(0, math.rad(paso * 36), 0)
				task.wait(0.18)
			end

			local armaGanada = ARMAS_CAJA_TACTICAS[math.random(1, #ARMAS_CAJA_TACTICAS)]
			local entregada = entregarArmaCajaMisteriosa(player, armaGanada)
			if not entregada then
				desbloquearYEntregarArma(player, "Arma_BazucaAlgodon", 25)
			else
				GestorDatos.AgregarDulce(player, "Dulce_Gomita", 15)
			end
			reproducirSonido3D(cofre, SONIDO_POWERUP, 0.85, 1.15)

			lblCaja.Text = string.format("🎁 ¡PREMIO: %s!\nArmamento Entregado", armaGanada)
			notificarJugador(
				player,
				"🎁 ¡Caja Misteriosa!",
				string.format("¡Obtuviste %s de la Caja Misteriosa!", armaGanada)
			)

			task.delay(1.8, function()
				lblCaja.Text = "🎁 CAJA MISTERIOSA [ ? ]\nArma Táctica Aleatoria: $250 Pesos"
				prompt.Enabled = true
				girando = false
			end)
		end)
	end
end

-- ============================================================================
-- 4. MÁQUINAS DE JARABE PERK-A-COLA Y FORJA PACK-A-PUNCH TRON (7 ESTACIONES)
-- ============================================================================
local CONFIG_PERKS = {
	{
		Nombre = "MaquinaPerk_TitanMuela_Cocina",
		Titulo = "🥤 TITÁN-MUELA (JUGGERNOG DULCE)",
		Subtitulo = "Duplica tu Salud Máxima a 200 HP | Canje: 🍬 250 Dulces",
		Atributo = "PerkTitanMuela",
		Costo = 250,
		Color = Color3.fromRGB(255, 65, 85),
		Pos = Vector3.new(75, 62, -276),
	},
	{
		Nombre = "MaquinaPerk_Relampago_Cocina",
		Titulo = "⚡ GASEOSA RELÁMPAGO (STAMIN-UP)",
		Subtitulo = "+35% Velocidad de Movimiento Táctico | Canje: 🍬 200 Dulces",
		Atributo = "PerkVelocidad",
		Costo = 200,
		Color = Color3.fromRGB(255, 225, 55),
		Pos = Vector3.new(86, 62, -276),
	},
	{
		Nombre = "MaquinaPerk_DobleCadencia_Plaza",
		Titulo = "🔥 NÉCTAR DOBLE CADENCIA (DOUBLE TAP)",
		Subtitulo = "+40% Cadencia de Disparo y +35% Daño | Canje: 🍬 300 Dulces",
		Atributo = "PerkDobleDisparo",
		Costo = 300,
		Color = Color3.fromRGB(255, 140, 35),
		Pos = Vector3.new(58, 62, -206),
	},
	{
		Nombre = "MaquinaPerk_Regenerador_Colegio",
		Titulo = "💚 ELIXIR REGENERADOR (QUICK REVIVE)",
		Subtitulo = "Regeneración Rápida Continua (+8 HP/s) | Canje: 🍬 200 Dulces",
		Atributo = "PerkRegeneracion",
		Costo = 200,
		Color = Color3.fromRGB(50, 245, 210),
		Pos = Vector3.new(-32, 62, -214),
	},
	{
		Nombre = "Forja_PackAPunch_TRON_Plaza",
		Titulo = "🔮 FORJA PACK-A-PUNCH TRON (MK-II)",
		Subtitulo = "Potencia todas tus Armas (Daño x2.2 + Munición) | Canje: 🍬 500 Dulces",
		Atributo = "ArmaPotenciada",
		Costo = 500,
		Color = Color3.fromRGB(190, 70, 255),
		Pos = Vector3.new(78, 62, -206),
	},
	{
		Nombre = "MaquinaPerk_TitanMuela_Hospital",
		Titulo = "🥤 TITÁN-MUELA (HOSPITAL SAN RAFAEL)",
		Subtitulo = "Duplica tu Salud Máxima a 200 HP | Canje: 🍬 250 Dulces",
		Atributo = "PerkTitanMuela",
		Costo = 250,
		Color = Color3.fromRGB(255, 65, 85),
		Pos = Vector3.new(-375, 62, 338),
	},
	{
		Nombre = "Forja_PackAPunch_EsquinaPaisa",
		Titulo = "🔮 FORJA PACK-A-PUNCH (ESQUINA PAISA)",
		Subtitulo = "Potencia todas tus Armas (Daño x2.2 + Munición) | Canje: 🍬 500 Dulces",
		Atributo = "ArmaPotenciada",
		Costo = 500,
		Color = Color3.fromRGB(190, 70, 255),
		Pos = Vector3.new(165, 62, -148),
	},
}

local function aplicarEfectosPerksAlPersonaje(player: Player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return
	end

	if player:GetAttribute("PerkTitanMuela") == true then
		if hum.MaxHealth < 200 then
			hum.MaxHealth = 200
			hum.Health = 200
		end
	end

	if player:GetAttribute("PerkVelocidad") == true then
		if hum.WalkSpeed < 22 then
			hum.WalkSpeed = 22
		end
	end
end

local function construirMaquinasPerks()
	for _, cfg in ipairs(CONFIG_PERKS) do
		local posSuelo = obtenerPosSueloSegura(cfg.Pos, 0)
		local cfBase = CFrame.new(posSuelo)

		local modelo = Instance.new("Model")
		modelo.Name = cfg.Nombre
		modelo.Parent = carpetaEstaciones

		local cuerpo = Instance.new("Part")
		cuerpo.Name = "CuerpoMaquina"
		cuerpo.Size = Vector3.new(3.6, 6.4, 2.6)
		cuerpo.CFrame = cfBase * CFrame.new(0, 3.2, 0)
		cuerpo.Anchored = true
		cuerpo.CanCollide = true
		cuerpo.Color = Color3.fromRGB(30, 32, 38)
		cuerpo.Material = Enum.Material.Metal
		cuerpo.Parent = modelo
		modelo.PrimaryPart = cuerpo

		local marquesina = Instance.new("Part")
		marquesina.Name = "MarquesinaSuperior"
		marquesina.Size = Vector3.new(3.8, 0.75, 2.8)
		marquesina.CFrame = cfBase * CFrame.new(0, 6.2, 0)
		marquesina.Anchored = true
		marquesina.CanCollide = false
		marquesina.Color = Color3.fromRGB(22, 24, 28)
		marquesina.Material = Enum.Material.CorrodedMetal
		marquesina.Parent = modelo

		local luzInterior = Instance.new("Part")
		luzInterior.Name = "Retroiluminacion"
		luzInterior.Size = Vector3.new(2.4, 3.6, 2.55)
		luzInterior.CFrame = cfBase * CFrame.new(0, 3.4, 0)
		luzInterior.Anchored = true
		luzInterior.CanCollide = false
		luzInterior.Transparency = 0.25
		luzInterior.Color = cfg.Color
		luzInterior.Material = Enum.Material.Neon
		luzInterior.Parent = modelo

		local panelCristal = Instance.new("Part")
		panelCristal.Name = "PanelCristalFrontal"
		panelCristal.Size = Vector3.new(2.75, 4.0, 2.72)
		panelCristal.CFrame = cfBase * CFrame.new(0, 3.4, 0)
		panelCristal.Anchored = true
		panelCristal.CanCollide = false
		panelCristal.Transparency = 0.35
		panelCristal.Color = cfg.Color:Lerp(Color3.new(0, 0, 0), 0.45)
		panelCristal.Material = Enum.Material.Glass
		panelCristal.Parent = modelo

		local luz = Instance.new("PointLight")
		luz.Color = cfg.Color
		luz.Range = 14
		luz.Brightness = 1.6
		luz.Parent = panelCristal

		crearCartelFlotante(
			cuerpo,
			cfg.Titulo,
			cfg.Subtitulo,
			cfg.Color,
			Vector3.new(0, 4.4, 0)
		)

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "PromptComprarPerk"
		prompt.ObjectText = cfg.Titulo
		prompt.ActionText = string.format("Canjear Mejora (🍬 %d Dulces)", cfg.Costo)
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = cuerpo

		prompt.Triggered:Connect(function(player: Player)
			if player:GetAttribute(cfg.Atributo) == true then
				notificarJugador(player, "✅ Mejora Ya Activa", "Ya tienes equipada esta mejora de supervivencia Zombie.")
				return
			end
			local datos = GestorDatos.ObtenerDatos(player)
			if not datos or not GestorDatos.QuitarPesos(player, cfg.Costo) then
				notificarJugador(
					player,
					"🍬 Dulces Insuficientes",
					string.format("Necesitas 🍬 %d Dulces para activar %s.", cfg.Costo, cfg.Titulo)
				)
				return
			end

			player:SetAttribute(cfg.Atributo, true)
			aplicarEfectosPerksAlPersonaje(player)

			if cfg.Atributo == "ArmaPotenciada" then
				for _, idDulce in ipairs({ "Dulce_Gomita", "Dulce_Bombon", "Dulce_Chicle", "Dulce_Arequipe", "Dulce_Bocadillo" }) do
					GestorDatos.AgregarDulce(player, idDulce, 25)
				end
			end

			reproducirSonido3D(cuerpo, SONIDO_POWERUP, 0.85, 1.1)
			notificarJugador(
				player,
				"⚡ ¡Mejora Lazarus Activada!",
				string.format("Canjeaste %s por 🍬 %d Dulces. ¡Tu capacidad de supervivencia aumentó!", cfg.Titulo, cfg.Costo)
			)
		end)
	end
end

-- ============================================================================
-- 5. INFRAESTRUCTURA DE CUARENTENA ZOMBIE EN LA CIUDAD (TORRES, CRISTALES Y ARCOS)
-- ============================================================================
local TORRES_CUARENTENA = {
	{ Nombre = "TorreReflector_Plaza", Pos = Vector3.new(55, 62, -198), Color = Color3.fromRGB(0, 240, 255) },
	{ Nombre = "TorreReflector_Colegio", Pos = Vector3.new(-28, 62, -205), Color = Color3.fromRGB(255, 185, 45) },
	{ Nombre = "TorreReflector_ParqueCentral", Pos = Vector3.new(0, 62, -68), Color = Color3.fromRGB(190, 75, 255) },
	{ Nombre = "TorreReflector_EsquinaPaisa", Pos = Vector3.new(152, 62, -142), Color = Color3.fromRGB(0, 240, 255) },
	{ Nombre = "TorreReflector_DonAbaco", Pos = Vector3.new(-152, 62, 142), Color = Color3.fromRGB(80, 255, 150) },
	{ Nombre = "TorreReflector_Hospital", Pos = Vector3.new(-380, 62, 315), Color = Color3.fromRGB(255, 70, 95) },
}

local CRISTALES_INFECCION = {
	Vector3.new(42, 62, -238),
	Vector3.new(96, 62, -242),
	Vector3.new(-22, 62, -235),
	Vector3.new(18, 62, -110),
	Vector3.new(135, 62, -165),
	Vector3.new(-135, 62, 165),
	Vector3.new(-365, 62, 305),
	Vector3.new(10, 62, -330),
}

local function construirInfraestructuraZombie()
	for _, cfg in ipairs(TORRES_CUARENTENA) do
		local posSuelo = obtenerPosSueloSegura(cfg.Pos, 0)
		local cfBase = CFrame.new(posSuelo)

		local torre = Instance.new("Model")
		torre.Name = cfg.Nombre
		torre.Parent = carpetaInfraestructura

		local mastil = Instance.new("Part")
		mastil.Name = "MastilTactico"
		mastil.Size = Vector3.new(1.2, 14, 1.2)
		mastil.CFrame = cfBase * CFrame.new(0, 7, 0)
		mastil.Anchored = true
		mastil.CanCollide = true
		mastil.Color = Color3.fromRGB(30, 34, 46)
		mastil.Material = Enum.Material.Metal
		mastil.Parent = torre
		torre.PrimaryPart = mastil

		for i = 0, 3 do
			local ang = math.rad(i * 90)
			local saco = Instance.new("Part")
			saco.Name = "TrincheraArena_" .. i
			saco.Size = Vector3.new(3.4, 1.4, 1.2)
			saco.CFrame = cfBase * CFrame.Angles(0, ang, 0) * CFrame.new(0, 0.7, 1.8)
			saco.Anchored = true
			saco.CanCollide = true
			saco.Color = Color3.fromRGB(135, 118, 84)
			saco.Material = Enum.Material.Sand
			saco.Parent = torre
		end

		local reflector = Instance.new("Part")
		reflector.Name = "CabezalReflector"
		reflector.Size = Vector3.new(3.2, 1.6, 1.4)
		reflector.CFrame = cfBase * CFrame.new(0, 14.2, 0)
		reflector.Anchored = true
		reflector.CanCollide = false
		reflector.Color = cfg.Color
		reflector.Material = Enum.Material.Neon
		reflector.Parent = torre

		local luz = Instance.new("PointLight")
		luz.Color = cfg.Color
		luz.Range = 36
		luz.Brightness = 2.6
		luz.Parent = reflector

		crearCartelFlotante(
			reflector,
			"☣️ ZONA FORTIFICADA ANTI-ZOMBIE",
			"Moneda Oficial: 🍬 Dulces | Defiende las Barricadas",
			cfg.Color,
			Vector3.new(0, 2.5, 0)
		)
	end

	for idx, pos in ipairs(CRISTALES_INFECCION) do
		local posSuelo = obtenerPosSueloSegura(pos, 0)
		local cfBase = CFrame.new(posSuelo)

		local cluster = Instance.new("Model")
		cluster.Name = "ClusterAzucarZombie_" .. idx
		cluster.Parent = carpetaInfraestructura

		local coloresCristal = {
			Color3.fromRGB(185, 55, 255),
			Color3.fromRGB(65, 255, 145),
			Color3.fromRGB(255, 55, 140),
		}
		local col = coloresCristal[((idx - 1) % #coloresCristal) + 1]

		for c = 1, 3 do
			local cristal = Instance.new("Part")
			cristal.Name = "Cristal_" .. c
			cristal.Size = Vector3.new(1.1, 3.2 + c * 0.9, 1.1)
			cristal.CFrame = cfBase
				* CFrame.new((c - 2) * 0.9, 1.4 + c * 0.3, (c % 2 == 0 and 0.5 or -0.4))
				* CFrame.Angles(math.rad((c - 2) * 18), math.rad(c * 45), math.rad((2 - c) * 15))
			cristal.Anchored = true
			cristal.CanCollide = false
			cristal.Transparency = 0.15
			cristal.Color = col
			cristal.Material = Enum.Material.Neon
			cristal.Parent = cluster

			if c == 1 then
				local pLight = Instance.new("PointLight")
				pLight.Color = col
				pLight.Range = 14
				pLight.Brightness = 1.8
				pLight.Parent = cristal
			end
		end
	end
end

-- ============================================================================
-- 6. DROPS FLOTANTES DE ZOMBIS (KABOOM, MAX AMMO, 2X DULCES, INSTA-KILL)
-- ============================================================================
local TIPOS_POWERUP = {
	{
		Id = "KABOOM",
		Nombre = "💣 ¡KABOOM DULCE! (NUKE)",
		Color = Color3.fromRGB(255, 175, 40),
	},
	{
		Id = "MUNICION_MAXIMA",
		Nombre = "🍬 ¡MUNICIÓN MÁXIMA! (MAX AMMO)",
		Color = Color3.fromRGB(80, 255, 140),
	},
	{
		Id = "PUNTOS_DOBLES",
		Nombre = "🍬 ¡DULCES DOBLES! (2X - 30s)",
		Color = Color3.fromRGB(255, 235, 65),
	},
	{
		Id = "INSTA_KILL",
		Nombre = "💀 ¡AZÚCAR LETAL! (INSTA-KILL - 30s)",
		Color = Color3.fromRGB(255, 55, 95),
	},
}

local expiracionPuntosDobles = 0
local expiracionInstaKill = 0

local function activarEfectoPowerUpGlobal(tipoId: string, recolector: Player)
	if tipoId == "KABOOM" then
		local eliminados = 0
		for modeloZombi, _ in pairs(ZombieService.ObtenerZombisActivos()) do
			ZombieService.AplicarDanio(modeloZombi, 99999, recolector, "Arma_DinamitaPinata")
			eliminados += 1
		end
		for _, p in ipairs(Players:GetPlayers()) do
			GestorDatos.AgregarPesos(p, 150)
			notificarJugador(
				p,
				"💣 ¡KABOOM DULCE!",
				string.format("%s activó una Bomba Nuke: %d zombis pulverizados y +150 🍬 Dulces para todos!", recolector.Name, eliminados)
			)
		end
	elseif tipoId == "MUNICION_MAXIMA" then
		local dulcesMunicion = { "Dulce_Gomita", "Dulce_Bombon", "Dulce_Chicle", "Dulce_Panelita", "Dulce_Arequipe", "Dulce_Bocadillo" }
		for _, p in ipairs(Players:GetPlayers()) do
			for _, idDulce in ipairs(dulcesMunicion) do
				GestorDatos.AgregarDulce(p, idDulce, 25)
			end
			for _, contenedor in ipairs({ p:FindFirstChildOfClass("Backpack"), p.Character }) do
				if contenedor then
					for _, item in ipairs(contenedor:GetChildren()) do
						if item:IsA("Tool") then
							rellenarMunicionArma(item)
						end
					end
				end
			end
			notificarJugador(
				p,
				"🍬 ¡MUNICIÓN MÁXIMA!",
				string.format("%s recogió Munición Máxima: +25 de todos los Dulces y munición recargados!", recolector.Name)
			)
		end
	elseif tipoId == "PUNTOS_DOBLES" then
		expiracionPuntosDobles = os.clock() + 30
		Workspace:SetAttribute("LazarusPuntosDobles", true)
		Workspace:SetAttribute("LazarusPuntosDoblesSegundos", 30)
		for _, p in ipairs(Players:GetPlayers()) do
			notificarJugador(p, "🍬 ¡DULCES DOBLES (30s)!", "¡Todos los impactos, bajas y reparaciones de barricadas otorgan el DOBLE de Dulces por 30 segundos!")
		end
	elseif tipoId == "INSTA_KILL" then
		expiracionInstaKill = os.clock() + 30
		Workspace:SetAttribute("LazarusInstaKill", true)
		Workspace:SetAttribute("LazarusInstaKillSegundos", 30)
		for _, p in ipairs(Players:GetPlayers()) do
			notificarJugador(p, "💀 ¡AZÚCAR LETAL / INSTA-KILL (30s)!", "¡Cualquier disparo elimina a los zombis de un solo impacto durante 30 segundos!")
		end
	end
	local nombrePowerUp = tipoId
	for _, info in ipairs(TIPOS_POWERUP) do
		if info.Id == tipoId then
			nombrePowerUp = info.Nombre
			break
		end
	end
	EventosRemotos.ZombieEventoVisual:FireAllClients({
		Tipo = "PowerUp",
		PowerUpId = tipoId,
		Nombre = nombrePowerUp,
		Jugador = recolector.Name,
	})
end

local function generarDropPowerUp(posicion: Vector3, indiceForzado: number?)
	local cfg = TIPOS_POWERUP[indiceForzado or math.random(1, #TIPOS_POWERUP)]
	local posSuelo = obtenerPosSueloSegura(posicion, 2.6)

	local orbe = Instance.new("Part")
	orbe.Name = "PowerUpLazarus_" .. cfg.Id
	orbe.Shape = Enum.PartType.Ball
	orbe.Size = Vector3.new(2.6, 2.6, 2.6)
	orbe.Position = posSuelo
	orbe.Anchored = true
	orbe.CanCollide = false
	orbe.Color = cfg.Color
	orbe.Material = Enum.Material.Neon
	orbe:SetAttribute("TipoPowerUp", cfg.Id)
	orbe.Parent = carpetaDrops

	local luz = Instance.new("PointLight")
	luz.Color = cfg.Color
	luz.Range = 15
	luz.Brightness = 2.8
	luz.Parent = orbe

	crearCartelFlotante(
		orbe,
		cfg.Nombre,
		"¡Tócalo para activarlo para todo el equipo!",
		cfg.Color,
		Vector3.new(0, 2.6, 0)
	)

	local recogido = false
	orbe.Touched:Connect(function(hit: BasePart)
		if recogido then
			return
		end
		local char = hit.Parent
		local player = char and Players:GetPlayerFromCharacter(char :: Model)
		if not player then
			return
		end
		recogido = true
		reproducirSonido3D(Workspace, SONIDO_POWERUP, 0.9, 1.05)
		activarEfectoPowerUpGlobal(cfg.Id, player)
		orbe:Destroy()
	end)

	Debris:AddItem(orbe, 28)
	return orbe
end

local zombisMonitoreados: { [Model]: boolean } = {}
local function registrarMonitoreoZombi(modeloZombi: Model)
	if zombisMonitoreados[modeloZombi] then
		return
	end
	zombisMonitoreados[modeloZombi] = true

	local hum = modeloZombi:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end

	hum.Died:Connect(function()
		local hrp = modeloZombi.PrimaryPart or modeloZombi:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp and math.random() <= 0.42 then
			generarDropPowerUp(hrp.Position)
		end
		zombisMonitoreados[modeloZombi] = nil
	end)
end

-- ============================================================================
-- 7. BUCLE PRINCIPAL LAZARUS (ZOMBIS VS BARRICADAS, REGENERACIÓN Y TIMERS)
-- ============================================================================
construirBarricadas()
construirWallBuys()
construirCajasMisteriosasTacticas()
construirMaquinasPerks()
construirInfraestructuraZombie()

local bindDropExistente = script.Parent:FindFirstChild("SpawnDropLazarus")
if bindDropExistente then
	bindDropExistente:Destroy()
end
local bindDropLazarus = Instance.new("BindableEvent")
bindDropLazarus.Name = "SpawnDropLazarus"
bindDropLazarus.Parent = script.Parent
bindDropLazarus.Event:Connect(function(posicion: Vector3, tipoOIndice: any)
	if typeof(posicion) ~= "Vector3" then
		return
	end
	local indice: number? = nil
	if typeof(tipoOIndice) == "number" then
		indice = tipoOIndice
	elseif typeof(tipoOIndice) == "string" then
		for idx, info in ipairs(TIPOS_POWERUP) do
			if info.Id == tipoOIndice then
				indice = idx
				break
			end
		end
	end
	generarDropPowerUp(posicion, indice)
end)

generarDropPowerUp(Vector3.new(69, 62, -211), 3)

Players.PlayerAdded:Connect(function(player: Player)
	player.CharacterAdded:Connect(function()
		task.wait(0.35)
		aplicarEfectosPerksAlPersonaje(player)
	end)
end)
for _, p in ipairs(Players:GetPlayers()) do
	if p.Character then
		task.spawn(aplicarEfectosPerksAlPersonaje, p)
	end
end

task.spawn(function()
	while true do
		task.wait(0.5)
		local ahora = os.clock()

		if Workspace:GetAttribute("LazarusPuntosDobles") == true then
			local restante = math.max(0, math.ceil(expiracionPuntosDobles - ahora))
			Workspace:SetAttribute("LazarusPuntosDoblesSegundos", restante)
			if restante <= 0 then
				Workspace:SetAttribute("LazarusPuntosDobles", false)
			end
		end
		if Workspace:GetAttribute("LazarusInstaKill") == true then
			local restante = math.max(0, math.ceil(expiracionInstaKill - ahora))
			Workspace:SetAttribute("LazarusInstaKillSegundos", restante)
			if restante <= 0 then
				Workspace:SetAttribute("LazarusInstaKill", false)
			end
		end

		for _, orbe in ipairs(carpetaDrops:GetChildren()) do
			if orbe:IsA("BasePart") then
				orbe.CFrame = orbe.CFrame * CFrame.Angles(0, math.rad(22), 0)
			end
		end

		for _, player in ipairs(Players:GetPlayers()) do
			aplicarEfectosPerksAlPersonaje(player)
			if player:GetAttribute("PerkRegeneracion") == true then
				local char = player.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 and hum.Health < hum.MaxHealth then
					hum.Health = math.min(hum.MaxHealth, hum.Health + 4)
				end
			end
		end

		local carpetaZombis = UtilidadesMapaHorda.ObtenerCarpetaZombis()
		for _, inst in ipairs(carpetaZombis:GetChildren()) do
			if inst:IsA("Model") then
				registrarMonitoreoZombi(inst)
				local hrp = inst.PrimaryPart or inst:FindFirstChild("HumanoidRootPart") :: BasePart?
				local hum = inst:FindFirstChildOfClass("Humanoid")
				if hrp and hum and hum.Health > 0 then
					for _, reg in ipairs(barricadasActivas) do
						if reg.CantidadActual > 0 then
							local dist = (hrp.Position - reg.Centro.Position).Magnitude
							if dist <= 6.2 and (ahora - reg.UltimoAtaqueZombi) >= 1.7 then
								reg.UltimoAtaqueZombi = ahora
								reg.CantidadActual = math.max(0, reg.CantidadActual - 1)
								actualizarVisualBarricada(reg)
								reproducirSonido3D(reg.Centro, SONIDO_MADERA, 0.75, 0.95)
							end
						end
					end
				end
			end
		end
	end
end)

print("El Patrón del Dulce: Mapa, Moneda de Dulces e Infraestructura Zombie Project Lazarus inicializados.")

