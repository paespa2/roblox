--!strict
--[[
    SistemaMisionFincas.server.luau
    NPCs de Misión en las afueras de Ciudad_Cuadricula (Salida Norte hacia Fincas)
    para desbloquear y comenzar el Tycoon de las Fincas Exteriores.

    El Patrón del Dulce
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GestorDatos = require(script.Parent.GestorDatos)
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)
local ConstructorR6 = require(ReplicatedStorage.Shared.ConstructorR6)

local COSTO_ESCRITURA_FINCA = 200
local FAMA_REQUERIDA_FINCA = 10

local bonoRecibido: { [number]: boolean } = {}
local misionActiva: { [number]: boolean } = {}

local function crearParte(
	nombre: string,
	tamano: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material,
	padre: Instance,
	canCollide: boolean?
): Part
	local p = Instance.new("Part")
	p.Name = nombre
	p.Size = tamano
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.CanCollide = if canCollide ~= nil then canCollide else true
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = padre
	return p
end

local function construirArcoSalidaFincas(parent: Instance)
	local arco = Instance.new("Model")
	arco.Name = "PortalFincasExteriores"
	arco.Parent = parent

	local zArco = -355
	local yBase = 60.3

	for _, sx in ipairs({ -11.5, 11.5 }) do
		crearParte(
			"BasePiedra",
			Vector3.new(2.8, 4.0, 2.8),
			CFrame.new(sx, yBase + 2.0, zArco),
			Color3.fromRGB(130, 128, 120),
			Enum.Material.Cobblestone,
			arco,
			true
		)
		crearParte(
			"PilarMadera",
			Vector3.new(1.4, 14.0, 1.4),
			CFrame.new(sx, yBase + 10.0, zArco),
			Color3.fromRGB(116, 73, 43),
			Enum.Material.WoodPlanks,
			arco,
			true
		)
	end

	crearParte(
		"VigaSuperior",
		Vector3.new(25.5, 1.4, 1.8),
		CFrame.new(0, yBase + 16.5, zArco),
		Color3.fromRGB(116, 73, 43),
		Enum.Material.WoodPlanks,
		arco,
		false
	)
	local letrero = crearParte(
		"LetreroPortal",
		Vector3.new(20.0, 3.8, 0.6),
		CFrame.new(0, yBase + 18.8, zArco),
		Color3.fromRGB(40, 115, 55),
		Enum.Material.SmoothPlastic,
		arco,
		false
	)

	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.CanvasSize = Vector2.new(640, 128)
		gui.Parent = letrero

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(0.96, 0.9)
		lbl.Position = UDim2.fromScale(0.02, 0.05)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.FredokaOne
		lbl.Text = "🌾 ZONA DE FINCAS TYCOON • VILLA ALMÍBAR 🌾"
		lbl.TextColor3 = Color3.fromRGB(255, 240, 180)
		lbl.TextScaled = true
		lbl.Parent = gui
	end

	crearParte(
		"PisoCasetaFincas",
		Vector3.new(10, 0.5, 10),
		CFrame.new(-18, yBase + 0.25, -365),
		Color3.fromRGB(175, 165, 145),
		Enum.Material.Cobblestone,
		arco,
		true
	)
	crearParte(
		"EscritorioRegistro",
		Vector3.new(5.5, 2.8, 2.2),
		CFrame.new(-15.5, yBase + 1.6, -365),
		Color3.fromRGB(125, 80, 45),
		Enum.Material.Wood,
		arco,
		true
	)
	crearParte(
		"TechoCasetaFincas",
		Vector3.new(11, 0.8, 11),
		CFrame.new(-18, yBase + 9.5, -365),
		Color3.fromRGB(165, 65, 45),
		Enum.Material.Slate,
		arco,
		false
	)
	for _, ox in ipairs({ -4.5, 4.5 }) do
		for _, oz in ipairs({ -4.5, 4.5 }) do
			crearParte(
				"PosteCaseta",
				Vector3.new(0.5, 9.0, 0.5),
				CFrame.new(-18 + ox, yBase + 4.8, -365 + oz),
				Color3.fromRGB(95, 60, 35),
				Enum.Material.Wood,
				arco,
				true
			)
		end
	end
end

local function crearNPCMision(parent: Instance, info: any): ProximityPrompt
	local rig = ConstructorR6.CrearManiquiR6({
		Nombre = info.Nombre,
		Posicion = info.Posicion,
		RotacionY = info.RotY,
		ColorRopa = info.ColorRopa,
		ColorPantalon = info.ColorPantalon,
		SombreroColor = info.ColorSombrero,
		Expresion = "Alegre",
		Parent = parent,
	})
	rig.SetMoving(false)

	local bbg = Instance.new("BillboardGui")
	bbg.Name = "RotuloNPCFincas"
	bbg.Size = UDim2.fromOffset(250, 58)
	bbg.StudsOffset = Vector3.new(0, 3.6, 0)
	bbg.AlwaysOnTop = false
	bbg.MaxDistance = 70
	bbg.Parent = rig.Head

	local fondo = Instance.new("Frame")
	fondo.Size = UDim2.fromScale(1, 1)
	fondo.BackgroundColor3 = Color3.fromRGB(24, 34, 28)
	fondo.BackgroundTransparency = 0.15
	fondo.Parent = bbg
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = fondo

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(240, 195, 55)
	stroke.Thickness = 2
	stroke.Parent = fondo

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(0.95, 0.9)
	lbl.Position = UDim2.fromScale(0.025, 0.05)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.FredokaOne
	lbl.Text = info.Apodo .. "\n" .. info.Subtitulo
	lbl.TextColor3 = Color3.fromRGB(255, 240, 195)
	lbl.TextScaled = true
	lbl.Parent = fondo

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PromptMisionFinca"
	prompt.ObjectText = info.Apodo
	prompt.ActionText = info.ActionText
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = rig.Torso
	return prompt
end

local function obtenerDestinoFincaExterior(): Vector3
	local tycoon = Workspace:FindFirstChild("Tycoon Map 1")
	if tycoon and tycoon:IsA("Model") then
		local cf, sz = tycoon:GetBoundingBox()
		return Vector3.new(cf.X, cf.Y + sz.Y * 0.25 + 12, cf.Z + sz.Z * 0.35)
	end
	return Vector3.new(0, 65, -700)
end

local function inicializarMisionFincas()
	local mapa = Workspace:WaitForChild("Mapa", 10)
	if not mapa then
		return
	end

	local existente = mapa:FindFirstChild("Zona_MisionFincas")
	if existente then
		existente:Destroy()
	end

	local carpeta = Instance.new("Folder")
	carpeta.Name = "Zona_MisionFincas"
	carpeta.Parent = mapa

	construirArcoSalidaFincas(carpeta)

	local promptEfrain = crearNPCMision(carpeta, {
		Nombre = "NPC_DonEfrain_Fincas",
		Apodo = "🌾 Don Efraín (Comisionado)",
		Subtitulo = "Misión: Desbloquear Tycoon de Fincas",
		Posicion = Vector3.new(-13.5, 60.3, -365),
		RotY = 90,
		ColorRopa = Color3.fromRGB(235, 228, 210),
		ColorPantalon = Color3.fromRGB(55, 65, 85),
		ColorSombrero = Color3.fromRGB(240, 232, 200),
		ActionText = "Hablar • Misión Finca Tycoon",
	})

	promptEfrain.Triggered:Connect(function(player: Player)
		local datos = GestorDatos.ObtenerDatos(player)
		local yaDesbloqueada = player:GetAttribute("FincaTycoonDesbloqueada") == true

		if yaDesbloqueada then
			EventosRemotos.MostrarDialogoNPC:FireClient(player, {
				Nombre = "Don Efraín",
				Titulo = "Escritura de Finca Activa ✅",
				Icono = "🌾",
				Mensaje = "¡Ya eres propietario oficial de tu Finca Tycoon! Avanza al norte por esta carretera y habla con el Capataz Ramiro para ir directo a tus tierras.",
			})
			return
		end

		local pesos = if datos then (datos.PesosDulces or 0) else 0
		local fama = if datos then (datos.Fama or 0) else 0

		if
			not misionActiva[player.UserId]
			and pesos < COSTO_ESCRITURA_FINCA
			and fama < FAMA_REQUERIDA_FINCA
		then
			misionActiva[player.UserId] = true
			EventosRemotos.MostrarDialogoNPC:FireClient(player, {
				Nombre = "Don Efraín",
				Titulo = "📜 Nueva Misión: Tu Primera Finca",
				Icono = "🌾",
				Mensaje = string.format(
					"¡Bienvenido a las afueras del valle! Para desbloquear tu Finca Tycoon reúne $%d Pesos Dulces o %d de Fama vendiendo en las tiendas de la cuadrícula. (Tienes: $%d | Fama: %d)",
					COSTO_ESCRITURA_FINCA,
					FAMA_REQUERIDA_FINCA,
					pesos,
					fama
				),
			})
			return
		end

		if pesos >= COSTO_ESCRITURA_FINCA or fama >= FAMA_REQUERIDA_FINCA then
			if datos and pesos >= COSTO_ESCRITURA_FINCA then
				GestorDatos.AgregarPesos(player, -COSTO_ESCRITURA_FINCA)
			end
			player:SetAttribute("FincaTycoonDesbloqueada", true)
			misionActiva[player.UserId] = false

			EventosRemotos.MostrarDialogoNPC:FireClient(player, {
				Nombre = "Don Efraín",
				Titulo = "🎉 ¡FINCA TYCOON DESBLOQUEADA!",
				Icono = "🏡",
				Mensaje = "¡Felicitaciones patrón! Has recibido las escrituras de tu Finca Exterior. Sigue hacia el norte hasta el Capataz Ramiro para empezar a construir tu imperio dulcero.",
			})
		else
			EventosRemotos.MostrarDialogoNPC:FireClient(player, {
				Nombre = "Don Efraín",
				Titulo = "Misión en Progreso 📜",
				Icono = "🌾",
				Mensaje = string.format(
					"Te falta poco para la escritura de la finca: necesitas $%d Pesos Dulces o %d de Fama. Actualmente llevas $%d Pesos y %d Fama.",
					COSTO_ESCRITURA_FINCA,
					FAMA_REQUERIDA_FINCA,
					pesos,
					fama
				),
			})
		end
	end)

	local promptCarmenza = crearNPCMision(carpeta, {
		Nombre = "NPC_DonaCarmenza_Agronoma",
		Apodo = "🌱 Doña Carmenza (Agrónoma)",
		Subtitulo = "Guía de Cultivos y Fincas",
		Posicion = Vector3.new(13.5, 60.3, -365),
		RotY = -90,
		ColorRopa = Color3.fromRGB(65, 145, 90),
		ColorPantalon = Color3.fromRGB(65, 50, 40),
		ColorSombrero = Color3.fromRGB(215, 190, 130),
		ActionText = "Pedir Consejo de Fincas",
	})

	promptCarmenza.Triggered:Connect(function(player: Player)
		if not bonoRecibido[player.UserId] then
			bonoRecibido[player.UserId] = true
			GestorDatos.AgregarPesos(player, 25)
			EventosRemotos.MostrarDialogoNPC:FireClient(player, {
				Nombre = "Doña Carmenza",
				Titulo = "Bono Agrícola (+$25 Pesos) 🌱",
				Icono = "🌱",
				Mensaje = "¡Hola emprendedor! Afuera de las cordilleras están las tierras fértiles de las Fincas Tycoon. Toma $25 Pesos Dulces de apoyo para ayudarte a completar la misión de Don Efraín.",
			})
		else
			EventosRemotos.MostrarDialogoNPC:FireClient(player, {
				Nombre = "Doña Carmenza",
				Titulo = "Producción de Fincas 🌱",
				Icono = "🌱",
				Mensaje = "Cuando Don Efraín te entregue la escritura, podrás expandir cañaduzales y trapiches en las fincas exteriores para multiplicar tus ganancias.",
			})
		end
	end)

	local promptRamiro = crearNPCMision(carpeta, {
		Nombre = "NPC_CapatazRamiro_Fincas",
		Apodo = "🚜 Capataz Ramiro",
		Subtitulo = "Acceso Directo a Fincas Tycoon",
		Posicion = Vector3.new(-13.5, 60.3, -685),
		RotY = 90,
		ColorRopa = Color3.fromRGB(185, 95, 45),
		ColorPantalon = Color3.fromRGB(45, 50, 60),
		ColorSombrero = Color3.fromRGB(165, 120, 70),
		ActionText = "Ir a la Zona de Fincas",
	})

	promptRamiro.Triggered:Connect(function(player: Player)
		if player:GetAttribute("FincaTycoonDesbloqueada") ~= true then
			EventosRemotos.MostrarDialogoNPC:FireClient(player, {
				Nombre = "Capataz Ramiro",
				Titulo = "Acceso Restringido a Propietarios 🚧",
				Icono = "🚜",
				Mensaje = "¡Quieto ahí patrón! Primero habla con Don Efraín en el portal de salida de la ciudad para completar la misión y obtener tu escritura de Finca Tycoon.",
			})
			return
		end

		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			local destino = obtenerDestinoFincaExterior()
			hrp.CFrame = CFrame.new(destino)
			EventosRemotos.MostrarDialogoNPC:FireClient(player, {
				Nombre = "Capataz Ramiro",
				Titulo = "¡Bienvenido a tu Finca Tycoon! 🏡",
				Icono = "🚜",
				Mensaje = "¡Llegamos a las fincas exteriores! Aquí comienza tu imperio fuera de las cordilleras.",
			})
		end
	end)

	local ext = mapa:FindFirstChild("ZonasExterioresCordillera")
	local armeria = ext and ext:FindFirstChild("Zona_ArmeriaApocalipsis")
	local mostrador = armeria and armeria:FindFirstChild("MostradorArmeria")
	if mostrador and mostrador:IsA("BasePart") then
		local pArm = mostrador:FindFirstChildOfClass("ProximityPrompt")
		if not pArm then
			pArm = Instance.new("ProximityPrompt")
			pArm.Name = "PromptArmeriaApocalipsis"
			pArm.ObjectText = "☢️ Armería del Apocalipsis"
			pArm.ActionText = "Abrir Catálogo de Armas"
			pArm.HoldDuration = 0.25
			pArm.MaxActivationDistance = 14
			pArm.RequiresLineOfSight = false
			pArm.Parent = mostrador
		end
		pArm.Triggered:Connect(function(player: Player)
			EventosRemotos.MostrarDialogoNPC:FireClient(player, {
				Nombre = "Sargento Caramelo",
				Titulo = "☢️ Armería del Apocalipsis",
				Icono = "🔫",
				Mensaje = "¡Bienvenido al búnker clandestino! Aquí consigues el armamento pesado para defender tu imperio y sobrevivir a las hordas zombi.",
			})
			EventosRemotos.AbrirTiendaMejoras:FireClient(player, "Armas")
		end)
	end

	print(
		"El Patrón del Dulce: Portal y NPCs de Misión de Fincas Exteriores (Don Efraín, Doña Carmenza, Capataz Ramiro) inicializados."
	)
end

task.spawn(inicializarMisionFincas)
