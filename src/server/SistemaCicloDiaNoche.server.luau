local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

-- Configuración del Ciclo (12 minutos en la vida real = 24 horas en el juego)
-- 720 segundos reales = 24 horas del juego -> 1 hora de juego = 30 segundos reales
local SEGUNDOS_POR_HORA = 30
local VELOCIDAD_CICLO = 1 / SEGUNDOS_POR_HORA -- Horas de juego por segundo real

type ElementoLuz = {
	Parte: BasePart,
	Luz: Light?,
	ColorOriginal: Color3,
	MaterialOriginal: Enum.Material,
}

local farolasRegistradas: { ElementoLuz } = {}
local alumbradoPublicoEncendido = false

-- 1. Registrar automáticamente todas las farolas, postes de luz y bombillos del mapa
local function registrarLucesEnInstancia(inst: Instance)
	for _, desc in ipairs(inst:GetDescendants()) do
		if desc:IsA("BasePart") then
			local nombreLower = string.lower(desc.Name)

			-- Franjas amarillas retrorreflectivas de la carretera
			if string.find(nombreLower, "lineacentral") then
				desc.Material = Enum.Material.Neon
				desc.Color = Color3.fromRGB(255, 230, 45)
			end

			local esLuz = string.find(nombreLower, "farol")
				or string.find(nombreLower, "posteluz")
				or string.find(nombreLower, "bombillo")
				or string.find(nombreLower, "lampara")
				or string.find(nombreLower, "foco")

			local lightObj = desc:FindFirstChildWhichIsA("Light")

			if esLuz or lightObj then
				-- Si no tiene un PointLight, crearlo para iluminar la calle
				if not lightObj and esLuz then
					local nuevoPunto = Instance.new("PointLight")
					nuevoPunto.Name = "LuzNoche"
					nuevoPunto.Color = Color3.fromRGB(255, 225, 155)
					nuevoPunto.Range = 26
					nuevoPunto.Brightness = 1.8
					nuevoPunto.Shadows = false
					nuevoPunto.Enabled = false
					nuevoPunto.Parent = desc
					lightObj = nuevoPunto
				end

				table.insert(farolasRegistradas, {
					Parte = desc,
					Luz = lightObj,
					ColorOriginal = desc.Color,
					MaterialOriginal = desc.Material,
				})
			end
		end
	end
end

local function actualizarAlumbradoPublico(encender: boolean)
	if alumbradoPublicoEncendido == encender then
		return
	end
	alumbradoPublicoEncendido = encender

	for _, item in ipairs(farolasRegistradas) do
		if item.Parte and item.Parte.Parent then
			if encender then
				item.Parte.Material = Enum.Material.Neon
				item.Parte.Color = Color3.fromRGB(255, 240, 180)
				if item.Luz then
					item.Luz.Enabled = true
				end
			else
				item.Parte.Material = item.MaterialOriginal
				item.Parte.Color = item.ColorOriginal
				if item.Luz then
					item.Luz.Enabled = false
				end
			end
		end
	end
end

-- 2. Inicializar entorno de iluminación realista para el pueblo andino
local function inicializarIluminacion()
	Lighting.ClockTime = 14.0 -- Comienza a las 2:00 PM (Tarde soleada)
	Lighting.GeographicLatitude = 4.71 -- Latitud de Colombia (Bogotá / Medellín)
	Lighting.ExposureCompensation = 0.1

	local mapa = Workspace:WaitForChild("Mapa", 10)
	if mapa then
		registrarLucesEnInstancia(mapa)
		mapa.DescendantAdded:Connect(function(desc)
			if desc:IsA("BasePart") then
				registrarLucesEnInstancia(desc)
			end
		end)
	end
end

-- 3. Bucle principal de progresión de tiempo y atmósfera
task.spawn(function()
	inicializarIluminacion()

	while true do
		local dt = task.wait(0.5)
		local horaActual = Lighting.ClockTime + (VELOCIDAD_CICLO * dt)
		if horaActual >= 24 then
			horaActual -= 24
		end
		Lighting.ClockTime = horaActual

		-- Determinar período del día
		local periodo = "Día"
		local esDeNoche = false

		if horaActual >= 5.5 and horaActual < 6.8 then
			periodo = "Amanecer"
			-- Amanecer: Luz dorada suave, niebla andina ligera
			Lighting.Brightness = 1.6
			Lighting.OutdoorAmbient = Color3.fromRGB(150, 130, 120)
			Lighting.Ambient = Color3.fromRGB(60, 60, 65)
			actualizarAlumbradoPublico(false)
		elseif horaActual >= 6.8 and horaActual < 17.5 then
			periodo = "Día"
			-- Pleno día: sol brillante tropical
			Lighting.Brightness = 2.4
			Lighting.OutdoorAmbient = Color3.fromRGB(145, 130, 115)
			Lighting.Ambient = Color3.fromRGB(70, 70, 75)
			actualizarAlumbradoPublico(false)
		elseif horaActual >= 17.5 and horaActual < 18.5 then
			periodo = "Atardecer"
			-- Atardecer: cielo naranja y sombras cálidas
			Lighting.Brightness = 1.7
			Lighting.OutdoorAmbient = Color3.fromRGB(175, 110, 75)
			Lighting.Ambient = Color3.fromRGB(75, 55, 60)
			actualizarAlumbradoPublico(true)
		else
			periodo = "Noche"
			esDeNoche = true
			-- Noche: luna brillante, sombras frescas, farolas encendidas
			Lighting.Brightness = 0.75
			Lighting.OutdoorAmbient = Color3.fromRGB(48, 54, 75)
			Lighting.Ambient = Color3.fromRGB(36, 40, 52)
			actualizarAlumbradoPublico(true)
		end

		-- Formato de hora en texto para HUD (ej: 03:45 PM)
		local horas = math.floor(horaActual)
		local minutos = math.floor((horaActual - horas) * 60)
		local periodoAmPm = if horas >= 12 then "PM" else "AM"
		local horas12 = if horas % 12 == 0 then 12 else (horas % 12)
		local textoHora = string.format("%02d:%02d %s", horas12, minutos, periodoAmPm)

		Lighting:SetAttribute("PeriodoDia", periodo)
		Lighting:SetAttribute("EsDeNoche", esDeNoche)
		Lighting:SetAttribute("HoraTexto", textoHora)
		Lighting:SetAttribute("HoraDecimal", horaActual)
	end
end)

print("El Patrón del Dulce: Sistema de Ciclo Día y Noche Activo (Atmósfera y Alumbrado Público)")
