# Stud Rush - Kit framework migration contract

Migration of the Stud Rush / CoinRush prototype (single-script place) into this Kit
framework repo. Studio assets live in **Place1** (`ReplicatedStorage.Assets`), code
lives here and syncs via Rojo (`main.project.json`).

This document is the **contract between implementation agents**. Do not change a
name in here without updating every consumer listed.

## 1. Framework rules (Kit mechanics + Enlistment conventions)

- Modules resolve by **globally-unique file name** via `shared("Name")`. Always
  annotate: `local X = shared("X") ---@module X`.
- **Jobs** are ModuleScripts under a `Jobs/` folder (`Client/Jobs/**`,
  `Server/Jobs/**`, `Shared/Jobs/**`). Lifecycle: optional `Strict()` (no yield),
  `Init()` (serial), `Run()` (spawned). Optional `Priority` number (higher starts
  first within its lifecycle bucket). No manual registration - file placement is
  registration.
- **Classes** (non-job) go under `Classes/` or `Modules/`. Class style: plain
  metatable class like `SpringSet`/`ButtonModel` (NO BaseObject here - it doesn't
  exist in this repo). Every class owns a `Maid`; `Destroy()` cleans it.
- **Signals, never BindableEvents**: `shared("Signal")`. In classes:
  `self.Thing = self.Maid:Add(Signal.new()) :: Signal.Signal<...>`. In jobs:
  module-level `Job.ThingChanged = Signal.new()`.
- **Networking**: `local GetRemote = shared("GetRemote")`, then
  `GetRemote("Name")` → object with `FireServer/FireClient/FireAllClients/
  OnClientEvent(cb)/OnServerEvent(cb)`. RemoteEvents only - request/response is
  two events. No RemoteFunctions.
- **Player data**: ProfileService + Replica already wired
  (`PlayerDataServer`, `DataClient`, `ProfileTemplate`). Server mutates via
  `PlayerDataServer:WaitForReplica(player):SetValue(path, value)` (path = array of
  strings). Client reads via `DataClient:WaitForReplica()`; subscribe with
  `replica:ListenToChange({"Path"}, cb)` (Madwork Replica v1 API - check
  `Client/Vendor/Data/ReplicaController.luau` for exact listener names before use).
- **File style** (match Enlistment): header comment
  `--[[\n\tAuthor(s): Josh, Claude\n\tModule: <Name>.luau\n]]`, then section comments in
  order: `-- Services`, `-- Modules`, `-- Types`, `-- Constants`, `-- Variables`,
  `-- Private functions`, `-- Public functions`, `-- Start` (jobs) /
  `-- Constructor` (classes). Constants UPPER_SNAKE_CASE, locals camelCase,
  privates `self._camelCase`, publics/signals PascalCase, no single-letter
  variables, backtick string interpolation, `warn("[ModuleName] ...")` prefixes,
  tabs for indentation, `export type X = ...` from every class.
- **Stories**: every pane gets a sibling `<Name>.story.luau` (pattern from
  `TestPane.story.luau` - first line `require(game.ReplicatedStorage.Kit)`).
  Files with `.` in the name are skipped/destroyed by the module indexer, so
  stories never collide with module names.

## 2. Data contract

`Shared/Modules/Data/ProfileTemplate.luau` (replaces the placeholder `Coins` field):

```lua
local ProfileTemplate = {
	Money = 0,
	Rebirths = 0,
	Upgrades = {
		Speed = 0,
		Value = 0,
		Capacity = 0,
	},
	Carried = 0,        -- backpack units currently held
	CarriedValue = 0,   -- accumulated base $ of held studs
	CarriedItems = {},  -- array of { Type: string, Mutation: string? }
}
```

- All fields replicate to the owning client via the PlayerData replica.
- `Carried`/`CarriedValue` are always kept consistent with `CarriedItems` by
  `BackpackServer` (single writer for all three).
- Money/Rebirths written only by `EconomyServer` helpers (sell, buy, rebirth,
  dev products).
- **leaderstats**: `Money`, `Rebirths` IntValues, mirrored by `LeaderstatsServer`.
- **Player attributes** (server-written, client-read): `HasDoubleCash` only.
  Everything else that used to be an attribute now comes from the replica.

## 3. Remotes (GetRemote names + payloads)

| Name | Direction | Payload |
|---|---|---|
| `UpgradesServer:Buy` | C→S | `(upgradeName: string)` |
| `UpgradesServer:BuyResult` | S→C | `(result: { ok: boolean, msg: string, upgradeName: string? })` |
| `RebirthServer:Rebirth` | C→S | `()` |
| `RebirthServer:RebirthResult` | S→C | `(result: { ok: boolean, msg: string })` |
| `BackpackServer:PickupBlocked` | S→C | `({ needed: number, free: number })` (throttled 1/s per player) |
| `SellServer:Sold` | S→C | `({ total: number, units: number, baseValue: number, multiplier: number })` |

Server validates everything; client never mutates state directly.

## 4. Tags, attributes, asset names

**Tags**
- `"Coin"` - any tagged BasePart in Workspace gets bob/spin/labels client-side.
  Server adds the tag to dropped studs only AFTER the landing tween.
- `"Tool"` - a Roblox `Tool` instance owned by a player (Backpack or Character).
  The template in `Assets.Tools` carries the tag and a `ToolName` attribute;
  clones inherit both. The server binder resolves `{ToolName}ToolObjectServer`
  via `shared()` (fallback `ToolBaseObjectServer`) and MUST ignore tagged
  instances that are not descendants of `Workspace` or `Players` (i.e. skip the
  template itself).

**Stud attributes** (unchanged contract from the GDD): `StudType`, `Worth`,
`Value`, `Mutation` (nil if none), `CollectedBy` (userId set right before
Destroy). Zone parts: `StudType` (force type), `Weight` (spawn bias). Barriers:
`RequiredSpeed`.

**Assets registry** (flat names must be globally unique; folders organizational):

```
ReplicatedStorage.Assets/
  Gui/
    Hud/         TopHudPaneTemplate, HudSideButtonsPaneTemplate,
                 UpgradesPaneTemplate, ShopPaneTemplate, ToastPaneTemplate
    Components/  StatPillPaneTemplate, SideButtonPaneTemplate,
                 UpgradeRowPaneTemplate, BuyButtonPaneTemplate,
                 CloseButtonPaneTemplate, ShopItemButtonPaneTemplate
  Studs/         Stud, DoubleStud, QuadStud, HexStud, GigaStud, OmegaStud
  Tools/         Bat (Tool; tagged "Tool", attribute ToolName = "Bat")
```

Panes clone templates with `GuiPane.new({ Template = "<flat name>", Instances = {...} })`
(this repo's GuiPane uses `Template`, NOT Enlistment's `AssetName`; it clones via
`Assets:Clone(name)` - flat name, no dots).

**Workspace (Place1)**: `Studs` folder (live studs), `SpawnZones`, `TierFloors`,
`SellPad`, `SpawnLocation`. Built in Studio, not by code. Code must tolerate
missing `SpawnZones` (fallback open-range spawn per GameConfig.MapRange).

## 5. GameConfig (Shared/Modules/Data/GameConfig.luau)

Direct port of the old `GameConfig` ModuleScript: CoinCount(80), CoinRespawnTime(3),
CoinBaseValue, MapRange, `Upgrades` (Speed/Value/Capacity with baseCost/costMult/
maxLevel/walkSpeedPerLevel/capacityPerLevel), BaseCapacity(10), `StudTypes` (6 -
units/baseValue/minDistance/rarity), `RarityColors`, `Mutations` (Gold 7%/x5,
Frozen 3%/x8, Rainbow 1%/x20 with color/material/highlight), RebirthBaseCost(10000),
RebirthCostMult(2), DoubleCashGamePassId(0), `CashProducts` (3, ids 0), and
functions: `getStudType(name)`, `getStudTypeForDistance(distance, rand)`,
`rollMutation(rand)`, `getUpgradeCost(name, level)`, `getRebirthCost(rebirths)`,
`getCapacity(capacityLevel)`, `getSellMultiplier(valueLevel, rebirths, hasDoubleCash)`.
Keep values/formulas EXACTLY as the old place (parity is the acceptance bar).

## 6. File ownership (one owner per file - agents must not cross)

**Agent S - Shared + Server**
```
Shared/Modules/Data/GameConfig.luau          (new)
Shared/Modules/Data/ProfileTemplate.luau     (rewrite fields)
Shared/Modules/TagObjects.luau               (new binder, Enlistment-style API)
Server/Jobs/Game/LeaderstatsServer.luau
Server/Jobs/Game/BackpackServer.luau         (carry/capacity, back stack, drops, death)
Server/Jobs/Game/StudsServer.luau            (zones, spawning, respawn, pickup wiring)
Server/Jobs/Game/SellServer.luau
Server/Jobs/Game/UpgradesServer.luau         (buy + walk speed apply)
Server/Jobs/Game/RebirthServer.luau
Server/Jobs/Game/TransactionsServer.luau     (ProcessReceipt, gamepass)
Server/Jobs/Game/ToolsServer.luau            (binder start + grant Bat on spawn)
Server/Classes/StudObject.luau               (one live stud: attrs, Touched, lock)
Server/Classes/Tools/ToolBaseObjectServer.luau
Server/Classes/Tools/ToolObjects/BatToolObjectServer.luau
```

**Agent G - Client GUI**
```
Client/Modules/Gui/GuiStyles.luau            (new; FormatUtil already requires it)
Client/Jobs/Gui/ScreenGuisClient.luau        (port of Enlistment API)
Client/Jobs/Gui/UIStateManager.luau          (lightweight: states + components)
Client/Jobs/Gui/TopHudGuiClient.luau
Client/Jobs/Gui/HudButtonsGuiClient.luau
Client/Jobs/Gui/UpgradesGuiClient.luau
Client/Jobs/Gui/ShopGuiClient.luau
Client/Jobs/Gui/NotificationsGuiClient.luau  (toasts, +$ float, pickup blocked)
Client/Classes/Gui/Hud/{TopHudPane,HudSideButtonsPane,UpgradesPane,ShopPane,ToastPane}/init.luau (+ .story.luau each)
Client/Classes/Gui/Components/{StatPillPane,SideButtonPane,UpgradeRowPane,BuyButtonPane,CloseButtonPane,ShopItemButtonPane}/init.luau (+ .story.luau each)
Client/Classes/Gui/Hud/Hud.storybook.luau
Client/Classes/Gui/Components/Components.storybook.luau
docs/StudRush-Gui-Templates.md               (EXACT template hierarchy spec - see §8)
```

**Agent W - Client world**
```
Client/Jobs/World/StudAnimatorClient.luau    (bob/spin/labels/slot lines/fly-to-collector/rainbow)
Client/Jobs/World/BarriersClient.luau        (RequiredSpeed ghosting)
Client/Jobs/World/SellPadClient.luau         (pulse)
```

Shared read-only for everyone: existing Kit/vendor modules, `DataClient`,
`PlayerDataServer`, `GetRemote`, `Assets`, `FormatUtil`, GuiPane core.

## 7. UI states

`UIStateManager` states: `Gameplay` (default), `Upgrades`, `Shop`. Opening one
panel closes the other (states are exclusive). Components registered:
`HUD_TopHud`, `HUD_SideButtons`, `Panel_Upgrades`, `Panel_Shop`. Side buttons:
Upgrades, Shop, Rebirth (rebirth fires remote directly, shows toast on result,
displays live cost from GameConfig + replica Rebirths).

Simulator look & feel carries over from the prototype: chunky rounded panels,
FredokaOne/GothamBlack, spring/AccelTween juice via each pane's `_springSet`
(press/hover scale, panel pop via Alpha spring in `_updateGui`).

## 8. GUI template spec (Agent G deliverable)

Agent G writes `docs/StudRush-Gui-Templates.md` describing EVERY template in §4
as an exact instance tree: name, ClassName, key properties (size/position/anchor/
colors/fonts/text/corner radii/strokes/gradients), matching each pane's
`Instances` map (instance names unique within a template). The Studio build in
Place1 is generated from that doc - if it's ambiguous, the build will be wrong.

## 9. Parity checklist (acceptance)

Collect → capacity block (throttled toast) → back-stack plates match stud
size/color → sell (exact multiplier math) → upgrades (cost/level/max, walk speed
applies) → rebirth (reset + toast + cost curve) → bat hit / death scatters exact
carried items (uncollectable until landed, 60s despawn) → fly-to-collector ghost
→ barriers ghost at required speed → rainbow hue cycle + frozen slow bob →
labels with rarity + slot lines → dev product cash grants + 2x pass →
persistence via ProfileService (automatic).
