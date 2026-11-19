--!strict
-- The hand-built cast's art: the parts each of the first fourteen brainrots is built from, keyed by id.
-- Front of every character is local -Z; y = 0 is the ground under its feet.

local PartShapes = require(script.Parent:WaitForChild("PartShapes"))
local block, ball, pillar, wheel, tube, eyes, join =
	PartShapes.block, PartShapes.ball, PartShapes.pillar, PartShapes.wheel, PartShapes.tube, PartShapes.eyes, PartShapes.join

local rgb = Color3.fromRGB
local v3 = Vector3.new
local TOAST = rgb(226, 172, 92)
local CRUST = rgb(150, 95, 45)
local WHITE = rgb(240, 240, 240)
local BLACK = rgb(25, 25, 30)

local CastArt = {}

CastArt.parts = {
	toastolini = join({
		block(0.4, 1.2, 0.4, -0.5, 0.6, 0, CRUST),
		block(0.4, 1.2, 0.4, 0.5, 0.6, 0, CRUST),
		block(2.7, 2.9, 0.7, 0, 2.6, 0.08, CRUST),
		block(2.4, 2.6, 0.8, 0, 2.6, 0, TOAST),
		block(1.0, 0.9, 0.12, 0.35, 2.1, -0.45, rgb(255, 228, 110)),
		block(1.2, 0.3, 0.3, -1.85, 2.7, 0, CRUST, { rot = v3(0, 0, 25) }),
		block(1.2, 0.3, 0.3, 1.85, 2.7, 0, CRUST, { rot = v3(0, 0, -25) }),
		block(0.7, 0.15, 0.1, 0, 2.75, -0.45, BLACK, { keep = true }),
	}, eyes(3.3, -0.42, 0.5, 0.55)),
	pickle = join({
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
	sockodile = join({
		block(1.5, 1.5, 3.8, 0, 1.0, 0.4, rgb(220, 60, 60)),
		block(1.55, 1.55, 0.4, 0, 1.0, -0.6, WHITE),
		block(1.55, 1.55, 0.4, 0, 1.0, 0.6, WHITE),
		block(1.55, 1.55, 0.4, 0, 1.0, 1.8, WHITE),
		block(1.3, 0.7, 1.6, 0, 0.75, -2.2, rgb(80, 160, 70)),
		block(1.1, 0.15, 1.4, 0, 0.35, -2.2, WHITE, { keep = true }),
		block(1.2, 0.7, 1.2, 0, 2.0, -0.9, rgb(60, 90, 220), { rot = v3(-20, 0, 0) }),
		ball(0.6, 0, 2.5, -0.2, WHITE),
	}, eyes(1.95, -1.55, 0.4, 0.55)),
	fridgoletto = join({
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
	duckuccino = join({
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
	bananaconda = join({
		wheel(0.5, 1.5, 0, 0.75, -1.7, BLACK),
		wheel(0.5, 1.5, 0, 0.75, 1.7, BLACK),
		block(0.5, 0.4, 3.6, 0, 1.2, 0, rgb(200, 30, 40)),
		tube(4.2, 1.3, 0, 1.9, 0.2, rgb(255, 225, 60)),
		ball(1.7, 0, 2.7, -2.0, rgb(255, 225, 60)),
		block(0.4, 0.4, 0.6, 0, 2.1, 2.5, rgb(90, 60, 30)),
		block(2.2, 0.2, 0.2, 0, 2.5, -1.3, rgb(170, 170, 180)),
		block(0.2, 0.1, 0.7, 0, 2.35, -2.95, rgb(230, 40, 60), { keep = true }),
	}, eyes(3.05, -2.7, 0.42, 0.5)),
	moaistro = join({
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
	cactus = join({
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
	toiletronaut = join({
		pillar(1.6, 2.2, 0, 0.8, 0, WHITE),
		pillar(0.25, 2.5, 0, 1.75, 0, rgb(230, 230, 235)),
		block(2.2, 2.1, 0.8, 0, 2.6, 0.95, WHITE),
		ball(3.8, 0, 2.3, 0.2, rgb(170, 220, 255), { material = Enum.Material.Glass, transparency = 0.65, keep = true }),
		block(0.12, 1.0, 0.12, 0, 4.6, 0.2, rgb(170, 170, 180)),
		ball(0.4, 0, 5.15, 0.2, rgb(255, 50, 60), { material = Enum.Material.Neon, keep = true }),
		block(0.9, 0.18, 0.1, 0, 2.15, 0.53, BLACK, { keep = true }),
	}, eyes(2.95, 0.52, 0.42, 0.5)),
	sushi = join({
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
	goldfish = join({
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
	lavalampo = join({
		pillar(1.2, 1.7, 0, 0.6, 0, rgb(190, 190, 200), { material = Enum.Material.Metal }),
		pillar(3.0, 1.6, 0, 2.7, 0, rgb(170, 60, 255), { material = Enum.Material.Neon, transparency = 0.35 }),
		ball(0.9, 0.2, 2.1, 0, rgb(255, 140, 30), { material = Enum.Material.Neon, keep = true }),
		ball(0.7, -0.2, 3.3, 0, rgb(255, 90, 60), { material = Enum.Material.Neon, keep = true }),
		pillar(0.8, 1.2, 0, 4.6, 0, rgb(190, 190, 200), { material = Enum.Material.Metal }),
		block(0.7, 0.15, 0.1, 0, 2.55, -0.82, BLACK, { keep = true }),
	}, eyes(3.0, -0.82, 0.35, 0.45)),
	discodino = join({
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
	wobblegel = join({
		block(4.0, 4.0, 4.0, 0, 2.0, 0, rgb(90, 255, 160), { material = Enum.Material.Glass, transparency = 0.3 }),
		ball(1.6, 0, 2.0, 0, rgb(255, 90, 200), { material = Enum.Material.Neon, keep = true }),
		block(2.6, 0.5, 2.6, 0, 4.25, 0, rgb(255, 205, 40), { material = Enum.Material.Metal, keep = true }),
		block(0.4, 0.9, 0.4, -1.1, 4.9, -1.1, rgb(255, 205, 40), { material = Enum.Material.Metal, keep = true }),
		block(0.4, 0.9, 0.4, 1.1, 4.9, -1.1, rgb(255, 205, 40), { material = Enum.Material.Metal, keep = true }),
		block(0.4, 0.9, 0.4, -1.1, 4.9, 1.1, rgb(255, 205, 40), { material = Enum.Material.Metal, keep = true }),
		block(0.4, 0.9, 0.4, 1.1, 4.9, 1.1, rgb(255, 205, 40), { material = Enum.Material.Metal, keep = true }),
		block(1.4, 0.25, 0.1, 0, 1.6, -2.05, BLACK, { keep = true }),
	}, eyes(2.8, -2.05, 0.7, 0.8)),
} :: { [string]: { any } }

return CastArt
