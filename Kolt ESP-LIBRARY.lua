--// 📦 Library Kolt V1.1--
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
        TracerOrigin = "Bottom",
        ShowTracer = true,
        ShowHighlightFill = true,
        ShowHighlightOutline = true,
        ShowName = true,
        ShowDistance = true,
        ShowBox = true,       -- Novo
        ShowSkeleton = false, -- Novo
        RainbowMode = false,
        MaxDistance = math.huge,
        MinDistance = 0,
        Opacity = 0.8,
        LineThickness = 1.5,
        BoxThickness = 1.5,      -- Novo
        SkeletonThickness = 1.2, -- Novo
        BoxTransparency = 0.5,   -- Novo
        FontSize = 14,
        AutoRemoveInvalid = true,
        HighlightFillTransparency = 0.85,
        HighlightOutlineTransparency = 0.65,
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
        OutlineColor = config and config.OutlineColor or self.Theme.OutlineColor,
        HighlightFillTransparency = config and config.HighlightFillTransparency or self.GlobalSettings.HighlightFillTransparency,
        HighlightOutlineTransparency = config and config.HighlightOutlineTransparency or self.GlobalSettings.HighlightOutlineTransparency,
        ShowTracer = config and config.ShowTracer ~= nil and config.ShowTracer or self.GlobalSettings.ShowTracer,
        ShowName = config and config.ShowName ~= nil and config.ShowName or self.GlobalSettings.ShowName,
        ShowDistance = config and config.ShowDistance ~= nil and config.ShowDistance or self.GlobalSettings.ShowDistance,
        ShowBox = config and config.ShowBox ~= nil and config.ShowBox or self.GlobalSettings.ShowBox,
        ShowSkeleton = config and config.ShowSkeleton ~= nil and config.ShowSkeleton or self.GlobalSettings.ShowSkeleton,
        ShowHighlightFill = config and config.ShowHighlightFill ~= nil and config.ShowHighlightFill or self.GlobalSettings.ShowHighlightFill,
        ShowHighlightOutline = config and config.ShowHighlightOutline ~= nil and config.ShowHighlightOutline or self.GlobalSettings.ShowHighlightOutline,
        Opacity = config and config.Opacity or self.GlobalSettings.Opacity,
        LineThickness = config and config.LineThickness or self.GlobalSettings.LineThickness,
        BoxThickness = config and config.BoxThickness or self.GlobalSettings.BoxThickness,
        SkeletonThickness = config and config.SkeletonThickness or self.GlobalSettings.SkeletonThickness,
        BoxTransparency = config and config.BoxTransparency or self.GlobalSettings.BoxTransparency,
        FontSize = config and config.FontSize or self.GlobalSettings.FontSize,
        MaxDistance = config and config.MaxDistance or self.GlobalSettings.MaxDistance,
        MinDistance = config and config.MinDistance or self.GlobalSettings.MinDistance,
    }

    -- Drawings básicos
    cfg.tracerLine = createDrawing("Line", {
        Thickness = cfg.LineThickness,
        Color = cfg.Color,
        Transparency = cfg.Opacity,
        Visible = false
    })
    cfg.nameText = createDrawing("Text", {
        Text = cfg.Name,
        Color = cfg.Color,
        Size = cfg.FontSize,
        Center = true,
        Outline = true,
        OutlineColor = self.Theme.OutlineColor,
        Font = Drawing.Fonts.Monospace,
        Transparency = cfg.Opacity,
        Visible = false
    })
    cfg.distanceText = createDrawing("Text", {
        Text = "",
        Color = cfg.Color,
        Size = cfg.FontSize-2,
        Center = true,
        Outline = true,
        OutlineColor = self.Theme.OutlineColor,
        Font = Drawing.Fonts.Monospace,
        Transparency = cfg.Opacity,
        Visible = false
    })

    -- Highlight
    if cfg.ShowHighlightFill or cfg.ShowHighlightOutline then
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESPHighlight"
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillColor = cfg.Color
        highlight.OutlineColor = cfg.OutlineColor
        highlight.FillTransparency = cfg.ShowHighlightFill and cfg.HighlightFillTransparency or 1
        highlight.OutlineTransparency = cfg.ShowHighlightOutline and cfg.HighlightOutlineTransparency or 1
        highlight.Parent = target
        cfg.highlight = highlight
    end

    -- Box ESP
    if cfg.ShowBox then
        cfg.box = createDrawing("Square", {
            Thickness = cfg.BoxThickness,
            Color = cfg.Color,
            Transparency = cfg.BoxTransparency,
            Visible = false
        })
    end

    -- Skeleton ESP (simplificado)
    if cfg.ShowSkeleton and target:IsA("Model") then
        cfg.skeletonLines = {}
        for _, part in ipairs(target:GetDescendants()) do
            if part:IsA("BasePart") then
                local line = createDrawing("Line", {
                    Thickness = cfg.SkeletonThickness,
                    Color = cfg.Color,
                    Transparency = cfg.Opacity,
                    Visible = false
                })
                table.insert(cfg.skeletonLines, line)
            end
        end
    end

    table.insert(self.Objects, cfg)
end

--// ➖ Remove ESP individual
function ModelESP:Remove(target)
    for i=#self.Objects,1,-1 do
        local obj = self.Objects[i]
        if obj.Target == target then
            for _, draw in ipairs({obj.tracerLine,obj.nameText,obj.distanceText}) do if draw then pcall(draw.Remove,draw) end end
            if obj.highlight then pcall(obj.highlight.Destroy,obj.highlight) end
            if obj.box then pcall(obj.box.Remove,obj.box) end
            if obj.skeletonLines then for _, l in ipairs(obj.skeletonLines) do if l then pcall(l.Remove,l) end end end
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
        if obj.box then pcall(obj.box.Remove,obj.box) end
        if obj.skeletonLines then for _, l in ipairs(obj.skeletonLines) do if l then pcall(l.Remove,l) end end end
    end
    self.Objects = {}
end

--// 🌐 Update GlobalSettings
function ModelESP:UpdateGlobalSettings()
    for _, esp in ipairs(self.Objects) do
        if esp.tracerLine then esp.tracerLine.Thickness = self.GlobalSettings.LineThickness end
        if esp.nameText then esp.nameText.Size = self.GlobalSettings.FontSize end
        if esp.distanceText then esp.distanceText.Size = self.GlobalSettings.FontSize-2 end
        if esp.box then esp.box.Thickness = self.GlobalSettings.BoxThickness esp.box.Transparency = self.GlobalSettings.BoxTransparency end
        if esp.skeletonLines then
            for _, l in ipairs(esp.skeletonLines) do
                l.Thickness = self.GlobalSettings.SkeletonThickness
            end
        end
    end
end

--// ✅ Configs Globais (APIs)
function ModelESP:SetGlobalTracerOrigin(origin)
    if tracerOrigins[origin] then
        self.GlobalSettings.TracerOrigin = origin
    end
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
function ModelESP:SetGlobalHighlightFillTransparency(value)
    self.GlobalSettings.HighlightFillTransparency = math.clamp(value,0,1)
    self:UpdateGlobalSettings()
end
function ModelESP:SetGlobalHighlightOutlineTransparency(value)
    self.GlobalSettings.HighlightOutlineTransparency = math.clamp(value,0,1)
    self:UpdateGlobalSettings()
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
            if ModelESP.GlobalSettings.AutoRemoveInvalid then
                ModelESP:Remove(target)
            end
            continue
        end

        local pos3D = target:IsA("Model") and getModelCenter(target) or (target:IsA("BasePart") and target.Position)
        if not pos3D then continue end

        local success, pos2D = pcall(function() return camera:WorldToViewportPoint(pos3D) end)
        if not success or pos2D.Z <= 0 then
            for _, draw in ipairs({esp.tracerLine,esp.nameText,esp.distanceText,esp.box}) do if draw then draw.Visible=false end end
            if esp.highlight then esp.highlight.Enabled=false end
            if esp.skeletonLines then for _, l in ipairs(esp.skeletonLines) do l.Visible=false end end
            continue
        end

        local distance = (camera.CFrame.Position - pos3D).Magnitude
        local visible = distance >= esp.MinDistance and distance <= esp.MaxDistance
        local screenPos = Vector2.new(pos2D.X,pos2D.Y)
        local color = ModelESP.GlobalSettings.RainbowMode and getRainbowColor(time) or esp.Color

        -- Tracer
        if esp.tracerLine then
            esp.tracerLine.Visible = esp.ShowTracer and visible
            esp.tracerLine.From = tracerOrigins[ModelESP.GlobalSettings.TracerOrigin](vs)
            esp.tracerLine.To = screenPos
            esp.tracerLine.Color = color
        end
        -- Name
        if esp.nameText then
            esp.nameText.Visible = esp.ShowName and visible
            esp.nameText.Position = screenPos - Vector2.new(0,20)
            esp.nameText.Text = esp.Name
            esp.nameText.Color = color
        end
        -- Distance
        if esp.distanceText then
            esp.distanceText.Visible = esp.ShowDistance and visible
            esp.distanceText.Position = screenPos + Vector2.new(0,5)
            esp.distanceText.Text = string.format("%.1fm",distance)
            esp.distanceText.Color = color
        end
        -- Highlight
        if esp.highlight then
            esp.highlight.Enabled = (esp.ShowHighlightFill or esp.ShowHighlightOutline) and visible
            esp.highlight.FillColor = color
            esp.highlight.OutlineColor = esp.OutlineColor
            esp.highlight.FillTransparency = esp.ShowHighlightFill and esp.HighlightFillTransparency or 1
            esp.highlight.OutlineTransparency = esp.ShowHighlightOutline and esp.HighlightOutlineTransparency or 1
        end
        -- Box ESP
        if esp.box then
            esp.box.Visible = esp.ShowBox and visible
            esp.box.Size = Vector2.new(50,50) -- Placeholder, você pode calcular bounds reais
            esp.box.Position = screenPos - esp.box.Size/2
            esp.box.Color = color
        end
        -- Skeleton ESP
        if esp.skeletonLines then
            for _, l in ipairs(esp.skeletonLines) do
                l.Visible = esp.ShowSkeleton and visible
                l.Color = color
                -- Aqui você pode atualizar posições reais se tiver joints
            end
        end
    end
end)

return ModelESP
------------------------[END]-------------------------------
