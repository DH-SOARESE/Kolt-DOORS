--// 📦 Library Kolt v1
--// 👤 Autor: DH_SOARES
--// 🎨 Estilo: Animações suaves, tipografia refinada, pouco poluição visual

--// 🔧 Serviços
local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService") -- Mantido para possíveis animações futuras

--// 🧠 Tabela principal da biblioteca
local ModelESP = {
    Objects = {},
    Enabled = true,
    Theme = {
        PrimaryColor = Color3.fromRGB(130, 200, 255),
        SecondaryColor = Color3.fromRGB(255, 255, 255),
        OutlineColor = Color3.fromRGB(0, 0, 0),
        RainbowMode = false,
        PulseSpeed = 2,
    }
}

--// 📦 Configuração Global ESP
local GlobalESPConfig = {
    UseGlobal = false,
    Tracer = nil,
    TracerOrigin = nil,
    ShowName = nil,
    ShowDistance = nil
}

--// 📍 Funções de configuração global
local SetGlobalEsp = {}

function SetGlobalEsp:EnableGlobal(state)
    GlobalESPConfig.UseGlobal = state
end

function SetGlobalEsp:Tracer(state)
    GlobalESPConfig.Tracer = state
    for _, esp in ipairs(ModelESP.Objects) do
        if esp.tracerLine then esp.tracerLine.Visible = state end
        esp.Tracer = state
    end
end

local tracerOrigins = {
    Top = function(vs) return Vector2.new(vs.X / 2, 0) end,
    Center = function(vs) return Vector2.new(vs.X / 2, vs.Y / 2) end,
    Bottom = function(vs) return Vector2.new(vs.X / 2, vs.Y) end,
    Left = function(vs) return Vector2.new(0, vs.Y / 2) end,
    Right = function(vs) return Vector2.new(vs.X, vs.Y / 2) end,
}

function SetGlobalEsp:TracerOrigin(origin)
    if tracerOrigins[origin] then
        GlobalESPConfig.TracerOrigin = origin
        for _, esp in ipairs(ModelESP.Objects) do
            esp.TracerOrigin = origin
        end
    end
end

function SetGlobalEsp:ShowName(state)
    GlobalESPConfig.ShowName = state
    for _, esp in ipairs(ModelESP.Objects) do
        if esp.nameText then esp.nameText.Visible = state end
        esp.ShowName = state
    end
end

function SetGlobalEsp:ShowDistance(state)
    GlobalESPConfig.ShowDistance = state
    for _, esp in ipairs(ModelESP.Objects) do
        if esp.distanceText then esp.distanceText.Visible = state end
        esp.ShowDistance = state
    end
end

--// 🌈 Função para cor arco-íris
local function getRainbowColor(t)
    local frequency = 0.5
    local r = math.sin(frequency * t + 0) * 127 + 128
    local g = math.sin(frequency * t + 2) * 127 + 128
    local b = math.sin(frequency * t + 4) * 127 + 128
    return Color3.fromRGB(r, g, b)
end

--// 📍 Calcula o centro visual do modelo
local function getModelCenter(model)
    local total, count = Vector3.zero, 0
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") and p.Transparency < 1 and p.CanCollide then
            total += p.Position
            count += 1
        end
    end
    return count > 0 and total / count or (model.PrimaryPart and model.PrimaryPart.Position or model:GetPivot().Position)
end

--// 🛠️ Cria objetos Drawing com propriedades
local function createDrawing(class, props)
    local obj = Drawing.new(class)
    for k, v in pairs(props) do obj[k] = v end
    return obj
end

--// ➕ Adiciona novo ESP
function ModelESP:Add(target, config)
    if not target or not target:IsA("Instance") then return end
    if not (target:IsA("Model") or target:IsA("BasePart")) then return end

    -- Remove highlights duplicados
    for _, obj in ipairs(target:GetChildren()) do
        if obj:IsA("Highlight") and obj.Name == "ESPHighlight" then
            obj:Destroy()
        end
    end

    -- Aplica global config
    if GlobalESPConfig.UseGlobal then
        config.Tracer = (GlobalESPConfig.Tracer ~= nil) and GlobalESPConfig.Tracer or config.Tracer
        config.TracerOrigin = (GlobalESPConfig.TracerOrigin ~= nil) and GlobalESPConfig.TracerOrigin or config.TracerOrigin
        config.ShowName = (GlobalESPConfig.ShowName ~= nil) and GlobalESPConfig.ShowName or config.ShowName
        config.ShowDistance = (GlobalESPConfig.ShowDistance ~= nil) and GlobalESPConfig.ShowDistance or config.ShowDistance
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
        Opacity = config.Opacity or 0.7,
    }

    cfg.tracerLine = cfg.Tracer and createDrawing("Line", {
        Thickness = 1.5,
        Color = cfg.Color,
        Transparency = cfg.Opacity,
        Visible = false
    }) or nil

    cfg.nameText = cfg.ShowName and createDrawing("Text", {
        Text = cfg.Name,
        Color = cfg.Color,
        Size = 14,
        Center = true,
        Outline = true,
        OutlineColor = ModelESP.Theme.OutlineColor,
        Font = Drawing.Fonts.Monospace,
        Transparency = cfg.Opacity,
        Visible = false
    }) or nil

    cfg.distanceText = cfg.ShowDistance and createDrawing("Text", {
        Color = cfg.Color,
        Size = 12,
        Center = true,
        Outline = true,
        OutlineColor = ModelESP.Theme.OutlineColor,
        Font = Drawing.Fonts.Monospace,
        Transparency = cfg.Opacity,
        Visible = false
    }) or nil

    -- Highlight
    if cfg.HighlightFill or cfg.HighlightOutline then
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESPHighlight"
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillColor = cfg.Color
        highlight.OutlineColor = ModelESP.Theme.SecondaryColor
        highlight.FillTransparency = cfg.HighlightFill and 0.85 or 1
        highlight.OutlineTransparency = cfg.HighlightOutline and 0.65 or 1
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

--// 🎨 Alterna tema Rainbow
function ModelESP:ToggleRainbowMode(enable)
    ModelESP.Theme.RainbowMode = enable
end

--// 🔁 Atualização por frame
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

        if esp.tracerLine then
            esp.tracerLine.From = originPos
            esp.tracerLine.To = screenPos
            esp.tracerLine.Color = currentColor
        end

        if esp.nameText then
            esp.nameText.Position = screenPos - Vector2.new(0, 20)
            esp.nameText.Text = esp.Name
            esp.nameText.Color = currentColor
        end

        if esp.distanceText then
            esp.distanceText.Position = screenPos + Vector2.new(0, 5)
            esp.distanceText.Text = string.format("%.1fm", distance)
            esp.distanceText.Color = currentColor
        end

        if esp.highlight then
            esp.highlight.FillColor = currentColor
            esp.highlight.OutlineColor = ModelESP.Theme.OutlineColor
        end
    end
end)

return ModelESP
