-- HudController: draws the HUD over the 3D carnival and keeps it in step with the server.
-- Top: logo, event band, popcorn-wave band. Left: money, money a second, next goal. Bottom: LOCK, REBIRTH,
-- INDEX, UPGRADES, the CARRYING bar and the BOUGHT / PLACED receipts. The middle of the screen stays clear.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local HudEffects = require(script.Parent:WaitForChild("HudEffects"))
local HudPanels = require(script.Parent:WaitForChild("HudPanels"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local playerAction = remotes:WaitForChild("PlayerAction")
local notice = remotes:WaitForChild("Notice")

local INK = Color3.fromRGB(26, 18, 44)
local GOLD = Color3.fromRGB(255, 205, 60)
local WHITE = Color3.new(1, 1, 1)
local GREEN = Color3.fromRGB(110, 255, 140)

local old = playerGui:FindFirstChild("CarnivalHud")
if old then
	old:Destroy()
end
local screen = Instance.new("ScreenGui")
screen.Name = "CarnivalHud"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui
HudEffects.init(screen)

local function sendAction(action: string, argument: any?)
	playerAction:FireServer(action, argument)
end

local function round(parent: Instance, radius: number, strokeColor: Color3?, thickness: number?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(radius, 0)
	corner.Parent = parent
	if strokeColor then
		local stroke = Instance.new("UIStroke")
		stroke.Color = strokeColor
		stroke.Thickness = thickness or 3
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = parent
	end
end

local function label(parent: Instance, content: string, position: UDim2, size: UDim2, color: Color3?): TextLabel
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Position = position
	text.Size = size
	text.Font = Enum.Font.FredokaOne
	text.Text = content
	text.TextColor3 = color or WHITE
	text.TextScaled = true
	text.TextStrokeColor3 = INK
	text.TextStrokeTransparency = 0.2
	text.Parent = parent
	return text
end

local function card(position: UDim2, size: UDim2, strokeColor: Color3, anchorX: number?): Frame
	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(anchorX or 0, 0)
	frame.Position = position
	frame.Size = size
	frame.BackgroundColor3 = INK
	frame.BackgroundTransparency = 0.12
	frame.Parent = screen
	round(frame, 0.2, strokeColor)
	return frame
end

-- Top centre: the logo and what the game holds, in one line.
local logo = label(screen, GameConfig.TITLE, UDim2.fromScale(0.36, 0.008), UDim2.fromScale(0.28, 0.07), GOLD)
logo.TextStrokeColor3 = Color3.fromRGB(150, 30, 60)
logo.TextStrokeTransparency = 0
local pitch = card(UDim2.fromScale(0.5, 0.078), UDim2.fromScale(0.64, 0.04), Color3.fromRGB(255, 120, 200), 0.5)
label(pitch, string.format("%s   %d BRAINROTS   7 RARITIES   5 MUTATIONS   WAVE   THIEVES   LOCK   REBIRTH", GameConfig.SUBTITLE, BrainrotCatalog.count()), UDim2.fromScale(0.02, 0.1), UDim2.fromScale(0.96, 0.8))

local eventBand = card(UDim2.fromScale(0.5, 0.126), UDim2.fromScale(0.34, 0.042), GOLD, 0.5)
eventBand.Visible = false
local eventText = label(eventBand, "", UDim2.fromScale(0.03, 0.08), UDim2.fromScale(0.94, 0.84))

local waveBand = card(UDim2.fromScale(0.5, 0.176), UDim2.fromScale(0.3, 0.036), Color3.fromRGB(255, 232, 110), 0.5)
local waveText = label(waveBand, "", UDim2.fromScale(0.03, 0.08), UDim2.fromScale(0.94, 0.84), Color3.fromRGB(255, 240, 150))

-- Left: money and money a second, then the next goal with a progress bar.
local moneyCard = card(UDim2.fromScale(0.012, 0.125), UDim2.fromScale(0.185, 0.1), GREEN)
local moneyText = label(moneyCard, "$0", UDim2.fromScale(0.05, 0.04), UDim2.fromScale(0.9, 0.54), GOLD)
moneyText.TextXAlignment = Enum.TextXAlignment.Left
local incomeText = label(moneyCard, "+$0/s", UDim2.fromScale(0.05, 0.58), UDim2.fromScale(0.52, 0.36), GREEN)
incomeText.TextXAlignment = Enum.TextXAlignment.Left
local rebirthText = label(moneyCard, "", UDim2.fromScale(0.58, 0.6), UDim2.fromScale(0.38, 0.32), Color3.fromRGB(210, 150, 255))
rebirthText.TextXAlignment = Enum.TextXAlignment.Right

local goalCard = card(UDim2.fromScale(0.012, 0.235), UDim2.fromScale(0.185, 0.075), Color3.fromRGB(80, 170, 255))
local goalText = label(goalCard, "", UDim2.fromScale(0.05, 0.06), UDim2.fromScale(0.9, 0.42))
goalText.TextXAlignment = Enum.TextXAlignment.Left
local goalBar = Instance.new("Frame")
goalBar.Position = UDim2.fromScale(0.05, 0.56)
goalBar.Size = UDim2.fromScale(0.9, 0.32)
goalBar.BackgroundColor3 = Color3.fromRGB(60, 46, 96)
goalBar.Parent = goalCard
round(goalBar, 0.5)
local goalFill = Instance.new("Frame")
goalFill.Size = UDim2.fromScale(0, 1)
goalFill.BackgroundColor3 = Color3.fromRGB(80, 170, 255)
goalFill.Parent = goalBar
round(goalFill, 0.5)
local goalProgress = label(goalBar, "", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1))
goalProgress.ZIndex = 2

-- Bottom centre: the four big buttons.
local BUTTONS = {
	{ key = "lock", text = "LOCK", color = Color3.fromRGB(235, 50, 70) },
	{ key = "rebirth", text = "REBIRTH", color = Color3.fromRGB(170, 80, 255) },
	{ key = "index", text = "INDEX", color = Color3.fromRGB(50, 140, 255) },
	{ key = "upgrades", text = "UPGRADES", color = Color3.fromRGB(50, 180, 90) },
}
local buttons = {}
for index, spec in BUTTONS do
	local button = Instance.new("TextButton")
	button.Position = UDim2.fromScale(0.262 + (index - 1) * 0.121, 0.885)
	button.Size = UDim2.fromScale(0.113, 0.085)
	button.BackgroundColor3 = spec.color
	button.Font = Enum.Font.FredokaOne
	button.Text = spec.text
	button.TextColor3 = WHITE
	button.TextScaled = true
	button.TextStrokeColor3 = INK
	button.TextStrokeTransparency = 0.3
	button.Parent = screen
	round(button, 0.22, WHITE, 3)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0.16, 0)
	padding.PaddingBottom = UDim.new(0.16, 0)
	padding.PaddingLeft = UDim.new(0.06, 0)
	padding.PaddingRight = UDim.new(0.06, 0)
	padding.Parent = button
	buttons[spec.key] = button
	button.Activated:Connect(function()
		HudEffects.bounce(button)
		if spec.key == "lock" then
			sendAction("lock")
		else
			HudPanels.toggle(spec.key)
		end
	end)
end

local carryBand = card(UDim2.fromScale(0.5, 0.818), UDim2.fromScale(0.42, 0.048), Color3.fromRGB(255, 150, 60), 0.5)
carryBand.Visible = false
local carryText = label(carryBand, "", UDim2.fromScale(0.02, 0.1), UDim2.fromScale(0.96, 0.8))

-- Bottom left: the last thing bought and the last thing placed.
local boughtCard = card(UDim2.fromScale(0.012, 0.86), UDim2.fromScale(0.235, 0.048), Color3.fromRGB(255, 224, 90))
local boughtText = label(boughtCard, "BUY A BRAINROT FROM THE PRIZE BELT", UDim2.fromScale(0.03, 0.12), UDim2.fromScale(0.94, 0.76), Color3.fromRGB(255, 224, 90))
local placedCard = card(UDim2.fromScale(0.012, 0.918), UDim2.fromScale(0.235, 0.048), GREEN)
local placedText = label(placedCard, "CARRY IT TO YOUR BOOTH TO EARN $/s", UDim2.fromScale(0.03, 0.12), UDim2.fromScale(0.94, 0.76), GREEN)

HudPanels.buildPanels(screen, player, sendAction)

local shownMoney = 0
local function refreshHud()
	local money = player:GetAttribute("Money") or 0
	local income = player:GetAttribute("Income") or 0
	local rebirths = player:GetAttribute("Rebirths") or 0
	incomeText.Text = "+" .. GameConfig.formatMoney(income) .. "/s"
	rebirthText.Text = string.format("REBIRTH %d  x%.1f", rebirths, GameConfig.rebirthIncomeMultiplier(rebirths))
	local found = {}
	for id in string.gmatch(player:GetAttribute("Index") or "", "[^,]+") do
		found[id] = true
	end
	local goal = BrainrotCatalog.nextGoal(money, found)
	local target = goal and goal.price or GameConfig.rebirthCost(rebirths)
	goalText.Text = goal and ("NEXT: " .. goal.name) or "NEXT: REBIRTH"
	goalFill.Size = UDim2.fromScale(math.clamp(money / target, 0, 1), 1)
	goalProgress.Text = GameConfig.formatMoney(money) .. " / " .. GameConfig.formatMoney(target)
	local carrying = player:GetAttribute("Carrying") or ""
	carryBand.Visible = carrying ~= ""
	carryText.Text = "CARRYING: " .. carrying .. "  ->  RUN TO YOUR BOOTH!"
	HudPanels.refresh()
end

for _, attribute in { "Money", "Income", "Rebirths", "Index", "Carrying", "UpPedestals", "UpSpeed", "UpLock" } do
	player:GetAttributeChangedSignal(attribute):Connect(refreshHud)
end
refreshHud()

-- Count the money up smoothly, and tick the bands' timers.
RunService.RenderStepped:Connect(function(deltaTime)
	local money = player:GetAttribute("Money") or 0
	shownMoney += (money - shownMoney) * math.min(1, deltaTime * 8)
	if math.abs(money - shownMoney) < 1 then
		shownMoney = money
	end
	moneyText.Text = GameConfig.formatMoney(shownMoney)
	local now = Workspace:GetServerTimeNow()
	local eventKey = Workspace:GetAttribute("EventKey") or ""
	local event = GameConfig.EVENTS[eventKey]
	eventBand.Visible = event ~= nil
	if event then
		eventText.Text = string.format("%s  %ds", event.title, math.max(0, math.ceil((Workspace:GetAttribute("EventEnds") or 0) - now)))
		eventText.TextColor3 = event.color
	end
	local waveIn = (Workspace:GetAttribute("WaveAt") or 0) - now
	if Workspace:GetAttribute("WaveActive") then
		waveText.Text = "POPCORN WAVE! GET OFF THE STREET!"
		waveText.TextColor3 = Color3.fromRGB(255, 90, 90)
	elseif waveIn > 0 and waveIn <= GameConfig.WAVE.warning then
		waveText.Text = string.format("WAVE IN %ds! RUN TO YOUR BOOTH!", math.ceil(waveIn))
		waveText.TextColor3 = (math.floor(now * 4) % 2 == 0) and Color3.fromRGB(255, 90, 90) or WHITE
	else
		waveText.Text = string.format("NEXT POPCORN WAVE IN %ds", math.max(0, math.ceil(waveIn)))
		waveText.TextColor3 = Color3.fromRGB(255, 240, 150)
	end
	local lockLeft = (player:GetAttribute("LockUntil") or 0) - now
	local lockReady = (player:GetAttribute("LockReadyAt") or 0) - now
	if lockLeft > 0 then
		buttons.lock.Text = lockLeft > 99 and "LOCKED" or string.format("LOCKED %ds", math.ceil(lockLeft))
		buttons.lock.BackgroundColor3 = Color3.fromRGB(255, 90, 40)
	elseif lockReady > 0 then
		buttons.lock.Text = string.format("LOCK %ds", math.ceil(lockReady))
		buttons.lock.BackgroundColor3 = Color3.fromRGB(110, 90, 100)
	else
		buttons.lock.Text = "LOCK"
		buttons.lock.BackgroundColor3 = Color3.fromRGB(235, 50, 70)
	end
end)

local function receipt(text: TextLabel, frame: Frame, content: string)
	text.Text = content
	HudEffects.bounce(frame)
end

-- What the server tells this player, and how the HUD answers each.
local NOTICES = {}

function NOTICES.bought(data)
	receipt(boughtText, boughtCard, string.format("BOUGHT %s  -%s", data.name, GameConfig.formatMoney(data.price)))
	HudEffects.playSound("buy")
	HudEffects.popNumber("-" .. GameConfig.formatMoney(data.price), UDim2.fromScale(0.2, 0.17), Color3.fromRGB(255, 120, 120))
end

function NOTICES.placed(data)
	receipt(placedText, placedCard, string.format("PLACED %s  +%s/s", data.name, GameConfig.formatMoney(data.income)))
	HudEffects.playSound("place")
	HudEffects.bounce(moneyCard)
	HudEffects.popNumber("+" .. GameConfig.formatMoney(data.income) .. "/s", UDim2.fromScale(0.2, 0.2), GREEN)
	if data.mutation or BrainrotCatalog.rarityOf({ rarity = data.rarity }).order >= 5 then
		HudEffects.confetti(40)
		HudEffects.toast(string.upper(data.rarity) .. (data.mutation and (" " .. string.upper(data.mutation)) or "") .. " ON YOUR PEDESTAL!", "purple")
	end
end

function NOTICES.sold(data)
	HudEffects.playSound("sell")
	HudEffects.toast("SOLD " .. data.name .. "  +" .. GameConfig.formatMoney(data.refund), "gold")
end

function NOTICES.dropped(data)
	HudEffects.toast("THE WAVE TOOK YOUR " .. string.upper(data.name) .. "!", "red", 3.5)
end

function NOTICES.toast(data)
	HudEffects.toast(data.text, data.color)
	if data.color == "red" then
		HudEffects.playSound("error")
	end
end

function NOTICES.upgraded(data)
	HudEffects.playSound("buy")
	HudEffects.confetti(25)
	HudEffects.toast(data.title .. "  LEVEL " .. data.level, "green")
end

function NOTICES.rebirth(data)
	HudPanels.closeAll()
	HudEffects.playSound("rebirth")
	HudEffects.flash(Color3.fromRGB(190, 110, 255))
	HudEffects.confetti(120)
	HudEffects.bounce(moneyCard)
	HudEffects.toast(string.format("REBIRTH %d!  INCOME x%.1f FOREVER", data.rebirths, data.multiplier), "purple", 5)
end

function NOTICES.event(data)
	HudEffects.playSound("event")
	HudEffects.bounce(eventBand)
	HudEffects.confetti(30)
end

function NOTICES.waveStart()
	HudEffects.playSound("wave")
	HudEffects.bounce(waveBand)
end

function NOTICES.waveHit(data)
	HudEffects.flash(Color3.fromRGB(255, 236, 150))
	HudEffects.shakeCamera(0.6, 0.6)
	HudEffects.playSound("bonk")
	if not data.dropped then
		HudEffects.toast("POPCORNED! STAY OFF THE STREET DURING A WAVE", "red")
	end
end

function NOTICES.thief()
	HudEffects.playSound("alarm")
	HudEffects.toast("SNEAKY CLOWN IS COMING! LOCK YOUR GATE!", "red", 4)
	HudEffects.bounce(buttons.lock)
end

function NOTICES.blocked()
	HudEffects.playSound("blocked")
	HudEffects.toast("BLOCKED BY LOCK! THE CLOWN GOT NOTHING", "green", 3.5)
end

function NOTICES.stealing(data)
	HudEffects.playSound("alarm")
	HudEffects.toast("HE HAS YOUR " .. string.upper(data.name) .. "! RUN INTO HIM TO BONK!", "red", 5)
end

function NOTICES.stolen(data)
	HudEffects.playSound("stolen")
	HudEffects.flash(Color3.fromRGB(235, 50, 70))
	HudEffects.toast(string.upper(data.name) .. " WAS STOLEN!", "red", 4)
end

function NOTICES.bonk(data)
	HudEffects.playSound("bonk")
	HudEffects.confetti(40)
	HudEffects.toast("BONK! CLOWN CAUGHT  +" .. GameConfig.formatMoney(data.reward), "green", 3.5)
end

function NOTICES.locked(data)
	HudEffects.playSound("lock")
	HudEffects.toast(string.format("GATE LOCKED FOR %ds", data.seconds), "green")
end

function NOTICES.unlocked()
	HudEffects.toast("GATE UNLOCKED - LOCK RECHARGING", "gold")
end

function NOTICES.cannon()
	HudEffects.playSound("cannon")
end

-- The tour points the camera at a staged scene; an empty notice hands it back.
function NOTICES.camera(data)
	local camera = Workspace.CurrentCamera
	if data and data.from and data.to then
		camera.CameraType = Enum.CameraType.Scriptable
		camera.FieldOfView = 62
		camera.CFrame = CFrame.lookAt(data.from, data.to)
	else
		camera.CameraType = Enum.CameraType.Custom
		camera.FieldOfView = 70
	end
end

function NOTICES.panel(data)
	if data.close then
		HudPanels.closeAll()
	end
	for _, name in data.open or {} do
		HudPanels.open(name)
	end
end

notice.OnClientEvent:Connect(function(kind: string, data)
	local handle = NOTICES[kind]
	if handle then
		handle(data or {})
	end
end)

