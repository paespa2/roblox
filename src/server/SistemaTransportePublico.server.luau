local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GestorDatos = require(script.Parent.GestorDatos)
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)

local function soldar(p0: BasePart, p1: BasePart)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.Parent = p0
end

-- ====================================================================
-- DEFINICIÓN DE LAS 4 PARADAS OFICIALES DEL SERVICIO DE TRANSPORTE
-- ====================================================================
type ParadaInfo = {
	Id: number,
	Nombre: string,
	Subtitulo: string,
	PosicionBahia: Vector3,
	RotacionY: number,
}

local PARADAS: { ParadaInfo } = {
	{
		Id = 1,
		Nombre = "Colegio San Jerónimo",
		Subtitulo = "Salida Escolar • Prohibido Dulces",
		PosicionBahia = Vector3.new(12, 60, -35),
		RotacionY = 180,
	},
	{
		Id = 2,
		Nombre = "Plaza Central & Tiendas",
		Subtitulo = "La Esquina Paisa • Almacén Don Chucho",
		PosicionBahia = Vector3.new(12, 60, 60),
		RotacionY = 180,
	},
	{
		Id = 3,
		Nombre = "Hospital San Rafael",
		Subtitulo = "Urgencias 24H • Puesto de Salud",
		PosicionBahia = Vector3.new(16, 83.2, 215),
		RotacionY = 180,
	},
	{
		Id = 4,
		Nombre = "Mirador del Valle & Café",
		Subtitulo = "Los Almendros • Cima de Ladera",
		PosicionBahia = Vector3.new(12, 95.5, 380),
		RotacionY = 180,
	},
}

-- Puntos intermedios de la carretera para tránsito fluido sin atajos
local WAYPOINTS_CARRETERA: { Vector3 } = {
	Vector3.new(4, 60, -35),
	Vector3.new(4, 60, 15),
	Vector3.new(4, 60, 60),
	Vector3.new(4, 69, 120),
	Vector3.new(4, 75, 165),
	Vector3.new(4, 82, 215),
	Vector3.new(4, 82.5, 260),
	Vector3.new(4, 90, 320),
	Vector3.new(4, 96.5, 380),
}

-- ====================================================================
-- 1. CONSTRUCCIÓN DE CASETAS Y POSTES DE PARADA
-- ====================================================================
local function construirCasetaParada(info: ParadaInfo, parent: Instance)
	local modelo = Instance.new("Model")
	modelo.Name = "ParadaTransporte_" .. info.Id

	local base = Instance.new("Part")
	base.Name = "PlataformaEspera"
	base.Size = Vector3.new(6.0, 0.4, 4.0)
	base.Position = info.PosicionBahia + Vector3.new(2.5, 0.2, 0)
	base.Color = Color3.fromRGB(180, 185, 190)
	base.Material = Enum.Material.Concrete
	base.Anchored = true
	base.CanCollide = true
	base.Parent = modelo
	modelo.PrimaryPart = base

	-- Tejadito protector de lluvia
	local poste = Instance.new("Part")
	poste.Name = "PosteTejadito"
	poste.Size = Vector3.new(0.4, 6.0, 0.4)
	poste.Position = base.Position + Vector3.new(2.4, 3.0, 0)
	poste.Color = Color3.fromRGB(40, 50, 65)
	poste.Material = Enum.Material.Metal
	poste.Anchored = true
	poste.CanCollide = true
	poste.Parent = modelo

	local techo = Instance.new("Part")
	techo.Name = "TechoCaseta"
	techo.Size = Vector3.new(6.4, 0.4, 4.4)
	techo.Position = base.Position + Vector3.new(0, 5.8, 0)
	techo.Color = Color3.fromRGB(45, 90, 160)
	techo.Material = Enum.Material.Metal
	techo.Anchored = true
	techo.CanCollide = false
	techo.Parent = modelo

	-- Banca de espera para pasajeros
	local banca = Instance.new("Part")
	banca.Name = "BancaEspera"
	banca.Size = Vector3.new(4.5, 0.4, 1.4)
	banca.Position = base.Position + Vector3.new(0, 1.2, 0.8)
	banca.Color = Color3.fromRGB(120, 75, 40)
	banca.Material = Enum.Material.WoodPlanks
	banca.Anchored = true
	banca.CanCollide = true
	banca.Parent = modelo

	-- Rótulo iluminado de la parada
	local posteRotulo = Instance.new("Part")
	posteRotulo.Name = "PosteRotulo"
	posteRotulo.Size = Vector3.new(0.3, 7.5, 0.3)
	posteRotulo.Position = base.Position + Vector3.new(-2.8, 3.75, -1.8)
	posteRotulo.Color = Color3.fromRGB(50, 50, 55)
	posteRotulo.Material = Enum.Material.Metal
	posteRotulo.Anchored = true
	posteRotulo.CanCollide = false
	posteRotulo.Parent = modelo

	local cartel = Instance.new("Part")
	cartel.Name = "CartelParada"
	cartel.Size = Vector3.new(2.8, 2.0, 0.2)
	cartel.Position = posteRotulo.Position + Vector3.new(0, 3.0, 0)
	cartel.Color = Color3.fromRGB(25, 30, 42)
	cartel.Material = Enum.Material.SmoothPlastic
	cartel.Anchored = true
	cartel.CanCollide = false
	cartel.Parent = modelo

	local bbg = Instance.new("BillboardGui")
	bbg.Name = "InfoParada"
	bbg.Size = UDim2.fromOffset(240, 56)
	bbg.StudsOffset = Vector3.new(0, 1.6, 0)
	bbg.AlwaysOnTop = true
	bbg.MaxDistance = 55
	bbg.Parent = cartel

	local fondo = Instance.new("Frame")
	fondo.Size = UDim2.fromScale(1, 1)
	fondo.BackgroundColor3 = Color3.fromRGB(20, 30, 45)
	fondo.BackgroundTransparency = 0.15
	fondo.Parent = bbg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = fondo

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 205, 50)
	stroke.Thickness = 1.5
	stroke.Parent = fondo

	local lblT = Instance.new("TextLabel")
	lblT.Size = UDim2.fromScale(1, 0.55)
	lblT.BackgroundTransparency = 1
	lblT.Font = Enum.Font.FredokaOne
	lblT.Text = string.format("🚏 PARADA %d: %s", info.Id, info.Nombre:upper())
	lblT.TextColor3 = Color3.fromRGB(255, 230, 120)
	lblT.TextSize = 13
	lblT.Parent = fondo

	local lblS = Instance.new("TextLabel")
	lblS.Size = UDim2.fromScale(1, 0.45)
	lblS.Position = UDim2.fromScale(0, 0.55)
	lblS.BackgroundTransparency = 1
	lblS.Font = Enum.Font.FredokaOne
	lblS.Text = info.Subtitulo
	lblS.TextColor3 = Color3.fromRGB(200, 225, 255)
	lblS.TextSize = 10
	lblS.Parent = fondo

	modelo.Parent = parent
	return modelo
end

-- ====================================================================
-- 2. EL TAXI DE DON LIBARDO CON CHÓFER NPC Y ASIENTOS DE PASAJEROS
-- ====================================================================
local function crearTaxiDeDonLibardo(parent: Instance): Model
	local taxi = Instance.new("Model")
	taxi.Name = "Transporte_TaxiDonLibardo"

	local posInicial = PARADAS[2].PosicionBahia + Vector3.new(0, 1.8, 0)

	-- Chasis principal (Amarillo taxi con faldones)
	local chasis = Instance.new("Part")
	chasis.Name = "Chasis"
	chasis.Size = Vector3.new(6.5, 2.6, 13.0)
	chasis.Position = posInicial
	chasis.Color = Color3.fromRGB(255, 210, 20)
	chasis.Material = Enum.Material.Metal
	chasis.Anchored = true
	chasis.CanCollide = true
	chasis.Parent = taxi
	taxi.PrimaryPart = chasis

	-- Franja ajedrezada lateral negra/blanca típica
	local franjaCheck = Instance.new("Part")
	franjaCheck.Name = "FranjaAjedrezada"
	franjaCheck.Size = Vector3.new(6.6, 0.4, 13.0)
	franjaCheck.Position = chasis.Position + Vector3.new(0, 0.3, 0)
	franjaCheck.Color = Color3.fromRGB(25, 25, 30)
	franjaCheck.Material = Enum.Material.SmoothPlastic
	franjaCheck.Anchored = true
	franjaCheck.CanCollide = false
	franjaCheck.Parent = taxi
	soldar(chasis, franjaCheck)

	-- Cabina con parabrisas
	local cabina = Instance.new("Part")
	cabina.Name = "Cabina"
	cabina.Size = Vector3.new(5.8, 2.2, 7.0)
	cabina.Position = chasis.Position + Vector3.new(0, 2.2, 0.5)
	cabina.Color = Color3.fromRGB(45, 55, 68)
	cabina.Material = Enum.Material.Glass
	cabina.Transparency = 0.4
	cabina.Anchored = true
	cabina.CanCollide = true
	cabina.Parent = taxi
	soldar(chasis, cabina)

	-- Letrero TAXI iluminado en el techo
	local letreroTaxi = Instance.new("Part")
	letreroTaxi.Name = "LetreroTecho"
	letreroTaxi.Size = Vector3.new(2.4, 0.7, 1.2)
	letreroTaxi.Position = cabina.Position + Vector3.new(0, 1.45, 0)
	letreroTaxi.Color = Color3.fromRGB(255, 245, 220)
	letreroTaxi.Material = Enum.Material.Neon
	letreroTaxi.Anchored = true
	letreroTaxi.CanCollide = false
	letreroTaxi.Parent = taxi
	soldar(chasis, letreroTaxi)

	local bbgTaxi = Instance.new("BillboardGui")
	bbgTaxi.Size = UDim2.fromOffset(80, 28)
	bbgTaxi.AlwaysOnTop = true
	bbgTaxi.MaxDistance = 50
	bbgTaxi.Parent = letreroTaxi

	local lblT = Instance.new("TextLabel")
	lblT.Size = UDim2.fromScale(1, 1)
	lblT.BackgroundTransparency = 1
	lblT.Font = Enum.Font.FredokaOne
	lblT.Text = "TAXI LIBARDO"
	lblT.TextColor3 = Color3.fromRGB(20, 20, 25)
	lblT.TextSize = 13
	lblT.Parent = bbgTaxi

	-- Farolas frontales luminosas
	local farolIzq = Instance.new("Part")
	farolIzq.Name = "FarolIzq"
	farolIzq.Size = Vector3.new(0.8, 0.6, 0.3)
	farolIzq.Position = chasis.Position + Vector3.new(-2.2, 0.2, -6.5)
	farolIzq.Color = Color3.fromRGB(255, 255, 210)
	farolIzq.Material = Enum.Material.Neon
	farolIzq.Anchored = true
	farolIzq.CanCollide = false
	farolIzq.Parent = taxi
	soldar(chasis, farolIzq)

	local luzFarol = Instance.new("SpotLight")
	luzFarol.Name = "LuzDelantera"
	luzFarol.Color = Color3.fromRGB(255, 250, 200)
	luzFarol.Range = 40
	luzFarol.Brightness = 3.0
	luzFarol.Angle = 65
	luzFarol.Face = Enum.NormalId.Front
	luzFarol.Parent = farolIzq

	local farolDer = Instance.new("Part")
	farolDer.Name = "FarolDer"
	farolDer.Size = Vector3.new(0.8, 0.6, 0.3)
	farolDer.Position = chasis.Position + Vector3.new(2.2, 0.2, -6.5)
	farolDer.Color = Color3.fromRGB(255, 255, 210)
	farolDer.Material = Enum.Material.Neon
	farolDer.Anchored = true
	farolDer.CanCollide = false
	farolDer.Parent = taxi
	soldar(chasis, farolDer)

	-- Ruedas
	for _, x in ipairs({ -3.3, 3.3 }) do
		for _, z in ipairs({ -4.2, 4.2 }) do
			local rueda = Instance.new("Part")
			rueda.Name = "RuedaTaxi"
			rueda.Shape = Enum.PartType.Cylinder
			rueda.Size = Vector3.new(0.9, 2.2, 2.2)
			rueda.CFrame = CFrame.new(chasis.Position + Vector3.new(x, -0.8, z))
				* CFrame.Angles(0, 0, math.rad(90))
			rueda.Color = Color3.fromRGB(30, 30, 35)
			rueda.Material = Enum.Material.Rubber
			rueda.Anchored = true
			rueda.CanCollide = false
			rueda.Parent = taxi
			soldar(chasis, rueda)
		end
	end

	-- Asiento del Pasajero (Seat interactivo)
	local asientoPasajero = Instance.new("Seat")
	asientoPasajero.Name = "AsientoPasajero"
	asientoPasajero.Size = Vector3.new(2.0, 0.6, 2.0)
	asientoPasajero.Position = chasis.Position + Vector3.new(1.4, 0.6, 0.6)
	asientoPasajero.Color = Color3.fromRGB(50, 45, 45)
	asientoPasajero.Anchored = true
	asientoPasajero.CanCollide = true
	asientoPasajero.Parent = taxi
	soldar(chasis, asientoPasajero)

	-- Chófer Don Libardo al volante
	local donLibardo = Instance.new("Model")
	donLibardo.Name = "NPC_DonLibardo"
	donLibardo.Parent = taxi

	local choferTorso = Instance.new("Part")
	choferTorso.Name = "TorsoChofer"
	choferTorso.Size = Vector3.new(1.6, 1.6, 0.8)
	choferTorso.Position = chasis.Position + Vector3.new(-1.4, 1.5, 0.6)
	choferTorso.Color = Color3.fromRGB(45, 95, 170) -- Camisa azul chófer
	choferTorso.Material = Enum.Material.SmoothPlastic
	choferTorso.Anchored = true
	choferTorso.CanCollide = false
	choferTorso.Parent = donLibardo
	soldar(chasis, choferTorso)

	local choferHead = Instance.new("Part")
	choferHead.Name = "Head"
	choferHead.Size = Vector3.new(1.0, 1.0, 1.0)
	choferHead.Position = choferTorso.Position + Vector3.new(0, 1.3, 0)
	choferHead.Color = Color3.fromRGB(230, 185, 150)
	choferHead.Material = Enum.Material.SmoothPlastic
	choferHead.Anchored = true
	choferHead.CanCollide = false
	choferHead.Parent = donLibardo
	soldar(chasis, choferHead)

	local gorraChofer = Instance.new("Part")
	gorraChofer.Name = "GorraChofer"
	gorraChofer.Size = Vector3.new(1.2, 0.35, 1.3)
	gorraChofer.Position = choferHead.Position + Vector3.new(0, 0.55, -0.1)
	gorraChofer.Color = Color3.fromRGB(25, 30, 42)
	gorraChofer.Material = Enum.Material.SmoothPlastic
	gorraChofer.Anchored = true
	gorraChofer.CanCollide = false
	gorraChofer.Parent = donLibardo
	soldar(chasis, gorraChofer)

	-- Volante de conducción
	local volante = Instance.new("Part")
	volante.Name = "Volante"
	volante.Size = Vector3.new(0.9, 0.9, 0.2)
	volante.Position = choferTorso.Position + Vector3.new(0, 0.3, -1.0)
	volante.Color = Color3.fromRGB(20, 20, 25)
	volante.Material = Enum.Material.Metal
	volante.Anchored = true
	volante.CanCollide = false
	volante.Parent = donLibardo
	soldar(chasis, volante)

	-- Rótulo y Prompt de servicio de transporte
	local bbgChofer = Instance.new("BillboardGui")
	bbgChofer.Name = "RotuloLibardo"
	bbgChofer.Size = UDim2.fromOffset(240, 52)
	bbgChofer.StudsOffset = Vector3.new(0, 2.8, 0)
	bbgChofer.AlwaysOnTop = true
	bbgChofer.MaxDistance = 45
	bbgChofer.Parent = choferHead

	local lblChofer = Instance.new("TextLabel")
	lblChofer.Size = UDim2.fromScale(1, 1)
	lblChofer.BackgroundColor3 = Color3.fromRGB(25, 28, 38)
	lblChofer.BackgroundTransparency = 0.2
	lblChofer.Font = Enum.Font.FredokaOne
	lblChofer.Text = "🚕 Don Libardo (El Taxista)\nServicio de Transporte Municipal"
	lblChofer.TextColor3 = Color3.fromRGB(255, 220, 80)
	lblChofer.TextSize = 12
	lblChofer.Parent = bbgChofer

	local cornerCh = Instance.new("UICorner")
	cornerCh.CornerRadius = UDim.new(0, 8)
	cornerCh.Parent = lblChofer

	local strokeCh = Instance.new("UIStroke")
	strokeCh.Color = Color3.fromRGB(240, 180, 40)
	strokeCh.Thickness = 1.5
	strokeCh.Parent = lblChofer

	-- ProximityPrompt en la puerta del taxi para viajar
	local promptTaxi = Instance.new("ProximityPrompt")
	promptTaxi.Name = "PromptTransporte"
	promptTaxi.ObjectText = "Taxi de Don Libardo"
	promptTaxi.ActionText = "Pedir Carrera / Subir ($5 Pesos)"
	promptTaxi.HoldDuration = 0.3
	promptTaxi.MaxActivationDistance = 14
	promptTaxi.RequiresLineOfSight = false
	promptTaxi.Parent = chasis

	taxi.Parent = parent
	return taxi
end

-- ====================================================================
-- 3. CONTROLADOR Y NAVEGACIÓN EN TIEMPO REAL DEL SERVICIO
-- ====================================================================
local function iniciarServicioTransporte(taxi: Model)
	local chasis = taxi.PrimaryPart or taxi:FindFirstChild("Chasis") :: BasePart?
	if not chasis then
		return
	end

	local promptTaxi = chasis:FindFirstChild("PromptTransporte") :: ProximityPrompt?
	local paradaActualIdx = 2 -- Inicia en la Plaza Central
	local enViajeActivo = false

	local function sonarBocina()
		local pito = Instance.new("Sound")
		pito.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		pito.Volume = 0.8
		pito.Parent = chasis
		pito:Play()
		task.delay(1.5, function()
			pito:Destroy()
		end)
	end

	-- Función que desplaza físicamente el taxi de un punto a otro
	local function moverTaxiHacia(destino: Vector3, velocidad: number)
		local dir = (destino - chasis.Position)
		local dist = dir.Magnitude
		if dist <= 1.5 then
			return
		end

		local dur = math.clamp(dist / velocidad, 0.8, 6.0)
		local dirNorm = (dir * Vector3.new(1, 0, 1)).Unit
		local cfMeta = CFrame.lookAt(destino, destino + dirNorm)

		local tween = TweenService:Create(
			chasis,
			TweenInfo.new(dur, Enum.EasingStyle.Linear),
			{ CFrame = cfMeta }
		)
		tween:Play()

		-- Actualizar todas las piezas ancladas soldadas al taxi
		local t0 = os.clock()
		while os.clock() - t0 < dur do
			local cfIntermedio = chasis.CFrame
			for _, part in ipairs(taxi:GetDescendants()) do
				if part:IsA("BasePart") and part ~= chasis and part.Anchored then
					local weld = part:FindFirstChildOfClass("WeldConstraint")
					if weld and weld.Part0 == chasis then
						-- Conserva el offset relativo
						local offset = part:GetAttribute("OffsetRelativo")
						if not offset then
							offset = chasis.CFrame:ToObjectSpace(part.CFrame)
							part:SetAttribute("OffsetRelativo", offset)
						end
						part.CFrame = cfIntermedio * offset
					end
				end
			end
			task.wait(0.05)
		end
	end

	-- Conduce por los waypoints hasta la parada deseada
	local function viajarAParada(paradaDestinoIdx: number)
		enViajeActivo = true
		sonarBocina()

		-- Determinar si sube o baja por la carretera
		local destinoBahia = PARADAS[paradaDestinoIdx].PosicionBahia
		local paso = if paradaDestinoIdx >= paradaActualIdx then 1 else -1

		-- 1. Incorporarse a la calzada
		local puntoEntrada = Vector3.new(4, chasis.Position.Y, chasis.Position.Z)
		moverTaxiHacia(puntoEntrada, 12)

		-- 2. Recorrer waypoints intermedios
		for i = 1, #WAYPOINTS_CARRETERA do
			local wp = WAYPOINTS_CARRETERA[i]
			local enRango = false
			if paso > 0 then
				enRango = (wp.Z >= chasis.Position.Z - 5 and wp.Z <= destinoBahia.Z + 5)
			else
				enRango = (wp.Z <= chasis.Position.Z + 5 and wp.Z >= destinoBahia.Z - 5)
			end

			if enRango then
				moverTaxiHacia(wp, 18)
			end
		end

		-- 3. Entrar a la bahía de la parada de destino
		moverTaxiHacia(destinoBahia, 10)
		paradaActualIdx = paradaDestinoIdx

		sonarBocina()
		enViajeActivo = false
	end

	-- Interacción del jugador para pedir carrera o transporte
	if promptTaxi then
		promptTaxi.Triggered:Connect(function(player: Player)
			if enViajeActivo then
				EventosRemotos.MostrarDialogoNPC:FireClient(player, {
					Nombre = "Don Libardo",
					Titulo = "Taxi en Marcha",
					Icono = "🚕",
					Mensaje = "¡Agárrese que ya vamos en camino a la siguiente estación!",
				})
				return
			end

			local datos = GestorDatos.ObtenerDatos(player)
			local pesos = if datos then datos.PesosDulces else 0

			-- Calcular siguiente parada en la ruta
			local siguienteIdx = (paradaActualIdx % #PARADAS) + 1
			local proxParada = PARADAS[siguienteIdx]

			if pesos >= 5 then
				GestorDatos.GastarPesos(player, 5)
			end

			-- Montar al jugador en el asiento del copiloto
			local char = player.Character
			if char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				local asientoPasajero = taxi:FindFirstChild("AsientoPasajero") :: Seat?
				if hum and asientoPasajero then
					asientoPasajero:Sit(hum)
				end
			end

			EventosRemotos.MostrarDialogoNPC:FireClient(player, {
				Nombre = "Don Libardo",
				Titulo = "Taxi Municipal • En Marcha",
				Icono = "🚕",
				Mensaje = string.format(
					"¡Súbase compadre, agárrese bien que arrancamos! Próxima parada: %s (%s). ¡Ojo con las curvas!",
					proxParada.Nombre,
					proxParada.Subtitulo
				),
			})

			task.delay(1.0, function()
				viajarAParada(siguienteIdx)

				EventosRemotos.MostrarDialogoNPC:FireClient(player, {
					Nombre = "Don Libardo",
					Titulo = "¡Llegamos a su destino!",
					Icono = "🚏",
					Mensaje = string.format(
						"¡Llegamos a %s! Que le rinda el negocio y cuídese de la policía dental.",
						proxParada.Nombre
					),
				})
			end)
		end)
	end

	-- Recorrido circular autónomo continuo cuando ningún jugador está en express
	task.spawn(function()
		while taxi.Parent do
			task.wait(8.0) -- Espera 8 segundos en cada parada para permitir subida/bajada
			if not enViajeActivo then
				local proxIdx = (paradaActualIdx % #PARADAS) + 1
				viajarAParada(proxIdx)
			end
		end
	end)
end

-- ====================================================================
-- INICIALIZADOR GENERAL DEL SISTEMA DE TRANSPORTE
-- ====================================================================
local function inicializarTransportePublico()
	local mapa = Workspace:WaitForChild("Mapa", 10)
	if not mapa then
		return
	end
	local decoracion = mapa:WaitForChild("Decoracion", 10)
	if not decoracion then
		decoracion = Instance.new("Folder")
		decoracion.Name = "Decoracion"
		decoracion.Parent = mapa
	end

	local carpetaTransporte = Instance.new("Folder")
	carpetaTransporte.Name = "SistemaTransportePublico"
	carpetaTransporte.Parent = decoracion

	-- Construir las 4 paradas
	for _, parada in ipairs(PARADAS) do
		construirCasetaParada(parada, carpetaTransporte)
	end

	-- Crear el Taxi con conductor
	local taxi = crearTaxiDeDonLibardo(carpetaTransporte)
	iniciarServicioTransporte(taxi)

	print(
		"El Patrón del Dulce: Sistema de Transporte Público (Taxi Don Libardo y 4 Paradas) Inicializado con Éxito"
	)
end

task.spawn(inicializarTransportePublico)
