--// 📦 Library Kolt V1.3-- (Tracer & ESP melhorado, origin agrupado, referências de tela)
--// 👤 Autor: DH_SOARES
--// 🎨 Estilo: Minimalista, eficiente e responsivo, orientado a endereço de objetos

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
        TracerOrigin = "Bottom", -- Origem global para todos
        TracerStack = true,      -- Agrupa origem dos tracers juntos
        TracerScreenRefs = true, -- Usa múltiplas referências do alvo (box corners) para render
        ShowTracer = true,
        ShowHighlightFill = true,
        ShowHighlightOutline = true,
        ShowName = true,
        ShowDistance = true,
        ShowBox = true,
        RainbowMode = false,
        MaxDistance = math.huge,
        MinDistance = 0,
        Opacity = 0.8,
        LineThickness = 1.5,
        BoxThickness = 1.5,
        BoxTransparency = 0.5,
        HighlightOutlineTransparency = 0.65,
        HighlightFillTransparency = 0.85,
        FontSize = 14,
        AutoRemoveInvalid = true,
        BoxPadding = 5,
        TracerPadding = 0, -- Distância dos tracers entre si (0 = stack total)
        BoxType = "Dynamic", -- Dynamic = usa bounds, Fixed = tamanho fixo
        ShowTeamColor = false, -- Exemplo de config útil
    }
}

--// 🌈 Cor arco-íris
local function getRainbowColor(t)
    local f = 2
    return Color3.fromRGB(
        math.sin(f*t+0)*127+128,
        math.sin(f*t+2)*127+128,
        math.sin(f*t+4)*127+128
    )
end

--// 📍 Tracer Origins
local tracerOrigins = {
    Bottom = function(vs) return Vector2.new(vs.X/2, vs.Y) end,
    Top = function(vs) return Vector2.new(vs.X/2, 0) end,
    Center = function(vs) return Vector2.new(vs.X/2, vs.Y/2) end,
    Left = function(vs) return Vector2.new(0, vs.Y/2) end,
    Right = function(vs) return Vector2.new(vs.X, vs.Y/2) end,
}

--// 📍 Centro e bounds do modelo
local function getModelScreenBounds(model)
    local min, max
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") and part.Transparency < 1 then
            local cf = part.CFrame
            local size = part.Size/2
            for _, off in ipairs({
                Vector3.new(-size.X,-size.Y,-size.Z),
                Vector3.new(size.X,-size.Y,-size.Z),
                Vector3.new(-size.X,size.Y,-size.Z),
                Vector3.new(size.X,size.Y,-size.Z),
                Vector3.new(-size.X,-size.Y,size.Z),
                Vector3.new(size.X,-size.Y,size.Z),
                Vector3.new(-size.X,size.Y,size.Z),
                Vector3.new(size.X,size.Y,size.Z)
            }) do
                local corner = (cf.Position + (cf.Rotation * off))
                local _, screen = pcall(function() return camera:WorldToViewportPoint(corner) end)
                if screen and screen.Z > 0 then
                    local v2 = Vector2.new(screen.X, screen.Y)
                    min = min and Vector2.new(math.min(min.X,v2.X), math.min(min.Y,v2.Y)) or v2
                    max = max and Vector2.new(math.max(max.X,v2.X), math.max(max.Y,v2.Y)) or v2
                end
            end
        end
    end
    return min,max
end

--// 🛠️ Cria Drawing
local function createDrawing(class, props)
    local obj = Drawing.new(class)
    for k,v in pairs(props) do obj[k]=v end
    return obj
end

--// ➕ Adiciona ESP
function ModelESP:Add(target, config)
    if not target or not target:IsA("Instance") then return end
    if not (target:IsA("Model") or target:IsA("BasePart")) then return end

    for _, obj in ipairs(target:GetChildren()) do
        if obj:IsA("Highlight") and obj.Name == "ESPHighlight" then obj:Destroy() end
    end

    local cfg = {
        Target = target,
        Name = config and config.Name or target.Name,
        Color = config and config.Color or self.Theme.PrimaryColor,
        HighlightOutlineColor = config and config.HighlightOutlineColor or self.Theme.OutlineColor,
        HighlightOutlineTransparency = config and config.HighlightOutlineTransparency or self.GlobalSettings.HighlightOutlineTransparency,
        FilledTransparency = config and config.FilledTransparency or self.GlobalSettings.HighlightFillTransparency,
        BoxColor = config and config.BoxColor or nil,
        TracerColor = config and config.TracerColor or nil,
    }

    -- Tracer: sempre cria, pode desenhar múltiplos
    cfg.tracerLines = {}
    for i=1, (self.GlobalSettings.TracerScreenRefs and 4 or 1) do
        table.insert(cfg.tracerLines, createDrawing("Line", {
            Thickness = self.GlobalSettings.LineThickness,
            Color = cfg.TracerColor or cfg.Color,
            Transparency = self.GlobalSettings.Opacity,
            Visible = false
        }))
    end

    cfg.nameText = createDrawing("Text", {
        Text = cfg.Name,
        Color = cfg.Color,
        Size = self.GlobalSettings.FontSize,
        Center = true,
        Outline = true,
        OutlineColor = self.Theme.OutlineColor,
        Font = Drawing.Fonts.Monospace,
        Transparency = self.GlobalSettings.Opacity,
        Visible = false
    })
    cfg.distanceText = createDrawing("Text", {
        Text = "",
        Color = cfg.Color,
        Size = self.GlobalSettings.FontSize-2,
        Center = true,
        Outline = true,
        OutlineColor = self.Theme.OutlineColor,
        Font = Drawing.Fonts.Monospace,
        Transparency = self.GlobalSettings.Opacity,
        Visible = false
    })

    -- Highlight
    if self.GlobalSettings.ShowHighlightFill or self.GlobalSettings.ShowHighlightOutline then
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESPHighlight"
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillColor = cfg.Color
        highlight.OutlineColor = cfg.HighlightOutlineColor
        highlight.FillTransparency = self.GlobalSettings.ShowHighlightFill and cfg.FilledTransparency or 1
        highlight.OutlineTransparency = self.GlobalSettings.ShowHighlightOutline and cfg.HighlightOutlineTransparency or 1
        highlight.Parent = target
        cfg.highlight = highlight
    end

    -- Box ESP
    if self.GlobalSettings.ShowBox then
        cfg.box = createDrawing("Square", {
            Thickness = self.GlobalSettings.BoxThickness,
            Color = cfg.BoxColor or cfg.Color,
            Transparency = self.GlobalSettings.BoxTransparency,
            Visible = false
        })
    end

    table.insert(self.Objects, cfg)
end

--// ➖ Remove ESP individual
function ModelESP:Remove(target)
    for i=#self.Objects,1,-1 do
        local obj = self.Objects[i]
        if obj.Target == target then
            for _, draw in ipairs(obj.tracerLines or {}) do if draw then pcall(draw.Remove,draw) end end
            for _, draw in ipairs({obj.nameText,obj.distanceText,obj.box}) do if draw then pcall(draw.Remove,draw) end end
            if obj.highlight then pcall(obj.highlight.Destroy,obj.highlight) end
            table.remove(self.Objects,i)
            break
        end
    end
end

function ModelESP:Clear()
    for _, obj in ipairs(self.Objects) do
        for _, draw in ipairs(obj.tracerLines or {}) do if draw then pcall(draw.Remove,draw) end end
        for _, draw in ipairs({obj.nameText,obj.distanceText,obj.box}) do if draw then pcall(draw.Remove,draw) end end
        if obj.highlight then pcall(obj.highlight.Destroy,obj.highlight) end
    end
    self.Objects = {}
end

function ModelESP:UpdateGlobalSettings()
    for _, esp in ipairs(self.Objects) do
        for _, line in ipairs(esp.tracerLines or {}) do line.Thickness = self.GlobalSettings.LineThickness end
        if esp.nameText then esp.nameText.Size = self.GlobalSettings.FontSize end
        if esp.distanceText then esp.distanceText.Size = self.GlobalSettings.FontSize-2 end
        if esp.box then esp.box.Thickness = self.GlobalSettings.BoxThickness esp.box.Transparency = self.GlobalSettings.BoxTransparency end
        if esp.highlight then
            esp.highlight.FillTransparency = self.GlobalSettings.ShowHighlightFill and esp.FilledTransparency or 1
            esp.highlight.OutlineTransparency = self.GlobalSettings.ShowHighlightOutline and esp.HighlightOutlineTransparency or 1
        end
    end
end

--// Configs Globais (APIs)
function ModelESP:SetGlobalTracerOrigin(origin)
    if tracerOrigins[origin] then self.GlobalSettings.TracerOrigin = origin end
end
function ModelESP:SetGlobalTracerStack(enable)
    self.GlobalSettings.TracerStack = enable
end
function ModelESP:SetGlobalTracerScreenRefs(enable)
    self.GlobalSettings.TracerScreenRefs = enable
end
function ModelESP:SetGlobalESPType(typeName, enabled)
    self.GlobalSettings[typeName] = enabled
    self:UpdateGlobalSettings()
end
function ModelESP:SetGlobalRainbow(enable)
    self.GlobalSettings.RainbowMode = enable
end
function ModelESP:SetGlobalOpacity(value)
    self.GlobalSettings.Opacity = math.clamp(value,0,1)
    self:UpdateGlobalSettings()
end
function ModelESP:SetGlobalFontSize(size)
    self.GlobalSettings.FontSize = math.max(10,size)
    self:UpdateGlobalSettings()
end
function ModelESP:SetGlobalLineThickness(thick)
    self.GlobalSettings.LineThickness = math.max(1,thick)
    self:UpdateGlobalSettings()
end
function ModelESP:SetGlobalBoxThickness(thick)
    self.GlobalSettings.BoxThickness = math.max(1,thick)
    self:UpdateGlobalSettings()
end
function ModelESP:SetGlobalBoxTransparency(value)
    self.GlobalSettings.BoxTransparency = math.clamp(value, 0, 1)
    self:UpdateGlobalSettings()
end
function ModelESP:SetGlobalHighlightOutlineTransparency(value)
    self.GlobalSettings.HighlightOutlineTransparency = math.clamp(value, 0, 1)
    self:UpdateGlobalSettings()
end
function ModelESP:SetGlobalHighlightFillTransparency(value)
    self.GlobalSettings.HighlightFillTransparency = math.clamp(value, 0, 1)
    self:UpdateGlobalSettings()
end

-- 🔁 Atualização por frame
RunService.RenderStepped:Connect(function()
    if not ModelESP.Enabled then return end
    local vs = camera.ViewportSize
    local time = tick()
    local tracerOriginPos = tracerOrigins[ModelESP.GlobalSettings.TracerOrigin](vs)

    -- Para TracerStack, calcula origem agrupada
    local stackedOrigins = {}
    if ModelESP.GlobalSettings.TracerStack then
        local stackCount = #ModelESP.Objects
        local base = tracerOriginPos
        local pad = ModelESP.GlobalSettings.TracerPadding
        for i=1,stackCount do
            if tracerOriginPos.Y == 0 or tracerOriginPos.Y == vs.Y then -- vertical stack
                stackedOrigins[i] = base + Vector2.new((i-((stackCount+1)/2))*pad, 0)
            else
                stackedOrigins[i] = base + Vector2.new(0,(i-((stackCount+1)/2))*pad)
            end
        end
    end

    for i=#ModelESP.Objects,1,-1 do
        local esp = ModelESP.Objects[i]
        local target = esp.Target
        if not target or not target.Parent then
            if ModelESP.GlobalSettings.AutoRemoveInvalid then
                ModelESP:Remove(target)
            end
            continue
        end

        local min,max = target:IsA("Model") and getModelScreenBounds(target) or nil,nil
        local pos3D = nil
        if target:IsA("Model") then
            local center = target:GetPivot().Position
            pos3D = center
        elseif target:IsA("BasePart") then
            pos3D = target.Position
        end

        if not pos3D then continue end
        local success, pos2D = pcall(function() return camera:WorldToViewportPoint(pos3D) end)
        if not success or pos2D.Z <= 0 then
            for _, draw in ipairs(esp.tracerLines or {}) do draw.Visible=false end
            for _, draw in ipairs({esp.nameText,esp.distanceText,esp.box}) do if draw then draw.Visible=false end end
            if esp.highlight then esp.highlight.Enabled=false end
            continue
        end

        local distance = (camera.CFrame.Position - pos3D).Magnitude
        local visible = distance >= ModelESP.GlobalSettings.MinDistance and distance <= ModelESP.GlobalSettings.MaxDistance
        local color = ModelESP.GlobalSettings.RainbowMode and getRainbowColor(time) or esp.Color

        -- Tracer
        if esp.tracerLines then
            local refs = {}
            if ModelESP.GlobalSettings.TracerScreenRefs and min and max then
                table.insert(refs, min)
                table.insert(refs, Vector2.new(max.X,min.Y))
                table.insert(refs, Vector2.new(min.X,max.Y))
                table.insert(refs, max)
            else
                table.insert(refs, Vector2.new(pos2D.X,pos2D.Y))
            end
            for idx, line in ipairs(esp.tracerLines) do
                line.Visible = ModelESP.GlobalSettings.ShowTracer and visible
                line.Color = esp.TracerColor or color
                line.From = ModelESP.GlobalSettings.TracerStack and stackedOrigins[i] or tracerOriginPos
                line.To = refs[idx] or refs[1]
            end
        end

        -- Name
        if esp.nameText then
            esp.nameText.Visible = ModelESP.GlobalSettings.ShowName and visible
            esp.nameText.Position = Vector2.new(pos2D.X,pos2D.Y) - Vector2.new(0,20)
            esp.nameText.Text = esp.Name
            esp.nameText.Color = color
        end
        -- Distance
        if esp.distanceText then
            esp.distanceText.Visible = ModelESP.GlobalSettings.ShowDistance and visible
            esp.distanceText.Position = Vector2.new(pos2D.X,pos2D.Y) + Vector2.new(0,5)
            esp.distanceText.Text = string.format("%.1fm",distance)
            esp.distanceText.Color = color
        end
        -- Highlight
        if esp.highlight then
            esp.highlight.Enabled = (ModelESP.GlobalSettings.ShowHighlightFill or ModelESP.GlobalSettings.ShowHighlightOutline) and visible
            esp.highlight.FillColor = color
            esp.highlight.OutlineColor = esp.HighlightOutlineColor
            esp.highlight.FillTransparency = ModelESP.GlobalSettings.ShowHighlightFill and esp.FilledTransparency or 1
            esp.highlight.OutlineTransparency = ModelESP.GlobalSettings.ShowHighlightOutline and esp.HighlightOutlineTransparency or 1
        end
        -- Box ESP
        if esp.box and min and max then
            esp.box.Visible = ModelESP.GlobalSettings.ShowBox and visible
            local size = max-min + Vector2.new(ModelESP.GlobalSettings.BoxPadding*2,ModelESP.GlobalSettings.BoxPadding*2)
            esp.box.Size = ModelESP.GlobalSettings.BoxType=="Fixed" and Vector2.new(50,50) or size
            esp.box.Position = min - Vector2.new(ModelESP.GlobalSettings.BoxPadding,ModelESP.GlobalSettings.BoxPadding)
            esp.box.Color = esp.BoxColor or color
        end
    end
end)

return ModelESP
------------------------[END]-------------------------------
