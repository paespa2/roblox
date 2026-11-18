--!strict
--[[
	ZombieAnimationController.luau
	Controlador de animaciones de zombis en el cliente.
	Integra Animator + AnimationTracks cuando existan AnimationIds válidos
	en Datos.Zombis.Animaciones.Zombi, y ejecuta animación procedural por
	Motor6D.Transform cuando los AnimationIds aún estén pendientes.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)

local ZombieAnimationController = {}

type PistasAnimacion = {
	Idle: AnimationTrack?,
	Walk: AnimationTrack?,
	Run: AnimationTrack?,
	Attack: AnimationTrack?,
	Hit: AnimationTrack?,
	Death: AnimationTrack?,
}

type DatosAnimZombi = {
	Modelo: Model,
	HRP: BasePart,
	Humanoid: Humanoid,
	RootJoint: Motor6D?,
	Neck: Motor6D?,
	LeftShoulder: Motor6D?,
	RightShoulder: Motor6D?,
	LeftHip: Motor6D?,
	RightHip: Motor6D?,
	Pistas: PistasAnimacion,
	Desfase: number,
	UltimoAtaqueVisto: number,
	UltimoGolpeVisto: number,
	InicioMuerte: number?,
	PistaActivaLocomocion: AnimationTrack?,
}

local _zombisRegistrados: { [Model]: DatosAnimZombi } = {}
local _conexionesModelo: { [Model]: RBXScriptConnection } = {}

local function cargarPista(
	animator: Animator,
	carpeta: Folder,
	nombre: string,
	looped: boolean
): AnimationTrack?
	local anim = carpeta:FindFirstChild(nombre)
	if anim and anim:IsA("Animation") and anim.AnimationId ~= "" then
		local ok, track = pcall(function()
			return animator:LoadAnimation(anim)
		end)
		if ok and track then
			track.Looped = looped
			return track
		end
	end
	return nil
end

local function registrarZombi(modelo: Model)
	if _zombisRegistrados[modelo] then
		return
	end

	local hrp = modelo:WaitForChild("HumanoidRootPart", 4)
	local torso = modelo:WaitForChild("Torso", 4)
	local hum = modelo:WaitForChild("Humanoid", 4)
	if not hrp or not hrp:IsA("BasePart") or not torso or not hum or not hum:IsA("Humanoid") then
		return
	end

	local pistas: PistasAnimacion = {}
	local animator = hum:FindFirstChildOfClass("Animator")
	local carpetaAnims = hum:FindFirstChild("Animaciones")
	if animator and carpetaAnims and carpetaAnims:IsA("Folder") then
		pistas.Idle = cargarPista(animator, carpetaAnims, "Idle", true)
		pistas.Walk = cargarPista(animator, carpetaAnims, "Walk", true)
		pistas.Run = cargarPista(animator, carpetaAnims, "Run", true)
		pistas.Attack = cargarPista(animator, carpetaAnims, "Attack", false)
		pistas.Hit = cargarPista(animator, carpetaAnims, "Hit", false)
		pistas.Death = cargarPista(animator, carpetaAnims, "Death", false)
	end

	_zombisRegistrados[modelo] = {
		Modelo = modelo,
		HRP = hrp,
		Humanoid = hum,
		RootJoint = hrp:FindFirstChild("RootJoint") :: Motor6D?,
		Neck = torso:FindFirstChild("Neck") :: Motor6D?,
		LeftShoulder = torso:FindFirstChild("Left Shoulder") :: Motor6D?,
		RightShoulder = torso:FindFirstChild("Right Shoulder") :: Motor6D?,
		LeftHip = torso:FindFirstChild("Left Hip") :: Motor6D?,
		RightHip = torso:FindFirstChild("Right Hip") :: Motor6D?,
		Pistas = pistas,
		Desfase = math.random() * math.pi * 2,
		UltimoAtaqueVisto = 0,
		UltimoGolpeVisto = 0,
		InicioMuerte = nil,
		PistaActivaLocomocion = nil,
	}

	_conexionesModelo[modelo] = modelo.AncestryChanged:Connect(function(_, nuevoPadre)
		if not nuevoPadre then
			_zombisRegistrados[modelo] = nil
			local conn = _conexionesModelo[modelo]
			if conn then
				conn:Disconnect()
				_conexionesModelo[modelo] = nil
			end
		end
	end)
end

local function cambiarPistaLocomocion(datos: DatosAnimZombi, nuevaPista: AnimationTrack?)
	if datos.PistaActivaLocomocion == nuevaPista then
		return
	end
	if datos.PistaActivaLocomocion and datos.PistaActivaLocomocion.IsPlaying then
		datos.PistaActivaLocomocion:Stop(0.15)
	end
	datos.PistaActivaLocomocion = nuevaPista
	if nuevaPista and not nuevaPista.IsPlaying then
		nuevaPista:Play(0.15)
	end
end

local function animarZombi(datos: DatosAnimZombi, t: number)
	local modelo = datos.Modelo
	local estado = tostring(modelo:GetAttribute("EstadoIA") or "Idle")
	local velBase = tonumber(modelo:GetAttribute("VelocidadBase")) or 10
	local velActual = (datos.HRP.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude

	local ultimoAtaque = tonumber(modelo:GetAttribute("UltimoAtaque")) or 0
	local ultimoGolpe = tonumber(modelo:GetAttribute("UltimoGolpe")) or 0

	-- 1. Estado Muerto (Death)
	if estado == "Dead" then
		if not datos.InicioMuerte then
			datos.InicioMuerte = t
			cambiarPistaLocomocion(datos, nil)
			if datos.Pistas.Death then
				datos.Pistas.Death:Play(0.1)
			end
		end
		if datos.Pistas.Death then
			return
		end
		local progreso = math.clamp((t - (datos.InicioMuerte :: number)) / 0.45, 0, 1)
		local anguloCaida = math.rad(88 * progreso)
		if datos.RootJoint then
			datos.RootJoint.Transform = CFrame.new(0, -2.2 * progreso, 0.8 * progreso)
				* CFrame.Angles(-anguloCaida, 0, 0)
		end
		if datos.LeftShoulder then
			datos.LeftShoulder.Transform =
				CFrame.Angles(math.rad(30 * progreso), 0, math.rad(-25 * progreso))
		end
		if datos.RightShoulder then
			datos.RightShoulder.Transform =
				CFrame.Angles(math.rad(40 * progreso), 0, math.rad(25 * progreso))
		end
		return
	end

	-- 2. Reacción de Impacto (Hit / Stunned)
	if ultimoGolpe > datos.UltimoGolpeVisto then
		datos.UltimoGolpeVisto = ultimoGolpe
		if datos.Pistas.Hit then
			datos.Pistas.Hit:Play(0.05)
		end
	end

	if estado == "Stunned" or (t - datos.UltimoGolpeVisto) < 0.25 then
		if datos.Pistas.Hit and datos.Pistas.Hit.IsPlaying then
			return
		end
		local sacudida = math.sin((t - datos.UltimoGolpeVisto) * 28) * 0.22
		if datos.RootJoint then
			datos.RootJoint.Transform = CFrame.Angles(math.rad(16), sacudida, 0)
		end
		if datos.Neck then
			datos.Neck.Transform = CFrame.Angles(math.rad(18), -sacudida, 0)
		end
		return
	end

	-- 3. Ataque cuerpo a cuerpo (Attack)
	if ultimoAtaque > datos.UltimoAtaqueVisto then
		datos.UltimoAtaqueVisto = ultimoAtaque
		if datos.Pistas.Attack then
			datos.Pistas.Attack:Play(0.05)
		end
	end

	local tiempoDesdeAtaque = t - datos.UltimoAtaqueVisto
	if estado == "Attacking" or tiempoDesdeAtaque < 0.45 then
		if datos.Pistas.Attack and datos.Pistas.Attack.IsPlaying then
			return
		end
		local fase = math.clamp(tiempoDesdeAtaque / 0.45, 0, 1)
		local zarpazo = math.sin(fase * math.pi)
		if datos.RootJoint then
			datos.RootJoint.Transform = CFrame.Angles(math.rad(-22 * zarpazo), 0, 0)
		end
		if datos.LeftShoulder then
			datos.LeftShoulder.Transform =
				CFrame.Angles(math.rad(135 - 95 * zarpazo), 0, math.rad(-10))
		end
		if datos.RightShoulder then
			datos.RightShoulder.Transform =
				CFrame.Angles(math.rad(135 - 95 * zarpazo), 0, math.rad(10))
		end
		return
	end

	-- 4. Locomoción (Idle / Walk / Run)
	local enMovimiento = velActual > 1.2
	local corriendo = enMovimiento and (velBase >= 13.0 or velActual >= 12.5)

	if not enMovimiento then
		if datos.Pistas.Idle then
			cambiarPistaLocomocion(datos, datos.Pistas.Idle)
			return
		end
		local vaiven = math.sin(t * 2.2 + datos.Desfase)
		if datos.RootJoint then
			datos.RootJoint.Transform = CFrame.new(0, vaiven * 0.04, 0)
				* CFrame.Angles(math.rad(-4), 0, vaiven * 0.03)
		end
		if datos.Neck then
			datos.Neck.Transform =
				CFrame.Angles(math.rad(6), math.sin(t * 1.1 + datos.Desfase) * 0.18, 0)
		end
		if datos.LeftShoulder then
			datos.LeftShoulder.Transform = CFrame.Angles(math.rad(25 + vaiven * 4), 0, math.rad(-5))
		end
		if datos.RightShoulder then
			datos.RightShoulder.Transform = CFrame.Angles(math.rad(22 - vaiven * 4), 0, math.rad(5))
		end
		if datos.LeftHip then
			datos.LeftHip.Transform = CFrame.identity
		end
		if datos.RightHip then
			datos.RightHip.Transform = CFrame.identity
		end
	elseif corriendo then
		if datos.Pistas.Run then
			cambiarPistaLocomocion(datos, datos.Pistas.Run)
			return
		end
		local ciclo = (t * 10.5) + datos.Desfase
		local paso = math.sin(ciclo)
		if datos.RootJoint then
			datos.RootJoint.Transform = CFrame.new(0, math.abs(paso) * 0.16, 0)
				* CFrame.Angles(math.rad(-14), paso * 0.08, 0)
		end
		if datos.Neck then
			datos.Neck.Transform = CFrame.Angles(math.rad(12), -paso * 0.08, 0)
		end
		if datos.LeftShoulder then
			datos.LeftShoulder.Transform =
				CFrame.Angles(math.rad(92) + paso * 0.35, 0, math.rad(-8))
		end
		if datos.RightShoulder then
			datos.RightShoulder.Transform =
				CFrame.Angles(math.rad(92) - paso * 0.35, 0, math.rad(8))
		end
		if datos.LeftHip then
			datos.LeftHip.Transform = CFrame.Angles(-paso * 0.72, 0, 0)
		end
		if datos.RightHip then
			datos.RightHip.Transform = CFrame.Angles(paso * 0.72, 0, 0)
		end
	else
		if datos.Pistas.Walk then
			cambiarPistaLocomocion(datos, datos.Pistas.Walk)
			return
		end
		local ciclo = (t * 6.2) + datos.Desfase
		local paso = math.sin(ciclo)
		if datos.RootJoint then
			datos.RootJoint.Transform = CFrame.new(0, math.abs(paso) * 0.09, 0)
				* CFrame.Angles(math.rad(-6), 0, math.cos(ciclo) * 0.06)
		end
		if datos.Neck then
			datos.Neck.Transform =
				CFrame.Angles(math.rad(6), math.sin(ciclo * 0.5) * 0.14, math.rad(8))
		end
		if datos.LeftShoulder then
			datos.LeftShoulder.Transform =
				CFrame.Angles(math.rad(76) + paso * 0.16, 0, math.rad(-6))
		end
		if datos.RightShoulder then
			datos.RightShoulder.Transform =
				CFrame.Angles(math.rad(72) - paso * 0.16, 0, math.rad(6))
		end
		if datos.LeftHip then
			datos.LeftHip.Transform = CFrame.Angles(-paso * 0.48, 0, 0)
		end
		if datos.RightHip then
			datos.RightHip.Transform = CFrame.Angles(paso * 0.48, 0, 0)
		end
	end
end

local function manejarEventoVisual(info: { Tipo: string, Posicion: Vector3? })
	if info.Tipo == "Impacto" and info.Posicion then
		local marca = Instance.new("Part")
		marca.Size = Vector3.new(0.4, 0.4, 0.4)
		marca.Position = info.Posicion
		marca.Transparency = 1
		marca.Anchored = true
		marca.CanCollide = false
		marca.CanTouch = false
		marca.Parent = Workspace

		local chispas = Instance.new("ParticleEmitter")
		chispas.Color =
			ColorSequence.new(Color3.fromRGB(160, 240, 120), Color3.fromRGB(255, 110, 140))
		chispas.Size = NumberSequence.new(0.45, 0.05)
		chispas.Lifetime = NumberRange.new(0.25, 0.45)
		chispas.Speed = NumberRange.new(6, 14)
		chispas.Rate = 0
		chispas.Parent = marca
		chispas:Emit(10)

		task.delay(0.7, function()
			if marca.Parent then
				marca:Destroy()
			end
		end)
	end
end

function ZombieAnimationController.Iniciar()
	local sistema = Workspace:WaitForChild("HordaSistema", 10)
	if sistema then
		local carpetaZombis = sistema:WaitForChild("Zombis", 10)
		if carpetaZombis then
			for _, child in ipairs(carpetaZombis:GetChildren()) do
				if child:IsA("Model") then
					task.spawn(registrarZombi, child)
				end
			end
			carpetaZombis.ChildAdded:Connect(function(child)
				if child:IsA("Model") then
					task.spawn(registrarZombi, child)
				end
			end)
		end
	end

	local evVisual = EventosRemotos.ZombieEventoVisual
	if not evVisual then
		local f = ReplicatedStorage:WaitForChild("EventosRemotos", 10)
		evVisual = f and f:WaitForChild("ZombieEventoVisual", 10) :: RemoteEvent?
	end
	if evVisual and evVisual:IsA("RemoteEvent") then
		evVisual.OnClientEvent:Connect(manejarEventoVisual)
	else
		warn("[ZombieAnimationController] No se pudo conectar ZombieEventoVisual RemoteEvent")
	end

	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for _, datos in pairs(_zombisRegistrados) do
			if datos.Modelo.Parent and datos.HRP.Parent then
				animarZombi(datos, t)
			end
		end
	end)
end

return ZombieAnimationController
