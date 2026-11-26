--!strict

-- Server combat controller
-- Place in ServerScriptService.
-- All action cooldowns, stamina, range, and damage are validated on the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local remotes = ReplicatedStorage:FindFirstChild("CombatRemotes") or Instance.new("Folder")
remotes.Name = "CombatRemotes"
remotes.Parent = ReplicatedStorage

local actionRemote = remotes:FindFirstChild("CombatAction") or Instance.new("RemoteEvent")
actionRemote.Name = "CombatAction"
actionRemote.Parent = remotes

local PUNCH_DAMAGE = 12
local PUNCH_RANGE = 5
local PUNCH_COOLDOWN = 0.32
local STOMP_DAMAGE = 18
local STOMP_MULTIPLIER = 1.5
local STOMP_RANGE = 8
local WEAVE_COOLDOWN = 1.2
local WEAVE_COST = 18
local GLIDE_SPEED = 32

local stateByPlayer: {[Player]: {
	PunchReady: number,
	WeaveReady: number,
	Stamina: number,
	Gliding: boolean,
}} = {}

local function getHumanoid(character: Model?): Humanoid?
	if not character then return nil end
	return character:FindFirstChildOfClass("Humanoid")
end

local function isAlive(character: Model?): boolean
	local humanoid = getHumanoid(character)
	return humanoid ~= nil and humanoid.Health > 0
end

local function takeStamina(state, cost: number): boolean
	if state.Stamina < cost then return false end
	state.Stamina -= cost
	return true
end

local function enemiesInRadius(attacker: Player, radius: number): {Humanoid}
	local character = attacker.Character
	if not character then return {} end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then return {} end

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}
	params.MaxParts = 100

	local hits = workspace:GetPartBoundsInRadius(root.Position, radius, params)
	local found: {[Humanoid]: boolean} = {}
	for _, part in hits do
		local model = part:FindFirstAncestorOfClass("Model")
		if model then
			local humanoid = getHumanoid(model)
			local hitPlayer = Players:GetPlayerFromCharacter(model)
			if humanoid and hitPlayer ~= attacker and isAlive(model) then
				found[humanoid] = true
			end
		end
	end

	local result = {}
	for humanoid in found do table.insert(result, humanoid) end
	return result
end

local function handlePunch(player: Player)
	local state = stateByPlayer[player]
	local character = player.Character
	if not state or not isAlive(character) then return end

	local now = workspace:GetServerTimeNow()
	if now < state.PunchReady then return end
	state.PunchReady = now + PUNCH_COOLDOWN

	for _, humanoid in enemiesInRadius(player, PUNCH_RANGE) do
		humanoid:TakeDamage(PUNCH_DAMAGE)
	end
end

local function handleStomp(player: Player)
	local state = stateByPlayer[player]
	local character = player.Character
	if not state or not isAlive(character) then return end

	local humanoid = getHumanoid(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") then return end

	-- Airborne stomps can only deal the stomp multiplier when the player is falling.
	if humanoid.FloorMaterial ~= Enum.Material.Air then return end
	if root.AssemblyLinearVelocity.Y > -8 then return end

	for _, target in enemiesInRadius(player, STOMP_RANGE) do
		target:TakeDamage(STOMP_DAMAGE * STOMP_MULTIPLIER)
	end
end

local function handleWeave(player: Player)
	local state = stateByPlayer[player]
	local character = player.Character
	if not state or not isAlive(character) then return end

	local now = workspace:GetServerTimeNow()
	if now < state.WeaveReady or not takeStamina(state, WEAVE_COST) then return end
	state.WeaveReady = now + WEAVE_COOLDOWN

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then return end
	local humanoid = getHumanoid(character)
	if not humanoid then return end

	-- Player-input-only lateral dodge; no target lock or automatic attacking.
	local look = root.CFrame.LookVector
	root.AssemblyLinearVelocity = Vector3.new(look.X * 38, math.max(12, root.AssemblyLinearVelocity.Y), look.Z * 38)
end

local function handleGlide(player: Player, enabled: boolean)
	local state = stateByPlayer[player]
	local character = player.Character
	if not state or not isAlive(character) then return end

	local humanoid = getHumanoid(character)
	if not humanoid or humanoid.FloorMaterial ~= Enum.Material.Air then
		state.Gliding = false
		return
	end

	if enabled and takeStamina(state, 1) then
		state.Gliding = true
	else
		state.Gliding = false
	end
end

actionRemote.OnServerEvent:Connect(function(player: Player, action: unknown, ...: any)
	if type(action) ~= "string" then return end
	if action == "Punch" then
		handlePunch(player)
	elseif action == "Stomp" then
		handleStomp(player)
	elseif action == "Weave" then
		handleWeave(player)
	elseif action == "Glide" then
		local enabled = select(1, ...)
		if type(enabled) == "boolean" then handleGlide(player, enabled) end
	end
end)

Players.PlayerAdded:Connect(function(player)
	stateByPlayer[player] = {
		PunchReady = 0,
		WeaveReady = 0,
		Stamina = 100,
		Gliding = false,
	}

	player.CharacterAdded:Connect(function(character)
		local humanoid = getHumanoid(character)
		if humanoid then humanoid.WalkSpeed = 16 end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	stateByPlayer[player] = nil
end)

-- Server-owned stamina and glide force.
while task.wait(0.1) do
	for player, state in stateByPlayer do
		local character = player.Character
		if isAlive(character) then
			state.Stamina = math.min(100, state.Stamina + (state.Gliding and 1 or 4))
			local root = character:FindFirstChild("HumanoidRootPart")
			if state.Gliding and root and root:IsA("BasePart") then
				local velocity = root.AssemblyLinearVelocity
				root.AssemblyLinearVelocity = Vector3.new(velocity.X, math.max(velocity.Y, -GLIDE_SPEED * 0.12), velocity.Z)
			end
		else
			state.Gliding = false
			state.Stamina = 100
		end
	end
end
