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
	MensajeArmas: string?,
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
		_cacheOleadaTxt = setTextCached(_lblOleada, string.format("👁️ ESPECTADOR — OLEADA %d", math.max(1, oleada)), _cacheOleadaTxt)
		_cacheEstadoTxt = setTextCached(_lblEstado, string.format("Horda cooperativa en curso (%d/%d vivos)", vivos, totalPart), _cacheEstadoTxt)
		_cacheZombisTxt = setTextCached(_lblZombis, "Espera a que termine para unirte", _cacheZombisTxt)
		return
	end

	-- Participantes eliminados esperan el fin de la sesión sin alertas invasivas
	if rol == "Eliminado" then
		actualizarMusicaTension(false)
		_cacheOleadaTxt = setTextCached(_lblOleada, string.format("☠️ ELIMINADO — OLEADA %d", math.max(1, oleada)), _cacheOleadaTxt)
		_cacheEstadoTxt = setTextCached(_lblEstado, string.format("Esperando fin de horda (%d/%d vivos)", vivos, totalPart), _cacheEstadoTxt)
		_cacheZombisTxt = setTextCached(_lblZombis, string.format("🧟 Zombis restantes: %d", restantes), _cacheZombisTxt)
		return
	end

	actualizarMusicaTension(true)

	if estado == "Preparando" or estado == "CuentaRegresiva" then
		_cacheOleadaTxt = setTextCached(_lblOleada, "⚠️ LA HORDA SE ACERCA...", _cacheOleadaTxt)
		_cacheEstadoTxt = setTextCached(_lblEstado, string.format("Oleada 1 en %ds • Vivos: %d", tiempo, vivos), _cacheEstadoTxt)
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
		_cacheOleadaTxt = setTextCached(_lblOleada, string.format("💀 OLEADA %d", oleada), _cacheOleadaTxt)
		_cacheEstadoTxt = setTextCached(_lblEstado, string.format("COMBATE ACTIVO • Vivos: %d/%d", vivos, totalPart), _cacheEstadoTxt)
		_cacheZombisTxt = setTextCached(_lblZombis, string.format("🧟 Zombis restantes: %d / %d", restantes, total), _cacheZombisTxt)

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
		_cacheOleadaTxt = setTextCached(_lblOleada, string.format("✓ OLEADA %d", oleada), _cacheOleadaTxt)
		_cacheEstadoTxt = setTextCached(_lblEstado, string.format("Siguiente oleada en %ds", tiempo), _cacheEstadoTxt)
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

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- ============================================================================
-- INTERFAZ TÁCTICA CALL OF DUTY ZOMBIES
-- ============================================================================
local _codGui: ScreenGui
local _codRoot: Frame
local _tiraSuperior: Frame
local _lblTiraInfo: TextLabel
local _barraAbatido: Frame
local _lblAbatido: TextLabel

local _contenedorRonda: Frame
local _escalaRonda: UIScale
local _tallyFrame: Frame
local _tallyBarras: { Frame } = {}
local _tallyDiagonal: Frame
local _lblRondaNum: TextLabel
local _lblTipoRonda: TextLabel

local _barraPerks: Frame
local _badgesPerks: { [string]: Frame } = {}
local _placaPuntos: Frame
local _lblPuntos: TextLabel
local _lblEstadisticas: TextLabel
local _bajasLocales = 0

local _contenedorPowerUps: Frame
local _badge2X: Frame
local _lbl2X: TextLabel
local _badgeInsta: Frame
local _lblInsta: TextLabel

local _bannerCoD: Frame
local _lblBannerCoDTitulo: TextLabel
local _lblBannerCoDSub: TextLabel
local _lineaSupBanner: Frame
local _lineaInfBanner: Frame
local _timerBannerCoD: thread? = nil

local _tarjetaResumen: Frame
local _lblResumenTitulo: TextLabel
local _lblResumenSub: TextLabel
local _lblResumenStats: TextLabel
local _timerResumen: thread? = nil

local _codUltimaOleada = 0
local _codUltimoEstadoKey = ""

local PERKS_COD = {
	{ Atributo = "PerkTitanMuela", Sigla = "HP+", Color = Color3.fromRGB(220, 45, 65), Orden = 1 },
	{ Atributo = "PerkVelocidad", Sigla = "VEL", Color = Color3.fromRGB(255, 210, 45), Orden = 2 },
	{ Atributo = "PerkDobleDisparo", Sigla = "2X", Color = Color3.fromRGB(255, 130, 35), Orden = 3 },
	{ Atributo = "PerkRegeneracion", Sigla = "REV", Color = Color3.fromRGB(45, 235, 205), Orden = 4 },
	{ Atributo = "ArmaPotenciada", Sigla = "PAP", Color = Color3.fromRGB(185, 70, 255), Orden = 5 },
}

local function reproducirSonidoCoD(soundId: string, volumen: number, pitch: number?)
	if soundId == "" then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = soundId
	s.Volume = volumen
	s.PlaybackSpeed = pitch or 1.0
	s.Parent = SoundService
	pcall(function()
		s:Play()
	end)
	task.delay(3.0, function()
		if s.Parent then
			s:Destroy()
		end
	end)
end

local function mostrarBannerCoD(titulo: string, subtitulo: string, colorAcento: Color3, duracion: number)
	if _timerBannerCoD then
		local h = _timerBannerCoD
		_timerBannerCoD = nil
		if coroutine.running() ~= h then
			pcall(task.cancel, h)
		end
	end

	_lblBannerCoDTitulo.Text = titulo
	_lblBannerCoDTitulo.TextColor3 = colorAcento
	_lblBannerCoDSub.Text = subtitulo
	_lineaSupBanner.BackgroundColor3 = colorAcento
	_lineaInfBanner.BackgroundColor3 = colorAcento

	_bannerCoD.Visible = true
	_bannerCoD.BackgroundTransparency = 1
	_lblBannerCoDTitulo.TextTransparency = 1
	_lblBannerCoDSub.TextTransparency = 1
	_lineaSupBanner.BackgroundTransparency = 1
	_lineaInfBanner.BackgroundTransparency = 1

	TweenService:Create(_bannerCoD, TweenInfo.new(0.28), { BackgroundTransparency = 0.28 }):Play()
	TweenService:Create(_lblBannerCoDTitulo, TweenInfo.new(0.28), { TextTransparency = 0 }):Play()
	TweenService:Create(_lblBannerCoDSub, TweenInfo.new(0.28), { TextTransparency = 0 }):Play()
	TweenService:Create(_lineaSupBanner, TweenInfo.new(0.28), { BackgroundTransparency = 0.15 }):Play()
	TweenService:Create(_lineaInfBanner, TweenInfo.new(0.28), { BackgroundTransparency = 0.15 }):Play()

	_timerBannerCoD = task.delay(duracion, function()
		_timerBannerCoD = nil
		TweenService:Create(_bannerCoD, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(_lblBannerCoDTitulo, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
		TweenService:Create(_lblBannerCoDSub, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
		TweenService:Create(_lineaSupBanner, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
		local tOut = TweenService:Create(_lineaInfBanner, TweenInfo.new(0.35), { BackgroundTransparency = 1 })
		tOut:Play()
		tOut.Completed:Connect(function()
			if _timerBannerCoD == nil then
				_bannerCoD.Visible = false
			end
		end)
	end)
end

local function animarCambioRonda(oleada: number)
	_escalaRonda.Scale = 1.38
	TweenService:Create(_escalaRonda, TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1.0,
	}):Play()

	local colorRojo = Color3.fromRGB(205, 25, 32)
	local colorBlanco = Color3.fromRGB(255, 245, 235)

	if oleada >= 1 and oleada <= 5 then
		for i, bar in ipairs(_tallyBarras) do
			bar.Visible = i <= math.min(4, oleada)
			bar.BackgroundColor3 = colorBlanco
			TweenService:Create(bar, TweenInfo.new(1.1), { BackgroundColor3 = colorRojo }):Play()
		end
		_tallyDiagonal.Visible = oleada >= 5
		if _tallyDiagonal.Visible then
			_tallyDiagonal.BackgroundColor3 = colorBlanco
			TweenService:Create(_tallyDiagonal, TweenInfo.new(1.1), { BackgroundColor3 = colorRojo }):Play()
		end
	else
		_lblRondaNum.TextColor3 = colorBlanco
		TweenService:Create(_lblRondaNum, TweenInfo.new(1.1), { TextColor3 = colorRojo }):Play()
	end
end

local function actualizarRondaVisual(oleada: number, esEspecial: boolean, esJefe: boolean, enCuentaRegresiva: boolean)
	if enCuentaRegresiva or oleada <= 0 then
		_tallyFrame.Visible = false
		_lblRondaNum.Visible = true
		_lblRondaNum.Text = "!"
		_lblTipoRonda.Text = "PREPARANDO"
		_lblTipoRonda.TextColor3 = Color3.fromRGB(240, 185, 65)
		return
	end

	if oleada <= 5 then
		_tallyFrame.Visible = true
		_lblRondaNum.Visible = false
		for i, bar in ipairs(_tallyBarras) do
			bar.Visible = i <= math.min(4, oleada)
		end
		_tallyDiagonal.Visible = oleada >= 5
	else
		_tallyFrame.Visible = false
		_lblRondaNum.Visible = true
		_lblRondaNum.Text = tostring(oleada)
	end

	if esEspecial then
		_lblTipoRonda.Text = "RONDA ESPECIAL"
		_lblTipoRonda.TextColor3 = Color3.fromRGB(255, 145, 45)
	elseif esJefe then
		_lblTipoRonda.Text = "JEFE EN CAMINO"
		_lblTipoRonda.TextColor3 = Color3.fromRGB(255, 65, 75)
	else
		_lblTipoRonda.Text = "RONDA " .. tostring(oleada)
		_lblTipoRonda.TextColor3 = Color3.fromRGB(190, 185, 185)
	end
end

local function actualizarPerksVisual()
	for _, cfg in ipairs(PERKS_COD) do
		local badge = _badgesPerks[cfg.Atributo]
		if badge then
			badge.Visible = LocalPlayer:GetAttribute(cfg.Atributo) == true
		end
	end
end

local function actualizarPuntuacionVisual()
	local pts = tonumber(LocalPlayer:GetAttribute("PuntosLazarusAcumulados")) or 0
	local criticos = tonumber(LocalPlayer:GetAttribute("HordaCriticos")) or 0
	_lblPuntos.Text = string.format("$%d", pts)
	_lblEstadisticas.Text = string.format("BAJAS: %d  •  CRÍTICOS: %d", _bajasLocales, criticos)
end

local function actualizarPowerUpsVisual()
	local hay2X = Workspace:GetAttribute("LazarusPuntosDobles") == true
	local seg2X = tonumber(Workspace:GetAttribute("LazarusPuntosDoblesSegundos")) or 0
	_badge2X.Visible = hay2X
	if hay2X then
		_lbl2X.Text = string.format("2X PUNTOS (%ds)", seg2X)
	end

	local hayInsta = Workspace:GetAttribute("LazarusInstaKill") == true
	local segInsta = tonumber(Workspace:GetAttribute("LazarusInstaKillSegundos")) or 0
	_badgeInsta.Visible = hayInsta
	if hayInsta then
		_lblInsta.Text = string.format("INSTA-KILL (%ds)", segInsta)
	end
end

local function lanzarPopupPuntos(puntos: number, esCritico: boolean)
	if not _codRoot.Visible or puntos <= 0 then
		return
	end
	local popup = Instance.new("TextLabel")
	popup.Name = "ScorePopup"
	popup.AnchorPoint = Vector2.new(1, 1)
	popup.Position = UDim2.new(1, -28 + math.random(-14, 4), 1, -104)
	popup.Size = UDim2.fromOffset(110, 26)
	popup.BackgroundTransparency = 1
	popup.Font = Enum.Font.GothamBold
	popup.Text = string.format("+%d", puntos)
	popup.TextColor3 = if esCritico then Color3.fromRGB(255, 95, 75) else Color3.fromRGB(255, 215, 55)
	popup.TextStrokeTransparency = 0.25
	popup.TextSize = if esCritico then 20 else 17
	popup.TextXAlignment = Enum.TextXAlignment.Right
	popup.ZIndex = 20
	popup.Parent = _codGui

	local dx = math.random(-28, -4)
	local dy = math.random(-56, -38)
	local t = TweenService:Create(popup, TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, -28 + dx, 1, -104 + dy),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	t:Play()
	t.Completed:Connect(function()
		popup:Destroy()
	end)
end

local function mostrarTarjetaResumen(res: { Bajas: number?, TirosCriticos: number?, OleadasSobrevividas: number?, PesosGanados: number?, FamaGanada: number? }, mensaje: string)
	if _timerResumen then
		local h = _timerResumen
		_timerResumen = nil
		if coroutine.running() ~= h then
			pcall(task.cancel, h)
		end
	end

	local rondas = res.OleadasSobrevividas or 0
	_lblResumenTitulo.Text = if rondas == 1 then "SOBREVIVISTE 1 RONDA" else string.format("SOBREVIVISTE %d RONDAS", rondas)
	_lblResumenSub.Text = if mensaje ~= "" then mensaje else "Operación de supervivencia concluida"
	_lblResumenStats.Text = string.format(
		"BAJAS TOTALES: %d   •   TIROS CRÍTICOS: %d\nRECOMPENSA: +$%d PESOS   •   +%d FAMA",
		res.Bajas or 0,
		res.TirosCriticos or 0,
		res.PesosGanados or 0,
		res.FamaGanada or 0
	)

	_tarjetaResumen.Visible = true
	_timerResumen = task.delay(8.0, function()
		_timerResumen = nil
		_tarjetaResumen.Visible = false
	end)
end

local function construirInterfazCoD()
	local previoLegacy = PlayerGui:FindFirstChild("UI_HordaZombis")
	if previoLegacy then
		previoLegacy:Destroy()
	end
	local previo = PlayerGui:FindFirstChild("UI_HordaCoD")
	if previo then
		previo:Destroy()
	end

	_codGui = Instance.new("ScreenGui")
	_codGui.Name = "UI_HordaCoD"
	_codGui.ResetOnSpawn = false
	_codGui.IgnoreGuiInset = true
	_codGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	_codGui.DisplayOrder = 19
	_codGui.Parent = PlayerGui

	_codRoot = Instance.new("Frame")
	_codRoot.Name = "ContenedorCoD"
	_codRoot.Size = UDim2.fromScale(1, 1)
	_codRoot.BackgroundTransparency = 1
	_codRoot.Visible = false
	_codRoot.Parent = _codGui

	-- 1. Tira táctica superior
	_tiraSuperior = Instance.new("Frame")
	_tiraSuperior.Name = "TiraSuperior"
	_tiraSuperior.AnchorPoint = Vector2.new(0.5, 0)
	_tiraSuperior.Position = UDim2.new(0.5, 0, 0, 14)
	_tiraSuperior.Size = UDim2.fromOffset(390, 30)
	_tiraSuperior.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
	_tiraSuperior.BackgroundTransparency = 0.25
	_tiraSuperior.BorderSizePixel = 0
	_tiraSuperior.Parent = _codRoot

	local cornerTira = Instance.new("UICorner")
	cornerTira.CornerRadius = UDim.new(0, 4)
	cornerTira.Parent = _tiraSuperior

	local strokeTira = Instance.new("UIStroke")
	strokeTira.Color = Color3.fromRGB(145, 28, 34)
	strokeTira.Thickness = 1.2
	strokeTira.Transparency = 0.35
	strokeTira.Parent = _tiraSuperior

	_lblTiraInfo = Instance.new("TextLabel")
	_lblTiraInfo.Size = UDim2.fromScale(1, 1)
	_lblTiraInfo.BackgroundTransparency = 1
	_lblTiraInfo.Font = Enum.Font.GothamBold
	_lblTiraInfo.Text = "ENEMIGOS RESTANTES: 0  |  SUPERVIVIENTES: 0/0"
	_lblTiraInfo.TextColor3 = Color3.fromRGB(230, 226, 222)
	_lblTiraInfo.TextSize = 12
	_lblTiraInfo.Parent = _tiraSuperior

	_barraAbatido = Instance.new("Frame")
	_barraAbatido.Name = "BarraAbatido"
	_barraAbatido.AnchorPoint = Vector2.new(0.5, 0)
	_barraAbatido.Position = UDim2.new(0.5, 0, 0, 50)
	_barraAbatido.Size = UDim2.fromOffset(370, 28)
	_barraAbatido.BackgroundColor3 = Color3.fromRGB(95, 12, 16)
	_barraAbatido.BackgroundTransparency = 0.15
	_barraAbatido.Visible = false
	_barraAbatido.Parent = _codRoot

	local cornerAbat = Instance.new("UICorner")
	cornerAbat.CornerRadius = UDim.new(0, 4)
	cornerAbat.Parent = _barraAbatido

	_lblAbatido = Instance.new("TextLabel")
	_lblAbatido.Size = UDim2.fromScale(1, 1)
	_lblAbatido.BackgroundTransparency = 1
	_lblAbatido.Font = Enum.Font.GothamBold
	_lblAbatido.Text = "ABATIDO — DESANGRÁNDOSE EN 30s"
	_lblAbatido.TextColor3 = Color3.fromRGB(255, 225, 225)
	_lblAbatido.TextSize = 12
	_lblAbatido.Parent = _barraAbatido

	-- 2. Contador de Ronda icónico (Abajo-Izquierda)
	_contenedorRonda = Instance.new("Frame")
	_contenedorRonda.Name = "ContadorRonda"
	_contenedorRonda.AnchorPoint = Vector2.new(0, 1)
	_contenedorRonda.Position = UDim2.new(0, 26, 1, -24)
	_contenedorRonda.Size = UDim2.fromOffset(124, 84)
	_contenedorRonda.BackgroundTransparency = 1
	_contenedorRonda.Parent = _codRoot

	_escalaRonda = Instance.new("UIScale")
	_escalaRonda.Scale = 1
	_escalaRonda.Parent = _contenedorRonda

	_tallyFrame = Instance.new("Frame")
	_tallyFrame.Name = "MarcasTally"
	_tallyFrame.Size = UDim2.fromOffset(115, 62)
	_tallyFrame.BackgroundTransparency = 1
	_tallyFrame.Parent = _contenedorRonda

	table.clear(_tallyBarras)
	local rotaciones = { -3, 2, -2, 3 }
	for i = 1, 4 do
		local bar = Instance.new("Frame")
		bar.Name = "Tally_" .. i
		bar.Size = UDim2.fromOffset(8, 54)
		bar.Position = UDim2.fromOffset((i - 1) * 19 + 8, 4)
		bar.Rotation = rotaciones[i]
		bar.BackgroundColor3 = Color3.fromRGB(205, 25, 32)
		bar.BorderSizePixel = 0
		bar.Visible = false
		bar.Parent = _tallyFrame

		local st = Instance.new("UIStroke")
		st.Color = Color3.fromRGB(35, 6, 8)
		st.Thickness = 1.5
		st.Parent = bar

		table.insert(_tallyBarras, bar)
	end

	_tallyDiagonal = Instance.new("Frame")
	_tallyDiagonal.Name = "TallyDiagonal"
	_tallyDiagonal.AnchorPoint = Vector2.new(0.5, 0.5)
	_tallyDiagonal.Position = UDim2.fromOffset(42, 31)
	_tallyDiagonal.Size = UDim2.fromOffset(92, 8)
	_tallyDiagonal.Rotation = -34
	_tallyDiagonal.BackgroundColor3 = Color3.fromRGB(205, 25, 32)
	_tallyDiagonal.BorderSizePixel = 0
	_tallyDiagonal.Visible = false
	_tallyDiagonal.ZIndex = 3
	_tallyDiagonal.Parent = _tallyFrame

	local stDiag = Instance.new("UIStroke")
	stDiag.Color = Color3.fromRGB(35, 6, 8)
	stDiag.Thickness = 1.5
	stDiag.Parent = _tallyDiagonal

	_lblRondaNum = Instance.new("TextLabel")
	_lblRondaNum.Name = "NumeroRonda"
	_lblRondaNum.Size = UDim2.fromOffset(115, 62)
	_lblRondaNum.BackgroundTransparency = 1
	_lblRondaNum.Font = Enum.Font.Oswald
	_lblRondaNum.Text = "6"
	_lblRondaNum.TextColor3 = Color3.fromRGB(205, 25, 32)
	_lblRondaNum.TextStrokeColor3 = Color3.fromRGB(25, 5, 8)
	_lblRondaNum.TextStrokeTransparency = 0.15
	_lblRondaNum.TextSize = 64
	_lblRondaNum.TextXAlignment = Enum.TextXAlignment.Left
	_lblRondaNum.Visible = false
	_lblRondaNum.Parent = _contenedorRonda

	_lblTipoRonda = Instance.new("TextLabel")
	_lblTipoRonda.Name = "SubRonda"
	_lblTipoRonda.Position = UDim2.fromOffset(2, 64)
	_lblTipoRonda.Size = UDim2.fromOffset(140, 18)
	_lblTipoRonda.BackgroundTransparency = 1
	_lblTipoRonda.Font = Enum.Font.GothamBold
	_lblTipoRonda.Text = "RONDA 1"
	_lblTipoRonda.TextColor3 = Color3.fromRGB(190, 185, 185)
	_lblTipoRonda.TextSize = 11
	_lblTipoRonda.TextXAlignment = Enum.TextXAlignment.Left
	_lblTipoRonda.Parent = _contenedorRonda

	-- 3. Tira de Perks (junto al contador de ronda)
	_barraPerks = Instance.new("Frame")
	_barraPerks.Name = "BarraPerks"
	_barraPerks.AnchorPoint = Vector2.new(0, 1)
	_barraPerks.Position = UDim2.new(0, 154, 1, -28)
	_barraPerks.Size = UDim2.fromOffset(260, 42)
	_barraPerks.BackgroundTransparency = 1
	_barraPerks.Parent = _codRoot

	local layoutPerks = Instance.new("UIListLayout")
	layoutPerks.FillDirection = Enum.FillDirection.Horizontal
	layoutPerks.SortOrder = Enum.SortOrder.LayoutOrder
	layoutPerks.Padding = UDim.new(0, 8)
	layoutPerks.VerticalAlignment = Enum.VerticalAlignment.Center
	layoutPerks.Parent = _barraPerks

	table.clear(_badgesPerks)
	for _, cfg in ipairs(PERKS_COD) do
		local badge = Instance.new("Frame")
		badge.Name = "Perk_" .. cfg.Atributo
		badge.Size = UDim2.fromOffset(38, 38)
		badge.LayoutOrder = cfg.Orden
		badge.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
		badge.BackgroundTransparency = 0.15
		badge.Visible = false
		badge.Parent = _barraPerks

		local cB = Instance.new("UICorner")
		cB.CornerRadius = UDim.new(0, 6)
		cB.Parent = badge

		local sB = Instance.new("UIStroke")
		sB.Color = cfg.Color
		sB.Thickness = 2
		sB.Parent = badge

		local lblB = Instance.new("TextLabel")
		lblB.Size = UDim2.fromScale(1, 1)
		lblB.BackgroundTransparency = 1
		lblB.Font = Enum.Font.GothamBlack
		lblB.Text = cfg.Sigla
		lblB.TextColor3 = cfg.Color
		lblB.TextSize = 13
		lblB.Parent = badge

		_badgesPerks[cfg.Atributo] = badge
	end

	-- 4. Placa de puntuación y combate (Abajo-Derecha)
	_placaPuntos = Instance.new("Frame")
	_placaPuntos.Name = "PlacaPuntuacion"
	_placaPuntos.AnchorPoint = Vector2.new(1, 1)
	_placaPuntos.Position = UDim2.new(1, -26, 1, -24)
	_placaPuntos.Size = UDim2.fromOffset(228, 70)
	_placaPuntos.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
	_placaPuntos.BackgroundTransparency = 0.22
	_placaPuntos.Parent = _codRoot

	local cPlaca = Instance.new("UICorner")
	cPlaca.CornerRadius = UDim.new(0, 6)
	cPlaca.Parent = _placaPuntos

	local sPlaca = Instance.new("UIStroke")
	sPlaca.Color = Color3.fromRGB(165, 35, 42)
	sPlaca.Thickness = 1.5
	sPlaca.Transparency = 0.25
	sPlaca.Parent = _placaPuntos

	_lblPuntos = Instance.new("TextLabel")
	_lblPuntos.Position = UDim2.fromOffset(12, 6)
	_lblPuntos.Size = UDim2.new(1, -24, 0, 34)
	_lblPuntos.BackgroundTransparency = 1
	_lblPuntos.Font = Enum.Font.Oswald
	_lblPuntos.Text = "$0"
	_lblPuntos.TextColor3 = Color3.fromRGB(255, 215, 70)
	_lblPuntos.TextSize = 30
	_lblPuntos.TextXAlignment = Enum.TextXAlignment.Right
	_lblPuntos.Parent = _placaPuntos

	_lblEstadisticas = Instance.new("TextLabel")
	_lblEstadisticas.Position = UDim2.fromOffset(12, 42)
	_lblEstadisticas.Size = UDim2.new(1, -24, 0, 20)
	_lblEstadisticas.BackgroundTransparency = 1
	_lblEstadisticas.Font = Enum.Font.GothamBold
	_lblEstadisticas.Text = "BAJAS: 0  •  CRÍTICOS: 0"
	_lblEstadisticas.TextColor3 = Color3.fromRGB(210, 206, 202)
	_lblEstadisticas.TextSize = 11
	_lblEstadisticas.TextXAlignment = Enum.TextXAlignment.Right
	_lblEstadisticas.Parent = _placaPuntos

	-- 5. Power-Ups activos (Abajo-Centro)
	_contenedorPowerUps = Instance.new("Frame")
	_contenedorPowerUps.Name = "PowerUpsActivos"
	_contenedorPowerUps.AnchorPoint = Vector2.new(0.5, 1)
	_contenedorPowerUps.Position = UDim2.new(0.5, 0, 1, -26)
	_contenedorPowerUps.Size = UDim2.fromOffset(340, 34)
	_contenedorPowerUps.BackgroundTransparency = 1
	_contenedorPowerUps.Parent = _codRoot

	local layoutPU = Instance.new("UIListLayout")
	layoutPU.FillDirection = Enum.FillDirection.Horizontal
	layoutPU.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layoutPU.Padding = UDim.new(0, 10)
	layoutPU.Parent = _contenedorPowerUps

	local function crearBadgePowerUp(nombre: string, color: Color3): (Frame, TextLabel)
		local f = Instance.new("Frame")
		f.Name = nombre
		f.Size = UDim2.fromOffset(154, 30)
		f.BackgroundColor3 = Color3.fromRGB(16, 14, 18)
		f.BackgroundTransparency = 0.2
		f.Visible = false
		f.Parent = _contenedorPowerUps

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 4)
		c.Parent = f

		local st = Instance.new("UIStroke")
		st.Color = color
		st.Thickness = 1.6
		st.Parent = f

		local l = Instance.new("TextLabel")
		l.Size = UDim2.fromScale(1, 1)
		l.BackgroundTransparency = 1
		l.Font = Enum.Font.GothamBold
		l.TextColor3 = color
		l.TextSize = 12
		l.Text = nombre
		l.Parent = f

		return f, l
	end

	_badge2X, _lbl2X = crearBadgePowerUp("2X PUNTOS", Color3.fromRGB(255, 220, 65))
	_badgeInsta, _lblInsta = crearBadgePowerUp("INSTA-KILL", Color3.fromRGB(255, 65, 85))

	-- 6. Banner cinemático central estilo CoD
	_bannerCoD = Instance.new("Frame")
	_bannerCoD.Name = "BannerCinematograficoCoD"
	_bannerCoD.AnchorPoint = Vector2.new(0.5, 0)
	_bannerCoD.Position = UDim2.new(0.5, 0, 0, 96)
	_bannerCoD.Size = UDim2.fromOffset(520, 74)
	_bannerCoD.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
	_bannerCoD.BackgroundTransparency = 1
	_bannerCoD.BorderSizePixel = 0
	_bannerCoD.Visible = false
	_bannerCoD.Parent = _codGui

	_lineaSupBanner = Instance.new("Frame")
	_lineaSupBanner.Size = UDim2.new(1, 0, 0, 2)
	_lineaSupBanner.BackgroundColor3 = Color3.fromRGB(205, 35, 42)
	_lineaSupBanner.BorderSizePixel = 0
	_lineaSupBanner.Parent = _bannerCoD

	_lineaInfBanner = Instance.new("Frame")
	_lineaInfBanner.Position = UDim2.new(0, 0, 1, -2)
	_lineaInfBanner.Size = UDim2.new(1, 0, 0, 2)
	_lineaInfBanner.BackgroundColor3 = Color3.fromRGB(205, 35, 42)
	_lineaInfBanner.BorderSizePixel = 0
	_lineaInfBanner.Parent = _bannerCoD

	_lblBannerCoDTitulo = Instance.new("TextLabel")
	_lblBannerCoDTitulo.Position = UDim2.fromOffset(12, 8)
	_lblBannerCoDTitulo.Size = UDim2.new(1, -24, 0, 34)
	_lblBannerCoDTitulo.BackgroundTransparency = 1
	_lblBannerCoDTitulo.Font = Enum.Font.Oswald
	_lblBannerCoDTitulo.Text = "RONDA 1"
	_lblBannerCoDTitulo.TextColor3 = Color3.fromRGB(220, 45, 52)
	_lblBannerCoDTitulo.TextSize = 30
	_lblBannerCoDTitulo.Parent = _bannerCoD

	_lblBannerCoDSub = Instance.new("TextLabel")
	_lblBannerCoDSub.Position = UDim2.fromOffset(12, 44)
	_lblBannerCoDSub.Size = UDim2.new(1, -24, 0, 22)
	_lblBannerCoDSub.BackgroundTransparency = 1
	_lblBannerCoDSub.Font = Enum.Font.GothamBold
	_lblBannerCoDSub.Text = "Sobrevive a los infectados"
	_lblBannerCoDSub.TextColor3 = Color3.fromRGB(230, 226, 220)
	_lblBannerCoDSub.TextSize = 13
	_lblBannerCoDSub.Parent = _bannerCoD

	-- 7. Tarjeta Game Over CoD
	_tarjetaResumen = Instance.new("Frame")
	_tarjetaResumen.Name = "TarjetaGameOver"
	_tarjetaResumen.AnchorPoint = Vector2.new(0.5, 0.5)
	_tarjetaResumen.Position = UDim2.fromScale(0.5, 0.45)
	_tarjetaResumen.Size = UDim2.fromOffset(470, 190)
	_tarjetaResumen.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
	_tarjetaResumen.BackgroundTransparency = 0.1
	_tarjetaResumen.Visible = false
	_tarjetaResumen.ZIndex = 22
	_tarjetaResumen.Parent = _codGui

	local cRes = Instance.new("UICorner")
	cRes.CornerRadius = UDim.new(0, 6)
	cRes.Parent = _tarjetaResumen

	local sRes = Instance.new("UIStroke")
	sRes.Color = Color3.fromRGB(195, 32, 38)
	sRes.Thickness = 2
	sRes.Parent = _tarjetaResumen

	_lblResumenTitulo = Instance.new("TextLabel")
	_lblResumenTitulo.Position = UDim2.fromOffset(16, 16)
	_lblResumenTitulo.Size = UDim2.new(1, -32, 0, 38)
	_lblResumenTitulo.BackgroundTransparency = 1
	_lblResumenTitulo.Font = Enum.Font.Oswald
	_lblResumenTitulo.Text = "SOBREVIVISTE 0 RONDAS"
	_lblResumenTitulo.TextColor3 = Color3.fromRGB(220, 40, 48)
	_lblResumenTitulo.TextSize = 32
	_lblResumenTitulo.ZIndex = 23
	_lblResumenTitulo.Parent = _tarjetaResumen

	_lblResumenSub = Instance.new("TextLabel")
	_lblResumenSub.Position = UDim2.fromOffset(16, 56)
	_lblResumenSub.Size = UDim2.new(1, -32, 0, 22)
	_lblResumenSub.BackgroundTransparency = 1
	_lblResumenSub.Font = Enum.Font.GothamBold
	_lblResumenSub.Text = "Todos los supervivientes han caído"
	_lblResumenSub.TextColor3 = Color3.fromRGB(215, 210, 205)
	_lblResumenSub.TextSize = 13
	_lblResumenSub.ZIndex = 23
	_lblResumenSub.Parent = _tarjetaResumen

	_lblResumenStats = Instance.new("TextLabel")
	_lblResumenStats.Position = UDim2.fromOffset(16, 86)
	_lblResumenStats.Size = UDim2.new(1, -32, 0, 52)
	_lblResumenStats.BackgroundTransparency = 1
	_lblResumenStats.Font = Enum.Font.GothamBold
	_lblResumenStats.Text = ""
	_lblResumenStats.TextColor3 = Color3.fromRGB(255, 215, 75)
	_lblResumenStats.TextSize = 13
	_lblResumenStats.ZIndex = 23
	_lblResumenStats.Parent = _tarjetaResumen

	local btnCerrarRes = Instance.new("TextButton")
	btnCerrarRes.AnchorPoint = Vector2.new(0.5, 1)
	btnCerrarRes.Position = UDim2.new(0.5, 0, 1, -12)
	btnCerrarRes.Size = UDim2.fromOffset(130, 30)
	btnCerrarRes.BackgroundColor3 = Color3.fromRGB(165, 28, 34)
	btnCerrarRes.Font = Enum.Font.GothamBold
	btnCerrarRes.Text = "CERRAR"
	btnCerrarRes.TextColor3 = Color3.new(1, 1, 1)
	btnCerrarRes.TextSize = 12
	btnCerrarRes.ZIndex = 23
	btnCerrarRes.Parent = _tarjetaResumen

	local cBtnRes = Instance.new("UICorner")
	cBtnRes.CornerRadius = UDim.new(0, 4)
	cBtnRes.Parent = btnCerrarRes

	btnCerrarRes.MouseButton1Click:Connect(function()
		_tarjetaResumen.Visible = false
	end)
end

local function manejarActualizacionEstadoCoD(datosEstado: { [string]: any })
	local estado = tostring(datosEstado.Estado or "Inactiva")
	local oleada = tonumber(datosEstado.Oleada) or 0
	local restantes = tonumber(datosEstado.ZombisRestantes) or 0
	local total = tonumber(datosEstado.TotalOleada) or 0
	local mensaje = tostring(datosEstado.Mensaje or "")
	local tiempo = tonumber(datosEstado.TiempoRestante) or 0
	local rol = tostring(datosEstado.Rol or "Espectador")
	local vivos = tonumber(datosEstado.ParticipantesVivos) or 0
	local totalPart = tonumber(datosEstado.TotalParticipantes) or 0
	local esEspecial = datosEstado.EsRondaEspecial == true
	local esJefe = datosEstado.EsRondaJefe == true

	if estado == "Inactiva" or estado == "Finalizando" then
		_codRoot.Visible = false
		LocalPlayer:SetAttribute("HordaHUDActivo", nil)
		_codUltimaOleada = 0
		_codUltimoEstadoKey = ""
		_bajasLocales = 0
		actualizarMusicaTension(false)

		if estado == "Inactiva" and datosEstado.ResumenFinal then
			mostrarTarjetaResumen(datosEstado.ResumenFinal, mensaje)
		elseif estado == "Inactiva" and mensaje ~= "" then
			mostrarBannerCoD("OPERACIÓN FINALIZADA", mensaje, Color3.fromRGB(205, 55, 65), 4.0)
		end
		return
	end

	_tarjetaResumen.Visible = false
	_codRoot.Visible = true
	LocalPlayer:SetAttribute("HordaHUDActivo", true)

	if rol == "Espectador" then
		actualizarMusicaTension(false)
		_lblTiraInfo.Text = string.format("ESPECTADOR  |  RONDA %d  |  SUPERVIVIENTES: %d/%d", math.max(1, oleada), vivos, totalPart)
		actualizarRondaVisual(oleada, esEspecial, esJefe, false)
		return
	elseif rol == "Eliminado" then
		actualizarMusicaTension(false)
		_lblTiraInfo.Text = string.format("ELIMINADO  |  ENEMIGOS: %d  |  SUPERVIVIENTES: %d/%d", restantes, vivos, totalPart)
		actualizarRondaVisual(oleada, esEspecial, esJefe, false)
		return
	end

	actualizarMusicaTension(true)
	actualizarPerksVisual()
	actualizarPuntuacionVisual()
	actualizarPowerUpsVisual()

	if estado == "Preparando" or estado == "CuentaRegresiva" then
		_lblTiraInfo.Text = string.format("INICIANDO EN %ds  |  SUPERVIVIENTES: %d", tiempo, vivos)
		actualizarRondaVisual(0, false, false, true)
		if estado == "CuentaRegresiva" and _codUltimoEstadoKey ~= "CuentaRegresiva" then
			_codUltimoEstadoKey = "CuentaRegresiva"
			reproducirSonidoCoD(ConfigZombis.Sonidos.InicioOleada, 0.7, 0.85)
			mostrarBannerCoD(
				"LA HORDA SE ACERCA",
				string.format("Prepárate para resistir — Ronda 1 en %ds", tiempo),
				Color3.fromRGB(245, 165, 55),
				3.4
			)
		elseif estado == "CuentaRegresiva" then
			reproducirSonidoCoD(ConfigZombis.Sonidos.AlertaUI, 0.28, 0.9)
		end
	elseif estado == "EnCurso" then
		_lblTiraInfo.Text = string.format("ENEMIGOS RESTANTES: %d / %d  |  SUPERVIVIENTES: %d/%d", restantes, total, vivos, totalPart)
		actualizarRondaVisual(oleada, esEspecial, esJefe, false)

		if _codUltimaOleada ~= oleada then
			_codUltimaOleada = oleada
			_codUltimoEstadoKey = "Oleada_" .. tostring(oleada)
			animarCambioRonda(oleada)
			reproducirSonidoCoD(ConfigZombis.Sonidos.InicioOleada, 0.78, 0.78)

			local mensajeArmas = tostring(datosEstado.MensajeArmas or "")
			local tituloBanner = if esEspecial
				then string.format("RONDA %d — SABUESOS INFERNALES", oleada)
				elseif esJefe then string.format("RONDA %d — ¡JEFE BLINDADO!", oleada)
				else string.format("RONDA %d", oleada)

			local subBanner = if mensajeArmas ~= ""
				then mensajeArmas
				elseif esEspecial then "Niebla espesa detectada — Elimina a los cazadores para Munición Máxima"
				elseif esJefe then "¡Titán Blindado entrando al sector! Apunta a la cabeza"
				else string.format("%d infectados detectados en el perímetro", total)

			local colBanner = if esEspecial
				then Color3.fromRGB(255, 140, 45)
				elseif esJefe then Color3.fromRGB(255, 55, 65)
				else Color3.fromRGB(215, 42, 48)

			mostrarBannerCoD(tituloBanner, subBanner, colBanner, 3.8)
		end
	elseif estado == "OleadaCompletada" then
		_lblTiraInfo.Text = string.format("RONDA %d COMPLETADA  |  SIGUIENTE EN %ds", oleada, tiempo)
		actualizarRondaVisual(oleada, esEspecial, esJefe, false)
		if _codUltimoEstadoKey ~= ("Completada_" .. tostring(oleada)) then
			_codUltimoEstadoKey = "Completada_" .. tostring(oleada)
			reproducirSonidoCoD(ConfigZombis.Sonidos.AlertaUI, 0.65, 0.9)
			mostrarBannerCoD(
				string.format("RONDA %d COMPLETADA", oleada),
				"Todos los infectados han sido neutralizados",
				Color3.fromRGB(110, 225, 140),
				3.2
			)
		end
	end
end

function HordeUI.Iniciar()
	construirInterfazCoD()

	for _, cfg in ipairs(PERKS_COD) do
		LocalPlayer:GetAttributeChangedSignal(cfg.Atributo):Connect(actualizarPerksVisual)
	end
	LocalPlayer:GetAttributeChangedSignal("PuntosLazarusAcumulados"):Connect(actualizarPuntuacionVisual)
	LocalPlayer:GetAttributeChangedSignal("HordaCriticos"):Connect(actualizarPuntuacionVisual)

	Workspace:GetAttributeChangedSignal("LazarusPuntosDobles"):Connect(actualizarPowerUpsVisual)
	Workspace:GetAttributeChangedSignal("LazarusPuntosDoblesSegundos"):Connect(actualizarPowerUpsVisual)
	Workspace:GetAttributeChangedSignal("LazarusInstaKill"):Connect(actualizarPowerUpsVisual)
	Workspace:GetAttributeChangedSignal("LazarusInstaKillSegundos"):Connect(actualizarPowerUpsVisual)

	RunService.Heartbeat:Connect(function()
		if not _codRoot.Visible then
			return
		end
		local abatido = LocalPlayer:GetAttribute("HordaAbatido") == true
		_barraAbatido.Visible = abatido
		if abatido then
			local fin = tonumber(LocalPlayer:GetAttribute("HordaAbatidoFin")) or os.clock()
			local seg = math.max(0, math.ceil(fin - os.clock()))
			_lblAbatido.Text = string.format("ABATIDO — DESANGRÁNDOSE EN %ds (ESPERA A UN ALIADO)", seg)
		end
	end)

	local evVisual = EventosRemotos.ZombieEventoVisual
	if evVisual and evVisual:IsA("RemoteEvent") then
		evVisual.OnClientEvent:Connect(function(ev: any)
			if typeof(ev) ~= "table" then
				return
			end
			if ev.Tipo == "Impacto" then
				lanzarPopupPuntos(tonumber(ev.Puntos) or 10, ev.EsCritico == true)
				actualizarPuntuacionVisual()
			elseif ev.Tipo == "Muerte" then
				_bajasLocales += 1
				lanzarPopupPuntos(tonumber(ev.Puntos) or 60, ev.EsCritico == true)
				actualizarPuntuacionVisual()
			elseif ev.Tipo == "PowerUp" then
				local pId = tostring(ev.PowerUpId or "")
				local col = if pId == "INSTA_KILL"
					then Color3.fromRGB(255, 65, 85)
					elseif pId == "KABOOM" then Color3.fromRGB(255, 185, 55)
					elseif pId == "MUNICION_MAXIMA" then Color3.fromRGB(95, 240, 145)
					else Color3.fromRGB(255, 225, 65)
				mostrarBannerCoD(tostring(ev.Nombre or pId), "Activado por " .. tostring(ev.Jugador or "Equipo"), col, 2.8)
			end
		end)
	end

	local evEstado = EventosRemotos.EstadoHordaActualizado
	if not evEstado then
		local f = ReplicatedStorage:WaitForChild("EventosRemotos", 10)
		evEstado = f and f:WaitForChild("EstadoHordaActualizado", 10) :: RemoteEvent?
	end
	if evEstado and evEstado:IsA("RemoteEvent") then
		evEstado.OnClientEvent:Connect(manejarActualizacionEstadoCoD)
	else
		warn("[HordeUI] No se pudo conectar EstadoHordaActualizado RemoteEvent")
	end

	task.spawn(function()
		local fnEstado = EventosRemotos.ObtenerEstadoHorda
		if fnEstado and fnEstado:IsA("RemoteFunction") then
			local ok, payload = pcall(function()
				return fnEstado:InvokeServer()
			end)
			if ok and typeof(payload) == "table" then
				manejarActualizacionEstadoCoD(payload)
			end
		end
	end)
end

return HordeUI
