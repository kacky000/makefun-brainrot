--!strict
-- Builds the whole carnival at server start: ground, the Midway street with the Prize Belt, the Prize
-- Cannon, the Popcorn Machine, title arches, a spinning Ferris wheel and carousel, tents, lights and
-- balloons, and the six player booths (floor, candy walls, gate, gate laser, lock button, pedestals).

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

export type Plot = {
	index: number,
	gate: CFrame, -- at the gate, LookVector pointing into the booth
	inward: Vector3,
	color: Color3,
	folder: Model,
	pedestals: { BasePart },
	laser: BasePart,
	lockButton: BasePart,
	sign: TextLabel,
	signSub: TextLabel,
	spawn: CFrame,
}

local CarnivalWorld = {}
CarnivalWorld.plots = {} :: { Plot }

local rgb = Color3.fromRGB
local world: Folder
local rides: { { model: Model, pivot: CFrame, axis: string, speed: number } } = {}

local PASTELS = {
	rgb(255, 150, 200),
	rgb(130, 230, 190),
	rgb(185, 160, 255),
	rgb(255, 190, 120),
	rgb(120, 200, 255),
	rgb(255, 235, 110),
}
local CANDY = { rgb(255, 70, 90), rgb(255, 255, 255) }

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		(p :: any)[key] = value
	end
	if not props.Parent then
		p.Parent = world
	end
	return p
end

local function cylinderUp(height: number, diameter: number, pos: Vector3, color: Color3, parent: Instance?, material: Enum.Material?): Part
	return part({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, diameter, diameter),
		CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)),
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
		Parent = parent or world,
	})
end

local function sign(face: BasePart, faceEnum: Enum.NormalId, title: string, sub: string?, titleColor: Color3?, back: Color3?): (TextLabel, TextLabel?)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Face" .. faceEnum.Name
	gui.Face = faceEnum
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.LightInfluence = 0
	gui.Parent = face
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = back or rgb(60, 20, 90)
	frame.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 6
	stroke.Color = rgb(255, 220, 60)
	stroke.Parent = frame
	local label = Instance.new("TextLabel")
	label.Name = "Title"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(0.94, if sub then 0.62 else 0.9)
	label.Position = UDim2.fromScale(0.03, 0.04)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = title
	label.TextColor3 = titleColor or rgb(255, 230, 70)
	label.TextStrokeTransparency = 0
	label.Parent = frame
	local subLabel: TextLabel? = nil
	if sub then
		local s = label:Clone()
		s.Name = "Sub"
		s.Size = UDim2.fromScale(0.94, 0.3)
		s.Position = UDim2.fromScale(0.03, 0.66)
		s.Text = sub
		s.TextColor3 = rgb(255, 255, 255)
		s.Parent = frame
		subLabel = s
	end
	return label, subLabel
end

local function buildGround()
	part({ Name = "Ground", Size = Vector3.new(1000, 2, 800), Position = Vector3.new(0, -1, 0), Color = rgb(120, 205, 120), Material = Enum.Material.Grass })
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MidwaySpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 0.4, 10)
	spawn.Position = Vector3.new(-150, 0.4, -10)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Duration = 0
	spawn.Parent = world
end

local function buildStreet()
	local half = GameConfig.STREET_HALF_WIDTH
	-- Checkered Midway tiles in two pastel tones.
	local tile = 16
	for x = -200, 200 - tile, tile do
		for zIndex = 0, 1 do
			local z = -half + tile / 2 + zIndex * tile
			local even = ((x // tile) + zIndex) % 2 == 0
			part({
				Name = "MidwayTile",
				Size = Vector3.new(tile, 0.4, tile),
				Position = Vector3.new(x + tile / 2, 0.2, z),
				Color = if even then rgb(255, 150, 195) else rgb(255, 222, 120),
			})
		end
	end
	-- Kerbs
	for _, side in { 1, -1 } do
		part({ Name = "Kerb", Size = Vector3.new(400, 0.8, 1.2), Position = Vector3.new(0, 0.4, side * (half + 0.6)), Color = rgb(255, 90, 140) })
	end
	-- The Prize Belt
	local beltLength = GameConfig.BELT_END_X - GameConfig.BELT_START_X
	local beltX = (GameConfig.BELT_END_X + GameConfig.BELT_START_X) / 2
	part({ Name = "PrizeBelt", Size = Vector3.new(beltLength, 1, GameConfig.BELT_WIDTH), Position = Vector3.new(beltX, 0.5, 0), Color = rgb(55, 50, 75), Material = Enum.Material.Fabric })
	for _, side in { 1, -1 } do
		part({ Name = "BeltRail", Size = Vector3.new(beltLength, 0.5, 0.6), Position = Vector3.new(beltX, 1.25, side * (GameConfig.BELT_WIDTH / 2 + 0.3)), Color = rgb(255, 220, 60), Material = Enum.Material.Neon })
	end
	for x = GameConfig.BELT_START_X + 6, GameConfig.BELT_END_X - 6, 12 do
		part({ Name = "BeltChevron", Size = Vector3.new(1.2, 0.08, 4), CFrame = CFrame.new(x, 1.02, 0) * CFrame.Angles(0, math.rad(35), 0), Color = rgb(255, 120, 200), Material = Enum.Material.Neon, CanCollide = false })
	end
end

local function buildPrizeCannon()
	local x = GameConfig.BELT_START_X - 16
	local model = Instance.new("Model")
	model.Name = "PrizeCannon"
	model.Parent = world
	cylinderUp(4, 16, Vector3.new(x, 2, 0), rgb(90, 60, 160), model)
	cylinderUp(1, 17, Vector3.new(x, 4.4, 0), rgb(255, 220, 60), model, Enum.Material.Neon)
	for i = 0, 5 do
		local stripe = CANDY[i % 2 + 1]
		part({
			Name = "Barrel",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(3, 9 - i * 0.3, 9 - i * 0.3),
			CFrame = CFrame.new(x, 9, 0) * CFrame.Angles(0, 0, math.rad(35)) * CFrame.new(i * 3, 0, 0),
			Color = stripe,
			Parent = model,
		})
	end
	part({ Name = "Muzzle", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.5, 9.5, 9.5), CFrame = CFrame.new(x, 9, 0) * CFrame.Angles(0, 0, math.rad(35)) * CFrame.new(18, 0, 0), Color = rgb(255, 220, 60), Material = Enum.Material.Neon, Parent = model })
	for _, side in { 1, -1 } do
		part({ Name = "Wheel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.5, 9, 9), CFrame = CFrame.new(x - 2, 6, side * 5.5) * CFrame.Angles(0, math.rad(90), 0), Color = rgb(255, 200, 40), Parent = model })
	end
	local board = part({ Name = "CannonSign", Size = Vector3.new(1, 7, 26), Position = Vector3.new(x - 8, 24, 0), Parent = model })
	sign(board, Enum.NormalId.Right, "PRIZE CANNON", "fresh brainrots every few seconds!")
	local sparks = Instance.new("ParticleEmitter")
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Rate = 25
	sparks.Speed = NumberRange.new(6, 12)
	sparks.SpreadAngle = Vector2.new(30, 30)
	sparks.Lifetime = NumberRange.new(0.6, 1.2)
	sparks.Color = ColorSequence.new(rgb(255, 120, 220), rgb(255, 230, 80))
	sparks.LightEmission = 1
	sparks.EmissionDirection = Enum.NormalId.Right
	sparks.Parent = model:FindFirstChild("Muzzle")
end

local function buildPopcornMachine()
	local x = 205
	local model = Instance.new("Model")
	model.Name = "PopcornMachine"
	model.Parent = world
	part({ Name = "Cart", Size = Vector3.new(26, 14, 44), Position = Vector3.new(x, 7, 0), Color = rgb(230, 40, 60), Parent = model })
	for i = -2, 2 do
		part({ Name = "Stripe", Size = Vector3.new(26.2, 14.2, 3), Position = Vector3.new(x, 7, i * 9), Color = rgb(255, 255, 255), Parent = model })
	end
	part({ Name = "Glass", Size = Vector3.new(24, 22, 42), Position = Vector3.new(x, 25, 0), Color = rgb(200, 240, 255), Material = Enum.Material.Glass, Transparency = 0.6, Parent = model })
	part({ Name = "Roof", Size = Vector3.new(28, 2, 46), Position = Vector3.new(x, 37, 0), Color = rgb(230, 40, 60), Parent = model })
	local rng = Random.new(7)
	for _ = 1, 70 do
		part({
			Name = "Kernel",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * rng:NextNumber(2, 3.6),
			Position = Vector3.new(x + rng:NextNumber(-10, 10), rng:NextNumber(15, 28), rng:NextNumber(-19, 19)),
			Color = if rng:NextNumber() < 0.7 then rgb(255, 250, 225) else rgb(255, 215, 90),
			CanCollide = false,
			Parent = model,
		})
	end
	local board = part({ Name = "MachineSign", Size = Vector3.new(1, 8, 40), Position = Vector3.new(x - 13.6, 43, 0), Parent = model })
	sign(board, Enum.NormalId.Left, "POPCORN MACHINE", "it overflows every minute or so. RUN!", rgb(255, 255, 255), rgb(200, 30, 50))
end

local function buildTitleArch(x: number, faceEnum: Enum.NormalId)
	local half = GameConfig.STREET_HALF_WIDTH + 6
	for _, side in { 1, -1 } do
		for i = 0, 8 do
			cylinderUp(4, 4, Vector3.new(x, 2 + i * 4, side * half), CANDY[i % 2 + 1])
		end
		part({ Name = "ArchBall", Shape = Enum.PartType.Ball, Size = Vector3.one * 6, Position = Vector3.new(x, 39, side * half), Color = rgb(255, 220, 60), Material = Enum.Material.Neon })
	end
	local board = part({ Name = "TitleBoard", Size = Vector3.new(2, 14, half * 2 + 10), Position = Vector3.new(x, 31, 0), Color = rgb(60, 20, 90) })
	sign(board, faceEnum, GameConfig.TITLE, GameConfig.SUBTITLE .. "!", rgb(255, 225, 60), rgb(110, 30, 160))
	local otherFace = if faceEnum == Enum.NormalId.Left then Enum.NormalId.Right else Enum.NormalId.Left
	sign(board, otherFace, GameConfig.TITLE, GameConfig.SUBTITLE .. "!", rgb(255, 225, 60), rgb(110, 30, 160))
	for i = -6, 6 do
		part({ Name = "Bulb", Shape = Enum.PartType.Ball, Size = Vector3.one * 1.3, Position = Vector3.new(x, 38.6, i * 3.6), Color = if i % 2 == 0 then rgb(255, 240, 120) else rgb(255, 120, 200), Material = Enum.Material.Neon })
	end
end

local function buildFerrisWheel(center: Vector3)
	local model = Instance.new("Model")
	model.Name = "FerrisWheel"
	model.Parent = world
	local radius = 40
	-- Legs stay still; the wheel spins.
	for _, side in { -1, 1 } do
		for _, lean in { -1, 1 } do
			part({ Name = "Leg", Size = Vector3.new(2.5, center.Y + 4, 2.5), CFrame = CFrame.new(center + Vector3.new(lean * 16, -center.Y / 2, side * 6)) * CFrame.Angles(0, 0, math.rad(lean * 20)), Color = rgb(255, 255, 255) })
		end
	end
	local wheel = Instance.new("Model")
	wheel.Name = "Wheel"
	wheel.Parent = model
	local hub = part({ Name = "Hub", Shape = Enum.PartType.Cylinder, Size = Vector3.new(14, 6, 6), CFrame = CFrame.new(center) * CFrame.Angles(0, math.rad(90), 0), Color = rgb(255, 220, 60), Material = Enum.Material.Neon, Parent = wheel })
	wheel.PrimaryPart = hub
	local spokes = 16
	for i = 1, spokes do
		local angle = (i / spokes) * math.pi * 2
		local dir = Vector3.new(math.cos(angle), math.sin(angle), 0)
		local color = PASTELS[(i - 1) % #PASTELS + 1]
		part({ Name = "Spoke", Size = Vector3.new(radius, 0.8, 0.8), CFrame = CFrame.new(center + dir * radius / 2) * CFrame.Angles(0, 0, angle), Color = rgb(255, 255, 255), Parent = wheel })
		local chord = 2 * radius * math.sin(math.pi / spokes) + 0.6
		part({ Name = "Rim", Size = Vector3.new(1.4, chord, 1.4), CFrame = CFrame.new(center + dir * radius) * CFrame.Angles(0, 0, angle), Color = rgb(255, 90, 160), Material = Enum.Material.Neon, Parent = wheel })
		part({ Name = "Gondola", Size = Vector3.new(6, 5, 7), CFrame = CFrame.new(center + dir * radius - Vector3.new(0, 4, 0)), Color = color, Parent = wheel })
	end
	wheel:SetAttribute("RidePivot", CFrame.new(center))
	wheel:SetAttribute("RideAxis", "Z")
	wheel:SetAttribute("RideSpeed", 0.12)
end

local function buildCarousel(center: Vector3)
	local model = Instance.new("Model")
	model.Name = "Carousel"
	model.Parent = world
	cylinderUp(2, 40, center + Vector3.new(0, 1, 0), rgb(255, 230, 245), model)
	local spin = Instance.new("Model")
	spin.Name = "Spinner"
	spin.Parent = model
	local pole = cylinderUp(26, 3, center + Vector3.new(0, 14, 0), rgb(255, 220, 60), spin, Enum.Material.Neon)
	spin.PrimaryPart = pole
	for i = 0, 4 do
		cylinderUp(2.2, 44 - i * 8, center + Vector3.new(0, 26 + i * 2.2, 0), CANDY[i % 2 + 1], spin)
	end
	local horses = 8
	for i = 1, horses do
		local angle = (i / horses) * math.pi * 2
		local pos = center + Vector3.new(math.cos(angle) * 15, 0, math.sin(angle) * 15)
		cylinderUp(24, 0.6, pos + Vector3.new(0, 14, 0), rgb(255, 215, 80), spin, Enum.Material.Metal)
		local facing = CFrame.lookAt(pos + Vector3.new(0, 7, 0), pos + Vector3.new(0, 7, 0) + Vector3.new(-math.sin(angle), 0, math.cos(angle)))
		part({ Name = "Horse", Size = Vector3.new(2, 3, 6), CFrame = facing, Color = PASTELS[(i - 1) % #PASTELS + 1], Parent = spin })
		part({ Name = "HorseHead", Size = Vector3.new(1.6, 3, 2), CFrame = facing * CFrame.new(0, 2.2, -3), Color = PASTELS[(i - 1) % #PASTELS + 1], Parent = spin })
	end
	spin:SetAttribute("RidePivot", CFrame.new(center))
	spin:SetAttribute("RideAxis", "Y")
	spin:SetAttribute("RideSpeed", 0.35)
end

local function buildTent(pos: Vector3, size: number, color: Color3)
	for i = 0, 3 do
		cylinderUp(size * 0.35, size * (1 - i * 0.24), pos + Vector3.new(0, size * 0.18 + i * size * 0.33, 0), if i % 2 == 0 then color else rgb(255, 255, 255))
	end
	part({ Name = "Flag", Size = Vector3.new(0.4, 4, 3), Position = pos + Vector3.new(0, size * 1.35 + 2, 1.6), Color = rgb(255, 220, 60), Material = Enum.Material.Neon })
	cylinderUp(5, 0.4, pos + Vector3.new(0, size * 1.35, 0), rgb(255, 255, 255))
end

local function buildStringLights()
	local half = GameConfig.STREET_HALF_WIDTH + 3
	for x = -180, 180, 30 do
		for _, side in { 1, -1 } do
			cylinderUp(18, 0.8, Vector3.new(x, 9, side * half), rgb(255, 255, 255))
		end
		for i = 0, 12 do
			local z = -half + i * (half * 2 / 12)
			local sag = 17 - math.sin((i / 12) * math.pi) * 3
			part({ Name = "Bulb", Shape = Enum.PartType.Ball, Size = Vector3.one * 1, Position = Vector3.new(x, sag, z), Color = PASTELS[i % #PASTELS + 1], Material = Enum.Material.Neon, CanCollide = false })
		end
	end
end

local function buildBalloons(pos: Vector3, rng: Random)
	for _ = 1, 5 do
		local offset = Vector3.new(rng:NextNumber(-3, 3), rng:NextNumber(10, 16), rng:NextNumber(-3, 3))
		part({ Name = "Balloon", Shape = Enum.PartType.Ball, Size = Vector3.one * 3, Position = pos + offset, Color = PASTELS[rng:NextInteger(1, #PASTELS)], Material = Enum.Material.Glass, Transparency = 0.1, CanCollide = false })
		part({ Name = "String", Size = Vector3.new(0.1, offset.Y, 0.1), Position = pos + Vector3.new(offset.X / 2, offset.Y / 2, offset.Z / 2), Color = rgb(255, 255, 255), CanCollide = false })
	end
end

local function buildLollipopTree(pos: Vector3, color: Color3)
	cylinderUp(10, 1, pos + Vector3.new(0, 5, 0), rgb(255, 255, 255))
	part({ Name = "Lolly", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.5, 8, 8), CFrame = CFrame.new(pos + Vector3.new(0, 13, 0)) * CFrame.Angles(0, math.rad(90), 0), Color = color })
	part({ Name = "LollySwirl", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 4.5, 4.5), CFrame = CFrame.new(pos + Vector3.new(0, 13, 0)) * CFrame.Angles(0, math.rad(90), 0), Color = rgb(255, 255, 255) })
end

local function buildPlot(index: number, x: number, side: number): Plot
	local inward = Vector3.new(0, 0, side)
	local gatePos = Vector3.new(x, 0, side * (GameConfig.STREET_HALF_WIDTH + GameConfig.PLOT_GAP))
	local gate = CFrame.lookAt(gatePos, gatePos + inward)
	local color = PASTELS[(index - 1) % #PASTELS + 1]
	local width, depth = GameConfig.PLOT_WIDTH, GameConfig.PLOT_DEPTH
	local folder = Instance.new("Model")
	folder.Name = "Booth" .. index
	folder:SetAttribute("Index", index)
	folder:SetAttribute("Gate", gate)
	folder:SetAttribute("Inward", inward)
	folder:SetAttribute("Color", color)
	folder.Parent = world

	local function at(lx: number, y: number, d: number): CFrame
		return gate * CFrame.new(lx, y, -d)
	end

	part({ Name = "Floor", Size = Vector3.new(width, 0.6, depth), CFrame = at(0, 0.3, depth / 2), Color = color:Lerp(rgb(255, 255, 255), 0.35), Parent = folder })
	part({ Name = "Carpet", Size = Vector3.new(22, 0.7, depth - 2), CFrame = at(0, 0.35, depth / 2), Color = rgb(230, 40, 60), Material = Enum.Material.Fabric, Parent = folder })
	for _, lx in { -11.5, 11.5 } do
		part({ Name = "CarpetTrim", Size = Vector3.new(1, 0.75, depth - 2), CFrame = at(lx, 0.38, depth / 2), Color = rgb(255, 215, 60), Material = Enum.Material.Neon, Parent = folder })
	end

	-- Candy-striped walls with a gap for the gate.
	local wallH = 3.5
	local function wall(lx: number, d: number, sx: number, sz: number)
		local segments = math.max(1, math.floor(math.max(sx, sz) / 8))
		for i = 0, segments - 1 do
			local t = (i + 0.5) / segments - 0.5
			local pos = if sx > sz then at(lx + t * sx, wallH / 2, d) else at(lx, wallH / 2, d + t * sz)
			part({
				Name = "Wall",
				Size = if sx > sz then Vector3.new(sx / segments, wallH, sz) else Vector3.new(sx, wallH, sz / segments),
				CFrame = pos,
				Color = if i % 2 == 0 then color else rgb(255, 255, 255),
				Parent = folder,
			})
		end
		part({ Name = "WallTop", Size = Vector3.new(math.max(sx, 1.4), 0.6, math.max(sz, 1.4)), CFrame = at(lx, wallH + 0.3, d), Color = rgb(255, 220, 60), Material = Enum.Material.Neon, Parent = folder })
	end
	wall(0, depth, width, 1.2)
	wall(-width / 2, depth / 2, 1.2, depth)
	wall(width / 2, depth / 2, 1.2, depth)
	wall(-(width / 2 + 12) / 2, 0, width / 2 - 12, 1.2)
	wall((width / 2 + 12) / 2, 0, width / 2 - 12, 1.2)

	-- Gate arch and its sign.
	for _, lx in { -13, 13 } do
		for i = 0, 3 do
			part({ Name = "GatePost", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3.5, 3, 3), CFrame = at(lx, 1.75 + i * 3.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = CANDY[i % 2 + 1], Parent = folder })
		end
	end
	local board = part({ Name = "GateSign", Size = Vector3.new(26, 5, 1), CFrame = at(0, 23, -2), Color = rgb(60, 20, 90), Parent = folder })
	for _, lx in { -11, 11 } do
		part({ Name = "SignPole", Size = Vector3.new(0.6, 10, 0.6), CFrame = at(lx, 16, -2), Color = rgb(255, 255, 255), Parent = folder })
	end
	local title, sub = sign(board, Enum.NormalId.Back, "EMPTY BOOTH", "step in to claim it", rgb(255, 230, 70), color:Lerp(rgb(60, 20, 90), 0.7))
	-- The face is Back because the sign's LookVector points inward; mirror for the inside too.
	sign(board, Enum.NormalId.Front, "YOUR BOOTH", nil)

	local laser = part({
		Name = "GateLaser",
		Size = Vector3.new(24, 10, 0.6),
		CFrame = at(0, 5, 0),
		Color = rgb(255, 40, 70),
		Material = Enum.Material.Neon,
		Transparency = 1,
		CanCollide = false,
		Parent = folder,
	})
	-- Bright beams across the gate that light up with the lock.
	for i = 1, 5 do
		local beam = part({
			Name = "LaserBeam",
			Size = Vector3.new(24, 0.35, 0.35),
			CFrame = at(0, 1.2 + i * 1.6, 0),
			Color = rgb(255, 30, 60),
			Material = Enum.Material.Neon,
			Transparency = 1,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Parent = laser,
		})
		beam.Anchored = true
	end

	local lockButton = part({
		Name = "LockButton",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.2, 6, 6),
		CFrame = at(15, 0.6, 5) * CFrame.Angles(0, 0, math.rad(90)),
		Color = rgb(255, 40, 70),
		Material = Enum.Material.Neon,
		Parent = folder,
	})
	local lockPost = part({ Name = "LockSign", Size = Vector3.new(8, 3, 0.5), CFrame = at(15, 6, 8) * CFrame.Angles(0, math.rad(180), 0), Color = rgb(40, 20, 60), Parent = folder })
	sign(lockPost, Enum.NormalId.Front, "LOCK GATE", nil, rgb(255, 80, 100), rgb(40, 20, 60))
	cylinderUp(4, 0.4, (at(15, 2, 8)).Position, rgb(255, 255, 255), folder)

	-- Pedestals: two banks of two columns either side of the aisle, front row nearest the gate.
	local pedestals = {}
	local columnXs = GameConfig.PEDESTAL_COLUMN_XS
	for slot = 1, GameConfig.MAX_PEDESTALS do
		local row = (slot - 1) // #columnXs
		local lx = columnXs[(slot - 1) % #columnXs + 1]
		local d = GameConfig.PEDESTAL_FIRST_ROW + row * GameConfig.PEDESTAL_SPACING_Z
		local base = part({
			Name = "Pedestal" .. slot,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.6, 6, 6),
			CFrame = at(lx, 0.8 + 0.6, d) * CFrame.Angles(0, 0, math.rad(90)),
			Color = rgb(255, 255, 255),
			Parent = folder,
		})
		base:SetAttribute("Slot", slot)
		part({ Name = "PedestalRim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 6.6, 6.6), CFrame = at(lx, 1.0, d) * CFrame.Angles(0, 0, math.rad(90)), Color = color, Material = Enum.Material.Neon, Parent = folder })
		table.insert(pedestals, base)
	end

	folder:SetAttribute("Spawn", at(0, 3, depth - 24) * CFrame.Angles(0, math.rad(180), 0))
	local _ = title
	local _ = sub
	return CarnivalWorld.readPlot(folder)
end

-- Reads a booth's record back from the instances and attributes buildPlot left on it, so a booth baked
-- into the place file works exactly like a freshly built one.
function CarnivalWorld.readPlot(folder: Model): Plot
	local pedestals = {}
	for _, child in folder:GetChildren() do
		local slot = child:GetAttribute("Slot")
		if slot and child:IsA("BasePart") then
			pedestals[slot] = child
		end
	end
	local board = folder:FindFirstChild("GateSign") :: BasePart
	local face = (board:FindFirstChild("FaceBack") :: SurfaceGui):FindFirstChildOfClass("Frame") :: Frame
	return {
		index = folder:GetAttribute("Index") :: number,
		gate = folder:GetAttribute("Gate") :: CFrame,
		inward = folder:GetAttribute("Inward") :: Vector3,
		color = folder:GetAttribute("Color") :: Color3,
		folder = folder,
		pedestals = pedestals,
		laser = folder:FindFirstChild("GateLaser") :: BasePart,
		lockButton = folder:FindFirstChild("LockButton") :: BasePart,
		sign = face:FindFirstChild("Title") :: TextLabel,
		signSub = face:FindFirstChild("Sub") :: TextLabel,
		spawn = folder:GetAttribute("Spawn") :: CFrame,
	}
end

local function buildPlots()
	local index = 0
	for _, side in GameConfig.PLOT_SIDES do
		for _, x in GameConfig.PLOT_XS do
			index += 1
			table.insert(CarnivalWorld.plots, buildPlot(index, x, side))
		end
	end
end

local function buildScenery()
	local rng = Random.new(42)
	local back = GameConfig.STREET_HALF_WIDTH + GameConfig.PLOT_GAP + GameConfig.PLOT_DEPTH
	-- The big rides stand right behind the first booths so they rise over the Midway in most views.
	buildFerrisWheel(Vector3.new(-80, 46, back + 44))
	buildCarousel(Vector3.new(-120, 0, -(back + 34)))
	buildTent(Vector3.new(-40, 0, -(back + 34)), 30, rgb(255, 80, 120))
	buildTent(Vector3.new(170, 0, back + 30), 22, rgb(120, 140, 255))
	buildTent(Vector3.new(70, 0, -(back + 34)), 28, rgb(130, 220, 160))
	buildTent(Vector3.new(-180, 0, back + 20), 20, rgb(255, 170, 60))
	buildTent(Vector3.new(180, 0, -(back + 24)), 22, rgb(200, 120, 255))
	buildStringLights()
	-- Lollipop trees and balloon bunches on the lawns between the street and the booths.
	local lawn = GameConfig.STREET_HALF_WIDTH + GameConfig.PLOT_GAP / 2
	local function nearGate(x: number): boolean
		for _, gx in GameConfig.PLOT_XS do
			if math.abs(x - gx) < 24 then
				return true
			end
		end
		return false
	end
	for x = -190, 190, 27 do
		for _, side in { 1, -1 } do
			if nearGate(x) then
				continue
			elseif rng:NextNumber() < 0.55 then
				buildLollipopTree(Vector3.new(x + rng:NextNumber(-4, 4), 0, side * (lawn + rng:NextNumber(-3, 3))), PASTELS[rng:NextInteger(1, #PASTELS)])
			else
				buildBalloons(Vector3.new(x, 0, side * lawn), rng)
			end
		end
	end
	-- A big billboard of the title behind each row, readable from the street.
	for _, side in { 1, -1 } do
		local board = part({ Name = "TitleBillboard", Size = Vector3.new(90, 26, 2), Position = Vector3.new(40, 34, side * (back + 14)), Color = rgb(60, 20, 90) })
		sign(board, if side == 1 then Enum.NormalId.Front else Enum.NormalId.Back, GameConfig.TITLE, "36 BRAINROTS · POPCORN WAVE · CLOWN THIEVES", rgb(255, 225, 60), rgb(120, 30, 170))
		for _, lx in { -40, 40 } do
			cylinderUp(22, 2, Vector3.new(40 + lx, 11, side * (back + 14)), rgb(255, 255, 255))
		end
	end
	-- Confetti over the Midway.
	local confettiSource = part({ Name = "ConfettiSky", Size = Vector3.new(360, 1, 40), Position = Vector3.new(0, 45, 0), Transparency = 1, CanCollide = false, CanQuery = false })
	local confetti = Instance.new("ParticleEmitter")
	confetti.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	confetti.Rate = 40
	confetti.Lifetime = NumberRange.new(6, 9)
	confetti.Speed = NumberRange.new(4, 7)
	confetti.EmissionDirection = Enum.NormalId.Bottom
	confetti.Size = NumberSequence.new(0.6)
	confetti.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, rgb(255, 90, 160)),
		ColorSequenceKeypoint.new(0.5, rgb(255, 230, 80)),
		ColorSequenceKeypoint.new(1, rgb(90, 200, 255)),
	})
	confetti.LightEmission = 0.6
	confetti.Parent = confettiSource
end

local function setLighting()
	-- Late-afternoon carnival light: warm sun, long shadows, neon starting to glow.
	Lighting.ClockTime = 16.9
	Lighting.GeographicLatitude = 30
	Lighting.Brightness = 2.2
	Lighting.Ambient = rgb(130, 105, 135)
	Lighting.OutdoorAmbient = rgb(190, 150, 160)
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.6
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.1
	atmosphere.Color = rgb(255, 200, 190)
	atmosphere.Decay = rgb(220, 140, 220)
	atmosphere.Glare = 0.1
	atmosphere.Haze = 0.25
	atmosphere.Parent = Lighting
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Saturation = 0.35
	cc.Contrast = 0.16
	cc.Brightness = 0.02
	cc.TintColor = rgb(255, 242, 232)
	cc.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.22
	bloom.Size = 30
	bloom.Threshold = 0.9
	bloom.Parent = Lighting
	local rays = Instance.new("SunRaysEffect")
	rays.Intensity = 0.06
	rays.Parent = Lighting
end

-- Turns the Ferris wheel and the carousel every frame.
local function spinRides()
	for _, model in world:GetDescendants() do
		if model:IsA("Model") and model:GetAttribute("RideAxis") then
			table.insert(rides, {
				model = model,
				pivot = model:GetAttribute("RidePivot") :: CFrame,
				axis = model:GetAttribute("RideAxis") :: string,
				speed = model:GetAttribute("RideSpeed") :: number,
			})
		end
	end
	local angle = 0
	RunService.Heartbeat:Connect(function(dt)
		angle += dt
		for _, ride in rides do
			local turn = if ride.axis == "Z" then CFrame.Angles(0, 0, angle * ride.speed) else CFrame.Angles(0, angle * ride.speed, 0)
			if ride.model.PrimaryPart then
				local offset = ride.model:GetAttribute("BaseOffset") :: CFrame?
				if not offset then
					offset = ride.pivot:ToObjectSpace(ride.model:GetPivot())
					ride.model:SetAttribute("BaseOffset", offset)
				end
				ride.model:PivotTo(ride.pivot * turn * (offset :: CFrame))
			end
		end
	end)
end

-- Builds the whole carnival into workspace.Carnival (run at server start, or once in Studio's edit mode to
-- bake it into the place file as world/Carnival.rbxm).
function CarnivalWorld.buildCarnival(): Folder
	world = Instance.new("Folder")
	world.Name = "Carnival"
	world.Parent = workspace
	buildGround()
	buildStreet()
	buildPrizeCannon()
	buildPopcornMachine()
	buildTitleArch(-150, Enum.NormalId.Left)
	buildTitleArch(150, Enum.NormalId.Left)
	buildPlots()
	buildScenery()
	return world
end

-- Uses the carnival baked into the place when there is one, and builds it otherwise.
function CarnivalWorld.adoptOrBuild()
	local baked = workspace:FindFirstChild("Carnival")
	if baked and baked:IsA("Folder") and baked:FindFirstChild("Booth1") then
		world = baked
		table.clear(CarnivalWorld.plots)
		local booths = {}
		for _, child in baked:GetChildren() do
			if child:IsA("Model") and child:GetAttribute("Gate") then
				table.insert(booths, CarnivalWorld.readPlot(child))
			end
		end
		table.sort(booths, function(a, b)
			return a.index < b.index
		end)
		for _, plot in booths do
			table.insert(CarnivalWorld.plots, plot)
		end
	else
		CarnivalWorld.buildCarnival()
	end
	setLighting()
end

function CarnivalWorld.folder(): Folder
	return world
end

function CarnivalWorld.init(_services)
	CarnivalWorld.adoptOrBuild()
end

function CarnivalWorld.start()
	spinRides()
end

return CarnivalWorld
