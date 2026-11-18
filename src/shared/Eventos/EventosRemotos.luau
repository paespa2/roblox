local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventosRemotos = {}

local function obtenerOCrearFolder(): Folder
	local folder = ReplicatedStorage:FindFirstChild("EventosRemotos")
	if not folder then
		if RunService:IsServer() or RunService:IsEdit() or not RunService:IsRunning() then
			local nuevoFolder = Instance.new("Folder")
			nuevoFolder.Name = "EventosRemotos"
			nuevoFolder.Parent = ReplicatedStorage
			folder = nuevoFolder
		else
			folder = ReplicatedStorage:WaitForChild("EventosRemotos", 5)
			if not folder then
				local nuevoFolder = Instance.new("Folder")
				nuevoFolder.Name = "EventosRemotos"
				nuevoFolder.Parent = ReplicatedStorage
				folder = nuevoFolder
			end
		end
	end
	return folder :: Folder
end

local function obtenerOCrearEvento(nombre: string): RemoteEvent
	local folder = obtenerOCrearFolder()
	local evento = folder and folder:FindFirstChild(nombre)
	if not evento then
		if RunService:IsServer() or RunService:IsEdit() or not RunService:IsRunning() then
			local nuevoEvento = Instance.new("RemoteEvent")
			nuevoEvento.Name = nombre
			nuevoEvento.Parent = folder
			evento = nuevoEvento
		else
			evento = folder:WaitForChild(nombre, 5) :: RemoteEvent?
			if not evento then
				local nuevoEvento = Instance.new("RemoteEvent")
				nuevoEvento.Name = nombre
				nuevoEvento.Parent = folder
				evento = nuevoEvento
			end
		end
	end
	return evento :: RemoteEvent
end

local function obtenerOCrearFuncion(nombre: string): RemoteFunction
	local folder = obtenerOCrearFolder()
	local funcion = folder and folder:FindFirstChild(nombre)
	if not funcion then
		if RunService:IsServer() or RunService:IsEdit() or not RunService:IsRunning() then
			local nuevaFuncion = Instance.new("RemoteFunction")
			nuevaFuncion.Name = nombre
			nuevaFuncion.Parent = folder
			funcion = nuevaFuncion
		else
			funcion = folder:WaitForChild(nombre, 5) :: RemoteFunction?
			if not funcion then
				local nuevaFuncion = Instance.new("RemoteFunction")
				nuevaFuncion.Name = nombre
				nuevaFuncion.Parent = folder
				funcion = nuevaFuncion
			end
		end
	end
	return funcion :: RemoteFunction
end

EventosRemotos.DatosActualizados = obtenerOCrearEvento("DatosActualizados")
EventosRemotos.SolicitarDatos = obtenerOCrearFuncion("SolicitarDatos")
EventosRemotos.CocinaActualizada = obtenerOCrearEvento("CocinaActualizada")
EventosRemotos.SolicitarCocinar = obtenerOCrearFuncion("SolicitarCocinar")
EventosRemotos.VentaCompletada = obtenerOCrearEvento("VentaCompletada")
EventosRemotos.SolicitarCompraMejora = obtenerOCrearFuncion("SolicitarCompraMejora")
EventosRemotos.SolicitarCompraVehiculo = obtenerOCrearFuncion("SolicitarCompraVehiculo")
EventosRemotos.SolicitarEquiparVehiculo = obtenerOCrearFuncion("SolicitarEquiparVehiculo")
EventosRemotos.AbrirTiendaMejoras = obtenerOCrearEvento("AbrirTiendaMejoras")
EventosRemotos.EstrellasActualizadas = obtenerOCrearEvento("EstrellasActualizadas")
EventosRemotos.AlertaPolicia = obtenerOCrearEvento("AlertaPolicia")
EventosRemotos.CargaConfiscada = obtenerOCrearEvento("CargaConfiscada")
EventosRemotos.DispararArma = obtenerOCrearFuncion("DispararArma")
EventosRemotos.SolicitarVehiculo = obtenerOCrearFuncion("SolicitarVehiculo")
EventosRemotos.EnviadoAlInternado = obtenerOCrearEvento("EnviadoAlInternado")
EventosRemotos.LiberadoDelInternado = obtenerOCrearEvento("LiberadoDelInternado")
EventosRemotos.SolicitarPagarFianza = obtenerOCrearFuncion("SolicitarPagarFianza")
EventosRemotos.CepillarMuela = obtenerOCrearFuncion("CepillarMuela")
EventosRemotos.MostrarDialogoNPC = obtenerOCrearEvento("MostrarDialogoNPC")
EventosRemotos.LogroDesbloqueado = obtenerOCrearEvento("LogroDesbloqueado")
EventosRemotos.CampanaRecreo = obtenerOCrearEvento("CampanaRecreo")
EventosRemotos.ObjetivoMisionActualizado = obtenerOCrearEvento("ObjetivoMisionActualizado")
EventosRemotos.RedadaIniciada = obtenerOCrearEvento("RedadaIniciada")
EventosRemotos.RedadaTerminada = obtenerOCrearEvento("RedadaTerminada")
EventosRemotos.SolicitarViajeTransporte = obtenerOCrearFuncion("SolicitarViajeTransporte")

return EventosRemotos
