local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GestorDatos = require(script.Parent.GestorDatos)
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)

local TIEMPO_ENFRIAMIENTO_POR_ESTRELLA = 3.5
local RADIO_ESCONDITE = 16
local RADIO_DETECCION_RETEN = 16

type EstadoJugadorPersecucion = {
	TiempoEnEscondite: number,
	Enfriando: boolean,
	UltimaNotificacionReten: number,
}

local estadosPersecucion: { [Player]: EstadoJugadorPersecucion } = {}

local function obtenerPuntoSpawnSeguro(): Vector3
	local puntos = Workspace:FindFirstChild("Puntos")
	if puntos then
		local apariciones = puntos:FindFirstChild("Apariciones")
		if apariciones then
			local cocina = apariciones:FindFirstChild("Punto_Cocina_Inicial") :: BasePart?
			if cocina then
				return cocina.Position + Vector3.new(0, 3, 0)
			end
		end
	end
	return Vector3.new(0, 5, 0)
end

local function configurarEscondites()
	local puntos = Workspace:WaitForChild("Puntos", 10)
	if not puntos then
		return
	end
	local esconditesFolder = puntos:WaitForChild("Escondites", 10)
	if not esconditesFolder then
		return
	end

	for _, punto in ipairs(esconditesFolder:GetChildren()) do
		if punto:IsA("BasePart") then
			local existente = punto:FindFirstChild("IndicadorEscondite")
			if not existente then
				local bbg = Instance.new("BillboardGui")
				bbg.Name = "IndicadorEscondite"
				bbg.Size = UDim2.fromOffset(180, 50)
				bbg.StudsOffset = Vector3.new(0, 3, 0)
				bbg.AlwaysOnTop = false
				bbg.MaxDistance = 40
				bbg.Parent = punto

				local fondo = Instance.new("Frame")
				fondo.Name = "Fondo"
				fondo.Size = UDim2.fromScale(1, 1)
				fondo.BackgroundColor3 = Color3.fromRGB(20, 35, 25)
				fondo.BackgroundTransparency = 0.2
				fondo.Parent = bbg

				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0, 8)
				corner.Parent = fondo

				local stroke = Instance.new("UIStroke")
				stroke.Color = Color3.fromRGB(70, 220, 120)
				stroke.Thickness = 1.5
				stroke.Parent = fondo

				local titulo = Instance.new("TextLabel")
				titulo.Name = "Titulo"
				titulo.Size = UDim2.fromScale(1, 0.55)
				titulo.BackgroundTransparency = 1
				titulo.Font = Enum.Font.FredokaOne
				titulo.Text = "🕶️ ZONA SEGURA"
				titulo.TextColor3 = Color3.fromRGB(120, 255, 160)
				titulo.TextSize = 15
				titulo.Parent = fondo

				local subtitulo = Instance.new("TextLabel")
				subtitulo.Name = "Subtitulo"
				subtitulo.Size = UDim2.fromScale(1, 0.45)
				subtitulo.Position = UDim2.fromScale(0, 0.55)
				subtitulo.BackgroundTransparency = 1
				subtitulo.Font = Enum.Font.GothamMedium
				subtitulo.Text = "Escondite de Callejón"
				subtitulo.TextColor3 = Color3.fromRGB(200, 240, 210)
				subtitulo.TextSize = 12
				subtitulo.Parent = fondo
			end
		end
	end
end

local function configurarRetenes()
	local puntos = Workspace:WaitForChild("Puntos", 10)
	if not puntos then
		return
	end
	local retenesFolder = puntos:WaitForChild("Retenes", 10)
	if not retenesFolder then
		return
	end

	for _, reten in ipairs(retenesFolder:GetChildren()) do
		if reten:IsA("BasePart") then
			local existente = reten:FindFirstChild("IndicadorReten")
			if not existente then
				local bbg = Instance.new("BillboardGui")
				bbg.Name = "IndicadorReten"
				bbg.Size = UDim2.fromOffset(200, 55)
				bbg.StudsOffset = Vector3.new(0, 4, 0)
				bbg.AlwaysOnTop = false
				bbg.MaxDistance = 50
				bbg.Parent = reten

				local fondo = Instance.new("Frame")
				fondo.Name = "Fondo"
				fondo.Size = UDim2.fromScale(1, 1)
				fondo.BackgroundColor3 = Color3.fromRGB(35, 15, 15)
				fondo.BackgroundTransparency = 0.2
				fondo.Parent = bbg

				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0, 8)
				corner.Parent = fondo

				local stroke = Instance.new("UIStroke")
				stroke.Color = Color3.fromRGB(255, 60, 60)
				stroke.Thickness = 2
				stroke.Parent = fondo

				local titulo = Instance.new("TextLabel")
				titulo.Name = "Titulo"
				titulo.Size = UDim2.fromScale(1, 0.55)
				titulo.BackgroundTransparency = 1
				titulo.Font = Enum.Font.FredokaOne
				titulo.Text = "🚨 RETÉN DENTAL"
				titulo.TextColor3 = Color3.fromRGB(255, 100, 100)
				titulo.TextSize = 16
				titulo.Parent = fondo

				local subtitulo = Instance.new("TextLabel")
				subtitulo.Name = "Subtitulo"
				subtitulo.Size = UDim2.fromScale(1, 0.45)
				subtitulo.Position = UDim2.fromScale(0, 0.55)
				subtitulo.BackgroundTransparency = 1
				subtitulo.Font = Enum.Font.GothamMedium
				subtitulo.Text = "Inspección de Azúcar"
				subtitulo.TextColor3 = Color3.fromRGB(255, 200, 200)
				subtitulo.TextSize = 12
				subtitulo.Parent = fondo

				-- Luz de advertencia policial
				local sirenaLuz = Instance.new("PointLight")
				sirenaLuz.Name = "SirenaLuz"
				sirenaLuz.Color = Color3.fromRGB(255, 40, 40)
				sirenaLuz.Brightness = 2
				sirenaLuz.Range = 24
				sirenaLuz.Parent = reten
			end
		end
	end
end

local function buscarEsconditeCercano(posicion: Vector3): (boolean, number)
	local puntos = Workspace:FindFirstChild("Puntos")
	if not puntos then
		return false, math.huge
	end
	local esconditesFolder = puntos:FindFirstChild("Escondites")
	if not esconditesFolder then
		return false, math.huge
	end

	local distanciaMinima = math.huge
	for _, punto in ipairs(esconditesFolder:GetChildren()) do
		if punto:IsA("BasePart") then
			local dist = (punto.Position - posicion).Magnitude
			if dist < distanciaMinima then
				distanciaMinima = dist
			end
		end
	end

	return (distanciaMinima <= RADIO_ESCONDITE), distanciaMinima
end

local function buscarRetenCercano(posicion: Vector3): (boolean, BasePart?)
	local puntos = Workspace:FindFirstChild("Puntos")
	if not puntos then
		return false, nil
	end
	local retenesFolder = puntos:FindFirstChild("Retenes")
	if not retenesFolder then
		return false, nil
	end

	for _, punto in ipairs(retenesFolder:GetChildren()) do
		if punto:IsA("BasePart") then
			local dist = (punto.Position - posicion).Magnitude
			if dist <= RADIO_DETECCION_RETEN then
				return true, punto
			end
		end
	end

	return false, nil
end

local intervaloChequeo = 0.5
local acumuladorTiempo = 0

RunService.Heartbeat:Connect(function(dt: number)
	acumuladorTiempo += dt
	if acumuladorTiempo < intervaloChequeo then
		return
	end
	acumuladorTiempo = 0

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if not character then
			continue
		end
		local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then
			continue
		end

		if not estadosPersecucion[player] then
			estadosPersecucion[player] = {
				TiempoEnEscondite = 0,
				Enfriando = false,
				UltimaNotificacionReten = 0,
			}
		end

		local estado = estadosPersecucion[player]
		local estrellas = GestorDatos.ObtenerEstrellas(player)

		-- 1. Verificar Escondites (Enfriar estrellas)
		local estaEscondido = buscarEsconditeCercano(hrp.Position)
		if estaEscondido and estrellas > 0 then
			estado.Enfriando = true
			estado.TiempoEnEscondite += intervaloChequeo

			local progreso =
				math.clamp(estado.TiempoEnEscondite / TIEMPO_ENFRIAMIENTO_POR_ESTRELLA, 0, 1)

			if estado.TiempoEnEscondite >= TIEMPO_ENFRIAMIENTO_POR_ESTRELLA then
				estado.TiempoEnEscondite = 0
				local nuevasEstrellas = GestorDatos.ModificarEstrellas(player, -1)
				estrellas = nuevasEstrellas
				progreso = 0
				print(
					string.format(
						"El Patrón del Dulce: %s enfrió 1 estrella en el escondite. Estrellas actuales: %d",
						player.Name,
						nuevasEstrellas
					)
				)
			end

			EventosRemotos.EstrellasActualizadas:FireClient(player, {
				Estrellas = estrellas,
				Enfriando = true,
				ProgresoEnfriamiento = progreso,
			})
		else
			if estado.Enfriando then
				estado.Enfriando = false
				estado.TiempoEnEscondite = 0
				EventosRemotos.EstrellasActualizadas:FireClient(player, {
					Estrellas = estrellas,
					Enfriando = false,
					ProgresoEnfriamiento = 0,
				})
			end
		end

		-- 2. Verificar Retenes (Detección y Confiscación con >= 2 estrellas)
		if estrellas >= 2 then
			local cercaReten, retenPart = buscarRetenCercano(hrp.Position)
			if cercaReten and retenPart then
				-- Verificar si el retén o agente está aturdido por cauchera de gomitas
				local mapa = Workspace:FindFirstChild("Mapa")
				local npcs = mapa
					and mapa:FindFirstChild("Decoracion")
					and mapa.Decoracion:FindFirstChild("NPCs_Interactivos")
				local agente = npcs and npcs:FindFirstChild("Personaje_AgenteDental")
				local estaAturdido = (agente and agente:GetAttribute("Aturdido") == true)
					or (retenPart:GetAttribute("Aturdido") == true)

				if not estaAturdido then
					local ahora = os.clock()
					if ahora - estado.UltimaNotificacionReten > 3 then
						estado.UltimaNotificacionReten = ahora

						-- Confiscación de mercancía
						local cantidadConfiscada = GestorDatos.ConfiscarCarga(player)
						if cantidadConfiscada > 0 then
							-- Teletransportar al punto de spawn seguro (cocina / consultorio)
							hrp.CFrame = CFrame.new(obtenerPuntoSpawnSeguro())

							EventosRemotos.CargaConfiscada:FireClient(player, cantidadConfiscada)

							print(
								string.format(
									"El Patrón del Dulce: ¡Policía Dental confiscó %d dulces a %s en el retén!",
									cantidadConfiscada,
									player.Name
								)
							)
						end
					end
				end
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	estadosPersecucion[player] = nil
end)

task.spawn(configurarEscondites)
task.spawn(configurarRetenes)
print("El Patrón del Dulce: Sistema de Persecución y Policía Dental inicializado")
