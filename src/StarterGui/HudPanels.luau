-- HudPanels: the three pop-up panels of the HUD. INDEX (all 36 brainrots as 3D preview cards,
-- undiscovered ones as silhouettes), REBIRTH (what you give up and what you keep) and UPGRADES
-- (MORE PEDESTALS, ROLLER SKATES, LONGER LOCK). They only display state and send requests.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))

local HudPanels = {}

local player = Players.LocalPlayer
local INK = Color3.fromRGB(22, 18, 34)
local WHITE = Color3.fromRGB(255, 255, 255)
local YELLOW = Color3.fromRGB(255, 226, 90)

-- Tiny builder: HudPanels.new("TextLabel", { props }, parent).
function HudPanels.new(className: string, props: { [string]: any }, parent: Instance?)
	local object = Instance.new(className)
	for key, value in props do
		(object :: any)[key] = value
	end
	if object:IsA("TextLabel") or object:IsA("TextButton") then
		object.Font = props.Font or Enum.Font.FredokaOne
		object.TextScaled = if props.TextScaled == nil then true else props.TextScaled
		object.BackgroundTransparency = props.BackgroundTransparency or 1
	end
	object.Parent = parent
	return object
end

-- A dark rounded card with a coloured outline, the look every HUD box shares.
function HudPanels.card(parent: Instance, name: string, position: UDim2, size: UDim2, outline: Color3): Frame
	local frame = HudPanels.new("Frame", { Name = name, Position = position, Size = size, BackgroundColor3 = INK, BackgroundTransparency = 0.12, BorderSizePixel = 0 }, parent)
	HudPanels.new("UICorner", { CornerRadius = UDim.new(0.14, 0) }, frame)
	HudPanels.new("UIStroke", { Color = outline, Thickness = 3 }, frame)
	return frame
end

local function panelShell(gui: ScreenGui, name: string, title: string, position: UDim2, size: UDim2, outline: Color3): Frame
	local panel = HudPanels.card(gui, name, position, size, outline)
	panel.Visible = false
	panel.ZIndex = 20
	panel.BackgroundTransparency = 0.04
	local corner = panel:FindFirstChildOfClass("UICorner") :: UICorner
	corner.CornerRadius = UDim.new(0.04, 0)
	HudPanels.new("TextLabel", { Name = "Title", Text = title, TextColor3 = outline, Position = UDim2.fromScale(0.04, 0.02), Size = UDim2.fromScale(0.78, 0.11), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 21 }, panel)
	local close = HudPanels.new("TextButton", { Name = "Close", Text = "X", TextColor3 = WHITE, BackgroundColor3 = Color3.fromRGB(232, 50, 70), BackgroundTransparency = 0, Position = UDim2.fromScale(0.89, 0.025), Size = UDim2.fromScale(0.08, 0.1), ZIndex = 22 }, panel)
	HudPanels.new("UICorner", { CornerRadius = UDim.new(0.3, 0) }, close)
	close.Activated:Connect(function()
		panel.Visible = false
	end)
	return panel
end

-- INDEX: one card per brainrot in catalog order, with a spinning-free 3D preview.
function HudPanels.buildIndexPanel(gui: ScreenGui)
	local panel = panelShell(gui, "IndexPanel", "BRAINROT INDEX", UDim2.fromScale(0.03, 0.15), UDim2.fromScale(0.6, 0.8), Color3.fromRGB(80, 190, 255))
	local count = HudPanels.new("TextLabel", { Name = "Count", Text = "0/36", TextColor3 = YELLOW, Position = UDim2.fromScale(0.6, 0.03), Size = UDim2.fromScale(0.27, 0.09), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 21 }, panel)
	local grid = HudPanels.new("Frame", { Name = "Grid", BackgroundTransparency = 1, Position = UDim2.fromScale(0.02, 0.14), Size = UDim2.fromScale(0.96, 0.84), ZIndex = 21 }, panel)
	HudPanels.new("UIGridLayout", { CellSize = UDim2.fromScale(0.105, 0.24), CellPadding = UDim2.fromScale(0.006, 0.012), SortOrder = Enum.SortOrder.LayoutOrder, FillDirectionMaxCells = 9 }, grid)
	local previews = ReplicatedStorage:WaitForChild("BrainrotPreviews", 10)
	local cards = {}
	for order, entry in BrainrotCatalog.LIST do
		local rarity = GameConfig.RARITY_BY_KEY[entry.rarity]
		local card = HudPanels.new("Frame", { Name = entry.id, LayoutOrder = order, BackgroundColor3 = Color3.fromRGB(40, 34, 60), BorderSizePixel = 0, ZIndex = 21 }, grid)
		HudPanels.new("UICorner", { CornerRadius = UDim.new(0.1, 0) }, card)
		HudPanels.new("UIStroke", { Color = rarity.color, Thickness = 2 }, card)
		local view = HudPanels.new("ViewportFrame", { Name = "View", BackgroundTransparency = 1, Position = UDim2.fromScale(0.04, 0.02), Size = UDim2.fromScale(0.92, 0.6), ZIndex = 22, Ambient = Color3.fromRGB(200, 200, 200), LightColor = WHITE }, card)
		local source = previews and previews:FindFirstChild(entry.id)
		if source then
			local model = source:Clone()
			model.Parent = view
			local top = (model:GetAttribute("TopY") or 6) :: number
			local camera = Instance.new("Camera")
			camera.FieldOfView = 34
			camera.CFrame = CFrame.lookAt(Vector3.new(top * 0.35, top * 0.62, -top * 1.75), Vector3.new(0, top * 0.42, 0))
			camera.Parent = view
			view.CurrentCamera = camera
		end
		local name = HudPanels.new("TextLabel", { Name = "BrainrotName", Text = "???", TextColor3 = WHITE, Position = UDim2.fromScale(0.03, 0.62), Size = UDim2.fromScale(0.94, 0.2), ZIndex = 22 }, card)
		local detail = HudPanels.new("TextLabel", { Name = "Detail", Text = string.upper(entry.rarity), TextColor3 = rarity.color, Position = UDim2.fromScale(0.03, 0.82), Size = UDim2.fromScale(0.94, 0.16), ZIndex = 22 }, card)
		cards[order] = { view = view, name = name, detail = detail, entry = entry }
	end

	local function refresh()
		local index = (player:GetAttribute("Index") or "") :: string
		local found = 0
		for order, card in cards do
			local known = string.sub(index, order, order) == "1"
			if known then
				found += 1
			end
			card.view.ImageColor3 = if known then WHITE else Color3.fromRGB(8, 6, 14)
			card.name.Text = if known then card.entry.name else "???"
			card.detail.Text = if known then string.upper(card.entry.rarity) .. " $" .. GameConfig.formatCash(card.entry.income) .. "/s" else string.upper(card.entry.rarity)
		end
		count.Text = found .. "/" .. BrainrotCatalog.COUNT
	end
	player:GetAttributeChangedSignal("Index"):Connect(refresh)
	refresh()
	return panel
end

-- REBIRTH: the trade spelled out, with a progress bar toward the cost.
function HudPanels.buildRebirthPanel(gui: ScreenGui, request: (string, string?) -> ())
	local purple = Color3.fromRGB(190, 110, 255)
	local panel = panelShell(gui, "RebirthPanel", "REBIRTH", UDim2.fromScale(0.645, 0.15), UDim2.fromScale(0.34, 0.8), purple)
	local now = HudPanels.new("TextLabel", { Name = "Now", Text = "", TextColor3 = WHITE, Position = UDim2.fromScale(0.05, 0.15), Size = UDim2.fromScale(0.9, 0.09), ZIndex = 21 }, panel)
	local nextUp = HudPanels.new("TextLabel", { Name = "Next", Text = "", TextColor3 = YELLOW, Position = UDim2.fromScale(0.05, 0.25), Size = UDim2.fromScale(0.9, 0.12), ZIndex = 21 }, panel)
	local lines = {
		{ "YOU KEEP: upgrades, INDEX, luck", Color3.fromRGB(120, 255, 140) },
		{ "YOU GIVE UP: cash + every brainrot", Color3.fromRGB(255, 120, 130) },
		{ "EACH REBIRTH: +50% income forever", WHITE },
		{ "AND +25% MUTATION LUCK on the belt", WHITE },
	}
	for row, line in lines do
		HudPanels.new("TextLabel", { Text = line[1], TextColor3 = line[2], Position = UDim2.fromScale(0.05, 0.3 + row * 0.085), Size = UDim2.fromScale(0.9, 0.07), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 21 }, panel)
	end
	local bar = HudPanels.new("Frame", { Name = "Bar", BackgroundColor3 = Color3.fromRGB(50, 40, 76), BorderSizePixel = 0, Position = UDim2.fromScale(0.05, 0.75), Size = UDim2.fromScale(0.9, 0.055), ZIndex = 21 }, panel)
	HudPanels.new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, bar)
	local fill = HudPanels.new("Frame", { Name = "Fill", BackgroundColor3 = purple, BorderSizePixel = 0, Size = UDim2.fromScale(0, 1), ZIndex = 22 }, bar)
	HudPanels.new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, fill)
	local go = HudPanels.new("TextButton", { Name = "Go", Text = "REBIRTH", TextColor3 = WHITE, BackgroundColor3 = purple, BackgroundTransparency = 0, Position = UDim2.fromScale(0.1, 0.83), Size = UDim2.fromScale(0.8, 0.13), ZIndex = 21 }, panel)
	HudPanels.new("UICorner", { CornerRadius = UDim.new(0.25, 0) }, go)
	go.Activated:Connect(function()
		request("rebirth")
	end)

	local function refresh()
		local rebirths = (player:GetAttribute("Rebirths") or 0) :: number
		local cash = (player:GetAttribute("Cash") or 0) :: number
		local cost = GameConfig.rebirthCost(rebirths)
		now.Text = "REBIRTH " .. rebirths .. "  -  INCOME x" .. GameConfig.rebirthMultiplier(rebirths)
		nextUp.Text = "NEXT: x" .. GameConfig.rebirthMultiplier(rebirths + 1) .. " INCOME"
		fill.Size = UDim2.fromScale(math.clamp(cash / cost, 0, 1), 1)
		go.Text = if cash >= cost then "REBIRTH NOW!" else "COSTS $" .. GameConfig.formatCash(cost)
	end
	player:GetAttributeChangedSignal("Rebirths"):Connect(refresh)
	player:GetAttributeChangedSignal("Cash"):Connect(refresh)
	refresh()
	return panel
end

-- UPGRADES: three rows, each with its level, effect and next price.
function HudPanels.buildUpgradesPanel(gui: ScreenGui, request: (string, string?) -> ())
	local orange = Color3.fromRGB(255, 160, 60)
	local panel = panelShell(gui, "UpgradesPanel", "UPGRADES", UDim2.fromScale(0.645, 0.15), UDim2.fromScale(0.34, 0.8), orange)
	local rows = {}
	for index, key in GameConfig.UPGRADE_ORDER do
		local upgrade = GameConfig.UPGRADES[key]
		local row = HudPanels.card(panel, key, UDim2.fromScale(0.05, 0.16 + (index - 1) * 0.27), UDim2.fromScale(0.9, 0.24), orange)
		row.ZIndex = 21
		HudPanels.new("TextLabel", { Text = upgrade.title, TextColor3 = WHITE, Position = UDim2.fromScale(0.04, 0.05), Size = UDim2.fromScale(0.92, 0.3), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 22 }, row)
		local detail = HudPanels.new("TextLabel", { Name = "Detail", Text = "", TextColor3 = YELLOW, Position = UDim2.fromScale(0.04, 0.36), Size = UDim2.fromScale(0.92, 0.22), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 22 }, row)
		local buy = HudPanels.new("TextButton", { Name = "Buy", Text = "", TextColor3 = WHITE, BackgroundColor3 = Color3.fromRGB(60, 190, 90), BackgroundTransparency = 0, Position = UDim2.fromScale(0.3, 0.62), Size = UDim2.fromScale(0.66, 0.32), ZIndex = 22 }, row)
		HudPanels.new("UICorner", { CornerRadius = UDim.new(0.3, 0) }, buy)
		buy.Activated:Connect(function()
			request("upgrade", key)
		end)
		rows[key] = { detail = detail, buy = buy, upgrade = upgrade }
	end

	local function refresh()
		for key, row in rows do
			local level = (player:GetAttribute("Upgrade" .. key) or 0) :: number
			local cost = row.upgrade.costs[level + 1]
			row.detail.Text = "LEVEL " .. level .. "/" .. #row.upgrade.costs .. "  -  NOW " .. GameConfig.upgradeValue(key, level) .. "  -  " .. row.upgrade.blurb
			row.buy.Text = if cost then "BUY $" .. GameConfig.formatCash(cost) else "MAXED"
			row.buy.BackgroundColor3 = if cost then Color3.fromRGB(60, 190, 90) else Color3.fromRGB(90, 84, 104)
		end
	end
	for _, key in GameConfig.UPGRADE_ORDER do
		player:GetAttributeChangedSignal("Upgrade" .. key):Connect(refresh)
	end
	refresh()
	return panel
end

return HudPanels
