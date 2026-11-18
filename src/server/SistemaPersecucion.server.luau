local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GestorDatos = require(script.Parent.GestorDatos)
local Datos = require(ReplicatedStorage.Shared.Datos)
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)

local RADIO_ESCONDITE = 16
local RADIO_DETECCION_RETEN = 16

type EstadoJugadorPersecucion = {
	TiempoEnEscondite: number,
	Enfriando: boolean,
	UltimaNotificacionReten: number,
	UltimoTickSegundo: number,
}

local estadosPersecucion: { [Player]: EstadoJugadorPersecucion } = {}
local redadaEnCurso = false
local iniciarRedadaDental: () -> ()

local function soldar(p0: BasePart, p1: BasePart)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.Parent = p0
end

local function obtenerPosicionSuelo(posBase: Vector3, alturaOffset: number?): Vector3
	local offset = alturaOffset or 3.0
	local rayOrigin = Vector3.new(posBase.X, posBase.Y + 12.0, posBase.Z)
	local rayDir = Vector3.new(0, -75, 0)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	local exclusions: { Instance } = {}
	local mapa = Workspace:FindFirstChild("Mapa")
	if mapa then
		local dec = mapa:FindFirstChild("Decoracion")
		if dec then
			table.insert(exclusions, dec)
		end
	end

	local maxPasos = 10
	local paso = 0
	while paso < maxPasos do
		paso += 1
		params.FilterDescendantsInstances = exclusions
		local hit = Workspace:Raycast(rayOrigin, rayDir, params)
		if not hit then
			break
		end

		local n = hit.Instance.Name:lower()
		local esTechoOCielo = (
			string.find(n, "techo")
			or string.find(n, "teja")
			or string.find(n, "cubierta")
			or string.find(n, "dintel")
			or string.find(n, "alero")
			or string.find(n, "toldo")
			or string.find(n, "cobertizo")
			or string.find(n, "marquesina")
			or string.find(n, "cielo")
			or string.find(n, "losa")
			or string.find(n, "banderin")
			or string.find(n, "poste")
			or string.find(n, "foco")
			or string.find(n, "letrero")
			or not hit.Instance.CanCollide
			or (hit.Position.Y > posBase.Y + 2.0)
		)

		if esTechoOCielo then
			table.insert(exclusions, hit.Instance)
			rayOrigin = hit.Position - Vector3.new(0, 0.05, 0)
		else
			return Vector3.new(posBase.X, hit.Position.Y + offset, posBase.Z)
		end
	end

	return posBase
end

local function obtenerPuntoSpawnSeguro(): Vector3
	local puntos = Workspace:FindFirstChild("Puntos")
	if puntos then
		local apariciones = puntos:FindFirstChild("Apariciones")
		if apariciones then
			local cocina = apariciones:FindFirstChild("Punto_Cocina_Inicial") :: BasePart?
			if cocina then
				return cocina.Position + Vector3.new(0, 3, 0)
			end
		end
	end
	return Vector3.new(97, 63, -119)
end

local function obtenerPuntoInternado(): Vector3
	local mapa = Workspace:FindFirstChild("Mapa")
	local internado = mapa and mapa:FindFirstChild("Zona_InternadoSinAzucar")
	local punto = internado and internado:FindFirstChild("Punto_Internado") :: BasePart?
	if punto then
		return punto.Position + Vector3.new(0, 3, 0)
	end
	return Vector3.new(0, 118, 520)
end

local function configurarEscondites()
	local puntos = Workspace:WaitForChild("Puntos", 10)
	if not puntos then
		return
	end
	local esconditesFolder = puntos:WaitForChild("Escondites", 10)
	if not esconditesFolder then
		return
	end

	for _, punto in ipairs(esconditesFolder:GetChildren()) do
		if punto:IsA("BasePart") then
			local existente = punto:FindFirstChild("IndicadorEscondite")
			if not existente then
				local bbg = Instance.new("BillboardGui")
				bbg.Name = "IndicadorEscondite"
				bbg.Size = UDim2.fromOffset(180, 50)
				bbg.StudsOffset = Vector3.new(0, 3, 0)
				bbg.AlwaysOnTop = false
				bbg.MaxDistance = 40
				bbg.Parent = punto

				local fondo = Instance.new("Frame")
				fondo.Name = "Fondo"
				fondo.Size = UDim2.fromScale(1, 1)
				fondo.BackgroundColor3 = Color3.fromRGB(20, 35, 25)
				fondo.BackgroundTransparency = 0.2
				fondo.Parent = bbg

				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0, 8)
				corner.Parent = fondo

				local stroke = Instance.new("UIStroke")
				stroke.Color = Color3.fromRGB(70, 220, 120)
				stroke.Thickness = 1.5
				stroke.Parent = fondo

				local titulo = Instance.new("TextLabel")
				titulo.Name = "Titulo"
				titulo.Size = UDim2.fromScale(1, 0.55)
				titulo.BackgroundTransparency = 1
				titulo.Font = Enum.Font.FredokaOne
				titulo.Text = "🕶️ ZONA SEGURA"
				titulo.TextColor3 = Color3.fromRGB(120, 255, 160)
				titulo.TextSize = 15
				titulo.Parent = fondo

				local subtitulo = Instance.new("TextLabel")
				subtitulo.Name = "Subtitulo"
				subtitulo.Size = UDim2.fromScale(1, 0.45)
				subtitulo.Position = UDim2.fromScale(0, 0.55)
				subtitulo.BackgroundTransparency = 1
				subtitulo.Font = Enum.Font.GothamMedium
				subtitulo.Text = "Escondite (-15 pts/s)"
				subtitulo.TextColor3 = Color3.fromRGB(200, 240, 210)
				subtitulo.TextSize = 12
				subtitulo.Parent = fondo
			end
		end
	end
end

local function buscarEsconditeCercano(posicion: Vector3): (boolean, number)
	local puntos = Workspace:FindFirstChild("Puntos")
	if not puntos then
		return false, math.huge
	end
	local esconditesFolder = puntos:FindFirstChild("Escondites")
	if not esconditesFolder then
		return false, math.huge
	end

	local distanciaMinima = math.huge
	for _, punto in ipairs(esconditesFolder:GetChildren()) do
		if punto:IsA("BasePart") then
			local dist = (punto.Position - posicion).Magnitude
			if dist < distanciaMinima then
				distanciaMinima = dist
			end
		end
	end

	return (distanciaMinima <= RADIO_ESCONDITE), distanciaMinima
end

local function buscarRetenCercano(posicion: Vector3): (boolean, BasePart?)
	local puntos = Workspace:FindFirstChild("Puntos")
	if not puntos then
		return false, nil
	end
	local retenesFolder = puntos:FindFirstChild("Retenes")
	if not retenesFolder then
		return false, nil
	end

	for _, punto in ipairs(retenesFolder:GetChildren()) do
		if punto:IsA("BasePart") then
			local dist = (punto.Position - posicion).Magnitude
			if dist <= RADIO_DETECCION_RETEN then
				return true, punto
			end
		end
	end

	return false, nil
end

-- ====================================================================
-- SISTEMA DE 12 POLICÍAS DENTALES (6 DE RETÉN CON REQUISAS + 6 PATRULLEROS)
-- ====================================================================
local function crearModeloPoliciaBase(
	nombre: string,
	pos: Vector3,
	titulo: string,
	parentFolder: Instance,
	esPatrullero: boolean
): Model
	local modelo = Instance.new("Model")
	modelo.Name = nombre
	modelo.Parent = parentFolder

	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(2, 2, 1)
	hrp.Position = obtenerPosicionSuelo(pos, 3.0)
	hrp.Transparency = 1
	hrp.CanCollide = false
	hrp.Anchored = true
	hrp.Parent = modelo
	modelo.PrimaryPart = hrp

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Position = hrp.Position
	torso.Color = Color3.fromRGB(24, 34, 56) -- Uniforme policía azul oscuro
	torso.Material = Enum.Material.SmoothPlastic
	torso.Anchored = false
	torso.CanCollide = false
	torso.Parent = modelo
	soldar(hrp, torso)

	local cinturon = Instance.new("Part")
	cinturon.Name = "Cinturon"
	cinturon.Size = Vector3.new(2.1, 0.35, 1.1)
	cinturon.Position = torso.Position + Vector3.new(0, -0.85, 0)
	cinturon.Color = Color3.fromRGB(15, 15, 18)
	cinturon.Material = Enum.Material.SmoothPlastic
	cinturon.Anchored = false
	cinturon.CanCollide = false
	cinturon.Parent = modelo
	soldar(hrp, cinturon)

	local hebilla = Instance.new("Part")
	hebilla.Name = "Hebilla"
	hebilla.Size = Vector3.new(0.4, 0.3, 0.15)
	hebilla.Position = cinturon.Position + Vector3.new(0, 0, -0.55)
	hebilla.Color = Color3.fromRGB(240, 200, 50)
	hebilla.Material = Enum.Material.Metal
	hebilla.Anchored = false
	hebilla.CanCollide = false
	hebilla.Parent = modelo
	soldar(hrp, hebilla)

	-- Chaleco Reflectivo de Tránsito de Alta Visibilidad
	local chaleco = Instance.new("Part")
	chaleco.Name = "ChalecoReflectivo"
	chaleco.Size = Vector3.new(2.05, 1.3, 1.05)
	chaleco.Position = torso.Position + Vector3.new(0, 0.25, 0)
	chaleco.Color = Color3.fromRGB(220, 245, 35) -- Amarillo/Verde neón de tránsito
	chaleco.Material = Enum.Material.SmoothPlastic
	chaleco.Anchored = false
	chaleco.CanCollide = false
	chaleco.Parent = modelo
	soldar(hrp, chaleco)

	-- Franjas reflectivas plateadas que brillan en la oscuridad
	for _, yFranja in ipairs({ -0.15, 0.25 }) do
		local franjaPlateada = Instance.new("Part")
		franjaPlateada.Name = "FranjaReflectiva"
		franjaPlateada.Size = Vector3.new(2.1, 0.22, 1.1)
		franjaPlateada.Position = chaleco.Position + Vector3.new(0, yFranja, 0)
		franjaPlateada.Color = Color3.fromRGB(245, 250, 255)
		franjaPlateada.Material = Enum.Material.Neon
		franjaPlateada.Anchored = false
		franjaPlateada.CanCollide = false
		franjaPlateada.Parent = modelo
		soldar(hrp, franjaPlateada)
	end

	-- Radio walkie-talkie en el hombro izquierdo
	local radioHombro = Instance.new("Part")
	radioHombro.Name = "RadioTransmisor"
	radioHombro.Size = Vector3.new(0.35, 0.65, 0.35)
	radioHombro.Position = torso.Position + Vector3.new(-0.85, 0.85, -0.1)
	radioHombro.Color = Color3.fromRGB(25, 25, 30)
	radioHombro.Material = Enum.Material.SmoothPlastic
	radioHombro.Anchored = false
	radioHombro.CanCollide = false
	radioHombro.Parent = modelo
	soldar(hrp, radioHombro)

	local antena = Instance.new("Part")
	antena.Name = "AntenaRadio"
	antena.Size = Vector3.new(0.08, 0.7, 0.08)
	antena.Position = radioHombro.Position + Vector3.new(0, 0.6, 0)
	antena.Color = Color3.fromRGB(15, 15, 15)
	antena.Material = Enum.Material.Metal
	antena.Anchored = false
	antena.CanCollide = false
	antena.Parent = modelo
	soldar(hrp, antena)

	-- Bastón de mando / Porra policial en el cinto derecho
	local porra = Instance.new("Part")
	porra.Name = "PorraPolicial"
	porra.Size = Vector3.new(0.25, 1.8, 0.25)
	porra.Position = cinturon.Position + Vector3.new(1.15, -0.5, 0.1)
	porra.Color = Color3.fromRGB(20, 20, 25)
	porra.Material = Enum.Material.Metal
	porra.Anchored = false
	porra.CanCollide = false
	porra.Parent = modelo
	soldar(hrp, porra)

	local placa = Instance.new("Part")
	placa.Name = "Placa"
	placa.Size = Vector3.new(0.35, 0.45, 0.1)
	placa.Position = torso.Position + Vector3.new(0.5, 0.45, -0.55)
	placa.Color = Color3.fromRGB(255, 215, 0)
	placa.Material = Enum.Material.Metal
	placa.Anchored = false
	placa.CanCollide = false
	placa.Parent = modelo
	soldar(hrp, placa)

	local cabeza = Instance.new("Part")
	cabeza.Name = "Head"
	cabeza.Size = Vector3.new(1.2, 1.2, 1.2)
	cabeza.Position = torso.Position + Vector3.new(0, 1.6, 0)
	cabeza.Color = Color3.fromRGB(235, 195, 160)
	cabeza.Material = Enum.Material.SmoothPlastic
	cabeza.Anchored = false
	cabeza.CanCollide = false
	cabeza.Parent = modelo
	soldar(hrp, cabeza)

	-- Bigote policial de autoridad
	local bigote = Instance.new("Part")
	bigote.Name = "Bigote"
	bigote.Size = Vector3.new(0.55, 0.15, 0.15)
	bigote.Position = cabeza.Position + Vector3.new(0, -0.22, -0.6)
	bigote.Color = Color3.fromRGB(40, 30, 25)
	bigote.Material = Enum.Material.SmoothPlastic
	bigote.Anchored = false
	bigote.CanCollide = false
	bigote.Parent = modelo
	soldar(hrp, bigote)

	if esPatrullero then
		-- Gafas de sol tácticas para patrulleros
		local gafas = Instance.new("Part")
		gafas.Name = "GafasTacticas"
		gafas.Size = Vector3.new(0.95, 0.25, 0.2)
		gafas.Position = cabeza.Position + Vector3.new(0, 0.15, -0.62)
		gafas.Color = Color3.fromRGB(20, 20, 25)
		gafas.Material = Enum.Material.Glass
		gafas.Anchored = false
		gafas.CanCollide = false
		gafas.Parent = modelo
		soldar(hrp, gafas)
	else
		-- Paleta de PARE / ALTO POLICÍA DENTAL para oficiales de retén
		local paletaPalo = Instance.new("Part")
		paletaPalo.Name = "PaletaPalo"
		paletaPalo.Size = Vector3.new(0.18, 1.8, 0.18)
		paletaPalo.Position = torso.Position + Vector3.new(-1.3, -0.2, -0.6)
		paletaPalo.Color = Color3.fromRGB(150, 150, 150)
		paletaPalo.Material = Enum.Material.Metal
		paletaPalo.Anchored = false
		paletaPalo.CanCollide = false
		paletaPalo.Parent = modelo
		soldar(hrp, paletaPalo)

		local paletaDisco = Instance.new("Part")
		paletaDisco.Name = "PaletaDisco"
		paletaDisco.Size = Vector3.new(1.3, 1.3, 0.15)
		paletaDisco.Position = paletaPalo.Position + Vector3.new(0, 0.9, 0)
		paletaDisco.Color = Color3.fromRGB(230, 35, 35) -- Octágono / disco rojo
		paletaDisco.Material = Enum.Material.SmoothPlastic
		paletaDisco.Anchored = false
		paletaDisco.CanCollide = false
		paletaDisco.Parent = modelo
		soldar(hrp, paletaDisco)

		local paletaCentro = Instance.new("Part")
		paletaCentro.Name = "PaletaCentro"
		paletaCentro.Size = Vector3.new(0.8, 0.8, 0.18)
		paletaCentro.Position = paletaDisco.Position
		paletaCentro.Color = Color3.fromRGB(255, 255, 255)
		paletaCentro.Material = Enum.Material.Neon
		paletaCentro.Anchored = false
		paletaCentro.CanCollide = false
		paletaCentro.Parent = modelo
		soldar(hrp, paletaCentro)
	end

	local gorra = Instance.new("Part")
	gorra.Name = "Gorra"
	gorra.Size = Vector3.new(1.3, 0.5, 1.4)
	gorra.Position = cabeza.Position + Vector3.new(0, 0.65, -0.1)
	gorra.Color = Color3.fromRGB(20, 26, 42)
	gorra.Material = Enum.Material.SmoothPlastic
	gorra.Anchored = false
	gorra.CanCollide = false
	gorra.Parent = modelo
	soldar(hrp, gorra)

	local viseraGorra = Instance.new("Part")
	viseraGorra.Name = "ViseraGorra"
	viseraGorra.Size = Vector3.new(1.2, 0.12, 0.65)
	viseraGorra.Position = gorra.Position + Vector3.new(0, -0.15, -0.75)
	viseraGorra.Color = Color3.fromRGB(10, 10, 12)
	viseraGorra.Material = Enum.Material.Metal -- Visera charolada brillante
	viseraGorra.Anchored = false
	viseraGorra.CanCollide = false
	viseraGorra.Parent = modelo
	soldar(hrp, viseraGorra)

	local placaGorra = Instance.new("Part")
	placaGorra.Name = "PlacaGorra"
	placaGorra.Size = Vector3.new(0.3, 0.3, 0.1)
	placaGorra.Position = gorra.Position + Vector3.new(0, 0, -0.72)
	placaGorra.Color = Color3.fromRGB(255, 215, 0)
	placaGorra.Material = Enum.Material.Metal
	placaGorra.Anchored = false
	placaGorra.CanCollide = false
	placaGorra.Parent = modelo
	soldar(hrp, placaGorra)

	local piernas = Instance.new("Part")
	piernas.Name = "Piernas"
	piernas.Size = Vector3.new(1.8, 2, 0.9)
	piernas.Position = torso.Position + Vector3.new(0, -2, 0)
	piernas.Color = Color3.fromRGB(18, 24, 38)
	piernas.Material = Enum.Material.SmoothPlastic
	piernas.Anchored = false
	piernas.CanCollide = false
	piernas.Parent = modelo
	soldar(hrp, piernas)

	local sirena = Instance.new("PointLight")
	sirena.Name = "SirenaLuz"
	sirena.Color = if esPatrullero
		then Color3.fromRGB(40, 120, 255)
		else Color3.fromRGB(255, 40, 40)
	sirena.Brightness = 2.5
	sirena.Range = 22
	sirena.Enabled = true
	sirena.Parent = gorra

	local bbg = Instance.new("BillboardGui")
	bbg.Name = "RotuloPolicia"
	bbg.Size = UDim2.fromOffset(220, 48)
	bbg.StudsOffset = Vector3.new(0, 3.2, 0)
	bbg.AlwaysOnTop = true
	bbg.MaxDistance = 45
	bbg.Parent = cabeza

	local lbl = Instance.new("TextLabel")
	lbl.Name = "TextoRotulo"
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.FredokaOne
	lbl.Text = titulo
	lbl.TextColor3 = Color3.fromRGB(200, 225, 255)
	lbl.TextSize = 13
	lbl.Parent = bbg

	return modelo
end

local function crearBarreraRetenFisica(pos: Vector3, parentFolder: Instance): Model
	local barrera = Instance.new("Model")
	barrera.Name = "BarreraReten"
	barrera.Parent = parentFolder

	local valla = Instance.new("Part")
	valla.Name = "Valla"
	valla.Size = Vector3.new(7.5, 2.5, 0.8)
	valla.Position = pos
	valla.Color = Color3.fromRGB(240, 240, 245)
	valla.Material = Enum.Material.SmoothPlastic
	valla.Anchored = true
	valla.CanCollide = true
	valla.Parent = barrera

	local f1 = Instance.new("Part")
	f1.Name = "Franja1"
	f1.Size = Vector3.new(1.8, 2.55, 0.85)
	f1.Position = pos + Vector3.new(-2.2, 0, 0)
	f1.Color = Color3.fromRGB(220, 40, 40)
	f1.Material = Enum.Material.SmoothPlastic
	f1.Anchored = true
	f1.CanCollide = false
	f1.Parent = barrera

	local f2 = Instance.new("Part")
	f2.Name = "Franja2"
	f2.Size = Vector3.new(1.8, 2.55, 0.85)
	f2.Position = pos + Vector3.new(2.2, 0, 0)
	f2.Color = Color3.fromRGB(220, 40, 40)
	f2.Material = Enum.Material.SmoothPlastic
	f2.Anchored = true
	f2.CanCollide = false
	f2.Parent = barrera

	local luzSirena = Instance.new("PointLight")
	luzSirena.Name = "SirenaBarrera"
	luzSirena.Color = Color3.fromRGB(255, 40, 40)
	luzSirena.Brightness = 2.5
	luzSirena.Range = 20
	luzSirena.Parent = valla

	return barrera
end

local function configurar12PoliciasDentales()
	local puntos = Workspace:WaitForChild("Puntos", 10)
	if not puntos then
		return
	end
	local retenesFolder = puntos:WaitForChild("Retenes", 10)
	if not retenesFolder then
		return
	end

	local mapa = Workspace:WaitForChild("Mapa", 10)
	local decoracion = mapa and mapa:WaitForChild("Decoracion", 10)
	if not decoracion then
		return
	end

	local policiasFolder = decoracion:FindFirstChild("PoliciasDentales")
	if not policiasFolder then
		policiasFolder = Instance.new("Folder")
		policiasFolder.Name = "PoliciasDentales"
		policiasFolder.Parent = decoracion
	end

	local folderRetenes = policiasFolder:FindFirstChild("Retenes")
	if not folderRetenes then
		folderRetenes = Instance.new("Folder")
		folderRetenes.Name = "Retenes"
		folderRetenes.Parent = policiasFolder
	end

	local folderPatrulleros = policiasFolder:FindFirstChild("Patrulleros")
	if not folderPatrulleros then
		folderPatrulleros = Instance.new("Folder")
		folderPatrulleros.Name = "Patrulleros"
		folderPatrulleros.Parent = policiasFolder
	end

	-- -------------------------------------------------------------
	-- A. 6 POLICÍAS DE RETÉN EN PUNTOS FIJOS (REQUISAS E INSPECCIONES)
	-- -------------------------------------------------------------
	local listaRetenes = {
		{
			Id = "Punto_Reten_01",
			Nombre = "Policia_Reten_01",
			Titulo = "👮 Agente Dental N° 1\n(Retén Salida Colegio)",
			PosicionReten = Vector3.new(-90, 65, -35),
			PosicionOficial = Vector3.new(-86, 65, -35),
		},
		{
			Id = "Punto_Reten_02",
			Nombre = "Policia_Reten_02",
			Titulo = "👮 Agente Dental N° 2\n(Retén Avenida Norte)",
			PosicionReten = Vector3.new(0, 69, 120),
			PosicionOficial = Vector3.new(4, 69, 120),
		},
		{
			Id = "Punto_Reten_03",
			Nombre = "Policia_Reten_03",
			Titulo = "👮 Agente Dental N° 3\n(Retén Cruce Comercio)",
			PosicionReten = Vector3.new(55, 65, 80),
			PosicionOficial = Vector3.new(59, 65, 80),
		},
		{
			Id = "Punto_Reten_04",
			Nombre = "Policia_Reten_04",
			Titulo = "👮 Agente Dental N° 4\n(Retén Curva Ladera)",
			PosicionReten = Vector3.new(-55, 75, 230),
			PosicionOficial = Vector3.new(-51, 75, 230),
		},
		{
			Id = "Punto_Reten_05",
			Nombre = "Policia_Reten_05",
			Titulo = "👮 Agente Dental N° 5\n(Retén Subida Media)",
			PosicionReten = Vector3.new(0, 96.5, 360),
			PosicionOficial = Vector3.new(4, 96.5, 360),
		},
		{
			Id = "Punto_Reten_06",
			Nombre = "Policia_Reten_06",
			Titulo = "👮 Agente Dental N° 6\n(Retén Acceso Internado)",
			PosicionReten = Vector3.new(0, 115, 490),
			PosicionOficial = Vector3.new(4, 115, 490),
		},
	}

	for _, ret in ipairs(listaRetenes) do
		-- Asegurar parte en Workspace.Puntos.Retenes
		local parteReten = retenesFolder:FindFirstChild(ret.Id) :: BasePart?
		if not parteReten then
			parteReten = Instance.new("Part")
			parteReten.Name = ret.Id
			parteReten.Size = Vector3.new(8, 2, 8)
			parteReten.Position = ret.PosicionReten
			parteReten.Transparency = 1
			parteReten.CanCollide = false
			parteReten.Anchored = true
			parteReten.Parent = retenesFolder
		end

		-- Crear barrera física
		if not parteReten:FindFirstChild("BarreraReten") then
			crearBarreraRetenFisica(ret.PosicionReten, parteReten)
		end

		-- Crear modelo de oficial de retén si no existe
		local oficialExistente = folderRetenes:FindFirstChild(ret.Nombre)
		if not oficialExistente then
			local oficial = crearModeloPoliciaBase(
				ret.Nombre,
				ret.PosicionOficial,
				ret.Titulo,
				folderRetenes,
				false
			)

			-- ProximityPrompt para solicitar / permitir requisa voluntaria
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "PromptRequisa"
			prompt.ObjectText = "Policía Dental"
			prompt.ActionText = "Permitir Requisa"
			prompt.HoldDuration = 0.4
			prompt.MaxActivationDistance = 12
			prompt.RequiresLineOfSight = false
			prompt.Parent = oficial:FindFirstChild("Torso")

			prompt.Triggered:Connect(function(player: Player)
				if oficial:GetAttribute("Aturdido") then
					EventosRemotos.MostrarDialogoNPC:FireClient(player, {
						Nombre = "Policía Dental (Retén)",
						Titulo = "¡Aturdido!",
						Icono = "😵",
						Mensaje = "¡Puaj! ¡Tengo dulce pegado en la gorra y en la placa! Pasa rápido antes de que me limpie...",
					})
					return
				end

				local estrellas = GestorDatos.ObtenerEstrellas(player)
				local calor = GestorDatos.ObtenerPuntosCalor(player)

				if estrellas >= 1 or calor > 10 then
					local reglaEstrella = Datos.Persecucion.Estrellas[estrellas]
						or Datos.Persecucion.Estrellas[1]
					local pct = reglaEstrella.PierdeCargaPorcentaje or 0.15
					local confiscados = GestorDatos.ConfiscarCargaPorcentaje(player, pct)

					EventosRemotos.MostrarDialogoNPC:FireClient(player, {
						Nombre = "Policía Dental (Retén)",
						Titulo = "🚨 ¡REQUISA DENTAL OFICIAL!",
						Icono = "👮",
						Mensaje = string.format(
							"¡ALTO AHÍ! Inspección de rutina de la Policía Dental de Villa Almíbar.\n\nPor violar el Decreto Municipal N° 001, tu cargamento de golosinas ha sido decomisado (%d unidades incautadas). ¡Cero caries en nuestro pueblo!",
							confiscados
						),
					})
				else
					EventosRemotos.MostrarDialogoNPC:FireClient(player, {
						Nombre = "Policía Dental (Retén)",
						Titulo = "Inspección de Rutina",
						Icono = "👮",
						Mensaje = "Inspección completada: Bolsillos y maletín dentro de la norma sanitaria. Puede circular con precaución por las vías.",
					})
				end
			end)
		end
	end

	-- -------------------------------------------------------------
	-- B. 6 POLICÍAS PATRULLEROS EN RUTAS CALLEJERAS Y PERSECUCIÓN
	-- -------------------------------------------------------------
	local listaPatrulleros = {
		{
			Nombre = "Policia_Patrulla_01",
			Titulo = "🚓 Patrullero 01\n(Sector Colegio/Parque)",
			PosicionInicial = Vector3.new(-90, 65, -55),
			Ruta = {
				Vector3.new(-90, 65, -55),
				Vector3.new(-65, 65, -38),
				Vector3.new(-75, 65, -15),
			},
		},
		{
			Nombre = "Policia_Patrulla_02",
			Titulo = "🚓 Patrullero 02\n(Avenida Principal Norte)",
			PosicionInicial = Vector3.new(0, 67, 30),
			Ruta = {
				Vector3.new(0, 67, 30),
				Vector3.new(0, 69, 95),
				Vector3.new(0, 71, 155),
			},
		},
		{
			Nombre = "Policia_Patrulla_03",
			Titulo = "🚓 Patrullero 03\n(Barrio Comercial Abajo)",
			PosicionInicial = Vector3.new(65, 65, 65),
			Ruta = {
				Vector3.new(65, 65, 65),
				Vector3.new(90, 65, 95),
				Vector3.new(55, 65, 125),
			},
		},
		{
			Nombre = "Policia_Patrulla_04",
			Titulo = "🚓 Patrullero 04\n(Avenida Media Central)",
			PosicionInicial = Vector3.new(0, 75, 205),
			Ruta = {
				Vector3.new(0, 75, 205),
				Vector3.new(-25, 77, 245),
				Vector3.new(0, 81, 285),
			},
		},
		{
			Nombre = "Policia_Patrulla_05",
			Titulo = "🚓 Patrullero 05\n(Ladera y Tienda 04)",
			PosicionInicial = Vector3.new(-45, 83, 295),
			Ruta = {
				Vector3.new(-45, 83, 295),
				Vector3.new(-20, 89, 345),
				Vector3.new(0, 94, 375),
			},
		},
		{
			Nombre = "Policia_Patrulla_06",
			Titulo = "🚓 Patrullero 06\n(Carretera Alta Internado)",
			PosicionInicial = Vector3.new(0, 99, 410),
			Ruta = {
				Vector3.new(0, 99, 410),
				Vector3.new(0, 108, 455),
				Vector3.new(12, 114, 480),
			},
		},
	}

	for _, pat in ipairs(listaPatrulleros) do
		local patrulleroExistente = folderPatrulleros:FindFirstChild(pat.Nombre)
		if patrulleroExistente then
			patrulleroExistente:Destroy()
		end

		local oficial = crearModeloPoliciaBase(
			pat.Nombre,
			pat.PosicionInicial,
			pat.Titulo,
			folderPatrulleros,
			true
		)

		-- Hilo de IA de patrullaje callejero y persecución por estrellas
		task.spawn(function()
			local hrp = oficial.PrimaryPart
			if not hrp then
				return
			end
			local bbg = oficial:FindFirstChildWhichIsA("BillboardGui", true)
			local lbl = bbg and bbg:FindFirstChildWhichIsA("TextLabel", true)
			local sirena = oficial:FindFirstChildWhichIsA("PointLight", true)

			local ruta = pat.Ruta
			local idxRuta = 1
			local cooldownsJugador: { [Player]: number } = {}
			local ultimoTick = os.clock()
			local tickSiren = 0

			while oficial.Parent do
				task.wait(0.2)
				local ahora = os.clock()
				local dt = ahora - ultimoTick
				ultimoTick = ahora

				-- 1. Si está aturdido por dulce o cauchera, pausar
				if oficial:GetAttribute("Aturdido") then
					continue
				end

				-- 2. Buscar si hay jugadores cercanos con estrellas de búsqueda o alto calor
				local jugadorObjetivo: Player? = nil
				local posObjetivo: Vector3? = nil
				local distanciaMinima = 35

				for _, player in ipairs(Players:GetPlayers()) do
					local cd = cooldownsJugador[player]
					if cd and ahora < cd then
						continue
					end

					local char = player.Character
					local pHrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
					if pHrp then
						local dist = (pHrp.Position - hrp.Position).Magnitude
						if dist <= distanciaMinima then
							-- Comprobar si el jugador está escondido en zona segura
							local estaEscondido = buscarEsconditeCercano(pHrp.Position)
							if not estaEscondido then
								local estrellas = GestorDatos.ObtenerEstrellas(player)
								local calor = GestorDatos.ObtenerPuntosCalor(player)

								if estrellas >= 1 or calor > 15 then
									local vecPlano = (pHrp.Position - hrp.Position) * Vector3.new(1, 0, 1)
									local dotVision = hrp.CFrame.LookVector:Dot(vecPlano.Unit)
									-- Cono de visión de patrulla: A más de 10 studs requiere estar en campo visual frontal
									local enVision = (dist < 10) or (dotVision > 0.15) or (estrellas >= 3)
									if enVision then
										distanciaMinima = dist
										jugadorObjetivo = player
										posObjetivo = pHrp.Position
									end
								end
							end
						end
					end
				end

				-- 3. Modo Persecución activa o Modo Patrulla callejera
				if jugadorObjetivo and posObjetivo then
					-- Modo Persecución: sirena titilante azul/roja
					tickSiren += dt
					if sirena then
						sirena.Color = if (math.floor(tickSiren * 6) % 2 == 0)
							then Color3.fromRGB(255, 40, 40)
							else Color3.fromRGB(40, 100, 255)
					end
					if lbl then
						lbl.Text = "🚨 ¡DETÉNGASE!\nPOLICÍA DENTAL"
						lbl.TextColor3 = Color3.fromRGB(255, 80, 80)
					end

					local dir = (posObjetivo - hrp.Position) * Vector3.new(1, 0, 1)
					local dist = dir.Magnitude

					if dist < 4.8 then
						-- ¡Intercepción en la calle!
						cooldownsJugador[jugadorObjetivo] = ahora + 7.0

						local estrellas = GestorDatos.ObtenerEstrellas(jugadorObjetivo)
						local reglaEstrella = Datos.Persecucion.Estrellas[estrellas]
							or Datos.Persecucion.Estrellas[1]
						local pct = reglaEstrella.PierdeCargaPorcentaje or 0.15
						local confiscados =
							GestorDatos.ConfiscarCargaPorcentaje(jugadorObjetivo, pct)

						local pito = Instance.new("Sound")
						pito.SoundId = "rbxasset://sounds/electronicpingshort.wav"
						pito.Volume = 0.9
						pito.Parent = hrp
						pito:Play()
						task.delay(1.5, function()
							pito:Destroy()
						end)

						if reglaEstrella.EnviaAlInternado then
							local condena = reglaEstrella.CondenaSegundos or 60
							local fianza = reglaEstrella.FianzaPesos or 50
							GestorDatos.EstablecerCondenaInternado(jugadorObjetivo, condena)

							local jChar = jugadorObjetivo.Character
							local jHrp = jChar
								and jChar:FindFirstChild("HumanoidRootPart") :: BasePart?
							if jHrp then
								jHrp.CFrame = CFrame.new(obtenerPuntoInternado())
							end

							EventosRemotos.EnviadoAlInternado:FireClient(jugadorObjetivo, {
								CondenaSegundos = condena,
								FianzaPesos = fianza,
								Estrellas = estrellas,
							})

							EventosRemotos.MostrarDialogoNPC:FireClient(jugadorObjetivo, {
								Nombre = pat.Nombre,
								Titulo = "🚨 ¡ARRESTO POLICIAL!",
								Icono = "🚔",
								Mensaje = string.format(
									"¡Quedas bajo arresto! Con %d estrellas no hay fianza en la calle. Se confiscan %d dulces y eres trasladado al Internado Sin Azúcar por %ds.",
									estrellas,
									confiscados,
									condena
								),
							})
						else
							EventosRemotos.MostrarDialogoNPC:FireClient(jugadorObjetivo, {
								Nombre = pat.Nombre,
								Titulo = "🚨 ¡INTERCEPTADO EN LA CALLE!",
								Icono = "🚓",
								Mensaje = string.format(
									"¡Quedas intervenido por la patrulla de la Policía Dental!\n\nSe te confiscan %d dulces por comercialización ilegal. ¡Dispersate inmediatamente!",
									confiscados
								),
							})
						end

						task.wait(2.0)
					else
						-- Avanzar persiguiendo al jugador a 13.5 studs/s
						local paso = dir.Unit * math.min(dist, 13.5 * dt)
						local nuevaPos = hrp.Position + paso
						local posSuelo = obtenerPosicionSuelo(nuevaPos, 3.0)
						hrp.CFrame = CFrame.lookAt(
							posSuelo,
							posSuelo + dir.Unit
						)
					end
				else
					-- Modo Patrulla callejera normal
					if sirena then
						sirena.Color = Color3.fromRGB(40, 100, 255)
					end
					if lbl then
						lbl.Text = pat.Titulo
						lbl.TextColor3 = Color3.fromRGB(200, 225, 255)
					end

					local metaPatrulla = ruta[idxRuta]
					local dirPatrulla = (metaPatrulla - hrp.Position) * Vector3.new(1, 0, 1)
					local distPatrulla = dirPatrulla.Magnitude

					if distPatrulla < 2.0 then
						idxRuta = (idxRuta % #ruta) + 1
						task.wait(2.5)
					else
						local paso = dirPatrulla.Unit * math.min(distPatrulla, 7.0 * dt)
						local nuevaPos = hrp.Position + paso
						local posSuelo = obtenerPosicionSuelo(nuevaPos, 3.0)
						hrp.CFrame = CFrame.lookAt(
							posSuelo,
							posSuelo + dirPatrulla.Unit
						)
					end
				end
			end
		end)
	end
end

local function configurarInteraccionesInternado()
	local mapa = Workspace:WaitForChild("Mapa", 10)
	if not mapa then
		return
	end
	local internado = mapa:WaitForChild("Zona_InternadoSinAzucar", 10)
	if not internado then
		return
	end

	local muela = internado:FindFirstChild("MuelaGigante")
	local promptMuela = muela and muela:FindFirstChild("PromptCepillar") :: ProximityPrompt?
	if promptMuela then
		promptMuela.Triggered:Connect(function(player: Player)
			if GestorDatos.EstaEnInternado(player) then
				local reduccion = Datos.Persecucion.Internado.ReduccionPorCepilladoSegundos or 20
				local restante = GestorDatos.ReducirCondenaInternado(player, reduccion)
				if restante <= 0 then
					local character = player.Character
					local hrp = character
						and character:FindFirstChild("HumanoidRootPart") :: BasePart?
					if hrp then
						hrp.CFrame = CFrame.new(obtenerPuntoSpawnSeguro())
					end
					EventosRemotos.LiberadoDelInternado:FireClient(player)
					print(
						string.format(
							"El Patrón del Dulce: %s completó su condena y fue liberado.",
							player.Name
						)
					)
				end
			end
		end)
	end

	local enfermero = internado:FindFirstChild("EnfermeroDental")
	local promptFianza = enfermero and enfermero:FindFirstChild("PromptFianza") :: ProximityPrompt?
	if promptFianza then
		promptFianza.Triggered:Connect(function(player: Player)
			if GestorDatos.EstaEnInternado(player) then
				local exito, msg = GestorDatos.PagarFianza(player)
				if exito then
					local character = player.Character
					local hrp = character
						and character:FindFirstChild("HumanoidRootPart") :: BasePart?
					if hrp then
						hrp.CFrame = CFrame.new(obtenerPuntoSpawnSeguro())
					end
					EventosRemotos.LiberadoDelInternado:FireClient(player)
					print(
						string.format(
							"El Patrón del Dulce: %s pagó fianza y fue liberado.",
							player.Name
						)
					)
				else
					EventosRemotos.AlertaPolicia:FireClient(player, msg, 0)
				end
			end
		end)
	end
end

local intervaloChequeo = 0.5
local acumuladorTiempo = 0

RunService.Heartbeat:Connect(function(dt: number)
	acumuladorTiempo += dt
	if acumuladorTiempo < intervaloChequeo then
		return
	end
	local dtEfectivo = acumuladorTiempo
	acumuladorTiempo = 0

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if not character then
			continue
		end
		local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then
			continue
		end

		if not estadosPersecucion[player] then
			estadosPersecucion[player] = {
				TiempoEnEscondite = 0,
				Enfriando = false,
				UltimaNotificacionReten = 0,
				UltimoTickSegundo = os.clock(),
			}
		end

		local estado = estadosPersecucion[player]

		-- A. Manejo de Condena en el Internado Sin Azúcar
		if GestorDatos.EstaEnInternado(player) then
			local restante = GestorDatos.ReducirCondenaInternado(player, dtEfectivo)
			if restante <= 0 then
				hrp.CFrame = CFrame.new(obtenerPuntoSpawnSeguro())
				EventosRemotos.LiberadoDelInternado:FireClient(player)
				print(
					string.format(
						"El Patrón del Dulce: %s cumplió su tiempo de condena y salió libre.",
						player.Name
					)
				)
			end
			continue
		end

		local puntosCalor = GestorDatos.ObtenerPuntosCalor(player)
		local estrellas = GestorDatos.ObtenerEstrellas(player)

		-- B. Enfriamiento en Escondites (-15 pts/s) vs Enfriamiento en Calle (-3 pts/s)
		local estaEscondido = buscarEsconditeCercano(hrp.Position)
		local cercaReten, retenPart = buscarRetenCercano(hrp.Position)

		if estaEscondido and puntosCalor > 0 then
			estado.Enfriando = true
			local tasaEscondite = Datos.Persecucion.TasaEnfriamiento.Escondite or 15
			local ptsAEnfriar = tasaEscondite * dtEfectivo
			local nuevosPuntos, nuevasEstrellas = GestorDatos.EnfriarCalor(player, ptsAEnfriar)

			local progreso = 0
			if nuevasEstrellas > 0 then
				local conf = Datos.Persecucion.Estrellas[nuevasEstrellas]
				if conf then
					progreso = math.clamp(nuevosPuntos / conf.UmbralPuntos, 0, 1)
				end
			end

			EventosRemotos.EstrellasActualizadas:FireClient(player, {
				Estrellas = nuevasEstrellas,
				Enfriando = true,
				ProgresoEnfriamiento = progreso,
				PuntosCalor = nuevosPuntos,
			})
		elseif (not cercaReten) and puntosCalor > 0 then
			-- Enfriamiento pasivo en calle (-3 pts/s)
			local tasaCalle = Datos.Persecucion.TasaEnfriamiento.Calle or 3
			local ptsAEnfriar = tasaCalle * dtEfectivo
			local nuevosPuntos, nuevasEstrellas = GestorDatos.EnfriarCalor(player, ptsAEnfriar)

			EventosRemotos.EstrellasActualizadas:FireClient(player, {
				Estrellas = nuevasEstrellas,
				Enfriando = false,
				ProgresoEnfriamiento = 0,
				PuntosCalor = nuevosPuntos,
			})
		else
			if estado.Enfriando then
				estado.Enfriando = false
				EventosRemotos.EstrellasActualizadas:FireClient(player, {
					Estrellas = estrellas,
					Enfriando = false,
					ProgresoEnfriamiento = 0,
					PuntosCalor = puntosCalor,
				})
			end
		end

		-- Disparo dinámico de Redada si las estrellas alcanzan nivel 4 o 5
		if estrellas >= 4 and not redadaEnCurso and iniciarRedadaDental then
			task.spawn(iniciarRedadaDental)
		end

		-- C. Intercepción en Retenes Policiales
		if estrellas >= 1 and cercaReten and retenPart then
			local mapa = Workspace:FindFirstChild("Mapa")
			local npcs = mapa
				and mapa:FindFirstChild("Decoracion")
				and mapa.Decoracion:FindFirstChild("NPCs_Interactivos")
			local agente = npcs and npcs:FindFirstChild("Personaje_AgenteDental")
			local estaAturdido = (agente and agente:GetAttribute("Aturdido") == true)
				or (retenPart:GetAttribute("Aturdido") == true)

			if not estaAturdido then
				local ahora = os.clock()
				if ahora - estado.UltimaNotificacionReten > 25 then
					estado.UltimaNotificacionReten = ahora

					local reglaEstrella = Datos.Persecucion.Estrellas[estrellas]
						or Datos.Persecucion.Estrellas[1]
					local pctConfiscacion = reglaEstrella.PierdeCargaPorcentaje or 0.10
					local confiscados =
						GestorDatos.ConfiscarCargaPorcentaje(player, pctConfiscacion)

					if reglaEstrella.EnviaAlInternado then
						-- Arresto completo y envío al Internado Sin Azúcar
						local condena = reglaEstrella.CondenaSegundos or 60
						local fianza = reglaEstrella.FianzaPesos or 50
						GestorDatos.EstablecerCondenaInternado(player, condena)

						hrp.CFrame = CFrame.new(obtenerPuntoInternado())

						EventosRemotos.EnviadoAlInternado:FireClient(player, {
							CondenaSegundos = condena,
							FianzaPesos = fianza,
							Estrellas = estrellas,
						})
						if confiscados > 0 then
							EventosRemotos.CargaConfiscada:FireClient(player, confiscados)
						end

						print(
							string.format(
								"El Patrón del Dulce: ¡%s fue arrestado en el retén con %d estrellas! Confiscados: %d dulces. Enviado al Internado por %ds (Fianza: $%d)",
								player.Name,
								estrellas,
								confiscados,
								condena,
								fianza
							)
						)
					else
						-- Advertencia y confiscación parcial (Estrellas 1 o 2) - Notificación efímera en banner sin popup modal
						if confiscados > 0 then
							EventosRemotos.CargaConfiscada:FireClient(player, confiscados)
						else
							EventosRemotos.AlertaPolicia:FireClient(
								player,
								"👮 Retén de la Policía Dental: ¡Circule con precaución!",
								estrellas
							)
						end
					end
				end
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	estadosPersecucion[player] = nil
end)

-- ====================================================================
-- SISTEMA DE OLEADAS Y REDADAS DENTALES (OPERATIVO CERO AZÚCAR)
-- ====================================================================
iniciarRedadaDental = function()
	if redadaEnCurso then
		return
	end
	redadaEnCurso = true

	local mapa = Workspace:FindFirstChild("Mapa")
	local decoracion = mapa and mapa:FindFirstChild("Decoracion")
	local policiasFolder = decoracion and decoracion:FindFirstChild("PoliciasDentales")
	if not policiasFolder then
		redadaEnCurso = false
		return
	end

	local folderChoque = policiasFolder:FindFirstChild("FuerzasEspeciales")
	if folderChoque then
		folderChoque:Destroy()
	end
	folderChoque = Instance.new("Folder")
	folderChoque.Name = "FuerzasEspeciales"
	folderChoque.Parent = policiasFolder

	-- Notificar inicio de redada a todos los clientes (Banner efímero de emergencia con sirena)
	EventosRemotos.RedadaIniciada:FireAllClients()

	-- Despliegue de 4 Oficiales de Fuerzas Especiales Antidisturbios
	local puntosAparicionChoque = {
		Vector3.new(-60, 65, -30),
		Vector3.new(10, 68, 80),
		Vector3.new(-30, 75, 230),
		Vector3.new(10, 95, 360),
	}

	for i, spawnPos in ipairs(puntosAparicionChoque) do
		local nombreOficial = "Policia_Choque_" .. i
		local modelo = Instance.new("Model")
		modelo.Name = nombreOficial
		modelo.Parent = folderChoque

		local hrp = Instance.new("Part")
		hrp.Name = "HumanoidRootPart"
		hrp.Size = Vector3.new(2, 2, 1)
		hrp.Position = spawnPos
		hrp.Transparency = 1
		hrp.CanCollide = false
		hrp.Anchored = true
		hrp.Parent = modelo
		modelo.PrimaryPart = hrp

		local torso = Instance.new("Part")
		torso.Name = "Torso"
		torso.Size = Vector3.new(2.2, 2.2, 1.2)
		torso.Position = hrp.Position
		torso.Color = Color3.fromRGB(15, 20, 30)
		torso.Material = Enum.Material.Metal
		torso.Anchored = true
		torso.CanCollide = true
		torso.Parent = modelo

		local cabeza = Instance.new("Part")
		cabeza.Name = "Head"
		cabeza.Size = Vector3.new(1.2, 1.2, 1.2)
		cabeza.Position = torso.Position + Vector3.new(0, 1.7, 0)
		cabeza.Color = Color3.fromRGB(220, 185, 150)
		cabeza.Material = Enum.Material.SmoothPlastic
		cabeza.Anchored = true
		cabeza.CanCollide = false
		cabeza.Parent = modelo

		-- Casco táctico antimotines
		local casco = Instance.new("Part")
		casco.Name = "CascoAntimotines"
		casco.Size = Vector3.new(1.4, 0.9, 1.4)
		casco.Position = cabeza.Position + Vector3.new(0, 0.45, 0)
		casco.Color = Color3.fromRGB(25, 30, 40)
		casco.Material = Enum.Material.Metal
		casco.Anchored = true
		casco.CanCollide = false
		casco.Parent = modelo

		local visor = Instance.new("Part")
		visor.Name = "Visor"
		visor.Size = Vector3.new(1.1, 0.4, 0.3)
		visor.Position = casco.Position + Vector3.new(0, -0.2, -0.65)
		visor.Color = Color3.fromRGB(80, 200, 255)
		visor.Material = Enum.Material.Neon
		visor.Transparency = 0.3
		visor.Anchored = true
		visor.CanCollide = false
		visor.Parent = modelo

		-- Escudo antidisturbios en mano izquierda
		local escudo = Instance.new("Part")
		escudo.Name = "EscudoDental"
		escudo.Size = Vector3.new(0.3, 3.8, 2.2)
		escudo.Position = torso.Position + Vector3.new(-1.6, 0, -0.4)
		escudo.Color = Color3.fromRGB(30, 40, 55)
		escudo.Material = Enum.Material.Metal
		escudo.Anchored = true
		escudo.CanCollide = false
		escudo.Parent = modelo

		-- Bastón eléctrico dental en mano derecha
		local baston = Instance.new("Part")
		baston.Name = "BastonElectrico"
		baston.Size = Vector3.new(0.3, 2.6, 0.3)
		baston.Position = torso.Position + Vector3.new(1.6, 0, -0.4)
		baston.Color = Color3.fromRGB(60, 180, 255)
		baston.Material = Enum.Material.Neon
		baston.Anchored = true
		baston.CanCollide = false
		baston.Parent = modelo

		local luzBaston = Instance.new("PointLight")
		luzBaston.Name = "ChispaElectrica"
		luzBaston.Color = Color3.fromRGB(60, 200, 255)
		luzBaston.Brightness = 3
		luzBaston.Range = 16
		luzBaston.Parent = baston

		local piernas = Instance.new("Part")
		piernas.Name = "Piernas"
		piernas.Size = Vector3.new(1.8, 2, 0.9)
		piernas.Position = torso.Position + Vector3.new(0, -2, 0)
		piernas.Color = Color3.fromRGB(15, 20, 28)
		piernas.Material = Enum.Material.SmoothPlastic
		piernas.Anchored = true
		piernas.CanCollide = true
		piernas.Parent = modelo

		local bbg = Instance.new("BillboardGui")
		bbg.Name = "RotuloChoque"
		bbg.Size = UDim2.fromOffset(230, 48)
		bbg.StudsOffset = Vector3.new(0, 3.4, 0)
		bbg.AlwaysOnTop = true
		bbg.MaxDistance = 50
		bbg.Parent = cabeza

		local lbl = Instance.new("TextLabel")
		lbl.Name = "Texto"
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.FredokaOne
		lbl.Text = "🚨 FUERZAS ESPECIALES\n(Operativo Cero Azúcar)"
		lbl.TextColor3 = Color3.fromRGB(255, 60, 60)
		lbl.TextSize = 13
		lbl.Parent = bbg

		-- IA de persecución y ataque del oficial antidisturbios
		task.spawn(function()
			local cooldownAtaque: { [Player]: number } = {}
			local ultimoTick = os.clock()

			while modelo.Parent and redadaEnCurso do
				task.wait(0.2)
				local ahora = os.clock()
				local dt = ahora - ultimoTick
				ultimoTick = ahora

				if modelo:GetAttribute("Aturdido") then
					continue
				end

				-- Buscar al jugador más cercano fuera de escondite
				local jugadorObjetivo: Player? = nil
				local posObjetivo: Vector3? = nil
				local distMin = 45

				for _, player in ipairs(Players:GetPlayers()) do
					local char = player.Character
					local pHrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					if pHrp and hum and hum.Health > 0 then
						local dist = (pHrp.Position - hrp.Position).Magnitude
						if dist <= distMin then
							local estaEscondido = buscarEsconditeCercano(pHrp.Position)
							if not estaEscondido then
								distMin = dist
								jugadorObjetivo = player
								posObjetivo = pHrp.Position
							end
						end
					end
				end

				if jugadorObjetivo and posObjetivo then
					local dir = (posObjetivo - hrp.Position) * Vector3.new(1, 0, 1)
					local dist = dir.Magnitude

					if dist < 4.8 then
						-- ¡ATAQUE DE LA FUERZA ESPECIAL!
						local cd = cooldownAtaque[jugadorObjetivo] or 0
						if ahora >= cd then
							cooldownAtaque[jugadorObjetivo] = ahora + 1.2
							local char = jugadorObjetivo.Character
							local hum = char and char:FindFirstChildOfClass("Humanoid")

							if hum and hum.Health > 0 then
								local sonidoGolpe = Instance.new("Sound")
								sonidoGolpe.SoundId = "rbxasset://sounds/uuhhh.mp3"
								sonidoGolpe.Volume = 0.9
								sonidoGolpe.Parent = hrp
								sonidoGolpe:Play()
								task.delay(1.5, function()
									sonidoGolpe:Destroy()
								end)

								hum:TakeDamage(25)

								if hum.Health <= 0 then
									-- ¡DERROTA DEL JUGADOR!
									local perdidos = GestorDatos.VaciarCargaDulces(jugadorObjetivo)
									EventosRemotos.MostrarDialogoNPC:FireClient(jugadorObjetivo, {
										Nombre = "Enfermería Municipal",
										Titulo = "💀 ¡DERROTADO EN LA REDADA DENTAL!",
										Icono = "🚑",
										Mensaje = string.format(
											"¡Caíste ante las Fuerzas Especiales de la Policía Dental!\n\nTe decomisaron %d dulces de tu cargamento. Fuiste atendido en la enfermería municipal.",
											perdidos
										),
									})
								end
							end
						end
					else
						-- Carrera rápida de asalto a 14.5 studs/s
						local paso = dir.Unit * math.min(dist, 14.5 * dt)
						local nuevaPos = hrp.Position + paso
						local lookTarget = nuevaPos + dir.Unit
						modelo:PivotTo(
							CFrame.lookAt(
								nuevaPos,
								Vector3.new(lookTarget.X, nuevaPos.Y, lookTarget.Z)
							)
						)
					end
				end
			end
		end)
	end

	-- Duración de la Redada: 45 segundos
	task.delay(45, function()
		redadaEnCurso = false
		if folderChoque and folderChoque.Parent then
			folderChoque:Destroy()
		end

		EventosRemotos.RedadaTerminada:FireAllClients()

		-- Premiar a los jugadores que sobrevivieron
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				GestorDatos.AgregarPesos(player, 50)
				local datos = GestorDatos.ObtenerDatos(player)
				if datos then
					datos.Fama += 5
				end

				EventosRemotos.MostrarDialogoNPC:FireClient(player, {
					Nombre = "Doña Melcocha",
					Titulo = "🎉 ¡BURLASTE LA REDADA DENTAL!",
					Icono = "👵",
					Mensaje = "¡Eso mijo! Sobreviviste al operativo del Alcalde Apio sin que te atraparan. ¡Toma $50 pesos dulces y +5 de Fama como premio!",
				})
			end
		end

		print("El Patrón del Dulce: Redada Dental finalizada con éxito")
	end)
end

-- Ciclo periódico de Redadas Dentales (Cada 210 segundos / 3.5 minutos)
task.spawn(function()
	while true do
		task.wait(210)
		iniciarRedadaDental()
	end
end)

task.spawn(configurarEscondites)
task.spawn(configurar12PoliciasDentales)
task.spawn(configurarInteraccionesInternado)
print("El Patrón del Dulce: Sistema de Persecución, 12 Policías y Redadas inicializado")
