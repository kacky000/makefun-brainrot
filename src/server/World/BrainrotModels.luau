--!strict
-- Builds a brainrot's 3D model: its hand-built parts (CastArt) or a body recipe with googly eyes, mouth and
-- accessories, a mutation finish and a floating name / rarity / $-per-second card. Server-side; the client's
-- Index book clones the previews this publishes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local CastArt = require(script.Parent:WaitForChild("CastArt"))
local MutationRoller = require(ReplicatedStorage:WaitForChild("MutationRoller"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

type PartSpec = BrainrotCatalog.PartSpec
type Brainrot = BrainrotCatalog.Brainrot

local BrainrotModels = {}

local rgb = Color3.fromRGB
local v3 = Vector3.new
local WHITE = rgb(245, 245, 245)
local BLACK = rgb(25, 25, 30)

local function spec(shape: string, size: Vector3, pos: Vector3, color: Color3, extra: { [string]: any }?): PartSpec
	local s: any = { shape = shape, size = size, pos = pos, color = color }
	if extra then
		for k, v in extra do
			s[k] = v
		end
	end
	return s
end

local function ball(d: number, x: number, y: number, z: number, color: Color3, extra: { [string]: any }?): PartSpec
	return spec("Ball", v3(d, d, d), v3(x, y, z), color, extra)
end

local function block(sx: number, sy: number, sz: number, x: number, y: number, z: number, color: Color3, extra: { [string]: any }?): PartSpec
	return spec("Block", v3(sx, sy, sz), v3(x, y, z), color, extra)
end

local function pillar(h: number, d: number, x: number, y: number, z: number, color: Color3, extra: { [string]: any }?): PartSpec
	local s = spec("Cylinder", v3(h, d, d), v3(x, y, z), color, extra)
	s.rot = s.rot or v3(0, 0, 90)
	return s
end

local function wheel(w: number, d: number, x: number, y: number, z: number, color: Color3, extra: { [string]: any }?): PartSpec
	return spec("Cylinder", v3(w, d, d), v3(x, y, z), color, extra)
end

local function addEyes(parts: { PartSpec }, y: number, z: number, spacing: number, size: number)
	table.insert(parts, ball(size, -spacing, y, z, WHITE, { keep = true }))
	table.insert(parts, ball(size, spacing, y, z, WHITE, { keep = true }))
	table.insert(parts, ball(size * 0.5, -spacing + size * 0.1, y - size * 0.06, z - size * 0.33, BLACK, { keep = true }))
	table.insert(parts, ball(size * 0.5, spacing - size * 0.1, y + size * 0.07, z - size * 0.33, BLACK, { keep = true }))
end

-- A goofy open mouth with two buck teeth (and sometimes a tongue) under the eyes.
local function addMouth(parts: { PartSpec }, y: number, z: number, tongue: boolean)
	table.insert(parts, block(1.0, 0.42, 0.14, 0, y, z - 0.02, rgb(60, 15, 25), { keep = true }))
	table.insert(parts, block(0.24, 0.22, 0.1, -0.14, y + 0.12, z - 0.08, WHITE, { keep = true }))
	table.insert(parts, block(0.24, 0.22, 0.1, 0.14, y + 0.12, z - 0.08, WHITE, { keep = true }))
	if tongue then
		table.insert(parts, block(0.5, 0.14, 0.18, 0, y - 0.14, z - 0.1, rgb(250, 90, 120), { keep = true }))
	end
end

type Frame = { parts: { PartSpec }, top: number, faceY: number, faceZ: number, width: number }

-- Body archetypes: each lays down a body and says where the face and the top of the head are.
local BODIES: { [string]: (c1: Color3, c2: Color3, c3: Color3) -> Frame } = {
	blob = function(c1, c2, _c3)
		return {
			parts = {
				block(0.6, 0.5, 0.9, -0.6, 0.25, -0.1, c2),
				block(0.6, 0.5, 0.9, 0.6, 0.25, -0.1, c2),
				ball(2.8, 0, 1.8, 0, c1),
			},
			top = 3.2,
			faceY = 2.2,
			faceZ = -1.25,
			width = 2.8,
		}
	end,
	box = function(c1, c2, _c3)
		return {
			parts = {
				block(0.45, 1.0, 0.45, -0.6, 0.5, 0, c2),
				block(0.45, 1.0, 0.45, 0.6, 0.5, 0, c2),
				block(2.4, 2.6, 1.8, 0, 2.3, 0, c1),
				block(2.5, 0.3, 1.9, 0, 1.3, 0, c2),
			},
			top = 3.6,
			faceY = 2.8,
			faceZ = -0.92,
			width = 2.4,
		}
	end,
	can = function(c1, c2, c3)
		return {
			parts = {
				block(0.4, 0.9, 0.4, -0.5, 0.45, 0, c2),
				block(0.4, 0.9, 0.4, 0.5, 0.45, 0, c2),
				pillar(3.0, 2.0, 0, 2.4, 0, c1),
				pillar(0.35, 2.05, 0, 1.6, 0, c3),
				pillar(0.35, 2.05, 0, 3.2, 0, c3),
			},
			top = 3.9,
			faceY = 2.6,
			faceZ = -1.0,
			width = 2.0,
		}
	end,
	cone = function(c1, c2, c3)
		return {
			parts = {
				pillar(0.8, 0.7, 0, 0.4, 0, c2),
				pillar(0.8, 1.2, 0, 1.2, 0, c2),
				pillar(0.8, 1.7, 0, 2.0, 0, c2),
				ball(2.3, 0, 3.2, 0, c1),
				ball(0.5, 0, 4.4, 0, c3, { keep = true }),
			},
			top = 4.3,
			faceY = 3.3,
			faceZ = -1.05,
			width = 2.3,
		}
	end,
	quad = function(c1, c2, c3)
		return {
			parts = {
				block(0.45, 1.1, 0.45, -0.55, 0.55, -0.9, c2),
				block(0.45, 1.1, 0.45, 0.55, 0.55, -0.9, c2),
				block(0.45, 1.1, 0.45, -0.55, 0.55, 0.9, c2),
				block(0.45, 1.1, 0.45, 0.55, 0.55, 0.9, c2),
				block(1.7, 1.4, 3.0, 0, 1.7, 0, c1),
				ball(1.9, 0, 2.6, -1.7, c1),
				block(0.3, 0.3, 1.4, 0, 2.2, 1.9, c3, { rot = v3(-30, 0, 0) }),
			},
			top = 3.4,
			faceY = 2.8,
			faceZ = -2.5,
			width = 1.9,
		}
	end,
	bird = function(c1, c2, c3)
		return {
			parts = {
				block(0.2, 0.9, 0.2, -0.4, 0.45, 0, c3),
				block(0.2, 0.9, 0.2, 0.4, 0.45, 0, c3),
				ball(2.2, 0, 1.8, 0, c1),
				ball(1.6, 0, 3.1, -0.3, c1),
				block(0.7, 0.3, 0.7, 0, 3.0, -1.25, c3),
				block(0.25, 1.2, 1.4, -1.15, 1.9, 0.1, c2, { rot = v3(0, 0, 20) }),
				block(0.25, 1.2, 1.4, 1.15, 1.9, 0.1, c2, { rot = v3(0, 0, -20) }),
			},
			top = 3.9,
			faceY = 3.35,
			faceZ = -0.95,
			width = 2.2,
		}
	end,
	fish = function(c1, c2, c3)
		return {
			parts = {
				pillar(0.6, 0.9, 0, 0.3, 0, c3),
				ball(2.6, 0, 2.0, 0, c1),
				block(0.3, 1.6, 1.2, 0, 2.0, 1.6, c2, { rot = v3(25, 0, 0) }),
				block(0.25, 0.8, 0.9, 0, 3.2, 0.2, c2),
				block(0.2, 0.7, 0.9, -1.35, 1.8, 0, c2),
				block(0.2, 0.7, 0.9, 1.35, 1.8, 0, c2),
			},
			top = 3.4,
			faceY = 2.4,
			faceZ = -1.15,
			width = 2.6,
		}
	end,
	car = function(c1, c2, c3)
		return {
			parts = {
				wheel(0.4, 1.0, -1.25, 0.5, -1.1, BLACK),
				wheel(0.4, 1.0, 1.25, 0.5, -1.1, BLACK),
				wheel(0.4, 1.0, -1.25, 0.5, 1.1, BLACK),
				wheel(0.4, 1.0, 1.25, 0.5, 1.1, BLACK),
				block(2.4, 1.0, 3.4, 0, 1.2, 0, c1),
				block(2.0, 1.2, 1.8, 0, 2.3, 0.4, c2),
				block(2.5, 0.3, 0.3, 0, 1.0, -1.75, c3),
			},
			top = 2.9,
			faceY = 1.45,
			faceZ = -1.72,
			width = 2.4,
		}
	end,
	stack = function(c1, c2, _c3)
		return {
			parts = {
				ball(2.6, 0, 1.3, 0, c1),
				ball(1.9, 0, 3.2, 0, c2),
			},
			top = 4.1,
			faceY = 3.35,
			faceZ = -0.85,
			width = 2.6,
		}
	end,
	flat = function(c1, c2, c3)
		return {
			parts = {
				block(0.35, 1.0, 0.35, -0.6, 0.5, 0, c2),
				block(0.35, 1.0, 0.35, 0.6, 0.5, 0, c2),
				spec("Cylinder", v3(0.8, 3.2, 3.2), v3(0, 2.6, 0), c1, { rot = v3(0, 90, 0) }),
				block(2.2, 0.15, 0.05, 0, 2.2, -0.42, c3),
				block(2.2, 0.15, 0.05, 0, 3.0, -0.42, c3),
			},
			top = 4.2,
			faceY = 2.7,
			faceZ = -0.42,
			width = 3.2,
		}
	end,
}

-- Accessories sit on a frame: top of head, the face, or the sides.
local ACCESSORIES: { [string]: (f: Frame, c3: Color3) -> { PartSpec } } = {
	tophat = function(f, _c3)
		return {
			pillar(0.15, 2.0, 0, f.top + 0.05, 0, BLACK),
			pillar(1.3, 1.3, 0, f.top + 0.75, 0, BLACK),
			pillar(0.25, 1.32, 0, f.top + 0.35, 0, rgb(220, 40, 60), { keep = true }),
		}
	end,
	party = function(f, c3)
		return {
			pillar(0.5, 1.2, 0, f.top + 0.2, 0, c3, { keep = true }),
			pillar(0.5, 0.8, 0, f.top + 0.65, 0, rgb(255, 230, 70), { keep = true }),
			pillar(0.5, 0.4, 0, f.top + 1.1, 0, c3, { keep = true }),
			ball(0.4, 0, f.top + 1.45, 0, WHITE, { keep = true }),
		}
	end,
	crown = function(f, _c3)
		local gold = rgb(255, 205, 40)
		return {
			block(1.6, 0.4, 1.6, 0, f.top + 0.15, 0, gold, { material = Enum.Material.Metal, keep = true }),
			block(0.3, 0.6, 0.3, -0.6, f.top + 0.6, -0.6, gold, { material = Enum.Material.Metal, keep = true }),
			block(0.3, 0.6, 0.3, 0.6, f.top + 0.6, -0.6, gold, { material = Enum.Material.Metal, keep = true }),
			block(0.3, 0.6, 0.3, -0.6, f.top + 0.6, 0.6, gold, { material = Enum.Material.Metal, keep = true }),
			block(0.3, 0.6, 0.3, 0.6, f.top + 0.6, 0.6, gold, { material = Enum.Material.Metal, keep = true }),
			ball(0.35, 0, f.top + 0.2, -0.82, rgb(255, 40, 80), { material = Enum.Material.Neon, keep = true }),
		}
	end,
	chef = function(f, _c3)
		return {
			pillar(0.9, 1.4, 0, f.top + 0.4, 0, WHITE, { keep = true }),
			ball(1.7, 0, f.top + 1.1, 0, WHITE, { keep = true }),
		}
	end,
	cowboy = function(f, _c3)
		local brown = rgb(140, 85, 40)
		return {
			pillar(0.15, 2.8, 0, f.top + 0.05, 0, brown, { keep = true }),
			pillar(0.9, 1.5, 0, f.top + 0.5, 0, brown, { keep = true }),
		}
	end,
	propeller = function(f, c3)
		return {
			ball(1.3, 0, f.top - 0.1, 0, c3, { keep = true }),
			block(0.1, 0.5, 0.1, 0, f.top + 0.7, 0, BLACK, { keep = true }),
			block(2.0, 0.08, 0.35, 0, f.top + 0.95, 0, rgb(255, 60, 60), { keep = true }),
			block(0.35, 0.08, 2.0, 0, f.top + 0.95, 0, rgb(60, 140, 255), { keep = true }),
		}
	end,
	halo = function(f, _c3)
		return {
			wheel(0.12, 1.6, 0, f.top + 0.7, 0, rgb(255, 240, 120), { rot = v3(0, 0, 90), material = Enum.Material.Neon, keep = true }),
		}
	end,
	shades = function(f, _c3)
		return {
			block(1.7, 0.45, 0.15, 0, f.faceY + 0.05, f.faceZ - 0.2, BLACK, { keep = true }),
			block(1.9, 0.1, 0.1, 0, f.faceY + 0.25, f.faceZ - 0.2, BLACK, { keep = true }),
		}
	end,
	mustache = function(f, _c3)
		return {
			block(1.2, 0.25, 0.15, 0, f.faceY - 0.55, f.faceZ - 0.1, BLACK, { keep = true }),
			block(0.35, 0.25, 0.15, -0.65, f.faceY - 0.7, f.faceZ - 0.1, BLACK, { rot = v3(0, 0, 30), keep = true }),
			block(0.35, 0.25, 0.15, 0.65, f.faceY - 0.7, f.faceZ - 0.1, BLACK, { rot = v3(0, 0, -30), keep = true }),
		}
	end,
	clownnose = function(f, _c3)
		return { ball(0.6, 0, f.faceY - 0.4, f.faceZ - 0.25, rgb(255, 30, 40), { keep = true }) }
	end,
	bowtie = function(f, c3)
		return {
			block(0.6, 0.5, 0.2, -0.35, f.faceY - 1.0, f.faceZ, c3, { rot = v3(0, 0, 20), keep = true }),
			block(0.6, 0.5, 0.2, 0.35, f.faceY - 1.0, f.faceZ, c3, { rot = v3(0, 0, -20), keep = true }),
		}
	end,
	arms = function(f, c3)
		local half = f.width / 2 + 0.5
		return {
			block(1.2, 0.3, 0.3, -half, f.faceY - 0.6, 0, c3, { rot = v3(0, 0, 30) }),
			block(1.2, 0.3, 0.3, half, f.faceY - 0.6, 0, c3, { rot = v3(0, 0, -30) }),
			ball(0.5, -half - 0.55, f.faceY - 0.25, 0, WHITE, { keep = true }),
			ball(0.5, half + 0.55, f.faceY - 0.25, 0, WHITE, { keep = true }),
		}
	end,
	wings = function(f, c3)
		local half = f.width / 2 + 0.6
		return {
			block(0.2, 1.4, 2.0, -half, f.faceY, 0.5, c3, { rot = v3(0, 20, 30), material = Enum.Material.Neon, transparency = 0.2, keep = true }),
			block(0.2, 1.4, 2.0, half, f.faceY, 0.5, c3, { rot = v3(0, -20, -30), material = Enum.Material.Neon, transparency = 0.2, keep = true }),
		}
	end,
	rocket = function(f, _c3)
		local gray = rgb(160, 165, 175)
		return {
			spec("Cylinder", v3(1.6, 0.6, 0.6), v3(-0.7, f.faceY - 0.6, 1.4), gray, { rot = v3(0, 90, 0), keep = true }),
			spec("Cylinder", v3(1.6, 0.6, 0.6), v3(0.7, f.faceY - 0.6, 1.4), gray, { rot = v3(0, 90, 0), keep = true }),
			ball(0.6, -0.7, f.faceY - 0.6, 2.35, rgb(255, 120, 30), { material = Enum.Material.Neon, keep = true }),
			ball(0.6, 0.7, f.faceY - 0.6, 2.35, rgb(255, 120, 30), { material = Enum.Material.Neon, keep = true }),
		}
	end,
	cape = function(f, c3)
		return { block(f.width, 2.4, 0.15, 0, f.faceY - 1.0, 1.0, c3, { rot = v3(-10, 0, 0), keep = true }) }
	end,
	horn = function(f, _c3)
		return { block(0.35, 1.1, 0.35, 0, f.top + 0.3, f.faceZ * 0.6, rgb(255, 250, 230), { rot = v3(-20, 0, 0), keep = true }) }
	end,
	antenna = function(f, c3)
		return {
			block(0.1, 1.0, 0.1, -0.4, f.top + 0.4, 0, BLACK, { keep = true }),
			block(0.1, 1.0, 0.1, 0.4, f.top + 0.4, 0, BLACK, { keep = true }),
			ball(0.4, -0.4, f.top + 0.95, 0, c3, { material = Enum.Material.Neon, keep = true }),
			ball(0.4, 0.4, f.top + 0.95, 0, c3, { material = Enum.Material.Neon, keep = true }),
		}
	end,
	sack = function(f, _c3)
		return { ball(1.6, 0, f.faceY - 0.4, 1.3, rgb(170, 130, 80), { keep = true }) }
	end,
	tongue = function(f, _c3)
		return { block(0.45, 0.12, 0.7, 0, f.faceY - 0.7, f.faceZ - 0.3, rgb(240, 70, 110), { keep = true }) }
	end,
}

-- The full part list of a catalog entry: hand-built parts, or a recipe of body + accessories.
function BrainrotModels.partsFor(def: Brainrot): { PartSpec }
	local handBuilt = CastArt.parts[def.id]
	if handBuilt then
		return handBuilt
	end
	local recipe = assert(def.recipe, "brainrot " .. def.id .. " has neither parts nor recipe")
	local frame = BODIES[recipe.body](recipe.c1, recipe.c2, recipe.c3)
	local parts = table.clone(frame.parts)
	if recipe.eyes ~= false then
		addEyes(parts, frame.faceY + 0.3, frame.faceZ, 0.46, 0.68)
	end
	local acc = recipe.acc or {}
	if not table.find(acc, "mustache") and not table.find(acc, "tongue") then
		addMouth(parts, frame.faceY - 0.45, frame.faceZ, #def.id % 2 == 0)
	end
	for _, name in recipe.acc or {} do
		local make = ACCESSORIES[name]
		if make then
			for _, p in make(frame, recipe.c3) do
				table.insert(parts, p)
			end
		end
	end
	return parts
end

local SHAPES = {
	Ball = Enum.PartType.Ball,
	Block = Enum.PartType.Block,
	Cylinder = Enum.PartType.Cylinder,
}

local function finishColor(base: Color3, mutation: MutationRoller.Mutation?, index: number): Color3
	if not mutation then
		return base
	end
	if mutation.name == "Rainbow" then
		return Color3.fromHSV((index * 0.13) % 1, 0.75, 1)
	end
	return base:Lerp(mutation.color, 0.8)
end

local function heightOf(parts: { PartSpec }): number
	local top = 0
	for _, p in parts do
		top = math.max(top, p.pos.Y + p.size.Y / 2)
	end
	return top
end

-- A framed label card over the brainrot: mutation chip, name, rarity and money a second (and a price on
-- the belt), in a dark rounded card edged in the rarity colour so it reads against any background.
local function makeTag(def: Brainrot, mutationName: string?, height: number, extraLine: string?): BillboardGui
	local rarity = BrainrotCatalog.rarity(def.rarity)
	local mutation = MutationRoller.get(mutationName)
	local income = def.income * MutationRoller.multiplier(mutationName)

	local lines = 3 + (if mutation then 1 else 0) + (if extraLine then 1 else 0)
	-- Rarer brainrots get bigger cards, so the prizes stand out and the commons recede.
	local size = 0.72 + rarity.order * 0.09
	local lineStuds = 1.45 * size
	local gui = Instance.new("BillboardGui")
	gui.Name = "Tag"
	gui.Size = UDim2.fromScale(11.5 * size, lines * lineStuds + 0.7 * size)
	gui.StudsOffset = Vector3.new(0, height + (lines * lineStuds) / 2 + 1.2, 0)
	gui.MaxDistance = 125
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false

	local card = Instance.new("Frame")
	card.Name = "Card"
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = rgb(28, 14, 48)
	card.BackgroundTransparency = 0.18
	card.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.18, 0)
	corner.Parent = card
	local stroke = Instance.new("UIStroke")
	stroke.Color = rarity.color
	stroke.Thickness = 3
	stroke.Parent = card
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0.05, 0)
	padding.PaddingBottom = UDim.new(0.05, 0)
	padding.PaddingLeft = UDim.new(0.04, 0)
	padding.PaddingRight = UDim.new(0.04, 0)
	padding.Parent = card

	local list = Instance.new("UIListLayout")
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = card

	local function line(order: number, text: string, color: Color3, weight: number)
		local label = Instance.new("TextLabel")
		label.LayoutOrder = order
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, weight / lines)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.Text = text
		label.TextColor3 = color
		label.TextStrokeTransparency = 0.35
		label.TextStrokeColor3 = Color3.new(0, 0, 0)
		label.Parent = card
		return label
	end

	if mutation then
		line(0, mutation.tag .. " x" .. mutation.multiplier, mutation.color, 0.85)
	end
	line(1, def.name, Color3.new(1, 1, 1), 1.05)
	line(2, string.upper(def.rarity), rarity.color, 0.9)
	line(3, "+" .. GameConfig.perSecond(income), rgb(120, 255, 130), 1.05)
	if extraLine then
		line(4, extraLine, if string.find(extraLine, "STOLEN") then rgb(255, 80, 90) else rgb(255, 225, 80), 1.0)
	end
	return gui
end

-- Builds a Model whose PrimaryPart "Root" is an invisible, anchored plate at the feet; every other part
-- is welded to it, unanchored, massless and non-colliding, so moving Root moves the whole brainrot.
-- World brainrots stand this much larger than their catalog parts, so they read from across the Midway.
BrainrotModels.WORLD_SCALE = 2.2

function BrainrotModels.build(def: Brainrot, mutationName: string?, options: { tag: boolean?, priceLine: string?, scale: number? }?): Model
	local opts = options or {}
	local mutation = MutationRoller.get(mutationName)
	local parts = BrainrotModels.partsFor(def)
	local scale = def.scale * (opts.scale or BrainrotModels.WORLD_SCALE)

	local model = Instance.new("Model")
	model.Name = def.name

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(2, 0.2, 2)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = true
	root.CanTouch = false
	root.Parent = model
	model.PrimaryPart = root

	for index, p in parts do
		local part = Instance.new("Part")
		part.Shape = SHAPES[p.shape] or Enum.PartType.Block
		part.Size = p.size * scale
		part.Color = if p.keep then p.color else finishColor(p.color, mutation, index)
		part.Material = p.material or Enum.Material.SmoothPlastic
		if mutation and not p.keep and mutation.material then
			part.Material = mutation.material
		end
		if mutation and mutation.name == "Gold" and not p.keep then
			part.Reflectance = 0.25
		end
		part.Transparency = p.transparency or 0
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		local rot = p.rot or Vector3.zero
		part.CFrame = root.CFrame
			* CFrame.new(p.pos * scale)
			* CFrame.Angles(math.rad(rot.X), math.rad(rot.Y), math.rad(rot.Z))
		part.Anchored = false
		part.CanCollide = false
		part.CanTouch = false
		part.Massless = true
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = part
		weld.Parent = part
		part.Parent = model
	end

	local height = heightOf(parts) * scale
	model:SetAttribute("Height", height)
	model:SetAttribute("BrainrotId", def.id)
	model:SetAttribute("Mutation", mutationName or "")

	if mutation then
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Name = "MutationGlow"
		sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkle.Color = ColorSequence.new(mutation.color)
		sparkle.Rate = 6
		sparkle.Lifetime = NumberRange.new(0.6, 1.2)
		sparkle.Speed = NumberRange.new(1, 2)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.Size = NumberSequence.new(0.5)
		sparkle.LightEmission = 1
		sparkle.Parent = root
	end

	local rarity = BrainrotCatalog.rarity(def.rarity)
	if rarity.order >= 4 then
		local light = Instance.new("PointLight")
		light.Color = rarity.color
		light.Range = 10 + rarity.order * 2
		light.Brightness = 1.5
		light.Parent = root
	end

	if opts.tag ~= false then
		makeTag(def, mutationName, height, opts.priceLine).Parent = root
	end
	return model
end

-- Publishes a tagless preview of every brainrot to ReplicatedStorage.CastPreviews for the Index book.
function BrainrotModels.publishPreviews()
	local folder = Instance.new("Folder")
	folder.Name = "CastPreviews"
	for _, def in BrainrotCatalog.list do
		local model = BrainrotModels.build(def, nil, { tag = false, scale = 1 })
		model.Name = def.id
		model.Parent = folder
	end
	folder.Parent = ReplicatedStorage
end

-- Re-labels a model's price line (the conveyor shows prices, a pedestal does not).
function BrainrotModels.setPriceLine(model: Model, text: string?)
	local root = model.PrimaryPart
	if not root then
		return
	end
	local old = root:FindFirstChild("Tag")
	if old then
		old:Destroy()
	end
	local def = BrainrotCatalog.get(model:GetAttribute("BrainrotId") :: string)
	if not def then
		return
	end
	local mutation = model:GetAttribute("Mutation") :: string
	makeTag(def, if mutation == "" then nil else mutation, model:GetAttribute("Height") :: number, text).Parent = root
end

return BrainrotModels
