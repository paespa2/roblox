local Persecucion = {
	CalorPorAccion = {
		VentaComun = 15,
		VentaColegio = 25,
		SobrecargaPorSegundo = 5,
		DisparoCauchera = 20,
		EvasionBarricada = 50,
	},
	TasaEnfriamiento = {
		Calle = 3,
		Escondite = 15,
	},
	Estrellas = {
		[1] = {
			UmbralPuntos = 50,
			VelocidadPatrulla = 16,
			ConoVisionStuds = 30,
			PierdeCargaPorcentaje = 0.10,
			EnviaAlInternado = false,
			CondenaSegundos = 0,
			FianzaPesos = 0,
		},
		[2] = {
			UmbralPuntos = 120,
			VelocidadPatrulla = 22,
			ConoVisionStuds = 55,
			PierdeCargaPorcentaje = 0.50,
			EnviaAlInternado = false,
			CondenaSegundos = 0,
			FianzaPesos = 0,
		},
		[3] = {
			UmbralPuntos = 220,
			VelocidadPatrulla = 26,
			ConoVisionStuds = 70,
			PierdeCargaPorcentaje = 1.00,
			EnviaAlInternado = true,
			CondenaSegundos = 60,
			FianzaPesos = 50,
		},
		[4] = {
			UmbralPuntos = 350,
			VelocidadPatrulla = 32,
			ConoVisionStuds = 85,
			PierdeCargaPorcentaje = 1.00,
			EnviaAlInternado = true,
			CondenaSegundos = 120,
			FianzaPesos = 100,
		},
		[5] = {
			UmbralPuntos = 500,
			VelocidadPatrulla = 36,
			ConoVisionStuds = 100,
			PierdeCargaPorcentaje = 1.00,
			EnviaAlInternado = true,
			CondenaSegundos = 180,
			FianzaPesos = 250,
		},
	},
	Internado = {
		ReduccionPorCepilladoSegundos = 20,
		MaxCondenaSegundos = 180,
	},
}

return Persecucion
