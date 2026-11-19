--!strict
-- The shop the HUD's buttons talk to: buy another pedestal, faster shoes or a longer gate lock, and route
-- the LOCK and REBIRTH buttons to their services. The server checks every price.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local UpgradeShop = {}

local services: { [string]: any } = {}
local Remotes: Folder

local function notify(player: Player, text: string, color: Color3?)
	(Remotes :: any).Notify:FireClient(player, text, color or Color3.fromRGB(255, 255, 255))
end

local function pay(player: Player, cost: number): boolean
	if services.PlayerData.trySpend(player, cost) then
		(Remotes :: any).Sfx:FireClient(player, "upgrade")
		return true
	end
	notify(player, "Need " .. GameConfig.money(cost) .. "!", Color3.fromRGB(255, 110, 110));
	(Remotes :: any).Sfx:FireClient(player, "blocked")
	return false
end

function UpgradeShop.buyPedestal(player: Player)
	local profile = services.PlayerData.get(player)
	if not profile or profile.pedestals >= GameConfig.MAX_PEDESTALS then
		return
	end
	if pay(player, services.PlayerData.nextPedestalCost(profile)) then
		profile.pedestals += 1
		services.PlayerData.publish(player)
		services.BasePedestals.refreshPedestals(player)
		notify(player, "New pedestal! " .. profile.pedestals .. "/" .. GameConfig.MAX_PEDESTALS, Color3.fromRGB(120, 255, 140))
	end
end

function UpgradeShop.buySpeed(player: Player)
	local profile = services.PlayerData.get(player)
	local cost = profile and GameConfig.SPEED_COSTS[profile.speedLevel + 1]
	if not profile or not cost then
		return
	end
	if pay(player, cost) then
		profile.speedLevel += 1
		services.PlayerData.publish(player)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = GameConfig.SPEED_LEVELS[profile.speedLevel]
		end
		notify(player, "Faster shoes! Speed " .. GameConfig.SPEED_LEVELS[profile.speedLevel], Color3.fromRGB(120, 200, 255))
	end
end

function UpgradeShop.buyLockTime(player: Player)
	local profile = services.PlayerData.get(player)
	local cost = profile and GameConfig.LOCK_COSTS[profile.lockLevel + 1]
	if not profile or not cost then
		return
	end
	if pay(player, cost) then
		profile.lockLevel += 1
		services.PlayerData.publish(player)
		notify(player, "Longer lock! " .. GameConfig.LOCK_LEVELS[profile.lockLevel] .. "s shield", Color3.fromRGB(255, 120, 150))
	end
end

function UpgradeShop.handleShopRequest(player: Player, action: any)
	if action == "BuyPedestal" then
		UpgradeShop.buyPedestal(player)
	elseif action == "BuySpeed" then
		UpgradeShop.buySpeed(player)
	elseif action == "BuyLock" then
		UpgradeShop.buyLockTime(player)
	elseif action == "LockGate" then
		services.GateLock.lockGate(player)
	elseif action == "Rebirth" then
		services.RebirthService.rebirth(player)
	end
end

function UpgradeShop.init(all: { [string]: any })
	services = all
	Remotes = ReplicatedStorage:WaitForChild("Remotes") :: Folder
end

function UpgradeShop.start()
	(Remotes :: any).ShopRequest.OnServerEvent:Connect(UpgradeShop.handleShopRequest)
end

return UpgradeShop
