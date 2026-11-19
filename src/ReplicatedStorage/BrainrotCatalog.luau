-- BrainrotCatalog: the cast. 36 original carnival brainrots on a ladder of 7 rarities.
-- Row: id, name, rarity (1 Common .. 7 Secret), price, money a second, body, three colours, accessories.
local GameConfig = require(script.Parent.GameConfig)
local MutationRoller = require(script.Parent.MutationRoller)

local BrainrotCatalog = {}

local ROWS = {
	-- Common
	{ "toastolini", "Toastolini Toastolino", 1, 25, 1, "toast", "e8b76a,8a5a2b,ffe9a8", "mustache,arms" },
	{ "popcornetto", "Popcornetto Piccolo", 1, 40, 2, "bucket", "f04848,ffffff,fff3c4", "arms" },
	{ "duckuccino", "Duckuccino Turbo", 1, 60, 3, "cup", "ffd84a,ffffff,7a4a22", "beak,wings,propeller" },
	{ "pretzelino", "Pretzelino Twisto", 1, 90, 4, "knot", "b9722d,fff6dd,7a4a22", "arms,partyhat" },
	{ "sockaroni", "Sockaroni Stinko", 1, 130, 5, "sock", "f2f2f2,e84c4c,6fd06f", "stink,arms" },
	{ "churrini", "Churro Churrini", 1, 180, 7, "tube", "d9963f,fff1d0,a05a1e", "mustache,tophat" },
	{ "bananito", "Bananito Bumperino", 1, 240, 9, "banana", "ffe14a,6b4a1e,ff5a5a", "wheels,glasses" },
	{ "gelatino", "Gelatino Wobblo", 1, 320, 12, "jelly", "ff5aa8,ffd0e6,ffffff", "arms,cherry" },
	-- Uncommon
	{ "hotdoggo", "Hotdoggo Trampolino", 2, 500, 18, "tube", "c9482e,e8b76a,ffd84a", "ears,tail,spring" },
	{ "tacotto", "Tacotto Carouselo", 2, 700, 25, "slice", "f2c14e,7ac74f,e84c4c", "arms,partyhat,tail" },
	{ "froggo", "Froggo Lollipoppo", 2, 950, 33, "ball", "5fd35f,ff6fb5,ffffff", "stick,eyestalks" },
	{ "pizzarello", "Pizzarello Ferriswheelo", 2, 1300, 44, "slice", "ffd166,c9482e,b33a2a", "propeller,arms,mustache" },
	{ "donutello", "Donutello Spinnato", 2, 1700, 56, "donut", "e8b76a,ff7ac0,ffffff", "arms,sprinkles" },
	{ "pickleoni", "Pickleoni Juggleri", 2, 2200, 70, "capsule", "5aa84a,3d7a32,ffe14a", "arms,juggle,bowtie" },
	{ "waffleoni", "Waffleoni Rollercoasto", 2, 2900, 90, "block", "e8a94a,b9722d,ff5a5a", "wheels,cherry,arms" },
	-- Rare
	{ "penguini", "Penguini Snowconi", 3, 4000, 120, "cone", "f2d9a0,5ad1ff,ff5aa8", "beak,wings,bowtie" },
	{ "giraffa", "Giraffa Cottoncandia", 3, 5500, 160, "cloud", "ff9ad5,ffd84a,9a6a2b", "neck,stick" },
	{ "crabbo", "Crabbo Carameloni", 3, 7500, 210, "ball", "e85a3a,c9862e,ffffff", "claws,eyestalks,stick" },
	{ "llamacchino", "Llamacchino Balloonato", 3, 10000, 270, "cup", "f5efe0,c9a27a,ff5a5a", "ears,neckfluff,balloon" },
	{ "octopizza", "Octopizza Otto", 3, 13000, 340, "slice", "ffd166,b05ad6,c9482e", "tentacles,tophat" },
	{ "moosetachio", "Moosetachio Magnifico", 3, 17000, 430, "capsule", "9ad67a,7a4a22,fff1d0", "antlers,mustache,arms" },
	-- Epic
	{ "sharkolato", "Sharkolato Fudgerino", 4, 25000, 600, "capsule", "6a4a3a,d9c2a0,ffffff", "fin,tail,teeth,arms" },
	{ "elephanto", "Elephanto Peanutini", 4, 34000, 800, "capsule", "d9b98a,a8a8b8,ff7ac0", "trunk,bigears,tophat" },
	{ "tigrotto", "Tigrotto Ticketmastro", 4, 46000, 1050, "block", "ff9a2e,2a2a2a,ffe14a", "ears,stripes,tail,bowtie" },
	{ "hippo", "Hippo Hulahoopo", 4, 60000, 1350, "ball", "b58ad6,ff7ac0,5ad1ff", "hoop,ears,teeth,arms" },
	{ "flamingelato", "Flamingelato Rosa", 4, 80000, 1750, "cone", "f2d9a0,ff8ac8,ffffff", "neck,beak,wings" },
	-- Legendary
	{ "rhinoccino", "Ringmaster Rhinoccino", 5, 120000, 2500, "cup", "8a8a9a,c9482e,ffd84a", "horn,tophat,cape,mustache,arms" },
	{ "dragonzola", "Dragonzola Fireworko", 5, 170000, 3400, "capsule", "5a8ad6,fff1d0,ff5a2e", "wings,horn,tail,flame" },
	{ "gorillasagna", "Gorillasagna Strongmano", 5, 240000, 4600, "block", "c9482e,ffd166,3a2a2a", "bigarms,barbell,mustache" },
	{ "unicornetto", "Unicornetto Glitterati", 5, 330000, 6200, "cone", "f2d9a0,ffffff,ff8ac8", "horn,ears,rainbowtail,sprinkles" },
	-- Mythic
	{ "kernelcorn", "King Kernelcorn", 6, 500000, 9000, "bucket", "f04848,ffffff,ffe14a", "crown,cape,bigarms,scepter" },
	{ "krakenoli", "Krakenoli Carnevale", 6, 800000, 14000, "ball", "8a3ad6,ff5aa8,ffe14a", "tentacles,crown,eyestalks,balloon" },
	{ "phoenixpresso", "Phoenixpresso Infernale", 6, 1250000, 21000, "cup", "ff6a1e,ffd84a,3a1e0a", "wings,flame,beak,rainbowtail" },
	-- Secret
	{ "trofeo", "Trofeo Infinito", 7, 2500000, 40000, "trophy", "ffd84a,fff3a0,ff5aa8", "wings,halo,arms" },
	{ "tentissimo", "Il Grande Tentissimo", 7, 5000000, 75000, "tent", "ff4848,ffffff,ffd84a", "bigarms,mustache,flag" },
	{ "jackpotto", "Jackpotto Supremo", 7, 10000000, 140000, "slot", "c92e4a,ffd84a,ffffff", "lever,crown,wings,halo" },
}

BrainrotCatalog.list = {}
BrainrotCatalog.byId = {}
for order, row in ROWS do
	local colors = {}
	for hex in string.gmatch(row[7], "[^,]+") do
		table.insert(colors, Color3.fromHex(hex))
	end
	local entry = {
		order = order,
		id = row[1],
		name = row[2],
		rarity = row[3],
		price = row[4],
		income = row[5],
		body = row[6],
		colors = colors,
		accessories = string.split(row[8], ","),
	}
	BrainrotCatalog.list[order] = entry
	BrainrotCatalog.byId[row[1]] = entry
end
BrainrotCatalog.count = #BrainrotCatalog.list

function BrainrotCatalog.incomePerSecond(id, mutation) -- $/s x mutation
	local entry = BrainrotCatalog.byId[id]
	return if entry then entry.income * MutationRoller.incomeMultiplier(mutation) else 0
end

function BrainrotCatalog.rarityOf(id: string)
	return GameConfig.RARITIES[BrainrotCatalog.byId[id].rarity]
end

-- pickForCannon: weighted by rarity; rareBoost (Cannon Frenzy, rebirth luck) multiplies Rare and up.
function BrainrotCatalog.pickForCannon(rng: Random, rareBoost: number)
	local total = 0
	local weights = {}
	for i, rarity in GameConfig.RARITIES do
		weights[i] = if i >= 3 then rarity.weight * rareBoost else rarity.weight
		total += weights[i]
	end
	local roll = rng:NextNumber(0, total)
	local tier = 1
	for i, weight in weights do
		roll -= weight
		if roll <= 0 then
			tier = i
			break
		end
	end
	local pool = {}
	for _, entry in BrainrotCatalog.list do
		if entry.rarity == tier then
			table.insert(pool, entry)
		end
	end
	return pool[rng:NextInteger(1, #pool)]
end

-- nextGoal: the cheapest brainrot the player has not found yet, for the HUD's NEXT GOAL line.
function BrainrotCatalog.nextGoal(found: { [string]: boolean })
	for _, entry in BrainrotCatalog.list do
		if not found[entry.id] then
			return entry
		end
	end
	return nil
end

function BrainrotCatalog.formatMoney(amount: number): string
	local units = { "", "K", "M", "B", "T" }
	local value = math.floor(amount)
	local unit = 1
	local shown = value
	while shown >= 1000 and unit < #units do
		shown /= 1000
		unit += 1
	end
	if unit == 1 then
		return "$" .. tostring(value)
	end
	return string.format("$%.2f%s", math.floor(shown * 100) / 100, units[unit])
end

return BrainrotCatalog
