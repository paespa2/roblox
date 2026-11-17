local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)

local VELOCIDAD_NORMAL = 16
local VELOCIDAD_SPRINT = 24
local VELOCIDAD_SOBRECARGA = 12

local estaSprintando = false
local tieneSobrecarga = false
local cantidadCarga = 0
local capacidadMorral = 20

local function obtenerHumanoid(): Humanoid?
	local char = localPlayer.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function actualizarVelocidad()
	local hum = obtenerHumanoid()
	if not hum or hum.Health <= 0 or hum.Sit then
		return
	end

	local targetSpeed = VELOCIDAD_NORMAL
	if tieneSobrecarga then
		targetSpeed = if estaSprintando then 16 else VELOCIDAD_SOBRECARGA
	elseif estaSprintando then
		targetSpeed = VELOCIDAD_SPRINT
	end

	hum.WalkSpeed = targetSpeed

	if camera then
		local targetFov = if estaSprintando and hum.MoveDirection.Magnitude > 0.1 then 78 else 70
		TweenService
			:Create(camera, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				FieldOfView = targetFov,
			})
			:Play()
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		estaSprintando = true
		actualizarVelocidad()
	end
end)

UserInputService.InputEnded:Connect(function(input, _gameProcessed)
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		estaSprintando = false
		actualizarVelocidad()
	end
end)

-- Actualizar carga con los datos recibidos
EventosRemotos.DatosActualizados.OnClientEvent:Connect(function(datos)
	if datos and datos.Inventario then
		local total = 0
		for _, cant in pairs(datos.Inventario) do
			total += cant
		end
		cantidadCarga = total

		-- Obtener capacidad del morral actual
		local cap = 20
		if datos.MejorasCompradas then
			if datos.MejorasCompradas["Mejora_Morral_Capacidad_3"] then
				cap = 60
			elseif datos.MejorasCompradas["Mejora_Morral_Capacidad_2"] then
				cap = 40
			end
		end
		capacidadMorral = cap
		tieneSobrecarga = (cantidadCarga > capacidadMorral)
		actualizarVelocidad()
	end
end)

local function enPersonajeAgregado(character: Model)
	local hum = character:WaitForChild("Humanoid", 5) :: Humanoid?
	if hum then
		hum:GetPropertyChangedSignal("Sit"):Connect(function()
			if not hum.Sit then
				actualizarVelocidad()
			end
		end)
		hum:GetPropertyChangedSignal("MoveDirection"):Connect(function()
			if estaSprintando and camera then
				local targetFov = if hum.MoveDirection.Magnitude > 0.1 then 78 else 70
				TweenService:Create(
					camera,
					TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						FieldOfView = targetFov,
					}
				):Play()
			end
		end)
	end
	actualizarVelocidad()
end

if localPlayer.Character then
	enPersonajeAgregado(localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(enPersonajeAgregado)
