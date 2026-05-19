local lines = {
	healthy_low = {
		"Haven't seen many come from the docks lately.",
		"Markets have been quiet this week.",
	},
	healthy_high = {
		"People are getting sick on my street. I've been keeping indoors.",
		"I heard something went wrong in the east quarter.",
	},
	symptomatic = {
		"I don't feel well. Something's wrong with me.",
		"My chest has been tight since I visited the market.",
		"Please. I need help.",
	},
	critical = {
		"...",
		"Can't breathe.",
		"Please.",
	},
	treated_before = {
		"You again. You helped someone on my street last week.",
		"Thank you for before.",
	},
}

local DialogueData = {}

function DialogueData.GetLine(condition)
	local pool = lines[condition]
	if not pool or #pool == 0 then
		return nil
	end
	return pool[math.random(1, #pool)]
end

return DialogueData