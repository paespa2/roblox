local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

local function procesarVenta(player: Player, idTienda: string)
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
					prompt.HoldDuration = 0.5
					prompt.MaxActivationDistance = 12
					prompt.RequiresLineOfSight = false
					prompt.Parent = puntoPart
				end

				prompt.Triggered:Connect(function(player: Player)
					procesarVenta(player, idTienda)
				end)
			end
		end
	end

	print("El Patrón del Dulce: 7 Puntos de Venta conectados a las tiendas")
end

task.spawn(configurarPuntosDeVenta)
