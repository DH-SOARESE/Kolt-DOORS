--// 📦 Library Kolt v1.2
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
        RainbowMode = false,
        MaxDistance = math.huge,
        MinDistance = 0,
        Opacity = 0.8,
        LineThickness = 1.5,
        FontSize = 14,
        AutoRemoveInvalid = true,
    }
}

--// 🌈 Cor arco-íris (corrigido)
local function getRainbowColor(t)
    local f = 2
    return Color3.fromRGB(
        math.floor(math.sin(f*t + 0) * 127 + 128),
        math.floor(math.sin(f*t + 2) * 127 + 128),
        math.floor(math.sin(f*t + 4) * 127 + 128)
    )
end

--// 📍 Tracer Origins
local tracerOrigins = {
    Top    = function(vs) return Vector2.new(vs.X/2, 0) end,
    Center = function(vs) return Vector2.new(vs.X/2, vs.Y/2) end,
    Bottom = function(vs) return Vector2.new(vs.X/2, vs.Y) end,
    Left   = function(vs) return Vector2.new(0, vs.Y/2) end,
    Right  = function(vs) return Vector2.new(vs.X, vs.Y/2) end,
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

    -- Remove highlight antigo
    for _, obj in ipairs(target:GetChildren()) do
        if obj:IsA("Highlight") and obj.Name == "ESPHighlight" then obj:Destroy() end
    end

    local cfg = {
        Target = target,
        Name = config and config.Name or target.Name,
        Color = config and config.Color or self.Theme.PrimaryColor,
    }

    -- Criando Drawings
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
        Size = self.GlobalSettings.FontSize - 2,
        Center = true,
        Outline = true,
        OutlineColor = self.Theme.OutlineColor,
        Font = Drawing.Fonts.Monospace,
        Transparency = self.GlobalSettings.Opacity,
        Visible = false
    })

    -- Highlight (sempre pega dos globais)
    if self.GlobalSettings.ShowHighlightFill or self.GlobalSettings.ShowHighlightOutline then
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESPHighlight"
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = target
        cfg.highlight = highlight
    end

    table.insert(self.Objects, cfg)
end

--// ➕ Adiciona Entities2D
function ModelESP:AddEntities2D(target, config)
    if not target or not target:IsA("Model") then return end

    if not target:FindFirstChildOfClass("Humanoid") then
        local humanoid = Instance.new("Humanoid")
        humanoid.Name = "FakeHumanoid"
        humanoid.Health = 0
        humanoid.MaxHealth = 0
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        humanoid.Parent = target
    end

    for _, obj in ipairs(target:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.Transparency = 0.99
            obj.CanCollide = false
        end
    end

    self:Add(target, {Name = config and config.Name or target.Name, Color = config and config.Color or self.Theme.PrimaryColor})
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

--// 🌐 Atualiza configs globais
function ModelESP:UpdateGlobalSettings()
    for _, esp in ipairs(self.Objects) do
        if esp.tracerLine then esp.tracerLine.Thickness = self.GlobalSettings.LineThickness end
        if esp.nameText then esp.nameText.Size = self.GlobalSettings.FontSize end
        if esp.distanceText then esp.distanceText.Size = self.GlobalSettings.FontSize - 2 end
    end
end

--// ✅ APIs Globais
function ModelESP:SetGlobalTracerOrigin(origin)
    if tracerOrigins[origin] then
        self.GlobalSettings.TracerOrigin = origin
    end
end
function ModelESP:SetGlobalESPType(typeName, enabled)
    self.GlobalSettings[typeName] = enabled
    self:UpdateGlobalSettings()
end
function ModelESP:SetGlobalRainbow(enable) self.GlobalSettings.RainbowMode = enable end
function ModelESP:SetGlobalOpacity(value)
    self.GlobalSettings.Opacity = math.clamp(value,0,1)
    self:UpdateGlobalSettings()
end
function ModelESP:SetGlobalFontSize(size)
    self.GlobalSettings.FontSize = math.max(10, size)
    self:UpdateGlobalSettings()
end
function ModelESP:SetGlobalLineThickness(thick)
    self.GlobalSettings.LineThickness = math.max(1, thick)
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
            for _, draw in ipairs({esp.tracerLine,esp.nameText,esp.distanceText}) do if draw then draw.Visible=false end end      
            if esp.highlight then esp.highlight.Enabled=false end      
            continue      
        end      

        local distance = (camera.CFrame.Position - pos3D).Magnitude      
        local visible = distance >= ModelESP.GlobalSettings.MinDistance and distance <= ModelESP.GlobalSettings.MaxDistance      

        local screenPos = Vector2.new(pos2D.X,pos2D.Y)      
        local originPos = tracerOrigins[ModelESP.GlobalSettings.TracerOrigin](vs) -- ✅ sempre global      
        local color = ModelESP.GlobalSettings.RainbowMode and getRainbowColor(time) or esp.Color      

        if esp.tracerLine then      
            esp.tracerLine.Visible = ModelESP.GlobalSettings.ShowTracer and visible      
            esp.tracerLine.From = originPos      
            esp.tracerLine.To = screenPos      
            esp.tracerLine.Color = color      
        end      
        if esp.nameText then      
            esp.nameText.Visible = ModelESP.GlobalSettings.ShowName and visible      
            esp.nameText.Position = screenPos - Vector2.new(0,20)      
            esp.nameText.Text = esp.Name      
            esp.nameText.Color = color      
        end      
        if esp.distanceText then      
            esp.distanceText.Visible = ModelESP.GlobalSettings.ShowDistance and visible      
            esp.distanceText.Position = screenPos + Vector2.new(0,5)      
            esp.distanceText.Text = string.format("%.1fm",distance)      
            esp.distanceText.Color = color      
        end      
        if esp.highlight then      
            esp.highlight.Enabled = (ModelESP.GlobalSettings.ShowHighlightFill or ModelESP.GlobalSettings.ShowHighlightOutline) and visible      
            esp.highlight.FillColor = color      
            esp.highlight.OutlineColor = ModelESP.Theme.OutlineColor      
            esp.highlight.FillTransparency = ModelESP.GlobalSettings.ShowHighlightFill and 0.85 or 1      
            esp.highlight.OutlineTransparency = ModelESP.GlobalSettings.ShowHighlightOutline and 0.65 or 1      
        end
    end
end)

return ModelESP
