--!strict
-- The Brainrot Index: a book of the whole cast, each card a live 3D preview with name, rarity and income;
-- undiscovered ones show as black silhouettes with "???".

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local MutationRoller = require(ReplicatedStorage:WaitForChild("MutationRoller"))

local IndexBook = {}

local panel: Frame? = nil
local cards: { [string]: { viewport: ViewportFrame, name: TextLabel } } = {}
local header: TextLabel

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function text(parent: Instance, value: string, size: UDim2, pos: UDim2, color: Color3, font: Enum.Font?): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = pos
	label.Font = font or Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = value
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.2
	label.Parent = parent
	return label
end

local function makeCard(parent: Instance, def: BrainrotCatalog.Brainrot, order: number)
	local rarity = BrainrotCatalog.rarity(def.rarity)
	local card = Instance.new("Frame")
	card.Name = def.id
	card.LayoutOrder = order
	card.BackgroundColor3 = Color3.fromRGB(40, 24, 70)
	card.Parent = parent
	corner(card, 8)
	local stroke = Instance.new("UIStroke")
	stroke.Color = rarity.color
	stroke.Thickness = 2
	stroke.Parent = card

	local viewport = Instance.new("ViewportFrame")
	viewport.Size = UDim2.new(1, -6, 0.62, 0)
	viewport.Position = UDim2.fromOffset(3, 3)
	viewport.BackgroundColor3 = rarity.color:Lerp(Color3.fromRGB(30, 20, 60), 0.6)
	viewport.Ambient = Color3.fromRGB(200, 200, 200)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.LightDirection = Vector3.new(-0.4, -1, 0.6)
	viewport.Parent = card
	corner(viewport, 6)

	local model = (ReplicatedStorage:WaitForChild("CastPreviews"):WaitForChild(def.id) :: Model):Clone()
	model:PivotTo(CFrame.Angles(0, math.rad(-25), 0))
	model.Parent = viewport
	local height = model:GetAttribute("Height") :: number
	local camera = Instance.new("Camera")
	camera.FieldOfView = 40
	local focus = Vector3.new(0, height * 0.5, 0)
	camera.CFrame = CFrame.lookAt(focus + Vector3.new(0, height * 0.2, -(height * 1.15 + 2.2)), focus)
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local name = text(card, def.name, UDim2.new(1, -6, 0.22, 0), UDim2.new(0, 3, 0.62, 0), Color3.new(1, 1, 1))
	local info = text(card, string.upper(def.rarity) .. " · " .. GameConfig.perSecond(def.income), UDim2.new(1, -6, 0.14, 0), UDim2.new(0, 3, 0.84, 0), rarity.color)
	info.TextStrokeTransparency = 0
	cards[def.id] = { viewport = viewport, name = name }
end

function IndexBook.build(parent: ScreenGui)
	local frame = Instance.new("Frame")
	frame.Name = "IndexBook"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.455, 0.54)
	frame.Size = UDim2.fromOffset(856, 512)
	frame.BackgroundColor3 = Color3.fromRGB(70, 30, 120)
	frame.Visible = false
	frame.Parent = parent
	corner(frame, 16)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 220, 60)
	stroke.Thickness = 4
	stroke.Parent = frame

	header = text(frame, "BRAINROT INDEX", UDim2.new(0.7, 0, 0, 44), UDim2.fromOffset(18, 8), Color3.fromRGB(255, 225, 60))
	header.TextXAlignment = Enum.TextXAlignment.Left
	local legend = text(frame, "", UDim2.new(0.96, 0, 0, 20), UDim2.fromOffset(18, 52), Color3.new(1, 1, 1), Enum.Font.GothamBold)
	legend.TextXAlignment = Enum.TextXAlignment.Left
	legend.RichText = true
	local parts = {}
	for _, rarity in BrainrotCatalog.rarities do
		table.insert(parts, string.format('<font color="#%s">%s</font>', rarity.color:ToHex(), string.upper(rarity.name)))
	end
	local muts = {}
	for _, m in MutationRoller.list do
		table.insert(muts, string.format('<font color="#%s">%s x%d</font>', m.color:ToHex(), m.tag, m.multiplier))
	end
	legend.Text = table.concat(parts, "  ") .. "     MUTATIONS: " .. table.concat(muts, " ")

	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(44, 44)
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -10, 0, 10)
	close.BackgroundColor3 = Color3.fromRGB(255, 70, 90)
	close.Font = Enum.Font.FredokaOne
	close.TextScaled = true
	close.Text = "X"
	close.TextColor3 = Color3.new(1, 1, 1)
	close.Parent = frame
	corner(close, 10)
	close.Activated:Connect(function()
		frame.Visible = false
	end)

	local grid = Instance.new("Frame")
	grid.BackgroundTransparency = 1
	grid.Position = UDim2.fromOffset(14, 80)
	grid.Size = UDim2.new(1, -28, 1, -92)
	grid.Parent = frame
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(88, 102)
	layout.CellPadding = UDim2.fromOffset(4, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid
	for order, def in BrainrotCatalog.list do
		makeCard(grid, def, order)
	end
	panel = frame
end

-- Colours each card by whether the player has met that brainrot.
function IndexBook.refresh(discoveredCsv: string)
	local found: { [string]: boolean } = {}
	local count = 0
	for id in string.gmatch(discoveredCsv, "[^,]+") do
		found[id] = true
		count += 1
	end
	for id, card in cards do
		local def = BrainrotCatalog.get(id)
		if found[id] then
			card.viewport.ImageColor3 = Color3.new(1, 1, 1)
			card.name.Text = if def then def.name else id
		else
			card.viewport.ImageColor3 = Color3.new(0, 0, 0)
			card.name.Text = "???"
		end
	end
	header.Text = string.format("BRAINROT INDEX  %d/%d", count, BrainrotCatalog.COUNT)
end

-- Centred on its own; slid left (same size) when it shares the screen with the Rebirth panel.
function IndexBook.setOpen(open: boolean, besidePanel: boolean?)
	if not panel then
		return
	end
	panel.Visible = open
	panel.AnchorPoint = if besidePanel then Vector2.new(0, 0.5) else Vector2.new(0.5, 0.5)
	panel.Position = if besidePanel then UDim2.new(0, 10, 0.57, 0) else UDim2.fromScale(0.455, 0.54)
end

function IndexBook.isOpen(): boolean
	return panel ~= nil and panel.Visible
end

return IndexBook
