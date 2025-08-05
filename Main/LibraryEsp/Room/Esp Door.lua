local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local currentRoom = player:GetAttribute("CurrentRoom")
local workspaceRooms = workspace:WaitForChild("CurrentRooms")

--// CONFIGURAÇÕES EXTERNAS E MÉTODOS DE CONTROLE
local settings = {
	Enabled = true,
	Color = Color3.fromRGB(255, 0, 0),
	VisibleTypes = { Locked = true, Door = true },

	Stop = function(self)
		self.Enabled = false
		removeCurrentESP()
	end,

	Start = function(self)
		self.Enabled = true
	end,

	SetVisible = function(self, espType, visible)
		if self.VisibleTypes[espType] ~= nil then
			self.VisibleTypes[espType] = visible
		end
	end,
}

--// Utilidade: Formatar número com 4 dígitos
local function formatRoomNumber(n)
	return string.format("%04d", tonumber(n))
end

--// Verifica se o modelo é válido para ESP
local function isValidDoor(doorModel)
	if not doorModel or not doorModel:IsA("Model") then return false end
	return doorModel:FindFirstChild("Door") and doorModel.Door:IsA("BasePart")
end

--// Procura a próxima porta com Collision
local function findNextValidRoom(startIndex)
	for i = startIndex + 1, 999 do
		local room = workspaceRooms:FindFirstChild(tostring(i))
		if room and room:FindFirstChild("Door") then
			local doorPart = room.Door:FindFirstChild("Door")
			if doorPart and doorPart:IsA("BasePart") and doorPart.CanCollide then
				return room, i
			end
		end
	end
	return nil
end

--// Cria a ESP na porta da sala
local currentESP = nil
local currentESPType = nil

local function createDoorESP(room, index)
	if not room then return end
	local doorModel = room:FindFirstChild("Door")
	if not isValidDoor(doorModel) then return end
	local doorPart = doorModel.Door
	local hasLock = doorModel:FindFirstChild("Lock")

	local typeName = hasLock and "Locked" or "Door"
	local name = string.format("%s (%s)", typeName, formatRoomNumber(index + 1))

	-- Checa se esse tipo está visível nas configurações
	if not settings.VisibleTypes[typeName] then return end

	ModelESP:Add(doorPart, {
		Color = settings.Color,
		Name = name,
		ShowName = true,
		Tracer = true,
		HighlightFill = true,
		HighlightOutline = true,
		TracerOrigin = "Bottom",
	})
	currentESP = doorPart
	currentESPType = typeName
end

--// Remove ESP atual
function removeCurrentESP()
	if currentESP then
		ModelESP:Remove(currentESP)
		currentESP = nil
		currentESPType = nil
	end
end

--// Marca como "Door Opened" (não removível)
local function markDoorOpened(model)
	pcall(function()
		model:SetAttribute("Door Opened", true)
	end)
end

--// Verifica e atualiza a porta atual
local function checkDoorLoop()
	local room = workspaceRooms:FindFirstChild(tostring(currentRoom))
	if not room then return end
	local doorModel = room:FindFirstChild("Door")
	if not isValidDoor(doorModel) then return end
	local doorPart = doorModel.Door

	if not currentESP and doorPart.CanCollide then
		createDoorESP(room, currentRoom)
	end

	-- Se a porta perdeu colisão
	if currentESP and not doorPart.CanCollide then
		removeCurrentESP()
		markDoorOpened(doorModel)

		-- procura próxima porta válida
		local nextRoom, nextIndex = findNextValidRoom(currentRoom)
		if nextRoom and nextIndex then
			currentRoom = nextIndex
			createDoorESP(nextRoom, nextIndex)
		end
	end
end

--// Primeira detecção do jogador
task.spawn(function()
	while not currentRoom do
		currentRoom = player:GetAttribute("CurrentRoom")
		task.wait(0.2)
	end
end)

--// Loop principal
RunService.RenderStepped:Connect(function()
	if settings.Enabled and currentRoom then
		checkDoorLoop()
	end
end)

return settings
