local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer

type InfoNPC = {
	Modelo: Model,
	HRP: BasePart,
	Cabeza: BasePart?,
	BrazoDer: BasePart?,
	Cucharon: BasePart?,
	CFrameOriginalCabeza: CFrame?,
	CFrameOriginalBrazo: CFrame?,
	CFrameOriginalCucharon: CFrame?,
	OffsetRelativoCabeza: CFrame?,
	DesfaseTiempo: number,
}

local listaNPCs: { InfoNPC } = {}

local function registrarNPC(npc: Model)
	local hrp = npc:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end

	local cabeza = npc:FindFirstChild("Head") :: BasePart?
	local brazoDer = npc:FindFirstChild("BrazoDer") :: BasePart?
	local cucharon = npc:FindFirstChild("CucharonMadera") :: BasePart?

	local info: InfoNPC = {
		Modelo = npc,
		HRP = hrp,
		Cabeza = cabeza,
		BrazoDer = brazoDer,
		Cucharon = cucharon,
		CFrameOriginalCabeza = if cabeza then cabeza.CFrame else nil,
		CFrameOriginalBrazo = if brazoDer then brazoDer.CFrame else nil,
		CFrameOriginalCucharon = if cucharon then cucharon.CFrame else nil,
		OffsetRelativoCabeza = if cabeza then hrp.CFrame:ToObjectSpace(cabeza.CFrame) else nil,
		DesfaseTiempo = math.random() * math.pi * 2,
	}

	table.insert(listaNPCs, info)
end

local function iniciarAnimaciones()
	local mapa = Workspace:WaitForChild("Mapa", 10)
	if not mapa then
		return
	end
	local decoracion = mapa:WaitForChild("Decoracion", 10)
	if not decoracion then
		return
	end
	local npcsFolder = decoracion:WaitForChild("NPCs_Interactivos", 10)
	if not npcsFolder then
		return
	end

	for _, child in ipairs(npcsFolder:GetChildren()) do
		if child:IsA("Model") then
			registrarNPC(child)
		end
	end

	npcsFolder.ChildAdded:Connect(function(child)
		if child:IsA("Model") then
			registrarNPC(child)
		end
	end)

	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		local miChar = localPlayer.Character
		local miHRP = miChar and miChar:FindFirstChild("HumanoidRootPart") :: BasePart?
		local miPos = if miHRP then miHRP.Position else nil

		for _, info in ipairs(listaNPCs) do
			if not info.HRP or not info.HRP.Parent then
				continue
			end

			-- Respiración sutil en cabeza
			local respiracion = math.sin((t * 2.2) + info.DesfaseTiempo) * 0.04
			local rotacionCabeza = CFrame.identity

			-- Si el jugador está cerca, girar cabeza suavemente hacia él
			if miPos and info.Cabeza and info.OffsetRelativoCabeza then
				local dist = (miPos - info.HRP.Position).Magnitude
				if dist < 14 and dist > 1.5 then
					local dirAlJugador = (miPos - info.Cabeza.Position).Unit
					local lookAtLocal = info.HRP.CFrame:VectorToObjectSpace(dirAlJugador)
					local anguloY =
						math.clamp(-math.atan2(lookAtLocal.X, -lookAtLocal.Z), -0.7, 0.7)
					local anguloX = math.clamp(math.asin(lookAtLocal.Y), -0.3, 0.3)
					rotacionCabeza = CFrame.Angles(anguloX, anguloY, 0)
				end

				local baseCFrame = info.HRP.CFrame * info.OffsetRelativoCabeza
				info.Cabeza.CFrame = baseCFrame * CFrame.new(0, respiracion, 0) * rotacionCabeza
			end

			-- Animación de revolver melcocha para Doña Melcocha
			if info.Cucharon and info.BrazoDer and info.CFrameOriginalCucharon then
				local anguloRevolver = t * 3.5
				local offsetX = math.cos(anguloRevolver) * 0.25
				local offsetZ = math.sin(anguloRevolver) * 0.25
				local offsetStir =
					Vector3.new(offsetX, math.sin(anguloRevolver * 2) * 0.05, offsetZ)

				info.Cucharon.CFrame = info.CFrameOriginalCucharon
					* CFrame.new(offsetStir)
					* CFrame.Angles(
						math.sin(anguloRevolver) * 0.15,
						0,
						math.cos(anguloRevolver) * 0.15
					)
			end
		end
	end)
end

task.spawn(iniciarAnimaciones)
