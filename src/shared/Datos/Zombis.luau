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

export type EfectoEspecialZombi = {
	Tipo: "Quemadura" | "Congelamiento" | "Veneno",
	Duracion: number,
	DanioPorTick: number?,
	IntervaloTick: number?,
	FactorVelocidad: number?,
}

export type VarianteZombi = {
	Id: string,
	Nombre: string,
	MultiplicadorVida: number,
	MultiplicadorVelocidad: number,
	MultiplicadorDanio: number,
	MultiplicadorCooldownAtaque: number?,
	ResistenciaAturdimiento: number?,
	Escala: number,
	ColorPiel: Color3,
	ColorRopa: Color3,
	ColorPantalon: Color3,
	ColorOjos: Color3,
	TieneCristalesDulces: boolean,
	EsDeFuego: boolean?,
	EsDeHielo: boolean?,
	EsToxico: boolean?,
	EsJefe: boolean?,
	EsEspecialRonda: boolean?,
	EfectoEspecial: EfectoEspecialZombi?,
	TexturaLava: string?,
	TexturaCara: string?,
	OleadaMinima: number,
	PesoAparicion: number,
	RecompensaPesos: number,
}

local Zombis = {
	General = {
		MaxZombisSimultaneos = 16,
		IntervaloSpawnSegundos = 0.65,
		CuentaRegresivaInicial = 5,
		TiempoEntreOleadas = 6,
		MaxReintentosSpawn = 12,
		DistanciaMinSpawnJugador = 22,
		DistanciaMaxSpawnJugador = 95,
		DistanciaMinEntreZombis = 5.5,
		RadioDeteccionStuds = 160,
		RangoAtaqueStuds = 4.6,
		RangoImpactoMaximoStuds = 6.2,
		VentanaImpactoSegundos = 0.28,
		CooldownDanioJugadorSegundos = 0.55,
		DuracionAturdimientoGolpe = 0.22,
		TiempoDespawnMuerto = 2.5,
		MunicionMinimaAlIniciar = 25,
		MunicionDropPorMuerte = 3,
		MunicionPorOleadaCompletada = 8,
		BonoOleadaBasePesos = 40,
		BonoOleadaExtraPesos = 20,
		BonoOleadaFama = 2,
		BonoSupervivenciaPesosPorOleada = 20,
		BonoSupervivenciaFamaPorOleada = 1,
		PuntosPorImpacto = 10,
		PuntosPorBaja = 60,
		PuntosPorHeadshot = 100,
		PuntosPorRevivir = 200,
		DuracionAbatidoSegundos = 30,
		TiempoRevivirSegundos = 3.0,
		IntervaloRondaEspecial = 5,
		OleadaMinimaJefe = 8,
		IntervaloJefe = 4,
		MaxLucesDinamicasZombis = 8,
		DistanciaCullingAnimacion = 150,
		NombreCollisionGroupZombis = "ZombisHorda",
		TexturaCara = "", -- Rostros oscuros realistas estilo CoD con ojos brillantes
	},

	-- Arsenal progresivo entregado a los participantes vivos según la ronda
	ArmasPorOleada = {
		[1] = {
			Armas = { "Uzi", "Hand axes" },
			Mensaje = "¡Arsenal inicial entregado: Uzi y Hand axes!",
		},
		[3] = {
			Armas = { "Taper 21", "Kinetic" },
			Mensaje = "¡Arsenal mejorado: Taper 21 y Kinetic desbloqueados!",
		},
		[5] = {
			Armas = { "DMR", "Rhino spear" },
			Mensaje = "¡Armamento pesado: DMR y Rhino spear desbloqueados!",
		},
		[7] = {
			Armas = { "Burtan AntiMaterialRifle" },
			Mensaje = "¡Rifle Antimateria Burtan desbloqueado!",
		},
		[10] = {
			Armas = { "Railgun" },
			Mensaje = "¡ARMA DEFINITIVA DESBLOQUEADA: Railgun!",
		},
	} :: { [number]: { Armas: { string }, Mensaje: string } },

	NombresArmasHorda = {
		"Uzi",
		"Hand axes",
		"Taper 21",
		"Kinetic",
		"DMR",
		"Rhino spear",
		"Burtan AntiMaterialRifle",
		"Railgun",
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
			"Si aceptas iniciar la horda, todos los jugadores vivos del servidor entrarán al combate cooperativo.",
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
		Arma_CaucheraGomitas = 40,
		Arma_PistolaCrema = 65,
		Arma_EscopetaChicle = 95,
		Arma_MinaCaramelo = 135,
		Arma_GranadaGaseosa = 125,
		Arma_BazucaAlgodon = 160,
		Arma_DinamitaPinata = 240,
		Arma_CanonChiva = 280,
	} :: { [string]: number },

	-- Variantes visuales y jugables estilo Call of Duty Zombies
	Variantes = {
		{
			Id = "CaminantePodrido",
			Nombre = "Caminante Infectado",
			MultiplicadorVida = 1.0,
			MultiplicadorVelocidad = 1.0,
			MultiplicadorDanio = 1.0,
			Escala = 1.0,
			ColorPiel = Color3.fromRGB(98, 108, 90),
			ColorRopa = Color3.fromRGB(46, 48, 42),
			ColorPantalon = Color3.fromRGB(30, 30, 32),
			ColorOjos = Color3.fromRGB(255, 190, 40),
			TieneCristalesDulces = false,
			OleadaMinima = 1,
			PesoAparicion = 60,
			RecompensaPesos = 60,
		},
		{
			Id = "AzucaradoToxico",
			Nombre = "Infectado Químico",
			MultiplicadorVida = 0.95,
			MultiplicadorVelocidad = 1.12,
			MultiplicadorDanio = 1.05,
			Escala = 0.98,
			ColorPiel = Color3.fromRGB(110, 128, 112),
			ColorRopa = Color3.fromRGB(48, 52, 44),
			ColorPantalon = Color3.fromRGB(28, 30, 28),
			ColorOjos = Color3.fromRGB(130, 255, 95),
			TieneCristalesDulces = false,
			EfectoEspecial = {
				Tipo = "Veneno",
				Duracion = 2.0,
				DanioPorTick = 2,
				IntervaloTick = 1.0,
			},
			OleadaMinima = 2,
			PesoAparicion = 20,
			RecompensaPesos = 70,
		},
		{
			Id = "CorredorRabioso",
			Nombre = "Corredor Frenético",
			MultiplicadorVida = 0.85,
			MultiplicadorVelocidad = 1.32,
			MultiplicadorDanio = 1.15,
			MultiplicadorCooldownAtaque = 0.75,
			Escala = 0.96,
			ColorPiel = Color3.fromRGB(115, 86, 82),
			ColorRopa = Color3.fromRGB(78, 28, 28),
			ColorPantalon = Color3.fromRGB(26, 24, 24),
			ColorOjos = Color3.fromRGB(255, 175, 30),
			TieneCristalesDulces = false,
			OleadaMinima = 2,
			PesoAparicion = 28,
			RecompensaPesos = 75,
		},
		{
			Id = "BrutoCaramelo",
			Nombre = "Titán Blindado",
			MultiplicadorVida = 4.2,
			MultiplicadorVelocidad = 0.84,
			MultiplicadorDanio = 1.7,
			MultiplicadorCooldownAtaque = 1.2,
			ResistenciaAturdimiento = 0.85,
			Escala = 1.36,
			ColorPiel = Color3.fromRGB(72, 78, 72),
			ColorRopa = Color3.fromRGB(34, 36, 40),
			ColorPantalon = Color3.fromRGB(22, 24, 28),
			ColorOjos = Color3.fromRGB(255, 35, 35),
			TieneCristalesDulces = false,
			EsJefe = true,
			OleadaMinima = 8,
			PesoAparicion = 8,
			RecompensaPesos = 250,
		},
		{
			Id = "ZombiLava",
			Nombre = "Sabueso Infernal",
			MultiplicadorVida = 0.75,
			MultiplicadorVelocidad = 1.42,
			MultiplicadorDanio = 1.15,
			MultiplicadorCooldownAtaque = 0.78,
			ResistenciaAturdimiento = 0.25,
			Escala = 0.98,
			ColorPiel = Color3.fromRGB(32, 26, 26),
			ColorRopa = Color3.fromRGB(22, 18, 18),
			ColorPantalon = Color3.fromRGB(18, 16, 16),
			ColorOjos = Color3.fromRGB(255, 110, 20),
			TieneCristalesDulces = false,
			EsDeFuego = true,
			EsEspecialRonda = true,
			EfectoEspecial = {
				Tipo = "Quemadura",
				Duracion = 2.4,
				DanioPorTick = 3,
				IntervaloTick = 0.8,
			},
			OleadaMinima = 5,
			PesoAparicion = 18,
			RecompensaPesos = 90,
		},
		{
			Id = "ZombiHielo",
			Nombre = "Espectro Criogénico",
			MultiplicadorVida = 1.6,
			MultiplicadorVelocidad = 1.15,
			MultiplicadorDanio = 1.35,
			ResistenciaAturdimiento = 0.30,
			Escala = 1.06,
			ColorPiel = Color3.fromRGB(145, 170, 185),
			ColorRopa = Color3.fromRGB(32, 42, 54),
			ColorPantalon = Color3.fromRGB(24, 30, 38),
			ColorOjos = Color3.fromRGB(110, 230, 255),
			TieneCristalesDulces = false,
			EsDeHielo = true,
			EfectoEspecial = {
				Tipo = "Congelamiento",
				Duracion = 2.0,
				FactorVelocidad = 0.72,
			},
			TexturaCara = "",
			OleadaMinima = 6,
			PesoAparicion = 20,
			RecompensaPesos = 95,
		},
		{
			Id = "ZombiToxico",
			Nombre = "Coloso Radiactivo",
			MultiplicadorVida = 2.4,
			MultiplicadorVelocidad = 0.95,
			MultiplicadorDanio = 1.55,
			ResistenciaAturdimiento = 0.45,
			Escala = 1.18,
			ColorPiel = Color3.fromRGB(72, 92, 66),
			ColorRopa = Color3.fromRGB(36, 42, 34),
			ColorPantalon = Color3.fromRGB(24, 28, 22),
			ColorOjos = Color3.fromRGB(130, 255, 80),
			TieneCristalesDulces = false,
			EsToxico = true,
			EfectoEspecial = {
				Tipo = "Veneno",
				Duracion = 3.0,
				DanioPorTick = 4,
				IntervaloTick = 1.0,
			},
			TexturaCara = "",
			OleadaMinima = 10,
			PesoAparicion = 16,
			RecompensaPesos = 130,
		},
	} :: { VarianteZombi },

	-- Puntos exteriores despejados verificados si no existe carpeta Workspace.Puntos.Zombis
	PuntosAparicionRespaldo = {
		Vector3.new(62, 60, -145),
		Vector3.new(132, 60, -140),
		Vector3.new(60, 62, -88),
		Vector3.new(40, 60, -115),
		Vector3.new(-65, 62, -70),
		Vector3.new(-115, 62, -65),
		Vector3.new(35, 62, -20),
		Vector3.new(120, 62, -20),
		Vector3.new(-20, 62, -45),
		Vector3.new(150, 62, -60),
	},

	--[[
		Slots de AnimationId para Roblox Animator (rigs R6).
		IMPORTANTE: Se dejan vacíos ("") para no inventar IDs externos no verificados.
		Los AnimationIds R15 existentes en modelos de muestra de ServerStorage no son compatibles con rigs R6.
		Mientras estén vacíos, ZombieAnimationController y DanteController usan
		animación procedural mediante Motor6D.Transform.
		Al colocar un "rbxassetid://TU_ID" válido para R6 aquí, Animator lo reproducirá automáticamente.
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
		Cantidad = math.min(60, 20 + extra * 5),
		VelocidadBase = math.min(22.5, 18.2 + extra * 0.5),
		VidaBase = 230 + extra * 38,
		DanioBase = math.min(42, 26 + extra * 2.5),
		CooldownAtaque = math.max(0.82, 1.0 - extra * 0.025),
		EtiquetaVelocidad = "Infinita",
	}
end

return Zombis

