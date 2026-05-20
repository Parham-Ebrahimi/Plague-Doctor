# Plague Doctor — Current Status

## Active Branch
`main` — the `feature/humours-examination` branch has been merged.
Next feature work should branch fresh from `main`.

## What Works (on main)
- NPC interaction: press E on a sick NPC, server validates, client opens
  examination flow
- Examination camera: smooth glide to the NPC framed on the left of the
  screen, character fades out, held position throughout examination,
  smooth glide back on exit, character fades back in
- NPC rotation: NPCs server-side rotate to face the player when E is
  pressed
- Examination panel: shows hardcoded NPC info (name, occupation, age,
  notes), four humour rows (Blood, Phlegm, Yellow Bile, Black Bile)
  that fill in as the player clicks body regions, Leave button to exit
- A SetHumour BindableEvent on TreatmentPanelUI for revealing humour
  values
- Shared Humours module at `src/shared/core/Humours.lua` — single source
  of truth for the four humour name strings (display-name keys with
  spaces preserved), an ordered `Names` array for iteration, and a
  `BodyRegions` table mapping R15 part names to the humour each region
  reveals
- Server-side humour state: each NPC gets four random integer humour
  values in [-20, 20] generated once at registration in NPCData and
  intentionally not re-rolled on stage transitions; range constants live
  in GameConstants under a `-- Humours.` section
- ExaminationApproved payload extended with a `humours` field carrying
  the per-NPC humour map (display-name keys, integer values)
- Client-side ExaminationState store at `src/client/world/ExaminationState.lua`
  — public API of `SetCurrentNPC`, `ClearCurrentNPC`, `GetCurrentNPC`,
  `GetHumour`, `GetAllHumours` (shallow copy); populated by
  TreatmentPanelUI on examination open, cleared on close; emits a
  `CurrentNPCChanged` BindableEvent on every transition (nil ↔ NPC),
  carrying the new value
- Body-region click detection at `src/client/world/BodyRegionClicks.client.lua`
  — listens for MouseButton1 during examination, raycasts with an
  NPC-Include filter, walks through unmapped parts (HumanoidRootPart,
  accessory Handles) up to 5 iterations until it finds a mapped body
  part, looks up the humour in Humours.BodyRegions, fires SetHumour to
  reveal the value; resets its revealed-humours set on every
  CurrentNPCChanged transition so same-NPC re-examination starts fresh

## In Progress / Next Steps

### Major redesign: examination as symptom discovery
The current click-to-reveal mechanic (one click per body region, one
humour value revealed) is being redesigned around symptoms as the
player-facing diagnostic vocabulary. The redesign closes the loop
toward treatment by giving the player something to *infer* from
examination, rather than handing them the answer directly.

Player-facing model:
- The player examines a patient by clicking body regions and
  observing other channels (passive observation on panel open is
  free; later iterations may add tools, dialogue, etc., but those
  are deferred)
- Each region reveals which *symptoms* the patient currently presents
  (e.g. "fever," "pallor," "swollen buboes"), not raw humour values
- Each symptom carries a numeric contribution to one specific humour
  (e.g. fever contributes +X to Blood, sweating contributes -Y to
  Blood)
- The panel maintains a running humour graph (bipolar visualisation,
  centre = balance, up = excess, down = deficiency) that updates per
  symptom as the player discovers them
- When all symptoms for a patient have been found, the running graph
  equals the true humour values
- If the player misses symptoms, their estimate diverges from the
  true values by the missed symptoms' contributions; this misjudgement
  produces a slightly wrong remedy and a less effective treatment
  (this consequence depends on the treatment system, which is also
  next)

Architecture:
- Humour values remain the ground truth, stored server-side per NPC
  (humours-first design)
- Symptoms are *derived* from humour values via deterministic rules
  (each symptom has a threshold condition on the humour state and a
  contribution value the player learns when they observe it)
- The server computes the symptom set for each NPC at examination
  start and sends the set with contributions in the
  ExaminationApproved payload; raw humour values are no longer sent
  to the client (server-authoritative tightening)
- The client's ExaminationState stores the symptom set instead of
  (or in addition to) the humour map; the panel's humour graph is
  computed by summing contributions from revealed symptoms

The draft symptom vocabulary, mappings, and contribution values live
in `docs/symptom-vocabulary.md` and should be reviewed before
implementation begins.

### After symptoms: treatment / alchemy
The treatment system is the natural follow-on. The player crafts
remedies that target specific humours (raise Blood, lower Phlegm,
etc.), applies them to the patient, and the server updates the
NPC's humour values accordingly. Symptoms automatically update
based on the new values (humours-first benefit). The exact crafting
mechanism is deferred — it could be recipe-based, ingredient-mixing,
or something else; that's a separate design conversation.

## Deferred Decisions
- Whether to keep the NPC-turn feature in the eventual house-visits
  model (where NPCs are bedridden and the rotation may not be needed)
- Real NPC data (currently all hardcoded as "Leofwine Brewstere" — will
  later be driven by Roblox attributes on each NPC model)
- Stripping the now-dead TreatmentResult and QuarantineResult handlers
  in TreatmentPanelUI
- Whether `TreatmentPanelUI`'s local `currentTargetNPC` should be
  replaced by reads of `ExaminationState.GetCurrentNPC()` after
  body-region click detection lands. The two are populated and cleared
  in lockstep today; consolidating before a second consumer exists would
  couple panel UI state to the public examination state contract on
  speculation rather than evidence.
- Whether `COMFORT_TIMER` should pause while a treatment panel is open.
  The 25-second proximity timer currently force-closes any examination
  that runs longer, including ones where the player is actively
  clicking body regions. Behaviourally degrades the humours UX; deferred
  because the fix is to ProximityDetector, not to the humours flow
  itself.
- Whether examined humour values should persist across re-examinations
  of the same NPC. Currently the panel resets to em-dashes on every
  open and the click-detection script resets its revealed set whenever
  the examined NPC reference changes. Persistence would require a cache
  (client- or server-side) and a deliberate design decision on scope
  (per-session, per-NPC, per-player). Deferred until there's evidence
  persistence improves the loop.
- Whether the examination camera framing needs adjustment to expose
  all four clickable body regions. Current framing crops the head on
  taller NPCs; deferred until click-detection playtest confirms whether
  this actually blocks reveals or just looks odd.
- Whether no-op clicks during body-region examination should produce
  visual feedback (a brief flash, a sound, a cursor change) to
  distinguish them from genuinely broken clicks. Currently a click that
  hits an unmapped part or a region whose humour is already revealed
  produces zero feedback, which is indistinguishable from a click that
  did nothing because something is broken. Playtest of body-region
  clicking revealed this generates false bug reports; deferred because
  the right answer involves a visual-design decision rather than a
  code change.
- Whether tools (uroscopy, lancet, stethoscope-equivalent, etc.) should
  be added to examination as additional channels beyond body-region
  clicks. Considered during the symptoms redesign and explicitly
  deferred — the body-region clicking with auto-updating graph is the
  starting point; tools are a depth-extension to revisit after playtest.
- Whether symptom severity / intensity should be modelled (a symptom
  with multiple presentation strengths, e.g. mild fever vs burning
  fever, contributing different amounts based on how far the underlying
  humour is from its threshold). The first implementation uses fixed
  per-symptom contributions; intensity is a refinement available
  later because the humours-first architecture naturally supports it.
- Whether the player-facing UI should display raw integer humour
  values (-20 to +20) or bucketed labels ("Excess," "Balance," etc.).
  The internal range stays -20 to +20; the UI translation is a
  visual decision to make when building the new panel.
- The tonal direction of the game (approachable-medieval vs
  grim-plague-visceral). Reference imagery is leaning toward grim;
  decide deliberately before committing to character art and writing
  style.
- House-visits vs. street-examination model: tentatively committed to
  house-visits but no implementation yet

## Locked Design Commitments
- Four humours: Blood, Phlegm, Yellow Bile, Black Bile, range -20 to +20
- Server-authoritative humour state — values live on the server and the
  client only sees the *derived symptom set* after ExaminationApproved
  (in the redesigned system; the current shipped system sends raw values
  but will be tightened during the symptoms redesign)
- Display-name strings ("Blood", "Phlegm", "Yellow Bile", "Black Bile")
  used as humour identifiers end-to-end (server entry keys, payload
  keys, ExaminationState keys, SetHumour parameter, panel label keys)
  — single source of truth in `src/shared/core/Humours.lua`
- Examination reveals humour state indirectly via symptoms, not via
  direct value reveal. The player observes symptoms; the panel sums
  symptom contributions into a running humour graph; the player infers
  the patient's humour profile from the graph
- Symptoms are derived deterministically from humour values
  (humours-first architecture). Symptoms don't have independent
  existence — they're a projection of the underlying humour state
- Each symptom carries a fixed contribution to one humour. Symptoms
  contributing to the same humour sum together. A fully-examined
  patient's graph equals their true humour values
- Symptoms are associated with body regions (head, chest, arms, legs)
  for click-based discovery, with passive-on-open as a free first-pass
- The graph starts at 0 for each humour (no symptoms found =
  player's estimate is balanced/unknown) and shifts up or down as
  symptoms are observed
- Bipolar visualisation (centre = 0 = balance, up = excess, down =
  deficiency); art treatment to be decided but the mathematical shape
  is fixed
- Examination is read-only; treatment (alchemy) is what modifies
  humours
- Hardcoded NPC info during prototype phase
- Camera approach is the held-CFrame prototype (do not redesign without
  evidence from playtest)