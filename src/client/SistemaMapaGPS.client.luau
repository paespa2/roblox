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

local sincronizarPinsVisuales: (() -> ())? = nil

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
	if sincronizarPinsVisuales then
		sincronizarPinsVisuales()
	end
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
local function crearBotonTamano(
	nombre: string,
	texto: string,
	xOffset: number,
	activo: boolean
): TextButton
	local btn = Instance.new("TextButton")
	btn.Name = "BtnTamano_" .. nombre
	btn.Size = UDim2.fromOffset(18, 18)
	btn.AnchorPoint = Vector2.new(1, 0.5)
	btn.Position = UDim2.new(1, xOffset, 0.5, 0)
	btn.BackgroundColor3 = if activo
		then Color3.fromRGB(0, 175, 240)
		else Color3.fromRGB(38, 46, 60)
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

local lblIconoManiobra = Instance.new("TextLabel")
lblIconoManiobra.Name = "IconoManiobra"
lblIconoManiobra.Size = UDim2.fromOffset(28, 28)
lblIconoManiobra.AnchorPoint = Vector2.new(0, 0.5)
lblIconoManiobra.Position = UDim2.new(0, 8, 0.5, 0)
lblIconoManiobra.BackgroundColor3 = Color3.fromRGB(18, 42, 60)
lblIconoManiobra.Font = Enum.Font.FredokaOne
lblIconoManiobra.Text = "⬆️"
lblIconoManiobra.TextColor3 = Color3.fromRGB(120, 235, 255)
lblIconoManiobra.TextSize = 16
lblIconoManiobra.Parent = pillEstadoGPS

local cornerManiobra = Instance.new("UICorner")
cornerManiobra.CornerRadius = UDim.new(0, 8)
cornerManiobra.Parent = lblIconoManiobra

local lblDestinoGPS = Instance.new("TextLabel")
lblDestinoGPS.Size = UDim2.new(1, -74, 0, 20)
lblDestinoGPS.Position = UDim2.fromOffset(42, 3)
lblDestinoGPS.BackgroundTransparency = 1
lblDestinoGPS.Font = Enum.Font.FredokaOne
lblDestinoGPS.Text = "🧭 Destino"
lblDestinoGPS.TextColor3 = Color3.fromRGB(220, 250, 255)
lblDestinoGPS.TextSize = 13
lblDestinoGPS.TextTruncate = Enum.TextTruncate.AtEnd
lblDestinoGPS.TextXAlignment = Enum.TextXAlignment.Left
lblDestinoGPS.Parent = pillEstadoGPS

local lblDistanciaGPS = Instance.new("TextLabel")
lblDistanciaGPS.Size = UDim2.new(1, -74, 0, 18)
lblDistanciaGPS.Position = UDim2.fromOffset(42, 22)
lblDistanciaGPS.BackgroundTransparency = 1
lblDistanciaGPS.Font = Enum.Font.GothamBold
lblDistanciaGPS.Text = "0 m"
lblDistanciaGPS.TextColor3 = COLOR_RUTA_GPS
lblDistanciaGPS.TextSize = 11
lblDistanciaGPS.TextTruncate = Enum.TextTruncate.AtEnd
lblDistanciaGPS.TextXAlignment = Enum.TextXAlignment.Left
lblDistanciaGPS.Parent = pillEstadoGPS

local btnCancelarGPSMini = Instance.new("TextButton")
btnCancelarGPSMini.Size = UDim2.fromOffset(24, 24)
btnCancelarGPSMini.AnchorPoint = Vector2.new(1, 0.5)
btnCancelarGPSMini.Position = UDim2.new(1, -8, 0.5, 0)
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
	pillEstadoGPS.Size = UDim2.fromOffset(math.max(w, 210), 46)
end

local function aplicarTamanoMinimapa(clave: string, animado: boolean?)
	local cfg = TAMANOS_MINIMAPA[clave]
	if not cfg then
		return
	end
	_tamanoMinimapaActual = clave
	_zoomMinimapaActual = cfg.Zoom

	btnTamanoP.BackgroundColor3 = if clave == "P"
		then Color3.fromRGB(0, 175, 240)
		else Color3.fromRGB(38, 46, 60)
	btnTamanoP.TextColor3 = if clave == "P"
		then Color3.fromRGB(255, 255, 255)
		else Color3.fromRGB(180, 192, 210)

	btnTamanoM.BackgroundColor3 = if clave == "M"
		then Color3.fromRGB(0, 175, 240)
		else Color3.fromRGB(38, 46, 60)
	btnTamanoM.TextColor3 = if clave == "M"
		then Color3.fromRGB(255, 255, 255)
		else Color3.fromRGB(180, 192, 210)

	btnTamanoG.BackgroundColor3 = if clave == "G"
		then Color3.fromRGB(0, 175, 240)
		else Color3.fromRGB(38, 46, 60)
	btnTamanoG.TextColor3 = if clave == "G"
		then Color3.fromRGB(255, 255, 255)
		else Color3.fromRGB(180, 192, 210)

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

-- Estado y animación avanzada de la ruta 3D
local _puntosRutaSuavizada: { Vector3 } = {}
local _nodosGiroGPS: { { Pos: Vector3, Angulo: number, Giro: string } } = {}
local _acumuladosDistancia: { number } = {}
local _longitudTotalRuta: number = 0
local _pulsos3D: { Part } = {}
local _senalesGiro3D: { { Nodo: any, PartAncla: Part, Stroke: UIStroke, LabelDist: TextLabel } } =
	{}
local _anilloDestinoInterior: Part? = nil
local _anilloDestinoExterior: Part? = nil
local _billboardDestino: BillboardGui? = nil
local _lblDistanciaDestino3D: TextLabel? = nil
local _progresoPulsoLuz: number = 0
local _tiempoAnimacionGPS: number = 0
local _ultimoNodoSonado: any = nil

local function obtenerInfoSuelo(pos: Vector3): (Vector3, Vector3)
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

	local resultado =
		Workspace:Raycast(Vector3.new(pos.X, pos.Y + 35, pos.Z), Vector3.new(0, -90, 0), params)
	if resultado then
		return resultado.Position, resultado.Normal
	end
	return pos, Vector3.new(0, 1, 0)
end

local function obtenerAlturaSuelo(pos: Vector3): number
	local p, _ = obtenerInfoSuelo(pos)
	return p.Y
end

local function limpiarRuta3D()
	if _carpetaRuta3D then
		_carpetaRuta3D:ClearAllChildren()
	end
	table.clear(_puntosRutaSuavizada)
	table.clear(_acumuladosDistancia)
	table.clear(_nodosGiroGPS)
	table.clear(_pulsos3D)
	table.clear(_senalesGiro3D)
	_anilloDestinoInterior = nil
	_anilloDestinoExterior = nil
	_billboardDestino = nil
	_lblDistanciaDestino3D = nil
	_longitudTotalRuta = 0
	_ultimoNodoSonado = nil
end

local function suavizarRuta(puntosOriginales: { Vector3 }): { Vector3 }
	if #puntosOriginales <= 1 then
		return puntosOriginales
	end
	if #puntosOriginales == 2 then
		local p1, n1 = obtenerInfoSuelo(puntosOriginales[1])
		local p2, n2 = obtenerInfoSuelo(puntosOriginales[2])
		return { p1 + n1 * 0.08, p2 + n2 * 0.08 }
	end

	local resultado: { Vector3 } = {}
	table.clear(_nodosGiroGPS)

	local pIni, nIni = obtenerInfoSuelo(puntosOriginales[1])
	table.insert(resultado, pIni + nIni * 0.08)

	for i = 2, #puntosOriginales - 1 do
		local pPrev = puntosOriginales[i - 1]
		local pCurr = puntosOriginales[i]
		local pNext = puntosOriginales[i + 1]

		local vIn = pCurr - pPrev
		local vOut = pNext - pCurr
		local distIn = vIn.Magnitude
		local distOut = vOut.Magnitude

		if distIn > 1.5 and distOut > 1.5 then
			local dirIn = Vector2.new(vIn.X, vIn.Z).Unit
			local dirOut = Vector2.new(vOut.X, vOut.Z).Unit
			local dot = math.clamp(dirIn.X * dirOut.X + dirIn.Y * dirOut.Y, -1, 1)
			local cross = dirIn.X * dirOut.Y - dirIn.Y * dirOut.X
			local angulo = math.deg(math.acos(dot))

			if angulo >= 16 then
				local radio = math.min(7.5, distIn * 0.38, distOut * 0.38)
				local q1 = pCurr - vIn.Unit * radio
				local q2 = pCurr + vOut.Unit * radio

				local pQ1, nQ1 = obtenerInfoSuelo(q1)
				table.insert(resultado, pQ1 + nQ1 * 0.08)

				for step = 1, 3 do
					local t = step / 4
					local pBez = (1 - t) * (1 - t) * q1 + 2 * (1 - t) * t * pCurr + t * t * q2
					local pSuelo, normSuelo = obtenerInfoSuelo(pBez)
					table.insert(resultado, pSuelo + normSuelo * 0.08)
				end

				local pQ2, nQ2 = obtenerInfoSuelo(q2)
				table.insert(resultado, pQ2 + nQ2 * 0.08)

				table.insert(_nodosGiroGPS, {
					Pos = pCurr,
					Angulo = angulo,
					Giro = if cross > 0 then "derecha" else "izquierda",
				})
			else
				local pSuelo, normSuelo = obtenerInfoSuelo(pCurr)
				table.insert(resultado, pSuelo + normSuelo * 0.08)
			end
		else
			local pSuelo, normSuelo = obtenerInfoSuelo(pCurr)
			table.insert(resultado, pSuelo + normSuelo * 0.08)
		end
	end

	local pFin, nFin = obtenerInfoSuelo(puntosOriginales[#puntosOriginales])
	table.insert(resultado, pFin + nFin * 0.08)

	return resultado
end

local function recalcularMetricasRuta()
	table.clear(_acumuladosDistancia)
	_acumuladosDistancia = { 0 }
	local total = 0
	for i = 1, #_puntosRutaSuavizada - 1 do
		local d = (_puntosRutaSuavizada[i + 1] - _puntosRutaSuavizada[i]).Magnitude
		total += d
		table.insert(_acumuladosDistancia, total)
	end
	_longitudTotalRuta = total
end

local function interpolarPuntoRuta(distDeseada: number): (Vector3?, Vector3?)
	if #_puntosRutaSuavizada < 2 or _longitudTotalRuta <= 0.1 then
		return nil, nil
	end
	local dTarget = math.clamp(distDeseada, 0, _longitudTotalRuta)
	for i = 1, #_acumuladosDistancia - 1 do
		local d0 = _acumuladosDistancia[i]
		local d1 = _acumuladosDistancia[i + 1]
		if dTarget >= d0 and dTarget <= d1 then
			local segLen = d1 - d0
			local alpha = if segLen > 0.001 then (dTarget - d0) / segLen else 0
			local pA = _puntosRutaSuavizada[i]
			local pB = _puntosRutaSuavizada[i + 1]
			local pInterp = pA:Lerp(pB, alpha)
			return pInterp, Vector3.new(0, 1, 0)
		end
	end
	return _puntosRutaSuavizada[#_puntosRutaSuavizada], Vector3.new(0, 1, 0)
end

local function renderizarRuta3D()
	local destino = _destinoGPS
	if not destino or #_waypointsRuta == 0 then
		limpiarRuta3D()
		return
	end

	local carpeta = asegurarCarpetaRuta3D()
	carpeta:ClearAllChildren()
	table.clear(_pulsos3D)
	table.clear(_senalesGiro3D)

	local posJugador = obtenerPosicionJugador()
	local puntosOriginales = { posJugador }
	for _, wp in ipairs(_waypointsRuta) do
		table.insert(puntosOriginales, wp)
	end

	_puntosRutaSuavizada = suavizarRuta(puntosOriginales)
	recalcularMetricasRuta()

	-- A. Ribbon Dual Aerodinámico y Discos de Esquina
	for i = 1, #_puntosRutaSuavizada - 1 do
		local a = _puntosRutaSuavizada[i]
		local b = _puntosRutaSuavizada[i + 1]
		local delta = b - a
		local dist = delta.Magnitude

		if dist > 0.35 then
			local mid = (a + b) * 0.5
			local _, normMid = obtenerInfoSuelo(mid)
			local cf = CFrame.lookAt(mid, mid + delta, normMid)

			-- 1. Base Ribbon (Aura Neón Cyan)
			local tramoBase = Instance.new("Part")
			tramoBase.Name = "RutaBase_" .. i
			tramoBase.Anchored = true
			tramoBase.CanCollide = false
			tramoBase.CanTouch = false
			tramoBase.CanQuery = false
			tramoBase.CastShadow = false
			tramoBase.Material = Enum.Material.Neon
			tramoBase.Color = Color3.fromRGB(0, 205, 255)
			tramoBase.Transparency = 0.38
			tramoBase.Size = Vector3.new(1.35, 0.04, dist + 0.1)
			tramoBase.CFrame = cf
			tramoBase.Parent = carpeta

			-- 2. Núcleo Láser Central (Luz Brillante)
			local tramoCore = Instance.new("Part")
			tramoCore.Name = "RutaCore_" .. i
			tramoCore.Anchored = true
			tramoCore.CanCollide = false
			tramoCore.CanTouch = false
			tramoCore.CanQuery = false
			tramoCore.CastShadow = false
			tramoCore.Material = Enum.Material.Neon
			tramoCore.Color = Color3.fromRGB(225, 252, 255)
			tramoCore.Transparency = 0.10
			tramoCore.Size = Vector3.new(0.38, 0.06, dist + 0.12)
			tramoCore.CFrame = cf
			tramoCore.Parent = carpeta

			-- 3. Disco de unión en vértice A para curvas continuas
			local disco = Instance.new("Part")
			disco.Name = "RutaDisco_" .. i
			disco.Anchored = true
			disco.CanCollide = false
			disco.CanTouch = false
			disco.CanQuery = false
			disco.CastShadow = false
			disco.Shape = Enum.PartType.Cylinder
			disco.Material = Enum.Material.Neon
			disco.Color = Color3.fromRGB(0, 215, 255)
			disco.Transparency = 0.35
			disco.Size = Vector3.new(0.045, 1.35, 1.35)
			disco.CFrame = CFrame.lookAt(a, a + normMid) * CFrame.Angles(0, math.rad(90), 0)
			disco.Parent = carpeta
		end
	end

	-- B. Pulsos de Luz Dinámicos (3 orbes de energía viajando por la ruta)
	for pIdx = 1, 3 do
		local pulso = Instance.new("Part")
		pulso.Name = "PulsoLuz_" .. pIdx
		pulso.Anchored = true
		pulso.CanCollide = false
		pulso.CanTouch = false
		pulso.CanQuery = false
		pulso.CastShadow = false
		pulso.Shape = Enum.PartType.Cylinder
		pulso.Material = Enum.Material.Neon
		pulso.Color = Color3.fromRGB(255, 255, 255)
		pulso.Transparency = 0.08
		pulso.Size = Vector3.new(0.12, 1.5, 1.5)
		pulso.Parent = carpeta

		local luz = Instance.new("PointLight")
		luz.Color = Color3.fromRGB(0, 235, 255)
		luz.Range = 8.5
		luz.Brightness = 2.2
		luz.Shadows = false
		luz.Parent = pulso

		table.insert(_pulsos3D, pulso)
	end

	-- C. Señalización 3D Holográfica en Giros y Esquinas
	for _, nodo in ipairs(_nodosGiroGPS) do
		if nodo.Angulo >= 22 then
			local ancla = Instance.new("Part")
			ancla.Name = "AnclaGiroGPS"
			ancla.Anchored = true
			ancla.CanCollide = false
			ancla.CanTouch = false
			ancla.CanQuery = false
			ancla.CastShadow = false
			ancla.Transparency = 1
			ancla.Size = Vector3.new(1, 1, 1)
			ancla.Position = nodo.Pos + Vector3.new(0, 3.6, 0)
			ancla.Parent = carpeta

			local bb = Instance.new("BillboardGui")
			bb.Name = "BBGiro"
			bb.Size = UDim2.fromOffset(56, 46)
			bb.AlwaysOnTop = true
			bb.MaxDistance = 160
			bb.Parent = ancla

			local fondoBB = Instance.new("Frame")
			fondoBB.Size = UDim2.fromScale(1, 1)
			fondoBB.BackgroundColor3 = Color3.fromRGB(14, 26, 38)
			fondoBB.BackgroundTransparency = 0.15
			fondoBB.Parent = bb

			local cFondo = Instance.new("UICorner")
			cFondo.CornerRadius = UDim.new(0, 8)
			cFondo.Parent = fondoBB

			local sFondo = Instance.new("UIStroke")
			sFondo.Color = COLOR_RUTA_GPS
			sFondo.Thickness = 1.8
			sFondo.Parent = fondoBB

			local lblFlecha = Instance.new("TextLabel")
			lblFlecha.Size = UDim2.new(1, 0, 0, 26)
			lblFlecha.BackgroundTransparency = 1
			lblFlecha.Font = Enum.Font.FredokaOne
			lblFlecha.Text = if nodo.Giro == "derecha" then "↱" else "↰"
			lblFlecha.TextColor3 = Color3.fromRGB(255, 225, 90)
			lblFlecha.TextSize = 22
			lblFlecha.Parent = fondoBB

			local lblDist = Instance.new("TextLabel")
			lblDist.Size = UDim2.new(1, 0, 0, 16)
			lblDist.Position = UDim2.fromOffset(0, 26)
			lblDist.BackgroundTransparency = 1
			lblDist.Font = Enum.Font.GothamBold
			lblDist.Text = "-- m"
			lblDist.TextColor3 = Color3.fromRGB(200, 235, 255)
			lblDist.TextSize = 10
			lblDist.Parent = fondoBB

			table.insert(_senalesGiro3D, {
				Nodo = nodo,
				PartAncla = ancla,
				Stroke = sFondo,
				LabelDist = lblDist,
			})
		end
	end

	-- D. Baliza y Radar Holográfico de Destino
	local posDestSuelo, normDest = obtenerInfoSuelo(destino.Posicion)
	local posBaseDest = posDestSuelo + normDest * 0.08

	local anilloExt = Instance.new("Part")
	anilloExt.Name = "AnilloDestinoExt"
	anilloExt.Anchored = true
	anilloExt.CanCollide = false
	anilloExt.CanTouch = false
	anilloExt.CanQuery = false
	anilloExt.CastShadow = false
	anilloExt.Shape = Enum.PartType.Cylinder
	anilloExt.Material = Enum.Material.Neon
	anilloExt.Color = destino.Color
	anilloExt.Transparency = 0.45
	anilloExt.Size = Vector3.new(0.08, 12, 12)
	anilloExt.CFrame = CFrame.lookAt(posBaseDest, posBaseDest + normDest)
		* CFrame.Angles(0, math.rad(90), 0)
	anilloExt.Parent = carpeta
	_anilloDestinoExterior = anilloExt

	local anilloInt = Instance.new("Part")
	anilloInt.Name = "AnilloDestinoInt"
	anilloInt.Anchored = true
	anilloInt.CanCollide = false
	anilloInt.CanTouch = false
	anilloInt.CanQuery = false
	anilloInt.CastShadow = false
	anilloInt.Shape = Enum.PartType.Cylinder
	anilloInt.Material = Enum.Material.Neon
	anilloInt.Color = Color3.fromRGB(255, 255, 255)
	anilloInt.Transparency = 0.2
	anilloInt.Size = Vector3.new(0.1, 4.5, 4.5)
	anilloInt.CFrame = CFrame.lookAt(posBaseDest + normDest * 0.02, posBaseDest + normDest * 1.0)
		* CFrame.Angles(0, math.rad(90), 0)
	anilloInt.Parent = carpeta
	_anilloDestinoInterior = anilloInt

	local baliza = Instance.new("Part")
	baliza.Name = "BalizaDestinoGPS"
	baliza.Anchored = true
	baliza.CanCollide = false
	baliza.CanTouch = false
	baliza.CanQuery = false
	baliza.CastShadow = false
	baliza.Material = Enum.Material.Neon
	baliza.Color = destino.Color
	baliza.Transparency = 0.72
	baliza.Size = Vector3.new(1.8, 90, 1.8)
	baliza.Position = posBaseDest + Vector3.new(0, 45, 0)
	baliza.Parent = carpeta

	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(destino.Color, Color3.fromRGB(255, 255, 255))
	pe.LightEmission = 0.95
	pe.LightInfluence = 0
	pe.Size =
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) })
	pe.Transparency =
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	pe.Lifetime = NumberRange.new(1.6, 2.4)
	pe.Rate = 14
	pe.Speed = NumberRange.new(4, 8)
	pe.SpreadAngle = Vector2.new(15, 15)
	pe.Parent = baliza

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(210, 62)
	billboard.StudsOffset = Vector3.new(0, 14, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 3500
	billboard.Parent = baliza
	_billboardDestino = billboard

	local contenedorBB = Instance.new("Frame")
	contenedorBB.Size = UDim2.fromScale(1, 1)
	contenedorBB.BackgroundColor3 = Color3.fromRGB(14, 22, 34)
	contenedorBB.BackgroundTransparency = 0.12
	contenedorBB.Parent = billboard

	local cBB = Instance.new("UICorner")
	cBB.CornerRadius = UDim.new(0, 10)
	cBB.Parent = contenedorBB

	local sBB = Instance.new("UIStroke")
	sBB.Color = destino.Color
	sBB.Thickness = 2
	sBB.Parent = contenedorBB

	local lblNomDest = Instance.new("TextLabel")
	lblNomDest.Size = UDim2.new(1, -16, 0, 26)
	lblNomDest.Position = UDim2.fromOffset(8, 4)
	lblNomDest.BackgroundTransparency = 1
	lblNomDest.Font = Enum.Font.FredokaOne
	lblNomDest.Text = string.format("%s %s", destino.Icono, destino.Nombre)
	lblNomDest.TextColor3 = Color3.fromRGB(255, 255, 255)
	lblNomDest.TextSize = 15
	lblNomDest.TextTruncate = Enum.TextTruncate.AtEnd
	lblNomDest.Parent = contenedorBB

	local lblDistDest = Instance.new("TextLabel")
	lblDistDest.Size = UDim2.new(1, -16, 0, 22)
	lblDistDest.Position = UDim2.fromOffset(8, 30)
	lblDistDest.BackgroundTransparency = 1
	lblDistDest.Font = Enum.Font.GothamBold
	lblDistDest.Text = "🎯 Calculando distancia..."
	lblDistDest.TextColor3 = Color3.fromRGB(255, 225, 90)
	lblDistDest.TextSize = 12
	lblDistDest.Parent = contenedorBB
	_lblDistanciaDestino3D = lblDistDest
end

local function actualizarAnimacionesRuta3D(dt: number, posJugador: Vector3)
	if not _destinoGPS or #_puntosRutaSuavizada < 2 or not _carpetaRuta3D then
		return
	end

	_tiempoAnimacionGPS += dt

	-- 1. Animación fluida de pulsos de luz viajando hacia el destino
	if _longitudTotalRuta > 2 and #_pulsos3D > 0 then
		_progresoPulsoLuz = (_progresoPulsoLuz + dt * 28) % _longitudTotalRuta
		for pIdx, pulso in ipairs(_pulsos3D) do
			local offsetDist = (_progresoPulsoLuz + (pIdx - 1) * 35) % _longitudTotalRuta
			local posPulso, normPulso = interpolarPuntoRuta(offsetDist)
			if posPulso and normPulso then
				pulso.CFrame = CFrame.lookAt(
					posPulso + normPulso * 0.12,
					posPulso + normPulso * 1.0
				) * CFrame.Angles(0, math.rad(90), 0)
				pulso.Transparency = 0.05
					+ 0.12 * math.abs(math.sin(_tiempoAnimacionGPS * 4 + pIdx))
			else
				pulso.Transparency = 1
			end
		end
	end

	-- 2. Animación de anillos y baliza en la meta
	if _anilloDestinoInterior and _anilloDestinoInterior.Parent then
		local pulsoEscala = 4.2 + math.sin(_tiempoAnimacionGPS * 3.8) * 1.8
		_anilloDestinoInterior.Size = Vector3.new(0.08, pulsoEscala, pulsoEscala)
		_anilloDestinoInterior.Transparency = 0.15
			+ 0.25 * math.abs(math.cos(_tiempoAnimacionGPS * 3.8))
	end

	if _billboardDestino and _billboardDestino.Parent then
		_billboardDestino.StudsOffset =
			Vector3.new(0, 14 + math.sin(_tiempoAnimacionGPS * 2.5) * 0.7, 0)
	end

	-- 3. Señales flotantes 3D en esquinas e interacción de proximidad
	local distTotalMeta = (_destinoGPS.Posicion - posJugador).Magnitude
	if _lblDistanciaDestino3D and _lblDistanciaDestino3D.Parent then
		_lblDistanciaDestino3D.Text =
			string.format("🎯 %d m hasta la meta", math.floor(distTotalMeta))
	end

	local nodoMasCercano: any = nil
	local distMinTurno = math.huge

	for _, senal in ipairs(_senalesGiro3D) do
		local nodo = senal.Nodo
		local ancla = senal.PartAncla
		if ancla and ancla.Parent then
			local distAlGiro = (posJugador - nodo.Pos).Magnitude
			senal.LabelDist.Text = string.format("%d m", math.floor(distAlGiro))
			ancla.Position = nodo.Pos
				+ Vector3.new(0, 3.6 + math.sin(_tiempoAnimacionGPS * 3.5) * 0.35, 0)

			if distAlGiro < distMinTurno and distAlGiro > 4 then
				distMinTurno = distAlGiro
				nodoMasCercano = nodo
			end

			if distAlGiro <= 28 then
				senal.Stroke.Color = Color3.fromRGB(255, 225, 90)
				senal.Stroke.Thickness = 2.4
			else
				senal.Stroke.Color = COLOR_RUTA_GPS
				senal.Stroke.Thickness = 1.6
			end
		end
	end

	-- 4. Actualizar HUD Pill con Maniobra Activa y Distancia
	if distTotalMeta <= DISTANCIA_LLEGADA then
		lblIconoManiobra.Text = "🎯"
		lblIconoManiobra.TextColor3 = Color3.fromRGB(80, 255, 140)
		lblDistanciaGPS.Text =
			string.format("🎯 ¡Llegando a la meta! (%d m)", math.floor(distTotalMeta))
		strokePillGPS.Color = Color3.fromRGB(80, 255, 140)
	elseif nodoMasCercano and distMinTurno <= 55 then
		local esDer = (nodoMasCercano.Giro == "derecha")
		lblIconoManiobra.Text = if esDer then "↱" else "↰"
		lblIconoManiobra.TextColor3 = Color3.fromRGB(255, 225, 90)
		lblDistanciaGPS.Text = string.format(
			"%s En %d m gira a la %s • Total: %d m",
			if esDer then "↱" else "↰",
			math.floor(distMinTurno),
			if esDer then "derecha" else "izquierda",
			math.floor(distTotalMeta)
		)
		if distMinTurno <= 22 then
			strokePillGPS.Color = Color3.fromRGB(255, 215, 60)
		else
			strokePillGPS.Color = COLOR_RUTA_GPS
		end
	else
		lblIconoManiobra.Text = "⬆️"
		lblIconoManiobra.TextColor3 = Color3.fromRGB(120, 225, 255)
		lblDistanciaGPS.Text = string.format(
			"⬆️ Continúa recto • %d m hasta el destino",
			math.floor(distTotalMeta)
		)
		strokePillGPS.Color = COLOR_RUTA_GPS
	end
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
	lblIconoManiobra.Text = "⬆️"
	lblIconoManiobra.TextColor3 = Color3.fromRGB(120, 235, 255)
	strokePillGPS.Color = COLOR_RUTA_GPS
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
	lblIconoManiobra.Text = "⬆️"
	lblIconoManiobra.TextColor3 = Color3.fromRGB(120, 235, 255)
	lblDestinoGPS.Text = string.format("%s %s", punto.Icono, punto.Nombre)
	lblDistanciaGPS.Text = "🧭 Calculando ruta óptima..."
	calcularRutaGPSAsync()
end

-- ============================================================================
-- RENDERIZADO 2D (MINIMAPA + MAPA COMPLETO)
-- ============================================================================
local renderizarMapaCompleto: () -> ()
local actualizarDetalleUI: () -> ()
local actualizarListaLateral: () -> ()

-- 1. Pool persistente de distritos
local _etiquetasDistritos: { TextLabel } = {}
local function inicializarDistritosVisuales()
	for _, lbl in ipairs(_etiquetasDistritos) do
		lbl:Destroy()
	end
	table.clear(_etiquetasDistritos)
	for _, d in ipairs(DISTRITOS_MAPA) do
		local lbl = Instance.new("TextLabel")
		lbl.Name = "Distrito_" .. d.Nombre
		lbl.AnchorPoint = Vector2.new(0.5, 0.5)
		lbl.Size = UDim2.fromOffset(180, 20)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBlack
		lbl.Text = d.Nombre
		lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		lbl.TextTransparency = 0.72
		lbl.TextSize = 11
		lbl.ZIndex = 27
		lbl.Visible = false
		lbl.Parent = capaDistritosMapa
		table.insert(_etiquetasDistritos, lbl)
	end
end

-- 2. Pool persistente de jugadores en el mapa
local flechaJugadorMapa = Instance.new("TextLabel")
flechaJugadorMapa.Name = "FlechaJugadorMapa"
flechaJugadorMapa.AnchorPoint = Vector2.new(0.5, 0.5)
flechaJugadorMapa.Size = UDim2.fromOffset(24, 24)
flechaJugadorMapa.BackgroundTransparency = 1
flechaJugadorMapa.Font = Enum.Font.GothamBlack
flechaJugadorMapa.Text = "▲"
flechaJugadorMapa.TextColor3 = Color3.fromRGB(80, 255, 140)
flechaJugadorMapa.TextStrokeTransparency = 0
flechaJugadorMapa.TextSize = 20
flechaJugadorMapa.ZIndex = 33
flechaJugadorMapa.Visible = false
flechaJugadorMapa.Parent = capaJugadoresMapa

local _poolJugadoresMapa: { Frame } = {}
local function obtenerDotJugador(idx: number): Frame
	if _poolJugadoresMapa[idx] then
		return _poolJugadoresMapa[idx]
	end
	local dot = Instance.new("Frame")
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Size = UDim2.fromOffset(10, 10)
	dot.BackgroundColor3 = Color3.fromRGB(120, 210, 255)
	dot.ZIndex = 32
	dot.Parent = capaJugadoresMapa
	local cDot = Instance.new("UICorner")
	cDot.CornerRadius = UDim.new(1, 0)
	cDot.Parent = dot
	_poolJugadoresMapa[idx] = dot
	return dot
end

-- 3. Pool persistente de segmentos de ruta GPS (Full Map y Minimapa)
local _poolRutaMapa: { Frame } = {}
local _poolRutaMini: { Frame } = {}

local function actualizarRutaVisual(
	pool: { Frame },
	padre: Frame,
	waypoints: { Vector3 },
	inicioX: number,
	inicioY: number,
	zoom: number,
	cx: number,
	cy: number,
	panX: number,
	panY: number,
	grosor: number,
	color: Color3,
	zIndex: number
)
	local segIndex = 0
	if _destinoGPS and #waypoints > 0 then
		local prevX = cx + (inicioX - panX) * zoom
		local prevY = cy + (inicioY - panY) * zoom
		for _, wp in ipairs(waypoints) do
			local nx = cx + (wp.X - panX) * zoom
			local ny = cy + (wp.Z - panY) * zoom
			local dx = nx - prevX
			local dy = ny - prevY
			local len = math.sqrt(dx * dx + dy * dy)
			if len >= 1 then
				segIndex += 1
				local seg = pool[segIndex]
				if not seg then
					seg = Instance.new("Frame")
					seg.AnchorPoint = Vector2.new(0.5, 0.5)
					seg.BorderSizePixel = 0
					seg.Parent = padre
					pool[segIndex] = seg
				end
				seg.Position = UDim2.fromOffset((prevX + nx) * 0.5, (prevY + ny) * 0.5)
				seg.Size = UDim2.fromOffset(len + grosor * 0.4, grosor)
				seg.Rotation = math.deg(math.atan2(dy, dx))
				seg.BackgroundColor3 = color
				seg.ZIndex = zIndex
				seg.Visible = true
			end
			prevX, prevY = nx, ny
		end
	end
	for i = segIndex + 1, #pool do
		pool[i].Visible = false
	end
end

-- 4. Pool persistente de puntos de interés (POIs) - Sin parpadeos ni Destroy continuo
type PinVisualMapa = {
	Punto: PuntoResuelto,
	Boton: TextButton,
	Stroke: UIStroke,
	Etiqueta: TextLabel,
}

type PinVisualMini = {
	Punto: PuntoResuelto,
	Label: TextLabel,
	Stroke: UIStroke,
}

local _pinsVisualesMapa: { [string]: PinVisualMapa } = {}
local _pinsVisualesMini: { [string]: PinVisualMini } = {}

local function crearPinMapa(p: PuntoResuelto): PinVisualMapa
	local pin = Instance.new("TextButton")
	pin.Name = "PinMapa_" .. p.Id
	pin.AnchorPoint = Vector2.new(0.5, 0.5)
	pin.Size = UDim2.fromOffset(24, 24)
	pin.BackgroundColor3 = p.Color
	pin.Font = Enum.Font.GothamBold
	pin.Text = p.Icono
	pin.TextSize = 13
	pin.ZIndex = 30
	pin.AutoButtonColor = false
	pin.Visible = false
	pin.Parent = capaPOIMapa

	local cPin = Instance.new("UICorner")
	cPin.CornerRadius = UDim.new(1, 0)
	cPin.Parent = pin

	local sPin = Instance.new("UIStroke")
	sPin.Color = Color3.fromRGB(16, 19, 26)
	sPin.Thickness = 1.2
	sPin.Parent = pin

	local etiqueta = Instance.new("TextLabel")
	etiqueta.Name = "Etiqueta"
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
	etiqueta.Visible = false
	etiqueta.Parent = pin

	local cEt = Instance.new("UICorner")
	cEt.CornerRadius = UDim.new(0, 4)
	cEt.Parent = etiqueta

	local idCapturado = p.Id
	pin.MouseButton1Click:Connect(function()
		local seleccionado: PuntoResuelto? = nil
		for _, cand in ipairs(_puntosResueltos) do
			if cand.Id == idCapturado then
				seleccionado = cand
				break
			end
		end
		if seleccionado then
			_puntoSeleccionado = seleccionado
			if type(actualizarDetalleUI) == "function" then
				actualizarDetalleUI()
			end
			if type(actualizarListaLateral) == "function" then
				actualizarListaLateral()
			end
			if type(renderizarMapaCompleto) == "function" then
				renderizarMapaCompleto()
			end
		end
	end)

	return {
		Punto = p,
		Boton = pin,
		Stroke = sPin,
		Etiqueta = etiqueta,
	}
end

local function crearPinMini(p: PuntoResuelto): PinVisualMini
	local pin = Instance.new("TextLabel")
	pin.Name = "PinMini_" .. p.Id
	pin.AnchorPoint = Vector2.new(0.5, 0.5)
	pin.Size = UDim2.fromOffset(20, 20)
	pin.BackgroundColor3 = p.Color
	pin.BackgroundTransparency = 0.1
	pin.Font = Enum.Font.GothamBold
	pin.Text = p.Icono
	pin.TextSize = 12
	pin.ZIndex = 8
	pin.Visible = false
	pin.Parent = capaPOIMini

	local cPin = Instance.new("UICorner")
	cPin.CornerRadius = UDim.new(1, 0)
	cPin.Parent = pin

	local sPin = Instance.new("UIStroke")
	sPin.Color = Color3.fromRGB(16, 19, 26)
	sPin.Thickness = 1.2
	sPin.Parent = pin

	return {
		Punto = p,
		Label = pin,
		Stroke = sPin,
	}
end

sincronizarPinsVisuales = function()
	local idsActuales: { [string]: boolean } = {}
	for _, p in ipairs(_puntosResueltos) do
		idsActuales[p.Id] = true

		local visualMapa = _pinsVisualesMapa[p.Id]
		if visualMapa then
			visualMapa.Punto = p
			visualMapa.Boton.Text = p.Icono
			visualMapa.Etiqueta.Text = p.Nombre
		else
			_pinsVisualesMapa[p.Id] = crearPinMapa(p)
		end

		local visualMini = _pinsVisualesMini[p.Id]
		if visualMini then
			visualMini.Punto = p
			visualMini.Label.Text = p.Icono
			visualMini.Label.BackgroundColor3 = p.Color
		else
			_pinsVisualesMini[p.Id] = crearPinMini(p)
		end
	end

	for id, visualMapa in pairs(_pinsVisualesMapa) do
		if not idsActuales[id] then
			visualMapa.Boton:Destroy()
			_pinsVisualesMapa[id] = nil
		end
	end

	for id, visualMini in pairs(_pinsVisualesMini) do
		if not idsActuales[id] then
			visualMini.Label:Destroy()
			_pinsVisualesMini[id] = nil
		end
	end
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

actualizarDetalleUI = function()
	local sel = _puntoSeleccionado
	if not sel then
		lblDetalleTitulo.Text = "📍 Selecciona un punto o haz clic en el mapa"
		lblDetalleDesc.Text =
			"El GPS calculará la ruta óptima y te guiará con señales en la calle."
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
		local pasaBusq = (busquedaLower == "")
			or (string.find(string.lower(p.Nombre), busquedaLower, 1, true) ~= nil)
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
		sCard.Color = if esActivo
			then COLOR_RUTA_GPS
			elseif esSel then p.Color
			else Color3.fromRGB(45, 54, 70)
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
		btnIr.BackgroundColor3 = if esActivo
			then Color3.fromRGB(185, 55, 65)
			else Color3.fromRGB(0, 145, 200)
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

local function actualizarBloqueVisual(
	f: Frame,
	linea: Frame?,
	_b: BloqueMapa,
	sx: number,
	sy: number,
	sw: number,
	sh: number,
	ancho: number,
	alto: number
)
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

renderizarMapaCompleto = function()
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

	-- Etiquetas de distritos (persistentes, sin Destroy)
	for i, d in ipairs(DISTRITOS_MAPA) do
		local lbl = _etiquetasDistritos[i]
		if lbl then
			local dx = cx + (d.X - _panMapa.X) * _zoomMapa
			local dy = cy + (d.Z - _panMapa.Y) * _zoomMapa
			if dx >= -80 and dx <= ancho + 80 and dy >= -30 and dy <= alto + 30 then
				lbl.Position = UDim2.fromOffset(dx, dy)
				lbl.Visible = true
			else
				lbl.Visible = false
			end
		end
	end

	-- Ruta GPS (persistente en pool, sin Destroy)
	local posJugador, yawJugador = obtenerPosicionJugador()
	actualizarRutaVisual(
		_poolRutaMapa,
		capaRutaMapa,
		_waypointsRuta,
		posJugador.X,
		posJugador.Z,
		_zoomMapa,
		cx,
		cy,
		_panMapa.X,
		_panMapa.Y,
		3.5,
		COLOR_RUTA_GPS,
		28
	)

	-- Pins de POI (persistentes en pool, sin Destroy ni parpadeos)
	for _, p in ipairs(_puntosResueltos) do
		local visual = _pinsVisualesMapa[p.Id]
		if visual then
			local pasaFiltro = (
				_categoriaFiltro == "Todos"
				or p.Categoria == _categoriaFiltro
				or p.EsPersonalizado
			)
			if pasaFiltro then
				local px = cx + (p.Posicion.X - _panMapa.X) * _zoomMapa
				local py = cy + (p.Posicion.Z - _panMapa.Y) * _zoomMapa
				if px >= -24 and px <= ancho + 24 and py >= -24 and py <= alto + 24 then
					local esSel = _puntoSeleccionado and _puntoSeleccionado.Id == p.Id
					local esGPS = _destinoGPS and _destinoGPS.Id == p.Id

					visual.Boton.Position = UDim2.fromOffset(px, py)
					visual.Boton.Size = if esSel or esGPS
						then UDim2.fromOffset(30, 30)
						else UDim2.fromOffset(24, 24)
					visual.Boton.BackgroundColor3 = if esGPS then COLOR_RUTA_GPS else p.Color
					visual.Boton.TextSize = if esSel or esGPS then 16 else 13
					visual.Boton.ZIndex = if esSel or esGPS then 31 else 30
					visual.Stroke.Color = if esSel or esGPS
						then Color3.fromRGB(255, 255, 255)
						else Color3.fromRGB(16, 19, 26)
					visual.Stroke.Thickness = if esSel or esGPS then 2 else 1.2
					visual.Etiqueta.Visible = (_zoomMapa >= 0.42 or esSel or esGPS)
					visual.Etiqueta.ZIndex = visual.Boton.ZIndex + 1
					visual.Boton.Visible = true
				else
					visual.Boton.Visible = false
				end
			else
				visual.Boton.Visible = false
			end
		end
	end

	-- Jugadores (persistentes en pool, sin Destroy)
	local idxPlr = 0
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
			if hrp and hrp:IsA("BasePart") then
				local px = cx + (hrp.Position.X - _panMapa.X) * _zoomMapa
				local py = cy + (hrp.Position.Z - _panMapa.Y) * _zoomMapa
				if px >= 0 and px <= ancho and py >= 0 and py <= alto then
					idxPlr += 1
					local dot = obtenerDotJugador(idxPlr)
					dot.Position = UDim2.fromOffset(px, py)
					dot.Visible = true
				end
			end
		end
	end
	for i = idxPlr + 1, #_poolJugadoresMapa do
		_poolJugadoresMapa[i].Visible = false
	end

	local jx = cx + (posJugador.X - _panMapa.X) * _zoomMapa
	local jy = cy + (posJugador.Z - _panMapa.Y) * _zoomMapa
	flechaJugadorMapa.Position = UDim2.fromOffset(jx, jy)
	flechaJugadorMapa.Rotation = yawJugador
	flechaJugadorMapa.Visible = true
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
			actualizarBloqueVisual(
				item.FrameMini,
				item.LineaViaMini,
				b,
				sx,
				sy,
				sw,
				sh,
				ancho,
				alto
			)
		end
	end

	-- Ruta en minimapa (persistente en pool, sin Destroy)
	actualizarRutaVisual(
		_poolRutaMini,
		capaRutaMini,
		_waypointsRuta,
		posJugador.X,
		posJugador.Z,
		_zoomMinimapaActual,
		cx,
		cy,
		posJugador.X,
		posJugador.Z,
		2.8,
		COLOR_RUTA_GPS,
		6
	)

	-- POIs en minimapa (persistentes en pool, sin Destroy)
	local masCercano: PuntoResuelto? = nil
	local distMin = math.huge

	for _, p in ipairs(_puntosResueltos) do
		local d = (p.Posicion - posJugador).Magnitude
		if d < distMin and not p.EsPersonalizado then
			distMin = d
			masCercano = p
		end

		local visual = _pinsVisualesMini[p.Id]
		if visual then
			local px = cx + (p.Posicion.X - posJugador.X) * _zoomMinimapaActual
			local py = cy + (p.Posicion.Z - posJugador.Z) * _zoomMinimapaActual
			if px >= -8 and px <= ancho + 8 and py >= -8 and py <= alto + 8 then
				visual.Label.Position = UDim2.fromOffset(px, py)
				visual.Label.Visible = true
			else
				visual.Label.Visible = false
			end
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
			local escala = math.min(
				margenX / math.max(math.abs(dx), 0.001),
				margenY / math.max(math.abs(dy), 0.001)
			)
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
		btn.BackgroundColor3 = if activo
			then Color3.fromRGB(0, 145, 200)
			else Color3.fromRGB(30, 36, 48)
		btn.TextColor3 = if activo
			then Color3.fromRGB(255, 255, 255)
			else Color3.fromRGB(185, 198, 218)
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
	_zoomMinimapaActual =
		math.clamp(math.floor((_zoomMinimapaActual + 0.08) * 100) / 100, 0.20, 0.85)
end)

btnZoomOut.MouseButton1Click:Connect(function()
	_zoomMinimapaActual =
		math.clamp(math.floor((_zoomMinimapaActual - 0.08) * 100) / 100, 0.20, 0.85)
end)

local _arrastrandoResize = false
local _posInicialMouse: Vector2 = Vector2.zero
local _tamInicialFrame: Vector2 = Vector2.zero

tiradorResize.InputBegan:Connect(function(input)
	if
		input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
	then
		_arrastrandoResize = true
		_posInicialMouse = Vector2.new(input.Position.X, input.Position.Y)
		_tamInicialFrame = contenedorMinimapa.AbsoluteSize
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if
		input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
	then
		if _arrastrandoResize then
			_arrastrandoResize = false
		end
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if
		_arrastrandoResize
		and (
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		)
	then
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

		btnTamanoP.BackgroundColor3 = if _tamanoMinimapaActual == "P"
			then Color3.fromRGB(0, 175, 240)
			else Color3.fromRGB(38, 46, 60)
		btnTamanoP.TextColor3 = if _tamanoMinimapaActual == "P"
			then Color3.fromRGB(255, 255, 255)
			else Color3.fromRGB(180, 192, 210)
		btnTamanoM.BackgroundColor3 = if _tamanoMinimapaActual == "M"
			then Color3.fromRGB(0, 175, 240)
			else Color3.fromRGB(38, 46, 60)
		btnTamanoM.TextColor3 = if _tamanoMinimapaActual == "M"
			then Color3.fromRGB(255, 255, 255)
			else Color3.fromRGB(180, 192, 210)
		btnTamanoG.BackgroundColor3 = if _tamanoMinimapaActual == "G"
			then Color3.fromRGB(0, 175, 240)
			else Color3.fromRGB(38, 46, 60)
		btnTamanoG.TextColor3 = if _tamanoMinimapaActual == "G"
			then Color3.fromRGB(255, 255, 255)
			else Color3.fromRGB(180, 192, 210)

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
	if
		input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
	then
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
	if
		input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
	then
		local actual = Vector2.new(input.Position.X, input.Position.Y)
		local delta = actual - _inicioArrastre
		_arrastroDistancia = math.max(_arrastroDistancia, delta.Magnitude)
		_panMapa = _panInicio - (delta / _zoomMapa)
		renderizarMapaCompleto()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if
		input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
	then
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
					Descripcion = string.format(
						"Destino manual en coordenadas (%.0f, %.0f).",
						worldX,
						worldZ
					),
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
	inicializarDistritosVisuales()
	resolverPuntosInteres()
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
		local distancia = (
			Vector3.new(_destinoGPS.Posicion.X, posJugador.Y, _destinoGPS.Posicion.Z) - posJugador
		).Magnitude

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
			actualizarAnimacionesRuta3D(dt, posJugador)

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
