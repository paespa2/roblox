--!strict
--[[
	SistemaMapaServidor.server.luau
	Escanea la geometría completa del mapa en el servidor (sin verse afectado por
	StreamingEnabled) y la entrega a los clientes para el Minimapa y Mapa GPS.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Datos = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Datos"))
local PuntosMapa = Datos.PuntosMapa

export type BloqueMapaServidor = {
	X: number,
	Z: number,
	W: number,
	D: number,
	Tipo: string, -- "suelo" | "lote" | "via" | "edificio" | "zona"
	R: number,
	G: number,
	B: number,
}

local _cacheBloques: { BloqueMapaServidor }? = nil

local function extraerColor(inst: Instance): (number, number, number)
	if inst:IsA("BasePart") then
		local c = inst.Color
		return math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255)
	elseif inst:IsA("Model") then
		for _, desc in ipairs(inst:GetDescendants()) do
			if desc:IsA("BasePart") and desc.Transparency < 0.9 then
				local c = desc.Color
				return math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255)
			end
		end
	end
	return 85, 95, 110
end

local function agregarBloque(lista: { BloqueMapaServidor }, inst: Instance, tipo: string, rOverride: number?, gOverride: number?, bOverride: number?)
	if inst:IsA("BasePart") then
		local size = inst.Size
		local cf = inst.CFrame
		local right = cf.RightVector
		local look = cf.LookVector
		local spanX = math.abs(right.X) * size.X + math.abs(look.X) * size.Z
		local spanZ = math.abs(right.Z) * size.X + math.abs(look.Z) * size.Z
		local r, g, b = extraerColor(inst)
		table.insert(lista, {
			X = math.floor(inst.Position.X * 10) / 10,
			Z = math.floor(inst.Position.Z * 10) / 10,
			W = math.max(math.floor(spanX * 10) / 10, 4),
			D = math.max(math.floor(spanZ * 10) / 10, 4),
			Tipo = tipo,
			R = rOverride or r,
			G = gOverride or g,
			B = bOverride or b,
		})
	elseif inst:IsA("Model") then
		local ok, cf, size = pcall(function()
			return inst:GetBoundingBox()
		end)
		if ok and cf and size and size.Magnitude > 0.1 then
			local r, g, b = extraerColor(inst)
			table.insert(lista, {
				X = math.floor(cf.Position.X * 10) / 10,
				Z = math.floor(cf.Position.Z * 10) / 10,
				W = math.max(math.floor(size.X * 10) / 10, 6),
				D = math.max(math.floor(size.Z * 10) / 10, 6),
				Tipo = tipo,
				R = rOverride or r,
				G = gOverride or g,
				B = bOverride or b,
			})
		end
	end
end

local function construirGeometria(): { BloqueMapaServidor }
	local bloques: { BloqueMapaServidor } = {}

	-- 1. Base de la ciudad (SueloCiudad)
	local suelo = Workspace:FindFirstChild("SueloCiudad")
	if suelo and suelo:IsA("BasePart") then
		agregarBloque(bloques, suelo, "suelo", 74, 126, 78) -- Verde pradera natural
	end

	local mapaFolder = Workspace:FindFirstChild("Mapa")
	if mapaFolder then
		local cuadricula = mapaFolder:FindFirstChild("Ciudad_Cuadricula")
		if cuadricula then
			-- 2. Lotes urbanos y parques
			local lotes = cuadricula:FindFirstChild("Lotes")
			if lotes then
				for _, l in ipairs(lotes:GetChildren()) do
					if l:IsA("BasePart") then
						if l.Material == Enum.Material.Grass or l.Color.G > l.Color.R + 0.08 then
							agregarBloque(bloques, l, "lote", 86, 148, 80) -- Césped verde vivo
						else
							agregarBloque(bloques, l, "lote", 118, 130, 142) -- Manzana urbanizada
						end
					end
				end
			end

			-- 3. Parques verdes
			local parques = cuadricula:FindFirstChild("Parques")
			if parques then
				for _, p in ipairs(parques:GetChildren()) do
					if p:IsA("BasePart") then
						agregarBloque(bloques, p, "lote", 68, 168, 76)
					elseif p:IsA("Model") then
						agregarBloque(bloques, p, "lote", 68, 168, 76)
					end
				end
			end

			-- 4. Vías / Calles (asfalto nítido)
			local vias = cuadricula:FindFirstChild("Vias")
			if vias then
				for _, v in ipairs(vias:GetChildren()) do
					agregarBloque(bloques, v, "via", 58, 64, 76) -- Asfalto urbano elegante
				end
			end

			-- 5. Edificios modernos (arquitectura luminosa con contraste)
			local edificios = cuadricula:FindFirstChild("Edificios")
			if edificios then
				for _, e in ipairs(edificios:GetChildren()) do
					agregarBloque(bloques, e, "edificio", 218, 226, 238)
				end
			end

			-- 6. Casas (techos coloniales terracota/ladrillo)
			local casas = cuadricula:FindFirstChild("Casas")
			if casas then
				for _, c in ipairs(casas:GetChildren()) do
					agregarBloque(bloques, c, "edificio", 214, 158, 122)
				end
			end
		end

		-- 7. Zonas exteriores y carreteras de cordillera
		local exteriores = mapaFolder:FindFirstChild("ZonasExterioresCordillera")
		if exteriores then
			for _, obj in ipairs(exteriores:GetChildren()) do
				if obj.Name:find("Carretera") then
					agregarBloque(bloques, obj, "via", 72, 78, 90)
				elseif obj:IsA("Model") and obj.Name:find("Zona_") then
					agregarBloque(bloques, obj, "zona", 140, 165, 185)
				end
			end
		end

		-- 8. Edificios principales del mapa
		for _, obj in ipairs(mapaFolder:GetChildren()) do
			if obj:IsA("Model") and (obj.Name:find("Zona_") or obj.Name:find("Edificio_") or obj.Name:find("Tienda_")) then
				agregarBloque(bloques, obj, "zona", 225, 215, 175)
			end
		end
	end

	-- 7. Hospital dinámico si ya existe
	local hospital = Workspace:FindFirstChild("HospitalDulceEsperanza")
	if hospital then
		agregarBloque(bloques, hospital, "zona", 220, 235, 245)
	end

	return bloques
end

local function obtenerPosicionesPuntos(): { [string]: Vector3 }
	local mapaPosiciones: { [string]: Vector3 } = {}
	for _, def in ipairs(PuntosMapa.Puntos) do
		local pos = def.PosicionFallback
		if def.RutaWorkspace then
			local actual: Instance = Workspace
			local encontrado = true
			for _, n in ipairs(def.RutaWorkspace) do
				local sig = actual:FindFirstChild(n)
				if not sig then
					encontrado = false
					break
				end
				actual = sig
			end
			if encontrado then
				if actual:IsA("BasePart") then
					pos = actual.Position
				elseif actual:IsA("Model") then
					local ok, cf, size = pcall(function()
						return actual:GetBoundingBox()
					end)
					if ok and cf and size and size.Magnitude > 0.1 then
						pos = cf.Position
					end
				end
			end
		elseif def.BuscarPorNombre then
			local inst = Workspace:FindFirstChild(def.BuscarPorNombre, true)
			if inst then
				if inst:IsA("BasePart") then
					pos = inst.Position
				elseif inst:IsA("Model") then
					local ok, cf, size = pcall(function()
						return inst:GetBoundingBox()
					end)
					if ok and cf and size and size.Magnitude > 0.1 then
						pos = cf.Position
					end
				end
			end
		end
		mapaPosiciones[def.Id] = pos
	end
	return mapaPosiciones
end

-- Crear RemoteFunction en ReplicatedStorage
local rf = ReplicatedStorage:FindFirstChild("ObtenerDatosMapaGPS")
if not rf then
	rf = Instance.new("RemoteFunction")
	rf.Name = "ObtenerDatosMapaGPS"
	rf.Parent = ReplicatedStorage
end

pcall(function()
	(rf :: RemoteFunction).OnServerInvoke = function(_player: Player)
		if not _cacheBloques then
			_cacheBloques = construirGeometria()
		end
		return {
			Bloques = _cacheBloques,
			Posiciones = obtenerPosicionesPuntos(),
		}
	end
end)

-- Pre-calentar caché tras 1.5s para incluir entidades generadas al inicio (Hospital, Dante)
task.delay(1.5, function()
	_cacheBloques = construirGeometria()
end)
