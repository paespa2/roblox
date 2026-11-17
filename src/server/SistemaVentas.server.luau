local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GestorDatos = require(script.Parent.GestorDatos)
local Datos = require(ReplicatedStorage.Shared.Datos)
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)

local MAPA_PUNTOS_TIENDAS = {
	Punto_Venta_Colegio = "Tienda_ColegioRecreo",
	Punto_Venta_Tienda01 = "Tienda_EsquinaPaisa",
	Punto_Venta_Tienda02 = "Tienda_DonAbaco",
	Punto_Venta_Tienda03 = "Tienda_LaLadera",
	Punto_Venta_Tienda04 = "Tienda_ParqueCentral",
	Punto_Venta_Tienda05 = "Tienda_TerminalRuta",
	Punto_Venta_Tienda06 = "Tienda_TerminalRuta",
}

local function crearEfectoVenta(puntoPart: BasePart, montoPesos: number)
	-- Texto 3D flotante animado
	local bbg = Instance.new("BillboardGui")
	bbg.Name = "EfectoVentaFlotante"
	bbg.Size = UDim2.fromOffset(160, 45)
	bbg.StudsOffset = Vector3.new(0, 2, 0)
	bbg.AlwaysOnTop = true
	bbg.MaxDistance = 60
	bbg.Parent = puntoPart

	local texto = Instance.new("TextLabel")
	texto.Size = UDim2.fromScale(1, 1)
	texto.BackgroundTransparency = 1
	texto.Font = Enum.Font.FredokaOne
	texto.Text = string.format("+$%d 💰", montoPesos)
	texto.TextColor3 = Color3.fromRGB(255, 220, 60)
	texto.TextSize = 24
	texto.Parent = bbg

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(30, 20, 10)
	stroke.Thickness = 2
	stroke.Parent = texto

	-- Animación flotante hacia arriba
	local tweenOffset = TweenService:Create(
		bbg,
		TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ StudsOffset = Vector3.new(0, 6, 0) }
	)
	local tweenFade = TweenService:Create(
		texto,
		TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ TextTransparency = 1 }
	)
	local tweenStrokeFade = TweenService:Create(
		stroke,
		TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Transparency = 1 }
	)

	tweenOffset:Play()
	tweenFade:Play()
	tweenStrokeFade:Play()

	-- Sonido de moneda
	local sonido = Instance.new("Sound")
	sonido.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	sonido.Volume = 0.9
	sonido.Parent = puntoPart
	sonido:Play()

	task.delay(1.3, function()
		bbg:Destroy()
		sonido:Destroy()
	end)
end

local function procesarVenta(player: Player, idTienda: string, puntoPart: BasePart)
	local tiendaInfo = Datos.Tiendas[idTienda]
	if not tiendaInfo then
		return
	end

	local datosJugador = GestorDatos.ObtenerDatos(player)
	if not datosJugador then
		return
	end

	local totalPesos = 0
	local totalDulces = 0
	local detallesVenta = {}

	for _, idDulce in ipairs(tiendaInfo.DulcesComprados) do
		local cantidad = datosJugador.Inventario[idDulce] or 0
		if cantidad > 0 then
			local infoDulce = Datos.Dulces[idDulce]
			local valorBase = if infoDulce then infoDulce.ValorVenta else 1
			local ganancia = math.floor(cantidad * valorBase * tiendaInfo.Multiplicador)

			if GestorDatos.QuitarDulce(player, idDulce, cantidad) then
				totalPesos += ganancia
				totalDulces += cantidad
				table.insert(detallesVenta, string.format("%dx %s", cantidad, idDulce))
			end
		end
	end

	if totalPesos > 0 then
		GestorDatos.AgregarPesos(player, totalPesos)
		-- Incrementar Fama al completar entregas
		datosJugador.Fama += 1
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local famaVal = leaderstats:FindFirstChild("Fama") :: IntValue?
			if famaVal then
				famaVal.Value = datosJugador.Fama
			end
		end

		-- Aumentar calor policial (Estrellas de búsqueda según reglas de Santiago)
		local esColegio = (idTienda == "Tienda_ColegioRecreo")
		local calorAccion = if esColegio
			then Datos.Persecucion.CalorPorAccion.VentaColegio
			else Datos.Persecucion.CalorPorAccion.VentaComun
		local puntosCalor, nuevasEstrellas = GestorDatos.AgregarCalor(player, calorAccion)
		EventosRemotos.EstrellasActualizadas:FireClient(player, {
			Estrellas = nuevasEstrellas,
			Enfriando = false,
			ProgresoEnfriamiento = 0,
			PuntosCalor = puntosCalor,
		})

		-- Disparar efectos visuales y sonoros en 3D
		crearEfectoVenta(puntoPart, totalPesos)

		-- Afiliar / Conquistar la tienda para generar ingreso pasivo (Mecánica Tycoon)
		local primeraVez = GestorDatos.ConquistarTienda(player, idTienda)
		if primeraVez then
			EventosRemotos.MostrarDialogoNPC:FireClient(player, {
				Nombre = tiendaInfo.Nombre,
				Titulo = "¡Nueva Tienda Aliada!",
				Icono = "🤝",
				Mensaje = string.format(
					"¡Trato hecho, patrón! Desde hoy %s es tu punto de venta oficial. Te generaremos ganancias pasivas cada 30 segundos.",
					tiendaInfo.Nombre
				),
			})
		end

		EventosRemotos.VentaCompletada:FireClient(player, {
			Tienda = tiendaInfo.Nombre,
			PesosGanados = totalPesos,
			DulcesVendidos = totalDulces,
			Detalles = detallesVenta,
		})

		-- Desbloquear logro "Primer Bombón" en la primera venta del tutorial
		if (datosJugador.PasoTutorial or 0) <= 1 then
			if GestorDatos.EstablecerPasoTutorial then
				GestorDatos.EstablecerPasoTutorial(player, 2)
			end
			EventosRemotos.LogroDesbloqueado:FireClient(player, {
				Nombre = "Primer Bombón",
				Fama = 1,
			})
		end

		print(
			string.format(
				"El Patrón del Dulce: %s vendió %d dulces (%s) en %s por $%d pesos (+1 Fama)",
				player.Name,
				totalDulces,
				table.concat(detallesVenta, ", "),
				tiendaInfo.Nombre,
				totalPesos
			)
		)
	else
		local nombresDulces = {}
		for _, idD in ipairs(tiendaInfo.DulcesComprados) do
			local d = Datos.Dulces[idD]
			table.insert(nombresDulces, if d then d.Nombre else idD)
		end
		local listaStr = table.concat(nombresDulces, " o ")
		EventosRemotos.MostrarDialogoNPC:FireClient(player, {
			Nombre = tiendaInfo.Nombre,
			Titulo = "Tendero del Barrio",
			Icono = "🏪",
			Mensaje = string.format(
				"¡Buenas patrón! Ahorita en este local solo le estoy recibiendo %s. ¡Vuelva con la maleta llena desde la cocina!",
				listaStr
			),
		})
	end
end

local MAPA_NPCS_TIENDAS = {
	NPC_KioskoColegio = {
		IdTienda = "Tienda_ColegioRecreo",
		Nombre = "Lola Paleta",
		Titulo = "Kiosko del Recreo",
		Icono = "🍭",
	},
	NPC_Tendero01 = {
		IdTienda = "Tienda_EsquinaPaisa",
		Nombre = "Don Chucho",
		Titulo = "La Esquina Paisa",
		Icono = "🏪",
	},
	NPC_Tendero02 = {
		IdTienda = "Tienda_DonAbaco",
		Nombre = "Doña Rosa",
		Titulo = "Tienda La Panelita",
		Icono = "🏪",
	},
	Personaje_DonAbaco = {
		IdTienda = "Tienda_DonAbaco",
		Nombre = "Don Ábaco",
		Titulo = "Contador y Abarrotes",
		Icono = "🧮",
	},
	NPC_Tendero04 = {
		IdTienda = "Tienda_ParqueCentral",
		Nombre = "Don Carmelo",
		Titulo = "Dulces El Parque",
		Icono = "🏪",
	},
	NPC_Tendero05 = {
		IdTienda = "Tienda_TerminalRuta",
		Nombre = "Doña Tulia",
		Titulo = "La Última Curva",
		Icono = "🏪",
	},
	NPC_Tendero06 = {
		IdTienda = "Tienda_TerminalRuta",
		Nombre = "Don Pacho",
		Titulo = "El Mirador",
		Icono = "🏪",
	},
}

local function limpiarTarimasYAlinearSuelo(npcsFolder: Folder)
	-- 1. Eliminar tarimas / cajas residuales si existieran
	for _, child in ipairs(npcsFolder:GetChildren()) do
		if child.Name:sub(1, 7) == "Tarima_" then
			child:Destroy()
		end
	end

	-- 2. Asegurar que los pies de cada NPC toquen exactamente la superficie del suelo real
	local exclusions: { Instance } = { npcsFolder }
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	for _, child in ipairs(npcsFolder:GetChildren()) do
		if child:IsA("Model") then
			local hrp = child:FindFirstChild("HumanoidRootPart") :: BasePart? or child.PrimaryPart
			if hrp then
				local rayOrigin = Vector3.new(hrp.Position.X, hrp.Position.Y + 2.0, hrp.Position.Z)
				local hit = nil
				for _ = 1, 10 do
					params.FilterDescendantsInstances = exclusions
					hit = Workspace:Raycast(rayOrigin, Vector3.new(0, -35, 0), params)
					if not hit then
						break
					end
					local n = hit.Instance.Name:lower()
					if
						string.find(n, "techo")
						or string.find(n, "cubierta")
						or string.find(n, "teja")
						or string.find(n, "tarima")
						or not hit.Instance.CanCollide
					then
						table.insert(exclusions, hit.Instance)
					else
						break
					end
				end

				if hit then
					local piernas = child:FindFirstChild("PiernaDer") :: BasePart?
						or child:FindFirstChild("PiernaIzq") :: BasePart?
						or child:FindFirstChild("Piernas") :: BasePart?
					local offsetPie = 3.0
					if piernas then
						offsetPie = (hrp.Position.Y - piernas.Position.Y) + (piernas.Size.Y / 2)
					end

					local nuevaY = hit.Position.Y + offsetPie
					local deltaY = nuevaY - hrp.Position.Y
					if math.abs(deltaY) > 0.05 then
						if child.PrimaryPart then
							child:SetPrimaryPartCFrame(child.PrimaryPart.CFrame + Vector3.new(0, deltaY, 0))
						else
							for _, p in ipairs(child:GetDescendants()) do
								if p:IsA("BasePart") then
									p.Position += Vector3.new(0, deltaY, 0)
								end
							end
						end
					end
				end
			end
		end
	end
end

local function configurarNPCsInteractivos()
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

	-- Limpieza de tarimas y alineación precisa con la superficie del suelo
	limpiarTarimasYAlinearSuelo(npcsFolder)

	-- 1. Tenderos y Don Ábaco
	for npcName, info in pairs(MAPA_NPCS_TIENDAS) do
		local npcModel = npcsFolder:FindFirstChild(npcName)
		if npcModel and npcModel:IsA("Model") then
			local hrp = npcModel.PrimaryPart
				or npcModel:FindFirstChild("HumanoidRootPart")
				or npcModel:FindFirstChildWhichIsA("BasePart")
			if hrp then
				local prompt = hrp:FindFirstChildOfClass("ProximityPrompt")
				if not prompt then
					prompt = Instance.new("ProximityPrompt")
					prompt.Name = "PromptNPCVenta"
					prompt.ObjectText = string.format("%s (%s)", info.Nombre, info.Titulo)
					prompt.ActionText = "Hablar / Vender dulces"
					prompt.HoldDuration = 0.3
					prompt.MaxActivationDistance = 14
					prompt.RequiresLineOfSight = false
					prompt.Parent = hrp
				end

				prompt.Triggered:Connect(function(player: Player)
					procesarVenta(player, info.IdTienda, hrp)
				end)
			end
		end
	end

	-- 2. Agente Dental (Policía con advertencia verbal)
	local agente = npcsFolder:FindFirstChild("Personaje_AgenteDental")
	if agente and agente:IsA("Model") then
		local hrp = agente.PrimaryPart
			or agente:FindFirstChild("HumanoidRootPart")
			or agente:FindFirstChildWhichIsA("BasePart")
		if hrp then
			local prompt = hrp:FindFirstChildOfClass("ProximityPrompt")
			if not prompt then
				prompt = Instance.new("ProximityPrompt")
				prompt.Name = "PromptAgenteDental"
				prompt.ObjectText = "Agente Dental (Policía)"
				prompt.ActionText = "Escuchar Advertencia"
				prompt.HoldDuration = 0.3
				prompt.MaxActivationDistance = 14
				prompt.RequiresLineOfSight = false
				prompt.Parent = hrp
			end

			local advertencias = {
				"¡Atención ciudadano! La Ordenanza Municipal N° 404 prohíbe terminantemente el porte y distribución de azúcares refinados sin aval del odontólogo. ¡Circule inmediatamente!",
				"¡Le estamos siguiendo la pista a los cargamentos de melcocha que bajan de la ladera! La caries no pasará en esta ciudad.",
				"Si lo vemos pedaleando con más de 20 dulces, sonará la sirena y su carga quedará bajo custodia dental. ¡Advertido queda!",
			}
			local idx = 1
			prompt.Triggered:Connect(function(player: Player)
				local msg = advertencias[idx]
				idx = (idx % #advertencias) + 1
				EventosRemotos.MostrarDialogoNPC:FireClient(player, {
					Nombre = "Agente Dental",
					Titulo = "Policía Municipal",
					Icono = "👮‍♂️",
					Mensaje = msg,
				})
			end)
		end
	end

	print("El Patrón del Dulce: NPCs interactivos configurados con diálogos y ventas")
end

local function configurarPuntosDeVenta()
	local puntosFolder = Workspace:WaitForChild("Puntos", 10)
	if not puntosFolder then
		return
	end

	local ventasFolder = puntosFolder:WaitForChild("Ventas", 10)
	if not ventasFolder then
		return
	end

	for _, puntoPart in ipairs(ventasFolder:GetChildren()) do
		if puntoPart:IsA("BasePart") then
			local idTienda = MAPA_PUNTOS_TIENDAS[puntoPart.Name]
			if idTienda then
				local tiendaInfo = Datos.Tiendas[idTienda]
				local nombreTienda = if tiendaInfo then tiendaInfo.Nombre else puntoPart.Name

				local prompt = puntoPart:FindFirstChildOfClass("ProximityPrompt")
				if not prompt then
					prompt = Instance.new("ProximityPrompt")
					prompt.Name = "PromptVenta"
					prompt.ObjectText = nombreTienda
					prompt.ActionText = "Vender dulces"
					prompt.HoldDuration = 0.4
					prompt.MaxActivationDistance = 14
					prompt.RequiresLineOfSight = false
					prompt.Parent = puntoPart
				end

				prompt.Triggered:Connect(function(player: Player)
					procesarVenta(player, idTienda, puntoPart)
				end)
			end
		end
	end

	print("El Patrón del Dulce: 7 Puntos de Venta conectados con efectos visuales")
end

task.spawn(configurarPuntosDeVenta)
task.spawn(configurarNPCsInteractivos)

-- ====================================================================
-- CICLO TYCOON: INGRESO PASIVO DE TIENDAS AFILIADAS (CADA 30 SEGUNDOS)
-- ====================================================================
task.spawn(function()
	local Players = game:GetService("Players")
	while true do
		task.wait(30)
		for _, player in ipairs(Players:GetPlayers()) do
			local tiendas = GestorDatos.ObtenerTiendasConquistadas(player)
			local conteo = 0
			for _ in pairs(tiendas) do
				conteo += 1
			end

			if conteo > 0 then
				local gananciaPasiva = conteo * 3 -- $3 pesos por cada tienda aliada
				GestorDatos.AgregarPesos(player, gananciaPasiva)

				EventosRemotos.MostrarDialogoNPC:FireClient(player, {
					Nombre = "Red de Tiendas del Barrio",
					Titulo = "💰 Recaudo Pasivo Tycoon",
					Icono = "🏪",
					Mensaje = string.format(
						"¡Ganancias recibidas! Tus %d tiendas aliadas te generaron +$%d Pesos Dulces.",
						conteo,
						gananciaPasiva
					),
				})
			end
		end
	end
end)
