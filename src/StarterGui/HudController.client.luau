-- HudController: the screen over the 3D carnival. Title and feature line, event and Popcorn Wave banners, cash and
-- money a second, the next goal, the LOCK / REBIRTH / INDEX / UPGRADES buttons, the carrying bar and the receipts.
-- It only draws what the server says (player attributes and Notify) and asks the server through Action.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local MutationRoller = require(ReplicatedStorage:WaitForChild("MutationRoller"))
local HudPanels = require(script.Parent:WaitForChild("HudPanels"))
local HudEffects = require(script.Parent:WaitForChild("HudEffects"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local actionRemote = remotes:WaitForChild("Action")
local notifyRemote = remotes:WaitForChild("Notify")
local money = BrainrotCatalog.formatMoney
local rgb = Color3.fromRGB

local old = player.PlayerGui:FindFirstChild("CarnivalHud")
if old then
	old:Destroy()
end

local function new(class: string, props: { [string]: any }, children: { Instance }?): any
	local inst = Instance.new(class)
	for key, value in props do
		if key ~= "Parent" then
			inst[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = inst
	end
	inst.Parent = props.Parent
	return inst
end

local function corner(radius: number)
	return new("UICorner", { CornerRadius = UDim.new(0, radius) })
end

local function stroke(color: Color3, thickness: number)
	return new("UIStroke", { Color = color, Thickness = thickness, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

local function outline(color: Color3, thickness: number)
	return new("UIStroke", { Color = color, Thickness = thickness, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual })
end

local function text(props: { [string]: any }, children: { Instance }?)
	local base = { BackgroundTransparency = 1, Font = Enum.Font.FredokaOne, TextColor3 = Color3.new(1, 1, 1), TextScaled = true }
	for key, value in props do
		base[key] = value
	end
	return new("TextLabel", base, children)
end

local gui = new("ScreenGui", { Name = "CarnivalHud", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 5, Parent = player.PlayerGui })
local uiScale = new("UIScale", { Parent = gui })
local function fitScale()
	local camera = Workspace.CurrentCamera
	uiScale.Scale = math.clamp(camera.ViewportSize.Y / 720, 0.5, 2)
end
fitScale()
Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitScale)

-- Top centre: the title and what the game holds, counted from the catalog and the config.
local DARK = rgb(28, 20, 44)
new("TextLabel", {
	Parent = gui,
	Name = "Logo",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 4),
	Size = UDim2.fromOffset(600, 62),
	BackgroundTransparency = 1,
	Font = Enum.Font.LuckiestGuy,
	Text = GameConfig.TITLE,
	TextColor3 = rgb(255, 222, 70),
	TextScaled = true,
}, { outline(rgb(214, 40, 120), 5) })
local features = string.format(
	"%s  ·  %d BRAINROTS  ·  %d RARITIES  ·  %d MUTATIONS  ·  WAVES  ·  THIEVES  ·  LOCK  ·  REBIRTH",
	GameConfig.SUBTITLE,
	BrainrotCatalog.count,
	#GameConfig.RARITIES,
	#GameConfig.MUTATIONS
)
text({ Parent = gui, Name = "Features", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 66), Size = UDim2.fromOffset(760, 28), BackgroundTransparency = 0.1, BackgroundColor3 = DARK, Text = features }, {
	corner(14),
	stroke(rgb(255, 222, 70), 2),
	new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3) }),
})

local banners = new("Frame", { Parent = gui, Name = "Banners", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 100), Size = UDim2.fromOffset(640, 100), BackgroundTransparency = 1 }, {
	new("UIListLayout", { Padding = UDim.new(0, 5), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
})
local function banner(name: string, order: number)
	return text({ Parent = banners, Name = name, LayoutOrder = order, Size = UDim2.fromOffset(640, 40), BackgroundTransparency = 0, BackgroundColor3 = DARK, Font = Enum.Font.LuckiestGuy, Visible = false }, {
		corner(12),
		stroke(Color3.new(1, 1, 1), 3),
		new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 3) }),
	})
end
local eventBanner = banner("EventBanner", 1)
local waveBanner = banner("WaveBanner", 2)
local thiefBanner = banner("ThiefBanner", 3)

-- Left: cash, money a second, stash, rebirth multiplier and the next goal. Kept below Roblox's own corner buttons.
local wallet = new("Frame", { Parent = gui, Name = "Wallet", Position = UDim2.fromOffset(14, 150), Size = UDim2.fromOffset(310, 156), BackgroundColor3 = DARK, BackgroundTransparency = 0.1 }, { corner(18), stroke(rgb(90, 240, 120), 3) })
local cashText = text({ Parent = wallet, Name = "Cash", Position = UDim2.fromOffset(12, 4), Size = UDim2.fromOffset(286, 64), Font = Enum.Font.LuckiestGuy, Text = "$0", TextColor3 = rgb(110, 255, 130), TextXAlignment = Enum.TextXAlignment.Left }, { outline(rgb(10, 70, 30), 3) })
local incomeText = text({ Parent = wallet, Name = "Income", Position = UDim2.fromOffset(12, 66), Size = UDim2.fromOffset(286, 38), Text = "+$0/s", TextColor3 = rgb(255, 236, 110), TextXAlignment = Enum.TextXAlignment.Left }, { outline(rgb(90, 60, 0), 2) })
local stashText = text({ Parent = wallet, Name = "Stash", Position = UDim2.fromOffset(12, 104), Size = UDim2.fromOffset(286, 22), Text = "BOOTH STASH $0", TextColor3 = rgb(200, 255, 210), TextXAlignment = Enum.TextXAlignment.Left })
local rebirthText = text({ Parent = wallet, Name = "Rebirth", Position = UDim2.fromOffset(12, 128), Size = UDim2.fromOffset(286, 22), Text = "REBIRTH 0  ·  x1.0 MONEY", TextColor3 = rgb(214, 170, 255), TextXAlignment = Enum.TextXAlignment.Left })

local goal = new("Frame", { Parent = gui, Name = "Goal", Position = UDim2.fromOffset(14, 314), Size = UDim2.fromOffset(310, 78), BackgroundColor3 = DARK, BackgroundTransparency = 0.1 }, { corner(16), stroke(rgb(255, 222, 70), 3) })
text({ Parent = goal, Position = UDim2.fromOffset(12, 4), Size = UDim2.fromOffset(286, 20), Text = "NEXT GOAL", TextColor3 = rgb(255, 222, 70), TextXAlignment = Enum.TextXAlignment.Left })
local goalText = text({ Parent = goal, Name = "GoalText", Position = UDim2.fromOffset(12, 24), Size = UDim2.fromOffset(286, 26), Text = "", TextXAlignment = Enum.TextXAlignment.Left })
local goalBar = new("Frame", { Parent = goal, Position = UDim2.fromOffset(12, 54), Size = UDim2.fromOffset(286, 14), BackgroundColor3 = rgb(60, 50, 80) }, { corner(7) })
local goalFill = new("Frame", { Parent = goalBar, Size = UDim2.fromScale(0, 1), BackgroundColor3 = rgb(110, 255, 130) }, { corner(7) })

-- Right: the four big buttons.
local panels = HudPanels.build(gui, { new = new, text = text, corner = corner, stroke = stroke, outline = outline, action = actionRemote, player = player })
local buttons = {}
local function bigButton(name: string, order: number, color: Color3, onPress: () -> ())
	local button = new("TextButton", { Parent = gui, Name = name .. "Button", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 176 + order * 82), Size = UDim2.fromOffset(204, 72), BackgroundColor3 = color, Text = "", AutoButtonColor = true }, {
		corner(18),
		stroke(Color3.new(1, 1, 1), 3),
	})
	text({ Parent = button, Name = "Title", Position = UDim2.fromOffset(8, 4), Size = UDim2.new(1, -16, 0, 38), Font = Enum.Font.LuckiestGuy, Text = name }, { outline(rgb(40, 20, 50), 2.5) })
	local sub = text({ Parent = button, Name = "Sub", Position = UDim2.fromOffset(8, 42), Size = UDim2.new(1, -16, 0, 24), Text = "" }, { outline(rgb(40, 20, 50), 1.5) })
	button.Activated:Connect(function()
		HudEffects.play("Click")
		onPress()
	end)
	buttons[name] = sub
end
bigButton("LOCK", 0, rgb(232, 52, 70), function()
	actionRemote:FireServer("Lock")
end)
bigButton("REBIRTH", 1, rgb(160, 84, 240), function()
	panels.toggle("Rebirth")
end)
bigButton("INDEX", 2, rgb(50, 150, 250), function()
	panels.toggle("Index")
end)
bigButton("UPGRADES", 3, rgb(255, 150, 40), function()
	panels.toggle("Upgrades")
end)

-- Bottom centre: what is being carried, and the last BOUGHT and PLACED receipts.
local carryBar = text({ Parent = gui, Name = "CarryBar", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -112), Size = UDim2.fromOffset(640, 46), BackgroundTransparency = 0, BackgroundColor3 = rgb(255, 222, 70), TextColor3 = rgb(50, 26, 60), Font = Enum.Font.LuckiestGuy, Visible = false }, {
	corner(14),
	stroke(Color3.new(1, 1, 1), 3),
	new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 4) }),
})
local receipts = {}
for i, kind in { "BOUGHT", "PLACED" } do
	receipts[kind] = text({ Parent = gui, Name = kind .. "Receipt", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -62 + (i - 1) * 46), Size = UDim2.fromOffset(600, 40), BackgroundTransparency = 0.1, BackgroundColor3 = DARK, RichText = true, Visible = false }, {
		corner(12),
		stroke(rgb(110, 255, 130), 2),
		new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5) }),
	})
end

local toast = text({ Parent = gui, Name = "Toast", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 236), Size = UDim2.fromOffset(700, 46), Font = Enum.Font.LuckiestGuy, TextTransparency = 1 }, { outline(rgb(40, 20, 50), 3) })
local toastStroke = toast:FindFirstChildOfClass("UIStroke")
local toastToken = 0
local function showToast(message: string, color: Color3, seconds: number?)
	toastToken += 1
	local token = toastToken
	toast.Text = message
	toast.TextColor3 = color
	toast.TextTransparency = 0
	toastStroke.Transparency = 0
	toast.Size = UDim2.fromOffset(760, 54)
	TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(700, 46) }):Play()
	task.delay(seconds or 2.2, function()
		if token == toastToken then
			TweenService:Create(toast, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
			TweenService:Create(toastStroke, TweenInfo.new(0.4), { Transparency = 1 }):Play()
		end
	end)
end

local function colorTag(color: Color3, inner: string): string
	return string.format('<font color="#%s">%s</font>', color:ToHex(), inner)
end

local function showReceipt(payload)
	local label = receipts[payload.line] or receipts.BOUGHT
	local rarity = GameConfig.RARITIES[payload.rarity or 1]
	local mutation = MutationRoller.find(payload.mutation)
	local name = (if mutation then colorTag(mutation.color, string.upper(mutation.name) .. " ") else "") .. colorTag(rarity.color, payload.name)
	label.Text = string.format("%s  %s  %s", payload.line, name, colorTag(rgb(255, 236, 110), payload.detail))
	label.Visible = true
	label.Size = UDim2.fromOffset(650, 46)
	TweenService:Create(label, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(600, 40) }):Play()
end

-- Everything the server tells this player.
local shownCash = 0
local function onNotify(kind: string, payload)
	if kind == "Receipt" then
		showReceipt(payload)
		if payload.line == "PLACED" then
			HudEffects.play("Place")
			HudEffects.popNumber(gui, payload.detail, rgb(110, 255, 130))
			if payload.isNew then
				showToast("NEW BRAINROT: " .. string.upper(payload.name) .. "!", GameConfig.RARITIES[payload.rarity].color, 3)
				HudEffects.confetti(gui, 30)
				HudEffects.play("Fanfare")
			end
			if (payload.rarity or 1) >= 4 then
				HudEffects.punchCamera(8)
			end
		else
			HudEffects.play("Buy")
		end
	elseif kind == "Collected" then
		HudEffects.play("Collect")
		HudEffects.popNumber(gui, "+" .. money(payload.amount), rgb(110, 255, 130))
	elseif kind == "Toast" then
		showToast(payload.text, if payload.bad then rgb(255, 110, 110) else rgb(255, 236, 110))
		if payload.bad then
			HudEffects.play("Error")
		end
	elseif kind == "Dropped" then
		showToast("YOU DROPPED " .. string.upper(payload.name) .. "!", rgb(255, 110, 110), 3)
	elseif kind == "WaveWarning" then
		HudEffects.play("Alarm")
	elseif kind == "WaveHit" then
		HudEffects.play("Splat")
		HudEffects.knockBack(player)
		HudEffects.shakeCamera(0.7)
		showToast(if payload.dropped then "SWEPT AWAY! LOST " .. string.upper(payload.dropped) else "SWEPT BY THE POPCORN WAVE!", rgb(255, 110, 110), 3)
	elseif kind == "WaveDodged" then
		showToast("WAVE DODGED! +" .. money(payload.bonus), rgb(110, 255, 130))
		HudEffects.play("Collect")
	elseif kind == "EventStarted" then
		showToast(payload.banner, payload.color, 3)
		HudEffects.play("Fanfare")
		HudEffects.confetti(gui, 24)
	elseif kind == "Locked" then
		showToast("GATE LOCKED FOR " .. payload.seconds .. "s!", rgb(255, 120, 130))
		HudEffects.play("Lock")
	elseif kind == "ThiefWarning" then
		showToast("SNEAKY CLOWN INCOMING! LOCK YOUR GATE!", rgb(255, 120, 130), 4)
		HudEffects.play("Alarm")
	elseif kind == "ThiefBlocked" then
		showToast("BLOCKED BY LOCK! THE CLOWN GOT NOTHING", rgb(110, 255, 130), 3)
		HudEffects.play("Blocked")
	elseif kind == "ThiefGrabbed" then
		showToast("HE GRABBED " .. string.upper(payload.name) .. "! BONK HIM!", rgb(255, 110, 110), 4)
		HudEffects.play("Alarm")
		HudEffects.shakeCamera(0.4)
	elseif kind == "ThiefBonked" then
		showToast("BONK! +" .. money(payload.reward), rgb(110, 255, 130), 3)
		HudEffects.play("Bonk")
		HudEffects.confetti(gui, 20)
	elseif kind == "Stolen" then
		showToast(string.upper(payload.name) .. " WAS STOLEN BY " .. string.upper(payload.by) .. "!", rgb(255, 110, 110), 4)
		HudEffects.play("Error")
	elseif kind == "RareOnBelt" then
		showToast(string.upper(GameConfig.RARITIES[payload.rarity].name) .. " ON THE BELT: " .. string.upper(payload.name) .. "!", GameConfig.RARITIES[payload.rarity].color, 3)
	elseif kind == "Upgraded" then
		showToast(payload.label .. " LEVEL " .. payload.level .. "!", rgb(255, 190, 90))
		HudEffects.play("Place")
	elseif kind == "Rebirthed" then
		showToast("REBIRTH " .. payload.rebirths .. "!  x" .. string.format("%.1f", payload.multiplier) .. " MONEY FOREVER", rgb(214, 170, 255), 4)
		HudEffects.play("Fanfare")
		HudEffects.confetti(gui, 60)
		HudEffects.flash(gui, rgb(214, 170, 255))
		HudEffects.punchCamera(18)
		shownCash = 0
	elseif kind == "OpenPanels" then
		panels.closeAll()
		for _, name in payload.panels do
			panels.open(name)
		end
	elseif kind == "ClosePanels" then
		panels.closeAll()
	elseif kind == "TourCamera" then
		HudEffects.aimCamera(payload.position, payload.lookAt)
	end
end
notifyRemote.OnClientEvent:Connect(onNotify)

-- Ten times a second: redraw from the attributes the server mirrors.
local function secondsLeft(untilTime: number?): number
	return math.max(0, math.ceil((untilTime or 0) - Workspace:GetServerTimeNow()))
end

local function parseFound(): { [string]: boolean }
	local found = {}
	for id in string.gmatch(player:GetAttribute("Found") or "", "[^,]+") do
		found[id] = true
	end
	return found
end

local function redraw()
	local cash = player:GetAttribute("Cash") or 0
	local income = player:GetAttribute("Income") or 0
	local rebirths = player:GetAttribute("Rebirths") or 0
	shownCash += (cash - shownCash) * 0.35
	if math.abs(cash - shownCash) < 1 then
		shownCash = cash
	end
	cashText.Text = money(shownCash)
	incomeText.Text = "+" .. money(income) .. "/s"
	stashText.Text = "BOOTH STASH " .. money(player:GetAttribute("Stash") or 0) .. "  ·  STEP ON PAD"
	rebirthText.Text = string.format("REBIRTH %d  ·  x%.1f MONEY", rebirths, 1 + rebirths * GameConfig.REBIRTH.incomeBonus)

	local found = parseFound()
	local nextGoal = BrainrotCatalog.nextGoal(found)
	if nextGoal then
		goalText.Text = nextGoal.name .. "  " .. money(nextGoal.price)
		goalText.TextColor3 = GameConfig.RARITIES[nextGoal.rarity].color
		goalFill.Size = UDim2.fromScale(math.clamp(cash / nextGoal.price, 0, 1), 1)
	else
		goalText.Text = "INDEX COMPLETE!"
		goalFill.Size = UDim2.fromScale(1, 1)
	end

	local lockedFor = secondsLeft(player:GetAttribute("LockedUntil"))
	local rechargeFor = secondsLeft(player:GetAttribute("LockReadyAt"))
	buttons.LOCK.Text = if lockedFor > 0 then "LOCKED " .. lockedFor .. "s" elseif rechargeFor > 0 then "RECHARGE " .. rechargeFor .. "s" else "READY - BLOCKS THIEVES"
	local rebirthCost = GameConfig.REBIRTH.base * GameConfig.REBIRTH.growth ^ rebirths
	buttons.REBIRTH.Text = if cash >= rebirthCost then "READY!" else money(rebirthCost)
	local foundCount = 0
	for _ in found do
		foundCount += 1
	end
	buttons.INDEX.Text = foundCount .. " / " .. BrainrotCatalog.count .. " FOUND"
	buttons.UPGRADES.Text = (player:GetAttribute("Filled") or 0) .. " / " .. (player:GetAttribute("Capacity") or 0) .. " PEDESTALS"

	local carrying = player:GetAttribute("Carrying") or ""
	carryBar.Visible = carrying ~= ""
	if carrying ~= "" then
		local entry = BrainrotCatalog.byId[carrying]
		local mutation = player:GetAttribute("CarryMutation") or ""
		carryBar.Text = "CARRYING " .. (if mutation ~= "" then string.upper(mutation) .. " " else "") .. string.upper(entry.name) .. " - RUN TO YOUR BOOTH!"
		carryBar.BackgroundColor3 = GameConfig.RARITIES[entry.rarity].color
	end

	local eventText = Workspace:GetAttribute("EventBanner") or ""
	eventBanner.Visible = eventText ~= ""
	if eventText ~= "" then
		eventBanner.Text = eventText .. "  ·  " .. secondsLeft(Workspace:GetAttribute("EventEnds")) .. "s"
		eventBanner.BackgroundColor3 = Workspace:GetAttribute("EventColor") or DARK
		eventBanner.TextColor3 = rgb(50, 26, 60)
	end
	local waveState = Workspace:GetAttribute("WaveState")
	waveBanner.Visible = true
	if waveState == "warning" then
		waveBanner.Text = "POPCORN WAVE IN " .. secondsLeft(Workspace:GetAttribute("WaveHitsAt")) .. "s - GET OFF THE STREET!"
		waveBanner.BackgroundColor3 = if os.clock() % 0.5 < 0.25 then rgb(232, 52, 70) else rgb(255, 150, 40)
	elseif waveState == "rolling" then
		waveBanner.Text = "POPCORN WAVE! GET OFF THE STREET!"
		waveBanner.BackgroundColor3 = rgb(232, 52, 70)
	else
		waveBanner.Text = "NEXT POPCORN WAVE IN " .. secondsLeft(Workspace:GetAttribute("NextWaveAt")) .. "s"
		waveBanner.BackgroundColor3 = DARK
	end
	local thief = Workspace:GetAttribute("ThiefTarget") or ""
	thiefBanner.Visible = thief ~= ""
	if thief ~= "" then
		thiefBanner.Text = if thief == player.Name then "SNEAKY CLOWN IS AFTER YOUR BOOTH! LOCK OR BONK!" else "SNEAKY CLOWN IS RAIDING " .. string.upper(thief) .. "!"
		thiefBanner.BackgroundColor3 = rgb(120, 30, 150)
	end
	panels.refresh(found, cash, rebirths)
end

local sinceRedraw = 0
RunService.RenderStepped:Connect(function(dt)
	sinceRedraw += dt
	if sinceRedraw >= 0.1 then
		sinceRedraw = 0
		redraw()
	end
	HudEffects.step(dt)
end)
