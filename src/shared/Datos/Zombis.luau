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
	EfectoEspecial: EfectoEspecialZombi?,
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
		MaxReintentosSpawn = 12,
		DistanciaMinSpawnJugador = 22,
		DistanciaMaxSpawnJugador = 95,
		DistanciaMinEntreZombis = 5.5,
		RadioDeteccionStuds = 160,
		RangoAtaqueStuds = 4.6,
		RangoImpactoMaximoStuds = 6.2,
		VentanaImpactoSegundos = 0.28,
		CooldownDanioJugadorSegundos = 0.55,
		DuracionAturdimientoGolpe = 0.25,
		TiempoDespawnMuerto = 2.5,
		MunicionMinimaAlIniciar = 25,
		MunicionDropPorMuerte = 3,
		MunicionPorOleadaCompletada = 8,
		BonoOleadaBasePesos = 30,
		BonoOleadaExtraPesos = 15,
		BonoOleadaFama = 2,
		BonoSupervivenciaPesosPorOleada = 15,
		BonoSupervivenciaFamaPorOleada = 1,
		MaxLucesDinamicasZombis = 6,
		DistanciaCullingAnimacion = 140,
		NombreCollisionGroupZombis = "ZombisHorda",
		TexturaCara = "rbxassetid://1102142750", -- Archivo 2D Very Scary Face
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
			EfectoEspecial = {
				Tipo = "Veneno",
				Duracion = 2.0,
				DanioPorTick = 2,
				IntervaloTick = 1.0,
			},
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
			MultiplicadorCooldownAtaque = 0.78,
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
			MultiplicadorCooldownAtaque = 1.25,
			ResistenciaAturdimiento = 0.75,
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
			ResistenciaAturdimiento = 0.25,
			Escala = 1.05,
			ColorPiel = Color3.fromRGB(25, 25, 25),
			ColorRopa = Color3.fromRGB(18, 18, 18),
			ColorPantalon = Color3.fromRGB(18, 18, 18),
			ColorOjos = Color3.fromRGB(255, 120, 20),
			TieneCristalesDulces = false,
			EsDeFuego = true,
			EfectoEspecial = {
				Tipo = "Quemadura",
				Duracion = 2.4,
				DanioPorTick = 3,
				IntervaloTick = 0.8,
			},
			TexturaLava = "rbxassetid://102118326",
			OleadaMinima = 3,
			PesoAparicion = 35,
			RecompensaPesos = 24,
		},
		{
			Id = "ZombiHielo",
			Nombre = "Ice Zombie",
			MultiplicadorVida = 1.65,
			MultiplicadorVelocidad = 1.18,
			MultiplicadorDanio = 1.40,
			ResistenciaAturdimiento = 0.30,
			Escala = 1.08,
			ColorPiel = Color3.fromRGB(0, 255, 255),
			ColorRopa = Color3.fromRGB(0, 210, 235),
			ColorPantalon = Color3.fromRGB(0, 175, 215),
			ColorOjos = Color3.fromRGB(85, 255, 255),
			TieneCristalesDulces = false,
			EsDeHielo = true,
			EfectoEspecial = {
				Tipo = "Congelamiento",
				Duracion = 2.0,
				FactorVelocidad = 0.72,
			},
			TexturaCara = "rbxassetid://174393211",
			OleadaMinima = 6,
			PesoAparicion = 30,
			RecompensaPesos = 32,
		},
		{
			Id = "ZombiToxico",
			Nombre = "Toxic Zombie",
			MultiplicadorVida = 2.40,
			MultiplicadorVelocidad = 0.95,
			MultiplicadorDanio = 1.55,
			ResistenciaAturdimiento = 0.40,
			Escala = 1.15,
			ColorPiel = Color3.fromRGB(44, 101, 29),
			ColorRopa = Color3.fromRGB(34, 78, 22),
			ColorPantalon = Color3.fromRGB(28, 60, 18),
			ColorOjos = Color3.fromRGB(113, 255, 61),
			TieneCristalesDulces = false,
			EsToxico = true,
			EfectoEspecial = {
				Tipo = "Veneno",
				Duracion = 3.0,
				DanioPorTick = 4,
				IntervaloTick = 1.0,
			},
			TexturaCara = "rbxassetid://174330148",
			OleadaMinima = 10,
			PesoAparicion = 28,
			RecompensaPesos = 45,
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
