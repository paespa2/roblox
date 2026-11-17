local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)

local enCooldown = false

local function reproducirSonidoCampana()
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	sound.Volume = 0.7
	sound.Parent = SoundService
	pcall(function()
		sound:Play()
	end)
	task.delay(1.5, function()
		sound:Destroy()
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.V then
		if enCooldown then
			return
		end
		enCooldown = true

		local exito, mensaje = EventosRemotos.SolicitarVehiculo:InvokeServer()
		if exito then
			reproducirSonidoCampana()
		else
			warn(mensaje)
		end

		task.wait(0.8)
		enCooldown = false
	end
end)
