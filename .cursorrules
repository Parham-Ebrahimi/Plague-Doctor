# Plague Doctor — Project Rules

## Current Phase

Phase 1 — NPC examination loop. The camera zoom prototype is complete:
press E on an NPC, custom scriptable camera smoothly glides to a held
position framing the NPC, the player's character fades out, and the exit
glides cleanly back. Working systems that must not be modified unless
explicitly asked: the camera prototype in CameraController.client.lua
(enterExamination, exitExamination, the held-CFrame mechanism, the
stale-tween guards on Completed handlers); the SetExamining BindableEvent
wiring in TreatmentPanelUI; the server-side NPC rotation in
TreatmentHandler.

Currently building: the four-humours examination system. Each NPC has
four humour values (blood, phlegm, yellow bile, black bile) in the
range -20 to +20, generated at NPC registration. The player examines
the NPC by clicking on body regions (head, chest, arms, legs); each
region reveals one humour value in the panel UI. The panel itself
is being redesigned away from the original symptom-tags + inventory
grid layout toward a humours readout.

## Game

Plague Doctor is a Roblox game written in Luau. Genre: medieval strategy
simulation. The player is a plague doctor managing illness across multiple
city districts. Core loop: examine sick villagers, choose remedies from a
satchel, treat them, log findings in a journal. Wider systems: district
infection pools (0-100), rat vectors, contaminated wells, crafting,
quarantine, day/night cycle, plague mutation, morale.

## Architecture

- Server-authoritative. All game state lives on the server.
- Client is for UI, input, camera, sounds, and visual effects only.
- Client and server communicate ONLY through RemoteEvents stored in
  `ReplicatedStorage.Shared.core.RemoteEvents`.
- Never trust client input on the server. Validate distances, ownership,
  and inventory contents before applying any state change.

## Project Layout (Rojo)

`default.project.json` maps:

- `src/server/`  -> `ServerScriptService.Server`
- `src/shared/`  -> `ReplicatedStorage.Shared`
- `src/client/`  -> `StarterPlayer.StarterPlayerScripts.Client`

Subfolders become Roblox `Folder` instances. Use the existing folders:

- `src/server/npc/`       NPC stage data, NPC visuals, rat behaviour and nest systems
- `src/server/plague/`    infection pool, mutation, investigations
- `src/server/player/`    satchel, treatment, player infection, chest/pickup handlers
- `src/server/world/`     day/night, wells, morale, map data
- `src/server/data/`      journal data and the handler that processes journal RemoteEvents, persistence
- `src/server/crafting/`  crafting handler
- `src/shared/core/`      RemoteEvents, GameConstants, InfectionStages
- `src/shared/data/`      data containers shared between server and client (ItemData, SymptomData, DialogueData, NPCData)
- `src/shared/rules/`     TreatmentRules
- `src/client/ui/`        ScreenGui logic (treatment panel, journal, crafting, map, chest)
- `src/client/world/`     proximity detector, dialogue display, camera control
- `src/client/hud/`       persistent HUD, infection VFX, camera controller

## File Extensions (IMPORTANT)

- `*.lua`         -> ModuleScript (only runs when required)
- `*.server.lua`  -> Script (auto-runs on server)
- `*.client.lua`  -> LocalScript (auto-runs on client)

Data containers (NPCData, SatchelData, JournalData, InfectionPool, etc.)
must be ModuleScripts (`*.lua`). Auto-running systems (NPCStageTimer,
RatBehaviour, TreatmentHandler, DayNightCycle, etc.) must be Scripts
(`*.server.lua`).

## Naming Conventions

- PascalCase for files, modules, and exposed functions: `NPCData`, `SetStage`.
- camelCase for local variables: `local stageTimer = 0`.
- SCREAMING_SNAKE for constants in a file: `local MAX_SATCHEL = 8`.
- Module file name matches the table it returns: `NPCData.lua` returns `NPCData`.
- Suffix conventions:
  - `*Data`     -> data store / dictionary module (e.g. `SatchelData`)
  - `*Handler`  -> server RemoteEvent receiver (e.g. `TreatmentHandler`)
  - `*System`   -> world/background system (e.g. `WellSystem`)
  - `*UI`       -> client-side UI controller (e.g. `TreatmentPanelUI`)

## Game Constants

- NPC infection stages: 1 = Healthy, 2 = Exposed, 3 = Symptomatic,
  4 = Critical, 5 = Dead. Defined in `shared/core/InfectionStages.lua`.
- District infection pool: number 0-100, one per district, stored in
  `server/plague/InfectionPool.lua`.
- Player satchel: up to 8 slots, server-side per player, stored in
  `server/player/SatchelData.lua`.
- All tunable numbers (durations, ranges, rates) live in
  `shared/core/GameConstants.lua`. Do not hardcode numbers in other files.

## CollectionService Tags

NPCs and world objects are connected to scripts by tags, not by parenting
scripts inside models. Use:

- `"NPC"`           villagers (also has `NPCType` and `District` attributes)
- `"Rat"`           rat models
- `"RatNest"`       rat nest props (has `District` attribute)
- `"Well"`          well models (has `District` and `Contaminated` attributes)
- `"CraftingBench"` crafting benches (has `BenchType` attribute)

Do NOT place Scripts inside Workspace models. Server controllers find
tagged instances via `CollectionService:GetTagged(tag)` and
`GetInstanceAddedSignal(tag)`.

## Lua / Luau Rules

- Use `task.wait`, `task.spawn`, `task.delay`. Never use `wait()`,
  `spawn()`, or `delay()` (deprecated).
- Use `Instance.new("Class")` then set properties. Do not use the
  deprecated parent-as-second-argument form.
- Prefer `for _, v in collection do` (generalized iteration) over `ipairs`
  / `pairs` unless explicitly needed.
- Use `:FindFirstChild` for optional children, `:WaitForChild` only when
  the instance is expected to replicate.
- Prefer `Vector3.new` math over deprecated CFrame conversions where
  obvious.
- Use Luau type annotations on public module functions when it improves
  clarity.
- Comments should explain non-obvious intent or invariants. Do not narrate
  what the code already says.

## TweenService Patterns

- TweenService writes the target property only while the tween is
  playing. It does NOT hold the value after completion. If a property
  needs to stay at the tween's target after the tween finishes, either
  add a Completed handler that captures the final value and writes it
  every frame (via RenderStep or similar), or arrange for another writer
  to take over before the tween stops writing.

- When transitioning ownership of a property between writers (e.g.,
  tween A stops writing, tween B starts writing, or a held-state writer
  hands off to a tween), there must be NO frame where neither writer is
  active. An unowned property in Roblox will be repositioned by the
  engine, producing a snap. Establish the new writer before stopping
  the old one, or maintain a continuous fallback writer that bridges
  handoffs.

- Any `.Completed:Connect` on a tween must guard against Cancel-triggered
  re-fires. Tween:Cancel() also fires Completed. Capture the active
  tween at connection time and bail if the module-level tween reference
  has been replaced:

    local thisTween = activeTween
    activeTween.Completed:Connect(function()
        if activeTween ~= thisTween then
            return
        end
        -- safe to act
    end)
    
## Module Pattern

Every ModuleScript follows this shape:

```lua
local ModuleName = {}

local privateState = {}

function ModuleName.PublicFunction(arg)
    -- ...
end

return ModuleName
```

Do not use globals. Always `require()` modules at the top of the file.

## RemoteEvent Pattern

All RemoteEvents are created once in `shared/core/RemoteEvents.lua` and
required by both sides:

```lua
local RE = require(ReplicatedStorage.Shared.core.RemoteEvents)
RE.AttemptTreatment:FireServer(npc, item)
```

Server handlers always validate the player and inputs before mutating
state.

## Working With Existing Code

- Before making changes, identify the specific files that need to be
  modified and list them. Wait for confirmation before editing if the
  list seems large or unexpected.
- Keep changes scoped to the requested task. Do not refactor unrelated
  code, even if it looks improvable.
- Do not add features that were not requested.
- Do not delete code that appears unused without confirming it is unused.
- If the requested change conflicts with existing patterns in the
  codebase, surface the conflict and ask before resolving it.
- If a request is ambiguous, ask a clarifying question rather than
  guessing.
- After making changes, summarize what was changed in 2-3 sentences and
  identify any edge cases or follow-ups the user should be aware of.

## Git Workflow

- The user uses git for version control. The repo is at
  https://github.com/Parham-Ebrahimi/Plague-Doctor.
- The user prefers to make their own commits rather than have them
  generated automatically.
- When changes are made, briefly suggest what the next commit message
  could be, but do not run git commands unless explicitly asked.
- Never run `git reset --hard`, `git push --force`, `git rebase`, or
  `git clean` without explicit confirmation, even if asked.

## When Asked to Write Code

- Read referenced files first.
- Keep changes scoped to the requested module/function.
- Match the existing style and folder layout.
- Prefer extending existing files over creating new ones.
- Never add deprecated APIs, even in placeholder code.
- After writing code, briefly explain what was added and how it connects
  to other modules.