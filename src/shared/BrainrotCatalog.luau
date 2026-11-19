--!strict
-- The ROT CARNIVAL cast: every character's name, rarity, price, income a second and the parts it is built from.
-- Front of every character is local -Z; y = 0 is the ground under its feet.

export type PartSpec = {
	shape: string, -- "Block" | "Ball" | "Cylinder" | "Wedge"
	size: Vector3,
	pos: Vector3,
	color: Color3,
	material: Enum.Material?,
	rot: Vector3?, -- degrees
	transparency: number?,
	keep: boolean?, -- keeps its own colour under a mutation (eyes, mouths, glow)
}

-- A recipe builds a brainrot from a body archetype, three colours and accessories (see BrainrotModels).
export type Recipe = {
	body: string,
	c1: Color3,
	c2: Color3,
	c3: Color3,
	acc: { string }?,
	eyes: boolean?,
}

export type Brainrot = {
	id: string,
	name: string,
	rarity: string,
	price: number,
	income: number,
	scale: number,
	quip: string,
	parts: { PartSpec }?,
	recipe: Recipe?,
}

export type Rarity = {
	name: string,
	color: Color3,
	weight: number,
	order: number,
	scale: number,
}

local rgb = Color3.fromRGB
local v3 = Vector3.new

local function block(sx, sy, sz, x, y, z, color, extra: { [string]: any }?): PartSpec
	local spec: any = { shape = "Block", size = v3(sx, sy, sz), pos = v3(x, y, z), color = color }
	if extra then
		for key, value in extra do
			spec[key] = value
		end
	end
	return spec
end

local function ball(d, x, y, z, color, extra: { [string]: any }?): PartSpec
	local spec = block(d, d, d, x, y, z, color, extra)
	spec.shape = "Ball"
	return spec
end

-- An upright cylinder: height along Y.
local function pillar(height, diameter, x, y, z, color, extra: { [string]: any }?): PartSpec
	local spec = block(height, diameter, diameter, x, y, z, color, extra)
	spec.shape = "Cylinder"
	spec.rot = v3(0, 0, 90)
	return spec
end

-- A cylinder lying along X (a wheel seen from the side, a log across).
local function wheel(width, diameter, x, y, z, color, extra: { [string]: any }?): PartSpec
	local spec = block(width, diameter, diameter, x, y, z, color, extra)
	spec.shape = "Cylinder"
	return spec
end

-- A cylinder lying along Z (a rocket, a tail).
local function tube(length, diameter, x, y, z, color, extra: { [string]: any }?): PartSpec
	local spec = block(length, diameter, diameter, x, y, z, color, extra)
	spec.shape = "Cylinder"
	spec.rot = v3(0, 90, 0)
	return spec
end

-- Two googly eyes on the front face at height y, surface z.
local function eyes(y, z, spacing, size): { PartSpec }
	local white = rgb(255, 255, 255)
	local black = rgb(20, 20, 25)
	return {
		ball(size, -spacing, y, z, white, { keep = true }),
		ball(size, spacing, y, z, white, { keep = true }),
		ball(size * 0.5, -spacing + size * 0.08, y - size * 0.05, z - size * 0.32, black, { keep = true }),
		ball(size * 0.5, spacing - size * 0.08, y + size * 0.06, z - size * 0.32, black, { keep = true }),
	}
end

local function join(...: { PartSpec }): { PartSpec }
	local out = {}
	for _, list in { ... } do
		for _, spec in list do
			table.insert(out, spec)
		end
	end
	return out
end

local BrainrotCatalog = {}

BrainrotCatalog.rarities = {
	{ name = "Common", color = rgb(215, 215, 215), weight = 55, order = 1, scale = 1 },
	{ name = "Rare", color = rgb(70, 160, 255), weight = 27, order = 2, scale = 1.06 },
	{ name = "Epic", color = rgb(190, 95, 255), weight = 11, order = 3, scale = 1.13 },
	{ name = "Legendary", color = rgb(255, 196, 40), weight = 5, order = 4, scale = 1.22 },
	{ name = "Mythic", color = rgb(255, 70, 80), weight = 1.6, order = 5, scale = 1.3 },
	{ name = "Cosmic", color = rgb(60, 245, 225), weight = 0.35, order = 6, scale = 1.4 },
	{ name = "Secret", color = rgb(255, 255, 255), weight = 0.05, order = 7, scale = 1.55 },
} :: { Rarity }

local TOAST = rgb(226, 172, 92)
local CRUST = rgb(150, 95, 45)
local WHITE = rgb(240, 240, 240)
local BLACK = rgb(25, 25, 30)

BrainrotCatalog.list = {
	{
		id = "toastolini",
		name = "Toastolini Toastolino",
		rarity = "Common",
		price = 25,
		income = 2,
		quip = "crunchy and unbothered",
		parts = join({
			block(0.4, 1.2, 0.4, -0.5, 0.6, 0, CRUST),
			block(0.4, 1.2, 0.4, 0.5, 0.6, 0, CRUST),
			block(2.7, 2.9, 0.7, 0, 2.6, 0.08, CRUST),
			block(2.4, 2.6, 0.8, 0, 2.6, 0, TOAST),
			block(1.0, 0.9, 0.12, 0.35, 2.1, -0.45, rgb(255, 228, 110)),
			block(1.2, 0.3, 0.3, -1.85, 2.7, 0, CRUST, { rot = v3(0, 0, 25) }),
			block(1.2, 0.3, 0.3, 1.85, 2.7, 0, CRUST, { rot = v3(0, 0, -25) }),
			block(0.7, 0.15, 0.1, 0, 2.75, -0.45, BLACK, { keep = true }),
		}, eyes(3.3, -0.42, 0.5, 0.55)),
	},
	{
		id = "pickle",
		name = "Pickle Pirouetto",
		rarity = "Common",
		price = 60,
		income = 4,
		quip = "spins until it is sour",
		parts = join({
			block(0.25, 1.3, 0.25, -0.3, 0.65, 0, WHITE),
			block(0.25, 1.3, 0.25, 0.3, 0.65, 0, WHITE),
			pillar(3.4, 1.6, 0, 2.9, 0, rgb(96, 160, 62)),
			ball(1.6, 0, 4.55, 0, rgb(96, 160, 62)),
			wheel(0.3, 3.4, 0, 1.75, 0, rgb(255, 140, 205), { rot = v3(0, 0, 90) }),
			ball(0.35, 0.55, 3.0, -0.7, rgb(70, 130, 45)),
			ball(0.3, -0.5, 2.3, -0.72, rgb(70, 130, 45)),
			block(0.25, 1.5, 0.25, -1.0, 4.0, 0, rgb(96, 160, 62), { rot = v3(0, 0, 25) }),
			block(0.25, 1.5, 0.25, 1.0, 4.0, 0, rgb(96, 160, 62), { rot = v3(0, 0, -25) }),
		}, eyes(3.9, -0.72, 0.38, 0.5)),
	},
	{
		id = "sockodile",
		name = "Sockodile Snoozo",
		rarity = "Common",
		price = 110,
		income = 6,
		quip = "a crocodile that lives in your laundry",
		parts = join({
			block(1.5, 1.5, 3.8, 0, 1.0, 0.4, rgb(220, 60, 60)),
			block(1.55, 1.55, 0.4, 0, 1.0, -0.6, WHITE),
			block(1.55, 1.55, 0.4, 0, 1.0, 0.6, WHITE),
			block(1.55, 1.55, 0.4, 0, 1.0, 1.8, WHITE),
			block(1.3, 0.7, 1.6, 0, 0.75, -2.2, rgb(80, 160, 70)),
			block(1.1, 0.15, 1.4, 0, 0.35, -2.2, WHITE, { keep = true }),
			block(1.2, 0.7, 1.2, 0, 2.0, -0.9, rgb(60, 90, 220), { rot = v3(-20, 0, 0) }),
			ball(0.6, 0, 2.5, -0.2, WHITE),
		}, eyes(1.95, -1.55, 0.4, 0.55)),
	},
	{
		id = "fridgoletto",
		name = "Frigoletto Fridgerino",
		rarity = "Rare",
		price = 700,
		income = 26,
		quip = "keeps the vibes at four degrees",
		parts = join({
			block(0.45, 0.5, 0.45, -0.8, 0.25, 0, BLACK),
			block(0.45, 0.5, 0.45, 0.8, 0.25, 0, BLACK),
			block(2.4, 4.2, 2.0, 0, 2.6, 0, rgb(236, 240, 245)),
			block(2.42, 0.1, 2.02, 0, 3.4, 0, rgb(150, 160, 170)),
			block(0.2, 1.1, 0.2, 0.9, 2.5, -1.05, rgb(150, 160, 170)),
			block(1.3, 0.28, 0.2, 0, 3.75, -1.05, BLACK, { keep = true }),
			ball(0.45, -0.6, 2.2, -1.05, rgb(255, 80, 80), { keep = true }),
			ball(0.4, -0.2, 1.7, -1.05, rgb(80, 200, 120), { keep = true }),
			block(1.2, 0.25, 0.25, -1.7, 3.0, 0, rgb(236, 240, 245), { rot = v3(0, 0, 30) }),
			block(1.2, 0.25, 0.25, 1.7, 3.0, 0, rgb(236, 240, 245), { rot = v3(0, 0, -30) }),
		}, eyes(4.2, -1.02, 0.5, 0.55)),
	},
	{
		id = "duckuccino",
		name = "Duckuccino Turbo",
		rarity = "Rare",
		price = 1000,
		income = 35,
		quip = "espresso-powered and legally a duck",
		parts = join({
			pillar(1.8, 2.4, 0, 0.9, 0, WHITE),
			pillar(0.1, 2.2, 0, 1.82, 0, rgb(110, 65, 35)),
			wheel(0.25, 1.2, 1.3, 1.0, 0, WHITE),
			ball(2.0, 0, 2.5, 0, rgb(255, 215, 50)),
			ball(1.4, 0, 3.7, -0.3, rgb(255, 215, 50)),
			block(0.7, 0.25, 0.6, 0, 3.55, -1.15, rgb(255, 140, 30)),
			tube(1.6, 0.6, -0.9, 2.5, 1.1, rgb(160, 165, 175)),
			tube(1.6, 0.6, 0.9, 2.5, 1.1, rgb(160, 165, 175)),
			ball(0.6, -0.9, 2.5, 2.05, rgb(255, 120, 30), { material = Enum.Material.Neon, keep = true }),
			ball(0.6, 0.9, 2.5, 2.05, rgb(255, 120, 30), { material = Enum.Material.Neon, keep = true }),
		}, eyes(3.9, -0.92, 0.32, 0.42)),
	},
	{
		id = "bananaconda",
		name = "Bananaconda Brrrum",
		rarity = "Epic",
		price = 5500,
		income = 140,
		quip = "a banana snake that only rides motorbikes",
		parts = join({
			wheel(0.5, 1.5, 0, 0.75, -1.7, BLACK),
			wheel(0.5, 1.5, 0, 0.75, 1.7, BLACK),
			block(0.5, 0.4, 3.6, 0, 1.2, 0, rgb(200, 30, 40)),
			tube(4.2, 1.3, 0, 1.9, 0.2, rgb(255, 225, 60)),
			ball(1.7, 0, 2.7, -2.0, rgb(255, 225, 60)),
			block(0.4, 0.4, 0.6, 0, 2.1, 2.5, rgb(90, 60, 30)),
			block(2.2, 0.2, 0.2, 0, 2.5, -1.3, rgb(170, 170, 180)),
			block(0.2, 0.1, 0.7, 0, 2.35, -2.95, rgb(230, 40, 60), { keep = true }),
		}, eyes(3.05, -2.7, 0.42, 0.5)),
	},
	{
		id = "moaistro",
		name = "Moaistro Rollerino",
		rarity = "Epic",
		price = 7500,
		income = 180,
		quip = "stone-faced, roller-skating, DJ-ing",
		parts = join({
			block(0.9, 0.5, 1.7, -0.6, 0.55, 0, rgb(255, 110, 180)),
			block(0.9, 0.5, 1.7, 0.6, 0.55, 0, rgb(255, 110, 180)),
			wheel(0.3, 0.45, -0.6, 0.2, -0.55, rgb(255, 230, 60), { keep = true }),
			wheel(0.3, 0.45, -0.6, 0.2, 0.55, rgb(255, 230, 60), { keep = true }),
			wheel(0.3, 0.45, 0.6, 0.2, -0.55, rgb(255, 230, 60), { keep = true }),
			wheel(0.3, 0.45, 0.6, 0.2, 0.55, rgb(255, 230, 60), { keep = true }),
			block(2.4, 3.8, 2.0, 0, 2.75, 0, rgb(125, 120, 115), { material = Enum.Material.Slate }),
			block(2.5, 0.5, 0.6, 0, 3.95, -0.95, rgb(105, 100, 95), { material = Enum.Material.Slate }),
			block(0.6, 1.5, 0.7, 0, 3.0, -1.2, rgb(115, 110, 105), { material = Enum.Material.Slate }),
			block(1.2, 0.2, 0.3, 0, 1.75, -1.05, BLACK, { keep = true }),
			wheel(0.4, 1.3, -1.35, 3.5, 0, rgb(230, 40, 60)),
			wheel(0.4, 1.3, 1.35, 3.5, 0, rgb(230, 40, 60)),
			block(2.9, 0.25, 0.3, 0, 4.75, 0, BLACK),
		}, eyes(3.55, -1.02, 0.55, 0.45)),
	},
	{
		id = "cactus",
		name = "Cactus Cowabungo",
		rarity = "Legendary",
		price = 40000,
		income = 700,
		quip = "yeehaw but spiky",
		parts = join({
			pillar(4.0, 1.8, 0, 2.2, 0, rgb(70, 165, 80)),
			block(0.9, 0.55, 0.55, -1.1, 2.4, 0, rgb(70, 165, 80)),
			block(0.9, 0.55, 0.55, 1.1, 2.4, 0, rgb(70, 165, 80)),
			pillar(1.5, 0.7, -1.5, 3.0, 0, rgb(70, 165, 80)),
			pillar(1.5, 0.7, 1.5, 3.0, 0, rgb(70, 165, 80)),
			pillar(0.15, 3.4, 0, 4.3, 0, rgb(140, 85, 40)),
			pillar(1.0, 1.8, 0, 4.85, 0, rgb(140, 85, 40)),
			ball(0.6, 0.7, 4.6, -0.85, rgb(255, 80, 170), { material = Enum.Material.Neon, keep = true }),
			block(1.7, 0.45, 0.2, 0, 3.45, -0.95, BLACK, { keep = true }),
			block(0.8, 0.12, 0.12, 0, 2.75, -0.92, BLACK, { keep = true }),
			block(1.0, 0.18, 0.18, 0, 0.25, -0.2, rgb(140, 85, 40)),
		}),
	},
	{
		id = "toiletronaut",
		name = "Toiletronaut Supremo",
		rarity = "Legendary",
		price = 60000,
		income = 950,
		quip = "first toilet on the moon, will not stop telling you",
		parts = join({
			pillar(1.6, 2.2, 0, 0.8, 0, WHITE),
			pillar(0.25, 2.5, 0, 1.75, 0, rgb(230, 230, 235)),
			block(2.2, 2.1, 0.8, 0, 2.6, 0.95, WHITE),
			ball(3.8, 0, 2.3, 0.2, rgb(170, 220, 255), { material = Enum.Material.Glass, transparency = 0.65, keep = true }),
			block(0.12, 1.0, 0.12, 0, 4.6, 0.2, rgb(170, 170, 180)),
			ball(0.4, 0, 5.15, 0.2, rgb(255, 50, 60), { material = Enum.Material.Neon, keep = true }),
			block(0.9, 0.18, 0.1, 0, 2.15, 0.53, BLACK, { keep = true }),
		}, eyes(2.95, 0.52, 0.42, 0.5)),
	},
	{
		id = "sushi",
		name = "Sushi Shogunetto",
		rarity = "Mythic",
		price = 260000,
		income = 3500,
		quip = "honour, rice and a very small sword",
		parts = join({
			block(3.0, 1.4, 1.8, 0, 0.8, 0, rgb(250, 250, 245)),
			block(3.2, 0.6, 2.0, 0, 1.8, 0, rgb(250, 125, 85)),
			block(0.25, 0.62, 2.02, -0.8, 1.8, 0, rgb(255, 210, 190)),
			block(0.25, 0.62, 2.02, 0.8, 1.8, 0, rgb(255, 210, 190)),
			block(0.8, 1.55, 1.95, 0, 1.2, 0, rgb(30, 55, 35)),
			block(2.2, 0.45, 1.6, 0, 2.35, 0, rgb(150, 25, 30)),
			block(0.25, 1.0, 0.25, -0.7, 2.9, -0.5, rgb(255, 200, 40), { rot = v3(0, 0, 25), material = Enum.Material.Metal }),
			block(0.25, 1.0, 0.25, 0.7, 2.9, -0.5, rgb(255, 200, 40), { rot = v3(0, 0, -25), material = Enum.Material.Metal }),
			block(0.15, 0.15, 3.0, 1.9, 1.6, 0, rgb(210, 215, 225), { rot = v3(35, 0, 0), material = Enum.Material.Metal }),
		}, eyes(1.85, -1.05, 0.5, 0.48)),
	},
	{
		id = "goldfish",
		name = "Goldfish Gigantino",
		rarity = "Mythic",
		price = 380000,
		income = 4800,
		quip = "skipped fin day, never leg day",
		parts = join({
			block(0.6, 1.4, 0.6, -0.6, 0.7, 0, rgb(50, 90, 200)),
			block(0.6, 1.4, 0.6, 0.6, 0.7, 0, rgb(50, 90, 200)),
			block(0.8, 0.4, 1.0, -0.6, 0.2, -0.15, WHITE),
			block(0.8, 0.4, 1.0, 0.6, 0.2, -0.15, WHITE),
			ball(3.0, 0, 2.7, 0, rgb(255, 140, 30)),
			block(0.3, 2.0, 1.4, 0, 2.8, 1.9, rgb(255, 110, 20), { rot = v3(20, 0, 0) }),
			block(0.9, 0.9, 1.8, -1.9, 2.6, -0.3, rgb(255, 140, 30)),
			block(0.9, 0.9, 1.8, 1.9, 2.6, -0.3, rgb(255, 140, 30)),
			ball(1.1, -1.9, 2.6, -1.3, rgb(255, 140, 30)),
			ball(1.1, 1.9, 2.6, -1.3, rgb(255, 140, 30)),
			block(1.9, 0.18, 0.18, 0, 2.0, -1.25, rgb(255, 215, 40), { material = Enum.Material.Neon, keep = true }),
			block(0.6, 0.25, 0.2, 0, 2.4, -1.45, BLACK, { keep = true }),
		}, eyes(3.25, -1.25, 0.6, 0.75)),
	},
	{
		id = "lavalampo",
		name = "Lavalampo Lunatico",
		rarity = "Cosmic",
		price = 1800000,
		income = 18000,
		quip = "groovy blobs, zero thoughts",
		parts = join({
			pillar(1.2, 1.7, 0, 0.6, 0, rgb(190, 190, 200), { material = Enum.Material.Metal }),
			pillar(3.0, 1.6, 0, 2.7, 0, rgb(170, 60, 255), { material = Enum.Material.Neon, transparency = 0.35 }),
			ball(0.9, 0.2, 2.1, 0, rgb(255, 140, 30), { material = Enum.Material.Neon, keep = true }),
			ball(0.7, -0.2, 3.3, 0, rgb(255, 90, 60), { material = Enum.Material.Neon, keep = true }),
			pillar(0.8, 1.2, 0, 4.6, 0, rgb(190, 190, 200), { material = Enum.Material.Metal }),
			block(0.7, 0.15, 0.1, 0, 2.55, -0.82, BLACK, { keep = true }),
		}, eyes(3.0, -0.82, 0.35, 0.45)),
	},
	{
		id = "discodino",
		name = "Discoball Dinosauro",
		rarity = "Cosmic",
		price = 2700000,
		income = 25000,
		quip = "extinct? no. booked every weekend",
		parts = join({
			block(0.7, 1.3, 0.7, -0.6, 0.65, 0.3, rgb(80, 190, 90)),
			block(0.7, 1.3, 0.7, 0.6, 0.65, 0.3, rgb(80, 190, 90)),
			block(2.0, 2.0, 3.0, 0, 2.2, 0.3, rgb(80, 190, 90)),
			block(0.9, 0.9, 2.6, 0, 1.8, 2.6, rgb(80, 190, 90), { rot = v3(15, 0, 0) }),
			block(0.8, 1.6, 0.8, 0, 3.4, -0.9, rgb(80, 190, 90)),
			ball(2.6, 0, 4.6, -1.3, rgb(220, 225, 235), { material = Enum.Material.Foil }),
			block(0.4, 0.4, 0.1, -0.5, 5.2, -2.5, rgb(255, 60, 200), { material = Enum.Material.Neon, keep = true }),
			block(0.4, 0.4, 0.1, 0.6, 4.0, -2.5, rgb(60, 220, 255), { material = Enum.Material.Neon, keep = true }),
			block(0.4, 0.4, 0.1, 0.8, 5.0, -2.45, rgb(255, 230, 60), { material = Enum.Material.Neon, keep = true }),
		}, eyes(4.7, -2.55, 0.5, 0.5)),
	},
	{
		id = "wobblegel",
		name = "Lord Wobblegel",
		rarity = "Secret",
		price = 12000000,
		income = 90000,
		quip = "the jelly that rules the surge",
		parts = join({
			block(4.0, 4.0, 4.0, 0, 2.0, 0, rgb(90, 255, 160), { material = Enum.Material.Glass, transparency = 0.3 }),
			ball(1.6, 0, 2.0, 0, rgb(255, 90, 200), { material = Enum.Material.Neon, keep = true }),
			block(2.6, 0.5, 2.6, 0, 4.25, 0, rgb(255, 205, 40), { material = Enum.Material.Metal, keep = true }),
			block(0.4, 0.9, 0.4, -1.1, 4.9, -1.1, rgb(255, 205, 40), { material = Enum.Material.Metal, keep = true }),
			block(0.4, 0.9, 0.4, 1.1, 4.9, -1.1, rgb(255, 205, 40), { material = Enum.Material.Metal, keep = true }),
			block(0.4, 0.9, 0.4, -1.1, 4.9, 1.1, rgb(255, 205, 40), { material = Enum.Material.Metal, keep = true }),
			block(0.4, 0.9, 0.4, 1.1, 4.9, 1.1, rgb(255, 205, 40), { material = Enum.Material.Metal, keep = true }),
			block(1.4, 0.25, 0.1, 0, 1.6, -2.05, BLACK, { keep = true }),
		}, eyes(2.8, -2.05, 0.7, 0.8)),
	},
} :: { Brainrot }

-- The rest of the cast, built from recipes: id, name, rarity, price, income, quip, body, c1, c2, c3, accessories.
local RECIPES = {
	{ "cornetto", "Cornetto Carousello", "Common", 160, 8, "a corn cob that never gets off the ride", "can", rgb(255, 215, 60), rgb(90, 170, 60), rgb(240, 120, 40), { "party", "arms" } },
	{ "ticketto", "Ticketto Tacotto", "Common", 230, 11, "admit one (1) taco", "flat", rgb(240, 190, 90), rgb(120, 80, 40), rgb(90, 200, 80), { "wings", "tongue" } },
	{ "balloona", "Balloona Bassotto", "Common", 320, 14, "a balloon dog with a fear of pins", "quad", rgb(255, 80, 130), rgb(230, 60, 100), rgb(255, 255, 255), { "party" } },
	{ "napkinini", "Napkinini Ninja", "Common", 450, 18, "silent, absorbent, deadly", "box", rgb(250, 250, 250), rgb(40, 40, 50), rgb(220, 40, 60), { "cape", "shades" } },
	{ "pretzelino", "Pretzelino Pistolero", "Rare", 1400, 46, "the twistiest draw in the west", "stack", rgb(190, 120, 50), rgb(210, 140, 60), rgb(240, 240, 240), { "cowboy", "mustache", "arms" } },
	{ "cottoncamelo", "Cottoncandy Camelo", "Rare", 2000, 60, "two humps, both sugar", "quad", rgb(255, 170, 220), rgb(200, 150, 110), rgb(170, 210, 255), { "party", "tongue" } },
	{ "gummygorillo", "Gummy Gorillo", "Rare", 2800, 78, "chewy, angry, adorable", "blob", rgb(255, 60, 90), rgb(200, 40, 70), rgb(255, 220, 80), { "arms", "bowtie" } },
	{ "jukejelly", "Jukebox Jellyfisho", "Rare", 3800, 100, "plays one song, forever", "can", rgb(180, 90, 255), rgb(255, 140, 220), rgb(60, 230, 255), { "antenna", "bowtie" } },
	{ "wafflewalrus", "Waffle Walrusso", "Epic", 10000, 230, "syrup-tusked gentleman", "flat", rgb(230, 170, 80), rgb(150, 100, 60), rgb(255, 250, 240), { "mustache", "tophat", "arms" } },
	{ "teacuppa", "Teacuppa Typhoono", "Epic", 14000, 300, "the spinning-cup ride became sentient", "cone", rgb(120, 200, 255), rgb(240, 240, 250), rgb(255, 100, 140), { "propeller" } },
	{ "clownfishino", "Clownfish Clownino", "Epic", 19000, 380, "honk honk, blub blub", "fish", rgb(255, 130, 30), rgb(255, 255, 255), rgb(40, 40, 40), { "clownnose", "party" } },
	{ "hotdogcopter", "Hotdog Helicoptero", "Epic", 26000, 480, "relish-powered rotor", "car", rgb(210, 110, 60), rgb(240, 190, 110), rgb(255, 220, 40), { "propeller", "shades" } },
	{ "ferrisfrog", "Ferriswheel Frogatto", "Legendary", 85000, 1300, "ribbit, round and round", "blob", rgb(90, 200, 90), rgb(60, 150, 60), rgb(255, 90, 200), { "halo", "tongue", "arms" } },
	{ "popcornelius", "Popcornelius Maximus", "Legendary", 120000, 1750, "emperor of the bucket", "can", rgb(230, 40, 50), rgb(255, 255, 255), rgb(255, 240, 180), { "crown", "cape" } },
	{ "bumperbulldog", "Bumpercar Bulldoggo", "Legendary", 170000, 2400, "bonks first, asks never", "car", rgb(60, 140, 255), rgb(180, 140, 100), rgb(255, 220, 40), { "antenna", "tongue" } },
	{ "ringrhino", "Ringmaster Rhinoccino", "Mythic", 550000, 6600, "ladies, gentlemen and brainrots", "quad", rgb(150, 150, 165), rgb(120, 120, 135), rgb(220, 30, 50), { "tophat", "horn", "cape" } },
	{ "lollilobster", "Lollipop Lobsterone", "Mythic", 800000, 9000, "pinchy and sticky", "stack", rgb(240, 60, 60), rgb(255, 120, 200), rgb(255, 255, 255), { "arms", "antenna", "crown" } },
	{ "fortunetoad", "Fortunetella Toadini", "Mythic", 1150000, 12500, "sees your future: more brainrots", "blob", rgb(110, 70, 180), rgb(80, 170, 90), rgb(60, 230, 255), { "chef", "halo", "mustache" } },
	{ "saturnsundae", "Saturno Sundaeo", "Cosmic", 4000000, 35000, "a sundae with its own rings", "cone", rgb(255, 180, 220), rgb(200, 150, 90), rgb(255, 60, 80), { "halo", "wings" } },
	{ "coasterraptor", "Rollercoaster Raptorini", "Cosmic", 6000000, 48000, "keep your arms inside the dinosaur", "car", rgb(255, 60, 60), rgb(90, 200, 90), rgb(255, 230, 60), { "horn", "rocket", "tongue" } },
	{ "kernelking", "King Kernelcorn", "Secret", 25000000, 170000, "the first kernel that ever popped", "blob", rgb(255, 245, 200), rgb(255, 200, 60), rgb(255, 90, 40), { "crown", "cape", "shades" } },
	{ "grandprize", "Trofeo Infinito", "Secret", 60000000, 380000, "the grand prize, and it knows it", "can", rgb(255, 205, 40), rgb(255, 180, 30), rgb(60, 230, 255), { "wings", "halo", "arms" } },
}

for _, r in RECIPES do
	table.insert(BrainrotCatalog.list, {
		id = r[1],
		name = r[2],
		rarity = r[3],
		price = r[4],
		income = r[5],
		quip = r[6],
		scale = 1,
		recipe = { body = r[7], c1 = r[8], c2 = r[9], c3 = r[10], acc = r[11] },
	} :: any)
end

local rarityOrder: { [string]: number } = {}
for _, rarity in BrainrotCatalog.rarities do
	rarityOrder[rarity.name] = rarity.order
end
for _, brainrot in BrainrotCatalog.list do
	for _, rarity in BrainrotCatalog.rarities do
		if rarity.name == brainrot.rarity then
			brainrot.scale = rarity.scale
		end
	end
end
-- The Index book and the belt read the cast cheapest first.
table.sort(BrainrotCatalog.list, function(a, b)
	return a.price < b.price
end)

BrainrotCatalog.COUNT = #BrainrotCatalog.list

local byId: { [string]: Brainrot } = {}
local byRarity: { [string]: { Brainrot } } = {}
local rarityByName: { [string]: Rarity } = {}

for _, rarity in BrainrotCatalog.rarities do
	rarityByName[rarity.name] = rarity
	byRarity[rarity.name] = {}
end
for _, brainrot in BrainrotCatalog.list do
	byId[brainrot.id] = brainrot
	table.insert(byRarity[brainrot.rarity], brainrot)
end

function BrainrotCatalog.get(id: string): Brainrot?
	return byId[id]
end

function BrainrotCatalog.rarity(name: string): Rarity
	return rarityByName[name]
end

function BrainrotCatalog.ofRarity(name: string): { Brainrot }
	return byRarity[name]
end

-- Picks a rarity by weight. luck > 1 shifts weight toward the rarer end; minOrder skips the low tiers.
function BrainrotCatalog.rollRarity(luck: number, rng: Random, minOrder: number?, allowSecret: boolean?): Rarity
	local floor = minOrder or 1
	local total = 0
	local weights = {}
	for _, rarity in BrainrotCatalog.rarities do
		local weight = 0
		if rarity.order >= floor and (rarity.name ~= "Secret" or allowSecret) then
			weight = rarity.weight * (luck ^ (rarity.order - 1))
		end
		weights[rarity.name] = weight
		total += weight
	end
	local pick = rng:NextNumber() * total
	for _, rarity in BrainrotCatalog.rarities do
		pick -= weights[rarity.name]
		if pick <= 0 and weights[rarity.name] > 0 then
			return rarity
		end
	end
	return BrainrotCatalog.rarities[floor]
end

function BrainrotCatalog.rollBrainrot(luck: number, rng: Random, minOrder: number?, allowSecret: boolean?): Brainrot
	local rarity = BrainrotCatalog.rollRarity(luck, rng, minOrder, allowSecret)
	local pool = byRarity[rarity.name]
	return pool[rng:NextInteger(1, #pool)]
end

return BrainrotCatalog
