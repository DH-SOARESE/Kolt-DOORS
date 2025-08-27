--// 📦 Library Kolt v1.1
--// 👤 Autor: DH_SOARES
--// 🎨 Estilo: Minimalista, eficiente e responsivo

local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera

local ModelESP = {
    Objects = {},
    Enabled = true,

    Theme = {
        PrimaryColor = Color3.fromRGB(130, 200, 255),
        SecondaryColor = Color3.fromRGB(255, 255, 255),
        OutlineColor = Color3.fromRGB(0, 0, 0),
    },

    GlobalSettings = {
        -- Tracer
        TracerOrigin = "Bottom",  -- Top/Center/Bottom/Left/Right
        ShowTracer = true,
        TracerThickness = 1.5,
        TracerTransparency = 0.9,

        -- Highlight
        ShowHighlightFill = true,
        ShowHighlightOutline = true,
        AlwaysOnTop = true,

        -- Texto
        ShowName = true,
        ShowDistance = true,
        TextSizeName = 14,
        TextSizeDistance = 12,

        -- Extras
        RainbowMode = false,
        MaxRenderDistance = 3000, -- limite global
    }
}

--// 🌈 Cor arco-íris
local function getRainbowColor(t)
    local f = 0.5
    return Color3.fromRGB(
        math.sin(f*t+0)*127+128,
        math.sin(f*t+2)*127+128,
        math.sin(f*t+4)*127+128
    )
end

--// 📍 Tracer Origins
local tracerOrigins = {
    Top = function(vs) return Vector2.new(vs.X/2, 0) end,
    Center = function(vs) return Vector2.new(vs.X/2, vs.Y/2) end,
    Bottom = function(vs) return Vector2.new(vs.X/2, vs.Y) end,
    Left = function(vs) return Vector2.new(0, vs.Y/2) end,
    Right = function(vs) return Vector2.new(vs.X, vs.Y/2) end,
}

--// 📍 Centro do modelo
local function getModelCenter(model)
    local total, count = Vector3.zero, 0
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") and p.Transparency < 1 then
            total += p.Position
            count += 1
        end
    end
    return count > 0 and total/count or (model.PrimaryPart and model.PrimaryPart.Position or model:GetPivot().Position)
end

--// 🛠️ Cria Drawing
local function createDrawing(class, props)
    local obj = Drawing.new(class)
    for k,v in pairs(props) do obj[k]=v end
    return obj
end

--// 🔧 Aplica configs no Highlight
local function applyHighlightSettings(highlight, cfg, global)
    highlight.DepthMode = global.AlwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    highlight.FillColor = cfg.Color
    highlight.OutlineColor = ModelESP.Theme.SecondaryColor
    highlight.FillTransparency = global.ShowHighlightFill and 0.85 or 1
    highlight.OutlineTransparency = global.ShowHighlightOutline and 0.65 or 1
end

--// ➕ Adiciona ESP
function ModelESP:Add(target, config)
    if not target or not target:IsA("Instance") then return end
    if not (target:IsA("Model") or target:IsA("BasePart")) then return end

    -- Remove highlight antigo
    for _, obj in ipairs(target:GetChildren()) do
        if obj:IsA("Highlight") and obj.Name == "ESPHighlight" then obj:Destroy() end
    end

    local cfg = {
        Target = target,
        Name = config.Name or target.Name,
        Color = config.Color or self.Theme.PrimaryColor,
        MinDistance = config.MinDistance or 0,
        MaxDistance = config.MaxDistance or math.huge,
        Opacity = config.Opacity or 0.7,
    }

    -- Criando Drawings
    cfg.tracerLine = createDrawing("Line", {Thickness=ModelESP.GlobalSettings.TracerThickness, Color=cfg.Color, Transparency=ModelESP.GlobalSettings.TracerTransparency, Visible=false})
    cfg.nameText = createDrawing("Text", {Text=cfg.Name, Color=cfg.Color, Size=ModelESP.GlobalSettings.TextSizeName, Center=true, Outline=true, OutlineColor=self.Theme.OutlineColor, Font=Drawing.Fonts.Monospace, Transparency=cfg.Opacity, Visible=false})
    cfg.distanceText = createDrawing("Text", {Text="", Color=cfg.Color, Size=ModelESP.GlobalSettings.TextSizeDistance, Center=true, Outline=true, OutlineColor=self.Theme.OutlineColor, Font=Drawing.Fonts.Monospace, Transparency=cfg.Opacity, Visible=false})

    -- Highlight
    if self.GlobalSettings.ShowHighlightFill or self.GlobalSettings.ShowHighlightOutline then
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESPHighlight"
        applyHighlightSettings(highlight, cfg, self.GlobalSettings)
        highlight.Parent = target
        cfg.highlight = highlight
    end

    table.insert(self.Objects, cfg)
end

--// ➕ Adiciona Entities2D
function ModelESP:AddEntities2D(target, config)
    if not target or not target:IsA("Model") then return end

    -- Cria humanoid falso se não existir
    if not target:FindFirstChildOfClass("Humanoid") then
        local humanoid = Instance.new("Humanoid")
        humanoid.Name = "FakeHumanoid"
        humanoid.Health = 0
        humanoid.MaxHealth = 0
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        humanoid.Parent = target
    end

    -- Torna todas partes quase invisíveis
    for _, obj in ipairs(target:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.Transparency = 0.99
            obj.CanCollide = false
        end
    end

    -- Adiciona ESP normal
    self:Add(target, {
        Name = config.Name or target.Name,
        Color = config.Color or self.Theme.PrimaryColor,
    })
end

--// ➖ Remove ESP individual
function ModelESP:Remove(target)
    for i=#self.Objects,1,-1 do
        local obj = self.Objects[i]
        if obj.Target == target then
            for _, draw in ipairs({obj.tracerLine,obj.nameText,obj.distanceText}) do if draw then pcall(draw.Remove,draw) end end
            if obj.highlight then pcall(obj.highlight.Destroy,obj.highlight) end
            table.remove(self.Objects,i)
            break
        end
    end
end

--// 🧹 Limpa todos ESP
function ModelESP:Clear()
    for _, obj in ipairs(self.Objects) do
        for _, draw in ipairs({obj.tracerLine,obj.nameText,obj.distanceText}) do if draw then pcall(draw.Remove,draw) end end
        if obj.highlight then pcall(obj.highlight.Destroy,obj.highlight) end
    end
    self.Objects = {}
end

--// 🌐 Alterar config global
function ModelESP:SetGlobal(option, value)
    if self.GlobalSettings[option] ~= nil then
        self.GlobalSettings[option] = value
    end
end

--// 🔁 Atualização por frame
RunService.RenderStepped:Connect(function()
    if not ModelESP.Enabled then return end
    local vs = camera.ViewportSize
    local time = tick()

    for i=#ModelESP.Objects,1,-1 do
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
        if not success or pos2D.Z <= 0 then
            for _, draw in ipairs({esp.tracerLine,esp.nameText,esp.distanceText}) do if draw then draw.Visible=false end end
            if esp.highlight then esp.highlight.Enabled=false end
            continue
        end

        local distance = (camera.CFrame.Position - pos3D).Magnitude
        local visible = distance>=esp.MinDistance and distance<=esp.MaxDistance and distance<=ModelESP.GlobalSettings.MaxRenderDistance

        local screenPos = Vector2.new(pos2D.X,pos2D.Y)
        local originPos = tracerOrigins[ModelESP.GlobalSettings.TracerOrigin](vs) -- 🔑 sempre depende do global
        local color = ModelESP.GlobalSettings.RainbowMode and getRainbowColor(time) or esp.Color

        -- Tracer
        if esp.tracerLine then
            esp.tracerLine.Visible = ModelESP.GlobalSettings.ShowTracer and visible
            esp.tracerLine.Thickness = ModelESP.GlobalSettings.TracerThickness
            esp.tracerLine.Transparency = ModelESP.GlobalSettings.TracerTransparency
            esp.tracerLine.From = originPos
            esp.tracerLine.To = screenPos
            esp.tracerLine.Color = color
        end

        -- Nome
        if esp.nameText then
            esp.nameText.Visible = ModelESP.GlobalSettings.ShowName and visible
            esp.nameText.Size = ModelESP.GlobalSettings.TextSizeName
            esp.nameText.Position = screenPos - Vector2.new(0,20)
            esp.nameText.Text = esp.Name
            esp.nameText.Color = color
        end

        -- Distância
        if esp.distanceText then
            esp.distanceText.Visible = ModelESP.GlobalSettings.ShowDistance and visible
            esp.distanceText.Size = ModelESP.GlobalSettings.TextSizeDistance
            esp.distanceText.Position = screenPos + Vector2.new(0,5)
            esp.distanceText.Text = string.format("%.1fm",distance)
            esp.distanceText.Color = color
        end

        -- Highlight
        if esp.highlight then
            esp.highlight.Enabled = (ModelESP.GlobalSettings.ShowHighlightFill or ModelESP.GlobalSettings.ShowHighlightOutline) and visible
            applyHighlightSettings(esp.highlight, esp, ModelESP.GlobalSettings)
        end
    end
end)

return ModelESP
