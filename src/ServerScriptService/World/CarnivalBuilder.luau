-- CarnivalBuilder: builds the 3D carnival out of parts: the checkered street, the Prize Belt, the Prize Cannon,
-- the Popcorn Machine, six player booths (gate, laser lock, carpet, collect pad, 20 pedestals) and the fairground
-- around them (ferris wheel, carousel, big tops, lollipop trees, balloons, string lights, title arches).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.GameConfig)

local CarnivalBuilder = {}

local rgb = Color3.fromRGB
local RED, WHITE, GOLD = rgb(235, 64, 72), rgb(255, 255, 255), rgb(255, 205, 60)
local PINK, YELLOW, MINT, SKY, PURPLE, ORANGE = rgb(255, 150, 196), rgb(255, 226, 120), rgb(140, 226, 170), rgb(110, 200, 255), rgb(186, 130, 255), rgb(255, 160, 80)
local CANDY = { RED, YELLOW, SKY, PINK, MINT, PURPLE, ORANGE }
local BOOTH_FLOORS = { rgb(255, 214, 226), rgb(210, 236, 255), rgb(255, 240, 196), rgb(214, 246, 214), rgb(232, 216, 255), rgb(255, 224, 200) }
local UPRIGHT = CFrame.Angles(0, 0, math.pi / 2)
local SMOOTH, NEON = Enum.Material.SmoothPlastic, Enum.Material.Neon

local function make(parent: Instance, name: string, shape: Enum.PartType, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = shape
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or SMOOTH
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function box(parent, name, sx, sy, sz, x, y, z, color, material: Enum.Material?)
	return make(parent, name, Enum.PartType.Block, Vector3.new(sx, sy, sz), CFrame.new(x, y, z), color, material)
end

local function post(parent, name, d, h, x, y, z, color, material: Enum.Material?)
	return make(parent, name, Enum.PartType.Cylinder, Vector3.new(h, d, d), CFrame.new(x, y, z) * UPRIGHT, color, material)
end

local function orb(parent, name, d, x, y, z, color, material: Enum.Material?)
	return make(parent, name, Enum.PartType.Ball, Vector3.new(d, d, d), CFrame.new(x, y, z), color, material)
end

local function decor(p: Part): Part
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	return p
end

local function sign(part: Part, face: Enum.NormalId, text: string, color: Color3, back: Color3?): TextLabel
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Sign" .. face.Name
	gui.Face = face
	local wide, tall = part.Size.X, part.Size.Y
	if face == Enum.NormalId.Top then
		tall = part.Size.Z
	elseif face == Enum.NormalId.Left or face == Enum.NormalId.Right then
		wide = part.Size.Z
	end
	gui.CanvasSize = Vector2.new(900, math.floor(900 * tall / wide))
	gui.LightInfluence = 0
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = if back then 0 else 1
	label.BackgroundColor3 = back or WHITE
	label.FontFace = Font.fromEnum(Enum.Font.LuckiestGuy)
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = rgb(60, 20, 60)
	label.Parent = gui
	return label
end

-- striped: a run of candy-stripe wall segments from (x1, z1) to (x2, z2).
local function striped(parent: Instance, x1: number, z1: number, x2: number, z2: number, height: number, a: Color3, b: Color3)
	local length = math.sqrt((x2 - x1) ^ 2 + (z2 - z1) ^ 2)
	local count = math.max(1, math.round(length / 6))
	for i = 1, count do
		local t = (i - 0.5) / count
		local alongX = math.abs(x2 - x1) > math.abs(z2 - z1)
		local seg = length / count
		box(parent, "Wall", if alongX then seg else 1.2, height, if alongX then 1.2 else seg, x1 + (x2 - x1) * t, height / 2, z1 + (z2 - z1) * t, if i % 2 == 0 then a else b)
	end
	local cap = box(parent, "WallCap", math.abs(x2 - x1) + 1.6, 0.5, math.abs(z2 - z1) + 1.6, (x1 + x2) / 2, height + 0.25, (z1 + z2) / 2, GOLD)
	decor(cap)
end

local function buildStreet(root: Instance)
	local street = Instance.new("Model")
	street.Name = "Street"
	local S = GameConfig.STREET
	box(street, "Ground", 760, 2, 760, 0, -1, 0, rgb(150, 226, 150), Enum.Material.Grass)
	box(street, "Plaza", 330, 0.2, 190, 0, 0.05, 0, rgb(255, 240, 214))
	local tile = 8
	for ix = 0, math.floor((S.xMax - S.xMin) / tile) do
		for iz = 0, math.floor(S.halfWidth * 2 / tile) - 1 do
			local t = box(street, "Tile", tile, 0.3, tile, S.xMin + (ix + 0.5) * tile, 0.15, -S.halfWidth + (iz + 0.5) * tile, if (ix + iz) % 2 == 0 then PINK else YELLOW)
			t.CastShadow = false
		end
	end
	for _, side in { -1, 1 } do
		box(street, "Kerb", S.xMax - S.xMin + 8, 0.5, 1, 0, 0.25, side * (S.halfWidth + 0.5), WHITE)
	end
	street.Parent = root
end

local function buildBelt(root: Instance)
	local belt = Instance.new("Model")
	belt.Name = "Belt"
	local B = GameConfig.BELT
	local length = B.xEnd - B.xStart
	local mid = (B.xEnd + B.xStart) / 2
	local surface = box(belt, "BeltSurface", length, 0.6, 5, mid, B.y - 0.3, 0, rgb(52, 46, 70))
	sign(surface, Enum.NormalId.Top, string.rep(">  ", 46), YELLOW).TextStrokeTransparency = 1
	for _, side in { -1, 1 } do
		box(belt, "Rail", length, 0.5, 0.5, mid, B.y + 0.05, side * 2.75, rgb(80, 240, 255), NEON)
		box(belt, "Skirt", length, 1.4, 0.4, mid, B.y - 1.2, side * 2.6, RED)
	end
	for x = B.xStart, B.xEnd, 12 do
		post(belt, "Leg", 1.2, B.y - 0.4, x, (B.y - 0.4) / 2, 0, rgb(90, 84, 110))
		decor(orb(belt, "Bulb", 0.9, x, B.y + 0.5, 2.75, GOLD, NEON))
		decor(orb(belt, "Bulb", 0.9, x, B.y + 0.5, -2.75, GOLD, NEON))
	end
	local banner = box(belt, "BeltBanner", 30, 4, 0.6, B.xStart + 40, 17, 0, PURPLE)
	sign(banner, Enum.NormalId.Front, "PRIZE BELT", YELLOW)
	sign(banner, Enum.NormalId.Back, "PRIZE BELT", YELLOW)
	for _, dx in { -14, 14 } do
		post(belt, "BannerPole", 0.8, 17, B.xStart + 40 + dx, 8.5, 0, WHITE).CanCollide = false
	end
	belt.Parent = root
end

local function buildCannon(root: Instance)
	local cannon = Instance.new("Model")
	cannon.Name = "Cannon"
	local x = GameConfig.BELT.xStart - 12
	box(cannon, "Deck", 18, 1.2, 14, x, 0.6, 0, PURPLE)
	for _, side in { -1, 1 } do
		make(cannon, "Wheel", Enum.PartType.Cylinder, Vector3.new(1.6, 9, 9), CFrame.new(x, 4.6, side * 5) * CFrame.Angles(0, math.pi / 2, 0), GOLD)
		make(cannon, "Hub", Enum.PartType.Cylinder, Vector3.new(1.9, 3, 3), CFrame.new(x, 4.6, side * 5) * CFrame.Angles(0, math.pi / 2, 0), RED)
	end
	local tilt = CFrame.new(x + 2, 8, 0) * CFrame.Angles(0, 0, math.rad(18))
	make(cannon, "Barrel", Enum.PartType.Cylinder, Vector3.new(17, 7.5, 7.5), tilt, RED)
	for i = -1, 1 do
		make(cannon, "Band", Enum.PartType.Cylinder, Vector3.new(1.2, 8, 8), tilt * CFrame.new(i * 6, 0, 0), GOLD)
	end
	make(cannon, "Bore", Enum.PartType.Cylinder, Vector3.new(0.4, 6, 6), tilt * CFrame.new(8.5, 0, 0), rgb(30, 20, 40))
	for i = 0, 5 do
		decor(orb(cannon, "Star", 1.2, x - 6 + i * 2.4, 12.5 + math.sin(i * 1.7) * 1.2, 0, YELLOW, NEON))
	end
	local muzzle = box(cannon, "Muzzle", 1, 1, 1, GameConfig.BELT.xStart, GameConfig.BELT.y + 3, 0, WHITE)
	muzzle.Transparency = 1
	muzzle.CanCollide = false
	local board = box(cannon, "CannonSign", 20, 4.5, 0.8, x, 17.5, 0, RED)
	sign(board, Enum.NormalId.Front, "PRIZE CANNON", YELLOW)
	sign(board, Enum.NormalId.Back, "PRIZE CANNON", YELLOW)
	post(cannon, "SignPole", 0.9, 16, x - 9, 8, 0, WHITE).CanCollide = false
	post(cannon, "SignPole", 0.9, 16, x + 9, 8, 0, WHITE).CanCollide = false
	cannon.Parent = root
end

local function buildPopcornMachine(root: Instance)
	local machine = Instance.new("Model")
	machine.Name = "PopcornMachine"
	local x = GameConfig.BELT.xEnd + 16
	box(machine, "Cart", 20, 9, 22, x, 4.5, 0, RED)
	for i = -2, 2 do
		box(machine, "CartStripe", 20.2, 9.05, 1.6, x, 4.5, i * 4.4, WHITE)
	end
	local glass = box(machine, "Glass", 18, 12, 20, x, 15, 0, rgb(210, 240, 255), Enum.Material.Glass)
	glass.Transparency = 0.55
	local rng = Random.new(7)
	for i = 1, 70 do
		decor(orb(machine, "Kernel", rng:NextNumber(1.6, 2.6), x + rng:NextNumber(-7.5, 7.5), rng:NextNumber(9.8, 17), rng:NextNumber(-8.5, 8.5), if i % 3 == 0 then YELLOW else rgb(255, 248, 224)))
	end
	box(machine, "Roof", 24, 2, 26, x, 22, 0, RED)
	for i = -2, 2 do
		box(machine, "RoofStripe", 24.2, 2.05, 2.2, x, 22, i * 5.2, WHITE)
	end
	local board = box(machine, "MachineSign", 1, 5, 24, x - 12.6, 25.5, 0, YELLOW)
	sign(board, Enum.NormalId.Left, "POPCORN MACHINE", RED)
	box(machine, "Chute", 8, 1, 8, x - 12, 2.2, 0, rgb(52, 46, 70))
	for _, side in { -1, 1 } do
		make(machine, "CartWheel", Enum.PartType.Cylinder, Vector3.new(1.4, 7, 7), CFrame.new(x + 4, 3.5, side * 11.6) * CFrame.Angles(0, math.pi / 2, 0), GOLD)
	end
	machine.Parent = root
end

-- buildBooth: one player base. Everything hangs off the gate centre, lz studs into the booth.
local function buildBooth(root: Instance, index: number, spec)
	local booth = Instance.new("Model")
	booth.Name = "Booth" .. index
	local B = GameConfig.BOOTH
	local gateZ = GameConfig.STREET.halfWidth + 1
	local function z(lz: number): number
		return spec.side * (gateZ + lz)
	end
	local accent = CANDY[index]
	box(booth, "Floor", B.halfWidth * 2, 0.4, B.depth, spec.x, 0.2, z(B.depth / 2), BOOTH_FLOORS[index])
	striped(booth, spec.x - B.halfWidth, z(0), spec.x - B.gateHalf - 1, z(0), 5, accent, WHITE)
	striped(booth, spec.x + B.gateHalf + 1, z(0), spec.x + B.halfWidth, z(0), 5, accent, WHITE)
	striped(booth, spec.x - B.halfWidth, z(0), spec.x - B.halfWidth, z(B.depth), 5, accent, WHITE)
	striped(booth, spec.x + B.halfWidth, z(0), spec.x + B.halfWidth, z(B.depth), 5, accent, WHITE)
	striped(booth, spec.x - B.halfWidth, z(B.depth), spec.x + B.halfWidth, z(B.depth), 7, accent, WHITE)

	local gate = Instance.new("Model")
	gate.Name = "Gate"
	for _, side in { -1, 1 } do
		for i = 0, 6 do
			post(gate, "GatePost", 2.2, 2, spec.x + side * (B.gateHalf + 1), 1 + i * 2, z(0), if i % 2 == 0 then accent else WHITE)
		end
		decor(orb(gate, "PostOrb", 3, spec.x + side * (B.gateHalf + 1), 15.5, z(0), GOLD, NEON))
	end
	local beam = box(gate, "Beam", B.gateHalf * 2 + 6, 3.4, 1.6, spec.x, 12.5, z(0), rgb(60, 36, 90))
	sign(beam, if spec.side == 1 then Enum.NormalId.Front else Enum.NormalId.Back, "OPEN BOOTH", YELLOW).Name = "OwnerText"
	sign(beam, if spec.side == 1 then Enum.NormalId.Back else Enum.NormalId.Front, "ROT CARNIVAL", PINK)
	for i = -4, 4 do
		decor(orb(gate, "GateBulb", 0.9, spec.x + i * 2.2, 14.6, z(0), CANDY[(i + 4) % #CANDY + 1], NEON))
	end
	gate.Parent = booth

	local lasers = Instance.new("Folder")
	lasers.Name = "Lasers"
	for i = 0, 3 do
		local bar = box(lasers, "Laser", B.gateHalf * 2, 0.45, 0.45, spec.x, 1.6 + i * 2.6, z(0), rgb(255, 40, 60), NEON)
		bar.Transparency = 1
		bar.CanCollide = false
		bar.CanQuery = false
	end
	lasers.Parent = booth

	box(booth, "Carpet", 8, 0.12, B.depth - 6, spec.x, 0.46, z(B.depth / 2), RED)
	for _, side in { -1, 1 } do
		decor(box(booth, "CarpetTrim", 0.6, 0.14, B.depth - 6, spec.x + side * 4.2, 0.47, z(B.depth / 2), GOLD))
	end
	local pad = box(booth, "CollectPad", 8, 0.5, 5, spec.x, 0.55, z(6), rgb(70, 230, 110), NEON)
	pad.CanCollide = false
	local padGui = Instance.new("BillboardGui")
	padGui.Name = "PadGui"
	padGui.Size = UDim2.fromScale(9, 2.4)
	padGui.StudsOffsetWorldSpace = Vector3.new(0, 2.4, 0)
	padGui.MaxDistance = 80
	padGui.LightInfluence = 0
	padGui.Parent = pad
	local padText = Instance.new("TextLabel")
	padText.Name = "Text"
	padText.Size = UDim2.fromScale(1, 1)
	padText.BackgroundTransparency = 1
	padText.FontFace = Font.fromEnum(Enum.Font.LuckiestGuy)
	padText.Text = "COLLECT $0"
	padText.TextColor3 = rgb(120, 255, 140)
	padText.TextScaled = true
	padText.TextStrokeTransparency = 0
	padText.Parent = padGui

	local pedestals = Instance.new("Folder")
	pedestals.Name = "Pedestals"
	local columns = { -9, 9, -18, 18 }
	for slot = 1, B.maxPedestals do
		local row = (slot - 1) // 4
		local lx = columns[(slot - 1) % 4 + 1]
		local px, pz = spec.x + lx, z(14 + row * 10)
		post(pedestals, "Base" .. slot, 6.4, 0.7, px, 0.75, pz, rgb(235, 235, 245))
		local top = post(pedestals, "P" .. slot, 5.6, 0.6, px, 1.4, pz, GOLD)
		top:SetAttribute("Slot", slot)
		top:SetAttribute("FaceX", if lx < 0 then 1 else -1)
		decor(post(pedestals, "Ring" .. slot, 6.8, 0.2, px, 0.5, pz, accent, NEON))
	end
	pedestals.Parent = booth

	booth:SetAttribute("X", spec.x)
	booth:SetAttribute("Side", spec.side)
	booth:SetAttribute("GateZ", z(0))
	booth.Parent = root
end

local function buildFerrisWheel(root: Instance, x: number, z: number)
	local ferris = Instance.new("Model")
	ferris.Name = "FerrisWheel"
	local hubY, radius = 40, 30
	for _, side in { -1, 1 } do
		make(ferris, "Leg", Enum.PartType.Block, Vector3.new(2, 46, 2), CFrame.new(x - 9, 20, z + side * 4) * CFrame.Angles(0, 0, math.rad(-24)), WHITE).CanCollide = false
		make(ferris, "Leg", Enum.PartType.Block, Vector3.new(2, 46, 2), CFrame.new(x + 9, 20, z + side * 4) * CFrame.Angles(0, 0, math.rad(24)), WHITE).CanCollide = false
	end
	local wheel = Instance.new("Model")
	wheel.Name = "Wheel"
	local hub = make(wheel, "Hub", Enum.PartType.Cylinder, Vector3.new(7, 7, 7), CFrame.new(x, hubY, z) * CFrame.Angles(0, math.pi / 2, 0), GOLD, NEON)
	wheel.PrimaryPart = hub
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		local dir = Vector3.new(math.cos(a), math.sin(a), 0)
		decor(make(wheel, "Spoke", Enum.PartType.Block, Vector3.new(radius, 0.8, 0.8), CFrame.new(x, hubY, z) * CFrame.Angles(0, 0, a) * CFrame.new(radius / 2, 0, 0), CANDY[i % #CANDY + 1], NEON))
		local rim = Vector3.new(x, hubY, z) + dir * radius
		decor(make(wheel, "Rim", Enum.PartType.Block, Vector3.new(0.9, radius * 0.53, 0.9), CFrame.new(rim) * CFrame.Angles(0, 0, a + math.rad(15)) * CFrame.new(0, radius * 0.26, 0), WHITE))
		decor(box(wheel, "Gondola", 5, 4, 4, rim.X, rim.Y - 2.5, rim.Z, CANDY[(i + 3) % #CANDY + 1]))
		decor(box(wheel, "GondolaRoof", 5.6, 0.7, 4.6, rim.X, rim.Y - 0.2, rim.Z, WHITE))
	end
	wheel.Parent = ferris
	ferris.Parent = root
end

local function buildTent(root: Instance, x: number, z: number, radius: number, a: Color3, b: Color3)
	local tent = Instance.new("Model")
	tent.Name = "BigTop"
	post(tent, "Drum", radius * 2, 10, x, 5, z, WHITE)
	for i = 0, 11 do
		local ang = i / 12 * math.pi * 2
		decor(make(tent, "DrumStripe", Enum.PartType.Block, Vector3.new(radius * 0.27, 10.1, 0.6), CFrame.new(x + math.sin(ang) * radius * 0.985, 5, z + math.cos(ang) * radius * 0.985) * CFrame.Angles(0, ang, 0), a))
	end
	for i = 0, 6 do
		decor(post(tent, "Roof", (radius * 2 + 4) * (1 - i / 7.4), 2.4, x, 11.2 + i * 2.4, z, if i % 2 == 0 then a else b))
	end
	decor(post(tent, "Mast", 0.6, 8, x, 30, z, GOLD))
	decor(box(tent, "Pennant", 5, 2.4, 0.2, x + 2.6, 32.6, z, a))
	decor(box(tent, "Door", radius * 0.5, 7, 0.8, x, 3.5, z - math.sign(z) * radius, rgb(60, 36, 90)))
	tent.Parent = root
end

local function buildCarousel(root: Instance, x: number, z: number)
	local carousel = Instance.new("Model")
	carousel.Name = "Carousel"
	post(carousel, "Stage", 34, 1.6, x, 0.8, z, PINK)
	post(carousel, "Core", 6, 14, x, 8.6, z, WHITE)
	local spin = Instance.new("Model")
	spin.Name = "Wheel"
	local roof = post(spin, "Canopy", 36, 1.4, x, 16, z, RED)
	spin.PrimaryPart = roof
	for i = 0, 5 do
		decor(post(spin, "CanopyTier", 30 - i * 5.4, 1.5, x, 17.4 + i * 1.5, z, if i % 2 == 0 then YELLOW else RED))
	end
	decor(orb(spin, "Finial", 3, x, 27.5, z, GOLD, NEON))
	for i = 0, 7 do
		local ang = i / 8 * math.pi * 2
		local hx, hz = x + math.sin(ang) * 13, z + math.cos(ang) * 13
		decor(post(spin, "Pole", 0.5, 14, hx, 8.6, hz, GOLD))
		local color = CANDY[i % #CANDY + 1]
		local y = 5 + (i % 2) * 2
		decor(make(spin, "Steed", Enum.PartType.Block, Vector3.new(2, 2.4, 5), CFrame.new(hx, y, hz) * CFrame.Angles(0, ang + math.pi / 2, 0), color))
		decor(make(spin, "SteedHead", Enum.PartType.Block, Vector3.new(1.6, 2.6, 1.8), CFrame.new(hx, y + 2, hz) * CFrame.Angles(0, ang + math.pi / 2, 0) * CFrame.new(0, 0, -2.2), color))
		decor(orb(spin, "CanopyBulb", 1.2, x + math.sin(ang) * 17.6, 15.6, z + math.cos(ang) * 17.6, YELLOW, NEON))
	end
	spin.Parent = carousel
	carousel.Parent = root
end

local function buildArch(root: Instance, x: number, text: string)
	local arch = Instance.new("Model")
	arch.Name = "TitleArch"
	local half = GameConfig.STREET.halfWidth + 3
	for _, side in { -1, 1 } do
		for i = 0, 10 do
			post(arch, "ArchPost", 3.4, 2.4, x, 1.2 + i * 2.4, side * half, if i % 2 == 0 then RED else WHITE)
		end
		decor(orb(arch, "ArchOrb", 5, x, 29, side * half, GOLD, NEON))
	end
	local board = box(arch, "TitleBoard", 1.6, 9, half * 2 + 4, x, 24.5, 0, rgb(60, 36, 90))
	board.CanCollide = false
	sign(board, Enum.NormalId.Right, text, YELLOW)
	sign(board, Enum.NormalId.Left, text, YELLOW)
	for i = -8, 8 do
		decor(orb(arch, "ArchBulb", 1.3, x, 30.2, i * 2.2, CANDY[(i + 8) % #CANDY + 1], NEON))
	end
	arch.Parent = root
end

local function buildScenery(root: Instance)
	local scenery = Instance.new("Model")
	scenery.Name = "Scenery"
	local rng = Random.new(2026)
	local S = GameConfig.STREET
	-- String lights down both kerbs.
	for _, side in { -1, 1 } do
		for x = S.xMin + 6, S.xMax - 6, 24 do
			local nearGate = false
			for _, spec in GameConfig.BOOTHS do
				if spec.side == side and math.abs(spec.x - x) < 11 then
					nearGate = true
				end
			end
			if not nearGate then
				decor(post(scenery, "LightPole", 0.7, 13, x, 6.5, side * (S.halfWidth + 1.2), WHITE))
				decor(orb(scenery, "PoleLamp", 2, x, 13.6, side * (S.halfWidth + 1.2), YELLOW, NEON))
			end
			for i = 1, 5 do
				local t = i / 6
				decor(orb(scenery, "StringBulb", 0.8, x + t * 24, 12.6 - math.sin(t * math.pi) * 2.2, side * (S.halfWidth + 1.2), CANDY[(i + x // 24) % #CANDY + 1], NEON))
			end
		end
	end
	-- Lollipop trees and balloon bunches fill the lawns behind and between the booths.
	for i = 1, 34 do
		local x, z
		repeat
			x, z = rng:NextNumber(-190, 190), rng:NextNumber(-170, 170)
			local onBooths = math.abs(z) < 84 and math.abs(x) < 118
			local onStreet = math.abs(z) < 24
		until not onBooths and not onStreet
		local color = CANDY[i % #CANDY + 1]
		if i % 3 == 0 then
			decor(post(scenery, "BalloonString", 0.12, 9, x, 4.5, z, WHITE))
			for j = 0, 2 do
				decor(orb(scenery, "Balloon", 3.4, x + (j - 1) * 2, 10 + (j % 2) * 1.6, z + (j - 1) * 0.6, CANDY[(i + j) % #CANDY + 1]))
			end
		else
			local h = rng:NextNumber(9, 15)
			decor(post(scenery, "LollipopStick", 0.8, h, x, h / 2, z, WHITE))
			decor(make(scenery, "Lollipop", Enum.PartType.Cylinder, Vector3.new(1.4, 7, 7), CFrame.new(x, h + 3, z) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), color))
			decor(make(scenery, "LollipopSwirl", Enum.PartType.Cylinder, Vector3.new(1.5, 4, 4), CFrame.new(x, h + 3, z) * CFrame.Angles(0, 0, 0), WHITE)).Transparency = 1
		end
	end
	-- Confetti on the ground.
	for i = 1, 220 do
		local c = decor(box(scenery, "Confetti", 0.9, 0.06, 0.5, rng:NextNumber(-160, 160), 0.36, rng:NextNumber(-100, 100), CANDY[i % #CANDY + 1]))
		c.CFrame *= CFrame.Angles(0, rng:NextNumber(0, 3), 0)
	end
	-- Candy fence, pastel hills and clouds close the horizon.
	for i = 0, 71 do
		local a = i / 72 * math.pi * 2
		decor(post(scenery, "FencePost", 2.4, 9, math.cos(a) * 214, 4.5, math.sin(a) * 196, if i % 2 == 0 then RED else WHITE))
	end
	for i = 0, 17 do
		local a = i / 18 * math.pi * 2
		local d = rng:NextNumber(90, 150)
		decor(orb(scenery, "Hill", d, math.cos(a) * 300, -d * 0.18, math.sin(a) * 290, ({ MINT, rgb(190, 236, 160), rgb(255, 200, 220), rgb(200, 220, 255) })[i % 4 + 1]))
	end
	for i = 1, 14 do
		local x, y, z = rng:NextNumber(-260, 260), rng:NextNumber(90, 130), rng:NextNumber(-260, 260)
		for j = 0, 3 do
			local puff = decor(orb(scenery, "Cloud", rng:NextNumber(18, 30), x + j * 14, y + (j % 2) * 5, z + (j % 2) * 4, WHITE))
			puff.Transparency = 0.15
		end
	end
	scenery.Parent = root
end

-- buildCarnival: the whole world under one model. Main calls it only when the place holds no baked Carnival.
function CarnivalBuilder.buildCarnival(parent: Instance): Model
	local root = Instance.new("Model")
	root.Name = "Carnival"
	buildStreet(root)
	buildBelt(root)
	buildCannon(root)
	buildPopcornMachine(root)
	local booths = Instance.new("Folder")
	booths.Name = "Booths"
	for index, spec in GameConfig.BOOTHS do
		buildBooth(booths, index, spec)
	end
	booths.Parent = root
	buildFerrisWheel(root, -42, 132)
	buildCarousel(root, 46, -128)
	buildTent(root, -150, 120, 22, RED, WHITE)
	buildTent(root, 150, 126, 20, PURPLE, YELLOW)
	buildTent(root, -146, -124, 20, SKY, WHITE)
	buildTent(root, 156, -118, 22, ORANGE, WHITE)
	buildTent(root, 60, 150, 16, PINK, WHITE)
	buildTent(root, -60, -152, 16, MINT, WHITE)
	buildArch(root, GameConfig.STREET.xMin + 2, GameConfig.TITLE)
	buildArch(root, GameConfig.STREET.xMax - 2, GameConfig.TITLE)
	buildScenery(root)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Size = Vector3.new(8, 0.4, 8)
	spawn.CFrame = CFrame.new(-20, 0.5, 10)
	spawn.Anchored = true
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Parent = root
	root.Parent = parent
	return root
end

-- dressLighting: a bright late-afternoon fairground sky.
function CarnivalBuilder.dressLighting()
	local Lighting = game:GetService("Lighting")
	Lighting.ClockTime = 15.6
	Lighting.GeographicLatitude = 28
	Lighting.Brightness = 3
	Lighting.Ambient = rgb(120, 110, 130)
	Lighting.OutdoorAmbient = rgb(170, 160, 170)
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 0.6
	Lighting.FogEnd = 100000
	for _, old in Lighting:GetChildren() do
		if old:IsA("PostEffect") or old:IsA("Atmosphere") then
			old:Destroy()
		end
	end
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Saturation = 0.28
	grade.Contrast = 0.08
	grade.TintColor = rgb(255, 246, 236)
	grade.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.35
	bloom.Size = 20
	bloom.Threshold = 1.6
	bloom.Parent = Lighting
	local air = Instance.new("Atmosphere")
	air.Density = 0.22
	air.Haze = 0.9
	air.Color = rgb(255, 226, 214)
	air.Decay = rgb(255, 190, 170)
	air.Parent = Lighting
end

return CarnivalBuilder
