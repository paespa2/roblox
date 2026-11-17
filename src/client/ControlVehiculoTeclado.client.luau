local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)

local enCooldown = false
local velocidadActual = 0

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

-- 2. Conducción fluida del lado del cliente (propietario de la red física)
RunService.RenderStepped:Connect(function(dt: number)
	local char = localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or not hum.Sit or not hum.SeatPart or not hum.SeatPart:IsA("VehicleSeat") then
		velocidadActual = 0
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

	-- Eliminar UprightStabilizer si existe para dar libertad total de giro al manubrio
	local ao = chasis:FindFirstChild("UprightStabilizer")
	if ao then
		ao:Destroy()
	end

	local lv = chasis:FindFirstChild("DriveVelocity") :: LinearVelocity?
	local av = chasis:FindFirstChild("SteerVelocity") :: AngularVelocity?
	if not lv or not av then
		return
	end

	-- Asegurar propiedades de física libre sin flotación
	if lv.RelativeTo ~= Enum.ActuatorRelativeTo.World then
		lv.RelativeTo = Enum.ActuatorRelativeTo.World
		lv.ForceLimitMode = Enum.ForceLimitMode.PerAxis
		lv.MaxAxesForce = Vector3.new(35000, 0, 35000) -- Cero en Y: la gravedad manda
	end
	if av.RelativeTo ~= Enum.ActuatorRelativeTo.World then
		av.RelativeTo = Enum.ActuatorRelativeTo.World
		av.MaxTorque = 45000
	end

	local throttle = asiento.ThrottleFloat
	local steer = asiento.SteerFloat

	-- Detección de suelo por raycast
	raycastParams.FilterDescendantsInstances = { modelo, char }
	local hit = Workspace:Raycast(chasis.Position, Vector3.new(0, -4.5, 0), raycastParams)

	local factorSuperficie = 1.0
	local tasaAceleracion = 28
	local velocidadBase = 22

	if hit then
		local mat = hit.Material
		if
			mat == Enum.Material.Grass
			or mat == Enum.Material.LeafyGrass
			or mat == Enum.Material.Ground
		then
			factorSuperficie = 0.75 -- Césped: pedaleo más pesado
			tasaAceleracion = 18
		elseif mat == Enum.Material.Sand or mat == Enum.Material.Mud then
			factorSuperficie = 0.55 -- Arena/Lodo: mucha fricción
			tasaAceleracion = 12
		else
			factorSuperficie = 1.0 -- Asfalto y Concreto: agarre total
			tasaAceleracion = 32
		end
	else
		-- En el aire (saltando): sin tracción de pedales
		factorSuperficie = 0.15
		tasaAceleracion = 6
	end

	local velMax = velocidadBase * factorSuperficie
	local velMeta = throttle * velMax

	if math.abs(throttle) > 0.05 then
		local diff = velMeta - velocidadActual
		velocidadActual += math.sign(diff) * math.min(math.abs(diff), tasaAceleracion * dt)
	else
		-- Desaceleración por fricción al soltar pedales
		local friccion = if hit then 20 * dt else 4 * dt
		if math.abs(velocidadActual) <= friccion then
			velocidadActual = 0
		else
			velocidadActual -= math.sign(velocidadActual) * friccion
		end
	end

	-- Dirección horizontal de avance (W = adelante, S = reversa)
	local look = chasis.CFrame.LookVector
	local fwdHoriz = Vector3.new(look.X, 0, look.Z)
	if fwdHoriz.Magnitude > 0.01 then
		fwdHoriz = fwdHoriz.Unit
	else
		fwdHoriz = Vector3.new(0, 0, -1)
	end

	-- Aplicar velocidad horizontal (Y = 0 para que la gravedad actúe natural)
	local velVec = fwdHoriz * velocidadActual
	lv.VectorVelocity = Vector3.new(velVec.X, 0, velVec.Z)

	-- Giro limpio y libre sobre el eje Y mundial:
	-- A (steer = -1) -> gira a la izquierda (+Y)
	-- D (steer = +1) -> gira a la derecha (-Y)
	local factorGiro = math.clamp(math.abs(velocidadActual) / 4, 0.4, 1.0)
	av.AngularVelocity = Vector3.new(0, -steer * 2.8 * factorGiro, 0)
end)
