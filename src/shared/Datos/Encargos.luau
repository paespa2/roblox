local Encargos = {
	Encargo_EntregaBombones = {
		Id = "Encargo_EntregaBombones",
		Texto = "Entrega 20 bombones en el colegio",
		Meta = 20,
		DulceRequerido = "Dulce_Bombon",
		PremioPesos = 30,
		PremioPase = 50,
	},
	Encargo_VentaGomitas = {
		Id = "Encargo_VentaGomitas",
		Texto = "Vende 15 gomitas en tiendas del barrio",
		Meta = 15,
		DulceRequerido = "Dulce_Gomita",
		PremioPesos = 45,
		PremioPase = 50,
	},
	Encargo_EscapadaDental = {
		Id = "Encargo_EscapadaDental",
		Texto = "Escapa de una patrulla dental con 1 estrella",
		Meta = 1,
		DulceRequerido = nil,
		PremioPesos = 50,
		PremioPase = 75,
	},
}

return Encargos
