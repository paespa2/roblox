local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local GestorDatos = require(script.Parent.GestorDatos)
local Datos = require(ReplicatedStorage.Shared.Datos)
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)

local function crearToolCauchera(): Tool
	local tool = Instance.new("Tool")
	tool.Name = "Cauchera de Gomitas"
	tool.ToolTip = "Dispara gomitas dulces para aturdir a la Policía Dental"
	tool.CanBeDropped = false

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.6, 1.2, 0.4)
	handle.Color = Color3.fromRGB(140, 85, 45)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Parent = tool

	local elastico = Instance.new("Part")
	elastico.Name = "Elastico"
	elastico.Size = Vector3.new(0.5, 0.2, 0.5)
	elastico.Color = Color3.fromRGB(240, 50, 70)
	elastico.Material = Enum.Material.SmoothPlastic
	elastico.CanCollide = false
	elastico.Position = handle.Position + Vector3.new(0, 0.5, 0)
	elastico.Parent = tool

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = elastico
	weld.Parent = handle

	return tool
end

local function entregarCauchera(player: Player)
	local backpack = player:FindFirstChild("Backpack")
	if backpack and not backpack:FindFirstChild("Cauchera de Gomitas") then
		local character = player.Character
		if not (character and character:FindFirstChild("Cauchera de Gomitas")) then
			local cauchera = crearToolCauchera()
			cauchera.Parent = backpack
		end
	end
end

local function configurarStarterPack()
	local starterPack = game:GetService("StarterPack")
	local existente = starterPack:FindFirstChild("Cauchera de Gomitas")
	if not existente then
		local tool = crearToolCauchera()
		tool.Parent = starterPack
	end
end

EventosRemotos.DispararArma.OnServerInvoke = function(
	player: Player,
	idArma: string,
	direccion: any
)
	if idArma ~= "Arma_CaucheraGomitas" then
		return false, "Arma no reconocida"
	end
	if typeof(direccion) ~= "Vector3" then
		return false, "Dirección inválida"
	end

	local infoArma = Datos.Armas[idArma]
	if not infoArma then
		return false, "Datos de arma no encontrados"
	end

	local character = player.Character
	if not character or not character:FindFirstChild("Head") then
		return false, "Personaje no disponible"
	end

	local datosJugador = GestorDatos.ObtenerDatos(player)
	if not datosJugador then
		return false, "Datos de jugador no encontrados"
	end

	-- Verificar munición: Requiere Dulce_Gomita (con fallback a Dulce_Bombon si no tiene gomita)
	local municionId = infoArma.DulceMunicion
	local tieneGomita = (datosJugador.Inventario[municionId] or 0) >= infoArma.GastoPorDisparo
	local tieneBombon = (datosJugador.Inventario["Dulce_Bombon"] or 0) >= infoArma.GastoPorDisparo

	local municionUsada = nil
	if tieneGomita then
		municionUsada = municionId
	elseif tieneBombon then
		municionUsada = "Dulce_Bombon"
	end

	if not municionUsada then
		return false,
			string.format(
				"¡Sin munición! Necesitas al menos 1 dulce (%s) para disparar.",
				municionId
			)
	end

	GestorDatos.QuitarDulce(player, municionUsada, infoArma.GastoPorDisparo)

	-- Crear proyectil gomita dulce
	local origen = character.Head.Position + (direccion.Unit * 2)
	local proyectil = Instance.new("Part")
	proyectil.Name = "ProyectilGomita"
	proyectil.Shape = Enum.PartType.Ball
	proyectil.Size = Vector3.new(0.8, 0.8, 0.8)
	proyectil.Position = origen
	proyectil.Color = if municionUsada == "Dulce_Gomita"
		then Color3.fromRGB(255, 60, 140)
		else Color3.fromRGB(240, 120, 40)
	proyectil.Material = Enum.Material.Neon
	proyectil.CanCollide = false
	proyectil.AssemblyLinearVelocity = direccion.Unit * 85
	proyectil.Parent = Workspace

	local light = Instance.new("PointLight")
	light.Color = proyectil.Color
	light.Range = 10
	light.Brightness = 2
	light.Parent = proyectil

	Debris:AddItem(proyectil, 3.5)

	-- Detección de impacto
	proyectil.Touched:Connect(function(hit)
		if hit:IsDescendantOf(character) then
			return
		end

		-- Efecto de impacto
		proyectil.AssemblyLinearVelocity = Vector3.zero
		proyectil.Transparency = 1
		proyectil.CanTouch = false

		local splat = Instance.new("ParticleEmitter")
		splat.Color = ColorSequence.new(proyectil.Color)
		splat.Size = NumberSequence.new(0.6, 0.1)
		splat.Lifetime = NumberRange.new(0.3, 0.6)
		splat.Rate = 0
		splat.Speed = NumberRange.new(5, 12)
		splat.Parent = proyectil
		splat:Emit(15)

		-- Aturdir retén o patrulla dental si impacta cerca
		local retenes = Workspace:FindFirstChild("Puntos")
			and Workspace.Puntos:FindFirstChild("Retenes")
		if retenes then
			for _, reten in ipairs(retenes:GetChildren()) do
				if
					reten:IsA("BasePart")
					and (reten.Position - proyectil.Position).Magnitude < 14
				then
					local sirena = reten:FindFirstChild("SirenaLuz") :: PointLight?
					if sirena then
						sirena.Enabled = false
						task.delay(infoArma.Duracion, function()
							sirena.Enabled = true
						end)
					end
					print(
						string.format(
							"El Patrón del Dulce: %s empalagó el retén %s con su %s",
							player.Name,
							reten.Name,
							infoArma.Nombre
						)
					)
				end
			end
		end

		task.delay(0.6, function()
			proyectil:Destroy()
		end)
	end)

	return true, "¡Disparo de gomita efectuado!"
end

local function conectarJugador(player: Player)
	player.CharacterAdded:Connect(function()
		task.wait(0.3)
		entregarCauchera(player)
	end)
	if player.Character then
		task.spawn(entregarCauchera, player)
	end
end

Players.PlayerAdded:Connect(conectarJugador)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(conectarJugador, player)
end
task.spawn(configurarStarterPack)

print("El Patrón del Dulce: Sistema de Dulce-Armas (Cauchera de Gomitas) inicializado")
