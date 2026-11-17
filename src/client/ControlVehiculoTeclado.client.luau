local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)
local Datos = require(ReplicatedStorage.Shared.Datos)

local enCooldown = false

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true

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

-- 1. Invocación y Desmontaje con tecla V
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

-- 2. Detección y calibración de superficies en tiempo real (Físicas y realismo)
RunService.RenderStepped:Connect(function(_dt: number)
	local char = localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or not hum.Sit or not hum.SeatPart or not hum.SeatPart:IsA("VehicleSeat") then
		return
	end

	local asiento = hum.SeatPart :: VehicleSeat
	local modelo = asiento.Parent
	if not modelo then
		return
	end

	local chasis = modelo.PrimaryPart or modelo:FindFirstChild("Chasis") :: BasePart?
	if not chasis then
		return
	end

	-- Limpiar cualquier remanente que cause elevación o congelamiento de giro
	local ao = chasis:FindFirstChild("UprightStabilizer")
	if ao then
		ao:Destroy()
	end
	local lv = chasis:FindFirstChild("DriveVelocity")
	if lv then
		lv:Destroy()
	end
	local av = chasis:FindFirstChild("SteerVelocity")
	if av then
		av:Destroy()
	end

	-- Asiento nunca colisionable
	if asiento.CanCollide then
		asiento.CanCollide = false
	end

	-- Identificar vehículo equipado y estadísticas base
	local idVehiculo = if string.find(modelo.Name, "Moto")
		then "Vehiculo_Moto"
		else "Vehiculo_Bicicleta"
	local stats = Datos.Vehiculos[idVehiculo]
		or (
			if idVehiculo == "Vehiculo_Moto"
				then { VelocidadMax = 38, Torque = 38, TurnSpeed = 2.4 }
				else { VelocidadMax = 26, Torque = 28, TurnSpeed = 2.2 }
		)
	local velBase = stats.VelocidadMax or 26
	local torqueBase = stats.Torque or 28

	-- Detección de superficie bajo el vehículo
	raycastParams.FilterDescendantsInstances = { modelo, char }
	local hit = Workspace:Raycast(chasis.Position, Vector3.new(0, -5, 0), raycastParams)

	if hit then
		local mat = hit.Material
		if
			mat == Enum.Material.Grass
			or mat == Enum.Material.LeafyGrass
			or mat == Enum.Material.Ground
		then
			-- Césped: pedaleo más pesado (75% velocidad, 80% torque)
			asiento.MaxSpeed = velBase * 0.75
			asiento.Torque = torqueBase * 0.8
		elseif mat == Enum.Material.Sand or mat == Enum.Material.Mud then
			-- Arena o barro: alta fricción (55% velocidad, 60% torque)
			asiento.MaxSpeed = velBase * 0.55
			asiento.Torque = torqueBase * 0.6
		else
			-- Asfalto, concreto, adoquín: agarre total
			asiento.MaxSpeed = velBase
			asiento.Torque = torqueBase
		end
	else
		-- En el aire (saltando o descolgándose): sin torque de pedaleo para caída limpia por gravedad
		asiento.Torque = 0
	end
end)
