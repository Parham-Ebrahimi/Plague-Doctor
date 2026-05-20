# Plague Doctor — Current Status

## Active Branch
`feature/examination-redesign` — building the symptoms-based
examination system on top of the shipped click-to-reveal
baseline. The `feature/humours-examination` branch has already
been merged to main.

## Build Strategy

The game uses **horizontal-slice development**: build a crude
version of every loop step for the day-one experience before
deepening any single system. The goal of the first major
milestone is a playable day-one loop (wake → examine → brew →
treat → repeat) where every system exists in its simplest
working form. Deepening happens iteratively after the loop is
playable.

Specifically, day-one consists of:
1. Player wakes in their house. A note on the desk lists the
   day's sick NPC(s).
2. Player walks outside, checks the garden, gathers ingredients.
3. Player walks to the city. Random environmental events occur
   along the way based on city infection state.
4. Player reaches a sick NPC's house, enters, walks up to them,
   presses E.
5. Examination panel opens: NPC on the left, journal on the
   right with that NPC's page (name, age, occupation, notes,
   humour graph all at 0).
6. Player clicks body regions to discover symptoms.
7. Player flips to journal page 2 (symptom-reference key) to
   look up each symptom's humour and value.
8. Player flips back to the patient page, drags humour
   medallions to integer positions matching their calculations.
9. Player exits examination. Journal retains state.
10. Player walks back to apothecary, brews potions with
    gathered ingredients.
11. Player returns to NPC, applies potion. Graph updates.
12. If treatment was successful (within tolerance), NPC is
    cured. Their page leaves the active journal.
13. Repeat for other patients. Player sleeps to end day.

The first goal is to get this *crude but complete* end-to-end.
Each system in the loop starts at the simplest functional
version and is deepened after the loop is playable.

## What Works (on main)
- NPC interaction: press E on a sick NPC, server validates,
  client opens examination flow
- Examination camera: smooth glide to the NPC framed on the
  left of the screen, character fades out, held position
  throughout examination, smooth glide back on exit, character
  fades back in
- NPC rotation: NPCs server-side rotate to face the player when
  E is pressed
- Examination panel: shows hardcoded NPC info (name, occupation,
  age, notes), four humour rows that fill in as the player
  clicks body regions, Leave button to exit
- A SetHumour BindableEvent on TreatmentPanelUI for revealing
  humour values
- Shared Humours module at `src/shared/core/Humours.lua`:
  single source of truth for the four humour name strings, an
  ordered `Names` array, and a `BodyRegions` table mapping R15
  part names to humours
- Server-side humour state: each NPC gets four random integer
  humour values in [-20, 20] generated once at registration;
  range constants live in GameConstants under a `-- Humours.`
  section
- ExaminationApproved payload extended with a `humours` field
  carrying the per-NPC humour map
- Client-side ExaminationState store at
  `src/client/world/ExaminationState.lua` with public API
  Set/Clear/Get and a CurrentNPCChanged event
- Body-region click detection at
  `src/client/world/BodyRegionClicks.client.lua`: raycasts
  through unmapped parts, fires SetHumour, resets revealed set
  on examination transitions

## In Progress / Next Steps

### Examination redesign — day-one slice
Replace the click-to-reveal-humour-value mechanic with the
symptom-discovery model described in
`docs/symptom-vocabulary.md`. For the day-one slice:

- All 16 symptoms exist in code and are derived deterministically
  from NPC humour values server-side
- All symptoms are discovered through simple clicks on body
  regions (no skill-check minigames yet, no body-region zoom
  yet, no visual indicators on body parts)
- The examination panel is redesigned: NPC on the left, journal
  on the right
- The journal has two pages: patient page (name, occupation,
  age, notes, bipolar humour graph) and symptom-reference page
  (key: each symptom's humour and contribution value)
- The player manually drags humour medallions on the bipolar
  graph to integer positions matching their calculations
- Examination state persists across visits (journal retains
  graph state when player leaves and returns)
- Patient notes are hand-authored hardcoded strings per-NPC
  type for first implementation

What the day-one slice deliberately *does not* include
(deferred to later iterations):
- Camera zoom into body regions
- Visual indicators of symptoms on the NPC body
- Skill-check minigames
- Multi-page journal navigation beyond the two pages above
- Polished art for journal, body-region indicators, etc.
- Notepad / scratchpad UI for player math

### Other day-one systems (after examination)
After examination is functional, build crude versions of the
rest of the day-one loop. Each in order, each playtested before
moving on:

- Apothecary / brewing system (minimal: input target humour
  and magnitude, get potion in inventory)
- Potion application on NPCs (button to apply, server updates
  humour values, graph updates on re-examination)
- Garden with collectible ingredients (static area, click to
  collect)
- Ingredient inventory UI
- Morning note placement on player's desk
- Sleep-to-end-day interaction
- A second NPC to examine (variation in patient cases)

Beyond day-one (deferred):
- Multiple NPCs across the city
- Market stalls with ingredient purchase
- City infection state visualisation (changes to props by
  infection level)
- Random environmental events while walking
- Day cycle with morning/day/night states
- District infection pools
- Quest / event systems
- Persistence across game sessions

## Deferred Decisions

- Whether to keep the NPC-turn feature in the eventual house-
  visits model
- Real NPC data (currently all hardcoded; eventually driven by
  Roblox attributes on each NPC model)
- Stripping the now-dead TreatmentResult and QuarantineResult
  handlers in TreatmentPanelUI
- Whether `TreatmentPanelUI`'s local `currentTargetNPC` should
  be replaced by reads of `ExaminationState.GetCurrentNPC()`
- Whether `COMFORT_TIMER` should pause while a treatment panel
  is open
- Whether the examination camera framing needs adjustment to
  expose all four clickable body regions
- Whether no-op clicks during body-region examination should
  produce visual feedback (a brief flash, a sound, a cursor
  change) to distinguish them from genuinely broken clicks
- Whether tools (uroscopy, lancet, stethoscope-equivalent, etc.)
  should be added to examination as additional channels beyond
  body-region clicks and skill checks
- Whether symptom severity / intensity should be modelled (a
  symptom with multiple presentation strengths)
- Whether the player-facing UI should display raw integer
  humour values (-20 to +20) or bucketed labels ("Excess,"
  "Balance," etc.)
- The tonal direction of the game (approachable-medieval vs
  grim-plague-visceral)
- Skill-check minigame style (slider-based pressure, Stardew-
  fishing-bar, osu-circle-tap)
- Skill-check failure handling (retry vs lock-out)
- Visual indicator art style (photorealistic, stylised,
  abstract)
- Whether patient notes should be hand-authored per-NPC or
  generated from the symptom set
- Camera zoom transition timing and easing for body-region zoom
- Whether examination ever becomes "expert mode" where
  experienced players can skip examination entirely
- Whether NPCs should have natural temperaments — innate humour
  profiles that aren't 0/0/0/0
- Exact alchemy/crafting mechanics (recipes, ingredient
  mixing, workbenches)
- Whether multiple potions applied in quick succession should
  have diminishing returns or side effects
- Whether potions have a cost (gold, ingredient inventory,
  in-game time) that creates pressure against trial-and-error
- How treatment quality score is consumed by larger game
  systems (morale, district infection, NPC relationships, XP)
- Notepad / scratchpad UI for player math during examination
- How the previous plague doctor's death/disappearance is
  communicated through the journal and other clues (deferred,
  but locked as a load-bearing narrative thread)
- House-visits vs. street-examination model
- Day cycle implementation (morning/day/night state, transition
  triggers, visual changes)
- Garden growth mechanics (real-time, day-based, instant)

## Locked Design Commitments

### Core architecture
- Four humours: Blood, Phlegm, Yellow Bile, Black Bile, range
  -20 to +20
- Server-authoritative humour state — values live on the server
  and the client only sees the derived symptom set after
  ExaminationApproved (in the redesigned system; the current
  shipped system sends raw values but will be tightened during
  the symptoms redesign)
- Display-name strings used as humour identifiers end-to-end —
  single source of truth in `src/shared/core/Humours.lua`
- Symptoms are derived deterministically from humour values
  (humours-first architecture). Symptoms don't have independent
  existence — they're a projection of the underlying humour
  state
- Symptoms are stored in `src/shared/data/SymptomData.lua` with
  full properties; humour-to-symptom derivation is computed
  server-side from humour values

### Examination
- Examination reveals humour state indirectly via symptoms, not
  via direct value reveal
- Examination has 16 symptoms total, 4 per humour (2 excess, 2
  deficiency). Thresholds at ±5 and ±15 with contributions ±8
  and ±12 in each direction
- The player manually places humour values on the graph by
  observing symptoms, looking up contribution values in the
  journal's symptom-reference page, and dragging medallions to
  integer positions. The graph does **not** auto-update.
- Examination uses body-region clicks for discovery. In the
  day-one slice these are simple clicks; the eventual full
  design adds a body-region zoom and visual indicators on body
  parts (deferred)
- Three symptoms (bounding_pulse, tender_side, swollen_bubo)
  are designed to use skill-check minigames in the eventual
  full design. In the day-one slice they are simple clicks.
- Patient notes in the journal always reliably indicate where
  symptoms can be found (always-true notes in first
  implementation)
- Symptom vocabulary excludes discharge, genital examination,
  and anything sexual. Tonally medical-serious but Roblox-
  appropriate
- The graph starts at 0 for each humour (player's initial state
  before any examination) and shifts only when the player drags
  a medallion
- Bipolar visualisation (centre = 0 = balance, up = excess,
  down = deficiency); art treatment to be decided but the
  mathematical shape is fixed
- Examination persists across visits. When the player leaves a
  patient and returns, the journal page reflects the state of
  the player's previous examination (the medallion positions
  they placed). The player can revise their placements if they
  re-examine and find new information

### Treatment
- Examination is read-only; treatment (alchemy) is what
  modifies humours
- Player's treatment goal: bring all four humours to 0 (balance)
- Treatment effectiveness model: graded by accuracy. Treatment
  within ±7 of the true humour value achieves full effect for
  that humour (humour goes to 0). Treatment outside that
  tolerance achieves partial effect or, at large error, may
  worsen the patient. The ±7 tolerance matches the worst-case
  quantisation error of the symptom system, so thorough
  examination guarantees successful treatment.
- Treatment is direct: a potion specifies a humour modifier
  (e.g. -8 Blood) and applies that modifier directly to the
  humour value, regardless of the player's estimate. The graph
  updates automatically on re-examination as symptoms change.
- Crafting is ingredient-additive: each ingredient has a fixed
  humour modifier; combining ingredients sums their modifiers.
  Players craft potions of any magnitude by choosing ingredient
  quantities (e.g., 4 willowbark = -8 Blood). Specific
  ingredients and modifiers are deferred to the alchemy system
  design.
- Bonus reward scales with how close to 0 the treatment lands.
  Perfect 0/0/0/0 gives maximum bonus. Close-to-0 gives high
  bonus. Within-tolerance-but-not-close gives baseline bonus.
- Morale, happiness, and other consequences of treatment
  quality are deferred. The treatment system produces a
  numeric quality score; consumption of that score by gameplay
  systems happens later.

### Game shape and pacing
- The game's centre of gravity is the *rhythm of a day in a
  plague-stricken city*: wake, gather, walk, examine,
  calculate, brew, return, treat, sleep. No single mechanic
  carries the experience; the loop does.
- The pace is slow and methodical by design. Don't optimise
  for player speed.
- The city's visual state varies with infection level (boarded
  windows, fewer NPCs, closed stalls at high infection; lively
  streets, open commerce at low infection). Mechanics deferred,
  direction locked.
- Each NPC has a 3-day window from when they are listed as ill
  to either being cured or dying. Creates time pressure without
  frame-by-frame urgency.
- The journal is a finite physical artifact, not an infinite
  database. Framed as a previous plague doctor's research that
  the player is inheriting and continuing. Pages have meaning.
- The previous plague doctor's name is scratched out on the
  journal's title page. This is a load-bearing narrative
  thread (load-bearing because the game's tone depends on the
  presence of mystery and loss in the world). Specific
  implementation deferred.

### Implementation discipline
- Prototype-first prototype-architecture: small commits, each
  playtested before moving on, each touches one concern at a
  time
- Server-authoritative for any state that affects gameplay
- Hardcoded NPC info during prototype phase
- Camera approach is the held-CFrame prototype (do not redesign
  without evidence from playtest)