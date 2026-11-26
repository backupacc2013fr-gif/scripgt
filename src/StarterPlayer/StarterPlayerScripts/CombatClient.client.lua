--!strict

-- Local combat input controller
-- Place in StarterPlayerScripts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local remotes = ReplicatedStorage:WaitForChild("CombatRemotes")
local actionRemote = remotes:WaitForChild("CombatAction")

local PUNCH_SPEED = 0.32
local lastPunch = 0

local glideHeld = false

local function punch()
	local now = os.clock()
	if now - lastPunch < PUNCH_SPEED then return end
	lastPunch = now
	actionRemote:FireServer("Punch")
end

local function toggleGlide(enabled: boolean)
	glideHeld = enabled
	actionRemote:FireServer("Glide", enabled)
end

local function onInputBegan(input: InputObject, processed: boolean)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.F or input.UserInputType == Enum.UserInputType.MouseButton1 then
		punch()
	elseif input.KeyCode == Enum.KeyCode.R then
		actionRemote:FireServer("Stomp")
	elseif input.KeyCode == Enum.KeyCode.Q then
		actionRemote:FireServer("Weave")
	elseif input.KeyCode == Enum.KeyCode.E then
		toggleGlide(true)
	end
end

local function onInputEnded(input: InputObject)
	if input.KeyCode == Enum.KeyCode.E then
		toggleGlide(false)
	end
end

UserInputService.InputBegan:Connect(onInputBegan)
UserInputService.InputEnded:Connect(onInputEnded)

-- A weave is intentionally not automatic. This setting provides an accessibility
-- hint for rapid repeated glides only; it never attacks or aims.
_G.SchoolFightAutoWeave = false
