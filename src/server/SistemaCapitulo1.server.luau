local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GestorDatos = require(script.Parent.GestorDatos)
local _Datos = require(ReplicatedStorage.Shared.Datos)
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)

local portonAbierto = false
local hojaIzq: BasePart? = nil
local hojaDer: BasePart? = nil
local candado: BasePart? = nil

local function soldar(p0: BasePart, p1: BasePart)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.Parent = p0
end

local function obtenerPosicionSuelo(posBase: Vector3, alturaOffset: number?): Vector3
	local offset = alturaOffset or 3.0
	local rayOrigin = Vector3.new(posBase.X, posBase.Y + 12.0, posBase.Z)
	local rayDir = Vector3.new(0, -75, 0)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	local exclusions: { Instance } = {}
	local mapa = Workspace:FindFirstChild("Mapa")
	if mapa then
		local dec = mapa:FindFirstChild("Decoracion")
		if dec then
			table.insert(exclusions, dec)
		end
	end

	local maxPasos = 10
	local paso = 0
	while paso < maxPasos do
		paso += 1
		params.FilterDescendantsInstances = exclusions
		local hit = Workspace:Raycast(rayOrigin, rayDir, params)
		if not hit then
			break
		end

		local n = hit.Instance.Name:lower()
		local esTechoOCielo = (
			string.find(n, "techo")
			or string.find(n, "teja")
			or string.find(n, "cubierta")
			or string.find(n, "dintel")
			or string.find(n, "alero")
			or string.find(n, "toldo")
			or string.find(n, "cobertizo")
			or string.find(n, "marquesina")
			or string.find(n, "cielo")
			or string.find(n, "losa")
			or string.find(n, "banderin")
			or string.find(n, "poste")
			or string.find(n, "foco")
			or string.find(n, "letrero")
			or not hit.Instance.CanCollide
			or (hit.Position.Y > posBase.Y + 2.0)
		)

		if esTechoOCielo then
			table.insert(exclusions, hit.Instance)
			rayOrigin = hit.Position - Vector3.new(0, 0.05, 0)
		else
			return Vector3.new(posBase.X, hit.Position.Y + offset, posBase.Z)
		end
	end

	return posBase
end

-- ====================================================================
-- 1. CONSTRUCCIÓN Y CONFIGURACIÓN DEL PORTÓN FÍSICO DEL COLEGIO
-- ====================================================================
local function construirPortonColegio()
	local mapa = Workspace:WaitForChild("Mapa", 10)
	if not mapa then
		return
	end
	local zonaColegio = mapa:WaitForChild("Zona_Colegio", 10)
	if not zonaColegio then
		return
	end

	-- Verificar si ya existe el modelo del portón
	local modeloPorton = zonaColegio:FindFirstChild("PortonColegio")
	if not modeloPorton then
		modeloPorton = Instance.new("Model")
		modeloPorton.Name = "PortonColegio"
		modeloPorton.Parent = zonaColegio
	end

	-- Hoja Izquierda (-104.5, 66, -40)
	hojaIzq = modeloPorton:FindFirstChild("HojaIzquierda") :: BasePart?
	if not hojaIzq then
		hojaIzq = Instance.new("Part")
		hojaIzq.Name = "HojaIzquierda"
		hojaIzq.Size = Vector3.new(8.5, 12, 1)
		hojaIzq.CFrame = CFrame.new(-104.5, 66, -40)
		hojaIzq.Color = Color3.fromRGB(45, 52, 65)
		hojaIzq.Material = Enum.Material.Metal
		hojaIzq.Anchored = true
		hojaIzq.CanCollide = true
		hojaIzq.Parent = modeloPorton
	end

	-- Hoja Derecha (-95.5, 66, -40)
	hojaDer = modeloPorton:FindFirstChild("HojaDerecha") :: BasePart?
	if not hojaDer then
		hojaDer = Instance.new("Part")
		hojaDer.Name = "HojaDerecha"
		hojaDer.Size = Vector3.new(8.5, 12, 1)
		hojaDer.CFrame = CFrame.new(-95.5, 66, -40)
		hojaDer.Color = Color3.fromRGB(45, 52, 65)
		hojaDer.Material = Enum.Material.Metal
		hojaDer.Anchored = true
		hojaDer.CanCollide = true
		hojaDer.Parent = modeloPorton
	end

	-- Candado central
	candado = modeloPorton:FindFirstChild("Candado_Porton") :: BasePart?
	if not candado then
		candado = Instance.new("Part")
		candado.Name = "Candado_Porton"
		candado.Size = Vector3.new(1.8, 2.2, 1.4)
		candado.CFrame = CFrame.new(-100, 66, -39.4)
		candado.Color = Color3.fromRGB(255, 200, 60)
		candado.Material = Enum.Material.Metal
		candado.Anchored = true
		candado.CanCollide = false
		candado.Parent = modeloPorton
	end

	-- Cartel indicador sobre el portón
	local cartel = candado:FindFirstChild("Cartel_Porton")
	if not cartel then
		local bbg = Instance.new("BillboardGui")
		bbg.Name = "Cartel_Porton"
		bbg.Size = UDim2.fromOffset(260, 48)
		bbg.StudsOffset = Vector3.new(0, 2.5, 0)
		bbg.AlwaysOnTop = true
		bbg.MaxDistance = 45
		bbg.Parent = candado

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
		lbl.BackgroundTransparency = 0.2
		lbl.Font = Enum.Font.FredokaOne
		lbl.Text = "🔒 Portón del Colegio (Salida al Barrio)"
		lbl.TextColor3 = Color3.fromRGB(255, 215, 100)
		lbl.TextSize = 13
		lbl.Parent = bbg

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = lbl

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(220, 160, 40)
		stroke.Thickness = 1.5
		stroke.Parent = lbl
	end

	-- ProximityPrompt de interacción
	local prompt = candado:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "PromptPorton"
		prompt.ObjectText = "Portón del Colegio"
		prompt.ActionText = "Empujar / Inspeccionar"
		prompt.HoldDuration = 0.4
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt.Parent = candado

		prompt.Triggered:Connect(function(player: Player)
			local cap = GestorDatos.ObtenerCapitulo(player)
			local datos = GestorDatos.ObtenerDatos(player)
			local pesos = if datos then datos.PesosDulces else 0

			if cap >= 2 or portonAbierto then
				EventosRemotos.MostrarDialogoNPC:FireClient(player, {
					Nombre = "Portería del Colegio",
					Titulo = "Salida Abierta",
					Icono = "🔓",
					Mensaje = "El portón está abierto de par en par. ¡Puedes pedalear libremente por el barrio hacia las tiendas!",
				})
			else
				EventosRemotos.MostrarDialogoNPC:FireClient(player, {
					Nombre = "Portón con Candado",
					Titulo = "Cerrado en Hora de Recreo",
					Icono = "🔒",
					Mensaje = string.format(
						"¡El portón está cerrado! Necesitas completar la entrega a Lola Paleta en el kiosko del patio y reunir al menos $50 pesos dulces (Llevas $%d). ¡Cuidado con el Coordinador Tiza!",
						pesos
					),
				})
			end
		end)
	end
end

-- ====================================================================
-- 2. APERTURA CINEMÁTICA DEL PORTÓN AL COMPLETAR CAPÍTULO 1
-- ====================================================================
local function abrirPortonColegioPara(player: Player)
	if not portonAbierto then
		portonAbierto = true

		if candado and candado.Parent then
			candado.Transparency = 0.8
			local prompt = candado:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.ActionText = "Portón Abierto"
			end
			local bbg = candado:FindFirstChild("Cartel_Porton") :: BillboardGui?
			local lbl = bbg and bbg:FindFirstChildOfClass("TextLabel")
			if lbl then
				lbl.Text = "🔓 Portón Abierto — Camino al Barrio"
				lbl.TextColor3 = Color3.fromRGB(120, 255, 160)
			end
		end

		if hojaIzq and hojaIzq.Parent then
			hojaIzq.CanCollide = false
			local metaIzq = hojaIzq.CFrame * CFrame.Angles(0, math.rad(-75), 0)
				+ Vector3.new(-1, 0, 1)
			TweenService:Create(
				hojaIzq,
				TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ CFrame = metaIzq }
			):Play()
		end

		if hojaDer and hojaDer.Parent then
			hojaDer.CanCollide = false
			local metaDer = hojaDer.CFrame * CFrame.Angles(0, math.rad(75), 0)
				+ Vector3.new(1, 0, 1)
			TweenService:Create(
				hojaDer,
				TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ CFrame = metaDer }
			):Play()
		end

		-- Sonido de rejas abriéndose
		local sonido = Instance.new("Sound")
		sonido.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		sonido.Volume = 0.9
		sonido.Parent = hojaIzq or Workspace
		sonido:Play()
		task.delay(2, function()
			sonido:Destroy()
		end)
	end

	-- Notificación y diálogo de felicitación al jugador
	EventosRemotos.MostrarDialogoNPC:FireClient(player, {
		Nombre = "Doña Melcocha",
		Titulo = "¡Capítulo 1 Completado!",
		Icono = "👵",
		Mensaje = "¡Excelente, mijo! Ya demostró que tiene madera de patrón del dulce. El portón del colegio está abierto. ¡Cargue la bicicleta con la tecla V y vaya al barrio a hablar con Don Ábaco!",
	})
end

-- ====================================================================
-- ====================================================================
-- 3. AUTORIDADES ESCOLARES (DIRECTOR, COORDINADOR Y PROFESOR CON IA DE PERSECUCIÓN)
-- ====================================================================
local function crearAutoridadesEscolares()
	local mapa = Workspace:WaitForChild("Mapa", 10)
	if not mapa then
		return
	end
	local decoracion = mapa:WaitForChild("Decoracion", 10)
	if not decoracion then
		return
	end
	local npcsFolder = decoracion:WaitForChild("NPCs_Interactivos", 10)
	if not npcsFolder then
		return
	end

	local listaAutoridades = {
		{
			Nombre = "Personaje_Coordinador",
			Titulo = "👔 Coordinador Tiza\n(Disciplina Escolar)",
			Icono = "👔",
			ColorTraje = Color3.fromRGB(30, 45, 80),
			ColorPantalon = Color3.fromRGB(25, 30, 45),
			ColorPelo = Color3.fromRGB(60, 40, 30),
			TieneLentes = true,
			TieneCorbata = true,
			PosicionInicial = Vector3.new(-85, 63.0, -85),
			PuntosPatrulla = {
				Vector3.new(-85, 63.0, -85),
				Vector3.new(-105, 63.0, -85),
				Vector3.new(-95, 63.0, -100),
			},
			MensajeCaptura = "🚨 ¡SILBATO ROJO! ¡Te pillé con dulces en pleno recreo! Te decomiso la mercancía y quedas anotado en el observador.",
			MensajeNormal = "¡Ehh jovencito! ¡Está terminantemente prohibido traficar dulces y chicles en mi patio! Si te pillo con la maleta llena, te decomiso la mercancía con el silbato.",
			MensajeSalida = "Ya sonó la campana de salida. Tienes permiso de cruzar el portón hacia el barrio, pero que no te vea corriendo por los pasillos.",
		},
		{
			Nombre = "Personaje_Director",
			Titulo = "🎩 Director Don Severo\n(Rectoría Escolar)",
			Icono = "🎩",
			ColorTraje = Color3.fromRGB(45, 48, 55),
			ColorPantalon = Color3.fromRGB(35, 38, 45),
			ColorPelo = Color3.fromRGB(220, 220, 225),
			TieneLentes = true,
			TieneCorbata = false,
			TieneMaletin = true,
			PosicionInicial = Vector3.new(-100, 63.0, -112),
			PuntosPatrulla = {
				Vector3.new(-100, 63.0, -112),
				Vector3.new(-115, 63.0, -112),
				Vector3.new(-85, 63.0, -112),
			},
			MensajeCaptura = "🚨 ¡A LA DIRECCIÓN! ¡En este colegio rige la disciplina y la salud bucal! Por infringir el Decreto 001, te decomiso esta golosina. ¡A estudiar!",
			MensajeNormal = "Buenos días. En el Colegio República del Dulce defendemos la excelencia académica y la dentadura sana. ¡Cero azúcar!",
			MensajeSalida = "Veo que tienes tus permisos en regla para salir al barrio. Ve con cuidado por las avenidas.",
		},
		{
			Nombre = "Personaje_Profesor",
			Titulo = "📐 Profesor Regla\n(Docente y Vigilancia)",
			Icono = "📐",
			ColorTraje = Color3.fromRGB(110, 75, 45),
			ColorPantalon = Color3.fromRGB(40, 50, 45),
			ColorPelo = Color3.fromRGB(45, 35, 25),
			TieneLentes = false,
			TieneCorbata = false,
			TieneRegla = true,
			PosicionInicial = Vector3.new(-125, 63.0, -75),
			PuntosPatrulla = {
				Vector3.new(-125, 63.0, -75),
				Vector3.new(-125, 63.0, -60),
				Vector3.new(-125, 63.0, -90),
			},
			MensajeCaptura = "🚨 ¡DETENTE! ¡Cero golosinas y chucherías en mi turno de patio! Me quedo con este dulce para la sala de profesores.",
			MensajeNormal = "¡A estudiar! La educación es la base del éxito, no los bombones ni las melcochas clandestinas.",
			MensajeSalida = "Terminó la jornada de clases. Aprovecha para repasar las tablas de multiplicar.",
		},
	}

	for _, config in ipairs(listaAutoridades) do
		local existente = npcsFolder:FindFirstChild(config.Nombre)
		if existente then
			existente:Destroy()
		end

		local modelo = Instance.new("Model")
		modelo.Name = config.Nombre
		modelo.Parent = npcsFolder

		local hrp = Instance.new("Part")
		hrp.Name = "HumanoidRootPart"
		hrp.Size = Vector3.new(2, 2, 1)
		hrp.Position = obtenerPosicionSuelo(config.PosicionInicial, 3.0)
		hrp.Transparency = 1
		hrp.CanCollide = false
		hrp.Anchored = true
		hrp.Parent = modelo
		modelo.PrimaryPart = hrp

		local torso = Instance.new("Part")
		torso.Name = "Torso"
		torso.Size = Vector3.new(2, 2, 1)
		torso.Position = hrp.Position
		torso.Color = config.ColorTraje
		torso.Material = Enum.Material.SmoothPlastic
		torso.Anchored = false
		torso.CanCollide = false
		torso.Parent = modelo
		soldar(hrp, torso)

		local cabeza = Instance.new("Part")
		cabeza.Name = "Head"
		cabeza.Size = Vector3.new(1.2, 1.2, 1.2)
		cabeza.Position = torso.Position + Vector3.new(0, 1.6, 0)
		cabeza.Color = Color3.fromRGB(235, 195, 160)
		cabeza.Material = Enum.Material.SmoothPlastic
		cabeza.Anchored = false
		cabeza.CanCollide = false
		cabeza.Parent = modelo
		soldar(hrp, cabeza)

		if config.ColorPelo then
			local pelo = Instance.new("Part")
			pelo.Name = "Pelo"
			pelo.Size = Vector3.new(1.3, 0.4, 1.3)
			pelo.Position = cabeza.Position + Vector3.new(0, 0.65, 0)
			pelo.Color = config.ColorPelo
			pelo.Material = Enum.Material.SmoothPlastic
			pelo.Anchored = false
			pelo.CanCollide = false
			pelo.Parent = modelo
			soldar(hrp, pelo)
		end

		if config.TieneCorbata then
			local corbata = Instance.new("Part")
			corbata.Name = "Corbata"
			corbata.Size = Vector3.new(0.4, 1.4, 0.2)
			corbata.Position = torso.Position + Vector3.new(0, 0.1, -0.55)
			corbata.Color = Color3.fromRGB(190, 40, 40)
			corbata.Material = Enum.Material.SmoothPlastic
			corbata.Anchored = false
			corbata.CanCollide = false
			corbata.Parent = modelo
			soldar(hrp, corbata)
		end

		if config.TieneLentes then
			local lentes = Instance.new("Part")
			lentes.Name = "Lentes"
			lentes.Size = Vector3.new(0.9, 0.3, 0.2)
			lentes.Position = cabeza.Position + Vector3.new(0, 0.1, -0.62)
			lentes.Color = Color3.fromRGB(40, 40, 40)
			lentes.Material = Enum.Material.Metal
			lentes.Anchored = false
			lentes.CanCollide = false
			lentes.Parent = modelo
			soldar(hrp, lentes)
		end

		if config.TieneRegla then
			local regla = Instance.new("Part")
			regla.Name = "Regla"
			regla.Size = Vector3.new(0.3, 2.2, 0.2)
			regla.Position = torso.Position + Vector3.new(1.2, -0.2, -0.3)
			regla.Color = Color3.fromRGB(220, 180, 110)
			regla.Material = Enum.Material.Wood
			regla.Anchored = false
			regla.CanCollide = false
			regla.Parent = modelo
			soldar(hrp, regla)
		end

		if config.TieneMaletin then
			local maletin = Instance.new("Part")
			maletin.Name = "Maletin"
			maletin.Size = Vector3.new(0.5, 1.4, 1.6)
			maletin.Position = torso.Position + Vector3.new(-1.3, -0.5, 0)
			maletin.Color = Color3.fromRGB(70, 45, 30)
			maletin.Material = Enum.Material.SmoothPlastic
			maletin.Anchored = false
			maletin.CanCollide = false
			maletin.Parent = modelo
			soldar(hrp, maletin)
		end

		local piernas = Instance.new("Part")
		piernas.Name = "Piernas"
		piernas.Size = Vector3.new(1.8, 2, 0.9)
		piernas.Position = torso.Position + Vector3.new(0, -2, 0)
		piernas.Color = config.ColorPantalon
		piernas.Material = Enum.Material.SmoothPlastic
		piernas.Anchored = false
		piernas.CanCollide = false
		piernas.Parent = modelo
		soldar(hrp, piernas)

		-- BillboardGui con nombre y rol
		local bbg = Instance.new("BillboardGui")
		bbg.Name = "RotuloAutoridad"
		bbg.Size = UDim2.fromOffset(230, 52)
		bbg.StudsOffset = Vector3.new(0, 3.4, 0)
		bbg.AlwaysOnTop = true
		bbg.MaxDistance = 45
		bbg.Parent = cabeza

		local lbl = Instance.new("TextLabel")
		lbl.Name = "TextoRotulo"
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.FredokaOne
		lbl.Text = config.Titulo
		lbl.TextColor3 = Color3.fromRGB(255, 230, 140)
		lbl.TextSize = 13
		lbl.Parent = bbg

		-- ProximityPrompt para interactuar pacíficamente
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "PromptAutoridad"
		prompt.ObjectText = config.Nombre:gsub("Personaje_", "")
		prompt.ActionText = "Hablar"
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Parent = torso

		prompt.Triggered:Connect(function(player: Player)
			local aturdido = modelo:GetAttribute("Aturdido")
			if aturdido then
				EventosRemotos.MostrarDialogoNPC:FireClient(player, {
					Nombre = config.Nombre:gsub("Personaje_", ""),
					Titulo = "¡Aturdido por Dulce!",
					Icono = "😵",
					Mensaje = "¡Auch! ¡Me cayó dulce en la cara y no veo nada! ¡Aprovecha antes de que me limpie!",
				})
				return
			end

			local cap = GestorDatos.ObtenerCapitulo(player)
			if cap >= 2 then
				EventosRemotos.MostrarDialogoNPC:FireClient(player, {
					Nombre = config.Nombre:gsub("Personaje_", ""),
					Titulo = "Permiso de Salida",
					Icono = config.Icono,
					Mensaje = config.MensajeSalida,
				})
			else
				EventosRemotos.MostrarDialogoNPC:FireClient(player, {
					Nombre = config.Nombre:gsub("Personaje_", ""),
					Titulo = "Vigilancia Escolar",
					Icono = config.Icono,
					Mensaje = config.MensajeNormal,
				})
			end
		end)

		-- IA de Patrullaje y Persecución Activa en el Colegio
		task.spawn(function()
			local puntosPatrulla = config.PuntosPatrulla
			local idxPatrulla = 1
			local cooldownsJugador: { [Player]: number } = {}
			local ultimoTick = os.clock()

			while modelo.Parent do
				task.wait(0.2)
				local ahora = os.clock()
				local dt = ahora - ultimoTick
				ultimoTick = ahora

				-- 1. Si está aturdido por gomita, no persigue
				if modelo:GetAttribute("Aturdido") then
					continue
				end

				-- 2. Buscar si hay algún jugador cercano con dulces en el patio
				local jugadorObjetivo: Player? = nil
				local posObjetivo: Vector3? = nil
				local distanciaMinima = 32

				for _, player in ipairs(Players:GetPlayers()) do
					local cd = cooldownsJugador[player]
					if cd and ahora < cd then
						continue
					end

					local char = player.Character
					local playerHrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
					if playerHrp then
						local dist = (playerHrp.Position - hrp.Position).Magnitude
						if dist <= distanciaMinima then
							local datos = GestorDatos.ObtenerDatos(player)
							local tieneDulces = datos
								and (
									(datos.Inventario["Dulce_Bombon"] or 0) > 0
									or (datos.Inventario["Dulce_Gomita"] or 0) > 0
									or (datos.PuntosCalor or 0) > 0
								)
							if tieneDulces then
								distanciaMinima = dist
								jugadorObjetivo = player
								posObjetivo = playerHrp.Position
							end
						end
					end
				end

				-- 3. Modo Persecución activa o Modo Patrulla
				if jugadorObjetivo and posObjetivo then
					-- En Persecución
					lbl.Text = "🚨 ¡DETENTE AHÍ!\n¡TRAES DULCES!"
					lbl.TextColor3 = Color3.fromRGB(255, 90, 90)

					local dir = (posObjetivo - hrp.Position) * Vector3.new(1, 0, 1)
					local dist = dir.Magnitude

					if dist < 4.8 then
						-- ¡Atrapó al jugador! Confiscar 1 dulce y mostrar diálogo estático con [X]
						cooldownsJugador[jugadorObjetivo] = ahora + 7.0 -- Cooldown de 7s para escapar

						local dulceConfiscado = nil
						if GestorDatos.QuitarDulce(jugadorObjetivo, "Dulce_Bombon", 1) then
							dulceConfiscado = "Bombón de Melcocha"
						elseif GestorDatos.QuitarDulce(jugadorObjetivo, "Dulce_Gomita", 1) then
							dulceConfiscado = "Gomita Ácida"
						end

						-- Silbato de alerta
						local pito = Instance.new("Sound")
						pito.SoundId = "rbxasset://sounds/electronicpingshort.wav"
						pito.Volume = 0.85
						pito.Parent = hrp
						pito:Play()
						task.delay(1.5, function()
							pito:Destroy()
						end)

						local msg = config.MensajeCaptura
						if dulceConfiscado then
							msg = msg
								.. string.format("\n\n(Te decomisaron: 1x %s)", dulceConfiscado)
						end

						EventosRemotos.MostrarDialogoNPC:FireClient(jugadorObjetivo, {
							Nombre = config.Nombre:gsub("Personaje_", ""),
							Titulo = "🚨 ¡CONFISCACIÓN EN EL PATIO!",
							Icono = config.Icono,
							Mensaje = msg,
						})

						-- Pequeño retroceso para no estancarse
						task.wait(1.5)
					else
						-- Avanzar hacia el jugador a velocidad moderada (11 studs/s)
						local paso = dir.Unit * math.min(dist, 11 * dt)
						local nuevaPos = hrp.Position + paso
						local posSuelo = obtenerPosicionSuelo(nuevaPos, 3.0)
						hrp.CFrame = CFrame.lookAt(
							posSuelo,
							posSuelo + dir.Unit
						)
					end
				else
					-- En Patrulla normal por el colegio
					lbl.Text = config.Titulo
					lbl.TextColor3 = Color3.fromRGB(255, 230, 140)

					local metaPatrulla = puntosPatrulla[idxPatrulla]
					local dirPatrulla = (metaPatrulla - hrp.Position) * Vector3.new(1, 0, 1)
					local distPatrulla = dirPatrulla.Magnitude

					if distPatrulla < 2.0 then
						idxPatrulla = (idxPatrulla % #puntosPatrulla) + 1
						task.wait(2.0)
					else
						local paso = dirPatrulla.Unit * math.min(distPatrulla, 6.5 * dt)
						local nuevaPos = hrp.Position + paso
						local posSuelo = obtenerPosicionSuelo(nuevaPos, 3.0)
						hrp.CFrame = CFrame.lookAt(
							posSuelo,
							posSuelo + dirPatrulla.Unit
						)
					end
				end
			end
		end)
	end
end

-- ====================================================================
-- 4. ESTUDIANTES DEL COLEGIO (CLIENTES DIRECTOS DEL RECREO)
-- ====================================================================
local function crearEstudiantes()
	local mapa = Workspace:WaitForChild("Mapa", 10)
	if not mapa then
		return
	end
	local decoracion = mapa:WaitForChild("Decoracion", 10)
	if not decoracion then
		return
	end
	local npcsFolder = decoracion:WaitForChild("NPCs_Interactivos", 10)
	if not npcsFolder then
		return
	end

	local listaEstudiantes = {
		{
			Nombre = "Estudiante_Tito",
			Apodo = "Tito (Estudiante)",
			Posicion = Vector3.new(-76, 62.4, -84),
			ColorUniforme = Color3.fromRGB(60, 120, 200),
			ColorPantalon = Color3.fromRGB(30, 35, 50),
			DulceDeseado = "Dulce_Bombon",
			Pago = 10,
		},
		{
			Nombre = "Estudiante_Sofi",
			Apodo = "Sofi (Estudiante)",
			Posicion = Vector3.new(-112, 62.4, -95),
			ColorUniforme = Color3.fromRGB(220, 90, 130),
			ColorPantalon = Color3.fromRGB(40, 30, 45),
			DulceDeseado = "Dulce_Bombon",
			Pago = 10,
		},
	}

	for _, info in ipairs(listaEstudiantes) do
		local existente = npcsFolder:FindFirstChild(info.Nombre)
		if not existente then
			local modelo = Instance.new("Model")
			modelo.Name = info.Nombre
			modelo.Parent = npcsFolder

			local torso = Instance.new("Part")
			torso.Name = "Torso"
			torso.Size = Vector3.new(1.6, 1.8, 0.8)
			torso.Position = info.Posicion
			torso.Color = info.ColorUniforme
			torso.Material = Enum.Material.SmoothPlastic
			torso.Anchored = true
			torso.CanCollide = true
			torso.Parent = modelo
			modelo.PrimaryPart = torso

			local cabeza = Instance.new("Part")
			cabeza.Name = "Head"
			cabeza.Size = Vector3.new(1, 1, 1)
			cabeza.Position = torso.Position + Vector3.new(0, 1.4, 0)
			cabeza.Color = Color3.fromRGB(240, 205, 175)
			cabeza.Material = Enum.Material.SmoothPlastic
			cabeza.Anchored = true
			cabeza.CanCollide = false
			cabeza.Parent = modelo

			local piernas = Instance.new("Part")
			piernas.Name = "Piernas"
			piernas.Size = Vector3.new(1.4, 1.6, 0.7)
			piernas.Position = torso.Position + Vector3.new(0, -1.6, 0)
			piernas.Color = info.ColorPantalon
			piernas.Material = Enum.Material.SmoothPlastic
			piernas.Anchored = true
			piernas.CanCollide = true
			piernas.Parent = modelo

			local bbg = Instance.new("BillboardGui")
			bbg.Name = "Rotulo"
			bbg.Size = UDim2.fromOffset(180, 40)
			bbg.StudsOffset = Vector3.new(0, 2.5, 0)
			bbg.AlwaysOnTop = true
			bbg.MaxDistance = 35
			bbg.Parent = cabeza

			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.fromScale(1, 1)
			lbl.BackgroundTransparency = 1
			lbl.Font = Enum.Font.FredokaOne
			lbl.Text = string.format("🎒 %s", info.Apodo)
			lbl.TextColor3 = Color3.fromRGB(255, 245, 180)
			lbl.TextSize = 13
			lbl.Parent = bbg

			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "PromptComprar"
			prompt.ObjectText = info.Apodo
			prompt.ActionText = string.format("Vender %s ($%d)", "Bombón", info.Pago)
			prompt.HoldDuration = 0.3
			prompt.MaxActivationDistance = 12
			prompt.RequiresLineOfSight = false
			prompt.Parent = torso

			prompt.Triggered:Connect(function(player: Player)
				local datos = GestorDatos.ObtenerDatos(player)
				if not datos then
					return
				end

				local tieneDulce = (datos.Inventario[info.DulceDeseado] or 0) > 0
				if tieneDulce then
					if GestorDatos.QuitarDulce(player, info.DulceDeseado, 1) then
						GestorDatos.AgregarPesos(player, info.Pago)
						datos.Fama += 1

						-- Sonido y notificación
						local sonido = Instance.new("Sound")
						sonido.SoundId = "rbxasset://sounds/electronicpingshort.wav"
						sonido.Volume = 0.8
						sonido.Parent = torso
						sonido:Play()
						task.delay(1.5, function()
							sonido:Destroy()
						end)

						EventosRemotos.MostrarDialogoNPC:FireClient(player, {
							Nombre = info.Apodo,
							Titulo = "¡Gracias por el dulce!",
							Icono = "😋",
							Mensaje = string.format(
								"¡Qué delicia de bombón! Toma tus $%d pesos. ¡Lola Paleta en el kiosko también te compra más!",
								info.Pago
							),
						})

						-- Comprobar si cumple la meta del Capítulo 1
						if datos.CapituloActual == 1 and datos.PesosDulces >= 50 then
							GestorDatos.AvanzarCapitulo(player, 2)
							abrirPortonColegioPara(player)
						end
					end
				else
					EventosRemotos.MostrarDialogoNPC:FireClient(player, {
						Nombre = info.Apodo,
						Titulo = "Buscando dulces",
						Icono = "🎒",
						Mensaje = "¡Hola! ¿Tienes bombones de Doña Melcocha? ¡Tráeme uno o véndelos con Lola Paleta en el kiosko!",
					})
				end
			end)
		end
	end
end

-- ====================================================================
-- 5. ANUNCIO Y CARTEL DEL ALCALDE APIO (TUTORIAL MINUTO 0:00)
-- ====================================================================
local function construirAnuncioAlcalde()
	local mapa = Workspace:WaitForChild("Mapa", 10)
	if not mapa then
		return
	end
	local zonaColegio = mapa:WaitForChild("Zona_Colegio", 10)
	if not zonaColegio then
		return
	end

	-- Cartel oficial de Azúcar Prohibida
	local cartel = zonaColegio:FindFirstChild("Cartel_AzucarProhibida")
	if not cartel then
		cartel = Instance.new("Part")
		cartel.Name = "Cartel_AzucarProhibida"
		cartel.Size = Vector3.new(12, 6, 0.6)
		cartel.CFrame = CFrame.new(-61, 75, -66) * CFrame.Angles(0, math.rad(90), 0)
		cartel.Color = Color3.fromRGB(240, 240, 245)
		cartel.Material = Enum.Material.SmoothPlastic
		cartel.Anchored = true
		cartel.CanCollide = false
		cartel.Parent = zonaColegio

		local sg = Instance.new("SurfaceGui")
		sg.Name = "GuiDecreto"
		sg.Face = Enum.NormalId.Front
		sg.Parent = cartel

		local f = Instance.new("Frame")
		f.Size = UDim2.fromScale(1, 1)
		f.BackgroundColor3 = Color3.fromRGB(230, 45, 45)
		f.BorderSizePixel = 0
		f.Parent = sg

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 0.4)
		lbl.Position = UDim2.fromScale(0, 0.05)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.FredokaOne
		lbl.Text = "🚫 DECRETO MUNICIPAL N° 001"
		lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		lbl.TextScaled = true
		lbl.Parent = f

		local sub = Instance.new("TextLabel")
		sub.Size = UDim2.fromScale(0.9, 0.45)
		sub.Position = UDim2.fromScale(0.05, 0.5)
		sub.BackgroundTransparency = 1
		sub.Font = Enum.Font.FredokaOne
		sub.Text =
			"PROHIBIDO EL AZÚCAR Y LOS DULCES\n¡Cero Caries en Villa Almíbar!\n— Alcalde Apio"
		sub.TextColor3 = Color3.fromRGB(255, 245, 200)
		sub.TextScaled = true
		sub.Parent = f
	end
end

-- ====================================================================
-- 6. FLUJO DEL TUTORIAL Y METAS DEL CAPÍTULO 1
-- ====================================================================
local function iniciarTutorialParaJugador(player: Player)
	local datos = GestorDatos.ObtenerDatos(player)
	if not datos then
		return
	end

	local cap = GestorDatos.ObtenerCapitulo(player)
	local paso = GestorDatos.ObtenerPasoTutorial(player)

	if cap == 1 and paso == 0 then
		task.delay(2.5, function()
			if not player.Parent then
				return
			end
			-- Paso 0: Anuncio por el altavoz del Alcalde Apio
			EventosRemotos.MostrarDialogoNPC:FireClient(player, {
				Nombre = "Altavoz Escolar (Alcalde Apio)",
				Titulo = "Decreto Municipal N° 001",
				Icono = "📢",
				Mensaje = "¡Atención estudiantes de Villa Almíbar! Por Decreto Municipal, queda terminantemente PROHIBIDO el consumo y venta de azúcar, melcochas y bombones. ¡Cero caries en mi municipio!",
			})

			-- Asegurar que el jugador tenga sus primeros 5 bombones y 3 gomitas para el tutorial
			local bombones = (datos.Inventario["Dulce_Bombon"] or 0)
			if bombones < 5 then
				GestorDatos.AgregarDulce(player, "Dulce_Bombon", 5 - bombones)
			end
			local gomitas = (datos.Inventario["Dulce_Gomita"] or 0)
			if gomitas < 3 then
				GestorDatos.AgregarDulce(player, "Dulce_Gomita", 3 - gomitas)
			end

			-- Paso 0.5: Doña Melcocha le pasa los dulces y le da el primer encargo
			task.delay(6, function()
				if not player.Parent then
					return
				end
				EventosRemotos.MostrarDialogoNPC:FireClient(player, {
					Nombre = "Doña Melcocha",
					Titulo = "La Abuela",
					Icono = "👵",
					Mensaje = "¡Mijo! Si el Alcalde cree que nos va a dejar sin dulce, ¡está loco! Te pasé 5 bombones a escondidas. Ve al patio del colegio y véndelos con Lola Paleta o los niños antes de que suene la campana. ¡Y si te cansas, pulsa V para montar la bicicleta!",
				})
				GestorDatos.EstablecerPasoTutorial(player, 1)
			end)
		end)
	elseif cap >= 2 then
		if not portonAbierto then
			abrirPortonColegioPara(player)
		end
	end
end

GestorDatos.PesosModificados.Event:Connect(function(player: Player, pesos: number, datos)
	if datos and (datos.CapituloActual or 1) == 1 and pesos >= 50 then
		GestorDatos.AvanzarCapitulo(player, 2)
		GestorDatos.EstablecerPasoTutorial(player, 5)
		abrirPortonColegioPara(player)
	end
end)

Players.PlayerAdded:Connect(function(player: Player)
	task.wait(1.5)
	iniciarTutorialParaJugador(player)
end)

for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(iniciarTutorialParaJugador, p)
end

-- Campana periódica del Recreo Escolar (cada 180s)
task.spawn(function()
	while true do
		task.wait(180)
		EventosRemotos.CampanaRecreo:FireAllClients()
	end
end)

task.spawn(construirPortonColegio)
task.spawn(construirAnuncioAlcalde)
task.spawn(crearAutoridadesEscolares)
task.spawn(crearEstudiantes)
print(
	"El Patrón del Dulce: Sistema de Capítulo 1 (Tutorial, Recreo y Portón del Colegio) Inicializado"
)
