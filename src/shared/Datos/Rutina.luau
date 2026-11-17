local Rutina = {
	Racha = {
		Dias = {
			[1] = { Tipo = "PesosDulces", Cantidad = 50, Nombre = "Bienvenida" },
			[2] = { Tipo = "Dulce_Gomita", Cantidad = 10, Nombre = "Golosinas de la Abuela" },
			[3] = { Tipo = "PesosDulces", Cantidad = 150, Nombre = "Ganancia de Cuadra" },
			[4] = { Tipo = "ComodinRacha", Cantidad = 1, Nombre = "Seguro Dental" },
			[5] = { Tipo = "PesosDulces", Cantidad = 300, Nombre = "Reinversión Clandestina" },
			[6] = { Tipo = "Dulce_Arequipe", Cantidad = 8, Nombre = "Dulce Especial" },
			[7] = { Tipo = "AzucarDorada", Cantidad = 25, PesosExtra = 500, Nombre = "Cofre del Patrón" },
		},
		ComodinId = "ComodinRacha",
	},
	EncargosPool = {
		Encargo_EntregaBombones = {
			Id = "Encargo_EntregaBombones",
			Emisor = "Doña Melcocha",
			Texto = "Entrega 20 bombones en el colegio",
			Meta = 20,
			DulceRequerido = "Dulce_Bombon",
			PremioPesos = 30,
			PremioPase = 50,
		},
		Encargo_VentaGomitas = {
			Id = "Encargo_VentaGomitas",
			Emisor = "Don Ábaco",
			Texto = "Vende 15 gomitas en tiendas del barrio",
			Meta = 15,
			DulceRequerido = "Dulce_Gomita",
			PremioPesos = 45,
			PremioPase = 50,
		},
		Encargo_EscapadaDental = {
			Id = "Encargo_EscapadaDental",
			Emisor = "Lola Paleta",
			Texto = "Escapa de una patrulla dental con 1 estrella",
			Meta = 1,
			DulceRequerido = nil,
			PremioPesos = 50,
			PremioPase = 75,
		},
		Encargo_RecetaCasera = {
			Id = "Encargo_RecetaCasera",
			Emisor = "Doña Melcocha",
			Texto = "Fabrica 5 dulces caseros en la paila",
			Meta = 5,
			DulceRequerido = "Dulce_Arequipe",
			PremioPesos = 60,
			PremioPase = 60,
		},
		Encargo_ClienteFiel = {
			Id = "Encargo_ClienteFiel",
			Emisor = "Don Ábaco",
			Texto = "Vende a 3 tiendas distintas en un viaje",
			Meta = 3,
			DulceRequerido = nil,
			PremioPesos = 70,
			PremioPase = 80,
		},
	},
	Eventos = {
		HoraDelRecreo = {
			FrecuenciaSegundos = 3600, -- Cada 1 hora
			DuracionSegundos = 600, -- 10 minutos
			TiendaId = "Tienda_ColegioRecreo",
			Multiplicador = 2.0,
			MensajeAnuncio = "¡Tocó el timbre del recreo! Los estudiantes quieren dulce. ¡Vende al doble!",
		},
	},
	DulceDelDia = {
		Multiplicador = 3.0,
	},
	ProduccionAusencia = {
		FactorVelocidad = 0.5, -- Produce al 50% de velocidad
		MaxHorasOffline = 8,
	},
}

return Rutina
