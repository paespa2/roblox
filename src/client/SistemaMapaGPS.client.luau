--!strict
--[[
	SistemaMapaGPS.client.luau
	Sistema completo de Mapa Interactivo, Minimapa Radar en tiempo real
	y Navegación GPS 3D (Pathfinding + Ruta en el suelo + Marcadores).
	El Patrón del Dulce
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local PathfindingService = game:GetService("PathfindingService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Datos = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Datos"))
local PuntosMapa = Datos.PuntosMapa

-- ============================================================================
-- CONFIGURACIÓN Y CONSTANTES VISUALES
-- ============================================================================
local TECLA_MAPA = Enum.KeyCode.M
local DISTANCIA_LLEGADA = 22
local INTERVALO_RECALCULO_RUTA = 1.4
local MIN_ZOOM_MAPA = 0.22
local MAX_ZOOM_MAPA = 1.75
local ZOOM_INICIAL_MAPA = 0.48

local TAMANOS_MINIMAPA = {
	P = { Ancho = 165, Alto = 185, Zoom = 0.38, Nombre = "Pequeño" },
	M = { Ancho = 220, Alto = 248, Zoom = 0.42, Nombre = "Mediano" },
	G = { Ancho = 320, Alto = 360, Zoom = 0.46, Nombre = "Grande" },
}
local _tamanoMinimapaActual = "M"
local _zoomMinimapaActual = 0.42 -- píxeles por stud en minimapa (ajustable)

local COLOR_FONDO_PANEL = Color3.fromRGB(18, 22, 29)
local COLOR_BORDE_PANEL = Color3.fromRGB(70, 110, 150)
local COLOR_TERRENO_FONDO = Color3.fromRGB(74, 126, 78) -- Valle y praderas verdes realistas
local COLOR_LINEA_VIA = Color3.fromRGB(255, 218, 60) -- Línea vial dorada brillante
local COLOR_RUTA_GPS = Color3.fromRGB(0, 225, 255)
local COLOR_MARCADOR_CUSTOM = Color3.fromRGB(255, 95, 210)

local DISTRITOS_MAPA = {
	{ Nombre = "CENTRO URBANO", X = 40, Z = -120 },
	{ Nombre = "ZONA COLEGIO", X = -80, Z = -240 },
	{ Nombre = "INTERNADO SUR", X = -80, Z = 880 },
	{ Nombre = "SECTOR ORIENTAL", X = 520, Z = 320 },
	{ Nombre = "CORDILLERA OESTE", X = -1120, Z = 320 },
	{ Nombre = "ARMERÍA SUR", X = -1200, Z = 800 },
	{ Nombre = "PISTA ESTE", X = 1220, Z = 160 },
}

-- ============================================================================
-- TIPOS INTERNOS
-- ============================================================================
type BloqueMapa = {
	X: number,
	Z: number,
	W: number,
	D: number,
	Tipo: string, -- "suelo" | "lote" | "via" | "edificio" | "zona"
	R: number,
	G: number,
	B: number,
}

type PuntoResuelto = {
	Id: string,
	Nombre: string,
	Categoria: string,
	Icono: string,
	Descripcion: string,
	Color: Color3,
	Posicion: Vector3,
	EsPersonalizado: boolean?,
}

-- ============================================================================
-- ESTADO DEL SISTEMA
-- ============================================================================
local _mapaAbierto = false
local _categoriaFiltro = "Todos"
local _textoBusqueda = ""
local _panMapa = Vector2.new(0, 200)
local _zoomMapa = ZOOM_INICIAL_MAPA
local _arrastrando = false
local _inicioArrastre = Vector2.zero
local _panInicio = Vector2.zero
local _arrastroDistancia = 0

local _bloquesGeometria: { BloqueMapa } = {}
local _posicionesServidor: { [string]: Vector3 } = {}
local _puntosResueltos: { PuntoResuelto } = {}
local _puntoSeleccionado: PuntoResuelto? = nil
local _marcadorPersonalizado: PuntoResuelto? = nil

-- Estado GPS Activo
local _destinoGPS: PuntoResuelto? = nil
local _waypointsRuta: { Vector3 } = {}
local _ultimoRecalculo = 0
local _calculandoRuta = false
local _ultimoOrigenCalculo = Vector3.zero

-- Carpeta local 3D para la guía visual GPS
local _carpetaRuta3D: Folder? = nil

-- ============================================================================
-- UTILIDADES DE POSICIÓN Y MUNDO
-- ============================================================================
local function obtenerPosicionJugador(): (Vector3, number)
	local char = LocalPlayer.Character
	if char then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp and hrp:IsA("BasePart") then
			local look = hrp.CFrame.LookVector
			local angulo = math.deg(math.atan2(look.X, -look.Z))
			return hrp.Position, angulo
		end
	end
	local cam = Workspace.CurrentCamera
	if cam then
		local look = cam.CFrame.LookVector
		local angulo = math.deg(math.atan2(look.X, -look.Z))
		return cam.CFrame.Position, angulo
	end
	return Vector3.new(69, 62, -199), 0
end

local function obtenerPosicionInstanciaValida(inst: Instance): Vector3?
	if inst:IsA("BasePart") then
		return inst.Position
	elseif inst:IsA("Model") then
		local ok, cf, size = pcall(function()
			return inst:GetBoundingBox()
		end)
		if ok and cf and size and size.Magnitude > 0.1 then
			return cf.Position
		end
	end
	return nil
end

local function buscarPorRuta(ruta: { string }): Instance?
	local actual: Instance = Workspace
	for _, nombre in ipairs(ruta) do
		local siguiente = actual:FindFirstChild(nombre)
		if not siguiente then
			return nil
		end
		actual = siguiente
	end
	return actual
end

local function resolverPuntosInteres()
	local lista: { PuntoResuelto } = {}
	for _, def in ipairs(PuntosMapa.Puntos) do
		local pos = _posicionesServidor[def.Id] or def.PosicionFallback
		if def.RutaWorkspace then
			local inst = buscarPorRuta(def.RutaWorkspace)
			if inst then
				local p = obtenerPosicionInstanciaValida(inst)
				if p then
					pos = p
				end
			end
		elseif def.BuscarPorNombre then
			local inst = Workspace:FindFirstChild(def.BuscarPorNombre, true)
			if inst then
				local p = obtenerPosicionInstanciaValida(inst)
				if p then
					pos = p
				end
			end
		end

		local catInfo = PuntosMapa.Categorias[def.Categoria]
		local color = if catInfo then catInfo.Color else Color3.fromRGB(220, 220, 220)

		table.insert(lista, {
			Id = def.Id,
			Nombre = def.Nombre,
			Categoria = def.Categoria,
			Icono = def.Icono,
			Descripcion = def.Descripcion,
			Color = color,
			Posicion = pos,
			EsPersonalizado = false,
		})
	end

	if _marcadorPersonalizado then
		table.insert(lista, _marcadorPersonalizado)
	end

	_puntosResueltos = lista
end

-- ============================================================================
-- CONSTRUCCIÓN DE LA INTERFAZ (MINIMAPA + MAPA COMPLETO)
-- ============================================================================
local previoGui = PlayerGui:FindFirstChild("UI_SistemaMapaGPS")
if previoGui then
	previoGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UI_SistemaMapaGPS"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 15
screenGui.Parent = PlayerGui

-- ----------------------------------------------------------------------------
-- 1. MINIMAPA / RADAR (ESQUINA INFERIOR DERECHA)
-- ----------------------------------------------------------------------------
local contenedorMinimapa = Instance.new("Frame")
contenedorMinimapa.Name = "ContenedorMinimapa"
contenedorMinimapa.Size = UDim2.fromOffset(TAMANOS_MINIMAPA.M.Ancho, TAMANOS_MINIMAPA.M.Alto)
contenedorMinimapa.AnchorPoint = Vector2.new(1, 1)
contenedorMinimapa.Position = UDim2.new(1, -20, 1, -20)
contenedorMinimapa.BackgroundColor3 = COLOR_FONDO_PANEL
contenedorMinimapa.BackgroundTransparency = 0.08
contenedorMinimapa.Parent = screenGui

local cornerMini = Instance.new("UICorner")
cornerMini.CornerRadius = UDim.new(0, 12)
cornerMini.Parent = contenedorMinimapa

local strokeMini = Instance.new("UIStroke")
strokeMini.Color = COLOR_BORDE_PANEL
strokeMini.Thickness = 2
strokeMini.Parent = contenedorMinimapa

local barraSupMini = Instance.new("Frame")
barraSupMini.Name = "BarraSuperior"
barraSupMini.Size = UDim2.new(1, 0, 0, 28)
barraSupMini.BackgroundColor3 = Color3.fromRGB(24, 29, 38)
barraSupMini.BorderSizePixel = 0
barraSupMini.Parent = contenedorMinimapa

local cornerBarraMini = Instance.new("UICorner")
cornerBarraMini.CornerRadius = UDim.new(0, 10)
cornerBarraMini.Parent = barraSupMini

-- Tirador para arrastrar y cambiar el tamaño libremente
local tiradorResize = Instance.new("TextButton")
tiradorResize.Name = "TiradorResize"
tiradorResize.Size = UDim2.fromOffset(18, 18)
tiradorResize.AnchorPoint = Vector2.new(0, 0.5)
tiradorResize.Position = UDim2.new(0, 4, 0.5, 0)
tiradorResize.BackgroundColor3 = Color3.fromRGB(36, 44, 58)
tiradorResize.BackgroundTransparency = 0.2
tiradorResize.Font = Enum.Font.GothamBold
tiradorResize.Text = "⤢"
tiradorResize.TextColor3 = Color3.fromRGB(160, 185, 220)
tiradorResize.TextSize = 12
tiradorResize.AutoButtonColor = true
tiradorResize.Parent = barraSupMini

local cornerTirador = Instance.new("UICorner")
cornerTirador.CornerRadius = UDim.new(0, 4)
cornerTirador.Parent = tiradorResize

local lblZonaMini = Instance.new("TextLabel")
lblZonaMini.Name = "LblZona"
lblZonaMini.Size = UDim2.new(1, -145, 1, 0)
lblZonaMini.Position = UDim2.fromOffset(26, 0)
lblZonaMini.BackgroundTransparency = 1
lblZonaMini.Font = Enum.Font.GothamBold
lblZonaMini.Text = "📍 Ciudad"
lblZonaMini.TextColor3 = Color3.fromRGB(220, 230, 245)
lblZonaMini.TextSize = 11
lblZonaMini.TextTruncate = Enum.TextTruncate.AtEnd
lblZonaMini.TextXAlignment = Enum.TextXAlignment.Left
lblZonaMini.Parent = barraSupMini

-- Botones para tamaños predeterminados: Pequeño (P), Mediano (M), Grande (G)
local function crearBotonTamano(nombre: string, texto: string, xOffset: number, activo: boolean): TextButton
	local btn = Instance.new("TextButton")
	btn.Name = "BtnTamano_" .. nombre
	btn.Size = UDim2.fromOffset(18, 18)
	btn.AnchorPoint = Vector2.new(1, 0.5)
	btn.Position = UDim2.new(1, xOffset, 0.5, 0)
	btn.BackgroundColor3 = if activo then Color3.fromRGB(0, 175, 240) else Color3.fromRGB(38, 46, 60)
	btn.Font = Enum.Font.GothamBold
	btn.Text = texto
	btn.TextColor3 = if activo then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(180, 192, 210)
	btn.TextSize = 10
	btn.AutoButtonColor = true
	btn.Parent = barraSupMini

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 4)
	c.Parent = btn

	return btn
end

local btnTamanoP = crearBotonTamano("P", "P", -102, false)
local btnTamanoM = crearBotonTamano("M", "M", -81, true)
local btnTamanoG = crearBotonTamano("G", "G", -60, false)

local btnAbrirMapaMini = Instance.new("TextButton")
btnAbrirMapaMini.Name = "BtnAbrirMapa"
btnAbrirMapaMini.Size = UDim2.fromOffset(52, 20)
btnAbrirMapaMini.AnchorPoint = Vector2.new(1, 0.5)
btnAbrirMapaMini.Position = UDim2.new(1, -5, 0.5, 0)
btnAbrirMapaMini.BackgroundColor3 = Color3.fromRGB(35, 115, 185)
btnAbrirMapaMini.Font = Enum.Font.FredokaOne
btnAbrirMapaMini.Text = "[M] Mapa"
btnAbrirMapaMini.TextColor3 = Color3.fromRGB(255, 255, 255)
btnAbrirMapaMini.TextSize = 10
btnAbrirMapaMini.Parent = barraSupMini

local cornerBtnMini = Instance.new("UICorner")
cornerBtnMini.CornerRadius = UDim.new(0, 6)
cornerBtnMini.Parent = btnAbrirMapaMini

local lienzoMini = Instance.new("Frame")
lienzoMini.Name = "LienzoRadar"
lienzoMini.Size = UDim2.new(1, -12, 1, -38)
lienzoMini.Position = UDim2.fromOffset(6, 32)
lienzoMini.BackgroundColor3 = COLOR_TERRENO_FONDO
lienzoMini.ClipsDescendants = true
lienzoMini.Parent = contenedorMinimapa

local cornerLienzoMini = Instance.new("UICorner")
cornerLienzoMini.CornerRadius = UDim.new(0, 8)
cornerLienzoMini.Parent = lienzoMini

-- Controles de Zoom in / Zoom out en el radar
local contenedorZoom = Instance.new("Frame")
contenedorZoom.Name = "ContenedorZoom"
contenedorZoom.Size = UDim2.fromOffset(44, 22)
contenedorZoom.AnchorPoint = Vector2.new(0, 1)
contenedorZoom.Position = UDim2.new(0, 6, 1, -6)
contenedorZoom.BackgroundColor3 = Color3.fromRGB(18, 22, 29)
contenedorZoom.BackgroundTransparency = 0.25
contenedorZoom.ZIndex = 20
contenedorZoom.Parent = lienzoMini

local cornerZoom = Instance.new("UICorner")
cornerZoom.CornerRadius = UDim.new(0, 6)
cornerZoom.Parent = contenedorZoom

local strokeZoom = Instance.new("UIStroke")
strokeZoom.Color = Color3.fromRGB(50, 65, 85)
strokeZoom.Thickness = 1
strokeZoom.Parent = contenedorZoom

local btnZoomIn = Instance.new("TextButton")
btnZoomIn.Name = "BtnZoomIn"
btnZoomIn.Size = UDim2.fromOffset(20, 20)
btnZoomIn.Position = UDim2.fromOffset(1, 1)
btnZoomIn.BackgroundTransparency = 1
btnZoomIn.Font = Enum.Font.GothamBold
btnZoomIn.Text = "+"
btnZoomIn.TextColor3 = Color3.fromRGB(220, 235, 255)
btnZoomIn.TextSize = 13
btnZoomIn.ZIndex = 21
btnZoomIn.Parent = contenedorZoom

local btnZoomOut = Instance.new("TextButton")
btnZoomOut.Name = "BtnZoomOut"
btnZoomOut.Size = UDim2.fromOffset(20, 20)
btnZoomOut.Position = UDim2.fromOffset(23, 1)
btnZoomOut.BackgroundTransparency = 1
btnZoomOut.Font = Enum.Font.GothamBold
btnZoomOut.Text = "−"
btnZoomOut.TextColor3 = Color3.fromRGB(220, 235, 255)
btnZoomOut.TextSize = 13
btnZoomOut.ZIndex = 21
btnZoomOut.Parent = contenedorZoom

local capaGeoMini = Instance.new("Frame")
capaGeoMini.Name = "CapaGeometria"
capaGeoMini.Size = UDim2.fromScale(1, 1)
capaGeoMini.BackgroundTransparency = 1
capaGeoMini.ZIndex = 1
capaGeoMini.Parent = lienzoMini

local capaRutaMini = Instance.new("Frame")
capaRutaMini.Name = "CapaRuta"
capaRutaMini.Size = UDim2.fromScale(1, 1)
capaRutaMini.BackgroundTransparency = 1
capaRutaMini.ZIndex = 6
capaRutaMini.Parent = lienzoMini

local capaPOIMini = Instance.new("Frame")
capaPOIMini.Name = "CapaPOI"
capaPOIMini.Size = UDim2.fromScale(1, 1)
capaPOIMini.BackgroundTransparency = 1
capaPOIMini.ZIndex = 7
capaPOIMini.Parent = lienzoMini

local badgeNorte = Instance.new("TextLabel")
badgeNorte.Name = "Norte"
badgeNorte.Size = UDim2.fromOffset(18, 16)
badgeNorte.AnchorPoint = Vector2.new(0.5, 0)
badgeNorte.Position = UDim2.new(0.5, 0, 0, 4)
badgeNorte.BackgroundColor3 = Color3.fromRGB(16, 19, 26)
badgeNorte.BackgroundTransparency = 0.2
badgeNorte.Font = Enum.Font.GothamBlack
badgeNorte.Text = "N"
badgeNorte.TextColor3 = Color3.fromRGB(255, 90, 90)
badgeNorte.TextSize = 11
badgeNorte.ZIndex = 12
badgeNorte.Parent = lienzoMini

local cornerNorte = Instance.new("UICorner")
cornerNorte.CornerRadius = UDim.new(0, 4)
cornerNorte.Parent = badgeNorte

local flechaJugadorMini = Instance.new("TextLabel")
flechaJugadorMini.Name = "FlechaJugador"
flechaJugadorMini.Size = UDim2.fromOffset(22, 22)
flechaJugadorMini.AnchorPoint = Vector2.new(0.5, 0.5)
flechaJugadorMini.Position = UDim2.fromScale(0.5, 0.5)
flechaJugadorMini.BackgroundTransparency = 1
flechaJugadorMini.Font = Enum.Font.GothamBlack
flechaJugadorMini.Text = "▲"
flechaJugadorMini.TextColor3 = Color3.fromRGB(80, 255, 140)
flechaJugadorMini.TextStrokeColor3 = Color3.fromRGB(10, 20, 15)
flechaJugadorMini.TextStrokeTransparency = 0
flechaJugadorMini.TextSize = 18
flechaJugadorMini.ZIndex = 14
flechaJugadorMini.Parent = lienzoMini

local indicadorBordeGPS = Instance.new("Frame")
indicadorBordeGPS.Name = "IndicadorBordeGPS"
indicadorBordeGPS.Size = UDim2.fromOffset(22, 22)
indicadorBordeGPS.AnchorPoint = Vector2.new(0.5, 0.5)
indicadorBordeGPS.BackgroundColor3 = COLOR_RUTA_GPS
indicadorBordeGPS.Visible = false
indicadorBordeGPS.ZIndex = 13
indicadorBordeGPS.Parent = lienzoMini

local cornerIndGPS = Instance.new("UICorner")
cornerIndGPS.CornerRadius = UDim.new(1, 0)
cornerIndGPS.Parent = indicadorBordeGPS

local lblIndGPS = Instance.new("TextLabel")
lblIndGPS.Size = UDim2.fromScale(1, 1)
lblIndGPS.BackgroundTransparency = 1
lblIndGPS.Font = Enum.Font.GothamBold
lblIndGPS.Text = "📍"
lblIndGPS.TextSize = 12
lblIndGPS.ZIndex = 14
lblIndGPS.Parent = indicadorBordeGPS

local btnClickRadar = Instance.new("TextButton")
btnClickRadar.Size = UDim2.fromScale(1, 1)
btnClickRadar.BackgroundTransparency = 1
btnClickRadar.Text = ""
btnClickRadar.ZIndex = 5 -- Debajo de los controles de zoom (20-21)
btnClickRadar.Parent = lienzoMini

local pillEstadoGPS = Instance.new("Frame")
pillEstadoGPS.Name = "PillEstadoGPS"
pillEstadoGPS.Size = UDim2.fromOffset(TAMANOS_MINIMAPA.M.Ancho, 44)
pillEstadoGPS.AnchorPoint = Vector2.new(1, 1)
pillEstadoGPS.Position = UDim2.new(1, -20, 1, -(TAMANOS_MINIMAPA.M.Alto + 28))
pillEstadoGPS.BackgroundColor3 = Color3.fromRGB(14, 34, 46)
pillEstadoGPS.BackgroundTransparency = 0.08
pillEstadoGPS.Visible = false
pillEstadoGPS.Parent = screenGui

local cornerPillGPS = Instance.new("UICorner")
cornerPillGPS.CornerRadius = UDim.new(0, 10)
cornerPillGPS.Parent = pillEstadoGPS

local strokePillGPS = Instance.new("UIStroke")
strokePillGPS.Color = COLOR_RUTA_GPS
strokePillGPS.Thickness = 1.8
strokePillGPS.Parent = pillEstadoGPS

local lblDestinoGPS = Instance.new("TextLabel")
lblDestinoGPS.Size = UDim2.new(1, -34, 0, 20)
lblDestinoGPS.Position = UDim2.fromOffset(8, 3)
lblDestinoGPS.BackgroundTransparency = 1
lblDestinoGPS.Font = Enum.Font.FredokaOne
lblDestinoGPS.Text = "🧭 Destino"
lblDestinoGPS.TextColor3 = Color3.fromRGB(220, 250, 255)
lblDestinoGPS.TextSize = 13
lblDestinoGPS.TextTruncate = Enum.TextTruncate.AtEnd
lblDestinoGPS.TextXAlignment = Enum.TextXAlignment.Left
lblDestinoGPS.Parent = pillEstadoGPS

local lblDistanciaGPS = Instance.new("TextLabel")
lblDistanciaGPS.Size = UDim2.new(1, -34, 0, 18)
lblDistanciaGPS.Position = UDim2.fromOffset(8, 22)
lblDistanciaGPS.BackgroundTransparency = 1
lblDistanciaGPS.Font = Enum.Font.GothamBold
lblDistanciaGPS.Text = "0 m"
lblDistanciaGPS.TextColor3 = COLOR_RUTA_GPS
lblDistanciaGPS.TextSize = 12
lblDistanciaGPS.TextXAlignment = Enum.TextXAlignment.Left
lblDistanciaGPS.Parent = pillEstadoGPS

local btnCancelarGPSMini = Instance.new("TextButton")
btnCancelarGPSMini.Size = UDim2.fromOffset(22, 22)
btnCancelarGPSMini.AnchorPoint = Vector2.new(1, 0.5)
btnCancelarGPSMini.Position = UDim2.new(1, -6, 0.5, 0)
btnCancelarGPSMini.BackgroundColor3 = Color3.fromRGB(160, 45, 55)
btnCancelarGPSMini.Font = Enum.Font.GothamBold
btnCancelarGPSMini.Text = "✕"
btnCancelarGPSMini.TextColor3 = Color3.fromRGB(255, 255, 255)
btnCancelarGPSMini.TextSize = 12
btnCancelarGPSMini.Parent = pillEstadoGPS

local cornerCancelMini = Instance.new("UICorner")
cornerCancelMini.CornerRadius = UDim.new(0, 6)
cornerCancelMini.Parent = btnCancelarGPSMini

local function actualizarPosicionPillGPS(altoMinimapa: number?, anchoMinimapa: number?)
	local h = altoMinimapa or contenedorMinimapa.AbsoluteSize.Y
	local w = anchoMinimapa or contenedorMinimapa.AbsoluteSize.X
	pillEstadoGPS.Position = UDim2.new(1, -20, 1, -(h + 28))
	pillEstadoGPS.Size = UDim2.fromOffset(math.max(w, 180), 44)
end

local function aplicarTamanoMinimapa(clave: string, animado: boolean?)
	local cfg = TAMANOS_MINIMAPA[clave]
	if not cfg then return end
	_tamanoMinimapaActual = clave
	_zoomMinimapaActual = cfg.Zoom

	btnTamanoP.BackgroundColor3 = if clave == "P" then Color3.fromRGB(0, 175, 240) else Color3.fromRGB(38, 46, 60)
	btnTamanoP.TextColor3 = if clave == "P" then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(180, 192, 210)

	btnTamanoM.BackgroundColor3 = if clave == "M" then Color3.fromRGB(0, 175, 240) else Color3.fromRGB(38, 46, 60)
	btnTamanoM.TextColor3 = if clave == "M" then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(180, 192, 210)

	btnTamanoG.BackgroundColor3 = if clave == "G" then Color3.fromRGB(0, 175, 240) else Color3.fromRGB(38, 46, 60)
	btnTamanoG.TextColor3 = if clave == "G" then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(180, 192, 210)

	if clave == "P" then
		btnAbrirMapaMini.Text = "[M]"
		btnAbrirMapaMini.Size = UDim2.fromOffset(34, 20)
		btnTamanoP.Position = UDim2.new(1, -84, 0.5, 0)
		btnTamanoM.Position = UDim2.new(1, -63, 0.5, 0)
		btnTamanoG.Position = UDim2.new(1, -42, 0.5, 0)
		lblZonaMini.Size = UDim2.new(1, -114, 1, 0)
	else
		btnAbrirMapaMini.Text = "[M] Mapa"
		btnAbrirMapaMini.Size = UDim2.fromOffset(52, 20)
		btnTamanoP.Position = UDim2.new(1, -102, 0.5, 0)
		btnTamanoM.Position = UDim2.new(1, -81, 0.5, 0)
		btnTamanoG.Position = UDim2.new(1, -60, 0.5, 0)
		lblZonaMini.Size = UDim2.new(1, -145, 1, 0)
	end

	local nuevoSize = UDim2.fromOffset(cfg.Ancho, cfg.Alto)
	if animado ~= false then
		local tw = TweenService:Create(
			contenedorMinimapa,
			TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = nuevoSize }
		)
		tw:Play()
	else
		contenedorMinimapa.Size = nuevoSize
	end
	actualizarPosicionPillGPS(cfg.Alto, cfg.Ancho)
end

local bannerLlegada = Instance.new("Frame")
bannerLlegada.Name = "BannerLlegada"
bannerLlegada.Size = UDim2.fromOffset(320, 42)
bannerLlegada.AnchorPoint = Vector2.new(0.5, 1)
bannerLlegada.Position = UDim2.new(0.5, 0, 1, -110)
bannerLlegada.BackgroundColor3 = Color3.fromRGB(18, 46, 32)
bannerLlegada.BackgroundTransparency = 0.08
bannerLlegada.Visible = false
bannerLlegada.Parent = screenGui

local cornerLlegada = Instance.new("UICorner")
cornerLlegada.CornerRadius = UDim.new(0, 10)
cornerLlegada.Parent = bannerLlegada

local strokeLlegada = Instance.new("UIStroke")
strokeLlegada.Color = Color3.fromRGB(70, 235, 135)
strokeLlegada.Thickness = 2
strokeLlegada.Parent = bannerLlegada

local lblLlegada = Instance.new("TextLabel")
lblLlegada.Size = UDim2.fromScale(1, 1)
lblLlegada.BackgroundTransparency = 1
lblLlegada.Font = Enum.Font.FredokaOne
lblLlegada.Text = "✅ ¡Has llegado a tu destino!"
lblLlegada.TextColor3 = Color3.fromRGB(215, 255, 225)
lblLlegada.TextSize = 15
lblLlegada.Parent = bannerLlegada

-- ----------------------------------------------------------------------------
-- 2. MAPA INTERACTIVO COMPLETO (PANTALLA CENTRAL)
-- ----------------------------------------------------------------------------
local fondoOscuro = Instance.new("Frame")
fondoOscuro.Name = "FondoMapaCompleto"
fondoOscuro.Size = UDim2.fromScale(1, 1)
fondoOscuro.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
fondoOscuro.BackgroundTransparency = 0.45
fondoOscuro.Visible = false
fondoOscuro.ZIndex = 20
fondoOscuro.Parent = screenGui

local panelMapa = Instance.new("Frame")
panelMapa.Name = "PanelMapa"
panelMapa.Size = UDim2.fromScale(0.88, 0.86)
panelMapa.AnchorPoint = Vector2.new(0.5, 0.5)
panelMapa.Position = UDim2.fromScale(0.5, 0.5)
panelMapa.BackgroundColor3 = COLOR_FONDO_PANEL
panelMapa.ZIndex = 21
panelMapa.Parent = fondoOscuro

local cornerPanelMapa = Instance.new("UICorner")
cornerPanelMapa.CornerRadius = UDim.new(0, 14)
cornerPanelMapa.Parent = panelMapa

local strokePanelMapa = Instance.new("UIStroke")
strokePanelMapa.Color = COLOR_BORDE_PANEL
strokePanelMapa.Thickness = 2
strokePanelMapa.Parent = panelMapa

local cabeceraMapa = Instance.new("Frame")
cabeceraMapa.Name = "Cabecera"
cabeceraMapa.Size = UDim2.new(1, 0, 0, 54)
cabeceraMapa.BackgroundColor3 = Color3.fromRGB(22, 27, 36)
cabeceraMapa.BorderSizePixel = 0
cabeceraMapa.ZIndex = 22
cabeceraMapa.Parent = panelMapa

local cornerCab = Instance.new("UICorner")
cornerCab.CornerRadius = UDim.new(0, 14)
cornerCab.Parent = cabeceraMapa

local tituloMapa = Instance.new("TextLabel")
tituloMapa.Size = UDim2.new(0, 320, 1, 0)
tituloMapa.Position = UDim2.fromOffset(18, 0)
tituloMapa.BackgroundTransparency = 1
tituloMapa.Font = Enum.Font.FredokaOne
tituloMapa.Text = "🗺️ MAPA DE LA CIUDAD Y GPS"
tituloMapa.TextColor3 = Color3.fromRGB(255, 225, 130)
tituloMapa.TextSize = 20
tituloMapa.TextXAlignment = Enum.TextXAlignment.Left
tituloMapa.ZIndex = 23
tituloMapa.Parent = cabeceraMapa

local instruccionMapa = Instance.new("TextLabel")
instruccionMapa.Size = UDim2.new(0, 400, 1, 0)
instruccionMapa.Position = UDim2.fromOffset(330, 0)
instruccionMapa.BackgroundTransparency = 1
instruccionMapa.Font = Enum.Font.Gotham
instruccionMapa.Text = "Arrastra para mover • Rueda para zoom • Clic para marcador"
instruccionMapa.TextColor3 = Color3.fromRGB(165, 180, 200)
instruccionMapa.TextSize = 12
instruccionMapa.TextXAlignment = Enum.TextXAlignment.Left
instruccionMapa.ZIndex = 23
instruccionMapa.Parent = cabeceraMapa

local btnCerrarMapa = Instance.new("TextButton")
btnCerrarMapa.Size = UDim2.fromOffset(92, 34)
btnCerrarMapa.AnchorPoint = Vector2.new(1, 0.5)
btnCerrarMapa.Position = UDim2.new(1, -14, 0.5, 0)
btnCerrarMapa.BackgroundColor3 = Color3.fromRGB(175, 45, 55)
btnCerrarMapa.Font = Enum.Font.FredokaOne
btnCerrarMapa.Text = "✕ Cerrar"
btnCerrarMapa.TextColor3 = Color3.fromRGB(255, 255, 255)
btnCerrarMapa.TextSize = 14
btnCerrarMapa.ZIndex = 23
btnCerrarMapa.Parent = cabeceraMapa

local cornerCerrarMapa = Instance.new("UICorner")
cornerCerrarMapa.CornerRadius = UDim.new(0, 8)
cornerCerrarMapa.Parent = btnCerrarMapa

local barraLateral = Instance.new("Frame")
barraLateral.Name = "BarraLateral"
barraLateral.Size = UDim2.new(0, 290, 1, -66)
barraLateral.Position = UDim2.fromOffset(10, 60)
barraLateral.BackgroundColor3 = Color3.fromRGB(20, 24, 33)
barraLateral.ZIndex = 22
barraLateral.Parent = panelMapa

local cornerLateral = Instance.new("UICorner")
cornerLateral.CornerRadius = UDim.new(0, 10)
cornerLateral.Parent = barraLateral

local cajaBusqueda = Instance.new("TextBox")
cajaBusqueda.Name = "CajaBusqueda"
cajaBusqueda.Size = UDim2.new(1, -16, 0, 34)
cajaBusqueda.Position = UDim2.fromOffset(8, 8)
cajaBusqueda.BackgroundColor3 = Color3.fromRGB(30, 36, 48)
cajaBusqueda.PlaceholderText = "🔍 Buscar tienda, cocina, zona..."
cajaBusqueda.PlaceholderColor3 = Color3.fromRGB(130, 145, 165)
cajaBusqueda.Text = ""
cajaBusqueda.TextColor3 = Color3.fromRGB(240, 245, 255)
cajaBusqueda.Font = Enum.Font.Gotham
cajaBusqueda.TextSize = 13
cajaBusqueda.ClearTextOnFocus = false
cajaBusqueda.ZIndex = 23
cajaBusqueda.Parent = barraLateral

local cornerBusqueda = Instance.new("UICorner")
cornerBusqueda.CornerRadius = UDim.new(0, 8)
cornerBusqueda.Parent = cajaBusqueda

local gridCategorias = Instance.new("Frame")
gridCategorias.Name = "FiltrosCategoria"
gridCategorias.Size = UDim2.new(1, -16, 0, 64)
gridCategorias.Position = UDim2.fromOffset(8, 48)
gridCategorias.BackgroundTransparency = 1
gridCategorias.ZIndex = 23
gridCategorias.Parent = barraLateral

local layoutCats = Instance.new("UIGridLayout")
layoutCats.CellSize = UDim2.new(0.32, 0, 0, 26)
layoutCats.CellPadding = UDim2.fromOffset(4, 4)
layoutCats.SortOrder = Enum.SortOrder.LayoutOrder
layoutCats.Parent = gridCategorias

local listaPuntosScroll = Instance.new("ScrollingFrame")
listaPuntosScroll.Name = "ListaPuntos"
listaPuntosScroll.Size = UDim2.new(1, -16, 1, -124)
listaPuntosScroll.Position = UDim2.fromOffset(8, 118)
listaPuntosScroll.BackgroundTransparency = 1
listaPuntosScroll.BorderSizePixel = 0
listaPuntosScroll.ScrollBarThickness = 5
listaPuntosScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
listaPuntosScroll.CanvasSize = UDim2.fromOffset(0, 0)
listaPuntosScroll.ZIndex = 23
listaPuntosScroll.Parent = barraLateral

local layoutLista = Instance.new("UIListLayout")
layoutLista.Padding = UDim.new(0, 6)
layoutLista.SortOrder = Enum.SortOrder.LayoutOrder
layoutLista.Parent = listaPuntosScroll

local areaDerecha = Instance.new("Frame")
areaDerecha.Name = "AreaDerecha"
areaDerecha.Size = UDim2.new(1, -314, 1, -66)
areaDerecha.Position = UDim2.fromOffset(306, 60)
areaDerecha.BackgroundTransparency = 1
areaDerecha.ZIndex = 22
areaDerecha.Parent = panelMapa

local lienzoMapa = Instance.new("Frame")
lienzoMapa.Name = "LienzoMapa"
lienzoMapa.Size = UDim2.new(1, 0, 1, -82)
lienzoMapa.BackgroundColor3 = COLOR_TERRENO_FONDO
lienzoMapa.ClipsDescendants = true
lienzoMapa.ZIndex = 22
lienzoMapa.Parent = areaDerecha

local cornerLienzoMapa = Instance.new("UICorner")
cornerLienzoMapa.CornerRadius = UDim.new(0, 10)
cornerLienzoMapa.Parent = lienzoMapa

local strokeLienzoMapa = Instance.new("UIStroke")
strokeLienzoMapa.Color = Color3.fromRGB(48, 58, 76)
strokeLienzoMapa.Thickness = 1.5
strokeLienzoMapa.Parent = lienzoMapa

local capaGeoMapa = Instance.new("Frame")
capaGeoMapa.Size = UDim2.fromScale(1, 1)
capaGeoMapa.BackgroundTransparency = 1
capaGeoMapa.ZIndex = 23
capaGeoMapa.Parent = lienzoMapa

local capaDistritosMapa = Instance.new("Frame")
capaDistritosMapa.Size = UDim2.fromScale(1, 1)
capaDistritosMapa.BackgroundTransparency = 1
capaDistritosMapa.ZIndex = 27
capaDistritosMapa.Parent = lienzoMapa

local capaRutaMapa = Instance.new("Frame")
capaRutaMapa.Size = UDim2.fromScale(1, 1)
capaRutaMapa.BackgroundTransparency = 1
capaRutaMapa.ZIndex = 28
capaRutaMapa.Parent = lienzoMapa

local capaPOIMapa = Instance.new("Frame")
capaPOIMapa.Size = UDim2.fromScale(1, 1)
capaPOIMapa.BackgroundTransparency = 1
capaPOIMapa.ZIndex = 30
capaPOIMapa.Parent = lienzoMapa

local capaJugadoresMapa = Instance.new("Frame")
capaJugadoresMapa.Size = UDim2.fromScale(1, 1)
capaJugadoresMapa.BackgroundTransparency = 1
capaJugadoresMapa.ZIndex = 32
capaJugadoresMapa.Parent = lienzoMapa

local barraControles = Instance.new("Frame")
barraControles.Size = UDim2.fromOffset(40, 128)
barraControles.AnchorPoint = Vector2.new(1, 0)
barraControles.Position = UDim2.new(1, -12, 0, 12)
barraControles.BackgroundTransparency = 1
barraControles.ZIndex = 35
barraControles.Parent = lienzoMapa

local layoutControles = Instance.new("UIListLayout")
layoutControles.Padding = UDim.new(0, 6)
layoutControles.Parent = barraControles

local function crearBotonControl(texto: string): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(38, 38)
	btn.BackgroundColor3 = Color3.fromRGB(28, 34, 46)
	btn.Font = Enum.Font.GothamBold
	btn.Text = texto
	btn.TextColor3 = Color3.fromRGB(230, 240, 255)
	btn.TextSize = 18
	btn.ZIndex = 36
	btn.Parent = barraControles

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = btn

	local s = Instance.new("UIStroke")
	s.Color = COLOR_BORDE_PANEL
	s.Thickness = 1
	s.Parent = btn
	return btn
end

local btnZoomMas = crearBotonControl("+")
local btnZoomMenos = crearBotonControl("−")
local btnCentrar = crearBotonControl("🎯")

local barraDetalle = Instance.new("Frame")
barraDetalle.Name = "BarraDetalle"
barraDetalle.Size = UDim2.new(1, 0, 0, 74)
barraDetalle.AnchorPoint = Vector2.new(0, 1)
barraDetalle.Position = UDim2.fromScale(0, 1)
barraDetalle.BackgroundColor3 = Color3.fromRGB(22, 27, 36)
barraDetalle.ZIndex = 23
barraDetalle.Parent = areaDerecha

local cornerDetalle = Instance.new("UICorner")
cornerDetalle.CornerRadius = UDim.new(0, 10)
cornerDetalle.Parent = barraDetalle

local lblDetalleTitulo = Instance.new("TextLabel")
lblDetalleTitulo.Size = UDim2.new(1, -240, 0, 26)
lblDetalleTitulo.Position = UDim2.fromOffset(14, 10)
lblDetalleTitulo.BackgroundTransparency = 1
lblDetalleTitulo.Font = Enum.Font.FredokaOne
lblDetalleTitulo.Text = "📍 Selecciona un punto o haz clic en el mapa"
lblDetalleTitulo.TextColor3 = Color3.fromRGB(240, 245, 255)
lblDetalleTitulo.TextSize = 17
lblDetalleTitulo.TextXAlignment = Enum.TextXAlignment.Left
lblDetalleTitulo.ZIndex = 24
lblDetalleTitulo.Parent = barraDetalle

local lblDetalleDesc = Instance.new("TextLabel")
lblDetalleDesc.Size = UDim2.new(1, -240, 0, 28)
lblDetalleDesc.Position = UDim2.fromOffset(14, 38)
lblDetalleDesc.BackgroundTransparency = 1
lblDetalleDesc.Font = Enum.Font.Gotham
lblDetalleDesc.Text = "El GPS calculará la ruta óptima y te guiará con señales en la calle."
lblDetalleDesc.TextColor3 = Color3.fromRGB(165, 180, 200)
lblDetalleDesc.TextSize = 13
lblDetalleDesc.TextTruncate = Enum.TextTruncate.AtEnd
lblDetalleDesc.TextXAlignment = Enum.TextXAlignment.Left
lblDetalleDesc.ZIndex = 24
lblDetalleDesc.Parent = barraDetalle

local btnAccionGPS = Instance.new("TextButton")
btnAccionGPS.Name = "BtnAccionGPS"
btnAccionGPS.Size = UDim2.fromOffset(205, 44)
btnAccionGPS.AnchorPoint = Vector2.new(1, 0.5)
btnAccionGPS.Position = UDim2.new(1, -14, 0.5, 0)
btnAccionGPS.BackgroundColor3 = Color3.fromRGB(0, 155, 210)
btnAccionGPS.Font = Enum.Font.FredokaOne
btnAccionGPS.Text = "🧭 FIJAR RUTA GPS"
btnAccionGPS.TextColor3 = Color3.fromRGB(255, 255, 255)
btnAccionGPS.TextSize = 15
btnAccionGPS.Visible = false
btnAccionGPS.ZIndex = 24
btnAccionGPS.Parent = barraDetalle

local cornerAccionGPS = Instance.new("UICorner")
cornerAccionGPS.CornerRadius = UDim.new(0, 10)
cornerAccionGPS.Parent = btnAccionGPS

-- ============================================================================
-- MOTOR DE RUTA GPS 3D Y PATHFINDING
-- ============================================================================
local function asegurarCarpetaRuta3D(): Folder
	if _carpetaRuta3D and _carpetaRuta3D.Parent then
		return _carpetaRuta3D
	end
	local existente = Workspace:FindFirstChild("_GPS_RutaLocal")
	if existente and existente:IsA("Folder") then
		_carpetaRuta3D = existente
		return existente
	end
	local carpeta = Instance.new("Folder")
	carpeta.Name = "_GPS_RutaLocal"
	carpeta.Parent = Workspace
	_carpetaRuta3D = carpeta
	return carpeta
end

local function limpiarRuta3D()
	if _carpetaRuta3D then
		_carpetaRuta3D:ClearAllChildren()
	end
end

local function obtenerAlturaSuelo(pos: Vector3): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local excluidos: { Instance } = {}
	if LocalPlayer.Character then
		table.insert(excluidos, LocalPlayer.Character)
	end
	if _carpetaRuta3D then
		table.insert(excluidos, _carpetaRuta3D)
	end
	params.FilterDescendantsInstances = excluidos

	local resultado = Workspace:Raycast(Vector3.new(pos.X, pos.Y + 40, pos.Z), Vector3.new(0, -120, 0), params)
	if resultado then
		return resultado.Position.Y
	end
	return pos.Y
end

local function renderizarRuta3D()
	local destino = _destinoGPS
	if not destino or #_waypointsRuta == 0 then
		limpiarRuta3D()
		return
	end

	local carpeta = asegurarCarpetaRuta3D()
	carpeta:ClearAllChildren()

	local posJugador = obtenerPosicionJugador()

	local puntos = { Vector3.new(posJugador.X, obtenerAlturaSuelo(posJugador) + 0.6, posJugador.Z) }
	for _, wp in ipairs(_waypointsRuta) do
		local ySuelo = obtenerAlturaSuelo(wp)
		table.insert(puntos, Vector3.new(wp.X, ySuelo + 0.6, wp.Z))
	end

	for i = 1, #puntos - 1 do
		local a = puntos[i]
		local b = puntos[i + 1]
		local delta = b - a
		local dist = delta.Magnitude
		if dist > 1 then
			local tramo = Instance.new("Part")
			tramo.Name = "TramoGPS_" .. i
			tramo.Anchored = true
			tramo.CanCollide = false
			tramo.CanTouch = false
			tramo.CanQuery = false
			tramo.CastShadow = false
			tramo.Material = Enum.Material.Neon
			tramo.Color = COLOR_RUTA_GPS
			tramo.Transparency = 0.25
			tramo.Size = Vector3.new(1.5, 0.25, dist)
			tramo.CFrame = CFrame.lookAt((a + b) * 0.5, b)
			tramo.Parent = carpeta
		end
	end

	local yDest = obtenerAlturaSuelo(destino.Posicion)
	local posDest = Vector3.new(destino.Posicion.X, yDest, destino.Posicion.Z)

	local baliza = Instance.new("Part")
	baliza.Name = "BalizaDestinoGPS"
	baliza.Anchored = true
	baliza.CanCollide = false
	baliza.CanTouch = false
	baliza.CanQuery = false
	baliza.CastShadow = false
	baliza.Material = Enum.Material.Neon
	baliza.Color = destino.Color
	baliza.Transparency = 0.65
	baliza.Size = Vector3.new(3.2, 65, 3.2)
	baliza.Position = posDest + Vector3.new(0, 32.5, 0)
	baliza.Parent = carpeta

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(200, 56)
	billboard.StudsOffset = Vector3.new(0, 12, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 3000
	billboard.Parent = baliza

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundColor3 = Color3.fromRGB(14, 22, 32)
	lbl.BackgroundTransparency = 0.2
	lbl.Font = Enum.Font.FredokaOne
	lbl.Text = string.format("%s %s", destino.Icono, destino.Nombre)
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.TextSize = 14
	lbl.TextWrapped = true
	lbl.Parent = billboard

	local cBill = Instance.new("UICorner")
	cBill.CornerRadius = UDim.new(0, 8)
	cBill.Parent = lbl
end

local function calcularRutaGPSAsync()
	if _calculandoRuta or not _destinoGPS then
		return
	end
	_calculandoRuta = true
	local destinoActual = _destinoGPS
	local origen = obtenerPosicionJugador()
	_ultimoOrigenCalculo = origen

	task.spawn(function()
		local path = PathfindingService:CreatePath({
			AgentRadius = 3.0,
			AgentHeight = 5.5,
			AgentCanJump = true,
			WaypointSpacing = 18,
		})

		local ok = pcall(function()
			path:ComputeAsync(origen, destinoActual.Posicion)
		end)

		if _destinoGPS ~= destinoActual then
			_calculandoRuta = false
			return
		end

		local nuevosPuntos: { Vector3 } = {}
		if ok and path.Status == Enum.PathStatus.Success then
			local wps = path:GetWaypoints()
			for i = 2, #wps do
				table.insert(nuevosPuntos, wps[i].Position)
			end
		end

		if #nuevosPuntos == 0 then
			local totalVec = destinoActual.Posicion - origen
			local dist = totalVec.Magnitude
			local pasos = math.clamp(math.floor(dist / 60), 1, 20)
			for i = 1, pasos do
				table.insert(nuevosPuntos, origen:Lerp(destinoActual.Posicion, i / pasos))
			end
		end

		_waypointsRuta = nuevosPuntos
		renderizarRuta3D()
		_calculandoRuta = false
	end)
end

local function cancelarRutaGPS()
	_destinoGPS = nil
	_waypointsRuta = {}
	limpiarRuta3D()
	pillEstadoGPS.Visible = false
	indicadorBordeGPS.Visible = false
end

local function reproducirSonidoLlegada()
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://4590657391"
	sound.Volume = 0.6
	sound.Parent = SoundService
	sound:Play()
	task.delay(2.5, function()
		sound:Destroy()
	end)
end

local function mostrarBannerLlegada(nombreDestino: string)
	lblLlegada.Text = "✅ ¡Has llegado a " .. nombreDestino .. "!"
	bannerLlegada.Visible = true
	bannerLlegada.BackgroundTransparency = 0.1
	task.delay(3.0, function()
		if bannerLlegada.Visible then
			bannerLlegada.Visible = false
		end
	end)
end

local function iniciarRutaGPS(punto: PuntoResuelto)
	_destinoGPS = punto
	_ultimoRecalculo = 0
	pillEstadoGPS.Visible = true
	actualizarPosicionPillGPS()
	lblDestinoGPS.Text = string.format("%s %s", punto.Icono, punto.Nombre)
	calcularRutaGPSAsync()
end

-- ============================================================================
-- RENDERIZADO 2D (MINIMAPA + MAPA COMPLETO)
-- ============================================================================
local function crearSegmento2D(padre: Frame, x1: number, y1: number, x2: number, y2: number, grosor: number, color: Color3, zIndex: number)
	local dx = x2 - x1
	local dy = y2 - y1
	local len = math.sqrt(dx * dx + dy * dy)
	if len < 1 then
		return
	end
	local seg = Instance.new("Frame")
	seg.AnchorPoint = Vector2.new(0.5, 0.5)
	seg.Position = UDim2.fromOffset((x1 + x2) * 0.5, (y1 + y2) * 0.5)
	seg.Size = UDim2.fromOffset(len + grosor * 0.4, grosor)
	seg.Rotation = math.deg(math.atan2(dy, dx))
	seg.BackgroundColor3 = color
	seg.BorderSizePixel = 0
	seg.ZIndex = zIndex
	seg.Parent = padre
end

type ItemGeoVisual = {
	Bloque: BloqueMapa,
	FrameMapa: Frame,
	FrameMini: Frame,
	LineaViaMapa: Frame?,
	LineaViaMini: Frame?,
}

local _itemsGeoVisual: { ItemGeoVisual } = {}

local function zIndexParaTipo(tipo: string, esMapaCompleto: boolean): number
	local base = if esMapaCompleto then 22 else 1
	if tipo == "suelo" then
		return base
	elseif tipo == "lote" then
		return base + 1
	elseif tipo == "via" then
		return base + 2
	elseif tipo == "zona" then
		return base + 3
	else -- "edificio"
		return base + 4
	end
end

local function inicializarPoolsGeometria()
	for _, item in ipairs(_itemsGeoVisual) do
		item.FrameMapa:Destroy()
		item.FrameMini:Destroy()
	end
	table.clear(_itemsGeoVisual)

	for _, b in ipairs(_bloquesGeometria) do
		local color = Color3.fromRGB(b.R, b.G, b.B)

		local fMapa = Instance.new("Frame")
		fMapa.AnchorPoint = Vector2.new(0.5, 0.5)
		fMapa.BackgroundColor3 = color
		fMapa.BorderSizePixel = 0
		fMapa.ZIndex = zIndexParaTipo(b.Tipo, true)
		fMapa.Parent = capaGeoMapa

		local fMini = Instance.new("Frame")
		fMini.AnchorPoint = Vector2.new(0.5, 0.5)
		fMini.BackgroundColor3 = color
		fMini.BorderSizePixel = 0
		fMini.ZIndex = zIndexParaTipo(b.Tipo, false)
		fMini.Parent = capaGeoMini

		-- Detalle realista: borde sutil en edificios y línea central en vías
		local lineaMapa: Frame? = nil
		local lineaMini: Frame? = nil

		if b.Tipo == "edificio" or b.Tipo == "zona" then
			local s1 = Instance.new("UIStroke")
			s1.Color = Color3.fromRGB(22, 26, 34)
			s1.Thickness = 1
			s1.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			s1.Parent = fMapa

			local s2 = Instance.new("UIStroke")
			s2.Color = Color3.fromRGB(22, 26, 34)
			s2.Thickness = 1
			s2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			s2.Parent = fMini
		elseif b.Tipo == "via" then
			local l1 = Instance.new("Frame")
			l1.AnchorPoint = Vector2.new(0.5, 0.5)
			l1.Position = UDim2.fromScale(0.5, 0.5)
			l1.BackgroundColor3 = COLOR_LINEA_VIA
			l1.BackgroundTransparency = 0.35
			l1.BorderSizePixel = 0
			l1.ZIndex = fMapa.ZIndex
			l1.Parent = fMapa
			lineaMapa = l1

			local l2 = Instance.new("Frame")
			l2.AnchorPoint = Vector2.new(0.5, 0.5)
			l2.Position = UDim2.fromScale(0.5, 0.5)
			l2.BackgroundColor3 = COLOR_LINEA_VIA
			l2.BackgroundTransparency = 0.45
			l2.BorderSizePixel = 0
			l2.ZIndex = fMini.ZIndex
			l2.Parent = fMini
			lineaMini = l2
		end

		table.insert(_itemsGeoVisual, {
			Bloque = b,
			FrameMapa = fMapa,
			FrameMini = fMini,
			LineaViaMapa = lineaMapa,
			LineaViaMini = lineaMini,
		})
	end
end

local function actualizarDetalleUI()
	local sel = _puntoSeleccionado
	if not sel then
		lblDetalleTitulo.Text = "📍 Selecciona un punto o haz clic en el mapa"
		lblDetalleDesc.Text = "El GPS calculará la ruta óptima y te guiará con señales en la calle."
		btnAccionGPS.Visible = false
		return
	end

	local posJugador = obtenerPosicionJugador()
	local dist = math.floor((sel.Posicion - posJugador).Magnitude)
	lblDetalleTitulo.Text = string.format("%s %s (%d m)", sel.Icono, sel.Nombre, dist)
	lblDetalleDesc.Text = sel.Descripcion
	btnAccionGPS.Visible = true

	if _destinoGPS and _destinoGPS.Id == sel.Id then
		btnAccionGPS.Text = "🛑 CANCELAR RUTA GPS"
		btnAccionGPS.BackgroundColor3 = Color3.fromRGB(185, 55, 65)
	else
		btnAccionGPS.Text = "🧭 FIJAR RUTA GPS"
		btnAccionGPS.BackgroundColor3 = Color3.fromRGB(0, 155, 210)
	end
end

local actualizarListaLateral

actualizarListaLateral = function()
	for _, child in ipairs(listaPuntosScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local posJugador = obtenerPosicionJugador()
	local filtrados: { { Punto: PuntoResuelto, Dist: number } } = {}
	local busquedaLower = string.lower(_textoBusqueda)

	for _, p in ipairs(_puntosResueltos) do
		local pasaCat = (_categoriaFiltro == "Todos") or (p.Categoria == _categoriaFiltro)
		local pasaBusq = (busquedaLower == "") or (string.find(string.lower(p.Nombre), busquedaLower, 1, true) ~= nil)
		if pasaCat and pasaBusq then
			local dist = (p.Posicion - posJugador).Magnitude
			table.insert(filtrados, { Punto = p, Dist = dist })
		end
	end

	table.sort(filtrados, function(a, b)
		return a.Dist < b.Dist
	end)

	for idx, item in ipairs(filtrados) do
		local p = item.Punto
		local esActivo = _destinoGPS and _destinoGPS.Id == p.Id
		local esSel = _puntoSeleccionado and _puntoSeleccionado.Id == p.Id

		local card = Instance.new("Frame")
		card.Name = "Card_" .. p.Id
		card.Size = UDim2.new(1, -6, 0, 52)
		card.BackgroundColor3 = if esActivo
			then Color3.fromRGB(18, 48, 64)
			elseif esSel then Color3.fromRGB(36, 44, 60)
			else Color3.fromRGB(27, 32, 42)
		card.LayoutOrder = idx
		card.ZIndex = 24
		card.Parent = listaPuntosScroll

		local cCard = Instance.new("UICorner")
		cCard.CornerRadius = UDim.new(0, 8)
		cCard.Parent = card

		local sCard = Instance.new("UIStroke")
		sCard.Color = if esActivo then COLOR_RUTA_GPS elseif esSel then p.Color else Color3.fromRGB(45, 54, 70)
		sCard.Thickness = if esActivo or esSel then 1.5 else 1
		sCard.Parent = card

		local lblIcon = Instance.new("TextLabel")
		lblIcon.Size = UDim2.fromOffset(32, 32)
		lblIcon.Position = UDim2.fromOffset(8, 10)
		lblIcon.BackgroundColor3 = p.Color
		lblIcon.BackgroundTransparency = 0.78
		lblIcon.Font = Enum.Font.GothamBold
		lblIcon.Text = p.Icono
		lblIcon.TextSize = 18
		lblIcon.ZIndex = 25
		lblIcon.Parent = card

		local cIcon = Instance.new("UICorner")
		cIcon.CornerRadius = UDim.new(1, 0)
		cIcon.Parent = lblIcon

		local lblNom = Instance.new("TextLabel")
		lblNom.Size = UDim2.new(1, -104, 0, 22)
		lblNom.Position = UDim2.fromOffset(46, 6)
		lblNom.BackgroundTransparency = 1
		lblNom.Font = Enum.Font.GothamBold
		lblNom.Text = p.Nombre
		lblNom.TextColor3 = Color3.fromRGB(235, 242, 255)
		lblNom.TextSize = 12
		lblNom.TextTruncate = Enum.TextTruncate.AtEnd
		lblNom.TextXAlignment = Enum.TextXAlignment.Left
		lblNom.ZIndex = 25
		lblNom.Parent = card

		local lblDist = Instance.new("TextLabel")
		lblDist.Size = UDim2.new(1, -104, 0, 18)
		lblDist.Position = UDim2.fromOffset(46, 28)
		lblDist.BackgroundTransparency = 1
		lblDist.Font = Enum.Font.Gotham
		lblDist.Text = string.format("%s • %d m", p.Categoria, math.floor(item.Dist))
		lblDist.TextColor3 = p.Color
		lblDist.TextSize = 11
		lblDist.TextXAlignment = Enum.TextXAlignment.Left
		lblDist.ZIndex = 25
		lblDist.Parent = card

		local btnIr = Instance.new("TextButton")
		btnIr.Size = UDim2.fromOffset(46, 30)
		btnIr.AnchorPoint = Vector2.new(1, 0.5)
		btnIr.Position = UDim2.new(1, -8, 0.5, 0)
		btnIr.BackgroundColor3 = if esActivo then Color3.fromRGB(185, 55, 65) else Color3.fromRGB(0, 145, 200)
		btnIr.Font = Enum.Font.FredokaOne
		btnIr.Text = if esActivo then "✕" else "🧭 Ir"
		btnIr.TextColor3 = Color3.fromRGB(255, 255, 255)
		btnIr.TextSize = 12
		btnIr.ZIndex = 26
		btnIr.Parent = card

		local cIr = Instance.new("UICorner")
		cIr.CornerRadius = UDim.new(0, 6)
		cIr.Parent = btnIr

		local btnFondoCard = Instance.new("TextButton")
		btnFondoCard.Size = UDim2.new(1, -56, 1, 0)
		btnFondoCard.BackgroundTransparency = 1
		btnFondoCard.Text = ""
		btnFondoCard.ZIndex = 25
		btnFondoCard.Parent = card

		btnFondoCard.MouseButton1Click:Connect(function()
			_puntoSeleccionado = p
			_panMapa = Vector2.new(p.Posicion.X, p.Posicion.Z)
			actualizarDetalleUI()
			actualizarListaLateral()
		end)

		btnIr.MouseButton1Click:Connect(function()
			_puntoSeleccionado = p
			if _destinoGPS and _destinoGPS.Id == p.Id then
				cancelarRutaGPS()
			else
				iniciarRutaGPS(p)
				_panMapa = Vector2.new(p.Posicion.X, p.Posicion.Z)
			end
			actualizarDetalleUI()
			actualizarListaLateral()
		end)
	end
end

local function actualizarBloqueVisual(f: Frame, linea: Frame?, b: BloqueMapa, sx: number, sy: number, sw: number, sh: number, ancho: number, alto: number)
	if sx + sw < 0 or sx - sw > ancho or sy + sh < 0 or sy - sh > alto then
		f.Visible = false
		return
	end
	f.Visible = true
	f.Position = UDim2.fromOffset(sx, sy)
	f.Size = UDim2.fromOffset(sw, sh)

	if linea then
		if sw > sh * 1.4 then
			linea.Size = UDim2.new(1, -2, 0, 1)
			linea.Visible = true
		elseif sh > sw * 1.4 then
			linea.Size = UDim2.new(0, 1, 1, -2)
			linea.Visible = true
		else
			linea.Visible = false
		end
	end
end

local function renderizarMapaCompleto()
	if not _mapaAbierto then
		return
	end

	local ancho = lienzoMapa.AbsoluteSize.X
	local alto = lienzoMapa.AbsoluteSize.Y
	if ancho <= 0 or alto <= 0 then
		return
	end
	local cx = ancho * 0.5
	local cy = alto * 0.5

	for _, item in ipairs(_itemsGeoVisual) do
		local b = item.Bloque
		local sx = cx + (b.X - _panMapa.X) * _zoomMapa
		local sy = cy + (b.Z - _panMapa.Y) * _zoomMapa
		local sw = math.max(b.W * _zoomMapa, 2)
		local sh = math.max(b.D * _zoomMapa, 2)
		actualizarBloqueVisual(item.FrameMapa, item.LineaViaMapa, b, sx, sy, sw, sh, ancho, alto)
	end

	-- Etiquetas de distritos
	for _, c in ipairs(capaDistritosMapa:GetChildren()) do
		c:Destroy()
	end
	for _, d in ipairs(DISTRITOS_MAPA) do
		local dx = cx + (d.X - _panMapa.X) * _zoomMapa
		local dy = cy + (d.Z - _panMapa.Y) * _zoomMapa
		if dx >= -80 and dx <= ancho + 80 and dy >= -30 and dy <= alto + 30 then
			local lbl = Instance.new("TextLabel")
			lbl.AnchorPoint = Vector2.new(0.5, 0.5)
			lbl.Position = UDim2.fromOffset(dx, dy)
			lbl.Size = UDim2.fromOffset(180, 20)
			lbl.BackgroundTransparency = 1
			lbl.Font = Enum.Font.GothamBlack
			lbl.Text = d.Nombre
			lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
			lbl.TextTransparency = 0.72
			lbl.TextSize = 11
			lbl.ZIndex = 27
			lbl.Parent = capaDistritosMapa
		end
	end

	for _, c in ipairs(capaRutaMapa:GetChildren()) do
		c:Destroy()
	end
	local posJugador, yawJugador = obtenerPosicionJugador()
	if _destinoGPS and #_waypointsRuta > 0 then
		local prevX = cx + (posJugador.X - _panMapa.X) * _zoomMapa
		local prevY = cy + (posJugador.Z - _panMapa.Y) * _zoomMapa
		for _, wp in ipairs(_waypointsRuta) do
			local nx = cx + (wp.X - _panMapa.X) * _zoomMapa
			local ny = cy + (wp.Z - _panMapa.Y) * _zoomMapa
			crearSegmento2D(capaRutaMapa, prevX, prevY, nx, ny, 3.5, COLOR_RUTA_GPS, 28)
			prevX, prevY = nx, ny
		end
	end

	for _, c in ipairs(capaPOIMapa:GetChildren()) do
		c:Destroy()
	end
	for _, p in ipairs(_puntosResueltos) do
		if _categoriaFiltro == "Todos" or p.Categoria == _categoriaFiltro or p.EsPersonalizado then
			local px = cx + (p.Posicion.X - _panMapa.X) * _zoomMapa
			local py = cy + (p.Posicion.Z - _panMapa.Y) * _zoomMapa
			if px >= -24 and px <= ancho + 24 and py >= -24 and py <= alto + 24 then
				local esSel = _puntoSeleccionado and _puntoSeleccionado.Id == p.Id
				local esGPS = _destinoGPS and _destinoGPS.Id == p.Id

				local pin = Instance.new("TextButton")
				pin.AnchorPoint = Vector2.new(0.5, 0.5)
				pin.Position = UDim2.fromOffset(px, py)
				pin.Size = if esSel or esGPS then UDim2.fromOffset(30, 30) else UDim2.fromOffset(24, 24)
				pin.BackgroundColor3 = if esGPS then COLOR_RUTA_GPS else p.Color
				pin.Font = Enum.Font.GothamBold
				pin.Text = p.Icono
				pin.TextSize = if esSel or esGPS then 16 else 13
				pin.ZIndex = if esSel or esGPS then 31 else 30
				pin.Parent = capaPOIMapa

				local cPin = Instance.new("UICorner")
				cPin.CornerRadius = UDim.new(1, 0)
				cPin.Parent = pin

				local sPin = Instance.new("UIStroke")
				sPin.Color = if esSel or esGPS then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(16, 19, 26)
				sPin.Thickness = if esSel or esGPS then 2 else 1.2
				sPin.Parent = pin

				if _zoomMapa >= 0.42 or esSel or esGPS then
					local etiqueta = Instance.new("TextLabel")
					etiqueta.AnchorPoint = Vector2.new(0.5, 0)
					etiqueta.Position = UDim2.new(0.5, 0, 1, 2)
					etiqueta.Size = UDim2.fromOffset(130, 16)
					etiqueta.BackgroundColor3 = Color3.fromRGB(14, 17, 24)
					etiqueta.BackgroundTransparency = 0.25
					etiqueta.Font = Enum.Font.GothamBold
					etiqueta.Text = p.Nombre
					etiqueta.TextColor3 = Color3.fromRGB(240, 245, 255)
					etiqueta.TextSize = 10
					etiqueta.TextTruncate = Enum.TextTruncate.AtEnd
					etiqueta.ZIndex = 31
					etiqueta.Parent = pin

					local cEt = Instance.new("UICorner")
					cEt.CornerRadius = UDim.new(0, 4)
					cEt.Parent = etiqueta
				end

				pin.MouseButton1Click:Connect(function()
					_puntoSeleccionado = p
					actualizarDetalleUI()
					actualizarListaLateral()
					renderizarMapaCompleto()
				end)
			end
		end
	end

	for _, c in ipairs(capaJugadoresMapa:GetChildren()) do
		c:Destroy()
	end

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
			if hrp and hrp:IsA("BasePart") then
				local px = cx + (hrp.Position.X - _panMapa.X) * _zoomMapa
				local py = cy + (hrp.Position.Z - _panMapa.Y) * _zoomMapa
				if px >= 0 and px <= ancho and py >= 0 and py <= alto then
					local dot = Instance.new("Frame")
					dot.AnchorPoint = Vector2.new(0.5, 0.5)
					dot.Position = UDim2.fromOffset(px, py)
					dot.Size = UDim2.fromOffset(10, 10)
					dot.BackgroundColor3 = Color3.fromRGB(120, 210, 255)
					dot.ZIndex = 32
					dot.Parent = capaJugadoresMapa
					local cDot = Instance.new("UICorner")
					cDot.CornerRadius = UDim.new(1, 0)
					cDot.Parent = dot
				end
			end
		end
	end

	local jx = cx + (posJugador.X - _panMapa.X) * _zoomMapa
	local jy = cy + (posJugador.Z - _panMapa.Y) * _zoomMapa
	local flecha = Instance.new("TextLabel")
	flecha.AnchorPoint = Vector2.new(0.5, 0.5)
	flecha.Position = UDim2.fromOffset(jx, jy)
	flecha.Size = UDim2.fromOffset(24, 24)
	flecha.BackgroundTransparency = 1
	flecha.Font = Enum.Font.GothamBlack
	flecha.Text = "▲"
	flecha.TextColor3 = Color3.fromRGB(80, 255, 140)
	flecha.TextStrokeTransparency = 0
	flecha.TextSize = 20
	flecha.Rotation = yawJugador
	flecha.ZIndex = 33
	flecha.Parent = capaJugadoresMapa
end

local function actualizarMinimapa(posJugador: Vector3, yawJugador: number)
	local ancho = lienzoMini.AbsoluteSize.X
	local alto = lienzoMini.AbsoluteSize.Y
	if ancho <= 0 or alto <= 0 then
		return
	end
	local cx = ancho * 0.5
	local cy = alto * 0.5

	flechaJugadorMini.Rotation = yawJugador

	local radioMax = (math.max(ancho, alto) * 0.5) / _zoomMinimapaActual + 50
	for _, item in ipairs(_itemsGeoVisual) do
		local b = item.Bloque
		local dx = b.X - posJugador.X
		local dz = b.Z - posJugador.Z
		if math.abs(dx) > radioMax + b.W * 0.5 or math.abs(dz) > radioMax + b.D * 0.5 then
			item.FrameMini.Visible = false
		else
			local sx = cx + dx * _zoomMinimapaActual
			local sy = cy + dz * _zoomMinimapaActual
			local sw = math.max(b.W * _zoomMinimapaActual, 2)
			local sh = math.max(b.D * _zoomMinimapaActual, 2)
			actualizarBloqueVisual(item.FrameMini, item.LineaViaMini, b, sx, sy, sw, sh, ancho, alto)
		end
	end

	for _, c in ipairs(capaRutaMini:GetChildren()) do
		c:Destroy()
	end
	if _destinoGPS and #_waypointsRuta > 0 then
		local prevX, prevY = cx, cy
		for _, wp in ipairs(_waypointsRuta) do
			local nx = cx + (wp.X - posJugador.X) * _zoomMinimapaActual
			local ny = cy + (wp.Z - posJugador.Z) * _zoomMinimapaActual
			crearSegmento2D(capaRutaMini, prevX, prevY, nx, ny, 2.8, COLOR_RUTA_GPS, 6)
			prevX, prevY = nx, ny
		end
	end

	for _, c in ipairs(capaPOIMini:GetChildren()) do
		c:Destroy()
	end
	local masCercano: PuntoResuelto? = nil
	local distMin = math.huge

	for _, p in ipairs(_puntosResueltos) do
		local d = (p.Posicion - posJugador).Magnitude
		if d < distMin and not p.EsPersonalizado then
			distMin = d
			masCercano = p
		end

		local px = cx + (p.Posicion.X - posJugador.X) * _zoomMinimapaActual
		local py = cy + (p.Posicion.Z - posJugador.Z) * _zoomMinimapaActual
		if px >= -8 and px <= ancho + 8 and py >= -8 and py <= alto + 8 then
			local pin = Instance.new("TextLabel")
			pin.AnchorPoint = Vector2.new(0.5, 0.5)
			pin.Position = UDim2.fromOffset(px, py)
			pin.Size = UDim2.fromOffset(20, 20)
			pin.BackgroundColor3 = p.Color
			pin.BackgroundTransparency = 0.1
			pin.Font = Enum.Font.GothamBold
			pin.Text = p.Icono
			pin.TextSize = 12
			pin.ZIndex = 8
			pin.Parent = capaPOIMini

			local cPin = Instance.new("UICorner")
			cPin.CornerRadius = UDim.new(1, 0)
			cPin.Parent = pin

			local sPin = Instance.new("UIStroke")
			sPin.Color = Color3.fromRGB(16, 19, 26)
			sPin.Thickness = 1.2
			sPin.Parent = pin
		end
	end

	if masCercano then
		lblZonaMini.Text = string.format("📍 %s", masCercano.Nombre)
	end

	if _destinoGPS then
		local dx = (_destinoGPS.Posicion.X - posJugador.X) * _zoomMinimapaActual
		local dy = (_destinoGPS.Posicion.Z - posJugador.Z) * _zoomMinimapaActual
		local margenX = cx - 14
		local margenY = cy - 14
		if math.abs(dx) > margenX or math.abs(dy) > margenY then
			local escala = math.min(margenX / math.max(math.abs(dx), 0.001), margenY / math.max(math.abs(dy), 0.001))
			indicadorBordeGPS.Position = UDim2.fromOffset(cx + dx * escala, cy + dy * escala)
			indicadorBordeGPS.Visible = true
		else
			indicadorBordeGPS.Visible = false
		end
	else
		indicadorBordeGPS.Visible = false
	end
end

-- ============================================================================
-- BOTONES DE FILTROS Y EVENTOS DE INTERACCIÓN
-- ============================================================================
local _botonesFiltro: { [string]: TextButton } = {}

local function actualizarEstilosFiltros()
	for id, btn in pairs(_botonesFiltro) do
		local activo = (_categoriaFiltro == id)
		btn.BackgroundColor3 = if activo then Color3.fromRGB(0, 145, 200) else Color3.fromRGB(30, 36, 48)
		btn.TextColor3 = if activo then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(185, 198, 218)
	end
end

do
	local listaCats = { { Id = "Todos", Nombre = "Todos", Orden = 0 } }
	for _, cat in pairs(PuntosMapa.Categorias) do
		table.insert(listaCats, cat)
	end
	table.sort(listaCats, function(a, b)
		return a.Orden < b.Orden
	end)

	for _, cat in ipairs(listaCats) do
		local btn = Instance.new("TextButton")
		btn.Name = "Filtro_" .. cat.Id
		btn.BackgroundColor3 = Color3.fromRGB(30, 36, 48)
		btn.Font = Enum.Font.GothamBold
		btn.Text = cat.Nombre
		btn.TextSize = 11
		btn.LayoutOrder = cat.Orden
		btn.ZIndex = 24
		btn.Parent = gridCategorias

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = btn

		_botonesFiltro[cat.Id] = btn
		btn.MouseButton1Click:Connect(function()
			_categoriaFiltro = cat.Id
			actualizarEstilosFiltros()
			actualizarListaLateral()
			renderizarMapaCompleto()
		end)
	end
	actualizarEstilosFiltros()
end

local function alternarMapa(forzarEstado: boolean?)
	local nuevoEstado = if forzarEstado ~= nil then forzarEstado else not _mapaAbierto
	if nuevoEstado == _mapaAbierto then
		return
	end
	_mapaAbierto = nuevoEstado
	fondoOscuro.Visible = _mapaAbierto

	if _mapaAbierto then
		resolverPuntosInteres()
		local posJugador = obtenerPosicionJugador()
		_panMapa = Vector2.new(posJugador.X, posJugador.Z)
		actualizarListaLateral()
		actualizarDetalleUI()
		renderizarMapaCompleto()
	end
end

btnTamanoP.MouseButton1Click:Connect(function()
	aplicarTamanoMinimapa("P")
end)

btnTamanoM.MouseButton1Click:Connect(function()
	aplicarTamanoMinimapa("M")
end)

btnTamanoG.MouseButton1Click:Connect(function()
	aplicarTamanoMinimapa("G")
end)

btnZoomIn.MouseButton1Click:Connect(function()
	_zoomMinimapaActual = math.clamp(math.floor((_zoomMinimapaActual + 0.08) * 100) / 100, 0.20, 0.85)
end)

btnZoomOut.MouseButton1Click:Connect(function()
	_zoomMinimapaActual = math.clamp(math.floor((_zoomMinimapaActual - 0.08) * 100) / 100, 0.20, 0.85)
end)

local _arrastrandoResize = false
local _posInicialMouse: Vector2 = Vector2.zero
local _tamInicialFrame: Vector2 = Vector2.zero

tiradorResize.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		_arrastrandoResize = true
		_posInicialMouse = Vector2.new(input.Position.X, input.Position.Y)
		_tamInicialFrame = contenedorMinimapa.AbsoluteSize
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if _arrastrandoResize then
			_arrastrandoResize = false
		end
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if _arrastrandoResize and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local currentMouse = Vector2.new(input.Position.X, input.Position.Y)
		local deltaX = _posInicialMouse.X - currentMouse.X
		local deltaY = _posInicialMouse.Y - currentMouse.Y
		local nuevoAncho = math.clamp(math.floor(_tamInicialFrame.X + deltaX), 150, 440)
		local nuevoAlto = math.clamp(math.floor(_tamInicialFrame.Y + deltaY), 170, 480)
		contenedorMinimapa.Size = UDim2.fromOffset(nuevoAncho, nuevoAlto)

		if nuevoAncho < 185 then
			_tamanoMinimapaActual = "P"
			btnAbrirMapaMini.Text = "[M]"
			btnAbrirMapaMini.Size = UDim2.fromOffset(34, 20)
			btnTamanoP.Position = UDim2.new(1, -84, 0.5, 0)
			btnTamanoM.Position = UDim2.new(1, -63, 0.5, 0)
			btnTamanoG.Position = UDim2.new(1, -42, 0.5, 0)
			lblZonaMini.Size = UDim2.new(1, -114, 1, 0)
		else
			if nuevoAncho > 265 then
				_tamanoMinimapaActual = "G"
			else
				_tamanoMinimapaActual = "M"
			end
			btnAbrirMapaMini.Text = "[M] Mapa"
			btnAbrirMapaMini.Size = UDim2.fromOffset(52, 20)
			btnTamanoP.Position = UDim2.new(1, -102, 0.5, 0)
			btnTamanoM.Position = UDim2.new(1, -81, 0.5, 0)
			btnTamanoG.Position = UDim2.new(1, -60, 0.5, 0)
			lblZonaMini.Size = UDim2.new(1, -145, 1, 0)
		end

		btnTamanoP.BackgroundColor3 = if _tamanoMinimapaActual == "P" then Color3.fromRGB(0, 175, 240) else Color3.fromRGB(38, 46, 60)
		btnTamanoP.TextColor3 = if _tamanoMinimapaActual == "P" then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(180, 192, 210)
		btnTamanoM.BackgroundColor3 = if _tamanoMinimapaActual == "M" then Color3.fromRGB(0, 175, 240) else Color3.fromRGB(38, 46, 60)
		btnTamanoM.TextColor3 = if _tamanoMinimapaActual == "M" then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(180, 192, 210)
		btnTamanoG.BackgroundColor3 = if _tamanoMinimapaActual == "G" then Color3.fromRGB(0, 175, 240) else Color3.fromRGB(38, 46, 60)
		btnTamanoG.TextColor3 = if _tamanoMinimapaActual == "G" then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(180, 192, 210)

		actualizarPosicionPillGPS(nuevoAlto, nuevoAncho)
	end
end)

btnAbrirMapaMini.MouseButton1Click:Connect(function()
	alternarMapa(true)
end)
btnClickRadar.MouseButton1Click:Connect(function()
	alternarMapa(true)
end)
btnCerrarMapa.MouseButton1Click:Connect(function()
	alternarMapa(false)
end)
btnCancelarGPSMini.MouseButton1Click:Connect(function()
	cancelarRutaGPS()
	if _mapaAbierto then
		actualizarDetalleUI()
		actualizarListaLateral()
		renderizarMapaCompleto()
	end
end)

btnAccionGPS.MouseButton1Click:Connect(function()
	if not _puntoSeleccionado then
		return
	end
	if _destinoGPS and _destinoGPS.Id == _puntoSeleccionado.Id then
		cancelarRutaGPS()
	else
		iniciarRutaGPS(_puntoSeleccionado)
	end
	actualizarDetalleUI()
	actualizarListaLateral()
	renderizarMapaCompleto()
end)

btnZoomMas.MouseButton1Click:Connect(function()
	_zoomMapa = math.clamp(_zoomMapa * 1.25, MIN_ZOOM_MAPA, MAX_ZOOM_MAPA)
	renderizarMapaCompleto()
end)

btnZoomMenos.MouseButton1Click:Connect(function()
	_zoomMapa = math.clamp(_zoomMapa * 0.8, MIN_ZOOM_MAPA, MAX_ZOOM_MAPA)
	renderizarMapaCompleto()
end)

btnCentrar.MouseButton1Click:Connect(function()
	local posJugador = obtenerPosicionJugador()
	_panMapa = Vector2.new(posJugador.X, posJugador.Z)
	renderizarMapaCompleto()
end)

cajaBusqueda:GetPropertyChangedSignal("Text"):Connect(function()
	_textoBusqueda = cajaBusqueda.Text
	actualizarListaLateral()
end)

lienzoMapa.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		_arrastrando = true
		_inicioArrastre = Vector2.new(input.Position.X, input.Position.Y)
		_panInicio = _panMapa
		_arrastroDistancia = 0
	end
end)

lienzoMapa.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		local factor = if input.Position.Z > 0 then 1.15 else 0.87
		_zoomMapa = math.clamp(_zoomMapa * factor, MIN_ZOOM_MAPA, MAX_ZOOM_MAPA)
		renderizarMapaCompleto()
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not _arrastrando or not _mapaAbierto then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		local actual = Vector2.new(input.Position.X, input.Position.Y)
		local delta = actual - _inicioArrastre
		_arrastroDistancia = math.max(_arrastroDistancia, delta.Magnitude)
		_panMapa = _panInicio - (delta / _zoomMapa)
		renderizarMapaCompleto()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if _arrastrando and _mapaAbierto and _arrastroDistancia < 6 then
			local absPos = lienzoMapa.AbsolutePosition
			local absSize = lienzoMapa.AbsoluteSize
			local mx = input.Position.X - absPos.X
			local my = input.Position.Y - absPos.Y
			if mx >= 0 and mx <= absSize.X and my >= 0 and my <= absSize.Y then
				local worldX = _panMapa.X + (mx - absSize.X * 0.5) / _zoomMapa
				local worldZ = _panMapa.Y + (my - absSize.Y * 0.5) / _zoomMapa
				local altura = obtenerAlturaSuelo(Vector3.new(worldX, 80, worldZ))

				local custom: PuntoResuelto = {
					Id = "marcador_personalizado",
					Nombre = "Marcador Personalizado",
					Categoria = "Especial",
					Icono = "📌",
					Descripcion = string.format("Destino manual en coordenadas (%.0f, %.0f).", worldX, worldZ),
					Color = COLOR_MARCADOR_CUSTOM,
					Posicion = Vector3.new(worldX, altura, worldZ),
					EsPersonalizado = true,
				}
				_marcadorPersonalizado = custom
				resolverPuntosInteres()
				_puntoSeleccionado = custom
				iniciarRutaGPS(custom)
				actualizarDetalleUI()
				actualizarListaLateral()
				renderizarMapaCompleto()
			end
		end
		_arrastrando = false
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == TECLA_MAPA then
		alternarMapa()
	elseif input.KeyCode == Enum.KeyCode.Escape and _mapaAbierto then
		alternarMapa(false)
	end
end)

-- ============================================================================
-- INICIALIZACIÓN Y BUCLE EN TIEMPO REAL
-- ============================================================================
task.spawn(function()
	local rf = ReplicatedStorage:WaitForChild("ObtenerDatosMapaGPS", 10)
	if rf and rf:IsA("RemoteFunction") then
		local ok, data = pcall(function()
			return rf:InvokeServer()
		end)
		if ok and data and data.Bloques then
			_bloquesGeometria = data.Bloques
			if data.Posiciones then
				_posicionesServidor = data.Posiciones
			end
		end
	end
	resolverPuntosInteres()
	inicializarPoolsGeometria()
end)

local _acumuladorMapa = 0
local _acumuladorRefrescoPOI = 0

RunService.RenderStepped:Connect(function(dt)
	local posJugador, yawJugador = obtenerPosicionJugador()

	actualizarMinimapa(posJugador, yawJugador)

	if _destinoGPS then
		local distancia = (Vector3.new(_destinoGPS.Posicion.X, posJugador.Y, _destinoGPS.Posicion.Z) - posJugador).Magnitude
		lblDistanciaGPS.Text = string.format("%d m hasta el destino", math.floor(distancia))

		if distancia <= DISTANCIA_LLEGADA then
			local nombreLlegada = _destinoGPS.Nombre
			cancelarRutaGPS()
			reproducirSonidoLlegada()
			mostrarBannerLlegada(nombreLlegada)
			if _mapaAbierto then
				actualizarDetalleUI()
				actualizarListaLateral()
				renderizarMapaCompleto()
			end
		else
			_ultimoRecalculo += dt
			local desvio = (posJugador - _ultimoOrigenCalculo).Magnitude
			if _ultimoRecalculo >= INTERVALO_RECALCULO_RUTA or desvio >= 28 then
				_ultimoRecalculo = 0
				calcularRutaGPSAsync()
			end
		end
	end

	_acumuladorRefrescoPOI += dt
	if _acumuladorRefrescoPOI >= 5.0 then
		_acumuladorRefrescoPOI = 0
		resolverPuntosInteres()
	end

	if _mapaAbierto then
		_acumuladorMapa += dt
		if _acumuladorMapa >= 0.15 then
			_acumuladorMapa = 0
			renderizarMapaCompleto()
		end
	end
end)
