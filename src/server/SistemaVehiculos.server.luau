local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GestorDatos = require(script.Parent.GestorDatos)
local Datos = require(ReplicatedStorage.Shared.Datos)

local vehiculosActivos: { [Player]: Model } = {}

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

	local asiento = Instance.new("VehicleSeat")
	asiento.Name = "AsientoConductor"
	asiento.Size = Vector3.new(2, 1, 4)
	asiento.Color = Color3.fromRGB(220, 80, 50)
	asiento.MaxSpeed = Datos.Vehiculos.Vehiculo_Bicicleta.VelocidadMax or 16
	asiento.Torque = 15
	asiento.TurnSpeed = 2
	asiento.Parent = modelo
	modelo.PrimaryPart = asiento

	local manubrio = Instance.new("Part")
	manubrio.Name = "Manubrio"
	manubrio.Size = Vector3.new(3, 0.4, 0.4)
	manubrio.Position = asiento.Position + Vector3.new(0, 1, -1.8)
	manubrio.Color = Color3.fromRGB(50, 50, 50)
	manubrio.Parent = modelo

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = asiento
	weld.Part1 = manubrio
	weld.Parent = asiento

	return modelo
end

local function aparecerVehiculo(player: Player, idVehiculo: string): Model?
	local vehiculoExistente = vehiculosActivos[player]
	if vehiculoExistente and vehiculoExistente.Parent then
		vehiculoExistente:Destroy()
	end

	local infoVehiculo = Datos.Vehiculos[idVehiculo]
	if not infoVehiculo then
		return nil
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
		modeloBase = crearModeloBicicletaFallback()
	end

	local posAparicion = obtenerPuntoAparicion()
	modeloBase:PivotTo(CFrame.new(posAparicion))
	modeloBase.Parent = Workspace
	vehiculosActivos[player] = modeloBase

	local asiento = modeloBase:FindFirstChildOfClass("VehicleSeat")
	if asiento then
		asiento.MaxSpeed = infoVehiculo.VelocidadMax

		-- Ajustar velocidad si el jugador está sobrecargado
		asiento:GetPropertyChangedSignal("Occupant"):Connect(function()
			local humanoid = asiento.Occupant
			if humanoid then
				local jugadorSentado = Players:GetPlayerFromCharacter(humanoid.Parent)
				if jugadorSentado then
					local datosJugador = GestorDatos.ObtenerDatos(jugadorSentado)
					if datosJugador then
						local totalCarga = 0
						for _, cant in pairs(datosJugador.Inventario) do
							totalCarga += cant
						end

						if totalCarga > infoVehiculo.CapacidadCarga then
							-- Penalización de velocidad por sobrecarga (-25%)
							asiento.MaxSpeed = math.floor(infoVehiculo.VelocidadMax * 0.75)
							print(
								string.format(
									"El Patrón del Dulce: %s lleva sobrecarga (%d/%d). Velocidad reducida a %d.",
									jugadorSentado.Name,
									totalCarga,
									infoVehiculo.CapacidadCarga,
									asiento.MaxSpeed
								)
							)
						else
							asiento.MaxSpeed = infoVehiculo.VelocidadMax
						end
					end
				end
			end
		end)
	end

	return modeloBase
end

-- Configurar puesto de recogida de bicicleta al salir de la cocina
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
			prompt.ActionText = "Tomar Bicicleta"
			prompt.HoldDuration = 0.5
			prompt.MaxActivationDistance = 14
			prompt.RequiresLineOfSight = false
			prompt.Parent = puntoCocina
		end

		prompt.Triggered:Connect(function(player: Player)
			local datosJugador = GestorDatos.ObtenerDatos(player)
			local vehiculoEquipado = if datosJugador
				then datosJugador.VehiculoEquipado
				else "Vehiculo_Bicicleta"
			aparecerVehiculo(player, vehiculoEquipado)
			print(
				string.format(
					"El Patrón del Dulce: %s obtuvo su %s",
					player.Name,
					vehiculoEquipado
				)
			)
		end)
	end
end

Players.PlayerRemoving:Connect(function(player: Player)
	local v = vehiculosActivos[player]
	if v and v.Parent then
		v:Destroy()
	end
	vehiculosActivos[player] = nil
end)

task.spawn(configurarSpawnBicicleta)
print("El Patrón del Dulce: Sistema de Vehículos y Carga inicializado")
