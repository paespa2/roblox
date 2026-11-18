local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GestorDatos = require(script.Parent.GestorDatos)
local Datos = require(ReplicatedStorage.Shared.Datos)
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)

-- ====================================================================
-- UTILIDAD: RAYCAST CANÓNICO PARA ENRAIZAR NPCS Y OBJETOS AL SUELO
-- ====================================================================
local function obtenerPosicionSuelo(posBase: Vector3, alturaOffset: number?): Vector3
	local offset = alturaOffset or 2.7
	local startY = math.max(posBase.Y + 30.0, 135)
	local rayOrigin = Vector3.new(posBase.X, startY, posBase.Z)
	local rayDir = Vector3.new(0, -180, 0)
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
		local esTechoOOstaculo = (
			string.find(n, "techo")
			or string.find(n, "teja")
			or string.find(n, "cubierta")
			or string.find(n, "dintel")
			or string.find(n, "alero")
			or string.find(n, "toldo")
			or string.find(n, "cobertizo")
			or string.find(n, "marquesina")
			or string.find(n, "cielo")
			or string.find(n, "banderin")
			or string.find(n, "poste")
			or string.find(n, "foco")
			or string.find(n, "letrero")
			or string.find(n, "cartel")
			or string.find(n, "lampara")
			or string.find(n, "baranda")
			or string.find(n, "valla")
			or string.find(n, "banca")
			or string.find(n, "asiento")
			or not hit.Instance.CanCollide
		)

		if esTechoOOstaculo then
			table.insert(exclusions, hit.Instance)
			rayOrigin = hit.Position - Vector3.new(0, 0.1, 0)
			rayDir = Vector3.new(0, -120, 0)
		else
			return Vector3.new(posBase.X, hit.Position.Y + offset, posBase.Z)
		end
	end

	return posBase
end

local function soldar(p0: BasePart, p1: BasePart)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.Parent = p0
end

-- ====================================================================
-- 1. CREACIÓN DE ESTUDIANTES VIVOS EN EL PATIO DEL COLEGIO
-- ====================================================================
local function crearEstudianteVivo(
	info: {
		Nombre: string,
		Apodo: string,
		Posicion: Vector3,
		ColorRopa: Color3,
		ColorPantalon: Color3,
		PuntosMovimiento: { Vector3 }?,
		Frases: { string },
	},
	parentFolder: Instance
)
	local modelo = Instance.new("Model")
	modelo.Name = info.Nombre
	modelo.Parent = parentFolder

	local posAlineada = obtenerPosicionSuelo(info.Posicion, 2.4)

	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(1.6, 1.8, 0.8)
	hrp.Position = posAlineada
	hrp.Transparency = 1
	hrp.CanCollide = false
	hrp.Anchored = true
	hrp.Parent = modelo
	modelo.PrimaryPart = hrp

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(1.6, 1.8, 0.8)
	torso.Position = hrp.Position
	torso.Color = info.ColorRopa
	torso.Material = Enum.Material.SmoothPlastic
	torso.Anchored = false
	torso.CanCollide = false
	torso.Parent = modelo
	soldar(hrp, torso)

	local cabeza = Instance.new("Part")
	cabeza.Name = "Head"
	cabeza.Size = Vector3.new(1, 1, 1)
	cabeza.Position = torso.Position + Vector3.new(0, 1.4, 0)
	cabeza.Color = Color3.fromRGB(240, 205, 175)
	cabeza.Material = Enum.Material.SmoothPlastic
	cabeza.Anchored = false
	cabeza.CanCollide = false
	cabeza.Parent = modelo
	soldar(hrp, cabeza)

	local piernas = Instance.new("Part")
	piernas.Name = "Piernas"
	piernas.Size = Vector3.new(1.4, 1.6, 0.7)
	piernas.Position = torso.Position + Vector3.new(0, -1.6, 0)
	piernas.Color = info.ColorPantalon
	piernas.Material = Enum.Material.SmoothPlastic
	piernas.Anchored = false
	piernas.CanCollide = false
	piernas.Parent = modelo
	soldar(hrp, piernas)

	-- Mochila escolar colorida
	local mochila = Instance.new("Part")
	mochila.Name = "Mochila"
	mochila.Size = Vector3.new(1.2, 1.3, 0.5)
	mochila.Position = torso.Position + Vector3.new(0, 0, 0.55)
	mochila.Color = Color3.fromRGB(240, 100, 50)
	mochila.Material = Enum.Material.SmoothPlastic
	mochila.Anchored = false
	mochila.CanCollide = false
	mochila.Parent = modelo
	soldar(hrp, mochila)

	-- Burbuja de Diálogo animada (Speech Bubble)
	local bbg = Instance.new("BillboardGui")
	bbg.Name = "BurbujaDialogo"
	bbg.Size = UDim2.fromOffset(200, 48)
	bbg.StudsOffset = Vector3.new(0, 2.8, 0)
	bbg.AlwaysOnTop = false
	bbg.MaxDistance = 40
	bbg.Parent = cabeza

	local fondoBurbuja = Instance.new("Frame")
	fondoBurbuja.Size = UDim2.fromScale(1, 1)
	fondoBurbuja.BackgroundColor3 = Color3.fromRGB(25, 30, 42)
	fondoBurbuja.BackgroundTransparency = 0.15
	fondoBurbuja.Parent = bbg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = fondoBurbuja

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 160, 255)
	stroke.Thickness = 1.5
	stroke.Parent = fondoBurbuja

	local textoBurbuja = Instance.new("TextLabel")
	textoBurbuja.Name = "Texto"
	textoBurbuja.Size = UDim2.new(1, -12, 1, 0)
	textoBurbuja.Position = UDim2.fromOffset(6, 0)
	textoBurbuja.BackgroundTransparency = 1
	textoBurbuja.Font = Enum.Font.FredokaOne
	textoBurbuja.Text = info.Frases[1] or "¡Quiero dulces!"
	textoBurbuja.TextColor3 = Color3.fromRGB(255, 245, 200)
	textoBurbuja.TextSize = 11
	textoBurbuja.TextWrapped = true
	textoBurbuja.Parent = fondoBurbuja

	-- ProximityPrompt para comprar dulce
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PromptComprar"
	prompt.ObjectText = info.Apodo
	prompt.ActionText = "Vender Bombón ($10)"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = torso

	prompt.Triggered:Connect(function(player: Player)
		local datos = GestorDatos.ObtenerDatos(player)
		if not datos then
			return
		end
		local bombones = datos.Inventario["Dulce_Bombon"] or 0
		if bombones > 0 then
			if GestorDatos.QuitarDulce(player, "Dulce_Bombon", 1) then
				GestorDatos.AgregarPesos(player, 10)
				datos.Fama += 1

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
					Mensaje = "¡Qué delicia! Toma tus $10 pesos. ¡Ojo que no te vea el Coordinador Tiza ni el Director!",
				})
			end
		else
			EventosRemotos.MostrarDialogoNPC:FireClient(player, {
				Nombre = info.Apodo,
				Titulo = "Buscando dulce",
				Icono = "🎒",
				Mensaje = "¡Hola! ¿Tienes bombones de Doña Melcocha? ¡Carga tu mochila en la cocina y tráeme uno!",
			})
		end
	end)

	-- Hilo de rotación de frases y patrullaje suave en el patio
	task.spawn(function()
		local idxFrase = 1
		local puntos = info.PuntosMovimiento
		local idxPunto = 1

		while modelo.Parent do
			task.wait(6.0)
			idxFrase = (idxFrase % #info.Frases) + 1
			textoBurbuja.Text = info.Frases[idxFrase]

			if puntos and #puntos > 1 then
				idxPunto = (idxPunto % #puntos) + 1
				local meta = obtenerPosicionSuelo(puntos[idxPunto], 2.4)
				local dir = (meta - hrp.Position) * Vector3.new(1, 0, 1)
				if dir.Magnitude > 1.5 then
					local nuevoCFrame = CFrame.lookAt(meta, meta + dir.Unit)
					local duracion = math.clamp(dir.Magnitude / 3.5, 1.5, 4.0)
					local tween = TweenService:Create(
						hrp,
						TweenInfo.new(duracion, Enum.EasingStyle.Linear),
						{ CFrame = nuevoCFrame }
					)
					tween:Play()
				end
			end
		end
	end)

	return modelo
end

-- ====================================================================
-- 2. CREACIÓN DE VECINOS Y PEATONES EN LAS ACERAS DEL BARRIO
-- ====================================================================
local function crearVecinoBarrio(
	info: {
		Nombre: string,
		Apodo: string,
		Posicion: Vector3,
		ColorRopa: Color3,
		ColorPantalon: Color3,
		Frases: { string },
		Icono: string,
	},
	parentFolder: Instance
)
	local modelo = Instance.new("Model")
	modelo.Name = info.Nombre
	modelo.Parent = parentFolder

	local posAlineada = obtenerPosicionSuelo(info.Posicion, 2.5)

	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(1.8, 2, 0.9)
	hrp.Position = posAlineada
	hrp.Transparency = 1
	hrp.CanCollide = false
	hrp.Anchored = true
	hrp.Parent = modelo
	modelo.PrimaryPart = hrp

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(1.8, 2, 0.9)
	torso.Position = hrp.Position
	torso.Color = info.ColorRopa
	torso.Material = Enum.Material.SmoothPlastic
	torso.Anchored = false
	torso.CanCollide = false
	torso.Parent = modelo
	soldar(hrp, torso)

	local cabeza = Instance.new("Part")
	cabeza.Name = "Head"
	cabeza.Size = Vector3.new(1.1, 1.1, 1.1)
	cabeza.Position = torso.Position + Vector3.new(0, 1.55, 0)
	cabeza.Color = Color3.fromRGB(235, 195, 160)
	cabeza.Material = Enum.Material.SmoothPlastic
	cabeza.Anchored = false
	cabeza.CanCollide = false
	cabeza.Parent = modelo
	soldar(hrp, cabeza)

	local piernas = Instance.new("Part")
	piernas.Name = "Piernas"
	piernas.Size = Vector3.new(1.6, 1.8, 0.8)
	piernas.Position = torso.Position + Vector3.new(0, -1.8, 0)
	piernas.Color = info.ColorPantalon
	piernas.Material = Enum.Material.SmoothPlastic
	piernas.Anchored = false
	piernas.CanCollide = false
	piernas.Parent = modelo
	soldar(hrp, piernas)

	-- Burbuja de Banter de barrio
	local bbg = Instance.new("BillboardGui")
	bbg.Name = "BurbujaVecino"
	bbg.Size = UDim2.fromOffset(220, 52)
	bbg.StudsOffset = Vector3.new(0, 3.2, 0)
	bbg.AlwaysOnTop = false
	bbg.MaxDistance = 45
	bbg.Parent = cabeza

	local fondoBurbuja = Instance.new("Frame")
	fondoBurbuja.Size = UDim2.fromScale(1, 1)
	fondoBurbuja.BackgroundColor3 = Color3.fromRGB(30, 24, 20)
	fondoBurbuja.BackgroundTransparency = 0.15
	fondoBurbuja.Parent = bbg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = fondoBurbuja

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(240, 160, 60)
	stroke.Thickness = 1.5
	stroke.Parent = fondoBurbuja

	local textoBurbuja = Instance.new("TextLabel")
	textoBurbuja.Name = "Texto"
	textoBurbuja.Size = UDim2.new(1, -12, 1, 0)
	textoBurbuja.Position = UDim2.fromOffset(6, 0)
	textoBurbuja.BackgroundTransparency = 1
	textoBurbuja.Font = Enum.Font.FredokaOne
	textoBurbuja.Text = info.Frases[1] or "¡Buenos días patrón!"
	textoBurbuja.TextColor3 = Color3.fromRGB(255, 230, 180)
	textoBurbuja.TextSize = 11
	textoBurbuja.TextWrapped = true
	textoBurbuja.Parent = fondoBurbuja

	-- ProximityPrompt de venta callejera y charla amigable
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PromptVecino"
	prompt.ObjectText = info.Apodo
	prompt.ActionText = "Comprar Dulce / Charlar"
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = torso

	prompt.Triggered:Connect(function(player: Player)
		local datos = GestorDatos.ObtenerDatos(player)
		if not datos then
			return
		end

		-- Buscar algún dulce en inventario
		local dulceParaVender: string? = nil
		local defDulce: any = nil
		for idDulce, cant in pairs(datos.Inventario) do
			if cant > 0 then
				dulceParaVender = idDulce
				defDulce = Datos.Dulces[idDulce]
				break
			end
		end

		if dulceParaVender and GestorDatos.QuitarDulce(player, dulceParaVender, 1) then
			local mult = datos.MultiplicadorRenacimiento or 1
			local valorBase = defDulce and defDulce.ValorVenta or 1
			local ganancia = math.max(valorBase * 3, 5) * mult
			GestorDatos.AgregarPesos(player, ganancia)
			datos.Fama += 1

			local sonido = Instance.new("Sound")
			sonido.SoundId = "rbxasset://sounds/electronicpingshort.wav"
			sonido.Volume = 0.7
			sonido.Parent = torso
			sonido:Play()
			task.delay(1.5, function()
				sonido:Destroy()
			end)

			local nombreD = defDulce and defDulce.Nombre or "Dulce"
			EventosRemotos.MostrarDialogoNPC:FireClient(player, {
				Nombre = info.Apodo,
				Titulo = "¡Venta Callejera!",
				Icono = "🍬",
				Mensaje = string.format("¡Uy qué delicia! Te compré 1 %s por $%d pesos dulces. ¡Sigue así, patrón!", nombreD, ganancia),
			})
		else
			local fraseElegida = info.Frases[math.random(1, #info.Frases)]
			EventosRemotos.MostrarDialogoNPC:FireClient(player, {
				Nombre = info.Apodo,
				Titulo = "Vecino de Villa Almíbar",
				Icono = info.Icono,
				Mensaje = fraseElegida,
			})
		end
	end)

	task.spawn(function()
		local idx = 1
		while modelo.Parent do
			task.wait(7.5)
			idx = (idx % #info.Frases) + 1
			textoBurbuja.Text = info.Frases[idx]
		end
	end)

	return modelo
end

-- ====================================================================
-- 3. ANIMALES DE VILLA ALMÍBAR (PERRITO, GALLINAS Y PALOMAS)
-- ====================================================================
local function crearFirulaisElPerrito(parentFolder: Instance)
	local modelo = Instance.new("Model")
	modelo.Name = "Animal_Firulais"
	modelo.Parent = parentFolder

	local posInicial = obtenerPosicionSuelo(Vector3.new(5, 60, 80), 0.55)

	local cuerpo = Instance.new("Part")
	cuerpo.Name = "HumanoidRootPart"
	cuerpo.Size = Vector3.new(1.2, 1.0, 2.2)
	cuerpo.Position = posInicial
	cuerpo.Color = Color3.fromRGB(195, 130, 70) -- Canela criollo
	cuerpo.Material = Enum.Material.SmoothPlastic
	cuerpo.Anchored = true
	cuerpo.CanCollide = false
	cuerpo.Parent = modelo
	modelo.PrimaryPart = cuerpo

	local cabeza = Instance.new("Part")
	cabeza.Name = "Head"
	cabeza.Size = Vector3.new(0.9, 0.9, 1.0)
	cabeza.Position = cuerpo.Position + Vector3.new(0, 0.7, -1.2)
	cabeza.Color = Color3.fromRGB(180, 115, 60)
	cabeza.Material = Enum.Material.SmoothPlastic
	cabeza.Anchored = false
	cabeza.CanCollide = false
	cabeza.Parent = modelo
	soldar(cuerpo, cabeza)

	local hocico = Instance.new("Part")
	hocico.Name = "Hocico"
	hocico.Size = Vector3.new(0.5, 0.4, 0.6)
	hocico.Position = cabeza.Position + Vector3.new(0, -0.15, -0.6)
	hocico.Color = Color3.fromRGB(40, 30, 25)
	hocico.Material = Enum.Material.SmoothPlastic
	hocico.Anchored = false
	hocico.CanCollide = false
	hocico.Parent = modelo
	soldar(cuerpo, hocico)

	-- Cola del perro (menea)
	local cola = Instance.new("Part")
	cola.Name = "Cola"
	cola.Size = Vector3.new(0.25, 0.25, 1.1)
	cola.Position = cuerpo.Position + Vector3.new(0, 0.4, 1.3)
	cola.Color = Color3.fromRGB(160, 100, 50)
	cola.Material = Enum.Material.SmoothPlastic
	cola.Anchored = false
	cola.CanCollide = false
	cola.Parent = modelo
	soldar(cuerpo, cola)

	-- Rótulo amigable
	local bbg = Instance.new("BillboardGui")
	bbg.Name = "Rotulo"
	bbg.Size = UDim2.fromOffset(160, 36)
	bbg.StudsOffset = Vector3.new(0, 2.0, 0)
	bbg.AlwaysOnTop = false
	bbg.MaxDistance = 30
	bbg.Parent = cabeza

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.FredokaOne
	lbl.Text = "🐕 Firulais (Criollo)"
	lbl.TextColor3 = Color3.fromRGB(255, 235, 160)
	lbl.TextSize = 12
	lbl.Parent = bbg

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PromptAcariciar"
	prompt.ObjectText = "Firulais"
	prompt.ActionText = "Acariciar / Dar golosina"
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = cuerpo

	local jugadorSeguido: Player? = nil
	local tiempoSeguimiento = 0

	prompt.Triggered:Connect(function(player: Player)
		local datos = GestorDatos.ObtenerDatos(player)
		local sonido = Instance.new("Sound")
		sonido.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		sonido.Volume = 0.6
		sonido.Parent = cuerpo
		sonido:Play()
		task.delay(1, function()
			sonido:Destroy()
		end)

		jugadorSeguido = player
		tiempoSeguimiento = os.clock() + 45.0 -- Acompaña al jugador 45 segundos

		local tieneGolosina = false
		if datos then
			for idD, cant in pairs(datos.Inventario) do
				if cant > 0 and GestorDatos.QuitarDulce(player, idD, 1) then
					tieneGolosina = true
					datos.Fama += 2
					break
				end
			end
		end

		local mensajeTexto = if tieneGolosina
			then "¡Guau, guau! *Firulais devora la golosina feliz y corre a tu lado como guardián fiel. ¡Te acompañará un rato!*"
			else "¡Guau, guau! *Firulais menea la colita contento y decide seguirte por la calle.*"

		EventosRemotos.MostrarDialogoNPC:FireClient(player, {
			Nombre = "Firulais",
			Titulo = "Perrito Acompañante 🐕",
			Icono = "🐕",
			Mensaje = mensajeTexto,
		})
	end)

	-- Hilo de paseo y seguimiento suave al jugador
	task.spawn(function()
		local puntos = {
			Vector3.new(5, 60, 75),
			Vector3.new(5, 60, 95),
			Vector3.new(5, 60, 65),
		}
		local idx = 1

		while modelo.Parent do
			task.wait(0.25)
			local ahora = os.clock()

			if jugadorSeguido and ahora < tiempoSeguimiento and jugadorSeguido.Parent and jugadorSeguido.Character then
				local char = jugadorSeguido.Character
				local pHrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
				if pHrp then
					local dist = (pHrp.Position - cuerpo.Position).Magnitude
					if dist > 4.5 and dist < 80 then
						local dir = (pHrp.Position - cuerpo.Position) * Vector3.new(1, 0, 1)
						local meta = obtenerPosicionSuelo(cuerpo.Position + dir.Unit * 3.2, 0.55)
						cuerpo.CFrame = CFrame.lookAt(meta, meta + dir.Unit)
					end
				else
					jugadorSeguido = nil
				end
			else
				jugadorSeguido = nil
				task.wait(3.5)
				idx = (idx % #puntos) + 1
				local meta = obtenerPosicionSuelo(puntos[idx], 0.55)
				local dir = (meta - cuerpo.Position) * Vector3.new(1, 0, 1)
				if dir.Magnitude > 1.5 then
					local cframeObj = CFrame.lookAt(meta, meta + dir.Unit)
					local tween = TweenService:Create(
						cuerpo,
						TweenInfo.new(3.5, Enum.EasingStyle.Linear),
						{ CFrame = cframeObj }
					)
					tween:Play()
				end
			end
		end
	end)
end

local function crearGallinasMelcocha(parentFolder: Instance)
	local puntosGallinas = {
		Vector3.new(94, 61, -114),
		Vector3.new(98, 61, -118),
	}

	for i, pos in ipairs(puntosGallinas) do
		local nombre = if i == 1 then "Gallina_Clotilde" else "Gallina_Margarita"
		local modelo = Instance.new("Model")
		modelo.Name = nombre
		modelo.Parent = parentFolder

		local posSuelo = obtenerPosicionSuelo(pos, 0.4)

		local cuerpo = Instance.new("Part")
		cuerpo.Name = "HumanoidRootPart"
		cuerpo.Size = Vector3.new(0.8, 0.8, 1.0)
		cuerpo.Position = posSuelo
		cuerpo.Color = if i == 1
			then Color3.fromRGB(245, 245, 245)
			else Color3.fromRGB(210, 105, 50)
		cuerpo.Material = Enum.Material.SmoothPlastic
		cuerpo.Anchored = true
		cuerpo.CanCollide = false
		cuerpo.Parent = modelo
		modelo.PrimaryPart = cuerpo

		local cabeza = Instance.new("Part")
		cabeza.Name = "Cabeza"
		cabeza.Size = Vector3.new(0.5, 0.5, 0.5)
		cabeza.Position = cuerpo.Position + Vector3.new(0, 0.5, -0.5)
		cabeza.Color = cuerpo.Color
		cabeza.Material = Enum.Material.SmoothPlastic
		cabeza.Anchored = false
		cabeza.CanCollide = false
		cabeza.Parent = modelo
		soldar(cuerpo, cabeza)

		local cresta = Instance.new("Part")
		cresta.Name = "Cresta"
		cresta.Size = Vector3.new(0.2, 0.3, 0.4)
		cresta.Position = cabeza.Position + Vector3.new(0, 0.35, 0)
		cresta.Color = Color3.fromRGB(220, 30, 30)
		cresta.Material = Enum.Material.SmoothPlastic
		cresta.Anchored = false
		cresta.CanCollide = false
		cresta.Parent = modelo
		soldar(cuerpo, cresta)

		local pico = Instance.new("Part")
		pico.Name = "Pico"
		pico.Size = Vector3.new(0.2, 0.2, 0.3)
		pico.Position = cabeza.Position + Vector3.new(0, -0.1, -0.35)
		pico.Color = Color3.fromRGB(255, 190, 40)
		pico.Material = Enum.Material.SmoothPlastic
		pico.Anchored = false
		pico.CanCollide = false
		pico.Parent = modelo
		soldar(cuerpo, pico)

		-- Animación de picoteo en el solar
		task.spawn(function()
			while modelo.Parent do
				task.wait(math.random(25, 45) / 10)
				-- Inclinarse a picotear
				cabeza.CFrame = cuerpo.CFrame
					* CFrame.new(0, 0.2, -0.6)
					* CFrame.Angles(math.rad(30), 0, 0)
				task.wait(0.3)
				cabeza.CFrame = cuerpo.CFrame * CFrame.new(0, 0.5, -0.5)
			end
		end)
	end
end

-- ====================================================================
-- 4. LA CHIVA RUMBERA TRADICIONAL (BUS ESCALERA DE VILLA ALMÍBAR)
-- ====================================================================
local function crearChivaRumbera(parentFolder: Instance)
	local modelo = Instance.new("Model")
	modelo.Name = "Vehiculo_ChivaRumbera"
	modelo.Parent = parentFolder

	local posInicial = Vector3.new(0, 69.5, 20)

	local chasis = Instance.new("Part")
	chasis.Name = "Chasis"
	chasis.Size = Vector3.new(5.0, 1.8, 12.0)
	chasis.Position = posInicial
	chasis.Color = Color3.fromRGB(240, 200, 30) -- Amarillo Chiva
	chasis.Material = Enum.Material.Metal
	chasis.Anchored = true
	chasis.CanCollide = true
	chasis.Parent = modelo
	modelo.PrimaryPart = chasis

	-- Franjas de color patriótico colombiano
	local franjaAzul = Instance.new("Part")
	franjaAzul.Name = "FranjaAzul"
	franjaAzul.Size = Vector3.new(5.1, 0.5, 12.0)
	franjaAzul.Position = chasis.Position + Vector3.new(0, 0.4, 0)
	franjaAzul.Color = Color3.fromRGB(30, 70, 180)
	franjaAzul.Material = Enum.Material.SmoothPlastic
	franjaAzul.Anchored = true
	franjaAzul.CanCollide = false
	franjaAzul.Parent = modelo
	soldar(chasis, franjaAzul)

	local franjaRoja = Instance.new("Part")
	franjaRoja.Name = "FranjaRoja"
	franjaRoja.Size = Vector3.new(5.1, 0.5, 12.0)
	franjaRoja.Position = chasis.Position + Vector3.new(0, -0.2, 0)
	franjaRoja.Color = Color3.fromRGB(220, 40, 40)
	franjaRoja.Material = Enum.Material.SmoothPlastic
	franjaRoja.Anchored = true
	franjaRoja.CanCollide = false
	franjaRoja.Parent = modelo
	soldar(chasis, franjaRoja)

	-- Techo con portaequipaje
	local techo = Instance.new("Part")
	techo.Name = "TechoPortaequipaje"
	techo.Size = Vector3.new(5.2, 0.6, 11.5)
	techo.Position = chasis.Position + Vector3.new(0, 3.2, 0)
	techo.Color = Color3.fromRGB(230, 230, 240)
	techo.Material = Enum.Material.Metal
	techo.Anchored = true
	techo.CanCollide = false
	techo.Parent = modelo
	soldar(chasis, techo)

	-- Farolas frontales iluminadas
	local faroIzq = Instance.new("Part")
	faroIzq.Name = "FaroIzq"
	faroIzq.Size = Vector3.new(0.8, 0.8, 0.3)
	faroIzq.Position = chasis.Position + Vector3.new(-1.8, 0.2, -6.1)
	faroIzq.Color = Color3.fromRGB(255, 255, 200)
	faroIzq.Material = Enum.Material.Neon
	faroIzq.Anchored = true
	faroIzq.CanCollide = false
	faroIzq.Parent = modelo
	soldar(chasis, faroIzq)

	local faroDer = Instance.new("Part")
	faroDer.Name = "FaroDer"
	faroDer.Size = Vector3.new(0.8, 0.8, 0.3)
	faroDer.Position = chasis.Position + Vector3.new(1.8, 0.2, -6.1)
	faroDer.Color = Color3.fromRGB(255, 255, 200)
	faroDer.Material = Enum.Material.Neon
	faroDer.Anchored = true
	faroDer.CanCollide = false
	faroDer.Parent = modelo
	soldar(chasis, faroDer)

	local luzChiva = Instance.new("PointLight")
	luzChiva.Name = "LuzFrontal"
	luzChiva.Color = Color3.fromRGB(255, 245, 180)
	luzChiva.Brightness = 3.0
	luzChiva.Range = 28
	luzChiva.Parent = faroIzq

	-- Rótulo frontal de la chiva
	local bbg = Instance.new("BillboardGui")
	bbg.Name = "RotuloRuta"
	bbg.Size = UDim2.fromOffset(220, 38)
	bbg.StudsOffset = Vector3.new(0, 4.2, -5.5)
	bbg.AlwaysOnTop = true
	bbg.MaxDistance = 60
	bbg.Parent = chasis

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
	lbl.BackgroundTransparency = 0.2
	lbl.Font = Enum.Font.FredokaOne
	lbl.Text = "🚌 LA CHIVA ALMIBARADA"
	lbl.TextColor3 = Color3.fromRGB(255, 220, 50)
	lbl.TextSize = 12
	lbl.Parent = bbg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = lbl

	-- Recorrido en bucle por la avenida principal
	task.spawn(function()
		local paradas = {
			Vector3.new(0, 69.5, 20),
			Vector3.new(0, 71.0, 80),
			Vector3.new(0, 78.0, 160),
			Vector3.new(0, 88.0, 260),
			Vector3.new(0, 96.5, 360),
			Vector3.new(0, 88.0, 260),
			Vector3.new(0, 78.0, 160),
			Vector3.new(0, 71.0, 80),
		}

		local idx = 1
		while modelo.Parent do
			idx = (idx % #paradas) + 1
			local destino = paradas[idx]
			local dir = destino - chasis.Position
			local dist = dir.Magnitude

			if dist > 1.5 then
				local duracion = math.clamp(dist / 14, 2.5, 9.0)
				local cframeObjetivo = CFrame.lookAt(destino, destino + dir.Unit)

				local tweenChasis = TweenService:Create(
					chasis,
					TweenInfo.new(duracion, Enum.EasingStyle.Linear),
					{ CFrame = cframeObjetivo }
				)
				tweenChasis:Play()

				-- Acompañar piezas
				franjaAzul.CFrame = cframeObjetivo * CFrame.new(0, 0.4, 0)
				franjaRoja.CFrame = cframeObjetivo * CFrame.new(0, -0.2, 0)
				techo.CFrame = cframeObjetivo * CFrame.new(0, 3.2, 0)
				faroIzq.CFrame = cframeObjetivo * CFrame.new(-1.8, 0.2, -6.1)
				faroDer.CFrame = cframeObjetivo * CFrame.new(1.8, 0.2, -6.1)

				task.wait(duracion)

				-- Tocar bocina en esquinas principales
				if idx == 1 or idx == 3 or idx == 5 then
					local bocina = Instance.new("Sound")
					bocina.SoundId = "rbxasset://sounds/electronicpingshort.wav"
					bocina.Volume = 0.8
					bocina.Parent = chasis
					bocina:Play()
					task.delay(1.5, function()
						bocina:Destroy()
					end)
				end
			else
				task.wait(1.0)
			end
		end
	end)
end

-- ====================================================================
-- 5. DECORACIÓN AMBIENTAL COLOMBIANA: BANDERINES Y FAROLES LUMINOSOS
-- ====================================================================
local function decorarAmbienteBarrio(parentFolder: Instance)
	local puntosFaroles = {
		Vector3.new(-70, 68, -40),
		Vector3.new(-30, 68, 20),
		Vector3.new(20, 68, 60),
		Vector3.new(80, 68, 100),
		Vector3.new(-20, 78, 220),
		Vector3.new(15, 85, 280),
		Vector3.new(-35, 95, 340),
		Vector3.new(10, 105, 420),
	}

	local carpetaLuces = Instance.new("Folder")
	carpetaLuces.Name = "AlumbradoPublico"
	carpetaLuces.Parent = parentFolder

	for i, pos in ipairs(puntosFaroles) do
		local posSuelo = obtenerPosicionSuelo(pos, 0)
		local poste = Instance.new("Part")
		poste.Name = "PosteLuz_" .. i
		poste.Size = Vector3.new(0.6, 9, 0.6)
		poste.Position = posSuelo + Vector3.new(0, 4.5, 0)
		poste.Color = Color3.fromRGB(45, 50, 60)
		poste.Material = Enum.Material.Metal
		poste.Anchored = true
		poste.CanCollide = false
		poste.Parent = carpetaLuces

		local foco = Instance.new("Part")
		foco.Name = "Foco"
		foco.Size = Vector3.new(1.2, 0.6, 1.2)
		foco.Position = poste.Position + Vector3.new(0, 4.2, 0)
		foco.Color = Color3.fromRGB(255, 230, 150)
		foco.Material = Enum.Material.Neon
		foco.Anchored = true
		foco.CanCollide = false
		foco.Parent = poste

		local luz = Instance.new("PointLight")
		luz.Name = "LuzCalida"
		luz.Color = Color3.fromRGB(255, 215, 120)
		luz.Brightness = 2.2
		luz.Range = 32
		luz.Shadows = true
		luz.Parent = foco
	end

	-- Banderines festivos en el cruce comercial (bunting flags)
	local carpetaBanderines = Instance.new("Folder")
	carpetaBanderines.Name = "GuirnaldasFiesta"
	carpetaBanderines.Parent = parentFolder

	local coloresBandera = {
		Color3.fromRGB(255, 215, 0), -- Amarillo
		Color3.fromRGB(40, 90, 220), -- Azul
		Color3.fromRGB(230, 40, 40), -- Rojo
		Color3.fromRGB(80, 200, 100), -- Verde
		Color3.fromRGB(240, 100, 180), -- Rosa dulce
	}

	local origenBanderas = Vector3.new(45, 74, 75)
	for b = 1, 10 do
		local banderin = Instance.new("Part")
		banderin.Name = "Banderin_" .. b
		banderin.Size = Vector3.new(0.8, 1.2, 0.1)
		banderin.Position = origenBanderas + Vector3.new(b * 1.6, math.sin(b * 0.5) * 0.4, 0)
		banderin.Color = coloresBandera[(b % #coloresBandera) + 1]
		banderin.Material = Enum.Material.SmoothPlastic
		banderin.Anchored = true
		banderin.CanCollide = false
		banderin.Parent = carpetaBanderines
	end
end

-- ====================================================================
-- 5. PEATONES VIVOS CAMINANDO POR LAS ACERAS DEL PUEBLO
-- ====================================================================
local function crearPeatonesCaminando(parentFolder: Instance)
	local carpetaPeatones = Instance.new("Folder")
	carpetaPeatones.Name = "Peatones_Caminando"
	carpetaPeatones.Parent = parentFolder

	local listaPeatones = {
		{
			Nombre = "Peaton_DonaGladys",
			Apodo = "Doña Gladys (Con Canasto)",
			ColorRopa = Color3.fromRGB(190, 80, 140),
			ColorPantalon = Color3.fromRGB(45, 40, 50),
			Icono = "🧺",
			Ruta = {
				Vector3.new(6, 60, -35),
				Vector3.new(6, 60, 45),
				Vector3.new(6, 68, 90),
				Vector3.new(6, 60, 10),
			},
			Frase = "¡Voy para la tienda de Don Chucho a ver si llegaron los dulces!",
		},
		{
			Nombre = "Peaton_DonChepe",
			Apodo = "Don Chepe (El Campesino)",
			ColorRopa = Color3.fromRGB(230, 220, 205),
			ColorPantalon = Color3.fromRGB(70, 50, 35),
			Icono = "🌾",
			Ruta = {
				Vector3.new(-6, 60, 40),
				Vector3.new(-6, 60, -30),
				Vector3.new(-6, 68, 75),
			},
			Frase = "¡Buenas tardes patrón! Qué bonita que está la tarde en el pueblo.",
		},
		{
			Nombre = "Peaton_SantiEstudiante",
			Apodo = "Santi (El Mandadero)",
			ColorRopa = Color3.fromRGB(50, 120, 220),
			ColorPantalon = Color3.fromRGB(35, 40, 55),
			Icono = "🏃‍♂️",
			Ruta = {
				Vector3.new(-42, 60, -10),
				Vector3.new(-42, 60, 30),
				Vector3.new(-70, 60, -30),
			},
			Frase = "¡Llevo un encargo de panelitas para mi tía!",
		},
		{
			Nombre = "Peaton_DrJavier",
			Apodo = "Dr. Javier (Camino al Hospital)",
			ColorRopa = Color3.fromRGB(240, 245, 250),
			ColorPantalon = Color3.fromRGB(35, 75, 130),
			Icono = "👨‍⚕️",
			Ruta = {
				Vector3.new(6, 60, 60),
				Vector3.new(6, 75, 160),
				Vector3.new(12, 83.2, 210),
				Vector3.new(6, 75, 160),
			},
			Frase = "¡Voy subiendo al Hospital San Rafael para el turno de urgencias!",
		},
		{
			Nombre = "Peaton_NikoCiclista",
			Apodo = "Niko (El Deportista)",
			ColorRopa = Color3.fromRGB(255, 120, 30),
			ColorPantalon = Color3.fromRGB(25, 25, 30),
			Icono = "🚴",
			Ruta = {
				Vector3.new(6, 83, 215),
				Vector3.new(-18, 81.5, 255),
				Vector3.new(6, 90, 320),
				Vector3.new(-18, 81.5, 255),
			},
			Frase = "¡Esta subida a la ladera es exigente pero perfecta para entrenar!",
		},
	}

	for _, info in ipairs(listaPeatones) do
		local modelo = Instance.new("Model")
		modelo.Name = info.Nombre
		modelo.Parent = carpetaPeatones

		local posIni = obtenerPosicionSuelo(info.Ruta[1], 2.7)

		local hrp = Instance.new("Part")
		hrp.Name = "HumanoidRootPart"
		hrp.Size = Vector3.new(1.6, 1.8, 0.8)
		hrp.Position = posIni
		hrp.Transparency = 1
		hrp.CanCollide = false
		hrp.Anchored = true
		hrp.Parent = modelo
		modelo.PrimaryPart = hrp

		local torso = Instance.new("Part")
		torso.Name = "Torso"
		torso.Size = Vector3.new(1.6, 1.8, 0.8)
		torso.Position = hrp.Position
		torso.Color = info.ColorRopa
		torso.Material = Enum.Material.SmoothPlastic
		torso.Anchored = false
		torso.CanCollide = false
		torso.Parent = modelo
		soldar(hrp, torso)

		local cabeza = Instance.new("Part")
		cabeza.Name = "Head"
		cabeza.Size = Vector3.new(1, 1, 1)
		cabeza.Position = torso.Position + Vector3.new(0, 1.4, 0)
		cabeza.Color = Color3.fromRGB(240, 205, 175)
		cabeza.Material = Enum.Material.SmoothPlastic
		cabeza.Anchored = false
		cabeza.CanCollide = false
		cabeza.Parent = modelo
		soldar(hrp, cabeza)

		local piernas = Instance.new("Part")
		piernas.Name = "Piernas"
		piernas.Size = Vector3.new(1.4, 1.6, 0.7)
		piernas.Position = torso.Position + Vector3.new(0, -1.6, 0)
		piernas.Color = info.ColorPantalon
		piernas.Material = Enum.Material.SmoothPlastic
		piernas.Anchored = false
		piernas.CanCollide = false
		piernas.Parent = modelo
		soldar(hrp, piernas)

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "PromptPeaton"
		prompt.ObjectText = info.Apodo
		prompt.ActionText = "Comprar Dulce / Saludar"
		prompt.HoldDuration = 0.2
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = torso

		prompt.Triggered:Connect(function(player: Player)
			local datos = GestorDatos.ObtenerDatos(player)
			if not datos then
				return
			end

			-- Buscar algún dulce en inventario
			local dulceParaVender: string? = nil
			local defDulce: any = nil
			for idDulce, cant in pairs(datos.Inventario) do
				if cant > 0 then
					dulceParaVender = idDulce
					defDulce = Datos.Dulces[idDulce]
					break
				end
			end

			if dulceParaVender and GestorDatos.QuitarDulce(player, dulceParaVender, 1) then
				local mult = datos.MultiplicadorRenacimiento or 1
				local valorBase = defDulce and defDulce.ValorVenta or 1
				local ganancia = math.max(valorBase * 3, 5) * mult
				GestorDatos.AgregarPesos(player, ganancia)
				datos.Fama += 1

				local sonido = Instance.new("Sound")
				sonido.SoundId = "rbxasset://sounds/electronicpingshort.wav"
				sonido.Volume = 0.7
				sonido.Parent = torso
				sonido:Play()
				task.delay(1.5, function()
					sonido:Destroy()
				end)

				local nombreD = defDulce and defDulce.Nombre or "Dulce"
				EventosRemotos.MostrarDialogoNPC:FireClient(player, {
					Nombre = info.Apodo,
					Titulo = "¡Venta Callejera!",
					Icono = "🍬",
					Mensaje = string.format("¡Uy qué delicia! Te compré 1 %s por $%d pesos. ¡Gracias patrón!", nombreD, ganancia),
				})
			else
				EventosRemotos.MostrarDialogoNPC:FireClient(player, {
					Nombre = info.Apodo,
					Titulo = "Peatón de Villa Almíbar",
					Icono = info.Icono,
					Mensaje = info.Frase,
				})
			end
		end)

		-- Hilo de patrullaje continuo adaptado al suelo
		task.spawn(function()
			local ruta = info.Ruta
			local idx = 1
			while modelo.Parent do
				idx = (idx % #ruta) + 1
				local metaPunto = ruta[idx]
				local velPeaton = 4.2

				while modelo.Parent do
					local curPos = hrp.Position
					local deltaXZ = (metaPunto - curPos) * Vector3.new(1, 0, 1)
					local distXZ = deltaXZ.Magnitude
					if distXZ <= 1.2 then
						break
					end

					local dt = task.wait(0.1)
					local paso = deltaXZ.Unit * math.min(distXZ, velPeaton * dt)
					local nextXZ = curPos + paso
					local nextGrounded = obtenerPosicionSuelo(nextXZ, 2.7)
					hrp.CFrame = CFrame.lookAt(nextGrounded, nextGrounded + deltaXZ.Unit)
				end

				task.wait(math.random(3, 5))
			end
		end)
	end
end

-- ====================================================================
-- 6. PALOMAS DE LA PLAZOLETA (VIDA ANIMAL URBANA)
-- ====================================================================
local function crearPalomasPlazoleta(parentFolder: Instance)
	local carpetaPalomas = Instance.new("Folder")
	carpetaPalomas.Name = "PalomasPlaza"
	carpetaPalomas.Parent = parentFolder

	local posicionesPalomas = {
		Vector3.new(-22, 60, -12),
		Vector3.new(-18, 60, -8),
		Vector3.new(-24, 60, -5),
		Vector3.new(14, 60, 12),
		Vector3.new(18, 60, 8),
		Vector3.new(16, 60, 15),
	}

	for i, posBase in ipairs(posicionesPalomas) do
		local pos = obtenerPosicionSuelo(posBase, 0.4)
		local paloma = Instance.new("Model")
		paloma.Name = "Paloma_" .. i
		paloma.Parent = carpetaPalomas

		local cuerpo = Instance.new("Part")
		cuerpo.Name = "Cuerpo"
		cuerpo.Size = Vector3.new(0.6, 0.5, 0.9)
		cuerpo.Position = pos
		cuerpo.Color = Color3.fromRGB(130, 135, 145) -- Gris paloma
		cuerpo.Material = Enum.Material.SmoothPlastic
		cuerpo.Anchored = true
		cuerpo.CanCollide = false
		cuerpo.Parent = paloma
		paloma.PrimaryPart = cuerpo

		local cabeza = Instance.new("Part")
		cabeza.Name = "Head"
		cabeza.Shape = Enum.PartType.Ball
		cabeza.Size = Vector3.new(0.35, 0.35, 0.35)
		cabeza.Position = pos + Vector3.new(0, 0.35, -0.4)
		cabeza.Color = Color3.fromRGB(110, 115, 125)
		cabeza.Material = Enum.Material.SmoothPlastic
		cabeza.Anchored = false
		cabeza.CanCollide = false
		cabeza.Parent = paloma
		soldar(cuerpo, cabeza)

		local pico = Instance.new("Part")
		pico.Name = "Pico"
		pico.Size = Vector3.new(0.12, 0.1, 0.2)
		pico.Position = cabeza.Position + Vector3.new(0, -0.05, -0.2)
		pico.Color = Color3.fromRGB(240, 180, 50)
		pico.Material = Enum.Material.SmoothPlastic
		pico.Anchored = false
		pico.CanCollide = false
		pico.Parent = paloma
		soldar(cuerpo, pico)

		-- Pequeño picoteo animado
		task.spawn(function()
			local cfBase = cuerpo.CFrame
			while paloma.Parent do
				task.wait(math.random(1, 3))
				local rot = CFrame.Angles(0, math.rad(math.random(-45, 45)), 0)
				cuerpo.CFrame = cfBase * rot
				-- Picotear
				task.wait(0.2)
				cuerpo.CFrame = cfBase * rot * CFrame.Angles(math.rad(15), 0, 0)
				task.wait(0.2)
				cuerpo.CFrame = cfBase * rot
			end
		end)
	end
end

-- ====================================================================
-- INICIALIZADOR GENERAL DE VIDA DEL MUNDO
-- ====================================================================
local function inicializarVidaMundo()
	local mapa = Workspace:WaitForChild("Mapa", 10)
	if not mapa then
		return
	end
	local decoracion = mapa:WaitForChild("Decoracion", 10)
	if not decoracion then
		return
	end

	local carpetaVida = decoracion:FindFirstChild("VidaMundo")
	if carpetaVida then
		carpetaVida:Destroy()
	end
	carpetaVida = Instance.new("Folder")
	carpetaVida.Name = "VidaMundo"
	carpetaVida.Parent = decoracion

	-- 1. Estudiantes en el patio del colegio (con posiciones ajustadas)
	local listaEstudiantesPatio = {
		{
			Nombre = "Estudiante_Mateo",
			Apodo = "Mateo (El Pelota)",
			Posicion = Vector3.new(-82, 60, -78),
			ColorRopa = Color3.fromRGB(45, 110, 210),
			ColorPantalon = Color3.fromRGB(30, 35, 50),
			PuntosMovimiento = {
				Vector3.new(-82, 60, -78),
				Vector3.new(-74, 60, -88),
				Vector3.new(-88, 60, -84),
			},
			Frases = {
				"¡Pásala, pásala que no hay portero!",
				"¡Un bombón me da energía para meter un gol!",
				"¡Ojo con el silbato de Tiza!",
			},
		},
		{
			Nombre = "Estudiante_Valentina",
			Apodo = "Valentina (Rayuela)",
			Posicion = Vector3.new(-100, 60, -85),
			ColorRopa = Color3.fromRGB(230, 75, 120),
			ColorPantalon = Color3.fromRGB(40, 30, 45),
			PuntosMovimiento = {
				Vector3.new(-100, 60, -85),
				Vector3.new(-106, 60, -92),
				Vector3.new(-96, 60, -95),
			},
			Frases = {
				"¡Saltar rayuela da mucha hambre!",
				"¡Doña Melcocha cocina los mejores dulces del mundo!",
				"¡Quiero una gomita ácida de mora!",
			},
		},
		{
			Nombre = "Estudiante_Camilo",
			Apodo = "Camilo (El Piloto)",
			Posicion = Vector3.new(-72, 60, -100),
			ColorRopa = Color3.fromRGB(50, 170, 90),
			ColorPantalon = Color3.fromRGB(35, 45, 38),
			Frases = {
				"¡Cuando sea grande voy a tener una chiva de dulces!",
				"¡El Alcalde Apio odia las cosas ricas!",
				"¡Véndeme un bombón antes de que toquen la campana!",
			},
		},
		{
			Nombre = "Estudiante_Mariana",
			Apodo = "Mariana (Cuaderno)",
			Posicion = Vector3.new(-115, 60, -108),
			ColorRopa = Color3.fromRGB(240, 160, 40),
			ColorPantalon = Color3.fromRGB(45, 35, 30),
			Frases = {
				"¡Estudiar matemáticas sin azúcar da mucho sueño!",
				"¡Guardé mis $10 pesos del recreo para un bombón!",
				"¡El portón del colegio tiene candado, qué encierro!",
			},
		},
	}

	for _, est in ipairs(listaEstudiantesPatio) do
		crearEstudianteVivo(est, carpetaVida)
	end

	-- 2. Vecinos en las aceras del barrio (posiciones corregidas en aceras reales)
	local listaVecinosBarrio = {
		{
			Nombre = "Vecino_DonPacho",
			Apodo = "Don Pacho (El del Tinto)",
			Posicion = Vector3.new(6, 68, 70),
			ColorRopa = Color3.fromRGB(220, 215, 200),
			ColorPantalon = Color3.fromRGB(70, 50, 35),
			Icono = "☕",
			Frases = {
				"¡En mis tiempos el azúcar no era pecado ni delito!",
				"¡Qué viva el dulce de Doña Melcocha!",
				"¡Ojo con los retenes de la policía dental, andan alborotados!",
			},
		},
		{
			Nombre = "Vecina_DonaLuz",
			Apodo = "Doña Luz (La Chismosa)",
			Posicion = Vector3.new(-6, 68, 60),
			ColorRopa = Color3.fromRGB(240, 120, 160),
			ColorPantalon = Color3.fromRGB(50, 40, 55),
			Icono = "👀",
			Frases = {
				"¡Ave María Purísima! Vi pasar una patrulla dental a toda mecha.",
				"¡Caminen con cuidado que el Alcalde Apio mandó inspectores!",
				"¡Si esconden la carga en los callejones la policía no los ve!",
			},
		},
		{
			Nombre = "Vecino_DonRogelio",
			Apodo = "Don Rogelio (Chófer de Chiva)",
			Posicion = Vector3.new(6, 68, 115),
			ColorRopa = Color3.fromRGB(55, 95, 160),
			ColorPantalon = Color3.fromRGB(30, 35, 45),
			Icono = "🚌",
			Frases = {
				"¡Mi chiva corre más rápido que cualquier patrulla dental!",
				"¡Llévele melcochas a la gente de la montaña alta!",
				"¡La carretera de ladera es brava pero paga bien!",
			},
		},
	}

	for _, vec in ipairs(listaVecinosBarrio) do
		crearVecinoBarrio(vec, carpetaVida)
	end

	-- 3. Animales típicos (Firulais el perro criollo y las gallinas de la abuela)
	crearFirulaisElPerrito(carpetaVida)
	crearGallinasMelcocha(carpetaVida)

	-- 4. Ruta de buses / La Chiva Rumbera Tradicional
	crearChivaRumbera(carpetaVida)

	-- 5. Faroles, banderines y alumbrado
	decorarAmbienteBarrio(carpetaVida)

	-- 6. Peatones caminando por las aceras y palomas en la plazoleta
	crearPeatonesCaminando(carpetaVida)
	crearPalomasPlazoleta(carpetaVida)

	print(
		"El Patrón del Dulce: Sistema de Vida del Mundo (Estudiantes, Vecinos, Animales y Chiva) Inicializado"
	)
end

task.spawn(inicializarVidaMundo)
