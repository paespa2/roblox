--!strict
--[[
	ControlVehiculoTeclado.client.luau
	Punto de entrada cliente para el sistema de control y físicas de vehículos.
	Delega la lógica al controlador modular VehiculoController.
	
	El Patrón del Dulce
]]

local VehiculoController = require(script.Parent.Vehiculos.VehiculoController)

VehiculoController.Iniciar()
