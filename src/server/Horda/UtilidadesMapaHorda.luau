--!strict
--[[
	UtilidadesMapaHorda.luau
	Utilidades espaciales compartidas para validar suelo, evitar techos/muros
	y localizar puntos válidos para Dante y las apariciones de zombis.
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local UtilidadesMapaHorda = {}

local NOMBRES_IGNORAR_SUELO = {
	"techo",
	"teja",
	"cubierta",
	"dintel",
	"alero",
	"toldo",
	"cobertizo",
	"marquesina",
	"cielo",
	"losa",
	"banderin",
	"poste",
	"foco",
	"letrero",
	"cartel",
	"lampara",
	"baranda",
	"valla",
	"banca",
	"asiento",
	"mesa",
	"rama",
	"copa",
	"hoja",
}

local function esSuperficieIgnorable(instancia: BasePart): boolean
	if not instancia.CanCollide then
		return true
	end
	local n = string.lower(instancia.Name)
	for _, patron in ipairs(NOMBRES_IGNORAR_SUELO) do
		if string.find(n, patron, 1, true) then
			return true
		end
	end
	return false
end

function UtilidadesMapaHorda.ObtenerCarpetaSistema(): Folder
	local carpeta = Workspace:FindFirstChild("HordaSistema")
	if not carpeta then
		local nueva = Instance.new("Folder")
		nueva.Name = "HordaSistema"
		nueva.Parent = Workspace
		carpeta = nueva
	end
	return carpeta :: Folder
end

function UtilidadesMapaHorda.ObtenerCarpetaZombis(): Folder
	local sistema = UtilidadesMapaHorda.ObtenerCarpetaSistema()
	local zombis = sistema:FindFirstChild("Zombis")
	if not zombis then
		local nueva = Instance.new("Folder")
		nueva.Name = "Zombis"
		nueva.Parent = sistema
		zombis = nueva
	end
	return zombis :: Folder
end

function UtilidadesMapaHorda.ObtenerSpawnInicial(): Vector3
	-- 1. Priorizar SpawnLocation activo donde aparecen los jugadores en Studio
	local spawnLoc = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	if spawnLoc and spawnLoc.Enabled then
		return spawnLoc.Position
	end
	if spawnLoc then
		return spawnLoc.Position
	end

	-- 2. Si ya hay personajes en el servidor, usar la posición del primer jugador
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp and hrp:IsA("BasePart") then
			return hrp.Position
		end
	end

	-- 3. Buscar punto canónico del juego en Puntos.Apariciones si existe
	local puntos = Workspace:FindFirstChild("Puntos")
	if puntos then
		local apariciones = puntos:FindFirstChild("Apariciones")
		if apariciones then
			local cocina = apariciones:FindFirstChild("Punto_Cocina_Inicial")
			if cocina and cocina:IsA("BasePart") then
				return cocina.Position
			end
		end
	end

	-- 4. Respaldo canónico de barrio usado por SistemaPersecucion
	return Vector3.new(97, 63, -119)
end

function UtilidadesMapaHorda.ObtenerPosicionSuelo(
	posBase: Vector3,
	alturaCentro: number?,
	ignorarLista: { Instance }?
): (Vector3, boolean)
	local offset = alturaCentro or 3.0
	local rayOrigin = Vector3.new(posBase.X, posBase.Y + 14.0, posBase.Z)
	local rayDir = Vector3.new(0, -90, 0)

	local exclusiones: { Instance } = {}
	local sistema = Workspace:FindFirstChild("HordaSistema")
	if sistema then
		table.insert(exclusiones, sistema)
	end
	if ignorarLista then
		for _, inst in ipairs(ignorarLista) do
			table.insert(exclusiones, inst)
		end
	end
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			table.insert(exclusiones, player.Character)
		end
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	for _ = 1, 12 do
		params.FilterDescendantsInstances = exclusiones
		local hit = Workspace:Raycast(rayOrigin, rayDir, params)
		if not hit then
			break
		end

		local inst = hit.Instance
		if inst:IsA("BasePart") then
			if esSuperficieIgnorable(inst) or hit.Position.Y > (posBase.Y + 4.5) then
				table.insert(exclusiones, inst)
				rayOrigin = hit.Position - Vector3.new(0, 0.08, 0)
			elseif hit.Normal.Y < 0.7 then
				-- Superficie demasiado inclinada (muro/roca)
				return posBase, false
			else
				return Vector3.new(posBase.X, hit.Position.Y + offset, posBase.Z), true
			end
		else
			table.insert(exclusiones, inst)
		end
	end

	return posBase, false
end

function UtilidadesMapaHorda.EstaEspacioLibre(posicionCentro: Vector3, tamanoCaja: Vector3): boolean
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	local exclusiones: { Instance } = {}
	local sistema = Workspace:FindFirstChild("HordaSistema")
	if sistema then
		table.insert(exclusiones, sistema)
	end
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			table.insert(exclusiones, player.Character)
		end
	end
	params.FilterDescendantsInstances = exclusiones

	local partes = Workspace:GetPartBoundsInBox(CFrame.new(posicionCentro), tamanoCaja, params)
	for _, parte in ipairs(partes) do
		if parte.CanCollide and not esSuperficieIgnorable(parte) then
			return false
		end
	end
	return true
end

function UtilidadesMapaHorda.BuscarPosicionSeguraCercaDe(
	origen: Vector3,
	offsetsCandidatos: { Vector3 },
	alturaCentro: number
): Vector3
	for _, offset in ipairs(offsetsCandidatos) do
		local candidato = origen + offset
		local posSuelo, haySuelo = UtilidadesMapaHorda.ObtenerPosicionSuelo(candidato, alturaCentro)
		if haySuelo then
			-- Comprobar despeje del cuerpo por encima del suelo
			local centroColision = posSuelo + Vector3.new(0, 0.6, 0)
			if UtilidadesMapaHorda.EstaEspacioLibre(centroColision, Vector3.new(3.2, 4.0, 3.2)) then
				return posSuelo
			end
		end
	end
	local fallback, _ =
		UtilidadesMapaHorda.ObtenerPosicionSuelo(origen + offsetsCandidatos[1], alturaCentro)
	return fallback
end

function UtilidadesMapaHorda.ObtenerPuntosAparicionZombis(
	puntosRespaldo: { Vector3 },
	distanciaMinJugador: number,
	distanciaMaxJugador: number
): { Vector3 }
	local candidatos: { Vector3 } = {}

	-- 1. Si el mapa tiene carpeta Workspace.Puntos.Zombis con partes configuradas, priorizarlas
	local puntosFolder = Workspace:FindFirstChild("Puntos")
	local zombisFolder = puntosFolder and puntosFolder:FindFirstChild("Zombis")
	if zombisFolder then
		for _, child in ipairs(zombisFolder:GetChildren()) do
			if child:IsA("BasePart") then
				table.insert(candidatos, child.Position)
			end
		end
	end

	-- 2. Si no hay suficientes configurados en Studio, generar anillo dinámico alrededor del spawn/jugadores
	if #candidatos < 4 then
		local centroBase = UtilidadesMapaHorda.ObtenerSpawnInicial()
		for _, pos in ipairs(puntosRespaldo) do
			table.insert(candidatos, pos)
		end

		local radios = { 34, 46, 58 }
		for _, radio in ipairs(radios) do
			for anguloDeg = 0, 315, 45 do
				local rad = math.rad(anguloDeg)
				local p = centroBase + Vector3.new(math.cos(rad) * radio, 2, math.sin(rad) * radio)
				table.insert(candidatos, p)
			end
		end
	end

	-- 3. Validar suelo, despeje contra muros y distancia segura respecto a jugadores vivos
	local posicionesJugadores: { Vector3 } = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and hrp:IsA("BasePart") and hum and hum.Health > 0 then
			table.insert(posicionesJugadores, hrp.Position)
		end
	end

	local validos: { Vector3 } = {}
	for _, cand in ipairs(candidatos) do
		local posSuelo, haySuelo = UtilidadesMapaHorda.ObtenerPosicionSuelo(cand, 3.0)
		if not haySuelo then
			continue
		end

		if
			not UtilidadesMapaHorda.EstaEspacioLibre(
				posSuelo + Vector3.new(0, 0.8, 0),
				Vector3.new(3.2, 4.2, 3.2)
			)
		then
			continue
		end

		local muyCerca = false
		local alMenosUnoEnRango = #posicionesJugadores == 0
		for _, pPos in ipairs(posicionesJugadores) do
			local dist = (posSuelo - pPos).Magnitude
			if dist < distanciaMinJugador then
				muyCerca = true
				break
			end
			if dist <= distanciaMaxJugador then
				alMenosUnoEnRango = true
			end
		end

		if not muyCerca and alMenosUnoEnRango then
			table.insert(validos, posSuelo)
		end
	end

	-- Fallback si todos estaban fuera de rango (ej. jugador viajó lejos): generar anillo alrededor de un jugador vivo
	if #validos == 0 and #posicionesJugadores > 0 then
		local centro = posicionesJugadores[1]
		for anguloDeg = 0, 315, 45 do
			local rad = math.rad(anguloDeg)
			local cand = centro + Vector3.new(math.cos(rad) * 38, 2, math.sin(rad) * 38)
			local posSuelo, haySuelo = UtilidadesMapaHorda.ObtenerPosicionSuelo(cand, 3.0)
			if
				haySuelo
				and UtilidadesMapaHorda.EstaEspacioLibre(
					posSuelo + Vector3.new(0, 0.8, 0),
					Vector3.new(3.2, 4.2, 3.2)
				)
			then
				table.insert(validos, posSuelo)
			end
		end
	end

	return validos
end

return UtilidadesMapaHorda
