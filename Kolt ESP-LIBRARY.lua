--// 📦 Library Kolt v1
--// 👤 Autor: DH_SOARES
--// 🎨 Estilo: Focado em animações suaves, tipografia refinada e pouco poluição visual

--// 🔧 Serviços
local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService") -- Mantemos o serviço, mas não o usamos para a posição

--// 🧠 Tabela principal da biblioteca
local ModelESP = {
	Objects = {},
	Enabled = true,
	Theme = {
		PrimaryColor = Color3.fromRGB(130, 200, 255), -- Azul claro suave
		SecondaryColor = Color3.fromRGB(255, 255, 255), -- Branco
		OutlineColor = Color3.fromRGB(0, 0, 0), -- Contorno preto sutil para legibilidade
		RainbowMode = false,
		PulseSpeed = 2,
	},
	Settings = {
		Tracer = {
			Enabled = true,
			Origin = "Bottom",
		},
		Name = {
			Enabled = true,
		},
		Distance = {
			Enabled = true,
		},
		Highlight = {
			FillEnabled = true,
			OutlineEnabled = true,
		},
		Opacity = 0.7,
		FillTransparency = 0.85,
		OutlineTransparency = 0.65,
	}
}

--// 🌈 Função para gerar cor arco-íris
local function getRainbowColor(t)
	local frequency = 0.5
	local r = math.sin(frequency * t + 0) * 127 + 128
	local g = math.sin(frequency * t + 2) * 127 + 128
	local b = math.sin(frequency * t + 4) * 127 + 128
	return Color3.fromRGB(r, g, b)
end

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
	return count > 0 and total / count or (model:IsA("Model") and (model.PrimaryPart and model.PrimaryPart.Position or model:GetPivot().Position))
end

--// 🛠️ Cria objetos Drawing com propriedades estilizadas
local function createDrawing(class, props)
	local obj = Drawing.new(class)
	for k, v in pairs(props) do obj[k] = v end
	return obj
end

--// ➕ Adiciona novo ESP ao sistema
function ModelESP:Add(target, config)
	if not target or not target:IsA("Instance") then return end
	if not (target:IsA("Model") or target:IsA("BasePart")) then return end

	-- Remove Highlights anteriores para evitar duplicatas
	for _, obj in ipairs(target:GetChildren()) do
		if obj:IsA("Highlight") and obj.Name == "ESPHighlight" then
			obj:Destroy()
		end
	end

	local cfg = {
		Target = target,
		Color = config.Color or ModelESP.Theme.PrimaryColor,
		Name = config.Name or target.Name,
		MinDistance = config.MinDistance or 0,
		MaxDistance = config.MaxDistance or math.huge,
	}

	-- Desenhos ESP com estilo limpo (criados sempre, visibilidade controlada globalmente)
	cfg.tracerLine = createDrawing("Line", {
		Thickness = 1.5, -- Espessura reduzida para um visual mais delicado
		Color = cfg.Color,
		Transparency = ModelESP.Settings.Opacity,
		Visible = false
	})

	cfg.nameText = createDrawing("Text", {
		Text = cfg.Name,
		Color = cfg.Color,
		Size = 14, -- Tamanho reduzido para menos poluição
		Center = true,
		Outline = true,
		OutlineColor = ModelESP.Theme.OutlineColor, -- Contorno preto sutil
		Font = Drawing.Fonts.Monospace,
		Transparency = ModelESP.Settings.Opacity,
		Visible = false
	})

	cfg.distanceText = createDrawing("Text", {
		Color = cfg.Color,
		Size = 12, -- Tamanho ainda menor para a distância
		Center = true,
		Outline = true,
		OutlineColor = ModelESP.Theme.OutlineColor, -- Contorno preto sutil
		Font = Drawing.Fonts.Monospace,
		Transparency = ModelESP.Settings.Opacity,
		Visible = false
	})

	-- Highlight com estilo sutil (criado sempre, transparências controladas globalmente)
	local highlight = Instance.new("Highlight")
	highlight.Name = "ESPHighlight"
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = cfg.Color
	highlight.OutlineColor = ModelESP.Theme.SecondaryColor
	highlight.FillTransparency = 1 -- Inicial, ajustado no update
	highlight.OutlineTransparency = 1 -- Inicial, ajustado no update
	highlight.Parent = target
	cfg.highlight = highlight

	table.insert(ModelESP.Objects, cfg)
end

--// ➖ Remove ESP individual
function ModelESP:Remove(target)
	for i = #ModelESP.Objects, 1, -1 do
		local obj = ModelESP.Objects[i]
		if obj.Target == target then
			for _, draw in ipairs({obj.tracerLine, obj.nameText, obj.distanceText}) do
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
		for _, draw in ipairs({obj.tracerLine, obj.nameText, obj.distanceText}) do
			if draw then pcall(draw.Remove, draw) end
		end
		if obj.highlight then pcall(obj.highlight.Destroy, obj.highlight) end
	end
	ModelESP.Objects = {}
end

--// 🎨 Alterna tema para arco-íris
function ModelESP:ToggleRainbowMode(enable)
	ModelESP.Theme.RainbowMode = enable
end

--// 🔁 Atualização a cada frame
RunService.RenderStepped:Connect(function(deltaTime)
	if not ModelESP.Enabled then return end
	local vs = camera.ViewportSize
	local time = tick()

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
			esp.tracerLine.Visible = false
			esp.nameText.Visible = false
			esp.distanceText.Visible = false
			if esp.highlight then esp.highlight.Enabled = false end
			continue
		end

		local distance = (camera.CFrame.Position - pos3D).Magnitude
		local visible = distance >= esp.MinDistance and distance <= esp.MaxDistance

		if not visible then
			esp.tracerLine.Visible = false
			esp.nameText.Visible = false
			esp.distanceText.Visible = false
			if esp.highlight then esp.highlight.Enabled = false end
			continue
		end

		local screenPos = Vector2.new(pos2D.X, pos2D.Y)
		local originPos = tracerOrigins[ModelESP.Settings.Tracer.Origin](vs)
		local currentColor = ModelESP.Theme.RainbowMode and getRainbowColor(time * ModelESP.Theme.PulseSpeed) or esp.Color

		-- Atualiza Tracer
		esp.tracerLine.Visible = visible and ModelESP.Settings.Tracer.Enabled
		if esp.tracerLine.Visible then
			esp.tracerLine.From = originPos
			esp.tracerLine.To = screenPos
			esp.tracerLine.Color = currentColor
			esp.tracerLine.Transparency = ModelESP.Settings.Opacity
		end

		-- Atualiza nome
		esp.nameText.Visible = visible and ModelESP.Settings.Name.Enabled
		if esp.nameText.Visible then
			esp.nameText.Position = screenPos - Vector2.new(0, 20) -- Posição ajustada
			esp.nameText.Text = esp.Name
			esp.nameText.Color = currentColor
			esp.nameText.Transparency = ModelESP.Settings.Opacity
		end

		-- Atualiza distância
		esp.distanceText.Visible = visible and ModelESP.Settings.Distance.Enabled
		if esp.distanceText.Visible then
			esp.distanceText.Position = screenPos + Vector2.new(0, 5) -- Posição ajustada
			esp.distanceText.Text = string.format("%.1fm", distance)
			esp.distanceText.Color = currentColor
			esp.distanceText.Transparency = ModelESP.Settings.Opacity
		end

		-- Atualiza Highlight
		if esp.highlight then
			local highlightVisible = ModelESP.Settings.Highlight.FillEnabled or ModelESP.Settings.Highlight.OutlineEnabled
			esp.highlight.Enabled = visible and highlightVisible
			if esp.highlight.Enabled then
				esp.highlight.FillColor = currentColor
				esp.highlight.OutlineColor = ModelESP.Theme.SecondaryColor
				esp.highlight.FillTransparency = ModelESP.Settings.Highlight.FillEnabled and ModelESP.Settings.FillTransparency or 1
				esp.highlight.OutlineTransparency = ModelESP.Settings.Highlight.OutlineEnabled and ModelESP.Settings.OutlineTransparency or 1
			end
		end
	end
end)

return ModelESP
