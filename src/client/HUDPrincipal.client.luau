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

-- Contenedor Superior Izquierdo (Billetera, Fama, Botón Mejoras y Reloj Día/Noche)
local marcoSuperior = Instance.new("Frame")
marcoSuperior.Name = "MarcoSuperior"
marcoSuperior.Size = UDim2.fromOffset(280, 168)
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

-- Pill de Ciclo Día y Noche
local pillReloj = Instance.new("Frame")
pillReloj.Name = "PillReloj"
pillReloj.Size = UDim2.new(1, 0, 0, 26)
pillReloj.Position = UDim2.fromOffset(0, 128)
pillReloj.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
pillReloj.BackgroundTransparency = 0.35
pillReloj.Parent = marcoSuperior

local cornerReloj = Instance.new("UICorner")
cornerReloj.CornerRadius = UDim.new(0, 6)
cornerReloj.Parent = pillReloj

local textoReloj = Instance.new("TextLabel")
textoReloj.Name = "TextoReloj"
textoReloj.Size = UDim2.new(1, -12, 1, 0)
textoReloj.Position = UDim2.fromOffset(8, 0)
textoReloj.BackgroundTransparency = 1
textoReloj.Font = Enum.Font.FredokaOne
textoReloj.Text = "☀️ 02:00 PM • Día"
textoReloj.TextColor3 = Color3.fromRGB(220, 230, 245)
textoReloj.TextSize = 13
textoReloj.TextXAlignment = Enum.TextXAlignment.Left
textoReloj.Parent = pillReloj

local Lighting = game:GetService("Lighting")
local function actualizarReloj()
	local hora = Lighting:GetAttribute("HoraTexto") or "02:00 PM"
	local periodo = Lighting:GetAttribute("PeriodoDia") or "Día"
	local icono = if periodo == "Noche"
		then "🌙"
		elseif periodo == "Atardecer" then "🌇"
		elseif periodo == "Amanecer" then "🌅"
		else "☀️"
	textoReloj.Text = string.format("%s %s • %s", icono, hora, periodo)
end
Lighting:GetAttributeChangedSignal("HoraTexto"):Connect(actualizarReloj)
Lighting:GetAttributeChangedSignal("PeriodoDia"):Connect(actualizarReloj)
task.spawn(actualizarReloj)

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
bannerNotificacion.Position = UDim2.new(0.5, 0, 0, -250) -- Completamente fuera de pantalla
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
botonCerrarBanner.Text = "X"
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

local timerCierreBanner: thread? = nil
local tweenBannerActual: Tween? = nil

local function cancelarTimerBanner()
	if timerCierreBanner then
		local h = timerCierreBanner
		timerCierreBanner = nil
		if coroutine.running() ~= h then
			pcall(task.cancel, h)
		end
	end
end

local function cerrarBannerNotificacion()
	cancelarTimerBanner()
	if tweenBannerActual then
		tweenBannerActual:Cancel()
	end
	tweenBannerActual = TweenService:Create(
		bannerNotificacion,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = UDim2.new(0.5, 0, 0, -250) }
	)
	tweenBannerActual:Play()
	tweenBannerActual.Completed:Connect(function()
		bannerNotificacion.Visible = false
	end)
end

botonCerrarBanner.MouseButton1Click:Connect(cerrarBannerNotificacion)

local function mostrarBanner(mensaje: string, colorStroke: Color3?, duracionSegundos: number?)
	cancelarTimerBanner()
	if tweenBannerActual then
		tweenBannerActual:Cancel()
	end

	strokeBanner.Color = colorStroke or Color3.fromRGB(255, 215, 0)
	textoBanner.Text = mensaje

	bannerNotificacion.Visible = true
	local posObjetivo = UDim2.new(0.5, 0, 0, 70)
	if bannerNotificacion.Position.Y.Offset < 0 then
		bannerNotificacion.Position = UDim2.new(0.5, 0, 0, -250)
		tweenBannerActual = TweenService:Create(
			bannerNotificacion,
			TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Position = posObjetivo }
		)
		tweenBannerActual:Play()
	end

	-- Notificación efímera: auto-cierre tras duración (por defecto 3.2s) o descarte inmediato con [X]
	local tiempo = duracionSegundos or 3.2
	timerCierreBanner = task.delay(tiempo, function()
		timerCierreBanner = nil
		cerrarBannerNotificacion()
	end)
end

-- ====================================================================
-- SISTEMA DE DIÁLOGO DE PERSONAJES / NPCS (Doña Melcocha, Don Ábaco, etc.)
-- Cuadro interactivo estático con lectura cómoda, paginación, skip y [X]
-- ====================================================================
local cuadroDialogo = Instance.new("Frame")
cuadroDialogo.Name = "CuadroDialogoNPC"
cuadroDialogo.Size = UDim2.fromOffset(520, 116)
cuadroDialogo.AnchorPoint = Vector2.new(0.5, 1)
cuadroDialogo.Position = UDim2.new(0.5, 0, 1, 140) -- Oculto abajo
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
iconoAvatar.Position = UDim2.fromOffset(14, 18)
iconoAvatar.BackgroundTransparency = 1
iconoAvatar.Font = Enum.Font.FredokaOne
iconoAvatar.Text = "👵"
iconoAvatar.TextSize = 44
iconoAvatar.Parent = cuadroDialogo

local nombreLabel = Instance.new("TextLabel")
nombreLabel.Name = "NombreNPC"
nombreLabel.Size = UDim2.new(1, -125, 0, 22)
nombreLabel.Position = UDim2.fromOffset(84, 10)
nombreLabel.BackgroundTransparency = 1
nombreLabel.Font = Enum.Font.FredokaOne
nombreLabel.Text = "Doña Melcocha"
nombreLabel.TextColor3 = Color3.fromRGB(255, 215, 90)
nombreLabel.TextSize = 16
nombreLabel.TextXAlignment = Enum.TextXAlignment.Left
nombreLabel.Parent = cuadroDialogo

local mensajeLabel = Instance.new("TextLabel")
mensajeLabel.Name = "MensajeNPC"
mensajeLabel.Size = UDim2.new(1, -125, 0, 52)
mensajeLabel.Position = UDim2.fromOffset(84, 32)
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

-- Botón [X] superior de cierre instantáneo
local botonCerrarDialogo = Instance.new("TextButton")
botonCerrarDialogo.Name = "BotonCerrar"
botonCerrarDialogo.Size = UDim2.fromOffset(26, 26)
botonCerrarDialogo.AnchorPoint = Vector2.new(1, 0)
botonCerrarDialogo.Position = UDim2.new(1, -10, 0, 8)
botonCerrarDialogo.BackgroundColor3 = Color3.fromRGB(60, 68, 88)
botonCerrarDialogo.Font = Enum.Font.GothamBold
botonCerrarDialogo.Text = "X"
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

-- Indicador de Página (ej. "Página 1 / 3")
local indicadorPagina = Instance.new("TextLabel")
indicadorPagina.Name = "IndicadorPagina"
indicadorPagina.Size = UDim2.fromOffset(130, 20)
indicadorPagina.Position = UDim2.fromOffset(84, 86)
indicadorPagina.BackgroundTransparency = 1
indicadorPagina.Font = Enum.Font.GothamBold
indicadorPagina.Text = "Página 1 / 1"
indicadorPagina.TextColor3 = Color3.fromRGB(160, 175, 200)
indicadorPagina.TextSize = 11
indicadorPagina.TextXAlignment = Enum.TextXAlignment.Left
indicadorPagina.Visible = false
indicadorPagina.Parent = cuadroDialogo

-- Botón [Saltar >>] (Skip)
local botonSkip = Instance.new("TextButton")
botonSkip.Name = "BotonSkip"
botonSkip.Size = UDim2.fromOffset(82, 22)
botonSkip.AnchorPoint = Vector2.new(1, 1)
botonSkip.Position = UDim2.new(1, -125, 1, -10)
botonSkip.BackgroundColor3 = Color3.fromRGB(42, 50, 68)
botonSkip.Font = Enum.Font.GothamBold
botonSkip.Text = "Saltar >>"
botonSkip.TextColor3 = Color3.fromRGB(180, 195, 225)
botonSkip.TextSize = 11
botonSkip.AutoButtonColor = true
botonSkip.Visible = false
botonSkip.Parent = cuadroDialogo

local cornerSkip = Instance.new("UICorner")
cornerSkip.CornerRadius = UDim.new(0, 6)
cornerSkip.Parent = botonSkip

local strokeSkip = Instance.new("UIStroke")
strokeSkip.Color = Color3.fromRGB(65, 78, 105)
strokeSkip.Thickness = 1
strokeSkip.Parent = botonSkip

-- Botón [Siguiente >] o [Entendido ✓]
local botonSiguiente = Instance.new("TextButton")
botonSiguiente.Name = "BotonSiguiente"
botonSiguiente.Size = UDim2.fromOffset(105, 22)
botonSiguiente.AnchorPoint = Vector2.new(1, 1)
botonSiguiente.Position = UDim2.new(1, -12, 1, -10)
botonSiguiente.BackgroundColor3 = Color3.fromRGB(35, 135, 75)
botonSiguiente.Font = Enum.Font.GothamBold
botonSiguiente.Text = "Entendido ✓"
botonSiguiente.TextColor3 = Color3.fromRGB(245, 255, 245)
botonSiguiente.TextSize = 11
botonSiguiente.AutoButtonColor = true
botonSiguiente.Parent = cuadroDialogo

local cornerSig = Instance.new("UICorner")
cornerSig.CornerRadius = UDim.new(0, 6)
cornerSig.Parent = botonSiguiente

local strokeSig = Instance.new("UIStroke")
strokeSig.Color = Color3.fromRGB(60, 185, 110)
strokeSig.Thickness = 1
strokeSig.Parent = botonSiguiente

local tweenDialogoSalida: Tween? = nil
local paginasActuales: { string } = {}
local indicePaginaActual: number = 1

local function cerrarDialogo()
	if tweenDialogoSalida then
		tweenDialogoSalida:Cancel()
	end
	tweenDialogoSalida = TweenService:Create(
		cuadroDialogo,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = UDim2.new(0.5, 0, 1, 140) }
	)
	tweenDialogoSalida:Play()
	tweenDialogoSalida.Completed:Connect(function()
		cuadroDialogo.Visible = false
	end)
end

local function reproducirSonidoClick()
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	sound.Volume = 0.4
	sound.Parent = SoundService
	pcall(function()
		sound:Play()
	end)
	task.delay(1, function()
		sound:Destroy()
	end)
end

local function actualizarVistaPagina()
	local texto = paginasActuales[indicePaginaActual] or ""
	mensajeLabel.Text = texto

	local totalPaginas = #paginasActuales
	if totalPaginas > 1 then
		indicadorPagina.Visible = true
		indicadorPagina.Text = string.format("Página %d de %d", indicePaginaActual, totalPaginas)

		if indicePaginaActual < totalPaginas then
			botonSiguiente.Text = "Siguiente >"
			botonSiguiente.BackgroundColor3 = Color3.fromRGB(45, 95, 175)
			strokeSig.Color = Color3.fromRGB(75, 140, 235)
			botonSkip.Visible = true
		else
			botonSiguiente.Text = "Entendido ✓"
			botonSiguiente.BackgroundColor3 = Color3.fromRGB(35, 135, 75)
			strokeSig.Color = Color3.fromRGB(60, 185, 110)
			botonSkip.Visible = false
		end
	else
		indicadorPagina.Visible = false
		botonSkip.Visible = false
		botonSiguiente.Text = "Entendido ✓"
		botonSiguiente.BackgroundColor3 = Color3.fromRGB(35, 135, 75)
		strokeSig.Color = Color3.fromRGB(60, 185, 110)
	end
end

local function avanzarPagina()
	if indicePaginaActual < #paginasActuales then
		indicePaginaActual += 1
		reproducirSonidoClick()
		actualizarVistaPagina()
	else
		cerrarDialogo()
	end
end

botonCerrarDialogo.MouseButton1Click:Connect(cerrarDialogo)
botonSiguiente.MouseButton1Click:Connect(avanzarPagina)

botonSkip.MouseButton1Click:Connect(function()
	if #paginasActuales > 1 then
		indicePaginaActual = #paginasActuales
		reproducirSonidoClick()
		actualizarVistaPagina()
	end
end)

-- Permite hacer clic en cualquier área del texto para avanzar cómodamente
local botonFondoAvance = Instance.new("TextButton")
botonFondoAvance.Name = "BotonAvanceFondo"
botonFondoAvance.Size = UDim2.new(1, -150, 0, 52)
botonFondoAvance.Position = UDim2.fromOffset(84, 32)
botonFondoAvance.BackgroundTransparency = 1
botonFondoAvance.Text = ""
botonFondoAvance.Parent = cuadroDialogo
botonFondoAvance.MouseButton1Click:Connect(avanzarPagina)

local function procesarMensajeEnPaginas(mensaje: any): { string }
	if type(mensaje) == "table" then
		local paginas = {}
		for _, v in ipairs(mensaje) do
			local str = tostring(v)
			if #str > 0 then
				table.insert(paginas, str)
			end
		end
		if #paginas > 0 then
			return paginas
		end
	end

	local texto = tostring(mensaje or "")
	if texto == "" then
		return { "..." }
	end

	-- Si contiene saltos de párrafo dobles, dividirlos en páginas
	if string.find(texto, "\n\n") then
		local partes = string.split(texto, "\n\n")
		local filtradas = {}
		for _, p in ipairs(partes) do
			local limpia = string.gsub(p, "^%s*(.-)%s*$", "%1")
			if #limpia > 0 then
				table.insert(filtradas, limpia)
			end
		end
		if #filtradas > 0 then
			return filtradas
		end
	end

	-- Si es un texto largo mayor a 170 caracteres, dividir inteligentemente por puntos
	if #texto > 170 then
		local oraciones = string.split(texto, ". ")
		if #oraciones >= 2 then
			local mitad = math.ceil(#oraciones / 2)
			local pag1 = table.concat(table.move(oraciones, 1, mitad, 1, {}), ". ")
			local pag2 = table.concat(table.move(oraciones, mitad + 1, #oraciones, 1, {}), ". ")
			if not string.find(pag1, "%.$") then
				pag1 = pag1 .. "."
			end
			return { pag1, pag2 }
		end
	end

	return { texto }
end

local ultimoTextoNPC = ""
local tiempoUltimoTextoNPC = 0

local function mostrarDialogoNPC(info: {
	Nombre: string,
	Titulo: string?,
	Icono: string?,
	Mensaje: any,
	EsNotificacionEfimera: boolean?,
})
	local textoCrudo = tostring(info.Mensaje or "")
	local ahora = os.clock()

	-- 1. Anti-spam: Filtrar mensajes idénticos que lleguen en menos de 3.5 segundos
	if textoCrudo == ultimoTextoNPC and (ahora - tiempoUltimoTextoNPC) < 3.5 then
		return
	end
	ultimoTextoNPC = textoCrudo
	tiempoUltimoTextoNPC = ahora

	-- 2. Clasificación Inteligente:
	-- Mensajes cortos (< 100 caracteres y sin párrafos dobles \n\n) son NOTIFICACIONES EFÍMERAS.
	-- Desaparecen solas en 3.2 segundos o se descartan con [X], sin bloquear la pantalla ni los controles.
	local esTextoCorto = (#textoCrudo < 100) and not string.find(textoCrudo, "\n\n") and type(info.Mensaje) ~= "table"
	if info.EsNotificacionEfimera or esTextoCorto then
		local prefijo = string.format("%s %s:", info.Icono or "💬", info.Nombre)
		mostrarBanner(string.format("%s %s", prefijo, textoCrudo), Color3.fromRGB(245, 185, 60), 3.2)
		return
	end

	-- 3. DIÁLOGO MODAL ESTÁTICO (Historias largas, misiones, Doña Melcocha, etc.)
	-- Cuadro interactivo en la parte inferior con paginación, [Siguiente >] y [X] para leer con calma.
	iconoAvatar.Text = info.Icono or "🗣️"
	nombreLabel.Text = info.Nombre .. (if info.Titulo then " (" .. info.Titulo .. ")" else "")

	paginasActuales = procesarMensajeEnPaginas(info.Mensaje)
	indicePaginaActual = 1
	actualizarVistaPagina()

	cuadroDialogo.Visible = true
	cuadroDialogo.Position = UDim2.new(0.5, 0, 1, 140)
	local tweenEntrada = TweenService:Create(
		cuadroDialogo,
		TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 1, -80) }
	)
	tweenEntrada:Play()

	-- Sonido suave de diálogo
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	sound.Volume = 0.4
	sound.Parent = SoundService
	pcall(function()
		sound:Play()
	end)
	task.delay(1.5, function()
		sound:Destroy()
	end)
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

EventosRemotos.ObjetivoMisionActualizado.OnClientEvent:Connect(function(info)
	if not info then
		return
	end
	if info.Titulo then
		tituloObjetivo.Text = info.Titulo
	else
		tituloObjetivo.Text = string.format("📋 MISIÓN: CAPÍTULO %d", info.Capitulo or 1)
	end
	textoMision.Text = info.Descripcion or ""
	barraProgreso.Text = info.Progreso or info.ProgresoTexto or info.MetaTexto or ""

	if info.Completado then
		mostrarBanner(
			string.format(
				"🎉 ¡CAPÍTULO %d COMPLETADO! Habla con Don Ábaco para avanzar.",
				info.Capitulo or 1
			),
			Color3.fromRGB(100, 255, 120)
		)
	end
end)
