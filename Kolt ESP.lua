--📦 ModelESP Plus 2.1 | Autor: DH SOARES + Gemini
--✨ Features: Nome, Distância, Tracer + Círculo, Highlight, Customizações completas

local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera

local ModelESP = { Objects = {}, Enabled = true }

--📍 Posições de origem do tracer
local tracerOrigins = {
	Top = function(vs) return Vector2.new(vs.X / 2, 0) end,
	Center = function(vs) return Vector2.new(vs.X / 2, vs.Y / 2) end,
	Bottom = function(vs) return Vector2.new(vs.X / 2, vs.Y) end,
	Left = function(vs) return Vector2.new(0, vs.Y / 2) end,
	Right = function(vs) return Vector2.new(vs.X, vs.Y / 2) end,
}

--🎯 Centraliza o modelo
local function getModelCenter(model)
	local total, count = Vector3.zero, 0
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p.Transparency < 1 then
			total += p.Position
			count += 1
		end
	end
	return count > 0 and (total / count) or (model:GetPivot() and model:GetPivot().Position or nil)
end

--🧱 Cria um Drawing
local function createDrawing(class, props)
	local d = Drawing.new(class)
	for prop, val in pairs(props) do d[prop] = val end
	return d
end

--➕ Adiciona ESP
function ModelESP:Add(target, config)
	if not target or not target:IsA("Instance") then return end
	if not (target:IsA("Model") or target:IsA("BasePart")) then return end

	--🧹 Limpa Highlights antigos
	for _, c in ipairs(target:GetChildren()) do
		if c:IsA("Highlight") and c.Name:find("ESPHighlight") then c:Destroy() end
	end

	local color = config.Color or Color3.new(1, 1, 1)

	local esp = {
		Target = target,
		Color = color,
		Name = config.Name or target.Name,
		ShowName = config.ShowName or false,
		ShowDistance = config.ShowDistance or false,
		Tracer = config.Tracer or false,
		TracerCircle = config.TracerCircle or false,
		TracerOrigin = tracerOrigins[config.TracerOrigin] and config.TracerOrigin or "Bottom",
		HighlightFill = config.HighlightFill or false,
		HighlightOutline = config.HighlightOutline or false,
		FontSize = config.FontSize or 16,
		CircleRadius = config.CircleRadius or 4,
		LineThickness = config.LineThickness or 1.5,
		MinDistance = config.MinDistance or 0,
		MaxDistance = config.MaxDistance or math.huge
	}

	--🧵 Desenhos
	esp.tracerLine = esp.Tracer and createDrawing("Line", {
		Color = color, Transparency = 1, Visible = false, Thickness = esp.LineThickness
	}) or nil

	esp.tracerCircle = esp.TracerCircle and createDrawing("Circle", {
		Color = color, Transparency = 1, Visible = false, Radius = esp.CircleRadius, Filled = true, NumSides = 12
	}) or nil

	esp.nameText = esp.ShowName and createDrawing("Text", {
		Text = esp.Name, Color = color, Visible = false, Center = true, Outline = true,
		Size = esp.FontSize, Font = 2
	}) or nil

	esp.distanceText = esp.ShowDistance and createDrawing("Text", {
		Text = "", Color = color, Visible = false, Center = true, Outline = true,
		Size = math.floor(esp.FontSize * 0.8), Font = 2
	}) or nil

	--💡 Highlight
	if esp.HighlightFill or esp.HighlightOutline then
		local h = Instance.new("Highlight")
		h.Name = "ESPHighlight"
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.FillColor = color
		h.OutlineColor = color
		h.FillTransparency = esp.HighlightFill and 0.6 or 1
		h.OutlineTransparency = esp.HighlightOutline and 0 or 1
		h.Parent = target
		esp.highlight = h
	end

	table.insert(ModelESP.Objects, esp)
end

--❌ Remove ESP
function ModelESP:Remove(target)
	for i = #ModelESP.Objects, 1, -1 do
		local esp = ModelESP.Objects[i]
		if esp.Target == target then
			for _, v in pairs({ "tracerLine", "tracerCircle", "nameText", "distanceText" }) do
				if esp[v] then pcall(function() esp[v]:Remove() end) end
			end
			if esp.highlight then pcall(function() esp.highlight:Destroy() end) end
			table.remove(ModelESP.Objects, i)
			break
		end
	end
end

--🧼 Limpa todos
function ModelESP:Clear()
	for _, esp in ipairs(ModelESP.Objects) do
		for _, v in pairs({ "tracerLine", "tracerCircle", "nameText", "distanceText" }) do
			if esp[v] then pcall(function() esp[v]:Remove() end) end
		end
		if esp.highlight then pcall(function() esp.highlight:Destroy() end) end
	end
	ModelESP.Objects = {}
end

--📡 Atualização contínua
RunService.RenderStepped:Connect(function()
	if not ModelESP.Enabled then return end

	local vs = camera.ViewportSize

	for i = #ModelESP.Objects, 1, -1 do
		local esp = ModelESP.Objects[i]
		local target = esp.Target
		if not target or not target.Parent then ModelESP:Remove(target) continue end

		local pos3D = target:IsA("Model") and getModelCenter(target) or target.Position
		local ok, pos2D = pcall(function() return camera:WorldToViewportPoint(pos3D) end)
		local dist = (camera.CFrame.Position - pos3D).Magnitude

		local visible = ok and pos2D.Z > 0 and dist >= esp.MinDistance and dist <= esp.MaxDistance
		if not visible then
			if esp.tracerLine then esp.tracerLine.Visible = false end
			if esp.tracerCircle then esp.tracerCircle.Visible = false end
			if esp.nameText then esp.nameText.Visible = false end
			if esp.distanceText then esp.distanceText.Visible = false end
			if esp.highlight then esp.highlight.Enabled = false end
			continue
		end

		local origin = tracerOrigins[esp.TracerOrigin](vs)
		local screenPos = Vector2.new(pos2D.X, pos2D.Y)

		if esp.tracerLine then
			esp.tracerLine.From = origin
			esp.tracerLine.To = screenPos
			esp.tracerLine.Color = esp.Color
			esp.tracerLine.Visible = true
		end

		if esp.tracerCircle then
			esp.tracerCircle.Position = origin
			esp.tracerCircle.Color = esp.Color
			esp.tracerCircle.Visible = true
		end

		if esp.nameText then
			esp.nameText.Position = screenPos - Vector2.new(0, 18)
			esp.nameText.Text = esp.Name
			esp.nameText.Color = esp.Color
			esp.nameText.Visible = true
		end

		if esp.distanceText then
			esp.distanceText.Position = screenPos + Vector2.new(0, 6)
			esp.distanceText.Text = string.format("%.1fm", dist)
			esp.distanceText.Color = esp.Color
			esp.distanceText.Visible = true
		end

		if esp.highlight then
			esp.highlight.FillColor = esp.Color
			esp.highlight.OutlineColor = esp.Color
			esp.highlight.FillTransparency = esp.HighlightFill and 0.6 or 1
			esp.highlight.OutlineTransparency = esp.HighlightOutline and 0 or 1
			esp.highlight.Enabled = true
		end
	end
end)

return ModelESP
