# Spec Doc — NPC Interaction System
**Game:** Plague Doctor  
**Feature:** Player-to-NPC Interaction  
**Version:** 1.0  
**Status:** Draft  

---

## 1. Overview

This document specifies the full behaviour of the player interacting with an NPC — from the moment the player visually notices them, to the moment the interaction resolves. This is the most frequent action in the game and the primary expression of the treat verb. Every decision made in this system affects the journal, the district infection pool, NPC state, morale, and the player's satchel inventory.

---

## 2. Scope

This spec covers:
- Passive visual detection of NPCs from a distance
- Proximity-based interaction trigger
- The treatment panel — layout, contents, and behaviour
- Symptom display and how it maps to the journal
- Remedy application and outcomes
- Quarantine application and outcomes
- Broad spectrum remedy application and outcomes
- Journal logging triggered by interaction
- NPC state transitions post-interaction
- Morale effects
- Edge cases and failure states

This spec does not cover:
- Crafting system (separate spec)
- Journal UI layout in full (separate spec)
- Map update logic (separate spec)
- Quarantine marker inventory management (separate spec)

---

## 3. NPC States Relevant to This Feature

An NPC can be in one of five infection stages. Only stages 3 and 4 are interactable for treatment. Stage 2 is not yet detectable. Stage 5 triggers a different interaction (body disposal, out of scope here).

| Stage | Name | Visible to Player | Treatable | Urgency |
|---|---|---|---|---|
| 1 | Healthy | Yes | No | None |
| 2 | Exposed | No | No | None |
| 3 | Symptomatic | Yes | Yes | Medium |
| 4 | Critical | Yes | Yes | High |
| 5 | Dead | Yes | No (body disposal only) | N/A |

---

## 4. Phase 1 — Passive Visual Detection

### 4.1 Description
The player does not need to click or interact to begin noticing NPCs. Visual and audio cues broadcast NPC state passively as the player moves through the world. The player is expected to read the environment while walking, not tab through a list.

### 4.2 Visual Indicators by Stage

**Stage 3 — Symptomatic:**
- Movement speed reduced by ~25% from baseline
- Idle animation includes occasional hunch
- Skin tint shifts subtly toward grey-green (not dramatic — readable at 5–8 studs)
- Cough animation triggers every 8–15 seconds (randomised interval from pool of 2–3 cough animations)
- No UI element appears automatically — the player reads this environmentally

**Stage 4 — Critical:**
- Movement speed reduced by ~60% from baseline or NPC is stationary
- NPC may be leaning against a wall or partially collapsed in idle animation
- Skin tint is pronounced — visibly wrong at 10+ studs
- Cough animation frequency increases, occasionally replaced with a laboured breathing animation
- No UI element appears automatically

**Stage 1 — Healthy:**
- Normal movement speed and animations
- No visual indicators
- No audio cues

### 4.3 Audio Indicators
- Cough sound is 3D positional audio attached to the NPC model
- Fades with distance — audible from approximately 15–20 studs
- 2–3 audio files selected randomly per cough event to prevent repetition
- Symptomatic NPCs play cough audio on the same randomised timer as the animation

### 4.4 Urgency Readability Rule
A critical NPC must be visually distinguishable from a symptomatic NPC from at least 8 studs away without interaction. The player should never need to approach to determine urgency tier. Visual severity must be calibrated during development to ensure this holds.

---

## 5. Phase 2 — Proximity and Interaction Trigger

### 5.1 Proximity Threshold
When the player enters within **4–5 studs** of an NPC in stage 3 or stage 4, an interaction prompt appears. This is the only UI element that appears before the player chooses to interact.

### 5.2 Interaction Prompt
- Simple keybind prompt — e.g. `[E] Examine`
- Appears above the NPC or in the lower-centre screen (to be decided in UI pass)
- Does not appear for healthy NPCs (stage 1) or dead NPCs (stage 5)
- Does not appear for exposed NPCs (stage 2) — they are undetectable
- Disappears if the player moves beyond proximity threshold before pressing

### 5.3 NPC Comfort Timer
Once the player enters proximity and the prompt appears, an invisible timer begins — approximately **25–30 real seconds**. If the player does not interact within this window, the NPC becomes uncomfortable and walks away, dismissing the prompt. This prevents the player from parking next to an NPC indefinitely while thinking.

The timer only begins when the player is within threshold distance. It does not count down while the player is outside range.

---

## 6. Phase 3 — The Treatment Panel

### 6.1 Trigger
Player presses the interaction key within proximity and within the comfort timer window. The treatment panel opens.

### 6.2 Panel Layout
The treatment panel is a non-fullscreen overlay. It does not close the game world view — the player can still see the city behind it. It occupies roughly the right half of the screen.

**Panel sections (top to bottom):**

**NPC display**
- NPC name (generic title if unnamed — "Market Worker", "Resident", "Child")
- Brief descriptor of their visible state in the player's voice — written as a short observation, not a medical label. Example: *"Pale. Moving slowly. Has been coughing since I approached."*
- This descriptor is written by the system but framed as the player character's observation

**Symptom icons**
- 2–5 symptom icons displayed depending on the NPC's condition
- Each icon has a short label beneath it (e.g. "Fever", "Dark swelling", "Laboured breathing", "Tremors", "Surface wound")
- Icons are visually distinct and consistent — same icon always represents the same symptom across all interactions
- Symptom combinations vary by disease type and stage

**Satchel inventory panel**
- Shows all items currently in the player's satchel (6–8 slots)
- Items that have any relevance to the current symptom set glow softly — a subtle highlight, not a flashing arrow
- Relevance glow is based on broad category match (e.g. fever symptoms cause cooling-property items to glow), not exact recipe match
- Items the player has never used before do not glow regardless of relevance — the glow is earned through previous documented use
- Empty slots are shown as empty

**Journal button**
- A button or keybind that opens the journal in a side panel without closing the treatment panel
- Journal and treatment panel are simultaneously visible — the player can cross-reference notes while treating

**Action buttons**
- Apply [item] — enabled only when an item is selected from the satchel
- Quarantine — always available if the player has quarantine markers in their satchel
- Leave — closes the panel without action, NPC remains in current state

### 6.3 Item Selection
The player clicks or selects an item from the satchel panel to highlight it. The Apply button activates. The player then presses Apply to administer. There is no confirmation dialogue — Apply fires immediately. This keeps the interaction snappy.

### 6.4 Journal Side Panel Behaviour
When opened during the treatment panel:
- Journal opens to the Symptom Log by default
- Player can navigate to Treatment Records or Ingredient Notes from within
- Journal is read-only in this view — no editing
- Closing the journal returns focus to the treatment panel without closing it
- The journal remembers which section was last open within a session

---

## 7. Phase 4A — Applying a Remedy

### 7.1 Trigger
Player selects an item from their satchel and presses Apply.

### 7.2 Outcome — Correct remedy applied to matching condition

**Immediate:**
- Brief administration animation (2–3 seconds) — the player character reaches toward the NPC
- NPC responds with an animation (accepts the remedy, nods, or simply steadies themselves)
- Treatment panel closes
- A small non-intrusive confirmation appears — e.g. a brief text line "Treatment administered" — not a popup, just a UI line that fades after 3 seconds

**Over the next in-game hour:**
- NPC's infection stage begins reversing — critical NPCs move toward symptomatic, symptomatic NPCs move toward recovery
- NPC's visual indicators improve gradually — skin tone normalises, movement speed increases, cough frequency drops
- Full recovery from symptomatic stage takes approximately 1 in-game day
- Full recovery from critical stage takes approximately 1.5 in-game days
- District infection pool decreases: −2 pts for symptomatic, −3 pts for critical

**Journal logging (automatic, background):**
- If this symptom combination has not been successfully treated before: new entry added to Treatment Records — "Symptom set [icons] responded to [item name]. Confirmed effective."
- If this symptom combination has been treated before: existing entry updated with a repeat confirmation note
- No journal pop-up interrupts the player — logging is silent

### 7.3 Outcome — Wrong remedy applied

**Immediate:**
- Administration animation still plays — the player character does not know immediately that it was wrong
- NPC accepts the remedy
- Treatment panel closes

**Over the next in-game hour:**
- NPC does not improve — infection stage continues progressing at normal rate
- No immediate visible feedback that it was wrong — the player realises through lack of improvement when they next see the NPC

**Over the next 2 in-game hours:**
- If the player finds the NPC again, visual state has worsened despite the treatment attempt
- NPC may display a subtle "worse" animation state indicating no improvement

**Journal logging (automatic, background):**
- Entry added to Treatment Records: "Symptom set [icons] — [item name] administered. No improvement observed. Treatment appears ineffective."
- This negative entry is valuable data — it narrows future attempts

**District infection pool:**
- No change. A failed treatment does not reduce the pool.

### 7.4 Outcome — Remedy worsens the condition (rare, specific wrong combinations)

Reserved for a small number of specifically wrong combinations (e.g. a stimulating compound applied to a patient already in cardiac stress). Not triggered by most wrong remedies — only deliberate design decisions mark specific combinations as harmful.

**Immediate:**
- Administration animation plays — NPC reacts visibly with distress
- NPC staggers or flinches — clear visual signal something is wrong
- Treatment panel closes with a brief warning line: "The patient reacted badly."

**Over the next in-game hour:**
- NPC's stage progresses faster than normal — approximately 25% faster deterioration for 1 in-game hour before returning to normal rate
- If critical, time-to-death window narrows significantly

**Journal logging:**
- Entry added: "Symptom set [icons] — [item name] caused adverse reaction. Do not use on this presentation."

---

## 8. Phase 4B — Quarantine

### 8.1 Trigger
Player selects Quarantine from the action buttons. Requires at least one quarantine marker in the satchel.

### 8.2 Immediate Effects
- Quarantine animation plays (2–3 seconds) — player places a marker on the NPC and the nearest building door
- One quarantine marker is consumed from the satchel
- Treatment panel closes

### 8.3 NPC Behaviour Post-Quarantine
- NPC's movement radius shrinks to approximately 10–15 studs from the point of quarantine
- NPC will sit, stand, or pace a very short loop within this radius
- NPC does not walk to other districts
- NPC does not join crowd clusters
- A visible marker appears above the NPC — a small flag or coloured symbol visible from approximately 15–20 studs
- A matching marker appears on the nearest building door

### 8.4 Disease Progression During Quarantine
- The NPC's infection stage continues progressing at the normal rate
- Quarantine does not pause, slow, or cure the disease
- A critical NPC quarantined without treatment has approximately 1 in-game day before death (revised from earlier design)
- The player must return with the correct remedy within that window

### 8.5 Map Update
- On the player's next map open, the quarantined NPC appears as a distinct icon in the relevant district
- This is one of two live pieces of information the map provides (the other is active smoke/fumigation)

### 8.6 Effect on Nearby NPCs
- 2–3 NPCs within sight range react with visible animations — stepping back, covering mouths, moving away
- Morale in the immediate area takes a small hit — minor tick, not district-wide
- If multiple quarantines are applied in the same district within a short time, morale hits compound

### 8.7 Contact Spread During Quarantine
- Quarantined NPC still poses a reduced exposure risk to NPCs who pass within proximity
- Exposure risk is lower than free-roaming but not zero
- Boarding the nearest building eliminates residual exposure risk from the quarantined NPC (separate interaction on the building, out of scope here)

### 8.8 Journal Logging
- Entry added to District Notes: "Quarantined NPC [title] at [location descriptor] — [symptom icons noted]. Return with remedy."

---

## 9. Phase 4C — Broad Spectrum Remedy

### 9.1 Use Case
The player does not have a specific remedy for the NPC's condition but wants to slow deterioration without quarantining.

### 9.2 Trigger
Player selects a broad spectrum remedy from the satchel and presses Apply. Broad spectrum remedies are a specific item type crafted at a bench — they are not automatically available, the player must have crafted and carried them.

### 9.3 Immediate Effects
- Administration animation plays
- Treatment panel closes

### 9.4 Disease Progression Post-Application
- Infection stage progresses at approximately 50% of normal rate for 1 in-game day
- Does not reverse progression — only slows it
- Not cumulative — applying a second broad spectrum remedy does not stack the slowdown
- After 1 in-game day the slowdown effect expires and progression returns to normal rate

### 9.5 NPC Visual
- Subtle improvement in visual indicators — slight colour normalisation, slightly less frequent cough animation — to signal the player that something is happening without falsely implying a cure

### 9.6 District Infection Pool
- No change. Broad spectrum does not reduce the pool.

### 9.7 Journal Logging
- No new entry generated — broad spectrum use is not logged as a confirmed treatment or a failure
- It is a holding action, not a diagnostic finding

---

## 10. Phase 5 — Leaving Without Action

### 10.1 Trigger
Player presses Leave in the treatment panel, or the comfort timer expires before the player interacts.

### 10.2 Outcome
- Panel closes (or was never opened if timer expired)
- NPC continues in their current state — no change
- No journal entry
- No morale effect
- Disease continues progressing at normal rate

### 10.3 Design Note
Leaving without acting is a valid and sometimes correct decision. A symptomatic NPC with low urgency may not be worth the time cost of treatment when there is a critical NPC across the district. The system should not penalise the player for leaving — only the passage of time and disease progression does that.

---

## 11. NPC Dialogue During Interaction

### 11.1 Trigger
When the player enters proximity (before interaction), the NPC may speak a context-sensitive line. This is proximity dialogue, not interaction dialogue — it fires on proximity, not on panel open.

### 11.2 Dialogue Conditions
The dialogue system checks the following before selecting a line:
- What district is the NPC in
- What is the current infection level of that district
- What time of day is it
- Has this NPC been treated by the player before
- What is the NPC's current infection stage

### 11.3 Sample Dialogue by Condition

| Condition | Sample Line |
|---|---|
| Healthy NPC, early game | "Haven't seen many come from the docks lately." |
| Healthy NPC, high district infection | "People are getting sick on my street. I've been keeping indoors." |
| Symptomatic NPC | "I don't feel well. I've been feeling this way since the market." |
| Critical NPC | (laboured breathing, minimal speech) "Please." |
| NPC the player has previously treated | "You again. You helped someone on my street last week." |
| NPC refusing examination | "Stay away from me. I've heard what they say about plague doctors." |

### 11.4 Dialogue Display
- Text appears as a speech bubble above the NPC's head or in a small chat-style UI element near the NPC
- Duration: approximately 4–5 seconds before fading
- Does not block or delay the treatment panel if the player interacts while the line is displaying
- Maximum one line per proximity trigger — no dialogue chains on proximity alone

---

## 12. Resistant NPC Behaviour

### 12.1 Definition
Some NPCs have a resistant trait. When the player attempts to open the treatment panel on a resistant NPC, an additional step is required before the panel opens fully.

### 12.2 Resistance Interaction
- On interaction, instead of the full treatment panel, a brief resistance screen appears
- Shows the NPC's name and a short dialogue line — e.g. "I don't need your remedies. Leave me be."
- Player has two options:
  - **Persuade** — costs 5–10 seconds of real time. A short persuasion interaction (keybind hold or repeated press). Success rate is 100% in early game. In low morale conditions success rate drops — some NPCs cannot be persuaded at all.
  - **Leave** — closes the panel. NPC remains untreated.

### 12.3 Failed Persuasion
- If persuasion fails, the treatment panel does not open
- The NPC walks away from the player
- No morale effect
- No journal entry

### 12.4 Design Note
Force-treating an NPC is not available. The game does not allow the player to override NPC refusal through any mechanic. This is intentional — it reflects the historical reality and keeps morale as a meaningful system.

---

## 13. Journal Integration — Full Summary

All journal entries triggered by NPC interaction are automatic and silent. The player is never interrupted by a journal popup during an interaction.

| Trigger | Journal Section | Entry Type |
|---|---|---|
| New symptom observed during examination | Symptom Log | New entry — symptom name, description, co-symptoms noted |
| Correct remedy applied successfully | Treatment Records | Confirmed effective — symptom set + remedy name |
| Wrong remedy applied, no improvement | Treatment Records | Ineffective — symptom set + remedy name |
| Adverse reaction from wrong remedy | Treatment Records | Adverse — symptom set + remedy name, flagged |
| Quarantine applied | District Notes | Location + symptom set + return reminder |
| NPC treated who was previously quarantined | Treatment Records | Links to quarantine entry, resolution noted |

---

## 14. Morale Effects Summary

| Action | Morale Effect | Scope |
|---|---|---|
| Visible successful treatment | Small positive | Immediate district |
| Failed treatment (NPC dies shortly after) | Small negative | Immediate district |
| Quarantine applied | Small negative | Immediate area |
| Resistant NPC refuses treatment and dies publicly | Moderate negative | Immediate district |
| Player walks past critical NPC visibly without treating | No mechanical effect — only narrative weight | N/A |

---

## 15. Edge Cases

**Player runs out of satchel items mid-district**
- Treatment panel opens but satchel panel shows empty or partial inventory
- Player can quarantine or apply broad spectrum if they have those items
- If player has nothing, Leave is the only option
- The panel should not feel punishing in this state — it closes cleanly

**NPC dies while treatment panel is open**
- Panel closes automatically
- Brief line appears: "The patient did not survive."
- No remedy is consumed if the NPC died before Apply was pressed
- If Apply was pressed and the NPC dies during the animation, remedy is consumed but no treatment record is created — a failure entry is logged instead

**Player tries to interact with an NPC they have already treated this in-game day**
- Panel opens normally
- A brief note appears at the top of the panel: "You treated this person earlier today."
- Player can treat again — there is no lock preventing repeat treatment
- Treating a recovering NPC with the correct remedy a second time does nothing additionally — the first treatment is already processing

**Multiple NPCs in close proximity**
- Interaction prompt appears for the nearest NPC only
- Player must move to change which NPC is targeted
- No multi-target treatment mechanic exists — one NPC at a time

**NPC enters stage 5 (dies) without player interaction**
- Body remains at death location
- No treatment panel — a different interaction prompt appears for body disposal
- Body contributes +0.5 pts/hr to the district infection pool until disposed of

**Player is infected and treating an NPC**
- No mechanical difference to the interaction — the player can treat NPCs regardless of their own infection stage
- At severe player infection stage, the examination animation is slightly longer (shaking hands flavour) — cosmetic only, no functional impact

---

## 16. Technical Notes for Implementation

**Proximity detection**
Use a part or zone attached to the NPC with a Touched or a distance check running on a loop (every 0.2 seconds on the server or client). 4–5 studs radius. Tag the zone so only the local player character triggers it.

**Comfort timer**
A simple countdown variable initialised when proximity is entered. Reset if player leaves proximity before interacting. Cancel and reset if interaction is opened.

**Treatment panel UI**
Built as a ScreenGui with a Frame. Symptom icons are ImageLabels. Satchel inventory slots are individual Frames mapped to a satchel data table. Journal button fires a RemoteEvent that opens the journal Frame alongside without closing the treatment Frame.

**Symptom relevance glow**
Each item in the satchel data table has a property array of symptom categories it addresses (e.g. `{fever, respiratory}`). Each NPC condition has a matching symptom category array. On panel open, compare the two arrays — items with any matching category receive the glow highlight. Glow is only applied if the player has at least one confirmed Treatment Record entry for that item — check journal data table before applying.

**NPC state transitions**
NPC infection stage is stored as a value in the NPC model. Treatment outcome (success, failure, adverse) triggers a server-side function that modifies this value on the appropriate timer. District infection pool is a separate ModuleScript value per district — treatment outcomes call a function in that ModuleScript to apply the point change.

**Journal logging**
Journal data is a table stored per player (DataStore for persistence). Each entry is a structured record with fields: section, symptom_set, item_used, outcome, timestamp (in-game day). The logging function is called at the end of each treatment outcome resolution, not during the animation.

**Dialogue system**
Each NPC has a dialogue table with entries indexed by condition keys. On proximity trigger, evaluate condition keys in priority order (stage > morale > prior treatment > district > time) and select the highest-priority matching entry. Display via BillboardGui or a screen-space UI element.

---

## 17. Open Questions

These need answers before this feature can be fully built:

1. **Satchel slot count** — 6 or 8 slots? Affects how many items the player can carry and how often they need to restock.

2. **Comfort timer duration** — 25–30 seconds is the current estimate. Needs playtesting to confirm it feels fair rather than arbitrary.

3. **Glow threshold** — does the relevance glow require one confirmed Treatment Record, or just any previous encounter with that item? The former is stricter and more earned. Current spec assumes the former.

4. **Resistant NPC frequency** — what percentage of NPCs should be resistant? Too many makes the system annoying. Too few makes it forgettable. Suggested starting point: 15–20% of NPCs have the resistant trait, weighted toward high-morale-impact personality types (nobles, church NPCs).

5. **Adverse reaction combinations** — which specific wrong combinations cause adverse reactions rather than just no effect? This requires a full list of all remedy types and their contraindications. Not defined yet.

6. **Treatment panel position** — right half of screen is the current assumption. Needs UI design pass to confirm this does not obscure critical world information (like a second critical NPC the player should be aware of).

7. **Re-treatment cooldown** — should there be any mechanical cooldown on treating the same NPC twice? Current spec says no, but this should be confirmed during playtesting. Exploit potential: player applying the same remedy twice to check for improvement signal.
