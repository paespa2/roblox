--!strict
--[[
	SistemaVehiculos.server.luau
	Punto de entrada autoritativo para el sistema de vehículos.
	Delega toda la lógica de gestión, físicas y persistencia a VehiculosService.
	
	El Patrón del Dulce
]]

local VehiculosService = require(script.Parent.Vehiculos.VehiculosService)

VehiculosService.Iniciar()

print("El Patrón del Dulce: Sistema de Vehículos y Conducción Calibrado")
