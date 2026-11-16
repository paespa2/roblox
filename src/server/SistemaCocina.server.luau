local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GestorDatos = require(script.Parent.GestorDatos)
local Datos = require(ReplicatedStorage.Shared.Datos)
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)

local CANTIDAD_POR_TANDA = 5

type EstadoCoccion = {
	IdDulce: string,
	Inicio: number,
	Duracion: number,
	Listo: boolean,
}

local coccionesActivas: { [Player]: EstadoCoccion } = {}

local function obtenerPaila(): BasePart?
	local mapa = Workspace:WaitForChild("Mapa", 10)
	if not mapa then
		return nil
	end
	local cocina = mapa:WaitForChild("CocinaInicial", 10)
	if not cocina then
		return nil
	end
	return (
		cocina:FindFirstChild("Paila_Melcocha") or cocina:FindFirstChild("Fogon_Ladrillo")
	) :: BasePart?
end

local function crearBillboardPaila(paila: BasePart)
	local existente = paila:FindFirstChild("IndicadorPaila")
	if existente then
		existente:Destroy()
	end

	local bbg = Instance.new("BillboardGui")
	bbg.Name = "IndicadorPaila"
	bbg.Size = UDim2.fromOffset(220, 70)
	bbg.StudsOffset = Vector3.new(0, 3.8, 0)
	bbg.AlwaysOnTop = false
	bbg.MaxDistance = 50
	bbg.Parent = paila

	local fondo = Instance.new("Frame")
	fondo.Name = "Fondo"
	fondo.Size = UDim2.fromScale(1, 1)
	fondo.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	fondo.BackgroundTransparency = 0.15
	fondo.Parent = bbg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = fondo

	local stroke = Instance.new("UIStroke")
	stroke.Name = "Borde"
	stroke.Color = Color3.fromRGB(240, 140, 60)
	stroke.Thickness = 2
	stroke.Parent = fondo

	local titulo = Instance.new("TextLabel")
	titulo.Name = "Titulo"
	titulo.Size = UDim2.new(1, 0, 0, 26)
	titulo.Position = UDim2.fromOffset(0, 6)
	titulo.BackgroundTransparency = 1
	titulo.Font = Enum.Font.FredokaOne
	titulo.Text = "🍳 Paila de Melcocha"
	titulo.TextColor3 = Color3.fromRGB(255, 225, 140)
	titulo.TextSize = 16
	titulo.Parent = fondo

	local estado = Instance.new("TextLabel")
	estado.Name = "Estado"
	estado.Size = UDim2.new(1, 0, 0, 20)
	estado.Position = UDim2.fromOffset(0, 32)
	estado.BackgroundTransparency = 1
	estado.Font = Enum.Font.FredokaOne
	estado.Text = "Presiona E para cocinar"
	estado.TextColor3 = Color3.fromRGB(210, 210, 225)
	estado.TextSize = 13
	estado.Parent = fondo

	-- Barra de progreso interna
	local barraFondo = Instance.new("Frame")
	barraFondo.Name = "BarraFondo"
	barraFondo.Size = UDim2.new(0.85, 0, 0, 6)
	barraFondo.Position = UDim2.new(0.075, 0, 0, 56)
	barraFondo.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	barraFondo.Visible = false
	barraFondo.Parent = fondo

	local cornerBarraFondo = Instance.new("UICorner")
	cornerBarraFondo.CornerRadius = UDim.new(1, 0)
	cornerBarraFondo.Parent = barraFondo

	local barraRelleno = Instance.new("Frame")
	barraRelleno.Name = "BarraRelleno"
	barraRelleno.Size = UDim2.fromScale(0, 1)
	barraRelleno.BackgroundColor3 = Color3.fromRGB(245, 160, 40)
	barraRelleno.BorderSizePixel = 0
	barraRelleno.Parent = barraFondo

	local cornerRelleno = Instance.new("UICorner")
	cornerRelleno.CornerRadius = UDim.new(1, 0)
	cornerRelleno.Parent = barraRelleno

	return bbg
end

local function configurarPromptCocina(paila: BasePart)
	local bbg = crearBillboardPaila(paila)
	local fondo = bbg:WaitForChild("Fondo") :: Frame
	local stroke = fondo:WaitForChild("Borde") :: UIStroke
	local estadoLabel = fondo:WaitForChild("Estado") :: TextLabel
	local barraFondo = fondo:WaitForChild("BarraFondo") :: Frame
	local barraRelleno = barraFondo:WaitForChild("BarraRelleno") :: Frame

	local prompt = paila:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "PromptCocina"
		prompt.ObjectText = "Paila Clandestina"
		prompt.ActionText = "Cocinar / Recoger"
		prompt.HoldDuration = 0.4
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt.Parent = paila
	end

	prompt.Triggered:Connect(function(player: Player)
		local estadoActual = coccionesActivas[player]

		if not estadoActual then
			local idDulceDefault = "Dulce_Bombon"
			local infoDulce = Datos.Dulces[idDulceDefault]
			if not infoDulce then
				return
			end

			local duracion = infoDulce.TiempoProduccion

			coccionesActivas[player] = {
				IdDulce = idDulceDefault,
				Inicio = os.time(),
				Duracion = duracion,
				Listo = false,
			}

			-- Efecto visual en Billboard 3D
			prompt.ActionText = "Cocinando..."
			estadoLabel.Text = string.format("Cocinando %s...", infoDulce.Nombre)
			estadoLabel.TextColor3 = Color3.fromRGB(255, 180, 80)
			stroke.Color = Color3.fromRGB(255, 160, 40)
			barraFondo.Visible = true
			barraRelleno.Size = UDim2.fromScale(0, 1)

			local tweenBarra = TweenService:Create(
				barraRelleno,
				TweenInfo.new(duracion, Enum.EasingStyle.Linear),
				{ Size = UDim2.fromScale(1, 1) }
			)
			tweenBarra:Play()

			EventosRemotos.CocinaActualizada:FireClient(player, {
				IdDulce = idDulceDefault,
				Duracion = duracion,
				Listo = false,
			})

			task.delay(duracion, function()
				if
					coccionesActivas[player]
					and coccionesActivas[player].IdDulce == idDulceDefault
				then
					coccionesActivas[player].Listo = true

					prompt.ActionText = "¡Recoger Bombones!"
					estadoLabel.Text = "✨ ¡LISTO PARA RECOGER! ✨"
					estadoLabel.TextColor3 = Color3.fromRGB(100, 255, 140)
					stroke.Color = Color3.fromRGB(90, 240, 120)
					barraFondo.Visible = false

					EventosRemotos.CocinaActualizada:FireClient(player, {
						IdDulce = idDulceDefault,
						Duracion = 0,
						Listo = true,
					})
				end
			end)
		elseif estadoActual.Listo == true then
			local idDulce = estadoActual.IdDulce
			local infoDulce = Datos.Dulces[idDulce]
			local nombreDulce = if infoDulce then infoDulce.Nombre else idDulce

			GestorDatos.AgregarDulce(player, idDulce, CANTIDAD_POR_TANDA)
			coccionesActivas[player] = nil

			-- Resetear visual
			prompt.ActionText = "Cocinar / Recoger"
			estadoLabel.Text = "Presiona E para cocinar"
			estadoLabel.TextColor3 = Color3.fromRGB(210, 210, 225)
			stroke.Color = Color3.fromRGB(240, 140, 60)
			barraFondo.Visible = false

			-- Efecto de sonido de recogida
			local sonidoRecoger = Instance.new("Sound")
			sonidoRecoger.SoundId = "rbxasset://sounds/uianimation.wav"
			sonidoRecoger.Volume = 0.8
			sonidoRecoger.Parent = paila
			sonidoRecoger:Play()
			sonidoRecoger.Ended:Connect(function()
				sonidoRecoger:Destroy()
			end)

			EventosRemotos.CocinaActualizada:FireClient(player, {
				IdDulce = idDulce,
				Duracion = 0,
				Recogido = true,
				Cantidad = CANTIDAD_POR_TANDA,
			})

			print(
				string.format(
					"El Patrón del Dulce: %s recogió %d unidades de %s",
					player.Name,
					CANTIDAD_POR_TANDA,
					nombreDulce
				)
			)
		else
			local restante = math.max(0, estadoActual.Duracion - (os.time() - estadoActual.Inicio))
			print(
				string.format(
					"El Patrón del Dulce: %s, tu tanda está lista en %d segundos",
					player.Name,
					restante
				)
			)
		end
	end)
end

EventosRemotos.SolicitarCocinar.OnServerInvoke = function(player: Player, idDulce: string)
	local datosJugador = GestorDatos.ObtenerDatos(player)
	if not datosJugador then
		return false, "Datos no disponibles"
	end

	if not datosJugador.RecetasDesbloqueadas[idDulce] then
		return false, "Receta bloqueada"
	end

	local infoDulce = Datos.Dulces[idDulce]
	if not infoDulce then
		return false, "Dulce no válido"
	end

	if coccionesActivas[player] and not coccionesActivas[player].Listo then
		return false, "Ya hay una tanda en cocción"
	end

	coccionesActivas[player] = {
		IdDulce = idDulce,
		Inicio = os.time(),
		Duracion = infoDulce.TiempoProduccion,
		Listo = false,
	}

	task.delay(infoDulce.TiempoProduccion, function()
		if coccionesActivas[player] and coccionesActivas[player].IdDulce == idDulce then
			coccionesActivas[player].Listo = true
			EventosRemotos.CocinaActualizada:FireClient(player, {
				IdDulce = idDulce,
				Duracion = 0,
				Listo = true,
			})
		end
	end)

	return true, "Cocción iniciada"
end

Players.PlayerRemoving:Connect(function(player: Player)
	coccionesActivas[player] = nil
end)

local paila = obtenerPaila()
if paila then
	configurarPromptCocina(paila)
	print("El Patrón del Dulce: Sistema de Cocina conectado con efectos visuales")
else
	task.spawn(function()
		local reintentos = 0
		while reintentos < 20 do
			task.wait(1)
			reintentos += 1
			local pailaTardia = obtenerPaila()
			if pailaTardia then
				configurarPromptCocina(pailaTardia)
				print("El Patrón del Dulce: Sistema de Cocina conectado (tardío)")
				break
			end
		end
	end)
end
