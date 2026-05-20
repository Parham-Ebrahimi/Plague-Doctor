# Plague Doctor — Symptom Vocabulary (Draft v1)

This document captures the draft set of symptoms used in the
examination redesign. Each symptom has:

- A key (used internally and in code)
- A display name (shown to the player)
- A short description (the doctor's-notes-style flavour text)
- A body region (where the player discovers it on click; or "passive"
  for free-on-open)
- An associated humour
- A contribution value (signed integer; added to the player's
  running humour estimate when discovered)
- A trigger threshold (the humour value above or below which this
  symptom is present on the patient)

This is a first-pass draft. Numbers will be tuned during playtest;
some symptoms may be cut or added; severity/intensity variations are
deferred (see deferred decisions in current-status.md).

Internally, the humour range is -20 to +20. Thresholds and
contributions are chosen so that finding every symptom for a given
humour yields the patient's true humour value for that humour.

---

## Blood (sanguine — hot and wet)

Excess (positive Blood) symptoms:

- **fever** — *"Patient's skin is hot to the touch, flushed across
  the face and chest."*
  Region: head. Threshold: Blood > +5. Contribution: +8.

- **rapid_pulse** — *"Pulse is fast and strong; can be felt without
  pressing hard."*
  Region: chest. Threshold: Blood > +8. Contribution: +5.

- **florid_complexion** — *"Cheeks and nose are bright red; the
  whole face looks ruddy."*
  Region: passive. Threshold: Blood > +12. Contribution: +4.

- **bloody_cough** — *"Patient coughs and there are streaks of red
  in what comes up."*
  Region: chest. Threshold: Blood > +15. Contribution: +3.

Deficiency (negative Blood) symptoms:

- **pallor_lips** — *"Lips and gums look pale; almost bloodless."*
  Region: head. Threshold: Blood < -5. Contribution: -8.

- **weak_pulse** — *"Pulse is faint and slow; have to press to find
  it."*
  Region: chest. Threshold: Blood < -8. Contribution: -5.

- **cold_extremities** — *"Hands and feet are noticeably cold to
  the touch, even in a warm room."*
  Region: arms (and legs, but primarily attributed to arms for the
  mapping). Threshold: Blood < -12. Contribution: -4.

- **faintness** — *"Patient sways when standing; complains of
  dizziness when they sit up."*
  Region: passive. Threshold: Blood < -15. Contribution: -3.

---

## Phlegm (phlegmatic — cold and wet)

Excess (positive Phlegm) symptoms:

- **productive_cough** — *"Persistent wet cough; patient brings up
  thick white or pale-yellow phlegm."*
  Region: chest. Threshold: Phlegm > +5. Contribution: +8.

- **swollen_legs** — *"Legs are visibly swollen, especially at
  the ankles; skin holds an indent when pressed."*
  Region: legs. Threshold: Phlegm > +8. Contribution: +5.

- **clammy_skin** — *"Skin is cold and damp to the touch, with a
  sticky film of sweat."*
  Region: arms. Threshold: Phlegm > +12. Contribution: +4.

- **heavy_breathing** — *"Breathing is laboured and noisy; chest
  rises slowly."*
  Region: chest. Threshold: Phlegm > +15. Contribution: +3.

Deficiency (negative Phlegm) symptoms:

- **dry_mouth** — *"Lips are cracked; tongue is parched. Patient
  asks for water."*
  Region: head. Threshold: Phlegm < -5. Contribution: -8.

- **dry_cough** — *"Persistent harsh dry cough; nothing comes up."*
  Region: chest. Threshold: Phlegm < -8. Contribution: -5.

- **flaky_skin** — *"Patches of dry, flaking skin, especially on
  the forearms and shins."*
  Region: arms. Threshold: Phlegm < -12. Contribution: -4.

- **sunken_eyes** — *"Eyes look hollow and sunken; skin around them
  is drawn tight."*
  Region: head. Threshold: Phlegm < -15. Contribution: -3.

---

## Yellow Bile (choleric — hot and dry)

Excess (positive Yellow Bile) symptoms:

- **jaundice** — *"Skin and the whites of the eyes have a yellow
  cast."*
  Region: passive. Threshold: Yellow Bile > +5. Contribution: +8.

- **bitter_mouth** — *"Patient complains of a constant bitter
  taste; breath is sharp and sour."*
  Region: head. Threshold: Yellow Bile > +8. Contribution: +5.

- **bilious_vomit** — *"Patient has vomited a thin yellow-green
  fluid earlier today, according to their household."*
  Region: passive. Threshold: Yellow Bile > +12. Contribution: +4.

- **right_side_pain** — *"Patient flinches when the right side
  below the ribs is pressed."*
  Region: chest. Threshold: Yellow Bile > +15. Contribution: +3.

Deficiency (negative Yellow Bile) symptoms:

- **bland_appetite** — *"Patient says food tastes of nothing; no
  hunger, no aversion either."*
  Region: passive. Threshold: Yellow Bile < -5. Contribution: -8.

- **sluggish_digestion** — *"Patient complains of heaviness after
  meals that does not resolve."*
  Region: passive. Threshold: Yellow Bile < -8. Contribution: -5.

- **pale_stool** — *"Household reports stool has been unusually
  pale, almost clay-coloured."*
  Region: passive. Threshold: Yellow Bile < -12. Contribution: -4.

- **listless** — *"Patient is unusually quiet and slow to respond
  to questions, without distress."*
  Region: passive. Threshold: Yellow Bile < -15. Contribution: -3.

---

## Black Bile (melancholic — cold and dry)

Excess (positive Black Bile) symptoms:

- **dark_complexion** — *"Skin has a darkened, sallow cast,
  especially around the eyes."*
  Region: passive. Threshold: Black Bile > +5. Contribution: +8.

- **melancholy** — *"Patient is withdrawn; speaks little, voice
  flat. Avoids eye contact."*
  Region: passive. Threshold: Black Bile > +8. Contribution: +5.

- **dark_stool** — *"Household reports stool has been unusually
  dark, almost black and tarry."*
  Region: passive. Threshold: Black Bile > +12. Contribution: +4.

- **swollen_buboes** — *"Visible swellings under the jaw or in the
  armpit; tender, hard to the touch."*
  Region: head (jaw) or arms (armpits) — for the simple mapping,
  attribute to head. Threshold: Black Bile > +15. Contribution: +3.

Deficiency (negative Black Bile) symptoms:

- **flushed_cheeks** — *"Unusual brightness in the face; almost
  feverish-looking but skin is not hot."*
  Region: passive. Threshold: Black Bile < -5. Contribution: -8.

- **excessive_cheer** — *"Patient seems unusually upbeat and
  talkative given their condition; laughs at small things."*
  Region: passive. Threshold: Black Bile < -8. Contribution: -5.

- **restless_legs** — *"Patient cannot keep still; legs twitch or
  shift constantly while seated."*
  Region: legs. Threshold: Black Bile < -12. Contribution: -4.

- **flighty** — *"Difficulty holding a thought; changes the subject
  mid-sentence."*
  Region: passive. Threshold: Black Bile < -15. Contribution: -3.

---

## Notes for tuning

- Each humour has 8 symptoms (4 excess, 4 deficiency). Within each
  direction, the contributions sum to: 8 + 5 + 4 + 3 = 20. This
  matches the humour range, so finding all four symptoms in a
  direction precisely reconstructs the humour value at +20 or -20.

- For a humour at +12, the symptoms present are the +5, +8, and +12
  threshold symptoms (contributions: 8 + 5 + 4 = 17), so the player
  would observe their graph land at +17. But the true value is +12.
  This is a *bug in the current draft* — the contributions don't
  sum correctly to mid-range values. Tuning needed.

  **The fix:** thresholds and contributions need to be redesigned so
  the sum of contributions for symptoms present at humour value V
  equals V. One simple approach: each humour has N symptoms with
  equal contribution +20/N each, present at thresholds spaced evenly
  through 0 to +20. With N=4, each symptom contributes +5 and is
  present at +5, +10, +15, +20 thresholds. A humour at +12 has 2
  symptoms present (contributions 5+5=10), so the graph reads +10.
  Close but not exact — there's a quantisation error of up to one
  symptom's contribution (±5).

  **Alternative fix:** symptom contributions are *not* fixed integers
  but computed from the humour value at observation time (the
  "intensity" model from current-status.md's deferred decisions).
  This gives precise reconstruction but requires implementing
  per-symptom intensity.

  **Pragmatic choice for first implementation:** use the equal-
  contribution / quantised version. The player's estimate is within
  ±5 of the true value, which gives treatment a built-in tolerance.
  Perfect precision isn't necessary if the treatment system also
  tolerates approximation.

- Body region distribution across humours is uneven in this draft.
  "passive" symptoms cluster heavily in Yellow Bile and Black Bile
  (because those humours' historical associations are
  systemic/behavioural rather than anatomical). This is okay — it
  means examination of those humours leans on observation and
  patient notes rather than touch. But verify it produces playable
  variety; if Black Bile feels too easy because everything is
  passive, redistribute.

- Symptoms with the same region but different humours create
  *informative clicks*: clicking the chest reveals which of
  rapid_pulse, weak_pulse, productive_cough, dry_cough,
  bloody_cough, heavy_breathing, right_side_pain are present, and
  the *combination* tells the player about all four humours at
  once from a single region. That's good — body region clicks are
  multi-humour information sources, not one-region-per-humour.

- The Black Bile symptoms include "melancholy," "excessive cheer,"
  and "flighty" — behavioural / mental symptoms. These work in a
  prototype but will need NPC behaviour or dialogue support to
  display visibly. For now they can be revealed via the symptom
  text alone (the doctor's observation, stated in the patient
  notes or the symptom log). NPC animation for these is deferred.

## Open questions to resolve before implementation

- The threshold/contribution math doesn't reconstruct values
  precisely (see Notes for tuning). Pick one of the three
  approaches above before coding.
- "Swollen buboes" is plague-specific and visually distinctive. It
  may want to be a *special* symptom that overrides the simple
  threshold model — e.g. only certain disease types produce buboes
  even at high Black Bile. Deferred unless multiple disease types
  enter the game.
- Several symptoms reference "the household" or "the wife reports"
  — this implies an information source beyond the patient
  themselves. Decide whether that's flavour text only or implies a
  dialogue/NPC-network mechanic.
- The colour-coding seen in the mockup (red for severe symptoms,
  others muted) needs a rule: severity by symptom (this symptom is
  always serious) or by occurrence (this patient's instance of the
  symptom is severe). Recommend per-symptom for simplicity, with
  the four highest-contribution symptoms per humour being "severe"
  red, and the others muted.