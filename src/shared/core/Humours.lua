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

return Humours
