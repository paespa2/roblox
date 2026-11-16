local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local mouse = localPlayer:GetMouse()
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)

local enCooldown = false

local function conectarTool(tool: Tool)
	if tool.Name ~= "Cauchera de Gomitas" then
		return
	end

	tool.Activated:Connect(function()
		if enCooldown then
			return
		end
		enCooldown = true

		local character = localPlayer.Character
		if character and character:FindFirstChild("Head") then
			local origen = character.Head.Position
			local destino = mouse.Hit.Position
			local direccion = (destino - origen).Unit

			local exito, mensaje =
				EventosRemotos.DispararArma:InvokeServer("Arma_CaucheraGomitas", direccion)
			if not exito then
				warn("Cauchera: " .. tostring(mensaje))
			end
		end

		task.wait(0.6)
		enCooldown = false
	end)
end

local function alAgregarPersonaje(character: Model)
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			conectarTool(child)
		end
	end)
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then
			conectarTool(child)
		end
	end
end

if localPlayer.Character then
	alAgregarPersonaje(localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(alAgregarPersonaje)
