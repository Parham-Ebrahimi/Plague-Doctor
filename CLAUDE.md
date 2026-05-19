# Plague Doctor — Project Rules

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

- `src/server/npc/`       NPC stage data, visuals, rats
- `src/server/plague/`    infection pool, mutation, investigations
- `src/server/player/`    satchel, treatment, player infection
- `src/server/world/`     day/night, wells, morale, map data
- `src/server/data/`      journal, persistence
- `src/server/crafting/`  crafting handler
- `src/shared/core/`      RemoteEvents, GameConstants, InfectionStages
- `src/shared/data/`      SymptomData, ItemData, DialogueData
- `src/shared/rules/`     TreatmentRules
- `src/client/ui/`        ScreenGui logic (treatment panel, journal, etc.)
- `src/client/world/`     proximity detector, dialogue display
- `src/client/hud/`       persistent HUD, infection VFX

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

## Build Order

Follow the phased build plan in `docs/`. Phase 1 = NPC interaction loop:
NPCData -> NPCStageTimer -> NPCVisuals -> ProximityDetector ->
TreatmentPanelUI -> SatchelData -> TreatmentHandler -> JournalData. Do
not start later phases (district pool, crafting, map) until Phase 1 is
fully working.

## When Asked to Write Code

- Read referenced files first.
- Keep changes scoped to the requested module/function.
- Match the existing style and folder layout.
- Prefer extending existing files over creating new ones.
- Never add deprecated APIs, even in placeholder code.
- After writing code, briefly explain what was added and how it connects
  to other modules.
