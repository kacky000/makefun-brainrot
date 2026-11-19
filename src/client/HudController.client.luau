--!strict
-- The player's screen: cash and income, the event banner, the popcorn-wave timer, the next goal, the
-- LOCK / UPGRADES / REBIRTH / INDEX buttons, the carrying banner, toasts, big celebrations, "+$" popups
-- over the player's pedestals, sounds, and which prompts the player may see. Reads only attributes the
-- server publishes; every purchase is a request the server checks.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local MutationRoller = require(ReplicatedStorage:WaitForChild("MutationRoller"))
local IndexBook = require(script.Parent:WaitForChild("IndexBook"))

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
end)

local rgb = Color3.fromRGB
local GOLD = rgb(255, 222, 60)
local INK = rgb(45, 20, 80)

-- Sounds: Roblox's built-in client sounds, pitched per moment (see README "Sound sources").
local SOUNDS = {
	buy = { "rbxasset://sounds/volume_slider.ogg", 1.6, 0.8 },
	place = { "rbxasset://sounds/action_jump_land.mp3", 1.3, 1 },
	collect = { "rbxasset://sounds/volume_slider.ogg", 2.2, 0.6 },
	stolen = { "rbxasset://sounds/ouch.ogg", 1.0, 1 },
	blocked = { "rbxasset://sounds/impact_water.mp3", 1.7, 0.7 },
	rebirth = { "rbxasset://sounds/impact_explosion_03.mp3", 1.3, 0.7 },
	wave = { "rbxasset://sounds/impact_water.mp3", 0.6, 1 },
	bonk = { "rbxasset://sounds/oof.ogg", 1.7, 1 },
	lock = { "rbxasset://sounds/action_get_up.mp3", 2.0, 1 },
	alarm = { "rbxasset://sounds/action_falling.ogg", 1.5, 0.8 },
	upgrade = { "rbxasset://sounds/action_jump.mp3", 1.4, 0.9 },
}

local function playSound(name: string)
	local spec = SOUNDS[name]
	if not spec then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = spec[1]
	sound.PlaybackSpeed = spec[2]
	sound.Volume = spec[3]
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	task.delay(4, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

------------------------------------------------------------------------------------------------ building
local gui = Instance.new("ScreenGui")
gui.Name = "CarnivalHud"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local scale = Instance.new("UIScale")
scale.Parent = gui

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function stroke(parent: Instance, color: Color3, thickness: number)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function panel(name: string, size: UDim2, pos: UDim2, anchor: Vector2, color: Color3, parent: Instance?): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.Position = pos
	f.AnchorPoint = anchor
	f.BackgroundColor3 = color
	f.Parent = parent or gui
	corner(f, 12)
	return f
end

local function label(parent: Instance, text: string, size: UDim2, pos: UDim2, color: Color3, font: Enum.Font?): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size
	l.Position = pos
	l.Font = font or Enum.Font.FredokaOne
	l.TextScaled = true
	l.Text = text
	l.TextColor3 = color
	l.TextStrokeTransparency = 0
	l.TextStrokeColor3 = rgb(20, 5, 40)
	l.Parent = parent
	return l
end

-- Cash, top centre.
local cashPanel = panel("Cash", UDim2.fromOffset(390, 104), UDim2.new(0.5, 0, 0, 6), Vector2.new(0.5, 0), INK)
cashPanel.BackgroundTransparency = 0.15
stroke(cashPanel, GOLD, 4)
local cashLabel = label(cashPanel, "$0", UDim2.new(1, -16, 0, 56), UDim2.fromOffset(8, 2), GOLD)
local incomeLabel = label(cashPanel, "+$0/s", UDim2.new(1, -16, 0, 28), UDim2.fromOffset(8, 56), rgb(110, 255, 130))
local rebirthLine = label(cashPanel, "", UDim2.new(1, -16, 0, 18), UDim2.fromOffset(8, 84), rgb(230, 200, 255), Enum.Font.GothamBold)

-- Event banner and wave bar under it.
local eventBanner = panel("EventBanner", UDim2.fromOffset(660, 46), UDim2.new(0.5, 0, 0, 116), Vector2.new(0.5, 0), rgb(255, 200, 40))
stroke(eventBanner, rgb(255, 255, 255), 3)
local eventLabel = label(eventBanner, "", UDim2.new(1, -16, 1, -6), UDim2.fromOffset(8, 3), rgb(255, 255, 255))
eventBanner.Visible = false

local waveBar = panel("WaveBar", UDim2.fromOffset(560, 38), UDim2.new(0.5, 0, 0, 168), Vector2.new(0.5, 0), rgb(60, 30, 90))
stroke(waveBar, rgb(255, 230, 160), 3)
local waveFill = Instance.new("Frame")
waveFill.BackgroundColor3 = rgb(255, 214, 90)
waveFill.Size = UDim2.fromScale(0.5, 1)
waveFill.Parent = waveBar
corner(waveFill, 12)
local waveLabel = label(waveBar, "", UDim2.new(1, -16, 1, -6), UDim2.fromOffset(8, 3), rgb(255, 255, 255))
waveLabel.ZIndex = 2

-- Next goal card, left, clear of Roblox's top-left buttons.
local goalCard = panel("NextGoal", UDim2.fromOffset(300, 150), UDim2.fromOffset(12, 120), Vector2.zero, INK)
goalCard.BackgroundTransparency = 0.15
stroke(goalCard, rgb(130, 230, 190), 3)
label(goalCard, "NEXT GOAL", UDim2.new(1, -16, 0, 26), UDim2.fromOffset(8, 4), rgb(130, 230, 190))
local goalLine = label(goalCard, "", UDim2.new(1, -16, 0, 22), UDim2.fromOffset(8, 32), rgb(255, 255, 255))
local goalBarBack = panel("GoalBar", UDim2.new(1, -16, 0, 16), UDim2.fromOffset(8, 58), Vector2.zero, rgb(25, 10, 45), goalCard)
local goalBarFill = panel("Fill", UDim2.fromScale(0.3, 1), UDim2.fromScale(0, 0), Vector2.zero, rgb(200, 110, 255), goalBarBack)
local boothLine = label(goalCard, "", UDim2.new(1, -16, 0, 22), UDim2.fromOffset(8, 82), rgb(255, 225, 120))
local indexLine = label(goalCard, "", UDim2.new(1, -16, 0, 22), UDim2.fromOffset(8, 110), rgb(150, 220, 255))
for _, l in { goalLine, boothLine, indexLine } do
	l.TextXAlignment = Enum.TextXAlignment.Left
end

-- Big side buttons, right.
local buttons: { [string]: { frame: TextButton, sub: TextLabel } } = {}
local function sideButton(name: string, title: string, color: Color3, order: number, onClick: () -> ())
	local b = Instance.new("TextButton")
	b.Name = name
	b.AutoButtonColor = true
	b.Text = ""
	b.AnchorPoint = Vector2.new(1, 0)
	b.Size = UDim2.fromOffset(214, 66)
	b.Position = UDim2.new(1, -12, 0, 120 + (order - 1) * 76)
	b.BackgroundColor3 = color
	b.Parent = gui
	corner(b, 14)
	stroke(b, rgb(255, 255, 255), 3)
	label(b, title, UDim2.new(1, -12, 0, 36), UDim2.fromOffset(6, 4), rgb(255, 255, 255))
	local sub = label(b, "", UDim2.new(1, -12, 0, 20), UDim2.fromOffset(6, 40), rgb(255, 250, 210), Enum.Font.GothamBold)
	b.Activated:Connect(onClick)
	buttons[name] = { frame = b, sub = sub }
end

-- Carrying banner and the features strip, bottom.
local carryBanner = panel("Carrying", UDim2.fromOffset(700, 54), UDim2.new(0.5, 0, 1, -96), Vector2.new(0.5, 1), rgb(255, 214, 50))
stroke(carryBanner, INK, 4)
local carryLabel = label(carryBanner, "", UDim2.new(1, -16, 1, -8), UDim2.fromOffset(8, 4), INK)
carryLabel.TextStrokeTransparency = 1
carryBanner.Visible = false

local features = panel("Features", UDim2.fromOffset(980, 30), UDim2.new(0.5, 0, 1, -8), Vector2.new(0.5, 1), rgb(30, 12, 55))
features.BackgroundTransparency = 0.2
label(
	features,
	string.format(
		"%d BRAINROTS · %d RARITIES · %d MUTATIONS · POPCORN WAVE · CLOWN THIEVES · GATE LOCK · REBIRTH · %d EVENTS",
		BrainrotCatalog.COUNT,
		#BrainrotCatalog.rarities,
		#MutationRoller.list,
		4
	),
	UDim2.new(1, -16, 1, -6),
	UDim2.fromOffset(8, 3),
	rgb(255, 235, 150)
)

-- Toasts, left under the goal card.
local toastHolder = Instance.new("Frame")
toastHolder.BackgroundTransparency = 1
toastHolder.Position = UDim2.fromOffset(12, 282)
toastHolder.Size = UDim2.fromOffset(330, 200)
toastHolder.Parent = gui
local toastLayout = Instance.new("UIListLayout")
toastLayout.Padding = UDim.new(0, 6)
toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
toastLayout.Parent = toastHolder
local toastCount = 0

local function toast(text: string, color: Color3?)
	toastCount += 1
	local f = panel("Toast", UDim2.new(1, 0, 0, 40), UDim2.new(), Vector2.zero, rgb(30, 12, 55), toastHolder)
	f.LayoutOrder = -toastCount
	f.BackgroundTransparency = 0.1
	stroke(f, color or rgb(255, 255, 255), 2)
	local l = label(f, text, UDim2.new(1, -14, 1, -8), UDim2.fromOffset(7, 4), color or rgb(255, 255, 255))
	l.TextXAlignment = Enum.TextXAlignment.Left
	local children = toastHolder:GetChildren()
	local frames = 0
	for _, child in children do
		if child:IsA("Frame") then
			frames += 1
		end
	end
	if frames > 4 then
		local oldest: Frame? = nil
		for _, child in children do
			if child:IsA("Frame") and (oldest == nil or child.LayoutOrder > (oldest :: Frame).LayoutOrder) then
				oldest = child
			end
		end
		if oldest then
			oldest:Destroy()
		end
	end
	task.delay(5, function()
		if f.Parent then
			f:Destroy()
		end
	end)
end

-- Celebration: big centre title with a pop and a confetti burst.
local celebrate = Instance.new("Frame")
celebrate.BackgroundTransparency = 1
celebrate.AnchorPoint = Vector2.new(0.5, 0.5)
celebrate.Position = UDim2.fromScale(0.5, 0.42)
celebrate.Size = UDim2.fromOffset(700, 150)
celebrate.Visible = false
celebrate.Parent = gui
local celebrateTitle = label(celebrate, "", UDim2.new(1, 0, 0.62, 0), UDim2.new(), GOLD)
local celebrateSub = label(celebrate, "", UDim2.new(1, 0, 0.34, 0), UDim2.fromScale(0, 0.64), rgb(255, 255, 255))
local celebrateScale = Instance.new("UIScale")
celebrateScale.Parent = celebrate

local function showCelebration(title: string, sub: string, color: Color3)
	celebrateTitle.Text = title
	celebrateTitle.TextColor3 = color
	celebrateSub.Text = sub
	celebrate.Visible = true
	celebrateScale.Scale = 0.3
	TweenService:Create(celebrateScale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	local camera = Workspace.CurrentCamera
	if camera then
		local fov = camera.FieldOfView
		camera.FieldOfView = fov + 8
		TweenService:Create(camera, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { FieldOfView = fov }):Play()
	end
	task.delay(2.6, function()
		celebrate.Visible = false
	end)
end

-- Upgrades panel.
local upgrades = panel("Upgrades", UDim2.fromOffset(520, 300), UDim2.fromScale(0.5, 0.52), Vector2.new(0.5, 0.5), rgb(40, 60, 140))
stroke(upgrades, GOLD, 4)
upgrades.Visible = false
label(upgrades, "UPGRADES", UDim2.new(1, -20, 0, 44), UDim2.fromOffset(10, 8), GOLD)
local upgradeRows: { [string]: TextLabel } = {}
local function upgradeRow(order: number, key: string, title: string, action: string)
	local row = panel(key, UDim2.new(1, -24, 0, 64), UDim2.fromOffset(12, 58 + (order - 1) * 74), Vector2.zero, rgb(25, 35, 90), upgrades)
	local t = label(row, title, UDim2.new(0.6, 0, 0, 30), UDim2.fromOffset(10, 4), rgb(255, 255, 255))
	t.TextXAlignment = Enum.TextXAlignment.Left
	local info = label(row, "", UDim2.new(0.6, 0, 0, 22), UDim2.fromOffset(10, 36), rgb(180, 220, 255), Enum.Font.GothamBold)
	info.TextXAlignment = Enum.TextXAlignment.Left
	upgradeRows[key] = info
	local buy = Instance.new("TextButton")
	buy.AnchorPoint = Vector2.new(1, 0.5)
	buy.Position = UDim2.new(1, -10, 0.5, 0)
	buy.Size = UDim2.fromOffset(150, 46)
	buy.BackgroundColor3 = rgb(80, 220, 120)
	buy.Font = Enum.Font.FredokaOne
	buy.TextScaled = true
	buy.TextColor3 = rgb(255, 255, 255)
	buy.Text = "BUY"
	buy.Name = "Buy"
	buy.Parent = row
	corner(buy, 10)
	buy.Activated:Connect(function()
		(Remotes :: any).ShopRequest:FireServer(action)
	end)
end
upgradeRow(1, "Pedestal", "+1 PEDESTAL", "BuyPedestal")
upgradeRow(2, "Speed", "FASTER SHOES", "BuySpeed")
upgradeRow(3, "Lock", "LONGER GATE LOCK", "BuyLock")
local closeUpgrades = Instance.new("TextButton")
closeUpgrades.AnchorPoint = Vector2.new(1, 0)
closeUpgrades.Position = UDim2.new(1, -10, 0, 10)
closeUpgrades.Size = UDim2.fromOffset(40, 40)
closeUpgrades.BackgroundColor3 = rgb(255, 70, 90)
closeUpgrades.Font = Enum.Font.FredokaOne
closeUpgrades.TextScaled = true
closeUpgrades.Text = "X"
closeUpgrades.TextColor3 = rgb(255, 255, 255)
closeUpgrades.Parent = upgrades
corner(closeUpgrades, 10)
closeUpgrades.Activated:Connect(function()
	upgrades.Visible = false
end)

IndexBook.build(gui)

sideButton("Lock", "LOCK GATE", rgb(235, 50, 80), 1, function()
	(Remotes :: any).ShopRequest:FireServer("LockGate")
end)
sideButton("Upgrades", "UPGRADES", rgb(60, 130, 255), 2, function()
	upgrades.Visible = not upgrades.Visible
	IndexBook.setOpen(false)
end)
sideButton("Rebirth", "REBIRTH", rgb(170, 80, 240), 3, function()
	(Remotes :: any).ShopRequest:FireServer("Rebirth")
end)
sideButton("Index", "INDEX", rgb(40, 190, 110), 4, function()
	IndexBook.setOpen(not IndexBook.isOpen())
	upgrades.Visible = false
end)

------------------------------------------------------------------------------------------------ updating
local function attr(name: string, default: any): any
	local value = player:GetAttribute(name)
	if value == nil then
		return default
	end
	return value
end

local shownCash = 0
local function refreshStats()
	local cash = attr("Cash", 0)
	local income = attr("IncomePerSec", 0)
	local rebirths = attr("Rebirths", 0)
	local multiplier = attr("IncomeMultiplier", 1)
	incomeLabel.Text = "+" .. GameConfig.perSecond(income)
	rebirthLine.Text = string.format("REBIRTH %d  ·  x%.1f INCOME", rebirths, multiplier)

	local rebirthCost = attr("RebirthCost", 1)
	goalLine.Text = "Rebirth: " .. GameConfig.money(cash) .. " / " .. GameConfig.money(rebirthCost)
	goalBarFill.Size = UDim2.fromScale(math.clamp(cash / rebirthCost, 0.02, 1), 1)
	local used, total = attr("PedestalsUsed", 0), attr("Pedestals", 10)
	if used < total then
		boothLine.Text = string.format("Booth %d/%d - fill it from the belt!", used, total)
	else
		local nextCost = attr("NextPedestalCost", -1)
		boothLine.Text = if nextCost > 0 then string.format("Booth %d/%d - next pedestal %s", used, total, GameConfig.money(nextCost)) else string.format("Booth %d/%d - FULL", used, total)
	end
	indexLine.Text = string.format("Index %d/%d discovered", attr("IndexFound", 0), BrainrotCatalog.COUNT)

	local toBuy = 0
	for _, key in { "NextPedestalCost", "NextSpeedCost", "NextLockCost" } do
		if attr(key, -1) > 0 then
			toBuy += 1
		end
	end
	buttons.Upgrades.sub.Text = toBuy .. " upgrades to buy"
	buttons.Rebirth.sub.Text = GameConfig.money(rebirthCost) .. string.format(" · x%.1f", 1 + (rebirths + 1) * GameConfig.REBIRTH_INCOME_BONUS)
	buttons.Index.sub.Text = string.format("%d/%d found", attr("IndexFound", 0), BrainrotCatalog.COUNT)

	local function costText(key: string): string
		local cost = attr(key, -1)
		return if cost > 0 then GameConfig.money(cost) else "MAX"
	end
	upgradeRows.Pedestal.Text = string.format("%d/%d pedestals · next %s", total, GameConfig.MAX_PEDESTALS, costText("NextPedestalCost"))
	upgradeRows.Speed.Text = string.format("speed %d · next %s", GameConfig.SPEED_LEVELS[attr("SpeedLevel", 1)], costText("NextSpeedCost"))
	upgradeRows.Lock.Text = string.format("%ds shield · next %s", attr("LockSeconds", 40), costText("NextLockCost"))

	local carrying = attr("Carrying", "")
	carryBanner.Visible = carrying ~= ""
	if carrying ~= "" then
		local rarity = attr("CarryingRarity", "")
		carryLabel.Text = string.format("CARRYING %s (%s) - RUN TO YOUR BOOTH!", string.upper(carrying), string.upper(rarity))
	end
	IndexBook.refresh(attr("Discovered", ""))
end

for _, name in { "Cash", "IncomePerSec", "Rebirths", "Pedestals", "PedestalsUsed", "RebirthCost", "Carrying", "IndexFound", "Discovered", "NextPedestalCost", "NextSpeedCost", "NextLockCost", "SpeedLevel", "LockSeconds" } do
	player:GetAttributeChangedSignal(name):Connect(refreshStats)
end
refreshStats()

player:GetAttributeChangedSignal("OpenPanel"):Connect(function()
	if player:GetAttribute("OpenPanel") == "Index" then
		IndexBook.setOpen(true)
	end
end)

-- Per-frame: the rolling cash counter, the lock button, the event banner and the wave bar.
RunService.RenderStepped:Connect(function(dt)
	local viewport = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	scale.Scale = math.clamp(math.min(viewport.Y / 720, viewport.X / 1280), 0.55, 1.6)

	local cash = attr("Cash", 0)
	shownCash += (cash - shownCash) * math.min(1, dt * 8)
	if math.abs(cash - shownCash) < 1 then
		shownCash = cash
	end
	cashLabel.Text = GameConfig.money(shownCash)

	local now = Workspace:GetServerTimeNow()
	local lockUntil, cooldown = attr("LockUntil", 0), attr("LockCooldownUntil", 0)
	if lockUntil > now then
		buttons.Lock.sub.Text = "LOCKED " .. GameConfig.clock(lockUntil - now)
	elseif cooldown > now then
		buttons.Lock.sub.Text = "recharging " .. GameConfig.clock(cooldown - now)
	else
		buttons.Lock.sub.Text = attr("LockSeconds", 40) .. "s laser shield"
	end

	local eventName = Workspace:GetAttribute("EventName") or ""
	if eventName ~= "" then
		eventBanner.Visible = true
		eventBanner.BackgroundColor3 = Workspace:GetAttribute("EventColor") or GOLD
		local left = (Workspace:GetAttribute("EventEndsAt") or now) - now
		eventLabel.Text = string.format("%s! %s · %s", eventName, Workspace:GetAttribute("EventDesc") or "", GameConfig.clock(left))
	else
		eventBanner.Visible = false
	end

	if Workspace:GetAttribute("WaveActive") then
		local flash = math.floor(os.clock() * 4) % 2 == 0
		waveBar.BackgroundColor3 = if flash then rgb(230, 40, 50) else rgb(150, 20, 40)
		waveFill.Size = UDim2.fromScale(1, 1)
		waveFill.BackgroundTransparency = 1
		waveLabel.Text = "POPCORN WAVE! GET INTO A BOOTH!"
	else
		local eta = Workspace:GetAttribute("WaveEta") or 0
		local interval = Workspace:GetAttribute("WaveInterval") or GameConfig.WAVE_INTERVAL
		waveBar.BackgroundColor3 = rgb(60, 30, 90)
		waveFill.BackgroundTransparency = 0
		waveFill.Size = UDim2.fromScale(math.clamp(1 - eta / interval, 0.03, 1), 1)
		waveLabel.Text = "POPCORN WAVE IN " .. GameConfig.clock(eta)
	end
end)

------------------------------------------------------------------------------------------------ events
local remotes: any = Remotes
remotes.Notify.OnClientEvent:Connect(function(text: string, color: Color3?)
	toast(text, color)
end)
remotes.Celebrate.OnClientEvent:Connect(function(title: string, sub: string, color: Color3)
	showCelebration(title, sub, color)
	playSound("rebirth")
end)
remotes.Sfx.OnClientEvent:Connect(playSound)

-- "+$" popups rising from each of the player's earning pedestals.
local function pedestalPart(slot: number): BasePart?
	local carnival = Workspace:FindFirstChild("Carnival")
	local booth = carnival and carnival:FindFirstChild("Booth" .. tostring(attr("PlotIndex", 0)))
	return booth and booth:FindFirstChild("Pedestal" .. slot) :: BasePart?
end

remotes.IncomeTick.OnClientEvent:Connect(function(perSlot: { [string]: number }, _total: number)
	for key, amount in perSlot do
		local base = pedestalPart(tonumber(key) or 0)
		if base then
			local bill = Instance.new("BillboardGui")
			bill.Size = UDim2.fromScale(6, 1.6)
			bill.StudsOffset = Vector3.new(0, 1.5, 0)
			bill.MaxDistance = 90
			bill.LightInfluence = 0
			bill.Adornee = base
			local l = Instance.new("TextLabel")
			l.BackgroundTransparency = 1
			l.Size = UDim2.fromScale(1, 1)
			l.Font = Enum.Font.FredokaOne
			l.TextScaled = true
			l.Text = "+" .. GameConfig.money(amount)
			l.TextColor3 = rgb(120, 255, 130)
			l.TextStrokeTransparency = 0
			l.Parent = bill
			bill.Parent = gui
			TweenService:Create(bill, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { StudsOffset = Vector3.new(0, 5, 0) }):Play()
			TweenService:Create(l, TweenInfo.new(1.1), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
			task.delay(1.15, function()
				bill:Destroy()
			end)
		end
	end
end)

-- Show each player only the prompts meant for them: Sell and Lock on their own booth, Steal on others'.
local function filterPrompt(prompt: Instance)
	if not prompt:IsA("ProximityPrompt") then
		return
	end
	local function apply()
		local owner: number? = nil
		local node: Instance? = prompt.Parent
		while node and node ~= Workspace do
			local value = node:GetAttribute("OwnerUserId")
			if value then
				owner = value
				break
			end
			node = node.Parent
		end
		local mine = owner == player.UserId
		if prompt.Name == "SellPrompt" or prompt.Name == "LockPrompt" then
			prompt.Enabled = mine
		elseif prompt.Name == "StealPrompt" then
			prompt.Enabled = owner ~= nil and not mine
		end
	end
	apply()
	task.delay(0.5, apply)
end
Workspace.DescendantAdded:Connect(filterPrompt)
for _, d in Workspace:GetDescendants() do
	filterPrompt(d)
end

local _ = MutationRoller
