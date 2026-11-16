local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)

local function obtenerMostradorDonAbaco(): BasePart?
	local mapa = Workspace:WaitForChild("Mapa", 10)
	if not mapa then
		return nil
	end

	local t2 = mapa:FindFirstChild("Tienda_Barrio02")
	if t2 then
		local mostrador = t2:FindFirstChild("Mostrador")
		if mostrador and mostrador:IsA("BasePart") then
			return mostrador
		end
		-- Si no tiene Mostrador directo, buscar en hijos
		for _, child in ipairs(t2:GetChildren()) do
			if child:IsA("BasePart") and string.find(string.lower(child.Name), "mostrador") then
				return child
			end
		end
	end

	return nil
end

local function crearBillboardDonAbaco(mostrador: BasePart)
	local existente = mostrador:FindFirstChild("CartelDonAbaco")
	if existente then
		existente:Destroy()
	end

	local bbg = Instance.new("BillboardGui")
	bbg.Name = "CartelDonAbaco"
	bbg.Size = UDim2.fromOffset(200, 65)
	bbg.StudsOffset = Vector3.new(0, 3.5, 0)
	bbg.AlwaysOnTop = false
	bbg.MaxDistance = 45
	bbg.Parent = mostrador

	local fondo = Instance.new("Frame")
	fondo.Name = "Fondo"
	fondo.Size = UDim2.fromScale(1, 1)
	fondo.BackgroundColor3 = Color3.fromRGB(24, 28, 36)
	fondo.BackgroundTransparency = 0.15
	fondo.Parent = bbg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = fondo

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(70, 170, 255)
	stroke.Thickness = 2
	stroke.Parent = fondo

	local titulo = Instance.new("TextLabel")
	titulo.Name = "Titulo"
	titulo.Size = UDim2.fromScale(1, 0.5)
	titulo.BackgroundTransparency = 1
	titulo.Font = Enum.Font.FredokaOne
	titulo.Text = "Don Ábaco"
	titulo.TextColor3 = Color3.fromRGB(255, 235, 120)
	titulo.TextSize = 18
	titulo.Parent = fondo

	local subtitulo = Instance.new("TextLabel")
	subtitulo.Name = "Subtitulo"
	subtitulo.Size = UDim2.fromScale(1, 0.5)
	subtitulo.Position = UDim2.fromScale(0, 0.5)
	subtitulo.BackgroundTransparency = 1
	subtitulo.Font = Enum.Font.GothamMedium
	subtitulo.Text = "🛒 Mejoras & Vehículos"
	subtitulo.TextColor3 = Color3.fromRGB(200, 220, 240)
	subtitulo.TextSize = 13
	subtitulo.Parent = fondo
end

local function configurarDonAbaco()
	local mostrador = obtenerMostradorDonAbaco()
	if not mostrador then
		warn("El Patrón del Dulce: No se encontró el mostrador de Don Ábaco en Tienda_Barrio02")
		return
	end

	crearBillboardDonAbaco(mostrador)

	local prompt = mostrador:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "PromptDonAbaco"
		prompt.ObjectText = "Don Ábaco (Tendero)"
		prompt.ActionText = "Ver Mejoras del Negocio"
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Parent = mostrador
	end

	prompt.Triggered:Connect(function(player: Player)
		EventosRemotos.AbrirTiendaMejoras:FireClient(player)
	end)

	EventosRemotos.AbrirTiendaMejoras.OnServerEvent:Connect(function(player: Player)
		EventosRemotos.AbrirTiendaMejoras:FireClient(player)
	end)

	print("El Patrón del Dulce: Interacción con Don Ábaco configurada en Tienda_Barrio02")
end

task.spawn(configurarDonAbaco)
