# Plague Doctor — Symptom Vocabulary (Draft v3)

This document captures the symptom set used in the examination
redesign. Each symptom has:

- A key (used internally and in code)
- A display name (shown to the player)
- A short description (the doctor's-notes-style flavour text)
- A body region (where the player discovers it on click; or
  "passive" for free-on-open)
- An associated humour and direction (excess or deficiency)
- A contribution value (signed integer; the player reads this
  from the journal's symptom-reference page and uses it to
  calculate humour positions on the graph)
- A trigger threshold (the humour value above or below which
  this symptom is present on the patient)
- A discovery type: "click" for simple click discovery, or
  "skill_check" for a brief mini-interaction

The player-facing model is manual: the player observes symptoms
through clicks and skill checks, looks up each symptom's
contribution value in the journal, calculates the humour sums
mentally (or on paper), and drags the humour medallions on the
bipolar graph to the correct integer positions. The graph does
not auto-update. See current-status.md for the locked design
commitments.

This is a v3 draft. Numbers, descriptions, region placements,
and skill-check designs will all be tuned during playtest.
Tonal direction is medieval-medical-but-not-gory: visible skin
signs, audible cough and pulse, observable behaviour, tactile
temperature, respectful palpation. No discharge, no genital
examination, no content unsuitable for Roblox players.

## How the math works

The internal humour range is -20 to +20. Each humour has 4
symptoms total: 2 for excess (positive direction) and 2 for
deficiency (negative direction). Symptoms are arranged so the
sum of contributions for symptoms present at a given humour
value approximates that value within a bounded quantisation
error.

Threshold/contribution pairs in each direction:

- 1st symptom: threshold ±5, contribution ±8
- 2nd symptom: threshold ±15, contribution ±12

For a humour at +12, the player would find both symptoms? No —
only the first symptom (threshold +5 crossed, but threshold +15
not crossed). The player calculates +8 and places the medallion
at +8. The true value is +12. The player's estimate is short by
4.

For a humour at +18, both symptoms are present. The player
calculates +8 + +12 = +20 and places the medallion at +20. The
true value is +18. The player's estimate is over by 2.

The player's estimate is at most ±7 from the true value after
full examination. This bounded error is what the treatment
system's tolerance accommodates (see current-status.md).

The player does this math themselves using the journal's
symptom-reference page (page 2 of the journal). The graph does
not show the calculation; the player commits their answer by
dragging the medallion to the integer position they computed.

## Day-one scope note

For the day-one horizontal slice, simplifications are made to
keep scope manageable:

- All symptoms are discovered through simple clicks. The three
  skill-check symptoms (bounding_pulse, tender_side,
  swollen_bubo) are still marked with discovery_type =
  "skill_check" in the data, but the day-one implementation
  treats them as simple clicks. Skill-check minigames are
  built in a later iteration.
- No camera zoom on body region click. The player clicks a
  body region; the symptoms in that region appear in the
  observed-symptoms list as text. Visual indicators on body
  parts are deferred.
- No art for symptom visuals on the NPC. Symptoms are
  text-only in the observed-symptoms list.

The full design (skill-check minigames, body-region zoom, visual
indicators) is the eventual target, layered in after the
horizontal slice is playable end-to-end.

---

## Blood (sanguine — hot and wet)

### Excess (positive Blood)

- **fever** — *"Patient's forehead and cheeks feel hot. The face
  looks flushed and ruddy."*
  Region: head. Discovery: skill_check (day-one: click).
  Threshold: Blood ≥ +5. Contribution: +8.

- **bounding_pulse** — *"Pulse is fast and strong, easy to find
  and slightly forceful against the fingertips."*
  Region: chest (taken at the wrist or neck during chest
  examination). Discovery: skill_check (day-one: click).
  Threshold: Blood ≥ +15. Contribution: +12.

### Deficiency (negative Blood)

- **pallor** — *"Lips, gums, and the insides of the eyelids look
  pale and bloodless."*
  Region: head. Discovery: click. Threshold: Blood ≤ -5.
  Contribution: -8.

- **cold_extremities** — *"The hands and fingertips are
  noticeably cold even in a warm room."*
  Region: arms. Discovery: click. Threshold: Blood ≤ -15.
  Contribution: -12.

---

## Phlegm (phlegmatic — cold and wet)

### Excess (positive Phlegm)

- **wet_cough** — *"Patient coughs periodically; the cough sounds
  wet and productive."*
  Region: chest. Discovery: click. Threshold: Phlegm ≥ +5.
  Contribution: +8.

- **swollen_ankles** — *"The ankles are visibly swollen. Pressing
  the skin briefly leaves an indent."*
  Region: legs. Discovery: click. Threshold: Phlegm ≥ +15.
  Contribution: +12.

### Deficiency (negative Phlegm)

- **dry_lips** — *"The lips are cracked and dry. The patient
  asks for water."*
  Region: head. Discovery: click. Threshold: Phlegm ≤ -5.
  Contribution: -8.

- **flaky_skin** — *"Patches of dry, flaking skin on the
  forearms."*
  Region: arms. Discovery: click. Threshold: Phlegm ≤ -15.
  Contribution: -12.

---

## Yellow Bile (choleric — hot and dry)

### Excess (positive Yellow Bile)

- **jaundice** — *"The whites of the eyes have a yellow cast."*
  Region: head. Discovery: click. Threshold: Yellow Bile ≥ +5.
  Contribution: +8.

- **tender_side** — *"The area below the ribs on the right side
  is tender to gentle pressure."*
  Region: chest. Discovery: skill_check (day-one: click).
  Threshold: Yellow Bile ≥ +15. Contribution: +12.

### Deficiency (negative Yellow Bile)

- **sallow_skin** — *"The patient's skin has a dull, drained
  tone — not pale, but lifeless."*
  Region: head. Discovery: click. Threshold: Yellow Bile ≤ -5.
  Contribution: -8.

- **weak_grip** — *"When asked to grip the doctor's hand, the
  patient's grip is noticeably weak."*
  Region: arms. Discovery: click. Threshold: Yellow Bile ≤ -15.
  Contribution: -12.

---

## Black Bile (melancholic — cold and dry)

### Excess (positive Black Bile)

- **dark_undereyes** — *"The skin beneath the patient's eyes is
  darkened and hollow."*
  Region: head. Discovery: click. Threshold: Black Bile ≥ +5.
  Contribution: +8.

- **swollen_bubo** — *"A hard, tender swelling has formed beneath
  the jaw, characteristic of plague."*
  Region: head (jaw/neck). Discovery: skill_check (day-one:
  click). Threshold: Black Bile ≥ +15. Contribution: +12.

### Deficiency (negative Black Bile)

- **restless_movement** — *"The patient cannot sit still. Their
  legs and feet shift constantly."*
  Region: legs. Discovery: click. Threshold: Black Bile ≤ -5.
  Contribution: -8.

- **scattered_attention** — *"The patient cannot hold a thought.
  Their eyes dart; they change topic mid-sentence."*
  Region: passive (visible immediately on examination start).
  Discovery: click. Threshold: Black Bile ≤ -15. Contribution:
  -12.

---

## Body region distribution

- **head**: 7 symptoms (fever, pallor, dry_lips, jaundice,
  sallow_skin, dark_undereyes, swollen_bubo)
- **chest**: 3 symptoms (bounding_pulse, wet_cough, tender_side)
- **arms**: 3 symptoms (cold_extremities, flaky_skin, weak_grip)
- **legs**: 2 symptoms (swollen_ankles, restless_movement)
- **passive**: 1 symptom (scattered_attention)

Head is the most information-dense region because the face is
where most diagnostic signs traditionally read in medieval
medicine. This is a deliberate accept-the-asymmetry choice
rather than a balanced distribution. If playtest shows head
clicks feel overloaded relative to other regions, some symptoms
(jaundice moved to neck/chest; sallow_skin moved to forearms)
can be redistributed without changing the core design.

---

## Tonal calibration

Descriptions are written in clinical-medieval voice but avoid
the more visceral edges of period medicine. Symptoms involving
discharge (urine, stool, vomit, blood expelled from the body),
genital examination, or anything sexual are excluded. Bodily
content stays within: skin (visible appearance, temperature,
texture), audible signs (cough, breathing, pulse), behavioural
observations (movement, attention, speech), and respectful
palpation (pressing visible areas through clothing or on bare
arms).

This keeps the tone medical-serious without being gross or
inappropriate for Roblox's player base.

---

## Patient notes as examination hints

The patient examination panel includes a notes section in the
journal. These notes are narratively framed as the doctor's case
notes and information reported by the patient and their
household.

Notes are **always true** in the current design — they reliably
indicate where symptoms can be found. Examples:
- "Complains of fever, chest pain, chills, and swelling on the
  arms" → fever (head), some chest symptom, cold_extremities
  (arms), and one of swollen_ankles or flaky_skin (arms).
- "Sleeps poorly. Wife reports worsening cough since dawn." →
  wet_cough (chest), possibly some Phlegm or Blood imbalance.

The notes don't reveal *which specific* symptom is present, only
its general region or category. The player still has to examine
to confirm. But the notes reduce time wasted on body regions the
patient doesn't present any symptoms in.

This is the design for first implementation. Unreliable notes
(patient under-reports or self-reports incorrectly) are deferred
as a possible difficulty layer.

---

## Player flow (full design — implemented incrementally)

When the player presses E to examine an NPC:

1. The examination camera glides to the NPC (already
   implemented). The journal panel opens.
2. The journal is on the NPC's page: name, occupation, age,
   notes, empty bipolar humour graph (all four medallions at 0).
3. Passive symptoms (scattered_attention) appear in the
   observed-symptoms list immediately if present.
4. The player clicks a body region. In the full design, the
   camera zooms further into that region and visual indicators
   on the body part show present symptoms. In the day-one
   slice, the player just clicks the region and text symptoms
   appear in the observed-symptoms list.
5. The player flips to the symptom-reference page (page 2 of
   the journal) to look up the humour and contribution value
   for each observed symptom.
6. The player flips back to the patient page and drags the
   appropriate humour medallion to the integer position
   matching the sum of contributions for that humour. The
   medallion snaps to integer positions when the player
   releases left-click.
7. The player can repeat: examine other regions, look up
   contributions, drag medallions.
8. When the player exits examination, the journal retains the
   patient's page and current graph state.
9. If the player returns to the patient later (after brewing a
   potion, etc.), the journal page shows the graph as the
   player last placed it.

The full design adds skill-check minigames at step 4 for three
specific symptoms. The day-one slice omits this.

---

## Open questions to resolve before full implementation

These are not blockers for the day-one slice but should be
resolved before the deeper version ships:

- **Skill-check minigame style.** Recommend slider-based
  pressure control for thematic fit and implementation
  simplicity, but Stardew-fishing-bar and osu-circle-tap are
  also candidates.
- **Skill-check failure handling.** Recommend: one retry
  allowed, then symptom locked for the current examination.
  Reset on Leave.
- **Visual indicator art style.** Photorealistic, stylised, or
  abstract. Reference mockup leans semi-realistic. Decide before
  building the zoom interaction's visual layer.
- **Whether the patient notes should be hand-authored per-NPC
  or generated from the symptom set.** First implementation:
  hand-authored hardcoded notes per-NPC type, with generation
  as a later enhancement.
- **Camera zoom transition timing and easing.** Should match
  the existing examination camera's TweenService style (Quad-
  Out 0.6s) or use different parameters. Test in prototype.
- **Re-examination of a region after a skill-check failure.**
  Recommend: persistent within the current examination, reset
  on Leave.
- **Notepad / scratchpad for player math.** Whether to add a
  small text-input notepad area in the journal so the player
  can write down values as they look them up. Deferred until
  playtest shows whether players need it.