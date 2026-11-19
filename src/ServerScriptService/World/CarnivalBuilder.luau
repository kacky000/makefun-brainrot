-- CarnivalBuilder: builds the whole 3D carnival from parts: the checkered midway, the Prize Belt
-- with its Prize Cannon and Popcorn Machine, six player booths (gate, lock lasers, 20 pedestals),
-- Ferris wheels, carousels, big tops, lollipop trees, balloons, bunting and lamps.
-- It only uses Instance.new and property writes, so tools/bake-world.luau can run it under lune
-- to bake world/Carnival.rbxm; at runtime Main builds it only if the baked copy is missing.

local CarnivalBuilder = {}

local rgb = Color3.fromRGB
local PINK, YELLOW, RED, WHITE = rgb(255, 150, 200), rgb(255, 226, 110), rgb(232, 50, 70), rgb(255, 252, 245)
local TEAL, PURPLE, INK, GOLD = rgb(70, 215, 215), rgb(170, 110, 255), rgb(40, 34, 54), rgb(255, 200, 60)
local BOOTH_COLORS = { rgb(255, 200, 220), rgb(190, 235, 255), rgb(215, 250, 190), rgb(255, 232, 170), rgb(225, 205, 255), rgb(180, 245, 230) }
local BULB_COLORS = { rgb(255, 80, 110), rgb(255, 220, 70), rgb(80, 220, 255), rgb(120, 255, 140), rgb(255, 130, 240) }
local UPRIGHT = CFrame.Angles(0, 0, math.pi / 2)

-- Small deterministic generator so the baked world and a runtime build are the same carnival.
local seed = 20261119
local function chance(): number
	seed = (seed * 1103515245 + 12345) % 2147483648
	return seed / 2147483648
end

local function make(parent, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		part.Shape = shape
	end
	part.Parent = parent
	return part
end

local function pillar(parent, name: string, height: number, diameter: number, base: Vector3, color: Color3, material: Enum.Material?)
	return make(parent, name, Vector3.new(height, diameter, diameter), CFrame.new(base + Vector3.new(0, height / 2, 0)) * UPRIGHT, color, material, Enum.PartType.Cylinder)
end

local function ball(parent, name: string, diameter: number, at: Vector3, color: Color3, material: Enum.Material?)
	local part = make(parent, name, Vector3.new(diameter, diameter, diameter), CFrame.new(at), color, material, Enum.PartType.Ball)
	part.CanCollide = false
	return part
end

local function group(parent, name: string)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	return model
end

-- Painted lettering on one face of a part.
local function letter(part, face: Enum.NormalId, text: string, textColor: Color3, name: string?)
	local gui = Instance.new("SurfaceGui")
	gui.Name = name or "Face"
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 24
	gui.LightInfluence = 0
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Name = "Title"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = textColor
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = INK
	label.Parent = gui
	return label
end

local function glowBulb(parent, at: Vector3, index: number, diameter: number?)
	return ball(parent, "Bulb", diameter or 0.9, at, BULB_COLORS[index % #BULB_COLORS + 1], Enum.Material.Neon)
end

local function buildGround(world)
	local ground = group(world, "Ground")
	make(ground, "Lawn", Vector3.new(460, 4, 420), CFrame.new(0, -2, 0), rgb(150, 226, 170), Enum.Material.Grass)
	-- Sugar-sand paths ringing the booths so no flat lawn fills a frame.
	for _, z in { -108, 108 } do
		make(ground, "Boardwalk", Vector3.new(400, 0.2, 14), CFrame.new(0, 0.1, z), rgb(255, 224, 190), Enum.Material.WoodPlanks)
	end
	for _, x in { -168, 168 } do
		make(ground, "Boardwalk", Vector3.new(14, 0.2, 230), CFrame.new(x, 0.1, 0), rgb(255, 224, 190), Enum.Material.WoodPlanks)
	end
	for _ = 1, 120 do
		local x, z = (chance() - 0.5) * 430, (chance() - 0.5) * 390
		local bit = make(ground, "Confetti", Vector3.new(0.9, 0.12, 0.5), CFrame.new(x, 0.3, z) * CFrame.Angles(0, chance() * 6, 0), BULB_COLORS[math.floor(chance() * 5) + 1], Enum.Material.Neon)
		bit.CanCollide = false
	end
end

local function buildMidway(world, Config)
	local street = group(world, "Midway")
	local halfLength, halfWidth = Config.STREET.halfLength, Config.STREET.halfWidth
	local tileX, tileZ = 12.5, 11
	for ix = 0, math.floor(halfLength * 2 / tileX) - 1 do
		for iz = 0, math.floor(halfWidth * 2 / tileZ) - 1 do
			-- A deep plum checker: the bright cast, the belt and the popcorn stand out against it.
			local color = if (ix + iz) % 2 == 0 then rgb(96, 58, 150) else rgb(72, 42, 118)
			make(street, "Tile", Vector3.new(tileX, 0.3, tileZ), CFrame.new(-halfLength + tileX * (ix + 0.5), 0.15, -halfWidth + tileZ * (iz + 0.5)), color)
		end
	end
	for _, z in { -halfWidth - 0.5, halfWidth + 0.5 } do
		make(street, "Curb", Vector3.new(halfLength * 2, 0.5, 1), CFrame.new(0, 0.25, z), WHITE)
	end
end

local function buildPrizeBelt(world, Config)
	local belt = group(world, "PrizeBelt")
	local b = Config.BELT
	local length = b.x1 - b.x0 + 10
	make(belt, "BeltBed", Vector3.new(length, 0.6, b.width), CFrame.new(0, b.top - 0.3, b.z), rgb(58, 52, 78), Enum.Material.Metal)
	make(belt, "BeltSkirt", Vector3.new(length, b.top - 0.6, b.width - 1.5), CFrame.new(0, (b.top - 0.6) / 2, b.z), rgb(120, 60, 160))
	for _, side in { -1, 1 } do
		make(belt, "Rail", Vector3.new(length, 0.7, 0.6), CFrame.new(0, b.top + 0.15, b.z + side * (b.width / 2 + 0.3)), RED)
	end
	local index = 0
	for x = b.x0, b.x1, 8 do
		index += 1
		local arrow = make(belt, "Chevron", Vector3.new(0.8, 0.08, b.width - 1.6), CFrame.new(x, b.top + 0.03, b.z) * CFrame.Angles(0, 0.5, 0), YELLOW, Enum.Material.Neon)
		arrow.CanCollide = false
		for _, side in { -1, 1 } do
			local stripe = make(belt, "RailStripe", Vector3.new(3, 0.74, 0.64), CFrame.new(x, b.top + 0.15, b.z + side * (b.width / 2 + 0.3)), WHITE)
			stripe.CanCollide = false
			glowBulb(belt, Vector3.new(x + 4, b.top + 0.8, b.z + side * (b.width / 2 + 0.3)), index + (if side > 0 then 2 else 0), 0.7)
		end
	end

	-- The Prize Cannon fires brainrots onto the west end of the belt.
	local cannon = group(world, "PrizeCannon")
	local cx = b.x0 - 13
	local aim = CFrame.new(cx, 9, 0) * CFrame.Angles(0, 0, 0.42)
	for band = 0, 4 do
		make(cannon, "Barrel", Vector3.new(4.4, 11 - band * 0.5, 11 - band * 0.5), aim * CFrame.new(-8 + band * 4.4, 0, 0), if band % 2 == 0 then RED else WHITE, nil, Enum.PartType.Cylinder)
	end
	make(cannon, "Muzzle", Vector3.new(1.6, 10.6, 10.6), aim * CFrame.new(12.4, 0, 0), GOLD, Enum.Material.Foil, Enum.PartType.Cylinder)
	make(cannon, "Bore", Vector3.new(0.4, 7.4, 7.4), aim * CFrame.new(13.1, 0, 0), INK, nil, Enum.PartType.Cylinder)
	for _, side in { -1, 1 } do
		make(cannon, "Wheel", Vector3.new(1.6, 11, 11), CFrame.new(cx - 2, 5.5, side * 7) * CFrame.Angles(0, math.pi / 2, 0), rgb(120, 76, 40), Enum.Material.Wood, Enum.PartType.Cylinder)
		make(cannon, "Hub", Vector3.new(1.9, 3.4, 3.4), CFrame.new(cx - 2, 5.5, side * 7) * CFrame.Angles(0, math.pi / 2, 0), GOLD, Enum.Material.Foil, Enum.PartType.Cylinder)
	end
	make(cannon, "Carriage", Vector3.new(16, 2.4, 12), CFrame.new(cx - 2, 3.4, 0), PURPLE)
	local cannonSign = make(cannon, "CannonSign", Vector3.new(1, 5, 26), CFrame.new(cx - 12, 20, 0), INK)
	letter(cannonSign, Enum.NormalId.Right, "PRIZE CANNON", YELLOW)
	for _, side in { -1, 1 } do
		pillar(cannon, "SignPost", 18, 1.2, Vector3.new(cx - 12, 0, side * 12), WHITE)
	end
	for star = 1, 8 do
		glowBulb(cannon, Vector3.new(cx - 11.3, 23.2, -14 + star * 3.1), star, 1.2)
	end

	-- The Popcorn Machine swallows prizes at the east end and overflows as the Popcorn Wave.
	local machine = group(world, "PopcornMachine")
	local mx = b.x1 + 17
	make(machine, "Cabinet", Vector3.new(22, 7, 24), CFrame.new(mx, 3.5, 0), RED)
	make(machine, "Trim", Vector3.new(22.6, 1, 24.6), CFrame.new(mx, 7.2, 0), GOLD, Enum.Material.Foil)
	local glass = make(machine, "Glass", Vector3.new(20, 18, 22), CFrame.new(mx, 16.5, 0), rgb(210, 240, 255), Enum.Material.Glass)
	glass.Transparency = 0.6
	make(machine, "Roof", Vector3.new(24, 3, 26), CFrame.new(mx, 27, 0), RED)
	make(machine, "RoofCap", Vector3.new(16, 2.4, 18), CFrame.new(mx, 29.6, 0), WHITE)
	local machineSign = make(machine, "MachineSign", Vector3.new(1, 5.6, 25), CFrame.new(mx - 12.2, 27.2, 0), YELLOW)
	letter(machineSign, Enum.NormalId.Left, "POPCORN", RED)
	make(machine, "Chute", Vector3.new(8, 1, 9), CFrame.new(mx - 13, 4.6, 0) * CFrame.Angles(0, 0, -0.5), GOLD, Enum.Material.Foil)
	for _ = 1, 70 do
		local kernel = ball(machine, "Kernel", 2.2 + chance() * 1.6, Vector3.new(mx + (chance() - 0.5) * 17, 8.5 + chance() * 11, (chance() - 0.5) * 19), if chance() < 0.3 then YELLOW else rgb(255, 250, 225))
		kernel.CanCollide = false
	end
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			make(machine, "Caster", Vector3.new(2, 5, 5), CFrame.new(mx + sx * 8, 2.5, sz * 12.4) * CFrame.Angles(0, math.pi / 2, 0), INK, nil, Enum.PartType.Cylinder)
		end
	end
end

-- One arch of lettering over an end of the midway.
local function buildTitleArch(world, Config, x: number, facing: Enum.NormalId)
	local arch = group(world, "TitleArch")
	local halfWidth = Config.STREET.halfWidth + 4
	for _, side in { -1, 1 } do
		for band = 0, 6 do
			pillar(arch, "ArchPost", 4, 4, Vector3.new(x, band * 4, side * halfWidth), if band % 2 == 0 then RED else WHITE)
		end
		ball(arch, "ArchBall", 6, Vector3.new(x, 30, side * halfWidth), GOLD, Enum.Material.Foil)
	end
	local board = make(arch, "TitleBoard", Vector3.new(2, 10, halfWidth * 2 - 2), CFrame.new(x, 30, 0), INK)
	letter(board, facing, Config.TITLE, YELLOW)
	local tag = make(arch, "TitleTag", Vector3.new(1.6, 3.6, 34), CFrame.new(x, 23, 0), RED)
	letter(tag, facing, Config.SUBTITLE, WHITE)
	for bulb = 0, 16 do
		glowBulb(arch, Vector3.new(x, 35.6, -halfWidth + 3 + bulb * (halfWidth * 2 - 6) / 16), bulb, 1.5)
	end
end

local function buildBooth(world, Config, boothIndex: number)
	local booth = group(world, "Booth" .. boothIndex)
	booth:SetAttribute("BoothIndex", boothIndex)
	local settings = Config.BOOTH
	local _, dir = Config.boothOrigin(boothIndex)
	local function point(across: number, depth: number, y: number?): Vector3
		return Config.boothPoint(boothIndex, across, depth, y)
	end
	local tint = BOOTH_COLORS[boothIndex]
	local halfWidth, depth = settings.halfWidth, settings.depth

	make(booth, "Floor", Vector3.new(halfWidth * 2, 0.3, depth), CFrame.new(point(0, depth / 2, 0.15)), tint)
	make(booth, "Carpet", Vector3.new(10, 0.1, depth - 2), CFrame.new(point(0, depth / 2, 0.35)), rgb(200, 30, 50), Enum.Material.Fabric)
	for _, side in { -1, 1 } do
		make(booth, "CarpetTrim", Vector3.new(0.6, 0.12, depth - 2), CFrame.new(point(side * 5.3, depth / 2, 0.36)), GOLD, Enum.Material.Foil)
	end

	-- Candy-striped low walls: two sides, the back, and the front either side of the gate.
	local bulb = 0
	local function wallRun(fromAcross: number, fromDepth: number, toAcross: number, toDepth: number, segments: number)
		for segment = 0, segments - 1 do
			local t = (segment + 0.5) / segments
			local across = fromAcross + (toAcross - fromAcross) * t
			local back = fromDepth + (toDepth - fromDepth) * t
			local alongAcross = math.abs(toAcross - fromAcross) > math.abs(toDepth - fromDepth)
			local length = (if alongAcross then math.abs(toAcross - fromAcross) else math.abs(toDepth - fromDepth)) / segments
			local size = if alongAcross then Vector3.new(length, 5, 1.4) else Vector3.new(1.4, 5, length)
			make(booth, "Wall", size, CFrame.new(point(across, back, 2.5)), if segment % 2 == 0 then RED else WHITE)
			bulb += 1
			glowBulb(booth, point(across, back, 5.6), bulb + boothIndex)
		end
	end
	wallRun(-halfWidth, 0.7, -halfWidth, depth, 8)
	wallRun(halfWidth, 0.7, halfWidth, depth, 8)
	wallRun(-halfWidth, depth, halfWidth, depth, 8)
	wallRun(-halfWidth, 0.7, -8, 0.7, 3)
	wallRun(8, 0.7, halfWidth, 0.7, 3)

	-- The gate: striped posts, a marquee sign on both faces and three lock lasers.
	for _, side in { -1, 1 } do
		for band = 0, 3 do
			pillar(booth, "GatePost", 3.5, 2.6, point(side * 8, 0.7, band * 3.5), if band % 2 == 0 then tint else WHITE)
		end
		ball(booth, "GateBall", 3.4, point(side * 8, 0.7, 15.4), GOLD, Enum.Material.Foil)
	end
	local sign = make(booth, "Sign", Vector3.new(20, 5, 1.2), CFrame.new(point(0, 0.7, 16.5)), INK)
	letter(sign, Enum.NormalId.Front, "BOOTH " .. boothIndex, YELLOW, "FaceFront")
	letter(sign, Enum.NormalId.Back, "BOOTH " .. boothIndex, YELLOW, "FaceBack")
	make(booth, "SignTrim", Vector3.new(21, 0.6, 1.6), CFrame.new(point(0, 0.7, 19.3)), tint)
	for laser = 1, 3 do
		local bar = make(booth, "Laser" .. laser, Vector3.new(14, 0.5, 0.5), CFrame.new(point(0, 0.7, laser * 2.6)), rgb(255, 30, 60), Enum.Material.Neon)
		bar.Transparency = 1
		bar.CanCollide = false
	end
	for _, side in { -1, 1 } do
		make(booth, "LaserEmitter", Vector3.new(1, 9, 1.6), CFrame.new(point(side * 6.6, 0.7, 4.8)), INK, Enum.Material.Metal)
	end

	-- The lock button stands just inside the gate.
	pillar(booth, "LockStand", 3.2, 1.6, point(-13, 5, 0.3), INK, Enum.Material.Metal)
	local button = make(booth, "LockButton", Vector3.new(0.8, 2.6, 2.6), CFrame.new(point(-13, 5, 3.9)) * UPRIGHT, RED, Enum.Material.Neon, Enum.PartType.Cylinder)
	button:SetAttribute("BoothIndex", boothIndex)

	-- Twenty pedestals in rows of four; locked ones are unlocked by the MORE PEDESTALS upgrade.
	for slot = 1, Config.MAX_PEDESTALS do
		local at = Config.pedestalPosition(boothIndex, slot)
		pillar(booth, "PedestalBase", 0.7, 6, at + Vector3.new(0, 0.3, 0), GOLD, Enum.Material.Foil)
		local top = pillar(booth, string.format("Pedestal%02d", slot), 0.6, 5, at + Vector3.new(0, 1.0, 0), WHITE)
		top:SetAttribute("Slot", slot)
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Size = Vector3.new(7, 0.3, 7)
	spawn.CFrame = CFrame.new(point(0, 7, 0.5)) * CFrame.Angles(0, if dir > 0 then 0 else math.pi, 0)
	spawn.Color = GOLD
	spawn.Material = Enum.Material.Neon
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = booth

	-- A striped backdrop tent behind the booth and pennant poles on its corners.
	for panel = 0, 7 do
		make(booth, "Backdrop", Vector3.new(halfWidth * 2 / 8, 16 + (if panel % 2 == 0 then 0 else 1.5), 1), CFrame.new(point(-halfWidth + (panel + 0.5) * halfWidth * 2 / 8, depth + 1.6, 8)), if panel % 2 == 0 then tint else WHITE)
	end
	for _, side in { -1, 1 } do
		pillar(booth, "PennantPole", 22, 0.8, point(side * halfWidth, depth, 0), WHITE)
		make(booth, "Pennant", Vector3.new(0.3, 3, 5), CFrame.new(point(side * halfWidth, depth - 2.6 * 0, 20.4)) * CFrame.new(0, 0, 2.6 * dir), BULB_COLORS[(boothIndex + side + 5) % 5 + 1])
	end
end

local function buildFerrisWheel(world, x: number, z: number, facing: number)
	local wheel = group(world, "FerrisWheel")
	local hub = Vector3.new(x, 44, z)
	local radius = 36
	for _, side in { -1, 1 } do
		for _, lean in { -1, 1 } do
			make(wheel, "Leg", Vector3.new(2.4, 50, 2.4), CFrame.new(x + lean * 11, 22, z + side * 5) * CFrame.Angles(0, 0, lean * 0.42), WHITE)
		end
	end
	make(wheel, "Axle", Vector3.new(5, 5, 14), CFrame.new(hub), GOLD, Enum.Material.Foil)
	local cars = 12
	for step = 0, cars * 2 - 1 do
		local angle = step / (cars * 2) * math.pi * 2
		local rimAt = hub + Vector3.new(math.cos(angle) * radius, math.sin(angle) * radius, 0)
		for _, side in { -1, 1 } do
			make(wheel, "Rim", Vector3.new(1.2, radius * 2 * math.pi / (cars * 2) + 0.6, 1.2), CFrame.new(rimAt + Vector3.new(0, 0, side * 4)) * CFrame.Angles(0, 0, angle), if step % 2 == 0 then PINK else TEAL)
		end
		glowBulb(wheel, rimAt + Vector3.new(0, 0, facing * 5), step, 1.8)
		if step % 2 == 0 then
			local mid = hub + Vector3.new(math.cos(angle) * radius / 2, math.sin(angle) * radius / 2, 0)
			make(wheel, "Spoke", Vector3.new(radius, 0.7, 0.7), CFrame.new(mid) * CFrame.Angles(0, 0, angle), WHITE)
			local carAt = rimAt + Vector3.new(0, -4, 0)
			local color = BULB_COLORS[(step / 2) % 5 + 1]
			make(wheel, "Gondola", Vector3.new(6, 4, 6), CFrame.new(carAt), color)
			make(wheel, "GondolaRoof", Vector3.new(7, 0.8, 7), CFrame.new(carAt + Vector3.new(0, 3.4, 0)), WHITE)
		end
	end
end

local function buildCarousel(world, x: number, z: number)
	local carousel = group(world, "Carousel")
	pillar(carousel, "Deck", 2, 40, Vector3.new(x, 0, z), PINK)
	pillar(carousel, "DeckTrim", 0.6, 42, Vector3.new(x, 0, z), GOLD, Enum.Material.Foil)
	pillar(carousel, "Mast", 22, 5, Vector3.new(x, 2, z), WHITE)
	for tier = 0, 4 do
		pillar(carousel, "Canopy", 2.4, 44 - tier * 9.5, Vector3.new(x, 22 + tier * 2.4, z), if tier % 2 == 0 then RED else WHITE)
	end
	ball(carousel, "Finial", 5, Vector3.new(x, 36, z), GOLD, Enum.Material.Foil)
	for horse = 0, 7 do
		local angle = horse / 8 * math.pi * 2
		local at = Vector3.new(x + math.cos(angle) * 15, 0, z + math.sin(angle) * 15)
		local turn = CFrame.new(at) * CFrame.Angles(0, -angle, 0)
		local bob = if horse % 2 == 0 then 6 else 8
		pillar(carousel, "Pole", 20, 0.6, at + Vector3.new(0, 2, 0), GOLD, Enum.Material.Foil)
		local coat = BULB_COLORS[horse % 5 + 1]
		make(carousel, "Pony", Vector3.new(2.2, 2.6, 5.2), turn * CFrame.new(0, bob, 0), coat)
		make(carousel, "PonyHead", Vector3.new(1.8, 2.4, 2.2), turn * CFrame.new(0, bob + 2, -2.6), coat)
		make(carousel, "PonyMane", Vector3.new(0.6, 2.6, 1.4), turn * CFrame.new(0, bob + 2.4, -1.6), WHITE)
		glowBulb(carousel, Vector3.new(x + math.cos(angle) * 21, 22.4, z + math.sin(angle) * 21), horse, 1.6)
	end
end

local function buildBigTop(world, x: number, z: number, primary: Color3)
	local tent = group(world, "BigTop")
	pillar(tent, "TentWall", 12, 58, Vector3.new(x, 0, z), WHITE)
	for stripe = 0, 11 do
		local angle = stripe / 12 * math.pi * 2
		make(tent, "TentStripe", Vector3.new(7.6, 12.2, 1), CFrame.new(x + math.cos(angle) * 28.7, 6.1, z + math.sin(angle) * 28.7) * CFrame.Angles(0, -angle + math.pi / 2, 0), primary)
	end
	for tier = 0, 6 do
		pillar(tent, "TentRoof", 3.4, 62 - tier * 9.4, Vector3.new(x, 12 + tier * 3.4, z), if tier % 2 == 0 then primary else WHITE)
	end
	pillar(tent, "TentMast", 10, 0.9, Vector3.new(x, 35, z), INK)
	make(tent, "TentFlag", Vector3.new(7, 4, 0.3), CFrame.new(x + 3.5, 43, z), GOLD)
end

local function buildLollipopTree(world, x: number, z: number, index: number)
	local tree = group(world, "LollipopTree")
	local height = 13 + (index % 3) * 3
	pillar(tree, "Stick", height, 1.1, Vector3.new(x, 0, z), WHITE)
	local swirl = BULB_COLORS[index % 5 + 1]
	local turn = CFrame.new(x, height + 4, z) * CFrame.Angles(0, index * 0.9, 0)
	make(tree, "Candy", Vector3.new(2, 10, 10), turn, swirl, nil, Enum.PartType.Cylinder)
	make(tree, "CandySwirl", Vector3.new(2.2, 6.4, 6.4), turn, WHITE, nil, Enum.PartType.Cylinder)
	make(tree, "CandyCore", Vector3.new(2.4, 3, 3), turn, swirl, nil, Enum.PartType.Cylinder)
end

local function buildBalloons(world, x: number, z: number, index: number)
	local bunch = group(world, "Balloons")
	pillar(bunch, "Weight", 1.4, 2.4, Vector3.new(x, 0, z), INK)
	for balloon = 1, 5 do
		local sway = Vector3.new(math.cos(balloon * 1.3 + index) * 2.6, 11 + balloon * 1.7, math.sin(balloon * 1.3 + index) * 2.6)
		local string = make(bunch, "String", Vector3.new(0.12, sway.Y - 1.6, 0.12), CFrame.new(x + sway.X / 2, sway.Y / 2 + 0.2, z + sway.Z / 2) * CFrame.Angles(sway.Z / sway.Y, 0, -sway.X / sway.Y), WHITE)
		string.CanCollide = false
		ball(bunch, "Balloon", 4, Vector3.new(x, 0, z) + sway, BULB_COLORS[(balloon + index) % 5 + 1], Enum.Material.SmoothPlastic).Reflectance = 0.2
	end
end

local function buildLampAndBunting(world, Config, x: number)
	local lamps = group(world, "LampRow")
	local reach = Config.STREET.halfWidth + 1.6
	for _, side in { -1, 1 } do
		pillar(lamps, "LampPost", 17, 0.9, Vector3.new(x, 0, side * reach), INK, Enum.Material.Metal)
		local lamp = ball(lamps, "Lamp", 3, Vector3.new(x, 18, side * reach), rgb(255, 240, 190), Enum.Material.Neon)
		local light = Instance.new("PointLight")
		light.Color = rgb(255, 225, 170)
		light.Range = 36
		light.Brightness = 0.8
		light.Parent = lamp
	end
	for flag = 1, 13 do
		local t = flag / 14
		local sag = math.sin(t * math.pi) * 3.2
		local pennant = make(lamps, "Bunting", Vector3.new(0.2, 2.4, 2.2), CFrame.new(x, 16.6 - sag, -reach + t * reach * 2), BULB_COLORS[flag % 5 + 1])
		pennant.CanCollide = false
	end
end

local function buildFence(world)
	local fence = group(world, "Fence")
	local halfX, halfZ = 226, 206
	for _, z in { -halfZ, halfZ } do
		make(fence, "FenceRail", Vector3.new(halfX * 2, 1, 1), CFrame.new(0, 5, z), WHITE)
		for x = -halfX, halfX, 18 do
			pillar(fence, "FencePost", 7, 1.6, Vector3.new(x, 0, z), if (x / 18) % 2 == 0 then PINK else TEAL)
		end
	end
	for _, x in { -halfX, halfX } do
		make(fence, "FenceRail", Vector3.new(1, 1, halfZ * 2), CFrame.new(x, 5, 0), WHITE)
		for z = -halfZ, halfZ, 18 do
			pillar(fence, "FencePost", 7, 1.6, Vector3.new(x, 0, z), if (z / 18) % 2 == 0 then PINK else TEAL)
		end
	end
end

-- Builds the whole carnival under `parent` and returns it. Config is GameConfig.
function CarnivalBuilder.buildCarnival(parent, Config)
	seed = 20261119
	local world = Instance.new("Folder")
	world.Name = "Carnival"
	buildGround(world)
	buildMidway(world, Config)
	buildPrizeBelt(world, Config)
	buildTitleArch(world, Config, -Config.STREET.halfLength + 2, Enum.NormalId.Right)
	buildTitleArch(world, Config, Config.STREET.halfLength + 14, Enum.NormalId.Left)
	for boothIndex = 1, Config.BOOTH_COUNT do
		buildBooth(world, Config, boothIndex)
	end
	buildFerrisWheel(world, -52, 150, -1)
	buildFerrisWheel(world, 52, -150, 1)
	buildCarousel(world, 60, 140)
	buildCarousel(world, -60, -140)
	buildBigTop(world, 150, 150, RED)
	buildBigTop(world, -150, -150, PURPLE)
	buildBigTop(world, -160, 150, TEAL)
	buildBigTop(world, 160, -150, rgb(255, 150, 60))
	local trees = 0
	for _, z in { -98, 98 } do
		for x = -190, 190, 38 do
			trees += 1
			buildLollipopTree(world, x, z + (if trees % 2 == 0 then 6 else -2), trees)
		end
	end
	for _, x in { -196, 196 } do
		for z = -70, 70, 35 do
			trees += 1
			buildLollipopTree(world, x, z, trees)
		end
	end
	local bunches = 0
	for _, x in { -42, 42, -126, 126 } do
		buildLampAndBunting(world, Config, x)
		for _, z in { -40, 40 } do
			bunches += 1
			buildBalloons(world, x, z + (if z > 0 then 30 else -30), bunches)
		end
	end
	buildFence(world)
	world.Parent = parent
	return world
end

-- Evening carnival light: warm sun, thin haze, a little bloom. Runs on the server at start.
function CarnivalBuilder.dressLighting(lighting)
	lighting.ClockTime = 16.6
	lighting.GeographicLatitude = 28
	lighting.Brightness = 2.1
	lighting.ExposureCompensation = -0.12
	lighting.Ambient = rgb(120, 110, 140)
	lighting.OutdoorAmbient = rgb(170, 160, 180)
	lighting.ColorShift_Top = rgb(255, 214, 170)
	lighting.EnvironmentDiffuseScale = 0.6
	lighting.EnvironmentSpecularScale = 0.5
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.13
	atmosphere.Offset = 0.2
	atmosphere.Color = rgb(255, 214, 220)
	atmosphere.Decay = rgb(255, 170, 150)
	atmosphere.Glare = 0
	atmosphere.Haze = 0.4
	atmosphere.Parent = lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.2
	bloom.Size = 20
	bloom.Threshold = 1.3
	bloom.Parent = lighting
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Saturation = 0.22
	grade.Contrast = 0.08
	grade.TintColor = rgb(255, 246, 240)
	grade.Parent = lighting
end

return CarnivalBuilder
