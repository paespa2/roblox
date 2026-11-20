--!strict
--[[
	ModelosVehiculos.luau
	Módulo generador de modelos de vehículos (fallbacks 3D de alta fidelidad).
	Construye geometrías completas para motos y bicicletas urbanas de reparto
	con llantas cilíndricas verticales, suspensiones, chasis y accesorios.
	
	El Patrón del Dulce
]]

local ModelosVehiculos = {}

-- Constructor de Bicicleta Urbana de Reparto (Fallback 3D)
function ModelosVehiculos.CrearBicicletaFallback(): Model
	local modelo = Instance.new("Model")
	modelo.Name = "Vehiculo_Bicicleta"

	-- Chasis / Cuadro principal
	local chasis = Instance.new("Part")
	chasis.Name = "Chasis"
	chasis.Size = Vector3.new(0.8, 0.4, 3.8)
	chasis.Position = Vector3.new(0, 1.8, 0)
	chasis.Color = Color3.fromRGB(38, 140, 130)
	chasis.Material = Enum.Material.Metal
	chasis.CanCollide = false
	chasis.Parent = modelo
	modelo.PrimaryPart = chasis

	-- Esferas de física de contacto
	local colF = Instance.new("Part")
	colF.Name = "RuedaFisica"
	colF.Shape = Enum.PartType.Ball
	colF.Size = Vector3.new(2.4, 2.4, 2.4)
	colF.Position = Vector3.new(0, 1.2, -2.2)
	colF.CanCollide = true
	colF.Transparency = 1
	colF.CustomPhysicalProperties = PhysicalProperties.new(1.2, 0.25, 0.0, 1.0, 1.0)
	colF.Parent = modelo

	local colR = Instance.new("Part")
	colR.Name = "RuedaFisica"
	colR.Shape = Enum.PartType.Ball
	colR.Size = Vector3.new(2.4, 2.4, 2.4)
	colR.Position = Vector3.new(0, 1.2, 2.0)
	colR.CanCollide = true
	colR.Transparency = 1
	colR.CustomPhysicalProperties = PhysicalProperties.new(1.2, 0.25, 0.0, 1.0, 1.0)
	colR.Parent = modelo

	-- Llantas visuales cilíndricas verticales (Orientation = 0, 0, 0)
	local llantaDel = Instance.new("Part")
	llantaDel.Name = "LlantaBici"
	llantaDel.Shape = Enum.PartType.Cylinder
	llantaDel.Size = Vector3.new(0.28, 2.5, 2.5)
	llantaDel.CFrame = CFrame.new(0, 1.25, -2.2)
	llantaDel.Color = Color3.fromRGB(25, 25, 28)
	llantaDel.Material = Enum.Material.Rubber
	llantaDel.CanCollide = false
	llantaDel.Parent = modelo

	local llantaTras = Instance.new("Part")
	llantaTras.Name = "LlantaBici"
	llantaTras.Shape = Enum.PartType.Cylinder
	llantaTras.Size = Vector3.new(0.28, 2.5, 2.5)
	llantaTras.CFrame = CFrame.new(0, 1.25, 2.0)
	llantaTras.Color = Color3.fromRGB(25, 25, 28)
	llantaTras.Material = Enum.Material.Rubber
	llantaTras.CanCollide = false
	llantaTras.Parent = modelo

	-- Asiento para el jugador
	local asiento = Instance.new("VehicleSeat")
	asiento.Name = "Asiento"
	asiento.Size = Vector3.new(1.2, 0.45, 1.4)
	asiento.Position = Vector3.new(0, 2.85, 0.7)
	asiento.Color = Color3.fromRGB(110, 60, 35)
	asiento.Material = Enum.Material.Fabric
	asiento.MaxSpeed = 0
	asiento.Torque = 0
	asiento.TurnSpeed = 0
	asiento.CanCollide = false
	asiento.Parent = modelo

	-- Manubrio y canastilla
	local manubrio = Instance.new("Part")
	manubrio.Name = "Manubrio"
	manubrio.Size = Vector3.new(2.0, 0.25, 0.3)
	manubrio.Position = Vector3.new(0, 3.4, -1.9)
	manubrio.Color = Color3.fromRGB(200, 200, 205)
	manubrio.Material = Enum.Material.Metal
	manubrio.CanCollide = false
	manubrio.Parent = modelo

	local canasta = Instance.new("Part")
	canasta.Name = "CanastaDelantera"
	canasta.Size = Vector3.new(1.3, 0.7, 0.9)
	canasta.Position = Vector3.new(0, 3.1, -2.4)
	canasta.Color = Color3.fromRGB(180, 140, 90)
	canasta.Material = Enum.Material.Wood
	canasta.CanCollide = false
	canasta.Parent = modelo

	-- Farola delantera
	local farol = Instance.new("Part")
	farol.Name = "Farola"
	farol.Size = Vector3.new(0.5, 0.5, 0.4)
	farol.Position = Vector3.new(0, 2.8, -2.4)
	farol.Color = Color3.fromRGB(255, 245, 200)
	farol.Material = Enum.Material.Neon
	farol.CanCollide = false
	farol.Parent = modelo

	local spot = Instance.new("SpotLight")
	spot.Range = 35
	spot.Brightness = 2.5
	spot.Angle = 60
	spot.Face = Enum.NormalId.Front
	spot.Parent = farol

	return modelo
end

-- Constructor de Moto Urbana de Reparto (Fallback 3D)
function ModelosVehiculos.CrearMotoFallback(): Model
	local modelo = Instance.new("Model")
	modelo.Name = "Vehiculo_Moto"

	-- Chasis principal
	local chasis = Instance.new("Part")
	chasis.Name = "Chasis"
	chasis.Size = Vector3.new(1.2, 0.6, 4.4)
	chasis.Position = Vector3.new(0, 1.9, 0)
	chasis.Color = Color3.fromRGB(35, 37, 42)
	chasis.Material = Enum.Material.Metal
	chasis.CanCollide = false
	chasis.Parent = modelo
	modelo.PrimaryPart = chasis

	-- Ruedas de física interna
	local colF = Instance.new("Part")
	colF.Name = "RuedaFisica"
	colF.Shape = Enum.PartType.Ball
	colF.Size = Vector3.new(2.4, 2.4, 2.4)
	colF.Position = Vector3.new(0, 1.2, -2.5)
	colF.CanCollide = true
	colF.Transparency = 1
	colF.CustomPhysicalProperties = PhysicalProperties.new(1.2, 0.20, 0.0, 1.0, 1.0)
	colF.Parent = modelo

	local colR = Instance.new("Part")
	colR.Name = "RuedaFisica"
	colR.Shape = Enum.PartType.Ball
	colR.Size = Vector3.new(2.4, 2.4, 2.4)
	colR.Position = Vector3.new(0, 1.2, 2.3)
	colR.CanCollide = true
	colR.Transparency = 1
	colR.CustomPhysicalProperties = PhysicalProperties.new(1.2, 0.20, 0.0, 1.0, 1.0)
	colR.Parent = modelo

	-- Patín de protección inferior contra rocas
	local colC = Instance.new("Part")
	colC.Name = "ColisionCentral"
	colC.Size = Vector3.new(1.0, 0.4, 3.4)
	colC.Position = Vector3.new(0, 1.35, 0)
	colC.CanCollide = true
	colC.Transparency = 1
	colC.CustomPhysicalProperties = PhysicalProperties.new(1.0, 0.05, 0.0, 1.0, 1.0)
	colC.Parent = modelo

	-- Llantas visuales cilíndricas verticales (Orientation = 0, 0, 0)
	local llantaDel = Instance.new("Part")
	llantaDel.Name = "LlantaVisual"
	llantaDel.Shape = Enum.PartType.Cylinder
	llantaDel.Size = Vector3.new(0.55, 2.5, 2.5)
	llantaDel.CFrame = CFrame.new(0, 1.25, -2.5)
	llantaDel.Color = Color3.fromRGB(22, 22, 26)
	llantaDel.Material = Enum.Material.Rubber
	llantaDel.CanCollide = false
	llantaDel.Parent = modelo

	local llantaTras = Instance.new("Part")
	llantaTras.Name = "LlantaVisual"
	llantaTras.Shape = Enum.PartType.Cylinder
	llantaTras.Size = Vector3.new(0.55, 2.5, 2.5)
	llantaTras.CFrame = CFrame.new(0, 1.25, 2.3)
	llantaTras.Color = Color3.fromRGB(22, 22, 26)
	llantaTras.Material = Enum.Material.Rubber
	llantaTras.CanCollide = false
	llantaTras.Parent = modelo

	-- Rines de aleación
	local rinDel = Instance.new("Part")
	rinDel.Name = "RinAleacion"
	rinDel.Shape = Enum.PartType.Cylinder
	rinDel.Size = Vector3.new(0.58, 1.8, 1.8)
	rinDel.CFrame = CFrame.new(0, 1.25, -2.5)
	rinDel.Color = Color3.fromRGB(180, 182, 190)
	rinDel.Material = Enum.Material.Metal
	rinDel.CanCollide = false
	rinDel.Parent = modelo

	local rinTras = Instance.new("Part")
	rinTras.Name = "RinAleacion"
	rinTras.Shape = Enum.PartType.Cylinder
	rinTras.Size = Vector3.new(0.58, 1.8, 1.8)
	rinTras.CFrame = CFrame.new(0, 1.25, 2.3)
	rinTras.Color = Color3.fromRGB(180, 182, 190)
	rinTras.Material = Enum.Material.Metal
	rinTras.CanCollide = false
	rinTras.Parent = modelo

	-- Asiento ergonómico
	local asiento = Instance.new("VehicleSeat")
	asiento.Name = "Asiento"
	asiento.Size = Vector3.new(1.4, 0.6, 2.2)
	asiento.Position = Vector3.new(0, 2.7, 0.5)
	asiento.Color = Color3.fromRGB(28, 28, 32)
	asiento.Material = Enum.Material.Fabric
	asiento.MaxSpeed = 0
	asiento.Torque = 0
	asiento.TurnSpeed = 0
	asiento.CanCollide = false
	asiento.Parent = modelo

	-- Tanque de combustible rojo carmesí
	local tanque = Instance.new("Part")
	tanque.Name = "TanqueGasolina"
	tanque.Size = Vector3.new(1.3, 0.8, 1.6)
	tanque.Position = Vector3.new(0, 2.7, -1.0)
	tanque.Color = Color3.fromRGB(200, 30, 35)
	tanque.Material = Enum.Material.Metal
	tanque.CanCollide = false
	tanque.Parent = modelo

	-- Farola frontal LED y luz proyectada
	local farol = Instance.new("Part")
	farol.Name = "Farola"
	farol.Size = Vector3.new(0.85, 0.65, 0.55)
	farol.Position = Vector3.new(0, 3.2, -2.45)
	farol.Color = Color3.fromRGB(200, 30, 35)
	farol.CanCollide = false
	farol.Parent = modelo

	local lente = Instance.new("Part")
	lente.Name = "LenteFarola"
	lente.Size = Vector3.new(0.7, 0.5, 0.1)
	lente.Position = Vector3.new(0, 3.2, -2.75)
	lente.Color = Color3.fromRGB(255, 250, 230)
	lente.Material = Enum.Material.Neon
	lente.CanCollide = false
	lente.Parent = modelo

	local luz = Instance.new("SpotLight")
	luz.Range = 55
	luz.Brightness = 3.5
	luz.Angle = 70
	luz.Face = Enum.NormalId.Front
	luz.Parent = farol

	-- Luz trasera de freno reactiva
	local luzFreno = Instance.new("Part")
	luzFreno.Name = "LuzFreno"
	luzFreno.Size = Vector3.new(0.8, 0.35, 0.15)
	luzFreno.Position = Vector3.new(0, 2.7, 2.9)
	luzFreno.Color = Color3.fromRGB(200, 25, 25)
	luzFreno.Material = Enum.Material.Neon
	luzFreno.CanCollide = false
	luzFreno.Parent = modelo

	local luzRojo = Instance.new("PointLight")
	luzRojo.Name = "LuzRojoTrasera"
	luzRojo.Color = Color3.fromRGB(255, 30, 30)
	luzRojo.Range = 12
	luzRojo.Brightness = 1.5
	luzRojo.Parent = luzFreno

	-- Manubrio y tablero
	local manubrio = Instance.new("Part")
	manubrio.Name = "Manubrio"
	manubrio.Size = Vector3.new(2.4, 0.25, 0.3)
	manubrio.Position = Vector3.new(0, 3.6, -2.1)
	manubrio.Color = Color3.fromRGB(190, 192, 200)
	manubrio.Material = Enum.Material.Metal
	manubrio.CanCollide = false
	manubrio.Parent = modelo

	-- Cajón de reparto trasero
	local cajon = Instance.new("Part")
	cajon.Name = "CajonReparto"
	cajon.Size = Vector3.new(1.6, 1.3, 1.4)
	cajon.Position = Vector3.new(0, 3.2, 1.9)
	cajon.Color = Color3.fromRGB(30, 32, 38)
	cajon.Material = Enum.Material.SmoothPlastic
	cajon.CanCollide = false
	cajon.Parent = modelo

	return modelo
end

return ModelosVehiculos
