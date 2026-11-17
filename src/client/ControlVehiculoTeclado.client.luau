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
local pedalAngle = 0
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

-- 2. Sistema de Conducción Físico en Tiempo Real (Controles Corregidos: W Adelante, S Reversa, A Izquierda, D Derecha)
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

	-- El asiento nunca debe colisionar con el cuerpo del avatar
	if asiento.CanCollide then
		asiento.CanCollide = false
	end
	-- Deshabilitar el skid-steer nativo invertido de Roblox en el asiento
	if asiento.MaxSpeed ~= 0 or asiento.Torque ~= 0 then
		asiento.MaxSpeed = 0
		asiento.Torque = 0
		asiento.TurnSpeed = 0
	end

	-- Identificar vehículo equipado y estadísticas base
	local idVehiculo = if string.find(modelo.Name, "Moto")
		then "Vehiculo_Moto"
		else "Vehiculo_Bicicleta"
	local stats = Datos.Vehiculos[idVehiculo]
		or (
			if idVehiculo == "Vehiculo_Moto"
				then { VelocidadMax = 48, Torque = 52, TurnSpeed = 2.6 }
				else { VelocidadMax = 34, Torque = 36, TurnSpeed = 2.4 }
		)
	local velBase = stats.VelocidadMax or 34
	local turnSpeed = stats.TurnSpeed or 2.4

	-- Detección de superficie bajo el vehículo para física realista
	raycastParams.FilterDescendantsInstances = { modelo, char }
	local hit = Workspace:Raycast(chasis.Position, Vector3.new(0, -5, 0), raycastParams)

	local velMaxSuperficie = velBase
	local enElAire = false

	if hit then
		local mat = hit.Material
		if
			mat == Enum.Material.Grass
			or mat == Enum.Material.LeafyGrass
			or mat == Enum.Material.Ground
		then
			-- Césped / Ladera: pedaleo más pesado (75% velocidad)
			velMaxSuperficie = velBase * 0.75
		elseif mat == Enum.Material.Sand or mat == Enum.Material.Mud then
			-- Arena / Lodo: alta fricción (55% velocidad)
			velMaxSuperficie = velBase * 0.55
		else
			-- Asfalto, adoquín, concreto, metal: velocidad 100%
			velMaxSuperficie = velBase
		end
	else
		-- En el aire (saltando desniveles): caída libre por gravedad
		velMaxSuperficie = 0
		enElAire = true
	end

	-- Asegurar Attachment y Actuadores en Chasis
	local driveAtt = chasis:FindFirstChild("DriveAtt") :: Attachment?
	if not driveAtt then
		driveAtt = Instance.new("Attachment")
		driveAtt.Name = "DriveAtt"
		driveAtt.Parent = chasis
	end

	local driveLV = chasis:FindFirstChild("DriveLV") :: LinearVelocity?
	if not driveLV then
		driveLV = Instance.new("LinearVelocity")
		driveLV.Name = "DriveLV"
		driveLV.Attachment0 = driveAtt
		driveLV.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
		driveLV.ForceLimitsEnabled = true
		driveLV.MaxAxesForce = Vector3.new(0, 0, 28000)
		driveLV.Parent = chasis
	end

	local steerAV = chasis:FindFirstChild("SteerAV") :: AngularVelocity?
	if not steerAV then
		steerAV = Instance.new("AngularVelocity")
		steerAV.Name = "SteerAV"
		steerAV.Attachment0 = driveAtt
		steerAV.RelativeTo = Enum.ActuatorRelativeTo.World
		steerAV.MaxTorque = 70000
		steerAV.Parent = chasis
	end

	local ao = chasis:FindFirstChild("EstabilizadorVertical") :: AlignOrientation?
	if not ao then
		ao = Instance.new("AlignOrientation")
		ao.Name = "EstabilizadorVertical"
		ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
		ao.Attachment0 = driveAtt
		ao.AlignType = Enum.AlignType.PrimaryAxisParallel
		ao.PrimaryAxis = Vector3.new(0, 1, 0)
		ao.MaxTorque = 40000
		ao.Responsiveness = 35
		ao.ReactionTorqueEnabled = false
		ao.Parent = chasis
	end

	-- Lectura de controles directa por hardware (Teclado W, A, S, D) y fallback a VehicleSeat (Móvil/Gamepad)
	local throttle = 0
	if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
		throttle += 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then
		throttle -= 1
	end
	if math.abs(asiento.ThrottleFloat) > 0.1 then
		throttle = asiento.ThrottleFloat
	end

	local steer = 0
	if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
		steer += 1 -- D / Flecha Derecha: Giro a la DERECHA
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
		steer -= 1 -- A / Flecha Izquierda: Giro a la IZQUIERDA
	end
	if math.abs(asiento.SteerFloat) > 0.1 then
		steer = asiento.SteerFloat
	end

	local overrideThrottle = asiento:GetAttribute("OverrideThrottle")
	if overrideThrottle ~= nil then
		throttle = overrideThrottle
	end
	local overrideSteer = asiento:GetAttribute("OverrideSteer")
	if overrideSteer ~= nil then
		steer = overrideSteer
	end

	if enElAire then
		driveLV.MaxAxesForce = Vector3.new(0, 0, 0)
		driveLV.VectorVelocity = Vector3.zero
		steerAV.MaxTorque = 0
		steerAV.AngularVelocity = Vector3.zero
		velocidadActual = 0
	else
		-- 1. Aceleración y Desaceleración progresiva
		local velMeta = 0
		if throttle > 0.05 then
			velMeta = throttle * velMaxSuperficie -- Adelante (W)
		elseif throttle < -0.05 then
			velMeta = throttle * (velMaxSuperficie * 0.55) -- Reversa suave (S)
		end

		local tasaAcel = if math.abs(throttle) > 0.05 then 28 else 35
		local diff = velMeta - velocidadActual
		local deltaV = math.sign(diff) * math.min(math.abs(diff), tasaAcel * dt)
		velocidadActual += deltaV

		-- 2. Propulsión longitudinal únicamente en el eje Z local
		-- Nota: En el modelo de la bicicleta, -Z local apunta hacia el manubrio (adelante).
		-- Por lo tanto: velocidad hacia adelante (positiva) requiere empuje en -Z.
		driveLV.MaxAxesForce = Vector3.new(0, 0, 28000)
		driveLV.VectorVelocity = Vector3.new(0, 0, -velocidadActual)

		-- 3. Giro Horizontal (Yaw) en Movimiento y Estático:
		-- A (steer = -1): giro hacia la IZQUIERDA (+Y en rotación mundial)
		-- D (steer = 1): giro hacia la DERECHA (-Y en rotación mundial)
		-- Cuando va en movimiento hacia adelante o atrás, el giro es suave y continuo;
		-- cuando está detenido, permite girar o acomodarse.
		local factorGiro = 1.0
		if math.abs(velocidadActual) > 0.5 then
			-- En movimiento a velocidad alta, modula el giro para trazar arcos limpios
			factorGiro = math.clamp(1.2 - (math.abs(velocidadActual) / velBase) * 0.3, 0.7, 1.2)
		end

		local velocidadAngularY = steer * turnSpeed * factorGiro
		steerAV.MaxTorque = 70000
		steerAV.AngularVelocity = Vector3.new(0, velocidadAngularY, 0)

		-- 4. Inclinación Dinámica Realista (Banking) en Curvas
		-- Cuando gira a la derecha (D), la bicicleta y el avatar se inclinan hacia la derecha.
		-- Cuando gira a la izquierda (A), se inclinan hacia la izquierda.
		if ao then
			local leanAngle = 0
			if math.abs(velocidadActual) > 3 then
				local dirAvance = math.sign(velocidadActual)
				leanAngle = steer * 0.14 * dirAvance
			end
			-- Inclinación sobre el vector RightVector local
			local upDeseado = (chasis.CFrame.UpVector + (chasis.CFrame.RightVector * leanAngle)).Unit
			ao.PrimaryAxis = Vector3.new(upDeseado.X, 1, upDeseado.Z).Unit
		end
	end

	-- 5. Animación Procedural del Avatar (Pedaleo de piernas y Manos al Manubrio)
	local rootPart = char:FindFirstChild("HumanoidRootPart")
	if rootPart and math.abs(velocidadActual) > 0.5 and not enElAire then
		pedalAngle = (pedalAngle + (dt * velocidadActual * 0.45)) % (math.pi * 2)

		-- Motores R15 de caderas y rodillas
		local lowerTorso = char:FindFirstChild("LowerTorso")
		if lowerTorso then
			local leftHip = lowerTorso:FindFirstChild("LeftHip") :: Motor6D?
			local rightHip = lowerTorso:FindFirstChild("RightHip") :: Motor6D?
			if leftHip and rightHip then
				local anguloIzq = math.sin(pedalAngle) * 0.45
				local anguloDer = math.sin(pedalAngle + math.pi) * 0.45
				leftHip.Transform = CFrame.Angles(anguloIzq - 0.7, 0, 0)
				rightHip.Transform = CFrame.Angles(anguloDer - 0.7, 0, 0)
			end
		end

		local leftLeg = char:FindFirstChild("LeftLowerLeg")
		local rightLeg = char:FindFirstChild("RightLowerLeg")
		if leftLeg and rightLeg then
			local leftKnee = leftLeg:FindFirstChild("LeftKnee") :: Motor6D?
			local rightKnee = rightLeg:FindFirstChild("RightKnee") :: Motor6D?
			if leftKnee and rightKnee then
				local flexIzq = math.max(0, math.cos(pedalAngle) * 0.7 + 0.6)
				local flexDer = math.max(0, math.cos(pedalAngle + math.pi) * 0.7 + 0.6)
				leftKnee.Transform = CFrame.Angles(flexIzq, 0, 0)
				rightKnee.Transform = CFrame.Angles(flexDer, 0, 0)
			end
		end
	end
end)
