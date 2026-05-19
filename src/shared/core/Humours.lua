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

return Humours
