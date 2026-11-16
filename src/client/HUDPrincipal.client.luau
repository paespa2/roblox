local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local EventosRemotos = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Eventos"):WaitForChild("EventosRemotos")
)
local Datos = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Datos"))

-- Crear ScreenGui Principal
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HUD_ElPatronDelDulce"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

-- Contenedor Superior Izquierdo (Billetera y Fama)
local marcoSuperior = Instance.new("Frame")
marcoSuperior.Name = "MarcoSuperior"
marcoSuperior.Size = UDim2.fromOffset(280, 130)
marcoSuperior.Position = UDim2.fromOffset(20, 20)
marcoSuperior.BackgroundTransparency = 1
marcoSuperior.Parent = screenGui

-- Pill de Pesos Dulces
local pillPesos = Instance.new("Frame")
pillPesos.Name = "PillPesos"
pillPesos.Size = UDim2.new(1, 0, 0, 42)
pillPesos.Position = UDim2.fromOffset(0, 0)
pillPesos.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
pillPesos.BackgroundTransparency = 0.15
pillPesos.Parent = marcoSuperior

local cornerPesos = Instance.new("UICorner")
cornerPesos.CornerRadius = UDim.new(0, 10)
cornerPesos.Parent = pillPesos

local strokePesos = Instance.new("UIStroke")
strokePesos.Color = Color3.fromRGB(245, 180, 40)
strokePesos.Thickness = 2
strokePesos.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
strokePesos.Parent = pillPesos

local iconoPesos = Instance.new("TextLabel")
iconoPesos.Name = "Icono"
iconoPesos.Size = UDim2.new(0, 36, 1, 0)
iconoPesos.Position = UDim2.fromOffset(8, 0)
iconoPesos.BackgroundTransparency = 1
iconoPesos.Text = "💰"
iconoPesos.TextSize = 22
iconoPesos.Parent = pillPesos

local textoPesos = Instance.new("TextLabel")
textoPesos.Name = "TextoPesos"
textoPesos.Size = UDim2.new(1, -50, 1, 0)
textoPesos.Position = UDim2.fromOffset(46, 0)
textoPesos.BackgroundTransparency = 1
textoPesos.Font = Enum.Font.FredokaOne
textoPesos.Text = "0 Pesos Dulces"
textoPesos.TextColor3 = Color3.fromRGB(255, 235, 170)
textoPesos.TextSize = 18
textoPesos.TextXAlignment = Enum.TextXAlignment.Left
textoPesos.Parent = pillPesos

-- Pill de Fama
local pillFama = Instance.new("Frame")
pillFama.Name = "PillFama"
pillFama.Size = UDim2.new(1, 0, 0, 34)
pillFama.Position = UDim2.fromOffset(0, 48)
pillFama.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
pillFama.BackgroundTransparency = 0.25
pillFama.Parent = marcoSuperior

local cornerFama = Instance.new("UICorner")
cornerFama.CornerRadius = UDim.new(0, 8)
cornerFama.Parent = pillFama

local strokeFama = Instance.new("UIStroke")
strokeFama.Color = Color3.fromRGB(150, 100, 220)
strokeFama.Thickness = 1.5
strokeFama.Parent = pillFama

local iconoFama = Instance.new("TextLabel")
iconoFama.Name = "Icono"
iconoFama.Size = UDim2.new(0, 30, 1, 0)
iconoFama.Position = UDim2.fromOffset(8, 0)
iconoFama.BackgroundTransparency = 1
iconoFama.Text = "⭐"
iconoFama.TextSize = 16
iconoFama.Parent = pillFama

local textoFama = Instance.new("TextLabel")
textoFama.Name = "TextoFama"
textoFama.Size = UDim2.new(1, -45, 1, 0)
textoFama.Position = UDim2.fromOffset(42, 0)
textoFama.BackgroundTransparency = 1
textoFama.Font = Enum.Font.FredokaOne
textoFama.Text = "Fama: 0"
textoFama.TextColor3 = Color3.fromRGB(220, 200, 255)
textoFama.TextSize = 15
textoFama.TextXAlignment = Enum.TextXAlignment.Left
textoFama.Parent = pillFama

-- Botón de Mejoras
local botonMejoras = Instance.new("TextButton")
botonMejoras.Name = "BotonMejoras"
botonMejoras.Size = UDim2.new(1, 0, 0, 34)
botonMejoras.Position = UDim2.fromOffset(0, 88)
botonMejoras.BackgroundColor3 = Color3.fromRGB(30, 40, 58)
botonMejoras.BackgroundTransparency = 0.2
botonMejoras.Font = Enum.Font.FredokaOne
botonMejoras.Text = "🛒 Mejoras del Negocio"
botonMejoras.TextColor3 = Color3.fromRGB(255, 230, 120)
botonMejoras.TextSize = 14
botonMejoras.Parent = marcoSuperior

local cornerMejoras = Instance.new("UICorner")
cornerMejoras.CornerRadius = UDim.new(0, 8)
cornerMejoras.Parent = botonMejoras

local strokeMejoras = Instance.new("UIStroke")
strokeMejoras.Color = Color3.fromRGB(70, 160, 240)
strokeMejoras.Thickness = 1.5
strokeMejoras.Parent = botonMejoras

botonMejoras.MouseButton1Click:Connect(function()
	EventosRemotos.AbrirTiendaMejoras:FireServer()
end)

-- Contenedor Inferior (Inventario de carga)
local marcoInventario = Instance.new("Frame")
marcoInventario.Name = "MarcoInventario"
marcoInventario.Size = UDim2.fromOffset(320, 50)
marcoInventario.Position = UDim2.new(0, 20, 1, -70)
marcoInventario.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
marcoInventario.BackgroundTransparency = 0.2
marcoInventario.Parent = screenGui

local cornerInv = Instance.new("UICorner")
cornerInv.CornerRadius = UDim.new(0, 10)
cornerInv.Parent = marcoInventario

local strokeInv = Instance.new("UIStroke")
strokeInv.Color = Color3.fromRGB(240, 100, 160)
strokeInv.Thickness = 1.5
strokeInv.Parent = marcoInventario

local textoInventario = Instance.new("TextLabel")
textoInventario.Name = "TextoInventario"
textoInventario.Size = UDim2.new(1, -20, 1, 0)
textoInventario.Position = UDim2.fromOffset(12, 0)
textoInventario.BackgroundTransparency = 1
textoInventario.Font = Enum.Font.FredokaOne
textoInventario.Text = "🎒 Carga: Vacía (¡Cocina en la paila!)"
textoInventario.TextColor3 = Color3.fromRGB(255, 230, 240)
textoInventario.TextSize = 15
textoInventario.TextXAlignment = Enum.TextXAlignment.Left
textoInventario.Parent = marcoInventario

-- Notificación Banner Superior Central
local bannerNotificacion = Instance.new("Frame")
bannerNotificacion.Name = "BannerNotificacion"
bannerNotificacion.Size = UDim2.fromOffset(360, 44)
bannerNotificacion.Position = UDim2.new(0.5, -180, 0, -60) -- Oculto arriba
bannerNotificacion.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
bannerNotificacion.BackgroundTransparency = 0.1
bannerNotificacion.Parent = screenGui

local cornerBanner = Instance.new("UICorner")
cornerBanner.CornerRadius = UDim.new(0, 12)
cornerBanner.Parent = bannerNotificacion

local strokeBanner = Instance.new("UIStroke")
strokeBanner.Color = Color3.fromRGB(255, 215, 0)
strokeBanner.Thickness = 2
strokeBanner.Parent = bannerNotificacion

local textoBanner = Instance.new("TextLabel")
textoBanner.Name = "Texto"
textoBanner.Size = UDim2.new(1, -20, 1, 0)
textoBanner.Position = UDim2.fromOffset(10, 0)
textoBanner.BackgroundTransparency = 1
textoBanner.Font = Enum.Font.FredokaOne
textoBanner.Text = "¡Notificación!"
textoBanner.TextColor3 = Color3.fromRGB(255, 255, 255)
textoBanner.TextSize = 16
textoBanner.Parent = bannerNotificacion

local function mostrarBanner(mensaje: string, colorStroke: Color3?)
	strokeBanner.Color = colorStroke or Color3.fromRGB(255, 215, 0)
	textoBanner.Text = mensaje

	bannerNotificacion.Position = UDim2.new(0.5, -180, 0, -60)
	local tweenBajar = TweenService:Create(
		bannerNotificacion,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, -180, 0, 25) }
	)
	tweenBajar:Play()

	task.delay(3, function()
		local tweenSubir = TweenService:Create(
			bannerNotificacion,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(0.5, -180, 0, -60) }
		)
		tweenSubir:Play()
	end)
end

-- Efecto de pulso / escala en Pill de Pesos
local function animarPesos(nuevoMonto: number)
	textoPesos.Text = string.format("%d Pesos Dulces", nuevoMonto)

	local tweenGrande = TweenService:Create(
		pillPesos,
		TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.new(1, 15, 0, 48) }
	)
	local tweenNormal = TweenService:Create(
		pillPesos,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = UDim2.new(1, 0, 0, 42) }
	)

	tweenGrande:Play()
	tweenGrande.Completed:Connect(function()
		tweenNormal:Play()
	end)
end

-- Actualizar visualmente el inventario en el HUD
local function actualizarInventario(inventario: { [string]: number })
	local listaTextos = {}
	local totalDulces = 0

	for idDulce, cantidad in pairs(inventario) do
		if cantidad > 0 then
			local info = Datos.Dulces[idDulce]
			local nombre = if info then info.Nombre else idDulce
			table.insert(listaTextos, string.format("%s: %d", nombre, cantidad))
			totalDulces += cantidad
		end
	end

	if totalDulces > 0 then
		textoInventario.Text = "🎒 Carga: " .. table.concat(listaTextos, " | ")
		textoInventario.TextColor3 = Color3.fromRGB(255, 235, 120)
	else
		textoInventario.Text = "🎒 Carga: Vacía (¡Cocina en la paila!)"
		textoInventario.TextColor3 = Color3.fromRGB(200, 200, 210)
	end
end

-- Conexión de eventos
EventosRemotos.DatosActualizados.OnClientEvent:Connect(function(datos)
	animarPesos(datos.PesosDulces)
	textoFama.Text = string.format("Fama: %d ⭐", datos.Fama)
	actualizarInventario(datos.Inventario)
end)

EventosRemotos.CocinaActualizada.OnClientEvent:Connect(function(info)
	if info.Recogido then
		local nombre = if Datos.Dulces[info.IdDulce]
			then Datos.Dulces[info.IdDulce].Nombre
			else info.IdDulce
		mostrarBanner(
			string.format("🍬 ¡Empacaste %d %s!", info.Cantidad or 5, nombre),
			Color3.fromRGB(100, 255, 150)
		)
	elseif info.Listo then
		local nombre = if Datos.Dulces[info.IdDulce]
			then Datos.Dulces[info.IdDulce].Nombre
			else info.IdDulce
		mostrarBanner(
			string.format("✨ ¡%s listos en la paila! Presiona E", nombre),
			Color3.fromRGB(255, 220, 60)
		)
	else
		local nombre = if Datos.Dulces[info.IdDulce]
			then Datos.Dulces[info.IdDulce].Nombre
			else info.IdDulce
		mostrarBanner(
			string.format("⏳ Cocinando %s (%ds)...", nombre, info.Duracion),
			Color3.fromRGB(240, 140, 200)
		)
	end
end)

EventosRemotos.VentaCompletada.OnClientEvent:Connect(function(resumen)
	mostrarBanner(
		string.format("💰 ¡Vendiste en %s por +$%d!", resumen.Tienda, resumen.PesosGanados),
		Color3.fromRGB(255, 215, 0)
	)
end)
