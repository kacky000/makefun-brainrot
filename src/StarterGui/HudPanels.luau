-- HudPanels: the three panels the bottom buttons open: INDEX (every brainrot as a 3D preview, found or ???),
-- REBIRTH (what it costs and what it gives) and UPGRADES (pedestals, shoes, lock).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage.BrainrotCatalog)
local GameConfig = require(ReplicatedStorage.GameConfig)

local HudPanels = {}

local INK = Color3.fromRGB(26, 18, 44)
local GOLD = Color3.fromRGB(255, 205, 60)
local WHITE = Color3.new(1, 1, 1)

local player: Player
local sendAction: (string, any?) -> ()
local panels = {}
local indexCards = {}
local indexTitle: TextLabel
local rebirthLines = {}
local upgradeRows = {}

local function text(parent: Instance, content: string, position: UDim2, size: UDim2, color: Color3?): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = position
	label.Size = size
	label.Font = Enum.Font.FredokaOne
	label.Text = content
	label.TextColor3 = color or WHITE
	label.TextScaled = true
	label.TextStrokeTransparency = 0.6
	label.Parent = parent
	return label
end

local function round(parent: Instance, radius: number, strokeColor: Color3?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(radius, 0)
	corner.Parent = parent
	if strokeColor then
		local stroke = Instance.new("UIStroke")
		stroke.Color = strokeColor
		stroke.Thickness = 3
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = parent
	end
end

local function panelFrame(screen: ScreenGui, name: string, title: string, position: UDim2, size: UDim2, color: Color3): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Position = position
	frame.Size = size
	frame.BackgroundColor3 = INK
	frame.BackgroundTransparency = 0.04
	frame.Visible = false
	frame.ZIndex = 5
	frame.Parent = screen
	round(frame, 0.04, color)
	local heading = text(frame, title, UDim2.fromScale(0.04, 0.015), UDim2.fromScale(0.8, 0.1), color)
	heading.TextXAlignment = Enum.TextXAlignment.Left
	local close = Instance.new("TextButton")
	close.Position = UDim2.fromScale(0.9, 0.02)
	close.Size = UDim2.fromScale(0.08, 0.09)
	close.BackgroundColor3 = Color3.fromRGB(235, 50, 70)
	close.Font = Enum.Font.FredokaOne
	close.Text = "X"
	close.TextColor3 = WHITE
	close.TextScaled = true
	close.Parent = frame
	round(close, 0.3)
	close.Activated:Connect(function()
		frame.Visible = false
	end)
	panels[name] = frame
	return frame
end

-- INDEX: a 9 x 4 grid, one card a brainrot, each a ViewportFrame showing its real model.
local function buildIndexPanel(screen: ScreenGui)
	local frame = panelFrame(screen, "index", "INDEX", UDim2.fromScale(0.03, 0.16), UDim2.fromScale(0.58, 0.68), Color3.fromRGB(80, 170, 255))
	indexTitle = frame:FindFirstChildOfClass("TextLabel")
	local previews = ReplicatedStorage:WaitForChild("BrainrotPreviews", 15)
	local columns, rows = 9, 4
	for index, entry in BrainrotCatalog.ENTRIES do
		local column, row = (index - 1) % columns, math.floor((index - 1) / columns)
		local rarity = BrainrotCatalog.rarityOf(entry)
		local card = Instance.new("Frame")
		card.Position = UDim2.fromScale(0.015 + column * 0.108, 0.13 + row * 0.215)
		card.Size = UDim2.fromScale(0.1, 0.2)
		card.BackgroundColor3 = Color3.fromRGB(48, 36, 78)
		card.Parent = frame
		round(card, 0.1, rarity.color)
		local view = Instance.new("ViewportFrame")
		view.Position = UDim2.fromScale(0.05, 0.03)
		view.Size = UDim2.fromScale(0.9, 0.66)
		view.BackgroundTransparency = 1
		view.Ambient = Color3.fromRGB(200, 200, 200)
		view.LightColor = WHITE
		view.Parent = card
		local source = previews and previews:FindFirstChild(entry.id)
		if source then
			local copy = source:Clone()
			copy.Parent = view
			local camera = Instance.new("Camera")
			local height = (copy:GetAttribute("TopY") or 6) + 0.5
			camera.FieldOfView = 40
			camera.CFrame = CFrame.lookAt(Vector3.new(2.5, height * 0.62, -height * 1.75), Vector3.new(0, height * 0.5, 0))
			camera.Parent = view
			view.CurrentCamera = camera
		end
		local name = text(card, entry.name, UDim2.fromScale(0.03, 0.69), UDim2.fromScale(0.94, 0.17))
		local tier = text(card, string.upper(entry.rarity), UDim2.fromScale(0.03, 0.86), UDim2.fromScale(0.94, 0.12), rarity.color)
		indexCards[entry.id] = { view = view, name = name, tier = tier, entry = entry }
	end
end

local function buildRebirthPanel(screen: ScreenGui)
	local frame = panelFrame(screen, "rebirth", "REBIRTH", UDim2.fromScale(0.63, 0.16), UDim2.fromScale(0.34, 0.68), Color3.fromRGB(190, 110, 255))
	local rowsText = { "now", "income", "luck", "resets", "keeps" }
	for index, key in rowsText do
		local line = text(frame, "", UDim2.fromScale(0.05, 0.13 + (index - 1) * 0.095), UDim2.fromScale(0.9, 0.08))
		line.TextXAlignment = Enum.TextXAlignment.Left
		rebirthLines[key] = line
	end
	rebirthLines.resets.Text = "RESETS: money and pedestals"
	rebirthLines.resets.TextColor3 = Color3.fromRGB(255, 130, 140)
	rebirthLines.keeps.Text = "KEEPS: upgrades and index"
	rebirthLines.keeps.TextColor3 = Color3.fromRGB(130, 255, 160)
	local bar = Instance.new("Frame")
	bar.Position = UDim2.fromScale(0.05, 0.63)
	bar.Size = UDim2.fromScale(0.9, 0.09)
	bar.BackgroundColor3 = Color3.fromRGB(60, 46, 96)
	bar.Parent = frame
	round(bar, 0.4)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Color3.fromRGB(190, 110, 255)
	fill.Parent = bar
	round(fill, 0.4)
	rebirthLines.fill = fill
	rebirthLines.progress = text(bar, "", UDim2.fromScale(0, 0.05), UDim2.fromScale(1, 0.9))
	rebirthLines.progress.ZIndex = 2
	local button = Instance.new("TextButton")
	button.Position = UDim2.fromScale(0.12, 0.77)
	button.Size = UDim2.fromScale(0.76, 0.17)
	button.BackgroundColor3 = Color3.fromRGB(170, 80, 255)
	button.Font = Enum.Font.FredokaOne
	button.Text = "REBIRTH NOW"
	button.TextColor3 = WHITE
	button.TextScaled = true
	button.Parent = frame
	round(button, 0.25, GOLD)
	button.Activated:Connect(function()
		sendAction("rebirth")
	end)
	rebirthLines.button = button
end

local function buildUpgradesPanel(screen: ScreenGui)
	local frame = panelFrame(screen, "upgrades", "UPGRADES", UDim2.fromScale(0.63, 0.16), UDim2.fromScale(0.34, 0.68), Color3.fromRGB(90, 220, 120))
	for index, key in GameConfig.UPGRADE_ORDER do
		local spec = GameConfig.UPGRADES[key]
		local row = Instance.new("Frame")
		row.Position = UDim2.fromScale(0.04, 0.14 + (index - 1) * 0.28)
		row.Size = UDim2.fromScale(0.92, 0.25)
		row.BackgroundColor3 = Color3.fromRGB(48, 36, 78)
		row.Parent = frame
		round(row, 0.12)
		local title = text(row, spec.title, UDim2.fromScale(0.04, 0.06), UDim2.fromScale(0.56, 0.34), GOLD)
		title.TextXAlignment = Enum.TextXAlignment.Left
		local detail = text(row, "", UDim2.fromScale(0.04, 0.46), UDim2.fromScale(0.56, 0.44))
		detail.TextXAlignment = Enum.TextXAlignment.Left
		local buy = Instance.new("TextButton")
		buy.Position = UDim2.fromScale(0.63, 0.14)
		buy.Size = UDim2.fromScale(0.34, 0.72)
		buy.BackgroundColor3 = Color3.fromRGB(60, 190, 100)
		buy.Font = Enum.Font.FredokaOne
		buy.TextColor3 = WHITE
		buy.TextScaled = true
		buy.Parent = row
		round(buy, 0.2)
		buy.Activated:Connect(function()
			sendAction("upgrade", key)
		end)
		upgradeRows[key] = { detail = detail, buy = buy }
	end
end

-- Build all three panels (hidden) on the HUD's ScreenGui.
function HudPanels.buildPanels(screen: ScreenGui, localPlayer: Player, send: (string, any?) -> ())
	player = localPlayer
	sendAction = send
	buildIndexPanel(screen)
	buildRebirthPanel(screen)
	buildUpgradesPanel(screen)
	HudPanels.refresh()
end

-- Redraw the panels from the player's attributes.
function HudPanels.refresh()
	local found = {}
	local foundCount = 0
	for id in string.gmatch(player:GetAttribute("Index") or "", "[^,]+") do
		found[id] = true
		foundCount += 1
	end
	if indexTitle then
		indexTitle.Text = string.format("INDEX  %d/%d found", foundCount, BrainrotCatalog.count())
	end
	for id, card in indexCards do
		local known = found[id] == true
		card.view.ImageColor3 = known and WHITE or Color3.new(0, 0, 0)
		card.name.Text = known and card.entry.name or "???"
		card.tier.Text = known and (string.upper(card.entry.rarity) .. " +" .. GameConfig.formatMoney(card.entry.income) .. "/s") or string.upper(card.entry.rarity)
	end
	local rebirths = player:GetAttribute("Rebirths") or 0
	local money = player:GetAttribute("Money") or 0
	local cost = GameConfig.rebirthCost(rebirths)
	if rebirthLines.now then
		rebirthLines.now.Text = string.format("REBIRTHS: %d", rebirths)
		rebirthLines.income.Text = string.format("INCOME x%.1f  ->  x%.1f", GameConfig.rebirthIncomeMultiplier(rebirths), GameConfig.rebirthIncomeMultiplier(rebirths + 1))
		rebirthLines.luck.Text = string.format("CANNON LUCK x%.2f  ->  x%.2f", GameConfig.rebirthLuck(rebirths), GameConfig.rebirthLuck(rebirths + 1))
		rebirthLines.fill.Size = UDim2.fromScale(math.clamp(money / cost, 0, 1), 1)
		rebirthLines.progress.Text = GameConfig.formatMoney(money) .. " / " .. GameConfig.formatMoney(cost)
		rebirthLines.button.BackgroundColor3 = (money >= cost) and Color3.fromRGB(170, 80, 255) or Color3.fromRGB(90, 80, 110)
	end
	local levels = { pedestals = player:GetAttribute("UpPedestals") or 0, speed = player:GetAttribute("UpSpeed") or 0, lock = player:GetAttribute("UpLock") or 0 }
	local values = {
		pedestals = function(level)
			return GameConfig.pedestalCount(level) .. " pedestals"
		end,
		speed = function(level)
			return GameConfig.walkSpeed(level) .. " speed"
		end,
		lock = function(level)
			return GameConfig.lockSeconds(level) .. "s lock"
		end,
	}
	for key, row in upgradeRows do
		local spec = GameConfig.UPGRADES[key]
		local level = levels[key]
		row.detail.Text = string.format("LV %d/%d   %s", level, spec.maxLevel, values[key](level))
		if level >= spec.maxLevel then
			row.buy.Text = "MAX"
			row.buy.BackgroundColor3 = Color3.fromRGB(90, 80, 110)
		else
			local price = GameConfig.upgradeCost(key, level)
			row.buy.Text = spec.blurb .. "\n" .. GameConfig.formatMoney(price)
			row.buy.BackgroundColor3 = (money >= price) and Color3.fromRGB(60, 190, 100) or Color3.fromRGB(90, 80, 110)
		end
	end
end

function HudPanels.closeAll()
	for _, frame in panels do
		frame.Visible = false
	end
end

-- Open one panel. REBIRTH and UPGRADES share the right-hand spot, so opening one closes the other.
function HudPanels.open(name: string)
	local frame = panels[name]
	if not frame then
		return
	end
	if name == "rebirth" then
		panels.upgrades.Visible = false
	elseif name == "upgrades" then
		panels.rebirth.Visible = false
	end
	frame.Visible = true
	HudPanels.refresh()
end

function HudPanels.toggle(name: string)
	local frame = panels[name]
	if frame and frame.Visible then
		frame.Visible = false
	else
		HudPanels.open(name)
	end
end

return HudPanels
