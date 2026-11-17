local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GestorDatos = require(script.Parent.GestorDatos)
local Datos = require(ReplicatedStorage.Shared.Datos)
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)

local RADIO_ESCONDITE = 16
local RADIO_DETECCION_RETEN = 16

type EstadoJugadorPersecucion = {
	TiempoEnEscondite: number,
	Enfriando: boolean,
	UltimaNotificacionReten: number,
	UltimoTickSegundo: number,
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
	return Vector3.new(97, 63, -119)
end

local function obtenerPuntoInternado(): Vector3
	local mapa = Workspace:FindFirstChild("Mapa")
	local internado = mapa and mapa:FindFirstChild("Zona_InternadoSinAzucar")
	local punto = internado and internado:FindFirstChild("Punto_Internado") :: BasePart?
	if punto then
		return punto.Position + Vector3.new(0, 3, 0)
	end
	return Vector3.new(0, 118, 520)
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
				subtitulo.Text = "Escondite (-15 pts/s)"
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

local function configurarInteraccionesInternado()
	local mapa = Workspace:WaitForChild("Mapa", 10)
	if not mapa then
		return
	end
	local internado = mapa:WaitForChild("Zona_InternadoSinAzucar", 10)
	if not internado then
		return
	end

	local muela = internado:FindFirstChild("MuelaGigante")
	local promptMuela = muela and muela:FindFirstChild("PromptCepillar") :: ProximityPrompt?
	if promptMuela then
		promptMuela.Triggered:Connect(function(player: Player)
			if GestorDatos.EstaEnInternado(player) then
				local reduccion = Datos.Persecucion.Internado.ReduccionPorCepilladoSegundos or 20
				local restante = GestorDatos.ReducirCondenaInternado(player, reduccion)
				if restante <= 0 then
					local character = player.Character
					local hrp = character
						and character:FindFirstChild("HumanoidRootPart") :: BasePart?
					if hrp then
						hrp.CFrame = CFrame.new(obtenerPuntoSpawnSeguro())
					end
					EventosRemotos.LiberadoDelInternado:FireClient(player)
					print(
						string.format(
							"El Patrón del Dulce: %s completó su condena y fue liberado.",
							player.Name
						)
					)
				end
			end
		end)
	end

	local enfermero = internado:FindFirstChild("EnfermeroDental")
	local promptFianza = enfermero and enfermero:FindFirstChild("PromptFianza") :: ProximityPrompt?
	if promptFianza then
		promptFianza.Triggered:Connect(function(player: Player)
			if GestorDatos.EstaEnInternado(player) then
				local exito, msg = GestorDatos.PagarFianza(player)
				if exito then
					local character = player.Character
					local hrp = character
						and character:FindFirstChild("HumanoidRootPart") :: BasePart?
					if hrp then
						hrp.CFrame = CFrame.new(obtenerPuntoSpawnSeguro())
					end
					EventosRemotos.LiberadoDelInternado:FireClient(player)
					print(
						string.format(
							"El Patrón del Dulce: %s pagó fianza y fue liberado.",
							player.Name
						)
					)
				else
					EventosRemotos.AlertaPolicia:FireClient(player, msg, 0)
				end
			end
		end)
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
	local dtEfectivo = acumuladorTiempo
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
				UltimoTickSegundo = os.clock(),
			}
		end

		local estado = estadosPersecucion[player]

		-- A. Manejo de Condena en el Internado Sin Azúcar
		if GestorDatos.EstaEnInternado(player) then
			local restante = GestorDatos.ReducirCondenaInternado(player, dtEfectivo)
			if restante <= 0 then
				hrp.CFrame = CFrame.new(obtenerPuntoSpawnSeguro())
				EventosRemotos.LiberadoDelInternado:FireClient(player)
				print(
					string.format(
						"El Patrón del Dulce: %s cumplió su tiempo de condena y salió libre.",
						player.Name
					)
				)
			end
			continue
		end

		local puntosCalor = GestorDatos.ObtenerPuntosCalor(player)
		local estrellas = GestorDatos.ObtenerEstrellas(player)

		-- B. Enfriamiento en Escondites (-15 pts/s) vs Enfriamiento en Calle (-3 pts/s)
		local estaEscondido = buscarEsconditeCercano(hrp.Position)
		local cercaReten, retenPart = buscarRetenCercano(hrp.Position)

		if estaEscondido and puntosCalor > 0 then
			estado.Enfriando = true
			local tasaEscondite = Datos.Persecucion.TasaEnfriamiento.Escondite or 15
			local ptsAEnfriar = tasaEscondite * dtEfectivo
			local nuevosPuntos, nuevasEstrellas = GestorDatos.EnfriarCalor(player, ptsAEnfriar)

			local progreso = 0
			if nuevasEstrellas > 0 then
				local conf = Datos.Persecucion.Estrellas[nuevasEstrellas]
				if conf then
					progreso = math.clamp(nuevosPuntos / conf.UmbralPuntos, 0, 1)
				end
			end

			EventosRemotos.EstrellasActualizadas:FireClient(player, {
				Estrellas = nuevasEstrellas,
				Enfriando = true,
				ProgresoEnfriamiento = progreso,
				PuntosCalor = nuevosPuntos,
			})
		elseif (not cercaReten) and puntosCalor > 0 then
			-- Enfriamiento pasivo en calle (-3 pts/s)
			local tasaCalle = Datos.Persecucion.TasaEnfriamiento.Calle or 3
			local ptsAEnfriar = tasaCalle * dtEfectivo
			local nuevosPuntos, nuevasEstrellas = GestorDatos.EnfriarCalor(player, ptsAEnfriar)

			EventosRemotos.EstrellasActualizadas:FireClient(player, {
				Estrellas = nuevasEstrellas,
				Enfriando = false,
				ProgresoEnfriamiento = 0,
				PuntosCalor = nuevosPuntos,
			})
		else
			if estado.Enfriando then
				estado.Enfriando = false
				EventosRemotos.EstrellasActualizadas:FireClient(player, {
					Estrellas = estrellas,
					Enfriando = false,
					ProgresoEnfriamiento = 0,
					PuntosCalor = puntosCalor,
				})
			end
		end

		-- C. Intercepción en Retenes Policiales
		if estrellas >= 1 and cercaReten and retenPart then
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

					local reglaEstrella = Datos.Persecucion.Estrellas[estrellas]
						or Datos.Persecucion.Estrellas[1]
					local pctConfiscacion = reglaEstrella.PierdeCargaPorcentaje or 0.10
					local confiscados =
						GestorDatos.ConfiscarCargaPorcentaje(player, pctConfiscacion)

					if reglaEstrella.EnviaAlInternado then
						-- Arresto completo y envío al Internado Sin Azúcar
						local condena = reglaEstrella.CondenaSegundos or 60
						local fianza = reglaEstrella.FianzaPesos or 50
						GestorDatos.EstablecerCondenaInternado(player, condena)

						hrp.CFrame = CFrame.new(obtenerPuntoInternado())

						EventosRemotos.EnviadoAlInternado:FireClient(player, {
							CondenaSegundos = condena,
							FianzaPesos = fianza,
							Estrellas = estrellas,
						})
						EventosRemotos.CargaConfiscada:FireClient(player, confiscados)

						print(
							string.format(
								"El Patrón del Dulce: ¡%s fue arrestado en el retén con %d estrellas! Confiscados: %d dulces. Enviado al Internado por %ds (Fianza: $%d)",
								player.Name,
								estrellas,
								confiscados,
								condena,
								fianza
							)
						)
					else
						-- Advertencia y confiscación parcial (Estrellas 1 o 2)
						if confiscados > 0 then
							EventosRemotos.CargaConfiscada:FireClient(player, confiscados)
						end
						local msg = string.format(
							"¡Retén Policial! Te incautaron el %d%% de tu carga (%d dulces). ¡Cuidado!",
							math.floor(pctConfiscacion * 100),
							confiscados
						)
						EventosRemotos.AlertaPolicia:FireClient(player, msg, estrellas)
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
task.spawn(configurarInteraccionesInternado)
print("El Patrón del Dulce: Sistema de Persecución y Policía Dental (Fase 2) inicializado")
