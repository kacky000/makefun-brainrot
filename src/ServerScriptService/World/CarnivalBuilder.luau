-- CarnivalBuilder: builds the whole 3D carnival from parts: the midway street, the Prize Belt, the Prize Cannon,
-- the Popcorn Machine, six booths (walls, gate, lasers, lock button, 20 pedestals), rides, tents, lights, confetti.
-- It only uses Instance.new and plain datatypes, so tools/bake-world.luau can run it outside Roblox as well.
local CarnivalBuilder = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local PLUM = rgb(72, 42, 118)
local PLUM_LIGHT = rgb(96, 58, 150)
local CANDY_RED = rgb(235, 60, 80)
local CREAM = rgb(255, 244, 224)
local GOLD = rgb(255, 205, 60)
local INK = rgb(34, 26, 50)
local PARTY = { rgb(255, 90, 120), rgb(80, 200, 255), rgb(255, 220, 70), rgb(120, 230, 130), rgb(200, 130, 255), rgb(255, 150, 60) }
local BOOTH_FLOORS = { rgb(52, 92, 138), rgb(118, 50, 108), rgb(40, 104, 100), rgb(126, 72, 48), rgb(84, 60, 150), rgb(44, 100, 66) }

-- A tiny repeatable random, so the baked world is the same on every build.
local seed = 20261120
local function rand(low, high)
	seed = (seed * 1103515245 + 12345) % 2147483648
	return low + (high - low) * (seed / 2147483648)
end

local function make(parent, name, size, cframe, color, material, shape)
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

local function block(parent, name, sx, sy, sz, x, y, z, color, material)
	return make(parent, name, Vector3.new(sx, sy, sz), CFrame.new(x, y, z), color, material)
end

-- An upright cylinder standing on y.
local function pillar(parent, name, diameter, height, x, y, z, color, material)
	return make(parent, name, Vector3.new(height, diameter, diameter), CFrame.new(x, y + height / 2, z) * CFrame.Angles(0, 0, math.rad(90)), color, material, Enum.PartType.Cylinder)
end

local function sphere(parent, name, diameter, x, y, z, color, material)
	return make(parent, name, Vector3.new(diameter, diameter, diameter), CFrame.new(x, y, z), color, material, Enum.PartType.Ball)
end

local function decor(part)
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	return part
end

local function folder(parent, name)
	local group = Instance.new("Folder")
	group.Name = name
	group.Parent = parent
	return group
end

-- A sign face: text on one face of a part.
local function signText(part, face, text, color, pixelsPerStud)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SignGui"
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pixelsPerStud or 24
	gui.LightInfluence = 0
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Name = "Title"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.TextStrokeColor3 = INK
	label.TextStrokeTransparency = 0
	label.Parent = gui
	return label
end

local function buildGroundAndStreet(root, Config)
	local ground = folder(root, "Ground")
	block(ground, "Base", 520, 2, 360, 0, -1, 0, rgb(56, 34, 96))
	local street = Config.STREET
	local tile = 11
	local columns = math.floor((street.maxX - street.minX) / tile)
	for column = 0, columns - 1 do
		for row = 0, 3 do
			local color = ((column + row) % 2 == 0) and PLUM_LIGHT or PLUM
			block(ground, "StreetTile", tile, 0.2, tile, street.minX + tile / 2 + column * tile, 0.1, -16.5 + row * tile, color)
		end
	end
	-- Candy-striped kerbs down both edges of the street.
	for index = 0, 43 do
		local x = street.minX + 4 + index * 8
		for _, side in { -1, 1 } do
			block(ground, "Kerb", 8, 0.5, 1.2, x, 0.25, side * (street.halfWidth + 0.6), (index % 2 == 0) and CANDY_RED or CREAM)
		end
	end
	-- Lawns of plum and teal behind the booths, so the edge of the world is never one flat colour.
	for _, side in { -1, 1 } do
		for index = 0, 7 do
			block(ground, "Lawn", 65, 0.12, 62, -227.5 + index * 65, 0.06, side * 128, (index % 2 == 0) and rgb(38, 96, 104) or rgb(64, 50, 130))
		end
	end
end

local function buildPrizeBelt(root, Config)
	local belt = folder(root, "PrizeBelt")
	local spec = Config.BELT
	local length = spec.endX - spec.startX
	block(belt, "BeltBed", length, spec.topY - 0.1, 7, 0, (spec.topY - 0.1) / 2, 0, INK)
	block(belt, "BeltSurface", length, 0.12, 5.4, 0, spec.topY - 0.04, 0, rgb(60, 52, 84)).Material = Enum.Material.DiamondPlate
	for index = 0, math.floor(length / 6.5) - 1 do
		local x = spec.startX + 3.25 + index * 6.5
		local arrow = decor(block(belt, "BeltArrow", 1.6, 0.06, 3.6, x, spec.topY + 0.04, 0, rgb(255, 226, 90), Enum.Material.Neon))
		arrow.Transparency = 0.2
		for _, side in { -1, 1 } do
			block(belt, "BeltRail", 6.5, 0.5, 0.6, x, spec.topY + 0.15, side * 3.2, (index % 2 == 0) and CANDY_RED or CREAM)
		end
	end
end

local function buildPrizeCannon(root, Config)
	local cannon = folder(root, "PrizeCannon")
	local x = Config.BELT.startX - 12
	block(cannon, "Stage", 26, 2, 26, x, 1, 0, rgb(120, 52, 150))
	block(cannon, "StageTrim", 27, 0.5, 27, x, 2.2, 0, GOLD)
	for _, side in { -1, 1 } do
		make(cannon, "Wheel", Vector3.new(1.6, 9, 9), CFrame.new(x - 2, 6.6, side * 6.2) * CFrame.Angles(0, math.rad(90), 0), rgb(120, 74, 40), nil, Enum.PartType.Cylinder)
		make(cannon, "WheelHub", Vector3.new(1.9, 3, 3), CFrame.new(x - 2, 6.6, side * 6.2) * CFrame.Angles(0, math.rad(90), 0), GOLD, nil, Enum.PartType.Cylinder)
	end
	local barrelFrame = CFrame.new(x + 3, 10.5, 0) * CFrame.Angles(0, 0, math.rad(22))
	make(cannon, "Barrel", Vector3.new(22, 9, 9), barrelFrame, CANDY_RED, nil, Enum.PartType.Cylinder)
	for index = 0, 3 do
		make(cannon, "BarrelBand", Vector3.new(1.2, 9.6, 9.6), barrelFrame * CFrame.new(-8 + index * 5.5, 0, 0), (index % 2 == 0) and GOLD or CREAM, nil, Enum.PartType.Cylinder)
	end
	make(cannon, "Muzzle", Vector3.new(1.4, 11, 11), barrelFrame * CFrame.new(11, 0, 0), GOLD, nil, Enum.PartType.Cylinder)
	decor(make(cannon, "MuzzleGlow", Vector3.new(0.6, 8, 8), barrelFrame * CFrame.new(11.6, 0, 0), rgb(255, 240, 150), Enum.Material.Neon, Enum.PartType.Cylinder))
	for index = 1, 10 do
		decor(sphere(cannon, "CannonStar", 1.2, x + rand(-11, 11), 2.9, rand(-11, 11), PARTY[index % #PARTY + 1], Enum.Material.Neon))
	end
	local sign = block(cannon, "CannonSign", 24, 5, 1, x, 25, 0, rgb(60, 30, 100))
	sign.CFrame = CFrame.new(x, 25, 0) * CFrame.Angles(0, math.rad(90), 0)
	signText(sign, Enum.NormalId.Front, "PRIZE CANNON", GOLD)
	signText(sign, Enum.NormalId.Back, "PRIZE CANNON", GOLD)
	for _, side in { -1, 1 } do
		pillar(cannon, "SignPost", 1, 22, x, 2, side * 11.4, CREAM)
	end
end

local function buildPopcornMachine(root, Config)
	local machine = folder(root, "PopcornMachine")
	local x = Config.BELT.endX + 14
	block(machine, "Cart", 26, 8, 22, x, 4, 0, CANDY_RED)
	block(machine, "CartTrim", 27, 1, 23, x, 8.4, 0, GOLD)
	for index = 0, 5 do
		block(machine, "CartStripe", 2, 7.6, 22.3, x - 10.5 + index * 4.2, 4, 0, CREAM)
	end
	local glass = block(machine, "Glass", 24, 14, 20, x, 15.8, 0, rgb(190, 235, 255), Enum.Material.Glass)
	glass.Transparency = 0.6
	for _ = 1, 110 do
		local kernel = decor(sphere(machine, "Popcorn", rand(1.6, 2.8), x + rand(-10, 10), rand(9.6, 16), rand(-8, 8), (rand(0, 1) > 0.35) and rgb(255, 248, 226) or rgb(255, 214, 90)))
		kernel.Material = Enum.Material.SmoothPlastic
	end
	for index = 0, 6 do
		block(machine, "Roof", 28 - index * 3.6, 1.4, 24 - index * 3, x, 23.4 + index * 1.4, 0, (index % 2 == 0) and CANDY_RED or CREAM)
	end
	sphere(machine, "RoofBall", 3, x, 34, 0, GOLD)
	local sign = block(machine, "MachineSign", 22, 4.4, 0.8, x - 13.6, 12, 0, rgb(60, 30, 100))
	sign.CFrame = CFrame.new(x - 13.6, 13, 0) * CFrame.Angles(0, math.rad(90), 0)
	signText(sign, Enum.NormalId.Front, "POPCORN MACHINE", rgb(255, 240, 150))
	for _, side in { -1, 1 } do
		make(machine, "CartWheel", Vector3.new(1.4, 8, 8), CFrame.new(x + 4, 4, side * 11.6) * CFrame.Angles(0, math.rad(90), 0), INK, nil, Enum.PartType.Cylinder)
	end
end

-- The title arch that spans the street at each end.
local function buildTitleArch(root, Config, x, name)
	local arch = folder(root, name)
	local half = Config.STREET.halfWidth + 5
	for _, side in { -1, 1 } do
		for index = 0, 6 do
			pillar(arch, "ArchPost", 4.4, 4, x, index * 4, side * half, (index % 2 == 0) and CANDY_RED or CREAM)
		end
		sphere(arch, "ArchBall", 6, x, 31, side * half, GOLD)
	end
	local beam = block(arch, "ArchBeam", 2.4, 9, half * 2 + 4, x, 33, 0, rgb(60, 30, 100))
	signText(beam, Enum.NormalId.Left, Config.TITLE, GOLD, 16)
	signText(beam, Enum.NormalId.Right, Config.TITLE, GOLD, 16)
	block(arch, "ArchTrim", 2.8, 1, half * 2 + 5, x, 38, 0, GOLD)
	for index = 0, 13 do
		for _, face in { -1, 1 } do
			decor(sphere(arch, "ArchBulb", 1.3, x + face * 1.5, 39.2, -half + 2 + index * (half * 2 - 4) / 13, PARTY[index % #PARTY + 1], Enum.Material.Neon))
		end
	end
end

local function buildFerrisWheel(root, x, z)
	local wheel = folder(root, "FerrisWheel")
	local hubY, radius = 46, 36
	for _, side in { -1, 1 } do
		make(wheel, "Leg", Vector3.new(3, 52, 3), CFrame.new(x - 12, hubY / 2, z + side * 5) * CFrame.Angles(0, 0, math.rad(-14)), CREAM)
		make(wheel, "Leg", Vector3.new(3, 52, 3), CFrame.new(x + 12, hubY / 2, z + side * 5) * CFrame.Angles(0, 0, math.rad(14)), CREAM)
	end
	make(wheel, "Hub", Vector3.new(12, 8, 8), CFrame.new(x, hubY, z) * CFrame.Angles(0, math.rad(90), 0), GOLD, nil, Enum.PartType.Cylinder)
	for index = 0, 15 do
		local angle = index / 16 * math.pi * 2
		local dx, dy = math.cos(angle), math.sin(angle)
		decor(make(wheel, "Spoke", Vector3.new(radius, 1, 1), CFrame.new(x + dx * radius / 2, hubY + dy * radius / 2, z) * CFrame.Angles(0, 0, angle), PARTY[index % #PARTY + 1], Enum.Material.Neon))
		local next = (index + 1) / 16 * math.pi * 2
		local mx, my = (dx + math.cos(next)) / 2, (dy + math.sin(next)) / 2
		decor(make(wheel, "Rim", Vector3.new(radius * 0.4, 1.6, 1.6), CFrame.new(x + mx * radius, hubY + my * radius, z) * CFrame.Angles(0, 0, (angle + next) / 2 + math.pi / 2), CREAM))
		local cabin = block(wheel, "Gondola", 7, 6, 6, x + dx * radius, hubY + dy * radius - 4, z, PARTY[(index + 2) % #PARTY + 1])
		decor(cabin)
		decor(block(wheel, "GondolaRoof", 8, 1, 7, x + dx * radius, hubY + dy * radius - 0.6, z, CREAM))
		decor(sphere(wheel, "WheelBulb", 2, x + dx * (radius + 2), hubY + dy * (radius + 2), z - 1.5, rgb(255, 240, 160), Enum.Material.Neon))
	end
end

local function buildCarousel(root, x, z)
	local carousel = folder(root, "Carousel")
	pillar(carousel, "Deck", 44, 2, x, 0, z, rgb(255, 150, 190))
	pillar(carousel, "DeckTrim", 46, 0.6, x, 0, z, GOLD)
	pillar(carousel, "Core", 8, 22, x, 2, z, CREAM)
	for index = 0, 9 do
		local angle = index / 10 * math.pi * 2
		local px, pz = x + math.cos(angle) * 17, z + math.sin(angle) * 17
		pillar(carousel, "Pole", 0.6, 20, px, 2, pz, GOLD)
		local lift = (index % 2) * 2.5
		decor(block(carousel, "PonyBody", 5, 2.6, 2, px, 6.5 + lift, pz, PARTY[index % #PARTY + 1]))
		decor(block(carousel, "PonyHead", 1.8, 2.6, 1.6, px + 2.6, 8.4 + lift, pz, PARTY[index % #PARTY + 1]))
		decor(block(carousel, "PonyLegs", 4, 2, 1.2, px, 4.4 + lift, pz, CREAM))
	end
	for index = 0, 7 do
		pillar(carousel, "Canopy", 50 - index * 6, 1.6, x, 22 + index * 1.6, z, (index % 2 == 0) and CANDY_RED or CREAM)
	end
	sphere(carousel, "CanopyBall", 4, x, 36.5, z, GOLD)
	for index = 0, 19 do
		local angle = index / 20 * math.pi * 2
		decor(sphere(carousel, "CanopyBulb", 1.6, x + math.cos(angle) * 25, 21.6, z + math.sin(angle) * 25, PARTY[index % #PARTY + 1], Enum.Material.Neon))
	end
end

local function buildBigTop(root, x, z, colorA, colorB, scale)
	local tent = folder(root, "BigTop")
	for index = 0, 5 do
		pillar(tent, "TentWall", 40 * scale, 3 * scale, x, index * 3 * scale, z, (index % 2 == 0) and colorA or colorB)
	end
	for index = 0, 8 do
		pillar(tent, "TentRoof", (44 - index * 5) * scale, 2.2 * scale, x, (18 + index * 2.2) * scale, z, (index % 2 == 0) and colorB or colorA)
	end
	pillar(tent, "TentMast", 0.8 * scale, 8 * scale, x, 37.8 * scale, z, INK)
	decor(block(tent, "TentFlag", 5 * scale, 2.6 * scale, 0.3, x + 2.6 * scale, 44 * scale, z, GOLD))
end

-- Lollipop trees, balloon bunches, light strings over the street and confetti on the ground.
local function buildDecor(root, Config)
	local decorFolder = folder(root, "Decor")
	local street = Config.STREET
	for index = 0, 15 do
		local x = street.minX + 16 + index * 21.5
		for _, side in { -1, 1 } do
			local nearGate = false
			for _, booth in Config.BOOTHS do
				if booth.dir == side and math.abs(booth.x - x) < 31 then
					nearGate = true
				end
			end
			if not nearGate then
				local z = side * (street.halfWidth + 2.6)
				pillar(decorFolder, "LollipopStick", 0.8, 9, x, 0, z, CREAM)
				local candy = make(decorFolder, "LollipopCandy", Vector3.new(1.2, 6.5, 6.5), CFrame.new(x, 11.5, z), PARTY[index % #PARTY + 1], nil, Enum.PartType.Cylinder)
				decor(make(decorFolder, "LollipopSwirl", Vector3.new(1.3, 3.4, 3.4), CFrame.new(x, 11.5, z), CREAM, nil, Enum.PartType.Cylinder))
				decor(candy)
			end
		end
	end
	-- Light strings: poles on both kerbs with a sagging row of bulbs across the street.
	for index, x in { -160, -138, -46, 46, 138, 160 } do
		for _, side in { -1, 1 } do
			pillar(decorFolder, "LightPole", 0.9, 19, x, 0, side * (street.halfWidth + 1.2), rgb(60, 30, 100))
			sphere(decorFolder, "LightPoleCap", 1.8, x, 19.6, side * (street.halfWidth + 1.2), GOLD)
		end
		for bulb = 0, 12 do
			local t = bulb / 12
			local sag = 4 * (1 - (2 * t - 1) ^ 2)
			decor(sphere(decorFolder, "StreetBulb", 1.1, x, 18.6 - sag, -street.halfWidth - 1.2 + t * (street.halfWidth * 2 + 2.4), PARTY[(bulb + index) % #PARTY + 1], Enum.Material.Neon))
		end
	end
	-- Balloon bunches tied along the back lawns and between booths.
	for index = 1, 30 do
		local x, z = rand(-215, 215), (rand(0, 1) > 0.5 and 1 or -1) * rand(100, 150)
		decor(block(decorFolder, "BalloonString", 0.15, 12, 0.15, x, 6, z, CREAM))
		for cluster = 1, 3 do
			decor(sphere(decorFolder, "Balloon", rand(3.4, 4.6), x + rand(-2, 2), 12 + cluster * 2.2, z + rand(-2, 2), PARTY[(index + cluster) % #PARTY + 1]))
		end
	end
	for _ = 1, 230 do
		local piece = decor(block(decorFolder, "Confetti", rand(0.5, 1), 0.06, rand(0.3, 0.6), rand(street.minX, street.maxX), 0.24, rand(-street.halfWidth, street.halfWidth), PARTY[math.floor(rand(1, #PARTY + 0.99))]))
		piece.CFrame = piece.CFrame * CFrame.Angles(0, rand(0, math.pi), 0)
	end
	-- Snack stalls in the gaps between booths.
	for _, side in { -1, 1 } do
		for index, x in { -46, 46, -150, 150 } do
			local z = side * 50
			block(decorFolder, "StallCounter", 16, 4, 8, x, 2, z, PARTY[(index + (side > 0 and 0 or 3)) % #PARTY + 1])
			block(decorFolder, "StallTop", 17, 0.6, 9, x, 4.3, z, CREAM)
			for _, corner in { -1, 1 } do
				pillar(decorFolder, "StallPost", 0.7, 9, x + corner * 7.4, 4, z + side * 3.4, CREAM)
				pillar(decorFolder, "StallPost", 0.7, 9, x + corner * 7.4, 4, z - side * 3.4, CREAM)
			end
			for stripe = 0, 5 do
				block(decorFolder, "StallAwning", 3, 1, 10, x - 7.5 + stripe * 3, 13.5, z, (stripe % 2 == 0) and CANDY_RED or CREAM)
			end
			for snack = -1, 1 do
				decor(sphere(decorFolder, "StallSnack", 2.2, x + snack * 4, 5.7, z, PARTY[(snack + index + 2) % #PARTY + 1]))
			end
		end
	end
end

-- One booth: floor, candy-striped walls, gate arch with a sign, laser bars, lock button, red carpet, 20 pedestals.
local function buildBooth(boothsFolder, Config, boothIndex)
	local booth = folder(boothsFolder, "Booth" .. boothIndex)
	local spec = Config.BOOTH
	local origin, dir = Config.boothOrigin(boothIndex)
	local function at(forward, side, height)
		return Config.boothPoint(boothIndex, forward, side, height)
	end
	local function boothBlock(name, sideSize, height, forwardSize, forward, side, y, color, material)
		local spot = at(forward, side, y)
		return block(booth, name, sideSize, height, forwardSize, spot.X, spot.Y, spot.Z, color, material)
	end
	boothBlock("Floor", spec.halfWidth * 2, 0.3, spec.depth, spec.depth / 2, 0, 0.15, BOOTH_FLOORS[boothIndex])
	boothBlock("Carpet", 9, 0.12, spec.depth - 4, spec.depth / 2 - 1, 0, 0.36, rgb(200, 36, 60), Enum.Material.Fabric)
	for _, side in { -1, 1 } do
		boothBlock("CarpetTrim", 0.6, 0.14, spec.depth - 4, spec.depth / 2 - 1, side * 4.8, 0.37, GOLD)
	end
	-- Walls: striped segments on the back and both sides, and on each side of the gate.
	for index = 0, 7 do
		local color = (index % 2 == 0) and CANDY_RED or CREAM
		boothBlock("BackWall", spec.halfWidth * 2 / 8, 5, 1.4, spec.depth, -spec.halfWidth + (index + 0.5) * spec.halfWidth / 4, 2.5, color)
		for _, side in { -1, 1 } do
			boothBlock("SideWall", 1.4, 5, spec.depth / 8, (index + 0.5) * spec.depth / 8, side * spec.halfWidth, 2.5, color)
		end
	end
	local frontWidth = spec.halfWidth - spec.gateHalf
	for _, side in { -1, 1 } do
		for index = 0, 3 do
			boothBlock("FrontWall", frontWidth / 4, 5, 1.4, 0, side * (spec.gateHalf + (index + 0.5) * frontWidth / 4), 2.5, (index % 2 == 0) and CREAM or CANDY_RED)
		end
		for index = 0, 2 do
			local post = at(0, side * spec.gateHalf, 0)
			pillar(booth, "GatePost", 2.6, 3.4, post.X, index * 3.4, post.Z, (index % 2 == 0) and GOLD or rgb(60, 30, 100))
		end
		local cap = at(0, side * spec.gateHalf, 11.6)
		sphere(booth, "GatePostBall", 3.6, cap.X, cap.Y, cap.Z, PARTY[boothIndex])
		local cornerBack = at(spec.depth, side * spec.halfWidth, 0)
		pillar(booth, "CornerPost", 2, 9, cornerBack.X, 0, cornerBack.Z, GOLD)
		sphere(booth, "CornerBall", 3, cornerBack.X, 10, cornerBack.Z, PARTY[(boothIndex + 2) % #PARTY + 1])
	end
	-- The booth's sign stands on the back wall, facing the gate, so the gate itself stays low and open.
	local sign = boothBlock("Sign", 30, 6, 1.2, spec.depth - 1.4, 0, 11, rgb(60, 30, 100))
	for _, side in { -1, 1 } do
		local leg = at(spec.depth - 1.4, side * 13, 0)
		pillar(booth, "SignLeg", 1.2, 8, leg.X, 0, leg.Z, GOLD)
	end
	signText(sign, (dir > 0) and Enum.NormalId.Front or Enum.NormalId.Back, "BOOTH " .. boothIndex, GOLD)
	signText(sign, (dir > 0) and Enum.NormalId.Back or Enum.NormalId.Front, "BOOTH " .. boothIndex, GOLD)
	boothBlock("SignTrim", 31, 0.6, 1.6, spec.depth - 1.4, 0, 14.3, GOLD)
	for index = 0, 8 do
		local bulb = at(spec.depth - 1.4, -14 + index * 3.5, 15.2)
		decor(sphere(booth, "GateBulb", 1, bulb.X, bulb.Y, bulb.Z, PARTY[index % #PARTY + 1], Enum.Material.Neon))
	end
	-- Laser bars across the gate: invisible until GateLock switches them on.
	local lasers = folder(booth, "Lasers")
	for index = 0, 3 do
		local bar = decor(boothBlock("Laser", spec.gateHalf * 2 - 2.6, 0.5, 0.5, 0, 0, 2 + index * 2.6, rgb(255, 40, 60), Enum.Material.Neon))
		bar.Parent = lasers
		bar.Transparency = 1
	end
	local buttonSpot = at(5, spec.gateHalf + 3, 0)
	pillar(booth, "LockStand", 2.4, 3.2, buttonSpot.X, 0, buttonSpot.Z, INK)
	local button = pillar(booth, "LockButton", 2, 0.6, buttonSpot.X, 3.2, buttonSpot.Z, rgb(255, 50, 70), Enum.Material.Neon)
	button.Name = "LockButton"
	-- Pedestals: a striped drum with a glowing top. Slots past the start count are locked until upgraded.
	local pedestals = folder(booth, "Pedestals")
	for slot = 1, spec.maxPedestals do
		local spot = Config.pedestalPoint(boothIndex, slot)
		local group = Instance.new("Model")
		group.Name = "Pedestal" .. slot
		group.Parent = pedestals
		pillar(group, "Drum", 6.4, Config.PEDESTAL_TOP - 0.4, spot.X, 0, spot.Z, (slot % 2 == 0) and CREAM or CANDY_RED)
		local top = pillar(group, "Top", 7, 0.4, spot.X, Config.PEDESTAL_TOP - 0.4, spot.Z, GOLD)
		group.PrimaryPart = top
		decor(pillar(group, "Glow", 5, 0.1, spot.X, Config.PEDESTAL_TOP, spot.Z, rgb(255, 244, 170), Enum.Material.Neon))
	end
	return origin
end

-- Build the carnival under parent and return its model.
function CarnivalBuilder.buildCarnival(parent, Config)
	seed = 20261120
	local root = Instance.new("Model")
	root.Name = "Carnival"
	buildGroundAndStreet(root, Config)
	buildPrizeBelt(root, Config)
	buildPrizeCannon(root, Config)
	buildPopcornMachine(root, Config)
	buildTitleArch(root, Config, Config.STREET.minX + 4, "WestArch")
	buildTitleArch(root, Config, Config.STREET.maxX - 4, "EastArch")
	local booths = folder(root, "Booths")
	for boothIndex = 1, #Config.BOOTHS do
		buildBooth(booths, Config, boothIndex)
	end
	buildFerrisWheel(root, -46, 132)
	buildCarousel(root, 46, -134)
	buildBigTop(root, 48, 136, CANDY_RED, CREAM, 1)
	buildBigTop(root, -50, -138, rgb(80, 160, 255), CREAM, 0.9)
	buildBigTop(root, 170, 120, rgb(200, 130, 255), GOLD, 0.7)
	buildBigTop(root, -170, -118, rgb(255, 150, 60), CREAM, 0.7)
	buildDecor(root, Config)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MidwaySpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 0.4, 10)
	spawn.CFrame = CFrame.new(-20, 0.3, -12)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Parent = root
	root.Parent = parent
	return root
end

-- Evening light with a soft glow: set on the live Lighting service when the server starts.
function CarnivalBuilder.applyLighting(lighting)
	lighting.ClockTime = 16.6
	lighting.GeographicLatitude = 28
	lighting.Brightness = 2.1
	lighting.ExposureCompensation = -0.12
	lighting.Ambient = rgb(110, 96, 140)
	lighting.OutdoorAmbient = rgb(150, 130, 170)
	lighting.ColorShift_Top = rgb(255, 214, 170)
	lighting.EnvironmentDiffuseScale = 0.6
	lighting.EnvironmentSpecularScale = 0.4
	for _, child in lighting:GetChildren() do
		if child:IsA("Atmosphere") or child:IsA("BloomEffect") or child:IsA("ColorCorrectionEffect") then
			child:Destroy()
		end
	end
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.13
	atmosphere.Offset = 0.2
	atmosphere.Color = rgb(226, 190, 230)
	atmosphere.Decay = rgb(120, 90, 170)
	atmosphere.Glare = 0
	atmosphere.Haze = 0.4
	atmosphere.Parent = lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.2
	bloom.Size = 20
	bloom.Threshold = 1.4
	bloom.Parent = lighting
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Saturation = 0.18
	grade.Contrast = 0.06
	grade.Parent = lighting
end

return CarnivalBuilder
