-- HudController: the player's screen. Shows the title strip, cash and money a second, the next
-- goal, the event banner, the Popcorn Wave countdown and alarm, BOUGHT/PLACED receipts, the
-- CARRYING bar and the LOCK / REBIRTH / INDEX / UPGRADES buttons. It reads Player and Workspace
-- attributes the server publishes and sends requests through Remotes.Action; it decides nothing.
--
-- Layout (fractions of the screen; the top-left corner is left free for Roblox's own buttons):
--   title strip      x .30-.70  y .010-.135     event banner  x .24-.76  y .145-.205
--   wave pill/alarm  x .22-.78  y .215-.275     toasts        x .25-.75  y .29-.42
--   cash + goal      x .012-.235 y .15-.47      receipts      x .012-.30 y .49-.62
--   buttons          x .80-.988 y .30-.74       carrying bar  x .27-.73  y .86-.93

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local HudPanels = require(script.Parent:WaitForChild("HudPanels"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local actionRemote = remotes:WaitForChild("Action") :: RemoteEvent
local notifyRemote = remotes:WaitForChild("Notify") :: RemoteEvent

local new, card = HudPanels.new, HudPanels.card
local WHITE = Color3.fromRGB(255, 255, 255)
local YELLOW = Color3.fromRGB(255, 226, 90)
local GREEN = Color3.fromRGB(110, 255, 130)
local RED = Color3.fromRGB(255, 70, 90)
local TONES = { good = GREEN, bad = RED, gold = YELLOW, info = Color3.fromRGB(150, 210, 255) }

local old = playerGui:FindFirstChild("RotCarnivalHud")
if old then
	old:Destroy()
end
local gui = new("ScreenGui", { Name = "RotCarnivalHud", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, playerGui)

local function requestAction(action: string, detail: string?)
	actionRemote:FireServer(action, detail)
end

-- Sound effects: Roblox's built-in sounds, pitched apart so each action has its own.
local SOUNDS = {
	buy = { "rbxasset://sounds/action_jump.mp3", 1.5, 0.9 },
	place = { "rbxasset://sounds/action_jump_land.mp3", 1.1, 1 },
	sell = { "rbxasset://sounds/action_get_up.mp3", 1.6, 0.8 },
	stolen = { "rbxasset://sounds/ouch.ogg", 0.8, 1 },
	blocked = { "rbxasset://sounds/action_jump_land.mp3", 0.6, 1 },
	bonk = { "rbxasset://sounds/oof.ogg", 1.4, 1 },
	rebirth = { "rbxasset://sounds/impact_explosion_03.mp3", 1.2, 0.8 },
	upgrade = { "rbxasset://sounds/action_get_up.mp3", 1.1, 0.9 },
	lock = { "rbxasset://sounds/volume_slider.ogg", 0.7, 1 },
	wave = { "rbxasset://sounds/impact_water.mp3", 0.7, 1 },
	alarm = { "rbxasset://sounds/action_falling.ogg", 1.3, 0.8 },
	event = { "rbxasset://sounds/action_swim.mp3", 1.3, 0.8 },
	discover = { "rbxasset://sounds/action_jump.mp3", 2, 0.9 },
	error = { "rbxasset://sounds/volume_slider.ogg", 1.4, 0.6 },
}
local soundFolder = new("Folder", { Name = "Sounds" }, gui)
local function playSound(key: string)
	local spec = SOUNDS[key]
	if spec then
		local sound = new("Sound", { SoundId = spec[1], PlaybackSpeed = spec[2], Volume = spec[3] }, soundFolder)
		SoundService:PlayLocalSound(sound)
		task.delay(4, sound.Destroy, sound)
	end
end

-- Title strip: the game's name and what is in it, readable in a thumbnail.
local title = new("Frame", { Name = "TitleStrip", BackgroundTransparency = 1, Position = UDim2.fromScale(0.3, 0.01), Size = UDim2.fromScale(0.4, 0.125) }, gui)
local logo = new("TextLabel", { Name = "Logo", Text = GameConfig.TITLE, TextColor3 = YELLOW, Size = UDim2.fromScale(1, 0.72), Font = Enum.Font.LuckiestGuy }, title)
new("UIStroke", { Color = Color3.fromRGB(200, 30, 70), Thickness = 4 }, logo)
local tagline = card(title, "Tagline", UDim2.fromScale(-0.2, 0.74), UDim2.fromScale(1.4, 0.26), Color3.fromRGB(255, 150, 200))
new("TextLabel", { Text = string.format("%s  -  %d BRAINROTS  -  %d RARITIES  -  %d MUTATIONS  -  WAVE, THIEVES, LOCK, REBIRTH", GameConfig.SUBTITLE, BrainrotCatalog.COUNT, #GameConfig.RARITIES, #GameConfig.MUTATIONS), TextColor3 = WHITE, Position = UDim2.fromScale(0.02, 0.08), Size = UDim2.fromScale(0.96, 0.84) }, tagline)

-- Event banner and Popcorn Wave pill.
local eventBanner = card(gui, "EventBanner", UDim2.fromScale(0.24, 0.145), UDim2.fromScale(0.52, 0.06), YELLOW)
eventBanner.Visible = false
local eventText = new("TextLabel", { Name = "Text", Text = "", TextColor3 = YELLOW, Position = UDim2.fromScale(0.02, 0.08), Size = UDim2.fromScale(0.96, 0.84) }, eventBanner)
local wavePill = card(gui, "WavePill", UDim2.fromScale(0.36, 0.215), UDim2.fromScale(0.28, 0.05), Color3.fromRGB(255, 214, 110))
local waveText = new("TextLabel", { Name = "Text", Text = "POPCORN WAVE IN 1:15", TextColor3 = Color3.fromRGB(255, 240, 200), Position = UDim2.fromScale(0.03, 0.1), Size = UDim2.fromScale(0.94, 0.8) }, wavePill)

-- Cash card: money, money a second, rebirth multiplier.
local cashCard = card(gui, "CashCard", UDim2.fromScale(0.012, 0.15), UDim2.fromScale(0.223, 0.175), YELLOW)
local cashText = new("TextLabel", { Name = "Cash", Text = "$0", TextColor3 = YELLOW, Position = UDim2.fromScale(0.05, 0.03), Size = UDim2.fromScale(0.9, 0.5), TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.LuckiestGuy }, cashCard)
local cashScale = new("UIScale", {}, cashText)
local incomeText = new("TextLabel", { Name = "Income", Text = "+$0/s", TextColor3 = GREEN, Position = UDim2.fromScale(0.05, 0.52), Size = UDim2.fromScale(0.9, 0.26), TextXAlignment = Enum.TextXAlignment.Left }, cashCard)
local rebirthText = new("TextLabel", { Name = "Rebirth", Text = "REBIRTH 0  x1 INCOME", TextColor3 = WHITE, Position = UDim2.fromScale(0.05, 0.78), Size = UDim2.fromScale(0.9, 0.18), TextXAlignment = Enum.TextXAlignment.Left }, cashCard)

-- Goal card: what to buy next and how close the player is.
local goalCard = card(gui, "GoalCard", UDim2.fromScale(0.012, 0.34), UDim2.fromScale(0.223, 0.13), Color3.fromRGB(110, 200, 255))
local goalHead = new("TextLabel", { Name = "Head", Text = "NEXT GOAL", TextColor3 = Color3.fromRGB(150, 220, 255), Position = UDim2.fromScale(0.05, 0.05), Size = UDim2.fromScale(0.9, 0.24), TextXAlignment = Enum.TextXAlignment.Left }, goalCard)
local goalText = new("TextLabel", { Name = "Goal", Text = "", TextColor3 = WHITE, Position = UDim2.fromScale(0.05, 0.3), Size = UDim2.fromScale(0.9, 0.36), TextXAlignment = Enum.TextXAlignment.Left }, goalCard)
local goalBar = new("Frame", { Name = "Bar", BackgroundColor3 = Color3.fromRGB(50, 44, 76), BorderSizePixel = 0, Position = UDim2.fromScale(0.05, 0.74), Size = UDim2.fromScale(0.9, 0.16) }, goalCard)
new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, goalBar)
local goalFill = new("Frame", { Name = "Fill", BackgroundColor3 = GREEN, BorderSizePixel = 0, Size = UDim2.fromScale(0, 1) }, goalBar)
new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, goalFill)

-- Receipts: the last purchase and the last placement stay on screen for a while.
local receipts = {}
for line = 1, 2 do
	local receipt = card(gui, "Receipt" .. line, UDim2.fromScale(0.012, 0.49 + (line - 1) * 0.068), UDim2.fromScale(0.3, 0.058), if line == 1 then YELLOW else GREEN)
	receipt.Visible = false
	local text = new("TextLabel", { Name = "Text", Text = "", TextColor3 = if line == 1 then YELLOW else GREEN, Position = UDim2.fromScale(0.03, 0.1), Size = UDim2.fromScale(0.94, 0.8), TextXAlignment = Enum.TextXAlignment.Left }, receipt)
	receipts[line] = { frame = receipt, text = text, stamp = 0 }
end

-- Carrying bar.
local carryBar = card(gui, "CarryBar", UDim2.fromScale(0.27, 0.86), UDim2.fromScale(0.46, 0.07), Color3.fromRGB(255, 150, 200))
carryBar.Visible = false
local carryText = new("TextLabel", { Name = "Text", Text = "", TextColor3 = WHITE, Position = UDim2.fromScale(0.02, 0.1), Size = UDim2.fromScale(0.96, 0.8) }, carryBar)

-- Panels and the four big buttons that open them.
local indexPanel = HudPanels.buildIndexPanel(gui)
local rebirthPanel = HudPanels.buildRebirthPanel(gui, requestAction)
local upgradesPanel = HudPanels.buildUpgradesPanel(gui, requestAction)
local panels = { Index = indexPanel, Rebirth = rebirthPanel, Upgrades = upgradesPanel }

local function togglePanel(name: string)
	local panel = panels[name]
	local show = not panel.Visible
	if name == "Rebirth" then
		upgradesPanel.Visible = false
	elseif name == "Upgrades" then
		rebirthPanel.Visible = false
	end
	panel.Visible = show
	playSound("lock")
end

local buttonSubtexts = {}
local function bigButton(order: number, name: string, color: Color3, onClick: () -> ())
	local button = new("TextButton", { Name = name .. "Button", Text = "", BackgroundColor3 = color, BackgroundTransparency = 0, AutoButtonColor = true, Position = UDim2.fromScale(0.8, 0.3 + (order - 1) * 0.112), Size = UDim2.fromScale(0.188, 0.1) }, gui)
	new("UICorner", { CornerRadius = UDim.new(0.2, 0) }, button)
	new("UIStroke", { Color = WHITE, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, button)
	local head = new("TextLabel", { Text = string.upper(name), TextColor3 = WHITE, Position = UDim2.fromScale(0.04, 0.04), Size = UDim2.fromScale(0.92, 0.56), Font = Enum.Font.LuckiestGuy }, button)
	new("UIStroke", { Color = Color3.fromRGB(30, 24, 44), Thickness = 2.5 }, head)
	buttonSubtexts[name] = new("TextLabel", { Text = "", TextColor3 = Color3.fromRGB(255, 250, 220), Position = UDim2.fromScale(0.04, 0.6), Size = UDim2.fromScale(0.92, 0.34) }, button)
	button.Activated:Connect(onClick)
	return button
end
bigButton(1, "Lock", Color3.fromRGB(232, 50, 70), function()
	requestAction("lock")
end)
bigButton(2, "Rebirth", Color3.fromRGB(160, 90, 240), function()
	togglePanel("Rebirth")
end)
bigButton(3, "Index", Color3.fromRGB(50, 150, 250), function()
	togglePanel("Index")
end)
bigButton(4, "Upgrades", Color3.fromRGB(250, 140, 40), function()
	togglePanel("Upgrades")
end)

-- Toasts: short messages from the server, stacked under the wave pill.
local toastArea = new("Frame", { Name = "Toasts", BackgroundTransparency = 1, Position = UDim2.fromScale(0.25, 0.29), Size = UDim2.fromScale(0.5, 0.13) }, gui)
new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0.06, 0), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }, toastArea)
local toastCount = 0
local function showToast(text: string, tone: string?)
	toastCount += 1
	local color = TONES[tone or "info"] or WHITE
	local toast = card(toastArea, "Toast", UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.44), color)
	toast.LayoutOrder = -toastCount
	new("TextLabel", { Text = text, TextColor3 = color, Position = UDim2.fromScale(0.02, 0.1), Size = UDim2.fromScale(0.96, 0.8) }, toast)
	local live = 0
	for _, child in toastArea:GetChildren() do
		if child:IsA("Frame") then
			live += 1
		end
	end
	if live > 2 then
		local oldest, oldestOrder = nil, -math.huge
		for _, child in toastArea:GetChildren() do
			if child:IsA("Frame") and child.LayoutOrder > oldestOrder then
				oldest, oldestOrder = child, child.LayoutOrder
			end
		end
		if oldest then
			oldest:Destroy()
		end
	end
	task.delay(4.5, function()
		if toast.Parent then
			toast:Destroy()
		end
	end)
end

-- Big-moment feedback: a screen flash, a burst of confetti and a bounce of the cash counter.
local flash = new("Frame", { Name = "Flash", BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 50, Active = false }, gui)
local function flashScreen(color: Color3, strength: number)
	flash.BackgroundColor3 = color
	flash.BackgroundTransparency = 1 - strength
	TweenService:Create(flash, TweenInfo.new(0.7), { BackgroundTransparency = 1 }):Play()
end

local function burstConfetti(amount: number, color: Color3?)
	for _ = 1, amount do
		local bit = new("Frame", { BackgroundColor3 = color or Color3.fromHSV(math.random(), 0.8, 1), BorderSizePixel = 0, Rotation = math.random(0, 90), Position = UDim2.fromScale(0.5 + (math.random() - 0.5) * 0.2, 0.45), Size = UDim2.fromScale(0.012, 0.02), ZIndex = 45 }, gui)
		local goal = { Position = UDim2.fromScale(math.random(), 0.2 + math.random() * 0.9), Rotation = math.random(-360, 360), BackgroundTransparency = 1 }
		TweenService:Create(bit, TweenInfo.new(1.1 + math.random() * 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
		task.delay(1.8, bit.Destroy, bit)
	end
end

local function bounceCash()
	cashScale.Scale = 1.18
	TweenService:Create(cashScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

local function floatGain(amount: number)
	local gain = new("TextLabel", { Text = "+$" .. GameConfig.formatCash(amount), TextColor3 = GREEN, Position = UDim2.fromScale(0.15, 0.2), Size = UDim2.fromScale(0.09, 0.035), ZIndex = 30 }, gui)
	TweenService:Create(gain, TweenInfo.new(0.9), { Position = UDim2.fromScale(0.17, 0.12), TextTransparency = 1 }):Play()
	task.delay(1, gain.Destroy, gain)
end

local function shakeCamera(seconds: number)
	local camera = workspace.CurrentCamera
	local untilTime = os.clock() + seconds
	task.spawn(function()
		while os.clock() < untilTime do
			camera.CFrame *= CFrame.new((math.random() - 0.5) * 0.5, (math.random() - 0.5) * 0.5, 0)
			RunService.RenderStepped:Wait()
		end
	end)
end

local EFFECTS = {
	buy = function()
		burstConfetti(14)
		bounceCash()
	end,
	place = function()
		burstConfetti(20, GREEN)
		flashScreen(GREEN, 0.12)
	end,
	rebirth = function()
		burstConfetti(70)
		flashScreen(Color3.fromRGB(200, 130, 255), 0.6)
		shakeCamera(0.5)
	end,
	discover = function()
		burstConfetti(30, YELLOW)
	end,
	stolen = function()
		flashScreen(RED, 0.35)
		shakeCamera(0.3)
	end,
	bonk = function()
		burstConfetti(40, YELLOW)
		flashScreen(YELLOW, 0.25)
		bounceCash()
	end,
	wave = function()
		flashScreen(Color3.fromRGB(255, 226, 140), 0.3)
		shakeCamera(0.8)
	end,
	event = function()
		burstConfetti(40)
	end,
	upgrade = function()
		burstConfetti(24, Color3.fromRGB(255, 160, 60))
	end,
	blocked = function()
		flashScreen(RED, 0.2)
	end,
	lock = function()
		flashScreen(RED, 0.12)
	end,
}

notifyRemote.OnClientEvent:Connect(function(kind: string, payload)
	if kind == "toast" then
		showToast(payload.text, payload.tone)
	elseif kind == "receipt" then
		local receipt = receipts[payload.line]
		receipt.text.Text = payload.text
		receipt.frame.Visible = true
		receipt.stamp = os.clock()
	elseif kind == "panel" then
		for name, panel in panels do
			panel.Visible = table.find(payload.open, name) ~= nil
		end
	elseif kind == "camera" then
		-- TourDirector frames its showcase scenes; an empty payload hands the camera back.
		local camera = workspace.CurrentCamera
		camera.CameraType = if payload.from then Enum.CameraType.Scriptable else Enum.CameraType.Custom
		if payload.from then
			camera.CFrame = CFrame.lookAt(payload.from, payload.to)
		end
	end
	if payload.fx then
		playSound(payload.fx)
		local effect = EFFECTS[payload.fx]
		if effect then
			effect()
		end
	end
end)

-- Attribute-driven readouts.
local shownCash = 0
local function discoveredSet(): { [string]: boolean }
	local index = (player:GetAttribute("Index") or "") :: string
	local set = {}
	for order, entry in BrainrotCatalog.LIST do
		if string.sub(index, order, order) == "1" then
			set[entry.id] = true
		end
	end
	return set
end

local function refreshGoal()
	local cash = (player:GetAttribute("Cash") or 0) :: number
	local owned = (player:GetAttribute("Owned") or 0) :: number
	local carrying = (player:GetAttribute("Carrying") or "") :: string
	local goal = BrainrotCatalog.nextUndiscovered(discoveredSet())
	if carrying ~= "" then
		goalHead.Text = "NOW"
		goalText.Text = "RUN IT TO YOUR BOOTH!"
		goalFill.Size = UDim2.fromScale(1, 1)
	elseif owned == 0 and cash >= 25 then
		goalHead.Text = "FIRST STEP"
		goalText.Text = "BUY A BRAINROT OFF THE BELT"
		goalFill.Size = UDim2.fromScale(1, 1)
	elseif goal then
		goalHead.Text = "NEXT GOAL  " .. (player:GetAttribute("Found") or 0) .. "/" .. BrainrotCatalog.COUNT
		goalText.Text = string.upper(goal.name) .. "  $" .. GameConfig.formatCash(goal.price)
		goalFill.Size = UDim2.fromScale(math.clamp(cash / goal.price, 0, 1), 1)
	else
		goalHead.Text = "INDEX COMPLETE"
		goalText.Text = "REBIRTH FOR MORE INCOME"
		goalFill.Size = UDim2.fromScale(1, 1)
	end
end

local function refreshStats()
	local rebirths = (player:GetAttribute("Rebirths") or 0) :: number
	incomeText.Text = "+$" .. GameConfig.formatCash((player:GetAttribute("Income") or 0) :: number) .. "/s"
	rebirthText.Text = "REBIRTH " .. rebirths .. "  x" .. GameConfig.rebirthMultiplier(rebirths) .. " INCOME"
	buttonSubtexts.Rebirth.Text = "$" .. GameConfig.formatCash(GameConfig.rebirthCost(rebirths))
	buttonSubtexts.Index.Text = (player:GetAttribute("Found") or 0) .. "/" .. BrainrotCatalog.COUNT .. " found"
	buttonSubtexts.Upgrades.Text = (player:GetAttribute("Owned") or 0) .. "/" .. (player:GetAttribute("Capacity") or 8) .. " pedestals"
	local carrying = (player:GetAttribute("Carrying") or "") :: string
	carryBar.Visible = carrying ~= ""
	carryText.Text = "CARRYING " .. string.upper(carrying) .. "  -  RUN TO YOUR BOOTH!"
	refreshGoal()
end

local lastCash = (player:GetAttribute("Cash") or 0) :: number
player:GetAttributeChangedSignal("Cash"):Connect(function()
	local cash = (player:GetAttribute("Cash") or 0) :: number
	local income = (player:GetAttribute("Income") or 0) :: number
	if cash > lastCash and income > 0 and cash - lastCash == income then
		floatGain(income)
	end
	lastCash = cash
	refreshGoal()
end)
for _, attribute in { "Income", "Rebirths", "Index", "Found", "Owned", "Capacity", "Carrying" } do
	player:GetAttributeChangedSignal(attribute):Connect(refreshStats)
end
refreshStats()

local function clock(seconds: number): string
	local whole = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", whole // 60, whole % 60)
end

-- Per-frame: count the cash up smoothly and keep every countdown current.
local waveAlarm = false
RunService.RenderStepped:Connect(function(dt: number)
	local cash = (player:GetAttribute("Cash") or 0) :: number
	shownCash += (cash - shownCash) * math.min(1, dt * 8)
	if math.abs(cash - shownCash) < 1 then
		shownCash = cash
	end
	cashText.Text = "$" .. GameConfig.formatCash(shownCash)

	local now = workspace:GetServerTimeNow()
	local eventKey = (workspace:GetAttribute("EventKey") or "") :: string
	local event = GameConfig.EVENTS[eventKey]
	eventBanner.Visible = event ~= nil
	if event then
		eventText.Text = event.banner .. "  -  " .. math.max(0, math.ceil(((workspace:GetAttribute("EventEndsAt") or 0) :: number) - now)) .. "s"
		eventText.TextColor3 = event.color;
		(eventBanner:FindFirstChildOfClass("UIStroke") :: UIStroke).Color = event.color
	end

	local waveIn = ((workspace:GetAttribute("WaveAt") or now + 60) :: number) - now
	local alarm = workspace:GetAttribute("WaveActive") == true or waveIn <= GameConfig.WAVE.warn
	if alarm ~= waveAlarm then
		waveAlarm = alarm
		wavePill.Position = if alarm then UDim2.fromScale(0.22, 0.215) else UDim2.fromScale(0.36, 0.215)
		wavePill.Size = if alarm then UDim2.fromScale(0.56, 0.062) else UDim2.fromScale(0.28, 0.05)
		wavePill.BackgroundColor3 = if alarm then Color3.fromRGB(200, 30, 50) else Color3.fromRGB(22, 18, 34)
		if alarm then
			playSound("alarm")
		end
	end
	if workspace:GetAttribute("WaveActive") == true then
		waveText.Text = "POPCORN WAVE! GET OFF THE MIDWAY!"
		waveText.TextColor3 = WHITE
	elseif alarm then
		waveText.Text = "POPCORN WAVE IN " .. math.max(1, math.ceil(waveIn)) .. "! RUN TO YOUR BOOTH!"
		waveText.TextColor3 = WHITE
	else
		waveText.Text = "POPCORN WAVE IN " .. clock(waveIn)
		waveText.TextColor3 = Color3.fromRGB(255, 240, 200)
	end

	local lockUntil = (player:GetAttribute("LockUntil") or 0) :: number
	local lockReadyAt = (player:GetAttribute("LockReadyAt") or 0) :: number
	if now < lockUntil then
		buttonSubtexts.Lock.Text = "LOCKED " .. clock(lockUntil - now)
	elseif now < lockReadyAt then
		buttonSubtexts.Lock.Text = "recharging " .. math.ceil(lockReadyAt - now) .. "s"
	else
		buttonSubtexts.Lock.Text = "gate open - tap to lock"
	end

	for _, receipt in receipts do
		if receipt.frame.Visible and os.clock() - receipt.stamp > 12 then
			receipt.frame.Visible = false
		end
	end
end)
