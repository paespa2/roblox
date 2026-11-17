local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local function iniciarAnimacionHalos()
	local mapa = Workspace:WaitForChild("Mapa", 10)
	if not mapa then
		return
	end
	local decoracion = mapa:WaitForChild("Decoracion", 10)
	if not decoracion then
		return
	end
	local arosFolder = decoracion:WaitForChild("ArosInteractivos", 10)
	if not arosFolder then
		return
	end

	local listaHalos: { { Part: BasePart, BaseCFrame: CFrame, AlturaBase: number, Desfase: number } } =
		{}

	for i, halo in ipairs(arosFolder:GetChildren()) do
		if halo:IsA("BasePart") then
			halo.CanCollide = false
			table.insert(listaHalos, {
				Part = halo,
				BaseCFrame = halo.CFrame,
				AlturaBase = halo.Position.Y,
				Desfase = i * 0.7,
			})
		end
	end

	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for _, info in ipairs(listaHalos) do
			if info.Part and info.Part.Parent then
				local flotacion = math.sin((t * 2) + info.Desfase) * 0.4
				local rotacion = CFrame.Angles(0, t * 1.2, 0)
				local posOriginal = info.BaseCFrame.Position
				local nuevaPos =
					Vector3.new(posOriginal.X, info.AlturaBase + flotacion, posOriginal.Z)
				info.Part.CFrame = CFrame.new(nuevaPos) * rotacion
			end
		end
	end)
end

task.spawn(iniciarAnimacionHalos)
