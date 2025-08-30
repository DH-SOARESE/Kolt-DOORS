-- =================== [[ CHECAGENS INICIAIS ]] =================== --
local Players          = game:GetService("Players")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local RunService       = game:GetService("RunService")
local player           = Players.LocalPlayer
local floor            = ReplicatedStorage:WaitForChild("GameData"):WaitForChild("Floor")

-- =================== [[ PREVENÇÃO DE MÚLTIPLA EXECUÇÃO ]] =================== --
if _G.KoltHubLoaded then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Aviso",
        Text = "O Kolt Hub já está carregado.",
        Duration = 3
    })
    return
end
-- Marca o script como carregado
_G.KoltHubLoaded = true

-- Função de notificação nativa
local function notify(title, text, duration)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration or 3
    })
end

-- =================== [[ CHECAGENS DO JOGO ]] =================== --

-- Checa PlaceId
if game.PlaceId == 6516141723 then
    notify("Check Place Id", "Lobby detectado", 3)
    return
elseif game.PlaceId == 6839171747 then
    notify("Check Place Id", "Mapa válido", 3)
else
    notify("Check Place Id", "Mapa inválido", 3)
    return
end

task.wait(0.5)

-- Checa Floor
if floor.Value ~= "Hotel" then
    notify("Check Floor", "Floor inválido: " .. tostring(floor.Value), 3)
    return
else
    notify("Check Floor", "Floor válido: " .. tostring(floor.Value), 3)
end

task.wait(0.5)

-- =========================
-- SERVIÇOS
-- =========================
local Stats     = game:GetService("Stats")
local Workspace = game:GetService("Workspace")
local Lighting  = game:GetService("Lighting")

-- =========================
-- DEPENDÊNCIAS
-- =========================
local repo = 'https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/'
local Library      = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager  = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Options = Library.Options
local Toggles = Library.Toggles

-- Configurações globais
Library.ShowToggleFrameInKeybinds = true
Library.ShowCustomCursor          = true
Library.NotifySide                = "Left"

-- =========================
-- JOGADOR LOCAL
-- =========================
local Character       = player.Character or player.CharacterAdded:Wait()
local HumanoidRootPart= Character:WaitForChild("HumanoidRootPart")
local Humanoid        = Character:WaitForChild("Humanoid")
local FloorValue      = ReplicatedStorage.GameData.Floor.Value

-- =========================
-- JANELA PRINCIPAL
-- =========================
local Title = "Kolt Hub | Floor: " .. FloorValue .. " | " .. player.Name
local Window = Library:CreateWindow({
    Title = Title,
    Center = true,
    AutoShow = true,
    Resizable = true,
    ShowCustomCursor = true,
    NotifySide = "Left",
    TabPadding = 8,
    MenuFadeTime = 0.2
})
-- =========================
-- TABS
-- =========================
local Tabs = {
	Main = Window:AddTab('Main'),
	Visual = Window:AddTab('Visual'),
	['UI Settings'] = Window:AddTab('UI Settings'),
}

notify("Sucesso", "Menu carregado com sucesso!", 3)

local TabBox = Tabs.Main:AddLeftTabbox()
local Tab1 = TabBox:AddTab("LocalPlayer")
local Tab2 = TabBox:AddTab("Camera")

-- =========================
-- SERVIÇOS
-- =========================
local Players       = game:GetService("Players")
local Workspace     = game:GetService("Workspace")
local RunService    = game:GetService("RunService")
local Lighting      = game:GetService("Lighting")

local player        = Players.LocalPlayer

-- =========================
-- VARIÁVEIS DO JOGADOR
-- =========================
local Humanoid, HumanoidRootPart
local jumpValue = 7.2
local EnableJump = false
local internalChange = false

-- =========================
-- FUNÇÕES DE HUMANOID
-- =========================
local function GetHumanoid()
	if player.Character then
		return player.Character:FindFirstChildOfClass("Humanoid")
	end
	return nil
end

local function applyJumpBoost(hum)
	if not hum then return end
	hum.JumpHeight = jumpValue
	hum:GetPropertyChangedSignal("JumpHeight"):Connect(function()
		if hum.JumpHeight ~= jumpValue then
			hum.JumpHeight = jumpValue
		end
	end)
end

local function setupCharacter(char)
	Humanoid = char:WaitForChild("Humanoid")
	HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
	applyJumpBoost(Humanoid)

	if char:GetAttribute("CanJump") == nil then
		char:SetAttribute("CanJump", EnableJump)
	else
		char:SetAttribute("CanJump", EnableJump)
	end

	char:GetAttributeChangedSignal("CanJump"):Connect(function()
		if not internalChange then
			internalChange = true
			char:SetAttribute("CanJump", EnableJump)
			internalChange = false
		end
	end)
end

player.CharacterAdded:Connect(setupCharacter)
if player.Character then setupCharacter(player.Character) end

-- =========================
-- SLIDERS
-- =========================
Tab1:AddSlider("Speed", {
	Text = "WalkSpeed",
	Default = 15,
	Min = 15,
	Max = 50,
	Rounding = 0
})

Tab1:AddSlider("FlySpeed", {
	Text = "Fly Speed",
	Default = 20,
	Min = 20,
	Max = 50,
	Rounding = 0
})

Tab1:AddSlider("JumpBoost", {
	Text = "JumpBoost",
	Default = jumpValue,
	Min = 5,
	Max = 20,
	Rounding = 1,
	Callback = function(value)
		jumpValue = value
		if Humanoid then Humanoid.JumpHeight = jumpValue end
	end
})

Tab1:AddDivider()

-- =========================
-- SPEED TOGGLE
-- =========================
local SpeedConnection, BypassConnection, CloneCollision
local ToggleParent = true

Tab1:AddToggle("EnableSpeed", {
	Text = "Enable Speed",
	Default = false,
	Callback = function(state)
		local char = workspace:WaitForChild(player.Name)
		local HRP = char:WaitForChild("HumanoidRootPart")
		local Collision = char:WaitForChild("Collision")

		if state then
			if not CloneCollision then
				CloneCollision = Collision:Clone()
				CloneCollision.CanCollide = false
				CloneCollision.Anchored = false
				CloneCollision.Massless = false
				CloneCollision.Parent = HRP
			end

			task.spawn(function()
				while state and CloneCollision do
					CloneCollision.Parent = ToggleParent and Lighting or HRP
					ToggleParent = not ToggleParent
					task.wait(0.23)
				end
			end)

			BypassConnection = RunService.Heartbeat:Connect(function()
				if CloneCollision then
					CloneCollision.Massless = not CloneCollision.Massless
					CloneCollision.CanCollide = false
				end
			end)

			SpeedConnection = RunService.RenderStepped:Connect(function()
				local hum = GetHumanoid()
				if hum then hum.WalkSpeed = Options.Speed.Value end
			end)
		else
			if SpeedConnection then SpeedConnection:Disconnect() SpeedConnection = nil end
			if BypassConnection then BypassConnection:Disconnect() BypassConnection = nil end
			if CloneCollision then CloneCollision:Destroy() CloneCollision = nil end

			local hum = GetHumanoid()
			if hum then hum.WalkSpeed = 16 end
		end
	end
})

-- =========================
-- FLY SYSTEM
-- =========================
local flying = false
local bodyGyro, bodyVelocity
local FlyConnection
local verticalVelocitySmooth = 0
local horizontalVelocitySmooth = Vector3.zero

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true
rayParams.FilterDescendantsInstances = {player.Character}

local function enableFly()
	if flying then return end
	flying = true

	local Hum = GetHumanoid()
	local HRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not Hum or not HRP then return end

	Hum:ChangeState(Enum.HumanoidStateType.Physics)
	Hum.PlatformStand = true

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.P = 9000
	bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
	bodyGyro.CFrame = HRP.CFrame
	bodyGyro.Parent = HRP

	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	bodyVelocity.Velocity = Vector3.zero
	bodyVelocity.Parent = HRP

	FlyConnection = RunService.RenderStepped:Connect(function(deltaTime)
		if not flying or not HRP or not Hum then return end

		local move = Hum.MoveDirection
		local camera = Workspace.CurrentCamera
		local velocity = Vector3.zero

		if move.Magnitude > 0 then
			local targetHorizontal = move * Options.FlySpeed.Value
			horizontalVelocitySmooth = horizontalVelocitySmooth + (targetHorizontal - horizontalVelocitySmooth) * math.clamp(deltaTime * 12, 0, 1)

			local camForward = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z).Unit
			local forwardDot = move:Dot(camForward)

			local targetVertical = camera.CFrame.LookVector.Y * Options.FlySpeed.Value * (forwardDot < 0 and -1 or 1)
			verticalVelocitySmooth = verticalVelocitySmooth + (targetVertical - verticalVelocitySmooth) * math.clamp(deltaTime * 12, 0, 1)

			velocity = horizontalVelocitySmooth + Vector3.new(0, verticalVelocitySmooth, 0)
		else
			verticalVelocitySmooth *= 0.8
			horizontalVelocitySmooth *= 0.8
			velocity = horizontalVelocitySmooth + Vector3.new(0, verticalVelocitySmooth, 0)
		end

		-- Anti-afundar no chão
		local rayOrigin = HRP.Position
		local rayDirection = Vector3.new(0, -5, 0)
		local result = Workspace:Raycast(rayOrigin, rayDirection, rayParams)

		if result then
			local groundY = result.Position.Y
			local safeHeight = groundY + Hum.HipHeight + 1.5
			if HRP.Position.Y < safeHeight then
				local camLook = camera.CFrame.LookVector
				local lookFactor = math.clamp(1 + camLook.Y, 0.1, 1)
				velocity = Vector3.new(velocity.X, math.max(velocity.Y, 1 * lookFactor), velocity.Z)
			end
		end

		bodyVelocity.Velocity = velocity

		local camLook = camera.CFrame.LookVector
		local flatLook = Vector3.new(camLook.X, 0, camLook.Z).Unit
		local targetCFrame = CFrame.new(HRP.Position, HRP.Position + flatLook)
		bodyGyro.CFrame = bodyGyro.CFrame:Lerp(targetCFrame, math.clamp(deltaTime * 15, 0, 1))
	end)
end

local function disableFly()
	flying = false
	if FlyConnection then FlyConnection:Disconnect() FlyConnection = nil end
	if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
	if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end

	local Hum = GetHumanoid()
	if Hum then
		Hum.PlatformStand = false
		Hum:ChangeState(Enum.HumanoidStateType.Running)
	end
end

Tab1:AddToggle("EnableFly", {
	Text = "Enable Fly",
	Default = false,
	Callback = function(state)
		if state then enableFly() else disableFly() end
	end
})

-- =========================
-- JUMP TOGGLE
-- =========================
Tab1:AddToggle("EnableJump", {
	Text = "Enable jump",
	Default = false,
	Callback = function(state)
		EnableJump = state
		local char = workspace:FindFirstChild(player.Name)
		if char then
			internalChange = true
			char:SetAttribute("CanJump", EnableJump)
			internalChange = false
		end
	end
})

-- =========================
-- NO ACCELERATION
-- =========================
local NoAccelerationEnabled = false
Tab1:AddToggle("NoAcceleration", {
	Text = "No Acceleration",
	Default = false,
	Callback = function(state)
		NoAccelerationEnabled = state
	end
})

RunService.RenderStepped:Connect(function()
	if NoAccelerationEnabled and Humanoid and HumanoidRootPart then
		local moveDir = Humanoid.MoveDirection
		local speed = Humanoid.WalkSpeed
		local verticalVel = HumanoidRootPart.Velocity.Y

		HumanoidRootPart.Velocity = Vector3.new(
			moveDir.X * speed,
			verticalVel,
			moveDir.Z * speed
		)
	end
end)

-- =========================
-- CAMERA FOV
-- =========================
local camera = Workspace.CurrentCamera
local fovValue = 70
local fovEnabled = false
local fovConnection
local currentFov = camera.FieldOfView
local targetFov = fovValue
local startFov = currentFov
local fovSpeed = 1

local FOV_MAX_VISUAL = 120
local FOV_MAX_REAL = 150

local function easeInOutQuad(t)
    return t < 0.5 and 2 * t * t or 1 - ((-2 * t + 2)^2) / 2
end

local transitionProgress = 0
local transitioning = false
local transitioningOut = false

local function startTransition(newTargetFov, outTransition)
    targetFov = newTargetFov
    startFov = camera.FieldOfView
    transitioning = true
    transitioningOut = outTransition
    transitionProgress = 0
end

-- Slider do FOV
Tab2:AddSlider("FovSlider", {
    Text = "Fov FieldOfView",
    Min = 70,
    Max = FOV_MAX_VISUAL,
    Default = 70,
    Rounding = 1,
    HideMax = true,
    Suffix = "°",
    Callback = function(value)
        if fovEnabled then
            fovValue = math.clamp(value, 70, FOV_MAX_REAL)
            startTransition(fovValue, false)
        else
            -- Atualiza o valor mesmo desativado, pra usar depois
            fovValue = math.clamp(value, 70, FOV_MAX_REAL)
        end
    end
})

-- Checkbox para habilitar/desabilitar FOV
Tab2:AddToggle("EnableFov", {
    Text = "Enable Fov",
    Default = false,
    Callback = function(state)
        fovEnabled = state
        if state then
            -- Pega automaticamente o valor atual da slider e aplica
            fovValue = math.clamp(fovValue or 70, 70, FOV_MAX_REAL)
            startTransition(fovValue, false)

            if fovConnection then
                fovConnection:Disconnect()
            end

            -- Conexão do loop de transição
            fovConnection = RunService.RenderStepped:Connect(function(dt)
                if transitioning or fovEnabled then
                    if transitioning then
                        transitionProgress = math.min(transitionProgress + dt * fovSpeed, 1)
                        local easedProgress = easeInOutQuad(transitionProgress)
                        currentFov = startFov + (targetFov - startFov) * easedProgress
                        camera.FieldOfView = currentFov
                        if transitionProgress >= 1 then
                            transitioning = false
                            if transitioningOut then
                                fovEnabled = false
                                if fovConnection then
                                    fovConnection:Disconnect()
                                    fovConnection = nil
                                end
                            end
                        end
                    else
                        if fovEnabled then
                            currentFov = targetFov
                            camera.FieldOfView = currentFov
                        end
                    end
                end
            end)
        else
            -- Resetar para o FOV padrão
            startTransition(70, true)
            if not fovConnection then
                camera.FieldOfView = 70
                currentFov = 70
                transitioning = false
            end
        end
    end
})

local TabBox = Tabs.Main:AddRightTabbox()
local Game = TabBox:AddTab("Game")
local RemoteTab = TabBox:AddTab("Remote")

-- Serviços
local Lighting = game:GetService("Lighting")

-- Configuração do Fullbright
local targetLighting = {
    Brightness = 0,
    ClockTime = 14.5,
    FogEnd = 100000,
    FogStart = 0,
    Ambient = Color3.new(1,1,1),
    OutdoorAmbient = Color3.new(1,1,1),
    GlobalShadows = false,
    ExposureCompensation = 0
}

local fullbrightEnabled = false
local connection

-- Aplica os valores do fullbright
local function applyFullbright()
    for prop, value in pairs(targetLighting) do
        Lighting[prop] = value
    end
end

-- Função de toggle
local function setFullbright(state)
    fullbrightEnabled = state

    if state then
        -- aplica e mantém
        applyFullbright()
        connection = Lighting.Changed:Connect(function()
            if fullbrightEnabled then
                applyFullbright()
            end
        end)
    else
        -- solta o controle e deixa o jogo restaurar
        if connection then
            connection:Disconnect()
            connection = nil
        end
        -- reset manual (zera o que foi mexido, jogo repõe depois)
        Lighting.FogEnd = 250
        Lighting.FogStart = 150
        Lighting.Brightness = 0
        Lighting.ClockTime = 14.5
        Lighting.Ambient = Color3.fromRGB(67,51,56)
        Lighting.OutdoorAmbient = Color3.new(0,0,0)
        Lighting.GlobalShadows = true
        Lighting.ExposureCompensation = 1
    end
end

-- Toggle GUI
Game:AddToggle("Fullbright", {
    Text = "Fullbright",
    Default = false,
    Callback = function(state)
        setFullbright(state)
    end
})

RemoteTab:AddToggle("PadLock", {
    Text = "PadLock",
    Default = false,
    Callback = function(state)
        if not state then return end

        local player = game.Players.LocalPlayer
        local workspacePlayer = workspace:WaitForChild(player.Name) -- modelo do jogador
        local workspaceHint = workspacePlayer:WaitForChild("LibraryHintPaper"):WaitForChild("UI")
        local permHints = player.PlayerGui.PermUI.Hints
        local remote = game:GetService("ReplicatedStorage").RemotesFolder:WaitForChild("PL")

        local LibraryNotify = Library:Notify({
            Title = "Padlock",
            Description = "Monitoring...",
            Time = 10
        })

        local lastSentCode = nil -- evita envios repetidos

        -- Função que envia código para o servidor
        local function SendCodeToServer(code)
            if remote and code ~= lastSentCode then
                remote:FireServer(code)
                lastSentCode = code
                LibraryNotify:ChangeDescription("Code sent to server successfully!")
            end
        end

        -- Função que checa o LibraryHintPaper no modelo do jogador e decodifica
        local function CheckAndDecode()
            local paper = workspacePlayer:FindFirstChild("LibraryHintPaper")
            if not paper then
                LibraryNotify:ChangeDescription("No LibraryHintPaper found in player model. Waiting...")
                return
            end

            -- Coleta offsets da UI
            local targetOffsets = {}
            for i = 1, 5 do
                local uiElement = workspaceHint:FindFirstChild(tostring(i))
                if uiElement and uiElement:IsA("ImageLabel") then
                    targetOffsets[i] = uiElement.ImageRectOffset
                else
                    LibraryNotify:ChangeDescription("LibraryHintPaper UI element " .. i .. " not found.")
                    return
                end
            end

            -- Decodifica o código comparando com permHints
            local codeSequence = ""
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
                    codeSequence = codeSequence .. foundText
                    LibraryNotify:ChangeDescription("Decoding... Step " .. index .. "/5: " .. codeSequence)
                else
                    complete = false
                    break
                end
            end

            if complete then
                SendCodeToServer(codeSequence)
            else
                LibraryNotify:ChangeDescription("Incomplete code. Collect more LibraryHintPapers!")
            end
        end

        -- Listener para detectar quando o papel é adicionado ou removido do modelo
        workspacePlayer.ChildAdded:Connect(function(child)
            if child.Name == "LibraryHintPaper" then
                task.wait(0.1)
                CheckAndDecode()
            end
        end)

        workspacePlayer.ChildRemoved:Connect(function(child)
            if child.Name == "LibraryHintPaper" then
                LibraryNotify:ChangeDescription("LibraryHintPaper removed from player model. Waiting...")
            end
        end)

        -- Rodar imediatamente caso já exista
        CheckAndDecode()
    end
})

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("RemotesFolder")

local Functions = Tabs.Main:AddLeftGroupbox('Functions')

-- Função auxiliar para resetar o personagem
local function resetCharacter()
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.Health = 0
    end
end

-- Botão Play Again (double click)
Functions:AddButton({
    Text = "Play Again",
    Func = function()
        -- Dispara o remote PlayAgain 
        Remotes:WaitForChild("PlayAgain"):FireServer()
    end,
    DoubleClick = true,
    Tooltip = "Double click to trigger Play Again"
})

-- Botão Back to Lobby (single click)
Functions:AddButton({
    Text = "Back to Lobby",
    Func = function()
        Remotes:WaitForChild("Lobby"):FireServer()
    end,
    DoubleClick = true,
    Tooltip = "Return to the lobby"
})

-- Botão Reset Character (single click)
Functions:AddButton({
    Text = "Reset Character",
    Func = function()
        resetCharacter()
    end,
    DoubleClick = true,
    Tooltip = "Reset your character"
})


---------------------------
--AURA
---------------------------
local Aura = Tabs.Main:AddRightGroupbox('Aura')

local MAX_F2_INTERACT_DISTANCE = 11.5
local F2_InteractMode = "New"
local lastF2Interact = {}
local lastF2Cleanup = 0
local lastNoInteractionUse = {}
local autoF2Connection

-- Tabelas de prompts para interação
local PromptData = {
    Parents = {"DrawerContainer", "RolltopContainer", "ChestBox", "Bandage", "GoldPile", "KeyObtain", "Lock", "RolltopContainer", "LeverForGate", "Smoothie", "Vitamins", "Flashlight", "Lighter", "Candle", "LibraryHintPaper", "LiveHintBook", "Desk_Globe", "AlarmClock", "ElectricalKeyObtain", "LiveBreakerPolePickup", "Lockpick"},
    Children = {"ProximityPrompt", "ActivateEventPrompt", "ModulePrompt", "UnlockPrompt", "InteractPrompt", "LootPrompt"}
}

local function getHRP()
    return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function getDistance(part)
    local hrp = getHRP()
    return hrp and part and (hrp.Position - part.Position).Magnitude or math.huge
end

local function getPartForPrompt(prompt)
    local parent = prompt.Parent
    if parent:IsA("BasePart") then return parent end
    if parent:IsA("Model") then return parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart") end
    local ancestor = prompt:FindFirstAncestorWhichIsA("Model") or prompt:FindFirstAncestorWhichIsA("BasePart")
    if ancestor then
        if ancestor:IsA("BasePart") then return ancestor end
        if ancestor:IsA("Model") then return ancestor.PrimaryPart or ancestor:FindFirstChildWhichIsA("BasePart") end
    end
end

-- Agora sem checar se está olhando
local function isValidPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") or not prompt.Enabled or prompt:GetAttribute("Passed") then
        return false
    end

    local interactions = prompt:GetAttribute("Interactions")
    local id = prompt:GetDebugId()
    if interactions ~= nil then
        if interactions > 0 then return false end
    else
        local lastUse = lastNoInteractionUse[id] or 0
        if tick() - lastUse < 0.1 then return false end -- mais rápido (antes era 0.25s)
    end

    return true
end

local function firePrompt(prompt)
    if not isValidPrompt(prompt) then return false end
    local part = getPartForPrompt(prompt)
    if not part then return false end
    if not getHRP() then return false end

    fireproximityprompt(prompt)
    if prompt:GetAttribute("Interactions") == nil then
        lastNoInteractionUse[prompt:GetDebugId()] = tick()
    end
    return true
end

local function collectAllTargets()
    local targets = {}
    local currentRoom = Workspace.CurrentRooms:FindFirstChild(tostring(player:GetAttribute("CurrentRoom")))
    if currentRoom then
        for _, obj in ipairs(currentRoom:GetDescendants()) do
            if obj:IsA("Model") and table.find(PromptData.Parents, obj.Name) then
                for _, childName in ipairs(PromptData.Children) do
                    local prompt = obj:FindFirstChild(childName, true)
                    if prompt and isValidPrompt(prompt) then
                        local part = getPartForPrompt(prompt)
                        if part then table.insert(targets, { prompt = prompt, part = part }) end
                    end
                end
            end
        end
    end
    return targets
end

local lastCollect = 0
local cachedTargets = {}
local function interactF2Loop()
    local now = tick()
    if now - lastF2Cleanup >= 15 then
        lastF2Interact, lastNoInteractionUse = {}, {}
        lastF2Cleanup = now
    end

    if now - lastCollect >= 0.05 then -- coleta mais rápida (antes 0.1s)
        cachedTargets = collectAllTargets()
        lastCollect = now
    end

    table.sort(cachedTargets, function(a, b)
        return getDistance(a.part) < getDistance(b.part)
    end)

    for _, t in ipairs(cachedTargets) do
        local prompt, part = t.prompt, t.part
        local dist = getDistance(part)
        if dist <= MAX_F2_INTERACT_DISTANCE then
            local id = prompt:GetDebugId()
            local ready = not lastF2Interact[id] or (now - lastF2Interact[id] >= 0.1) -- delay mínimo
            if ready then
                firePrompt(prompt)
                lastF2Interact[id] = now
                if F2_InteractMode == "Old" then break end
            end
        end
    end
end

local function toggleF2Interact(enabled)
    if enabled then
        autoF2Connection = RunService.Heartbeat:Connect(interactF2Loop)
    elseif autoF2Connection then
        autoF2Connection:Disconnect()
        autoF2Connection = nil
    end
end

Aura:AddToggle("AutoInteractF2", {
    Text = "Auto Interact",
    Default = false,
    Callback = toggleF2Interact
})
local originalDurations = {}
local instantInteractEnabled = false
local interactConnection

Aura:AddToggle("InteractInstant", {
    Text = "Interact Instant",
    Default = false,
    Callback = function(state)
        instantInteractEnabled = state

        local function applyToPrompt(prompt)
            if prompt:IsA("ProximityPrompt") and prompt.HoldDuration > 0 then
                if state then
                    if not originalDurations[prompt] then originalDurations[prompt] = prompt.HoldDuration end
                    prompt.HoldDuration = 0
                else
                    if originalDurations[prompt] then prompt.HoldDuration = originalDurations[prompt] end
                end
            end
        end

        if state then
            for _, obj in ipairs(Workspace:GetDescendants()) do pcall(applyToPrompt, obj) end
            interactConnection = Workspace.DescendantAdded:Connect(function(obj)
                task.wait()
                pcall(applyToPrompt, obj)
            end)
        else
            for prompt, original in pairs(originalDurations) do
                if prompt and prompt.Parent then prompt.HoldDuration = original end
            end
            table.clear(originalDurations)
            if interactConnection then interactConnection:Disconnect() interactConnection = nil end
        end
    end
})


Aura:AddSlider("InteractRangeF2", {
    Text = "Range",
    Default = 11.5,
    Min = 5,
    Max = 11.5,
    HideMax = true,
    Suffix = ".m",
    Rounding = 1,
    Callback = function(v) MAX_F2_INTERACT_DISTANCE = v end
})

Aura:AddDropdown("InteractModeF2", {
    Values = { "Old", "New" },
    Default = 2,
    Multi = false,
    Text = "Interact Mode",
    Callback = function(mode) F2_InteractMode = mode end
})


-- =================== [[ VISUAL: ESP ]] =================== --

local ModelESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/DH-SOARESE/Kolt-DOORS/refs/heads/main/Kolt%20ESP-LIBRARY.lua"))()

ModelESP:SetGlobalESPType("ShowHighlightOutline", true)
ModelESP:SetGlobalESPType("ShowHighlightFill", true)
ModelESP:SetGlobalESPType("ShowName", true)
ModelESP:SetGlobalESPType("ShowDistance", true)
ModelESP:SetGlobalESPType("ShowTracer", false)
ModelESP.GlobalSettings.MinDistance = 5
ModelESP.GlobalSettings.ShowBox = false
ModelESP:SetGlobalTracerOrigin("Top")


-- Ativações de ESP
local espEnabled = {
    Door = false,
    Key = false,
    Gold = false,
    Books = false,
    Entities = false,
    Players = false,
    Items = false,
    Hidden = false,
    Lever = false,
    Dupe = false,
}

-- Listas de controle
local currentDoorESP
local currentKeyESPs = {}
local currentGoldESPs = {}
local currentBookESPs = {}
local currentEntityESPs = {}
local currentPlayerESPs = {}
local currentItemESPs = {}
local currentHiddenESPs = {}
local currentLeverESPs = {}
local currentDupeESPs = {}

-- =================== [[ FUNÇÕES GERAIS ]] =================== --

local function addESP(model, name, color)
ModelESP:Add(model, {
    Name = name,
    Color = color,
    ShowName = true,
    ShowDistance = true,
    Tracer = true,
    HighlightFill = true,
    HighlightOutline = true,
})
end

-- =================== [[ DOORS ]] =================== --
local function getDoorName(room)
    local latestRoom = tonumber(room.Name) or 0

    local door = room:FindFirstChild("Door")
    if not door then return "Door" end

    -- Nome do texto da placa  
    local text = "?"  
    local sign = door:FindFirstChild("Sign")  
    if sign and sign:FindFirstChild("Stinker") then  
        text = sign.Stinker.Text  
    end  

    -- Locked ou Door  
    local baseName = "Door"
    if latestRoom >= 89 then
        baseName = "Fence" -- muda para "Cerca" a partir da sala 89
    end

    if door:FindFirstChild("Lock") then  
        return "Locked (" .. text .. ")"  
    else
        return baseName .. " (" .. text .. ")"  
    end
end

local function createDoorESP()
    if not espEnabled.Door then return end
    if currentDoorESP then
        ModelESP:Remove(currentDoorESP)
        currentDoorESP = nil
    end

    local latestRoom = ReplicatedStorage.GameData.LatestRoom.Value  
    if latestRoom >= 100 then return end -- não cria ESP a partir da sala 100

    local room = Workspace.CurrentRooms:FindFirstChild(tostring(latestRoom))  
    if not room or not room:FindFirstChild("Door") then return end  

    local doorModel = room.Door  
    local doorTarget  

    -- Nas salas 49 & 50 -> ESP no model inteiro  
    if latestRoom == 49 or latestRoom == 50 then  
        doorTarget = doorModel  
    else  
        doorTarget = doorModel:FindFirstChild("Door")  
    end  

    if not doorTarget then return end  

    addESP(doorTarget, getDoorName(room), Color3.fromRGB(50, 205, 50))  
    currentDoorESP = doorTarget
end
-- =================== [[ KEYS ]] =================== --

local function createKeyESPs()
    for _, keyESP in ipairs(currentKeyESPs) do
        ModelESP:Remove(keyESP)
    end
    currentKeyESPs = {}

    if not espEnabled.Key then return end  

    local LocalPlayerName = player.Name
    local attrName = "Interactions" .. LocalPlayerName

    local latestRoom = ReplicatedStorage.GameData.LatestRoom.Value  
    local room = Workspace.CurrentRooms:FindFirstChild(tostring(latestRoom))  
    if not room or not room:FindFirstChild("Assets") then return end  

    for _, asset in ipairs(room.Assets:GetDescendants()) do  
        if asset:IsA("Model") and (asset.Name == "KeyObtain" or asset.Name == "ElectricalKeyObtain") then  
            local modulePrompt = asset:FindFirstChild("ModulePrompt")  
            if modulePrompt then  
                local interactionsValue = modulePrompt:GetAttribute(attrName) or 0  

                -- ESP inicial
                if interactionsValue == 0 then  
                    addESP(asset, "Key", Color3.fromRGB(255, 223, 0))  
                    table.insert(currentKeyESPs, asset)  
                end  

                -- Monitora mudanças no atributo
                modulePrompt:GetAttributeChangedSignal(attrName):Connect(function()
                    local newInteractionsValue = modulePrompt:GetAttribute(attrName) or 0  
                    if newInteractionsValue > 0 then  
                        for i, espAsset in ipairs(currentKeyESPs) do  
                            if espAsset == asset then  
                                ModelESP:Remove(espAsset)  
                                table.remove(currentKeyESPs, i)  
                                break  
                            end  
                        end  
                    elseif newInteractionsValue == 0 and not table.find(currentKeyESPs, asset) then  
                        addESP(asset, "Key", Color3.fromRGB(255, 223, 0))  
                        table.insert(currentKeyESPs, asset)  
                    end  
                end)
            end  
        end  
    end
end

-- =================== [[ GOLD ]] =================== --

local function addGoldESP(goldModel)
    if not espEnabled.Gold or not goldModel:IsA("Model") or goldModel.Name ~= "GoldPile" then return end
    for _, esp in ipairs(currentGoldESPs) do if esp == goldModel then return end end
    addESP(goldModel, "GoldPile", Color3.fromRGB(255, 190, 0))
    table.insert(currentGoldESPs, goldModel)
end

local function scanAllGoldPiles()
    for _, room in ipairs(Workspace.CurrentRooms:GetChildren()) do
        if room:FindFirstChild("Assets") then
            for _, asset in ipairs(room.Assets:GetDescendants()) do
                if asset:IsA("Model") and asset.Name == "GoldPile" then
                    addGoldESP(asset)
                end
            end
        end
    end
end

-- =================== [[ BOOKS ]] =================== --
local function addBookESP(bookModel, index)
    if not espEnabled.Books or not bookModel:IsA("Model") or bookModel.Name ~= "LiveHintBook" then return end
    for _, esp in ipairs(currentBookESPs) do
        if esp == bookModel then return end
    end
    -- Adiciona o índice no nome do ESP
    addESP(bookModel, "Book ["..index.."]", Color3.fromRGB(0, 255, 0))
    table.insert(currentBookESPs, bookModel)
end

local function scanBooksInRoom50()
    local room50 = Workspace.CurrentRooms:FindFirstChild("50")
    if not room50 or not room50:FindFirstChild("Assets") then return end
    local bookIndex = 1
    for _, asset in ipairs(room50.Assets:GetDescendants()) do
        if asset:IsA("Model") and asset.Name == "LiveHintBook" then
            addBookESP(asset, bookIndex)
            bookIndex = bookIndex + 1
        end
    end
end
-- =================== [[ ENTITIES]] =================== --
local entityWorkspaceNames = {
    RushMoving = {Name = "Rush", Color = Color3.fromRGB(255, 50, 50), Use2D = true},
    AmbushMoving = {Name = "Ambush", Color = Color3.fromRGB(255, 150, 50), Use2D = true},
    Eyes = {Name = "Eyes", Color = Color3.fromRGB(50, 150, 255), Use2D = true},
    SeekMovingNewClone = {Name = "Seek", Color = Color3.fromRGB(200, 50, 200), Use2D = false}
}

local entityRoomNames = {
    FigureRig = {Name = "Figure", Color = Color3.fromRGB(255, 200, 50), Use2D = false},
    Snare = {Name = "Snare", Color = Color3.fromRGB(255, 0, 0), Use2D = false}
}

local currentEntityESPs = {}
local entityConnections = {}

-- Adiciona ou atualiza ESP da entidade
local function addEntityESP(model, data)
    if not model or not model:IsA("Model") then return end

    -- Se já existe ESP, remove antes
    if currentEntityESPs[model] then
        pcall(function() ModelESP:Remove(model) end)
        currentEntityESPs[model] = nil
    end

    -- Aplica modo 2D se necessário
    if data.Use2D then
        local hasBasePart = false
        for _, obj in ipairs(model:GetDescendants()) do
            if obj:IsA("BasePart") then
                hasBasePart = true
                obj.Transparency = 0.99
                obj.CanCollide = false
            end
        end

        if not hasBasePart then
            local primaryPart = Instance.new("Part")
            primaryPart.Name = "Entity2DPart"
            primaryPart.Anchored = true
            primaryPart.CanCollide = false
            primaryPart.Size = model:GetExtentsSize() or Vector3.new(2,2,2)
            primaryPart.Transparency = 0.99
            primaryPart.Parent = model

            local mesh = Instance.new("SpecialMesh")
            mesh.MeshType = Enum.MeshType.Brick
            mesh.Scale = Vector3.new(1,1,1)
            mesh.Parent = primaryPart
        end

        if not model:FindFirstChildOfClass("Humanoid") then
            local humanoid = Instance.new("Humanoid")
            humanoid.Name = "FakeHumanoid"
            humanoid.Health = 0
            humanoid.MaxHealth = 0
            humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            humanoid.Parent = model
        end
    end

    -- Adiciona ESP via ModelESP
    ModelESP:Add(model, {
        Name = data.Name,
        Color = data.Color,
        ShowName = true,
        ShowDistance = true,
        Tracer = true,
        HighlightFill = true,
        HighlightOutline = true,
        TracerOrigin = "Top"
    })

    currentEntityESPs[model] = true
end

-- Escaneia Workspace
local function scanWorkspaceEntities()
    for realName, data in pairs(entityWorkspaceNames) do
        local obj = workspace:FindFirstChild(realName)
        if obj and obj:IsA("Model") then
            addEntityESP(obj, data)
        end
    end
end

-- Escaneia Rooms
local function scanRoomEntities()
    for _, room in ipairs(workspace.CurrentRooms:GetChildren()) do
        local assets = room:FindFirstChild("Assets")
        if assets then
            for realName, data in pairs(entityRoomNames) do
                for _, asset in ipairs(assets:GetDescendants()) do
                    if asset:IsA("Model") and asset.Name == realName then
                        addEntityESP(asset, data)
                    end
                end
            end
        end
    end
end

-- Ativa ESP
function enableEntitiesESP()
    -- Faz varredura inicial
    scanWorkspaceEntities()
    scanRoomEntities()

    -- Conexão para entidades diretas no Workspace
    entityConnections["Workspace"] = workspace.ChildAdded:Connect(function(child)
        local data = entityWorkspaceNames[child.Name]
        if data and child:IsA("Model") then
            addEntityESP(child, data)
        end
    end)

    -- Recria conexões para cada sala já existente
    for _, room in ipairs(workspace.CurrentRooms:GetChildren()) do
        local assets = room:FindFirstChild("Assets")
        if assets then
            -- Escaneia entidades já existentes
            for realName, data in pairs(entityRoomNames) do
                for _, asset in ipairs(assets:GetDescendants()) do
                    if asset:IsA("Model") and asset.Name == realName then
                        addEntityESP(asset, data)
                    end
                end
            end

            -- Conecta novos assets
            entityConnections[room] = assets.DescendantAdded:Connect(function(asset)
                local data = entityRoomNames[asset.Name]
                if data and asset:IsA("Model") then
                    addEntityESP(asset, data)
                end
            end)
        end
    end

    -- Novas salas sendo criadas
    entityConnections["Rooms"] = workspace.CurrentRooms.ChildAdded:Connect(function(room)
        local assets = room:WaitForChild("Assets", 3)
        if assets then
            -- Escaneia entidades já existentes na sala nova
            for realName, data in pairs(entityRoomNames) do
                for _, asset in ipairs(assets:GetDescendants()) do
                    if asset:IsA("Model") and asset.Name == realName then
                        addEntityESP(asset, data)
                    end
                end
            end

            -- Conecta novos assets dessa sala
            entityConnections[room] = assets.DescendantAdded:Connect(function(asset)
                local data = entityRoomNames[asset.Name]
                if data and asset:IsA("Model") then
                    addEntityESP(asset, data)
                end
            end)
        end
    end)
end

-- Desativa ESP
function disableEntitiesESP()
    for model in pairs(currentEntityESPs) do
        if model and model.Parent then
            if ModelESP then
                pcall(function() ModelESP:Remove(model) end)
            end
        end
    end
    table.clear(currentEntityESPs)

    for key, conn in pairs(entityConnections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
        entityConnections[key] = nil
    end
end
-- =================== [[ ITEMS ]] =================== --

-- Lista de itens configuráveis
local itemList = {
    "Lighter",
    "Bandage",
    "Vitamins",
    "Crucifix",
    "SkeletonKey",
    "Flashlight",
    "Lockpick",
    "AlarmClock",
    "Smoothie",
    "Candle",
    "LiveBreakerPolePickup"
}

local function addItemESP(itemModel)
    if not espEnabled.Items then return end
    if not itemModel:IsA("Model") then return end

    -- Verifica se já existe ESP nesse item  
    for _, esp in ipairs(currentItemESPs) do  
        if esp == itemModel then  
            return  
        end  
    end  

    -- Confere se o item está na lista  
    for _, itemName in ipairs(itemList) do  
        if itemModel.Name == itemName then  
            addESP(itemModel, itemName, Color3.fromRGB(0, 255, 100))  
            table.insert(currentItemESPs, itemModel)  
            break  
        end  
    end
end

local function scanAllItems()
    if not Workspace:FindFirstChild("CurrentRooms") then return end
    for _, room in ipairs(Workspace.CurrentRooms:GetChildren()) do
        local assets = room:FindFirstChild("Assets")
        if assets then
            for _, asset in ipairs(assets:GetDescendants()) do
                addItemESP(asset)
            end
        end
    end
end

local function disableItemsESP()
    for _, esp in ipairs(currentItemESPs) do
        ModelESP:Remove(esp)
    end
    table.clear(currentItemESPs)
end
-- =================== [[ HIDDEN ESP ]] =================== --

-- Lista de esconderijos: [Nome real do Model] = "Nome exibido"
local hiddenList = {
    ["Wardrobe"] = "Closet",
    ["Bed"] = "Bed",
    ["Toolshed"] = "Closet"
}

local MAX_DISTANCE = 100 -- 100 studs (~28m)

local function addHiddenESP(hiddenModel)
    if not espEnabled.Hidden then return end
    if not hiddenModel:IsA("Model") then return end

    -- Evita duplicatas
    for _, esp in ipairs(currentHiddenESPs) do
        if esp == hiddenModel then return end
    end

    local displayName = hiddenList[hiddenModel.Name]
    if not displayName then return end

    -- Verifica distância
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not hiddenModel.PrimaryPart then return end
    if (hrp.Position - hiddenModel.PrimaryPart.Position).Magnitude > MAX_DISTANCE then return end

    -- Cria ESP
    addESP(hiddenModel, displayName, Color3.fromRGB(180, 255, 180))
    table.insert(currentHiddenESPs, hiddenModel)
end

local function scanCurrentRoomHidden()
    if not Workspace:FindFirstChild("CurrentRooms") then return end

    local currentRoom = player:GetAttribute("CurrentRoom")
    if not currentRoom then return end

    local room = Workspace.CurrentRooms:FindFirstChild(tostring(currentRoom))
    if not room then return end

    -- 🔎 Varrendo TODOS os descendentes da sala, não só "Assets"
    for _, descendant in ipairs(room:GetDescendants()) do
        addHiddenESP(descendant)
    end
end

local function disableHiddenESP()
    for _, esp in ipairs(currentHiddenESPs) do
        ModelESP:Remove(esp)
    end
    table.clear(currentHiddenESPs)
end

local function updateHiddenDistanceCheck()
    if not espEnabled.Hidden then return end
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for i = #currentHiddenESPs, 1, -1 do
        local model = currentHiddenESPs[i]
        if not model or not model.PrimaryPart then
            ModelESP:Remove(model)
            table.remove(currentHiddenESPs, i)
        else
            local dist = (hrp.Position - model.PrimaryPart.Position).Magnitude
            if dist > MAX_DISTANCE then
                ModelESP:Remove(model)
                table.remove(currentHiddenESPs, i)
            end
        end
    end
end
-- =================== [[ LEVER ESP ]] =================== --
local function addLeverESP(leverModel)
    if currentLeverESPs[leverModel] then return end
    addESP(leverModel, "Lever", Color3.fromRGB(0, 255, 255))
    currentLeverESPs[leverModel] = leverModel
end

local function removeLeverESP(leverModel)
    if currentLeverESPs[leverModel] then
        ModelESP:Remove(leverModel)
        currentLeverESPs[leverModel] = nil
    end
end

local function disableLeverESP()
    for leverModel in pairs(currentLeverESPs) do
        removeLeverESP(leverModel)
    end
end

local function scanCurrentRoomLevers()
    local currentRoom = player:GetAttribute("CurrentRoom")
    if not currentRoom then return end

    local room = Workspace.CurrentRooms:FindFirstChild(tostring(currentRoom))
    if not room then return end

    -- Varre todos os descendentes da sala
    for _, obj in ipairs(room:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "LeverForGate" then
            local prompt = obj:FindFirstChild("ActivateEventPrompt")
            if prompt then
                local interactions = prompt:GetAttribute("Interactions") or 0
                if interactions == 0 then
                    addLeverESP(obj)
                else
                    removeLeverESP(obj)
                end
            end
        end
    end
end
-- =================== [[ DUPE ESP ]] =================== --

local function addDupeESP(dupeModel)
    if not espEnabled.Dupe then return end
    if not dupeModel:IsA("Model") then return end

    -- Verifica se já tem ESP nesse dupe
    for _, esp in ipairs(currentDupeESPs) do
        if esp == dupeModel then return end
    end

    addESP(dupeModel, "Dupe", Color3.fromRGB(255, 0, 0))
    table.insert(currentDupeESPs, dupeModel)
end

local function scanRoomDupes()
    local latestRoom = ReplicatedStorage.GameData.LatestRoom.Value
    local room = Workspace.CurrentRooms:FindFirstChild(tostring(latestRoom))
    if not room then return end

    -- Varre todos descendentes atrás de SideroomDupe > DoorFake
    for _, dupe in ipairs(room:GetDescendants()) do
        if dupe:IsA("Model") and dupe.Name == "DoorFake" then
            addDupeESP(dupe)
        end
    end
end

local function disableDupeESP()
    for _, dupe in ipairs(currentDupeESPs) do
        ModelESP:Remove(dupe)
    end
    table.clear(currentDupeESPs)
end

-- Listener para troca de sala
ReplicatedStorage.GameData.LatestRoom:GetPropertyChangedSignal("Value"):Connect(function()
    if espEnabled.Dupe then
        disableDupeESP()
        scanRoomDupes()
    end
end)

-- =================== [[ LISTENERS / UI ]] =================== --

ReplicatedStorage.GameData.LatestRoom:GetPropertyChangedSignal("Value"):Connect(function()
    if espEnabled.Door then createDoorESP() end
    if espEnabled.Key then createKeyESPs() end
end)

Workspace.ChildAdded:Connect(function(child)
    local data = entityWorkspaceNames[child.Name]
    if data and child:IsA("Model") then addEntityESP(child, data) end
end)

Workspace.CurrentRooms.ChildAdded:Connect(function(room)
    for _, desc in ipairs(room:GetDescendants()) do
        local data = entityRoomNames[desc.Name]
        if data and desc:IsA("Model") then addEntityESP(desc, data) end
    end
    room.DescendantAdded:Connect(function(desc)
        local data = entityRoomNames[desc.Name]
        if data and desc:IsA("Model") then addEntityESP(desc, data) end
    end)
end)

RunService.RenderStepped:Connect(function()
    if espEnabled.Door and currentDoorESP then
        local latestRoom = ReplicatedStorage.GameData.LatestRoom.Value
        local room = Workspace.CurrentRooms:FindFirstChild(tostring(latestRoom))
        if room then ModelESP:UpdateName(currentDoorESP, getDoorName(room)) end
    end
end)

-- Listener para itens novos
if Workspace:FindFirstChild("CurrentRooms") then
    Workspace.CurrentRooms.ChildAdded:Connect(function(room)
        if not espEnabled.Items then return end
        local assets = room:FindFirstChild("Assets")
        if assets then
            assets.DescendantAdded:Connect(function(desc)
                addItemESP(desc)
            end)
        end
    end)
end

-- Atualiza quando o player muda de sala (para hidden)
player:GetAttributeChangedSignal("CurrentRoom"):Connect(function()
    if espEnabled.Hidden then
        disableHiddenESP()
        scanCurrentRoomHidden()
    end
end)
-- =================== [[ CHESTBOX ESP ]] =================== --

local currentChestESPs = {}

local function addChestESP(chestModel)
    if not espEnabled.ChestBox then return end
    if not chestModel:IsA("Model") then return end

    -- Evita duplicatas
    for _, esp in ipairs(currentChestESPs) do
        if esp == chestModel then return end
    end

    addESP(chestModel, "ChestBox", Color3.fromRGB(255, 128, 0))
    table.insert(currentChestESPs, chestModel)
end

local function scanAllRoomsChestBoxes()
    for _, room in ipairs(Workspace.CurrentRooms:GetChildren()) do
        local sideroom = room:FindFirstChild("Sideroom")
        if sideroom and sideroom:FindFirstChild("Assets") then
            for _, chest in ipairs(sideroom.Assets:GetDescendants()) do
                if chest:IsA("Model") and chest.Name == "ChestBox" then
                    addChestESP(chest)
                end
            end
        end
    end
end

local function disableChestESP()
    for _, chest in ipairs(currentChestESPs) do
        ModelESP:Remove(chest)
    end
    table.clear(currentChestESPs)
end

-- Monitora futuras salas
Workspace.CurrentRooms.ChildAdded:Connect(function(room)
    local sideroom = room:WaitForChild("Sideroom", 3)
    if sideroom and sideroom:FindFirstChild("Assets") then
        for _, chest in ipairs(sideroom.Assets:GetDescendants()) do
            if chest:IsA("Model") and chest.Name == "ChestBox" then
                addChestESP(chest)
            end
        end

        -- Monitora adições futuras
        sideroom.Assets.DescendantAdded:Connect(function(desc)
            if desc:IsA("Model") and desc.Name == "ChestBox" then
                addChestESP(desc)
            end
        end)
    end
end)

-- =================== [[ CHECKBOXES ]] =================== --

local Settings = Tabs.Visual:AddLeftGroupbox("Settings")
local Targets = Tabs.Visual:AddRightGroupbox("Targets")

-- 🚪 Doors (principal)
Targets:AddToggle("EspDoor", {
    Text = "Doors",
    Default = false,
    Callback = function(enabled)
        espEnabled.Door = enabled
        if enabled then
            createDoorESP()
        elseif currentDoorESP then
            ModelESP:Remove(currentDoorESP)
            currentDoorESP = nil
        end
    end
})

-- 🔑 Keys (principal)
Targets:AddToggle("EspKey", {
    Text = "Keys",
    Default = false,
    Callback = function(enabled)
        espEnabled.Key = enabled
        if enabled then
            createKeyESPs()
        else
            for _, keyESP in ipairs(currentKeyESPs) do
                ModelESP:Remove(keyESP)
            end
            currentKeyESPs = {}
        end
    end
})

-- 📦 Items (principal)
Targets:AddToggle("EspItem", {
    Text = "Items",
    Default = false,
    Callback = function(enabled)
        espEnabled.Items = enabled
        if enabled then
            scanAllItems()
            task.spawn(function()
                while espEnabled.Items do
                    scanAllItems()
                    task.wait(3)
                end
            end)
        else
            disableItemsESP()
        end
    end
})

-- 💰 Gold
Targets:AddToggle("EspGold", {
    Text = "Gold Piles",
    Default = false,
    Callback = function(enabled)
        espEnabled.Gold = enabled
        if enabled then
            scanAllGoldPiles()
            for _, room in ipairs(Workspace.CurrentRooms:GetChildren()) do
                if room:FindFirstChild("Assets") then
                    room.Assets.DescendantAdded:Connect(addGoldESP)
                end
            end
            task.spawn(function()
                while espEnabled.Gold do
                    scanAllGoldPiles()
                    task.wait(3)
                end
            end)
        else
            for _, goldESP in ipairs(currentGoldESPs) do
                ModelESP:Remove(goldESP)
            end
            currentGoldESPs = {}
        end
    end
})

-- 📖 Books (apenas sala 50)
Targets:AddToggle("EspBook", {
    Text = "Books",
    Default = false,
    Callback = function(enabled)
        espEnabled.Books = enabled
        if enabled then
            scanBooksInRoom50()
            local room50 = Workspace.CurrentRooms:FindFirstChild("50")
            if room50 and room50:FindFirstChild("Assets") then
                room50.Assets.DescendantAdded:Connect(addBookESP)
            end
            task.spawn(function()
                while espEnabled.Books do
                    scanBooksInRoom50()
                    task.wait(3)
                end
            end)
        else
            for _, bookESP in ipairs(currentBookESPs) do
                ModelESP:Remove(bookESP)
            end
            currentBookESPs = {}
        end
    end
})
-- 👾 Entities
Targets:AddToggle("EspEntities", {
    Text = "Entities",
    Default = false,
    Callback = function(enabled)
        espEnabled.Entities = enabled
        if enabled then
            enableEntitiesESP()
        else
            disableEntitiesESP()
        end
    end
})

-- 📦 ChestBox
Targets:AddToggle("EspChestBox", {
    Text = "ChestBox",
    Default = false,
    Callback = function(enabled)
        espEnabled.ChestBox = enabled
        if enabled then
            scanAllRoomsChestBoxes()
        else
            disableChestESP()
        end
    end
})

-- 🪤 Dupe
Targets:AddToggle("EspDupe", {
    Text = "Dupe",
    Default = false,
    Callback = function(enabled)
        espEnabled.Dupe = enabled
        if enabled then
            scanRoomDupes()
            task.spawn(function()
                while espEnabled.Dupe do
                    scanRoomDupes()
                    task.wait(2)
                end
            end)
        else
            disableDupeESP()
        end
    end
})

-- 🪜 Lever
Targets:AddToggle("EspLever", {
    Text = "Lever",
    Default = false,
    Callback = function(enabled)
        espEnabled.Lever = enabled
        if enabled then
            task.spawn(function()
                while espEnabled.Lever do
                    scanCurrentRoomLevers()
                    task.wait(2)
                end
            end)
        else
            disableLeverESP()
        end
    end
})

-- 🪑 Hiding Spots
Targets:AddToggle("EspHidden", {
    Text = "Hiding Place",
    Default = false,
    Callback = function(enabled)
        espEnabled.Hidden = enabled
        if enabled then
            scanCurrentRoomHidden()
            task.spawn(function()
                while espEnabled.Hidden do
                    scanCurrentRoomHidden()
                    updateHiddenDistanceCheck()
                    task.wait(1)
                end
            end)
        else
            disableHiddenESP()
        end
    end
})

-- Esp Highlight Outline
Settings:AddToggle("EspHighlightOutline", {
    Text = "Esp Chams Outline",
    Default = true,
    Callback = function(Value)
        ModelESP:SetGlobalESPType("ShowHighlightOutline", Value)
    end
})

-- Esp Highlight Fill
Settings:AddToggle("EspHighlightFill", {
    Text = "Esp Chams Filled",
    Default = true,
    Callback = function(Value)
        ModelESP:SetGlobalESPType("ShowHighlightFill", Value)
    end
})

-- Esp Name
Settings:AddToggle("EspName", {
    Text = "Esp Name",
    Default = true,
    Callback = function(Value)
        ModelESP:SetGlobalESPType("ShowName", Value)
    end
})

-- Esp Distance
Settings:AddToggle("EspDistance", {
    Text = "Esp Distance",
    Default = true,
    Callback = function(Value)
        ModelESP:SetGlobalESPType("ShowDistance", Value)
    end
})

-- Esp Tracer
Settings:AddToggle("EspTracer", {
    Text = "Esp Tracer",
    Default = false,
    Callback = function(Value)
        ModelESP:SetGlobalESPType("ShowTracer", Value)
    end
})
Settings:AddToggle("RainbowEsp", {
    Text = "Rainbow Color",
    Default = false,
    Callback = function(Value)
        ModelESP:SetGlobalESPType("RainbowMode", Value)
    end
})

-- Esp Tracer Origin
Settings:AddDropdown("EspTracerOrigin", {
    Values = {"Top", "Center", "Bottom"},
    Default = "Top",
    Multi = false,
    Text = "Tracer Origin",
    Callback = function(Value)
        ModelESP:SetGlobalTracerOrigin(Value)
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


-- =========================
-- WATERMARK
-- =========================
local LatestRoom = ReplicatedStorage:WaitForChild("GameData"):WaitForChild("LatestRoom")
local FrameTimer, FrameCounter, FPS = tick(), 0, 60

RunService.RenderStepped:Connect(function()
    FrameCounter += 1
    if (tick() - FrameTimer) >= 1 then
        FPS, FrameTimer, FrameCounter = FrameCounter, tick(), 0
    end

    local currentRoomValue = LatestRoom.Value
    local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())

    Library:SetWatermark(('%s : CurrentRooms | %s FPS | %s MS'):format(
        currentRoomValue,
        math.floor(FPS),
        ping
    ))
end)

-- =========================
-- UI SETTINGS
-- =========================
local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')

MenuGroup:AddToggle("KeybindMenuOpen", { 
	Default = Library.KeybindFrame.Visible, 
	Text = "Open Keybind Menu", 
	Callback = function(value) Library.KeybindFrame.Visible = value end
})

MenuGroup:AddToggle("ShowCustomCursor", { 
	Text = "Custom Cursor", 
	Default = true, 
	Callback = function(Value) Library.ShowCustomCursor = Value end
})

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { 
	Default = "RightShift", 
	NoUI = true, 
	Text = "Menu keybind" 
})

MenuGroup:AddButton("Unload", function() Library:Unload() end)
Library.ToggleKeybind = Options.MenuKeybind 

-- =========================
-- THEME & SAVE MANAGERS
-- =========================
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

ThemeManager:SetFolder('Kolt')
SaveManager:SetFolder('Kolt/Doors')
SaveManager:SetSubFolder('6839171747')

SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])
SaveManager:LoadAutoloadConfig()
