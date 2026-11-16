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

		-- Aumentar calor policial (Estrellas de búsqueda)
		local estrellasActuales = GestorDatos.ObtenerEstrellas(player)
		if estrellasActuales < 5 then
			local nuevasEstrellas = GestorDatos.ModificarEstrellas(player, 1)
			local mensaje = string.format(
				"¡Alerta! Tienes %d estrella(s) de búsqueda. La patrulla dental vigila la zona.",
				nuevasEstrellas
			)
			EventosRemotos.AlertaPolicia:FireClient(player, mensaje, nuevasEstrellas)
		end

		-- Disparar efectos visuales y sonoros en 3D
		crearEfectoVenta(puntoPart, totalPesos)

		EventosRemotos.VentaCompletada:FireClient(player, {
			Tienda = tiendaInfo.Nombre,
			PesosGanados = totalPesos,
			DulcesVendidos = totalDulces,
			Detalles = detallesVenta,
		})

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
		print(
			string.format(
				"El Patrón del Dulce: %s no tiene dulces demandados por %s",
				player.Name,
				tiendaInfo.Nombre
			)
		)
	end
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
