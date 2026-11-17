local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventosRemotos = {}

local function obtenerOCrearFolder(): Folder
	local folder = ReplicatedStorage:FindFirstChild("EventosRemotos")
	if not folder then
		if RunService:IsServer() then
			local nuevoFolder = Instance.new("Folder")
			nuevoFolder.Name = "EventosRemotos"
			nuevoFolder.Parent = ReplicatedStorage
			folder = nuevoFolder
		else
			folder = ReplicatedStorage:WaitForChild("EventosRemotos") :: Folder
		end
	end
	return folder :: Folder
end

local function obtenerOCrearEvento(nombre: string): RemoteEvent
	local folder = obtenerOCrearFolder()
	local evento = folder:FindFirstChild(nombre)
	if not evento then
		if RunService:IsServer() then
			local nuevoEvento = Instance.new("RemoteEvent")
			nuevoEvento.Name = nombre
			nuevoEvento.Parent = folder
			evento = nuevoEvento
		else
			evento = folder:WaitForChild(nombre) :: RemoteEvent
		end
	end
	return evento :: RemoteEvent
end

local function obtenerOCrearFuncion(nombre: string): RemoteFunction
	local folder = obtenerOCrearFolder()
	local funcion = folder:FindFirstChild(nombre)
	if not funcion then
		if RunService:IsServer() then
			local nuevaFuncion = Instance.new("RemoteFunction")
			nuevaFuncion.Name = nombre
			nuevaFuncion.Parent = folder
			funcion = nuevaFuncion
		else
			funcion = folder:WaitForChild(nombre) :: RemoteFunction
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

return EventosRemotos
