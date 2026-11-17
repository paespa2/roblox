local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local EventosRemotos = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Eventos"):WaitForChild("EventosRemotos")
)
local Datos = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Datos"))

-- Crear ScreenGui Principal
local previo = PlayerGui:FindFirstChild("HUD_ElPatronDelDulce")
if previo then
	previo:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HUD_ElPatronDelDulce"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

-- Contenedor Superior Izquierdo (Billetera, Fama y Botón Mejoras)
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

-- Botón de Mejoras (Abre UI_Pantalla_Mejoras correctamente)
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
	local uiMejoras = PlayerGui:FindFirstChild("UI_Pantalla_Mejoras")
	if uiMejoras then
		uiMejoras.Enabled = not uiMejoras.Enabled
	end
end)

-- Contenedor Inferior (Inventario de carga y botón para abrir pantalla de inventario)
local marcoInventario = Instance.new("Frame")
marcoInventario.Name = "MarcoInventario"
marcoInventario.Size = UDim2.fromOffset(340, 50)
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
textoInventario.Text = "🎒 Carga: Vacía (¡Pulsa I o V!)"
textoInventario.TextColor3 = Color3.fromRGB(255, 230, 240)
textoInventario.TextSize = 14
textoInventario.TextXAlignment = Enum.TextXAlignment.Left
textoInventario.Parent = marcoInventario

local botonInventario = Instance.new("TextButton")
botonInventario.Name = "BotonAbrirInventario"
botonInventario.Size = UDim2.fromScale(1, 1)
botonInventario.BackgroundTransparency = 1
botonInventario.Text = ""
botonInventario.Parent = marcoInventario

botonInventario.MouseButton1Click:Connect(function()
	local pantallaInv = PlayerGui:FindFirstChild("UI_Pantalla_Inventario")
	if pantallaInv then
		pantallaInv.Enabled = not pantallaInv.Enabled
	end
end)

-- Marco de Misión / Objetivo Actual (debajo del medidor de policía a la izquierda)
local marcoObjetivo = Instance.new("Frame")
marcoObjetivo.Name = "MarcoObjetivo"
marcoObjetivo.Size = UDim2.fromOffset(280, 82)
marcoObjetivo.Position = UDim2.fromOffset(20, 260)
marcoObjetivo.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
marcoObjetivo.BackgroundTransparency = 0.2
marcoObjetivo.Parent = screenGui

local cornerObjetivo = Instance.new("UICorner")
cornerObjetivo.CornerRadius = UDim.new(0, 10)
cornerObjetivo.Parent = marcoObjetivo

local strokeObjetivo = Instance.new("UIStroke")
strokeObjetivo.Color = Color3.fromRGB(60, 130, 220)
strokeObjetivo.Thickness = 1.5
strokeObjetivo.Parent = marcoObjetivo

local tituloObjetivo = Instance.new("TextLabel")
tituloObjetivo.Name = "TituloObjetivo"
tituloObjetivo.Size = UDim2.new(1, -20, 0, 20)
tituloObjetivo.Position = UDim2.fromOffset(10, 6)
tituloObjetivo.BackgroundTransparency = 1
tituloObjetivo.Font = Enum.Font.FredokaOne
tituloObjetivo.Text = "📋 MISIÓN: CAPÍTULO 1"
tituloObjetivo.TextColor3 = Color3.fromRGB(140, 200, 255)
tituloObjetivo.TextSize = 12
tituloObjetivo.TextXAlignment = Enum.TextXAlignment.Left
tituloObjetivo.Parent = marcoObjetivo

local textoMision = Instance.new("TextLabel")
textoMision.Name = "TextoMision"
textoMision.Size = UDim2.new(1, -20, 0, 32)
textoMision.Position = UDim2.fromOffset(10, 26)
textoMision.BackgroundTransparency = 1
textoMision.Font = Enum.Font.GothamMedium
textoMision.Text = "Lleva los bombones al patio del colegio y véndelos en el recreo."
textoMision.TextColor3 = Color3.fromRGB(255, 245, 230)
textoMision.TextSize = 12
textoMision.TextWrapped = true
textoMision.TextXAlignment = Enum.TextXAlignment.Left
textoMision.TextYAlignment = Enum.TextYAlignment.Top
textoMision.Parent = marcoObjetivo

local barraProgreso = Instance.new("TextLabel")
barraProgreso.Name = "ProgresoObjetivo"
barraProgreso.Size = UDim2.new(1, -20, 0, 18)
barraProgreso.Position = UDim2.fromOffset(10, 58)
barraProgreso.BackgroundTransparency = 1
barraProgreso.Font = Enum.Font.FredokaOne
barraProgreso.Text = "Meta: Reúne $50 pesos para abrir el portón"
barraProgreso.TextColor3 = Color3.fromRGB(255, 215, 100)
barraProgreso.TextSize = 11
barraProgreso.TextXAlignment = Enum.TextXAlignment.Left
barraProgreso.Parent = marcoObjetivo

-- Notificación Banner (Posicionado debajo del banner de alertas de policía a Y=70 con botón X estático)
local bannerNotificacion = Instance.new("Frame")
bannerNotificacion.Name = "BannerNotificacion"
bannerNotificacion.Size = UDim2.fromOffset(420, 48)
bannerNotificacion.AnchorPoint = Vector2.new(0.5, 0)
bannerNotificacion.Position = UDim2.new(0.5, 0, 0, -80) -- Oculto arriba
bannerNotificacion.BackgroundColor3 = Color3.fromRGB(26, 30, 40)
bannerNotificacion.BackgroundTransparency = 0.1
bannerNotificacion.ClipsDescendants = true
bannerNotificacion.Visible = false
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
textoBanner.Size = UDim2.new(1, -54, 1, 0)
textoBanner.Position = UDim2.fromOffset(14, 0)
textoBanner.BackgroundTransparency = 1
textoBanner.Font = Enum.Font.FredokaOne
textoBanner.Text = ""
textoBanner.TextColor3 = Color3.fromRGB(255, 255, 255)
textoBanner.TextSize = 14
textoBanner.TextWrapped = true
textoBanner.TextXAlignment = Enum.TextXAlignment.Left
textoBanner.Parent = bannerNotificacion

local botonCerrarBanner = Instance.new("TextButton")
botonCerrarBanner.Name = "BotonCerrar"
botonCerrarBanner.Size = UDim2.fromOffset(24, 24)
botonCerrarBanner.Position = UDim2.new(1, -34, 0.5, -12)
botonCerrarBanner.BackgroundColor3 = Color3.fromRGB(50, 55, 70)
botonCerrarBanner.Font = Enum.Font.GothamBold
botonCerrarBanner.Text = "✕"
botonCerrarBanner.TextColor3 = Color3.fromRGB(240, 240, 250)
botonCerrarBanner.TextSize = 13
botonCerrarBanner.AutoButtonColor = true
botonCerrarBanner.Parent = bannerNotificacion

local cornerCerrarBanner = Instance.new("UICorner")
cornerCerrarBanner.CornerRadius = UDim.new(0, 6)
cornerCerrarBanner.Parent = botonCerrarBanner

local strokeCerrarBanner = Instance.new("UIStroke")
strokeCerrarBanner.Color = Color3.fromRGB(80, 88, 110)
strokeCerrarBanner.Thickness = 1
strokeCerrarBanner.Parent = botonCerrarBanner

local function cerrarBannerNotificacion()
	local tweenSubir = TweenService:Create(
		bannerNotificacion,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = UDim2.new(0.5, 0, 0, -80) }
	)
	tweenSubir:Play()
	tweenSubir.Completed:Connect(function()
		bannerNotificacion.Visible = false
	end)
end

botonCerrarBanner.MouseButton1Click:Connect(cerrarBannerNotificacion)

local function mostrarBanner(mensaje: string, colorStroke: Color3?)
	strokeBanner.Color = colorStroke or Color3.fromRGB(255, 215, 0)
	textoBanner.Text = mensaje

	bannerNotificacion.Visible = true
	bannerNotificacion.Position = UDim2.new(0.5, 0, 0, -80)
	local tweenBajar = TweenService:Create(
		bannerNotificacion,
		TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 0, 70) }
	)
	tweenBajar:Play()
	-- Permanece estático hasta que el jugador pulse [X]
end

-- ====================================================================
-- SISTEMA DE DIÁLOGO DE PERSONAJES / NPCS (Doña Melcocha, Don Ábaco, etc.)
-- ====================================================================
local cuadroDialogo = Instance.new("Frame")
cuadroDialogo.Name = "CuadroDialogoNPC"
cuadroDialogo.Size = UDim2.fromOffset(480, 100)
cuadroDialogo.AnchorPoint = Vector2.new(0.5, 1)
cuadroDialogo.Position = UDim2.new(0.5, 0, 1, 120) -- Oculto abajo
cuadroDialogo.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
cuadroDialogo.ClipsDescendants = true
cuadroDialogo.Visible = false
cuadroDialogo.Parent = screenGui

local cornerDialogo = Instance.new("UICorner")
cornerDialogo.CornerRadius = UDim.new(0, 14)
cornerDialogo.Parent = cuadroDialogo

local strokeDialogo = Instance.new("UIStroke")
strokeDialogo.Color = Color3.fromRGB(245, 170, 50)
strokeDialogo.Thickness = 2
strokeDialogo.Parent = cuadroDialogo

local iconoAvatar = Instance.new("TextLabel")
iconoAvatar.Name = "IconoAvatar"
iconoAvatar.Size = UDim2.fromOffset(60, 60)
iconoAvatar.Position = UDim2.fromOffset(15, 20)
iconoAvatar.BackgroundTransparency = 1
iconoAvatar.Font = Enum.Font.FredokaOne
iconoAvatar.Text = "👵"
iconoAvatar.TextSize = 44
iconoAvatar.Parent = cuadroDialogo

local nombreLabel = Instance.new("TextLabel")
nombreLabel.Name = "NombreNPC"
nombreLabel.Size = UDim2.new(1, -110, 0, 22)
nombreLabel.Position = UDim2.fromOffset(85, 12)
nombreLabel.BackgroundTransparency = 1
nombreLabel.Font = Enum.Font.FredokaOne
nombreLabel.Text = "Doña Melcocha"
nombreLabel.TextColor3 = Color3.fromRGB(255, 215, 90)
nombreLabel.TextSize = 16
nombreLabel.TextXAlignment = Enum.TextXAlignment.Left
nombreLabel.Parent = cuadroDialogo

local mensajeLabel = Instance.new("TextLabel")
mensajeLabel.Name = "MensajeNPC"
mensajeLabel.Size = UDim2.new(1, -110, 0, 56)
mensajeLabel.Position = UDim2.fromOffset(85, 34)
mensajeLabel.BackgroundTransparency = 1
mensajeLabel.Font = Enum.Font.GothamMedium
mensajeLabel.Text =
	"¡Mijo! Si el alcalde Apio cree que nos va a dejar sin dulce, está muy equivocado."
mensajeLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
mensajeLabel.TextSize = 13
mensajeLabel.TextWrapped = true
mensajeLabel.TextXAlignment = Enum.TextXAlignment.Left
mensajeLabel.TextYAlignment = Enum.TextYAlignment.Top
mensajeLabel.Parent = cuadroDialogo

local botonCerrarDialogo = Instance.new("TextButton")
botonCerrarDialogo.Name = "BotonCerrar"
botonCerrarDialogo.Size = UDim2.fromOffset(28, 28)
botonCerrarDialogo.AnchorPoint = Vector2.new(1, 0)
botonCerrarDialogo.Position = UDim2.new(1, -12, 0, 10)
botonCerrarDialogo.BackgroundColor3 = Color3.fromRGB(60, 68, 88)
botonCerrarDialogo.Font = Enum.Font.GothamBold
botonCerrarDialogo.Text = "✕"
botonCerrarDialogo.TextColor3 = Color3.fromRGB(240, 240, 255)
botonCerrarDialogo.TextSize = 14
botonCerrarDialogo.AutoButtonColor = true
botonCerrarDialogo.Parent = cuadroDialogo

local cornerCerrarDiag = Instance.new("UICorner")
cornerCerrarDiag.CornerRadius = UDim.new(0, 6)
cornerCerrarDiag.Parent = botonCerrarDialogo

local strokeCerrarDiag = Instance.new("UIStroke")
strokeCerrarDiag.Color = Color3.fromRGB(90, 100, 125)
strokeCerrarDiag.Thickness = 1
strokeCerrarDiag.Parent = botonCerrarDialogo

local hintCerrar = Instance.new("TextLabel")
hintCerrar.Name = "HintCerrar"
hintCerrar.Size = UDim2.fromOffset(140, 16)
hintCerrar.Position = UDim2.new(1, -150, 1, -18)
hintCerrar.BackgroundTransparency = 1
hintCerrar.Font = Enum.Font.GothamMedium
hintCerrar.Text = "Pulsa ✕ para continuar"
hintCerrar.TextColor3 = Color3.fromRGB(160, 170, 190)
hintCerrar.TextSize = 10
hintCerrar.TextXAlignment = Enum.TextXAlignment.Right
hintCerrar.Parent = cuadroDialogo

local tweenDialogoSalida: Tween? = nil

local function cerrarDialogo()
	if tweenDialogoSalida then
		tweenDialogoSalida:Cancel()
	end
	tweenDialogoSalida = TweenService:Create(
		cuadroDialogo,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = UDim2.new(0.5, 0, 1, 120) }
	)
	tweenDialogoSalida:Play()
	tweenDialogoSalida.Completed:Connect(function()
		cuadroDialogo.Visible = false
	end)
end

botonCerrarDialogo.MouseButton1Click:Connect(cerrarDialogo)

local function mostrarDialogoNPC(info: {
	Nombre: string,
	Titulo: string?,
	Icono: string?,
	Mensaje: string,
})
	iconoAvatar.Text = info.Icono or "🗣️"
	nombreLabel.Text = info.Nombre .. (if info.Titulo then " (" .. info.Titulo .. ")" else "")
	mensajeLabel.Text = info.Mensaje

	cuadroDialogo.Visible = true
	cuadroDialogo.Position = UDim2.new(0.5, 0, 1, 120)
	local tweenEntrada = TweenService:Create(
		cuadroDialogo,
		TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 1, -25) }
	)
	tweenEntrada:Play()

	-- Sonido suave de diálogo
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	sound.Volume = 0.5
	sound.Parent = SoundService
	pcall(function()
		sound:Play()
	end)
	task.delay(1.5, function()
		sound:Destroy()
	end)
	-- Diálogo estático: se mantiene en pantalla hasta que el jugador pulse ✕
end

EventosRemotos.MostrarDialogoNPC.OnClientEvent:Connect(mostrarDialogoNPC)

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
		textoInventario.Text = "🎒 Carga: " .. table.concat(listaTextos, " | ") .. " (Pulsa I)"
		textoInventario.TextColor3 = Color3.fromRGB(255, 235, 120)
	else
		textoInventario.Text = "🎒 Carga: Vacía (¡Cocina en la paila! / Pulsa V)"
		textoInventario.TextColor3 = Color3.fromRGB(200, 200, 210)
	end
end

-- Actualizar visualmente la tarjeta de Misión / Objetivo
local function actualizarObjetivo(datos)
	local cap = datos.CapituloActual or 1
	local pesos = datos.PesosDulces or 0
	local fama = datos.Fama or 0
	local paso = datos.PasoTutorial or 0
	local cantBombones = (datos.Inventario and datos.Inventario["Dulce_Bombon"]) or 0

	if cap >= 2 then
		tituloObjetivo.Text = "📋 CAPÍTULO 2: LA ESQUINA"
		textoMision.Text = "Visita a Don Ábaco en el barrio y surte las 6 tiendas locales."
		barraProgreso.Text = string.format("Progreso: $%d Pesos | %d Fama ⭐", pesos, fama)
		strokeObjetivo.Color = Color3.fromRGB(80, 220, 140)
	elseif pesos >= 50 then
		tituloObjetivo.Text = "🔓 ¡PORTÓN DEL COLEGIO ABIERTO!"
		textoMision.Text = "¡Capítulo 1 completado! Monta la bicicleta (tecla V) y sal al barrio."
		barraProgreso.Text = "🎉 ¡Camino al Barrio Desbloqueado!"
		strokeObjetivo.Color = Color3.fromRGB(255, 215, 0)
	elseif paso == 0 then
		tituloObjetivo.Text = "📢 ANUNCIO DEL ALCALDE APIO"
		textoMision.Text = "Escucha el altavoz y habla con Doña Melcocha en la cocina."
		barraProgreso.Text = "Presiona E para hablar con la Abuela"
		strokeObjetivo.Color = Color3.fromRGB(240, 120, 80)
	elseif cantBombones > 0 then
		tituloObjetivo.Text = "🎒 CAPÍTULO 1: EL RECREO"
		textoMision.Text = "Vende a Lola Paleta en el kiosko o a Tito y Sofi en la cancha."
		barraProgreso.Text = string.format("Meta: $%d / $50 Pesos Dulces", pesos)
		strokeObjetivo.Color = Color3.fromRGB(60, 160, 240)
	else
		tituloObjetivo.Text = "🍳 COCINA DE LA ABUELA"
		textoMision.Text = "¡Te quedaste sin bombones! Ve a la paila y presiona E para cocinar."
		barraProgreso.Text = string.format("Meta: $%d / $50 Pesos Dulces", pesos)
		strokeObjetivo.Color = Color3.fromRGB(240, 160, 60)
	end
end

-- Conexión de eventos
EventosRemotos.DatosActualizados.OnClientEvent:Connect(function(datos)
	animarPesos(datos.PesosDulces)
	textoFama.Text = string.format("Fama: %d ⭐", datos.Fama)
	actualizarInventario(datos.Inventario)
	actualizarObjetivo(datos)
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

EventosRemotos.LogroDesbloqueado.OnClientEvent:Connect(function(infoLogro)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	sound.Volume = 0.9
	sound.Parent = SoundService
	sound:Play()
	task.delay(1.5, function()
		sound:Destroy()
	end)

	mostrarBanner(
		string.format(
			"🏆 ¡LOGRO: %s! (+%d Fama)",
			infoLogro.Nombre or "Primer Bombón",
			infoLogro.Fama or 1
		),
		Color3.fromRGB(255, 215, 0)
	)
end)

EventosRemotos.CampanaRecreo.OnClientEvent:Connect(function()
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	sound.Volume = 1
	sound.Parent = SoundService
	sound:Play()
	task.delay(1.5, function()
		sound:Destroy()
	end)

	mostrarBanner(
		"🔔 ¡SUENA LA CAMPANA DEL RECREO! Los niños llenan el patio escolar",
		Color3.fromRGB(255, 120, 200)
	)
end)
