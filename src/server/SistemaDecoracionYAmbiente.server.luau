local Workspace = game:GetService("Workspace")

local function crearCarpetaSiNoExiste(parent: Instance, nombre: string): Folder
	local f = parent:FindFirstChild(nombre)
	if not f then
		f = Instance.new("Folder")
		f.Name = nombre
		f.Parent = parent
	end
	return f :: Folder
end

-- ====================================================================
-- 1. MOBILIARIO URBANO: BANCAS, JARDINERAS, PALMAS Y GUAYACANES
-- ====================================================================
local function crearBancaColonial(pos: Vector3, rotY: number, parent: Instance)
	local modelo = Instance.new("Model")
	modelo.Name = "BancaColonial"

	local base = Instance.new("Part")
	base.Name = "Asiento"
	base.Size = Vector3.new(5.0, 0.35, 1.6)
	base.CFrame = CFrame.new(pos + Vector3.new(0, 1.4, 0)) * CFrame.Angles(0, math.rad(rotY), 0)
	base.Color = Color3.fromRGB(115, 68, 38)
	base.Material = Enum.Material.WoodPlanks
	base.Anchored = true
	base.CanCollide = true
	base.Parent = modelo
	modelo.PrimaryPart = base

	-- Respaldo de madera
	local respaldo = Instance.new("Part")
	respaldo.Name = "Respaldo"
	respaldo.Size = Vector3.new(5.0, 1.4, 0.25)
	respaldo.CFrame = base.CFrame * CFrame.new(0, 0.9, -0.7)
	respaldo.Color = Color3.fromRGB(115, 68, 38)
	respaldo.Material = Enum.Material.WoodPlanks
	respaldo.Anchored = true
	respaldo.CanCollide = true
	respaldo.Parent = modelo

	-- Patas de hierro forjado negro
	for _, xOff in ipairs({ -2.1, 2.1 }) do
		local pata = Instance.new("Part")
		pata.Name = "PataHierro"
		pata.Size = Vector3.new(0.3, 1.4, 1.5)
		pata.CFrame = base.CFrame * CFrame.new(xOff, -0.65, 0)
		pata.Color = Color3.fromRGB(28, 28, 32)
		pata.Material = Enum.Material.Metal
		pata.Anchored = true
		pata.CanCollide = true
		pata.Parent = modelo
	end

	modelo.Parent = parent
	return modelo
end

local function crearJardineraFloral(pos: Vector3, size: Vector3, parent: Instance)
	local modelo = Instance.new("Model")
	modelo.Name = "JardineraFlores"

	local caja = Instance.new("Part")
	caja.Name = "MacetaPiedra"
	caja.Size = size
	caja.Position = pos + Vector3.new(0, size.Y / 2, 0)
	caja.Color = Color3.fromRGB(140, 135, 130)
	caja.Material = Enum.Material.Cobblestone
	caja.Anchored = true
	caja.CanCollide = true
	caja.Parent = modelo
	modelo.PrimaryPart = caja

	local tierra = Instance.new("Part")
	tierra.Name = "Tierra"
	tierra.Size = Vector3.new(size.X - 0.4, 0.2, size.Z - 0.4)
	tierra.Position = caja.Position + Vector3.new(0, size.Y / 2 + 0.05, 0)
	tierra.Color = Color3.fromRGB(60, 42, 28)
	tierra.Material = Enum.Material.Ground
	tierra.Anchored = true
	tierra.CanCollide = false
	tierra.Parent = modelo

	-- Flores andinas coloridas (Buganvilias, margaritas, claveles)
	local coloresFlores = {
		Color3.fromRGB(245, 60, 140), -- Buganvilia Fucsia
		Color3.fromRGB(255, 220, 40), -- Margarita Amarilla
		Color3.fromRGB(230, 45, 45), -- Clavel Rojo
		Color3.fromRGB(245, 245, 245), -- Jazmín Blanco
		Color3.fromRGB(150, 70, 220), -- Orquídea Morada
	}

	local numFlores = math.clamp(math.floor(size.X * size.Z * 1.5), 6, 20)
	for i = 1, numFlores do
		local fx = (math.random() - 0.5) * (size.X - 0.8)
		local fz = (math.random() - 0.5) * (size.Z - 0.8)
		local col = coloresFlores[(i % #coloresFlores) + 1]

		local flor = Instance.new("Part")
		flor.Name = "Flor"
		flor.Shape = Enum.PartType.Ball
		flor.Size = Vector3.new(0.65, 0.65, 0.65)
		flor.Position = tierra.Position + Vector3.new(fx, 0.35 + (math.random() * 0.25), fz)
		flor.Color = col
		flor.Material = Enum.Material.SmoothPlastic
		flor.Anchored = true
		flor.CanCollide = false
		flor.Parent = modelo
	end

	modelo.Parent = parent
	return modelo
end

local function crearPalmaDeCera(pos: Vector3, altura: number, parent: Instance)
	local modelo = Instance.new("Model")
	modelo.Name = "PalmaDeCera"

	-- Tronco alto y esbelto característico de la palma del Quindío
	local tronco = Instance.new("Part")
	tronco.Name = "Tronco"
	tronco.Shape = Enum.PartType.Cylinder
	tronco.Size = Vector3.new(altura, 1.4, 1.4)
	tronco.CFrame = CFrame.new(pos + Vector3.new(0, altura / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	tronco.Color = Color3.fromRGB(175, 170, 160)
	tronco.Material = Enum.Material.Wood
	tronco.Anchored = true
	tronco.CanCollide = true
	tronco.Parent = modelo
	modelo.PrimaryPart = tronco

	-- Corona de hojas verdes en la cima
	local cimaPos = pos + Vector3.new(0, altura, 0)
	for angulo = 0, 315, 45 do
		local hoja = Instance.new("Part")
		hoja.Name = "HojaPalma"
		hoja.Size = Vector3.new(5.5, 0.3, 1.6)
		hoja.CFrame = CFrame.new(cimaPos)
			* CFrame.Angles(0, math.rad(angulo), 0)
			* CFrame.Angles(math.rad(-25), 0, 0)
			* CFrame.new(0, 0, 2.4)
		hoja.Color = Color3.fromRGB(45, 135, 50)
		hoja.Material = Enum.Material.Grass
		hoja.Anchored = true
		hoja.CanCollide = false
		hoja.Parent = modelo
	end

	modelo.Parent = parent
	return modelo
end

local function crearGuayacanAmarillo(pos: Vector3, parent: Instance)
	local modelo = Instance.new("Model")
	modelo.Name = "GuayacanAmarillo"

	local tronco = Instance.new("Part")
	tronco.Name = "Tronco"
	tronco.Size = Vector3.new(2.2, 10, 2.2)
	tronco.Position = pos + Vector3.new(0, 5, 0)
	tronco.Color = Color3.fromRGB(90, 60, 40)
	tronco.Material = Enum.Material.Wood
	tronco.Anchored = true
	tronco.CanCollide = true
	tronco.Parent = modelo
	modelo.PrimaryPart = tronco

	-- Copa de flores amarillo oro brillante
	local copa = Instance.new("Part")
	copa.Name = "CopaDorada"
	copa.Shape = Enum.PartType.Ball
	copa.Size = Vector3.new(12, 10, 12)
	copa.Position = tronco.Position + Vector3.new(0, 6.5, 0)
	copa.Color = Color3.fromRGB(255, 215, 30)
	copa.Material = Enum.Material.Grass
	copa.Anchored = true
	copa.CanCollide = false
	copa.Parent = modelo

	modelo.Parent = parent
	return modelo
end

-- ====================================================================
-- 2. VEHÍCULOS ESTACIONADOS: TAXI AMARILLO Y CAMPERO DE ESTACAS
-- ====================================================================
local function crearTaxiAmarillo(pos: Vector3, rotY: number, parent: Instance)
	local modelo = Instance.new("Model")
	modelo.Name = "Vehiculo_TaxiTradicional"

	local chasis = Instance.new("Part")
	chasis.Name = "Chasis"
	chasis.Size = Vector3.new(6.5, 2.8, 13.0)
	chasis.CFrame = CFrame.new(pos + Vector3.new(0, 2.0, 0)) * CFrame.Angles(0, math.rad(rotY), 0)
	chasis.Color = Color3.fromRGB(255, 205, 20) -- Amarillo taxi
	chasis.Material = Enum.Material.Metal
	chasis.Anchored = true
	chasis.CanCollide = true
	chasis.Parent = modelo
	modelo.PrimaryPart = chasis

	-- Cabina / Techo
	local cabina = Instance.new("Part")
	cabina.Name = "Cabina"
	cabina.Size = Vector3.new(5.8, 2.4, 7.0)
	cabina.CFrame = chasis.CFrame * CFrame.new(0, 2.2, 0.4)
	cabina.Color = Color3.fromRGB(40, 48, 60)
	cabina.Material = Enum.Material.Glass
	cabina.Transparency = 0.35
	cabina.Anchored = true
	cabina.CanCollide = true
	cabina.Parent = modelo

	-- Letrero TAXI iluminado en el techo
	local cartelTaxi = Instance.new("Part")
	cartelTaxi.Name = "CartelTaxi"
	cartelTaxi.Size = Vector3.new(2.4, 0.7, 1.2)
	cartelTaxi.CFrame = cabina.CFrame * CFrame.new(0, 1.5, 0)
	cartelTaxi.Color = Color3.fromRGB(255, 245, 220)
	cartelTaxi.Material = Enum.Material.Neon
	cartelTaxi.Anchored = true
	cartelTaxi.CanCollide = false
	cartelTaxi.Parent = modelo

	local bbg = Instance.new("BillboardGui")
	bbg.Size = UDim2.fromOffset(80, 28)
	bbg.AlwaysOnTop = true
	bbg.MaxDistance = 50
	bbg.Parent = cartelTaxi

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text = "TAXI"
	lbl.Font = Enum.Font.FredokaOne
	lbl.TextColor3 = Color3.fromRGB(20, 20, 25)
	lbl.TextSize = 16
	lbl.Parent = bbg

	-- Farolas delanteras
	for _, x in ipairs({ -2.4, 2.4 }) do
		local farol = Instance.new("Part")
		farol.Name = "FarolDelantero"
		farol.Size = Vector3.new(0.9, 0.7, 0.4)
		farol.CFrame = chasis.CFrame * CFrame.new(x, 0.2, -6.4)
		farol.Color = Color3.fromRGB(255, 255, 220)
		farol.Material = Enum.Material.Neon
		farol.Anchored = true
		farol.CanCollide = false
		farol.Parent = modelo
	end

	-- Ruedas
	for _, x in ipairs({ -3.3, 3.3 }) do
		for _, z in ipairs({ -4.2, 4.2 }) do
			local rueda = Instance.new("Part")
			rueda.Name = "Rueda"
			rueda.Shape = Enum.PartType.Cylinder
			rueda.Size = Vector3.new(1.0, 2.4, 2.4)
			rueda.CFrame = chasis.CFrame * CFrame.new(x, -0.7, z) * CFrame.Angles(0, 0, math.rad(90))
			rueda.Color = Color3.fromRGB(30, 30, 35)
			rueda.Material = Enum.Material.Rubber
			rueda.Anchored = true
			rueda.CanCollide = false
			rueda.Parent = modelo
		end
	end

	modelo.Parent = parent
	return modelo
end

local function crearCamperoWillys(pos: Vector3, rotY: number, parent: Instance)
	local modelo = Instance.new("Model")
	modelo.Name = "Vehiculo_CamperoWillys"

	local chasis = Instance.new("Part")
	chasis.Name = "Chasis"
	chasis.Size = Vector3.new(7.0, 3.0, 14.0)
	chasis.CFrame = CFrame.new(pos + Vector3.new(0, 2.2, 0)) * CFrame.Angles(0, math.rad(rotY), 0)
	chasis.Color = Color3.fromRGB(55, 80, 50) -- Verde campero cafetero
	chasis.Material = Enum.Material.Metal
	chasis.Anchored = true
	chasis.CanCollide = true
	chasis.Parent = modelo
	modelo.PrimaryPart = chasis

	-- Cabina delantera
	local cabina = Instance.new("Part")
	cabina.Name = "Cabina"
	cabina.Size = Vector3.new(6.4, 2.8, 6.0)
	cabina.CFrame = chasis.CFrame * CFrame.new(0, 2.4, -2.5)
	cabina.Color = Color3.fromRGB(55, 80, 50)
	cabina.Material = Enum.Material.Metal
	cabina.Anchored = true
	cabina.CanCollide = true
	cabina.Parent = modelo

	-- Estacas traseras de madera
	for _, x in ipairs({ -3.1, 3.1 }) do
		local estaca = Instance.new("Part")
		estaca.Name = "EstacasMadera"
		estaca.Size = Vector3.new(0.35, 2.8, 7.5)
		estaca.CFrame = chasis.CFrame * CFrame.new(x, 2.2, 3.2)
		estaca.Color = Color3.fromRGB(150, 105, 60)
		estaca.Material = Enum.Material.WoodPlanks
		estaca.Anchored = true
		estaca.CanCollide = true
		estaca.Parent = modelo
	end

	-- Bultos de café en el platón
	for i = 1, 4 do
		local bulto = Instance.new("Part")
		bulto.Name = "BultoCafe"
		bulto.Size = Vector3.new(2.4, 1.4, 2.0)
		bulto.CFrame = chasis.CFrame * CFrame.new((i % 2 == 0 and 1.3 or -1.3), 1.2, 1.5 + (i * 1.0))
		bulto.Color = Color3.fromRGB(165, 140, 105)
		bulto.Material = Enum.Material.Fabric
		bulto.Anchored = true
		bulto.CanCollide = true
		bulto.Parent = modelo
	end

	modelo.Parent = parent
	return modelo
end

-- ====================================================================
-- 3. INTERIORES DE CASAS: MESA, CUADROS, RADIO Y FRASCOS DE DULCES
-- ====================================================================
local function decorarInteriorCocinaAbuela(parent: Instance)
	local interiorFolder = Instance.new("Model")
	interiorFolder.Name = "Interior_CasaAbuela"

	-- Coordenadas base dentro de Edificio_CocinaInicial (aprox 95, 61, -135)
	local posMesa = Vector3.new(90, 62.2, -132)

	-- Mesa de madera con mantel a cuadros
	local mesa = Instance.new("Part")
	mesa.Name = "MesaComedor"
	mesa.Size = Vector3.new(5.5, 0.4, 3.8)
	mesa.Position = posMesa
	mesa.Color = Color3.fromRGB(220, 60, 60) -- Mantel rojo tradicional
	mesa.Material = Enum.Material.Fabric
	mesa.Anchored = true
	mesa.CanCollide = true
	mesa.Parent = interiorFolder

	-- Patas de la mesa
	for _, xOff in ipairs({ -2.4, 2.4 }) do
		for _, zOff in ipairs({ -1.6, 1.6 }) do
			local pata = Instance.new("Part")
			pata.Name = "PataMesa"
			pata.Size = Vector3.new(0.4, 2.2, 0.4)
			pata.Position = mesa.Position + Vector3.new(xOff, -1.2, zOff)
			pata.Color = Color3.fromRGB(90, 55, 30)
			pata.Material = Enum.Material.Wood
			pata.Anchored = true
			pata.CanCollide = false
			pata.Parent = interiorFolder
		end
	end

	-- Radio de transistores antiguo sobre la mesa
	local radio = Instance.new("Part")
	radio.Name = "RadioTransistores"
	radio.Size = Vector3.new(1.4, 0.9, 0.6)
	radio.Position = mesa.Position + Vector3.new(-1.6, 0.65, -0.8)
	radio.Color = Color3.fromRGB(130, 85, 45)
	radio.Material = Enum.Material.Wood
	radio.Anchored = true
	radio.CanCollide = true
	radio.Parent = interiorFolder

	-- Cuadro tradicional en la pared (Sagrado Corazón / Paisaje Cafetero)
	local cuadro = Instance.new("Part")
	cuadro.Name = "CuadroSagradoCorazon"
	cuadro.Size = Vector3.new(3.2, 4.0, 0.2)
	cuadro.Position = Vector3.new(88, 67, -139.8)
	cuadro.Color = Color3.fromRGB(210, 165, 50) -- Marco dorado
	cuadro.Material = Enum.Material.Wood
	cuadro.Anchored = true
	cuadro.CanCollide = false
	cuadro.Parent = interiorFolder

	local lienzo = Instance.new("Part")
	lienzo.Name = "Lienzo"
	lienzo.Size = Vector3.new(2.8, 3.6, 0.1)
	lienzo.Position = cuadro.Position + Vector3.new(0, 0, 0.1)
	lienzo.Color = Color3.fromRGB(240, 220, 190)
	lienzo.Material = Enum.Material.SmoothPlastic
	lienzo.Anchored = true
	lienzo.CanCollide = false
	lienzo.Parent = interiorFolder

	-- Repisa de madera con frascos de dulces
	local repisa = Instance.new("Part")
	repisa.Name = "RepisaDulces"
	repisa.Size = Vector3.new(6.0, 0.3, 1.2)
	repisa.Position = Vector3.new(94, 66.5, -139.6)
	repisa.Color = Color3.fromRGB(110, 70, 40)
	repisa.Material = Enum.Material.WoodPlanks
	repisa.Anchored = true
	repisa.CanCollide = true
	repisa.Parent = interiorFolder

	local coloresFrascos = {
		Color3.fromRGB(240, 140, 40), -- Melcocha
		Color3.fromRGB(180, 110, 60), -- Panelita
		Color3.fromRGB(245, 60, 120), -- Bombón de guayaba
		Color3.fromRGB(255, 235, 120), -- Cocada
	}
	for i = 1, 4 do
		local frasco = Instance.new("Part")
		frasco.Name = "FrascoDulces"
		frasco.Shape = Enum.PartType.Cylinder
		frasco.Size = Vector3.new(1.1, 0.9, 0.9)
		frasco.CFrame = CFrame.new(repisa.Position + Vector3.new(-2.2 + (i * 1.1), 0.7, 0))
			* CFrame.Angles(0, 0, math.rad(90))
		frasco.Color = coloresFrascos[i]
		frasco.Material = Enum.Material.Glass
		frasco.Transparency = 0.25
		frasco.Anchored = true
		frasco.CanCollide = false
		frasco.Parent = interiorFolder
	end

	-- Lámpara colgante de luz cálida
	local lampara = Instance.new("Part")
	lampara.Name = "LamparaTechoCocina"
	lampara.Shape = Enum.PartType.Ball
	lampara.Size = Vector3.new(1.2, 1.2, 1.2)
	lampara.Position = Vector3.new(92, 70.5, -133)
	lampara.Color = Color3.fromRGB(255, 240, 190)
	lampara.Material = Enum.Material.Neon
	lampara.Anchored = true
	lampara.CanCollide = false
	lampara.Parent = interiorFolder

	local luzCocina = Instance.new("PointLight")
	luzCocina.Name = "LuzCalida"
	luzCocina.Color = Color3.fromRGB(255, 230, 170)
	luzCocina.Range = 24
	luzCocina.Brightness = 2.2
	luzCocina.Parent = lampara

	interiorFolder.Parent = parent
end

-- ====================================================================
-- 4. PUNTOS DE REFERENCIA Y LETREROS ILUMINADOS (LANDMARKS 3D)
-- ====================================================================
local function crearLetreroPuntoReferencia(
	texto: string,
	subtexto: string,
	pos: Vector3,
	rotY: number,
	colorMarco: Color3,
	parent: Instance
)
	local modelo = Instance.new("Model")
	modelo.Name = "Landmark_" .. string.gsub(texto, "%s+", "")

	local marco = Instance.new("Part")
	marco.Name = "Marco"
	marco.Size = Vector3.new(11.0, 3.2, 0.6)
	marco.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(rotY), 0)
	marco.Color = colorMarco
	marco.Material = Enum.Material.SmoothPlastic
	marco.Anchored = true
	marco.CanCollide = true
	marco.Parent = modelo
	modelo.PrimaryPart = marco

	-- Cara iluminada
	local caraLuz = Instance.new("Part")
	caraLuz.Name = "CaraIluminada"
	caraLuz.Size = Vector3.new(10.6, 2.8, 0.1)
	caraLuz.CFrame = marco.CFrame * CFrame.new(0, 0, 0.31)
	caraLuz.Color = Color3.fromRGB(25, 30, 42)
	caraLuz.Material = Enum.Material.Neon
	caraLuz.Anchored = true
	caraLuz.CanCollide = false
	caraLuz.Parent = modelo

	local surfGui = Instance.new("SurfaceGui")
	surfGui.Face = Enum.NormalId.Front
	surfGui.CanvasSize = Vector2.new(500, 140)
	surfGui.AlwaysOnTop = false
	surfGui.LightInfluence = 0.05
	surfGui.Parent = caraLuz

	local tituloLbl = Instance.new("TextLabel")
	tituloLbl.Size = UDim2.fromScale(1, 0.6)
	tituloLbl.Position = UDim2.fromOffset(0, 8)
	tituloLbl.BackgroundTransparency = 1
	tituloLbl.Font = Enum.Font.FredokaOne
	tituloLbl.Text = texto
	tituloLbl.TextColor3 = Color3.fromRGB(255, 240, 180)
	tituloLbl.TextSize = 34
	tituloLbl.Parent = surfGui

	local subLbl = Instance.new("TextLabel")
	subLbl.Size = UDim2.fromScale(1, 0.4)
	subLbl.Position = UDim2.fromOffset(0, 75)
	subLbl.BackgroundTransparency = 1
	subLbl.Font = Enum.Font.FredokaOne
	subLbl.Text = subtexto
	subLbl.TextColor3 = Color3.fromRGB(180, 215, 255)
	subLbl.TextSize = 22
	subLbl.Parent = surfGui

	local luzLandmark = Instance.new("PointLight")
	luzLandmark.Color = Color3.fromRGB(255, 235, 180)
	luzLandmark.Range = 18
	luzLandmark.Brightness = 1.5
	luzLandmark.Parent = marco

	modelo.Parent = parent
	return modelo
end

-- ====================================================================
-- INICIALIZACIÓN Y POBLACIÓN DEL MUNDO
-- ====================================================================
local function inicializarDecoracionYAmbiente()
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

	local parqueFolder = crearCarpetaSiNoExiste(decoracion, "ParquesYPlazoletas")
	local vehiculosEstacionados = crearCarpetaSiNoExiste(decoracion, "VehiculosEstacionados")
	local interioresFolder = crearCarpetaSiNoExiste(decoracion, "Interiores")
	local landmarksFolder = crearCarpetaSiNoExiste(decoracion, "PuntosDeReferencia")

	-- 1. Parque Central y Plazoleta del Colegio
	-- Bancas en el parque frente al colegio
	crearBancaColonial(Vector3.new(-42, 60, -25), 0, parqueFolder)
	crearBancaColonial(Vector3.new(-42, 60, 25), 180, parqueFolder)
	crearBancaColonial(Vector3.new(22, 60, -25), 0, parqueFolder)
	crearBancaColonial(Vector3.new(22, 60, 25), 180, parqueFolder)

	-- Jardineras florales en las esquinas de la plaza
	crearJardineraFloral(Vector3.new(-38, 60, -15), Vector3.new(6.0, 1.4, 2.4), parqueFolder)
	crearJardineraFloral(Vector3.new(-38, 60, 15), Vector3.new(6.0, 1.4, 2.4), parqueFolder)
	crearJardineraFloral(Vector3.new(18, 60, -15), Vector3.new(6.0, 1.4, 2.4), parqueFolder)
	crearJardineraFloral(Vector3.new(18, 60, 15), Vector3.new(6.0, 1.4, 2.4), parqueFolder)

	-- Palmas de Cera y Guayacanes Dorados
	crearPalmaDeCera(Vector3.new(-45, 60, -40), 22, parqueFolder)
	crearPalmaDeCera(Vector3.new(-45, 60, 40), 24, parqueFolder)
	crearGuayacanAmarillo(Vector3.new(28, 60, -45), parqueFolder)
	crearGuayacanAmarillo(Vector3.new(28, 60, 45), parqueFolder)

	-- 2. Vehículos Estacionados Típicos Colombianos
	-- Taxi tradicional en la bahía de la plaza
	crearTaxiAmarillo(Vector3.new(14, 60, -28), 90, vehiculosEstacionados)
	-- Campero Willys cafetero en la esquina comercial
	crearCamperoWillys(Vector3.new(-48, 60, 50), -90, vehiculosEstacionados)

	-- 3. Interiores
	decorarInteriorCocinaAbuela(interioresFolder)

	-- 4. Puntos de Referencia y Letreros Iluminados (Landmarks 3D)
	crearLetreroPuntoReferencia(
		"COLEGIO SAN JERÓNIMO",
		"Entrada Principal • Prohibido Dulces",
		Vector3.new(-75, 68, -48),
		0,
		Color3.fromRGB(35, 75, 140),
		landmarksFolder
	)
	crearLetreroPuntoReferencia(
		"LA ESQUINA PAISA",
		"Don Chucho • Víveres & Confites",
		Vector3.new(98, 73, 172),
		-90,
		Color3.fromRGB(160, 45, 35),
		landmarksFolder
	)
	crearLetreroPuntoReferencia(
		"CASA DE LA ABUELA",
		"Dulces Artesanales Doña Melcocha",
		Vector3.new(95, 68, -120),
		180,
		Color3.fromRGB(180, 110, 40),
		landmarksFolder
	)
	crearLetreroPuntoReferencia(
		"EL MIRADOR DEL VALLE",
		"Villa Almíbar • Altura 2.200m",
		Vector3.new(-98, 108, 412),
		90,
		Color3.fromRGB(45, 120, 60),
		landmarksFolder
	)

	print("El Patrón del Dulce: Decoración exterior, parques, interiores y landmarks inicializados")
end

task.spawn(inicializarDecoracionYAmbiente)
