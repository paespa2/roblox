--!strict
--[[
	SistemaHordaCliente.client.luau
	Inicializa los controladores de cliente del sistema de Horda de Zombis y Dante.
]]

local HordaFolder = script.Parent:WaitForChild("Horda")

local DanteController = require(HordaFolder:WaitForChild("DanteController") :: ModuleScript)
local HordeUI = require(HordaFolder:WaitForChild("HordeUI") :: ModuleScript)
local ZombieAnimationController =
	require(HordaFolder:WaitForChild("ZombieAnimationController") :: ModuleScript)

task.spawn(DanteController.Iniciar)
task.spawn(HordeUI.Iniciar)
task.spawn(ZombieAnimationController.Iniciar)

print("El Patrón del Dulce [Cliente]: Sistema de Horda de Zombis y Dante inicializado")
