--!strict
local RunService = game:GetService("RunService")
local ConstructorR6 = {}

local EXPRESIONES_ROSTRO: { [string]: string } = {
	Sonriente = "rbxasset://textures/face.png",
	Alegre = "rbxassetid://7074764",
	Guino = "rbxassetid://7074893",
	Determinado = "rbxassetid://7074836",
	Sorpresa = "rbxassetid://7074786",
	Amigable = "rbxassetid://209712379",
}
local LISTA_EXPRESIONES = { "Sonriente", "Alegre", "Guino", "Determinado", "Amigable" }

local function crearParteR6(nombre: string, tamano: Vector3, color: Color3, parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = nombre
	p.Size = tamano
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = false
	p.CanCollide = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function crearMotor(
	nombre: string,
	p0: BasePart,
	p1: BasePart,
	c0: CFrame,
	c1: CFrame
): Motor6D
	local m = Instance.new("Motor6D")
	m.Name = nombre
	m.Part0 = p0
	m.Part1 = p1
	m.C0 = c0
	m.C1 = c1
	m.Parent = p0
	return m
end

function ConstructorR6.CrearManiquiR6(cfg: any)
	local modelo = Instance.new("Model")
	modelo.Name = cfg.Nombre

	local skinColor = cfg.ColorPiel or Color3.fromRGB(238, 198, 164)
	local cfBase = CFrame.new(cfg.Posicion + Vector3.new(0, 3.0, 0))
		* CFrame.Angles(0, math.rad(cfg.RotacionY or 0), 0)

	local hrp = crearParteR6("HumanoidRootPart", Vector3.new(2, 2, 1), cfg.ColorRopa, modelo)
	hrp.Transparency = 1
	hrp.Anchored = true
	hrp.CFrame = cfBase
	modelo.PrimaryPart = hrp

	local torso = crearParteR6("Torso", Vector3.new(2, 2, 1), cfg.ColorRopa, modelo)
	torso.CFrame = cfBase

	local head = crearParteR6("Head", Vector3.new(1.25, 1.25, 1.25), skinColor, modelo)
	head.CFrame = cfBase * CFrame.new(0, 1.5, 0)
	local headMesh = Instance.new("SpecialMesh")
	headMesh.MeshType = Enum.MeshType.Head
	headMesh.Scale = Vector3.new(1.25, 1.25, 1.25)
	headMesh.Parent = head

	local faceDecal = Instance.new("Decal")
	faceDecal.Name = "face"
	faceDecal.Face = Enum.NormalId.Front
	local exprKey = cfg.Expresion or LISTA_EXPRESIONES[math.random(1, #LISTA_EXPRESIONES)]
	faceDecal.Texture = EXPRESIONES_ROSTRO[exprKey] or EXPRESIONES_ROSTRO.Sonriente
	faceDecal.Parent = head

	local leftArm = crearParteR6("Left Arm", Vector3.new(1, 2, 1), cfg.ColorRopa, modelo)
	local rightArm = crearParteR6("Right Arm", Vector3.new(1, 2, 1), cfg.ColorRopa, modelo)
	local leftLeg = crearParteR6("Left Leg", Vector3.new(1, 2, 1), cfg.ColorPantalon, modelo)
	local rightLeg = crearParteR6("Right Leg", Vector3.new(1, 2, 1), cfg.ColorPantalon, modelo)

	if cfg.SombreroColor then
		local ala =
			crearParteR6("SombreroAla", Vector3.new(2.3, 0.18, 2.3), cfg.SombreroColor, modelo)
		ala.Material = Enum.Material.Fabric
		local copa =
			crearParteR6("SombreroCopa", Vector3.new(1.3, 0.65, 1.3), cfg.SombreroColor, modelo)
		copa.Material = Enum.Material.Fabric
		local w1 = Instance.new("Weld")
		w1.Part0 = head
		w1.Part1 = ala
		w1.C0 = CFrame.new(0, 0.58, 0)
		w1.Parent = head
		local w2 = Instance.new("Weld")
		w2.Part0 = head
		w2.Part1 = copa
		w2.C0 = CFrame.new(0, 0.92, 0)
		w2.Parent = head
	end

	crearMotor("RootJoint", hrp, torso, CFrame.new(0, 0, 0), CFrame.new(0, 0, 0))
	local neck = crearMotor("Neck", torso, head, CFrame.new(0, 1.0, 0), CFrame.new(0, -0.5, 0))
	local leftShoulder =
		crearMotor("Left Shoulder", torso, leftArm, CFrame.new(-1.5, 0.5, 0), CFrame.new(0, 0.5, 0))
	local rightShoulder = crearMotor(
		"Right Shoulder",
		torso,
		rightArm,
		CFrame.new(1.5, 0.5, 0),
		CFrame.new(0, 0.5, 0)
	)
	local leftHip =
		crearMotor("Left Hip", torso, leftLeg, CFrame.new(-0.5, -1.0, 0), CFrame.new(0, 1.0, 0))
	local rightHip =
		crearMotor("Right Hip", torso, rightLeg, CFrame.new(0.5, -1.0, 0), CFrame.new(0, 1.0, 0))

	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R6
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.EvaluateStateMachine = false
	hum.Parent = modelo

	modelo.Parent = cfg.Parent

	local isMoving = false
	local phase = math.random() * math.pi * 2
	local conn
	conn = RunService.Heartbeat:Connect(function(dt: number)
		if not modelo.Parent then
			if conn then
				conn:Disconnect()
			end
			return
		end
		if isMoving then
			phase += dt * 7.5
			local swing = math.sin(phase) * 0.65
			leftShoulder.Transform = CFrame.Angles(swing, 0, 0)
			rightShoulder.Transform = CFrame.Angles(-swing, 0, 0)
			leftHip.Transform = CFrame.Angles(-swing * 0.9, 0, 0)
			rightHip.Transform = CFrame.Angles(swing * 0.9, 0, 0)
			neck.Transform = CFrame.Angles(0, math.sin(phase * 0.5) * 0.08, 0)
		else
			phase += dt * 2.0
			local breath = math.sin(phase) * 0.06
			local lookYaw = math.sin(phase * 0.6) * 0.22
			leftShoulder.Transform = CFrame.Angles(breath, 0, -0.05)
			rightShoulder.Transform = CFrame.Angles(-breath, 0, 0.05)
			leftHip.Transform = CFrame.identity
			rightHip.Transform = CFrame.identity
			neck.Transform = CFrame.Angles(breath * 0.5, lookYaw, 0)
		end
	end)

	return {
		Modelo = modelo,
		HRP = hrp,
		Torso = torso,
		Head = head,
		Humanoid = hum,
		SetMoving = function(moving: boolean)
			isMoving = moving
		end,
	}
end

return ConstructorR6
