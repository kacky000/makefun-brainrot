-- GateLock: the defence. LOCK raises red lasers across the owner's gate for a while; a locked booth cannot be
-- robbed by the Sneaky Clown or by another player. After it drops there is a short cooldown.
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.GameConfig)
local PlayerState = require(script.Parent.Parent.State.PlayerState)
local BasePedestals = require(script.Parent.Parent.Economy.BasePedestals)

local GateLock = {}

local function setLasers(player: Player, on: boolean)
	local booth = BasePedestals.boothOf(player)
	if not booth then
		return
	end
	for _, bar in booth.model.Lasers:GetChildren() do
		bar.Transparency = if on then 0 else 1
	end
	local beam = booth.model.Gate.Beam
	local lamp = beam:FindFirstChild("LockLamp")
	if not lamp then
		lamp = Instance.new("BillboardGui")
		lamp.Name = "LockLamp"
		lamp.Size = UDim2.fromScale(16, 3.2)
		lamp.StudsOffsetWorldSpace = Vector3.new(0, 5.6, 0)
		lamp.MaxDistance = 160
		lamp.LightInfluence = 0
		local text = Instance.new("TextLabel")
		text.Name = "Text"
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundColor3 = Color3.fromRGB(200, 30, 50)
		text.Font = Enum.Font.LuckiestGuy
		text.TextColor3 = Color3.new(1, 1, 1)
		text.TextScaled = true
		text.TextStrokeTransparency = 0
		text.Parent = lamp
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.3, 0)
		corner.Parent = text
		lamp.Parent = beam
	end
	lamp.Enabled = on
end

function GateLock.lockGate(player: Player, seconds: number?): boolean -- lasers up: thieves and stealers are blocked
	local s = PlayerState.get(player)
	local now = Workspace:GetServerTimeNow()
	if not s or s.booth == 0 then
		return false
	end
	if now < s.lockedUntil then
		return false
	end
	if now < s.lockReadyAt and not seconds then
		PlayerState.notify(player, "Toast", { text = "LOCK RECHARGING", bad = true })
		return false
	end
	local duration = seconds or GateLock.lockSeconds(player)
	s.lockedUntil = now + duration
	s.lockReadyAt = s.lockedUntil + GameConfig.LOCK.cooldown
	setLasers(player, true)
	PlayerState.mirror(player)
	PlayerState.notify(player, "Locked", { seconds = duration })
	task.spawn(function()
		local lamp = BasePedestals.boothOf(player).model.Gate.Beam.LockLamp
		while player.Parent and PlayerState.get(player) == s and Workspace:GetServerTimeNow() < s.lockedUntil do
			lamp.Text.Text = "LOCKED " .. math.ceil(s.lockedUntil - Workspace:GetServerTimeNow()) .. "s"
			task.wait(0.25)
		end
		if player.Parent and PlayerState.get(player) == s then
			setLasers(player, false)
		end
	end)
	return true
end

function GateLock.isLocked(owner: Player): boolean
	local s = PlayerState.get(owner)
	return s ~= nil and Workspace:GetServerTimeNow() < s.lockedUntil
end

function GateLock.lockSeconds(player: Player): number
	local s = PlayerState.get(player)
	return GameConfig.LOCK.seconds + s.upgrades.Lock * GameConfig.UPGRADES.Lock.per
end

function GateLock.unlockGate(player: Player)
	local s = PlayerState.get(player)
	if s then
		s.lockedUntil = 0
		s.lockReadyAt = 0
		setLasers(player, false)
		PlayerState.mirror(player)
	end
end

return GateLock
