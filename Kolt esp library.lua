-- ESPHub.lua

local ESPHub = {}
ESPHub.__index = ESPHub

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Configurações padrão do ESP
ESPHub.DefaultSettings = {
    Enabled = true,
    ShowTracer = true,
    ShowBox = true,
    ShowHighlightOutline = true,
    ShowHighlightFill = false,
    ShowDistance = true,
    ShowName = true,
    Color = Color3.fromRGB(0, 255, 0),
    DistanceColor = Color3.fromRGB(255, 255, 255),
    TracerOrigin = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y), -- origem no fundo da tela
}

-- Função auxiliar: converte 3D para 2D na tela, retorna nil se fora da visão
local function worldToScreen(point)
    local pos, onScreen = Camera:WorldToViewportPoint(point)
    if onScreen then
        return Vector2.new(pos.X, pos.Y)
    end
    return nil
end

-- Cria um objeto ESP para um alvo (Model, BasePart, etc)
function ESPHub.new(target, settings)
    local self = setmetatable({}, ESPHub)

    self.Target = target
    self.Settings = settings or {}
    for k, v in pairs(ESPHub.DefaultSettings) do
        if self.Settings[k] == nil then
            self.Settings[k] = v
        end
    end

    -- Cria elementos para o ESP:
    self.Objects = {}

    -- BillboardGui para Nome e Distância
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = target:IsA("BasePart") and target or (target:FindFirstChildWhichIsA("BasePart") or target.PrimaryPart)
    billboard.Size = UDim2.new(0, 150, 0, 40)
    billboard.AlwaysOnTop = true
    billboard.Name = "ESP_Billboard"
    billboard.Enabled = self.Settings.Enabled
    billboard.Parent = game:GetService("CoreGui")

    local nameLabel = Instance.new("TextLabel")
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.TextColor3 = self.Settings.Color
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextScaled = true
    nameLabel.Text = target.Name
    nameLabel.Parent = billboard

    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distanceLabel.TextColor3 = self.Settings.DistanceColor
    distanceLabel.TextStrokeTransparency = 0.5
    distanceLabel.Font = Enum.Font.SourceSans
    distanceLabel.TextScaled = true
    distanceLabel.Text = ""
    distanceLabel.Parent = billboard

    self.Objects.Billboard = billboard
    self.Objects.NameLabel = nameLabel
    self.Objects.DistanceLabel = distanceLabel

    -- Tracer: usa Drawing API para desenhar linha
    self.Objects.Tracer = Drawing.new("Line")
    self.Objects.Tracer.Visible = self.Settings.ShowTracer and self.Settings.Enabled
    self.Objects.Tracer.Color = self.Settings.Color
    self.Objects.Tracer.Thickness = 1.5

    -- Caixa (Box) 2D: desenha um retângulo em volta do objeto no 2D
    self.Objects.Box = Drawing.new("Square")
    self.Objects.Box.Visible = self.Settings.ShowBox and self.Settings.Enabled
    self.Objects.Box.Color = self.Settings.Color
    self.Objects.Box.Thickness = 1.5
    self.Objects.Box.Filled = false

    -- Highlight (Outline e Fill) para BasePart
    if target:IsA("BasePart") then
        local highlight = Instance.new("Highlight")
        highlight.Adornee = target
        highlight.Enabled = self.Settings.Enabled
        highlight.FillColor = self.Settings.Color
        highlight.FillTransparency = self.Settings.ShowHighlightFill and 0.5 or 1
        highlight.OutlineColor = self.Settings.Color
        highlight.OutlineTransparency = self.Settings.ShowHighlightOutline and 0 or 1
        highlight.Parent = game:GetService("CoreGui")
        self.Objects.Highlight = highlight
    elseif target:IsA("Model") then
        -- se for Model, tenta highlight na PrimaryPart ou em todas BaseParts
        if target.PrimaryPart then
            local highlight = Instance.new("Highlight")
            highlight.Adornee = target.PrimaryPart
            highlight.Enabled = self.Settings.Enabled
            highlight.FillColor = self.Settings.Color
            highlight.FillTransparency = self.Settings.ShowHighlightFill and 0.5 or 1
            highlight.OutlineColor = self.Settings.Color
            highlight.OutlineTransparency = self.Settings.ShowHighlightOutline and 0 or 1
            highlight.Parent = game:GetService("CoreGui")
            self.Objects.Highlight = highlight
        end
    end

    -- Atualização do ESP
    self.Connection = RunService.RenderStepped:Connect(function()
        if not self.Settings.Enabled then
            self:HideAll()
            return
        end

        -- Atualiza o billboard gui
        local adornee = billboard.Adornee
        if adornee and adornee.Parent then
            billboard.Enabled = true
            self.Objects.NameLabel.Text = target.Name

            local dist = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) and
                (LocalPlayer.Character.HumanoidRootPart.Position - adornee.Position).Magnitude or 0
            self.Objects.DistanceLabel.Text = string.format("%.1f studs", dist)

            -- Atualiza Tracer
            if self.Settings.ShowTracer then
                local screenPos = worldToScreen(adornee.Position)
                if screenPos then
                    self.Objects.Tracer.From = ESPHub.DefaultSettings.TracerOrigin
                    self.Objects.Tracer.To = screenPos
                    self.Objects.Tracer.Visible = true
                else
                    self.Objects.Tracer.Visible = false
                end
            else
                self.Objects.Tracer.Visible = false
            end

            -- Atualiza Box (simplificado, baseado no BoundingBox do PrimaryPart)
            if self.Settings.ShowBox and adornee:IsA("BasePart") then
                local cf = adornee.CFrame
                local size = adornee.Size

                -- calcula pontos 3D das 8 vértices da caixa
                local corners = {
                    cf * Vector3.new(-size.X/2, -size.Y/2, -size.Z/2),
                    cf * Vector3.new(-size.X/2, -size.Y/2, size.Z/2),
                    cf * Vector3.new(-size.X/2, size.Y/2, -size.Z/2),
                    cf * Vector3.new(-size.X/2, size.Y/2, size.Z/2),
                    cf * Vector3.new(size.X/2, -size.Y/2, -size.Z/2),
                    cf * Vector3.new(size.X/2, -size.Y/2, size.Z/2),
                    cf * Vector3.new(size.X/2, size.Y/2, -size.Z/2),
                    cf * Vector3.new(size.X/2, size.Y/2, size.Z/2),
                }

                local screenCorners = {}
                for i, corner in pairs(corners) do
                    local screenPos = worldToScreen(corner)
                    if screenPos then
                        table.insert(screenCorners, screenPos)
                    end
                end

                if #screenCorners == 8 then
                    -- calcula caixa 2D mínima que engloba todos os pontos
                    local minX = math.huge
                    local minY = math.huge
                    local maxX = -math.huge
                    local maxY = -math.huge
                    for _, pos in pairs(screenCorners) do
                        if pos.X < minX then minX = pos.X end
                        if pos.Y < minY then minY = pos.Y end
                        if pos.X > maxX then maxX = pos.X end
                        if pos.Y > maxY then maxY = pos.Y end
                    end

                    self.Objects.Box.Visible = true
                    self.Objects.Box.Position = Vector2.new(minX, minY)
                    self.Objects.Box.Size = Vector2.new(maxX - minX, maxY - minY)
                else
                    self.Objects.Box.Visible = false
                end
            else
                self.Objects.Box.Visible = false
            end

        else
            -- alvo não existe mais
            self:Destroy()
        end
    end)

    return self
end

function ESPHub:HideAll()
    if self.Objects.Billboard then self.Objects.Billboard.Enabled = false end
    if self.Objects.Tracer then self.Objects.Tracer.Visible = false end
    if self.Objects.Box then self.Objects.Box.Visible = false end
    if self.Objects.Highlight then self.Objects.Highlight.Enabled = false end
end

function ESPHub:Destroy()
    self.Connection:Disconnect()
    if self.Objects.Billboard then self.Objects.Billboard:Destroy() end
    if self.Objects.Tracer then self.Objects.Tracer:Remove() end
    if self.Objects.Box then self.Objects.Box:Remove() end
    if self.Objects.Highlight then self.Objects.Highlight:Destroy() end
    self.Objects = nil
end

return ESPHub
