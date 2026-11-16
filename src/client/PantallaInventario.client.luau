local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local PlayerGui = localPlayer:WaitForChild("PlayerGui")

local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)
local Datos = require(ReplicatedStorage.Shared.Datos)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UI_Pantalla_Inventario"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

local fondoOscuro = Instance.new("TextButton")
fondoOscuro.Name = "FondoOscuro"
fondoOscuro.Text = ""
fondoOscuro.Size = UDim2.fromScale(1, 1)
fondoOscuro.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
fondoOscuro.BackgroundTransparency = 0.5
fondoOscuro.Parent = screenGui

local panel = Instance.new("Frame")
panel.Name = "PanelPrincipal"
panel.Size = UDim2.fromOffset(540, 460)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
panel.ClipsDescendants = true
panel.Parent = screenGui

local cornerPanel = Instance.new("UICorner")
cornerPanel.CornerRadius = UDim.new(0, 16)
cornerPanel.Parent = panel

local strokePanel = Instance.new("UIStroke")
strokePanel.Color = Color3.fromRGB(240, 100, 160)
strokePanel.Thickness = 2.5
strokePanel.Parent = panel

-- Cabecera
local cabecera = Instance.new("Frame")
cabecera.Name = "Cabecera"
cabecera.Size = UDim2.new(1, 0, 0, 56)
cabecera.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
cabecera.BorderSizePixel = 0
cabecera.Parent = panel

local titulo = Instance.new("TextLabel")
titulo.Name = "Titulo"
titulo.Size = UDim2.fromScale(0.7, 1)
titulo.Position = UDim2.fromOffset(20, 0)
titulo.BackgroundTransparency = 1
titulo.Font = Enum.Font.FredokaOne
titulo.Text = "🎒 INVENTARIO Y CARGA"
titulo.TextColor3 = Color3.fromRGB(255, 220, 240)
titulo.TextSize = 20
titulo.TextXAlignment = Enum.TextXAlignment.Left
titulo.Parent = cabecera

local botonCerrar = Instance.new("TextButton")
botonCerrar.Name = "BotonCerrar"
botonCerrar.Size = UDim2.fromOffset(34, 34)
botonCerrar.AnchorPoint = Vector2.new(1, 0.5)
botonCerrar.Position = UDim2.new(1, -15, 0.5, 0)
botonCerrar.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
botonCerrar.Font = Enum.Font.GothamBold
botonCerrar.Text = "X"
botonCerrar.TextColor3 = Color3.fromRGB(255, 255, 255)
botonCerrar.TextSize = 15
botonCerrar.Parent = cabecera

local cornerCerrar = Instance.new("UICorner")
cornerCerrar.CornerRadius = UDim.new(0, 8)
cornerCerrar.Parent = botonCerrar

-- Sección de Capacidad del Vehículo
local seccionVehiculo = Instance.new("Frame")
seccionVehiculo.Name = "SeccionVehiculo"
seccionVehiculo.Size = UDim2.new(1, -40, 0, 60)
seccionVehiculo.Position = UDim2.fromOffset(20, 68)
seccionVehiculo.BackgroundColor3 = Color3.fromRGB(30, 36, 48)
seccionVehiculo.Parent = panel

local cornerVehiculo = Instance.new("UICorner")
cornerVehiculo.CornerRadius = UDim.new(0, 10)
cornerVehiculo.Parent = seccionVehiculo

local textoCapacidad = Instance.new("TextLabel")
textoCapacidad.Name = "TextoCapacidad"
textoCapacidad.Size = UDim2.new(1, -24, 0, 22)
textoCapacidad.Position = UDim2.fromOffset(12, 8)
textoCapacidad.BackgroundTransparency = 1
textoCapacidad.Font = Enum.Font.GothamBold
textoCapacidad.Text = "🚗 Carga en Vehículo: 0 / 20 dulces"
textoCapacidad.TextColor3 = Color3.fromRGB(240, 240, 240)
textoCapacidad.TextSize = 13
textoCapacidad.TextXAlignment = Enum.TextXAlignment.Left
textoCapacidad.Parent = seccionVehiculo

local barraFondo = Instance.new("Frame")
barraFondo.Name = "BarraFondo"
barraFondo.Size = UDim2.new(1, -24, 0, 12)
barraFondo.Position = UDim2.fromOffset(12, 34)
barraFondo.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
barraFondo.BorderSizePixel = 0
barraFondo.Parent = seccionVehiculo

local cornerBarraFondo = Instance.new("UICorner")
cornerBarraFondo.CornerRadius = UDim.new(1, 0)
cornerBarraFondo.Parent = barraFondo

local barraRelleno = Instance.new("Frame")
barraRelleno.Name = "BarraRelleno"
barraRelleno.Size = UDim2.fromScale(0, 1)
barraRelleno.BackgroundColor3 = Color3.fromRGB(80, 220, 120)
barraRelleno.BorderSizePixel = 0
barraRelleno.Parent = barraFondo

local cornerBarraRelleno = Instance.new("UICorner")
cornerBarraRelleno.CornerRadius = UDim.new(1, 0)
cornerBarraRelleno.Parent = barraRelleno

-- Banner Alerta de Sobrecarga
local bannerSobrecarga = Instance.new("Frame")
bannerSobrecarga.Name = "BannerSobrecarga"
bannerSobrecarga.Size = UDim2.new(1, -40, 0, 44)
bannerSobrecarga.Position = UDim2.fromOffset(20, 136)
bannerSobrecarga.BackgroundColor3 = Color3.fromRGB(45, 18, 22)
bannerSobrecarga.Visible = false
bannerSobrecarga.Parent = panel

local cornerSobrecarga = Instance.new("UICorner")
cornerSobrecarga.CornerRadius = UDim.new(0, 8)
cornerSobrecarga.Parent = bannerSobrecarga

local strokeSobrecarga = Instance.new("UIStroke")
strokeSobrecarga.Color = Color3.fromRGB(240, 60, 60)
strokeSobrecarga.Thickness = 1.5
strokeSobrecarga.Parent = bannerSobrecarga

local textoSobrecarga = Instance.new("TextLabel")
textoSobrecarga.Name = "TextoSobrecarga"
textoSobrecarga.Size = UDim2.fromScale(1, 1)
textoSobrecarga.BackgroundTransparency = 1
textoSobrecarga.Font = Enum.Font.GothamMedium
textoSobrecarga.Text =
	"⚠️ ¡Mucho peso! Tu velocidad se reduce un 25% y las patrullas te detectan más fácil."
textoSobrecarga.TextColor3 = Color3.fromRGB(255, 200, 200)
textoSobrecarga.TextSize = 11
textoSobrecarga.TextWrapped = true
textoSobrecarga.Parent = bannerSobrecarga

-- Cuadrícula de Dulces
local scrollDulces = Instance.new("ScrollingFrame")
scrollDulces.Name = "ScrollDulces"
scrollDulces.Size = UDim2.new(1, -40, 1, -195)
scrollDulces.Position = UDim2.fromOffset(20, 190)
scrollDulces.BackgroundTransparency = 1
scrollDulces.ScrollBarThickness = 6
scrollDulces.ScrollBarImageColor3 = Color3.fromRGB(70, 90, 120)
scrollDulces.CanvasSize = UDim2.fromScale(0, 0)
scrollDulces.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollDulces.Parent = panel

local layoutGrid = Instance.new("UIGridLayout")
layoutGrid.CellSize = UDim2.fromOffset(220, 80)
layoutGrid.CellPadding = UDim2.fromOffset(12, 10)
layoutGrid.SortOrder = Enum.SortOrder.LayoutOrder
layoutGrid.Parent = scrollDulces

local datosActuales = {
	Inventario = {},
	VehiculoEquipado = "Vehiculo_Bicicleta",
}

local function actualizarVista()
	local infoVehiculo = Datos.Vehiculos[datosActuales.VehiculoEquipado]
	local capacidadMax = (infoVehiculo and infoVehiculo.CapacidadCarga) or 20
	local nombreVehiculo = (infoVehiculo and infoVehiculo.Nombre) or "Vehículo"

	local totalCarga = 0
	for _, cantidad in pairs(datosActuales.Inventario) do
		totalCarga += cantidad
	end

	textoCapacidad.Text =
		string.format("🚗 %s: %d / %d dulces cargados", nombreVehiculo, totalCarga, capacidadMax)

	local ratio = math.clamp(totalCarga / capacidadMax, 0, 1)
	barraRelleno.Size = UDim2.fromScale(ratio, 1)

	if totalCarga > capacidadMax then
		barraRelleno.BackgroundColor3 = Color3.fromRGB(240, 50, 50)
		bannerSobrecarga.Visible = true
		scrollDulces.Position = UDim2.fromOffset(20, 190)
		scrollDulces.Size = UDim2.new(1, -40, 1, -195)
	elseif ratio > 0.75 then
		barraRelleno.BackgroundColor3 = Color3.fromRGB(240, 160, 40)
		bannerSobrecarga.Visible = false
		scrollDulces.Position = UDim2.fromOffset(20, 140)
		scrollDulces.Size = UDim2.new(1, -40, 1, -145)
	else
		barraRelleno.BackgroundColor3 = Color3.fromRGB(70, 220, 110)
		bannerSobrecarga.Visible = false
		scrollDulces.Position = UDim2.fromOffset(20, 140)
		scrollDulces.Size = UDim2.new(1, -40, 1, -145)
	end

	-- Limpiar slots previos
	for _, child in ipairs(scrollDulces:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local hayDulces = false
	for idDulce, cantidad in pairs(datosActuales.Inventario) do
		if cantidad > 0 then
			hayDulces = true
			local info = Datos.Dulces[idDulce]
			local nombreDulce = if info then info.Nombre else idDulce
			local valorVenta = if info then info.ValorVenta else 1

			local card = Instance.new("Frame")
			card.Name = "Slot_" .. idDulce
			card.BackgroundColor3 = Color3.fromRGB(34, 40, 54)
			card.Parent = scrollDulces

			local cornerCard = Instance.new("UICorner")
			cornerCard.CornerRadius = UDim.new(0, 10)
			cornerCard.Parent = card

			local strokeCard = Instance.new("UIStroke")
			strokeCard.Color = Color3.fromRGB(60, 80, 110)
			strokeCard.Thickness = 1.5
			strokeCard.Parent = card

			local icono = Instance.new("TextLabel")
			icono.Size = UDim2.fromOffset(40, 40)
			icono.Position = UDim2.fromOffset(12, 10)
			icono.BackgroundTransparency = 1
			icono.Font = Enum.Font.FredokaOne
			icono.Text = "🍬"
			icono.TextSize = 28
			icono.Parent = card

			local labelNombre = Instance.new("TextLabel")
			labelNombre.Size = UDim2.new(1, -60, 0, 20)
			labelNombre.Position = UDim2.fromOffset(56, 10)
			labelNombre.BackgroundTransparency = 1
			labelNombre.Font = Enum.Font.GothamBold
			labelNombre.Text = nombreDulce
			labelNombre.TextColor3 = Color3.fromRGB(255, 255, 255)
			labelNombre.TextSize = 13
			labelNombre.TextXAlignment = Enum.TextXAlignment.Left
			labelNombre.Parent = card

			local labelCantidad = Instance.new("TextLabel")
			labelCantidad.Size = UDim2.new(1, -60, 0, 16)
			labelCantidad.Position = UDim2.fromOffset(56, 30)
			labelCantidad.BackgroundTransparency = 1
			labelCantidad.Font = Enum.Font.GothamMedium
			labelCantidad.Text = string.format("Cantidad: x%d", cantidad)
			labelCantidad.TextColor3 = Color3.fromRGB(150, 230, 160)
			labelCantidad.TextSize = 12
			labelCantidad.TextXAlignment = Enum.TextXAlignment.Left
			labelCantidad.Parent = card

			local labelValor = Instance.new("TextLabel")
			labelValor.Size = UDim2.new(1, -60, 0, 16)
			labelValor.Position = UDim2.fromOffset(56, 48)
			labelValor.BackgroundTransparency = 1
			labelValor.Font = Enum.Font.GothamMedium
			labelValor.Text = string.format("Valor base: $%d c/u", valorVenta)
			labelValor.TextColor3 = Color3.fromRGB(240, 200, 100)
			labelValor.TextSize = 11
			labelValor.TextXAlignment = Enum.TextXAlignment.Left
			labelValor.Parent = card
		end
	end

	if not hayDulces then
		local vacio = Instance.new("TextLabel")
		vacio.Name = "TextoVacio"
		vacio.Size = UDim2.new(1, 0, 0, 60)
		vacio.BackgroundTransparency = 1
		vacio.Font = Enum.Font.GothamMedium
		vacio.Text =
			"No tienes dulces cargados.\n¡Ve a la cocina clandestina a preparar tu primera tanda!"
		vacio.TextColor3 = Color3.fromRGB(160, 170, 190)
		vacio.TextSize = 13
		vacio.TextWrapped = true
		vacio.Parent = scrollDulces
	end
end

local function abrirInventario()
	actualizarVista()
	screenGui.Enabled = true
	panel.Position = UDim2.fromScale(0.5, 0.55)
	panel.BackgroundTransparency = 1

	TweenService
		:Create(panel, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundTransparency = 0,
		})
		:Play()
end

local function cerrarInventario()
	local tween = TweenService:Create(
		panel,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{
			Position = UDim2.fromScale(0.5, 0.55),
			BackgroundTransparency = 1,
		}
	)
	tween:Play()
	tween.Completed:Connect(function()
		screenGui.Enabled = false
	end)
end

botonCerrar.MouseButton1Click:Connect(cerrarInventario)
fondoOscuro.MouseButton1Click:Connect(cerrarInventario)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.I then
		if screenGui.Enabled then
			cerrarInventario()
		else
			abrirInventario()
		end
	end
end)

EventosRemotos.DatosActualizados.OnClientEvent:Connect(function(nuevosDatos)
	if nuevosDatos then
		datosActuales.Inventario = nuevosDatos.Inventario or {}
		datosActuales.VehiculoEquipado = nuevosDatos.VehiculoEquipado or "Vehiculo_Bicicleta"
		if screenGui.Enabled then
			actualizarVista()
		end
	end
end)

task.spawn(function()
	local inicial = EventosRemotos.SolicitarDatos:InvokeServer()
	if inicial then
		datosActuales.Inventario = inicial.Inventario or {}
		datosActuales.VehiculoEquipado = inicial.VehiculoEquipado or "Vehiculo_Bicicleta"
	end
end)
