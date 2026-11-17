local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local PlayerGui = localPlayer:WaitForChild("PlayerGui")

local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)
local Datos = require(ReplicatedStorage.Shared.Datos)

type PerfilJugador = {
	PesosDulces: number,
	Fama: number,
	AzucarDorada: number,
	Inventario: { [string]: number },
	RecetasDesbloqueadas: { [string]: boolean },
	MejorasCompradas: { [string]: boolean },
	VehiculosComprados: { [string]: boolean },
	CapituloActual: number,
	VehiculoEquipado: string,
	EstrellasBusqueda: number,
}

local datosActuales: PerfilJugador = {
	PesosDulces = 0,
	Fama = 0,
	AzucarDorada = 0,
	Inventario = {},
	RecetasDesbloqueadas = {},
	MejorasCompradas = {},
	VehiculosComprados = { ["Vehiculo_Bicicleta"] = true },
	CapituloActual = 1,
	VehiculoEquipado = "Vehiculo_Bicicleta",
	EstrellasBusqueda = 0,
}

local pestanaActiva = "Cocina" -- "Cocina", "Vehiculos", "Bodega"

-- UI Containers
local previo = PlayerGui:FindFirstChild("UI_Pantalla_Mejoras")
if previo then
	previo:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UI_Pantalla_Mejoras"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

local fondoOscuro = Instance.new("TextButton")
fondoOscuro.Name = "FondoOscuro"
fondoOscuro.Text = ""
fondoOscuro.Size = UDim2.fromScale(1, 1)
fondoOscuro.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
fondoOscuro.BackgroundTransparency = 0.45
fondoOscuro.Parent = screenGui

local panel = Instance.new("Frame")
panel.Name = "PanelPrincipal"
panel.Size = UDim2.fromOffset(580, 480)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
panel.ClipsDescendants = true
panel.Parent = screenGui

local cornerPanel = Instance.new("UICorner")
cornerPanel.CornerRadius = UDim.new(0, 16)
cornerPanel.Parent = panel

local strokePanel = Instance.new("UIStroke")
strokePanel.Color = Color3.fromRGB(70, 160, 240)
strokePanel.Thickness = 2.5
strokePanel.Parent = panel

-- Cabecera
local cabecera = Instance.new("Frame")
cabecera.Name = "Cabecera"
cabecera.Size = UDim2.new(1, 0, 0, 60)
cabecera.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
cabecera.BorderSizePixel = 0
cabecera.Parent = panel

local titulo = Instance.new("TextLabel")
titulo.Name = "Titulo"
titulo.Size = UDim2.fromScale(0.6, 1)
titulo.Position = UDim2.fromOffset(20, 0)
titulo.BackgroundTransparency = 1
titulo.Font = Enum.Font.FredokaOne
titulo.Text = "MEJORAS DEL NEGOCIO"
titulo.TextColor3 = Color3.fromRGB(255, 230, 100)
titulo.TextSize = 22
titulo.TextXAlignment = Enum.TextXAlignment.Left
titulo.Parent = cabecera

local saldoLabel = Instance.new("TextLabel")
saldoLabel.Name = "SaldoLabel"
saldoLabel.Size = UDim2.fromScale(0.35, 1)
saldoLabel.Position = UDim2.new(0.6, -50, 0, 0)
saldoLabel.BackgroundTransparency = 1
saldoLabel.Font = Enum.Font.GothamBold
saldoLabel.Text = "💰 0 pesos"
saldoLabel.TextColor3 = Color3.fromRGB(120, 240, 130)
saldoLabel.TextSize = 16
saldoLabel.TextXAlignment = Enum.TextXAlignment.Right
saldoLabel.Parent = cabecera

local botonCerrar = Instance.new("TextButton")
botonCerrar.Name = "BotonCerrar"
botonCerrar.Size = UDim2.fromOffset(36, 36)
botonCerrar.AnchorPoint = Vector2.new(1, 0.5)
botonCerrar.Position = UDim2.new(1, -15, 0.5, 0)
botonCerrar.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
botonCerrar.Font = Enum.Font.GothamBold
botonCerrar.Text = "X"
botonCerrar.TextColor3 = Color3.fromRGB(255, 255, 255)
botonCerrar.TextSize = 16
botonCerrar.Parent = cabecera

local cornerCerrar = Instance.new("UICorner")
cornerCerrar.CornerRadius = UDim.new(0, 8)
cornerCerrar.Parent = botonCerrar

-- Barra de Pestañas
local barraPestanas = Instance.new("Frame")
barraPestanas.Name = "BarraPestanas"
barraPestanas.Size = UDim2.new(1, -40, 0, 42)
barraPestanas.Position = UDim2.fromOffset(20, 72)
barraPestanas.BackgroundTransparency = 1
barraPestanas.Parent = panel

local layoutPestanas = Instance.new("UIListLayout")
layoutPestanas.FillDirection = Enum.FillDirection.Horizontal
layoutPestanas.HorizontalAlignment = Enum.HorizontalAlignment.Left
layoutPestanas.Padding = UDim.new(0, 12)
layoutPestanas.Parent = barraPestanas

-- Contenedor de Contenido (Tarjetas)
local scrollContenido = Instance.new("ScrollingFrame")
scrollContenido.Name = "ScrollContenido"
scrollContenido.Size = UDim2.new(1, -40, 1, -135)
scrollContenido.Position = UDim2.fromOffset(20, 122)
scrollContenido.BackgroundTransparency = 1
scrollContenido.ScrollBarThickness = 6
scrollContenido.ScrollBarImageColor3 = Color3.fromRGB(80, 100, 130)
scrollContenido.CanvasSize = UDim2.fromScale(0, 0)
scrollContenido.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollContenido.Parent = panel

local layoutTarjetas = Instance.new("UIListLayout")
layoutTarjetas.SortOrder = Enum.SortOrder.LayoutOrder
layoutTarjetas.Padding = UDim.new(0, 10)
layoutTarjetas.Parent = scrollContenido

local botonesPestanas = {}

local function reproducirSonido(idSonido: string)
	local sound = Instance.new("Sound")
	sound.SoundId = idSonido
	sound.Volume = 0.6
	sound.Parent = SoundService
	sound:Play()
	task.delay(1.5, function()
		sound:Destroy()
	end)
end

local function crearTarjeta(config: {
	Titulo: string,
	Efecto: string,
	Precio: number,
	Comprado: boolean,
	Equipado: boolean?,
	OnComprar: () -> (),
	OnEquipar: (() -> ())?,
})
	local tarjeta = Instance.new("Frame")
	tarjeta.Name = "Tarjeta_" .. config.Titulo
	tarjeta.Size = UDim2.new(1, -8, 0, 85)
	tarjeta.BackgroundColor3 = Color3.fromRGB(36, 42, 56)
	tarjeta.Parent = scrollContenido

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = tarjeta

	local stroke = Instance.new("UIStroke")
	stroke.Color = if config.Comprado
		then Color3.fromRGB(70, 180, 100)
		else Color3.fromRGB(60, 75, 100)
	stroke.Thickness = 1.5
	stroke.Parent = tarjeta

	local infoContainer = Instance.new("Frame")
	infoContainer.Size = UDim2.fromScale(0.65, 1)
	infoContainer.Position = UDim2.fromOffset(15, 0)
	infoContainer.BackgroundTransparency = 1
	infoContainer.Parent = tarjeta

	local nombreLabel = Instance.new("TextLabel")
	nombreLabel.Size = UDim2.fromScale(1, 0.45)
	nombreLabel.Position = UDim2.fromOffset(0, 10)
	nombreLabel.BackgroundTransparency = 1
	nombreLabel.Font = Enum.Font.GothamBold
	nombreLabel.Text = config.Titulo
	nombreLabel.TextColor3 = Color3.fromRGB(250, 250, 250)
	nombreLabel.TextSize = 16
	nombreLabel.TextXAlignment = Enum.TextXAlignment.Left
	nombreLabel.Parent = infoContainer

	local efectoLabel = Instance.new("TextLabel")
	efectoLabel.Size = UDim2.fromScale(1, 0.45)
	efectoLabel.Position = UDim2.fromOffset(0, 36)
	efectoLabel.BackgroundTransparency = 1
	efectoLabel.Font = Enum.Font.GothamMedium
	efectoLabel.Text = config.Efecto
	efectoLabel.TextColor3 = Color3.fromRGB(180, 200, 220)
	efectoLabel.TextSize = 13
	efectoLabel.TextXAlignment = Enum.TextXAlignment.Left
	efectoLabel.Parent = infoContainer

	local botonAccion = Instance.new("TextButton")
	botonAccion.Size = UDim2.fromOffset(140, 42)
	botonAccion.AnchorPoint = Vector2.new(1, 0.5)
	botonAccion.Position = UDim2.new(1, -15, 0.5, 0)
	botonAccion.Font = Enum.Font.GothamBold
	botonAccion.TextSize = 14
	botonAccion.Parent = tarjeta

	local cornerBoton = Instance.new("UICorner")
	cornerBoton.CornerRadius = UDim.new(0, 8)
	cornerBoton.Parent = botonAccion

	if config.Comprado then
		if config.OnEquipar then
			if config.Equipado then
				botonAccion.Text = "EQUIPADO ✓"
				botonAccion.BackgroundColor3 = Color3.fromRGB(45, 120, 65)
				botonAccion.TextColor3 = Color3.fromRGB(220, 255, 220)
			else
				botonAccion.Text = "EQUIPAR"
				botonAccion.BackgroundColor3 = Color3.fromRGB(50, 110, 200)
				botonAccion.TextColor3 = Color3.fromRGB(255, 255, 255)
				botonAccion.MouseButton1Click:Connect(function()
					config.OnEquipar()
				end)
			end
		else
			botonAccion.Text = "ADQUIRIDO ✓"
			botonAccion.BackgroundColor3 = Color3.fromRGB(45, 120, 65)
			botonAccion.TextColor3 = Color3.fromRGB(200, 255, 200)
		end
	else
		local puedeComprar = datosActuales.PesosDulces >= config.Precio
		botonAccion.Text = string.format("Comprar $%d", config.Precio)
		botonAccion.BackgroundColor3 = if puedeComprar
			then Color3.fromRGB(230, 140, 30)
			else Color3.fromRGB(70, 70, 80)
		botonAccion.TextColor3 = if puedeComprar
			then Color3.fromRGB(255, 255, 255)
			else Color3.fromRGB(150, 150, 160)

		if puedeComprar then
			botonAccion.MouseButton1Click:Connect(function()
				botonAccion.Text = "Procesando..."
				config.OnComprar()
			end)
		end
	end
end

local function actualizarVista()
	saldoLabel.Text = string.format("💰 %d pesos", datosActuales.PesosDulces)

	-- Limpiar tarjetas previas
	for _, child in ipairs(scrollContenido:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Actualizar colores de pestañas
	for nombre, btn in pairs(botonesPestanas) do
		local activa = (nombre == pestanaActiva)
		btn.BackgroundColor3 = if activa
			then Color3.fromRGB(70, 150, 235)
			else Color3.fromRGB(36, 42, 54)
		btn.TextColor3 = if activa
			then Color3.fromRGB(255, 255, 255)
			else Color3.fromRGB(160, 180, 200)
	end

	if pestanaActiva == "Cocina" then
		-- Mejora Velocidad 1
		local m1 = Datos.Mejoras.Mejora_Cocina_Velocidad_1
		local m1Comprada = datosActuales.MejorasCompradas["Mejora_Cocina_Velocidad_1"] == true
		crearTarjeta({
			Titulo = "🔥 Velocidad de Cocina Niv. 1",
			Efecto = "Reduce el tiempo de cocción un -15%",
			Precio = m1.Precio,
			Comprado = m1Comprada,
			OnComprar = function()
				local exito, msg = EventosRemotos.SolicitarCompraMejora:InvokeServer(m1.Id)
				if exito then
					reproducirSonido("rbxassetid://9069609268")
				else
					warn(msg)
				end
			end,
		})

		-- Mejora Velocidad 2
		local m2 = Datos.Mejoras.Mejora_Cocina_Velocidad_2
		local m2Comprada = datosActuales.MejorasCompradas["Mejora_Cocina_Velocidad_2"] == true
		crearTarjeta({
			Titulo = "⚡ Velocidad de Cocina Niv. 2",
			Efecto = "Reduce el tiempo de cocción un -30%",
			Precio = m2.Precio,
			Comprado = m2Comprada,
			OnComprar = function()
				local exito, msg = EventosRemotos.SolicitarCompraMejora:InvokeServer(m2.Id)
				if exito then
					reproducirSonido("rbxassetid://9069609268")
				else
					warn(msg)
				end
			end,
		})

		-- Mejora Receta Extra
		local mReceta = Datos.Mejoras.Mejora_Cocina_RecetaExtra_1
		local mRecetaComprada = datosActuales.MejorasCompradas["Mejora_Cocina_RecetaExtra_1"]
			== true
		crearTarjeta({
			Titulo = "🍯 Segunda Olla Clandestina",
			Efecto = "Permite producir tandas dobles simultáneas",
			Precio = mReceta.Precio,
			Comprado = mRecetaComprada,
			OnComprar = function()
				local exito, msg = EventosRemotos.SolicitarCompraMejora:InvokeServer(mReceta.Id)
				if exito then
					reproducirSonido("rbxassetid://9069609268")
				else
					warn(msg)
				end
			end,
		})
	elseif pestanaActiva == "Vehiculos" then
		-- Bicicleta
		local vBici = Datos.Vehiculos.Vehiculo_Bicicleta
		local biciEquipada = (datosActuales.VehiculoEquipado == "Vehiculo_Bicicleta")
		crearTarjeta({
			Titulo = "🚲 " .. vBici.Nombre,
			Efecto = string.format(
				"Carga: %d dulces | Vel: %d km/h",
				vBici.CapacidadCarga,
				vBici.VelocidadMax
			),
			Precio = 0,
			Comprado = true,
			Equipado = biciEquipada,
			OnComprar = function() end,
			OnEquipar = function()
				EventosRemotos.SolicitarEquiparVehiculo:InvokeServer("Vehiculo_Bicicleta")
			end,
		})

		-- Moto
		local vMoto = Datos.Vehiculos.Vehiculo_Moto
		local motoComprada = datosActuales.VehiculosComprados["Vehiculo_Moto"] == true
		local motoEquipada = (datosActuales.VehiculoEquipado == "Vehiculo_Moto")
		crearTarjeta({
			Titulo = "🏍️ " .. vMoto.Nombre,
			Efecto = string.format(
				"Carga: %d dulces | Vel: %d km/h | 1 Escondite",
				vMoto.CapacidadCarga,
				vMoto.VelocidadMax
			),
			Precio = vMoto.Precio,
			Comprado = motoComprada,
			Equipado = motoEquipada,
			OnComprar = function()
				local exito, msg =
					EventosRemotos.SolicitarCompraVehiculo:InvokeServer("Vehiculo_Moto")
				if exito then
					reproducirSonido("rbxassetid://9069609268")
				else
					warn(msg)
				end
			end,
			OnEquipar = function()
				EventosRemotos.SolicitarEquiparVehiculo:InvokeServer("Vehiculo_Moto")
			end,
		})
	elseif pestanaActiva == "Bodega" then
		-- Bodega 1
		local b1 = Datos.Mejoras.Mejora_Bodega_Capacidad_1
		local b1Comprada = datosActuales.MejorasCompradas["Mejora_Bodega_Capacidad_1"] == true
		crearTarjeta({
			Titulo = "📦 Almacén de Ausencia Niv. 1",
			Efecto = "Capacidad offline: 200 dulces acumulados",
			Precio = b1.Precio,
			Comprado = b1Comprada,
			OnComprar = function()
				local exito, msg = EventosRemotos.SolicitarCompraMejora:InvokeServer(b1.Id)
				if exito then
					reproducirSonido("rbxassetid://9069609268")
				else
					warn(msg)
				end
			end,
		})

		-- Bodega 2
		local b2 = Datos.Mejoras.Mejora_Bodega_Capacidad_2
		local b2Comprada = datosActuales.MejorasCompradas["Mejora_Bodega_Capacidad_2"] == true
		crearTarjeta({
			Titulo = "🏭 Almacén de Ausencia Niv. 2",
			Efecto = "Capacidad offline: 500 dulces acumulados",
			Precio = b2.Precio,
			Comprado = b2Comprada,
			OnComprar = function()
				local exito, msg = EventosRemotos.SolicitarCompraMejora:InvokeServer(b2.Id)
				if exito then
					reproducirSonido("rbxassetid://9069609268")
				else
					warn(msg)
				end
			end,
		})
	end
end

local function crearBotonPestana(nombre: string)
	local boton = Instance.new("TextButton")
	boton.Name = "Pestana_" .. nombre
	boton.Size = UDim2.fromOffset(120, 36)
	boton.Font = Enum.Font.GothamBold
	boton.Text = nombre
	boton.TextSize = 14
	boton.Parent = barraPestanas

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = boton

	botonesPestanas[nombre] = boton

	boton.MouseButton1Click:Connect(function()
		pestanaActiva = nombre
		actualizarVista()
	end)
end

crearBotonPestana("Cocina")
crearBotonPestana("Vehiculos")
crearBotonPestana("Bodega")

local estaAbierto = false

local function abrirTienda(pestanaInicial: string?)
	if estaAbierto then
		if pestanaInicial and pestanaInicial ~= pestanaActiva then
			pestanaActiva = pestanaInicial
			actualizarVista()
		end
		return
	end
	estaAbierto = true
	if pestanaInicial then
		pestanaActiva = pestanaInicial
	end
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

local function cerrarTienda()
	if not estaAbierto then
		return
	end
	estaAbierto = false
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
		if not estaAbierto then
			screenGui.Enabled = false
		end
	end)
end

botonCerrar.MouseButton1Click:Connect(cerrarTienda)
fondoOscuro.MouseButton1Click:Connect(cerrarTienda)

screenGui:GetPropertyChangedSignal("Enabled"):Connect(function()
	if screenGui.Enabled and not estaAbierto then
		abrirTienda()
	elseif not screenGui.Enabled and estaAbierto then
		cerrarTienda()
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.M then
		if estaAbierto then
			cerrarTienda()
		else
			abrirTienda()
		end
	end
end)

EventosRemotos.AbrirTiendaMejoras.OnClientEvent:Connect(function(pestana: string?)
	abrirTienda(pestana)
end)

EventosRemotos.DatosActualizados.OnClientEvent:Connect(function(nuevosDatos)
	if nuevosDatos then
		datosActuales.PesosDulces = nuevosDatos.PesosDulces or 0
		datosActuales.Fama = nuevosDatos.Fama or 0
		datosActuales.Inventario = nuevosDatos.Inventario or {}
		datosActuales.MejorasCompradas = nuevosDatos.MejorasCompradas or {}
		datosActuales.VehiculosComprados = nuevosDatos.VehiculosComprados
			or { ["Vehiculo_Bicicleta"] = true }
		datosActuales.VehiculoEquipado = nuevosDatos.VehiculoEquipado or "Vehiculo_Bicicleta"

		if screenGui.Enabled then
			actualizarVista()
		end
	end
end)

-- Solicitar datos iniciales
task.spawn(function()
	local inicial = EventosRemotos.SolicitarDatos:InvokeServer()
	if inicial then
		datosActuales.PesosDulces = inicial.PesosDulces or 0
		datosActuales.Fama = inicial.Fama or 0
		datosActuales.Inventario = inicial.Inventario or {}
		datosActuales.MejorasCompradas = inicial.MejorasCompradas or {}
		datosActuales.VehiculosComprados = inicial.VehiculosComprados
			or { ["Vehiculo_Bicicleta"] = true }
		datosActuales.VehiculoEquipado = inicial.VehiculoEquipado or "Vehiculo_Bicicleta"
	end
end)
