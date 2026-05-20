local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Humours = require(Shared.core.Humours)

-- Two schemas coexist here while the symptom-discovery
-- examination redesign lands incrementally. The legacy entries
-- (cough, laboured_breathing, dark_swelling, pale_skin, tremors,
-- surface_wound) carry { label, category } and feed the existing
-- treatment-by-category pipeline in TreatmentRules /
-- TreatmentHandler. New-schema entries carry { displayName,
-- description, bodyRegion, humour, direction, threshold,
-- contribution, discoveryType } and feed the redesigned
-- examination flow. The `fever` entry sits in both schemas: it
-- predates the redesign and is also one of the 16 new symptoms,
-- so it carries the union of both field sets. See
-- docs/symptom-vocabulary.md for the authoritative spec of the
-- new schema.

local SymptomData = {
	fever = {
		label          = "Fever",
		category       = "fever",
		displayName    = "Fever",
		description    = "Patient's forehead and cheeks feel hot. The face looks flushed and ruddy.",
		bodyRegion     = Humours.Regions.Head,
		humour         = Humours.Blood,
		direction      = "excess",
		threshold      = 5,
		contribution   = 8,
		discoveryType  = "skill_check",
	},
	cough = { label = "Cough", category = "respiratory" },
	laboured_breathing = { label = "Laboured breathing", category = "respiratory" },
	dark_swelling = { label = "Dark swelling", category = "vascular" },
	pale_skin = { label = "Pale skin", category = "vascular" },
	tremors = { label = "Tremors", category = "neural" },
	surface_wound = { label = "Surface wound", category = "wound" },

	bounding_pulse = {
		displayName    = "Bounding pulse",
		description    = "Pulse is fast and strong, easy to find and slightly forceful against the fingertips.",
		bodyRegion     = Humours.Regions.Chest,
		humour         = Humours.Blood,
		direction      = "excess",
		threshold      = 15,
		contribution   = 12,
		discoveryType  = "skill_check",
	},
	pallor = {
		displayName    = "Pallor",
		description    = "Lips, gums, and the insides of the eyelids look pale and bloodless.",
		bodyRegion     = Humours.Regions.Head,
		humour         = Humours.Blood,
		direction      = "deficiency",
		threshold      = -5,
		contribution   = -8,
		discoveryType  = "click",
	},
	cold_extremities = {
		displayName    = "Cold extremities",
		description    = "The hands and fingertips are noticeably cold even in a warm room.",
		bodyRegion     = Humours.Regions.Arms,
		humour         = Humours.Blood,
		direction      = "deficiency",
		threshold      = -15,
		contribution   = -12,
		discoveryType  = "click",
	},

	wet_cough = {
		displayName    = "Wet cough",
		description    = "Patient coughs periodically; the cough sounds wet and productive.",
		bodyRegion     = Humours.Regions.Chest,
		humour         = Humours.Phlegm,
		direction      = "excess",
		threshold      = 5,
		contribution   = 8,
		discoveryType  = "click",
	},
	swollen_ankles = {
		displayName    = "Swollen ankles",
		description    = "The ankles are visibly swollen. Pressing the skin briefly leaves an indent.",
		bodyRegion     = Humours.Regions.Legs,
		humour         = Humours.Phlegm,
		direction      = "excess",
		threshold      = 15,
		contribution   = 12,
		discoveryType  = "click",
	},
	dry_lips = {
		displayName    = "Dry lips",
		description    = "The lips are cracked and dry. The patient asks for water.",
		bodyRegion     = Humours.Regions.Head,
		humour         = Humours.Phlegm,
		direction      = "deficiency",
		threshold      = -5,
		contribution   = -8,
		discoveryType  = "click",
	},
	flaky_skin = {
		displayName    = "Flaky skin",
		description    = "Patches of dry, flaking skin on the forearms.",
		bodyRegion     = Humours.Regions.Arms,
		humour         = Humours.Phlegm,
		direction      = "deficiency",
		threshold      = -15,
		contribution   = -12,
		discoveryType  = "click",
	},

	jaundice = {
		displayName    = "Jaundice",
		description    = "The whites of the eyes have a yellow cast.",
		bodyRegion     = Humours.Regions.Head,
		humour         = Humours.YellowBile,
		direction      = "excess",
		threshold      = 5,
		contribution   = 8,
		discoveryType  = "click",
	},
	tender_side = {
		displayName    = "Tender side",
		description    = "The area below the ribs on the right side is tender to gentle pressure.",
		bodyRegion     = Humours.Regions.Chest,
		humour         = Humours.YellowBile,
		direction      = "excess",
		threshold      = 15,
		contribution   = 12,
		discoveryType  = "skill_check",
	},
	sallow_skin = {
		displayName    = "Sallow skin",
		description    = "The patient's skin has a dull, drained tone — not pale, but lifeless.",
		bodyRegion     = Humours.Regions.Head,
		humour         = Humours.YellowBile,
		direction      = "deficiency",
		threshold      = -5,
		contribution   = -8,
		discoveryType  = "click",
	},
	weak_grip = {
		displayName    = "Weak grip",
		description    = "When asked to grip the doctor's hand, the patient's grip is noticeably weak.",
		bodyRegion     = Humours.Regions.Arms,
		humour         = Humours.YellowBile,
		direction      = "deficiency",
		threshold      = -15,
		contribution   = -12,
		discoveryType  = "click",
	},

	dark_undereyes = {
		displayName    = "Dark undereyes",
		description    = "The skin beneath the patient's eyes is darkened and hollow.",
		bodyRegion     = Humours.Regions.Head,
		humour         = Humours.BlackBile,
		direction      = "excess",
		threshold      = 5,
		contribution   = 8,
		discoveryType  = "click",
	},
	swollen_bubo = {
		displayName    = "Swollen bubo",
		description    = "A hard, tender swelling has formed beneath the jaw, characteristic of plague.",
		bodyRegion     = Humours.Regions.Head,
		humour         = Humours.BlackBile,
		direction      = "excess",
		threshold      = 15,
		contribution   = 12,
		discoveryType  = "skill_check",
	},
	restless_movement = {
		displayName    = "Restless movement",
		description    = "The patient cannot sit still. Their legs and feet shift constantly.",
		bodyRegion     = Humours.Regions.Legs,
		humour         = Humours.BlackBile,
		direction      = "deficiency",
		threshold      = -5,
		contribution   = -8,
		discoveryType  = "click",
	},
	scattered_attention = {
		displayName    = "Scattered attention",
		description    = "The patient cannot hold a thought. Their eyes dart; they change topic mid-sentence.",
		bodyRegion     = Humours.Regions.Passive,
		humour         = Humours.BlackBile,
		direction      = "deficiency",
		threshold      = -15,
		contribution   = -12,
		discoveryType  = "click",
	},
}

return SymptomData
