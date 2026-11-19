--!strict
--[[
	Zombis.luau
	Configuración centralizada del Sistema de Horda de Zombis y NPC Dante
	para El Patrón del Dulce.
]]

export type ConfigOleada = {
	Cantidad: number,
	VelocidadBase: number,
	VidaBase: number,
	DanioBase: number,
	CooldownAtaque: number,
	EtiquetaVelocidad: string,
}

export type VarianteZombi = {
	Id: string,
	Nombre: string,
	MultiplicadorVida: number,
	MultiplicadorVelocidad: number,
	MultiplicadorDanio: number,
	Escala: number,
	ColorPiel: Color3,
	ColorRopa: Color3,
	ColorPantalon: Color3,
	ColorOjos: Color3,
	TieneCristalesDulces: boolean,
	EsDeFuego: boolean?,
	TexturaLava: string?,
	TexturaCara: string?,
	OleadaMinima: number,
	PesoAparicion: number,
	RecompensaPesos: number,
}

local Zombis = {
	General = {
		MaxZombisSimultaneos = 14,
		IntervaloSpawnSegundos = 0.75,
		CuentaRegresivaInicial = 5,
		TiempoEntreOleadas = 6,
		DistanciaMinSpawnJugador = 22,
		DistanciaMaxSpawnJugador = 95,
		RadioDeteccionStuds = 160,
		RangoAtaqueStuds = 4.6,
		RangoImpactoMaximoStuds = 6.2,
		VentanaImpactoSegundos = 0.28,
		DuracionAturdimientoGolpe = 0.25,
		TiempoDespawnMuerto = 2.5,
		MunicionMinimaAlIniciar = 15,
		MunicionDropPorMuerte = 2,
		MultiplicadorHordaEnCurso = true,
		TexturaCara = "rbxassetid://1102142750", -- Archivo 2D Very Scary Face
	},

	Dante = {
		Nombre = "Dante",
		Titulo = "Vigía de las Sombras",
		DistanciaInteraccion = 10,
		DistanciaMaxRotulo = 35,
		RequiereLineaVision = false,
		DuracionHoldPrompt = 0.2,
		DistanciaMaxConfirmacion = 16,
		Dialogos = {
			"Pensé que nunca llegarías. Tenemos un problema... algo está saliendo de las sombras.",
			"Están llegando. Y créeme, no quieres quedarte aquí cuando aparezcan.",
			"Si quieres sobrevivir, tendrás que aprender a moverte rápido.",
		},
		DialogoInicio = "¡Prepárate! La primera oleada está comenzando. No dejes que te rodeen.",
	},

	-- Tabla de progresión oficial para oleadas 1 a 5 (oleadas 6+ usan fórmula progresiva)
	OleadasPredefinidas = {
		[1] = {
			Cantidad = 5,
			VelocidadBase = 10.0,
			VidaBase = 100,
			DanioBase = 12,
			CooldownAtaque = 1.4,
			EtiquetaVelocidad = "Lenta",
		},
		[2] = {
			Cantidad = 8,
			VelocidadBase = 11.5,
			VidaBase = 125,
			DanioBase = 15,
			CooldownAtaque = 1.3,
			EtiquetaVelocidad = "Lenta",
		},
		[3] = {
			Cantidad = 12,
			VelocidadBase = 14.0,
			VidaBase = 155,
			DanioBase = 18,
			CooldownAtaque = 1.2,
			EtiquetaVelocidad = "Normal",
		},
		[4] = {
			Cantidad = 16,
			VelocidadBase = 15.8,
			VidaBase = 190,
			DanioBase = 22,
			CooldownAtaque = 1.1,
			EtiquetaVelocidad = "Normal",
		},
		[5] = {
			Cantidad = 20,
			VelocidadBase = 18.2,
			VidaBase = 230,
			DanioBase = 26,
			CooldownAtaque = 1.0,
			EtiquetaVelocidad = "Rápida",
		},
	} :: { [number]: ConfigOleada },

	-- Daño de las dulce-armas existentes contra zombis
	DanioPorArma = {
		Arma_CaucheraGomitas = 35,
		Arma_PistolaCrema = 55,
		Arma_EscopetaChicle = 85,
		Arma_MinaCaramelo = 120,
		Arma_GranadaGaseosa = 110,
		Arma_BazucaAlgodon = 140,
		Arma_DinamitaPinata = 220,
		Arma_CanonChiva = 260,
	} :: { [string]: number },

	-- Variantes visuales y jugables de zombis
	Variantes = {
		{
			Id = "CaminantePodrido",
			Nombre = "Zombi Podrido",
			MultiplicadorVida = 1.0,
			MultiplicadorVelocidad = 1.0,
			MultiplicadorDanio = 1.0,
			Escala = 1.0,
			ColorPiel = Color3.fromRGB(115, 138, 102),
			ColorRopa = Color3.fromRGB(58, 62, 54),
			ColorPantalon = Color3.fromRGB(40, 38, 36),
			ColorOjos = Color3.fromRGB(255, 70, 50),
			TieneCristalesDulces = false,
			OleadaMinima = 1,
			PesoAparicion = 60,
			RecompensaPesos = 10,
		},
		{
			Id = "AzucaradoToxico",
			Nombre = "Azucarado Tóxico",
			MultiplicadorVida = 0.9,
			MultiplicadorVelocidad = 1.12,
			MultiplicadorDanio = 1.05,
			Escala = 0.98,
			ColorPiel = Color3.fromRGB(142, 160, 152),
			ColorRopa = Color3.fromRGB(68, 45, 78),
			ColorPantalon = Color3.fromRGB(35, 30, 42),
			ColorOjos = Color3.fromRGB(140, 255, 90),
			TieneCristalesDulces = true,
			OleadaMinima = 1,
			PesoAparicion = 25,
			RecompensaPesos = 14,
		},
		{
			Id = "CorredorRabioso",
			Nombre = "Corredor Rabioso",
			MultiplicadorVida = 0.8,
			MultiplicadorVelocidad = 1.28,
			MultiplicadorDanio = 1.15,
			Escala = 0.95,
			ColorPiel = Color3.fromRGB(136, 102, 98),
			ColorRopa = Color3.fromRGB(110, 38, 38),
			ColorPantalon = Color3.fromRGB(32, 28, 28),
			ColorOjos = Color3.fromRGB(255, 210, 40),
			TieneCristalesDulces = false,
			OleadaMinima = 2,
			PesoAparicion = 20,
			RecompensaPesos = 16,
		},
		{
			Id = "BrutoCaramelo",
			Nombre = "Bruto Caramelo",
			MultiplicadorVida = 2.1,
			MultiplicadorVelocidad = 0.82,
			MultiplicadorDanio = 1.45,
			Escala = 1.24,
			ColorPiel = Color3.fromRGB(88, 102, 86),
			ColorRopa = Color3.fromRGB(45, 35, 30),
			ColorPantalon = Color3.fromRGB(26, 24, 24),
			ColorOjos = Color3.fromRGB(255, 40, 40),
			TieneCristalesDulces = true,
			OleadaMinima = 3,
			PesoAparicion = 12,
			RecompensaPesos = 25,
		},
		{
			Id = "ZombiLava",
			Nombre = "Zombi de Lava",
			MultiplicadorVida = 1.40,
			MultiplicadorVelocidad = 1.15,
			MultiplicadorDanio = 1.35,
			Escala = 1.05,
			ColorPiel = Color3.fromRGB(25, 25, 25),
			ColorRopa = Color3.fromRGB(18, 18, 18),
			ColorPantalon = Color3.fromRGB(18, 18, 18),
			ColorOjos = Color3.fromRGB(255, 120, 20),
			TieneCristalesDulces = false,
			EsDeFuego = true,
			TexturaLava = "rbxassetid://102118326",
			OleadaMinima = 3,
			PesoAparicion = 35,
			RecompensaPesos = 24,
		},
	} :: { VarianteZombi },

	-- Puntos de aparición de respaldo alrededor de Villa Almíbar / Colegio si no hay carpeta Puntos.Zombis
	PuntosAparicionRespaldo = {
		Vector3.new(62, 63, -145),
		Vector3.new(132, 63, -140),
		Vector3.new(135, 63, -90),
		Vector3.new(60, 63, -88),
		Vector3.new(98, 63, -72),
		Vector3.new(40, 63, -115),
		Vector3.new(-65, 63, -70),
		Vector3.new(-115, 63, -65),
	},

	--[[
		Slots de AnimationId para Roblox Animator.
		IMPORTANTE: Se dejan vacíos ("") para no inventar IDs externos no verificados.
		Mientras estén vacíos, ZombieAnimationController y DanteController usan
		animación procedural mediante Motor6D.Transform.
		Al colocar un "rbxassetid://TU_ID" válido aquí, Animator lo reproducirá automáticamente.
	]]
	Animaciones = {
		Dante = {
			Idle = "",
			Talk = "",
		},
		Zombi = {
			Idle = "",
			Walk = "",
			Run = "",
			Attack = "",
			Hit = "",
			Death = "",
		},
	},

	--[[
		Recursos de sonido:
		- Los campos con valor usan sonidos ya verificados en el proyecto/cliente Roblox.
		- Los campos vacíos ("") están listos para conectar tus SoundIds propios de Creator Store.
	]]
	Sonidos = {
		Golpe = "rbxasset://sounds/uuhhh.mp3",
		AlertaUI = "rbxasset://sounds/electronicpingshort.wav",
		InicioOleada = "rbxasset://sounds/electronicpingshort.wav",
		GrunidoZombi = "",
		AtaqueZombi = "",
		MuerteZombi = "rbxasset://sounds/uuhhh.mp3",
		MusicaTension = "",
	},
}

function Zombis.ObtenerConfigOleada(numeroOleada: number): ConfigOleada
	local predefinida = Zombis.OleadasPredefinidas[numeroOleada]
	if predefinida then
		return predefinida
	end

	local extra = math.max(0, numeroOleada - 5)
	return {
		Cantidad = 20 + extra * 5,
		VelocidadBase = math.min(23.5, 18.2 + extra * 0.6),
		VidaBase = 230 + extra * 45,
		DanioBase = math.min(48, 26 + extra * 3),
		CooldownAtaque = math.max(0.80, 1.0 - extra * 0.03),
		EtiquetaVelocidad = "Infinita",
	}
end

return Zombis
