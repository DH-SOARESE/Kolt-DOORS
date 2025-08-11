--// 📦 Model ESP Library 
--// 👤 Autor: Kolt
--// 🎨 Estilo: Focado em clareza, cores suaves e pouca poluição visual

--// 🔧 Serviços
local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

--// 🧠 Tabela principal da biblioteca
local ModelESP = {
	Objects = {},
	Enabled = true,
	Theme = {
		PrimaryColor = Color3.fromRGB(130, 200, 255), -- Azul claro suave
		SecondaryColor = Color3.fromRGB(255, 255, 255), -- Branco
		OutlineColor = Color3.fromRGB(0, 0, 0), -- Contorno preto para legibilidade
		RainbowMode = false,
		PulseSpeed = 2,
	}
}

--// 🌈 Função para gerar cor arco-íris (mantida, mas com cores mais suaves)
local function getRainbowColor(t)
	local frequency = 0.5
	local r = math.sin(frequency * t + 0) * 127 + 128
	local g = math.sin(frequency * t + 2) * 127 + 128
	local b = math.sin(frequency * t + 4) * 127 + 128
	return Color3.fromRGB(r, g, b)
end

--// 📍 Posições de Origem para o Tracer (mantida)
local tracerOrigins = {
	Top = function(vs) return Vector2.new(vs.X / 2, 0) end,
	Center = function(vs) return Vector2.new(vs.X / 2, vs.Y / 2) end,
	Bottom = function(vs) return Vector2.new(vs.X / 2, vs.Y) end,
	Left = function(vs) return Vector2.new(0, vs.Y / 2) end,
	Right = function(vs) return Vector2.new(vs.X, vs.Y / 2) end,
}

--// 📍 Calcula o centro visual do modelo (mantida)
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

--// 🛠️ Cria objetos Drawing com propriedades estilizadas (mantida)
local function createDrawing(class, props)
	local obj = Drawing.new(class)
	for k, v in pairs(props) do obj[k] = v end
	return obj
end

--// ➕ Adiciona novo ESP ao sistema
function ModelESP:Add(target, config)
	if not target or not target:IsA("Instance") then return end
	if not (target:IsA("Model") or target:IsA("BasePart")) then return end

	-- Remove Highlights anteriores
	for _, obj in ipairs(target:GetChildren()) do
		if obj:IsA("Highlight") and obj.Name:sub(1, 12) == "ESPHighlight" then
			obj:Destroy()
		end
	end

	local cfg = {
		Target = target,
		Color = config.Color or ModelESP.Theme.PrimaryColor,
		Name = config.Name or target.Name,
		ShowName = config.ShowName ~= false,
		ShowDistance = config.ShowDistance ~= false,
		Tracer = config.Tracer ~= false,
		HighlightFill = config.HighlightFill ~= false,
		HighlightOutline = config.HighlightOutline ~= false,
		TracerOrigin = tracerOrigins[config.TracerOrigin] and config.TracerOrigin or "Bottom",
		MinDistance = config.MinDistance or 0,
		MaxDistance = config.MaxDistance or math.huge,
		Opacity = config.Opacity or 0.6, -- Opacidade padrão ajustada
	}

	-- Os elementos de texto e linha devem ser criados em uma ordem que simule o ZIndex desejado.
	-- Vamos criar primeiro o Highlight (se existir), que é um objeto 3D e se comporta de forma diferente,
	-- e depois os Drawing, que se sobrepõem na ordem de criação.

	-- Highlight com estilo sutil
	if cfg.HighlightFill or cfg.HighlightOutline then
		local highlight = Instance.new("Highlight")
		highlight.Name = "ESPHighlight"
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.FillColor = cfg.Color
		highlight.OutlineColor = ModelESP.Theme.SecondaryColor
		highlight.FillTransparency = cfg.HighlightFill and 0.8 or 1 -- Opacidade do preenchimento aumentada
		highlight.OutlineTransparency = cfg.HighlightOutline and 0.6 or 1 -- Opacidade do contorno aumentada
		highlight.Parent = target
		cfg.highlight = highlight
	end

	-- Desenhos ESP com estilo limpo
	-- O tracer é desenhado primeiro (camada mais baixa) para que o texto possa ficar por cima.
	cfg.tracerLine = cfg.Tracer and createDrawing("Line", {
		Thickness = 2, -- Espessura reduzida
		Color = cfg.Color,
		Transparency = cfg.Opacity,
		Visible = false
	}) or nil

	cfg.nameText = cfg.ShowName and createDrawing("Text", {
		Text = cfg.Name,
		Color = cfg.Color,
		Size = 16, -- Tamanho reduzido
		Center = true,
		Outline = true,
		OutlineColor = ModelESP.Theme.OutlineColor, -- Contorno preto
		Font = Drawing.Fonts.Monospace,
		Transparency = cfg.Opacity,
		Visible = false
	}) or nil

	cfg.distanceText = cfg.ShowDistance and createDrawing("Text", {
		Color = cfg.Color,
		Size = 14, -- Tamanho reduzido
		Center = true,
		Outline = true,
		OutlineColor = ModelESP.Theme.OutlineColor, -- Contorno preto
		Font = Drawing.Fonts.Monospace,
		Transparency = cfg.Opacity,
		Visible = false
	}) or nil

	table.insert(ModelESP.Objects, cfg)
end

--// ➖ Remove ESP individual (mantida)
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

--// 🧹 Remove todos os ESPs (mantida)
function ModelESP:Clear()
	for _, obj in ipairs(ModelESP.Objects) do
		for _, draw in ipairs({obj.tracerLine, obj.nameText, obj.distanceText}) do
			if draw then pcall(draw.Remove, draw) end
		end
		if obj.highlight then pcall(obj.highlight.Destroy, obj.highlight) end
	end
	ModelESP.Objects = {}
end

--// 🎨 Alterna tema para arco-íris (mantida)
function ModelESP:ToggleRainbowMode(enable)
	ModelESP.Theme.RainbowMode = enable
end

--// 🔁 Atualização a cada frame
RunService.RenderStepped:Connect(function(deltaTime)
	if not ModelESP.Enabled or not localPlayer or not localPlayer.Character then return end
	local vs = camera.ViewportSize
	local time = tick()

	for i = #ModelESP.Objects, 1, -1 do
		local esp = ModelESP.Objects[i]
		local target = esp.Target
		if not target or not target.Parent or (target:IsA("Model") and target.PrimaryPart == nil) then
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
			for _, draw in ipairs({esp.tracerLine, esp.nameText, esp.distanceText}) do
				if draw then draw.Visible = false end
			end
			if esp.highlight then esp.highlight.Enabled = false end
			continue
		end

		local distance = (camera.CFrame.Position - pos3D).Magnitude
		local visible = distance >= esp.MinDistance and distance <= esp.MaxDistance

		for _, draw in ipairs({esp.tracerLine, esp.nameText, esp.distanceText}) do
			if draw then draw.Visible = visible end
		end

		if esp.highlight then
			esp.highlight.Enabled = visible
		end

		if not visible then continue end

		local screenPos = Vector2.new(pos2D.X, pos2D.Y)
		local originPos = tracerOrigins[esp.TracerOrigin](vs)
		local currentColor = ModelESP.Theme.RainbowMode and getRainbowColor(time) or esp.Color
		
		-- Calcular a direção e o deslocamento para o tracer e o texto
		local direction = (screenPos - originPos).Unit
		
		-- Tamanhos dos textos e espaçamento para evitar sobreposição
		local nameTextSize = 16
		local distanceTextSize = 14
		local textSpacing = 2
		local tracerOffset = 30 -- Distância que o tracer para antes do texto
		
		local textGroupSize = nameTextSize + distanceTextSize + textSpacing
		
		-- Posição do texto
		local textCenterPos = screenPos - (direction * (textGroupSize / 2 + tracerOffset))
		
		-- Posições individuais dos textos, centralizados como um grupo
		local namePos = textCenterPos - Vector2.new(0, nameTextSize / 2)
		local distancePos = textCenterPos + Vector2.new(0, distanceTextSize / 2)
		
		-- Posição final do tracer
		local tracerEndPoint = screenPos - (direction * tracerOffset)
		
		-- Atualiza Tracer
		if esp.tracerLine then
			esp.tracerLine.From = originPos
			esp.tracerLine.To = tracerEndPoint
			esp.tracerLine.Color = currentColor
		end

		-- Atualiza nome
		if esp.nameText then
			esp.nameText.Position = namePos
			esp.nameText.Text = esp.Name
			esp.nameText.Color = currentColor
		end

		-- Atualiza distância
		if esp.distanceText then
			esp.distanceText.Position = distancePos
			esp.distanceText.Text = string.format("%.1fm", distance)
			esp.distanceText.Color = currentColor
		end

		-- Atualiza Highlight
		if esp.highlight then
			esp.highlight.FillColor = currentColor
			esp.highlight.OutlineColor = ModelESP.Theme.OutlineColor
		end
	end
end)

return ModelESP
