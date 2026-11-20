-- BrainrotCatalog: the cast. 36 original carnival brainrots on a ladder of 7 rarities, each with a price and money a second.
local BrainrotCatalog = {}

BrainrotCatalog.RARITIES = {
	{ key = "Common", weight = 46, color = Color3.fromRGB(190, 196, 204), scale = 1 },
	{ key = "Uncommon", weight = 26, color = Color3.fromRGB(90, 220, 110), scale = 1.08 },
	{ key = "Rare", weight = 14, color = Color3.fromRGB(70, 150, 255), scale = 1.18 },
	{ key = "Epic", weight = 7.5, color = Color3.fromRGB(190, 90, 255), scale = 1.3 },
	{ key = "Legendary", weight = 4.2, color = Color3.fromRGB(255, 170, 40), scale = 1.45 },
	{ key = "Mythic", weight = 1.7, color = Color3.fromRGB(255, 70, 90), scale = 1.62 },
	{ key = "Secret", weight = 0.6, color = Color3.fromRGB(255, 255, 255), scale = 1.85 },
}

local rarityByKey = {}
for order, rarity in BrainrotCatalog.RARITIES do
	rarity.order = order
	rarityByKey[rarity.key] = rarity
end

-- Pick a rarity off the ladder. luck (rebirths) fattens the rare end and thins the common end.
function BrainrotCatalog.rollRarity(luck: number?, random: Random?): string
	local rng = random or Random.new()
	local boost = luck or 1
	local total = 0
	local weights = {}
	for order, rarity in BrainrotCatalog.RARITIES do
		local weight = rarity.weight * boost ^ ((order - 1) * 0.5)
		weights[order] = weight
		total += weight
	end
	local roll = rng:NextNumber() * total
	for order, weight in weights do
		roll -= weight
		if roll <= 0 then
			return BrainrotCatalog.RARITIES[order].key
		end
	end
	return "Common"
end

local function c(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

BrainrotCatalog.ENTRIES = {}
BrainrotCatalog.byId = {}
local byRarity = {}

-- look: body shape, three colours (main, second, accent) and the props bolted on by BrainrotModels.
local function add(id, name, rarity, price, income, body, colors, props)
	local entry = { id = id, name = name, rarity = rarity, price = price, income = income, body = body, colors = colors, props = props }
	entry.number = #BrainrotCatalog.ENTRIES + 1
	table.insert(BrainrotCatalog.ENTRIES, entry)
	BrainrotCatalog.byId[id] = entry
	byRarity[rarity] = byRarity[rarity] or {}
	table.insert(byRarity[rarity], entry)
end

-- Common
add("toastolini", "Toastolini Toastolino", "Common", 50, 2, "slab", { c(222, 170, 100), c(255, 228, 120), c(120, 72, 36) }, { "butter", "arms" })
add("pretzello", "Pretzello Twistello", "Common", 120, 4, "ring", { c(176, 104, 44), c(250, 244, 230), c(110, 60, 24) }, { "salt", "arms" })
add("duckuccino", "Duckuccino Turbo", "Common", 250, 7, "ball", { c(255, 214, 60), c(255, 140, 40), c(250, 250, 250) }, { "beak", "cupHat", "wings" })
add("cornetto", "Cornetto Cornuto", "Common", 450, 11, "cone", { c(232, 180, 110), c(255, 150, 190), c(140, 80, 40) }, { "horns", "scoops" })
add("balloonini", "Balloonini Poppini", "Common", 700, 16, "ball", { c(255, 70, 90), c(255, 255, 255), c(60, 60, 70) }, { "string", "partyHat" })
add("ticketto", "Ticketto Stubbini", "Common", 1000, 22, "slab", { c(255, 120, 80), c(255, 230, 150), c(150, 40, 40) }, { "arms", "topHat" })
add("sodapop", "Soda Popolino", "Common", 1400, 29, "can", { c(60, 170, 255), c(255, 255, 255), c(255, 70, 90) }, { "straw", "arms" })
add("nachito", "Nachito Crunchito", "Common", 1900, 38, "wedge", { c(255, 190, 60), c(120, 200, 80), c(230, 60, 40) }, { "mustache", "sombrero" })
-- Uncommon
add("churrolino", "Churro Churrolino", "Uncommon", 3000, 55, "tall", { c(204, 140, 70), c(250, 240, 220), c(110, 60, 30) }, { "arms", "mustache", "salt" })
add("hotdoggo", "Hotdoggo Saltello", "Uncommon", 4500, 80, "log", { c(214, 110, 80), c(255, 214, 80), c(240, 190, 120) }, { "tail", "ears", "mustardStripe" })
add("gelato", "Gelato Gelatoni", "Uncommon", 6500, 110, "cone", { c(240, 196, 130), c(140, 230, 200), c(255, 120, 170) }, { "scoops", "cherry", "arms" })
add("pizzarella", "Pizzarella Piroetta", "Uncommon", 9000, 145, "wedge", { c(255, 200, 90), c(220, 60, 50), c(255, 170, 200) }, { "tutu", "arms", "bow" })
add("donutello", "Donutello Sprinklini", "Uncommon", 12500, 190, "ring", { c(255, 140, 190), c(255, 240, 200), c(90, 200, 255) }, { "sprinkles", "wings" })
add("frogaccia", "Frogaccia Focaccia", "Uncommon", 17000, 250, "block", { c(110, 200, 90), c(232, 196, 130), c(240, 90, 90) }, { "bigEyes", "tongue", "herbs" })
add("waffolo", "Waffolo Syruppo", "Uncommon", 23000, 320, "slab", { c(236, 180, 90), c(150, 80, 30), c(255, 240, 200) }, { "butter", "syrup", "arms" })
-- Rare
add("carousello", "Carousello Ponyoni", "Rare", 35000, 450, "log", { c(255, 250, 240), c(255, 120, 180), c(255, 210, 60) }, { "ponyHead", "pole", "tail" })
add("llamonade", "Llamonade Limonata", "Rare", 50000, 620, "tall", { c(255, 240, 150), c(250, 250, 250), c(120, 210, 90) }, { "ears", "straw", "lemonSlice" })
add("octopopcorn", "Octopopcorno Otto", "Rare", 70000, 840, "ball", { c(230, 90, 150), c(255, 244, 200), c(255, 255, 255) }, { "tentacles", "popcornPile" })
add("tacotigre", "Tacotigre Picante", "Rare", 95000, 1100, "wedge", { c(255, 160, 50), c(50, 40, 40), c(120, 210, 80) }, { "ears", "tail", "stripes", "mustache" })
add("bumperino", "Bumperino Carrello", "Rare", 130000, 1450, "block", { c(70, 120, 255), c(255, 220, 60), c(40, 40, 50) }, { "wheels", "antenna", "bumper" })
add("candalfo", "Cotton Candalfo", "Rare", 175000, 1900, "cone", { c(255, 170, 220), c(150, 200, 255), c(250, 250, 250) }, { "fluff", "wizardHat", "beard" })
-- Epic
add("rhinoccino", "Ringmaster Rhinoccino", "Epic", 260000, 2700, "block", { c(150, 150, 165), c(210, 40, 50), c(255, 210, 60) }, { "horn", "topHat", "coat", "arms", "cane" })
add("wheelio", "Ferris Wheelio Giraffo", "Epic", 380000, 3800, "tall", { c(255, 200, 70), c(160, 100, 40), c(90, 220, 255) }, { "longNeck", "wheelHalo", "spots" })
add("pandacotta", "Panda Cotta Grande", "Epic", 550000, 5300, "ball", { c(250, 250, 250), c(40, 40, 46), c(255, 120, 150) }, { "ears", "eyePatches", "cherry", "arms" })
add("lobsteroni", "Lobsteroni Macaroni", "Epic", 800000, 7400, "log", { c(235, 60, 50), c(255, 220, 110), c(255, 255, 255) }, { "claws", "antenna", "tail", "chefHat" })
add("clowncumber", "Clowncumber Pagliaccio", "Epic", 1150000, 10200, "tall", { c(90, 190, 80), c(255, 60, 70), c(255, 220, 60) }, { "clownNose", "afro", "ruff", "arms" })
-- Legendary
add("popcornado", "Popcornado Tornado", "Legendary", 1800000, 15000, "cone", { c(255, 244, 200), c(255, 200, 60), c(230, 50, 50) }, { "tornadoRings", "popcornPile", "arms" })
add("dragonoli", "Dragonoli Cannoli", "Legendary", 2800000, 22500, "log", { c(230, 170, 90), c(120, 220, 120), c(255, 250, 240) }, { "wings", "horns", "tail", "spikes", "cream" })
add("elefanfare", "Elefanfare Trombone", "Legendary", 4200000, 32500, "ball", { c(150, 170, 220), c(255, 200, 60), c(230, 60, 80) }, { "trunkHorn", "bigEars", "partyHat", "arms" })
add("sharkuterie", "Sharkuterie Salami", "Legendary", 6500000, 48000, "log", { c(90, 130, 170), c(200, 70, 70), c(250, 250, 250) }, { "fin", "tail", "salamiSpots", "teethRow" })
-- Mythic
add("kernelcorn", "King Kernelcorn", "Mythic", 11000000, 75000, "tall", { c(255, 220, 60), c(110, 200, 80), c(170, 60, 220) }, { "crown", "cape", "husk", "arms", "scepter" })
add("fortuna", "Madame Fortuna Meatballa", "Mythic", 18000000, 118000, "ball", { c(150, 80, 50), c(120, 60, 200), c(255, 210, 60) }, { "turban", "crystalBall", "arms", "spaghetti" })
add("rollercobra", "Rollercobra Espresso", "Mythic", 30000000, 185000, "tall", { c(60, 200, 150), c(255, 90, 60), c(90, 50, 30) }, { "hood", "coasterRings", "tongue", "cupHat" })
-- Secret
add("trofeo", "Trofeo Infinito", "Secret", 60000000, 350000, "can", { c(255, 205, 50), c(255, 255, 255), c(90, 200, 255) }, { "cupHandles", "crown", "starBurst", "arms", "wings" })
add("tendone", "Gran Tendone Cosmico", "Secret", 120000000, 650000, "cone", { c(240, 60, 70), c(255, 255, 255), c(255, 210, 60) }, { "tentStripes", "flag", "orbit", "arms" })
add("jackpotto", "Jackpotto Supremo", "Secret", 250000000, 1250000, "block", { c(200, 40, 60), c(255, 210, 60), c(60, 230, 120) }, { "slotFace", "lever", "coins", "crown", "wings" })

function BrainrotCatalog.rarityOf(entry)
	return rarityByKey[entry.rarity]
end

function BrainrotCatalog.count(): number
	return #BrainrotCatalog.ENTRIES
end

-- The Prize Cannon's next prize: a rarity off the ladder, then any brainrot of that rarity.
function BrainrotCatalog.rollBrainrot(luck: number?, random: Random?)
	local rng = random or Random.new()
	local pool = byRarity[BrainrotCatalog.rollRarity(luck, rng)]
	return pool[rng:NextInteger(1, #pool)]
end

-- A brainrot a nearly broke player can pay for: one of the three dearest they can afford (the cheapest if none).
function BrainrotCatalog.rollAffordable(money: number, random: Random?)
	local rng = random or Random.new()
	local last = 1
	for index, entry in BrainrotCatalog.ENTRIES do
		if entry.price <= money then
			last = index
		end
	end
	return BrainrotCatalog.ENTRIES[rng:NextInteger(math.max(1, last - 2), last)]
end

-- The cheapest brainrot a player has not discovered yet that costs more than they hold: the HUD's next goal.
-- nil once nothing left is out of reach, and the HUD then points at the next rebirth.
function BrainrotCatalog.nextGoal(money: number, discovered: { [string]: boolean })
	for _, entry in BrainrotCatalog.ENTRIES do
		if not discovered[entry.id] and entry.price > money then
			return entry
		end
	end
	return nil
end

return BrainrotCatalog
