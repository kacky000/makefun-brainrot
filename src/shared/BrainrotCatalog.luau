--!strict
-- The ROT CARNIVAL cast: 36 brainrots on a ladder of 7 rarities, each with its price, income a second and quip.
-- How each one looks lives server-side (World.CastArt for the hand-built ones, a body recipe for the rest).

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

local BrainrotCatalog = {}

local byId: { [string]: Brainrot } = {}
local byRarity: { [string]: { Brainrot } } = {}
local rarityByName: { [string]: Rarity } = {}

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

-- A random brainrot: a rarity by weight, then one of that rarity's cast.
function BrainrotCatalog.rollBrainrot(luck: number, rng: Random, minOrder: number?, allowSecret: boolean?): Brainrot
	local rarity = BrainrotCatalog.rollRarity(luck, rng, minOrder, allowSecret)
	local pool = byRarity[rarity.name]
	return pool[rng:NextInteger(1, #pool)]
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


BrainrotCatalog.rarities = {
	{ name = "Common", color = rgb(215, 215, 215), weight = 55, order = 1, scale = 1 },
	{ name = "Rare", color = rgb(70, 160, 255), weight = 27, order = 2, scale = 1.06 },
	{ name = "Epic", color = rgb(190, 95, 255), weight = 11, order = 3, scale = 1.13 },
	{ name = "Legendary", color = rgb(255, 196, 40), weight = 5, order = 4, scale = 1.22 },
	{ name = "Mythic", color = rgb(255, 70, 80), weight = 1.6, order = 5, scale = 1.3 },
	{ name = "Cosmic", color = rgb(60, 245, 225), weight = 0.35, order = 6, scale = 1.4 },
	{ name = "Secret", color = rgb(255, 255, 255), weight = 0.05, order = 7, scale = 1.55 },
} :: { Rarity }


BrainrotCatalog.list = {
	{
		id = "toastolini",
		name = "Toastolini Toastolino",
		rarity = "Common",
		price = 25,
		income = 2,
		quip = "crunchy and unbothered",
	},
	{
		id = "pickle",
		name = "Pickle Pirouetto",
		rarity = "Common",
		price = 60,
		income = 4,
		quip = "spins until it is sour",
	},
	{
		id = "sockodile",
		name = "Sockodile Snoozo",
		rarity = "Common",
		price = 110,
		income = 6,
		quip = "a crocodile that lives in your laundry",
	},
	{
		id = "fridgoletto",
		name = "Frigoletto Fridgerino",
		rarity = "Rare",
		price = 700,
		income = 26,
		quip = "keeps the vibes at four degrees",
	},
	{
		id = "duckuccino",
		name = "Duckuccino Turbo",
		rarity = "Rare",
		price = 1000,
		income = 35,
		quip = "espresso-powered and legally a duck",
	},
	{
		id = "bananaconda",
		name = "Bananaconda Brrrum",
		rarity = "Epic",
		price = 5500,
		income = 140,
		quip = "a banana snake that only rides motorbikes",
	},
	{
		id = "moaistro",
		name = "Moaistro Rollerino",
		rarity = "Epic",
		price = 7500,
		income = 180,
		quip = "stone-faced, roller-skating, DJ-ing",
	},
	{
		id = "cactus",
		name = "Cactus Cowabungo",
		rarity = "Legendary",
		price = 40000,
		income = 700,
		quip = "yeehaw but spiky",
	},
	{
		id = "toiletronaut",
		name = "Toiletronaut Supremo",
		rarity = "Legendary",
		price = 60000,
		income = 950,
		quip = "first toilet on the moon, will not stop telling you",
	},
	{
		id = "sushi",
		name = "Sushi Shogunetto",
		rarity = "Mythic",
		price = 260000,
		income = 3500,
		quip = "honour, rice and a very small sword",
	},
	{
		id = "goldfish",
		name = "Goldfish Gigantino",
		rarity = "Mythic",
		price = 380000,
		income = 4800,
		quip = "skipped fin day, never leg day",
	},
	{
		id = "lavalampo",
		name = "Lavalampo Lunatico",
		rarity = "Cosmic",
		price = 1800000,
		income = 18000,
		quip = "groovy blobs, zero thoughts",
	},
	{
		id = "discodino",
		name = "Discoball Dinosauro",
		rarity = "Cosmic",
		price = 2700000,
		income = 25000,
		quip = "extinct? no. booked every weekend",
	},
	{
		id = "wobblegel",
		name = "Lord Wobblegel",
		rarity = "Secret",
		price = 12000000,
		income = 90000,
		quip = "the jelly that rules the surge",
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

for _, rarity in BrainrotCatalog.rarities do
	rarityByName[rarity.name] = rarity
	byRarity[rarity.name] = {}
end
for _, brainrot in BrainrotCatalog.list do
	byId[brainrot.id] = brainrot
	table.insert(byRarity[brainrot.rarity], brainrot)
end

return BrainrotCatalog
