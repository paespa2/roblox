local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GestorDatos = require(script.Parent.GestorDatos)
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)

local function soldar(p0: BasePart, p1: BasePart)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.Parent = p0
end

local function configurarFisicaVehiculoConducible(
	modelo: Model,
	chasis: BasePart,
	asiento: VehicleSeat,
	nombreVehiculo: string
)
	asiento.CanCollide = false
	asiento.MaxSpeed = 0
	asiento.Torque = 0
	asiento.TurnSpeed = 0

	-- Propiedades físicas idénticas a la bicicleta (centro de gravedad bajo y adherencia equilibrada)
	chasis.CustomPhysicalProperties = PhysicalProperties.new(1.0, 0.1, 0, 1, 1)

	-- Contrapeso inferior anti-vuelcos (idéntico a la bicicleta, evita giros de cabeza)
	local contrapeso = chasis:FindFirstChild("ContrapesoBajo") :: BasePart?
	if not contrapeso then
		contrapeso = Instance.new("Part")
		contrapeso.Name = "ContrapesoBajo"
		contrapeso.Size = Vector3.new(math.max(chasis.Size.X * 0.7, 1.4), 0.4, math.max(chasis.Size.Z * 0.7, 2.6))
		contrapeso.CFrame = chasis.CFrame * CFrame.new(0, -chasis.Size.Y * 0.55, 0)
		contrapeso.Transparency = 1
		contrapeso.CanCollide = false
		contrapeso.Massless = false
		contrapeso.CustomPhysicalProperties = PhysicalProperties.new(4.0, 0.1, 0, 1, 1)
		contrapeso.Parent = chasis

		soldar(chasis, contrapeso)
	end

	for _, part in ipairs(modelo:GetDescendants()) do
		if part:IsA("BasePart") and part ~= chasis and part ~= contrapeso then
			part.Massless = true
			part.Anchored = false
		end
	end

	local driveAtt = chasis:FindFirstChild("DriveAtt") :: Attachment?
	if not driveAtt then
		driveAtt = Instance.new("Attachment")
		driveAtt.Name = "DriveAtt"
		driveAtt.Parent = chasis
	end

	local driveLV = chasis:FindFirstChild("DriveLV") :: LinearVelocity?
	if not driveLV then
		driveLV = Instance.new("LinearVelocity")
		driveLV.Name = "DriveLV"
		driveLV.Attachment0 = driveAtt
		driveLV.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
		driveLV.ForceLimitsEnabled = true
		driveLV.MaxAxesForce = Vector3.new(0, 0, 45000)
		driveLV.VectorVelocity = Vector3.zero
		driveLV.Parent = chasis
	end

	local steerAV = chasis:FindFirstChild("SteerAV") :: AngularVelocity?
	if not steerAV then
		steerAV = Instance.new("AngularVelocity")
		steerAV.Name = "SteerAV"
		steerAV.Attachment0 = driveAtt
		steerAV.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
		steerAV.MaxTorque = 80000
		steerAV.AngularVelocity = Vector3.zero
		steerAV.Parent = chasis
	end

	local ao = chasis:FindFirstChild("EstabilizadorVertical") :: AlignOrientation?
	if not ao then
		ao = Instance.new("AlignOrientation")
		ao.Name = "EstabilizadorVertical"
		ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
		ao.Attachment0 = driveAtt
		ao.AlignType = Enum.AlignType.PrimaryAxisParallel
		ao.PrimaryAxis = Vector3.new(0, 1, 0)
		ao.MaxTorque = 60000
		ao.Responsiveness = 35
		ao.ReactionTorqueEnabled = false
		ao.Parent = chasis
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PromptConducir"
	prompt.ObjectText = nombreVehiculo
	prompt.ActionText = "Conducir " .. nombreVehiculo
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = chasis

	prompt.Triggered:Connect(function(player: Player)
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and not asiento.Occupant then
			asiento:Sit(hum)
		end
	end)

	asiento:GetPropertyChangedSignal("Occupant"):Connect(function()
		local occ = asiento.Occupant
		if occ then
			local player = Players:GetPlayerFromCharacter(occ.Parent)
			if player then
				pcall(function()
					for _, part in ipairs(modelo:GetDescendants()) do
						if part:IsA("BasePart") then
							part:SetNetworkOwner(player)
						end
					end
				end)
			end
			chasis.Anchored = false
		else
			chasis.Anchored = true
			pcall(function()
				for _, part in ipairs(modelo:GetDescendants()) do
					if part:IsA("BasePart") then
						part:SetNetworkOwner(nil)
					end
				end
			end)
		end
	end)
end

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
-- 2. VEHÍCULOS ESTACIONADOS Y CONDUCIBLES: TAXI, CAMPERO Y MOTO REPARTOS
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
	cabina.Anchored = false
	cabina.CanCollide = true
	cabina.Parent = modelo
	soldar(chasis, cabina)

	-- Letrero TAXI iluminado en el techo
	local cartelTaxi = Instance.new("Part")
	cartelTaxi.Name = "CartelTaxi"
	cartelTaxi.Size = Vector3.new(2.4, 0.7, 1.2)
	cartelTaxi.CFrame = cabina.CFrame * CFrame.new(0, 1.5, 0)
	cartelTaxi.Color = Color3.fromRGB(255, 245, 220)
	cartelTaxi.Material = Enum.Material.Neon
	cartelTaxi.Anchored = false
	cartelTaxi.CanCollide = false
	cartelTaxi.Parent = modelo
	soldar(chasis, cartelTaxi)

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
		farol.Anchored = false
		farol.CanCollide = false
		farol.Parent = modelo
		soldar(chasis, farol)
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
			rueda.Anchored = false
			rueda.CanCollide = false
			rueda.Parent = modelo
			soldar(chasis, rueda)
		end
	end

	-- Asiento de Conducción
	local asiento = Instance.new("VehicleSeat")
	asiento.Name = "VehicleSeat"
	asiento.Size = Vector3.new(2, 1, 2)
	asiento.CFrame = chasis.CFrame * CFrame.new(-1.4, 1.2, -0.6)
	asiento.Transparency = 1
	asiento.CanCollide = false
	asiento.Parent = modelo
	soldar(chasis, asiento)

	configurarFisicaVehiculoConducible(modelo, chasis, asiento, "Taxi Clásico")

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
	cabina.Anchored = false
	cabina.CanCollide = true
	cabina.Parent = modelo
	soldar(chasis, cabina)

	-- Estacas traseras de madera
	for _, x in ipairs({ -3.1, 3.1 }) do
		local estaca = Instance.new("Part")
		estaca.Name = "EstacasMadera"
		estaca.Size = Vector3.new(0.35, 2.8, 7.5)
		estaca.CFrame = chasis.CFrame * CFrame.new(x, 2.2, 3.2)
		estaca.Color = Color3.fromRGB(150, 105, 60)
		estaca.Material = Enum.Material.WoodPlanks
		estaca.Anchored = false
		estaca.CanCollide = true
		estaca.Parent = modelo
		soldar(chasis, estaca)
	end

	-- Bultos de café en el platón
	for i = 1, 4 do
		local bulto = Instance.new("Part")
		bulto.Name = "BultoCafe"
		bulto.Size = Vector3.new(2.4, 1.4, 2.0)
		bulto.CFrame = chasis.CFrame * CFrame.new((i % 2 == 0 and 1.3 or -1.3), 1.2, 1.5 + (i * 1.0))
		bulto.Color = Color3.fromRGB(165, 140, 105)
		bulto.Material = Enum.Material.Fabric
		bulto.Anchored = false
		bulto.CanCollide = true
		bulto.Parent = modelo
		soldar(chasis, bulto)
	end

	-- Ruedas grandes 4x4
	for _, x in ipairs({ -3.5, 3.5 }) do
		for _, z in ipairs({ -4.5, 4.5 }) do
			local rueda = Instance.new("Part")
			rueda.Name = "RuedaCampero"
			rueda.Shape = Enum.PartType.Cylinder
			rueda.Size = Vector3.new(1.2, 2.8, 2.8)
			rueda.CFrame = chasis.CFrame * CFrame.new(x, -0.6, z) * CFrame.Angles(0, 0, math.rad(90))
			rueda.Color = Color3.fromRGB(25, 25, 25)
			rueda.Material = Enum.Material.Rubber
			rueda.Anchored = false
			rueda.CanCollide = false
			rueda.Parent = modelo
			soldar(chasis, rueda)
		end
	end

	-- Asiento de Conducción
	local asiento = Instance.new("VehicleSeat")
	asiento.Name = "VehicleSeat"
	asiento.Size = Vector3.new(2, 1, 2)
	asiento.CFrame = chasis.CFrame * CFrame.new(-1.6, 1.4, -2.0)
	asiento.Transparency = 1
	asiento.CanCollide = false
	asiento.Parent = modelo
	soldar(chasis, asiento)

	configurarFisicaVehiculoConducible(modelo, chasis, asiento, "Campero Willys")

	modelo.Parent = parent
	return modelo
end

local function crearMotoMensajera125(pos: Vector3, rotY: number, parent: Instance)
	local modelo = Instance.new("Model")
	modelo.Name = "Vehiculo_MotoMensajera125"

	local chasis = Instance.new("Part")
	chasis.Name = "Chasis"
	chasis.Size = Vector3.new(1.8, 1.6, 5.0)
	chasis.CFrame = CFrame.new(pos + Vector3.new(0, 1.6, 0)) * CFrame.Angles(0, math.rad(rotY), 0)
	chasis.Color = Color3.fromRGB(180, 30, 30) -- Rojo mensajería
	chasis.Material = Enum.Material.Metal
	chasis.Anchored = true
	chasis.CanCollide = true
	chasis.Parent = modelo
	modelo.PrimaryPart = chasis

	-- Tanque de gasolina
	local tanque = Instance.new("Part")
	tanque.Name = "Tanque"
	tanque.Size = Vector3.new(1.4, 0.9, 1.6)
	tanque.CFrame = chasis.CFrame * CFrame.new(0, 0.9, -0.8)
	tanque.Color = Color3.fromRGB(180, 30, 30)
	tanque.Material = Enum.Material.SmoothPlastic
	tanque.Anchored = false
	tanque.CanCollide = false
	tanque.Parent = modelo
	soldar(chasis, tanque)

	-- Manubrio y farol redondo
	local manubrio = Instance.new("Part")
	manubrio.Name = "Manubrio"
	manubrio.Size = Vector3.new(2.8, 0.25, 0.3)
	manubrio.CFrame = chasis.CFrame * CFrame.new(0, 1.7, -1.8)
	manubrio.Color = Color3.fromRGB(220, 220, 225)
	manubrio.Material = Enum.Material.Metal
	manubrio.Anchored = false
	manubrio.CanCollide = false
	manubrio.Parent = modelo
	soldar(chasis, manubrio)

	local farol = Instance.new("Part")
	farol.Name = "FarolDelantero"
	farol.Shape = Enum.PartType.Cylinder
	farol.Size = Vector3.new(0.4, 0.9, 0.9)
	farol.CFrame = chasis.CFrame * CFrame.new(0, 1.2, -2.4) * CFrame.Angles(0, 0, math.rad(90))
	farol.Color = Color3.fromRGB(255, 255, 230)
	farol.Material = Enum.Material.Neon
	farol.Anchored = false
	farol.CanCollide = false
	farol.Parent = modelo
	soldar(chasis, farol)

	-- Ruedas delantera y trasera
	for _, z in ipairs({ -2.1, 2.1 }) do
		local rueda = Instance.new("Part")
		rueda.Name = "RuedaMoto"
		rueda.Shape = Enum.PartType.Cylinder
		rueda.Size = Vector3.new(0.6, 2.2, 2.2)
		rueda.CFrame = chasis.CFrame * CFrame.new(0, -0.5, z) * CFrame.Angles(0, 0, math.rad(90))
		rueda.Color = Color3.fromRGB(25, 25, 25)
		rueda.Material = Enum.Material.Rubber
		rueda.Anchored = false
		rueda.CanCollide = false
		rueda.Parent = modelo
		soldar(chasis, rueda)
	end

	-- Cajón de repartos trasero ("REPARTOS EL PATRÓN")
	local cajon = Instance.new("Part")
	cajon.Name = "CajonRepartos"
	cajon.Size = Vector3.new(2.0, 1.8, 2.0)
	cajon.CFrame = chasis.CFrame * CFrame.new(0, 1.4, 1.8)
	cajon.Color = Color3.fromRGB(240, 240, 245)
	cajon.Material = Enum.Material.SmoothPlastic
	cajon.Anchored = false
	cajon.CanCollide = true
	cajon.Parent = modelo
	soldar(chasis, cajon)

	local bbgCajon = Instance.new("BillboardGui")
	bbgCajon.Size = UDim2.fromOffset(100, 30)
	bbgCajon.AlwaysOnTop = true
	bbgCajon.MaxDistance = 40
	bbgCajon.Parent = cajon

	local lblCajon = Instance.new("TextLabel")
	lblCajon.Size = UDim2.fromScale(1, 1)
	lblCajon.BackgroundTransparency = 1
	lblCajon.Font = Enum.Font.FredokaOne
	lblCajon.Text = "REPARTOS 125"
	lblCajon.TextColor3 = Color3.fromRGB(180, 25, 25)
	lblCajon.TextSize = 14
	lblCajon.Parent = bbgCajon

	-- Asiento VehicleSeat
	local asiento = Instance.new("VehicleSeat")
	asiento.Name = "VehicleSeat"
	asiento.Size = Vector3.new(1.6, 0.8, 1.6)
	asiento.CFrame = chasis.CFrame * CFrame.new(0, 1.0, 0.2)
	asiento.Transparency = 1
	asiento.CanCollide = false
	asiento.Parent = modelo
	soldar(chasis, asiento)

	configurarFisicaVehiculoConducible(modelo, chasis, asiento, "Moto Repartos 125")

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
-- ESTRUCTURAS OFICIALES DE LOS CAPÍTULOS 6 A 10
-- ====================================================================

-- 1. Capítulo 6: Barricada y Territorio de la Banda del Chicle
local function construirBarricadaBandaChicle(parent: Instance)
	local modelo = Instance.new("Model")
	modelo.Name = "Capitulo6_BarricadaBandaChicle"

	local basePos = Vector3.new(-50, 70, 140)

	-- Bloque de Barricada Principal
	local vallaMadera = Instance.new("Part")
	vallaMadera.Name = "VallaBarricada"
	vallaMadera.Size = Vector3.new(12, 4.5, 1.2)
	vallaMadera.Position = basePos + Vector3.new(0, 2.25, 0)
	vallaMadera.Color = Color3.fromRGB(160, 40, 120) -- Morado chicle rebelde
	vallaMadera.Material = Enum.Material.WoodPlanks
	vallaMadera.Anchored = true
	vallaMadera.CanCollide = true
	vallaMadera.Parent = modelo
	modelo.PrimaryPart = vallaMadera

	-- Cartel con Grafiti
	local cartel = Instance.new("Part")
	cartel.Name = "CartelGrafiti"
	cartel.Size = Vector3.new(10, 2.2, 0.4)
	cartel.Position = vallaMadera.Position + Vector3.new(0, 0.5, -0.7)
	cartel.Color = Color3.fromRGB(255, 60, 150)
	cartel.Material = Enum.Material.Neon
	cartel.Anchored = true
	cartel.CanCollide = false
	cartel.Parent = modelo

	local surfGui = Instance.new("SurfaceGui")
	surfGui.Face = Enum.NormalId.Back
	surfGui.LightInfluence = 0
	surfGui.Parent = cartel

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.fromScale(1, 1)
	txt.BackgroundTransparency = 1
	txt.Font = Enum.Font.FredokaOne
	txt.Text = "🍬 TERRITORIO BANDA DEL CHICLE 🍬"
	txt.TextColor3 = Color3.fromRGB(255, 255, 255)
	txt.TextSize = 22
	txt.Parent = surfGui

	-- Cajas de chicle y barriles derramados
	for i = 1, 3 do
		local caja = Instance.new("Part")
		caja.Name = "CajaChicles_" .. i
		caja.Size = Vector3.new(2.4, 2.0, 2.4)
		caja.Position = basePos + Vector3.new((i - 2) * 3.5, 1.0, -2.2)
		caja.Color = Color3.fromRGB(230, 80, 140)
		caja.Material = Enum.Material.Wood
		caja.Anchored = true
		caja.CanCollide = true
		caja.Parent = modelo
	end

	-- NPC Pandillero: "Lalo el Masticador"
	local pandillero = Instance.new("Model")
	pandillero.Name = "NPC_LaloChicle"
	pandillero.Parent = modelo

	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(1.8, 2.0, 1.0)
	hrp.Position = basePos + Vector3.new(2.5, 2.5, -1.8)
	hrp.Color = Color3.fromRGB(120, 30, 90)
	hrp.Material = Enum.Material.SmoothPlastic
	hrp.Anchored = true
	hrp.CanCollide = false
	hrp.Parent = pandillero
	pandillero.PrimaryPart = hrp

	local cabeza = Instance.new("Part")
	cabeza.Name = "Head"
	cabeza.Size = Vector3.new(1.2, 1.2, 1.2)
	cabeza.Position = hrp.Position + Vector3.new(0, 1.5, 0)
	cabeza.Color = Color3.fromRGB(240, 205, 175)
	cabeza.Material = Enum.Material.SmoothPlastic
	cabeza.Anchored = true
	cabeza.CanCollide = false
	cabeza.Parent = pandillero

	-- Burbuja de chicle en la boca
	local burbujaChicle = Instance.new("Part")
	burbujaChicle.Name = "BurbujaChicle"
	burbujaChicle.Shape = Enum.PartType.Ball
	burbujaChicle.Size = Vector3.new(0.9, 0.9, 0.9)
	burbujaChicle.Position = cabeza.Position + Vector3.new(0, -0.1, -0.7)
	burbujaChicle.Color = Color3.fromRGB(255, 90, 180)
	burbujaChicle.Material = Enum.Material.Neon
	burbujaChicle.Anchored = true
	burbujaChicle.CanCollide = false
	burbujaChicle.Parent = pandillero

	-- Rótulo sobre la cabeza
	local bbg = Instance.new("BillboardGui")
	bbg.Size = UDim2.fromOffset(180, 40)
	bbg.StudsOffset = Vector3.new(0, 2.5, 0)
	bbg.AlwaysOnTop = true
	bbg.MaxDistance = 35
	bbg.Parent = cabeza

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.FredokaOne
	lbl.Text = "💣 Lalo el Masticador\n(Banda del Chicle)"
	lbl.TextColor3 = Color3.fromRGB(255, 140, 210)
	lbl.TextSize = 13
	lbl.Parent = bbg

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PromptBandaChicle"
	prompt.ObjectText = "Lalo el Masticador"
	prompt.ActionText = "Desafiar / Negociar Territorio"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = hrp

	prompt.Triggered:Connect(function(player: Player)
		local datos = GestorDatos.ObtenerDatos(player)
		local cap = datos and (datos.CapituloActual or 1) or 1
		if cap >= 6 then
			EventosRemotos.MostrarDialogoNPC:FireClient(player, {
				Nombre = "Lalo el Masticador",
				Titulo = "Banda del Chicle",
				Icono = "🕶️",
				Mensaje = "¡Tranquilo patrón! Ya vimos que traes el Cañón de Confeti de Doña Melcocha. ¡Los callejones altos son tuyos!",
			})
		else
			EventosRemotos.MostrarDialogoNPC:FireClient(player, {
				Nombre = "Lalo el Masticador",
				Titulo = "Banda del Chicle",
				Icono = "💣",
				Mensaje = "¡Ey pelado! Esta esquina es de la Banda del Chicle. ¡Llega al Capítulo 6 ($1.000) si quieres pasar sin que te peguemos chicle en la ropa!",
			})
		end
	end)

	modelo.Parent = parent
	return modelo
end

-- 2. Capítulo 7: Finca La Melcocha y Trapiche Panelero
local function construirFincaLaMelcocha(parent: Instance)
	local modelo = Instance.new("Model")
	modelo.Name = "Capitulo7_FincaLaMelcocha"

	local basePos = Vector3.new(-98, 100, 412)

	-- Explanada / Patio de la Finca
	local patio = Instance.new("Part")
	patio.Name = "PatioFinca"
	patio.Size = Vector3.new(42, 0.8, 38)
	patio.Position = basePos + Vector3.new(0, 0.4, 0)
	patio.Color = Color3.fromRGB(150, 115, 80) -- Tierra firme y empedrado campestre
	patio.Material = Enum.Material.Slate
	patio.Anchored = true
	patio.CanCollide = true
	patio.Parent = modelo
	modelo.PrimaryPart = patio

	-- Gran Portón Colonial de Madera con Tejas
	local portonArco = Instance.new("Part")
	portonArco.Name = "ArcoPorton"
	portonArco.Size = Vector3.new(14, 1.4, 1.4)
	portonArco.Position = basePos + Vector3.new(0, 9.5, -18)
	portonArco.Color = Color3.fromRGB(90, 50, 25)
	portonArco.Material = Enum.Material.WoodPlanks
	portonArco.Anchored = true
	portonArco.CanCollide = true
	portonArco.Parent = modelo

	for _, xSide in ipairs({ -6.5, 6.5 }) do
		local pilar = Instance.new("Part")
		pilar.Name = "PilarPorton"
		pilar.Size = Vector3.new(1.6, 9.5, 1.6)
		pilar.Position = basePos + Vector3.new(xSide, 4.75, -18)
		pilar.Color = Color3.fromRGB(110, 60, 30)
		pilar.Material = Enum.Material.WoodPlanks
		pilar.Anchored = true
		pilar.CanCollide = true
		pilar.Parent = modelo
	end

	-- Cartel Tallado en Madera "FINCA LA MELCOCHA"
	local letreroFinca = Instance.new("Part")
	letreroFinca.Name = "LetreroFinca"
	letreroFinca.Size = Vector3.new(12, 2.2, 0.4)
	letreroFinca.Position = basePos + Vector3.new(0, 9.5, -17.2)
	letreroFinca.Color = Color3.fromRGB(240, 220, 170)
	letreroFinca.Material = Enum.Material.Wood
	letreroFinca.Anchored = true
	letreroFinca.CanCollide = false
	letreroFinca.Parent = modelo

	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Back
	sg.LightInfluence = 0.1
	sg.Parent = letreroFinca

	local tLbl = Instance.new("TextLabel")
	tLbl.Size = UDim2.fromScale(1, 1)
	tLbl.BackgroundTransparency = 1
	tLbl.Font = Enum.Font.FredokaOne
	tLbl.Text = "🌾 FINCA LA MELCOCHA — TRAPICHE"
	tLbl.TextColor3 = Color3.fromRGB(80, 45, 15)
	tLbl.TextSize = 22
	tLbl.Parent = sg

	-- Casa Campestre Tradicional
	local casa = Instance.new("Part")
	casa.Name = "CasaCampestre"
	casa.Size = Vector3.new(22, 10, 16)
	casa.Position = basePos + Vector3.new(8, 5.5, 8)
	casa.Color = Color3.fromRGB(248, 245, 240)
	casa.Material = Enum.Material.Concrete
	casa.Anchored = true
	casa.CanCollide = true
	casa.Parent = modelo

	local techoCasa = Instance.new("Part")
	techoCasa.Name = "TechoBarro"
	techoCasa.Size = Vector3.new(24, 2.5, 18)
	techoCasa.Position = casa.Position + Vector3.new(0, 5.5, 0)
	techoCasa.Color = Color3.fromRGB(180, 70, 40) -- Teja de barro colonial
	techoCasa.Material = Enum.Material.Brick
	techoCasa.Anchored = true
	techoCasa.CanCollide = true
	techoCasa.Parent = modelo

	-- Trapiche Panelero Artesanal (Paila hirviendo melao dulce)
	local trapiche = Instance.new("Part")
	trapiche.Name = "TrapichePaila"
	trapiche.Size = Vector3.new(8, 2.5, 8)
	trapiche.Position = basePos + Vector3.new(-12, 1.5, 2)
	trapiche.Color = Color3.fromRGB(75, 45, 30)
	trapiche.Material = Enum.Material.Cobblestone
	trapiche.Anchored = true
	trapiche.CanCollide = true
	trapiche.Parent = modelo

	local pailaMelao = Instance.new("Part")
	pailaMelao.Name = "MelaoHirviendo"
	pailaMelao.Size = Vector3.new(6, 0.4, 6)
	pailaMelao.Position = trapiche.Position + Vector3.new(0, 1.3, 0)
	pailaMelao.Color = Color3.fromRGB(215, 140, 30) -- Dulce de panela hirviendo
	pailaMelao.Material = Enum.Material.Neon
	pailaMelao.Anchored = true
	pailaMelao.CanCollide = false
	pailaMelao.Parent = modelo

	-- Humo dulce y vapor
	local humo = Instance.new("Smoke")
	humo.Color = Color3.fromRGB(255, 240, 210)
	humo.Opacity = 0.35
	humo.RiseVelocity = 3.5
	humo.Size = 4.0
	humo.Parent = pailaMelao

	-- Cañaduzal (Cultivo de Caña Dulce Cosechable)
	local canaFolder = Instance.new("Folder")
	canaFolder.Name = "Canaduzal"
	canaFolder.Parent = modelo

	for i = 1, 6 do
		local tallo = Instance.new("Part")
		tallo.Name = "CanaAzucar_" .. i
		tallo.Size = Vector3.new(0.6, 7.0, 0.6)
		local offsetX = -16 + ((i % 3) * 2.2)
		local offsetZ = 10 + (math.floor(i / 3) * 3.0)
		tallo.Position = basePos + Vector3.new(offsetX, 3.8, offsetZ)
		tallo.Color = Color3.fromRGB(90, 180, 50) -- Verde cañaduzal
		tallo.Material = Enum.Material.Grass
		tallo.Anchored = true
		tallo.CanCollide = true
		tallo.Parent = canaFolder

		local hojas = Instance.new("Part")
		hojas.Name = "HojasCana"
		hojas.Size = Vector3.new(2.4, 1.2, 2.4)
		hojas.Position = tallo.Position + Vector3.new(0, 3.5, 0)
		hojas.Color = Color3.fromRGB(60, 150, 40)
		hojas.Material = Enum.Material.Grass
		hojas.Anchored = true
		hojas.CanCollide = false
		hojas.Parent = canaFolder
	end

	-- ProximityPrompt en el Trapiche para cosechar melao
	local promptTrapiche = Instance.new("ProximityPrompt")
	promptTrapiche.Name = "PromptCosecha"
	promptTrapiche.ObjectText = "Trapiche Melcochero"
	promptTrapiche.ActionText = "Cosechar Melaza de Caña ($)"
	promptTrapiche.HoldDuration = 0.5
	promptTrapiche.MaxActivationDistance = 14
	promptTrapiche.RequiresLineOfSight = false
	promptTrapiche.Parent = trapiche

	promptTrapiche.Triggered:Connect(function(player: Player)
		local datos = GestorDatos.ObtenerDatos(player)
		if not datos then
			return
		end
		local mult = datos.MultiplicadorRenacimiento or 1
		local ganancia = 35 * mult
		GestorDatos.AgregarPesos(player, ganancia)
		datos.Fama += 2

		local sonido = Instance.new("Sound")
		sonido.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		sonido.Volume = 0.8
		sonido.Parent = trapiche
		sonido:Play()
		task.delay(1.5, function()
			sonido:Destroy()
		end)

		EventosRemotos.MostrarDialogoNPC:FireClient(player, {
			Nombre = "Trapiche de la Finca",
			Titulo = "¡Cosecha Fresca!",
			Icono = "🌾",
			Mensaje = string.format("¡Molienda exitosa! Obtuviste melaza fresca y $%d pesos dulces para tu imperio.", ganancia),
		})
	end)

	modelo.Parent = parent
	return modelo
end

-- 3. Capítulo 8: Pista de Aterrizaje y Avioneta Dulcera de Exportación
local function construirPistaYAvionetaDulcera(parent: Instance)
	local modelo = Instance.new("Model")
	modelo.Name = "Capitulo8_AeroclubDulcero"

	local basePos = Vector3.new(45, 96.5, 435)

	-- Pista de Aterrizaje
	local pista = Instance.new("Part")
	pista.Name = "PistaAterrizaje"
	pista.Size = Vector3.new(24, 0.6, 75)
	pista.Position = basePos + Vector3.new(0, 0.3, 0)
	pista.Color = Color3.fromRGB(80, 85, 90)
	pista.Material = Enum.Material.Asphalt
	pista.Anchored = true
	pista.CanCollide = true
	pista.Parent = modelo
	modelo.PrimaryPart = pista

	-- Franjas de Pista Neon Brillantes
	for z = -30, 30, 15 do
		local franja = Instance.new("Part")
		franja.Name = "FranjaPista"
		franja.Size = Vector3.new(1.8, 0.1, 7.0)
		franja.Position = basePos + Vector3.new(0, 0.65, z)
		franja.Color = Color3.fromRGB(255, 230, 45)
		franja.Material = Enum.Material.Neon
		franja.Anchored = true
		franja.CanCollide = false
		franja.Parent = modelo
	end

	-- Hangar Rústico
	local hangar = Instance.new("Part")
	hangar.Name = "HangarAvioneta"
	hangar.Size = Vector3.new(22, 10, 20)
	hangar.Position = basePos + Vector3.new(-18, 5.2, -15)
	hangar.Color = Color3.fromRGB(65, 75, 90)
	hangar.Material = Enum.Material.CorrodedMetal
	hangar.Anchored = true
	hangar.CanCollide = true
	hangar.Parent = modelo

	local cartelHangar = Instance.new("Part")
	cartelHangar.Name = "CartelHangar"
	cartelHangar.Size = Vector3.new(18, 2.2, 0.4)
	cartelHangar.Position = hangar.Position + Vector3.new(0, 4.2, 10.2)
	cartelHangar.Color = Color3.fromRGB(240, 200, 50)
	cartelHangar.Material = Enum.Material.Neon
	cartelHangar.Anchored = true
	cartelHangar.CanCollide = false
	cartelHangar.Parent = modelo

	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.LightInfluence = 0
	sg.Parent = cartelHangar

	local tLbl = Instance.new("TextLabel")
	tLbl.Size = UDim2.fromScale(1, 1)
	tLbl.BackgroundTransparency = 1
	tLbl.Font = Enum.Font.FredokaOne
	tLbl.Text = "🛩️ AEROCLUB VILLA ALMÍBAR — RUTA DULCERA"
	tLbl.TextColor3 = Color3.fromRGB(20, 25, 35)
	tLbl.TextSize = 20
	tLbl.Parent = sg

	-- MODELO DE LA AVIONETA DULCERA
	local avioneta = Instance.new("Model")
	avioneta.Name = "AvionetaDulcera"
	avioneta.Parent = modelo

	local fuselaje = Instance.new("Part")
	fuselaje.Name = "Fuselaje"
	fuselaje.Size = Vector3.new(4.2, 3.8, 16)
	fuselaje.Position = basePos + Vector3.new(0, 3.8, 10)
	fuselaje.Color = Color3.fromRGB(255, 215, 30) -- Amarillo brillante
	fuselaje.Material = Enum.Material.Metal
	fuselaje.Anchored = true
	fuselaje.CanCollide = true
	fuselaje.Parent = avioneta

	-- Alas de la Avioneta
	local alas = Instance.new("Part")
	alas.Name = "Alas"
	alas.Size = Vector3.new(26, 0.6, 4.5)
	alas.Position = fuselaje.Position + Vector3.new(0, 1.4, -1.0)
	alas.Color = Color3.fromRGB(35, 90, 200) -- Azul cielo
	alas.Material = Enum.Material.Metal
	alas.Anchored = true
	alas.CanCollide = true
	alas.Parent = avioneta

	-- Hélice Delantera
	local helice = Instance.new("Part")
	helice.Name = "Helice"
	helice.Size = Vector3.new(0.4, 5.0, 0.6)
	helice.Position = fuselaje.Position + Vector3.new(0, 0, -8.3)
	helice.Color = Color3.fromRGB(30, 30, 35)
	helice.Material = Enum.Material.Metal
	helice.Anchored = true
	helice.CanCollide = false
	helice.Parent = avioneta

	-- Giro suave de hélice en idle
	task.spawn(function()
		while helice.Parent do
			helice.CFrame = helice.CFrame * CFrame.Angles(0, 0, math.rad(18))
			task.wait(0.04)
		end
	end)

	-- NPC Piloto: Capitán Chepe
	local piloto = Instance.new("Model")
	piloto.Name = "NPC_CapitanChepe"
	piloto.Parent = modelo

	local pHrp = Instance.new("Part")
	pHrp.Name = "HumanoidRootPart"
	pHrp.Size = Vector3.new(1.8, 2.0, 1.0)
	pHrp.Position = fuselaje.Position + Vector3.new(5.0, -1.0, 0)
	pHrp.Color = Color3.fromRGB(90, 60, 40)
	pHrp.Material = Enum.Material.SmoothPlastic
	pHrp.Anchored = true
	pHrp.CanCollide = false
	pHrp.Parent = piloto

	local pHead = Instance.new("Part")
	pHead.Name = "Head"
	pHead.Size = Vector3.new(1.2, 1.2, 1.2)
	pHead.Position = pHrp.Position + Vector3.new(0, 1.5, 0)
	pHead.Color = Color3.fromRGB(240, 205, 175)
	pHead.Material = Enum.Material.SmoothPlastic
	pHead.Anchored = true
	pHead.CanCollide = false
	pHead.Parent = piloto

	local pBbg = Instance.new("BillboardGui")
	pBbg.Size = UDim2.fromOffset(180, 40)
	pBbg.StudsOffset = Vector3.new(0, 2.5, 0)
	pBbg.AlwaysOnTop = true
	pBbg.MaxDistance = 35
	pBbg.Parent = pHead

	local pLbl = Instance.new("TextLabel")
	pLbl.Size = UDim2.fromScale(1, 1)
	pLbl.BackgroundTransparency = 1
	pLbl.Font = Enum.Font.FredokaOne
	pLbl.Text = "👨‍✈️ Capitán Chepe\n(Exportación Aérea)"
	pLbl.TextColor3 = Color3.fromRGB(255, 235, 150)
	pLbl.TextSize = 13
	pLbl.Parent = pBbg

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PromptExportar"
	prompt.ObjectText = "Capitán Chepe"
	prompt.ActionText = "Despachar Exportación Aérea (5 Dulces -> $150)"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = pHrp

	prompt.Triggered:Connect(function(player: Player)
		local datos = GestorDatos.ObtenerDatos(player)
		if not datos then
			return
		end

		-- Contar dulces totales en inventario
		local dulcesTotales = 0
		for _, cant in pairs(datos.Inventario) do
			dulcesTotales += cant
		end

		if dulcesTotales >= 5 then
			-- Quitar 5 dulces
			local quitados = 0
			for idD, cant in pairs(datos.Inventario) do
				while cant > 0 and quitados < 5 do
					GestorDatos.QuitarDulce(player, idD, 1)
					cant -= 1
					quitados += 1
				end
				if quitados >= 5 then
					break
				end
			end

			local mult = datos.MultiplicadorRenacimiento or 1
			local pago = 150 * mult
			GestorDatos.AgregarPesos(player, pago)
			datos.Fama += 15

			local sonido = Instance.new("Sound")
			sonido.SoundId = "rbxasset://sounds/electronicpingshort.wav"
			sonido.Volume = 0.9
			sonido.Parent = fuselaje
			sonido:Play()
			task.delay(2, function()
				sonido:Destroy()
			end)

			EventosRemotos.MostrarDialogoNPC:FireClient(player, {
				Nombre = "Capitán Chepe",
				Titulo = "¡Vuelo Despejado!",
				Icono = "🛩️",
				Mensaje = string.format("¡Avioneta cargada y despegando hacia la capital! Recibes $%d pesos por la exportación. ¡El imperio crece!", pago),
			})
		else
			EventosRemotos.MostrarDialogoNPC:FireClient(player, {
				Nombre = "Capitán Chepe",
				Titulo = "Avioneta Dulcera",
				Icono = "🛩️",
				Mensaje = "¡Buenas patrón! Necesito al menos 5 dulces en tu inventario para llenar las bodegas de la avioneta y justificar el vuelo.",
			})
		end
	end)

	modelo.Parent = parent
	return modelo
end

-- 4. Capítulo 10: Monumento y Altar de la Leyenda del Patrón
local function construirMonumentoAltarPatron(parent: Instance)
	local modelo = Instance.new("Model")
	modelo.Name = "Capitulo10_AltarDelPatron"

	local basePos = Vector3.new(0, 60.5, 60)

	-- Pedestal Octogonal de Mármol Blanco
	local pedestal = Instance.new("Part")
	pedestal.Name = "PedestalMarmol"
	pedestal.Size = Vector3.new(10, 1.8, 10)
	pedestal.Position = basePos + Vector3.new(0, 0.9, 0)
	pedestal.Color = Color3.fromRGB(245, 248, 252)
	pedestal.Material = Enum.Material.Marble
	pedestal.Anchored = true
	pedestal.CanCollide = true
	pedestal.Parent = modelo
	modelo.PrimaryPart = pedestal

	-- 4 Antorchas de Caramelo en las esquinas
	for _, xOff in ipairs({ -4.2, 4.2 }) do
		for _, zOff in ipairs({ -4.2, 4.2 }) do
			local pilar = Instance.new("Part")
			pilar.Name = "PilarAntorcha"
			pilar.Size = Vector3.new(0.8, 3.5, 0.8)
			pilar.Position = basePos + Vector3.new(xOff, 2.65, zOff)
			pilar.Color = Color3.fromRGB(220, 180, 60)
			pilar.Material = Enum.Material.Metal
			pilar.Anchored = true
			pilar.CanCollide = true
			pilar.Parent = modelo

			local llama = Instance.new("Part")
			llama.Name = "LlamaCaramelo"
			llama.Shape = Enum.PartType.Ball
			llama.Size = Vector3.new(1.0, 1.2, 1.0)
			llama.Position = pilar.Position + Vector3.new(0, 2.0, 0)
			llama.Color = Color3.fromRGB(255, 170, 30)
			llama.Material = Enum.Material.Neon
			llama.Anchored = true
			llama.CanCollide = false
			llama.Parent = modelo

			local pLight = Instance.new("PointLight")
			pLight.Color = Color3.fromRGB(255, 200, 80)
			pLight.Range = 14
			pLight.Brightness = 1.8
			pLight.Parent = llama
		end
	end

	-- Estatua Dorada de Doña Melcocha y el Gran Bombón
	local estatua = Instance.new("Part")
	estatua.Name = "EstatuaDorada"
	estatua.Size = Vector3.new(3.0, 5.5, 3.0)
	estatua.Position = pedestal.Position + Vector3.new(0, 3.65, 0)
	estatua.Color = Color3.fromRGB(255, 215, 0) -- Oro macizo
	estatua.Material = Enum.Material.Foil
	estatua.Anchored = true
	estatua.CanCollide = true
	estatua.Parent = modelo

	local bombonOro = Instance.new("Part")
	bombonOro.Name = "BombonDorado"
	bombonOro.Shape = Enum.PartType.Ball
	bombonOro.Size = Vector3.new(2.8, 2.8, 2.8)
	bombonOro.Position = estatua.Position + Vector3.new(0, 4.0, 0)
	bombonOro.Color = Color3.fromRGB(255, 225, 45)
	bombonOro.Material = Enum.Material.Neon
	bombonOro.Anchored = true
	bombonOro.CanCollide = false
	bombonOro.Parent = modelo

	-- Partículas de Confeti Dorado
	local confeti = Instance.new("ParticleEmitter")
	confeti.Name = "ConfetiDorado"
	confeti.Color = ColorSequence.new(Color3.fromRGB(255, 220, 50), Color3.fromRGB(255, 160, 20))
	confeti.Size = NumberSequence.new(0.4, 0.1)
	confeti.Rate = 12
	confeti.Speed = NumberRange.new(3, 6)
	confeti.SpreadAngle = Vector2.new(45, 45)
	confeti.Lifetime = NumberRange.new(2, 3.5)
	confeti.Parent = bombonOro

	-- Placa Conmemorativa con ProximityPrompt de Renacimiento
	local placa = Instance.new("Part")
	placa.Name = "PlacaRenacimiento"
	placa.Size = Vector3.new(3.2, 1.6, 0.4)
	placa.Position = pedestal.Position + Vector3.new(0, 0.2, -5.1)
	placa.Color = Color3.fromRGB(255, 215, 0)
	placa.Material = Enum.Material.Metal
	placa.Anchored = true
	placa.CanCollide = false
	placa.Parent = modelo

	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Back
	sg.LightInfluence = 0
	sg.Parent = placa

	local tLbl = Instance.new("TextLabel")
	tLbl.Size = UDim2.fromScale(1, 1)
	tLbl.BackgroundTransparency = 1
	tLbl.Font = Enum.Font.FredokaOne
	tLbl.Text = "👑 ALTAR DE LA LEYENDA 👑\n(Prestigio x2 Permanente)"
	tLbl.TextColor3 = Color3.fromRGB(40, 25, 10)
	tLbl.TextSize = 14
	tLbl.TextWrapped = true
	tLbl.Parent = sg

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PromptRenacimiento"
	prompt.ObjectText = "Altar de la Leyenda"
	prompt.ActionText = "👑 Realizar Renacimiento (Capítulo 10)"
	prompt.HoldDuration = 1.8
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = placa

	prompt.Triggered:Connect(function(player: Player)
		local datos = GestorDatos.ObtenerDatos(player)
		if not datos then
			return
		end

		local cap = datos.CapituloActual or 1
		local pesos = datos.PesosDulces or 0

		if cap >= 10 and pesos >= 6000 then
			-- Ejecutar Renacimiento / Prestigio
			GestorDatos.QuitarPesos(player, 6000)
			datos.Renacimientos = (datos.Renacimientos or 0) + 1
			datos.MultiplicadorRenacimiento = (datos.MultiplicadorRenacimiento or 1) * 2
			datos.Fama += 250

			-- Efecto de sonido triunfal
			local fanfare = Instance.new("Sound")
			fanfare.SoundId = "rbxasset://sounds/electronicpingshort.wav"
			fanfare.Volume = 1.0
			fanfare.Parent = bombonOro
			fanfare:Play()
			task.delay(2.5, function()
				fanfare:Destroy()
			end)

			-- Explosión visual de partículas
			confeti:Emit(100)

			EventosRemotos.MostrarDialogoNPC:FireClient(player, {
				Nombre = "Doña Melcocha",
				Titulo = "¡ERES LA LEYENDA DEL DULCE!",
				Icono = "👑",
				Mensaje = string.format(
					"¡Has completado el Renacimiento #%d! Todas tus ganancias futuras se han multiplicado por x%d de por vida. ¡El imperio dulce reina por siempre!",
					datos.Renacimientos,
					datos.MultiplicadorRenacimiento
				),
			})

			EventosRemotos.LogroDesbloqueado:FireClient(player, {
				Nombre = "El Patrón Legendario",
				Fama = 250,
			})
		else
			EventosRemotos.MostrarDialogoNPC:FireClient(player, {
				Nombre = "Doña Melcocha",
				Titulo = "Altar del Renacimiento",
				Icono = "👵",
				Mensaje = string.format(
					"Para alcanzar el Renacimiento y duplicar tus ganancias x2 necesitas llegar al Capítulo 10 y reunir $6.000 pesos dulces. Llevas $%d / $6.000. ¡Sigue adelante, mi patrón!",
					pesos
				),
			})
		end
	end)

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

	-- 2. Vehículos Estacionados y Conducibles Típicos Colombianos
	-- Taxi tradicional en la bahía de la plaza
	crearTaxiAmarillo(Vector3.new(14, 60, -28), 90, vehiculosEstacionados)
	-- Campero Willys cafetero en la esquina comercial
	crearCamperoWillys(Vector3.new(-48, 60, 50), -90, vehiculosEstacionados)
	-- Moto Mensajera 125cc en el parque frente al colegio
	crearMotoMensajera125(Vector3.new(-28, 60, -30), 45, vehiculosEstacionados)
	-- Moto Mensajera 125cc de entregas en la tienda de Don Chucho
	crearMotoMensajera125(Vector3.new(88, 60, 160), -90, vehiculosEstacionados)

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

	-- 5. Estructuras Oficiales de los Capítulos 6 a 10
	construirBarricadaBandaChicle(landmarksFolder)
	construirFincaLaMelcocha(landmarksFolder)
	construirPistaYAvionetaDulcera(landmarksFolder)
	construirMonumentoAltarPatron(parqueFolder)

	-- 6. Franjas Amarillas Reflectivas Brillantes de Carretera (Guías visuales nocturnas)
	task.spawn(function()
		task.wait(1.0)
		for _, desc in ipairs(mapa:GetDescendants()) do
			if desc:IsA("BasePart") then
				local n = desc.Name:lower()
				if n:find("lineacentral") or n:find("franja") or n:find("raya") then
					desc.Material = Enum.Material.Neon
					desc.Color = Color3.fromRGB(255, 230, 45)
				end
			end
		end
	end)

	print("El Patrón del Dulce: Decoración exterior, parques, interiores y landmarks inicializados")
end

task.spawn(inicializarDecoracionYAmbiente)
