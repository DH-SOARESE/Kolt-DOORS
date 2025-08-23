--// ESP LIBRARY
--// GitHub ready
--// Usage: local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/SEU_REPO/esp/main/esp.lua"))()

local ESP = {}
ESP.Objects = {}
ESP.Settings = {
    MaxDistance = 100,
    MinDistance = 1,
    Enabled = true,
    ShowName = true,
    ShowDistance = true,
    ShowTracer = true,
    ShowHighlight = true
}

local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

--// Função para adicionar objeto
function ESP:AddObject(obj, name)
    if not obj or not obj:IsA("BasePart") then return end
    
    self.Objects[obj] = {
        Name = name or obj.Name,
        Object = obj,
        Highlight = nil,
        Drawing = {
            Name = Drawing.new("Text"),
            Distance = Drawing.new("Text"),
            Tracer = Drawing.new("Line")
        }
    }

    -- Configuração inicial
    local data = self.Objects[obj]
    data.Drawing.Name.Size = 13
    data.Drawing.Name.Color = Color3.fromRGB(255, 255, 255)
    data.Drawing.Name.Center = true
    data.Drawing.Name.Outline = true

    data.Drawing.Distance.Size = 13
    data.Drawing.Distance.Color = Color3.fromRGB(0, 255, 255)
    data.Drawing.Distance.Center = true
    data.Drawing.Distance.Outline = true

    data.Drawing.Tracer.Thickness = 1
    data.Drawing.Tracer.Color = Color3.fromRGB(255, 0, 0)
    data.Drawing.Tracer.Transparency = 1

    -- Highlight
    if ESP.Settings.ShowHighlight then
        local highlight = Instance.new("Highlight")
        highlight.FillTransparency = 1
        highlight.OutlineTransparency = 0
        highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
        highlight.Parent = obj
        data.Highlight = highlight
    end
end

--// Função para remover objeto
function ESP:RemoveObject(obj)
    local data = self.Objects[obj]
    if not data then return end

    for _, v in pairs(data.Drawing) do
        if v then v:Remove() end
    end
    if data.Highlight then data.Highlight:Destroy() end

    self.Objects[obj] = nil
end

--// Funções de configuração
function ESP:SetMaxDistance(value)
    self.Settings.MaxDistance = value
end

function ESP:SetMinDistance(value)
    self.Settings.MinDistance = value
end

--// Renderização
RunService.RenderStepped:Connect(function()
    if not ESP.Settings.Enabled then
        for _, data in pairs(ESP.Objects) do
            for _, v in pairs(data.Drawing) do v.Visible = false end
            if data.Highlight then data.Highlight.Enabled = false end
        end
        return
    end

    for obj, data in pairs(ESP.Objects) do
        if obj and obj.Parent then
            local pos, onScreen = camera:WorldToViewportPoint(obj.Position)
            local distance = (localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")) and (localPlayer.Character.HumanoidRootPart.Position - obj.Position).Magnitude or 0

            if onScreen and distance <= ESP.Settings.MaxDistance and distance >= ESP.Settings.MinDistance then
                -- Highlight
                if data.Highlight then data.Highlight.Enabled = true end

                -- Nome
                if ESP.Settings.ShowName then
                    data.Drawing.Name.Position = Vector2.new(pos.X, pos.Y - 15)
                    data.Drawing.Name.Text = data.Name
                    data.Drawing.Name.Visible = true
                else
                    data.Drawing.Name.Visible = false
                end

                -- Distância
                if ESP.Settings.ShowDistance then
                    data.Drawing.Distance.Position = Vector2.new(pos.X, pos.Y)
                    data.Drawing.Distance.Text = string.format("%.1fm", distance)
                    data.Drawing.Distance.Visible = true
                else
                    data.Drawing.Distance.Visible = false
                end

                -- Tracer
                if ESP.Settings.ShowTracer then
                    data.Drawing.Tracer.From = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y)
                    data.Drawing.Tracer.To = Vector2.new(pos.X, pos.Y)
                    data.Drawing.Tracer.Visible = true
                else
                    data.Drawing.Tracer.Visible = false
                end
            else
                for _, v in pairs(data.Drawing) do v.Visible = false end
                if data.Highlight then data.Highlight.Enabled = false end
            end
        else
            ESP:RemoveObject(obj)
        end
    end
end)

return ESP
