--[[
📦 Model ESP Library Plus v1.2 - Estilo Hub Refinado
👤 Autor: DH SOARES
]]

--// 🔧 Serviços
local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera

--// 🧠 Tabela principal da biblioteca
local ModelESP = {}
ModelESP.Objects = {}
ModelESP.Enabled = true

--// 📍 Posições de Origem para o Tracer
local tracerOrigins = {
	Top = function(vs) return Vector2.new(vs.X / 2, 0) end,
	Center = function(vs) return Vector2.new(vs.X / 2, vs.Y / 2) end,
	Bottom = function(vs) return Vector2.new(vs.X / 2, vs.Y) end,
	Left = function(vs) return Vector2.new(0, vs.Y / 2) end,
	Right = function(vs) return Vector2.new(vs.X, vs.Y / 2) end,
}

--// 📍 Calcula o centro visual do modelo
local function getModelCenter(model)
	local total, count = Vector3.zero, 0
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p.Transparency < 1 and p.CanCollide then
			total += p.Position
			count += 1
		end
	end
	if count > 0 then return total / count end
	return model:IsA("Model") and (model.PrimaryPart and model.PrimaryPart.Position or model:GetPivot().Position)
end

--// 🛠️ Cria objetos Drawing com propriedades
local function createDrawing(class, props)
	local obj = Drawing.new(class)
	for k, v in pairs(props) do obj[k] = v end
	return obj
end

--// ➕ Adiciona novo ESP ao sistema
function ModelESP:Add(target, config)
	if not target or not target:IsA("Instance") then return end
	if not (target:IsA("Model") or target:IsA("BasePart")) then return end

	-- Remove Highlights anteriores do mesmo tipo
	for _, obj in ipairs(target:GetChildren()) do
		if obj:IsA("Highlight") and obj.Name:sub(1, 12) == "ESPHighlight" then
			obj:Destroy()
		end
	end

	local cfg = {
		Target = target,
		Color = config.Color or Color3.fromRGB(255, 255, 255),
		Name = config.Name or target.Name,
		ShowName = config.ShowName or false,
		ShowDistance = config.ShowDistance or false,
		Tracer = config.Tracer or false,
		HighlightFill = config.HighlightFill or false,
		HighlightOutline = config.HighlightOutline or false,
		TracerOrigin = tracerOrigins[config.TracerOrigin] and config.TracerOrigin or "Bottom",
		MinDistance = config.MinDistance or 0,
		MaxDistance = config.MaxDistance or math.huge,
	}

	-- Desenhos ESP
	cfg.tracerLine = cfg.Tracer and createDrawing("Line", {
		Thickness = 2,
		Color = cfg.Color,
		Transparency = 1,
		Visible = false
	}) or nil

	cfg.tracerCircle = cfg.Tracer and createDrawing("Circle", {
		Radius = 6,
		Color = cfg.Color,
		Filled = true,
		Thickness = 1,
		NumSides = 16,
		Transparency = 1,
		Visible = false
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
		Color = cfg.Color,
		Size = 14,
		Center = true,
		Outline = true,
		Font = 2,
		Visible = false
	}) or nil

	-- Highlight Roblox (estilo moderno)
	if cfg.HighlightFill or cfg.HighlightOutline then
		local highlight = Instance.new("Highlight")
		highlight.Name = "ESPHighlight"
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.FillColor = cfg.Color
		highlight.OutlineColor = cfg.Color
		highlight.FillTransparency = cfg.HighlightFill and 0.5 or 1
		highlight.OutlineTransparency = cfg.HighlightOutline and 0 or 1
		highlight.Parent = target
		cfg.highlight = highlight
	end

	table.insert(ModelESP.Objects, cfg)
end

--// ➖ Remove ESP individual
function ModelESP:Remove(target)
	for i = #ModelESP.Objects, 1, -1 do
		local obj = ModelESP.Objects[i]
		if obj.Target == target then
			for _, draw in ipairs({obj.tracerLine, obj.tracerCircle, obj.nameText, obj.distanceText}) do
				if draw then pcall(draw.Remove, draw) end
			end
			if obj.highlight then pcall(obj.highlight.Destroy, obj.highlight) end
			table.remove(ModelESP.Objects, i)
			break
		end
	end
end

--// 🧹 Remove todos os ESPs
function ModelESP:Clear()
	for _, obj in ipairs(ModelESP.Objects) do
		for _, draw in ipairs({obj.tracerLine, obj.tracerCircle, obj.nameText, obj.distanceText}) do
			if draw then pcall(draw.Remove, draw) end
		end
		if obj.highlight then pcall(obj.highlight.Destroy, obj.highlight) end
	end
	ModelESP.Objects = {}
end

--// 🔁 Atualização a cada frame
RunService.RenderStepped:Connect(function()
	if not ModelESP.Enabled then return end
	local vs = camera.ViewportSize

	for i = #ModelESP.Objects, 1, -1 do
		local esp = ModelESP.Objects[i]
		local target = esp.Target

		if not target or not target.Parent then
			ModelESP:Remove(target)
			continue
		end

		local pos3D = target:IsA("Model") and getModelCenter(target) or (target:IsA("BasePart") and target.Position)
		if not pos3D then
			ModelESP:Remove(target)
			continue
		end

		local success, pos2D = pcall(function() return camera:WorldToViewportPoint(pos3D) end)
		if not success or pos2D.Z <= 0 or pos2D.X ~= pos2D.X then
			if esp.tracerLine then esp.tracerLine.Visible = false end
			if esp.tracerCircle then esp.tracerCircle.Visible = false end
			if esp.nameText then esp.nameText.Visible = false end
			if esp.distanceText then esp.distanceText.Visible = false end
			if esp.highlight then esp.highlight.Enabled = false end
			continue
		end

		local distance = (camera.CFrame.Position - pos3D).Magnitude
		local visible = distance >= esp.MinDistance and distance <= esp.MaxDistance
		if not visible then continue end

		local screenPos = Vector2.new(pos2D.X, pos2D.Y)
		local originPos = tracerOrigins[esp.TracerOrigin](vs)

		-- Atualiza Tracer
		if esp.tracerLine then
			esp.tracerLine.From = originPos
			esp.tracerLine.To = screenPos
			esp.tracerLine.Color = esp.Color
			esp.tracerLine.Visible = true
		end

		-- Atualiza círculo decorativo no ponto de origem
		if esp.tracerCircle then
			esp.tracerCircle.Position = originPos
			esp.tracerCircle.Color = esp.Color
			esp.tracerCircle.Visible = true
		end

		-- Atualiza nome
		if esp.nameText then
			esp.nameText.Position = screenPos - Vector2.new(0, 20)
			esp.nameText.Text = esp.Name
			esp.nameText.Color = esp.Color
			esp.nameText.Visible = true
		end

		-- Atualiza distância
		if esp.distanceText then
			esp.distanceText.Position = screenPos + Vector2.new(0, 6)
			esp.distanceText.Text = string.format("%.1fm", distance)
			esp.distanceText.Color = esp.Color
			esp.distanceText.Visible = true
		end

		-- Atualiza Highlight
		if esp.highlight then
			esp.highlight.Enabled = true
			esp.highlight.FillColor = esp.Color
			esp.highlight.OutlineColor = esp.Color
		end
	end
end)

return ModelESP
