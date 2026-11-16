export type PerfilJugador = {
	PesosDulces: number,
	Fama: number,
	AzucarDorada: number,
	Inventario: { [string]: number },
	RecetasDesbloqueadas: { [string]: boolean },
	CapituloActual: number,
	VehiculoEquipado: string,
	EstrellasBusqueda: number,
}

local PlantillaPerfil: PerfilJugador = {
	PesosDulces = 0,
	Fama = 0,
	AzucarDorada = 0,
	Inventario = {},
	RecetasDesbloqueadas = {
		["Dulce_Bombon"] = true,
	},
	CapituloActual = 1,
	VehiculoEquipado = "Vehiculo_Bicicleta",
	EstrellasBusqueda = 0,
}

return PlantillaPerfil
