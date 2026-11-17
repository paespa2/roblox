local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local localPlayer = Players.LocalPlayer
local PlayerGui = localPlayer:WaitForChild("PlayerGui")

local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UI_HUD_Estrellas"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

-- Marco Superior Derecho (Contenedor de Dientes / Estrellas)
local marcoEstrellas = Instance.new("Frame")
marcoEstrellas.Name = "MarcoEstrellas"
marcoEstrellas.Size = UDim2.fromOffset(230, 50)
marcoEstrellas.AnchorPoint = Vector2.new(1, 0)
marcoEstrellas.Position = UDim2.new(1, -20, 0, 20)
marcoEstrellas.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
marcoEstrellas.BackgroundTransparency = 0.2
marcoEstrellas.Parent = screenGui

local cornerMarco = Instance.new("UICorner")
cornerMarco.CornerRadius = UDim.new(0, 10)
cornerMarco.Parent = marcoEstrellas

local strokeMarco = Instance.new("UIStroke")
strokeMarco.Name = "StrokeMarco"
strokeMarco.Color = Color3.fromRGB(60, 75, 95)
strokeMarco.Thickness = 1.5
strokeMarco.Parent = marcoEstrellas

local layoutDientes = Instance.new("UIListLayout")
layoutDientes.FillDirection = Enum.FillDirection.Horizontal
layoutDientes.HorizontalAlignment = Enum.HorizontalAlignment.Center
layoutDientes.VerticalAlignment = Enum.VerticalAlignment.Center
layoutDientes.Padding = UDim.new(0, 8)
layoutDientes.Parent = marcoEstrellas

local listaDientes: { TextLabel } = {}

for i = 1, 5 do
	local diente = Instance.new("TextLabel")
	diente.Name = "Diente_" .. i
	diente.Size = UDim2.fromOffset(34, 34)
	diente.BackgroundTransparency = 1
	diente.Font = Enum.Font.FredokaOne
	diente.Text = "🦷"
	diente.TextColor3 = Color3.fromRGB(70, 75, 85)
	diente.TextSize = 22
	diente.Parent = marcoEstrellas

	table.insert(listaDientes, diente)
end

-- Marco de Enfriamiento (Debajo de las estrellas)
local marcoEnfriamiento = Instance.new("Frame")
marcoEnfriamiento.Name = "MarcoEnfriamiento"
marcoEnfriamiento.Size = UDim2.fromOffset(230, 42)
marcoEnfriamiento.AnchorPoint = Vector2.new(1, 0)
marcoEnfriamiento.Position = UDim2.new(1, -20, 0, 76)
marcoEnfriamiento.BackgroundColor3 = Color3.fromRGB(18, 32, 24)
marcoEnfriamiento.BackgroundTransparency = 0.2
marcoEnfriamiento.Visible = false
marcoEnfriamiento.Parent = screenGui

local cornerEnfriamiento = Instance.new("UICorner")
cornerEnfriamiento.CornerRadius = UDim.new(0, 8)
cornerEnfriamiento.Parent = marcoEnfriamiento

local strokeEnfriamiento = Instance.new("UIStroke")
strokeEnfriamiento.Color = Color3.fromRGB(60, 200, 110)
strokeEnfriamiento.Thickness = 1.5
strokeEnfriamiento.Parent = marcoEnfriamiento

local textoEnfriamiento = Instance.new("TextLabel")
textoEnfriamiento.Name = "TextoEnfriamiento"
textoEnfriamiento.Size = UDim2.fromScale(1, 0.45)
textoEnfriamiento.Position = UDim2.fromOffset(0, 3)
textoEnfriamiento.BackgroundTransparency = 1
textoEnfriamiento.Font = Enum.Font.FredokaOne
textoEnfriamiento.Text = "🕶️ ESCONDIDO - ENFRIANDO"
textoEnfriamiento.TextColor3 = Color3.fromRGB(120, 255, 160)
textoEnfriamiento.TextSize = 11
textoEnfriamiento.Parent = marcoEnfriamiento

local barraFondo = Instance.new("Frame")
barraFondo.Name = "BarraFondo"
barraFondo.Size = UDim2.new(1, -20, 0, 8)
barraFondo.Position = UDim2.fromOffset(10, 24)
barraFondo.BackgroundColor3 = Color3.fromRGB(30, 45, 35)
barraFondo.BorderSizePixel = 0
barraFondo.Parent = marcoEnfriamiento

local cornerBarraFondo = Instance.new("UICorner")
cornerBarraFondo.CornerRadius = UDim.new(1, 0)
cornerBarraFondo.Parent = barraFondo

local barraRelleno = Instance.new("Frame")
barraRelleno.Name = "BarraRelleno"
barraRelleno.Size = UDim2.fromScale(0, 1)
barraRelleno.BackgroundColor3 = Color3.fromRGB(70, 230, 120)
barraRelleno.BorderSizePixel = 0
barraRelleno.Parent = barraFondo

local cornerBarraRelleno = Instance.new("UICorner")
cornerBarraRelleno.CornerRadius = UDim.new(1, 0)
cornerBarraRelleno.Parent = barraRelleno

-- Banner de Alerta Policial (Centro Superior)
local bannerAlerta = Instance.new("Frame")
bannerAlerta.Name = "BannerAlerta"
bannerAlerta.Size = UDim2.fromOffset(420, 46)
bannerAlerta.AnchorPoint = Vector2.new(0.5, 0)
bannerAlerta.Position = UDim2.new(0.5, 0, 0, -60)
bannerAlerta.BackgroundColor3 = Color3.fromRGB(35, 15, 18)
bannerAlerta.BackgroundTransparency = 0.15
bannerAlerta.ClipsDescendants = true
bannerAlerta.Visible = false
bannerAlerta.Parent = screenGui

local cornerBanner = Instance.new("UICorner")
cornerBanner.CornerRadius = UDim.new(0, 10)
cornerBanner.Parent = bannerAlerta

local strokeBanner = Instance.new("UIStroke")
strokeBanner.Color = Color3.fromRGB(240, 70, 70)
strokeBanner.Thickness = 2
strokeBanner.Parent = bannerAlerta

local textoAlerta = Instance.new("TextLabel")
textoAlerta.Name = "TextoAlerta"
textoAlerta.Size = UDim2.fromScale(1, 1)
textoAlerta.BackgroundTransparency = 1
textoAlerta.Font = Enum.Font.FredokaOne
textoAlerta.Text = "¡Alerta de la Policía Dental!"
textoAlerta.TextColor3 = Color3.fromRGB(255, 220, 220)
textoAlerta.TextSize = 14
textoAlerta.Parent = bannerAlerta

local function reproducirSonido(idSonido: string)
	local sound = Instance.new("Sound")
	sound.SoundId = idSonido
	sound.Volume = 0.65
	sound.Parent = SoundService
	sound:Play()
	task.delay(2, function()
		sound:Destroy()
	end)
end

local function mostrarAlerta(mensaje: string, esGrave: boolean)
	textoAlerta.Text = mensaje
	strokeBanner.Color = if esGrave
		then Color3.fromRGB(255, 40, 40)
		else Color3.fromRGB(255, 180, 50)
	bannerAlerta.BackgroundColor3 = if esGrave
		then Color3.fromRGB(45, 12, 15)
		else Color3.fromRGB(38, 25, 12)

	bannerAlerta.Visible = true
	local tweenEntrada = TweenService:Create(
		bannerAlerta,
		TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 0, 20) }
	)
	tweenEntrada:Play()

	task.delay(3.5, function()
		local tweenSalida = TweenService:Create(
			bannerAlerta,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(0.5, 0, 0, -60) }
		)
		tweenSalida:Play()
		tweenSalida.Completed:Connect(function()
			bannerAlerta.Visible = false
		end)
	end)
end

local function actualizarDientes(estrellas: number)
	for i = 1, 5 do
		local diente = listaDientes[i]
		if not diente then
			continue
		end

		if i <= estrellas then
			if estrellas == 1 then
				diente.TextColor3 = Color3.fromRGB(255, 230, 80)
				strokeMarco.Color = Color3.fromRGB(200, 180, 50)
			elseif estrellas == 2 then
				diente.TextColor3 = Color3.fromRGB(255, 150, 40)
				strokeMarco.Color = Color3.fromRGB(220, 120, 40)
			elseif estrellas == 3 then
				diente.TextColor3 = Color3.fromRGB(245, 60, 60)
				strokeMarco.Color = Color3.fromRGB(230, 40, 40)
			else
				-- 4-5 estrellas: Violeta / Caries ardiente
				diente.TextColor3 = Color3.fromRGB(190, 60, 255)
				strokeMarco.Color = Color3.fromRGB(170, 40, 240)
			end

			-- Efecto pop escala
			diente.TextSize = 26
			TweenService
				:Create(
					diente,
					TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{
						TextSize = 22,
					}
				)
				:Play()
		else
			diente.TextColor3 = Color3.fromRGB(65, 70, 80)
		end
	end

	if estrellas == 0 then
		strokeMarco.Color = Color3.fromRGB(60, 75, 95)
	end
end

EventosRemotos.EstrellasActualizadas.OnClientEvent:Connect(function(info: {
	Estrellas: number,
	Enfriando: boolean,
	ProgresoEnfriamiento: number?,
})
	if not info then
		return
	end

	actualizarDientes(info.Estrellas or 0)

	if info.Enfriando and (info.Estrellas or 0) > 0 then
		marcoEnfriamiento.Visible = true
		local progreso = info.ProgresoEnfriamiento or 0
		barraRelleno.Size = UDim2.fromScale(progreso, 1)
	else
		marcoEnfriamiento.Visible = false
		barraRelleno.Size = UDim2.fromScale(0, 1)
	end
end)

EventosRemotos.AlertaPolicia.OnClientEvent:Connect(function(mensaje: string, nivel: number)
	mostrarAlerta(mensaje, (nivel or 1) >= 3)
	if (nivel or 1) >= 3 then
		reproducirSonido("rbxassetid://9069609268")
	end
end)

EventosRemotos.CargaConfiscada.OnClientEvent:Connect(function(cantidad: number)
	reproducirSonido("rbxassetid://9069609268")
	mostrarAlerta(
		string.format(
			"¡TE EMPALAGARON! 🚨 La Policía Dental confiscó tus %d dulces.",
			cantidad
		),
		true
	)
end)

-- Banner especial de Internado Sin Azúcar
EventosRemotos.EnviadoAlInternado.OnClientEvent:Connect(function(info: {
	CondenaSegundos: number,
	FianzaPesos: number,
	Estrellas: number,
})
	if not info then
		return
	end
	reproducirSonido("rbxassetid://9069609268")
	mostrarAlerta(
		string.format(
			"🦷 ¡PRESO EN EL INTERNADO SIN AZÚCAR! Condena: %ds | Fianza: $%d",
			info.CondenaSegundos,
			info.FianzaPesos
		),
		true
	)
end)

EventosRemotos.LiberadoDelInternado.OnClientEvent:Connect(function()
	mostrarAlerta("🕊️ ¡LIBERTAD CONCEDIDA! Vuelve al negocio con cautela.", false)
end)

EventosRemotos.DatosActualizados.OnClientEvent:Connect(function(nuevosDatos)
	if nuevosDatos and nuevosDatos.EstrellasBusqueda ~= nil then
		actualizarDientes(nuevosDatos.EstrellasBusqueda)
	end
end)

-- Sincronizar datos iniciales
task.spawn(function()
	local inicial = EventosRemotos.SolicitarDatos:InvokeServer()
	if inicial and inicial.EstrellasBusqueda then
		actualizarDientes(inicial.EstrellasBusqueda)
	else
		actualizarDientes(0)
	end
end)
