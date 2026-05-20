local Humours = {
	Blood = "Blood",
	Phlegm = "Phlegm",
	YellowBile = "Yellow Bile",
	BlackBile = "Black Bile",
}

-- Iteration order for generation, display, and body-region mapping.
-- Listed separately because table iteration order on the dictionary
-- above is not guaranteed by Lua.
Humours.Names = { Humours.Blood, Humours.Phlegm, Humours.YellowBile, Humours.BlackBile }

-- Body region constants. Single source of truth for the
-- region strings used by RegionByPart (below) and by every
-- SymptomData entry's bodyRegion field. PascalCase field
-- names match the precedent set by the humour constants
-- above; lowercase values are the runtime strings.
Humours.Regions = {
	Head    = "head",
	Chest   = "chest",
	Arms    = "arms",
	Legs    = "legs",
	Passive = "passive",
}

-- Maps R15 BasePart names to the humour each region reveals.
-- All arm parts (both sides) flatten to YellowBile; all leg
-- parts to Phlegm; both torso parts to Blood. Anything not in
-- this table is treated as a no-op click.
Humours.BodyRegions = {
	Head = Humours.BlackBile,
	UpperTorso = Humours.Blood,
	LowerTorso = Humours.Blood,
	LeftUpperArm = Humours.YellowBile,
	LeftLowerArm = Humours.YellowBile,
	LeftHand = Humours.YellowBile,
	RightUpperArm = Humours.YellowBile,
	RightLowerArm = Humours.YellowBile,
	RightHand = Humours.YellowBile,
	LeftUpperLeg = Humours.Phlegm,
	LeftLowerLeg = Humours.Phlegm,
	LeftFoot = Humours.Phlegm,
	RightUpperLeg = Humours.Phlegm,
	RightLowerLeg = Humours.Phlegm,
	RightFoot = Humours.Phlegm,
}

-- Maps R15 BasePart names to body-region constants. Unlike
-- BodyRegions above, this does NOT encode a humour mapping —
-- region and humour are independent in the new
-- symptom-discovery model. A click on a leg part resolves to
-- Regions.Legs regardless of which humours have leg-region
-- symptoms. Key set must stay in sync with BodyRegions; a
-- load-time assertion below catches drift.
Humours.RegionByPart = {
	Head           = Humours.Regions.Head,
	UpperTorso     = Humours.Regions.Chest,
	LowerTorso     = Humours.Regions.Chest,
	LeftUpperArm   = Humours.Regions.Arms,
	LeftLowerArm   = Humours.Regions.Arms,
	LeftHand       = Humours.Regions.Arms,
	RightUpperArm  = Humours.Regions.Arms,
	RightLowerArm  = Humours.Regions.Arms,
	RightHand      = Humours.Regions.Arms,
	LeftUpperLeg   = Humours.Regions.Legs,
	LeftLowerLeg   = Humours.Regions.Legs,
	LeftFoot       = Humours.Regions.Legs,
	RightUpperLeg  = Humours.Regions.Legs,
	RightLowerLeg  = Humours.Regions.Legs,
	RightFoot      = Humours.Regions.Legs,
}

-- Sanity check: BodyRegions (legacy, part→humour) and
-- RegionByPart (part→region) must cover identical key sets
-- during the coexistence period. Drift in either direction
-- fails loudly at module load. Both tables go away when the
-- legacy click-to-reveal-humour mechanic is removed.
for partName in pairs(Humours.BodyRegions) do
	assert(
		Humours.RegionByPart[partName] ~= nil,
		"Humours: '" .. partName .. "' present in BodyRegions but missing from RegionByPart — add the missing R15 part name to both tables"
	)
end
for partName in pairs(Humours.RegionByPart) do
	assert(
		Humours.BodyRegions[partName] ~= nil,
		"Humours: '" .. partName .. "' present in RegionByPart but missing from BodyRegions — add the missing R15 part name to both tables"
	)
end

return Humours
