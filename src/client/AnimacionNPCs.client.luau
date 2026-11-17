local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer

type InfoNPC = {
	Modelo: Model,
	HRP: BasePart,
	Cabeza: BasePart?,
	BrazoDer: BasePart?,
	BrazoIzq: BasePart?,
	Cucharon: BasePart?,
	Cola: BasePart?,
	CFrameOriginalCabeza: CFrame?,
	CFrameOriginalBrazo: CFrame?,
	CFrameOriginalBrazoIzq: CFrame?,
	CFrameOriginalCucharon: CFrame?,
	CFrameOriginalCola: CFrame?,
	OffsetRelativoCabeza: CFrame?,
	OffsetRelativoBrazoDer: CFrame?,
	OffsetRelativoBrazoIzq: CFrame?,
	DesfaseTiempo: number,
	Tipo: string, -- "Tendero", "Policia", "Estudiante", "Animal", "General"
}

local listaNPCs: { InfoNPC } = {}

local function detectarTipoNPC(nombre: string): string
	local n = string.lower(nombre)
	if string.find(n, "tendero") or string.find(n, "donabaco") or string.find(n, "kiosko") then
		return "Tendero"
	elseif string.find(n, "agente") or string.find(n, "policia") then
		return "Policia"
	elseif
		string.find(n, "mateo")
		or string.find(n, "valentina")
		or string.find(n, "camilo")
		or string.find(n, "mariana")
	then
		return "Estudiante"
	elseif string.find(n, "firulais") or string.find(n, "gallina") or string.find(n, "animal") then
		return "Animal"
	end
	return "General"
end

local function registrarNPC(npc: Model)
	local hrp = npc:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		hrp = npc.PrimaryPart or npc:FindFirstChildWhichIsA("BasePart")
	end
	if not hrp then
		return
	end

	local cabeza = npc:FindFirstChild("Head") :: BasePart?
	local brazoDer = (npc:FindFirstChild("BrazoDer") or npc:FindFirstChild("RightUpperArm"))
		:: BasePart?
	local brazoIzq = (npc:FindFirstChild("BrazoIzq") or npc:FindFirstChild("LeftUpperArm"))
		:: BasePart?
	local cucharon = npc:FindFirstChild("CucharonMadera") :: BasePart?
	local cola = npc:FindFirstChild("Cola") :: BasePart?

	local info: InfoNPC = {
		Modelo = npc,
		HRP = hrp,
		Cabeza = cabeza,
		BrazoDer = brazoDer,
		BrazoIzq = brazoIzq,
		Cucharon = cucharon,
		Cola = cola,
		CFrameOriginalCabeza = if cabeza then cabeza.CFrame else nil,
		CFrameOriginalBrazo = if brazoDer then brazoDer.CFrame else nil,
		CFrameOriginalBrazoIzq = if brazoIzq then brazoIzq.CFrame else nil,
		CFrameOriginalCucharon = if cucharon then cucharon.CFrame else nil,
		CFrameOriginalCola = if cola then cola.CFrame else nil,
		OffsetRelativoCabeza = if cabeza then hrp.CFrame:ToObjectSpace(cabeza.CFrame) else nil,
		OffsetRelativoBrazoDer = if brazoDer then hrp.CFrame:ToObjectSpace(brazoDer.CFrame) else nil,
		OffsetRelativoBrazoIzq = if brazoIzq then hrp.CFrame:ToObjectSpace(brazoIzq.CFrame) else nil,
		DesfaseTiempo = math.random() * math.pi * 2,
		Tipo = detectarTipoNPC(npc.Name),
	}

	table.insert(listaNPCs, info)
end

local function escanearCarpeta(carpeta: Instance)
	for _, child in ipairs(carpeta:GetChildren()) do
		if child:IsA("Model") then
			registrarNPC(child)
		end
	end

	carpeta.ChildAdded:Connect(function(child)
		if child:IsA("Model") then
			task.wait(0.2)
			registrarNPC(child)
		end
	end)
end

local function iniciarAnimaciones()
	local mapa = Workspace:WaitForChild("Mapa", 10)
	if not mapa then
		return
	end
	local decoracion = mapa:WaitForChild("Decoracion", 10)
	if decoracion then
		local npcsFolder = decoracion:WaitForChild("NPCs_Interactivos", 10)
		if npcsFolder then
			escanearCarpeta(npcsFolder)
		end
		local animalesFolder = decoracion:FindFirstChild("Animales")
		if animalesFolder then
			escanearCarpeta(animalesFolder)
		end
	end

	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		local miChar = localPlayer.Character
		local miHRP = miChar and miChar:FindFirstChild("HumanoidRootPart") :: BasePart?
		local miPos = if miHRP then miHRP.Position else nil

		for _, info in ipairs(listaNPCs) do
			if not info.HRP or not info.HRP.Parent then
				continue
			end

			-- 1. Respiración sutil en cabeza
			local respiracion = math.sin((t * 2.2) + info.DesfaseTiempo) * 0.035
			local rotacionCabeza = CFrame.identity

			local dist = if miPos then (miPos - info.HRP.Position).Magnitude else 999
			local jugadorCerca = (dist < 14 and dist > 1.2)

			-- 2. Seguimiento de mirada al jugador
			if miPos and info.Cabeza and info.OffsetRelativoCabeza then
				if jugadorCerca then
					local dirAlJugador = (miPos - info.Cabeza.Position).Unit
					local lookAtLocal = info.HRP.CFrame:VectorToObjectSpace(dirAlJugador)
					local anguloY =
						math.clamp(-math.atan2(lookAtLocal.X, -lookAtLocal.Z), -0.75, 0.75)
					local anguloX = math.clamp(math.asin(lookAtLocal.Y), -0.35, 0.35)
					rotacionCabeza = CFrame.Angles(anguloX, anguloY, 0)
				end

				local baseCFrame = info.HRP.CFrame * info.OffsetRelativoCabeza
				info.Cabeza.CFrame = baseCFrame * CFrame.new(0, respiracion, 0) * rotacionCabeza
			end

			-- 3. Animación de Saludo para Tenderos al acercarse el jugador
			if
				info.Tipo == "Tendero"
				and info.BrazoDer
				and info.OffsetRelativoBrazoDer
				and not info.Cucharon
			then
				local baseBrazo = info.HRP.CFrame * info.OffsetRelativoBrazoDer
				if jugadorCerca then
					-- Saludo con la mano levantada ondeando amistosamente
					local ola = math.sin(t * 7) * 0.25
					info.BrazoDer.CFrame = baseBrazo
						* CFrame.new(0, 0.4, -0.2)
						* CFrame.Angles(math.rad(120), 0, math.rad(-25) + ola)
				else
					-- Brazo en reposo con respiración
					info.BrazoDer.CFrame = baseBrazo * CFrame.new(0, respiracion * 0.5, 0)
				end
			end

			-- 4. Animación de Doña Melcocha (revolver paila de melcocha)
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

			-- 5. Animación de Cola para Firulais (perrito criollo)
			if info.Cola and info.CFrameOriginalCola then
				local frecuenciaCola = if jugadorCerca then 14 else 4
				local anguloCola = math.sin((t * frecuenciaCola) + info.DesfaseTiempo) * 0.4
				info.Cola.CFrame = info.CFrameOriginalCola * CFrame.Angles(0, anguloCola, 0)
			end

			-- 6. Animación de picoteo para gallinas
			if string.find(string.lower(info.Modelo.Name), "gallina") and info.Cabeza then
				local picoteo = math.max(0, math.sin((t * 2.8) + info.DesfaseTiempo)) * 0.18
				if info.OffsetRelativoCabeza then
					local baseCFrame = info.HRP.CFrame * info.OffsetRelativoCabeza
					info.Cabeza.CFrame = baseCFrame * CFrame.new(0, -picoteo, picoteo * 0.5)
				end
			end
		end
	end)
end

task.spawn(iniciarAnimaciones)
