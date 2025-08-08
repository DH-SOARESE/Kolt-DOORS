--// KOLT ESP HUB LIBRARY
--// Estilo HUB simples, tipo orientado e modular

local KoltESP = {}
KoltESP.__index = KoltESP

local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

-- Cor padrão
local espColor = Color3.new(1, 1, 1)

-- Função utilitária: cria texto
local function createLabel(parent)
	local label = Drawing.new("Text")
	label.Visible = false
	label.Center = true
	label.Outline = true
	label.Size = 14
	label.Font = 2
	label.Color = espColor
	label.Text = ""
	return label
end

-- Função utilitária: cria linha (tracer)
local function createTracer()
	local line = Drawing.new("Line")
	line.Visible = false
	line.Thickness = 1
	line.Transparency = 1
	line.Color = espColor
	return line
end

-- Criação do ESP
function KoltESP.new(target, config)
	assert(typeof(target) == "Instance", "Target precisa ser Model ou BasePart")
	
	local self = setmetatable({}, KoltESP)
	self.Target = target
	self.Enabled = true
	self.TypeSettings = {
		Tracer = false,
		Name = false,
		Distance = false,
		HighlightOutline = false,
		HighlightFill = false,
	}
	self.TracerPosition = "Bottom" -- Top, Center, Bottom
	
	-- Componentes
	self.NameLabel = createLabel()
	self.DistanceLabel = createLabel()
	self.Tracer = createTracer()
	
	-- Highlight
	self.Highlight = Instance.new("Highlight")
	self.Highlight.FillColor = espColor
	self.Highlight.OutlineColor = espColor
	self.Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	self.Highlight.FillTransparency = 0.7
	self.Highlight.OutlineTransparency = 0
	self.Highlight.Parent = target
	self.Highlight.Adornee = target
	self.Highlight.Enabled = false
	
	RunService.RenderStepped:Connect(function()
		if not self.Enabled or not self.Target or not self.Target:IsDescendantOf(workspace) then
			self:HideAll()
			return
		end

		local pos = self:GetPosition()
		if not pos then
			self:HideAll()
			return
		end

		local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
		if not onScreen then
			self:HideAll()
			return
		end

		-- Name
		if self.TypeSettings.Name then
			self.NameLabel.Text = self.Target.Name
			self.NameLabel.Position = Vector2.new(screenPos.X, screenPos.Y - 20)
			self.NameLabel.Visible = true
		else
			self.NameLabel.Visible = false
		end

		-- Distance
		if self.TypeSettings.Distance then
			local distance = (Camera.CFrame.Position - pos).Magnitude
			self.DistanceLabel.Text = string.format("%.0fm", distance)
			self.DistanceLabel.Position = Vector2.new(screenPos.X, screenPos.Y)
			self.DistanceLabel.Visible = true
		else
			self.DistanceLabel.Visible = false
		end

		-- Tracer
		if self.TypeSettings.Tracer then
			self.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
			self.Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
			self.Tracer.Visible = true
		else
			self.Tracer.Visible = false
		end

		-- Highlight
		self.Highlight.Enabled = (self.TypeSettings.HighlightOutline or self.TypeSettings.HighlightFill)
		self.Highlight.FillTransparency = self.TypeSettings.HighlightFill and 0.7 or 1
		self.Highlight.OutlineTransparency = self.TypeSettings.HighlightOutline and 0 or 1
	end)

	return self
end

function KoltESP:GetPosition()
	if self.Target:IsA("BasePart") then
		return self.Target.Position
	elseif self.Target:IsA("Model") and self.Target.PrimaryPart then
		local offset = self.TracerPosition == "Top" and Vector3.new(0, 3, 0)
			or self.TracerPosition == "Center" and Vector3.new(0, 1, 0)
			or Vector3.new(0, 0, 0)
		return self.Target.PrimaryPart.Position + offset
	end
end

function KoltESP:SetType(typeName, visible)
	if self.TypeSettings[typeName] ~= nil then
		self.TypeSettings[typeName] = visible
	end
end

function KoltESP:SetTracerPosition(pos)
	if typeof(pos) == "string" and (pos == "Top" or pos == "Center" or pos == "Bottom") then
		self.TracerPosition = pos
	end
end

function KoltESP:SetTarget(newTarget)
	self.Target = newTarget
	self.Highlight.Adornee = newTarget
end

function KoltESP:HideAll()
	self.NameLabel.Visible = false
	self.DistanceLabel.Visible = false
	self.Tracer.Visible = false
	self.Highlight.Enabled = false
end

-- Configura cor global
function KoltESP.SetColor(color)
	espColor = color
end

return KoltESP
