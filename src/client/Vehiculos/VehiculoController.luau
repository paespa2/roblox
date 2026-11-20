--!strict
--[[
	VehiculoController.luau
	Controlador cliente modular para la conducción de vehículos.
	Maneja la entrada de usuario (teclas W/A/S/D, V, H, Espacio),
	físicas en tiempo real en coordenadas de mundo, inclinación dinámica (banking),
	animación procedural de pedaleo, efectos de luces de freno y audio dinámico de motor.
	
	El Patrón del Dulce
]]

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)
local Datos = require(ReplicatedStorage.Shared.Datos)

local VehiculoController = {}

local enCooldown = false
local pedalAngle = 0
local velocidadActual = 0
local ultimoSonidoMotor: Sound? = nil
local ultimoModeloMontado: Model? = nil

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

local function tocarPito(chasis: BasePart?)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	sound.PlaybackSpeed = 1.35
	sound.Volume = 0.85
	sound.Parent = chasis or SoundService
	pcall(function()
		sound:Play()
	end)
	task.delay(1.2, function()
		sound:Destroy()
	end)

	if chasis then
		local bbg = Instance.new("BillboardGui")
		bbg.Name = "BurbujaPito"
		bbg.Size = UDim2.fromOffset(130, 40)
		bbg.StudsOffset = Vector3.new(0, 3.2, -1.8)
		bbg.AlwaysOnTop = true
		bbg.MaxDistance = 50
		bbg.Parent = chasis

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundColor3 = Color3.fromRGB(25, 28, 35)
		lbl.TextColor3 = Color3.fromRGB(255, 215, 0)
		lbl.Font = Enum.Font.FredokaOne
		lbl.Text = "🛵 ¡PII-PII!"
		lbl.TextSize = 16
		lbl.Parent = bbg

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = lbl

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(255, 215, 0)
		stroke.Thickness = 1.5
		stroke.Parent = lbl

		task.delay(0.7, function()
			bbg:Destroy()
		end)
	end
end

function VehiculoController.Iniciar()
	-- 1. Invocación, Desmontaje y Bocina
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
		elseif input.KeyCode == Enum.KeyCode.H then
			local char = localPlayer.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum and hum.Sit and hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
				local modelo = hum.SeatPart.Parent
				local chasis = modelo
					and (modelo.PrimaryPart or modelo:FindFirstChild("Chasis")) :: BasePart?
				tocarPito(chasis)
			end
		elseif input.KeyCode == Enum.KeyCode.Space then
			local char = localPlayer.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hum and hum.Sit and hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") and hrp then
				local asiento = hum.SeatPart
				local chasis = asiento.Parent
					and (
						asiento.Parent.PrimaryPart or asiento.Parent:FindFirstChild("Chasis")
					) :: BasePart?
				hum.Sit = false
				task.wait(0.05)
				if chasis then
					hrp.CFrame = chasis.CFrame * CFrame.new(3.0, 0.8, 0)
				end
			end
		end
	end)

	-- 2. Sistema de Conducción Físico en Tiempo Real
	RunService.RenderStepped:Connect(function(dt: number)
		local char = localPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum or not hum.Sit or not hum.SeatPart or not hum.SeatPart:IsA("VehicleSeat") then
			velocidadActual = 0
			if ultimoSonidoMotor then
				ultimoSonidoMotor:Stop()
				ultimoSonidoMotor:Destroy()
				ultimoSonidoMotor = nil
			end
			ultimoModeloMontado = nil
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

		if asiento.CanCollide then
			asiento.CanCollide = false
		end
		if asiento.MaxSpeed ~= 0 or asiento.Torque ~= 0 then
			asiento.MaxSpeed = 0
			asiento.Torque = 0
			asiento.TurnSpeed = 0
		end

		local nombreMod = modelo.Name:lower()
		local tipoVehiculo = "Bicicleta"
		local velBase = 32
		local turnSpeed = 2.5
		local maxForceZ = 28000
		local maxTorqueGiro = 70000

		if string.find(nombreMod, "moto") then
			tipoVehiculo = "Moto"
			velBase = 48
			turnSpeed = 2.8
			maxForceZ = 36000
			maxTorqueGiro = 85000
		elseif string.find(nombreMod, "taxi") then
			tipoVehiculo = "Taxi"
			velBase = 36
			turnSpeed = 2.2
			maxForceZ = 45000
			maxTorqueGiro = 85000
		elseif string.find(nombreMod, "campero") or string.find(nombreMod, "willys") then
			tipoVehiculo = "Campero"
			velBase = 35
			turnSpeed = 2.1
			maxForceZ = 48000
			maxTorqueGiro = 88000
		else
			local stats = Datos.Vehiculos["Vehiculo_Bicicleta"]
			if stats then
				velBase = stats.VelocidadMax or 32
				turnSpeed = stats.TurnSpeed or 2.5
			end
		end

		-- Gestión del sonido de motor continuo para la moto
		if tipoVehiculo == "Moto" then
			if
				not ultimoSonidoMotor
				or ultimoModeloMontado ~= modelo
				or not ultimoSonidoMotor.Parent
			then
				if ultimoSonidoMotor then
					ultimoSonidoMotor:Destroy()
				end
				local sound = Instance.new("Sound")
				sound.Name = "SonidoMotor"
				sound.SoundId = "rbxassetid://12222242"
				sound.Looped = true
				sound.Volume = 0.35
				sound.PlaybackSpeed = 0.65
				sound.RollOffMaxDistance = 70
				sound.RollOffMinDistance = 5
				sound.Parent = chasis
				pcall(function()
					sound:Play()
				end)
				ultimoSonidoMotor = sound
				ultimoModeloMontado = modelo
			end

			if ultimoSonidoMotor then
				local ratio = math.clamp(math.abs(velocidadActual) / velBase, 0, 1)
				ultimoSonidoMotor.PlaybackSpeed = 0.65 + ratio * 0.95
				ultimoSonidoMotor.Volume = 0.30 + ratio * 0.25
			end
		else
			if ultimoSonidoMotor then
				ultimoSonidoMotor:Stop()
				ultimoSonidoMotor:Destroy()
				ultimoSonidoMotor = nil
			end
		end

		-- Detección de superficie bajo el vehículo
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
				velMaxSuperficie = velBase * 0.75
			elseif mat == Enum.Material.Sand or mat == Enum.Material.Mud then
				velMaxSuperficie = velBase * 0.55
			else
				velMaxSuperficie = velBase
			end
		else
			velMaxSuperficie = 0
			enElAire = true
		end

		-- Asegurar Attachments y Actuadores en Chasis
		local driveAtt = chasis:FindFirstChild("DriveAtt") :: Attachment?
		if not driveAtt then
			driveAtt = Instance.new("Attachment")
			driveAtt.Name = "DriveAtt"
			driveAtt.Parent = chasis
		end

		local uprightAtt = chasis:FindFirstChild("UprightAtt") :: Attachment?
		if not uprightAtt then
			uprightAtt = Instance.new("Attachment")
			uprightAtt.Name = "UprightAtt"
			uprightAtt.Axis = Vector3.new(0, 1, 0)
			uprightAtt.SecondaryAxis = Vector3.new(0, 0, -1)
			uprightAtt.Parent = chasis
		end

		local forwardDir = Vector3.new(chasis.CFrame.LookVector.X, 0, chasis.CFrame.LookVector.Z)
		if forwardDir.Magnitude > 0.01 then
			forwardDir = forwardDir.Unit
		else
			forwardDir = Vector3.new(0, 0, -1)
		end

		local driveLV = chasis:FindFirstChild("DriveLV") :: LinearVelocity?
		if not driveLV then
			driveLV = Instance.new("LinearVelocity")
			driveLV.Name = "DriveLV"
			driveLV.Attachment0 = driveAtt
			driveLV.RelativeTo = Enum.ActuatorRelativeTo.World
			driveLV.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
			driveLV.LineDirection = forwardDir
			driveLV.MaxForce = maxForceZ
			driveLV.LineVelocity = 0
			driveLV.Parent = chasis
		else
			if driveLV.RelativeTo ~= Enum.ActuatorRelativeTo.World then
				driveLV.RelativeTo = Enum.ActuatorRelativeTo.World
			end
			if driveLV.VelocityConstraintMode ~= Enum.VelocityConstraintMode.Line then
				driveLV.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
			end
			driveLV.LineDirection = forwardDir
			driveLV.MaxForce = maxForceZ
		end

		local steerAV = chasis:FindFirstChild("SteerAV") :: AngularVelocity?
		if not steerAV then
			steerAV = Instance.new("AngularVelocity")
			steerAV.Name = "SteerAV"
			steerAV.Attachment0 = driveAtt
			steerAV.RelativeTo = Enum.ActuatorRelativeTo.World
			steerAV.MaxTorque = maxTorqueGiro
			steerAV.Parent = chasis
		else
			if steerAV.RelativeTo ~= Enum.ActuatorRelativeTo.World then
				steerAV.RelativeTo = Enum.ActuatorRelativeTo.World
			end
		end

		local ao = chasis:FindFirstChild("EstabilizadorVertical") :: AlignOrientation?
		if not ao then
			ao = Instance.new("AlignOrientation")
			ao.Name = "EstabilizadorVertical"
			ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
			ao.Attachment0 = uprightAtt
			ao.AlignType = Enum.AlignType.PrimaryAxisParallel
			ao.PrimaryAxis = Vector3.new(0, 1, 0)
			ao.MaxTorque = 45000
			ao.Responsiveness = 35
			ao.ReactionTorqueEnabled = false
			ao.Parent = chasis
		elseif ao.Attachment0 ~= uprightAtt then
			ao.Attachment0 = uprightAtt
		end

		-- Lectura de controles
		local throttle = 0
		if
			UserInputService:IsKeyDown(Enum.KeyCode.W)
			or UserInputService:IsKeyDown(Enum.KeyCode.Up)
		then
			throttle += 1
		end
		if
			UserInputService:IsKeyDown(Enum.KeyCode.S)
			or UserInputService:IsKeyDown(Enum.KeyCode.Down)
		then
			throttle -= 1
		end
		if math.abs(asiento.ThrottleFloat) > 0.1 then
			throttle = asiento.ThrottleFloat
		end

		local steer = 0
		if
			UserInputService:IsKeyDown(Enum.KeyCode.D)
			or UserInputService:IsKeyDown(Enum.KeyCode.Right)
		then
			steer += 1
		end
		if
			UserInputService:IsKeyDown(Enum.KeyCode.A)
			or UserInputService:IsKeyDown(Enum.KeyCode.Left)
		then
			steer -= 1
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

		-- Luces de Freno reactivas
		local luzFreno = modelo:FindFirstChild("LuzFreno") :: BasePart?
		local lightFreno = modelo:FindFirstChild("LuzRojoTrasera", true) :: PointLight?
		if luzFreno then
			if throttle < -0.05 then
				luzFreno.Color = Color3.fromRGB(255, 50, 50)
				luzFreno.Material = Enum.Material.Neon
				if lightFreno then
					lightFreno.Brightness = 4.0
				end
			else
				luzFreno.Color = Color3.fromRGB(200, 25, 25)
				luzFreno.Material = Enum.Material.Neon
				if lightFreno then
					lightFreno.Brightness = 1.5
				end
			end
		end

		if enElAire then
			driveLV.LineVelocity = 0
			steerAV.MaxTorque = 0
			steerAV.AngularVelocity = Vector3.zero
			velocidadActual = 0
		else
			-- 1. Aceleración y Desaceleración progresiva
			local velMeta = 0
			if throttle > 0.05 then
				velMeta = throttle * velMaxSuperficie
			elseif throttle < -0.05 then
				velMeta = throttle * (velMaxSuperficie * 0.55)
			end

			local tasaAcel = if math.abs(throttle) > 0.05 then 34 else 42
			local diff = velMeta - velocidadActual
			local deltaV = math.sign(diff) * math.min(math.abs(diff), tasaAcel * dt)
			velocidadActual += deltaV

			-- 2. Propulsión longitudinal en modo Line (hacia adelante / reversa)
			driveLV.MaxForce = maxForceZ
			driveLV.LineVelocity = velocidadActual

			-- 3. Giro Horizontal (Yaw)
			local factorGiro = 1.0
			if math.abs(velocidadActual) > 0.5 then
				factorGiro = math.clamp(1.2 - (math.abs(velocidadActual) / velBase) * 0.3, 0.7, 1.2)
			end

			local velocidadAngularY = -steer * turnSpeed * factorGiro
			steerAV.MaxTorque = maxTorqueGiro
			steerAV.AngularVelocity = Vector3.new(0, velocidadAngularY, 0)

			-- 4. Inclinación Dinámica Realista (Banking) en dos ruedas
			if ao then
				local leanAngle = 0
				if
					(tipoVehiculo == "Bicicleta" or tipoVehiculo == "Moto")
					and math.abs(velocidadActual) > 3
				then
					local dirAvance = math.sign(velocidadActual)
					leanAngle = steer
						* 0.18
						* dirAvance
						* math.clamp(math.abs(velocidadActual) / velBase, 0.2, 1.0)
				end
				local rotLeaning = CFrame.fromAxisAngle(chasis.CFrame.LookVector, -leanAngle)
				ao.PrimaryAxis = rotLeaning * Vector3.new(0, 1, 0)
			end
		end

		-- 5. Animación Procedural del Avatar (Pedaleo únicamente en Bicicleta)
		local rootPart = char:FindFirstChild("HumanoidRootPart")
		if
			tipoVehiculo == "Bicicleta"
			and rootPart
			and math.abs(velocidadActual) > 0.5
			and not enElAire
		then
			pedalAngle = (pedalAngle + (dt * velocidadActual * 0.45)) % (math.pi * 2)

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

	print("El Patrón del Dulce [Cliente]: VehiculoController Inicializado")
end

return VehiculoController
