local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EventosRemotos = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Eventos"):WaitForChild("EventosRemotos")
)

EventosRemotos.DatosActualizados.OnClientEvent:Connect(function(datos)
	print(
		string.format(
			"El Patrón del Dulce [Cliente]: Datos sincronizados -> Pesos: %d | Fama: %d",
			datos.PesosDulces,
			datos.Fama
		)
	)
end)

EventosRemotos.CocinaActualizada.OnClientEvent:Connect(function(info)
	if info.Recogido then
		print(
			string.format(
				"🍬 [Cocina]: ¡Recogiste %d unidades de %s!",
				info.Cantidad,
				info.IdDulce
			)
		)
	elseif info.Listo then
		print(
			string.format(
				"🔔 [Cocina]: ¡Tu tanda de %s ya está lista para recoger!",
				info.IdDulce
			)
		)
	else
		print(
			string.format(
				"⏳ [Cocina]: Cocinando %s (tardará %d segundos)...",
				info.IdDulce,
				info.Duracion
			)
		)
	end
end)

EventosRemotos.VentaCompletada.OnClientEvent:Connect(function(resumen)
	print(
		string.format(
			"💰 [Venta]: ¡Vendiste %d dulces en %s y ganaste $%d pesos dulces!",
			resumen.DulcesVendidos,
			resumen.Tienda,
			resumen.PesosGanados
		)
	)
end)
