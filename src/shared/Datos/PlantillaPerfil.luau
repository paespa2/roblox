export type PerfilJugador = {
	PesosDulces: number,
	Fama: number,
	AzucarDorada: number,
	Inventario: { [string]: number },
	RecetasDesbloqueadas: { [string]: boolean },
	MejorasCompradas: { [string]: boolean },
	VehiculosComprados: { [string]: boolean },
	ArmasDesbloqueadas: { [string]: boolean },
	ArmaEquipada: string,
	CapituloActual: number,
	PasoTutorial: number,
	TutorialCompletado: boolean,
	VehiculoEquipado: string,
	EstrellasBusqueda: number,
	PuntosCalor: number,
	CondenaInternado: number,
	TiendasConquistadas: { [string]: boolean },
	IngresoPasivoAcumulado: number,
}

local PlantillaPerfil: PerfilJugador = {
	PesosDulces = 0,
	Fama = 0,
	AzucarDorada = 0,
	Inventario = {
		["Dulce_Bombon"] = 5,
		["Dulce_Gomita"] = 3,
	},
	RecetasDesbloqueadas = {
		["Dulce_Bombon"] = true,
	},
	MejorasCompradas = {},
	VehiculosComprados = {
		["Vehiculo_Bicicleta"] = true,
	},
	ArmasDesbloqueadas = {
		["Arma_CaucheraGomitas"] = true,
	},
	ArmaEquipada = "Arma_CaucheraGomitas",
	CapituloActual = 1,
	PasoTutorial = 0,
	TutorialCompletado = false,
	VehiculoEquipado = "Vehiculo_Bicicleta",
	EstrellasBusqueda = 0,
	PuntosCalor = 0,
	CondenaInternado = 0,
	TiendasConquistadas = {},
	IngresoPasivoAcumulado = 0,
}

return PlantillaPerfil
