--!strict
--[[
	HordeUI.luau
	Interfaz de supervivencia por oleadas estilo Call of Duty Zombies
	adaptada a El Patrón del Dulce, con soporte de roles (Participante,
	Eliminado, Espectador), caché de renderizado y resumen final.
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

local _cacheOleadaTxt = ""
local _cacheEstadoTxt = ""
local _cacheZombisTxt = ""

local function setTextCached(lbl: TextLabel, txt: string, cache: string): string
	if cache ~= txt then
		lbl.Text = txt
		return txt
	end
	return cache
end

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
		if coroutine.running() ~= h then
			pcall(task.cancel, h)
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

	_panelHorda = Instance.new("Frame")
	_panelHorda.Name = "PanelEstadoHorda"
	_panelHorda.Size = UDim2.fromOffset(265, 96)
	_panelHorda.AnchorPoint = Vector2.new(1, 0)
	_panelHorda.Position = UDim2.new(1, -20, 0, 20)
	_panelHorda.BackgroundColor3 = Color3.fromRGB(22, 18, 26)
	_panelHorda.BackgroundTransparency = 0.12
	_panelHorda.Visible = false
	_panelHorda.Parent = _screenGui

	local sizeConsPanel = Instance.new("UISizeConstraint")
	sizeConsPanel.MinSize = Vector2.new(210, 78)
	sizeConsPanel.MaxSize = Vector2.new(300, 110)
	sizeConsPanel.Parent = _panelHorda

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
	_lblEstado.Position = UDim2.fromOffset(12, 39)
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
	_lblZombis.Position = UDim2.fromOffset(12, 62)
	_lblZombis.BackgroundTransparency = 1
	_lblZombis.Font = Enum.Font.FredokaOne
	_lblZombis.Text = "🧟 Zombis restantes: 0"
	_lblZombis.TextColor3 = Color3.fromRGB(235, 240, 250)
	_lblZombis.TextSize = 14
	_lblZombis.TextXAlignment = Enum.TextXAlignment.Left
	_lblZombis.Parent = _panelHorda

	_bannerCentral = Instance.new("Frame")
	_bannerCentral.Name = "BannerOleada"
	_bannerCentral.Size = UDim2.fromOffset(460, 76)
	_bannerCentral.AnchorPoint = Vector2.new(0.5, 0)
	_bannerCentral.Position = UDim2.new(0.5, 0, 0, -120)
	_bannerCentral.BackgroundColor3 = Color3.fromRGB(28, 16, 22)
	_bannerCentral.BackgroundTransparency = 0.08
	_bannerCentral.Visible = false
	_bannerCentral.Parent = _screenGui

	local sizeConsBanner = Instance.new("UISizeConstraint")
	sizeConsBanner.MinSize = Vector2.new(300, 68)
	sizeConsBanner.MaxSize = Vector2.new(520, 92)
	sizeConsBanner.Parent = _bannerCentral

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
	_lblBannerTitulo.TextSize = 25
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
	Rol: string?,
	ParticipantesVivos: number?,
	TotalParticipantes: number?,
	ResumenFinal: {
		Bajas: number,
		OleadasSobrevividas: number,
		PesosGanados: number,
		FamaGanada: number,
	}?,
})
	local estado = datosEstado.Estado
	local oleada = datosEstado.Oleada or 0
	local restantes = datosEstado.ZombisRestantes or 0
	local total = datosEstado.TotalOleada or 0
	local mensaje = datosEstado.Mensaje or ""
	local tiempo = datosEstado.TiempoRestante or 0
	local rol = datosEstado.Rol or "Espectador"
	local vivos = datosEstado.ParticipantesVivos or 0
	local totalPart = datosEstado.TotalParticipantes or 0

	if estado == "Inactiva" or estado == "Finalizando" then
		_panelHorda.Visible = false
		_ultimaOleadaAnunciada = 0
		_ultimoMensajeAnunciado = ""
		actualizarMusicaTension(false)

		if estado == "Inactiva" and (mensaje ~= "" or datosEstado.ResumenFinal) then
			local res = datosEstado.ResumenFinal
			local sub = if res
				then string.format(
					"%s • %d bajas | %d oleadas | +$%d | +%d Fama",
					mensaje,
					res.Bajas or 0,
					res.OleadasSobrevividas or 0,
					res.PesosGanados or 0,
					res.FamaGanada or 0
				)
				else mensaje
			mostrarBannerOleada("HORDA FINALIZADA", sub, Color3.fromRGB(190, 80, 90), 4.2)
		end
		return
	end

	_panelHorda.Visible = true

	-- Espectadores (jugadores nuevos que entraron después del inicio) no oyen música de combate
	if rol == "Espectador" then
		actualizarMusicaTension(false)
		_cacheOleadaTxt = setTextCached(
			_lblOleada,
			string.format("👁️ ESPECTADOR — OLEADA %d", math.max(1, oleada)),
			_cacheOleadaTxt
		)
		_cacheEstadoTxt = setTextCached(
			_lblEstado,
			string.format("Horda cooperativa en curso (%d/%d vivos)", vivos, totalPart),
			_cacheEstadoTxt
		)
		_cacheZombisTxt =
			setTextCached(_lblZombis, "Espera a que termine para unirte", _cacheZombisTxt)
		return
	end

	-- Participantes eliminados esperan el fin de la sesión sin alertas invasivas
	if rol == "Eliminado" then
		actualizarMusicaTension(false)
		_cacheOleadaTxt = setTextCached(
			_lblOleada,
			string.format("☠️ ELIMINADO — OLEADA %d", math.max(1, oleada)),
			_cacheOleadaTxt
		)
		_cacheEstadoTxt = setTextCached(
			_lblEstado,
			string.format("Esperando fin de horda (%d/%d vivos)", vivos, totalPart),
			_cacheEstadoTxt
		)
		_cacheZombisTxt = setTextCached(
			_lblZombis,
			string.format("🧟 Zombis restantes: %d", restantes),
			_cacheZombisTxt
		)
		return
	end

	actualizarMusicaTension(true)

	if estado == "Preparando" or estado == "CuentaRegresiva" then
		_cacheOleadaTxt = setTextCached(_lblOleada, "⚠️ LA HORDA SE ACERCA...", _cacheOleadaTxt)
		_cacheEstadoTxt = setTextCached(
			_lblEstado,
			string.format("Oleada 1 en %ds • Vivos: %d", tiempo, vivos),
			_cacheEstadoTxt
		)
		_cacheZombisTxt = setTextCached(_lblZombis, "Prepárate para combatir", _cacheZombisTxt)

		if estado == "CuentaRegresiva" and _ultimoMensajeAnunciado ~= "CuentaRegresiva" then
			_ultimoMensajeAnunciado = "CuentaRegresiva"
			reproducirSonido(ConfigZombis.Sonidos.InicioOleada, 0.7)
			mostrarBannerOleada(
				"LA HORDA SE ACERCA...",
				string.format("Sobrevive — Iniciando en %d segundos", tiempo),
				Color3.fromRGB(255, 165, 50),
				3.5
			)
		elseif estado == "CuentaRegresiva" then
			reproducirSonido(ConfigZombis.Sonidos.AlertaUI, 0.3)
		end
	elseif estado == "EnCurso" then
		_cacheOleadaTxt =
			setTextCached(_lblOleada, string.format("💀 OLEADA %d", oleada), _cacheOleadaTxt)
		_cacheEstadoTxt = setTextCached(
			_lblEstado,
			string.format("COMBATE ACTIVO • Vivos: %d/%d", vivos, totalPart),
			_cacheEstadoTxt
		)
		_cacheZombisTxt = setTextCached(
			_lblZombis,
			string.format("🧟 Zombis restantes: %d / %d", restantes, total),
			_cacheZombisTxt
		)

		if _ultimaOleadaAnunciada ~= oleada then
			_ultimaOleadaAnunciada = oleada
			_ultimoMensajeAnunciado = "Oleada_" .. tostring(oleada)
			reproducirSonido(ConfigZombis.Sonidos.InicioOleada, 0.75)

			local mensajeArmas = tostring(datosEstado.MensajeArmas or "")
			local alertaBase = if oleada == 10
				then "☣️ ¡ALERTA: ZOMBIS TÓXICOS!"
				elseif oleada == 6 then "❄️ ¡ALERTA: ICE ZOMBIES EMERGIENDO!"
				elseif oleada == 3 then "🔥 ¡ALERTA: ZOMBIS DE LAVA!"
				else ""

			local subtitulo = if alertaBase ~= "" and mensajeArmas ~= ""
				then string.format("%s | ⚔️ %s", alertaBase, mensajeArmas)
				elseif alertaBase ~= "" then alertaBase
				elseif mensajeArmas ~= "" then string.format("⚔️ %s", mensajeArmas)
				else string.format("%d enemigos emergen de las sombras", total)

			local colorBorde = if oleada >= 10
				then Color3.fromRGB(113, 255, 61)
				elseif oleada >= 6 then Color3.fromRGB(85, 255, 255)
				elseif oleada >= 3 then Color3.fromRGB(255, 120, 30)
				else Color3.fromRGB(235, 55, 65)

			mostrarBannerOleada(string.format("OLEADA %d", oleada), subtitulo, colorBorde, 3.8)
		end
	elseif estado == "OleadaCompletada" then
		_cacheOleadaTxt =
			setTextCached(_lblOleada, string.format("✓ OLEADA %d", oleada), _cacheOleadaTxt)
		_cacheEstadoTxt = setTextCached(
			_lblEstado,
			string.format("Siguiente oleada en %ds", tiempo),
			_cacheEstadoTxt
		)
		_cacheZombisTxt = setTextCached(_lblZombis, "🧟 Zombis restantes: 0", _cacheZombisTxt)

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

	-- Sincronizar estado real al iniciar o reaparecer
	task.spawn(function()
		local fnEstado = EventosRemotos.ObtenerEstadoHorda
		if fnEstado and fnEstado:IsA("RemoteFunction") then
			local ok, payload = pcall(function()
				return fnEstado:InvokeServer()
			end)
			if ok and typeof(payload) == "table" then
				manejarActualizacionEstado(payload)
			end
		end
	end)
end

return HordeUI
