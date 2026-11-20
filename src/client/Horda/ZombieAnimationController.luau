--!strict
--[[
	ZombieAnimationController.luau
	Controlador de animaciones de zombis en el cliente.
	Usa contadores replicados (sin comparar relojes cliente-servidor),
	Stepped para Motor6D.Transform, suavizado Lerp, distance culling y Animator.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Datos = require(ReplicatedStorage.Shared.Datos)
local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)

local DistanciaCulling = (
	Datos.Zombis
	and Datos.Zombis.General
	and Datos.Zombis.General.DistanciaCullingAnimacion
) or 140

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
	VarianteId: string,
	RootJoint: Motor6D?,
	Neck: Motor6D?,
	LeftShoulder: Motor6D?,
	RightShoulder: Motor6D?,
	LeftHip: Motor6D?,
	RightHip: Motor6D?,
	Pistas: PistasAnimacion,
	Desfase: number,
	UltimoContadorAtaque: number,
	UltimoContadorGolpe: number,
	HoraLocalAtaque: number,
	HoraLocalGolpe: number,
	InicioMuerte: number?,
	PistaActivaLocomocion: AnimationTrack?,
}

local _zombisRegistrados: { [Model]: DatosAnimZombi } = {}
local _conexionesModelo: { [Model]: RBXScriptConnection } = {}
local _carpetasVinculadas: { [Instance]: boolean } = {}

local function cargarPista(
	animator: Animator,
	carpeta: Folder,
	nombre: string,
	looped: boolean,
	prioridad: Enum.AnimationPriority
): AnimationTrack?
	local anim = carpeta:FindFirstChild(nombre)
	if anim and anim:IsA("Animation") and anim.AnimationId ~= "" then
		local ok, track = pcall(function()
			return animator:LoadAnimation(anim)
		end)
		if ok and track then
			track.Looped = looped
			track.Priority = prioridad
			return track
		end
	end
	return nil
end

local function detenerTodasLasPistas(pistas: PistasAnimacion)
	for _, track in pairs(pistas) do
		if track and track.IsPlaying then
			track:Stop(0.1)
		end
	end
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
		pistas.Idle = cargarPista(animator, carpetaAnims, "Idle", true, Enum.AnimationPriority.Idle)
		pistas.Walk =
			cargarPista(animator, carpetaAnims, "Walk", true, Enum.AnimationPriority.Movement)
		pistas.Run =
			cargarPista(animator, carpetaAnims, "Run", true, Enum.AnimationPriority.Movement)
		pistas.Attack =
			cargarPista(animator, carpetaAnims, "Attack", false, Enum.AnimationPriority.Action)
		pistas.Hit =
			cargarPista(animator, carpetaAnims, "Hit", false, Enum.AnimationPriority.Action)
		pistas.Death =
			cargarPista(animator, carpetaAnims, "Death", false, Enum.AnimationPriority.Action2)
	end

	_zombisRegistrados[modelo] = {
		Modelo = modelo,
		HRP = hrp,
		Humanoid = hum,
		VarianteId = tostring(modelo:GetAttribute("VarianteId") or "CaminantePodrido"),
		RootJoint = hrp:FindFirstChild("RootJoint") :: Motor6D?,
		Neck = torso:FindFirstChild("Neck") :: Motor6D?,
		LeftShoulder = torso:FindFirstChild("Left Shoulder") :: Motor6D?,
		RightShoulder = torso:FindFirstChild("Right Shoulder") :: Motor6D?,
		LeftHip = torso:FindFirstChild("Left Hip") :: Motor6D?,
		RightHip = torso:FindFirstChild("Right Hip") :: Motor6D?,
		Pistas = pistas,
		Desfase = math.random() * math.pi * 2,
		UltimoContadorAtaque = tonumber(modelo:GetAttribute("ContadorAtaque")) or 0,
		UltimoContadorGolpe = tonumber(modelo:GetAttribute("ContadorGolpe")) or 0,
		HoraLocalAtaque = -10,
		HoraLocalGolpe = -10,
		InicioMuerte = nil,
		PistaActivaLocomocion = nil,
	}

	_conexionesModelo[modelo] = modelo.AncestryChanged:Connect(function(_, nuevoPadre)
		if not nuevoPadre then
			local reg = _zombisRegistrados[modelo]
			if reg then
				detenerTodasLasPistas(reg.Pistas)
				_zombisRegistrados[modelo] = nil
			end
			local conn = _conexionesModelo[modelo]
			if conn then
				conn:Disconnect()
				_conexionesModelo[modelo] = nil
			end
		end
	end)
end

local function cambiarPistaLocomocion(
	datos: DatosAnimZombi,
	nuevaPista: AnimationTrack?,
	velRatio: number
)
	if datos.PistaActivaLocomocion ~= nuevaPista then
		if datos.PistaActivaLocomocion and datos.PistaActivaLocomocion.IsPlaying then
			datos.PistaActivaLocomocion:Stop(0.15)
		end
		datos.PistaActivaLocomocion = nuevaPista
		if nuevaPista and not nuevaPista.IsPlaying then
			nuevaPista:Play(0.15)
		end
	end
	if nuevaPista and nuevaPista.IsPlaying then
		nuevaPista:AdjustSpeed(math.clamp(velRatio, 0.7, 1.8))
	end
end

local function suavizarJoint(motor: Motor6D?, objetivo: CFrame, alpha: number)
	if motor then
		motor.Transform = motor.Transform:Lerp(objetivo, alpha)
	end
end

local function animarZombi(datos: DatosAnimZombi, t: number, dt: number, camPos: Vector3?)
	if camPos and (datos.HRP.Position - camPos).Magnitude > DistanciaCulling then
		return
	end

	local modelo = datos.Modelo
	local estado = tostring(modelo:GetAttribute("EstadoIA") or "Idle")
	local velBase = tonumber(modelo:GetAttribute("VelocidadBase")) or 10
	local velActual = (datos.HRP.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude
	local alpha = math.clamp(dt * 14, 0.12, 1.0)

	local cntAtaque = tonumber(modelo:GetAttribute("ContadorAtaque")) or 0
	local cntGolpe = tonumber(modelo:GetAttribute("ContadorGolpe")) or 0

	-- 1. Estado Muerto (Death)
	if estado == "Dead" then
		if not datos.InicioMuerte then
			datos.InicioMuerte = t
			cambiarPistaLocomocion(datos, nil, 1)
			detenerTodasLasPistas(datos.Pistas)
			if datos.Pistas.Death then
				datos.Pistas.Death:Play(0.08)
			end
		end
		if datos.Pistas.Death then
			return
		end
		local progreso = math.clamp((t - (datos.InicioMuerte :: number)) / 0.45, 0, 1)
		local anguloCaida = math.rad(88 * progreso)
		suavizarJoint(
			datos.RootJoint,
			CFrame.new(0, -2.2 * progreso, 0.8 * progreso) * CFrame.Angles(-anguloCaida, 0, 0),
			alpha
		)
		suavizarJoint(
			datos.LeftShoulder,
			CFrame.Angles(math.rad(30 * progreso), 0, math.rad(-25 * progreso)),
			alpha
		)
		suavizarJoint(
			datos.RightShoulder,
			CFrame.Angles(math.rad(40 * progreso), 0, math.rad(25 * progreso)),
			alpha
		)
		suavizarJoint(
			datos.LeftHip,
			CFrame.Angles(math.rad(15 * progreso), 0, math.rad(-8 * progreso)),
			alpha
		)
		suavizarJoint(
			datos.RightHip,
			CFrame.Angles(math.rad(10 * progreso), 0, math.rad(8 * progreso)),
			alpha
		)
		return
	end

	-- 2. Reacción de Impacto (Hit / Stunned)
	if cntGolpe > datos.UltimoContadorGolpe then
		datos.UltimoContadorGolpe = cntGolpe
		datos.HoraLocalGolpe = t
		if datos.Pistas.Hit then
			datos.Pistas.Hit:Play(0.05)
		end
	end

	local tiempoDesdeGolpe = t - datos.HoraLocalGolpe
	if estado == "Stunned" or tiempoDesdeGolpe < 0.25 then
		if datos.Pistas.Hit and datos.Pistas.Hit.IsPlaying then
			return
		end
		local sacudida = math.sin(tiempoDesdeGolpe * 28) * 0.22
		suavizarJoint(datos.RootJoint, CFrame.Angles(math.rad(16), sacudida, 0), alpha)
		suavizarJoint(datos.Neck, CFrame.Angles(math.rad(18), -sacudida, 0), alpha)
		return
	end

	-- 3. Ataque cuerpo a cuerpo (Attack)
	if cntAtaque > datos.UltimoContadorAtaque then
		datos.UltimoContadorAtaque = cntAtaque
		datos.HoraLocalAtaque = t
		if datos.Pistas.Attack then
			datos.Pistas.Attack:Play(0.05)
		end
	end

	local tiempoDesdeAtaque = t - datos.HoraLocalAtaque
	if estado == "Attacking" or tiempoDesdeAtaque < 0.45 then
		if datos.Pistas.Attack and datos.Pistas.Attack.IsPlaying then
			return
		end
		local fase = math.clamp(tiempoDesdeAtaque / 0.45, 0, 1)
		local zarpazo = math.sin(fase * math.pi)
		suavizarJoint(datos.RootJoint, CFrame.Angles(math.rad(-22 * zarpazo), 0, 0), alpha)
		suavizarJoint(
			datos.LeftShoulder,
			CFrame.Angles(math.rad(135 - 95 * zarpazo), 0, math.rad(-10)),
			alpha
		)
		suavizarJoint(
			datos.RightShoulder,
			CFrame.Angles(math.rad(135 - 95 * zarpazo), 0, math.rad(10)),
			alpha
		)
		return
	end

	-- 4. Locomoción acoplada a velocidad real (Idle / Walk / Run)
	local enMovimiento = velActual > 0.8
	local corriendo = enMovimiento and (velActual >= 12.5 or (velBase >= 14.5 and velActual > 5.0))
	local velRatio = velActual / math.max(velBase, 1)

	if not enMovimiento then
		if datos.Pistas.Idle then
			cambiarPistaLocomocion(datos, datos.Pistas.Idle, 1)
			return
		end
		local vaiven = math.sin(t * 2.2 + datos.Desfase)
		suavizarJoint(
			datos.RootJoint,
			CFrame.new(0, vaiven * 0.04, 0) * CFrame.Angles(math.rad(-4), 0, vaiven * 0.03),
			alpha
		)
		suavizarJoint(
			datos.Neck,
			CFrame.Angles(math.rad(6), math.sin(t * 1.1 + datos.Desfase) * 0.18, 0),
			alpha
		)
		suavizarJoint(
			datos.LeftShoulder,
			CFrame.Angles(math.rad(25 + vaiven * 4), 0, math.rad(-5)),
			alpha
		)
		suavizarJoint(
			datos.RightShoulder,
			CFrame.Angles(math.rad(22 - vaiven * 4), 0, math.rad(5)),
			alpha
		)
		suavizarJoint(datos.LeftHip, CFrame.identity, alpha)
		suavizarJoint(datos.RightHip, CFrame.identity, alpha)
	elseif corriendo then
		if datos.Pistas.Run then
			cambiarPistaLocomocion(datos, datos.Pistas.Run, velRatio)
			return
		end
		local esCorredor = datos.VarianteId == "CorredorRabioso"
		local freq = (if esCorredor then 0.82 else 0.72) * velActual
		local ciclo = (t * freq) + datos.Desfase
		local paso = math.sin(ciclo)
		local inclinacion = if esCorredor then math.rad(-20) else math.rad(-14)
		suavizarJoint(
			datos.RootJoint,
			CFrame.new(0, math.abs(paso) * 0.16, 0) * CFrame.Angles(inclinacion, paso * 0.08, 0),
			alpha
		)
		suavizarJoint(datos.Neck, CFrame.Angles(math.rad(12), -paso * 0.08, 0), alpha)
		suavizarJoint(
			datos.LeftShoulder,
			CFrame.Angles(math.rad(96) + paso * 0.36, 0, math.rad(-8)),
			alpha
		)
		suavizarJoint(
			datos.RightShoulder,
			CFrame.Angles(math.rad(96) - paso * 0.36, 0, math.rad(8)),
			alpha
		)
		suavizarJoint(datos.LeftHip, CFrame.Angles(-paso * 0.70, 0, 0), alpha)
		suavizarJoint(datos.RightHip, CFrame.Angles(paso * 0.70, 0, 0), alpha)
	else
		if datos.Pistas.Walk then
			cambiarPistaLocomocion(datos, datos.Pistas.Walk, velRatio)
			return
		end
		local esBruto = datos.VarianteId == "BrutoCaramelo"
		local freq = math.clamp(velActual * 0.58, 3.2, 8.5)
		local ciclo = (t * freq) + datos.Desfase
		local paso = math.sin(ciclo)
		local ampBrazo = if esBruto then 0.12 else 0.18
		local ampPierna = if esBruto then 0.40 else 0.50
		suavizarJoint(
			datos.RootJoint,
			CFrame.new(0, math.abs(paso) * 0.08, 0)
				* CFrame.Angles(math.rad(-7), 0, math.cos(ciclo) * 0.06),
			alpha
		)
		suavizarJoint(
			datos.Neck,
			CFrame.Angles(math.rad(6), math.sin(ciclo * 0.5) * 0.14, math.rad(8)),
			alpha
		)
		suavizarJoint(
			datos.LeftShoulder,
			CFrame.Angles(math.rad(76) + paso * ampBrazo, 0, math.rad(-6)),
			alpha
		)
		suavizarJoint(
			datos.RightShoulder,
			CFrame.Angles(math.rad(72) - paso * ampBrazo, 0, math.rad(6)),
			alpha
		)
		suavizarJoint(datos.LeftHip, CFrame.Angles(-paso * ampPierna, 0, 0), alpha)
		suavizarJoint(datos.RightHip, CFrame.Angles(paso * ampPierna, 0, 0), alpha)
	end
end

local function obtenerColoresVisuales(varianteId: string?): (Color3, Color3)
	if varianteId == "ZombiLava" then
		return Color3.fromRGB(255, 130, 30), Color3.fromRGB(200, 45, 20)
	elseif varianteId == "ZombiHielo" then
		return Color3.fromRGB(85, 255, 255), Color3.fromRGB(0, 170, 255)
	elseif varianteId == "ZombiToxico" or varianteId == "AzucaradoToxico" then
		return Color3.fromRGB(113, 255, 61), Color3.fromRGB(50, 170, 40)
	end
	return Color3.fromRGB(160, 240, 120), Color3.fromRGB(255, 110, 140)
end

local function manejarEventoVisual(info: { Tipo: string, Posicion: Vector3?, VarianteId: string? })
	if (info.Tipo == "Impacto" or info.Tipo == "Aparicion") and info.Posicion then
		local cam = Workspace.CurrentCamera
		if cam and (info.Posicion - cam.CFrame.Position).Magnitude > DistanciaCulling then
			return
		end

		local marca = Instance.new("Part")
		marca.Size = Vector3.new(0.4, 0.4, 0.4)
		marca.Position = info.Posicion
		marca.Transparency = 1
		marca.Anchored = true
		marca.CanCollide = false
		marca.CanTouch = false
		marca.Parent = Workspace

		local c1, c2 = obtenerColoresVisuales(info.VarianteId)
		local chispas = Instance.new("ParticleEmitter")
		chispas.Color = ColorSequence.new(c1, c2)
		chispas.Size = NumberSequence.new(0.45, 0.05)
		chispas.Lifetime = NumberRange.new(0.25, 0.45)
		chispas.Speed = NumberRange.new(5, 12)
		chispas.Rate = 0
		chispas.Parent = marca
		chispas:Emit(if info.Tipo == "Aparicion" then 14 else 9)

		task.delay(0.7, function()
			if marca.Parent then
				marca:Destroy()
			end
		end)
	end
end

local function vincularCarpetaZombis(carpetaZombis: Instance)
	if _carpetasVinculadas[carpetaZombis] then
		return
	end
	_carpetasVinculadas[carpetaZombis] = true
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

local function vincularSistema(sistema: Instance)
	local carpetaZombis = sistema:FindFirstChild("Zombis")
	if carpetaZombis then
		vincularCarpetaZombis(carpetaZombis)
	end
	sistema.ChildAdded:Connect(function(child)
		if child.Name == "Zombis" then
			vincularCarpetaZombis(child)
		end
	end)
end

function ZombieAnimationController.Iniciar()
	local sistemaExistente = Workspace:FindFirstChild("HordaSistema")
	if sistemaExistente then
		vincularSistema(sistemaExistente)
	end
	Workspace.ChildAdded:Connect(function(child)
		if child.Name == "HordaSistema" then
			vincularSistema(child)
		end
	end)

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

	RunService.Stepped:Connect(function(_, dt: number)
		local t = os.clock()
		local cam = Workspace.CurrentCamera
		local camPos = if cam then cam.CFrame.Position else nil
		for _, datos in pairs(_zombisRegistrados) do
			if datos.Modelo.Parent and datos.HRP.Parent then
				animarZombi(datos, t, dt, camPos)
			end
		end
	end)
end

return ZombieAnimationController
