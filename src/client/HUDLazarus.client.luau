--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local existente = playerGui:FindFirstChild("HUDLazarusGui")
if existente then
	existente:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HUDLazarusGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 18
screenGui.Parent = playerGui

local contenedor = Instance.new("Frame")
contenedor.Name = "BarraLazarus"
contenedor.AnchorPoint = Vector2.new(0.5, 1)
contenedor.Position = UDim2.new(0.5, 0, 1, -86)
contenedor.Size = UDim2.fromOffset(620, 34)
contenedor.BackgroundColor3 = Color3.fromRGB(14, 16, 26)
contenedor.BackgroundTransparency = 0.25
contenedor.BorderSizePixel = 0
contenedor.Visible = false
contenedor.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = contenedor

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 195, 55)
stroke.Thickness = 1.5
stroke.Transparency = 0.2
stroke.Parent = contenedor

local textoEstado = Instance.new("TextLabel")
textoEstado.Name = "TextoPerksYPowerUps"
textoEstado.Size = UDim2.new(1, -16, 1, -4)
textoEstado.Position = UDim2.fromOffset(8, 2)
textoEstado.BackgroundTransparency = 1
textoEstado.Font = Enum.Font.GothamBold
textoEstado.TextColor3 = Color3.fromRGB(255, 240, 190)
textoEstado.TextSize = 13
textoEstado.TextWrapped = true
textoEstado.Text = ""
textoEstado.Parent = contenedor

local DEFINICION_PERKS = {
	{ Atributo = "PerkTitanMuela", Etiqueta = "🥤 Titán-Muela (200 HP)" },
	{ Atributo = "PerkVelocidad", Etiqueta = "⚡ Relámpago" },
	{ Atributo = "PerkDobleDisparo", Etiqueta = "🔥 Doble Cadencia" },
	{ Atributo = "PerkRegeneracion", Etiqueta = "💚 Regeneración" },
	{ Atributo = "ArmaPotenciada", Etiqueta = "🔮 MK-II Pack-a-Punch" },
}

local function actualizarHUDLazarus()
	if localPlayer:GetAttribute("HordaHUDActivo") == true then
		contenedor.Visible = false
		return
	end
	local partes: { string } = {}

	for _, info in ipairs(DEFINICION_PERKS) do
		if localPlayer:GetAttribute(info.Atributo) == true then
			table.insert(partes, info.Etiqueta)
		end
	end

	if Workspace:GetAttribute("LazarusPuntosDobles") == true then
		local segs = tonumber(Workspace:GetAttribute("LazarusPuntosDoblesSegundos")) or 0
		table.insert(partes, string.format("🍬 DULCES 2X (%ds)", segs))
	end

	if Workspace:GetAttribute("LazarusInstaKill") == true then
		local segs = tonumber(Workspace:GetAttribute("LazarusInstaKillSegundos")) or 0
		table.insert(partes, string.format("💀 INSTA-KILL (%ds)", segs))
	end

	local pts = tonumber(localPlayer:GetAttribute("PuntosLazarusAcumulados")) or 0
	local tablones = tonumber(localPlayer:GetAttribute("TablonesReparadosLazarus")) or 0
	if pts > 0 or tablones > 0 then
		table.insert(partes, string.format("🪵 Tablones: %d | 🎯 Dulces Impacto: +%d 🍬", tablones, pts))
	end

	if #partes > 0 then
		contenedor.Visible = true
		textoEstado.Text = "💀 LAZARUS: " .. table.concat(partes, "  •  ")
	else
		contenedor.Visible = false
	end
end

for _, info in ipairs(DEFINICION_PERKS) do
	localPlayer:GetAttributeChangedSignal(info.Atributo):Connect(actualizarHUDLazarus)
end
localPlayer:GetAttributeChangedSignal("PuntosLazarusAcumulados"):Connect(actualizarHUDLazarus)
localPlayer:GetAttributeChangedSignal("TablonesReparadosLazarus"):Connect(actualizarHUDLazarus)
localPlayer:GetAttributeChangedSignal("HordaHUDActivo"):Connect(actualizarHUDLazarus)

Workspace:GetAttributeChangedSignal("LazarusPuntosDobles"):Connect(actualizarHUDLazarus)
Workspace:GetAttributeChangedSignal("LazarusPuntosDoblesSegundos"):Connect(actualizarHUDLazarus)
Workspace:GetAttributeChangedSignal("LazarusInstaKill"):Connect(actualizarHUDLazarus)
Workspace:GetAttributeChangedSignal("LazarusInstaKillSegundos"):Connect(actualizarHUDLazarus)

actualizarHUDLazarus()
