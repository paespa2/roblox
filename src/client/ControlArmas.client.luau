local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local mouse = localPlayer:GetMouse()
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)

local enCooldown = false

local function conectarTool(tool: Tool)
	if tool:GetAttribute("_ControlArmasConectado") then
		return
	end
	local idArma = tool:GetAttribute("IdArma")
	if not idArma then
		if tool.Name == "Cauchera de Gomitas" then
			idArma = "Arma_CaucheraGomitas"
		elseif tool.Name == "Pistola de Crema" then
			idArma = "Arma_PistolaCrema"
		else
			return
		end
	end
	tool:SetAttribute("_ControlArmasConectado", true)

	tool.Activated:Connect(function()
		if enCooldown then
			return
		end
		enCooldown = true

		local cadencia = tool:GetAttribute("CadenciaSegundos") or 0.8
		local character = localPlayer.Character
		local head = character and character:FindFirstChild("Head")
		if character and head and head:IsA("BasePart") then
			local origen = head.Position
			local destino = mouse.Hit.Position
			local delta = destino - origen
			local direccion = if delta.Magnitude > 0.001 then delta.Unit else head.CFrame.LookVector

			local exito, mensaje = EventosRemotos.DispararArma:InvokeServer(idArma, direccion)
			if not exito then
				warn("Arma (" .. tostring(idArma) .. "): " .. tostring(mensaje))
			end
		end

		task.wait(cadencia)
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
