local Tiendas = {
	Tienda_ColegioRecreo = {
		Id = "Tienda_ColegioRecreo",
		Nombre = "Colegio (Recreo)",
		Barrio = "El Recreo",
		DulcesComprados = { "Dulce_Bombon", "Dulce_Chicle" },
		Multiplicador = 1.0,
		DemandaMax = 50,
	},
	Tienda_EsquinaPaisa = {
		Id = "Tienda_EsquinaPaisa",
		Nombre = "Tienda La Esquina Paisa",
		Barrio = "La Cuadra",
		DulcesComprados = { "Dulce_Bombon", "Dulce_Gomita" },
		Multiplicador = 1.0,
		DemandaMax = 40,
	},
	Tienda_DonAbaco = {
		Id = "Tienda_DonAbaco",
		Nombre = "Abarrotes Don Ábaco",
		Barrio = "La Cuadra",
		DulcesComprados = { "Dulce_Chicle", "Dulce_Gomita" },
		Multiplicador = 1.1,
		DemandaMax = 60,
	},
	Tienda_LaLadera = {
		Id = "Tienda_LaLadera",
		Nombre = "Kiosko La Ladera",
		Barrio = "El Alto",
		DulcesComprados = { "Dulce_Bombon", "Dulce_Arequipe" },
		Multiplicador = 1.2,
		DemandaMax = 35,
	},
	Tienda_ParqueCentral = {
		Id = "Tienda_ParqueCentral",
		Nombre = "Dulcería Parque Central",
		Barrio = "Centro",
		DulcesComprados = { "Dulce_Arequipe", "Dulce_Panelita" },
		Multiplicador = 1.25,
		DemandaMax = 50,
	},
	Tienda_TerminalRuta = {
		Id = "Tienda_TerminalRuta",
		Nombre = "Parador de la Variante",
		Barrio = "La Variante",
		DulcesComprados = { "Dulce_Panelita", "Dulce_Bocadillo" },
		Multiplicador = 1.3,
		DemandaMax = 45,
	},
}

return Tiendas
