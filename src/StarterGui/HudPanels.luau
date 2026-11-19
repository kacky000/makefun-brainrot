-- HudPanels: the three panels behind the HUD's buttons. INDEX (a 3D card for every brainrot found, ??? for the
-- rest), REBIRTH (what it resets, what it gives, its price) and UPGRADES (pedestals, speed, lock time).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))

local HudPanels = {}
local rgb = Color3.fromRGB
local DARK = rgb(28, 20, 44)
local money = BrainrotCatalog.formatMoney

function HudPanels.build(gui: ScreenGui, kit)
	local new, text, corner, stroke, outline = kit.new, kit.text, kit.corner, kit.stroke, kit.outline
	local frames = {}

	local function panel(name: string, title: string, position: UDim2, size: UDim2, color: Color3)
		local frame = new("Frame", { Parent = gui, Name = name .. "Panel", AnchorPoint = Vector2.new(0.5, 0.5), Position = position, Size = size, BackgroundColor3 = DARK, BackgroundTransparency = 0.04, Visible = false, ZIndex = 10 }, { corner(22), stroke(color, 4) })
		text({ Parent = frame, Name = "Title", Position = UDim2.fromOffset(16, 8), Size = UDim2.new(1, -32, 0, 44), Font = Enum.Font.LuckiestGuy, Text = title, TextColor3 = color, ZIndex = 11 }, { outline(rgb(20, 10, 30), 3) })
		frames[name] = frame
		return frame
	end

	-- INDEX: 9 x 4 cards, one per brainrot, in ladder order.
	local index = panel("Index", "INDEX", UDim2.new(0.5, -196, 0.5, 30), UDim2.fromOffset(640, 452), rgb(80, 170, 255))
	local cards = {}
	local previews = ReplicatedStorage:WaitForChild("BrainrotPreviews", 30)
	for i, entry in BrainrotCatalog.list do
		local col, row = (i - 1) % 9, (i - 1) // 9
		local rarity = GameConfig.RARITIES[entry.rarity]
		local card = new("Frame", { Parent = index, Name = entry.id, Position = UDim2.fromOffset(14 + col * 68.5, 58 + row * 97), Size = UDim2.fromOffset(64, 92), BackgroundColor3 = rgb(44, 34, 66), ZIndex = 11 }, { corner(10), stroke(rarity.color, 2.5) })
		local view = new("ViewportFrame", { Parent = card, Position = UDim2.fromOffset(2, 2), Size = UDim2.fromOffset(60, 58), BackgroundTransparency = 1, Ambient = Color3.new(1, 1, 1), LightColor = Color3.new(1, 1, 1), ZIndex = 12, Visible = false })
		local model = previews and previews:FindFirstChild(entry.id)
		if model then
			local copy = model:Clone()
			copy:PivotTo(CFrame.new(0, 0, 0))
			copy.Parent = view
			local camera = new("Camera", { Parent = view, FieldOfView = 40 })
			local top = copy:GetAttribute("TopY") or 5
			camera.CFrame = CFrame.lookAt(Vector3.new(-3.5, top * 0.25, -top * 1.75 - 3), Vector3.new(0, top * 0.05, 0))
			view.CurrentCamera = camera
		end
		local unknown = text({ Parent = card, Name = "Unknown", Position = UDim2.fromOffset(2, 2), Size = UDim2.fromOffset(60, 58), Font = Enum.Font.LuckiestGuy, Text = "?", TextColor3 = rgb(110, 96, 140), ZIndex = 12 })
		local label = text({ Parent = card, Name = "Name", Position = UDim2.fromOffset(3, 60), Size = UDim2.fromOffset(58, 30), Text = "???", TextColor3 = rarity.color, TextWrapped = true, ZIndex = 12 })
		cards[entry.id] = { view = view, unknown = unknown, label = label, entry = entry }
	end

	-- REBIRTH: what it costs and what it gives.
	local rebirth = panel("Rebirth", "REBIRTH", UDim2.new(0.5, 322, 0.5, 30), UDim2.fromOffset(360, 452), rgb(200, 140, 255))
	local function line(parent: Instance, y: number, height: number, message: string, color: Color3)
		return text({ Parent = parent, Position = UDim2.fromOffset(18, y), Size = UDim2.new(1, -36, 0, height), Text = message, TextColor3 = color, ZIndex = 11 })
	end
	local nowLine = line(rebirth, 58, 34, "NOW  x1.0 MONEY", Color3.new(1, 1, 1))
	local nextLine = line(rebirth, 96, 48, "NEXT  x1.5 MONEY", rgb(110, 255, 130))
	line(rebirth, 148, 26, "+20% MUTATION LUCK EVERY REBIRTH", rgb(255, 236, 110))
	line(rebirth, 186, 24, "RESETS  cash + pedestals", rgb(255, 130, 140))
	line(rebirth, 212, 24, "KEEPS  index + upgrades", rgb(150, 220, 255))
	local costLine = line(rebirth, 252, 36, "COST $50.00K", rgb(255, 222, 70))
	local bar = new("Frame", { Parent = rebirth, Position = UDim2.fromOffset(18, 296), Size = UDim2.new(1, -36, 0, 22), BackgroundColor3 = rgb(60, 50, 80), ZIndex = 11 }, { corner(11) })
	local fill = new("Frame", { Parent = bar, Size = UDim2.fromScale(0, 1), BackgroundColor3 = rgb(200, 140, 255), ZIndex = 12 }, { corner(11) })
	local go = new("TextButton", { Parent = rebirth, Position = UDim2.fromOffset(18, 340), Size = UDim2.new(1, -36, 0, 92), BackgroundColor3 = rgb(160, 84, 240), Text = "", ZIndex = 11 }, { corner(18), stroke(Color3.new(1, 1, 1), 3) })
	local goText = text({ Parent = go, Position = UDim2.fromOffset(10, 12), Size = UDim2.new(1, -20, 1, -24), Font = Enum.Font.LuckiestGuy, Text = "REBIRTH NOW", ZIndex = 12 }, { outline(rgb(40, 20, 50), 3) })
	go.Activated:Connect(function()
		kit.action:FireServer("Rebirth")
	end)

	-- UPGRADES: three rows.
	local upgrades = panel("Upgrades", "UPGRADES", UDim2.new(0.5, 0, 0.5, 30), UDim2.fromOffset(560, 380), rgb(255, 170, 70))
	local rows = {}
	for i, key in { "Pedestals", "Speed", "Lock" } do
		local config = GameConfig.UPGRADES[key]
		local row = new("Frame", { Parent = upgrades, Name = key, Position = UDim2.fromOffset(16, 62 + (i - 1) * 102), Size = UDim2.new(1, -32, 0, 92), BackgroundColor3 = rgb(44, 34, 66), ZIndex = 11 }, { corner(14) })
		text({ Parent = row, Position = UDim2.fromOffset(14, 6), Size = UDim2.fromOffset(300, 36), Font = Enum.Font.LuckiestGuy, Text = config.label, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12 })
		local level = text({ Parent = row, Position = UDim2.fromOffset(14, 46), Size = UDim2.fromOffset(300, 30), Text = "", TextColor3 = rgb(255, 222, 70), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12 })
		local buy = new("TextButton", { Parent = row, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(180, 66), BackgroundColor3 = rgb(70, 200, 100), Text = "", ZIndex = 12 }, { corner(14), stroke(Color3.new(1, 1, 1), 2) })
		local price = text({ Parent = buy, Position = UDim2.fromOffset(8, 10), Size = UDim2.new(1, -16, 1, -20), Font = Enum.Font.LuckiestGuy, Text = "", ZIndex = 13 }, { outline(rgb(20, 60, 30), 2) })
		buy.Activated:Connect(function()
			kit.action:FireServer("Upgrade", key)
		end)
		rows[key] = { level = level, price = price, buy = buy, config = config }
	end

	local api = {}

	function api.open(name: string)
		if frames[name] then
			frames[name].Visible = true
		end
	end

	function api.closeAll()
		for _, frame in frames do
			frame.Visible = false
		end
	end

	function api.toggle(name: string)
		local wasOpen = frames[name].Visible
		api.closeAll()
		frames[name].Visible = not wasOpen
	end

	-- refresh: redraw the open panels from the player's found set, cash and rebirths.
	function api.refresh(found: { [string]: boolean }, cash: number, rebirths: number)
		if index.Visible then
			local count = 0
			for id, card in cards do
				local have = found[id] == true
				card.view.Visible = have
				card.unknown.Visible = not have
				card.label.Text = if have then card.entry.name else "???"
				if have then
					count += 1
				end
			end
			index.Title.Text = string.format("INDEX  %d / %d FOUND", count, BrainrotCatalog.count)
		end
		if rebirth.Visible then
			local cost = GameConfig.REBIRTH.base * GameConfig.REBIRTH.growth ^ rebirths
			nowLine.Text = string.format("NOW  x%.1f MONEY", 1 + rebirths * GameConfig.REBIRTH.incomeBonus)
			nextLine.Text = string.format("NEXT  x%.1f MONEY", 1 + (rebirths + 1) * GameConfig.REBIRTH.incomeBonus)
			costLine.Text = "COST " .. money(cost)
			fill.Size = UDim2.fromScale(math.clamp(cash / cost, 0, 1), 1)
			goText.Text = if cash >= cost then "REBIRTH NOW" else "NEED " .. money(cost - cash)
			go.BackgroundColor3 = if cash >= cost then rgb(160, 84, 240) else rgb(90, 80, 110)
		end
		if upgrades.Visible then
			for key, row in rows do
				local level = kit.player:GetAttribute("Up" .. key) or 0
				local maxed = level >= row.config.max
				local cost = math.floor(row.config.base * row.config.growth ^ level)
				row.level.Text = string.format("LEVEL %d / %d  ·  %s", level, row.config.max, row.config.unit)
				row.price.Text = if maxed then "MAX" else money(cost)
				row.buy.BackgroundColor3 = if maxed then rgb(90, 80, 110) elseif cash >= cost then rgb(70, 200, 100) else rgb(200, 90, 90)
			end
		end
	end

	return api
end

return HudPanels
