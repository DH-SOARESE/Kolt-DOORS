--// 📦 Library Kolt V1.4-- (Tracer & ESP melhorado, origin agrupado, referências de tela, suporte a team color, unload function)
--// 👤 Autor: DH_SOARES
--// 🎨 Estilo: Minimalista, eficiente e responsivo, orientado a endereço de objetos

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local camera = workspace.CurrentCamera

local Kolt = {
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
        ShowTeamColor = false, -- Usa cor do time se disponível (para characters de jogadores)
    },
    connection = nil,
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

--// 📍 Centro e bounds do alvo (suporte a Model e BasePart)
local function getScreenBounds(target)
    local parts = {}
    if target:IsA("BasePart") then
        table.insert(parts, target)
    elseif target:IsA("Model") then
        for _, part in ipairs(target:GetDescendants()) do
            if part:IsA("BasePart") and part.Transparency < 1 then
                table.insert(parts, part)
            end
        end
    end
    if #parts == 0 then return nil, nil end

    local min, max
    for _, part in ipairs(parts) do
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
            local corner = cf.Position + (cf.Rotation * off)
            local success, screen = pcall(camera.WorldToViewportPoint, camera, corner)
            if success and screen.Z > 0 then
                local v2 = Vector2.new(screen.X, screen.Y)
                min = min and Vector2.new(math.min(min.X,v2.X), math.min(min.Y,v2.Y)) or v2
                max = max and Vector2.new(math.max(max.X,v2.X), math.max(max.Y,v2.Y)) or v2
            end
        end
    end
    return min, max
end

--// 🛠️ Cria Drawing
local function createDrawing(class, props)
    local obj = Drawing.new(class)
    for k,v in pairs(props) do obj[k]=v end
    return obj
end

--// ➕ Adiciona ESP
function Kolt:Add(target, config)
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
function Kolt:Remove(target)
    for i=#self.Objects,1,-1 do
        local obj = self.Objects[i]
        if obj.Target == target then
            for _, draw in ipairs(obj.tracerLines or {}) do if draw then draw:Remove() end end
            for _, draw in ipairs({obj.nameText,obj.distanceText,obj.box}) do if draw then draw:Remove() end end
            if obj.highlight then obj.highlight:Destroy() end
            table.remove(self.Objects,i)
            break
        end
    end
end

function Kolt:Clear()
    for _, obj in ipairs(self.Objects) do
        for _, draw in ipairs(obj.tracerLines or {}) do if draw then draw:Remove() end end
        for _, draw in ipairs({obj.nameText,obj.distanceText,obj.box}) do if draw then draw:Remove() end end
        if obj.highlight then obj.highlight:Destroy() end
    end
    self.Objects = {}
end

function Kolt:UpdateGlobalSettings()
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
function Kolt:SetGlobalTracerOrigin(origin)
    if tracerOrigins[origin] then self.GlobalSettings.TracerOrigin = origin end
end
function Kolt:SetGlobalTracerStack(enable)
    self.GlobalSettings.TracerStack = enable
end
function Kolt:SetGlobalTracerScreenRefs(enable)
    self.GlobalSettings.TracerScreenRefs = enable
end
function Kolt:SetGlobalESPType(typeName, enabled)
    self.GlobalSettings[typeName] = enabled
    self:UpdateGlobalSettings()
end
function Kolt:SetGlobalRainbow(enable)
    self.GlobalSettings.RainbowMode = enable
end
function Kolt:SetGlobalOpacity(value)
    self.GlobalSettings.Opacity = math.clamp(value,0,1)
    self:UpdateGlobalSettings()
end
function Kolt:SetGlobalFontSize(size)
    self.GlobalSettings.FontSize = math.max(10,size)
    self:UpdateGlobalSettings()
end
function Kolt:SetGlobalLineThickness(thick)
    self.GlobalSettings.LineThickness = math.max(1,thick)
    self:UpdateGlobalSettings()
end
function Kolt:SetGlobalBoxThickness(thick)
    self.GlobalSettings.BoxThickness = math.max(1,thick)
    self:UpdateGlobalSettings()
end
function Kolt:SetGlobalBoxTransparency(value)
    self.GlobalSettings.BoxTransparency = math.clamp(value, 0, 1)
    self:UpdateGlobalSettings()
end
function Kolt:SetGlobalHighlightOutlineTransparency(value)
    self.GlobalSettings.HighlightOutlineTransparency = math.clamp(value, 0, 1)
    self:UpdateGlobalSettings()
end
function Kolt:SetGlobalHighlightFillTransparency(value)
    self.GlobalSettings.HighlightFillTransparency = math.clamp(value, 0, 1)
    self:UpdateGlobalSettings()
end

--// 🔌 Função de unload
function Kolt:Unload()
    self:Clear()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
    self.Enabled = false
end

-- 🔁 Atualização por frame
Kolt.connection = RunService.RenderStepped:Connect(function()
    if not Kolt.Enabled then return end
    local vs = camera.ViewportSize
    local time = tick()
    local tracerOriginPos = tracerOrigins[Kolt.GlobalSettings.TracerOrigin](vs)

    local visibleESPs = {}
    for i=#Kolt.Objects,1,-1 do
        local esp = Kolt.Objects[i]
        local target = esp.Target
        if not target or not target.Parent then
            if Kolt.GlobalSettings.AutoRemoveInvalid then
                Kolt:Remove(target)
            end
            continue
        end

        local min, max = getScreenBounds(target)
        local pos3D
        if target:IsA("Model") then
            pos3D = target:GetPivot().Position
        elseif target:IsA("BasePart") then
            pos3D = target.Position
        end
        if not pos3D then continue end

        local success, pos2D = pcall(camera.WorldToViewportPoint, camera, pos3D)
        if not success or pos2D.Z <= 0 then
            for _, draw in ipairs(esp.tracerLines or {}) do draw.Visible = false end
            for _, draw in ipairs({esp.nameText,esp.distanceText,esp.box}) do if draw then draw.Visible = false end end
            if esp.highlight then esp.highlight.Enabled = false end
            continue
        end

        local center2D = min and max and (min + max) / 2 or Vector2.new(pos2D.X, pos2D.Y)
        local distance = (camera.CFrame.Position - pos3D).Magnitude
        local visible = distance >= Kolt.GlobalSettings.MinDistance and distance <= Kolt.GlobalSettings.MaxDistance

        if not visible then
            for _, draw in ipairs(esp.tracerLines or {}) do draw.Visible = false end
            for _, draw in ipairs({esp.nameText,esp.distanceText,esp.box}) do if draw then draw.Visible = false end end
            if esp.highlight then esp.highlight.Enabled = false end
            continue
        end

        table.insert(visibleESPs, {index = i, esp = esp, refs = {}})

        local color = Kolt.GlobalSettings.RainbowMode and getRainbowColor(time) or esp.Color
        if not Kolt.GlobalSettings.RainbowMode and Kolt.GlobalSettings.ShowTeamColor then
            local player = Players:GetPlayerFromCharacter(target)
            if player and player.Team then
                color = player.Team.TeamColor.Color
            end
        end

        -- Tracer refs
        local refs = visibleESPs[#visibleESPs].refs
        if Kolt.GlobalSettings.TracerScreenRefs and min and max then
            table.insert(refs, min)
            table.insert(refs, Vector2.new(max.X, min.Y))
            table.insert(refs, Vector2.new(min.X, max.Y))
            table.insert(refs, max)
        else
            table.insert(refs, center2D)
        end

        -- Tracer (To e visibilidade, From depois se stack)
        if esp.tracerLines then
            for idx, line in ipairs(esp.tracerLines) do
                line.Visible = Kolt.GlobalSettings.ShowTracer
                line.Color = esp.TracerColor or color
                line.To = refs[idx] or refs[1]
            end
        end

        -- Name
        if esp.nameText then
            esp.nameText.Visible = Kolt.GlobalSettings.ShowName
            esp.nameText.Position = center2D - Vector2.new(0, 20)
            esp.nameText.Text = esp.Name
            esp.nameText.Color = color
        end
        -- Distance
        if esp.distanceText then
            esp.distanceText.Visible = Kolt.GlobalSettings.ShowDistance
            esp.distanceText.Position = center2D + Vector2.new(0, 5)
            esp.distanceText.Text = string.format("%.1fm", distance)
            esp.distanceText.Color = color
        end
        -- Highlight
        if esp.highlight then
            esp.highlight.Enabled = Kolt.GlobalSettings.ShowHighlightFill or Kolt.GlobalSettings.ShowHighlightOutline
            esp.highlight.FillColor = color
            esp.highlight.OutlineColor = esp.HighlightOutlineColor
            esp.highlight.FillTransparency = Kolt.GlobalSettings.ShowHighlightFill and esp.FilledTransparency or 1
            esp.highlight.OutlineTransparency = Kolt.GlobalSettings.ShowHighlightOutline and esp.HighlightOutlineTransparency or 1
        end
        -- Box ESP
        if esp.box and min and max then
            esp.box.Visible = Kolt.GlobalSettings.ShowBox
            local size = max - min + Vector2.new(Kolt.GlobalSettings.BoxPadding * 2, Kolt.GlobalSettings.BoxPadding * 2)
            esp.box.Size = Kolt.GlobalSettings.BoxType == "Fixed" and Vector2.new(50, 50) or size
            esp.box.Position = min - Vector2.new(Kolt.GlobalSettings.BoxPadding, Kolt.GlobalSettings.BoxPadding)
            esp.box.Color = esp.BoxColor or color
        end
    end

    -- Aplicar stacked origins apenas aos visíveis
    if Kolt.GlobalSettings.TracerStack then
        local stackCount = #visibleESPs
        local base = tracerOriginPos
        local pad = Kolt.GlobalSettings.TracerPadding
        local stackedOrigins = {}
        for j = 1, stackCount do
            if tracerOriginPos.Y == 0 or tracerOriginPos.Y == vs.Y then -- horizontal stack
                stackedOrigins[j] = base + Vector2.new((j - ((stackCount + 1) / 2)) * pad, 0)
            else -- vertical stack
                stackedOrigins[j] = base + Vector2.new(0, (j - ((stackCount + 1) / 2)) * pad)
            end
        end
        for j, data in ipairs(visibleESPs) do
            local esp = data.esp
            if esp.tracerLines then
                local origin = stackedOrigins[j]
                for _, line in ipairs(esp.tracerLines) do
                    line.From = origin
                end
            end
        end
    else
        for _, data in ipairs(visibleESPs) do
            local esp = data.esp
            if esp.tracerLines then
                for _, line in ipairs(esp.tracerLines) do
                    line.From = tracerOriginPos
                end
            end
        end
    end
end)

return Kolt
------------------------[END]-------------------------------
