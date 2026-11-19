-- BrainrotCatalog: the cast of ROT CARNIVAL. 36 original carnival brainrots on a 7-rarity ladder.
-- Each entry is a name, a rarity, a price and a build recipe (body shape, three colours, props)
-- that World/BrainrotModels turns into a 3D model. Money a second comes from price and rarity.

local GameConfig = require(script.Parent.GameConfig)

local BrainrotCatalog = {}

local rgb = Color3.fromRGB

-- body: ball | cube | slab | cyl | long | tiers | cup | disc | tent | egg
-- props: see BrainrotModels.PROP_BUILDERS
BrainrotCatalog.LIST = {
	-- Common
	{ id = "poppo", name = "Poppo Kernelino", rarity = "Common", price = 25, body = "ball", colors = { rgb(255, 244, 200), rgb(255, 214, 90), rgb(220, 60, 60) }, props = { "cream", "legs", "arms" }, quip = "pops when nervous" },
	{ id = "toastolini", name = "Toastolini Toastolino", rarity = "Common", price = 40, body = "slab", colors = { rgb(232, 178, 104), rgb(150, 92, 44), rgb(255, 226, 90) }, props = { "butter", "legs", "moustache" }, quip = "always lands butter side up" },
	{ id = "ticketto", name = "Ticketto Stubbini", rarity = "Common", price = 65, body = "slab", colors = { rgb(255, 120, 150), rgb(255, 240, 240), rgb(60, 60, 80) }, props = { "stripes", "legs", "tophat" }, quip = "admit one, regret all" },
	{ id = "pretzelo", name = "Pretzelo Twistoni", rarity = "Common", price = 100, body = "disc", colors = { rgb(176, 104, 50), rgb(250, 246, 230), rgb(120, 66, 30) }, props = { "sprinkles", "legs", "arms" }, quip = "tied himself in knots" },
	{ id = "balloono", name = "Balloono Squeakarelli", rarity = "Common", price = 150, body = "long", colors = { rgb(255, 90, 170), rgb(255, 160, 210), rgb(255, 255, 255) }, props = { "ears", "tail", "legs", "nose" }, quip = "one poke from retirement" },
	{ id = "cornelio", name = "Cornelio Doggolino", rarity = "Common", price = 220, body = "cyl", colors = { rgb(214, 150, 60), rgb(250, 220, 60), rgb(190, 40, 40) }, props = { "stick", "stripes", "arms", "shades" }, quip = "corn dog, mostly dog" },
	{ id = "duckuccino", name = "Duckuccino Turbo", rarity = "Common", price = 320, body = "egg", colors = { rgb(255, 222, 50), rgb(255, 140, 30), rgb(90, 200, 255) }, props = { "beak", "propeller", "wings", "legs" }, quip = "quacks at 9000 rpm" },
	{ id = "churrito", name = "Churrito Bandito", rarity = "Common", price = 450, body = "cyl", colors = { rgb(205, 140, 70), rgb(255, 240, 220), rgb(50, 40, 40) }, props = { "sprinkles", "moustache", "tophat", "legs" }, quip = "stole the cinnamon" },
	-- Uncommon
	{ id = "nacho", name = "Nacho Gnocchino", rarity = "Uncommon", price = 700, body = "tent", colors = { rgb(255, 196, 60), rgb(255, 150, 30), rgb(120, 200, 70) }, props = { "cream", "legs", "arms", "shades" }, quip = "not yo cheese" },
	{ id = "slushi", name = "Slushi Brainfreezi", rarity = "Uncommon", price = 1000, body = "cup", colors = { rgb(80, 200, 255), rgb(255, 80, 120), rgb(255, 255, 255) }, props = { "straw", "legs", "arms" }, quip = "thinks in ice cubes" },
	{ id = "lollipoppa", name = "Lollipoppa Lickatoni", rarity = "Uncommon", price = 1500, body = "disc", colors = { rgb(255, 90, 200), rgb(255, 255, 255), rgb(120, 220, 255) }, props = { "stick", "stripes", "bowtie", "arms" }, quip = "dizzy since birth" },
	{ id = "bumperino", name = "Bumperino Carrello", rarity = "Uncommon", price = 2200, body = "cube", colors = { rgb(60, 120, 255), rgb(255, 220, 50), rgb(40, 40, 50) }, props = { "wheels", "antenna", "stripes" }, quip = "has no brakes or regrets" },
	{ id = "goldfisho", name = "Goldfisho Baggolini", rarity = "Uncommon", price = 3200, body = "egg", colors = { rgb(255, 140, 40), rgb(170, 230, 255), rgb(255, 200, 80) }, props = { "fin", "tail", "halo", "legs" }, quip = "won at ring toss, never forgave" },
	{ id = "waffolo", name = "Waffolo Conello", rarity = "Uncommon", price = 4600, body = "tent", colors = { rgb(222, 170, 100), rgb(255, 180, 210), rgb(190, 40, 60) }, props = { "cream", "cherry", "legs", "arms" }, quip = "two scoops of chaos" },
	{ id = "cottoncandi", name = "Cottoncandi Fluffolo", rarity = "Uncommon", price = 6500, body = "ball", colors = { rgb(255, 170, 220), rgb(150, 220, 255), rgb(255, 255, 255) }, props = { "ears", "stick", "horns", "tail" }, quip = "97% air, 3% sheep" },
	-- Rare
	{ id = "carousello", name = "Carousello Ponyccino", rarity = "Rare", price = 10000, body = "long", colors = { rgb(250, 250, 255), rgb(255, 200, 60), rgb(255, 100, 160) }, props = { "mane", "ears", "tail", "legs", "antenna" }, quip = "only runs in circles" },
	{ id = "juggelini", name = "Juggelini Tre Palle", rarity = "Rare", price = 15000, body = "egg", colors = { rgb(120, 80, 220), rgb(255, 220, 60), rgb(255, 70, 70) }, props = { "juggle", "arms", "legs", "nose", "bowtie" }, quip = "drops everything but beats" },
	{ id = "hotdoggo", name = "Hotdoggo Dachshundini", rarity = "Rare", price = 22000, body = "long", colors = { rgb(200, 90, 60), rgb(240, 200, 120), rgb(255, 220, 40) }, props = { "ears", "stripes", "tail", "legs", "shades" }, quip = "long boy, extra mustard" },
	{ id = "teacuppo", name = "Teacuppo Spinnaroni", rarity = "Rare", price = 32000, body = "cup", colors = { rgb(255, 250, 240), rgb(255, 120, 180), rgb(120, 220, 200) }, props = { "propeller", "arms", "moustache", "wheels" }, quip = "spins until lunch returns" },
	{ id = "funnelcako", name = "Funnelcako Tornado", rarity = "Rare", price = 46000, body = "tiers", colors = { rgb(240, 200, 130), rgb(255, 255, 255), rgb(255, 90, 90) }, props = { "sprinkles", "cherry", "arms", "legs" }, quip = "category five dessert" },
	{ id = "pizzarello", name = "Pizzarello Unicyclo", rarity = "Rare", price = 65000, body = "disc", colors = { rgb(250, 200, 80), rgb(210, 50, 40), rgb(60, 60, 70) }, props = { "sprinkles", "wheels", "tophat", "arms" }, quip = "delivers himself" },
	-- Epic
	{ id = "ferriswheelio", name = "Ferriswheelio Giganto", rarity = "Epic", price = 100000, body = "disc", colors = { rgb(255, 80, 120), rgb(80, 220, 255), rgb(255, 230, 80) }, props = { "hoop", "legs", "arms", "star" }, quip = "afraid of heights" },
	{ id = "strongmanno", name = "Strongmanno Baguetto", rarity = "Epic", price = 160000, body = "cyl", colors = { rgb(226, 170, 96), rgb(220, 40, 40), rgb(40, 40, 40) }, props = { "moustache", "arms", "legs", "stripes", "spikes" }, quip = "lifts bread, skips leg day" },
	{ id = "clownfisho", name = "Clownfisho Honkolini", rarity = "Epic", price = 250000, body = "egg", colors = { rgb(255, 120, 30), rgb(255, 255, 255), rgb(255, 40, 60) }, props = { "fin", "tail", "nose", "stripes", "tophat", "legs" }, quip = "honks underwater" },
	{ id = "rollercoastro", name = "Rollercoastro Screamini", rarity = "Epic", price = 380000, body = "long", colors = { rgb(255, 60, 60), rgb(255, 220, 50), rgb(70, 70, 90) }, props = { "wheels", "flame", "arms", "antenna", "shades" }, quip = "screams the whole way" },
	{ id = "mirrormaze", name = "Mirrormaze Confusini", rarity = "Epic", price = 550000, body = "cube", colors = { rgb(180, 240, 255), rgb(200, 120, 255), rgb(255, 255, 255) }, props = { "halo", "legs", "arms", "star", "horns" }, quip = "lost inside himself" },
	-- Legendary
	{ id = "ringmaster", name = "Ringmaster Rhinoccino", rarity = "Legendary", price = 900000, body = "egg", colors = { rgb(150, 150, 170), rgb(200, 30, 50), rgb(255, 210, 60) }, props = { "tusks", "tophat", "cape", "bowtie", "legs", "arms" }, quip = "charges for admission" },
	{ id = "elephanto", name = "Elephanto Peanutto Grande", rarity = "Legendary", price = 1500000, body = "ball", colors = { rgb(190, 170, 210), rgb(255, 150, 190), rgb(240, 200, 120) }, props = { "trunk", "ears", "tusks", "crown", "legs" }, quip = "never forgets a snack" },
	{ id = "cannonballo", name = "Cannonballo Humano", rarity = "Legendary", price = 2400000, body = "ball", colors = { rgb(50, 50, 60), rgb(255, 80, 40), rgb(255, 230, 90) }, props = { "flame", "shades", "cape", "legs", "arms", "antenna" }, quip = "commutes by cannon" },
	{ id = "tigre", name = "Tigre Tightropo", rarity = "Legendary", price = 3800000, body = "long", colors = { rgb(255, 150, 30), rgb(40, 30, 30), rgb(255, 255, 255) }, props = { "stripes", "ears", "tail", "legs", "hoop", "moustache" }, quip = "balanced diet of acrobats" },
	-- Mythic
	{ id = "kernelcorn", name = "King Kernelcorn", rarity = "Mythic", price = 7000000, body = "cyl", colors = { rgb(255, 220, 60), rgb(110, 200, 70), rgb(200, 40, 60) }, props = { "crown", "cape", "sprinkles", "moustache", "arms", "legs" }, quip = "rules by divine pop" },
	{ id = "gelato", name = "Gelato Dragoncello", rarity = "Mythic", price = 14000000, body = "tiers", colors = { rgb(150, 240, 210), rgb(255, 150, 200), rgb(255, 240, 150) }, props = { "wings", "horns", "tail", "flame", "legs", "cherry" }, quip = "breathes brain freeze" },
	{ id = "fortuna", name = "Fortuna Zoltarini", rarity = "Mythic", price = 28000000, body = "cube", colors = { rgb(110, 50, 170), rgb(255, 210, 70), rgb(80, 240, 230) }, props = { "halo", "tophat", "moustache", "star", "arms", "juggle" }, quip = "predicts you will buy her" },
	-- Secret
	{ id = "tendone", name = "Il Grande Tendone", rarity = "Secret", price = 75000000, body = "tent", colors = { rgb(240, 50, 70), rgb(255, 255, 255), rgb(255, 215, 60) }, props = { "flag", "stripes", "legs", "arms", "star", "moustache" }, quip = "the circus is inside him" },
	{ id = "trofeo", name = "Trofeo Infinito", rarity = "Secret", price = 250000000, body = "cup", colors = { rgb(255, 210, 60), rgb(255, 245, 170), rgb(90, 220, 255) }, props = { "halo", "wings", "crown", "star", "arms", "legs" }, quip = "wins every game he invents" },
	{ id = "popcornado", name = "Popcornado Supremo", rarity = "Secret", price = 1000000000, body = "tiers", colors = { rgb(255, 250, 220), rgb(255, 205, 70), rgb(230, 50, 60) }, props = { "cream", "crown", "flame", "wings", "juggle", "arms", "legs" }, quip = "the wave obeys him" },
}

BrainrotCatalog.COUNT = #BrainrotCatalog.LIST
BrainrotCatalog.BY_ID = {}
BrainrotCatalog.BY_RARITY = {}

for order, entry in BrainrotCatalog.LIST do
	local rarity = GameConfig.RARITY_BY_KEY[entry.rarity]
	entry.order = order
	entry.income = math.max(1, math.floor(entry.price / rarity.payback))
	BrainrotCatalog.BY_ID[entry.id] = entry
	BrainrotCatalog.BY_RARITY[entry.rarity] = BrainrotCatalog.BY_RARITY[entry.rarity] or {}
	table.insert(BrainrotCatalog.BY_RARITY[entry.rarity], entry)
end

-- Money a second of one brainrot: catalog income x mutation multiplier.
function BrainrotCatalog.incomePerSecond(id: string, mutationKey: string?): number
	local entry = BrainrotCatalog.BY_ID[id]
	local mutation = mutationKey and GameConfig.MUTATION_BY_KEY[mutationKey]
	return entry.income * (if mutation then mutation.mult else 1)
end

-- Belt price: a mutated prize costs more, but less than its extra income is worth.
function BrainrotCatalog.priceOf(id: string, mutationKey: string?, priceScale: number?): number
	local entry = BrainrotCatalog.BY_ID[id]
	local mutation = mutationKey and GameConfig.MUTATION_BY_KEY[mutationKey]
	local price = entry.price * (if mutation then 1 + (mutation.mult - 1) * 0.6 else 1)
	return math.max(1, math.floor(price * (priceScale or 1)))
end

-- Weighted pick for the Prize Cannon. rarityLuck > 1 thins out the commons.
function BrainrotCatalog.pickForBelt(roll: () -> number, rarityLuck: number?)
	local luck = rarityLuck or 1
	local total = 0
	local weights = {}
	for _, rarity in GameConfig.RARITIES do
		local weight = rarity.weight * luck ^ (rarity.rank - 1)
		weights[rarity.key] = weight
		total += weight
	end
	local target = roll() * total
	local chosen = GameConfig.RARITIES[1]
	for _, rarity in GameConfig.RARITIES do
		target -= weights[rarity.key]
		if target <= 0 then
			chosen = rarity
			break
		end
	end
	local pool = BrainrotCatalog.BY_RARITY[chosen.key]
	return pool[math.clamp(math.floor(roll() * #pool) + 1, 1, #pool)]
end

-- The cheapest brainrot the player has not discovered yet: the HUD's NEXT GOAL.
function BrainrotCatalog.nextUndiscovered(discovered: { [string]: boolean })
	for _, entry in BrainrotCatalog.LIST do
		if not discovered[entry.id] then
			return entry
		end
	end
	return nil
end

return BrainrotCatalog
