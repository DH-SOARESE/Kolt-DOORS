--// 📦 Library Kolt V1.2
--// 👤 Autor: DH_SOARES
--// 🎨 Estilo: Minimalista, eficiente e responsivo
--// 📝 Versão 1.2: Adicionadas mais configurações, ESPs aprimorados (box 3D projetado, skeleton para humanoids, health bar), overrides por ESP, mais opções globais.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local ModelESP = {
    Objects = {},
    Enabled = true,
    Theme = {
        PrimaryColor = Color3.fromRGB(130, 200, 255),
        SecondaryColor = Color3.fromRGB(255, 255, 255),
        OutlineColor = Color3.fromRGB(0, 0, 0),
        HealthLowColor = Color3.fromRGB(255, 0, 0),
        HealthHighColor = Color3.fromRGB(0, 255, 0),
        BackgroundColor = Color3.fromRGB(30, 30, 30),
    },
    GlobalSettings = {
        TracerOrigin = "Top", -- "Left", "Center", "Bottom"
        ShowTracer = true,
        ShowHighlightFill = true,
        ShowHighlightOutline = true,
        ShowName = true,
        ShowDistance = true,
        ShowBox = true,
        ShowSkeleton = true,
        ShowHealthBar = true,
        ShowHealthText = true,
        ShowOffscreenArrow = false,
        RainbowMode = false,
        RainbowSpeed = 2,
        MaxDistance = math.huge,
        MinDistance = 0,
        Opacity = 0.8,
        LineThickness = 1.5,
        BoxThickness = 1.5,
        SkeletonThickness = 1.2,
        BoxTransparency = 0.5,
        HealthBarWidth = 4,
        HealthBarHeight = 30,
        HealthBarPosition = "Left",  -- "Left", "Right", "Top", "Bottom"
        FontSize = 14,
        Font = Drawing.Fonts.Monospace,
        AutoRemoveInvalid = true,
        TeamCheck = false,  -- Ignora aliados (baseado em Team do Player)
        FriendCheck = false,  -- Custom, requer config.Friends table
    }
}

--// 🌈 Cor arco-íris
local function getRainbowColor(t)
    local f = ModelESP.GlobalSettings.RainbowSpeed
    return Color3.fromRGB(
        math.sin(f * t + 0) * 127 + 128,
        math.sin(f * t + 2) * 127 + 128,
        math.sin(f * t + 4) * 127 + 128
    )
end

--// 📍 Tracer Origins (adicionado "Mouse")
local tracerOrigins = {
    Top = function(vs) return Vector2.new(vs.X / 2, 0) end,
    Center = function(vs) return Vector2.new(vs.X / 2, vs.Y / 2) end,
    Bottom = function(vs) return Vector2.new(vs.X / 2, vs.Y) end,
    Left = function(vs) return Vector2.new(0, vs.Y / 2) end,
    Right = function(vs) return Vector2.new(vs.X, vs.Y / 2) end,
    Mouse = function(_) return UserInputService:GetMouseLocation() end,
}

--// 📍 Centro do modelo
local function getModelCenter(model)
    local cf = model:GetBoundingBox()
    return cf.Position
end

--// 🛠️ Cria Drawing
local function createDrawing(class, props)
    local obj = Drawing.new(class)
    for k, v in pairs(props) do obj[k] = v end
    return obj
end

--// 🔲 Projeta bounding box 2D (min-max screen)
local function get2DBoundingBox(model)
    local cf, size = model:GetBoundingBox()
    local halfSize = size / 2
    local corners = {
        cf * Vector3.new(-halfSize.X, -halfSize.Y, -halfSize.Z),
        cf * Vector3.new(-halfSize.X, -halfSize.Y, halfSize.Z),
        cf * Vector3.new(-halfSize.X, halfSize.Y, -halfSize.Z),
        cf * Vector3.new(-halfSize.X, halfSize.Y, halfSize.Z),
        cf * Vector3.new(halfSize.X, -halfSize.Y, -halfSize.Z),
        cf * Vector3.new(halfSize.X, -halfSize.Y, halfSize.Z),
        cf * Vector3.new(halfSize.X, halfSize.Y, -halfSize.Z),
        cf * Vector3.new(halfSize.X, halfSize.Y, halfSize.Z),
    }
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    local onScreen = false
    for _, pos in ipairs(corners) do
        local screenPos = camera:WorldToViewportPoint(pos)
        if screenPos.Z > 0 then
            onScreen = true
            minX = math.min(minX, screenPos.X)
            minY = math.min(minY, screenPos.Y)
            maxX = math.max(maxX, screenPos.X)
            maxY = math.max(maxY, screenPos.Y)
        end
    end
    if not onScreen then return nil end
    return Vector2.new(minX, minY), Vector2.new(maxX - minX, maxY - minY)
end

--// 🦴 Configuração de skeleton (para Humanoids, R15 simplificado)
local boneConnections = {
    {"Head", "Neck"},
    {"Neck", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
}

--// ➕ Adiciona ESP (com overrides por config)
function ModelESP:Add(target, config)
    if not target or not target:IsA("Instance") then return end
    if not (target:IsA("Model") or target:IsA("BasePart")) then return end

    for _, obj in ipairs(target:GetChildren()) do
        if obj:IsA("Highlight") and obj.Name == "ESPHighlight" then obj:Destroy() end
    end

    local cfg = {
        Target = target,
        Name = (config and config.Name) or target.Name,
        Color = (config and config.Color) or self.Theme.PrimaryColor,
        Settings = {},  -- Overrides
        Friends = (config and config.Friends) or {},  -- Tabela de usernames amigos
    }

    -- Merge settings: global + overrides
    for k, v in pairs(self.GlobalSettings) do
        cfg.Settings[k] = (config and config[k] ~= nil) and config[k] or v
    end

    -- Drawings básicos
    cfg.tracerLine = createDrawing("Line", {
        Thickness = cfg.Settings.LineThickness,
        Color = cfg.Color,
        Transparency = cfg.Settings.Opacity,
        Visible = false
    })
    cfg.nameText = createDrawing("Text", {
        Text = cfg.Name,
        Color = cfg.Color,
        Size = cfg.Settings.FontSize,
        Center = true,
        Outline = true,
        OutlineColor = self.Theme.OutlineColor,
        Font = cfg.Settings.Font,
        Transparency = cfg.Settings.Opacity,
        Visible = false
    })
    cfg.distanceText = createDrawing("Text", {
        Text = "",
        Color = cfg.Color,
        Size = cfg.Settings.FontSize - 2,
        Center = true,
        Outline = true,
        OutlineColor = self.Theme.OutlineColor,
        Font = cfg.Settings.Font,
        Transparency = cfg.Settings.Opacity,
        Visible = false
    })

    -- Highlight
    if cfg.Settings.ShowHighlightFill or cfg.Settings.ShowHighlightOutline then
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESPHighlight"
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillColor = cfg.Color
        highlight.OutlineColor = self.Theme.SecondaryColor
        highlight.FillTransparency = cfg.Settings.ShowHighlightFill and 0.85 or 1
        highlight.OutlineTransparency = cfg.Settings.ShowHighlightOutline and 0.65 or 1
        highlight.Parent = target
        cfg.highlight = highlight
    end

    -- Box ESP
    if cfg.Settings.ShowBox then
        cfg.box = createDrawing("Square", {
            Thickness = cfg.Settings.BoxThickness,
            Color = cfg.Color,
            Transparency = cfg.Settings.BoxTransparency,
            Filled = false,
            Visible = false
        })
    end

    -- Skeleton ESP
    if cfg.Settings.ShowSkeleton and target:IsA("Model") and target:FindFirstChildOfClass("Humanoid") then
        cfg.skeletonLines = {}
        for _, conn in ipairs(boneConnections) do
            local line = createDrawing("Line", {
                Thickness = cfg.Settings.SkeletonThickness,
                Color = cfg.Color,
                Transparency = cfg.Settings.Opacity,
                Visible = false
            })
            line._bones = conn  -- Armazena os nomes dos bones
            table.insert(cfg.skeletonLines, line)
        end
    end

    -- Health Bar (se Humanoid)
    local humanoid = target:FindFirstChildOfClass("Humanoid")
    if humanoid and (cfg.Settings.ShowHealthBar or cfg.Settings.ShowHealthText) then
        cfg.healthBarBG = createDrawing("Square", {
            Filled = true,
            Color = self.Theme.BackgroundColor,
            Transparency = 0.5,
            Visible = false
        })
        cfg.healthBar = createDrawing("Square", {
            Filled = true,
            Color = self.Theme.HealthHighColor,
            Transparency = cfg.Settings.Opacity,
            Visible = false
        })
        cfg.healthText = createDrawing("Text", {
            Text = "",
            Color = cfg.Color,
            Size = cfg.Settings.FontSize - 2,
            Center = true,
            Outline = true,
            OutlineColor = self.Theme.OutlineColor,
            Font = cfg.Settings.Font,
            Transparency = cfg.Settings.Opacity,
            Visible = false
        })
        cfg.humanoid = humanoid
    end

    -- Offscreen Arrow (triângulo apontando direção)
    if cfg.Settings.ShowOffscreenArrow then
        cfg.arrow = createDrawing("Triangle", {
            Thickness = 1,
            Color = cfg.Color,
            Transparency = cfg.Settings.Opacity,
            Filled = true,
            Visible = false
        })
    end

    table.insert(self.Objects, cfg)
end

--// ➖ Remove ESP individual
function ModelESP:Remove(target)
    for i = #self.Objects, 1, -1 do
        local obj = self.Objects[i]
        if obj.Target == target then
            local drawings = {obj.tracerLine, obj.nameText, obj.distanceText, obj.box, obj.healthBarBG, obj.healthBar, obj.healthText, obj.arrow}
            for _, draw in ipairs(drawings) do if draw then pcall(draw.Remove, draw) end end
            if obj.highlight then pcall(obj.highlight.Destroy, obj.highlight) end
            if obj.skeletonLines then for _, l in ipairs(obj.skeletonLines) do if l then pcall(l.Remove, l) end end end
            table.remove(self.Objects, i)
            break
        end
    end
end

--// 🧹 Limpa todos ESP
function ModelESP:Clear()
    for _, obj in ipairs(self.Objects) do
        local drawings = {obj.tracerLine, obj.nameText, obj.distanceText, obj.box, obj.healthBarBG, obj.healthBar, obj.healthText, obj.arrow}
        for _, draw in ipairs(drawings) do if draw then pcall(draw.Remove, draw) end end
        if obj.highlight then pcall(obj.highlight.Destroy, obj.highlight) end
        if obj.skeletonLines then for _, l in ipairs(obj.skeletonLines) do if l then pcall(l.Remove, l) end end end
    end
    self.Objects = {}
end

--// 🌐 Update GlobalSettings (aplica a todos)
function ModelESP:UpdateGlobalSettings()
    for _, esp in ipairs(self.Objects) do
        for k, v in pairs(self.GlobalSettings) do
            if esp.Settings[k] == nil then  -- Só atualiza se não override
                esp.Settings[k] = v
            end
        end
        -- Atualiza propriedades
        if esp.tracerLine then esp.tracerLine.Thickness = esp.Settings.LineThickness end
        if esp.nameText then esp.nameText.Size = esp.Settings.FontSize esp.nameText.Font = esp.Settings.Font end
        if esp.distanceText then esp.distanceText.Size = esp.Settings.FontSize - 2 esp.distanceText.Font = esp.Settings.Font end
        if esp.box then esp.box.Thickness = esp.Settings.BoxThickness esp.box.Transparency = esp.Settings.BoxTransparency end
        if esp.skeletonLines then for _, l in ipairs(esp.skeletonLines) do l.Thickness = esp.Settings.SkeletonThickness end end
        if esp.healthBar then esp.healthBar.Transparency = esp.Settings.Opacity end
        -- etc.
    end
end

--// ✅ Configs Globais (APIs expandidas)
function ModelESP:SetGlobalTracerOrigin(origin)
    if tracerOrigins[origin] then
        self.GlobalSettings.TracerOrigin = origin
        self:UpdateGlobalSettings()
    end
end
function ModelESP:SetGlobalESPType(typeName, enabled)
    self.GlobalSettings[typeName] = enabled
    self:UpdateGlobalSettings()
end
function ModelESP:SetGlobalRainbow(enable, speed)
    self.GlobalSettings.RainbowMode = enable
    if speed then self.GlobalSettings.RainbowSpeed = speed end
    self:UpdateGlobalSettings()
end
function ModelESP:SetGlobalOpacity(value)
    self.GlobalSettings.Opacity = math.clamp(value, 0, 1)
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
function ModelESP:SetGlobalBoxThickness(thick)
    self.GlobalSettings.BoxThickness = math.max(1, thick)
    self:UpdateGlobalSettings()
end
function ModelESP:SetGlobalSkeletonThickness(thick)
    self.GlobalSettings.SkeletonThickness = math.max(1, thick)
    self:UpdateGlobalSettings()
end
function ModelESP:SetGlobalHealthBarSize(width, height)
    self.GlobalSettings.HealthBarWidth = width
    self.GlobalSettings.HealthBarHeight = height or self.GlobalSettings.HealthBarHeight
    self:UpdateGlobalSettings()
end
function ModelESP:SetGlobalTeamCheck(enable)
    self.GlobalSettings.TeamCheck = enable
    self:UpdateGlobalSettings()
end
function ModelESP:SetThemeColor(key, color)
    if self.Theme[key] then
        self.Theme[key] = color
    end
end

--// 🔁 Atualização por frame
RunService.RenderStepped:Connect(function()
    if not ModelESP.Enabled then return end
    local vs = camera.ViewportSize
    local time = tick()

    for i = #ModelESP.Objects, 1, -1 do
        local esp = ModelESP.Objects[i]
        local target = esp.Target
        if not target or not target.Parent then
            if ModelESP.GlobalSettings.AutoRemoveInvalid then
                ModelESP:Remove(target)
            end
            continue
        end

        -- Check team/friend
        local player = Players:GetPlayerFromCharacter(target)
        local isFriend = table.find(esp.Friends, player and player.Name)
        local isTeam = player and esp.Settings.TeamCheck and player.Team == LocalPlayer.Team
        if isTeam or isFriend then continue end

        local pos3D = target:IsA("Model") and getModelCenter(target) or (target:IsA("BasePart") and target.Position)
        if not pos3D then continue end

        local pos2D, onScreen = camera:WorldToViewportPoint(pos3D)
        local screenPos = Vector2.new(pos2D.X, pos2D.Y)
        local distance = (camera.CFrame.Position - pos3D).Magnitude
        local visible = onScreen and pos2D.Z > 0 and distance >= esp.Settings.MinDistance and distance <= esp.Settings.MaxDistance
        local color = esp.Settings.RainbowMode and getRainbowColor(time) or esp.Color

        -- Offscreen handling
        if not onScreen and esp.Settings.ShowOffscreenArrow then
            local dir = (pos3D - camera.CFrame.Position).Unit
            local screenDir = camera.CFrame:VectorToObjectSpace(dir)
            local angle = math.atan2(screenDir.Y, screenDir.X)
            local edgePos = Vector2.new(vs.X / 2, vs.Y / 2) + Vector2.new(math.cos(angle), math.sin(angle)) * (math.min(vs.X, vs.Y) / 2 - 20)
            if esp.arrow then
                esp.arrow.Visible = visible  -- Visible baseado em distance
                esp.arrow.PointA = edgePos
                esp.arrow.PointB = edgePos + Vector2.new(math.cos(angle - math.pi / 6), math.sin(angle - math.pi / 6)) * 15
                esp.arrow.PointC = edgePos + Vector2.new(math.cos(angle + math.pi / 6), math.sin(angle + math.pi / 6)) * 15
                esp.arrow.Color = color
            end
            visible = false  -- Desliga outros ESPs se offscreen
        elseif esp.arrow then
            esp.arrow.Visible = false
        end

        -- Set visibility for all
        local drawings = {esp.tracerLine, esp.nameText, esp.distanceText, esp.box, esp.healthBarBG, esp.healthBar, esp.healthText}
        for _, draw in ipairs(drawings) do if draw then draw.Visible = false end end
        if esp.highlight then esp.highlight.Enabled = false end
        if esp.skeletonLines then for _, l in ipairs(esp.skeletonLines) do l.Visible = false end end
        if not visible then continue end

        -- Tracer
        if esp.tracerLine and esp.Settings.ShowTracer then
            esp.tracerLine.Visible = true
            esp.tracerLine.From = tracerOrigins[esp.Settings.TracerOrigin](vs)
            esp.tracerLine.To = screenPos
            esp.tracerLine.Color = color
        end
        -- Name
        if esp.nameText and esp.Settings.ShowName then
            esp.nameText.Visible = true
            esp.nameText.Position = screenPos - Vector2.new(0, 20)
            esp.nameText.Text = esp.Name
            esp.nameText.Color = color
        end
        -- Distance
        if esp.distanceText and esp.Settings.ShowDistance then
            esp.distanceText.Visible = true
            esp.distanceText.Position = screenPos + Vector2.new(0, 5)
            esp.distanceText.Text = string.format("%.1fm", distance)
            esp.distanceText.Color = color
        end
        -- Highlight
        if esp.highlight and (esp.Settings.ShowHighlightFill or esp.Settings.ShowHighlightOutline) then
            esp.highlight.Enabled = true
            esp.highlight.FillColor = color
            esp.highlight.OutlineColor = ModelESP.Theme.SecondaryColor
            esp.highlight.FillTransparency = esp.Settings.ShowHighlightFill and 0.85 or 1
            esp.highlight.OutlineTransparency = esp.Settings.ShowHighlightOutline and 0.65 or 1
        end
        -- Box
        if esp.box and esp.Settings.ShowBox then
            local pos, size = get2DBoundingBox(target)
            if pos and size then
                esp.box.Visible = true
                esp.box.Position = pos
                esp.box.Size = size
                esp.box.Color = color
            end
        end
        -- Skeleton
        if esp.skeletonLines and esp.Settings.ShowSkeleton then
            for _, line in ipairs(esp.skeletonLines) do
                local part1 = target:FindFirstChild(line._bones[1])
                local part2 = target:FindFirstChild(line._bones[2])
                if part1 and part2 then
                    local p1 = camera:WorldToViewportPoint(part1.Position)
                    local p2 = camera:WorldToViewportPoint(part2.Position)
                    if p1.Z > 0 and p2.Z > 0 then
                        line.Visible = true
                        line.From = Vector2.new(p1.X, p1.Y)
                        line.To = Vector2.new(p2.X, p2.Y)
                        line.Color = color
                    end
                end
            end
        end
        -- Health
        if esp.humanoid and (esp.Settings.ShowHealthBar or esp.Settings.ShowHealthText) then
            local health = esp.humanoid.Health
            local maxHealth = esp.humanoid.MaxHealth
            local healthFrac = math.clamp(health / maxHealth, 0, 1)
            local healthColor = ModelESP.Theme.HealthLowColor:Lerp(ModelESP.Theme.HealthHighColor, healthFrac)

            -- Posição da health bar baseada em config
            local barPos = screenPos
            if esp.Settings.HealthBarPosition == "Left" then
                barPos = screenPos - Vector2.new(esp.Settings.HealthBarHeight + 5, 0) - Vector2.new(0, esp.Settings.HealthBarHeight / 2)
            elseif esp.Settings.HealthBarPosition == "Right" then
                barPos = screenPos + Vector2.new(5, -esp.Settings.HealthBarHeight / 2)
            elseif esp.Settings.HealthBarPosition == "Top" then
                barPos = screenPos - Vector2.new(esp.Settings.HealthBarWidth / 2, esp.Settings.HealthBarHeight + 20)
            elseif esp.Settings.HealthBarPosition == "Bottom" then
                barPos = screenPos - Vector2.new(esp.Settings.HealthBarWidth / 2, -5)
            end

            if esp.Settings.ShowHealthBar then
                esp.healthBarBG.Visible = true
                esp.healthBarBG.Position = barPos
                esp.healthBarBG.Size = Vector2.new(esp.Settings.HealthBarWidth, esp.Settings.HealthBarHeight)

                esp.healthBar.Visible = true
                esp.healthBar.Position = barPos + Vector2.new(0, esp.Settings.HealthBarHeight * (1 - healthFrac))
                esp.healthBar.Size = Vector2.new(esp.Settings.HealthBarWidth, esp.Settings.HealthBarHeight * healthFrac)
                esp.healthBar.Color = healthColor
            end
            if esp.Settings.ShowHealthText then
                esp.healthText.Visible = true
                esp.healthText.Position = barPos + Vector2.new(esp.Settings.HealthBarWidth / 2, esp.Settings.HealthBarHeight + 5)
                esp.healthText.Text = string.format("%d/%d", health, maxHealth)
                esp.healthText.Color = healthColor
            end
        end
    end
end)

return ModelESP
