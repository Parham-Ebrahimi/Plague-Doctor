local GameConstants = {
	-- Time. Short values for testing; tune later.
	HOUR_IN_SECONDS = 60,
	HOURS_PER_DAY = 16,

	-- How many in-game days an NPC stays in each stage before progressing.
	STAGE_DURATIONS = {
		[2] = 2,
		[3] = 2,
		[4] = 1,
	},

	WALK_SPEEDS = {
		[1] = 10,
		[2] = 10,
		[3] = 8,
		[4] = 4,
		[5] = 0,
	},

	STAGE_COLORS = {
		[3] = Color3.fromRGB(160, 170, 145),
		[4] = Color3.fromRGB(130, 140, 118),
	},

	-- Player interaction.
	PROXIMITY_RANGE = 5,
	EXAM_VALID_RANGE = 7,
	COMFORT_TIMER = 25,

	-- Temporary NPC wandering test values.
	NPC_WANDER_RADIUS = 18,
	NPC_WANDER_INTERVAL_MIN = 3,
	NPC_WANDER_INTERVAL_MAX = 6,

	SATCHEL_SIZE = 8,

	COUGH_INTERVAL_MIN = 8,
	COUGH_INTERVAL_MAX = 15,

	BROAD_SPECTRUM_DURATION_DAYS = 1,
	BROAD_SPECTRUM_MULTIPLIER = 0.5,

	-- Camera. All angles in degrees, distances/amplitudes in studs.
	CAMERA_SENSITIVITY = 0.2,
	CAMERA_THIRD_PERSON_DIST = 8,
	CAMERA_THIRD_PERSON_HEIGHT = 2,
	CAMERA_THIRD_PERSON_SHOULDER_OFFSET = 1.5,
	CAMERA_LERP_SPEED = 18,

	CAMERA_BOB_WALK_FREQ = 8,
	CAMERA_BOB_WALK_AMP_V = 0.08,
	CAMERA_BOB_WALK_AMP_H = 0.05,
	CAMERA_BOB_RUN_FREQ = 12,
	CAMERA_BOB_RUN_AMP_V = 0.15,
	CAMERA_BOB_RUN_AMP_H = 0.10,

	CAMERA_SWAY_FREQ = 0.6,
	CAMERA_SWAY_AMP_FP = 0.6,
	CAMERA_SWAY_AMP_TP = 0.25,

	-- First-person horizontal head-turn limits in degrees, relative to the
	-- character's facing direction. Mirrors real human head rotation range.
	CAMERA_FP_YAW_MIN = -80,
	CAMERA_FP_YAW_MAX = 80,

	-- Local player movement. NPC speeds live in WALK_SPEEDS above and are
	-- unrelated to these.
	PLAYER_WALK_SPEED = 8,
	PLAYER_RUN_SPEED = 20,
	PLAYER_STAMINA_MAX = 100,
	PLAYER_STAMINA_DRAIN_RATE = 25,
	PLAYER_STAMINA_REGEN_RATE = 10,
	PLAYER_STAMINA_REGEN_THRESHOLD = 0.25,
}

return GameConstants
