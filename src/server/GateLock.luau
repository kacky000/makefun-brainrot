--!strict
-- Gate locks: the owner presses the booth's LOCK button (or the HUD's LOCK) and a laser shield closes the
-- gate for a while. Locked booths cannot be stolen from, raiding clowns bounce off, and other players who
-- touch the laser are pushed back out. Then it cools down before it can be locked again.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local GateLock = {}

local services: { [string]: any } = {}
local Remotes: Folder
local pushDebounce: { [Player]: number } = {}

local function notify(player: Player, text: string, color: Color3?)
	(Remotes :: any).Notify:FireClient(player, text, color or Color3.fromRGB(255, 255, 255))
end

function GateLock.isLocked(player: Player): boolean
	local profile = services.PlayerData.get(player)
	return profile ~= nil and profile.lockUntil > workspace:GetServerTimeNow()
end

function GateLock.lockGate(player: Player): boolean
	local profile = services.PlayerData.get(player)
	if not profile then
		return false
	end
	local now = workspace:GetServerTimeNow()
	if profile.lockUntil > now then
		notify(player, "Your gate is already locked.")
		return false
	end
	if profile.lockCooldownUntil > now then
		notify(player, "Lock recharging: " .. math.ceil(profile.lockCooldownUntil - now) .. "s", Color3.fromRGB(255, 200, 80))
		return false
	end
	local seconds = GameConfig.LOCK_LEVELS[profile.lockLevel]
	profile.lockUntil = now + seconds
	profile.lockCooldownUntil = profile.lockUntil + GameConfig.LOCK_COOLDOWN
	services.PlayerData.publish(player)
	notify(player, "GATE LOCKED for " .. seconds .. "s! Thieves bounce off.", Color3.fromRGB(255, 80, 110));
	(Remotes :: any).Sfx:FireClient(player, "lock")
	return true
end

-- Shows or hides each booth's laser and keeps the lock countdown on its sign.
local function refreshLasers()
	local now = workspace:GetServerTimeNow()
	for player, profile in services.PlayerData.all() do
		local plot = services.BasePedestals.plotOf(player)
		if plot then
			local locked = profile.lockUntil > now
			plot.laser.Transparency = if locked then 0.15 else 1
			plot.lockButton.Color = if locked then Color3.fromRGB(80, 255, 140) else Color3.fromRGB(255, 40, 70)
			if profile.lockUntil > 0 and not locked and profile.lockUntil > now - 0.6 then
				notify(player, "Your gate is OPEN again!", Color3.fromRGB(255, 200, 80))
			end
		end
	end
end

local function onLaserTouched(plotIndex: number, hit: BasePart)
	local character = hit.Parent
	local player = character and Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end
	local owner = services.BasePedestals.ownerOfPlot(plotIndex)
	if not owner or owner == player or not GateLock.isLocked(owner) then
		return
	end
	if (pushDebounce[player] or 0) > os.clock() then
		return
	end
	pushDebounce[player] = os.clock() + 0.6
	local plot = services.CarnivalWorld.plots[plotIndex]
	local rootPart = (character :: Model):FindFirstChild("HumanoidRootPart") :: BasePart?
	if rootPart then
		rootPart.AssemblyLinearVelocity = -plot.inward * 70 + Vector3.new(0, 25, 0)
	end
	notify(player, "That booth is LOCKED!", Color3.fromRGB(255, 80, 100));
	(Remotes :: any).Sfx:FireClient(player, "blocked")
end

function GateLock.init(all: { [string]: any })
	services = all
	Remotes = ReplicatedStorage:WaitForChild("Remotes") :: Folder
end

function GateLock.start()
	for index, plot in services.CarnivalWorld.plots do
		plot.laser.CanTouch = true
		plot.laser.Touched:Connect(function(hit)
			onLaserTouched(index, hit)
		end)
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "LockPrompt"
		prompt.ActionText = "Lock Gate"
		prompt.ObjectText = "Laser shield"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = plot.lockButton
		prompt.Triggered:Connect(function(player)
			if services.BasePedestals.ownerOfPlot(index) == player then
				GateLock.lockGate(player)
			end
		end)
	end
	task.spawn(function()
		while true do
			task.wait(0.5)
			refreshLasers()
		end
	end)
end

return GateLock
