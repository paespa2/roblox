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
