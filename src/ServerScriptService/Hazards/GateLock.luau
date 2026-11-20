-- GateLock: the defence. Locking your gate switches on its laser bars for a while; a Sneaky Clown that reaches
-- a locked gate is bounced. The lock then recharges before it can be used again.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.GameConfig)
local PlayerState = require(script.Parent.Parent.State.PlayerState)

local GateLock = {}

local services

local function setLasers(booth: number, on: boolean)
	for _, bar in services.BasePedestals.boothFolder(booth).Lasers:GetChildren() do
		bar.Transparency = on and 0.1 or 1
	end
end

-- Lock the player's gate. seconds overrides the upgraded lock time (the tour uses it to hold the lock).
function GateLock.lockGate(player: Player, seconds: number?): boolean
	local state = PlayerState.get(player)
	if not state or state.booth == 0 then
		return false
	end
	local now = Workspace:GetServerTimeNow()
	if not seconds and now < state.lockReadyAt then
		local text = (now < state.lockUntil) and "GATE IS ALREADY LOCKED" or string.format("LOCK RECHARGING %ds", math.ceil(state.lockReadyAt - now))
		services.notify(player, "toast", { text = text, color = "red" })
		return false
	end
	local duration = seconds or GameConfig.lockSeconds(state.upgrades.lock)
	state.lockUntil = now + duration
	state.lockReadyAt = state.lockUntil + GameConfig.LOCK_COOLDOWN
	setLasers(state.booth, true)
	PlayerState.syncToClient(player)
	services.notify(player, "locked", { seconds = duration })
	local untilTime = state.lockUntil
	task.delay(duration, function()
		local latest = PlayerState.get(player)
		if latest and latest.lockUntil == untilTime then
			setLasers(latest.booth, false)
			services.notify(player, "unlocked", {})
		end
	end)
	return true
end

function GateLock.isLocked(player: Player): boolean
	local state = PlayerState.get(player)
	return state ~= nil and Workspace:GetServerTimeNow() < state.lockUntil
end

function GateLock.unlockGate(player: Player)
	local state = PlayerState.get(player)
	if state and state.booth > 0 then
		state.lockUntil = 0
		state.lockReadyAt = 0
		setLasers(state.booth, false)
		PlayerState.syncToClient(player)
	end
end

-- Each booth has a red button by its gate: the owner presses it to lock.
function GateLock.init(shared)
	services = shared
	for booth = 1, #GameConfig.BOOTHS do
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Lock Gate"
		prompt.ObjectText = "Laser Lock"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.KeyboardKeyCode = Enum.KeyCode.Q
		prompt.Parent = services.BasePedestals.boothFolder(booth).LockButton
		prompt.Triggered:Connect(function(player)
			if services.BasePedestals.ownerOf(booth) == player then
				GateLock.lockGate(player)
			end
		end)
	end
end

return GateLock
