-- GateLock: the defence against stealing. Locking your gate fires three red lasers across it
-- for 30s+ (LONGER LOCK upgrade); while locked, Sneaky Clowns bounce off, rivals cannot steal
-- and are thrown back onto the midway. A cooldown follows each lock.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.GameConfig)

local GateLock = {}

local services = nil

local function setLasers(boothIndex: number, on: boolean)
	local booth = services.BasePedestals.boothModel(boothIndex)
	for laser = 1, 3 do
		local bar = booth:FindFirstChild("Laser" .. laser)
		if bar then
			bar.Transparency = if on then 0.05 else 1
		end
	end
	local button = booth:FindFirstChild("LockButton")
	if button then
		button.Color = if on then Color3.fromRGB(60, 255, 120) else Color3.fromRGB(232, 50, 70)
	end
end

-- Locks the player's gate if the lock is off cooldown. Returns true when the lasers went up.
function GateLock.lockGate(player: Player): boolean
	local state = services.PlayerState.get(player)
	if not state or not state.booth then
		return false
	end
	local now = workspace:GetServerTimeNow()
	if now < state.lockUntil then
		return false
	end
	if now < state.lockReadyAt then
		services.notify(player, "toast", { text = "LOCK RECHARGING " .. math.ceil(state.lockReadyAt - now) .. "s", tone = "info", fx = "error" })
		return false
	end
	local seconds = GameConfig.upgradeValue("LockTime", state.upgrades.LockTime)
	state.lockUntil = now + seconds
	state.lockReadyAt = state.lockUntil + GameConfig.LOCK_COOLDOWN
	setLasers(state.booth, true)
	services.PlayerState.publish(player)
	services.notify(player, "toast", { text = "GATE LOCKED " .. seconds .. "s! THIEVES BOUNCE OFF", tone = "good", fx = "lock" })
	return true
end

function GateLock.unlockGate(player: Player)
	local state = services.PlayerState.get(player)
	if state and state.booth then
		state.lockUntil = 0
		setLasers(state.booth, false)
		services.PlayerState.publish(player)
	end
end

function GateLock.isLocked(boothIndex: number): boolean
	local owner = services.BasePedestals.ownerOfBooth(boothIndex)
	local state = owner and services.PlayerState.get(owner)
	return state ~= nil and workspace:GetServerTimeNow() < state.lockUntil
end

-- Throws any rival standing inside a locked booth back out in front of its gate.
local function ejectIntruders(boothIndex: number, owner: Player)
	for player in services.PlayerState.all() do
		local torso = player ~= owner and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if torso and GameConfig.isInsideBooth(boothIndex, torso.Position) then
			player.Character:PivotTo(CFrame.new(GameConfig.boothPoint(boothIndex, 0, -8, 4)))
			services.notify(player, "toast", { text = "BLOCKED BY LOCK!", tone = "bad", fx = "blocked" })
		end
	end
end

function GateLock.start(allServices)
	services = allServices
	for boothIndex = 1, GameConfig.BOOTH_COUNT do
		local button = services.BasePedestals.boothModel(boothIndex):FindFirstChild("LockButton")
		if button then
			local prompt = Instance.new("ProximityPrompt")
			prompt.ObjectText = "Gate lock"
			prompt.ActionText = "Lock gate"
			prompt.MaxActivationDistance = 10
			prompt.RequiresLineOfSight = false
			prompt.Parent = button
			prompt.Triggered:Connect(function(player: Player)
				if services.BasePedestals.ownerOfBooth(boothIndex) == player then
					GateLock.lockGate(player)
				end
			end)
		end
	end
	task.spawn(function()
		while true do
			task.wait(0.25)
			local now = workspace:GetServerTimeNow()
			for player, state in services.PlayerState.all() do
				if state.booth then
					if state.lockUntil > 0 and now >= state.lockUntil then
						GateLock.unlockGate(player)
						services.notify(player, "toast", { text = "GATE UNLOCKED - thieves can get in", tone = "info", fx = "error" })
					elseif now < state.lockUntil then
						ejectIntruders(state.booth, player)
					end
				end
			end
		end
	end)
end

return GateLock
