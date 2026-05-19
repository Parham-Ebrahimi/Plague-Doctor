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

## In Progress / Next Steps
- Server-side humour state: each NPC gets four random humour values
  (range -20 to +20) generated at registration, stored in NPCData
- Body-region clicking: a new client-side script that detects clicks on
  the NPC's head, chest, arms, legs during examination; each region
  reveals one humour value by firing the SetHumour BindableEvent

## Deferred Decisions
- Whether to keep the NPC-turn feature in the eventual house-visits
  model (where NPCs are bedridden and the rotation may not be needed)
- Treatment / alchemy system (the actual potion-mixing and humour-
  balancing gameplay)
- Real NPC data (currently all hardcoded as "Leofwine Brewstere" — will
  later be driven by Roblox attributes on each NPC model)
- Stripping the now-dead TreatmentResult and QuarantineResult handlers
  in TreatmentPanelUI
- House-visits vs. street-examination model: tentatively committed to
  house-visits but no implementation yet

## Locked Design Commitments
- Four humours: Blood, Phlegm, Yellow Bile, Black Bile, range -20 to +20
- Examination reveals humour values via clicking body regions, mapped
  one-to-one (head -> one humour, chest -> one humour, arms -> one
  humour, legs -> one humour)
- Examination is read-only; potions/treatment will modify humours
- Hardcoded NPC info during prototype phase
- Camera approach is the held-CFrame prototype (do not redesign without
  evidence from playtest)