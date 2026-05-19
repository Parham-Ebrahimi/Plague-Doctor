# Plague Doctor — Current Status

## Active Branch
`feature/humours-examination` — building the four-humours examination
system on top of the existing camera prototype.

## What Works (on this branch)
- NPC interaction: press E on a sick NPC, server validates, client opens
  examination flow
- Examination camera: smooth glide to the NPC framed on the left of the
  screen, character fades out, held position throughout examination,
  smooth glide back on exit, character fades back in
- NPC rotation: NPCs server-side rotate to face the player when E is
  pressed
- Examination panel: redesigned for four-humours system, shows hardcoded
  NPC info (name, occupation, age, notes), four empty humour rows
  (Blood, Phlegm, Yellow Bile, Black Bile), Leave button to exit
- A SetHumour BindableEvent on TreatmentPanelUI for future scripts to
  populate humour values
- Shared Humours module at `src/shared/core/Humours.lua` — single source
  of truth for the four humour name strings (display-name keys with
  spaces preserved) and an ordered `Names` array for iteration
- Server-side humour state: each NPC gets four random integer humour
  values in [-20, 20] generated once at registration in NPCData and
  intentionally not re-rolled on stage transitions; range constants live
  in GameConstants under a `-- Humours.` section
- ExaminationApproved payload extended with a `humours` field carrying
  the per-NPC humour map (display-name keys, integer values)
- Client-side ExaminationState store at `src/client/world/ExaminationState.lua`
  — public API of `SetCurrentNPC`, `ClearCurrentNPC`, `GetCurrentNPC`,
  `GetHumour`, `GetAllHumours` (shallow copy); populated by
  TreatmentPanelUI on examination open, cleared on close; serves as the
  source of truth other client scripts read from

## In Progress / Next Steps
- Body-region clicking: a new client-side script that detects clicks on
  the NPC's head, chest, arms, legs during examination; each region
  reveals one humour value by firing the SetHumour BindableEvent on
  TreatmentPanelUI. Locked region-to-humour mapping: Head → Black Bile,
  UpperTorso/LowerTorso → Blood, all arm parts (both sides) → Yellow
  Bile, all leg parts (both sides) → Phlegm. Mapping will live in
  Humours.BodyRegions keyed by Roblox part name, with values referencing
  Humours.Blood / Humours.Phlegm / etc. for single-source-of-truth. First
  click on a region reveals; subsequent clicks on the same region are
  no-ops (revealed values stay visible). Re-examining the same NPC after
  Leave starts with em-dashed rows again — the panel resets on every
  open and the click script resets its revealed-humours set whenever the
  examined NPC reference changes.

## Deferred Decisions
- Whether to keep the NPC-turn feature in the eventual house-visits
  model (where NPCs are bedridden and the rotation may not be needed)
- Treatment / alchemy system (the actual potion-mixing and humour-
  balancing gameplay)
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
  open and the click-detection script will reset its revealed set
  whenever the examined NPC reference changes. Persistence would
  require a cache (client- or server-side) and a deliberate design
  decision on scope (per-session, per-NPC, per-player). Deferred until
  there's evidence persistence improves the loop.
- Whether the examination camera framing needs adjustment to expose
  all four clickable body regions. Current framing crops the head on
  taller NPCs; deferred until click-detection playtest confirms whether
  this actually blocks reveals or just looks odd.
- House-visits vs. street-examination model: tentatively committed to
  house-visits but no implementation yet
- Whether no-op clicks during body-region examination should produce visual feedback (a brief flash, a sound, a cursor change) to distinguish them from genuinely broken clicks. Currently a click that hits an unmapped part or a region whose humour is already revealed produces zero feedback, which is indistinguishable from a click that did nothing because something is broken. Playtest of body-region clicking revealed this generates false bug reports; deferred because the right answer involves a visual-design decision rather than a code change.

## Locked Design Commitments
- Four humours: Blood, Phlegm, Yellow Bile, Black Bile, range -20 to +20
- Examination reveals humour values via clicking body regions, mapped
  one-to-one at the region level (head -> one humour, chest -> one
  humour, arms -> one humour, legs -> one humour). Mapping is fixed
  (the same for every NPC), not randomised per-NPC.
- Examination is read-only; potions/treatment will modify humours
- Hardcoded NPC info during prototype phase
- Camera approach is the held-CFrame prototype (do not redesign without
  evidence from playtest)
- Server-authoritative humour state — values live on the server and the
  client only sees them after ExaminationApproved
- Display-name strings ("Blood", "Phlegm", "Yellow Bile", "Black Bile")
  used as humour identifiers end-to-end (server entry keys, payload
  keys, ExaminationState keys, SetHumour parameter, panel label keys)
  — single source of truth in `src/shared/core/Humours.lua`