local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)

local function soldar(p0: BasePart, p1: BasePart)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.Parent = p0
end

local function crearCarpeta(parent: Instance, nombre: string): Folder
	local f = parent:FindFirstChild(nombre)
	if not f then
		f = Instance.new("Folder")
		f.Name = nombre
		f.Parent = parent
	end
	return f :: Folder
end

-- ====================================================================
-- 1. CONSTRUCCIÓN DEL HOSPITAL SAN RAFAEL & URGENCIAS 24H
-- ====================================================================
local function construirHospitalSanRafael(parent: Instance)
	local hospitalModel = Instance.new("Model")
	hospitalModel.Name = "Hospital_SanRafael"

	local basePos = Vector3.new(38, 83.2, 215)

	-- Plataforma base / Pavimento de Urgencias
	local plataforma = Instance.new("Part")
	plataforma.Name = "PlataformaHospital"
	plataforma.Size = Vector3.new(30, 0.6, 26)
	plataforma.Position = basePos + Vector3.new(0, 0.3, 0)
	plataforma.Color = Color3.fromRGB(225, 230, 235)
	plataforma.Material = Enum.Material.Concrete
	plataforma.Anchored = true
	plataforma.CanCollide = true
	plataforma.Parent = hospitalModel
	hospitalModel.PrimaryPart = plataforma

	-- Edificio Principal (Fachada blanca con moldura azul clínico)
	local edificio = Instance.new("Part")
	edificio.Name = "EdificioPrincipal"
	edificio.Size = Vector3.new(22, 12, 18)
	edificio.Position = basePos + Vector3.new(2, 6.3, 0)
	edificio.Color = Color3.fromRGB(245, 248, 252)
	edificio.Material = Enum.Material.SmoothPlastic
	edificio.Anchored = true
	edificio.CanCollide = true
	edificio.Parent = hospitalModel

	-- Franja azul distintiva de centro de salud
	local franjaAzul = Instance.new("Part")
	franjaAzul.Name = "FranjaClinica"
	franjaAzul.Size = Vector3.new(22.2, 1.2, 18.2)
	franjaAzul.Position = edificio.Position + Vector3.new(0, 3.5, 0)
	franjaAzul.Color = Color3.fromRGB(45, 120, 215)
	franjaAzul.Material = Enum.Material.SmoothPlastic
	franjaAzul.Anchored = true
	franjaAzul.CanCollide = false
	franjaAzul.Parent = hospitalModel

	-- Techo con borde protector
	local cornisa = Instance.new("Part")
	cornisa.Name = "CornisaTecho"
	cornisa.Size = Vector3.new(23, 0.8, 19)
	cornisa.Position = edificio.Position + Vector3.new(0, 6.2, 0)
	cornisa.Color = Color3.fromRGB(60, 70, 85)
	cornisa.Material = Enum.Material.Concrete
	cornisa.Anchored = true
	cornisa.CanCollide = false
	cornisa.Parent = hospitalModel

	-- Gran Cruz Médica Iluminada (Cruz Verde / Roja de Urgencias)
	local cruzCentro = Instance.new("Part")
	cruzCentro.Name = "CruzMedica_V"
	cruzCentro.Size = Vector3.new(1.0, 3.8, 0.2)
	cruzCentro.Position = edificio.Position + Vector3.new(-11.12, 3.5, 0)
	cruzCentro.Color = Color3.fromRGB(40, 220, 100)
	cruzCentro.Material = Enum.Material.Neon
	cruzCentro.Anchored = true
	cruzCentro.CanCollide = false
	cruzCentro.Parent = hospitalModel

	local cruzHoriz = Instance.new("Part")
	cruzHoriz.Name = "CruzMedica_H"
	cruzHoriz.Size = Vector3.new(1.0, 1.0, 3.4)
	cruzHoriz.Position = cruzCentro.Position
	cruzHoriz.Color = Color3.fromRGB(40, 220, 100)
	cruzHoriz.Material = Enum.Material.Neon
	cruzHoriz.Anchored = true
	cruzHoriz.CanCollide = false
	cruzHoriz.Parent = hospitalModel

	local luzCruz = Instance.new("PointLight")
	luzCruz.Name = "LuzCruz"
	luzCruz.Color = Color3.fromRGB(50, 240, 120)
	luzCruz.Brightness = 2.5
	luzCruz.Range = 24
	luzCruz.Parent = cruzCentro

	-- Letrero 3D Superior Iluminado: HOSPITAL SAN RAFAEL
	local marcoLetrero = Instance.new("Part")
	marcoLetrero.Name = "MarcoLetrero"
	marcoLetrero.Size = Vector3.new(1.2, 2.6, 14)
	marcoLetrero.Position = edificio.Position + Vector3.new(-11.2, 7.8, 0)
	marcoLetrero.Color = Color3.fromRGB(30, 40, 55)
	marcoLetrero.Material = Enum.Material.Metal
	marcoLetrero.Anchored = true
	marcoLetrero.CanCollide = false
	marcoLetrero.Parent = hospitalModel

	local caraLetrero = Instance.new("Part")
	caraLetrero.Name = "CaraLetrero"
	caraLetrero.Size = Vector3.new(0.1, 2.4, 13.6)
	caraLetrero.Position = marcoLetrero.Position + Vector3.new(-0.6, 0, 0)
	caraLetrero.Color = Color3.fromRGB(240, 250, 255)
	caraLetrero.Material = Enum.Material.Neon
	caraLetrero.Anchored = true
	caraLetrero.CanCollide = false
	caraLetrero.Parent = hospitalModel

	local surfGui = Instance.new("SurfaceGui")
	surfGui.Face = Enum.NormalId.Left
	surfGui.CanvasSize = Vector2.new(650, 120)
	surfGui.AlwaysOnTop = false
	surfGui.LightInfluence = 0.05
	surfGui.Parent = caraLetrero

	local txtHosp = Instance.new("TextLabel")
	txtHosp.Size = UDim2.fromScale(1, 0.58)
	txtHosp.Position = UDim2.fromOffset(0, 6)
	txtHosp.BackgroundTransparency = 1
	txtHosp.Font = Enum.Font.FredokaOne
	txtHosp.Text = "🏥 HOSPITAL SAN RAFAEL"
	txtHosp.TextColor3 = Color3.fromRGB(20, 60, 130)
	txtHosp.TextSize = 32
	txtHosp.Parent = surfGui

	local txtUrg = Instance.new("TextLabel")
	txtUrg.Size = UDim2.fromScale(1, 0.42)
	txtUrg.Position = UDim2.fromOffset(0, 66)
	txtUrg.BackgroundTransparency = 1
	txtUrg.Font = Enum.Font.FredokaOne
	txtUrg.Text = "URGENCIAS 24H • PUESTO DE SALUD MUNICIPAL"
	txtUrg.TextColor3 = Color3.fromRGB(220, 40, 40)
	txtUrg.TextSize = 18
	txtUrg.Parent = surfGui

	-- Puerta de vidrio corrediza
	local puertaVidrio = Instance.new("Part")
	puertaVidrio.Name = "PuertaAccesoUrgencias"
	puertaVidrio.Size = Vector3.new(0.4, 6.0, 5.0)
	puertaVidrio.Position = edificio.Position + Vector3.new(-11.1, -2.5, -3)
	puertaVidrio.Color = Color3.fromRGB(160, 210, 245)
	puertaVidrio.Material = Enum.Material.Glass
	puertaVidrio.Transparency = 0.45
	puertaVidrio.Anchored = true
	puertaVidrio.CanCollide = false
	puertaVidrio.Parent = hospitalModel

	-- Interior de la sala de atención (Mostrador, Camilla, Suero, Luz Cálida)
	local mostrador = Instance.new("Part")
	mostrador.Name = "MostradorTriaje"
	mostrador.Size = Vector3.new(3.0, 2.4, 4.0)
	mostrador.Position = edificio.Position + Vector3.new(-6, -4.5, -3)
	mostrador.Color = Color3.fromRGB(235, 240, 245)
	mostrador.Material = Enum.Material.SmoothPlastic
	mostrador.Anchored = true
	mostrador.CanCollide = true
	mostrador.Parent = hospitalModel

	-- Camilla médica con almohada
	local camilla = Instance.new("Part")
	camilla.Name = "CamillaMedica"
	camilla.Size = Vector3.new(5.5, 1.8, 2.6)
	camilla.Position = edificio.Position + Vector3.new(-4, -4.8, 3.5)
	camilla.Color = Color3.fromRGB(60, 160, 120) -- Verde quirúrgico
	camilla.Material = Enum.Material.Fabric
	camilla.Anchored = true
	camilla.CanCollide = true
	camilla.Parent = hospitalModel

	local almohada = Instance.new("Part")
	almohada.Name = "Almohada"
	almohada.Size = Vector3.new(1.2, 0.4, 2.2)
	almohada.Position = camilla.Position + Vector3.new(-2.0, 1.0, 0)
	almohada.Color = Color3.fromRGB(250, 250, 255)
	almohada.Material = Enum.Material.Fabric
	almohada.Anchored = true
	almohada.CanCollide = false
	almohada.Parent = hospitalModel

	-- Poste de suero intravenoso (IV Drip Stand)
	local posteSuero = Instance.new("Part")
	posteSuero.Name = "PosteSuero"
	posteSuero.Size = Vector3.new(0.2, 5.5, 0.2)
	posteSuero.Position = camilla.Position + Vector3.new(-2.2, 2.0, -1.8)
	posteSuero.Color = Color3.fromRGB(200, 205, 215)
	posteSuero.Material = Enum.Material.Metal
	posteSuero.Anchored = true
	posteSuero.CanCollide = false
	posteSuero.Parent = hospitalModel

	local bolsaSuero = Instance.new("Part")
	bolsaSuero.Name = "BolsaSuero"
	bolsaSuero.Size = Vector3.new(0.4, 0.8, 0.4)
	bolsaSuero.Position = posteSuero.Position + Vector3.new(0, 2.2, 0)
	bolsaSuero.Color = Color3.fromRGB(220, 240, 255)
	bolsaSuero.Material = Enum.Material.Glass
	bolsaSuero.Transparency = 0.3
	bolsaSuero.Anchored = true
	bolsaSuero.CanCollide = false
	bolsaSuero.Parent = hospitalModel

	-- Lámpara interior de quirófano / triaje
	local luzClinica = Instance.new("PointLight")
	luzClinica.Name = "LuzInteriorClinica"
	luzClinica.Color = Color3.fromRGB(240, 250, 255)
	luzClinica.Range = 26
	luzClinica.Brightness = 2.2
	luzClinica.Parent = mostrador

	-- =================================================================
	-- 2. AMBULANCIA MUNICIPAL CON SIRENA Y LUCES ESTROBOSCÓPICAS
	-- =================================================================
	local ambulancia = Instance.new("Model")
	ambulancia.Name = "Vehiculo_AmbulanciaSanRafael"
	ambulancia.Parent = hospitalModel

	local posAmb = basePos + Vector3.new(-8, 1.8, 6.5)

	local chasisAmb = Instance.new("Part")
	chasisAmb.Name = "Chasis"
	chasisAmb.Size = Vector3.new(6.0, 3.2, 12.0)
	chasisAmb.Position = posAmb
	chasisAmb.Color = Color3.fromRGB(250, 250, 252)
	chasisAmb.Material = Enum.Material.SmoothPlastic
	chasisAmb.Anchored = true
	chasisAmb.CanCollide = true
	chasisAmb.Parent = ambulancia
	ambulancia.PrimaryPart = chasisAmb

	-- Franja roja de ambulancia
	local franjaRojaAmb = Instance.new("Part")
	franjaRojaAmb.Name = "FranjaAmbulancia"
	franjaRojaAmb.Size = Vector3.new(6.1, 0.8, 12.0)
	franjaRojaAmb.Position = chasisAmb.Position + Vector3.new(0, 0.2, 0)
	franjaRojaAmb.Color = Color3.fromRGB(220, 35, 35)
	franjaRojaAmb.Material = Enum.Material.SmoothPlastic
	franjaRojaAmb.Anchored = true
	franjaRojaAmb.CanCollide = false
	franjaRojaAmb.Parent = ambulancia
	soldar(chasisAmb, franjaRojaAmb)

	-- Sirena estroboscópica doble (Roja y Azul en el techo)
	local sirenaRoja = Instance.new("Part")
	sirenaRoja.Name = "SirenaRoja"
	sirenaRoja.Size = Vector3.new(0.8, 0.6, 1.0)
	sirenaRoja.Position = chasisAmb.Position + Vector3.new(-1.4, 2.0, -1.5)
	sirenaRoja.Color = Color3.fromRGB(255, 30, 30)
	sirenaRoja.Material = Enum.Material.Neon
	sirenaRoja.Anchored = true
	sirenaRoja.CanCollide = false
	sirenaRoja.Parent = ambulancia
	soldar(chasisAmb, sirenaRoja)

	local luzSirenaRoja = Instance.new("PointLight")
	luzSirenaRoja.Color = Color3.fromRGB(255, 30, 30)
	luzSirenaRoja.Brightness = 3.0
	luzSirenaRoja.Range = 22
	luzSirenaRoja.Parent = sirenaRoja

	local sirenaAzul = Instance.new("Part")
	sirenaAzul.Name = "SirenaAzul"
	sirenaAzul.Size = Vector3.new(0.8, 0.6, 1.0)
	sirenaAzul.Position = chasisAmb.Position + Vector3.new(1.4, 2.0, -1.5)
	sirenaAzul.Color = Color3.fromRGB(30, 100, 255)
	sirenaAzul.Material = Enum.Material.Neon
	sirenaAzul.Anchored = true
	sirenaAzul.CanCollide = false
	sirenaAzul.Parent = ambulancia
	soldar(chasisAmb, sirenaAzul)

	local luzSirenaAzul = Instance.new("PointLight")
	luzSirenaAzul.Color = Color3.fromRGB(40, 120, 255)
	luzSirenaAzul.Brightness = 3.0
	luzSirenaAzul.Range = 22
	luzSirenaAzul.Parent = sirenaAzul

	-- Ruedas de la ambulancia
	for _, x in ipairs({ -3.1, 3.1 }) do
		for _, z in ipairs({ -3.8, 3.8 }) do
			local rueda = Instance.new("Part")
			rueda.Name = "RuedaAmbulancia"
			rueda.Shape = Enum.PartType.Cylinder
			rueda.Size = Vector3.new(0.9, 2.2, 2.2)
			rueda.CFrame = CFrame.new(chasisAmb.Position + Vector3.new(x, -0.9, z))
				* CFrame.Angles(0, 0, math.rad(90))
			rueda.Color = Color3.fromRGB(30, 30, 35)
			rueda.Material = Enum.Material.Rubber
			rueda.Anchored = true
			rueda.CanCollide = false
			rueda.Parent = ambulancia
			soldar(chasisAmb, rueda)
		end
	end

	-- Efecto estroboscópico de luces de emergencia
	task.spawn(function()
		local toggle = false
		while ambulancia.Parent do
			toggle = not toggle
			luzSirenaRoja.Enabled = toggle
			luzSirenaAzul.Enabled = not toggle
			sirenaRoja.Color = if toggle
				then Color3.fromRGB(255, 30, 30)
				else Color3.fromRGB(80, 20, 20)
			sirenaAzul.Color = if not toggle
				then Color3.fromRGB(30, 120, 255)
				else Color3.fromRGB(20, 40, 80)
			task.wait(0.35)
		end
	end)

	-- =================================================================
	-- 3. NPC MÉDICA: DRA. ESPERANZA (URGENCIAS SAN RAFAEL)
	-- =================================================================
	local draModelo = Instance.new("Model")
	draModelo.Name = "NPC_DraEsperanza"
	draModelo.Parent = hospitalModel

	local draPos = mostrador.Position + Vector3.new(2.4, 1.4, 0)

	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(1.8, 2.0, 0.9)
	hrp.Position = draPos
	hrp.Transparency = 1
	hrp.CanCollide = false
	hrp.Anchored = true
	hrp.Parent = draModelo
	draModelo.PrimaryPart = hrp

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(1.8, 2.0, 0.9)
	torso.Position = hrp.Position
	torso.Color = Color3.fromRGB(245, 248, 252) -- Bata médica blanca
	torso.Material = Enum.Material.SmoothPlastic
	torso.Anchored = true
	torso.CanCollide = false
	torso.Parent = draModelo
	soldar(hrp, torso)

	-- Estetoscopio en el pecho
	local estetoscopio = Instance.new("Part")
	estetoscopio.Name = "Estetoscopio"
	estetoscopio.Size = Vector3.new(0.9, 0.8, 0.2)
	estetoscopio.Position = torso.Position + Vector3.new(0, 0.2, -0.5)
	estetoscopio.Color = Color3.fromRGB(35, 45, 60)
	estetoscopio.Material = Enum.Material.Metal
	estetoscopio.Anchored = true
	estetoscopio.CanCollide = false
	estetoscopio.Parent = draModelo
	soldar(hrp, estetoscopio)

	local cabeza = Instance.new("Part")
	cabeza.Name = "Head"
	cabeza.Size = Vector3.new(1.1, 1.1, 1.1)
	cabeza.Position = torso.Position + Vector3.new(0, 1.55, 0)
	cabeza.Color = Color3.fromRGB(235, 195, 160)
	cabeza.Material = Enum.Material.SmoothPlastic
	cabeza.Anchored = true
	cabeza.CanCollide = false
	cabeza.Parent = draModelo
	soldar(hrp, cabeza)

	local pelo = Instance.new("Part")
	pelo.Name = "Cabello"
	pelo.Size = Vector3.new(1.25, 0.6, 1.25)
	pelo.Position = cabeza.Position + Vector3.new(0, 0.55, 0.1)
	pelo.Color = Color3.fromRGB(45, 30, 20)
	pelo.Material = Enum.Material.SmoothPlastic
	pelo.Anchored = true
	pelo.CanCollide = false
	pelo.Parent = draModelo
	soldar(hrp, pelo)

	local piernas = Instance.new("Part")
	piernas.Name = "Piernas"
	piernas.Size = Vector3.new(1.6, 1.8, 0.8)
	piernas.Position = torso.Position + Vector3.new(0, -1.8, 0)
	piernas.Color = Color3.fromRGB(50, 110, 180) -- Pantalón médico azul
	piernas.Material = Enum.Material.SmoothPlastic
	piernas.Anchored = true
	piernas.CanCollide = false
	piernas.Parent = draModelo
	soldar(hrp, piernas)

	-- Rótulo 3D
	local bbg = Instance.new("BillboardGui")
	bbg.Name = "RotuloMedica"
	bbg.Size = UDim2.fromOffset(230, 50)
	bbg.StudsOffset = Vector3.new(0, 3.2, 0)
	bbg.AlwaysOnTop = true
	bbg.MaxDistance = 45
	bbg.Parent = cabeza

	local lblMed = Instance.new("TextLabel")
	lblMed.Size = UDim2.fromScale(1, 1)
	lblMed.BackgroundColor3 = Color3.fromRGB(20, 30, 45)
	lblMed.BackgroundTransparency = 0.2
	lblMed.Font = Enum.Font.FredokaOne
	lblMed.Text = "🩺 Dra. Esperanza\n(Urgencias San Rafael)"
	lblMed.TextColor3 = Color3.fromRGB(220, 245, 255)
	lblMed.TextSize = 13
	lblMed.Parent = bbg

	local cornerLbl = Instance.new("UICorner")
	cornerLbl.CornerRadius = UDim.new(0, 8)
	cornerLbl.Parent = lblMed

	local strokeLbl = Instance.new("UIStroke")
	strokeLbl.Color = Color3.fromRGB(50, 180, 120)
	strokeLbl.Thickness = 1.5
	strokeLbl.Parent = lblMed

	-- ProximityPrompt curativo interactivo
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PromptCuracion"
	prompt.ObjectText = "Dra. Esperanza"
	prompt.ActionText = "Consultar / Curarse (Gratis)"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = torso

	prompt.Triggered:Connect(function(player: Player)
		local char = player.Character
		if char then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Health = humanoid.MaxHealth
			end
		end

		-- Sonido sanador
		local chime = Instance.new("Sound")
		chime.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		chime.Volume = 0.75
		chime.Parent = torso
		chime:Play()
		task.delay(1.5, function()
			chime:Destroy()
		end)

		EventosRemotos.MostrarDialogoNPC:FireClient(player, {
			Nombre = "Dra. Esperanza",
			Titulo = "Atención Médica en Urgencias",
			Icono = "🩺",
			Mensaje = "¡Hola querido! Te he curado cualquier golpe de la bicicleta y tu salud está al 100%. "
				.. "Recuerda que la policía dental patrulla la carretera con retenes. "
				.. "¡Si te sientes mareado por el azúcar o te caes, vuelve aquí a Urgencias San Rafael!",
		})
	end)

	hospitalModel.Parent = parent
	return hospitalModel
end

-- ====================================================================
-- 2. PARQUE INFANTIL DE LADERA (COLUMPIOS, TOBOGÁN Y BANCAS)
-- ====================================================================
local function construirParqueLadera(parent: Instance)
	local parque = Instance.new("Model")
	parque.Name = "Parque_InfantilLadera"

	local basePos = Vector3.new(-25, 81.2, 260)

	-- Suelo de arena suave del parque
	local sueloArena = Instance.new("Part")
	sueloArena.Name = "SueloArenaParque"
	sueloArena.Size = Vector3.new(22, 0.4, 20)
	sueloArena.Position = basePos + Vector3.new(0, 0.2, 0)
	sueloArena.Color = Color3.fromRGB(225, 195, 140)
	sueloArena.Material = Enum.Material.Sand
	sueloArena.Anchored = true
	sueloArena.CanCollide = true
	sueloArena.Parent = parque
	parque.PrimaryPart = sueloArena

	-- Valla rústica de madera alrededor
	local valla = Instance.new("Part")
	valla.Name = "BarandaParque"
	valla.Size = Vector3.new(22.4, 1.8, 0.5)
	valla.Position = basePos + Vector3.new(0, 1.0, 9.8)
	valla.Color = Color3.fromRGB(120, 80, 45)
	valla.Material = Enum.Material.WoodPlanks
	valla.Anchored = true
	valla.CanCollide = true
	valla.Parent = parque

	-- Columpios infantiles (Swings)
	local vigaColumpio = Instance.new("Part")
	vigaColumpio.Name = "VigaColumpio"
	vigaColumpio.Size = Vector3.new(9.0, 0.5, 0.5)
	vigaColumpio.Position = basePos + Vector3.new(-4, 6.5, 0)
	vigaColumpio.Color = Color3.fromRGB(220, 60, 50)
	vigaColumpio.Material = Enum.Material.Metal
	vigaColumpio.Anchored = true
	vigaColumpio.CanCollide = false
	vigaColumpio.Parent = parque

	for _, xPoste in ipairs({ -8.5, 0.5 }) do
		local posteA = Instance.new("Part")
		posteA.Name = "PosteA"
		posteA.Size = Vector3.new(0.4, 7.0, 0.4)
		posteA.CFrame = CFrame.new(basePos + Vector3.new(xPoste, 3.5, 0))
			* CFrame.Angles(0, 0, math.rad(10))
		posteA.Color = Color3.fromRGB(40, 120, 210)
		posteA.Material = Enum.Material.Metal
		posteA.Anchored = true
		posteA.CanCollide = true
		posteA.Parent = parque
	end

	-- 2 Asientos de columpio
	for i = 1, 2 do
		local xOff = -6.5 + (i * 2.5)
		local asientoCol = Instance.new("Part")
		asientoCol.Name = "AsientoColumpio_" .. i
		asientoCol.Size = Vector3.new(1.8, 0.2, 0.8)
		asientoCol.Position = basePos + Vector3.new(xOff, 1.4, 0)
		asientoCol.Color = Color3.fromRGB(240, 200, 40)
		asientoCol.Material = Enum.Material.WoodPlanks
		asientoCol.Anchored = true
		asientoCol.CanCollide = true
		asientoCol.Parent = parque

		-- Cadenas
		for _, xCadena in ipairs({ -0.8, 0.8 }) do
			local cadena = Instance.new("Part")
			cadena.Name = "Cadena"
			cadena.Size = Vector3.new(0.1, 5.0, 0.1)
			cadena.Position = asientoCol.Position + Vector3.new(xCadena, 2.5, 0)
			cadena.Color = Color3.fromRGB(160, 165, 175)
			cadena.Material = Enum.Material.Metal
			cadena.Anchored = true
			cadena.CanCollide = false
			cadena.Parent = parque
		end
	end

	-- Tobogán infantil colorido (Slide)
	local tobogan = Instance.new("Part")
	tobogan.Name = "RampaTobogan"
	tobogan.Size = Vector3.new(2.4, 0.4, 8.0)
	tobogan.CFrame = CFrame.new(basePos + Vector3.new(6.5, 2.8, -1.0))
		* CFrame.Angles(math.rad(-30), 0, 0)
	tobogan.Color = Color3.fromRGB(60, 190, 80)
	tobogan.Material = Enum.Material.SmoothPlastic
	tobogan.Anchored = true
	tobogan.CanCollide = true
	tobogan.Parent = parque

	-- Farol del parque
	local farol = Instance.new("Part")
	farol.Name = "FarolParque"
	farol.Size = Vector3.new(0.5, 7.0, 0.5)
	farol.Position = basePos + Vector3.new(8, 3.5, 7)
	farol.Color = Color3.fromRGB(45, 50, 60)
	farol.Material = Enum.Material.Metal
	farol.Anchored = true
	farol.CanCollide = true
	farol.Parent = parque

	local foco = Instance.new("Part")
	foco.Name = "Foco"
	foco.Size = Vector3.new(1.0, 1.0, 1.0)
	foco.Position = farol.Position + Vector3.new(0, 3.5, 0)
	foco.Color = Color3.fromRGB(255, 235, 160)
	foco.Material = Enum.Material.Neon
	foco.Anchored = true
	foco.CanCollide = false
	foco.Parent = parque

	local luzFarol = Instance.new("PointLight")
	luzFarol.Color = Color3.fromRGB(255, 220, 140)
	luzFarol.Range = 26
	luzFarol.Brightness = 2.0
	luzFarol.Parent = foco

	parque.Parent = parent
	return parque
end

-- ====================================================================
-- 3. MIRADOR DEL CAFÉ CAMPESINO "LOS ALMENDROS" (ALTO DE LA MONTAÑA)
-- ====================================================================
local function construirMiradorCampesino(parent: Instance)
	local mirador = Instance.new("Model")
	mirador.Name = "Mirador_CafeCampesino"

	local basePos = Vector3.new(25, 95.5, 380)

	-- Terraza de madera rústica voladiza con vista al valle
	local deck = Instance.new("Part")
	deck.Name = "DeckMadera"
	deck.Size = Vector3.new(20, 0.6, 20)
	deck.Position = basePos + Vector3.new(0, 0.3, 0)
	deck.Color = Color3.fromRGB(125, 75, 42)
	deck.Material = Enum.Material.WoodPlanks
	deck.Anchored = true
	deck.CanCollide = true
	deck.Parent = mirador
	mirador.PrimaryPart = deck

	-- Baranda panorámica
	local barandaFrontal = Instance.new("Part")
	barandaFrontal.Name = "BarandaPanoramica"
	barandaFrontal.Size = Vector3.new(20, 2.2, 0.4)
	barandaFrontal.Position = deck.Position + Vector3.new(0, 1.2, 9.8)
	barandaFrontal.Color = Color3.fromRGB(100, 60, 35)
	barandaFrontal.Material = Enum.Material.WoodPlanks
	barandaFrontal.Anchored = true
	barandaFrontal.CanCollide = true
	barandaFrontal.Parent = mirador

	-- Kiosko cafetero con techo de teja
	local kiosko = Instance.new("Part")
	kiosko.Name = "KioskoCafe"
	kiosko.Size = Vector3.new(8.0, 3.2, 6.0)
	kiosko.Position = deck.Position + Vector3.new(-4.5, 1.8, -5.5)
	kiosko.Color = Color3.fromRGB(150, 95, 55)
	kiosko.Material = Enum.Material.WoodPlanks
	kiosko.Anchored = true
	kiosko.CanCollide = true
	kiosko.Parent = mirador

	local techoKiosko = Instance.new("Part")
	techoKiosko.Name = "TechoTejaKiosko"
	techoKiosko.Size = Vector3.new(9.5, 1.2, 7.5)
	techoKiosko.Position = kiosko.Position + Vector3.new(0, 2.2, 0)
	techoKiosko.Color = Color3.fromRGB(190, 75, 45) -- Arcilla colonial
	techoKiosko.Material = Enum.Material.CorrodedMetal
	techoKiosko.Anchored = true
	techoKiosko.CanCollide = false
	techoKiosko.Parent = mirador

	-- Rótulo del Mirador
	local bbg = Instance.new("BillboardGui")
	bbg.Name = "RotuloCafe"
	bbg.Size = UDim2.fromOffset(260, 48)
	bbg.StudsOffset = Vector3.new(0, 2.8, 0)
	bbg.AlwaysOnTop = true
	bbg.MaxDistance = 50
	bbg.Parent = techoKiosko

	local lblCafe = Instance.new("TextLabel")
	lblCafe.Size = UDim2.fromScale(1, 1)
	lblCafe.BackgroundColor3 = Color3.fromRGB(35, 24, 18)
	lblCafe.BackgroundTransparency = 0.15
	lblCafe.Font = Enum.Font.FredokaOne
	lblCafe.Text = "☕ CAFÉ LOS ALMENDROS\nMirador del Valle • Altura 2.200m"
	lblCafe.TextColor3 = Color3.fromRGB(255, 220, 140)
	lblCafe.TextSize = 13
	lblCafe.Parent = bbg

	local cornerCafe = Instance.new("UICorner")
	cornerCafe.CornerRadius = UDim.new(0, 8)
	cornerCafe.Parent = lblCafe

	-- Bultos de café de exportación
	for i = 1, 3 do
		local bulto = Instance.new("Part")
		bulto.Name = "BultoCafeGrano"
		bulto.Size = Vector3.new(2.0, 1.3, 1.6)
		bulto.Position = kiosko.Position + Vector3.new(4.5 + (i * 0.8), -0.8, -1.0)
		bulto.Color = Color3.fromRGB(165, 140, 105)
		bulto.Material = Enum.Material.Fabric
		bulto.Anchored = true
		bulto.CanCollide = true
		bulto.Parent = mirador
	end

	-- NPC Campesino Cafetero: Don Celso
	local celso = Instance.new("Model")
	celso.Name = "NPC_DonCelso"
	celso.Parent = mirador

	local celsoHrp = Instance.new("Part")
	celsoHrp.Name = "HumanoidRootPart"
	celsoHrp.Size = Vector3.new(1.8, 2.0, 0.9)
	celsoHrp.Position = deck.Position + Vector3.new(-1.0, 2.7, -2.5)
	celsoHrp.Transparency = 1
	celsoHrp.CanCollide = false
	celsoHrp.Anchored = true
	celsoHrp.Parent = celso
	celso.PrimaryPart = celsoHrp

	local celsoTorso = Instance.new("Part")
	celsoTorso.Name = "Torso"
	celsoTorso.Size = Vector3.new(1.8, 2.0, 0.9)
	celsoTorso.Position = celsoHrp.Position
	celsoTorso.Color = Color3.fromRGB(235, 230, 215) -- Ruana campesina clara
	celsoTorso.Material = Enum.Material.Fabric
	celsoTorso.Anchored = true
	celsoTorso.CanCollide = false
	celsoTorso.Parent = celso
	soldar(celsoHrp, celsoTorso)

	local celsoHead = Instance.new("Part")
	celsoHead.Name = "Head"
	celsoHead.Size = Vector3.new(1.1, 1.1, 1.1)
	celsoHead.Position = celsoTorso.Position + Vector3.new(0, 1.55, 0)
	celsoHead.Color = Color3.fromRGB(225, 180, 145)
	celsoHead.Material = Enum.Material.SmoothPlastic
	celsoHead.Anchored = true
	celsoHead.CanCollide = false
	celsoHead.Parent = celso
	soldar(celsoHrp, celsoHead)

	local sombrero = Instance.new("Part")
	sombrero.Name = "SombreroAguadeno"
	sombrero.Size = Vector3.new(2.4, 0.4, 2.4)
	sombrero.Position = celsoHead.Position + Vector3.new(0, 0.65, 0)
	sombrero.Color = Color3.fromRGB(245, 240, 220)
	sombrero.Material = Enum.Material.SmoothPlastic
	sombrero.Anchored = true
	sombrero.CanCollide = false
	sombrero.Parent = celso
	soldar(celsoHrp, sombrero)

	local celsoPrompt = Instance.new("ProximityPrompt")
	celsoPrompt.Name = "PromptCafe"
	celsoPrompt.ObjectText = "Don Celso"
	celsoPrompt.ActionText = "Charlar con el Cafetero"
	celsoPrompt.HoldDuration = 0.2
	celsoPrompt.MaxActivationDistance = 10
	celsoPrompt.RequiresLineOfSight = false
	celsoPrompt.Parent = celsoTorso

	celsoPrompt.Triggered:Connect(function(player: Player)
		EventosRemotos.MostrarDialogoNPC:FireClient(player, {
			Nombre = "Don Celso",
			Titulo = "Café de Origen Los Almendros",
			Icono = "☕",
			Mensaje = "¡Buenas tardes mi chino! Mire qué hermosura de vista hacia Villa Almíbar y el colegio abajo. "
				.. "Subir en bicicleta hasta acá no es jugando, ¡te felicito por semejante esfuerzo! "
				.. "El café caliente y las panelitas de Doña Melcocha son el mejor combustible de los campesinos.",
		})
	end)

	mirador.Parent = parent
	return mirador
end

-- ====================================================================
-- 4. POTRERO RURAL CON FAUNA (VACA JOSEFINA EN EL PASTIZAL)
-- ====================================================================
local function construirPotreroRural(parent: Instance)
	local potrero = Instance.new("Model")
	potrero.Name = "Potrero_FaunaRural"

	local basePos = Vector3.new(-35, 77.0, 320)

	-- Cerca de madera de estacas
	for i = 0, 4 do
		local estaca = Instance.new("Part")
		estaca.Name = "EstacaCerca"
		estaca.Size = Vector3.new(0.4, 3.2, 0.4)
		estaca.Position = basePos + Vector3.new(-10 + (i * 5), 1.6, 0)
		estaca.Color = Color3.fromRGB(110, 70, 40)
		estaca.Material = Enum.Material.Wood
		estaca.Anchored = true
		estaca.CanCollide = true
		estaca.Parent = potrero
	end

	local alambre = Instance.new("Part")
	alambre.Name = "AlambreCerca"
	alambre.Size = Vector3.new(20, 0.1, 0.1)
	alambre.Position = basePos + Vector3.new(0, 2.2, 0)
	alambre.Color = Color3.fromRGB(140, 145, 150)
	alambre.Material = Enum.Material.Metal
	alambre.Anchored = true
	alambre.CanCollide = false
	alambre.Parent = potrero

	-- Modelo de la Vaca Josefina
	local vaca = Instance.new("Model")
	vaca.Name = "Animal_VacaJosefina"
	vaca.Parent = potrero

	local vacaPos = basePos + Vector3.new(0, 1.8, -6)

	local cuerpoVaca = Instance.new("Part")
	cuerpoVaca.Name = "HumanoidRootPart"
	cuerpoVaca.Size = Vector3.new(2.8, 2.6, 5.0)
	cuerpoVaca.Position = vacaPos
	cuerpoVaca.Color = Color3.fromRGB(245, 245, 245) -- Vaca blanquinegra
	cuerpoVaca.Material = Enum.Material.SmoothPlastic
	cuerpoVaca.Anchored = true
	cuerpoVaca.CanCollide = false
	cuerpoVaca.Parent = vaca
	vaca.PrimaryPart = cuerpoVaca

	-- Manchas negras
	local mancha = Instance.new("Part")
	mancha.Name = "ManchaNegra"
	mancha.Size = Vector3.new(2.85, 1.8, 2.2)
	mancha.Position = cuerpoVaca.Position + Vector3.new(0, 0.3, -0.6)
	mancha.Color = Color3.fromRGB(30, 30, 35)
	mancha.Material = Enum.Material.SmoothPlastic
	mancha.Anchored = true
	mancha.CanCollide = false
	mancha.Parent = vaca
	soldar(cuerpoVaca, mancha)

	local cabezaVaca = Instance.new("Part")
	cabezaVaca.Name = "Head"
	cabezaVaca.Size = Vector3.new(1.6, 1.6, 2.0)
	cabezaVaca.Position = cuerpoVaca.Position + Vector3.new(0, 1.2, -3.2)
	cabezaVaca.Color = Color3.fromRGB(240, 240, 240)
	cabezaVaca.Material = Enum.Material.SmoothPlastic
	cabezaVaca.Anchored = true
	cabezaVaca.CanCollide = false
	cabezaVaca.Parent = vaca
	soldar(cuerpoVaca, cabezaVaca)

	-- Cuernos
	for _, xC in ipairs({ -0.9, 0.9 }) do
		local cuerno = Instance.new("Part")
		cuerno.Name = "Cuerno"
		cuerno.Size = Vector3.new(0.3, 0.8, 0.3)
		cuerno.Position = cabezaVaca.Position + Vector3.new(xC, 1.0, 0.2)
		cuerno.Color = Color3.fromRGB(220, 205, 175)
		cuerno.Material = Enum.Material.SmoothPlastic
		cuerno.Anchored = true
		cuerno.CanCollide = false
		cuerno.Parent = vaca
		soldar(cuerpoVaca, cuerno)
	end

	-- Rótulo amigable
	local bbgVaca = Instance.new("BillboardGui")
	bbgVaca.Name = "RotuloVaca"
	bbgVaca.Size = UDim2.fromOffset(180, 38)
	bbgVaca.StudsOffset = Vector3.new(0, 2.5, 0)
	bbgVaca.AlwaysOnTop = false
	bbgVaca.MaxDistance = 35
	bbgVaca.Parent = cabezaVaca

	local lblVaca = Instance.new("TextLabel")
	lblVaca.Size = UDim2.fromScale(1, 1)
	lblVaca.BackgroundTransparency = 1
	lblVaca.Font = Enum.Font.FredokaOne
	lblVaca.Text = "🐄 Josefina (Vaca Lechera)"
	lblVaca.TextColor3 = Color3.fromRGB(255, 235, 180)
	lblVaca.TextSize = 12
	lblVaca.Parent = bbgVaca

	local promptVaca = Instance.new("ProximityPrompt")
	promptVaca.Name = "PromptMugir"
	promptVaca.ObjectText = "Josefina"
	promptVaca.ActionText = "Acariciar la vaca"
	promptVaca.HoldDuration = 0.2
	promptVaca.MaxActivationDistance = 10
	promptVaca.RequiresLineOfSight = false
	promptVaca.Parent = cuerpoVaca

	promptVaca.Triggered:Connect(function(player: Player)
		EventosRemotos.MostrarDialogoNPC:FireClient(player, {
			Nombre = "Vaca Josefina",
			Titulo = "Fauna Campesina",
			Icono = "🐄",
			Mensaje = "¡Muuuuuu! *Mastica plácidamente el pasto verde de la ladera y te mira con ojos tranquilos.*",
		})
	end)

	-- Animación sutil de pastoreo
	task.spawn(function()
		while vaca.Parent do
			task.wait(math.random(3, 6))
			-- Agachar la cabeza a pastar
			cabezaVaca.CFrame = cuerpoVaca.CFrame
				* CFrame.new(0, 0.4, -3.4)
				* CFrame.Angles(math.rad(25), 0, 0)
			task.wait(1.5)
			cabezaVaca.CFrame = cuerpoVaca.CFrame * CFrame.new(0, 1.2, -3.2)
		end
	end)

	potrero.Parent = parent
	return potrero
end

-- ====================================================================
-- INICIALIZADOR GENERAL
-- ====================================================================
local function inicializarHospitalYExpansiones()
	local mapa = Workspace:WaitForChild("Mapa", 10)
	if not mapa then
		return
	end
	local decoracion = mapa:WaitForChild("Decoracion", 10)
	if not decoracion then
		decoracion = Instance.new("Folder")
		decoracion.Name = "Decoracion"
		decoracion.Parent = mapa
	end

	local carpetaHospital = crearCarpeta(decoracion, "ComplejoHospitalario")
	construirHospitalSanRafael(carpetaHospital)
	construirParqueLadera(carpetaHospital)
	construirMiradorCampesino(carpetaHospital)
	construirPotreroRural(carpetaHospital)

	print(
		"El Patrón del Dulce: Hospital San Rafael, Urgencias 24H, Parque, Mirador y Fauna Inicializados con Éxito"
	)
end

task.spawn(inicializarHospitalYExpansiones)
