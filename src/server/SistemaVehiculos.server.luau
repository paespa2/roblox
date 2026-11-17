local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GestorDatos = require(script.Parent.GestorDatos)
local Datos = require(ReplicatedStorage.Shared.Datos)
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)

local vehiculosActivos: { [Player]: Model } = {}
local conexionesVehiculos: { [Player]: RBXScriptConnection } = {}

local function obtenerPuntoAparicion(): Vector3
	local puntos = Workspace:FindFirstChild("Puntos")
	if puntos then
		local apariciones = puntos:FindFirstChild("Apariciones")
		if apariciones then
			local puntoCocina = apariciones:FindFirstChild("Punto_Cocina_Inicial") :: BasePart?
			if puntoCocina then
				return puntoCocina.Position + Vector3.new(0, 3, 0)
			end
		end
	end
	return Vector3.new(0, 5, 0)
end

local function crearModeloBicicletaFallback(): Model
	local modelo = Instance.new("Model")
	modelo.Name = "Vehiculo_Bicicleta"

	local chasis = Instance.new("Part")
	chasis.Name = "Chasis"
	chasis.Size = Vector3.new(1.8, 1.2, 4)
	chasis.Color = Color3.fromRGB(220, 75, 45)
	chasis.Material = Enum.Material.Metal
	chasis.CanCollide = true
	chasis.Parent = modelo
	modelo.PrimaryPart = chasis

	local asiento = Instance.new("VehicleSeat")
	asiento.Name = "Asiento"
	asiento.Size = Vector3.new(1.6, 0.8, 1.8)
	asiento.Position = chasis.Position + Vector3.new(0, 0.8, 0.2)
	asiento.Color = Color3.fromRGB(40, 40, 45)
	asiento.MaxSpeed = Datos.Vehiculos.Vehiculo_Bicicleta.VelocidadMax or 22
	asiento.Torque = 25
	asiento.TurnSpeed = 2.4
	asiento.CanCollide = false
	asiento.Parent = modelo

	local weldAsiento = Instance.new("WeldConstraint")
	weldAsiento.Part0 = chasis
	weldAsiento.Part1 = asiento
	weldAsiento.Parent = chasis

	local manubrio = Instance.new("Part")
	manubrio.Name = "Manubrio"
	manubrio.Size = Vector3.new(2.8, 0.4, 0.4)
	manubrio.Position = chasis.Position + Vector3.new(0, 1.4, -1.8)
	manubrio.Color = Color3.fromRGB(60, 60, 60)
	manubrio.CanCollide = false
	manubrio.Parent = modelo

	local weldManubrio = Instance.new("WeldConstraint")
	weldManubrio.Part0 = chasis
	weldManubrio.Part1 = manubrio
	weldManubrio.Parent = chasis

	local farola = Instance.new("Part")
	farola.Name = "Farola"
	farola.Size = Vector3.new(0.6, 0.6, 0.4)
	farola.Position = chasis.Position + Vector3.new(0, 1.1, -2.1)
	farola.Color = Color3.fromRGB(255, 255, 200)
	farola.Material = Enum.Material.Neon
	farola.CanCollide = false
	farola.Parent = modelo

	local weldFarola = Instance.new("WeldConstraint")
	weldFarola.Part0 = chasis
	weldFarola.Part1 = farola
	weldFarola.Parent = chasis

	return modelo
end

local function crearModeloMotoFallback(): Model
	local modelo = Instance.new("Model")
	modelo.Name = "Vehiculo_Moto"

	local chasis = Instance.new("Part")
	chasis.Name = "Chasis"
	chasis.Size = Vector3.new(2.0, 1.4, 4.5)
	chasis.Color = Color3.fromRGB(35, 40, 45)
	chasis.Material = Enum.Material.Metal
	chasis.CanCollide = true
	chasis.Parent = modelo
	modelo.PrimaryPart = chasis

	local asiento = Instance.new("VehicleSeat")
	asiento.Name = "Asiento"
	asiento.Size = Vector3.new(1.8, 0.8, 2.0)
	asiento.Position = chasis.Position + Vector3.new(0, 0.9, 0.1)
	asiento.Color = Color3.fromRGB(25, 25, 30)
	asiento.MaxSpeed = Datos.Vehiculos.Vehiculo_Moto.VelocidadMax or 38
	asiento.Torque = 40
	asiento.TurnSpeed = 2.8
	asiento.CanCollide = false
	asiento.Parent = modelo

	local weldAsiento = Instance.new("WeldConstraint")
	weldAsiento.Part0 = chasis
	weldAsiento.Part1 = asiento
	weldAsiento.Parent = chasis

	local tanque = Instance.new("Part")
	tanque.Name = "Tanque"
	tanque.Size = Vector3.new(1.8, 0.8, 1.8)
	tanque.Position = chasis.Position + Vector3.new(0, 1.1, -0.8)
	tanque.Color = Color3.fromRGB(220, 40, 40)
	tanque.Material = Enum.Material.SmoothPlastic
	tanque.CanCollide = false
	tanque.Parent = modelo

	local weldTanque = Instance.new("WeldConstraint")
	weldTanque.Part0 = chasis
	weldTanque.Part1 = tanque
	weldTanque.Parent = chasis

	local farol = Instance.new("Part")
	farol.Name = "Farol"
	farol.Size = Vector3.new(0.8, 0.8, 0.4)
	farol.Position = chasis.Position + Vector3.new(0, 1.2, -2.3)
	farol.Color = Color3.fromRGB(255, 255, 220)
	farol.Material = Enum.Material.Neon
	farol.CanCollide = false
	farol.Parent = modelo

	local luz = Instance.new("SpotLight")
	luz.Range = 35
	luz.Brightness = 2.5
	luz.Angle = 65
	luz.Face = Enum.NormalId.Front
	luz.Parent = farol

	local weldFarol = Instance.new("WeldConstraint")
	weldFarol.Part0 = chasis
	weldFarol.Part1 = farol
	weldFarol.Parent = chasis

	return modelo
end

local function configurarFisicaConduccion(player: Player, modelo: Model, infoVehiculo: any)
	local chasis = modelo.PrimaryPart or modelo:FindFirstChild("Chasis") :: BasePart?
	local asiento = modelo:FindFirstChildOfClass("VehicleSeat")
	if not chasis or not asiento then
		return
	end

	-- Desactivar fricción de ruedas físicas existentes para evitar que giren en reversa
	for _, desc in ipairs(modelo:GetDescendants()) do
		if desc:IsA("JointInstance") and desc.ClassName == "Rotate" then
			desc:Destroy()
		end
		if desc:IsA("BasePart") and desc ~= chasis and desc ~= asiento then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = chasis
			weld.Part1 = desc
			weld.Parent = chasis

			if desc.Name == "RuedaFisica" then
				desc.CanCollide = true
				desc.CustomPhysicalProperties = PhysicalProperties.new(1.2, 0.7, 0.2, 1, 1)
			else
				desc.CanCollide = false
				desc.CustomPhysicalProperties = PhysicalProperties.new(0.5, 0.05, 0.2, 1, 1)
			end
		end
	end

	chasis.CustomPhysicalProperties = PhysicalProperties.new(1.0, 0.2, 0.3, 1, 1)

	-- Desactivar el solver interno de VehicleSeat para que no interfiera con los constraints
	asiento.MaxSpeed = 0
	asiento.Torque = 0
	asiento.TurnSpeed = 0

	local att = chasis:FindFirstChild("VehicleDriveAttachment") :: Attachment?
	if not att then
		att = Instance.new("Attachment")
		att.Name = "VehicleDriveAttachment"
		att.Position = Vector3.zero
		att.Axis = Vector3.new(0, 1, 0) -- Eje primario apunta verticalmente (Local Up)
		att.SecondaryAxis = Vector3.new(0, 0, 1)
		att.Parent = chasis
	else
		att.Axis = Vector3.new(0, 1, 0)
		att.SecondaryAxis = Vector3.new(0, 0, 1)
	end

	local lv = chasis:FindFirstChild("DriveVelocity") :: LinearVelocity?
	if not lv then
		lv = Instance.new("LinearVelocity")
		lv.Name = "DriveVelocity"
		lv.Attachment0 = att
		lv.ForceLimitMode = Enum.ForceLimitMode.PerAxis
		lv.MaxAxesForce = Vector3.new(35000, 0, 35000) -- Fuerza CERO en Y mundial para evitar que despegue del suelo
		lv.RelativeTo = Enum.ActuatorRelativeTo.World
		lv.VectorVelocity = Vector3.zero
		lv.Parent = chasis
	else
		lv.ForceLimitMode = Enum.ForceLimitMode.PerAxis
		lv.MaxAxesForce = Vector3.new(35000, 0, 35000)
		lv.RelativeTo = Enum.ActuatorRelativeTo.World
	end

	local av = chasis:FindFirstChild("SteerVelocity") :: AngularVelocity?
	if not av then
		av = Instance.new("AngularVelocity")
		av.Name = "SteerVelocity"
		av.Attachment0 = att
		av.MaxTorque = 45000
		av.RelativeTo = Enum.ActuatorRelativeTo.World
		av.AngularVelocity = Vector3.zero
		av.Parent = chasis
	else
		av.MaxTorque = 45000
		av.RelativeTo = Enum.ActuatorRelativeTo.World
	end

	local ao = chasis:FindFirstChild("UprightStabilizer") :: AlignOrientation?
	if not ao then
		ao = Instance.new("AlignOrientation")
		ao.Name = "UprightStabilizer"
		ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
		ao.AlignType = Enum.AlignType.PrimaryAxisParallel
		ao.Attachment0 = att
		ao.PrimaryAxis = Vector3.new(0, 1, 0)
		ao.MaxTorque = 80000
		ao.Responsiveness = 45
		ao.CFrame = CFrame.identity
		ao.Parent = chasis
	else
		ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
		ao.AlignType = Enum.AlignType.PrimaryAxisParallel
		ao.PrimaryAxis = Vector3.new(0, 1, 0)
		ao.MaxTorque = 80000
		ao.Responsiveness = 45
		ao.CFrame = CFrame.identity
	end

	local velocidadBase = infoVehiculo.VelocidadMax or 22
	local velocidadGiro = 2.6
	local velocidadActual = 0

	local raycastSuperficie = RaycastParams.new()
	raycastSuperficie.FilterType = Enum.RaycastFilterType.Exclude
	raycastSuperficie.IgnoreWater = true

	-- Conectar bucle de conducción con física horizontal en coordenadas mundiales (pegado al suelo)
	if conexionesVehiculos[player] then
		conexionesVehiculos[player]:Disconnect()
	end

	conexionesVehiculos[player] = RunService.Heartbeat:Connect(function(dt: number)
		if not modelo.Parent or not asiento.Parent then
			if conexionesVehiculos[player] then
				conexionesVehiculos[player]:Disconnect()
				conexionesVehiculos[player] = nil
			end
			return
		end

		local occupant = asiento.Occupant
		if occupant and occupant.Health > 0 then
			local throttle = asiento.ThrottleFloat
			local steer = asiento.SteerFloat

			-- 1. Raycast a la superficie bajo el chasis para detectar material
			raycastSuperficie.FilterDescendantsInstances = { modelo, player.Character }
			local hit =
				Workspace:Raycast(chasis.Position, Vector3.new(0, -4.5, 0), raycastSuperficie)

			local factorSuperficie = 1.0
			local tasaAceleracion = 28

			if hit then
				local mat = hit.Material
				if
					mat == Enum.Material.Grass
					or mat == Enum.Material.LeafyGrass
					or mat == Enum.Material.Ground
				then
					factorSuperficie = 0.75 -- Césped/Tierra: menor tracción
					tasaAceleracion = 18
				elseif mat == Enum.Material.Sand or mat == Enum.Material.Mud then
					factorSuperficie = 0.55 -- Arena/Lodo: pedaleo pesado
					tasaAceleracion = 12
				else
					factorSuperficie = 1.0 -- Asfalto, Concreto, Metal: tracción total
					tasaAceleracion = 30
				end
			else
				-- En el aire (saltando un desnivel): tracción nula
				factorSuperficie = 0.15
				tasaAceleracion = 6
			end

			-- 2. Dirección horizontal de avance en espacio mundial
			local look = chasis.CFrame.LookVector
			local fwdHoriz = Vector3.new(look.X, 0, look.Z)
			if fwdHoriz.Magnitude > 0.01 then
				fwdHoriz = fwdHoriz.Unit
			else
				fwdHoriz = Vector3.new(0, 0, -1)
			end

			-- 3. Penalización por carga en morral
			local factorCarga = 1.0
			local datosJugador = GestorDatos.ObtenerDatos(player)
			if datosJugador then
				local totalCarga = 0
				for _, cant in pairs(datosJugador.Inventario) do
					totalCarga += cant
				end
				if totalCarga > infoVehiculo.CapacidadCarga then
					factorCarga = 0.75
				end
			end

			-- 4. Velocidad meta y aceleración progresiva
			local velMaxFinal = velocidadBase * factorSuperficie * factorCarga
			local velMeta = throttle * velMaxFinal

			if math.abs(throttle) > 0.05 then
				local diff = velMeta - velocidadActual
				local paso = math.sign(diff) * math.min(math.abs(diff), tasaAceleracion * dt)
				velocidadActual += paso
			else
				-- Fricción y desaceleración natural al soltar pedales
				local friccion = if hit then 20 * dt else 5 * dt
				if math.abs(velocidadActual) <= friccion then
					velocidadActual = 0
				else
					velocidadActual -= math.sign(velocidadActual) * friccion
				end
			end

			-- Aplicar velocidad puramente horizontal en el plano mundial (Y = 0)
			local velVector = fwdHoriz * velocidadActual
			lv.VectorVelocity = Vector3.new(velVector.X, 0, velVector.Z)

			-- 5. Control de giro sobre el eje Y mundial:
			-- A (steer = -1) -> rota hacia la izquierda (+Y mundial)
			-- D (steer = +1) -> rota hacia la derecha (-Y mundial)
			local factorGiroVel = math.clamp(math.abs(velocidadActual) / 5, 0.35, 1.0)
			av.AngularVelocity = Vector3.new(0, -steer * velocidadGiro * factorGiroVel, 0)
		else
			velocidadActual = 0
			lv.VectorVelocity = Vector3.zero
			av.AngularVelocity = Vector3.zero
		end
	end)
end

local function aparecerVehiculo(
	player: Player,
	idVehiculo: string,
	posPersonalizada: Vector3?,
	lookDir: Vector3?
): (Model?, VehicleSeat?)
	local vehiculoExistente = vehiculosActivos[player]
	if vehiculoExistente and vehiculoExistente.Parent then
		vehiculoExistente:Destroy()
	end
	if conexionesVehiculos[player] then
		conexionesVehiculos[player]:Disconnect()
		conexionesVehiculos[player] = nil
	end

	local infoVehiculo = Datos.Vehiculos[idVehiculo]
	if not infoVehiculo then
		return nil, nil
	end

	local modeloBase: Model? = nil
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if assets then
		local carpetaVehiculos = assets:FindFirstChild("Vehiculos")
		if carpetaVehiculos then
			local encontrado = carpetaVehiculos:FindFirstChild(idVehiculo)
			if encontrado and encontrado:IsA("Model") then
				modeloBase = encontrado:Clone()
			end
		end
	end

	if not modeloBase then
		if idVehiculo == "Vehiculo_Moto" then
			modeloBase = crearModeloMotoFallback()
		else
			modeloBase = crearModeloBicicletaFallback()
		end
	end

	local posAparicion = posPersonalizada or obtenerPuntoAparicion()
	local dirAvance = lookDir or Vector3.new(0, 0, -1)
	if dirAvance.Magnitude > 0.01 then
		dirAvance = Vector3.new(dirAvance.X, 0, dirAvance.Z).Unit
	else
		dirAvance = Vector3.new(0, 0, -1)
	end

	-- Raycast para colocar el vehículo suavemente sobre el suelo
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	if player.Character then
		raycastParams.FilterDescendantsInstances = { player.Character, modeloBase }
	end
	local rayResult = Workspace:Raycast(
		posAparicion + Vector3.new(0, 4, 0),
		Vector3.new(0, -15, 0),
		raycastParams
	)
	local posFinal = if rayResult then rayResult.Position + Vector3.new(0, 1.6, 0) else posAparicion

	local cframeOrientado = CFrame.lookAt(posFinal, posFinal + dirAvance)
	modeloBase:PivotTo(cframeOrientado)
	modeloBase.Parent = Workspace
	vehiculosActivos[player] = modeloBase

	configurarFisicaConduccion(player, modeloBase, infoVehiculo)

	local asiento = modeloBase:FindFirstChildOfClass("VehicleSeat")
	return modeloBase, asiento
end

local function configurarSpawnBicicleta()
	local puntos = Workspace:WaitForChild("Puntos", 10)
	if not puntos then
		return
	end
	local apariciones = puntos:WaitForChild("Apariciones", 10)
	if not apariciones then
		return
	end

	local puntoCocina = apariciones:FindFirstChild("Punto_Cocina_Inicial") :: BasePart?
	if puntoCocina then
		local prompt = puntoCocina:FindFirstChildOfClass("ProximityPrompt")
		if not prompt then
			prompt = Instance.new("ProximityPrompt")
			prompt.Name = "PromptVehiculo"
			prompt.ObjectText = "Taller de Reparto"
			prompt.ActionText = "Tomar Vehículo"
			prompt.HoldDuration = 0.4
			prompt.MaxActivationDistance = 14
			prompt.RequiresLineOfSight = false
			prompt.Parent = puntoCocina
		end

		prompt.Triggered:Connect(function(player: Player)
			local character = player.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local hum = character and character:FindFirstChild("Humanoid") :: Humanoid?
			local look = if hrp then hrp.CFrame.LookVector else Vector3.new(0, 0, -1)
			local pos = if hrp
				then hrp.Position + (look * 3)
				else puntoCocina.Position + Vector3.new(0, 3, 0)

			local datosJugador = GestorDatos.ObtenerDatos(player)
			local vehiculoEquipado = if datosJugador
				then datosJugador.VehiculoEquipado
				else "Vehiculo_Bicicleta"

			local _, asiento = aparecerVehiculo(player, vehiculoEquipado, pos, look)
			if asiento and hum then
				task.wait(0.1)
				asiento:Sit(hum)
			end
		end)
	end
end

local function configurarMaestroTuerca()
	local mapa = Workspace:WaitForChild("Mapa", 10)
	if not mapa then
		return
	end
	local decoracion = mapa:WaitForChild("Decoracion", 10)
	if not decoracion then
		return
	end
	local npcs = decoracion:WaitForChild("NPCs_Interactivos", 10)
	if not npcs then
		return
	end
	local tuerca = npcs:FindFirstChild("Personaje_MaestroTuerca")
	if tuerca then
		local part = tuerca.PrimaryPart or tuerca:FindFirstChildWhichIsA("BasePart")
		if part then
			local prompt = part:FindFirstChildOfClass("ProximityPrompt")
			if not prompt then
				prompt = Instance.new("ProximityPrompt")
				prompt.Name = "PromptMaestroTuerca"
				prompt.ObjectText = "Maestro Tuerca (Mecánico)"
				prompt.ActionText = "Abrir Taller de Vehículos"
				prompt.HoldDuration = 0.3
				prompt.MaxActivationDistance = 12
				prompt.RequiresLineOfSight = false
				prompt.Parent = part
			end
			prompt.Triggered:Connect(function(player: Player)
				EventosRemotos.MostrarDialogoNPC:FireClient(player, {
					Nombre = "Maestro Tuerca",
					Titulo = "Mecánico del Barrio",
					Icono = "🔧",
					Mensaje = "¡Epa patrón! Aquí le tengo la bicicleta engrasada. Si junta los pesos, pase por la moto para que no se quede en las laderas.",
				})
				EventosRemotos.AbrirTiendaMejoras:FireClient(player, "Vehiculos")
			end)
		end
	end
end

-- Desmontar o invocar con la tecla V
EventosRemotos.SolicitarVehiculo.OnServerInvoke = function(player: Player)
	local character = player.Character
	if
		not character
		or not character:FindFirstChild("HumanoidRootPart")
		or not character:FindFirstChild("Humanoid")
	then
		return false, "Personaje no disponible"
	end

	local hrp = character.HumanoidRootPart :: BasePart
	local humanoid = character.Humanoid :: Humanoid

	-- Si el jugador ya está sentado en su vehículo activo: DESMONTAR Y GUARDAR
	local vehiculoActual = vehiculosActivos[player]
	if vehiculoActual and vehiculoActual.Parent then
		local asiento = vehiculoActual:FindFirstChildOfClass("VehicleSeat")
		if asiento and asiento.Occupant == humanoid then
			humanoid.Sit = false
			task.wait(0.05)
			hrp.CFrame = hrp.CFrame + (hrp.CFrame.RightVector * 3.5)
			vehiculoActual:Destroy()
			vehiculosActivos[player] = nil
			if conexionesVehiculos[player] then
				conexionesVehiculos[player]:Disconnect()
				conexionesVehiculos[player] = nil
			end
			return true, "Vehículo guardado en el morral"
		end
	end

	-- Si no está montado: INVOCAR ORIENTADO Y MONTAR AUTOMÁTICAMENTE
	local datos = GestorDatos.ObtenerDatos(player)
	local vehiculoEquipado = if datos then datos.VehiculoEquipado else "Vehiculo_Bicicleta"
	local lookDir = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z).Unit
	local pos = hrp.Position + (lookDir * 3.5)

	local modelo, asiento = aparecerVehiculo(player, vehiculoEquipado, pos, lookDir)
	if modelo and asiento then
		task.wait(0.05)
		asiento:Sit(humanoid)
		return true, string.format("¡%s montado!", vehiculoEquipado)
	end

	return false, "No se pudo invocar el vehículo"
end

Players.PlayerRemoving:Connect(function(player: Player)
	local v = vehiculosActivos[player]
	if v and v.Parent then
		v:Destroy()
	end
	vehiculosActivos[player] = nil
	if conexionesVehiculos[player] then
		conexionesVehiculos[player]:Disconnect()
		conexionesVehiculos[player] = nil
	end
end)

task.spawn(configurarSpawnBicicleta)
task.spawn(configurarMaestroTuerca)
print("El Patrón del Dulce: Sistema de Vehículos y Conducción Calibrado")
