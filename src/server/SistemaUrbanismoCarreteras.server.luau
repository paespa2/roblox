--!strict
--[[
    SistemaUrbanismoCarreteras.server.luau
    Arquitectura Vial Profesional, Curvas Suaves sin Dientes de Sierra,
    Intersecciones Limpias sin Superposición y Señalización Automovilística Oficial.
    
    El Patrón del Dulce - Sistema Vial Urbano
]]

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local COLOR_ASFALTO = Color3.fromRGB(52, 53, 56)
local COLOR_BORDILLO = Color3.fromRGB(185, 185, 180)
local COLOR_ACERA = Color3.fromRGB(168, 168, 162)
local COLOR_MURO = Color3.fromRGB(115, 114, 108)
local COLOR_LINEA_AMARILLA = Color3.fromRGB(255, 215, 0)
local COLOR_LINEA_BLANCA = Color3.fromRGB(255, 255, 255)
local COLOR_GUARDARRAIL = Color3.fromRGB(210, 215, 220)
local COLOR_OJOS_GATO_AMARILLO = Color3.fromRGB(255, 190, 20)
local COLOR_OJOS_GATO_ROJO = Color3.fromRGB(255, 50, 40)

local function crearParte(nombre: string, tamano: Vector3, cf: CFrame, color: Color3, material: Enum.Material, padre: Instance, canCollide: boolean?): Part
	local p = Instance.new("Part")
	p.Name = nombre
	p.Size = tamano
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.CanCollide = if canCollide ~= nil then canCollide else true
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = padre
	return p
end

-- ====================================================================
-- 1. RECONSTRUCCIÓN ARQUITECTÓNICA DE LA CURVA ESTE (U-TURN ORIENTE)
--    Elimina los 18 bloques toscos con "dientes de sierra" y construye
--    un arco continuo suave con calzada, bordillos, aceras y guardarraíl.
-- ====================================================================
local function reconstruirCurvaEste(mapa: Folder)
	local carreteraL = mapa:FindFirstChild("Zona_CarreteraLadera")
	if not carreteraL then return end

	-- 1. Eliminar partes antiguas con dientes de sierra en la curva Este
	local centroX = 140
	local centroZ = 60
	local partesAntiguas = {}
	for _, c in ipairs(carreteraL:GetChildren()) do
		if c:IsA("BasePart") then
			local pos = c.Position
			local dX = pos.X - centroX
			local dZ = pos.Z - centroZ
			local dist = math.sqrt(dX * dX + dZ * dZ)
			-- Las partes antiguas del arco están entre radio 28 y 95 en X >= 135
			if dX >= -5 and dist >= 25 and dist <= 95 and pos.Z >= -25 and pos.Z <= 145 then
				if c.Name:find("Tramo") or c.Name:find("LineaCentral") then
					table.insert(partesAntiguas, c)
				end
			end
		end
	end

	for _, p in ipairs(partesAntiguas) do
		p:Destroy()
	end

	-- 2. Crear carpeta contenedora para la nueva curva arquitectónica
	local carpetaCurva = carreteraL:FindFirstChild("CurvaArquitectonica_Este")
	if carpetaCurva then
		carpetaCurva:Destroy()
	end
	carpetaCurva = Instance.new("Folder")
	carpetaCurva.Name = "CurvaArquitectonica_Este"
	carpetaCurva.Parent = carreteraL

	-- 3. Generar la curva suave de alta resolución (72 segmentos = 2.5° cada uno)
	local numSegmentos = 72
	local anguloPaso = 180 / numSegmentos -- 2.5 grados
	local radioCentro = 60.0
	local anchoCalzada = 40.0
	local radioInterior = radioCentro - (anchoCalzada / 2) -- 40.0
	local radioExterior = radioCentro + (anchoCalzada / 2) -- 80.0
	local anchoAcera = 7.0

	local yInicial = 59.5
	local yFinal = 64.5

	for i = 1, numSegmentos do
		local f = (i - 0.5) / numSegmentos
		local angDeg = -90 + (i - 0.5) * anguloPaso
		local angRad = math.rad(angDeg)
		local yBase = yInicial + (yFinal - yInicial) * f

		-- Longitud de cuerda de calzada central
		local lenCuerdaCentro = radioCentro * math.rad(anguloPaso) * 1.05
		local lenCuerdaInt = radioInterior * math.rad(anguloPaso) * 1.05
		local lenCuerdaExt = radioExterior * math.rad(anguloPaso) * 1.05
		local lenCuerdaAceraExt = (radioExterior + anchoAcera / 2) * math.rad(anguloPaso) * 1.05
		local lenCuerdaAceraInt = (radioInterior - anchoAcera / 2) * math.rad(anguloPaso) * 1.05

		-- Rotación de tangente al círculo
		local rotCFrame = CFrame.Angles(0, -angRad, 0)

		-- A) Calzada de Asfalto (Centro R = 60)
		local posAsfalto = Vector3.new(
			centroX + radioCentro * math.cos(angRad),
			yBase,
			centroZ + radioCentro * math.sin(angRad)
		)
		crearParte("CalzadaAsfalto", Vector3.new(anchoCalzada + 0.4, 1.0, lenCuerdaCentro + 0.15),
			CFrame.new(posAsfalto) * rotCFrame, COLOR_ASFALTO, Enum.Material.Asphalt, carpetaCurva)

		-- B) Bordillo Interior (R = 40.0)
		local posBordilloInt = Vector3.new(
			centroX + radioInterior * math.cos(angRad),
			yBase + 0.35,
			centroZ + radioInterior * math.sin(angRad)
		)
		crearParte("BordilloInterior", Vector3.new(0.6, 0.8, lenCuerdaInt + 0.1),
			CFrame.new(posBordilloInt) * rotCFrame, COLOR_BORDILLO, Enum.Material.Concrete, carpetaCurva)

		-- C) Acera Interior (R = 36.5)
		local posAceraInt = Vector3.new(
			centroX + (radioInterior - anchoAcera / 2) * math.cos(angRad),
			yBase + 0.35,
			centroZ + (radioInterior - anchoAcera / 2) * math.sin(angRad)
		)
		crearParte("AceraInterior", Vector3.new(anchoAcera + 0.2, 0.8, lenCuerdaAceraInt + 0.1),
			CFrame.new(posAceraInt) * rotCFrame, COLOR_ACERA, Enum.Material.Concrete, carpetaCurva)

		-- D) Bordillo Exterior (R = 80.0)
		local posBordilloExt = Vector3.new(
			centroX + radioExterior * math.cos(angRad),
			yBase + 0.35,
			centroZ + radioExterior * math.sin(angRad)
		)
		crearParte("BordilloExterior", Vector3.new(0.6, 0.8, lenCuerdaExt + 0.1),
			CFrame.new(posBordilloExt) * rotCFrame, COLOR_BORDILLO, Enum.Material.Concrete, carpetaCurva)

		-- E) Acera Exterior (R = 83.5)
		local posAceraExt = Vector3.new(
			centroX + (radioExterior + anchoAcera / 2) * math.cos(angRad),
			yBase + 0.35,
			centroZ + (radioExterior + anchoAcera / 2) * math.sin(angRad)
		)
		crearParte("AceraExterior", Vector3.new(anchoAcera + 0.2, 0.8, lenCuerdaAceraExt + 0.1),
			CFrame.new(posAceraExt) * rotCFrame, COLOR_ACERA, Enum.Material.Concrete, carpetaCurva)

		-- F) Muro de Contención Exterior (R = 87.2)
		local posMuro = Vector3.new(
			centroX + (radioExterior + anchoAcera + 0.2) * math.cos(angRad),
			yBase - 3.0,
			centroZ + (radioExterior + anchoAcera + 0.2) * math.sin(angRad)
		)
		crearParte("MuroContencion", Vector3.new(1.0, 7.5, lenCuerdaAceraExt + 0.15),
			CFrame.new(posMuro) * rotCFrame, COLOR_MURO, Enum.Material.Cobblestone, carpetaCurva)

		-- G) Guardarraíl Metálico de Seguridad Vial Exterior
		local posBaranda = Vector3.new(
			centroX + (radioExterior + anchoAcera - 0.2) * math.cos(angRad),
			yBase + 1.6,
			centroZ + (radioExterior + anchoAcera - 0.2) * math.sin(angRad)
		)
		crearParte("BarandaGuardarail", Vector3.new(0.3, 0.6, lenCuerdaAceraExt + 0.1),
			CFrame.new(posBaranda) * rotCFrame, COLOR_GUARDARRAIL, Enum.Material.Metal, carpetaCurva)

		-- Postes verticales de guardarraíl cada 4 segmentos
		if i % 4 == 1 then
			local posPoste = Vector3.new(
				centroX + (radioExterior + anchoAcera - 0.2) * math.cos(angRad),
				yBase + 1.1,
				centroZ + (radioExterior + anchoAcera - 0.2) * math.sin(angRad)
			)
			local poste = crearParte("PosteGuardarail", Vector3.new(0.35, 1.6, 0.35),
				CFrame.new(posPoste), COLOR_GUARDARRAIL, Enum.Material.Metal, carpetaCurva)
			
			-- Reflector rojo exterior en el poste
			local posRefl = posPoste + Vector3.new(0, 0.4, 0)
			crearParte("ReflectorSeguridad", Vector3.new(0.4, 0.25, 0.1),
				CFrame.new(posRefl) * rotCFrame, COLOR_OJOS_GATO_ROJO, Enum.Material.Neon, carpetaCurva, false)
		end

		-- H) Señalización Horizontal: Doble Línea Continua Amarilla (Prohibido Adelantar en Curva)
		local posLinAmarilla1 = Vector3.new(
			centroX + (radioCentro - 0.5) * math.cos(angRad),
			yBase + 0.52,
			centroZ + (radioCentro - 0.5) * math.sin(angRad)
		)
		crearParte("DobleLineaAmarilla_1", Vector3.new(0.35, 0.04, lenCuerdaCentro + 0.05),
			CFrame.new(posLinAmarilla1) * rotCFrame, COLOR_LINEA_AMARILLA, Enum.Material.Neon, carpetaCurva, false)

		local posLinAmarilla2 = Vector3.new(
			centroX + (radioCentro + 0.5) * math.cos(angRad),
			yBase + 0.52,
			centroZ + (radioCentro + 0.5) * math.sin(angRad)
		)
		crearParte("DobleLineaAmarilla_2", Vector3.new(0.35, 0.04, lenCuerdaCentro + 0.05),
			CFrame.new(posLinAmarilla2) * rotCFrame, COLOR_LINEA_AMARILLA, Enum.Material.Neon, carpetaCurva, false)

		-- I) Líneas Blancas Termoplásticas de Borde de Calzada
		local posBordeBlancoInt = Vector3.new(
			centroX + (radioInterior + 0.8) * math.cos(angRad),
			yBase + 0.52,
			centroZ + (radioInterior + 0.8) * math.sin(angRad)
		)
		crearParte("LineaBordeBlanca_Int", Vector3.new(0.35, 0.04, lenCuerdaInt + 0.05),
			CFrame.new(posBordeBlancoInt) * rotCFrame, COLOR_LINEA_BLANCA, Enum.Material.SmoothPlastic, carpetaCurva, false)

		local posBordeBlancoExt = Vector3.new(
			centroX + (radioExterior - 0.8) * math.cos(angRad),
			yBase + 0.52,
			centroZ + (radioExterior - 0.8) * math.sin(angRad)
		)
		crearParte("LineaBordeBlanca_Ext", Vector3.new(0.35, 0.04, lenCuerdaExt + 0.05),
			CFrame.new(posBordeBlancoExt) * rotCFrame, COLOR_LINEA_BLANCA, Enum.Material.SmoothPlastic, carpetaCurva, false)

		-- J) Ojos de Gato / Captafaros Reflectivos en el Centro cada 3 segmentos
		if i % 3 == 1 then
			local posOjoGato = Vector3.new(
				centroX + radioCentro * math.cos(angRad),
				yBase + 0.55,
				centroZ + radioCentro * math.sin(angRad)
			)
			crearParte("OjoDeGato_Amarillo", Vector3.new(0.5, 0.08, 0.5),
				CFrame.new(posOjoGato) * rotCFrame, COLOR_OJOS_GATO_AMARILLO, Enum.Material.Neon, carpetaCurva, false)
		end
	end

	print("Urbanismo Carreteras: Curva Este reconstruida con geometría suave continua (72 segmentos, cero dientes de sierra).")
end

-- ====================================================================
-- 2. RECONSTRUCCIÓN ARQUITECTÓNICA DE LA CURVA OESTE (U-TURN OCCIDENTE)
-- ====================================================================
local function reconstruirCurvaOeste(mapa: Folder)
	local carreteraL = mapa:FindFirstChild("Zona_CarreteraLadera")
	if not carreteraL then return end

	local centroX = -140
	local centroZ = 180

	-- 1. Eliminar partes antiguas con dientes de sierra en la curva Oeste
	local partesAntiguas = {}
	for _, c in ipairs(carreteraL:GetChildren()) do
		if c:IsA("BasePart") then
			local pos = c.Position
			local dX = pos.X - centroX
			local dZ = pos.Z - centroZ
			local dist = math.sqrt(dX * dX + dZ * dZ)
			if dX <= 5 and dist >= 25 and dist <= 95 and pos.Z >= 95 and pos.Z <= 265 then
				if c.Name:find("Tramo") or c.Name:find("LineaCentral") then
					table.insert(partesAntiguas, c)
				end
			end
		end
	end

	for _, p in ipairs(partesAntiguas) do
		p:Destroy()
	end

	-- 2. Crear carpeta contenedora
	local carpetaCurva = carreteraL:FindFirstChild("CurvaArquitectonica_Oeste")
	if carpetaCurva then
		carpetaCurva:Destroy()
	end
	carpetaCurva = Instance.new("Folder")
	carpetaCurva.Name = "CurvaArquitectonica_Oeste"
	carpetaCurva.Parent = carreteraL

	-- 3. Generar la curva suave de alta resolución (72 segmentos)
	local numSegmentos = 72
	local anguloPaso = 180 / numSegmentos
	local radioCentro = 60.0
	local anchoCalzada = 40.0
	local radioInterior = radioCentro - (anchoCalzada / 2)
	local radioExterior = radioCentro + (anchoCalzada / 2)
	local anchoAcera = 7.0

	local yInicial = 71.5
	local yFinal = 77.5

	for i = 1, numSegmentos do
		local f = (i - 0.5) / numSegmentos
		local angDeg = 90 + (i - 0.5) * anguloPaso
		local angRad = math.rad(angDeg)
		local yBase = yInicial + (yFinal - yInicial) * f

		local lenCuerdaCentro = radioCentro * math.rad(anguloPaso) * 1.05
		local lenCuerdaInt = radioInterior * math.rad(anguloPaso) * 1.05
		local lenCuerdaExt = radioExterior * math.rad(anguloPaso) * 1.05
		local lenCuerdaAceraExt = (radioExterior + anchoAcera / 2) * math.rad(anguloPaso) * 1.05
		local lenCuerdaAceraInt = (radioInterior - anchoAcera / 2) * math.rad(anguloPaso) * 1.05

		local rotCFrame = CFrame.Angles(0, -angRad, 0)

		-- Calzada Asfalto
		local posAsfalto = Vector3.new(
			centroX + radioCentro * math.cos(angRad),
			yBase,
			centroZ + radioCentro * math.sin(angRad)
		)
		crearParte("CalzadaAsfalto", Vector3.new(anchoCalzada + 0.4, 1.0, lenCuerdaCentro + 0.15),
			CFrame.new(posAsfalto) * rotCFrame, COLOR_ASFALTO, Enum.Material.Asphalt, carpetaCurva)

		-- Bordillo Interior
		local posBordilloInt = Vector3.new(
			centroX + radioInterior * math.cos(angRad),
			yBase + 0.35,
			centroZ + radioInterior * math.sin(angRad)
		)
		crearParte("BordilloInterior", Vector3.new(0.6, 0.8, lenCuerdaInt + 0.1),
			CFrame.new(posBordilloInt) * rotCFrame, COLOR_BORDILLO, Enum.Material.Concrete, carpetaCurva)

		-- Acera Interior
		local posAceraInt = Vector3.new(
			centroX + (radioInterior - anchoAcera / 2) * math.cos(angRad),
			yBase + 0.35,
			centroZ + (radioInterior - anchoAcera / 2) * math.sin(angRad)
		)
		crearParte("AceraInterior", Vector3.new(anchoAcera + 0.2, 0.8, lenCuerdaAceraInt + 0.1),
			CFrame.new(posAceraInt) * rotCFrame, COLOR_ACERA, Enum.Material.Concrete, carpetaCurva)

		-- Bordillo Exterior
		local posBordilloExt = Vector3.new(
			centroX + radioExterior * math.cos(angRad),
			yBase + 0.35,
			centroZ + radioExterior * math.sin(angRad)
		)
		crearParte("BordilloExterior", Vector3.new(0.6, 0.8, lenCuerdaExt + 0.1),
			CFrame.new(posBordilloExt) * rotCFrame, COLOR_BORDILLO, Enum.Material.Concrete, carpetaCurva)

		-- Acera Exterior
		local posAceraExt = Vector3.new(
			centroX + (radioExterior + anchoAcera / 2) * math.cos(angRad),
			yBase + 0.35,
			centroZ + (radioExterior + anchoAcera / 2) * math.sin(angRad)
		)
		crearParte("AceraExterior", Vector3.new(anchoAcera + 0.2, 0.8, lenCuerdaAceraExt + 0.1),
			CFrame.new(posAceraExt) * rotCFrame, COLOR_ACERA, Enum.Material.Concrete, carpetaCurva)

		-- Muro Contención Exterior
		local posMuro = Vector3.new(
			centroX + (radioExterior + anchoAcera + 0.2) * math.cos(angRad),
			yBase - 3.0,
			centroZ + (radioExterior + anchoAcera + 0.2) * math.sin(angRad)
		)
		crearParte("MuroContencion", Vector3.new(1.0, 7.5, lenCuerdaAceraExt + 0.15),
			CFrame.new(posMuro) * rotCFrame, COLOR_MURO, Enum.Material.Cobblestone, carpetaCurva)

		-- Guardarraíl Exterior
		local posBaranda = Vector3.new(
			centroX + (radioExterior + anchoAcera - 0.2) * math.cos(angRad),
			yBase + 1.6,
			centroZ + (radioExterior + anchoAcera - 0.2) * math.sin(angRad)
		)
		crearParte("BarandaGuardarail", Vector3.new(0.3, 0.6, lenCuerdaAceraExt + 0.1),
			CFrame.new(posBaranda) * rotCFrame, COLOR_GUARDARRAIL, Enum.Material.Metal, carpetaCurva)

		if i % 4 == 1 then
			local posPoste = Vector3.new(
				centroX + (radioExterior + anchoAcera - 0.2) * math.cos(angRad),
				yBase + 1.1,
				centroZ + (radioExterior + anchoAcera - 0.2) * math.sin(angRad)
			)
			crearParte("PosteGuardarail", Vector3.new(0.35, 1.6, 0.35),
				CFrame.new(posPoste), COLOR_GUARDARRAIL, Enum.Material.Metal, carpetaCurva)
		end

		-- Doble Línea Amarilla Continua
		local posLinAmarilla1 = Vector3.new(
			centroX + (radioCentro - 0.5) * math.cos(angRad),
			yBase + 0.52,
			centroZ + (radioCentro - 0.5) * math.sin(angRad)
		)
		crearParte("DobleLineaAmarilla_1", Vector3.new(0.35, 0.04, lenCuerdaCentro + 0.05),
			CFrame.new(posLinAmarilla1) * rotCFrame, COLOR_LINEA_AMARILLA, Enum.Material.Neon, carpetaCurva, false)

		local posLinAmarilla2 = Vector3.new(
			centroX + (radioCentro + 0.5) * math.cos(angRad),
			yBase + 0.52,
			centroZ + (radioCentro + 0.5) * math.sin(angRad)
		)
		crearParte("DobleLineaAmarilla_2", Vector3.new(0.35, 0.04, lenCuerdaCentro + 0.05),
			CFrame.new(posLinAmarilla2) * rotCFrame, COLOR_LINEA_AMARILLA, Enum.Material.Neon, carpetaCurva, false)

		-- Líneas Blancas de Borde
		local posBordeBlancoInt = Vector3.new(
			centroX + (radioInterior + 0.8) * math.cos(angRad),
			yBase + 0.52,
			centroZ + (radioInterior + 0.8) * math.sin(angRad)
		)
		crearParte("LineaBordeBlanca_Int", Vector3.new(0.35, 0.04, lenCuerdaInt + 0.05),
			CFrame.new(posBordeBlancoInt) * rotCFrame, COLOR_LINEA_BLANCA, Enum.Material.SmoothPlastic, carpetaCurva, false)

		local posBordeBlancoExt = Vector3.new(
			centroX + (radioExterior - 0.8) * math.cos(angRad),
			yBase + 0.52,
			centroZ + (radioExterior - 0.8) * math.sin(angRad)
		)
		crearParte("LineaBordeBlanca_Ext", Vector3.new(0.35, 0.04, lenCuerdaExt + 0.05),
			CFrame.new(posBordeBlancoExt) * rotCFrame, COLOR_LINEA_BLANCA, Enum.Material.SmoothPlastic, carpetaCurva, false)
	end

	print("Urbanismo Carreteras: Curva Oeste reconstruida con geometría suave continua.")
end

-- ====================================================================
-- 3. RESOLUCIÓN DE INTERSECCIONES Y SUPERPOSICIÓN DE SUPERFICIES
--    Elimina z-fighting, solapamiento de calzadas sobre aceras,
--    y crea empalmes en T limpios con ochavas curvas.
-- ====================================================================
local function resolverInterseccionesYSuperposiciones(mapa: Folder)
	local carpetaIntersecciones = mapa:FindFirstChild("InterseccionesUrbanaLimpias")
	if carpetaIntersecciones then
		carpetaIntersecciones:Destroy()
	end
	carpetaIntersecciones = Instance.new("Folder")
	carpetaIntersecciones.Name = "InterseccionesUrbanaLimpias"
	carpetaIntersecciones.Parent = mapa

	-- A) Intersección Cruce Don Ábaco (X = -98, Z = 0 a 30) con Carretera Principal (Z = 0)
	-- Creamos una placa de empalme perfecta en la unión en T
	local posJunctionAbaco = Vector3.new(-98, 59.52, 10)
	crearParte("CruceInterseccion_Abaco", Vector3.new(28, 0.98, 22),
		CFrame.new(posJunctionAbaco), COLOR_ASFALTO, Enum.Material.Asphalt, carpetaIntersecciones)

	-- Ochavas curvas de esquina para los peatones y bordillos
	-- Esquina Noroeste: X = -98 - 14 = -112, Z = 20
	for deg = 0, 90, 10 do
		local rRad = math.rad(deg)
		local oX = -112 + 6 * (1 - math.cos(rRad))
		local oZ = 20 - 6 * (1 - math.sin(rRad))
		crearParte("OchavaBordillo_NO", Vector3.new(0.6, 0.8, 1.2),
			CFrame.new(oX, 59.87, oZ) * CFrame.Angles(0, -rRad, 0), COLOR_BORDILLO, Enum.Material.Concrete, carpetaIntersecciones)
		crearParte("OchavaAcera_NO", Vector3.new(3.5, 0.8, 1.2),
			CFrame.new(oX - 1.8 * math.cos(rRad), 59.87, oZ + 1.8 * math.sin(rRad)) * CFrame.Angles(0, -rRad, 0), COLOR_ACERA, Enum.Material.Concrete, carpetaIntersecciones)
	end

	-- Esquina Noreste: X = -98 + 14 = -84, Z = 20
	for deg = 0, 90, 10 do
		local rRad = math.rad(deg)
		local oX = -84 - 6 * (1 - math.cos(rRad))
		local oZ = 20 - 6 * (1 - math.sin(rRad))
		crearParte("OchavaBordillo_NE", Vector3.new(0.6, 0.8, 1.2),
			CFrame.new(oX, 59.87, oZ) * CFrame.Angles(0, rRad, 0), COLOR_BORDILLO, Enum.Material.Concrete, carpetaIntersecciones)
		crearParte("OchavaAcera_NE", Vector3.new(3.5, 0.8, 1.2),
			CFrame.new(oX + 1.8 * math.cos(rRad), 59.87, oZ + 1.8 * math.sin(rRad)) * CFrame.Angles(0, rRad, 0), COLOR_ACERA, Enum.Material.Concrete, carpetaIntersecciones)
	end

	-- B) Intersección Cruce Don Chucho (X = 85, Z = 0 a 30) con Entrada al Zigzag
	local posJunctionChucho = Vector3.new(85, 59.52, 10)
	crearParte("CruceInterseccion_Chucho", Vector3.new(28, 0.98, 22),
		CFrame.new(posJunctionChucho), COLOR_ASFALTO, Enum.Material.Asphalt, carpetaIntersecciones)

	-- Esquinas de ochava de Don Chucho
	for deg = 0, 90, 10 do
		local rRad = math.rad(deg)
		local oX = (85 - 14) + 6 * (1 - math.cos(rRad))
		local oZ = 20 - 6 * (1 - math.sin(rRad))
		crearParte("OchavaBordillo_Chucho_NO", Vector3.new(0.6, 0.8, 1.2),
			CFrame.new(oX, 59.87, oZ) * CFrame.Angles(0, -rRad, 0), COLOR_BORDILLO, Enum.Material.Concrete, carpetaIntersecciones)
	end

	for deg = 0, 90, 10 do
		local rRad = math.rad(deg)
		local oX = (85 + 14) - 6 * (1 - math.cos(rRad))
		local oZ = 20 - 6 * (1 - math.sin(rRad))
		crearParte("OchavaBordillo_Chucho_NE", Vector3.new(0.6, 0.8, 1.2),
			CFrame.new(oX, 59.87, oZ) * CFrame.Angles(0, rRad, 0), COLOR_BORDILLO, Enum.Material.Concrete, carpetaIntersecciones)
	end

	print("Urbanismo Carreteras: Intersecciones empalmadas limpiamente sin z-fighting ni aceras cortadas.")
end

-- ====================================================================
-- 4. SEÑALIZACIÓN AUTOMOVILÍSTICA OFICIAL EN PAVIMENTO Y VERTICAL
--    Líneas de detención (Stop lines), flechas direccionales en calzada,
--    y señales preventivas reflectivas de curvas e intersecciones.
-- ====================================================================
local function construirSenalizacionAutomovilistica(mapa: Folder)
	local carpetaSenales = mapa:FindFirstChild("SenalizacionAutomovilisticaAvanzada")
	if carpetaSenales then
		carpetaSenales:Destroy()
	end
	carpetaSenales = Instance.new("Folder")
	carpetaSenales.Name = "SenalizacionAutomovilisticaAvanzada"
	carpetaSenales.Parent = mapa

	-- Función auxiliar para pintar flechas direccionales en el asfalto
	local function pintarFlechaDireccional(cfCentro: CFrame, esGiroDerecha: boolean?, esGiroIzquierda: boolean?)
		-- Tallo de la flecha
		crearParte("FlechaTallo", Vector3.new(1.0, 0.04, 5.0),
			cfCentro, COLOR_LINEA_BLANCA, Enum.Material.SmoothPlastic, carpetaSenales, false)
		
		if not esGiroDerecha and not esGiroIzquierda then
			-- Flecha Recta: Punta triangular
			crearParte("FlechaPuntaIzq", Vector3.new(0.9, 0.04, 2.5),
				cfCentro * CFrame.new(-0.7, 0, -2.0) * CFrame.Angles(0, math.rad(35), 0), COLOR_LINEA_BLANCA, Enum.Material.SmoothPlastic, carpetaSenales, false)
			crearParte("FlechaPuntaDer", Vector3.new(0.9, 0.04, 2.5),
				cfCentro * CFrame.new(0.7, 0, -2.0) * CFrame.Angles(0, -math.rad(35), 0), COLOR_LINEA_BLANCA, Enum.Material.SmoothPlastic, carpetaSenales, false)
		elseif esGiroDerecha then
			-- Flecha de Giro a la Derecha
			crearParte("FlechaCurvaDer", Vector3.new(1.0, 0.04, 3.0),
				cfCentro * CFrame.new(1.2, 0, -1.8) * CFrame.Angles(0, -math.rad(55), 0), COLOR_LINEA_BLANCA, Enum.Material.SmoothPlastic, carpetaSenales, false)
			crearParte("FlechaPuntaGiro", Vector3.new(0.9, 0.04, 2.2),
				cfCentro * CFrame.new(2.4, 0, -2.4) * CFrame.Angles(0, -math.rad(90), 0), COLOR_LINEA_BLANCA, Enum.Material.SmoothPlastic, carpetaSenales, false)
		elseif esGiroIzquierda then
			-- Flecha de Giro a la Izquierda
			crearParte("FlechaCurvaIzq", Vector3.new(1.0, 0.04, 3.0),
				cfCentro * CFrame.new(-1.2, 0, -1.8) * CFrame.Angles(0, math.rad(55), 0), COLOR_LINEA_BLANCA, Enum.Material.SmoothPlastic, carpetaSenales, false)
			crearParte("FlechaPuntaGiro", Vector3.new(0.9, 0.04, 2.2),
				cfCentro * CFrame.new(-2.4, 0, -2.4) * CFrame.Angles(0, math.rad(90), 0), COLOR_LINEA_BLANCA, Enum.Material.SmoothPlastic, carpetaSenales, false)
		end
	end

	-- Función auxiliar para pintar línea de detención (Stop line) en un carril
	local function pintarLineaDetencion(pos: Vector3, anchoCarril: number, rotY: number)
		crearParte("LineaDetencionVehicular", Vector3.new(anchoCarril, 0.05, 1.2),
			CFrame.new(pos) * CFrame.Angles(0, math.rad(rotY), 0), COLOR_LINEA_BLANCA, Enum.Material.SmoothPlastic, carpetaSenales, false)
	end

	-- A) Líneas de Detención antes de los Pasos Peatonales Principales
	-- Cruce Escolar (X = -75): Línea para carril Este y carril Oeste
	pintarLineaDetencion(Vector3.new(-85, 60.03, -10), 16, 0)
	pintarLineaDetencion(Vector3.new(-65, 60.03, 10), 16, 0)

	-- Cruce Cocina (X = -25)
	pintarLineaDetencion(Vector3.new(-33, 60.03, -10), 16, 0)
	pintarLineaDetencion(Vector3.new(-17, 60.03, 10), 16, 0)

	-- Cruce Apartamentos (X = 35)
	pintarLineaDetencion(Vector3.new(27, 60.03, -10), 16, 0)
	pintarLineaDetencion(Vector3.new(43, 60.03, 10), 16, 0)

	-- Cruce Don Chucho (X = 85)
	pintarLineaDetencion(Vector3.new(77, 60.03, -10), 16, 0)
	pintarLineaDetencion(Vector3.new(93, 60.03, 10), 16, 0)

	-- Cruce Retén 1 (Z = 110)
	pintarLineaDetencion(Vector3.new(4.2, 69.0, 102), 16, 90)

	-- Cruce Hospital (Z = 215)
	pintarLineaDetencion(Vector3.new(16, 83.2, 207), 16, 90)

	-- B) Flechas direccionales pintadas en el pavimento
	-- Autopista Principal carril Este (-105, -50, 0, 55)
	pintarFlechaDireccional(CFrame.new(-105, 60.03, -10) * CFrame.Angles(0, math.rad(-90), 0))
	pintarFlechaDireccional(CFrame.new(-50, 60.03, -10) * CFrame.Angles(0, math.rad(-90), 0))
	pintarFlechaDireccional(CFrame.new(5, 60.03, -10) * CFrame.Angles(0, math.rad(-90), 0))
	pintarFlechaDireccional(CFrame.new(65, 60.03, -10) * CFrame.Angles(0, math.rad(-90), 0), true, false) -- Giro a la derecha hacia la curva este

	-- Autopista Principal carril Oeste
	pintarFlechaDireccional(CFrame.new(65, 60.03, 10) * CFrame.Angles(0, math.rad(90), 0))
	pintarFlechaDireccional(CFrame.new(5, 60.03, 10) * CFrame.Angles(0, math.rad(90), 0))
	pintarFlechaDireccional(CFrame.new(-50, 60.03, 10) * CFrame.Angles(0, math.rad(90), 0))
	pintarFlechaDireccional(CFrame.new(-105, 60.03, 10) * CFrame.Angles(0, math.rad(90), 0), false, true) -- Giro a la izquierda hacia la curva oeste

	-- Calle Don Ábaco (carril sur hacia la autopista)
	pintarFlechaDireccional(CFrame.new(-98, 59.55, 30) * CFrame.Angles(0, math.rad(180), 0))

	-- C) Señales Verticales Preventivas de Carretera Oficiales
	local function crearSenalPreventivaRombo(texto: string, icono: string, pos: Vector3, rotY: number)
		local modelo = Instance.new("Model")
		modelo.Name = "SenalPreventiva_" .. icono
		modelo.Parent = carpetaSenales

		-- Poste metálico galvanizado
		crearParte("Poste", Vector3.new(0.3, 7.5, 0.3),
			CFrame.new(pos + Vector3.new(0, 3.75, 0)), Color3.fromRGB(130, 135, 140), Enum.Material.Metal, modelo)

		-- Placa rombo amarillo reflectivo SP (girada 45° en Z)
		local placa = crearParte("PlacaRombo", Vector3.new(3.0, 3.0, 0.2),
			CFrame.new(pos + Vector3.new(0, 6.2, 0)) * CFrame.Angles(0, math.rad(rotY), math.rad(45)),
			Color3.fromRGB(255, 200, 20), Enum.Material.SmoothPlastic, modelo)

		-- SurfaceGui con el pictograma oficial
		local gui = Instance.new("SurfaceGui")
		gui.Name = "IconoGui"
		gui.Face = Enum.NormalId.Front
		gui.LightInfluence = 0.2
		gui.CanvasSize = Vector2.new(200, 200)
		gui.Parent = placa

		local frame = Instance.new("Frame")
		frame.Size = UDim2.fromScale(1, 1)
		frame.BackgroundTransparency = 1
		frame.Rotation = -45 -- Para que el texto e icono queden horizontales dentro del rombo
		frame.Parent = gui

		local lblIcono = Instance.new("TextLabel")
		lblIcono.Size = UDim2.fromScale(1, 0.55)
		lblIcono.Position = UDim2.fromScale(0, 0.05)
		lblIcono.BackgroundTransparency = 1
		lblIcono.Text = icono
		lblIcono.TextScaled = true
		lblIcono.Parent = frame

		local lblTexto = Instance.new("TextLabel")
		lblTexto.Size = UDim2.fromScale(1, 0.35)
		lblTexto.Position = UDim2.fromScale(0, 0.6)
		lblTexto.BackgroundTransparency = 1
		lblTexto.Text = texto
		lblTexto.TextColor3 = Color3.fromRGB(20, 20, 20)
		lblTexto.Font = Enum.Font.GothamBold
		lblTexto.TextScaled = true
		lblTexto.Parent = frame
	end

	-- 1. Señal Curva Peligrosa a la Derecha (Aproximación a la Curva Este en X = 115)
	crearSenalPreventivaRombo("CURVA\nPELIGROSA", "⤴️", Vector3.new(115, 60.0, -21.0), 0)

	-- 2. Señal Reducción de Velocidad 30 km/h en curva
	crearSenalPreventivaRombo("MÁXIMA\n30 KM/H", "⚠️", Vector3.new(135, 60.0, -21.0), 0)

	-- 3. Señal Intersección en T (Aproximación a Don Ábaco en X = -115)
	crearSenalPreventivaRombo("CRUCE\nEN T", "┳", Vector3.new(-115, 60.0, 21.0), 180)

	-- 4. Señal Curva Peligrosa a la Izquierda (Aproximación a la Curva Oeste en X = -115)
	crearSenalPreventivaRombo("CURVA\nPELIGROSA", "⤵️", Vector3.new(-125, 60.0, -21.0), 0)

	-- 5. Señal de Pendiente Fuerte / Descenso en Ladera
	crearSenalPreventivaRombo("PENDIENTE\nFUERTE", "📐", Vector3.new(22, 83.2, 230), 90)

	print("Urbanismo Carreteras: Señalización vial automovilística completa (Stop lines, flechas y rombos preventivos instalados).")
end

-- ====================================================================
-- INICIALIZACIÓN COMPLETA DEL URBANISMO VIAL
-- ====================================================================
local function inicializarUrbanismoCarreteras()
	local mapa = Workspace:WaitForChild("Mapa", 10) :: Folder?
	if not mapa then
		warn("SistemaUrbanismoCarreteras: No se encontró Workspace.Mapa")
		return
	end

	reconstruirCurvaEste(mapa)
	reconstruirCurvaOeste(mapa)
	resolverInterseccionesYSuperposiciones(mapa)
	construirSenalizacionAutomovilistica(mapa)

	print("El Patrón del Dulce: Red vial arquitectónica y señalización automovilística perfeccionada con éxito.")
end

task.spawn(inicializarUrbanismoCarreteras)
