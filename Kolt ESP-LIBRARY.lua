--// 📦 Library Kolt V1.2
--// 👤 Autor: DH_SOARES
--// 🎨 Estilo: Minimalista, eficiente e responsivo
--// Atualizações: TracerOrigin mantido estritamente global; Adicionado cálculo dinâmico para Box ESP; Implementação proper de Skeleton para modelos rigged; Melhorias em posicionamento de textos baseados em bounds.

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
        ShowBox = true,
        ShowSkeleton = false,
        RainbowMode = false,
        MaxDistance = math.huge,
        MinDistance = 0,
        Opacity = 0.8,
        LineThickness = 1.5,
        BoxThickness = 1.5,
        SkeletonThickness = 1.2,
        BoxTransparency = 0.5,
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

--// 📍 Tracer Origins (global only)
local tracerOrigins = {
    Top = function(vs) return Vector2.new(vs.X/2, 0) end,
    Center = function(vs) return Vector2.new(vs.X/2, vs.Y/2) end,
    Bottom = function(vs) return Vector2.new(vs.X/2, vs.Y) end,
    Left = function(vs) return Vector2.new(0, vs.Y/2) end,
    Right = function(vs) return Vector2.new(vs.X, vs.Y/2) end,
}

--// 📦 Get Bounding Box
local function getBoundingBox(target)
    if target:IsA("Model") then
        return target:GetBoundingBox()
    elseif target:IsA("BasePart") then
        return target.CFrame, target.Size
    end
    return nil, nil
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
    }

    -- Drawings básicos
    cfg.tracerLine = createDrawing("Line", {
        Thickness = self.GlobalSettings.LineThickness,
        Color = cfg.Color,
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
        highlight.OutlineColor = self.Theme.SecondaryColor
        highlight.FillTransparency = self.GlobalSettings.ShowHighlightFill and 0.85 or 1
        highlight.OutlineTransparency = self.GlobalSettings.ShowHighlightOutline and 0.65 or 1
        highlight.Parent = target
        cfg.highlight = highlight
    end

    -- Box ESP
    if self.GlobalSettings.ShowBox then
        cfg.box = createDrawing("Square", {
            Thickness = self.GlobalSettings.BoxThickness,
            Color = cfg.Color,
            Transparency = self.GlobalSettings.BoxTransparency,
            Filled = false,
            Visible = false
        })
    end

    -- Skeleton ESP
    if self.GlobalSettings.ShowSkeleton and target:IsA("Model") then
        cfg.skeletonConnections = {}
        for _, joint in ipairs(target:GetDescendants()) do
            if joint:IsA("Motor6D") then
                local part0 = joint.Part0
                local part1 = joint.Part1
                if part0 and part1 then
                    local line = createDrawing("Line", {
                        Thickness = self.GlobalSettings.SkeletonThickness,
                        Color = cfg.Color,
                        Transparency = self.GlobalSettings.Opacity,
                        Visible = false
                    })
                    table.insert(cfg.skeletonConnections, {line = line, part0 = part0, part1 = part1})
                end
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
            if obj.skeletonConnections then for _, conn in ipairs(obj.skeletonConnections) do if conn.line then pcall(conn.line.Remove,conn.line) end end end
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
        if obj.skeletonConnections then for _, conn in ipairs(obj.skeletonConnections) do if conn.line then pcall(conn.line.Remove,conn.line) end end end
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
        if esp.skeletonConnections then
            for _, conn in ipairs(esp.skeletonConnections) do
                conn.line.Thickness = self.GlobalSettings.SkeletonThickness
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

        local cf, size = getBoundingBox(target)
        if not cf then continue end
        local pos3D = cf.Position

        local success, pos2D = pcall(function() return camera:WorldToViewportPoint(pos3D) end)
        if not success or pos2D.Z <= 0 then
            for _, draw in ipairs({esp.tracerLine,esp.nameText,esp.distanceText,esp.box}) do if draw then draw.Visible=false end end
            if esp.highlight then esp.highlight.Enabled=false end
            if esp.skeletonConnections then for _, conn in ipairs(esp.skeletonConnections) do conn.line.Visible=false end end
            continue
        end

        local distance = (camera.CFrame.Position - pos3D).Magnitude
        local visible = distance >= ModelESP.GlobalSettings.MinDistance and distance <= ModelESP.GlobalSettings.MaxDistance
        if not visible then
            for _, draw in ipairs({esp.tracerLine,esp.nameText,esp.distanceText,esp.box}) do if draw then draw.Visible=false end end
            if esp.highlight then esp.highlight.Enabled=false end
            if esp.skeletonConnections then for _, conn in ipairs(esp.skeletonConnections) do conn.line.Visible=false end end
            continue
        end

        local color = ModelESP.GlobalSettings.RainbowMode and getRainbowColor(time) or esp.Color

        -- Calcular bounds na tela
        local screenPoints = {}
        local hx, hy, hz = size.X/2, size.Y/2, size.Z/2
        local relPositions = {
            Vector3.new(hx, hy, hz), Vector3.new(hx, hy, -hz), Vector3.new(hx, -hy, hz), Vector3.new(hx, -hy, -hz),
            Vector3.new(-hx, hy, hz), Vector3.new(-hx, hy, -hz), Vector3.new(-hx, -hy, hz), Vector3.new(-hx, -hy, -hz),
        }
        for _, rel in ipairs(relPositions) do
            local worldPos = cf * rel
            local vp = camera:WorldToViewportPoint(worldPos)
            if vp.Z > 0 then
                table.insert(screenPoints, Vector2.new(vp.X, vp.Y))
            end
        end

        local showBounds = #screenPoints > 0
        local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
        if showBounds then
            for _, p in ipairs(screenPoints) do
                minX = math.min(minX, p.X)
                maxX = math.max(maxX, p.X)
                minY = math.min(minY, p.Y)
                maxY = math.max(maxY, p.Y)
            end
        else
            -- Fallback para centro se nenhum corner visível, mas centro é
            minX, maxX, minY, maxY = pos2D.X-25, pos2D.X+25, pos2D.Y-25, pos2D.Y+25
        end

        -- Tracer
        if esp.tracerLine then
            esp.tracerLine.Visible = ModelESP.GlobalSettings.ShowTracer
            esp.tracerLine.From = tracerOrigins[ModelESP.GlobalSettings.TracerOrigin](vs)
            esp.tracerLine.To = Vector2.new(pos2D.X, pos2D.Y)
            esp.tracerLine.Color = color
        end
        -- Name
        if esp.nameText then
            esp.nameText.Visible = ModelESP.GlobalSettings.ShowName
            esp.nameText.Position = Vector2.new((minX + maxX)/2, minY - esp.nameText.Size)
            esp.nameText.Text = esp.Name
            esp.nameText.Color = color
        end
        -- Distance
        if esp.distanceText then
            esp.distanceText.Visible = ModelESP.GlobalSettings.ShowDistance
            esp.distanceText.Position = Vector2.new((minX + maxX)/2, maxY + 2)
            esp.distanceText.Text = string.format("%.1fm", distance)
            esp.distanceText.Color = color
        end
        -- Highlight
        if esp.highlight then
            esp.highlight.Enabled = ModelESP.GlobalSettings.ShowHighlightFill or ModelESP.GlobalSettings.ShowHighlightOutline
            esp.highlight.FillColor = color
            esp.highlight.OutlineColor = ModelESP.Theme.SecondaryColor
            esp.highlight.FillTransparency = ModelESP.GlobalSettings.ShowHighlightFill and 0.85 or 1
            esp.highlight.OutlineTransparency = ModelESP.GlobalSettings.ShowHighlightOutline and 0.65 or 1
        end
        -- Box ESP
        if esp.box then
            esp.box.Visible = ModelESP.GlobalSettings.ShowBox and showBounds
            if showBounds then
                esp.box.Position = Vector2.new(minX, minY)
                esp.box.Size = Vector2.new(maxX - minX, maxY - minY)
                esp.box.Color = color
            end
        end
        -- Skeleton ESP
        if esp.skeletonConnections then
            for _, conn in ipairs(esp.skeletonConnections) do
                local line = conn.line
                line.Visible = ModelESP.GlobalSettings.ShowSkeleton
                line.Color = color
                if ModelESP.GlobalSettings.ShowSkeleton then
                    local vp0 = camera:WorldToViewportPoint(conn.part0.Position)
                    local vp1 = camera:WorldToViewportPoint(conn.part1.Position)
                    if vp0.Z > 0 and vp1.Z > 0 then
                        line.From = Vector2.new(vp0.X, vp0.Y)
                        line.To = Vector2.new(vp1.X, vp1.Y)
                    else
                        line.Visible = false
                    end
                end
            end
        end
    end
end)

return ModelESP
