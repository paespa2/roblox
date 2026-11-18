--!strict
--[[
	HordeUI.luau
	Interfaz de supervivencia por oleadas estilo Call of Duty Zombies
	integrada con la identidad visual de El Patrón del Dulce.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local EventosRemotos = require(ReplicatedStorage.Shared.Eventos.EventosRemotos)
local Datos = require(ReplicatedStorage.Shared.Datos)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ConfigZombis = Datos.Zombis

local HordeUI = {}

local _screenGui: ScreenGui
local _panelHorda: Frame
local _lblOleada: TextLabel
local _lblEstado: TextLabel
local _lblZombis: TextLabel
local _bannerCentral: Frame
local _lblBannerTitulo: TextLabel
local _lblBannerSub: TextLabel
local _strokeBanner: UIStroke

local _musicaTension: Sound? = nil
local _ultimoMensajeAnunciado = ""
local _ultimaOleadaAnunciada = 0
local _timerOcultarBanner: thread? = nil

local function reproducirSonido(soundId: string, volumen: number?)
	if soundId == "" then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = soundId
	s.Volume = volumen or 0.6
	s.Parent = SoundService
	pcall(function()
		s:Play()
	end)
	task.delay(2.5, function()
		if s.Parent then
			s:Destroy()
		end
	end)
end

local function actualizarMusicaTension(activa: boolean)
	local idMusica = ConfigZombis.Sonidos.MusicaTension
	if idMusica == "" then
		return
	end
	if activa then
		if not _musicaTension then
			local m = Instance.new("Sound")
			m.Name = "MusicaTensionHorda"
			m.SoundId = idMusica
			m.Volume = 0.35
			m.Looped = true
			m.Parent = SoundService
			_musicaTension = m
		end
		if _musicaTension and not _musicaTension.IsPlaying then
			_musicaTension:Play()
		end
	else
		if _musicaTension and _musicaTension.IsPlaying then
			_musicaTension:Stop()
		end
	end
end

local function mostrarBannerOleada(
	titulo: string,
	subtitulo: string,
	colorBorde: Color3,
	duracion: number
)
	if _timerOcultarBanner then
		local h = _timerOcultarBanner
		_timerOcultarBanner = nil
		if coroutine.running() ~= h and coroutine.status(h) ~= "dead" then
			task.cancel(h)
		end
	end

	_lblBannerTitulo.Text = titulo
	_lblBannerSub.Text = subtitulo
	_strokeBanner.Color = colorBorde

	_bannerCentral.Visible = true
	_bannerCentral.Position = UDim2.new(0.5, 0, 0, -120)

	TweenService:Create(
		_bannerCentral,
		TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 0, 122) }
	):Play()

	_timerOcultarBanner = task.delay(duracion, function()
		_timerOcultarBanner = nil
		local tweenSalida = TweenService:Create(
			_bannerCentral,
			TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(0.5, 0, 0, -120) }
		)
		tweenSalida:Play()
		tweenSalida.Completed:Connect(function()
			_bannerCentral.Visible = false
		end)
	end)
end

local function construirInterfaz()
	local previo = PlayerGui:FindFirstChild("UI_HordaZombis")
	if previo then
		previo:Destroy()
	end

	_screenGui = Instance.new("ScreenGui")
	_screenGui.Name = "UI_HordaZombis"
	_screenGui.ResetOnSpawn = false
	_screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	_screenGui.Parent = PlayerGui

	-- Panel persistente superior derecho (no choca con HUDPrincipal ni HUDEstrellas)
	_panelHorda = Instance.new("Frame")
	_panelHorda.Name = "PanelEstadoHorda"
	_panelHorda.Size = UDim2.fromOffset(250, 92)
	_panelHorda.AnchorPoint = Vector2.new(1, 0)
	_panelHorda.Position = UDim2.new(1, -20, 0, 20)
	_panelHorda.BackgroundColor3 = Color3.fromRGB(22, 18, 26)
	_panelHorda.BackgroundTransparency = 0.12
	_panelHorda.Visible = false
	_panelHorda.Parent = _screenGui

	local cornerPanel = Instance.new("UICorner")
	cornerPanel.CornerRadius = UDim.new(0, 12)
	cornerPanel.Parent = _panelHorda

	local strokePanel = Instance.new("UIStroke")
	strokePanel.Color = Color3.fromRGB(215, 50, 65)
	strokePanel.Thickness = 2
	strokePanel.Parent = _panelHorda

	_lblOleada = Instance.new("TextLabel")
	_lblOleada.Name = "TextoOleada"
	_lblOleada.Size = UDim2.new(1, -20, 0, 30)
	_lblOleada.Position = UDim2.fromOffset(12, 8)
	_lblOleada.BackgroundTransparency = 1
	_lblOleada.Font = Enum.Font.FredokaOne
	_lblOleada.Text = "💀 OLEADA 1"
	_lblOleada.TextColor3 = Color3.fromRGB(255, 95, 95)
	_lblOleada.TextSize = 21
	_lblOleada.TextXAlignment = Enum.TextXAlignment.Left
	_lblOleada.Parent = _panelHorda

	_lblEstado = Instance.new("TextLabel")
	_lblEstado.Name = "TextoEstado"
	_lblEstado.Size = UDim2.new(1, -20, 0, 20)
	_lblEstado.Position = UDim2.fromOffset(12, 38)
	_lblEstado.BackgroundTransparency = 1
	_lblEstado.Font = Enum.Font.GothamBold
	_lblEstado.Text = "HORDA EN CURSO"
	_lblEstado.TextColor3 = Color3.fromRGB(255, 220, 130)
	_lblEstado.TextSize = 12
	_lblEstado.TextXAlignment = Enum.TextXAlignment.Left
	_lblEstado.Parent = _panelHorda

	_lblZombis = Instance.new("TextLabel")
	_lblZombis.Name = "ContadorZombis"
	_lblZombis.Size = UDim2.new(1, -20, 0, 24)
	_lblZombis.Position = UDim2.fromOffset(12, 58)
	_lblZombis.BackgroundTransparency = 1
	_lblZombis.Font = Enum.Font.FredokaOne
	_lblZombis.Text = "🧟 Zombis restantes: 0"
	_lblZombis.TextColor3 = Color3.fromRGB(235, 240, 250)
	_lblZombis.TextSize = 15
	_lblZombis.TextXAlignment = Enum.TextXAlignment.Left
	_lblZombis.Parent = _panelHorda

	-- Banner central dramático para anuncios de oleada
	_bannerCentral = Instance.new("Frame")
	_bannerCentral.Name = "BannerOleada"
	_bannerCentral.Size = UDim2.fromOffset(440, 74)
	_bannerCentral.AnchorPoint = Vector2.new(0.5, 0)
	_bannerCentral.Position = UDim2.new(0.5, 0, 0, -120)
	_bannerCentral.BackgroundColor3 = Color3.fromRGB(28, 16, 22)
	_bannerCentral.BackgroundTransparency = 0.08
	_bannerCentral.Visible = false
	_bannerCentral.Parent = _screenGui

	local cornerBan = Instance.new("UICorner")
	cornerBan.CornerRadius = UDim.new(0, 14)
	cornerBan.Parent = _bannerCentral

	_strokeBanner = Instance.new("UIStroke")
	_strokeBanner.Color = Color3.fromRGB(235, 65, 75)
	_strokeBanner.Thickness = 2.5
	_strokeBanner.Parent = _bannerCentral

	_lblBannerTitulo = Instance.new("TextLabel")
	_lblBannerTitulo.Size = UDim2.new(1, -20, 0, 36)
	_lblBannerTitulo.Position = UDim2.fromOffset(10, 8)
	_lblBannerTitulo.BackgroundTransparency = 1
	_lblBannerTitulo.Font = Enum.Font.FredokaOne
	_lblBannerTitulo.Text = "OLEADA 1"
	_lblBannerTitulo.TextColor3 = Color3.fromRGB(255, 95, 95)
	_lblBannerTitulo.TextSize = 26
	_lblBannerTitulo.Parent = _bannerCentral

	_lblBannerSub = Instance.new("TextLabel")
	_lblBannerSub.Size = UDim2.new(1, -20, 0, 22)
	_lblBannerSub.Position = UDim2.fromOffset(10, 44)
	_lblBannerSub.BackgroundTransparency = 1
	_lblBannerSub.Font = Enum.Font.GothamBold
	_lblBannerSub.Text = "Sobrevive a los muertos vivientes"
	_lblBannerSub.TextColor3 = Color3.fromRGB(255, 235, 190)
	_lblBannerSub.TextSize = 13
	_lblBannerSub.Parent = _bannerCentral
end

local function manejarActualizacionEstado(datosEstado: {
	Estado: string,
	Oleada: number,
	ZombisRestantes: number,
	TotalOleada: number,
	Mensaje: string,
	TiempoRestante: number,
})
	local estado = datosEstado.Estado
	local oleada = datosEstado.Oleada or 0
	local restantes = datosEstado.ZombisRestantes or 0
	local total = datosEstado.TotalOleada or 0
	local mensaje = datosEstado.Mensaje or ""
	local tiempo = datosEstado.TiempoRestante or 0

	if estado == "Inactiva" then
		_panelHorda.Visible = false
		_ultimaOleadaAnunciada = 0
		_ultimoMensajeAnunciado = ""
		actualizarMusicaTension(false)
		if mensaje ~= "" then
			mostrarBannerOleada("HORDA FINALIZADA", mensaje, Color3.fromRGB(190, 80, 90), 3.2)
		end
		return
	end

	_panelHorda.Visible = true
	actualizarMusicaTension(true)

	if estado == "CuentaRegresiva" then
		_lblOleada.Text = "⚠️ LA HORDA SE ACERCA..."
		_lblEstado.Text = string.format("Primera oleada en %ds", tiempo)
		_lblZombis.Text = "Prepárate para combatir"

		if _ultimoMensajeAnunciado ~= "CuentaRegresiva" then
			_ultimoMensajeAnunciado = "CuentaRegresiva"
			reproducirSonido(ConfigZombis.Sonidos.InicioOleada, 0.7)
			mostrarBannerOleada(
				"LA HORDA SE ACERCA...",
				string.format("Sobrevive — Iniciando en %d segundos", tiempo),
				Color3.fromRGB(255, 165, 50),
				3.5
			)
		else
			reproducirSonido(ConfigZombis.Sonidos.AlertaUI, 0.35)
		end
	elseif estado == "EnCurso" then
		_lblOleada.Text = string.format("💀 OLEADA %d", oleada)
		_lblEstado.Text = "COMBATE ACTIVO"
		_lblZombis.Text = string.format("🧟 Zombis restantes: %d / %d", restantes, total)

		if _ultimaOleadaAnunciada ~= oleada then
			_ultimaOleadaAnunciada = oleada
			_ultimoMensajeAnunciado = "Oleada_" .. tostring(oleada)
			reproducirSonido(ConfigZombis.Sonidos.InicioOleada, 0.75)
			mostrarBannerOleada(
				string.format("OLEADA %d", oleada),
				string.format("%d enemigos emergen de las sombras", total),
				Color3.fromRGB(235, 55, 65),
				3.4
			)
		end
	elseif estado == "OleadaCompletada" then
		_lblOleada.Text = string.format("✓ OLEADA %d", oleada)
		_lblEstado.Text = string.format("Siguiente oleada en %ds", tiempo)
		_lblZombis.Text = "🧟 Zombis restantes: 0"

		if _ultimoMensajeAnunciado ~= ("Completada_" .. tostring(oleada)) then
			_ultimoMensajeAnunciado = "Completada_" .. tostring(oleada)
			reproducirSonido(ConfigZombis.Sonidos.AlertaUI, 0.65)
			mostrarBannerOleada(
				"OLEADA COMPLETADA",
				"TODOS LOS ENEMIGOS ELIMINADOS",
				Color3.fromRGB(80, 225, 130),
				3.5
			)
		end
	end
end

function HordeUI.Iniciar()
	construirInterfaz()
	local evEstado = EventosRemotos.EstadoHordaActualizado
	if not evEstado then
		local f = ReplicatedStorage:WaitForChild("EventosRemotos", 10)
		evEstado = f and f:WaitForChild("EstadoHordaActualizado", 10) :: RemoteEvent?
	end
	if evEstado and evEstado:IsA("RemoteEvent") then
		evEstado.OnClientEvent:Connect(manejarActualizacionEstado)
	else
		warn("[HordeUI] No se pudo conectar EstadoHordaActualizado RemoteEvent")
	end
end

return HordeUI
