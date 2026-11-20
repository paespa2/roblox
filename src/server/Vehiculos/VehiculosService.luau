--!strict
--[[
	VehiculosService.luau
	Servicio autoritativo del servidor para la gestión del ciclo de vida,
	físicas de conducción, aparición, montaje y desmontaje de vehículos.
	
	El Patrón del Dulce
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GestorDatos = require(script.Parent.Parent.GestorDatos)
local Datos = require(ReplicatedStorage.Shared.Datos)
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)
local ModelosVehiculos = require(script.Parent.ModelosVehiculos)

local VehiculosService = {}

local vehiculosActivos: { [Player]: Model } = {}
local conexionesVehiculos: { [Player]: RBXScriptConnection } = {}

-- Obtener punto de aparición por defecto
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

-- Configuración de actuadores y física de conducción autoritativa
function VehiculosService.ConfigurarFisicaConduccion(
	player: Player,
	modelo: Model,
	_infoVehiculo: any
)
	local chasis = modelo.PrimaryPart or modelo:FindFirstChild("Chasis") :: BasePart?
	local asiento = modelo:FindFirstChildOfClass("VehicleSeat")
	if not chasis or not asiento then
		return
	end

	-- Limpieza de actuadores legacy
	for _, viejo in ipairs({
		"DriveVelocity",
		"SteerVelocity",
		"VehicleDriveAttachment",
		"UprightStabilizer",
	}) do
		local f = chasis:FindFirstChild(viejo) or modelo:FindFirstChild(viejo, true)
		if f then
			f:Destroy()
		end
	end

	-- El asiento nunca debe colisionar con el avatar ni usar el skid-steer invertido nativo
	asiento.CanCollide = false
	asiento.MaxSpeed = 0
	asiento.Torque = 0
	asiento.TurnSpeed = 0

	-- Contrapeso inferior para anclar centro de masa
	local contrapeso = chasis:FindFirstChild("ContrapesoBajo") :: BasePart?
	if not contrapeso then
		contrapeso = Instance.new("Part")
		contrapeso.Name = "ContrapesoBajo"
		contrapeso.Size = Vector3.new(1.4, 0.4, 2.6)
		contrapeso.CFrame = chasis.CFrame * CFrame.new(0, -0.65, 0)
		contrapeso.Transparency = 1
		contrapeso.CanCollide = false
		contrapeso.Massless = false
		contrapeso.CustomPhysicalProperties = PhysicalProperties.new(4.0, 0.1, 0, 1, 1)
		contrapeso.Parent = chasis

		local weldContra = Instance.new("WeldConstraint")
		weldContra.Part0 = chasis
		weldContra.Part1 = contrapeso
		weldContra.Parent = chasis
	end

	-- Attachment principal para actuadores físicos
	local driveAtt = chasis:FindFirstChild("DriveAtt") :: Attachment?
	if not driveAtt then
		driveAtt = Instance.new("Attachment")
		driveAtt.Name = "DriveAtt"
		driveAtt.Axis = Vector3.new(1, 0, 0)
		driveAtt.SecondaryAxis = Vector3.new(0, 1, 0)
		driveAtt.Parent = chasis
	end

	-- Attachment vertical dedicado para alineación giroscópica
	local uprightAtt = chasis:FindFirstChild("UprightAtt") :: Attachment?
	if not uprightAtt then
		uprightAtt = Instance.new("Attachment")
		uprightAtt.Name = "UprightAtt"
		uprightAtt.Axis = Vector3.new(0, 1, 0)
		uprightAtt.SecondaryAxis = Vector3.new(0, 0, -1)
		uprightAtt.Parent = chasis
	end

	-- Vector de avance horizontal inicial
	local forwardInit = Vector3.new(chasis.CFrame.LookVector.X, 0, chasis.CFrame.LookVector.Z)
	if forwardInit.Magnitude > 0.01 then
		forwardInit = forwardInit.Unit
	else
		forwardInit = Vector3.new(0, 0, -1)
	end

	-- Actuador de propulsión longitudinal en modo Line (coordenadas World)
	local driveLV = chasis:FindFirstChild("DriveLV") :: LinearVelocity?
	if not driveLV then
		driveLV = Instance.new("LinearVelocity")
		driveLV.Name = "DriveLV"
		driveLV.Attachment0 = driveAtt
		driveLV.RelativeTo = Enum.ActuatorRelativeTo.World
		driveLV.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
		driveLV.LineDirection = forwardInit
		driveLV.MaxForce = 60000
		driveLV.LineVelocity = 0
		driveLV.Parent = chasis
	else
		driveLV.RelativeTo = Enum.ActuatorRelativeTo.World
		driveLV.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
		driveLV.LineDirection = forwardInit
		driveLV.MaxForce = 60000
	end

	-- Actuador de giro horizontal en eje Y del mundo
	local steerAV = chasis:FindFirstChild("SteerAV") :: AngularVelocity?
	if not steerAV then
		steerAV = Instance.new("AngularVelocity")
		steerAV.Name = "SteerAV"
		steerAV.Attachment0 = driveAtt
		steerAV.RelativeTo = Enum.ActuatorRelativeTo.World
		steerAV.MaxTorque = 65000
		steerAV.AngularVelocity = Vector3.zero
		steerAV.Parent = chasis
	else
		steerAV.RelativeTo = Enum.ActuatorRelativeTo.World
	end

	-- Estabilizador vertical giroscópico (PrimaryAxisParallel)
	local ao = chasis:FindFirstChild("EstabilizadorVertical") :: AlignOrientation?
	if not ao then
		ao = Instance.new("AlignOrientation")
		ao.Name = "EstabilizadorVertical"
		ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
		ao.Attachment0 = uprightAtt
		ao.AlignType = Enum.AlignType.PrimaryAxisParallel
		ao.PrimaryAxis = Vector3.new(0, 1, 0)
		ao.MaxTorque = 40000
		ao.Responsiveness = 35
		ao.ReactionTorqueEnabled = false
		ao.Parent = chasis
	end

	-- Configuración de colisiones y soldaduras obligatorias de todas las piezas
	for _, desc in ipairs(modelo:GetDescendants()) do
		if desc:IsA("BasePart") and desc ~= chasis and desc ~= asiento and desc ~= contrapeso then
			if desc.Name == "RuedaFisica" or desc.Name == "ColisionCentral" then
				desc.CanCollide = true
				desc.CustomPhysicalProperties = PhysicalProperties.new(1.0, 0.20, 0.0, 1, 1)
			else
				desc.CanCollide = false
				desc.CustomPhysicalProperties = PhysicalProperties.new(0.5, 0.05, 0.1, 1, 1)
			end

			-- Soldar obligatoriamente todas las piezas al chasis
			local yaUnido = false
			for _, w in ipairs(chasis:GetChildren()) do
				if w:IsA("WeldConstraint") and (w.Part1 == desc or w.Part0 == desc) then
					yaUnido = true
					break
				end
			end
			if not yaUnido then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = chasis
				weld.Part1 = desc
				weld.Parent = chasis
			end
		end
	end

	chasis.CanCollide = false
	chasis.CustomPhysicalProperties = PhysicalProperties.new(1.0, 0.2, 0.1, 1, 1)

	-- Asignar red al jugador para conducción local responsiva
	for _, part in ipairs(modelo:GetDescendants()) do
		if part:IsA("BasePart") then
			pcall(function()
				part:SetNetworkOwner(player)
			end)
		end
	end

	-- Monitorear ocupante del asiento
	if conexionesVehiculos[player] then
		conexionesVehiculos[player]:Disconnect()
		conexionesVehiculos[player] = nil
	end

	conexionesVehiculos[player] = asiento:GetPropertyChangedSignal("Occupant"):Connect(function()
		if not asiento.Occupant then
			pcall(function()
				chasis:SetNetworkOwner(nil)
			end)
		else
			pcall(function()
				chasis:SetNetworkOwner(player)
			end)
		end
	end)
end

-- Aparecer e inicializar vehículo para el jugador
function VehiculosService.AparecerVehiculo(
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
			modeloBase = ModelosVehiculos.CrearMotoFallback()
		else
			modeloBase = ModelosVehiculos.CrearBicicletaFallback()
		end
	end

	local posAparicion = posPersonalizada or obtenerPuntoAparicion()
	local dirAvance = lookDir or Vector3.new(0, 0, -1)
	if dirAvance.Magnitude > 0.01 then
		dirAvance = Vector3.new(dirAvance.X, 0, dirAvance.Z).Unit
	else
		dirAvance = Vector3.new(0, 0, -1)
	end

	-- Raycast para colocar el vehículo suavemente sobre el asfalto (+1.95 studs de despeje)
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
	local posFinal = if rayResult
		then rayResult.Position + Vector3.new(0, 1.95, 0)
		else posAparicion

	local cframeOrientado = CFrame.lookAt(posFinal, posFinal + dirAvance)
	modeloBase:PivotTo(cframeOrientado)
	modeloBase.Parent = Workspace
	vehiculosActivos[player] = modeloBase

	VehiculosService.ConfigurarFisicaConduccion(player, modeloBase, infoVehiculo)

	local asiento = modeloBase:FindFirstChildOfClass("VehicleSeat")
	return modeloBase, asiento
end

-- Desmontar vehículo del jugador y guardarlo
function VehiculosService.DesmontarVehiculo(player: Player): boolean
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChild("Humanoid") :: Humanoid?

	local vehiculoActual = vehiculosActivos[player]
	if vehiculoActual and vehiculoActual.Parent then
		if humanoid then
			humanoid.Sit = false
		end
		task.wait(0.05)
		if hrp then
			hrp.CFrame = hrp.CFrame + (hrp.CFrame.RightVector * 3.5) + Vector3.new(0, 0.8, 0)
		end
		vehiculoActual:Destroy()
		vehiculosActivos[player] = nil
		if conexionesVehiculos[player] then
			conexionesVehiculos[player]:Disconnect()
			conexionesVehiculos[player] = nil
		end
		return true
	end
	return false
end

function VehiculosService.ObtenerVehiculoActivo(player: Player): Model?
	return vehiculosActivos[player]
end

-- Configurar interacción con el Taller de la Cocina
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
				else "Vehiculo_Moto"

			local _, asiento =
				VehiculosService.AparecerVehiculo(player, vehiculoEquipado, pos, look)
			if asiento and hum then
				task.wait(0.1)
				asiento:Sit(hum)
			end
		end)
	end
end

-- Configurar NPC Maestro Tuerca
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

-- Inicialización del servicio
function VehiculosService.Iniciar()
	-- Evento Remoto para montar / desmontar (Tecla V)
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

		-- Si ya está montado: desmontar y guardar
		local vehiculoActual = vehiculosActivos[player]
		if vehiculoActual and vehiculoActual.Parent then
			local asiento = vehiculoActual:FindFirstChildOfClass("VehicleSeat")
			if asiento and asiento.Occupant == humanoid then
				VehiculosService.DesmontarVehiculo(player)
				return true, "Vehículo guardado en el morral"
			end
		end

		-- Si no está montado: invocar orientado y montar automáticamente
		local datos = GestorDatos.ObtenerDatos(player)
		local vehiculoEquipado = if datos then datos.VehiculoEquipado else "Vehiculo_Moto"
		local lookDir = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z).Unit
		local pos = hrp.Position + (lookDir * 3.5)

		local modelo, asiento =
			VehiculosService.AparecerVehiculo(player, vehiculoEquipado, pos, lookDir)
		if modelo and asiento then
			task.wait(0.05)
			asiento:Sit(humanoid)
			return true, string.format("¡%s montado!", vehiculoEquipado)
		end

		return false, "No se pudo invocar el vehículo"
	end

	-- Limpieza al desconectarse el jugador
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

	print("El Patrón del Dulce: VehiculosService Inicializado")
end

return VehiculosService
