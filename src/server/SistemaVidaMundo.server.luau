local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GestorDatos = require(script.Parent.GestorDatos)
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)

-- ====================================================================
-- CREACIÓN DE ESTUDIANTES VIVOS EN EL PATIO DEL COLEGIO
-- ====================================================================
local function crearEstudianteVivo(
	info: {
		Nombre: string,
		Apodo: string,
		Posicion: Vector3,
		ColorRopa: Color3,
		ColorPantalon: Color3,
		PuntosMovimiento: { Vector3 }?,
		Frases: { string },
	},
	parentFolder: Instance
)
	local modelo = Instance.new("Model")
	modelo.Name = info.Nombre
	modelo.Parent = parentFolder

	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(1.6, 1.8, 0.8)
	hrp.Position = info.Posicion
	hrp.Transparency = 1
	hrp.CanCollide = false
	hrp.Anchored = true
	hrp.Parent = modelo
	modelo.PrimaryPart = hrp

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(1.6, 1.8, 0.8)
	torso.Position = hrp.Position
	torso.Color = info.ColorRopa
	torso.Material = Enum.Material.SmoothPlastic
	torso.Anchored = true
	torso.CanCollide = true
	torso.Parent = modelo

	local cabeza = Instance.new("Part")
	cabeza.Name = "Head"
	cabeza.Size = Vector3.new(1, 1, 1)
	cabeza.Position = torso.Position + Vector3.new(0, 1.4, 0)
	cabeza.Color = Color3.fromRGB(240, 205, 175)
	cabeza.Material = Enum.Material.SmoothPlastic
	cabeza.Anchored = true
	cabeza.CanCollide = false
	cabeza.Parent = modelo

	local piernas = Instance.new("Part")
	piernas.Name = "Piernas"
	piernas.Size = Vector3.new(1.4, 1.6, 0.7)
	piernas.Position = torso.Position + Vector3.new(0, -1.7, 0)
	piernas.Color = info.ColorPantalon
	piernas.Material = Enum.Material.SmoothPlastic
	piernas.Anchored = true
	piernas.CanCollide = true
	piernas.Parent = modelo

	-- Mochila escolar colorida
	local mochila = Instance.new("Part")
	mochila.Name = "Mochila"
	mochila.Size = Vector3.new(1.2, 1.3, 0.5)
	mochila.Position = torso.Position + Vector3.new(0, 0, 0.55)
	mochila.Color = Color3.fromRGB(240, 100, 50)
	mochila.Material = Enum.Material.SmoothPlastic
	mochila.Anchored = true
	mochila.CanCollide = false
	mochila.Parent = modelo

	-- Burbuja de Diálogo animada (Speech Bubble)
	local bbg = Instance.new("BillboardGui")
	bbg.Name = "BurbujaDialogo"
	bbg.Size = UDim2.fromOffset(200, 48)
	bbg.StudsOffset = Vector3.new(0, 2.8, 0)
	bbg.AlwaysOnTop = false
	bbg.MaxDistance = 40
	bbg.Parent = cabeza

	local fondoBurbuja = Instance.new("Frame")
	fondoBurbuja.Size = UDim2.fromScale(1, 1)
	fondoBurbuja.BackgroundColor3 = Color3.fromRGB(25, 30, 42)
	fondoBurbuja.BackgroundTransparency = 0.15
	fondoBurbuja.Parent = bbg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = fondoBurbuja

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 160, 255)
	stroke.Thickness = 1.5
	stroke.Parent = fondoBurbuja

	local textoBurbuja = Instance.new("TextLabel")
	textoBurbuja.Name = "Texto"
	textoBurbuja.Size = UDim2.new(1, -12, 1, 0)
	textoBurbuja.Position = UDim2.fromOffset(6, 0)
	textoBurbuja.BackgroundTransparency = 1
	textoBurbuja.Font = Enum.Font.FredokaOne
	textoBurbuja.Text = info.Frases[1] or "¡Quiero dulces!"
	textoBurbuja.TextColor3 = Color3.fromRGB(255, 245, 200)
	textoBurbuja.TextSize = 11
	textoBurbuja.TextWrapped = true
	textoBurbuja.Parent = fondoBurbuja

	-- ProximityPrompt para comprar dulce
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PromptComprar"
	prompt.ObjectText = info.Apodo
	prompt.ActionText = "Vender Bombón ($10)"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = torso

	prompt.Triggered:Connect(function(player: Player)
		local datos = GestorDatos.ObtenerDatos(player)
		if not datos then
			return
		end
		local bombones = datos.Inventario["Dulce_Bombon"] or 0
		if bombones > 0 then
			if GestorDatos.QuitarDulce(player, "Dulce_Bombon", 1) then
				GestorDatos.AgregarPesos(player, 10)
				datos.Fama += 1

				local sonido = Instance.new("Sound")
				sonido.SoundId = "rbxasset://sounds/electronicpingshort.wav"
				sonido.Volume = 0.8
				sonido.Parent = torso
				sonido:Play()
				task.delay(1.5, function()
					sonido:Destroy()
				end)

				EventosRemotos.MostrarDialogoNPC:FireClient(player, {
					Nombre = info.Apodo,
					Titulo = "¡Gracias por el dulce!",
					Icono = "😋",
					Mensaje = "¡Qué delicia! Toma tus $10 pesos. ¡Ojo que no te vea el Coordinador Tiza!",
				})
			end
		else
			EventosRemotos.MostrarDialogoNPC:FireClient(player, {
				Nombre = info.Apodo,
				Titulo = "Buscando dulce",
				Icono = "🎒",
				Mensaje = "¡Hola! ¿Tienes bombones de Doña Melcocha? ¡Carga tu mochila en la cocina y tráeme uno!",
			})
		end
	end)

	-- Hilo de rotación de frases y movimiento ligero
	task.spawn(function()
		local idxFrase = 1
		local puntos = info.PuntosMovimiento
		local idxPunto = 1

		while modelo.Parent do
			task.wait(6.0)
			-- Rotar frase
			idxFrase = (idxFrase % #info.Frases) + 1
			textoBurbuja.Text = info.Frases[idxFrase]

			-- Movimiento si tiene puntos de patrulla
			if puntos and #puntos > 1 then
				idxPunto = (idxPunto % #puntos) + 1
				local meta = puntos[idxPunto]
				local dir = (meta - hrp.Position) * Vector3.new(1, 0, 1)
				if dir.Magnitude > 1.5 then
					local nuevoCFrame = CFrame.lookAt(meta, meta + dir.Unit)
					TweenService:Create(
						hrp,
						TweenInfo.new(3, Enum.EasingStyle.Linear),
						{ CFrame = nuevoCFrame }
					):Play()
					modelo:PivotTo(nuevoCFrame)
				end
			end
		end
	end)

	return modelo
end

-- ====================================================================
-- CREACIÓN DE VECINOS Y PEATONES EN LAS ACERAS DEL BARRIO
-- ====================================================================
local function crearVecinoBarrio(
	info: {
		Nombre: string,
		Apodo: string,
		Posicion: Vector3,
		ColorRopa: Color3,
		ColorPantalon: Color3,
		Frases: { string },
		Icono: string,
	},
	parentFolder: Instance
)
	local modelo = Instance.new("Model")
	modelo.Name = info.Nombre
	modelo.Parent = parentFolder

	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(1.8, 2, 0.9)
	hrp.Position = info.Posicion
	hrp.Transparency = 1
	hrp.CanCollide = false
	hrp.Anchored = true
	hrp.Parent = modelo
	modelo.PrimaryPart = hrp

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(1.8, 2, 0.9)
	torso.Position = hrp.Position
	torso.Color = info.ColorRopa
	torso.Material = Enum.Material.SmoothPlastic
	torso.Anchored = true
	torso.CanCollide = true
	torso.Parent = modelo

	local cabeza = Instance.new("Part")
	cabeza.Name = "Head"
	cabeza.Size = Vector3.new(1.1, 1.1, 1.1)
	cabeza.Position = torso.Position + Vector3.new(0, 1.55, 0)
	cabeza.Color = Color3.fromRGB(235, 195, 160)
	cabeza.Material = Enum.Material.SmoothPlastic
	cabeza.Anchored = true
	cabeza.CanCollide = false
	cabeza.Parent = modelo

	local piernas = Instance.new("Part")
	piernas.Name = "Piernas"
	piernas.Size = Vector3.new(1.6, 1.8, 0.8)
	piernas.Position = torso.Position + Vector3.new(0, -1.9, 0)
	piernas.Color = info.ColorPantalon
	piernas.Material = Enum.Material.SmoothPlastic
	piernas.Anchored = true
	piernas.CanCollide = true
	piernas.Parent = modelo

	-- Burbuja de Banter de barrio
	local bbg = Instance.new("BillboardGui")
	bbg.Name = "BurbujaVecino"
	bbg.Size = UDim2.fromOffset(220, 52)
	bbg.StudsOffset = Vector3.new(0, 3.2, 0)
	bbg.AlwaysOnTop = false
	bbg.MaxDistance = 45
	bbg.Parent = cabeza

	local fondoBurbuja = Instance.new("Frame")
	fondoBurbuja.Size = UDim2.fromScale(1, 1)
	fondoBurbuja.BackgroundColor3 = Color3.fromRGB(30, 24, 20)
	fondoBurbuja.BackgroundTransparency = 0.15
	fondoBurbuja.Parent = bbg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = fondoBurbuja

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(240, 160, 60)
	stroke.Thickness = 1.5
	stroke.Parent = fondoBurbuja

	local textoBurbuja = Instance.new("TextLabel")
	textoBurbuja.Name = "Texto"
	textoBurbuja.Size = UDim2.new(1, -12, 1, 0)
	textoBurbuja.Position = UDim2.fromOffset(6, 0)
	textoBurbuja.BackgroundTransparency = 1
	textoBurbuja.Font = Enum.Font.FredokaOne
	textoBurbuja.Text = info.Frases[1] or "¡Buenos días patrón!"
	textoBurbuja.TextColor3 = Color3.fromRGB(255, 230, 180)
	textoBurbuja.TextSize = 11
	textoBurbuja.TextWrapped = true
	textoBurbuja.Parent = fondoBurbuja

	-- ProximityPrompt de charla amigable
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PromptVecino"
	prompt.ObjectText = info.Apodo
	prompt.ActionText = "Saludar / Charlar"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = torso

	prompt.Triggered:Connect(function(player: Player)
		local fraseElegida = info.Frases[math.random(1, #info.Frases)]
		EventosRemotos.MostrarDialogoNPC:FireClient(player, {
			Nombre = info.Apodo,
			Titulo = "Vecino de Villa Almíbar",
			Icono = info.Icono,
			Mensaje = fraseElegida,
		})
	end)

	task.spawn(function()
		local idx = 1
		while modelo.Parent do
			task.wait(7.5)
			idx = (idx % #info.Frases) + 1
			textoBurbuja.Text = info.Frases[idx]
		end
	end)

	return modelo
end

-- ====================================================================
-- DECORACIÓN AMBIENTAL COLOMBIANA: BANDERINES Y FAROLES LUMINOSOS
-- ====================================================================
local function decorarAmbienteBarrio(parentFolder: Instance)
	local puntosFaroles = {
		Vector3.new(-70, 68, -40),
		Vector3.new(-30, 68, 20),
		Vector3.new(20, 68, 60),
		Vector3.new(80, 68, 100),
		Vector3.new(-20, 78, 220),
		Vector3.new(15, 85, 280),
		Vector3.new(-35, 95, 340),
		Vector3.new(10, 105, 420),
	}

	local carpetaLuces = Instance.new("Folder")
	carpetaLuces.Name = "AlumbradoPublico"
	carpetaLuces.Parent = parentFolder

	for i, pos in ipairs(puntosFaroles) do
		local poste = Instance.new("Part")
		poste.Name = "PosteLuz_" .. i
		poste.Size = Vector3.new(0.6, 9, 0.6)
		poste.Position = pos + Vector3.new(0, 4.5, 0)
		poste.Color = Color3.fromRGB(45, 50, 60)
		poste.Material = Enum.Material.Metal
		poste.Anchored = true
		poste.CanCollide = false
		poste.Parent = carpetaLuces

		local foco = Instance.new("Part")
		foco.Name = "Foco"
		foco.Size = Vector3.new(1.2, 0.6, 1.2)
		foco.Position = poste.Position + Vector3.new(0, 4.2, 0)
		foco.Color = Color3.fromRGB(255, 230, 150)
		foco.Material = Enum.Material.Neon
		foco.Anchored = true
		foco.CanCollide = false
		foco.Parent = poste

		local luz = Instance.new("PointLight")
		luz.Name = "LuzCalida"
		luz.Color = Color3.fromRGB(255, 215, 120)
		luz.Brightness = 2.2
		luz.Range = 32
		luz.Shadows = true
		luz.Parent = foco
	end

	-- Banderines festivos en el cruce comercial (bunting flags)
	local carpetaBanderines = Instance.new("Folder")
	carpetaBanderines.Name = "GuirnaldasFiesta"
	carpetaBanderines.Parent = parentFolder

	local coloresBandera = {
		Color3.fromRGB(255, 215, 0), -- Amarillo
		Color3.fromRGB(40, 90, 220), -- Azul
		Color3.fromRGB(230, 40, 40), -- Rojo
		Color3.fromRGB(80, 200, 100), -- Verde
		Color3.fromRGB(240, 100, 180), -- Rosa dulce
	}

	local origenBanderas = Vector3.new(45, 74, 75)
	for b = 1, 10 do
		local banderin = Instance.new("Part")
		banderin.Name = "Banderin_" .. b
		banderin.Size = Vector3.new(0.8, 1.2, 0.1)
		banderin.Position = origenBanderas + Vector3.new(b * 1.6, math.sin(b * 0.5) * 0.4, 0)
		banderin.Color = coloresBandera[(b % #coloresBandera) + 1]
		banderin.Material = Enum.Material.SmoothPlastic
		banderin.Anchored = true
		banderin.CanCollide = false
		banderin.Parent = carpetaBanderines
	end
end

-- ====================================================================
-- INICIALIZADOR GENERAL DE VIDA DEL MUNDO
-- ====================================================================
local function inicializarVidaMundo()
	local mapa = Workspace:WaitForChild("Mapa", 10)
	if not mapa then
		return
	end
	local decoracion = mapa:WaitForChild("Decoracion", 10)
	if not decoracion then
		return
	end

	local carpetaVida = decoracion:FindFirstChild("VidaMundo")
	if carpetaVida then
		carpetaVida:Destroy()
	end
	carpetaVida = Instance.new("Folder")
	carpetaVida.Name = "VidaMundo"
	carpetaVida.Parent = decoracion

	-- 1. Estudiantes en el patio del colegio
	local listaEstudiantesPatio = {
		{
			Nombre = "Estudiante_Mateo",
			Apodo = "Mateo (El Pelota)",
			Posicion = Vector3.new(-82, 61.5, -78),
			ColorRopa = Color3.fromRGB(45, 110, 210),
			ColorPantalon = Color3.fromRGB(30, 35, 50),
			PuntosMovimiento = {
				Vector3.new(-82, 61.5, -78),
				Vector3.new(-74, 61.5, -88),
				Vector3.new(-88, 61.5, -84),
			},
			Frases = {
				"¡Pásala, pásala que no hay portero!",
				"¡Un bombón me da energía para meter un gol!",
				"¡Ojo con el silbato de Tiza!",
			},
		},
		{
			Nombre = "Estudiante_Valentina",
			Apodo = "Valentina (Rayuela)",
			Posicion = Vector3.new(-100, 61.5, -85),
			ColorRopa = Color3.fromRGB(230, 75, 120),
			ColorPantalon = Color3.fromRGB(40, 30, 45),
			PuntosMovimiento = {
				Vector3.new(-100, 61.5, -85),
				Vector3.new(-106, 61.5, -92),
				Vector3.new(-96, 61.5, -95),
			},
			Frases = {
				"¡Saltar rayuela da mucha hambre!",
				"¡Doña Melcocha cocina los mejores dulces del mundo!",
				"¡Quiero una gomita ácida de mora!",
			},
		},
		{
			Nombre = "Estudiante_Camilo",
			Apodo = "Camilo (El Piloto)",
			Posicion = Vector3.new(-72, 61.5, -105),
			ColorRopa = Color3.fromRGB(50, 170, 90),
			ColorPantalon = Color3.fromRGB(35, 45, 38),
			Frases = {
				"¡Cuando sea grande voy a tener una chiva de dulces!",
				"¡El Alcalde Apio odia las cosas ricas!",
				"¡Véndeme un bombón antes de que toquen la campana!",
			},
		},
		{
			Nombre = "Estudiante_Mariana",
			Apodo = "Mariana (Cuaderno)",
			Posicion = Vector3.new(-115, 61.5, -112),
			ColorRopa = Color3.fromRGB(240, 160, 40),
			ColorPantalon = Color3.fromRGB(45, 35, 30),
			Frases = {
				"¡Estudiar matemáticas sin azúcar da mucho sueño!",
				"¡Guardé mis $10 pesos del recreo para un bombón!",
				"¡El portón del colegio tiene candado, qué encierro!",
			},
		},
	}

	for _, est in ipairs(listaEstudiantesPatio) do
		crearEstudianteVivo(est, carpetaVida)
	end

	-- 2. Vecinos en las aceras del barrio
	local listaVecinosBarrio = {
		{
			Nombre = "Vecino_DonPacho",
			Apodo = "Don Pacho (El del Tinto)",
			Posicion = Vector3.new(48, 65, 75),
			ColorRopa = Color3.fromRGB(220, 215, 200),
			ColorPantalon = Color3.fromRGB(70, 50, 35),
			Icono = "☕",
			Frases = {
				"¡En mis tiempos el azúcar no era pecado ni delito!",
				"¡Qué viva el dulce de Doña Melcocha!",
				"¡Ojo con los retenes de la policía dental, andan alborotados!",
			},
		},
		{
			Nombre = "Vecina_DonaLuz",
			Apodo = "Doña Luz (La Chismosa)",
			Posicion = Vector3.new(-75, 65, 60),
			ColorRopa = Color3.fromRGB(240, 120, 160),
			ColorPantalon = Color3.fromRGB(50, 40, 55),
			Icono = "👀",
			Frases = {
				"¡Ave María Purísima! Vi pasar una patrulla dental a toda mecha.",
				"¡Caminen con cuidado que el Alcalde Apio mandó inspectores!",
				"¡Si esconden la carga en los callejones la policía no los ve!",
			},
		},
		{
			Nombre = "Vecino_DonRogelio",
			Apodo = "Don Rogelio (Chófer de Chiva)",
			Posicion = Vector3.new(18, 68, 140),
			ColorRopa = Color3.fromRGB(55, 95, 160),
			ColorPantalon = Color3.fromRGB(30, 35, 45),
			Icono = "🚌",
			Frases = {
				"¡Mi chiva corre más rápido que cualquier patrulla dental!",
				"¡Llévele melcochas a la gente de la montaña alta!",
				"¡La carretera de ladera es brava pero paga bien!",
			},
		},
	}

	for _, vec in ipairs(listaVecinosBarrio) do
		crearVecinoBarrio(vec, carpetaVida)
	end

	-- 3. Faroles, banderines y alumbrado
	decorarAmbienteBarrio(carpetaVida)

	print(
		"El Patrón del Dulce: Sistema de Vida del Mundo (Estudiantes, Vecinos y Banderines) Inicializado"
	)
end

task.spawn(inicializarVidaMundo)
