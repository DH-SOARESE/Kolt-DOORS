--[[
ESPLib (Roblox LocalScript Library)
Versão: 1.1.0
Autor: você :)
Licença: MIT

Recursos:  
  - Highlight Outline/Fill  
  - Nome + Distância (m) via BillboardGui  
  - Tracer 2D (Top/Center/Bottom) via GUI  
  - Filtros de distância (min/max) e Display global  
  - Suporte a Model (usa PrimaryPart) e BasePart  
  - Limpeza automática  

Observações:  
  - Distância: 1 stud = 1 "metro" para fins de HUD (ajustável por ScaleMetersPerStud).  
  - Rodar como LocalScript (cliente).

]]

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local Workspace      = game:GetService("Workspace")

local LocalPlayer    = Players.LocalPlayer
local PlayerGui      = LocalPlayer:WaitForChild("PlayerGui")
local Camera         = Workspace.CurrentCamera

-- ==============================
-- CONFIG GLOBAIS
-- ==============================
local GLOBAL = {
Display = true,
MinDistance = 1,      -- metros
MaxDistance = 100,    -- metros
TracerOrigin = "Bottom", -- "Top" | "Center" | "Bottom"
ScaleMetersPerStud = 1,  -- 1 stud = 1 m (ajuste se quiser)
}

-- ==============================
-- GUI RAIZ (para linhas/labels)
-- ==============================
local rootGui = Instance.new("ScreenGui")
rootGui.Name = "ESPLibGui"
rootGui.ResetOnSpawn = false
rootGui.IgnoreGuiInset = true
rootGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
rootGui.Parent = PlayerGui

-- Container para linhas
local linesFolder = Instance.new("Folder")
linesFolder.Name = "Lines"
linesFolder.Parent = rootGui

-- ==============================
-- UTILITÁRIOS
-- ==============================
local function isModel(x)
return typeof(x) == "Instance" and x:IsA("Model")
end

local function isBasePart(x)
return typeof(x) == "Instance" and x:IsA("BasePart")
end

local function getAdorneeFromTarget(target)
if isBasePart(target) then
return target
elseif isModel(target) then
if target.PrimaryPart then
return target.PrimaryPart
else
-- tenta inferir um part
local part = target:FindFirstChildWhichIsA("BasePart", true)
return part
end
end
return nil
end

local function getWorldCFrame(target)
local part = getAdorneeFromTarget(target)
if part and part.Parent then
return part.CFrame
end
return nil
end

local function getWorldPosition(target)
local cf = getWorldCFrame(target)
return cf and cf.Position or nil
end

local function formatMeters(studs, scale)
local meters = studs * (scale or GLOBAL.ScaleMetersPerStud)
-- arredonda para 0.1 m
meters = math.floor(meters * 10 + 0.5) / 10
return tostring(meters) .. " m"
end

local function inDistance(studs)
local m = studs * GLOBAL.ScaleMetersPerStud
return (m >= GLOBAL.MinDistance) and (m <= GLOBAL.MaxDistance)
end

local function makeUILine()
local fr = Instance.new("Frame")
fr.Name = "Tracer"
fr.AnchorPoint = Vector2.new(0, 0.5)
fr.BorderSizePixel = 0
fr.BackgroundColor3 = Color3.new(1,1,1)
fr.BackgroundTransparency = 0
fr.ZIndex = 2
fr.ClipsDescendants = true

local stroke = Instance.new("UIStroke")
stroke.Thickness = 1 -- Espessura da linha
stroke.Color = Color3.fromRGB(0,0,0) -- Contorno
stroke.Transparency = 0.5
stroke.Parent = fr

local originPoint = Instance.new("Frame")
originPoint.Name = "OriginPoint"
originPoint.AnchorPoint = Vector2.new(0.5, 0.5)
originPoint.Size = UDim2.new(0, 6, 0, 6)
originPoint.ZIndex = 3
originPoint.BackgroundColor3 = Color3.new(1,1,1)
originPoint.Parent = linesFolder

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = originPoint

fr.Parent = linesFolder
return fr, originPoint

end

local function drawLine(frame, p0, p1)
-- p0, p1: Vector2 (em pixels)
local dx = p1.X - p0.X
local dy = p1.Y - p0.Y
local len = math.max(1, math.sqrt(dx*dx + dy*dy))
local ang = math.deg(math.atan2(dy, dx))

frame.Position = UDim2.fromOffset(p0.X, p0.Y)
frame.Size = UDim2.fromOffset(len, 1) -- Linha mais fina
frame.Rotation = ang

end

local function getTracerOriginPx(mode)
local vs = Camera.ViewportSize
mode = (mode or GLOBAL.TracerOrigin)
if mode == "Top" then
return Vector2.new(vs.X/2, 0)
elseif mode == "Center" then
return Vector2.new(vs.X/2, vs.Y/2)
else -- "Bottom" default
return Vector2.new(vs.X/2, vs.Y)
end
end

local function getNameFromTarget(target)
if isModel(target) then
return target.Name
elseif isBasePart(target) then
if target.Parent and target.Parent:IsA("Model") then
return target.Parent.Name .. "/" .. target.Name
end
return target.Name
else
return "Unknown"
end
end

-- ==============================
-- CLASSE: EspItem
-- ==============================
local EspItem = {}
EspItem.__index = EspItem

function EspItem:_buildGui()
-- Billboard para nome+distância
local billboard = Instance.new("BillboardGui")
billboard.Name = "ESPLibBillboard"
billboard.AlwaysOnTop = true
billboard.Size = UDim2.new(0, 200, 0, 32)
billboard.StudsOffset = Vector3.new(0, 2.5, 0)
billboard.MaxDistance = math.huge

local label = Instance.new("TextLabel")  
label.Name = "Text"  
label.Size = UDim2.fromScale(1,1)  
label.BackgroundTransparency = 1  
label.TextScaled = true  
label.Font = Enum.Font.GothamMedium  
label.TextColor3 = Color3.new(1,1,1)  
label.TextStrokeTransparency = 0.5  
label.Text = ""  
label.Parent = billboard  

self.Billboard = billboard  
self.Label = label

end

function EspItem:_buildHighlight()
local h = Instance.new("Highlight")
h.Name = "ESPLibHighlight"
h.Enabled = true
h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
self.Highlight = h
end

function EspItem:_buildTracer()
local fr, pt = makeUILine()
self.TracerFrame = fr
self.TracerPoint = pt
end

function EspItem:_applyVisual()
-- Highlight
if self.Highlight then
self.Highlight.FillColor = self.Color
self.Highlight.OutlineColor = self.Color
self.Highlight.FillTransparency = self.HighlightFill and self.FillTransparency or 1
self.Highlight.OutlineTransparency = self.HighlightOutline and self.OutlineTransparency or 1
end
-- Texto
if self.Label then
self.Label.TextColor3 = self.Color
end
-- Tracer
if self.TracerFrame then
self.TracerFrame.BackgroundColor3 = self.Color
local stroke = self.TracerFrame:FindFirstChildOfClass("UIStroke")
if stroke then stroke.Color = self.Color end
if self.TracerPoint then
self.TracerPoint.BackgroundColor3 = self.Color
end
end
end

function EspItem.new(target, opts)
local self = setmetatable({}, EspItem)

self.Target = target  
self.Color = (opts and opts.Color) or Color3.fromRGB(255, 60, 60)  

self.ShowName = (opts and opts.ShowName) ~= false  
self.ShowDistance = (opts and opts.ShowDistance) ~= false  

self.HighlightOutline = (opts and opts.HighlightOutline) ~= false  
self.HighlightFill = (opts and opts.HighlightFill) or false  
self.FillTransparency = (opts and opts.FillTransparency) or 0.7  
self.OutlineTransparency = (opts and opts.OutlineTransparency) or 0  

self.NameText = (opts and opts.Name) or getNameFromTarget(target)  

self.Tracer = (opts and opts.Tracer) or "Off" -- "Top" | "Center" | "Bottom" | "Off"  
self.Adornee = getAdorneeFromTarget(target)  

self._maid = {}  

-- Construir elementos  
self:_buildGui()  
self:_buildHighlight()  
self:_buildTracer()  

-- Parentear  
if self.Adornee then  
    self.Billboard.Adornee = self.Adornee  
    self.Billboard.Parent = self.Adornee  
    self.Highlight.Adornee = isModel(self.Target) and self.Target or self.Adornee  
    self.Highlight.Parent = self.Adornee  
end  

self:_applyVisual()  

-- Conexão de atualização  
self._conn = RunService.RenderStepped:Connect(function()  
    self:_update()  
end)  

table.insert(self._maid, self._conn)  

-- Observa destruição do alvo  
if self.Adornee then  
    local ancConn = self.Adornee.AncestryChanged:Connect(function(_, parent)  
        if not parent then  
            self:Destroy()  
        end  
    end)  
    table.insert(self._maid, ancConn)  
end  

return self

end

function EspItem:_update()
if not GLOBAL.Display then
self:_setVisible(false)
return
end

local pos = getWorldPosition(self.Target)  
if not pos then  
    self:_setVisible(false)  
    return  
end  

local camPos = Camera.CFrame.Position  
local studs = (pos - camPos).Magnitude  

if not inDistance(studs) then  
    self:_setVisible(false)  
    return  
end  

-- On-screen?  
local screenPos, onScreen = Camera:WorldToViewportPoint(pos)  
if not onScreen or screenPos.Z < 0 then  
    self:_setVisible(false)  
    return  
end  

-- Atualiza texto  
local labelText = {}  
if self.ShowName then table.insert(labelText, self.NameText) end  
if self.ShowDistance then table.insert(labelText, "[" .. formatMeters(studs, GLOBAL.ScaleMetersPerStud) .. "]") end  
self.Label.Text = table.concat(labelText, " ")  

-- Cores/transparências (caso mude em runtime)  
self:_applyVisual()  

-- Tracer  
local tracerOn = (self.Tracer == "Top" or self.Tracer == "Center" or self.Tracer == "Bottom")  
if tracerOn then  
    self.TracerFrame.Visible = true  
    self.TracerPoint.Visible = true
    local origin = getTracerOriginPx(self.Tracer)  
    local target2D = Vector2.new(screenPos.X, screenPos.Y)  
    drawLine(self.TracerFrame, origin, target2D)  
    self.TracerPoint.Position = UDim2.fromOffset(origin.X, origin.Y)
else  
    self.TracerFrame.Visible = false  
    self.TracerPoint.Visible = false
end  

self:_setVisible(true)

end

function EspItem:_setVisible(v)
if self.Highlight then self.Highlight.Enabled = v end
if self.Billboard then self.Billboard.Enabled = v end
if self.TracerFrame then self.TracerFrame.Visible = v and (self.Tracer ~= "Off") end
if self.TracerPoint then self.TracerPoint.Visible = v and (self.Tracer ~= "Off") end
end

function EspItem:SetColor(color)
self.Color = color
self:_applyVisual()
end

function EspItem:SetName(nameText)
self.NameText = nameText
end

function EspItem:SetTracer(mode) -- "Top" | "Center" | "Bottom" | "Off"
self.Tracer = mode
end

function EspItem:Destroy()
if self._conn then
self._conn:Disconnect()
self._conn = nil
end
for _, c in ipairs(self._maid) do
if typeof(c) == "RBXScriptConnection" then
c:Disconnect()
end
end
self._maid = {}

if self.TracerFrame then  
    self.TracerFrame:Destroy()  
    self.TracerFrame = nil  
end  
if self.TracerPoint then
    self.TracerPoint:Destroy()
    self.TracerPoint = nil
end
if self.Billboard then  
    self.Billboard:Destroy()  
    self.Billboard = nil  
end  
if self.Highlight then  
    self.Highlight:Destroy()  
    self.Highlight = nil  
end  

self.Target = nil  
self.Adornee = nil

end

-- ==============================
-- API PÚBLICA
-- ==============================
local ESPLib = {}

-- Adiciona e retorna um "handle" (o próprio EspItem)
function ESPLib.Add(target, opts)
local adornee = getAdorneeFromTarget(target)
if not adornee then
warn("[ESPLib] Alvo inválido (não encontrou BasePart).")
return nil
end
return EspItem.new(target, opts or {})
end

function ESPLib.Remove(handle)
if handle and typeof(handle) == "table" and handle.Destroy then
handle:Destroy()
end
end

function ESPLib.SetDisplay(on)
GLOBAL.Display = not not on
end

function ESPLib.SetMaxDistance(meters)
GLOBAL.MaxDistance = tonumber(meters) or GLOBAL.MaxDistance
end

function ESPLib.SetMinDistance(meters)
GLOBAL.MinDistance = tonumber(meters) or GLOBAL.MinDistance
end

function ESPLib.SetTracerOrigin(mode) -- "Top" | "Center" | "Bottom"
if mode == "Top" or mode == "Center" or mode == "Bottom" then
GLOBAL.TracerOrigin = mode
end
end

function ESPLib.SetMetersPerStud(scale)
-- Caso queira 1 stud ≈ 0.28 m: ESPLib.SetMetersPerStud(0.28)
GLOBAL.ScaleMetersPerStud = tonumber(scale) or GLOBAL.ScaleMetersPerStud
end

-- Retorna versão
function ESPLib.Version()
return "1.1.0"
end

return ESPLib
