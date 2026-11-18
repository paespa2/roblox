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

	-- 1. Buscar en el nuevo edificio modelado por Andrés
	local nuevoEdificio = mapa:FindFirstChild("Edificio_CocinaInicial")
	if nuevoEdificio then
		local paila = nuevoEdificio:FindFirstChild("Paila")
			or nuevoEdificio:FindFirstChild("FogonLena")
		if paila and paila:IsA("BasePart") then
			return paila
		end
	end

	-- 2. Fallback a la estructura previa
	local cocina = mapa:FindFirstChild("CocinaInicial")
	if cocina then
		local paila = cocina:FindFirstChild("Paila_Melcocha")
			or cocina:FindFirstChild("Fogon_Ladrillo")
		if paila and paila:IsA("BasePart") then
			return paila
		end
	end

	return nil
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

	local listaRecetas =
		{ "Dulce_Bombon", "Dulce_Gomita", "Dulce_Panelita", "Dulce_Arequipe", "Dulce_Chicle" }
	local recetasJugador: { [Player]: string } = {}

	local promptCambiar = paila:FindFirstChild("PromptCambiarReceta") :: ProximityPrompt?
	if not promptCambiar then
		promptCambiar = Instance.new("ProximityPrompt")
		promptCambiar.Name = "PromptCambiarReceta"
		promptCambiar.ObjectText = "Paila de Melcocha"
		promptCambiar.ActionText = "Cambiar Receta"
		promptCambiar.HoldDuration = 0.2
		promptCambiar.MaxActivationDistance = 14
		promptCambiar.RequiresLineOfSight = false
		promptCambiar.Parent = paila

		promptCambiar.Triggered:Connect(function(player: Player)
			local recetaActual = recetasJugador[player] or "Dulce_Bombon"
			local idxActual = table.find(listaRecetas, recetaActual) or 1
			local siguienteIdx = (idxActual % #listaRecetas) + 1
			local nuevaReceta = listaRecetas[siguienteIdx]
			recetasJugador[player] = nuevaReceta

			local info = Datos.Dulces[nuevaReceta]
			local nom = if info then info.Nombre else nuevaReceta
			prompt.ActionText =
				string.format("Cocinar %s (%ds)", nom, if info then info.TiempoProduccion else 5)
			estadoLabel.Text = string.format("Receta: %s (Pulsa E)", nom)
			estadoLabel.TextColor3 = Color3.fromRGB(255, 215, 120)

			EventosRemotos.MostrarDialogoNPC:FireClient(player, {
				Nombre = "Paila Clandestina",
				Titulo = "Receta Seleccionada",
				Icono = "🍳",
				Mensaje = string.format("Cambiado a: %s. ¡Pulsa E para empezar a cocinar!", nom),
			})
		end)
	end

	prompt.Triggered:Connect(function(player: Player)
		local estadoActual = coccionesActivas[player]

		if not estadoActual then
			local idDulceSeleccionado = recetasJugador[player] or "Dulce_Bombon"
			local infoDulce = Datos.Dulces[idDulceSeleccionado]
			if not infoDulce then
				idDulceSeleccionado = "Dulce_Bombon"
				infoDulce = Datos.Dulces[idDulceSeleccionado]
			end

			local duracion = math.round(
				infoDulce.TiempoProduccion * GestorDatos.ObtenerMultiplicadorTiempoCocina(player)
			)

			coccionesActivas[player] = {
				IdDulce = idDulceSeleccionado,
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
				IdDulce = idDulceSeleccionado,
				Duracion = duracion,
				Listo = false,
			})

			task.delay(duracion, function()
				if
					coccionesActivas[player]
					and coccionesActivas[player].IdDulce == idDulceSeleccionado
				then
					coccionesActivas[player].Listo = true

					prompt.ActionText = string.format("¡Recoger %s!", infoDulce.Nombre)
					estadoLabel.Text = "✨ ¡LISTO PARA RECOGER! ✨"
					estadoLabel.TextColor3 = Color3.fromRGB(100, 255, 140)
					stroke.Color = Color3.fromRGB(90, 240, 120)
					barraFondo.Visible = false

					EventosRemotos.CocinaActualizada:FireClient(player, {
						IdDulce = idDulceSeleccionado,
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
			sonidoRecoger.SoundId = "rbxasset://sounds/electronicpingshort.wav"
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

	local duracion = math.round(
		infoDulce.TiempoProduccion * GestorDatos.ObtenerMultiplicadorTiempoCocina(player)
	)

	coccionesActivas[player] = {
		IdDulce = idDulce,
		Inicio = os.time(),
		Duracion = duracion,
		Listo = false,
	}

	task.delay(duracion, function()
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

local DIALOGOS_MELCOCHA = {
	"¡Mijo! Si el alcalde Apio cree que nos va a dejar sin dulce, está muy equivocado. Venga le enseño a hacer los primeros bombones en la olla vieja. Nadie se mete con la receta de la abuela.",
	"Eso es, mijo. No deje quemar el melao. Espere unos segundos a que cuaje y empaque los bombones antes de que llegue la patrulla con el cepillo gigante.",
	"Cargue la canasta de la bicicleta con la tecla V. Ni se le ocurra llenar demasiado el morral que después no puede pedalear en la subida.",
	"Si ve al Agente Dental con la sirena prendida, ¡péguese a los callejones o escóndase en las esquinas hasta que se le enfríen las caries!",
}

local indiceDialogo = 1

local function configurarDonaMelcocha()
	local mapa = Workspace:WaitForChild("Mapa", 10)
	if not mapa then
		return
	end
	local decoracion = mapa:WaitForChild("Decoracion", 10)
	if not decoracion then
		return
	end
	local npcs = decoracion:WaitForChild("NPCs_Interactivos", 10)
	if not npcs then
		return
	end
	local melcocha = npcs:FindFirstChild("Personaje_DonaMelcocha")
	if melcocha then
		local part = melcocha.PrimaryPart
			or melcocha:FindFirstChild("HumanoidRootPart")
			or melcocha:FindFirstChildWhichIsA("BasePart")
		if part then
			local prompt = part:FindFirstChildOfClass("ProximityPrompt")
			if not prompt then
				prompt = Instance.new("ProximityPrompt")
				prompt.Name = "PromptDonaMelcocha"
				prompt.ObjectText = "Doña Melcocha (La Abuela)"
				prompt.ActionText = "Hablar con la Abuela"
				prompt.HoldDuration = 0.3
				prompt.MaxActivationDistance = 14
				prompt.RequiresLineOfSight = false
				prompt.Parent = part
			end
			prompt.Triggered:Connect(function(player: Player)
				local datos = GestorDatos.ObtenerDatos(player)
				local cap = GestorDatos.ObtenerCapitulo(player)
				local cantBombones = (
					datos
					and datos.Inventario
					and datos.Inventario["Dulce_Bombon"]
				) or 0

				local mensaje = ""
				if cap == 1 then
					if cantBombones == 0 and (datos and datos.PesosDulces or 0) < 50 then
						mensaje =
							"¡Mijo! El Alcalde Apio cree que nos va a prohibir el dulce, ¡pero aquí manda la paila! Vaya al fogón, cocine una tanda de bombones y luego pulse la tecla V para montar su bicicleta e ir al colegio."
					elseif cantBombones > 0 and (datos and datos.PesosDulces or 0) < 50 then
						mensaje =
							"¡Eso es, mijo! Ya tiene los bombones listos. Móntese en la bicicleta con la tecla V y llévelos al recreo del colegio con Lola Paleta o los niños en el patio. ¡Si el Coordinador Tiza lo acosa, atúrdalo con la cauchera de gomitas!"
					else
						mensaje =
							"¡Mijo, ya tiene los pesos necesarios! Vaya al portón del colegio para abrirlo hacia el barrio y comenzar el Capítulo 2."
					end
				else
					local dialogoGenerico = DIALOGOS_MELCOCHA[indiceDialogo]
					indiceDialogo = (indiceDialogo % #DIALOGOS_MELCOCHA) + 1
					mensaje = dialogoGenerico
				end

				-- Mecánica de Bendición de la Abuela: Buff de energía dulce (+15% velocidad y sigilo)
				local char = player.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				local root = char and char:FindFirstChild("HumanoidRootPart")
				local tieneBendicion = player:GetAttribute("BendicionAbuela")

				if hum and not tieneBendicion then
					player:SetAttribute("BendicionAbuela", true)
					local speedOriginal = hum.WalkSpeed
					hum.WalkSpeed = math.max(speedOriginal, 18)

					-- Efecto visual dorado de bendición
					if root then
						local chispas = Instance.new("ParticleEmitter")
						chispas.Name = "ParticulasBendicion"
						chispas.Color = ColorSequence.new(Color3.fromRGB(255, 220, 80))
						chispas.LightEmission = 0.8
						chispas.Rate = 12
						chispas.Lifetime = NumberRange.new(0.6, 1.2)
						chispas.Speed = NumberRange.new(1, 3)
						chispas.Size = NumberSequence.new(0.3, 0)
						chispas.Parent = root
						task.delay(120, function()
							if chispas.Parent then
								chispas:Destroy()
							end
						end)
					end

					task.delay(120, function()
						if player.Parent then
							player:SetAttribute("BendicionAbuela", nil)
							if hum and hum.Parent then
								hum.WalkSpeed = speedOriginal
							end
						end
					end)

					mensaje = mensaje .. "\n\n✨ ¡Doña Melcocha te dio su Bendición! (+15% de velocidad y sigilo durante 2 minutos)."
				end

				EventosRemotos.MostrarDialogoNPC:FireClient(player, {
					Nombre = "Doña Melcocha",
					Titulo = "La Abuela",
					Icono = "👵",
					Mensaje = mensaje,
				})
			end)
		end
	end
end

local function configurarTiaCocinera(paila: BasePart)
	local mapa = Workspace:FindFirstChild("Mapa")
	local decoracion = mapa and mapa:FindFirstChild("Decoracion")
	local npcs = decoracion and decoracion:FindFirstChild("NPCs_Interactivos")
	if not npcs then
		return
	end

	local existente = npcs:FindFirstChild("NPC_TiaCocinera")
	if existente then
		existente:Destroy()
	end

	local tia = Instance.new("Model")
	tia.Name = "NPC_TiaCocinera"
	tia.Parent = npcs

	local pos = paila.Position + Vector3.new(4, 0, 0)
	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(2, 2, 1)
	hrp.Position = pos
	hrp.Transparency = 1
	hrp.CanCollide = false
	hrp.Anchored = true
	hrp.Parent = tia
	tia.PrimaryPart = hrp

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(1.8, 2, 0.9)
	torso.Position = pos
	torso.Color = Color3.fromRGB(245, 180, 80) -- Vestido amarillo
	torso.Material = Enum.Material.SmoothPlastic
	torso.Anchored = true
	torso.CanCollide = true
	torso.Parent = tia

	local delantal = Instance.new("Part")
	delantal.Name = "Delantal"
	delantal.Size = Vector3.new(1.4, 1.6, 0.2)
	delantal.Position = pos + Vector3.new(0, -0.2, -0.5)
	delantal.Color = Color3.fromRGB(245, 245, 250)
	delantal.Material = Enum.Material.SmoothPlastic
	delantal.Anchored = true
	delantal.CanCollide = false
	delantal.Parent = tia

	local cabeza = Instance.new("Part")
	cabeza.Name = "Head"
	cabeza.Size = Vector3.new(1.1, 1.1, 1.1)
	cabeza.Position = pos + Vector3.new(0, 1.55, 0)
	cabeza.Color = Color3.fromRGB(240, 205, 175)
	cabeza.Material = Enum.Material.SmoothPlastic
	cabeza.Anchored = true
	cabeza.CanCollide = false
	cabeza.Parent = tia

	local bbg = Instance.new("BillboardGui")
	bbg.Name = "Rotulo"
	bbg.Size = UDim2.fromOffset(200, 48)
	bbg.StudsOffset = Vector3.new(0, 2.8, 0)
	bbg.AlwaysOnTop = true
	bbg.MaxDistance = 35
	bbg.Parent = cabeza

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.FredokaOne
	lbl.Text = "👩‍🍳 Tía Rosa\n(Asistente de Cocina)"
	lbl.TextColor3 = Color3.fromRGB(255, 235, 150)
	lbl.TextSize = 13
	lbl.Parent = bbg

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PromptTia"
	prompt.ObjectText = "Tía Rosa"
	prompt.ActionText = "Hablar con Tía Rosa"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = torso

	prompt.Triggered:Connect(function(player: Player)
		EventosRemotos.MostrarDialogoNPC:FireClient(player, {
			Nombre = "Tía Rosa",
			Titulo = "Asistente Clandestina",
			Icono = "👩‍🍳",
			Mensaje = "¡Hola mijo! Yo le ayudo meneando la paila para que el dulce no se pegue. ¡Cada 25 segundos le horneo 2 bombones de regalo mientras usted reparte por el barrio!",
		})
	end)

	-- Ciclo de horneado pasivo automático de la Tía Rosa (Mecánica Tycoon)
	task.spawn(function()
		while tia.Parent do
			task.wait(25)
			for _, player in ipairs(Players:GetPlayers()) do
				GestorDatos.AgregarDulce(player, "Dulce_Bombon", 2)
				lbl.Text = "✨ +2 Bombones Horneados ✨"
				lbl.TextColor3 = Color3.fromRGB(120, 255, 160)
				task.delay(3, function()
					if lbl then
						lbl.Text = "👩‍🍳 Tía Rosa\n(Asistente de Cocina)"
						lbl.TextColor3 = Color3.fromRGB(255, 235, 150)
					end
				end)
			end
		end
	end)
end

local paila = obtenerPaila()
if paila then
	configurarPromptCocina(paila)
	configurarTiaCocinera(paila)
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
				configurarTiaCocinera(pailaTardia)
				print("El Patrón del Dulce: Sistema de Cocina conectado (tardío)")
				break
			end
		end
	end)
end

task.spawn(configurarDonaMelcocha)
