--// 📦 Library Kolt V1.2
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
        AlwaysOnTop = true,  -- Novo: Controla se o ESP é sempre visível (através de paredes)
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

--// 📍 Obtém o bounding box do target
local function getBoundingBox(target)
    if target:IsA("Model") then
        return target:GetBoundingBox()
    elseif target:IsA("BasePart") then
        return target.CFrame, target.Size
    end
    return nil, nil
end

--// 📍 Centro do modelo
local function getModelCenter(target)
    local cf = getBoundingBox(target)
    return cf and cf.Position or Vector3.zero
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
        highlight.DepthMode = self.GlobalSettings.AlwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
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
            Visible = false,
            Filled = false
        })
    end

    -- Skeleton ESP (para personagens com Humanoid)
    if self.GlobalSettings.ShowSkeleton and target:IsA("Model") and target:FindFirstChildOfClass("Humanoid") then
        local bonePairs = {
            {"Head", "UpperTorso"},
            {"UpperTorso", "LowerTorso"},
            {"LowerTorso", "LeftUpperLeg"}, {"LowerTorso", "RightUpperLeg"},
            {"UpperTorso", "LeftUpperArm"}, {"UpperTorso", "RightUpperArm"},
            {"LeftUpperArm", "LeftLowerArm"}, {"RightUpperArm", "RightLowerArm"},
            {"LeftLowerArm", "LeftHand"}, {"RightLowerArm", "RightHand"},
            {"LeftUpperLeg", "LeftLowerLeg"}, {"RightUpperLeg", "RightLowerLeg"},
            {"LeftLowerLeg", "LeftFoot"}, {"RightLowerLeg", "RightFoot"},
        }
        cfg.skeletonLines = {}
        for _, pair in ipairs(bonePairs) do
            local p1 = target:FindFirstChild(pair[1])
            local p2 = target:FindFirstChild(pair[2])
            if p1 and p2 then
                local line = createDrawing("Line", {
                    Thickness = self.GlobalSettings.SkeletonThickness,
                    Color = cfg.Color,
                    Transparency = self.GlobalSettings.Opacity,
                    Visible = false
                })
                table.insert(cfg.skeletonLines, {line = line, parts = {p1, p2}})
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
            if obj.skeletonLines then for _, skel in ipairs(obj.skeletonLines) do if skel.line then pcall(skel.line.Remove,skel.line) end end end
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
        if obj.skeletonLines then for _, skel in ipairs(obj.skeletonLines) do if skel.line then pcall(skel.line.Remove,skel.line) end end end
    end
    self.Objects = {}
end

--// 🌐 Update GlobalSettings
function ModelESP:UpdateGlobalSettings()
    for _, esp in ipairs(self.Objects) do
        if esp.tracerLine then esp.tracerLine.Thickness = self.GlobalSettings.LineThickness end
        if esp.nameText then esp.nameText.Size = self.GlobalSettings.FontSize end
        if esp.distanceText then esp.distanceText.Size = self.GlobalSettings.FontSize-2 end
        if esp.box then 
            esp.box.Thickness = self.GlobalSettings.BoxThickness 
            esp.box.Transparency = self.GlobalSettings.BoxTransparency 
        end
        if esp.skeletonLines then
            for _, skel in ipairs(esp.skeletonLines) do
                if skel.line then skel.line.Thickness = self.GlobalSettings.SkeletonThickness end
            end
        end
        if esp.highlight then
            esp.highlight.DepthMode = self.GlobalSettings.AlwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
            esp.highlight.FillTransparency = self.GlobalSettings.ShowHighlightFill and 0.85 or 1
            esp.highlight.OutlineTransparency = self.GlobalSettings.ShowHighlightOutline and 0.65 or 1
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
function ModelESP:SetEspAlVisible(enable)
    self.GlobalSettings.AlwaysOnTop = enable
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

        local pos3D = getModelCenter(target)
        if not pos3D then continue end

        local success, pos2D = pcall(function() return camera:WorldToViewportPoint(pos3D) end)
        if not success or pos2D.Z <= 0 then
            for _, draw in ipairs({esp.tracerLine,esp.nameText,esp.distanceText,esp.box}) do if draw then draw.Visible=false end end
            if esp.highlight then esp.highlight.Enabled=false end
            if esp.skeletonLines then for _, skel in ipairs(esp.skeletonLines) do if skel.line then skel.line.Visible=false end end end
            continue
        end

        local distance = (camera.CFrame.Position - pos3D).Magnitude
        local visible = distance >= ModelESP.GlobalSettings.MinDistance and distance <= ModelESP.GlobalSettings.MaxDistance
        local screenPos = Vector2.new(pos2D.X,pos2D.Y)
        local color = ModelESP.GlobalSettings.RainbowMode and getRainbowColor(time) or esp.Color

        -- Tracer
        if esp.tracerLine then
            esp.tracerLine.Visible = ModelESP.GlobalSettings.ShowTracer and visible
            esp.tracerLine.From = tracerOrigins[ModelESP.GlobalSettings.TracerOrigin](vs)
            esp.tracerLine.To = screenPos
            esp.tracerLine.Color = color
        end
        -- Name
        if esp.nameText then
            esp.nameText.Visible = ModelESP.GlobalSettings.ShowName and visible
            esp.nameText.Position = screenPos - Vector2.new(0,20)
            esp.nameText.Text = esp.Name
            esp.nameText.Color = color
        end
        -- Distance
        if esp.distanceText then
            esp.distanceText.Visible = ModelESP.GlobalSettings.ShowDistance and visible
            esp.distanceText.Position = screenPos + Vector2.new(0,5)
            esp.distanceText.Text = string.format("%.1fm",distance)
            esp.distanceText.Color = color
        end
        -- Highlight
        if esp.highlight then
            esp.highlight.Enabled = (ModelESP.GlobalSettings.ShowHighlightFill or ModelESP.GlobalSettings.ShowHighlightOutline) and visible
            esp.highlight.FillColor = color
            esp.highlight.OutlineColor = ModelESP.Theme.OutlineColor
        end
        -- Box ESP
        if esp.box then
            local cf, size3D = getBoundingBox(target)
            if cf and size3D then
                local offsets = {
                    Vector3.new(1,1,1), Vector3.new(1,1,-1), Vector3.new(1,-1,1), Vector3.new(1,-1,-1),
                    Vector3.new(-1,1,1), Vector3.new(-1,1,-1), Vector3.new(-1,-1,1), Vector3.new(-1,-1,-1),
                }
                local minX, minY = math.huge, math.huge
                local maxX, maxY = -math.huge, -math.huge
                local onScreen = false
                for _, off in ipairs(offsets) do
                    local corner = cf * (off * (size3D / 2))
                    local vp, inView = camera:WorldToViewportPoint(corner)
                    if inView then
                        onScreen = true
                        minX = math.min(minX, vp.X)
                        maxX = math.max(maxX, vp.X)
                        minY = math.min(minY, vp.Y)
                        maxY = math.max(maxY, vp.Y)
                    end
                end
                if onScreen and visible then
                    esp.box.Position = Vector2.new(minX, minY)
                    esp.box.Size = Vector2.new(maxX - minX, maxY - minY)
                    esp.box.Visible = true
                    esp.box.Color = color
                else
                    esp.box.Visible = false
                end
            else
                esp.box.Visible = false
            end
        end
        -- Skeleton ESP
        if esp.skeletonLines then
            for _, skel in ipairs(esp.skeletonLines) do
                local p1, p2 = skel.parts[1], skel.parts[2]
                if p1 and p2 then
                    local vp1, in1 = camera:WorldToViewportPoint(p1.Position)
                    local vp2, in2 = camera:WorldToViewportPoint(p2.Position)
                    if in1 and in2 and visible then
                        skel.line.From = Vector2.new(vp1.X, vp1.Y)
                        skel.line.To = Vector2.new(vp2.X, vp2.Y)
                        skel.line.Visible = true
                        skel.line.Color = color
                    else
                        skel.line.Visible = false
                    end
                end
            end
        end
    end
end)

return ModelESP
