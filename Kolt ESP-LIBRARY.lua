--// 📦 Library Kolt V1.3
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
        OutlineColor = Color3.fromRGB(0, 0, 0), -- Outline global
    },
    GlobalSettings = {
        TracerOrigin = "Bottom",
        ShowTracer = true,
        ShowHighlightFill = true,
        ShowHighlightOutline = true,
        ShowName = true,
        ShowDistance = true,
        ShowBox = true,
        ShowHealth = true,
        RainbowMode = false,
        MaxDistance = math.huge,
        MinDistance = 0,
        Opacity = 0.8,
        LineThickness = 1.5,
        BoxThickness = 1.5,
        HealthBarThickness = 4,
        HealthBarOffset = 5,
        HighlightOutlineTransparency = 0.65, -- Nova config global
        HighlightFillTransparency = 0.85, -- Nova config global
        FontSize = 14,
        AutoRemoveInvalid = true,
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

--// 🛠️ Cria Drawing
local function createDrawing(class, props)
    local obj = Drawing.new(class)
    for k,v in pairs(props) do obj[k]=v end
    return obj
end

--// 📦 Obter Bounding Box
local function getBoundingBox(target)
    if target:IsA("Model") then
        return target:GetBoundingBox()
    elseif target:IsA("BasePart") then
        return target.CFrame, target.Size
    end
    return nil
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

    -- Drawings básicos
    cfg.tracerLine = createDrawing("Line", {
        Thickness = self.GlobalSettings.LineThickness,
        Color = cfg.TracerColor or cfg.Color,
        Transparency = self.GlobalSettings.Opacity,
        Visible = false
    })
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
            Transparency = self.GlobalSettings.Opacity,
            Filled = false,
            Visible = false
        })
    end

    -- Health Bar (se Humanoid existir)
    local humanoid = target:FindFirstChildOfClass("Humanoid")
    if humanoid and self.GlobalSettings.ShowHealth then
        cfg.humanoid = humanoid
        cfg.healthBack = createDrawing("Square", {
            Thickness = 1,
            Color = self.Theme.OutlineColor,
            Transparency = 0.5,
            Filled = true,
            Visible = false
        })
        cfg.healthFill = createDrawing("Square", {
            Thickness = 1,
            Transparency = self.GlobalSettings.Opacity,
            Filled = true,
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
            for _, draw in ipairs({obj.tracerLine,obj.nameText,obj.distanceText,obj.box,obj.healthBack,obj.healthFill}) do if draw then pcall(draw.Remove,draw) end end
            if obj.highlight then pcall(obj.highlight.Destroy,obj.highlight) end
            table.remove(self.Objects,i)
            break
        end
    end
end

--// 🧹 Limpa todos ESP
function ModelESP:Clear()
    for _, obj in ipairs(self.Objects) do
        for _, draw in ipairs({obj.tracerLine,obj.nameText,obj.distanceText,obj.box,obj.healthBack,obj.healthFill}) do if draw then pcall(draw.Remove,draw) end end
        if obj.highlight then pcall(obj.highlight.Destroy,obj.highlight) end
    end
    self.Objects = {}
end

--// 🌐 Update GlobalSettings
function ModelESP:UpdateGlobalSettings()
    for _, esp in ipairs(self.Objects) do
        if esp.tracerLine then esp.tracerLine.Thickness = self.GlobalSettings.LineThickness end
        if esp.nameText then esp.nameText.Size = self.GlobalSettings.FontSize end
        if esp.distanceText then esp.distanceText.Size = self.GlobalSettings.FontSize-2 end
        if esp.box then esp.box.Thickness = self.GlobalSettings.BoxThickness esp.box.Transparency = self.GlobalSettings.Opacity end
        if esp.highlight then
            esp.highlight.FillTransparency = self.GlobalSettings.ShowHighlightFill and esp.FilledTransparency or 1
            esp.highlight.OutlineTransparency = self.GlobalSettings.ShowHighlightOutline and esp.HighlightOutlineTransparency or 1
        end
        if esp.healthBack then esp.healthBack.Size = Vector2.new(self.GlobalSettings.HealthBarThickness, esp.healthBack.Size.Y) end
        if esp.healthFill then esp.healthFill.Size = Vector2.new(self.GlobalSettings.HealthBarThickness, esp.healthFill.Size.Y) end
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
-- Novas APIs Globais
function ModelESP:SetGlobalBoxThickness(thick)
    self.GlobalSettings.BoxThickness = math.max(1,thick)
    self:UpdateGlobalSettings()
end
function ModelESP:SetGlobalHealthBarThickness(thick)
    self.GlobalSettings.HealthBarThickness = math.max(1,thick)
    self:UpdateGlobalSettings()
end
function ModelESP:SetGlobalHealthBarOffset(offset)
    self.GlobalSettings.HealthBarOffset = math.max(0,offset)
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

    for i=#ModelESP.Objects,1,-1 do
        local esp = ModelESP.Objects[i]
        local target = esp.Target
        if not target or not target.Parent then
            if ModelESP.GlobalSettings.AutoRemoveInvalid then
                ModelESP:Remove(target)
            end
            continue
        end

        local cf, size = getBoundingBox(target)
        if not cf then continue end
        local pos3D = cf.Position

        local distance = (camera.CFrame.Position - pos3D).Magnitude
        if distance < ModelESP.GlobalSettings.MinDistance or distance > ModelESP.GlobalSettings.MaxDistance then
            for _, draw in ipairs({esp.tracerLine,esp.nameText,esp.distanceText,esp.box,esp.healthBack,esp.healthFill}) do if draw then draw.Visible=false end end
            if esp.highlight then esp.highlight.Enabled=false end
            continue
        end

        local halfSize = size / 2
        local corners = {
            cf * Vector3.new( halfSize.X,  halfSize.Y,  halfSize.Z),
            cf * Vector3.new( halfSize.X,  halfSize.Y, -halfSize.Z),
            cf * Vector3.new( halfSize.X, -halfSize.Y,  halfSize.Z),
            cf * Vector3.new( halfSize.X, -halfSize.Y, -halfSize.Z),
            cf * Vector3.new(-halfSize.X,  halfSize.Y,  halfSize.Z),
            cf * Vector3.new(-halfSize.X,  halfSize.Y, -halfSize.Z),
            cf * Vector3.new(-halfSize.X, -halfSize.Y,  halfSize.Z),
            cf * Vector3.new(-halfSize.X, -halfSize.Y, -halfSize.Z),
        }

        local projected = {}
        local behind = true
        for _, corner in ipairs(corners) do
            local success, pos2D = pcall(camera.WorldToViewportPoint, camera, corner)
            if success and pos2D.Z > 0 then
                behind = false
                table.insert(projected, Vector2.new(pos2D.X, pos2D.Y))
            end
        end

        if behind or #projected == 0 then
            for _, draw in ipairs({esp.tracerLine,esp.nameText,esp.distanceText,esp.box,esp.healthBack,esp.healthFill}) do if draw then draw.Visible=false end end
            if esp.highlight then esp.highlight.Enabled=false end
            continue
        end

        local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
        for _, p in ipairs(projected) do
            minX = math.min(minX, p.X)
            maxX = math.max(maxX, p.X)
            minY = math.min(minY, p.Y)
            maxY = math.max(maxY, p.Y)
        end

        local boxPos = Vector2.new(minX, minY)
        local boxSize = Vector2.new(maxX - minX, maxY - minY)
        local color = ModelESP.GlobalSettings.RainbowMode and getRainbowColor(time) or esp.Color

        -- Box
        if esp.box then
            esp.box.Visible = ModelESP.GlobalSettings.ShowBox
            esp.box.Position = boxPos
            esp.box.Size = boxSize
            esp.box.Color = esp.BoxColor or color
        end

        -- Tracer
        local tracerTo = boxPos + Vector2.new(boxSize.X / 2, boxSize.Y) -- Bottom center
        if esp.tracerLine then
            esp.tracerLine.Visible = ModelESP.GlobalSettings.ShowTracer
            esp.tracerLine.From = tracerOrigins[ModelESP.GlobalSettings.TracerOrigin](vs)
            esp.tracerLine.To = tracerTo
            esp.tracerLine.Color = esp.TracerColor or color
        end

        -- Name
        if esp.nameText then
            esp.nameText.Visible = ModelESP.GlobalSettings.ShowName
            esp.nameText.Position = boxPos + Vector2.new(boxSize.X / 2, -esp.nameText.Size / 2)
            esp.nameText.Text = esp.Name
            esp.nameText.Color = color
        end

        -- Distance
        if esp.distanceText then
            esp.distanceText.Visible = ModelESP.GlobalSettings.ShowDistance
            esp.distanceText.Position = boxPos + Vector2.new(boxSize.X / 2, boxSize.Y + esp.distanceText.Size / 2)
            esp.distanceText.Text = string.format("%.1fm", distance)
            esp.distanceText.Color = color
        end

        -- Highlight
        if esp.highlight then
            esp.highlight.Enabled = ModelESP.GlobalSettings.ShowHighlightFill or ModelESP.GlobalSettings.ShowHighlightOutline
            esp.highlight.FillColor = color
            esp.highlight.OutlineColor = esp.HighlightOutlineColor
            esp.highlight.FillTransparency = ModelESP.GlobalSettings.ShowHighlightFill and esp.FilledTransparency or 1
            esp.highlight.OutlineTransparency = ModelESP.GlobalSettings.ShowHighlightOutline and esp.HighlightOutlineTransparency or 1
        end

        -- Health Bar
        if esp.humanoid and esp.healthBack and esp.healthFill then
            local health = math.clamp(esp.humanoid.Health / esp.humanoid.MaxHealth, 0, 1)
            local barHeight = boxSize.Y
            local barPos = boxPos - Vector2.new(self.GlobalSettings.HealthBarThickness + self.GlobalSettings.HealthBarOffset, 0)

            esp.healthBack.Visible = ModelESP.GlobalSettings.ShowHealth
            esp.healthBack.Position = barPos
            esp.healthBack.Size = Vector2.new(self.GlobalSettings.HealthBarThickness, barHeight)

            esp.healthFill.Visible = ModelESP.GlobalSettings.ShowHealth
            esp.healthFill.Position = barPos + Vector2.new(0, barHeight * (1 - health))
            esp.healthFill.Size = Vector2.new(self.GlobalSettings.HealthBarThickness, barHeight * health)
            esp.healthFill.Color = Color3.fromHSV(health * 0.33, 1, 1)
        end
    end
end)

return ModelESP
