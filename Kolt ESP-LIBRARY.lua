--[[
👤 Autor: DH_SOARES
🎨 Estilo: HUB Refinado
🧩 Recursos Suportados:
✅ Nome personalizado
✅ Distância até o alvo
✅ Tracer com bolinha de origem
✅ Highlight Fill & Outline
]]

local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera

local ModelESP = {}
ModelESP.Objects = {}
ModelESP.Enabled = true

local tracerOrigins = {
	Top = function(vs) return Vector2.new(vs.X / 2, 0) end,
	Center = function(vs) return Vector2.new(vs.X / 2, vs.Y / 2) end,
	Bottom = function(vs) return Vector2.new(vs.X / 2, vs.Y) end,
	Left = function(vs) return Vector2.new(0, vs.Y / 2) end,
	Right = function(vs) return Vector2.new(vs.X, vs.Y / 2) end,
}

local function getModelCenter(model)
	local total, count = Vector3.zero, 0
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p.Transparency < 1 and p.CanCollide then
			total += p.Position
			count += 1
		end
	end
	if count > 0 then return total / count end
	if model.PrimaryPart then return model.PrimaryPart.Position end
	if model:IsA("Model") and model.WorldPivot then return model.WorldPivot.Position end
	return nil
end

local function createDrawing(class, props)
	local obj = Drawing.new(class)
	for k, v in pairs(props) do obj[k] = v end
	return obj
end

function ModelESP:Add(target, config)
	if not target or not target:IsA("Instance") then return end
	if not target:IsA("Model") and not target:IsA("BasePart") then return end

	for _, obj in pairs(target:GetChildren()) do
		if obj:IsA("Highlight") and obj.Name:sub(1, 12) == "ESPHighlight" then
			obj:Destroy()
		end
	end

	local cfg = {
		Target = target,
		Color = config.Color or Color3.fromRGB(0, 255, 255),
		Name = config.Name or target.Name,
		ShowName = config.ShowName or false,
		ShowDistance = config.ShowDistance or false,
		Tracer = config.Tracer or false,
		TracerDot = config.TracerDot or true,
		HighlightFill = config.HighlightFill or false,
		HighlightOutline = config.HighlightOutline or false,
		TracerOrigin = tracerOrigins[config.TracerOrigin] and config.TracerOrigin or "Bottom",
		MinDistance = config.MinDistance or 0,
		MaxDistance = config.MaxDistance or math.huge,
	}

	-- DRAWINGS
	cfg.tracerLine = cfg.Tracer and createDrawing("Line", {
		Thickness = 1.5,
		Color = cfg.Color,
		Transparency = 1,
		Visible = false
	}) or nil

	cfg.tracerDot = cfg.TracerDot and createDrawing("Circle", {
		Radius = 4,
		Filled = true,
		Thickness = 1,
		Color = cfg.Color,
		Transparency = 1,
		Visible = false,
		Position = Vector2.new()
	}) or nil

	cfg.nameText = cfg.ShowName and createDrawing("Text", {
		Text = cfg.Name,
		Color = cfg.Color,
		Size = 16,
		Center = true,
		Outline = true,
		Font = 2,
		Visible = false
	}) or nil

	cfg.distanceText = cfg.ShowDistance and createDrawing("Text", {
		Text = "",
		Color = cfg.Color,
		Size = 14,
		Center = true,
		Outline = true,
		Font = 2,
		Visible = false
	}) or nil

	if cfg.HighlightFill or cfg.HighlightOutline then
		local highlight = Instance.new("Highlight")
		highlight.Name = "ESPHighlight"
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.FillColor = cfg.Color
		highlight.OutlineColor = cfg.Color
		highlight.FillTransparency = cfg.HighlightFill and 0.6 or 1
		highlight.OutlineTransparency = cfg.HighlightOutline and 0 or 1
		highlight.Parent = target
		cfg.highlight = highlight
	end

	table.insert(ModelESP.Objects, cfg)
end

function ModelESP:Remove(target)
	for i = #ModelESP.Objects, 1, -1 do
		local obj = ModelESP.Objects[i]
		if obj.Target == target then
			for _, k in pairs({ "tracerLine", "tracerDot", "nameText", "distanceText" }) do
				if obj[k] then pcall(function() obj[k]:Remove() end) end
			end
			if obj.highlight then pcall(function() obj.highlight:Destroy() end) end
			table.remove(ModelESP.Objects, i)
			break
		end
	end
end

function ModelESP:Clear()
	for _, obj in ipairs(ModelESP.Objects) do
		for _, k in pairs({ "tracerLine", "tracerDot", "nameText", "distanceText" }) do
			if obj[k] then pcall(function() obj[k]:Remove() end) end
		end
		if obj.highlight then pcall(function() obj.highlight:Destroy() end) end
	end
	ModelESP.Objects = {}
end

RunService.RenderStepped:Connect(function()
	if not ModelESP.Enabled then return end

	local vs = camera.ViewportSize

	for i = #ModelESP.Objects, 1, -1 do
		local esp = ModelESP.Objects[i]
		local target = esp.Target

		local pos3D = target:IsA("Model") and getModelCenter(target) or (target:IsA("BasePart") and target.Position or nil)
		if not target or not target.Parent or not pos3D then
			ModelESP:Remove(target)
			continue
		end

		local success, pos2D = pcall(function() return camera:WorldToViewportPoint(pos3D) end)
		local onScreen = success and pos2D.Z > 0
		local distance = (camera.CFrame.Position - pos3D).Magnitude
		local visible = onScreen and distance >= esp.MinDistance and distance <= esp.MaxDistance

		if not visible then
			if esp.tracerLine then esp.tracerLine.Visible = false end
			if esp.tracerDot then esp.tracerDot.Visible = false end
			if esp.nameText then esp.nameText.Visible = false end
			if esp.distanceText then esp.distanceText.Visible = false end
			if esp.highlight then esp.highlight.Enabled = false end
			continue
		end

		local tracerOrigin = tracerOrigins[esp.TracerOrigin](vs)

		if esp.tracerLine then
			esp.tracerLine.From = tracerOrigin
			esp.tracerLine.To = Vector2.new(pos2D.X, pos2D.Y)
			esp.tracerLine.Color = esp.Color
			esp.tracerLine.Visible = true
		end

		if esp.tracerDot then
			esp.tracerDot.Position = tracerOrigin
			esp.tracerDot.Color = esp.Color
			esp.tracerDot.Visible = true
		end

		if esp.nameText then
			esp.nameText.Position = Vector2.new(pos2D.X, pos2D.Y - 20)
			esp.nameText.Text = esp.Name
			esp.nameText.Color = esp.Color
			esp.nameText.Visible = true
		end

		if esp.distanceText then
			esp.distanceText.Position = Vector2.new(pos2D.X, pos2D.Y + 6)
			esp.distanceText.Text = string.format("%.1fm", distance)
			esp.distanceText.Color = esp.Color
			esp.distanceText.Visible = true
		end

		if esp.highlight then
			esp.highlight.Enabled = true
			esp.highlight.FillColor = esp.Color
			esp.highlight.OutlineColor = esp.Color
			esp.highlight.FillTransparency = esp.HighlightFill and 0.6 or 1
			esp.highlight.OutlineTransparency = esp.HighlightOutline and 0 or 1
		end
	end
end)

return ModelESP
