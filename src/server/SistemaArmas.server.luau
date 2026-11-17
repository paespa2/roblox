local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local GestorDatos = require(script.Parent.GestorDatos)
local Datos = require(ReplicatedStorage.Shared.Datos)
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)

local ultimosDisparos: { [Player]: { [string]: number } } = {}

local function crearToolArma(idArma: string): Tool?
	local infoArma = Datos.Armas[idArma]
	if not infoArma then
		return nil
	end

	local tool = Instance.new("Tool")
	tool.Name = infoArma.Nombre
	tool.ToolTip =
		string.format("%s (Usa %s como munición)", infoArma.Nombre, infoArma.DulceMunicion)
	tool.CanBeDropped = false
	tool:SetAttribute("IdArma", idArma)
	tool:SetAttribute("CadenciaSegundos", infoArma.CadenciaSegundos or 0.8)

	if idArma == "Arma_CaucheraGomitas" then
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
	elseif idArma == "Arma_PistolaCrema" then
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(0.5, 0.8, 1.2)
		handle.Color = Color3.fromRGB(240, 240, 250)
		handle.Material = Enum.Material.SmoothPlastic
		handle.CanCollide = false
		handle.Parent = tool

		local boquilla = Instance.new("Part")
		boquilla.Name = "Boquilla"
		boquilla.Size = Vector3.new(0.4, 0.4, 0.8)
		boquilla.Color = Color3.fromRGB(100, 220, 255)
		boquilla.Material = Enum.Material.Neon
		boquilla.CanCollide = false
		boquilla.Position = handle.Position + Vector3.new(0, 0.2, -0.9)
		boquilla.Parent = tool

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = boquilla
		weld.Parent = handle
	else
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(0.5, 0.8, 1.0)
		handle.Color = Color3.fromRGB(200, 150, 220)
		handle.Material = Enum.Material.SmoothPlastic
		handle.CanCollide = false
		handle.Parent = tool
	end

	return tool
end

local function entregarArmas(player: Player)
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then
		return
	end

	local datos = GestorDatos.ObtenerDatos(player)
	local armasDesbloqueadas = (datos and datos.ArmasDesbloqueadas)
		or { ["Arma_CaucheraGomitas"] = true }

	for idArma, desbloqueada in pairs(armasDesbloqueadas) do
		if desbloqueada and Datos.Armas[idArma] then
			local info = Datos.Armas[idArma]
			local tieneEnMano = player.Character and player.Character:FindFirstChild(info.Nombre)
			local tieneEnMochila = backpack:FindFirstChild(info.Nombre)
			if not tieneEnMano and not tieneEnMochila then
				local tool = crearToolArma(idArma)
				if tool then
					tool.Parent = backpack
				end
			end
		end
	end
end

local function configurarStarterPack()
	local starterPack = game:GetService("StarterPack")
	local existente = starterPack:FindFirstChild("Cauchera de Gomitas")
	if not existente then
		local tool = crearToolArma("Arma_CaucheraGomitas")
		if tool then
			tool.Parent = starterPack
		end
	end
end

EventosRemotos.DispararArma.OnServerInvoke = function(
	player: Player,
	idArma: string,
	direccion: any
)
	if typeof(idArma) ~= "string" or not Datos.Armas[idArma] then
		return false, "Arma no reconocida"
	end
	if typeof(direccion) ~= "Vector3" then
		return false, "Dirección inválida"
	end

	local infoArma = Datos.Armas[idArma]
	local character = player.Character
	if not character or not character:FindFirstChild("Head") then
		return false, "Personaje no disponible"
	end

	local datosJugador = GestorDatos.ObtenerDatos(player)
	if not datosJugador then
		return false, "Datos de jugador no encontrados"
	end

	-- Verificar cadencia
	local ahora = os.clock()
	local cadencia = infoArma.CadenciaSegundos or 0.8
	if not ultimosDisparos[player] then
		ultimosDisparos[player] = {}
	end
	local ultimo = ultimosDisparos[player][idArma] or 0
	if ahora - ultimo < (cadencia - 0.05) then
		return false, "Esperando recarga"
	end
	ultimosDisparos[player][idArma] = ahora

	-- Verificar munición: Requiere DulceMunicion (con fallback a Dulce_Bombon para Cauchera)
	local municionId = infoArma.DulceMunicion
	local gasto = infoArma.GastoPorDisparo or 1
	local cantActual = datosJugador.Inventario[municionId] or 0

	local municionUsada = nil
	if cantActual >= gasto then
		municionUsada = municionId
	elseif
		idArma == "Arma_CaucheraGomitas"
		and (datosJugador.Inventario["Dulce_Bombon"] or 0) >= gasto
	then
		municionUsada = "Dulce_Bombon"
	end

	if not municionUsada then
		return false,
			string.format(
				"¡Sin munición! Necesitas %d dulce(s) (%s) para disparar.",
				gasto,
				municionId
			)
	end

	GestorDatos.QuitarDulce(player, municionUsada, gasto)

	-- Generar calor por disparo de arma (+20 pts por cauchera / combate según Santiago)
	local calorDisparo = Datos.Persecucion.CalorPorAccion.DisparoCauchera or 20
	local puntosCalor, nuevasEstrellas = GestorDatos.AgregarCalor(player, calorDisparo)
	EventosRemotos.EstrellasActualizadas:FireClient(player, {
		Estrellas = nuevasEstrellas,
		Enfriando = false,
		ProgresoEnfriamiento = 0,
		PuntosCalor = puntosCalor,
	})

	-- Crear proyectil dulce
	local velocidad = infoArma.VelocidadProyectil or 80
	local alcance = infoArma.AlcanceStuds or 45
	local tiempoVida = math.clamp(alcance / velocidad, 0.4, 4.0)

	local origen = character.Head.Position + (direccion.Unit * 2)
	local proyectil = Instance.new("Part")
	proyectil.Name = "ProyectilDulce_" .. idArma
	proyectil.Shape = Enum.PartType.Ball
	proyectil.Size = Vector3.new(0.8, 0.8, 0.8)
	proyectil.Position = origen

	if idArma == "Arma_PistolaCrema" then
		proyectil.Color = Color3.fromRGB(255, 255, 245)
		proyectil.Material = Enum.Material.SmoothPlastic
	elseif municionUsada == "Dulce_Gomita" then
		proyectil.Color = Color3.fromRGB(255, 60, 140)
		proyectil.Material = Enum.Material.Neon
	else
		proyectil.Color = Color3.fromRGB(240, 120, 40)
		proyectil.Material = Enum.Material.Neon
	end

	proyectil.CanCollide = false
	proyectil.AssemblyLinearVelocity = direccion.Unit * velocidad
	proyectil.Parent = Workspace

	local light = Instance.new("PointLight")
	light.Color = proyectil.Color
	light.Range = 10
	light.Brightness = 2
	light.Parent = proyectil

	Debris:AddItem(proyectil, tiempoVida + 0.3)

	-- Detección de impacto
	proyectil.Touched:Connect(function(hit)
		if hit:IsDescendantOf(character) then
			return
		end

		proyectil.AssemblyLinearVelocity = Vector3.zero
		proyectil.Transparency = 1
		proyectil.CanTouch = false

		local splat = Instance.new("ParticleEmitter")
		splat.Color = ColorSequence.new(proyectil.Color)
		splat.Size = NumberSequence.new(0.7, 0.1)
		splat.Lifetime = NumberRange.new(0.3, 0.7)
		splat.Rate = 0
		splat.Speed = NumberRange.new(5, 14)
		splat.Parent = proyectil
		splat:Emit(18)

		-- Efecto de empalagamiento contra Retenes
		local retenes = Workspace:FindFirstChild("Puntos")
			and Workspace.Puntos:FindFirstChild("Retenes")
		if retenes then
			for _, reten in ipairs(retenes:GetChildren()) do
				if
					reten:IsA("BasePart")
					and (reten.Position - proyectil.Position).Magnitude < 16
				then
					reten:SetAttribute("Aturdido", true)
					local sirena = reten:FindFirstChild("SirenaLuz") :: PointLight?
					if sirena then
						sirena.Enabled = false
					end
					task.delay(infoArma.Duracion, function()
						reten:SetAttribute("Aturdido", nil)
						if sirena then
							sirena.Enabled = true
						end
					end)
					print(
						string.format(
							"El Patrón del Dulce: %s empalagó el retén %s (%s, %.1fs)",
							player.Name,
							reten.Name,
							infoArma.Efecto,
							infoArma.Duracion
						)
					)
				end
			end
		end

		-- Efecto contra Agente Dental NPC
		local mapa = Workspace:FindFirstChild("Mapa")
		local decoracion = mapa and mapa:FindFirstChild("Decoracion")
		local npcs = decoracion and decoracion:FindFirstChild("NPCs_Interactivos")
		if npcs then
			local agente = npcs:FindFirstChild("Personaje_AgenteDental")
			if agente and (agente:GetPivot().Position - proyectil.Position).Magnitude < 18 then
				agente:SetAttribute("Aturdido", true)
				local bbg = agente:FindFirstChildWhichIsA("BillboardGui", true)
				local lbl = bbg and bbg:FindFirstChildWhichIsA("TextLabel", true)
				local textoAnterior = lbl and lbl.Text
				if lbl then
					lbl.Text = string.format("😵 ¡EMPALAGADO! (%s) 🍬", infoArma.Efecto)
				end
				task.delay(infoArma.Duracion, function()
					agente:SetAttribute("Aturdido", nil)
					if lbl and textoAnterior then
						lbl.Text = textoAnterior
					end
				end)
				print(
					string.format(
						"El Patrón del Dulce: ¡Agente Dental aturdido por %s con %s!",
						player.Name,
						infoArma.Nombre
					)
				)
			end
		end

		task.delay(0.7, function()
			proyectil:Destroy()
		end)
	end)

	return true, "¡Disparo de dulce efectuado!"
end

local function conectarJugador(player: Player)
	player.CharacterAdded:Connect(function()
		task.wait(0.3)
		entregarArmas(player)
	end)
	if player.Character then
		task.spawn(entregarArmas, player)
	end
end

Players.PlayerAdded:Connect(conectarJugador)
Players.PlayerRemoving:Connect(function(player: Player)
	ultimosDisparos[player] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(conectarJugador, player)
end
task.spawn(configurarStarterPack)

print("El Patrón del Dulce: Sistema de Dulce-Armas y Combate inicializado")
