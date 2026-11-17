export type PerfilJugador = {
	PesosDulces: number,
	Fama: number,
	AzucarDorada: number,
	Inventario: { [string]: number },
	RecetasDesbloqueadas: { [string]: boolean },
	MejorasCompradas: { [string]: boolean },
	VehiculosComprados: { [string]: boolean },
	CapituloActual: number,
	VehiculoEquipado: string,
	EstrellasBusqueda: number,
	PuntosCalor: number,
	CondenaInternado: number,
}

local PlantillaPerfil: PerfilJugador = {
	PesosDulces = 0,
	Fama = 0,
	AzucarDorada = 0,
	Inventario = {},
	RecetasDesbloqueadas = {
		["Dulce_Bombon"] = true,
	},
	MejorasCompradas = {},
	VehiculosComprados = {
		["Vehiculo_Bicicleta"] = true,
	},
	CapituloActual = 1,
	VehiculoEquipado = "Vehiculo_Bicicleta",
	EstrellasBusqueda = 0,
	PuntosCalor = 0,
	CondenaInternado = 0,
}

return PlantillaPerfil
