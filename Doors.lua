--[[
==========================================================
 KOLT HUB - DOORS SCRIPT
----------------------------------------------------------
 Supported Floors:
   • Hotel
   • Mines
   • Backdoor
   • Rooms
----------------------------------------------------------
 Global Variables and Initialization
==========================================================
]]

_G.Menu = _G.Menu or false

-- =================================================================
-- GAME SERVICES
-- =================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid", 5)
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart", 5)
local GameData = ReplicatedStorage:WaitForChild("GameData", 5)
local Floor = GameData and GameData:FindFirstChild("Floor") and GameData.Floor.Value or "?"
local LatestRoomIndice = GameData:WaitForChild("LatestRoom")
local placeId = game.PlaceId
local EntityHidden = false

-- Global variables for features
local WalkSpeed = 15
local SpeedEnabled = false
local MaxDistance = 10
local DEBUG = false

-- Remove jump button from TouchGui and keep it removed
local function removeTouchJumpButton()
    local touchGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("TouchGui")
    if touchGui then
        local touchControlFrame = touchGui:FindFirstChild("TouchControlFrame")
        if touchControlFrame then
            local jumpButton = touchControlFrame:FindFirstChild("JumpButton")
            if jumpButton then
                jumpButton:Destroy()
            end
        end
    end
end

-- Primeira remoção imediata
removeTouchJumpButton()

-- Se o JumpButton reaparecer, destrói de novo
local touchGui = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("TouchGui")
local touchControlFrame = touchGui:WaitForChild("TouchControlFrame")

touchControlFrame.ChildAdded:Connect(function(child)
    if child.Name == "JumpButton" then
        task.wait() -- espera 1 frame para garantir que criou
        if child then
            child:Destroy()
        end
    end
end)

-- =================================================================
-- NOTIFICATION FUNCTION
-- =================================================================
local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5
        })
    end)
end

-- =================================================================
-- INITIAL CHECKS
-- =================================================================
if _G.Menu then
    notify("Erro", "Menu já carregado!", 5)
    return
end

if placeId == 6839171747 then
elseif placeId == 6516141723 then
    notify("Notificação", "Lobby detectado", 5)
    return
else
    notify("Erro", "Mapa não suportado", 5)
    return
end

if Floor == "Hotel" or Floor == "Mines" or Floor == "Backdoor" or Floor == "Rooms" then
    notify("Notificação", "Welcome "..LocalPlayer.Name, 5)
else
    notify("Erro", "Não há suporte para esse andar ainda.", 5)
    return
end

_G.Menu = true

-- =================================================================
-- LOAD UI LIBRARY
-- =================================================================
local repo = "https://raw.githubusercontent.com/DH-SOARESE/LinoriaLib/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
local Options = Library.Options
local Toggles = Library.Toggles

Library.ShowToggleFrameInKeybinds = true
Library.ShowCustomCursor = true
Library.NotifySide = "Left"

local title = string.format("Kolt Hub Client – | Floor: %s | %s", Floor, LocalPlayer.Name)
local Window = Library:CreateWindow({
    Title = title,
    Center = true,
    AutoShow = true,
    Resizable = true,
    ShowCustomCursor = true,
    NotifySide = "Left",
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    Main = Window:AddTab("Main"),
    Visual = Window:AddTab("Visual"),
    ["UI Settings"] = Window:AddTab("UI Settings"),
}

-- =================================================================
-- SYSTEMS DEFINITIONS
-- =================================================================

-- SPEED SYSTEM
local Speed = {}
Speed.walkSpeed = WalkSpeed
Speed.enabled = false
Speed.connection = nil

function Speed:Enable()
    if self.enabled then return end
    self.enabled = true

    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        self:Disable()
        return
    end

    self.connection = RunService.Heartbeat:Connect(function()
        if not self.enabled or not humanoid then
            self:Disable()
            return
        end
        humanoid.WalkSpeed = self.walkSpeed
    end)
end

function Speed:Disable()
    if not self.enabled then return end
    self.enabled = false

    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end

    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = 15
    end
end

-- JUMP BOOST SYSTEM
local JumpBoost = {}
JumpBoost.defaultJump = 50  -- Corrected to Roblox default JumpPower
JumpBoost.jumpValue = JumpBoost.defaultJump
JumpBoost.enabled = false
JumpBoost.jumpConnections = {}
JumpBoost.charAddedConn = nil

local function applyJumpBoost(humanoid)
    if not humanoid then return end
    humanoid.JumpPower = JumpBoost.jumpValue
    local conn = humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
        if humanoid and humanoid.Parent and humanoid.JumpPower ~= JumpBoost.jumpValue then
            humanoid.JumpPower = JumpBoost.jumpValue
        end
    end)
    table.insert(JumpBoost.jumpConnections, conn)
end

local function forceJump(character)
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then return end
    local conn = humanoid.StateChanged:Connect(function(_, newState)
        if newState == Enum.HumanoidStateType.Jumping and root and root.Parent then
            root.Velocity = Vector3.new(root.Velocity.X, JumpBoost.jumpValue, root.Velocity.Z)
        end
    end)
    table.insert(JumpBoost.jumpConnections, conn)
end

local function onCharacterAdded(char)
    if not char then return end
    forceJump(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        applyJumpBoost(hum)
    end
end

function JumpBoost:Enable()
    if self.enabled then return end
    self.enabled = true

    if LocalPlayer.Character then
        onCharacterAdded(LocalPlayer.Character)
    end

    self.charAddedConn = LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
end

function JumpBoost:Disable()
    if not self.enabled then return end
    self.enabled = false

    for _, conn in ipairs(self.jumpConnections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    self.jumpConnections = {}

    if self.charAddedConn then
        self.charAddedConn:Disconnect()
        self.charAddedConn = nil
    end

    local char = Workspace:FindFirstChild(LocalPlayer.Name)
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.JumpPower = self.defaultJump
        end
    end
end

-- BYPASS SYSTEM
local Bypass = {}
Bypass.collisionClone = nil
Bypass.heartbeatConn = nil
Bypass.masslessConn = nil
Bypass.enabled = false

function Bypass:Enable()
    if self.enabled then return end
    self.enabled = true

    local character = Workspace:FindFirstChild(LocalPlayer.Name)
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    local originalCollision = character and character:FindFirstChild("Collision")
    if not hrp or not originalCollision then
        self:Disable()
        return
    end

    self.collisionClone = originalCollision:Clone()
    self.collisionClone.Name = "Part"
    self.collisionClone.CanCollide = false
    self.collisionClone.Parent = hrp

    local toggleParent = true
    local lastToggle = tick()

    self.heartbeatConn = RunService.Heartbeat:Connect(function()
        if not self.collisionClone then
            self:Disable()
            return
        end
        if tick() - lastToggle >= 0.24 then
            toggleParent = not toggleParent
            self.collisionClone.Parent = toggleParent and hrp or Lighting
            lastToggle = tick()
        end
    end)

    self.masslessConn = RunService.Heartbeat:Connect(function()
        if self.collisionClone then
            self.collisionClone.Massless = not self.collisionClone.Massless
        end
    end)
end

function Bypass:Disable()
    if not self.enabled then return end
    self.enabled = false

    if self.collisionClone then
        self.collisionClone:Destroy()
        self.collisionClone = nil
    end
    if self.heartbeatConn then
        self.heartbeatConn:Disconnect()
        self.heartbeatConn = nil
    end
    if self.masslessConn then
        self.masslessConn:Disconnect()
        self.masslessConn = nil
    end
end

-- AUTO-ENABLE AT START
Bypass:Enable()

-- FLY SYSTEM
local Fly = {}
Fly.enabled = false
Fly.bodyGyro = nil
Fly.bodyVelocity = nil
Fly.connection = nil
Fly.verticalVelocitySmooth = 0
Fly.horizontalVelocitySmooth = Vector3.zero

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true
rayParams.FilterDescendantsInstances = {LocalPlayer.Character}

local function getHumanoid()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
end

function Fly:Disable()
    if not self.enabled then return end
    self.enabled = false

    if self.bodyGyro then
        self.bodyGyro:Destroy()
        self.bodyGyro = nil
    end
    if self.bodyVelocity then
        self.bodyVelocity:Destroy()
        self.bodyVelocity = nil
    end
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end

    local hum = getHumanoid()
    if hum then
        hum.PlatformStand = false
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end
end

function Fly:Enable()
    if self.enabled then 
        self:Disable()
        return 
    end
    self.enabled = true

    local hum = getHumanoid()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then
        self:Disable()
        return
    end

    hum:ChangeState(Enum.HumanoidStateType.Physics)
    hum.PlatformStand = true

    self.bodyGyro = Instance.new("BodyGyro")
    self.bodyGyro.P = 9000
    self.bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    self.bodyGyro.CFrame = hrp.CFrame
    self.bodyGyro.Parent = hrp

    self.bodyVelocity = Instance.new("BodyVelocity")
    self.bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    self.bodyVelocity.Velocity = Vector3.zero
    self.bodyVelocity.Parent = hrp

    self.connection = RunService.RenderStepped:Connect(function(deltaTime)
        if not self.enabled or not hrp or not hum then
            self:Disable()
            return
        end

        local move = hum.MoveDirection
        local camera = Workspace.CurrentCamera
        local velocity = Vector3.zero

        if move.Magnitude > 0 then
            local targetHorizontal = move * Options.FlySpeed.Value
            self.horizontalVelocitySmooth = self.horizontalVelocitySmooth + (targetHorizontal - self.horizontalVelocitySmooth) * math.clamp(deltaTime * 12, 0, 1)

            local camForward = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z).Unit
            local forwardDot = move:Dot(camForward)
            local targetVertical = camera.CFrame.LookVector.Y * Options.FlySpeed.Value * (forwardDot < 0 and -1 or 1)
            self.verticalVelocitySmooth = self.verticalVelocitySmooth + (targetVertical - self.verticalVelocitySmooth) * math.clamp(deltaTime * 12, 0, 1)

            velocity = self.horizontalVelocitySmooth + Vector3.new(0, self.verticalVelocitySmooth, 0)
        else
            self.verticalVelocitySmooth = self.verticalVelocitySmooth * 0.8
            self.horizontalVelocitySmooth = self.horizontalVelocitySmooth * 0.8
            velocity = self.horizontalVelocitySmooth + Vector3.new(0, self.verticalVelocitySmooth, 0)
        end

        local result = Workspace:Raycast(hrp.Position, Vector3.new(0, -5, 0), rayParams)
        if result then
            local safeHeight = result.Position.Y + hum.HipHeight + 1.2
            if hrp.Position.Y < safeHeight then
                local lookFactor = math.clamp(1 + camera.CFrame.LookVector.Y, 0.1, 1)
                velocity = Vector3.new(velocity.X, math.max(velocity.Y, 1 * lookFactor), velocity.Z)
            end
        end

        self.bodyVelocity.Velocity = velocity
        local flatLook = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z).Unit
        local targetCFrame = CFrame.new(hrp.Position, hrp.Position + flatLook)
        self.bodyGyro.CFrame = self.bodyGyro.CFrame:Lerp(targetCFrame, math.clamp(deltaTime * 15, 0, 1))
    end)
end

-- JUMP BUTTON SYSTEM
local JumpButton = {}
JumpButton.enabled = false
JumpButton.internalChange = false
JumpButton.connections = {}

local function resetJumpButton()
    local jumpBtn = LocalPlayer.PlayerGui:FindFirstChild("MainUI") and
                    LocalPlayer.PlayerGui.MainUI:FindFirstChild("MainFrame") and
                    LocalPlayer.PlayerGui.MainUI.MainFrame:FindFirstChild("MobileButtons") and
                    LocalPlayer.PlayerGui.MainUI.MainFrame.MobileButtons:FindFirstChild("JumpButton")
    if jumpBtn then
        jumpBtn.Position = JumpButton.enabled and UDim2.new(0.4, 0, 0.9, 4) or UDim2.new(0.5, 0, 1, 0)
        jumpBtn.Size = JumpButton.enabled and UDim2.new(0.3, 0, 0.3, 0) or UDim2.new(0.2, 0, 0.2, 0)
        jumpBtn.BackgroundTransparency = 0.35
    end
end

local function updateCanJump(char)
    if not char then return end
    JumpButton.internalChange = true
    char:SetAttribute("CanJump", JumpButton.enabled)
    JumpButton.internalChange = false
    resetJumpButton()
end

local function setupCharacter(char)
    if not char then return end
    if char:GetAttribute("CanJump") == nil then
        char:SetAttribute("CanJump", false)
    end
    table.insert(JumpButton.connections, char:GetAttributeChangedSignal("CanJump"):Connect(function()
        if JumpButton.internalChange then return end
        updateCanJump(char)
    end))
end

function JumpButton:Enable()
    if self.enabled then return end
    self.enabled = true

    if LocalPlayer.Character then
        setupCharacter(LocalPlayer.Character)
        updateCanJump(LocalPlayer.Character)
    end
    table.insert(self.connections, LocalPlayer.CharacterAdded:Connect(function(char)
        setupCharacter(char)
        updateCanJump(char)
    end))

    resetJumpButton()
end

function JumpButton:Disable()
    if not self.enabled then return end
    self.enabled = false

    for _, conn in ipairs(self.connections) do
        if conn.Connected then
            conn:Disconnect()
        end
    end
    self.connections = {}

    local char = Workspace:FindFirstChild(LocalPlayer.Name)
    if char then
        char:SetAttribute("CanJump", false)
    end

    resetJumpButton()
end

-- NO ACCELERATION SYSTEM
local NoAcceleration = {}
NoAcceleration.enabled = false
NoAcceleration.connection = nil

function NoAcceleration:Enable()
    if self.enabled then return end
    self.enabled = true

    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end

    self.connection = RunService.RenderStepped:Connect(function()
        if not self.enabled then return end

        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if humanoid and hrp then
            local moveDir = humanoid.MoveDirection
            local speed = humanoid.WalkSpeed
            local verticalVel = hrp.Velocity.Y
            hrp.Velocity = Vector3.new(moveDir.X * speed, verticalVel, moveDir.Z * speed)
        end
    end)
end

function NoAcceleration:Disable()
    if not self.enabled then return end
    self.enabled = false

    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
end

-- FOV SYSTEM
local Camera = Workspace.CurrentCamera
local fovValue = 70
local forceFovEnabled = false
local fovConnection

local function protectFov()
    if fovConnection then fovConnection:Disconnect() end
    fovConnection = Camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
        if forceFovEnabled and Camera.FieldOfView ~= fovValue then
            Camera.FieldOfView = fovValue
        end
    end)
end

local function enableFovLock()
    forceFovEnabled = true
    Camera.FieldOfView = fovValue
    protectFov()
end

local function disableFovLock()
    forceFovEnabled = false
    if fovConnection then
        fovConnection:Disconnect()
        fovConnection = nil
    end
end

-- NOCLIP SYSTEM
local Noclip = {}
Noclip.enabled = false
local NoclipConnection = nil

local function GetCurrentCharacter()
    return Players.LocalPlayer and Players.LocalPlayer.Character
end

local function ApplyNoclip(character)
    if not character then return end
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.CanCollide = false
        end
    end
end

local function RestoreCollision(character)
    if not character then return end
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end
end

function Noclip:Enable()
    if self.enabled then return end
    self.enabled = true

    NoclipConnection = RunService.Stepped:Connect(function()
        if not self.enabled then return end
        local character = GetCurrentCharacter()
        if character then
            ApplyNoclip(character)
        end
    end)

    local char = GetCurrentCharacter()
    if char then
        ApplyNoclip(char)
    end
end

function Noclip:Disable()
    if not self.enabled then return end
    self.enabled = false

    if NoclipConnection then
        NoclipConnection:Disconnect()
        NoclipConnection = nil
    end

    local char = GetCurrentCharacter()
    if char then
        RestoreCollision(char)
    end
end

function Noclip:Unload()
    self:Disable()
    Noclip = nil
end

local function OnCharacterAdded(character)
    if Noclip.enabled then
        task.wait(0.1)
        ApplyNoclip(character)
    end
end

if Players.LocalPlayer.Character then
    OnCharacterAdded(Players.LocalPlayer.Character)
end
Players.LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)

-- FOV LOCK SYSTEM
local LockFov = {}
LockFov.enabled = false
LockFov.connection = nil
LockFov.fovValue = 70

function LockFov:Enable()
    if self.enabled then return end
    self.enabled = true

    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end

    self.connection = RunService.RenderStepped:Connect(function()
        if not self.enabled then return end
        if Camera then
            Camera.FieldOfView = self.fovValue
        end
    end)
end

function LockFov:Disable()
    if not self.enabled then return end
    self.enabled = false

    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
end

function LockFov:SetFOV(value)
    self.fovValue = value
    if self.enabled and Camera then
        Camera.FieldOfView = self.fovValue
    end
end

-- LIGHTING SYSTEM
local originalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    GlobalShadows = Lighting.GlobalShadows,
    ExposureCompensation = Lighting.ExposureCompensation
}

local targetLighting = {
    Brightness = 0,
    ClockTime = 14.5,
    Ambient = Color3.new(1,1,1),
    OutdoorAmbient = Color3.new(1,1,1),
    GlobalShadows = false,
    ExposureCompensation = 0
}

local Fullbright = {}
Fullbright.enabled = false
Fullbright.connection = nil

local function applyFullbright()
    for prop, value in pairs(targetLighting) do
        Lighting[prop] = value
    end
end

function Fullbright:Enable()
    if self.enabled then return end
    self.enabled = true
    applyFullbright()
    self.connection = Lighting.Changed:Connect(function()
        if self.enabled then
            applyFullbright()
        end
    end)
end

function Fullbright:Disable()
    if not self.enabled then return end
    self.enabled = false
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
    for prop, value in pairs(originalLighting) do
        if prop ~= "FogStart" and prop ~= "FogEnd" then
            Lighting[prop] = value
        end
    end
end

local NoFog = {}
NoFog.enabled = false

function NoFog:Enable()
    if self.enabled then return end
    self.enabled = true
    Lighting.FogStart = 0
    Lighting.FogEnd = 100000
end

function NoFog:Disable()
    if not self.enabled then return end
    self.enabled = false
    Lighting.FogStart = originalLighting.FogStart
    Lighting.FogEnd = originalLighting.FogEnd
end

-- BYPASS MOVEMENT SYSTEM (Mines only)
local MainBypassMoviment = {}
if Floor == "Mines" then
    MainBypassMoviment = MainBypassMoviment or {}

    local climbingConnection = nil
    local ladderConnections = {}
    local roomConnection = nil
    local isActive = false

    local function addLadderESP(ladder)
        if not ladder or not ladder:IsA("Model") then return end

        local highlight = Instance.new("Highlight")
        highlight.Name = "BypassMovementHighlight"
        highlight.Adornee = ladder
        highlight.FillColor = Color3.fromRGB(0, 255, 0)
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
        highlight.OutlineTransparency = 0
        highlight.Parent = ladder

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "BypassMovimentLabel"
        billboard.Adornee = ladder.PrimaryPart or ladder:FindFirstChildWhichIsA("BasePart")
        billboard.Size = UDim2.new(0, 300, 0, 100)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = ladder

        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = "Bypass Movement"
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.TextScaled = true
        textLabel.TextWrapped = false
        textLabel.Font = Enum.Font.Code
        textLabel.Parent = billboard

        table.insert(ladderConnections, highlight)
        table.insert(ladderConnections, billboard)
    end

    local function monitorLadders()
        for _, room in pairs(Workspace.CurrentRooms:GetChildren()) do
            local ladder = room:FindFirstChild("Parts") and room.Parts:FindFirstChild("Ladder")
            if ladder then
                addLadderESP(ladder)
            end
        end

        roomConnection = Workspace.CurrentRooms.ChildAdded:Connect(function(room)
            local success, parts = pcall(function()
                return room:WaitForChild("Parts", 5)
            end)
            
            if success and parts then
                local ladder = parts:FindFirstChild("Ladder")
                if ladder then
                    addLadderESP(ladder)
                end
            end
        end)
    end

    local function removeAllLadderESP()
        for _, connection in pairs(ladderConnections) do
            if connection and connection.Parent then
                connection:Destroy()
            end
        end
        ladderConnections = {}
        
        for _, room in pairs(Workspace.CurrentRooms:GetChildren()) do
            local ladder = room:FindFirstChild("Parts") and room.Parts:FindFirstChild("Ladder")
            if ladder then
                local highlight = ladder:FindFirstChild("BypassMovementHighlight")
                if highlight then
                    highlight:Destroy()
                end
                
                local billboard = ladder:FindFirstChild("BypassMovimentLabel")
                if billboard then
                    billboard:Destroy()
                end
            end
        end
    end

    function MainBypassMoviment.Enable()
        if isActive then return end
        
        isActive = true
        local playerName = LocalPlayer.Name
        local character = Workspace:WaitForChild(playerName)

        if Library and Library.Notify then
            Library:Notify("Use uma escada para o bypass funcionar")
        end

        climbingConnection = RunService.Heartbeat:Connect(function()
            if character:GetAttribute("Climbing") == true then
                character:SetAttribute("Climbing", false)
                
                if Library and Library.Notify then
                    Library:Notify("Sucesso! Divirta-se", nil, 4590657391)
                end
            end
        end)

        monitorLadders()
    end

    function MainBypassMoviment.Disable()
        if not isActive then return end
        
        isActive = false
        
        if climbingConnection then
            climbingConnection:Disconnect()
            climbingConnection = nil
        end
        
        if roomConnection then
            roomConnection:Disconnect()
            roomConnection = nil
        end

        removeAllLadderESP()
    end

    function MainBypassMoviment.Unload()
        MainBypassMoviment.Disable()
        
        if Game and Game.AntiCheatMoviment then
            Game.AntiCheatMoviment:Set(false)
        end
        
        climbingConnection = nil
        roomConnection = nil
        ladderConnections = {}
        isActive = false
        
        MainBypassMoviment = nil
    end
end

-- PADLOCK SYSTEM (Hotel Floor Only)
local PadLock = {}

if Floor == "Hotel" then
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local Workspace = game.Workspace

    PadLock.enabled = false
    PadLock.connection = nil

    local remote = ReplicatedStorage:WaitForChild("RemotesFolder"):WaitForChild("PL")
    local totalSlots = 5
    local lastSentCode = nil

    -- Function to send the code to the server with debounce
    local function SendCodeToServer(code)
        if remote and code ~= lastSentCode then
            remote:FireServer(code)
            lastSentCode = code
            if Library and Library.Notify then
                Library:Notify({
                    Title = "Padlock",
                    Description = "✅ Code sent to server!\n" .. code,
                    Time = 5
                })
            end
        end
    end

    -- Function to retrieve progress and code from hints
    local function GetProgress()
        local playerFolder = Workspace:FindFirstChild(LocalPlayer.Name)
        if not playerFolder then return "-", "-", false, 0 end

        local workspaceHint = playerFolder:FindFirstChild("LibraryHintPaper")
        if not workspaceHint then return "-", "-", false, 0 end

        local workspaceUI = workspaceHint:FindFirstChild("UI")
        if not workspaceUI then return "-", "-", false, 0 end

        local permUI = LocalPlayer.PlayerGui:FindFirstChild("PermUI")
        if not permUI then return "-", "-", false, 0 end

        local permHints = permUI:FindFirstChild("Hints")
        if not permHints then return "-", "-", false, 0 end

        local targetOffsets = {}
        for i = 1, totalSlots do
            local uiElement = workspaceUI:FindFirstChild(tostring(i))
            if uiElement and uiElement:IsA("ImageLabel") then
                targetOffsets[i] = uiElement.ImageRectOffset
            end
        end

        local codeSequence = {}
        local progressSequence = {}
        local foundCount = 0
        local complete = true

        for index, targetOffset in ipairs(targetOffsets) do
            local foundText = nil
            for _, hint in ipairs(permHints:GetChildren()) do
                if hint:IsA("ImageLabel") and hint.ImageRectOffset == targetOffset then
                    local textLabel = hint:FindFirstChild("TextLabel")
                    if textLabel and textLabel:IsA("TextLabel") then
                        foundText = textLabel.Text
                        break
                    end
                end
            end

            if foundText then
                codeSequence[index] = foundText
                progressSequence[index] = foundText
                foundCount = foundCount + 1
            else
                codeSequence[index] = "-"
                progressSequence[index] = "-"
                complete = false
            end
        end

        return table.concat(progressSequence), table.concat(codeSequence), complete, foundCount
    end

    -- Toggle the PadLock system on/off
    function PadLock:Toggle(state)
        self.enabled = state
        if not state then
            self:Unload()
            return
        end

        if self.connection then
            self.connection:Disconnect()
            self.connection = nil
        end

        local playerFolder = Workspace:FindFirstChild(LocalPlayer.Name)
        if not playerFolder then return end

        self.connection = playerFolder.ChildAdded:Connect(function(child)
            if child.Name == "LibraryHintPaper" and self.enabled then
                task.wait(0.1)
                local progressStr, finalCode, complete, foundCount = GetProgress()

                if complete then
                    if Library and Library.Notify then
                        Library:Notify({
                            Title = "Padlock",
                            Description = "🔓 Full code found: " .. progressStr,
                            Time = 5
                        })
                    end
                    SendCodeToServer(finalCode)
                else
                    if Library and Library.Notify then
                        Library:Notify({
                            Title = "Padlock",
                            Description = "📜 Progress: " .. progressStr .. " (" .. foundCount .. "/" .. totalSlots .. ")",
                            Time = 5
                        })
                    end
                end
            end
        end)
    end

    -- Unload and clean up the PadLock system
    function PadLock:Unload()
        self.enabled = false
        if self.connection then
            self.connection:Disconnect()
            self.connection = nil
        end
    end
end

-- ANTI FEATURES
local AntiScreech = {}

function AntiScreech.Apply(state)
    for _, obj in ipairs(game:GetDescendants()) do
        if obj.Name == "Screech" or obj.Name == "_Screech" then
            obj.Name = state and "_Screech" or "Screech"
        end
    end
end

function AntiScreech.Enable()
    AntiScreech.Apply(true)
end

function AntiScreech.Disable()
    AntiScreech.Apply(false)
end

local AntiDupe = {}
local scanLoopDupe

AntiDupe.Enabled = false

function AntiDupe.Process(dupeModel)
    local hidden = dupeModel:FindFirstChild("Hidden")
    if hidden and hidden:IsA("BasePart") then
        hidden.CanTouch = not AntiDupe.Enabled
    end
end

function AntiDupe.Scan()
    local latestRoom = ReplicatedStorage.GameData.LatestRoom.Value
    local room = Workspace.CurrentRooms:FindFirstChild(tostring(latestRoom))
    if not room then return end
    for _, dupe in ipairs(room:GetDescendants()) do
        if dupe:IsA("Model") and dupe.Name == "DoorFake" then
            AntiDupe.Process(dupe)
        end
    end
end

function AntiDupe.Enable()
    AntiDupe.Enabled = true
    AntiDupe.Scan()
    if not scanLoopDupe then
        scanLoopDupe = task.spawn(function()
            while AntiDupe.Enabled do
                AntiDupe.Scan()
                task.wait(2)
            end
        end)
    end
end

function AntiDupe.Disable()
    AntiDupe.Enabled = false
    if scanLoopDupe then
        scanLoopDupe = nil
    end
    AntiDupe.Scan()
end

local AntiSnare = {}
local scanLoopSnare

AntiSnare.Enabled = false

function AntiSnare.Scan()
    for _, room in pairs(Workspace.CurrentRooms:GetChildren()) do
        if room:FindFirstChild("Assets") then
            for _, asset in pairs(room.Assets:GetChildren()) do
                if asset.Name == "Snare" and asset:FindFirstChild("Hitbox") then
                    asset.Hitbox.CanTouch = not AntiSnare.Enabled
                end
            end
        end
    end
end

function AntiSnare.Enable()
    AntiSnare.Enabled = true
    AntiSnare.Scan()
    if not scanLoopSnare then
        scanLoopSnare = task.spawn(function()
            while AntiSnare.Enabled do
                AntiSnare.Scan()
                task.wait(2)
            end
        end)
    end
end

function AntiSnare.Disable()
    AntiSnare.Enabled = false
    scanLoopSnare = nil
    AntiSnare.Scan()
end

local AntiGiggleCeiling = {}
local giggleLoop
local giggleCeilings = {}

AntiGiggleCeiling.Enabled = false

function AntiGiggleCeiling.ScanRooms()
    giggleCeilings = {}
    for _, room in pairs(Workspace.CurrentRooms:GetChildren()) do
        local ceiling = room:FindFirstChild("GiggleCeiling")
        if ceiling and ceiling:FindFirstChild("Hitbox") then
            table.insert(giggleCeilings, ceiling.Hitbox)
        end
    end
end

function AntiGiggleCeiling.RestoreHitboxes()
    for _, hitbox in pairs(giggleCeilings) do
        if hitbox and hitbox:IsA("BasePart") then
            hitbox.CanTouch = true
        end
    end
end

function AntiGiggleCeiling.Enable()
    AntiGiggleCeiling.Enabled = true
    AntiGiggleCeiling.ScanRooms()
    if not giggleLoop then
        giggleLoop = RunService.Heartbeat:Connect(function()
            if not AntiGiggleCeiling.Enabled then return end
            AntiGiggleCeiling.ScanRooms()
            for _, hitbox in pairs(giggleCeilings) do
                if hitbox and hitbox:IsA("BasePart") then
                    hitbox.CanTouch = false
                end
            end
        end)
    end
end

function AntiGiggleCeiling.Disable()
    AntiGiggleCeiling.Enabled = false
    if giggleLoop then
        giggleLoop:Disconnect()
        giggleLoop = nil
    end
    AntiGiggleCeiling.ScanRooms()
    AntiGiggleCeiling.RestoreHitboxes()
end

local AntiHalt = {}
AntiHalt.Enabled = false

function AntiHalt.Apply(state)
    local EntityModules = ReplicatedStorage:FindFirstChild("ModulesClient")
        and ReplicatedStorage.ModulesClient:FindFirstChild("EntityModules")
    if not EntityModules then return end

    local Shade = EntityModules:FindFirstChild("Shade") or EntityModules:FindFirstChild("_Shade")
    if not Shade then return end

    Shade.Name = state and "_Shade" or "Shade"
end

function AntiHalt.Enable()
    AntiHalt.Enabled = true
    AntiHalt.Apply(true)
end

function AntiHalt.Disable()
    AntiHalt.Enabled = false
    AntiHalt.Apply(false)
end

local AntiEyesLookman = {}
local Motor = ReplicatedStorage:WaitForChild("RemotesFolder"):WaitForChild("MotorReplication")
local fireLoop

AntiEyesLookman.Enabled = false
local isLookman = (Floor == "Backdoor") and "Lookman" or "Eyes"

function AntiEyesLookman.FirePackets()
    if isLookman == "Lookman" then
        for i = 1, 3 do
            Motor:FireServer(-647)
            task.wait(0.1)
        end
    else
        for i = 1, 3 do
            Motor:FireServer(0, 90, 0, false)
            task.wait(0.1)
        end
    end
end

function AntiEyesLookman.Enable()
    AntiEyesLookman.Enabled = true
    AntiEyesLookman.FirePackets()
    if not fireLoop then
        fireLoop = task.spawn(function()
            while AntiEyesLookman.Enabled do
                AntiEyesLookman.FirePackets()
                task.wait(2)
            end
        end)
    end
end

function AntiEyesLookman.Disable()
    AntiEyesLookman.Enabled = false
    if fireLoop then
        fireLoop = nil
    end
    if isLookman == "Lookman" then
        Motor:FireServer(0)
    else
        Motor:FireServer(0, 0, 0, true)
    end
end

-- ANTI SPIDER
local AntiSpider = {}
AntiSpider.Enabled = false

function AntiSpider.Apply(state)
    local Spider = ReplicatedStorage.Entities:FindFirstChild("Spider") 
        or ReplicatedStorage.Entities:FindFirstChild("_Spider")
    if Spider then
        Spider.Name = state and "_Spider" or "Spider"
    end
end

function AntiSpider.Enable()
    AntiSpider.Enabled = true
    AntiSpider.Apply(true)
end

function AntiSpider.Disable()
    AntiSpider.Enabled = false
    AntiSpider.Apply(false)
end

-- AUTO INTERACT SYSTEM
local AutoInteract = {}
AutoInteract.enabled = false
AutoInteract.MaxDistance = MaxDistance  -- Assuming MaxDistance is defined elsewhere
local objectCache = {}
local currentRoom = nil
local autoInteractConn
local descendantAddedConn
local descendantRemovingConn

-- Configuração de Targets por andar
local Targets = {}
if Floor == "Hotel" then
    Targets = {
        ["KeyObtain"] = { path = { "KeyObtain" }, prompt = "ModulePrompt", type = 2 },
        ["LeverForGate"] = { path = { "LeverForGate" }, prompt = "ModulePrompt", type = 2 },
        ["Door"] = { path = { "Door", "Lock" }, prompt = "UnlockPrompt", type = 3 },
        ["DrawerContainer"] = { path = { "DrawerContainer" }, prompt = "ActivateEventPrompt", type = 1 },
        ["RolltopContainer"] = { path = { "RolltopContainer" }, prompt = "ActivateEventPrompt", type = 1 },
        ["GoldPile"] = { path = { "GoldPile" }, prompt = "LootPrompt", type = 3 },
        ["Candle"] = { path = { "Candle" }, prompt = "ModulePrompt", type = 3 },
        ["Vitamins"] = { path = { "Vitamins" }, prompt = "ModulePrompt", type = 3 },
        ["CrucifixWall"] = { path = { "CrucifixWall" }, prompt = "ModulePrompt", type = 3 },
        ["Lockpick"] = { path = { "Lockpick" }, prompt = "ModulePrompt", type = 3 },
        ["Flashlight"] = { path = { "Flashlight" }, prompt = "ModulePrompt", type = 3 },
        ["Lighter"] = { path = { "Lighter" }, prompt = "ModulePrompt", type = 3 },
        ["ChestBox"] = { path = { "ChestBox" }, prompt = "ActivateEventPrompt", type = 2 },
        ["Bandage"] = { path = { "Bandage" }, prompt = "ModulePrompt", type = { nivel = 4, limited = 3 }},
        ["AlarmClock"] = { path = { "AlarmClock" }, prompt = "ModulePrompt", type = 3 },
        ["LibraryHintPaper1"] = { path = { "LibraryHintPaper" }, prompt = "ModulePrompt", type = 3 },
        ["LiveHintBook"] = { path = { "LiveHintBook" }, prompt = "ActivateEventPrompt", type = 3 },
        ["Shears"] = { path = { "Shears" }, prompt = "ModulePrompt", type = 3 },
        ["LibraryHintPaper"] = { path = { "LibraryHintPaper" }, prompt = "ActivateEventPrompt", type = { nivel = 4, limited = 3 }},
        ["LeverForGate"] = { path = { "LeverForGate"}, prompt = "ModulePrompt", type = 3},
        ["Smoothie"] = { path = {"Smoothie"}, prompt = "ModulePrompt", type = 3},
    }
elseif Floor == "Mines" then
    Targets = {
        ["Locker_Small"] = { path = { "Locker_Small", "Door" }, prompt = "ActivateEventPrompt", type = 1 },
        ["DrawerContainer"] = { path = { "DrawerContainer", "Metal" }, prompt = "ActivateEventPrompt", type = 1 },
        ["Toolshed_Small"] = { path = { "Toolshed_Small" }, prompt = "ActivateEventPrompt", type = 1 },
        ["Toolbox"] = { path = { "Toolbox" }, prompt = "ActivateEventPrompt", type = 1 },
        ["Fuses"] = { path = { "Fuses" }, prompt = "FusesPrompt", type = 3 },
        ["GoldPile"] = { path = { "GoldPile" }, prompt = "LootPrompt", type = 3 },
        ["FuseObtain"] = { path = { "FuseObtain" }, prompt = "ModulePrompt", type = 3 },
        ["Glowsticks"] = { path = { "Glowsticks" }, prompt = "ModulePrompt", type = 3 },
        ["Shears"] = { path = { "Shears" }, prompt = "ModulePrompt", type = 3 },
        ["Bandage"] = { path = { "Bandage" }, prompt = "ModulePrompt", type = { nivel = 4, limited = 3 }},
    }
elseif Floor == "Backdoor" then
    Targets = {
        ["KeyObtain"] = { path = { "KeyObtain" }, prompt = "ModulePrompt", type = 1 },
        ["Door"] = { path = { "Door", "Lock" }, prompt = "UnlockPrompt", type = 3 },
        ["TimerLever"] = { path = { "TimerLever" }, prompt = "ActivateEventPrompt", type = 1 },
        ["GoldPile"] = { path = { "GoldPile" }, prompt = "LootPrompt", type = 3 },
        ["Bandage"] = { path = { "Bandage" }, prompt = "ModulePrompt", type = { nivel = 4, limited = 3 }},
        ["DrawerContainer"] = { path = { "DrawerContainer" }, prompt = "ActivateEventPrompt", type = 1 },
    }
elseif Floor == "Rooms" then
    Targets = {
        ["GoldPile"] = { path = { "GoldPile" }, prompt = "LootPrompt", type = 3 },
        ["Bandage"] = { path = { "Bandage" }, prompt = "ModulePrompt", type = { nivel = 4, limited = 3 }},
        ["StardustPickup"] = { path = { "StardustPickup" }, prompt = "ModulePrompt", type = 3 },
        ["Candle"] = { path = { "Candle" }, prompt = "ModulePrompt", type = 3 },
        ["Vitamins"] = { path = { "Vitamins" }, prompt = "ModulePrompt", type = 3 },
        ["Flashlight"] = { path = { "Flashlight" }, prompt = "ModulePrompt", type = 3 },
        ["Lighter"] = { path = { "Lighter" }, prompt = "ModulePrompt", type = 3 },
    }
end

local function GetPromptWorldPosition(prompt)
    if not prompt or not prompt.Parent then return nil end
    local parent = prompt.Parent
    if parent:IsA("BasePart") then return parent.Position end
    if parent:IsA("Attachment") then return parent.WorldPosition or (parent.Parent and parent.Parent.Position) end
    if parent:IsA("Model") and parent.PrimaryPart then return parent.PrimaryPart.Position end
    local part = parent:FindFirstChildWhichIsA("BasePart", true)
    return part and part.Position or nil
end

local function IsWithinDistance(prompt)
    local playerPos = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart and LocalPlayer.Character.PrimaryPart.Position
    local promptPos = GetPromptWorldPosition(prompt)
    return playerPos and promptPos and (playerPos - promptPos).Magnitude <= AutoInteract.MaxDistance
end

local function MatchesPath(obj, path)
    local cur = obj
    for i = #path, 1, -1 do
        if not cur or cur.Name ~= path[i] then return false end
        cur = cur.Parent
    end
    return true
end

local function FindAllPrompts(obj, promptName)
    local results = {}
    for _, d in ipairs(obj:GetDescendants()) do
        if d:IsA("ProximityPrompt") and (not promptName or d.Name == promptName) then
            table.insert(results, d)
        end
    end
    return results
end

local function GetAttribute(prompt, attrName)
    local cur = prompt
    while cur do
        local val = cur:GetAttribute(attrName)
        if val ~= nil then return val end
        cur = cur.Parent
    end
    return nil
end

local function NormalizeInteractions(val)
    if val == nil then return 0 end
    if type(val) == "number" then return val end
    if type(val) == "boolean" then return val and 1 or 0 end
    return 0
end

local function SetInteractionAttribute(prompt, value)
    prompt:SetAttribute("ScriptInteractions", value)
end

local function TryInteract(prompt, typeInfo)
    if not prompt or not prompt:IsA("ProximityPrompt") or not prompt.Enabled then return end
    if not IsWithinDistance(prompt) then return end

    local interactionType = typeInfo
    local limited = nil
    
    if type(typeInfo) == "table" and typeInfo.nivel == 4 then
        interactionType = 4
        limited = typeInfo.limited or 1
    end

    if interactionType == 1 then
        if NormalizeInteractions(GetAttribute(prompt, "Interactions")) == 0 then
            fireproximityprompt(prompt)
        end
    elseif interactionType == 2 then
        local found = GetAttribute(prompt, "Interactions" .. LocalPlayer.Name) or GetAttribute(prompt, "Interactions")
        if NormalizeInteractions(found) == 0 then fireproximityprompt(prompt) end
    elseif interactionType == 3 then
        fireproximityprompt(prompt)
    elseif interactionType == 4 then
        local currentCount = NormalizeInteractions(GetAttribute(prompt, "ScriptInteractions"))
        if currentCount < limited then
            fireproximityprompt(prompt)
            SetInteractionAttribute(prompt, currentCount + 1)
            if DEBUG then print("Type 4 interaction:", currentCount + 1, "/", limited) end
        elseif DEBUG then
            print("Type 4 limit reached:", currentCount, "/", limited)
        end
    end
end

local function AddToCache(obj)
    for targetName, info in pairs(Targets) do
        if MatchesPath(obj, info.path) then
            local prompts = FindAllPrompts(obj, info.prompt)
            if #prompts > 0 then
                if not objectCache[targetName] then objectCache[targetName] = {} end
                objectCache[targetName][obj] = prompts
            end
        end
    end
end

local function RemoveFromCache(obj)
    for targetName, objectsData in pairs(objectCache) do
        if objectsData[obj] then
            objectsData[obj] = nil
        end
    end
end

local function BuildCache(room)
    objectCache = {}
    for _, obj in ipairs(room:GetDescendants()) do
        AddToCache(obj)
    end
end

local function SetupRoomListeners(room)
    if descendantAddedConn then descendantAddedConn:Disconnect() end
    if descendantRemovingConn then descendantRemovingConn:Disconnect() end
    
    descendantAddedConn = room.DescendantAdded:Connect(function(obj)
        AddToCache(obj)
    end)
    
    descendantRemovingConn = room.DescendantRemoving:Connect(function(obj)
        RemoveFromCache(obj)
    end)
end

function AutoInteract:Enable()
    if self.enabled then return end
    self.enabled = true

    if autoInteractConn then
        autoInteractConn:Disconnect()
        autoInteractConn = nil
    end

    autoInteractConn = RunService.Heartbeat:Connect(function()
        if not self.enabled then return end
        local char = LocalPlayer.Character
        if not char or not char.PrimaryPart then return end
        local currentRoomName = LocalPlayer:GetAttribute("CurrentRoom")
        if not currentRoomName then return end
        local newRoom = Workspace.CurrentRooms:FindFirstChild(currentRoomName)
        if not newRoom then return end

        if newRoom ~= currentRoom then
            currentRoom = newRoom
            BuildCache(currentRoom)
            SetupRoomListeners(currentRoom)
        end

        for targetName, objectsData in pairs(objectCache) do
            local info = Targets[targetName]
            if info then
                for obj, prompts in pairs(objectsData) do
                    if obj:IsDescendantOf(Workspace) then
                        for _, prompt in ipairs(prompts) do
                            if prompt:IsDescendantOf(Workspace) then
                                TryInteract(prompt, info.type)
                            end
                        end
                    end
                end
            end
        end
    end)
end

function AutoInteract:Disable()
    if not self.enabled then return end
    self.enabled = false

    if autoInteractConn then
        autoInteractConn:Disconnect()
        autoInteractConn = nil
    end
    if descendantAddedConn then
        descendantAddedConn:Disconnect()
        descendantAddedConn = nil
    end
    if descendantRemovingConn then
        descendantRemovingConn:Disconnect()
        descendantRemovingConn = nil
    end
    objectCache = {}
    currentRoom = nil
end

-- INSTANT INTERACT SYSTEM
local InstantInteract = {}
InstantInteract.enabled = false
local roomFolder = Workspace:WaitForChild("CurrentRooms")
local connections = {}

local function SetPromptInstant(prompt)
    if prompt:IsA("ProximityPrompt") then
        if prompt:GetAttribute("OriginalHoldDuration") == nil then
            prompt:SetAttribute("OriginalHoldDuration", prompt.HoldDuration)
        end
        prompt.HoldDuration = 0
    end
end

local function RestorePrompt(prompt)
    if prompt:IsA("ProximityPrompt") then
        local original = prompt:GetAttribute("OriginalHoldDuration")
        if original ~= nil then
            prompt.HoldDuration = original
            prompt:SetAttribute("OriginalHoldDuration", nil)
        end
    end
end

local function ApplyInstantInRoom(room)
    for _, descendant in ipairs(room:GetDescendants()) do
        if InstantInteract.enabled then
            SetPromptInstant(descendant)
        end
    end

    local conn = room.DescendantAdded:Connect(function(obj)
        if InstantInteract.enabled then
            SetPromptInstant(obj)
        end
    end)
    table.insert(connections, conn)
end

local function ApplyToAllRooms()
    for _, room in ipairs(roomFolder:GetChildren()) do
        ApplyInstantInRoom(room)
    end
end

function InstantInteract:Enable()
    if self.enabled then return end
    self.enabled = true

    ApplyToAllRooms()

    local connRoom = roomFolder.ChildAdded:Connect(function(room)
        if self.enabled then
            ApplyInstantInRoom(room)
        end
    end)
    table.insert(connections, connRoom)
end

function InstantInteract:Disable()
    if not self.enabled then return end
    self.enabled = false

    for _, room in ipairs(roomFolder:GetChildren()) do
        for _, prompt in ipairs(room:GetDescendants()) do
            RestorePrompt(prompt)
        end
    end

    for _, c in ipairs(connections) do
        if c.Connected then
            c:Disconnect()
        end
    end
    connections = {}
end

-- WATERMARK SYSTEM
Library:SetWatermarkVisibility(true)

local FrameTimer = tick()
local FrameCounter = 0
local FPS = 60

local WatermarkConnection
local lastTimerValue = 0

local function unloadWatermark()
    if WatermarkConnection then
        WatermarkConnection:Disconnect()
        WatermarkConnection = nil
    end
end

local function getAnyRoomTimer()
    for _, room in ipairs(workspace.CurrentRooms:GetChildren()) do
        local door = room:FindFirstChild("Door")
        if door then
            local displayTimer = door:FindFirstChild("DisplayTimer")
            if displayTimer then
                local textLabel = displayTimer:FindFirstChild("Text")
                if textLabel and textLabel:IsA("TextLabel") then
                    return textLabel.Text
                end
            end
        end
    end
    return nil
end

local function timerToSeconds(timerText)
    if not timerText then return 0 end
    local minutes, seconds = timerText:match("(%d+):(%d+)")
    if minutes and seconds then
        return tonumber(minutes) * 60 + tonumber(seconds)
    else
        return tonumber(timerText) or 0
    end
end

local executorName = identifyexecutor and identifyexecutor() or (RunService:IsStudio() and "Studio" or "Unknown")

WatermarkConnection = RunService.RenderStepped:Connect(function()
    -- FPS calculation
    FrameCounter = FrameCounter + 1
    if tick() - FrameTimer >= 1 then
        FPS = FrameCounter
        FrameTimer = tick()
        FrameCounter = 0
    end

    -- Ping
    local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())

    -- Adjusted room display
    local adjustedRoom = GameData.LatestRoom.Value
    if Floor == "Backdoor" then
        adjustedRoom = adjustedRoom - 50
    elseif Floor == "Mines" then
        adjustedRoom = adjustedRoom + 100
    end

    -- Watermark text logic
    local watermarkText = ""
    if Floor == "Backdoor" then
        local timerText = getAnyRoomTimer()
        if timerText then
            lastTimerValue = timerToSeconds(timerText)
        end
        watermarkText = string.format("%d : Time | %d : CurrentRooms | %d ms | Executor: %s",
            lastTimerValue, adjustedRoom, ping, executorName)
    elseif Floor == "Mines" then
        local char = workspace:FindFirstChild(LocalPlayer.Name)
        local oxygenValue = 0
        if char then
            oxygenValue = math.clamp(math.floor(char:GetAttribute("Oxygen") or 0), 0, 100)
        end
        watermarkText = string.format("%d : Oxygen | %d : CurrentRooms | %d ms | Executor: %s",
            oxygenValue, adjustedRoom, ping, executorName)
    else
        watermarkText = string.format("%d : CurrentRooms | %d ms | Executor: %s",
            adjustedRoom, ping, executorName)
    end

    Library:SetWatermark(watermarkText)
end)

-- =================================================================
-- USER INTERFACE
-- =================================================================

-- MAIN TAB - LocalPlayer
local Box1 = Tabs.Main:AddLeftTabbox()
local TabLocalPlayer = Box1:AddTab("LocalPlayer")
local TabCamera = Box1:AddTab("Camera")

TabLocalPlayer:AddSlider("Speed", {
    Text = "WalkSpeed",
    Default = WalkSpeed,
    Min = 15,
    Max = 50,
    Rounding = 0,
    Compact = true,
    HideMax = true,
    Callback = function(value)
        WalkSpeed = value
        Speed.walkSpeed = value
        if SpeedEnabled and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = WalkSpeed
            end
        end
    end
})

TabLocalPlayer:AddSlider("FlySpeed", {
    Text = "Fly Speed",
    Default = 20,
    Min = 20,
    Max = 50,
    Compact = true,
    HideMax = true,
    Rounding = 0
})

TabLocalPlayer:AddSlider("JumpBoost", {
    Text = "Jump Boost",
    Default = JumpBoost.defaultJump,
    Min = 20,
    Max = 50,
    Rounding = 0,
    Compact = true,
    HideMax = true,
    Callback = function(value)
        JumpBoost.jumpValue = value
        local char = Workspace:FindFirstChild(LocalPlayer.Name)
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                applyJumpBoost(hum)
            end
        end
    end
})

TabLocalPlayer:AddToggle("EnableSpeed", {
    Text = "Enable WalkSpeed",
    Default = false,
    Callback = function(state)
        SpeedEnabled = state
        if state then
            Speed:Enable()
        else
            Speed:Disable()
        end
    end
})

TabLocalPlayer:AddToggle("EnableFly", {
    Text = "Enable Fly",
    Default = false,
    Callback = function(state)
        if state then
            Fly:Enable()
        else
            Fly:Disable()
        end
    end
}):AddKeyPicker("Fly", {
    Mode = "Toggle",
    Default = "F",
    Text = "Fly",
    SyncToggleState = true
})

TabLocalPlayer:AddToggle("EnableJump", {
    Text = "Enable Jump",
    Default = false,
    Callback = function(v)
        if v then
            JumpButton:Enable()
            JumpBoost:Enable()
        else
            JumpButton:Disable()
            JumpBoost:Disable()
        end
    end
})

TabLocalPlayer:AddToggle("NoAcceleration", {
    Text = "No Acceleration",
    Default = false,
    Callback = function(state)
        if state then
            NoAcceleration:Enable()
        else
            NoAcceleration:Disable()
        end
    end
})

if Floor == "Mines" then
    TabLocalPlayer:AddToggle("Noclip", {
        Text = "Noclip",
        Default = false,
        Tooltip = "Permite atravessar paredes e objetos",
        Callback = function(state)
            if state then
                Noclip:Enable()
            else
                Noclip:Disable()
            end
        end
    }):AddKeyPicker("NoclipKey", {
        Mode = "Toggle",
        Default = "N",
        Text = "Noclip",
        SyncToggleState = true
    })
end

-- MAIN TAB - Camera
TabCamera:AddSlider("FieldOfView", {
    Text = "Field Of View",
    Default = LockFov.fovValue,
    Min = 70,
    Max = 120,
    Rounding = 0,
    Compact = true,
    HideMax = true,
    Callback = function(value)
        LockFov:SetFOV(value)
    end
})

TabCamera:AddToggle("EnableFov", {
    Text = "Enable FOV Lock",
    Default = false,
    Callback = function(state)
        if state then
            LockFov:Enable()
        else
            LockFov:Disable()
        end
    end
})

-- MAIN TAB - Functions
local Functions = Tabs.Main:AddLeftGroupbox("Functions")

local remotesFolder = ReplicatedStorage:WaitForChild("RemotesFolder")

local function resetCharacter()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        Library:Notify("Your character has been reset.", nil, 4590657391)
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Health = 0
    else
        Library:Notify("No character found to reset!", nil, 4590657391)
    end
end

Functions:AddButton({
    Text = "Play Again",
    Func = function()
        local playAgainRemote = remotesFolder:FindFirstChild("PlayAgain")
        if playAgainRemote then
            playAgainRemote:FireServer()
            Library:Notify("Starting a new run...", nil, 4590657391)
        else
            Library:Notify("PlayAgain remote not found!", nil, 4590657391)
        end
    end,
    DoubleClick = true,
    Tooltip = "Double click to start a new game"
})

Functions:AddButton({
    Text = "Back to Lobby",
    Func = function()
        local lobbyRemote = remotesFolder:FindFirstChild("Lobby")
        if lobbyRemote then
            Library:Notify("Returning to the lobby...", nil, 4590657391)
            task.wait(1)
            lobbyRemote:FireServer()
        else
            Library:Notify("Lobby remote not found!", nil, 4590657391)
        end
    end,
    DoubleClick = true,
    Tooltip = "Double click to return to the lobby"
})

Functions:AddButton({
    Text = "Reset Character",
    Func = resetCharacter,
    DoubleClick = true,
    Tooltip = "Double click to reset your character"
})

-- =================================================================
-- CONFIGURAÇÃO DE ENTIDADES PARA NOTIFICAÇÃO
-- =================================================================
local EntitiesNotify = {}

if Floor == "Hotel" or Floor == "Mines" then
    EntitiesNotify.Target = {
        ["RushMoving"]          = { Name = "Rush", SpawnMessage = "Rush foi criado, esconda-se!", DespawnMessage = "Rush desapareceu!", ChatNotify = true },
        ["AmbushMoving"]        = { Name = "Ambush", SpawnMessage = "Ambush foi criado, esconda-se!", DespawnMessage = "Ambush desapareceu!", ChatNotify = true },
        ["Eyes"]                = { Name = "Eyes", SpawnMessage = "Eyes foi criado, não olhe diretamente!", DespawnMessage = "Eyes sumiu!", ChatNotify = true },
        ["SeekMovingNewClone"]  = { Name = "Seek", SpawnMessage = "Hora do Seek! Boa sorte!", DespawnMessage = nil, ChatNotify = true },
        ["Screech"]             = { Name = "Screech", SpawnMessage = "Screech apareceu, olhe para ele!", DespawnMessage = nil, ChatNotify = false },
    }
elseif Floor == "Backdoor" then
    EntitiesNotify.Target = {
        ["BackdoorRush"]    = { Name = "Blitz", SpawnMessage = "Blitz foi criado, esconda-se!", DespawnMessage = "Blitz desapareceu!", ChatNotify = true },
        ["BackdoorLookman"] = { Name = "Lookman", SpawnMessage = "Lookman foi criado, não olhe diretamente!", DespawnMessage = nil, ChatNotify = true },
        ["EntityModel"]     = { Name = "Haste", SpawnMessage = "Boa sorte, cuide-se!", DespawnMessage = "Haste sumiu!", ChatNotify = true },
    }
elseif Floor == "Rooms" then
    EntitiesNotify.Target = {
        ["A60"]  = { Name = "A-60", SpawnMessage = "A–60 criado, esconda-se!", DespawnMessage = "A–60 desapareceu!", ChatNotify = true },
        ["A120"] = { Name = "A-120", SpawnMessage = "A–120 criado, esconda-se!", DespawnMessage = "A–120 desapareceu!", ChatNotify = true },
    }
end

-- =================================================================
-- VARIÁVEIS GLOBAIS E SERVICES
-- =================================================================
local NotifiedEntities = {}   -- Evita notificações duplicadas
local NotifyEventActive = false
local NotifyChatActive = false
local Expandi = false
local soundId = 4590657391

local TextChatService = game:GetService("TextChatService")
local Workspace = workspace

Toggles.NotificationActive = {Value = false}

-- =================================================================
-- FUNÇÕES AUXILIARES
-- =================================================================
local function UpdateExpandi()
    Expandi = NotifyEventActive or NotifyChatActive
    Toggles.NotificationActive.Value = Expandi
end

local function SendChatNotification(messageText)
    if not messageText or messageText == "" then return end
    local channel = TextChatService.TextChannels:WaitForChild("RBXGeneral")
    pcall(function()
        channel:SendAsync(messageText)
    end)
end

local function SendEventNotification(messageText, soundId)
    if not messageText or messageText == "" then return end
    pcall(function()
        Library:Notify(messageText, nil, soundId)
    end)
end

local function ProcessEntitySpawn(obj)
    if not obj or not obj.Name then return end
    local data = EntitiesNotify.Target[obj.Name]
    if data and not NotifiedEntities[obj] then
        NotifiedEntities[obj] = true
        if NotifyEventActive then SendEventNotification(data.SpawnMessage, soundId) end
        if NotifyChatActive and data.ChatNotify then SendChatNotification(data.SpawnMessage) end
    end
end

local function ProcessEntityDespawn(obj)
    if not obj or not obj.Name then return end
    local data = EntitiesNotify.Target[obj.Name]
    if data and NotifiedEntities[obj] then
        NotifiedEntities[obj] = nil
        if NotifyEventActive then SendEventNotification(data.DespawnMessage, soundId) end
        if NotifyChatActive and data.ChatNotify then SendChatNotification(data.DespawnMessage) end
    end
end

-- =================================================================
-- Função global para desativar notificações
-- =================================================================
_G.NotificacaoAl = _G.NotificacaoAl or {}
function _G.NotificacaoAl.Disable()
    NotifyEventActive = false
    NotifyChatActive = false
    Toggles.NotificationActive.Value = false
    NotifiedEntities = {}
    print("[NotificacaoAl] Todas as notificações foram desativadas!")
end

-- =================================================================
-- GUI / TOGGLES
-- =================================================================
local Notifications = Tabs.Main:AddLeftGroupbox("Notification")

Notifications:AddToggle("NotificationEvent", {
    Text = "Notify Event",
    Default = false,
    Callback = function(value)
        NotifyEventActive = value
        UpdateExpandi()
    end
})

Notifications:AddToggle("NotificationChat", {
    Text = "Notify Chat",
    Default = false,
    Callback = function(value)
        NotifyChatActive = value
        UpdateExpandi()
    end
})

-- InputBox dinâmico (spawn/despawn por entidade)
local InputBox = Notifications:AddDependencyBox()

for entityName, data in pairs(EntitiesNotify.Target) do
    if data.SpawnMessage and data.SpawnMessage ~= "" then
        InputBox:AddInput(entityName .. "_SpawnInput", {
            Text = data.Name .. " (Spawn)",
            Default = data.SpawnMessage,
            Placeholder = "Mensagem ao criar...",
            ClearTextOnFocus = false,
            Callback = function(value)
                if value and value ~= "" then
                    data.SpawnMessage = value
                    print(entityName .. " Spawn texto atualizado:", value)
                end
            end
        })
    end

    if data.DespawnMessage and data.DespawnMessage ~= "" then
        InputBox:AddInput(entityName .. "_DespawnInput", {
            Text = data.Name .. " (Despawn)",
            Default = data.DespawnMessage,
            Placeholder = "Mensagem ao desaparecer...",
            ClearTextOnFocus = false,
            Callback = function(value)
                if value and value ~= "" then
                    data.DespawnMessage = value
                    print(entityName .. " Despawn texto atualizado:", value)
                end
            end
        })
    end
end

InputBox:SetupDependencies({
    {Toggles.NotificationActive, true},
})

-- =================================================================
-- MONITORAMENTO DE ENTIDADES NO WORKSPACE
-- =================================================================
for _, obj in pairs(Workspace:GetChildren()) do
    ProcessEntitySpawn(obj)
end

Workspace.ChildAdded:Connect(ProcessEntitySpawn)
Workspace.ChildRemoved:Connect(ProcessEntityDespawn)

if Floor == "Mines" then
    -- MAIN TAB - Auto
    local Auto = Tabs.Main:AddLeftGroupbox("Auto")
    local autoNextRoomActive = false -- controla o loop externo

    -- Teleporte automático em loop
    Auto:AddToggle("AutoNextRoom", {
        Text = "Auto Next Room",
        Default = false,
        Callback = function(state)
            autoNextRoomActive = state
            if state then
                spawn(function()
                    while autoNextRoomActive do
                        local roomIndex = LatestRoomIndice.Value
                        local latestRoom = workspace.CurrentRooms:FindFirstChild(tostring(roomIndex))
                        if latestRoom and latestRoom:FindFirstChild("Door") then
                            local door = latestRoom.Door:FindFirstChild("Door")
                            if door then
                                local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                if hrp then
                                    hrp.CFrame = door.CFrame + Vector3.new(0,3,0)
                                end
                            end
                        end
                        wait(0.5)
                    end
                end)
            end
        end
    })

    -- Teleporte único
    Auto:AddButton({
        Text = "Next Room",
        Func = function()
            local roomIndex = LatestRoomIndice.Value
            local latestRoom = workspace.CurrentRooms:FindFirstChild(tostring(roomIndex))
            if latestRoom and latestRoom:FindFirstChild("Door") then
                local door = latestRoom.Door:FindFirstChild("Door")
                if door then
                    local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.CFrame = door.CFrame + Vector3.new(0,3,0)
                    end
                end
            end
        end
    })
end

-- MAIN TAB - Game & Remote Tabs
local hasGameFeatures = true
local hasRemoteFeatures = (Floor == "Hotel")
local TabBox, Game, RemoteTab

local function createGameTabs()
    TabBox = Tabs.Main:AddRightTabbox()
    
    if hasGameFeatures then
        Game = TabBox:AddTab("Game")
    end
    
    if hasRemoteFeatures then
        RemoteTab = TabBox:AddTab("Remote")
    end
end


createGameTabs()

if Game then
    Game:AddToggle("Fullbright", {
        Text = "Fullbright",
        Default = false,
        Callback = function(state)
            if state then
                Fullbright:Enable()
            else
                Fullbright:Disable()
            end
        end
    })

    Game:AddToggle("NoFog", {
        Text = "No Fog",
        Default = false,
        Callback = function(state)
            if state then
                NoFog:Enable()
            else
                NoFog:Disable()
            end
        end
    })
end

local AutoRooms = {}
AutoRooms.Running = false
AutoRooms.Connection = nil
AutoRooms.PathThread = nil

-- Função para habilitar AutoRooms
function AutoRooms.Enable()
    if AutoRooms.Running then return end
    AutoRooms.Running = true

    local LocalPlayer = game.Players.LocalPlayer
    local PathfindingService = game:GetService("PathfindingService")
    local LatestRoom = game.ReplicatedStorage.GameData.LatestRoom

    -- Verifica se já existe a pasta
    local Folder = workspace:FindFirstChild("PathFindPartsFolder")
    if not Folder then
        Folder = Instance.new("Folder")
        Folder.Name = "PathFindPartsFolder"
        Folder.Parent = workspace
    end

    -- Função para encontrar o locker mais próximo, com lógica aprimorada
    local function getLocker()
        local CurrentRoom = LocalPlayer:GetAttribute("CurrentRoom")
        if CurrentRoom == nil then return nil end

        local Entity = workspace:FindFirstChild("A60") or workspace:FindFirstChild("A120")
        if not Entity or Entity.Main.Position.Y <= -4 then return nil end

        local nextRoom = LatestRoom.Value
        local nextRoomObj = workspace.CurrentRooms:FindFirstChild(tostring(nextRoom))
        local nextDoorPos = nextRoomObj and nextRoomObj:FindFirstChild("Door") and nextRoomObj.Door.Door.Position

        local isNearNextDoor = false
        if nextDoorPos and (Entity.Main.Position - nextDoorPos).Magnitude < 100 then  -- Threshold ajustável para "próxima da próxima porta"
            isNearNextDoor = true
        end

        local function findClosestLockerInRoom(roomNum)
            local room = workspace.CurrentRooms:FindFirstChild(tostring(roomNum))
            if not room then return nil end

            local closest
            local playerPos = LocalPlayer.Character.HumanoidRootPart.Position
            for _, v in pairs(room:GetDescendants()) do
                if v.Name == "Rooms_Locker" and v:FindFirstChild("Door") and v:FindFirstChild("HiddenPlayer") then
                    if v.HiddenPlayer.Value == nil and v.Door.Position.Y > -3 then
                        local dist = (playerPos - v.Door.Position).Magnitude
                        if not closest or dist < closest.dist then
                            closest = {part = v.Door, dist = dist}
                        end
                    end
                end
            end
            return closest and closest.part
        end

        local locker = findClosestLockerInRoom(CurrentRoom)

        if not locker and isNearNextDoor then
            local roomToCheck = CurrentRoom - 1
            while roomToCheck >= 0 do
                locker = findClosestLockerInRoom(roomToCheck)
                if locker then break end
                roomToCheck = roomToCheck - 1
            end
        end

        -- Se ainda não encontrou, fallback para busca global (mais eficiente)
        if not locker then
            local globalClosest
            for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do
                if v.Name == "Rooms_Locker" and v:FindFirstChild("Door") and v:FindFirstChild("HiddenPlayer") then
                    if v.HiddenPlayer.Value == nil and v.Door.Position.Y > -3 then
                        local dist = (LocalPlayer.Character.HumanoidRootPart.Position - v.Door.Position).Magnitude
                        if not globalClosest or dist < (LocalPlayer.Character.HumanoidRootPart.Position - globalClosest.Position).Magnitude then
                            globalClosest = v.Door
                        end
                    end
                end
            end
            locker = globalClosest
        end

        return locker
    end

    -- Função para determinar o destino do pathfinding, com avanço sala por sala
    local function getPath()
        local Entity = workspace:FindFirstChild("A60") or workspace:FindFirstChild("A120")
        if Entity and Entity.Main.Position.Y > -4 then
            return getLocker()
        else
            local CurrentRoom = LocalPlayer:GetAttribute("CurrentRoom")
            if CurrentRoom == nil then return nil end

            local targetRoom = math.min(CurrentRoom + 1, LatestRoom.Value)
            if CurrentRoom >= LatestRoom.Value then
                targetRoom = LatestRoom.Value  -- Vai para a porta da sala atual/seguinte se já alcançado
            end

            local room = workspace.CurrentRooms:FindFirstChild(tostring(targetRoom))
            if room and room:FindFirstChild("Door") then
                return room.Door.Door
            end
        end
        return nil
    end

    -- Atualiza movimento do jogador conforme room
    LatestRoom:GetPropertyChangedSignal("Value"):Connect(function()
        if not AutoRooms.Running then return end
        if LatestRoom.Value ~= 1000 then
            LocalPlayer.DevComputerMovementMode = Enum.DevComputerMovementMode.Scriptable
        else
            LocalPlayer.DevComputerMovementMode = Enum.DevComputerMovementMode.KeyboardMouse
            Folder:ClearAllChildren()
            if Library then
                Library:Notify("Concluído com sucesso!!", 10, 4590657391)
            end
            AutoRooms.Disable()
        end
    end)

    -- Loop principal de integração com lockers e entidades
    AutoRooms.Connection = game:GetService("RunService").RenderStepped:Connect(function()
        if not AutoRooms.Running then return end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CanCollide = true 

            local Path = getPath()
            local Entity = workspace:FindFirstChild("A60") or workspace:FindFirstChild("A120")

            if Entity then
                -- Caso a entidade esteja acima do chão, tenta entrar no locker
                if Path and Path.Parent.Name == "Rooms_Locker" and Entity.Main.Position.Y > -4 then
                    if (LocalPlayer.Character.HumanoidRootPart.Position - Path.Position).Magnitude < 5 then
                        if not LocalPlayer.Character.HumanoidRootPart.Anchored then
                            local HidePrompt = Path.Parent:FindFirstChild("HidePrompt")
                            if HidePrompt then
                                fireproximityprompt(HidePrompt)
                            end
                        end
                    end
                end

                -- Caso a entidade esteja abaixo do chão, sai do esconderijo
                if Entity.Main.Position.Y < -4 then
                    local playerModel = workspace:FindFirstChild(LocalPlayer.Name)
                    if playerModel then
                        playerModel:SetAttribute("Hiding", false)
                    else
                        game:GetService("Players").LocalPlayer.PlayerGui.MainUI.MainFrame.ButtonUnhide.Visible = false
                    end
                    -- Garante que a câmera volte ao normal
                    if LocalPlayer.Character.HumanoidRootPart.Anchored then
                        game.ReplicatedStorage.RemotesFolder.CamLock:FireServer()
                    end
                end
            else
                -- Caso não haja entidade, apenas garante que a câmera não fique presa
                if LocalPlayer.Character.HumanoidRootPart.Anchored then
                    game.ReplicatedStorage.RemotesFolder.CamLock:FireServer()
                end
            end
        end
    end)

    -- Thread de pathfinding melhorada
    AutoRooms.PathThread = coroutine.create(function()
        while AutoRooms.Running do
            local Destination = getPath()
            if Destination then
                local path = PathfindingService:CreatePath({
                    WaypointSpacing = 0.8,  -- Aumentado para um caminho mais fluido e menos pontos
                    AgentRadius = 0.6,
                    AgentHeight = 5.5,  -- Adicionado para melhor precisão com altura do personagem
                    AgentCanJump = true,
                    Costs = {  -- Custos personalizados para evitar obstáculos indesejados
                        Water = 20,  -- Evita água se possível
                        Danger = math.huge  -- Evita áreas perigosas
                    }
                })
                path:ComputeAsync(LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(0, 3, 0), Destination.Position)  -- Ajustado para começar acima do chão
                local Waypoints = path:GetWaypoints()

                if path.Status == Enum.PathStatus.Success then  -- Verificação mais precisa
                    Folder:ClearAllChildren()
                    
                    -- Visualização melhorada: Esferas conectadas por linhas (Beams) para formar uma linha contínua
                    local attachments = {}  -- Para armazenar attachments dos beams
                    
                    for i, Waypoint in pairs(Waypoints) do
                        local part = Instance.new("Part")
                        part.Name = "PathWaypoint"
                        part.Size = Vector3.new(0.5, 0.5, 0.5)  -- Menor para ser menos intrusivo
                        part.Position = Waypoint.Position + Vector3.new(0, 0.25, 0)  -- Levemente acima do chão
                        part.Shape = Enum.PartType.Ball  -- Esferas em vez de cilindros para visual mais moderno
                        part.Material = Enum.Material.Neon  -- Neon para brilho
                        part.Color = Color3.fromRGB(0, 162, 255)  -- Azul vibrante
                        part.Transparency = 0.3  -- Semi-transparente
                        part.Anchored = true
                        part.CanCollide = false
                        part.Parent = Folder
                        
                        -- Conectar com Beam para formar uma linha contínua
                        if i > 1 then
                            local prevAttachment = attachments[i-1]
                            local currAttachment = Instance.new("Attachment")
                            currAttachment.Parent = part
                            
                            local beam = Instance.new("Beam")
                            beam.Attachment0 = prevAttachment
                            beam.Attachment1 = currAttachment
                            beam.Color = ColorSequence.new(Color3.fromRGB(0, 162, 255))
                            beam.Transparency = NumberSequence.new(0.5)
                            beam.Width0 = 0.3
                            beam.Width1 = 0.3
                            beam.Parent = Folder
                            
                            table.insert(attachments, currAttachment)
                        else
                            local firstAttachment = Instance.new("Attachment")
                            firstAttachment.Parent = part
                            table.insert(attachments, firstAttachment)
                        end
                    end

                    -- Movimento suave com verificações adicionais
                    for _, Waypoint in pairs(Waypoints) do
                        if not AutoRooms.Running then break end
                        
                        -- Verifica se o waypoint é válido e ajusta altura se necessário
                        local targetPos = Waypoint.Position
                        if Waypoint.Action == Enum.PathWaypointAction.Jump then
                            targetPos = targetPos + Vector3.new(0, 2, 0)  -- Ajuste para pulos
                        end
                        
                        LocalPlayer.Character.Humanoid:MoveTo(targetPos)
                        local connection
                        connection = LocalPlayer.Character.Humanoid.MoveToFinished:Connect(function(reached)
                            connection:Disconnect()
                        end)
                        LocalPlayer.Character.Humanoid.MoveToFinished:Wait()
                    end
                    
                    -- Limpeza automática após o movimento (opcional, para performance)
                    task.wait(0.1)
                    if Folder.Parent then
                        Folder:ClearAllChildren()
                    end
                end
            end
            task.wait(0.2)  -- Aumentado para menos CPU
        end
    end)
    coroutine.resume(AutoRooms.PathThread)
end

-- Função para desabilitar AutoRooms
function AutoRooms.Disable()
    AutoRooms.Running = false
    if AutoRooms.Connection then
        AutoRooms.Connection:Disconnect()
        AutoRooms.Connection = nil
    end
    AutoRooms.PathThread = nil
    if workspace:FindFirstChild("PathFindPartsFolder") then
        workspace.PathFindPartsFolder:ClearAllChildren()
    end
end

if Floor == "Rooms" and Game then
    Game:AddToggle("AutoRooms", {
        Text = "Auto Rooms",
        Default = false,
        Callback = function(state)
            if state then
                AutoRooms.Enable()
            else
                AutoRooms.Disable()
            end
        end
    })
end

if Floor == "Mines" and Game then
    Game:AddToggle("AntiCheatMoviment", {
        Text = "AntiCheat Movement Bypass",
        Default = false,
        Tooltip = "Bypassa o sistema anti-cheat de movimento nas escadas",
        Callback = function(state)
            if state then
                MainBypassMoviment.Enable()
            else
                MainBypassMoviment.Disable()
            end
        end
    })
end

if Floor == "Hotel" and RemoteTab then
    RemoteTab:AddToggle("PadLock", {
        Text = "PadLock",
        Default = false,
        Callback = function(state)
            PadLock:Toggle(state)
        end
    })
end

-- MAIN TAB - Anti & Jumpscare Tabs
local hasAntiFeatures = (Floor == "Hotel" or Floor == "Mines" or Floor == "Backdoor" or Floor == "Rooms")
local hasJumpscareFeatures = (Floor == "Hotel" or Floor == "Mines") and ReplicatedStorage.Entities:FindFirstChild("Spider")
local AntiTabBox, Anti, Jumpscare

local function createAntiTabs()
    AntiTabBox = Tabs.Main:AddRightTabbox()
    
    if hasAntiFeatures then
        Anti = AntiTabBox:AddTab("Anti")
    end
    
    if hasJumpscareFeatures then
        Jumpscare = AntiTabBox:AddTab("Jumpscare")
    end
end

createAntiTabs()

if (Floor == "Hotel" or Floor == "Mines") and Anti then
    Anti:AddToggle("NoScreech", {
        Text = "Anti Screech",
        Default = false,
        Callback = function(v)
            if v then
                AntiScreech.Enable()
            else
                AntiScreech.Disable()
            end
        end
    })

    Anti:AddToggle("NoDupe", {
        Text = "Anti Dupe",
        Default = false,
        Callback = function(v)
            if v then
                AntiDupe.Enable()
            else
                AntiDupe.Disable()
            end
        end
    })
end

local AntiVacuum = {}
local VacuumLoop
local storedParts = {}

AntiVacuum.Enabled = false
local MAX_DISTANCE = 5 -- distância máxima para considerar "colada"

-- Calcula a menor distância entre duas tabelas de partes
local function minDistance(partsA, partsB)
    local minDist = math.huge
    for _, a in pairs(partsA) do
        for _, b in pairs(partsB) do
            local dist = (a.Position - b.Position).Magnitude
            if dist < minDist then
                minDist = dist
            end
        end
    end
    return minDist
end

-- Atualiza partes do AntiVacuum com lógica de portas próximas
function AntiVacuum.UpdateParts()
    local partsToDisable = {}

    for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
        local doors = {}
        local sideroomParts = {}

        -- coleta portas e SideroomSpaces
        for _, child in pairs(room:GetChildren()) do
            if child.Name == "DoorNormal" then
                local doorParts = {}
                for _, p in pairs(child:GetDescendants()) do
                    if p:IsA("BasePart") then
                        table.insert(doorParts, p)
                    end
                end
                if #doorParts > 0 then
                    table.insert(doors, {model = child, parts = doorParts})
                end
            elseif child.Name == "SideroomSpace" then
                for _, p in pairs(child:GetDescendants()) do
                    if p:IsA("BasePart") then
                        table.insert(sideroomParts, p)
                    end
                end
            end
        end

        -- verifica cada porta próxima
        for _, door in pairs(doors) do
            local distance = minDistance(door.parts, sideroomParts)
            if distance <= MAX_DISTANCE then
                -- ativa CanCollide no filho Door
                local doorChild = door.model:FindFirstChild("Door", true)
                if doorChild and doorChild:IsA("BasePart") then
                    doorChild.CanCollide = true
                    doorChild.Anchored = true
                    partsToDisable[doorChild] = true
                end

                -- desativa CanTouch no filho Hidden
                local hiddenChild = door.model:FindFirstChild("Hidden", true)
                if hiddenChild and hiddenChild:IsA("BasePart") then
                    hiddenChild.CanTouch = false
                    partsToDisable[hiddenChild] = true
                end
            end
        end
    end

    return partsToDisable
end

function AntiVacuum.SetVacuumState(enabled)
    local parts = AntiVacuum.UpdateParts()
    if enabled then
        for obj in pairs(parts) do
            if obj and obj.Parent then
                storedParts[obj] = {CanTouch = obj.CanTouch, CanCollide = obj.CanCollide}
                if obj.Name == "Hidden" then
                    obj.CanTouch = false
                else
                    obj.CanCollide = true
                end
            end
        end
    else
        -- restaura estados originais
        for obj, state in pairs(storedParts) do
            if obj and obj.Parent then
                obj.CanTouch = state.CanTouch
                obj.CanCollide = state.CanCollide
            end
        end
        storedParts = {}
    end
end

function AntiVacuum.Enable()
    AntiVacuum.Enabled = true
    if not VacuumLoop then
        VacuumLoop = game:GetService("RunService").Heartbeat:Connect(function()
            if AntiVacuum.Enabled then
                AntiVacuum.SetVacuumState(true)
            end
        end)
    end
end

function AntiVacuum.Disable()
    AntiVacuum.Enabled = false
    if VacuumLoop then
        VacuumLoop:Disconnect()
        VacuumLoop = nil
    end
    AntiVacuum.SetVacuumState(false)
end

-- Toggle
if Floor == "Backdoor" and Anti then
    Anti:AddToggle("AntiVacuum", {
        Text = "Anti Vacuum",
        Default = false,
        Callback = function(v)
            if v then
                AntiVacuum.Enable()
            else
                AntiVacuum.Disable()
            end
        end
    })
end

if Floor == "Hotel" and Anti then
    Anti:AddToggle("AntiSnare", {
        Text = "Anti Snare",
        Default = false,
        Callback = function(v)
            if v then
                AntiSnare.Enable()
            else
                AntiSnare.Disable()
            end
        end
    })
end

if Floor == "Mines" and Anti then
    Anti:AddToggle("AntiGiggleCeiling", {
        Text = "Anti GiggleCeiling",
        Default = false,
        Callback = function(v)
            if v then
                AntiGiggleCeiling.Enable()
            else
                AntiGiggleCeiling.Disable()
            end
        end
    })
end

if (Floor == "Hotel" or Floor == "Mines") and Anti then
    Anti:AddToggle("AntiHalt", {
        Text = "Anti Halt",
        Default = false,
        Callback = function(v)
            if v then
                AntiHalt.Enable()
            else
                AntiHalt.Disable()
            end
        end
    })
end

if (Floor == "Hotel" or Floor == "Mines" or Floor == "Backdoor") and Anti then
    Anti:AddToggle("Anti"..isLookman, {
        Text = "Anti " .. isLookman,
        Default = false,
        Callback = function(v)
            if v then
                AntiEyesLookman.Enable()
            else
                AntiEyesLookman.Disable()
            end
        end
    })
end

-- =================================================================
-- ANTI A90
-- =================================================================
local AntiA90 = {}

do
    local modulesFolder = game:GetService("Players").LocalPlayer
        .PlayerGui.MainUI.Initiator.Main_Game.RemoteListener.Modules

    function AntiA90.Enable()
        local A90Module = modulesFolder:FindFirstChild("A90")
        if A90Module then
            A90Module.Name = "_A90"
        end
    end

    function AntiA90.Disable()
        local A90Module = modulesFolder:FindFirstChild("_A90")
        if A90Module then
            A90Module.Name = "A90"
        end
    end
end

-- =================================================================
-- TOGGLE
-- =================================================================
if (Floor == "Rooms") and Anti then
    Anti:AddToggle("AntiA90", {
        Text = "Anti A90",
        Default = false,
        Callback = function(v)
            if v then
                AntiA90.Enable()
            else
                AntiA90.Disable()
            end
        end
    })
end

if (Floor == "Hotel" or Floor == "Mines") and Jumpscare then
    Jumpscare:AddToggle("NoSpider", {
        Text = "No Timothy",
        Default = false,
        Callback = function(v)
            if v then
                AntiSpider.Enable()
            else
                AntiSpider.Disable()
            end
        end
    })
end

-- MAIN TAB - Aura
local Aura = Tabs.Main:AddRightGroupbox("Aura")

Aura:AddToggle("AutoInteract", {
    Text = "Auto Interact",
    Default = false,
    Callback = function(state)
        if state then
            AutoInteract:Enable()
        else
            AutoInteract:Disable()
        end
    end
})

Aura:AddToggle("InstantInteract", {
    Text = "Instant Interact",
    Default = false,
    Callback = function(state)
        if state then
            InstantInteract:Enable()
        else
            InstantInteract:Disable()
        end
    end
})

Aura:AddSlider("Range", {
    Text = "Range",
    Default = MaxDistance,
    Min = 5,
    Max = 14.5,
    Rounding = 1,
    Compact = true,
    HideMax = true,
    Callback = function(value)
        MaxDistance = value
        AutoInteract.MaxDistance = value
    end
})


-- ESP SYSTEM
local ModelESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/DH-SOARESE/KoltESP-Library/refs/heads/main/Library.lua"))()
local PlayerESP = {}
local DoorESP = nil
local KeyESP = {}
local ItemsESP = {}
local GoldPileESP = {}
local TimerLeverESP = {}
local FuseESP = {}
local GeneratorESP = {}
local HiddenESP = {}
local ChestESP = {}
local ChestObjects = {}
local EntityESP = {}
local AnchorESP = {}
local VacuumDoorRef = nil

local ESPEnabled = {
    Players = false,
    Doors = false,
    Keys = false,
    Items = false,
    GoldPile = false,
    TimerLever = false,
    Fuses = false,
    Generator = false,
    Hidden = false,
    Chest = false,
    Entities = false,
    Anchor = false
}

local FloorList = {
    Hotel = { Min = 0, Max = 99, Lock = true },
    Mines = { Min = 0, Max = 99, Lock = false },
    Backdoor = { Min = 0, Max = 49, Lock = true },
    Rooms = { Min = 0, Max = 999, Lock = false }
}

-- =================================================================
-- DOOR ESP
-- =================================================================

local function updateDoorESP()
    if not ESPEnabled.Doors or not FloorList[Floor] then return end

    if DoorESP then
        ModelESP:Remove(DoorESP)
        DoorESP = nil
    end

    local roomNumber = LatestRoomIndice.Value
    local floorData = FloorList[Floor]

    if roomNumber < floorData.Min or roomNumber > floorData.Max then return end

    local currentRoom = workspace.CurrentRooms:FindFirstChild(tostring(roomNumber))
    if not currentRoom or not currentRoom:FindFirstChild("Door") then return end

    local doorModel = currentRoom.Door

    -- Verifica se o modelo Door tem mais de uma Door
    local doorChildren = doorModel:GetChildren()
    local doorObjects = {}
    for _, child in ipairs(doorChildren) do
        if child.Name == "Door" then
            table.insert(doorObjects, child)
        end
    end

    local target
    if #doorObjects > 1 then
        target = doorModel
    else
        target = doorObjects[1] or doorModel:FindFirstChild("Door") or doorModel
    end

    local doorText = "?"
    local sign = doorModel.Sign and (doorModel.Sign:FindFirstChild("SignText") or doorModel.Sign:FindFirstChild("Stinker"))
    if sign and sign.Text then
        doorText = tostring(sign.Text)
    end

    -- Formata o nome de acordo com o lock
    if floorData.Lock and doorModel:FindFirstChild("Lock") then
        doorText = doorText .. " (Locked)"
    end

    ModelESP:Add(target, {
        Name = doorText,
        DistanceSuffix = ".m",
        DistanceContainer = {Start = "(", End = ")"},
        Color = {
            Name = {0, 255, 0},
            Distance = {0, 255, 0},
            Tracer = {0, 255, 0},
            Highlight = { Filled = {100,255,0}, Outline = {0,255,0} }
        }
    })

    DoorESP = target
end

-- =================================================================
-- GENERAL FUNCTIONS
-- =================================================================

local function addPlayerESP(player)
    if not ESPEnabled.Players or player == LocalPlayer or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or PlayerESP[player] then return end

    ModelESP:Add(player.Character, {
        Name = player.Name,
        Color = {
            Name = {0, 0, 255},
            Distance = {0, 0, 255},
            Tracer = {0, 0, 255},
            Highlight = { Filled = {0,40,80}, Outline = {0,170,255} }
        }
    })

    PlayerESP[player] = true
end

local function removePlayerESP(player)
    if PlayerESP[player] and player.Character then
        ModelESP:Remove(player.Character)
        PlayerESP[player] = nil
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if ESPEnabled.Players then
            task.wait(1)
            addPlayerESP(player)
        end
    end)
end)

Players.PlayerRemoving:Connect(removePlayerESP)

-- =================================================================
-- KEY ESP
-- =================================================================

local function updateKeyESP()
    if not ESPEnabled.Keys then
        for _, key in ipairs(KeyESP) do
            ModelESP:Remove(key)
        end
        KeyESP = {}
        return
    end

    local roomNumber = LatestRoomIndice.Value
    local currentRoom = workspace.CurrentRooms:FindFirstChild(tostring(roomNumber))
    if not currentRoom then return end

    for _, key in ipairs(KeyESP) do
        ModelESP:Remove(key)
    end
    KeyESP = {}

    for _, obj in ipairs(currentRoom:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "KeyObtain" then
            local modulePrompt = obj:FindFirstChild("ModulePrompt")
            local hideESP = false

            if modulePrompt then
                local attrName = "Interactions" .. LocalPlayer.Name
                local value = modulePrompt:GetAttribute(attrName)
                if value and value > 0 then
                    hideESP = true
                end

                modulePrompt:GetAttributeChangedSignal(attrName):Connect(function()
                    local newValue = modulePrompt:GetAttribute(attrName)
                    if newValue and newValue > 0 then
                        ModelESP:Remove(obj)
                        for i, k in ipairs(KeyESP) do
                            if k == obj then table.remove(KeyESP, i) break end
                        end
                    end
                end)
            end

            if not hideESP then
                ModelESP:Add(obj, {
                    Name = "Key",
                    DistanceSuffix = ".m",
                    DistanceContainer = {Start = "(", End = ")"},
                    Color = {
                        Name = {255, 255, 0},
                        Distance = {255, 255, 0},
                        Tracer = {255, 255, 0},
                        Highlight = { Filled = {255, 200, 0}, Outline = {255, 255, 0} }
                    }
                })
                table.insert(KeyESP, obj)
            end
        end
    end
end
-- =================================================================
-- ITEMS ESP
-- =================================================================

local TargetsItems = {}

-- Nome do alvo (Model) / ESP DISPLAYNAME 
if Floor == "Hotel" then
    TargetsItems = {
        ["Vitamins"] = { Name = "Vitamins", Color = {99, 0, 200} },
        ["Bandage"] = { Name = "Bandage", Color = {144, 40, 0} },
        ["Battery"] = { Name = "Battery", Color = {0, 200, 40} },
        ["Lockpick"] = { Name = "Lockpick", Color = {144, 0, 200} },
        ["Flashlight"] = { Name = "Flashlight", Color = {0, 122, 200} },
        ["Lighter"] = { Name = "Lighter", Color = {144, 200, 0} },
        ["CrucifixWall"] = { Name = "Crucifix", Color = {0, 40, 200} }
    }
elseif Floor == "Mines" then
    TargetsItems = {
        ["Vitamins"] = { Name = "Vitamins", Color = {99, 0, 200} },
        ["Bandage"] = { Name = "Bandage", Color = {144, 40, 0} },
        ["Battery"] = { Name = "Battery", Color = {0, 200, 40} },
        ["Lockpick"] = { Name = "Lockpick", Color = {144, 0, 200} },
        ["Flashlight"] = { Name = "Flashlight", Color = {0, 122, 200} },
        ["Lighter"] = { Name = "Lighter", Color = {144, 200, 0} },
        ["CrucifixWall"] = { Name = "Crucifix", Color = {0, 40, 200} },
        -- Mais...
    }
elseif Floor == "Backdoor" then
    TargetsItems = {
        ["StarVial"] = { Name = "Bottle", Color = {145, 200, 0} }
    }
elseif Floor == "Rooms" then
    TargetsItems = {
        ["Bandage"] = { Name = "Bandage", Color = {144, 40, 0} },
        ["Battery"] = { Name = "Battery", Color = {0, 200, 40} }
    }
end

local function updateItemsESP()
    if not ESPEnabled.Items then
        for obj in pairs(ItemsESP) do
            ModelESP:Remove(obj)
        end
        ItemsESP = {}
        return
    end

    local currentRoomIndex = LocalPlayer:GetAttribute("CurrentRoom")
    if not currentRoomIndex then return end

    local currentRoom = workspace.CurrentRooms:FindFirstChild(tostring(currentRoomIndex))
    if not currentRoom then return end

    -- Procura por modelos que estão na lista TargetsItems
    for _, obj in ipairs(currentRoom:GetDescendants()) do
        if obj:IsA("Model") and TargetsItems[obj.Name] and not ItemsESP[obj] then
            local data = TargetsItems[obj.Name]
            ModelESP:Add(obj, {
                Name = data.Name,
                DistanceSuffix = ".m",
                DistanceContainer = { Start = "(", End = ")" },
                Color = {
                    Text = data.Color,
                    Distance = data.Color,
                    Tracer = data.Color,
                    Highlight = { Filled = data.Color, Outline = data.Color }
                }
            })
            ItemsESP[obj] = true
        end
    end

    -- Remove ESP de itens que já não estão mais na sala
    for obj in pairs(ItemsESP) do
        if not obj:IsDescendantOf(currentRoom) then
            ModelESP:Remove(obj)
            ItemsESP[obj] = nil
        end
    end
end

-- Loop contínuo para atualizar os itens
task.spawn(function()
    while true do
        task.wait(1)
        if ESPEnabled.Items then
            updateItemsESP()
        end
    end
end)
-- =================================================================
-- GOLD PILE ESP
-- =================================================================

local function updateGoldPileESP()
    if not ESPEnabled.GoldPile then
        for gold in pairs(GoldPileESP) do
            ModelESP:Remove(gold)
        end
        GoldPileESP = {}
        return
    end

    local currentRoomIndex = LocalPlayer:GetAttribute("CurrentRoom")
    if not currentRoomIndex then return end

    local currentRoom = workspace.CurrentRooms:FindFirstChild(tostring(currentRoomIndex))
    if not currentRoom then return end

    for _, obj in ipairs(currentRoom:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "GoldPile" and not GoldPileESP[obj] then
            ModelESP:Add(obj, {
                Name = "Gold",
                DistanceSuffix = ".m",
                DistanceContainer = {Start = "(", End = ")"},
                Color = {
                    Name = {255, 215, 0},
                    Distance = {255, 215, 0},
                    Tracer = {255, 215, 0},
                    Highlight = { Filled = {255, 250, 100}, Outline = {255, 215, 0} }
                }
            })
            GoldPileESP[obj] = true
        end
    end

    for gold in pairs(GoldPileESP) do
        if not gold:IsDescendantOf(currentRoom) then
            ModelESP:Remove(gold)
            GoldPileESP[gold] = nil
        end
    end
end

task.spawn(function()
    while true do
        task.wait(1)
        if ESPEnabled.GoldPile then
            updateGoldPileESP()
        end
    end
end)

-- =================================================================
-- TIMER LEVER ESP
-- =================================================================

local function updateTimerLeverESP()
    if not ESPEnabled.TimerLever then
        for lever in pairs(TimerLeverESP) do
            ModelESP:Remove(lever)
        end
        TimerLeverESP = {}
        return
    end

    local roomNumber = LatestRoomIndice.Value
    local currentRoom = workspace.CurrentRooms:FindFirstChild(tostring(roomNumber))
    if not currentRoom then return end

    for _, obj in ipairs(currentRoom:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "TimerLever" then
            local prompt = obj:FindFirstChild("ActivateEventPrompt")
            local interactions = prompt and prompt:GetAttribute("Interactions") or 0

            if interactions > 0 then
                if TimerLeverESP[obj] then
                    ModelESP:Remove(obj)
                    TimerLeverESP[obj] = nil
                end
            else
                if not TimerLeverESP[obj] then
                    ModelESP:Add(obj, {
                        Name = "Timer Lever",
                        DistanceSuffix = ".m",
                        DistanceContainer = {Start = "(", End = ")"},
                        Color = {
                            Name = {0, 200, 255},
                            Distance = {0, 150, 255},
                            Tracer = {0, 255, 255},
                            Highlight = { Filled = {0, 100, 255}, Outline = {0, 200, 255} }
                        }
                    })
                    TimerLeverESP[obj] = true
                end
            end
        end
    end
end

task.spawn(function()
    while true do
        task.wait(1)
        if ESPEnabled.TimerLever then
            updateTimerLeverESP()
        end
    end
end)

-- =================================================================
-- FUSE ESP
-- =================================================================

local FuseScanTask = nil

local function monitorFuseModel(fuseModelPart, fuseObj)
    task.spawn(function()
        while fuseObj.Parent do
            local ltm = fuseModelPart.LocalTransparencyModifier
            if ltm and ltm >= 0.99 then
                if FuseESP[fuseObj] then
                    ModelESP:Remove(fuseObj)
                    FuseESP[fuseObj] = nil
                end
                break
            end
            task.wait(0.05)
        end
    end)
end

local function updateFuseESPOnce(currentRoom)
    local count = 0
    for _, obj in ipairs(currentRoom:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "FuseObtain" then
            local fuseModelPart = obj:FindFirstChild("FuseModel", true)
            if fuseModelPart then
                if not FuseESP[obj] then
                    ModelESP:Add(obj, {
                        Name = "Fuse",
                        DistanceSuffix = ".m",
                        DistanceContainer = {Start = "(", End = ")"},
                        Color = {
                            Name = {255, 165, 0},
                            Distance = {255, 165, 0},
                            Tracer = {255, 165, 0},
                            Highlight = { Filled = {255, 200, 0}, Outline = {255, 165, 0} }
                        }
                    })
                    FuseESP[obj] = true
                    count = count + 1
                    monitorFuseModel(fuseModelPart, obj)
                end
            end
            if count >= 3 then break end
        end
    end
end

local function startFuseScan()
    if FuseScanTask then
        task.cancel(FuseScanTask)
        FuseScanTask = nil
    end

    local currentRoomIndex = LocalPlayer:GetAttribute("CurrentRoom")
    if not currentRoomIndex then return end

    local currentRoom = workspace.CurrentRooms:FindFirstChild(tostring(currentRoomIndex))
    if not currentRoom then return end

    local startTime = tick()
    FuseScanTask = task.spawn(function()
        while tick() - startTime < 7 do
            if ESPEnabled.Fuses then
                updateFuseESPOnce(currentRoom)
            end
            task.wait(0.5)
        end
        FuseScanTask = nil
    end)
end

-- Limpeza contínua de fuses fora da sala
task.spawn(function()
    while true do
        task.wait(1)
        if ESPEnabled.Fuses then
            local currentRoomIndex = LocalPlayer:GetAttribute("CurrentRoom")
            local currentRoom = workspace.CurrentRooms:FindFirstChild(tostring(currentRoomIndex))
            for fuse in pairs(FuseESP) do
                if not fuse:IsDescendantOf(currentRoom) then
                    ModelESP:Remove(fuse)
                    FuseESP[fuse] = nil
                end
            end
        end
    end
end)

-- =================================================================
-- GENERATOR ESP
-- =================================================================

local function monitorGeneratorSound(generator)
    local generatorMain = generator:FindFirstChild("GeneratorMain")
    if not generatorMain then return end

    local sound = generatorMain:FindFirstChild("Sound")
    if not sound then return end

    if generator:GetAttribute("ESPDisabled") == nil then
        generator:SetAttribute("ESPDisabled", false)
    end

    local function checkSoundAndUpdateESP()
        if sound.Playing then
            generator:SetAttribute("ESPDisabled", true)
            if GeneratorESP[generator] then
                ModelESP:Remove(generator)
                GeneratorESP[generator] = nil
            end
        end
    end

    checkSoundAndUpdateESP()

    sound:GetPropertyChangedSignal("Playing"):Connect(checkSoundAndUpdateESP)
end

local function updateGeneratorESP()
    if not ESPEnabled.Generator then
        for gen in pairs(GeneratorESP) do
            ModelESP:Remove(gen)
        end
        GeneratorESP = {}
        return
    end

    local currentRoomIndex = LocalPlayer:GetAttribute("CurrentRoom")
    if not currentRoomIndex then return end

    local currentRoom = workspace.CurrentRooms:FindFirstChild(tostring(currentRoomIndex))
    if not currentRoom then return end

    local generator = currentRoom:FindFirstChild("Assets") and currentRoom.Assets:FindFirstChild("MinesGenerator")
    if generator then
        if generator:GetAttribute("ESPDisabled") == nil then
            generator:SetAttribute("ESPDisabled", false)
        end

        if not generator:GetAttribute("ESPDisabled") and not GeneratorESP[generator] then
            ModelESP:Add(generator, {
                Name = "Generator",
                DistanceSuffix = ".m",
                DistanceContainer = {Start = "(", End = ")"},
                Color = {
                    Name = {122, 0, 255},
                    Distance = {122, 0, 255},
                    Tracer = {122, 0, 255},
                    Highlight = { Filled = {50, 0, 200}, Outline = {122, 0, 255} }
                }
            })
            GeneratorESP[generator] = true
            monitorGeneratorSound(generator)
        elseif not GeneratorESP[generator] then
            monitorGeneratorSound(generator)
        end
    end

    for gen in pairs(GeneratorESP) do
        if not gen:IsDescendantOf(currentRoom) then
            ModelESP:Remove(gen)
            GeneratorESP[gen] = nil
        end
    end
end

-- =================================================================
-- HIDDEN SPOTS ESP
-- =================================================================

local HiddenTargetsByFloor = {
    Hotel = {
        Wardrobe = {Name = "Closet", Color = {0, 40, 255}},
        Bed = {Name = "Bed", Color = {144, 0, 255}},
        Toolshed = {Name = "Toolshed", Color = {144, 0, 255}},
    },
    Mines = {
        Locker_Large = {Name = "Locker", Color = {0, 40, 255}},
        Toolshed = {Name = "Closet", Color = {144, 0, 255}},
        CircularVent = {Name = "Vent", Color = {144, 0, 255}},
        Dumpster = {Name = "Dumpster", Color = {144, 0, 255}},
    },
    Backdoor = {
        Backdoor_Wardrobe = {Name = "Closet", Color = {0, 40, 255}},
    },
    Rooms = {
        Rooms_Locker = {Name = "Locker", Color = {0, 40, 255}},
        Rooms_Locker_Fridge = {Name = "Locker", Color = {0, 40, 255}},
    }
}

local function applyHiddenOverlay(model, color, displayName)
    if HiddenESP[model] then
        ModelESP:UpdateConfig(model, {
            Name = displayName,
            DistanceSuffix = ".m",
            DistanceContainer = {Start = "(", End = ")"},
            Color = {
                Name = color,
                Distance = color,
                Tracer = color,
                Highlight = {Filled = color, Outline = color}
            }
        })
    else
        ModelESP:Add(model, {
            Name = displayName,
            DistanceSuffix = ".m",
            DistanceContainer = {Start = "(", End = ")"},
            Color = {
                Name = color,
                Distance = color,
                Tracer = color,
                Highlight = {Filled = color, Outline = color}
            }
        })
        HiddenESP[model] = model
    end
end

local function updateHiddenESP()
    if not ESPEnabled.Hidden then
        for _, target in pairs(HiddenESP) do
            ModelESP:Remove(target)
        end
        HiddenESP = {}
        return
    end

    local currentRoomIndex = LocalPlayer:GetAttribute("CurrentRoom")
    if not currentRoomIndex then return end

    local currentRoom = workspace.CurrentRooms:FindFirstChild(tostring(currentRoomIndex))
    if not currentRoom then return end

    local HiddenTargets = HiddenTargetsByFloor[Floor] or {}
    
    for name, data in pairs(HiddenTargets) do
        for _, obj in ipairs(currentRoom:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == name then
                local finalName = data.Name
                local finalColor = data.Color

                if EntityHidden and obj:FindFirstChild("HideEntityOnSpot", true) then
                    finalName = data.Name .. " (Hide)"
                    finalColor = {255, 0, 0}
                end

                applyHiddenOverlay(obj, finalColor, finalName)
            end
        end
    end

    for obj in pairs(HiddenESP) do
        local room = obj:FindFirstAncestorWhichIsA("Model")
        local removeESP = not obj:IsDescendantOf(workspace) 
                          or (room and room.Parent == workspace.CurrentRooms and tonumber(room.Name) < currentRoomIndex)
        if removeESP then
            ModelESP:Remove(obj)
            HiddenESP[obj] = nil
        end
    end
end

task.spawn(function()
    while true do
        task.wait(0.5)
        if ESPEnabled.Hidden then
            updateHiddenESP()
        end
    end
end)

-- =================================================================
-- CHEST/TOOLBOX ESP
-- =================================================================

local ChestTargets = {}

if Floor == "Hotel" then
    ChestTargets = {
        ["ChestBox"]        = {Name = "ChestBox", Color = {0, 255, 255}},
        ["ChestBoxLocked"]  = {Name = "ChestBox (Locked)", Color = {0, 150, 255}}
    }
elseif Floor == "Mines" then
    ChestTargets = {
        ["Toolbox"]         = {Name = "Toolbox", Color = {0, 200, 255}},
        ["Toolbox_Locked"]  = {Name = "Toolbox (Locked)", Color = {0, 120, 255}},
        ["Chest_Vine"] = {Name = "Chest (Blocked)", Color = {0, 120, 255}}
    }
end

local function applyChestOverlay(model, data)
    ModelESP:Add(model, {
        Name = data.Name,
        DistanceSuffix = ".m",
        DistanceContainer = {Start = "(", End = ")"},
        Color = {
            Name = data.Color,
            Distance = data.Color,
            Tracer = data.Color,
            Highlight = {Filled = data.Color, Outline = data.Color}
        }
    })
end

local function shouldHideChestESP(obj)
    local promptTypes = {"ModulePrompt", "ActivateEventPrompt"}
    for _, promptName in ipairs(promptTypes) do
        local prompt = obj:FindFirstChild(promptName)
        if prompt then
            local value = prompt:GetAttribute("Interactions")
            if value and value > 0 then
                return true
            end
            prompt:GetAttributeChangedSignal("Interactions"):Connect(function()
                local newValue = prompt:GetAttribute("Interactions")
                if newValue and newValue > 0 and ChestESP[obj] then
                    ModelESP:Remove(obj)
                    ChestESP[obj] = nil
                    ChestObjects[obj] = nil
                end
            end)
        end
    end
    return false
end

local function updateChestESP()
    if not ESPEnabled.Chest then
        for obj in pairs(ChestESP) do
            ModelESP:Remove(obj)
        end
        ChestESP = {}
        ChestObjects = {}
        return
    end

    local currentRoomIndex = LocalPlayer:GetAttribute("CurrentRoom")
    if not currentRoomIndex then return end

    local currentRoom = workspace.CurrentRooms:FindFirstChild(tostring(currentRoomIndex))
    if not currentRoom then return end

    for name, data in pairs(ChestTargets) do
        for _, obj in ipairs(currentRoom:GetDescendants()) do
            if obj.Name == name and obj:IsA("Model") then
                ChestObjects[obj] = data
            end
        end
    end

    for obj, data in pairs(ChestObjects) do
        if obj:IsDescendantOf(workspace) and not ChestESP[obj] and not shouldHideChestESP(obj) then
            applyChestOverlay(obj, data)
            ChestESP[obj] = true
        end
    end

    for obj in pairs(ChestESP) do
        if not obj:IsDescendantOf(workspace) then
            ModelESP:Remove(obj)
            ChestESP[obj] = nil
            ChestObjects[obj] = nil
        end
    end
end

task.spawn(function()
    while true do
        task.wait(1)
        if ESPEnabled.Chest then
            updateChestESP()
        end
    end
end)

-- =================================================================
-- MINES ANCHOR ESP
-- =================================================================

local function updateAnchorESP()
    if not ESPEnabled.Anchor then
        for anchor in pairs(AnchorESP) do
            ModelESP:Remove(anchor)
        end
        AnchorESP = {}
        return
    end

    local currentRoomIndex = LocalPlayer:GetAttribute("CurrentRoom")
    if currentRoomIndex ~= 50 then
        for anchor in pairs(AnchorESP) do
            ModelESP:Remove(anchor)
        end
        AnchorESP = {}
        return
    end

    local currentRoom = workspace.CurrentRooms:FindFirstChild(tostring(currentRoomIndex))
    if not currentRoom then return end

    for _, obj in ipairs(currentRoom:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "MinesAnchor" and not AnchorESP[obj] then
            ModelESP:Add(obj, {
                Name = "Anchor",
                DistanceSuffix = ".m",
                DistanceContainer = {Start = "(", End = ")"},
                Color = {
                    Name = {255, 105, 180},
                    Distance = {255, 105, 180},
                    Tracer = {255, 105, 180},
                    Highlight = {Filled = {255, 182, 193}, Outline = {255, 105, 180}}
                }
            })
            AnchorESP[obj] = true
        end
    end

    for obj in pairs(AnchorESP) do
        if not obj:IsDescendantOf(currentRoom) then
            ModelESP:Remove(obj)
            AnchorESP[obj] = nil
        end
    end
end

task.spawn(function()
    while true do
        task.wait(1)
        if ESPEnabled.Anchor then
            updateAnchorESP()
        end
    end
end)

-- =================================================================
-- ENTITY ESP
-- =================================================================

local TargetEntities = {}

if Floor == "Hotel" then
    TargetEntities = {
        Workspace = {
            RushMoving = { Name = "Rush", Color = {255, 0, 0}, Entity2D = true },
            AmbushMoving = { Name = "Ambush", Color = {255, 0, 0}, Entity2D = true },
            Eyes = { Name = "Eyes", Color = {255, 0, 0}, Entity2D = true },
            SeekMovingNewClone = { Name = "Seek", Color = {255, 165, 0}, Entity2D = false },
        },
        Room = {
            FigureRig = { Name = "Figure", Color = {0, 255, 0}, Entity2D = false },
            Snare = { Name = "Snare", Color = {255, 0, 0}, Entity2D = true },
            DoorFake = { Name = "Dupe", Color = {255, 0, 0}, Entity2D = false },
        }
    }
elseif Floor == "Mines" then
    TargetEntities = {
        Workspace = {
            RushMoving = { Name = "Rush", Color = {255, 0, 0}, Entity2D = true },
            AmbushMoving = { Name = "Ambush", Color = {255, 0, 0}, Entity2D = true },
            Eyes = { Name = "Eyes", Color = {255, 0, 0}, Entity2D = true },
            SeekMovingNewClone = { Name = "Seek", Color = {255, 165, 0}, Entity2D = false },
        },
        Room = {
            FigureRig = { Name = "Figure", Color = {0, 255, 0}, Entity2D = false },
            GloomPile = { Name = "GloomPile", Color = {138, 43, 226}, Entity2D = false },
            GiggleCeiling = { Name = "Giggle", Color = {255, 215, 0}, Entity2D = false },
            DoorFake = { Name = "Dupe", Color = {255, 0, 0}, Entity2D = false },
            GrumbleRig = { Name = "Grumble", Color = {0, 255, 0}, Entity2D = false },
        }
    }
elseif Floor == "Backdoor" then
    TargetEntities = {
        Workspace = {
            BackdoorRush = { Name = "Blitz", Color = {255, 0, 0}, Entity2D = true },
            BackdoorLookman = { Name = "Lookman", Color = {255, 0, 0}, Entity2D = true },
            EntityModel = { Name = "Haste", Color = {255, 0, 0}, Entity2D = true },
        },
        Room = {
            VacuumDoor = { Name = "Vacuum", Color = {0, 200, 255}, Entity2D = false },
        }
    }
elseif Floor == "Rooms" then
    TargetEntities = {
        Workspace = {
            A120 = { Name = "A120", Color = {255, 0, 0}, Entity2D = true },
            A60 = { Name = "A60", Color = {255, 0, 0}, Entity2D = true },
        },
        Room = {}
    }
end

local function applyEntityOverlay(obj, data)
    ModelESP:Add(obj, {
        Name = data.Name,
        DistanceSuffix = ".m",
        DistanceContainer = { Start = "(", End = ")" },
        Collision = data.Entity2D,
        Color = {
            Name = data.Color,
            Distance = data.Color,
            Tracer = data.Color,
            Highlight = { Filled = data.Color, Outline = data.Color }
        }
    })
end

local lastRoomIndex = nil

local function updateEntityESP()
    if not ESPEnabled.Entities then
        for _, target in pairs(EntityESP) do
            ModelESP:Remove(target)
        end
        EntityESP = {}
        return
    end

    local currentRoomIndex = LocalPlayer:GetAttribute("CurrentRoom")
    local currentRoom = workspace.CurrentRooms:FindFirstChild(tostring(currentRoomIndex))

    if currentRoomIndex ~= lastRoomIndex then
        for obj in pairs(EntityESP) do
            ModelESP:Remove(obj)
        end
        EntityESP = {}
        lastRoomIndex = currentRoomIndex
    end

    for obj in pairs(EntityESP) do
        if not obj:IsDescendantOf(workspace) then
            ModelESP:Remove(obj)
            EntityESP[obj] = nil
        end
    end

    for name, data in pairs(TargetEntities.Workspace or {}) do
        local obj = workspace:FindFirstChild(name, true)
        if obj and obj:IsA("Model") and not EntityESP[obj] then
            applyEntityOverlay(obj, data)
            EntityESP[obj] = obj
        end
    end

    if currentRoom then
        for name, data in pairs(TargetEntities.Room or {}) do
            if name ~= "VacuumDoor" then
                for _, obj in ipairs(currentRoom:GetDescendants()) do
                    if obj:IsA("Model") and obj.Name == name and not EntityESP[obj] then
                        applyEntityOverlay(obj, data)
                        EntityESP[obj] = obj
                    end
                end
            end
        end
    end

    if VacuumDoorRef and VacuumDoorRef:IsA("Model") and TargetEntities.Room.VacuumDoor and not EntityESP[VacuumDoorRef] then
        applyEntityOverlay(VacuumDoorRef, TargetEntities.Room.VacuumDoor)
        EntityESP[VacuumDoorRef] = VacuumDoorRef
    end
end

task.spawn(function()
    while true do
        task.wait(0.3)
        if ESPEnabled.Entities then
            updateEntityESP()
        end
    end
end)

-- Hook for VacuumDoor
local oldUpdateParts = AntiVacuum.UpdateParts
AntiVacuum.UpdateParts = function(...)
    local parts = oldUpdateParts(...)
    for obj in pairs(parts) do
        local model = obj:FindFirstAncestor("DoorNormal")
        if model then
            VacuumDoorRef = model
        end
    end
    return parts
end

-- =================================================================
-- CONNECTIONS AND INITIAL UPDATES
-- =================================================================

LatestRoomIndice:GetPropertyChangedSignal("Value"):Connect(function()
    updateDoorESP()
    updateKeyESP()
    updateTimerLeverESP()
end)

LocalPlayer:GetAttributeChangedSignal("CurrentRoom"):Connect(function()
    if ESPEnabled.GoldPile then
        task.delay(0.2, updateGoldPileESP)
    end
    if ESPEnabled.Fuses then
        startFuseScan()
    end
    if ESPEnabled.Generator then
        task.delay(0.2, updateGeneratorESP)
    end
end)

task.delay(1, function()
    updateDoorESP()
    updateKeyESP()
end)

-- =================================================================
-- VISUAL TAB - GUI ELEMENTS
-- =================================================================

local TargetsESP = Tabs.Visual:AddRightGroupbox("Targets")
local Settings   = Tabs.Visual:AddLeftGroupbox("ESP Settings")

-- ================================================================
-- HOTEL
-- ================================================================
if Floor == "Hotel" then
    TargetsESP:AddToggle("EspDoor", {
        Text = "Show Doors",
        Default = ESPEnabled.Doors,
        Callback = function(value)
            ESPEnabled.Doors = value
            if value then updateDoorESP()
            elseif DoorESP then ModelESP:Remove(DoorESP) DoorESP = nil end
        end
    })

    TargetsESP:AddToggle("EspKey", {
        Text = "Show Keys",
        Default = ESPEnabled.Keys,
        Callback = function(value)
            ESPEnabled.Keys = value
            updateKeyESP()
        end
    })
    
    TargetsESP:AddToggle("EspItems", {
        Text = "Show Items",
        Default = ESPEnabled.Items,
        Callback = function(value)
            ESPEnabled.Items = value
            updateItemsESP()
        end
    })

    TargetsESP:AddToggle("EspGoldPile", {
        Text = "Show Gold Pile",
        Default = ESPEnabled.GoldPile,
        Callback = function(value)
            ESPEnabled.GoldPile = value
            updateGoldPileESP()
        end
    })

    TargetsESP:AddToggle("EspHiddenSpots", {
        Text = "Show Hidden Spots",
        Default = ESPEnabled.Hidden,
        Callback = function(value)
            ESPEnabled.Hidden = value
            updateHiddenESP()
        end
    })

    TargetsESP:AddToggle("EspEntities", {
        Text = "Show Entities",
        Default = ESPEnabled.Entities,
        Callback = function(value)
            ESPEnabled.Entities = value
            EntityHidden = value
            updateEntityESP()
        end
    })

    TargetsESP:AddToggle("EspChestBox", {
        Text = "Show ChestBox",
        Default = ESPEnabled.Chest,
        Callback = function(value)
            ESPEnabled.Chest = value
            updateChestESP()
        end
    })

    if #Players:GetPlayers() > 1 then
        TargetsESP:AddToggle("EspPlayers", {
            Text = "Show Players",
            Default = ESPEnabled.Players,
            Callback = function(value)
                ESPEnabled.Players = value
                if value then
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer then addPlayerESP(player) end
                    end
                else
                    for _, player in ipairs(Players:GetPlayers()) do
                        removePlayerESP(player)
                    end
                end
            end
        })
    end
end

-- ================================================================
-- MINES
-- ================================================================
if Floor == "Mines" then
    TargetsESP:AddToggle("EspDoor", {
        Text = "Show Doors",
        Default = ESPEnabled.Doors,
        Callback = function(value)
            ESPEnabled.Doors = value
            if value then updateDoorESP()
            elseif DoorESP then ModelESP:Remove(DoorESP) DoorESP = nil end
        end
    })

    TargetsESP:AddToggle("EspGenerator", {
        Text = "Show Generator",
        Default = ESPEnabled.Generator,
        Callback = function(value)
            ESPEnabled.Generator = value
            updateGeneratorESP()
        end
    })

    TargetsESP:AddToggle("EspFuses", {
        Text = "Show Fuses",
        Default = ESPEnabled.Fuses,
        Callback = function(value)
            ESPEnabled.Fuses = value
            startFuseScan()
        end
    })
    
    TargetsESP:AddToggle("EspItems", {
        Text = "Show Items",
        Default = ESPEnabled.Items,
        Callback = function(value)
            ESPEnabled.Items = value
            updateItemsESP()
        end
    })

    TargetsESP:AddToggle("EspGoldPile", {
        Text = "Show Gold Pile",
        Default = ESPEnabled.GoldPile,
        Callback = function(value)
            ESPEnabled.GoldPile = value
            updateGoldPileESP()
        end
    })

    TargetsESP:AddToggle("EspHiddenSpots", {
        Text = "Show Hidden Spots",
        Default = ESPEnabled.Hidden,
        Callback = function(value)
            ESPEnabled.Hidden = value
            updateHiddenESP()
        end
    })

    TargetsESP:AddToggle("EspEntities", {
        Text = "Show Entities",
        Default = ESPEnabled.Entities,
        Callback = function(value)
            ESPEnabled.Entities = value
            EntityHidden = value
            updateEntityESP()
        end
    })

    TargetsESP:AddToggle("EspChestBox", {
        Text = "Show Toolbox",
        Default = ESPEnabled.Chest,
        Callback = function(value)
            ESPEnabled.Chest = value
            updateChestESP()
        end
    })

    if #Players:GetPlayers() > 1 then
        TargetsESP:AddToggle("EspPlayers", {
            Text = "Show Players",
            Default = ESPEnabled.Players,
            Callback = function(value)
                ESPEnabled.Players = value
                if value then
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer then addPlayerESP(player) end
                    end
                else
                    for _, player in ipairs(Players:GetPlayers()) do
                        removePlayerESP(player)
                    end
                end
            end
        })
    end
end

-- ================================================================
-- BACKDOOR
-- ================================================================
if Floor == "Backdoor" then
    TargetsESP:AddToggle("EspDoor", {
        Text = "Show Doors",
        Default = ESPEnabled.Doors,
        Callback = function(value)
            ESPEnabled.Doors = value
            if value then updateDoorESP()
            elseif DoorESP then ModelESP:Remove(DoorESP) DoorESP = nil end
        end
    })

    TargetsESP:AddToggle("EspKey", {
        Text = "Show Keys",
        Default = ESPEnabled.Keys,
        Callback = function(value)
            ESPEnabled.Keys = value
            updateKeyESP()
        end
    })
    
    TargetsESP:AddToggle("EspItems", {
        Text = "Show Items",
        Default = ESPEnabled.Items,
        Callback = function(value)
            ESPEnabled.Items = value
            updateItemsESP()
        end
    })

    TargetsESP:AddToggle("EspGoldPile", {
        Text = "Show Gold Pile",
        Default = ESPEnabled.GoldPile,
        Callback = function(value)
            ESPEnabled.GoldPile = value
            updateGoldPileESP()
        end
    })

    TargetsESP:AddToggle("EspHiddenSpots", {
        Text = "Show Hidden Spots",
        Default = ESPEnabled.Hidden,
        Callback = function(value)
            ESPEnabled.Hidden = value
            updateHiddenESP()
        end
    })

    TargetsESP:AddToggle("EspEntities", {
        Text = "Show Entities",
        Default = ESPEnabled.Entities,
        Callback = function(value)
            ESPEnabled.Entities = value
            EntityHidden = value
            updateEntityESP()
        end
    })

    TargetsESP:AddToggle("EspTimerLever", {
        Text = "Show Timer Lever",
        Default = ESPEnabled.TimerLever,
        Callback = function(value)
            ESPEnabled.TimerLever = value
            updateTimerLeverESP()
        end
    })

    if #Players:GetPlayers() > 1 then
        TargetsESP:AddToggle("EspPlayers", {
            Text = "Show Players",
            Default = ESPEnabled.Players,
            Callback = function(value)
                ESPEnabled.Players = value
                if value then
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer then addPlayerESP(player) end
                    end
                else
                    for _, player in ipairs(Players:GetPlayers()) do
                        removePlayerESP(player)
                    end
                end
            end
        })
    end
end

-- ================================================================
-- ROOMS
-- ================================================================
if Floor == "Rooms" then
    TargetsESP:AddToggle("EspDoor", {
        Text = "Show Doors",
        Default = ESPEnabled.Doors,
        Callback = function(value)
            ESPEnabled.Doors = value
            if value then updateDoorESP()
            elseif DoorESP then ModelESP:Remove(DoorESP) DoorESP = nil end
        end
    })
    
    TargetsESP:AddToggle("EspItems", {
        Text = "Show Items",
        Default = ESPEnabled.Items,
        Callback = function(value)
            ESPEnabled.Items = value
            updateItemsESP()
        end
    })

    TargetsESP:AddToggle("EspGoldPile", {
        Text = "Show Gold Pile",
        Default = ESPEnabled.GoldPile,
        Callback = function(value)
            ESPEnabled.GoldPile = value
            updateGoldPileESP()
        end
    })

    TargetsESP:AddToggle("EspHiddenSpots", {
        Text = "Show Hidden Spots",
        Default = ESPEnabled.Hidden,
        Callback = function(value)
            ESPEnabled.Hidden = value
            updateHiddenESP()
        end
    })

    TargetsESP:AddToggle("EspEntities", {
        Text = "Show Entities",
        Default = ESPEnabled.Entities,
        Callback = function(value)
            ESPEnabled.Entities = value
            EntityHidden = value
            updateEntityESP()
        end
    })
end

-- =================================================================
-- SETTINGS GROUP
-- =================================================================
ModelESP:SetHighlightFolderName("Kolt DOORS")
ModelESP:SetGlobalESPType("ShowTracer", false)
ModelESP:SetGlobalESPType("ShowName", true)
ModelESP:SetGlobalESPType("ShowDistance", true)
ModelESP:SetGlobalESPType("ShowHighlightFill", true)
ModelESP:SetGlobalESPType("ShowHighlightOutline", true)
ModelESP:SetGlobalHighlightTransparency({Filled = 0.7, Outline = 0.3}) 
ModelESP:SetGlobalTracerOrigin("Top")
ModelESP.GlobalSettings.MaxDistance = 300
ModelESP.GlobalSettings.MinDistance = 5

Settings:AddToggle("EspHighlightOutline", {
    Text = "ESP Chams Outline",
    Default = true,
    Callback = function(value)
        ModelESP:SetGlobalESPType("ShowHighlightOutline", value)
    end
})

Settings:AddToggle("EspHighlightFill", {
    Text = "ESP Chams Filled",
    Default = true,
    Callback = function(value)
        ModelESP:SetGlobalESPType("ShowHighlightFill", value)
    end
})

Settings:AddToggle("EspName", {
    Text = "ESP Name",
    Default = true,
    Callback = function(value)
        ModelESP:SetGlobalESPType("ShowName", value)
    end
})

Settings:AddToggle("EspDistance", {
    Text = "ESP Distance",
    Default = true,
    Callback = function(value)
        ModelESP:SetGlobalESPType("ShowDistance", value)
    end
})

Settings:AddToggle("EspTracer", {
    Text = "ESP Tracer",
    Default = false,
    Callback = function(value)
        ModelESP:SetGlobalESPType("ShowTracer", value)
    end
})

Settings:AddDropdown("EspTracerOrigin", {
    Values = {"Top", "Center", "Bottom"},
    Default = "Top",
    Multi = false,
    Callback = function(value)
        ModelESP:SetGlobalTracerOrigin(value)
    end
})

Settings:AddDivider()

Settings:AddToggle("RainbowEsp", {
    Text = "Rainbow Color",
    Default = false,
    Callback = function(value)
        ModelESP:SetGlobalRainbow(value)
    end
})

Settings:AddSlider("EspMaxDistance", {
    Text = "Max Distance",
    Min = 1,
    Max = 1500,
    Default = 300,
    HideMax = true,
    Suffix = ".m",
    Rounding = 1,
    Callback = function(value)
        ModelESP.GlobalSettings.MaxDistance = value
    end
})

-- UI SETTINGS TAB
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")

MenuGroup:AddToggle("KeybindMenuOpen", {
    Text = "Open Keybind Menu",
    Default = Library.KeybindFrame.Visible,
    Callback = function(value)
        Library.KeybindFrame.Visible = value
    end
})

MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Callback = function(value)
        Library.ShowCustomCursor = value
    end
})

MenuGroup:AddDivider()

MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI = true,
    Text = "Menu keybind"
})

MenuGroup:AddButton("Unload", function()
    _G.Menu = false

    -- Desativa todas as flags de ESP
    for k, _ in pairs(ESPEnabled) do
        ESPEnabled[k] = false
    end

    -- Remove todos os ESPs de players
    for playerName, _ in pairs(PlayerESP) do
        local player = Players:FindFirstChild(playerName)
        if player then
            removePlayerESP(player)
        end
    end
    PlayerESP = {}

    -- Remove DoorESP
    if DoorESP then
        ModelESP:Remove(DoorESP)
        DoorESP = nil
    end

    -- Remove KeyESP
    for _, key in ipairs(KeyESP) do
        ModelESP:Remove(key)
    end
    KeyESP = {}

    -- Remove GoldPileESP
    for gold, _ in pairs(GoldPileESP) do
        ModelESP:Remove(gold)
    end
    GoldPileESP = {}

    -- Remove TimerLeverESP
    for lever, _ in pairs(TimerLeverESP) do
        ModelESP:Remove(lever)
    end
    TimerLeverESP = {}

    -- Remove FuseESP
    for fuse, _ in pairs(FuseESP) do
        ModelESP:Remove(fuse)
    end
    FuseESP = {}

    -- Remove GeneratorESP
    for gen, _ in pairs(GeneratorESP) do
        ModelESP:Remove(gen)
    end
    GeneratorESP = {}

    -- Remove HiddenESP
    for _, hidden in pairs(HiddenESP) do
        ModelESP:Remove(hidden)
    end
    HiddenESP = {}
    -- Remove ChestESP
    for chest, _ in pairs(ChestESP) do
        ModelESP:Remove(chest)
    end
    ChestESP = {}
    ChestObjects = {}

    -- Remove AnchorESP
    for anchor, _ in pairs(AnchorESP) do
        ModelESP:Remove(anchor)
    end
    AnchorESP = {}

    -- Remove EntityESP
    for _, entity in pairs(EntityESP) do
        ModelESP:Remove(entity)
    end
    EntityESP = {}

    VacuumDoorRef = nil

    -- Desativa todas as funcionalidades
    local disableList = {
        Fullbright, NoFog, AntiScreech, AntiDupe, AntiSnare, AntiGiggleCeiling, 
        AntiVacuum, AntiHalt, AntiEyesLookman, AntiSpider, Bypass, JumpButton, Fly,
        Speed, JumpBoost, Noclip, LockFov, NoAcceleration, InstantInteract, AutoInteract,
        AutoRooms
    }

    for _, mod in ipairs(disableList) do
        if mod and mod.Disable then
            mod:Disable()
        end
    end

    if AntiA90 and AntiA90.Disable then AntiA90:Disable() end
    if _G.NotificacaoAl and _G.NotificacaoAl.Disable then _G.NotificacaoAl:Disable() end

    -- Descarrega bibliotecas
    if Library and Library.Unload then
        pcall(Library.Unload)
    end
    if MainBypassMoviment and MainBypassMoviment.Unload then
        MainBypassMoviment:Unload()
    end
    if PadLock and PadLock.Unload then
        PadLock:Unload()
    end

    unloadWatermark()
end)

-- SAVE & THEME MANAGER
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})

ThemeManager:SetFolder("Hub")
SaveManager:SetFolder("Kolt Hub/Doors")

local floorFolders = {
    Hotel = "Hotel",
    Mines = "Mines",
    Backdoor = "Backdoor",
    Rooms = "Rooms"
}
if floorFolders[Floor] then
    SaveManager:SetSubFolder(floorFolders[Floor])
end

SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()
