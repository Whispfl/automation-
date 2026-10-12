# Native action contracts — navigation

Research-only checkpoint 2026-10-11. Command descriptions below are SOURCE_CONFIRMED client call-site contracts, not instructions executed during this audit and not proof of acceptance by a live server. Generic Remote presence supplies transport only. Exact saved source references and decompiler limits are in NAVIGATION_SOURCE_LEDGER.md.

## Contract states and result standards

- Island discovery changes received `LocalData.AreasUnlocked[island]`.
- Paid world unlock changes received `LocalData.WorldsUnlocked[world]`.
- Travel changes physical character location; it normally should not change unlock flags.
- Within-island navigation changes physical location without changing world/account access.
- Interaction approach is verified by the native volume/proximity and correct active facility; it does not itself prove the purchase/claim.
- Arrival, ownership, eligibility, balance, requested action, received acknowledgement and durable persistence need separate records. A bool-returning wrapper, animation, cleared gate or closed panel cannot replace them.

No ACCOUNT_OBSERVED profile was read. Prior OWNER_LIVE_VERIFIED behaviors from docs/PHASE3.md remain historical owner evidence; no new live pass was produced. Server-only handlers are UNAVAILABLE. Owner reports are not generalized to untested worlds/features.

## A. Discovering an island

| Field | Evidence |
|---|---|
| Native interface | Saved Island.UnlockHitbox touch-enabled Part for all five Overworld and four Minigame islands. No readable discovery handler or native discovery remote identified; script_grep UnlockHitbox returned no match. |
| Required account | Client portal unlock presentation reads AreasUnlocked[name] independently of WorldsUnlocked. Exact server contact eligibility/order remains UNAVAILABLE. |
| Physical requirement | Ordinary reach/contact mechanism suggested by UnlockHitbox geometry; center Y is documented separately from definition/folder height. No exact bubble capacity/amount minimum established. |
| UI/state | Normal portal presentation checks InRace. This is not evidence that all discovery-server rules equal travel guards. |
| Arguments/pattern | No SOURCE_CONFIRMED discovery command. Existing owner-reported optional runtime contact begin/end is documented in prior Phase 3; runtime-specific facility must not be called in Studio or treated as a native game API. |
| Pacing | No native server discovery cooldown exposed. Existing OC contact settings/attempt limits are preservation behavior, not inferred native rules. |
| Success | Correct received AreasUnlocked entry absent -> present. Track full account refresh; durable save requires owner rejoin. |
| Conflicts | Physical travel/respawn/contact can conflict with location leases, hatch or race. Future executor must reuse central scheduler. |
| Cancel/failure | No invented native CancelDiscovery. Stop new attempts; previous optional contact cleanup remains existing OC behavior. Missing/changed hitbox, capability or no correct flag is unavailable/unconfirmed. |
| Unknown | Server touch validation, distance, order, world access, saving and replication delay. Five Overworld acknowledgements do not establish four Minigame islands. |

## B. Traveling to an unlocked island via portal

| Field | Evidence |
|---|---|
| Native interface | ClientScript.hookPortal:1423-1587; Remote:FireServer('Teleport',destinationPath). |
| Required account | ClientScript:1603-1636 maps AreasUnlocked[island] presence into Model.Unlocked. Event portal maps Zen. This does not prove WorldMap's corrupted helper or server acceptance. |
| Physical requirement | Normal portal Display.Touched must originate from local character; no universal radius shown in this handler. Island path can remain server-valid when local portal presentation is chunked out; availability and arrival observation still required. |
| UI/state | Native checks nonlocal player, u34 debounce, RaceUtil.HasPlayer, then portal.Unlocked. Locked portals produce 'Discover … to unlock this portal' prompt. |
| Arguments | WorldUtil.toIslandLocation(world,island): 'Workspace.Worlds.<world>.Islands.<island>.Island.Portal.Spawn'. Client uses actual names. No guessed spelling or numeric index. |
| Pacing | Client waits0.5s after request then task.delay1s resets per-portal debounce. No server cooldown derived. |
| Success | Actual root arrival at expected local spawn or supported island geometry; same account discovery still present. Client 0.5s wait is not acknowledgement. |
| Conflicts | Hatching/foreground movement, race, transition, manual travel or respawn. Existing OC adds stronger guards; preserve them. |
| Cancel/failure | Native source has no server recall. Transition/portal callback already scheduled can fire later. Future central cancellation needs pre-dispatch check and late-result attribution; missing geometry stays unknown. |
| Unknown | Destination whitelist, unlock enforcement, anti-spam server policy, accepted arrival tolerance, stream latency, durable access. |

## C. Returning to a world surface

| Field | Evidence |
|---|---|
| Native interface | ClientScript:1574-1587 binds each island's Portal when world PortalSpawn exists; marks return portal unlocked. |
| Required account | No separate account cost/unlock check in this return binding; server requirements UNAVAILABLE. Do not infer arbitrary locked world access. |
| Physical requirement | Native return Portal.Display contact. |
| UI/state | Same hookPortal local-character/race/debounce behavior. |
| Arguments | Actual world PortalSpawn.GetFullName; reference Overworld destination is 'Workspace.Worlds.The Overworld.PortalSpawn'. |
| Pacing | Same portal debounce. |
| Success | Actual arrival near the correct surface return destination, distinct from world Spawn/FastTravel.Spawn. |
| Conflicts | Leaving an egg, selling return ledger, foreground location objective. |
| Cancel/failure | Once issued, server request cannot be recalled. No invented coordinate fallback. |
| Unknown | Server destination acceptance and exact surface arrival semantics. |

## D. World-map fast travel

| Field | Evidence |
|---|---|
| Native interface | WorldMap.TeleportTo:118-194, selection schema {Type,Name,World}; UI island buttons :591-603; teleport button :752-764. |
| Required account | Reads LocalData and calls isUnlocked; saved helper :87-117 corrupts ordinary area/world scope. Portal account mapping and WorldsUnlocked display update :834-856 corroborate account schema, but full helper return is UNAVAILABLE. Map capability UI at ClientScript:1990-2009 requires MasteryUpgrades Type=WorldMap in reconstructed update. |
| Physical requirement | Opening map via FastTravel uses Activation volume; teleport callback itself has no source proximity check. HUD/map access and server permissions remain separate. |
| UI/state | LocalData required; TransitionGui presence aborts. PlayTransition closes GuiFrame and displays transition. |
| Arguments | Island: WorldUtil path; ordinary world surface: actual workspace.Worlds[world].FastTravel.Spawn.GetFullName; Seven Seas: Areas[definition.DisplayName].IslandTeleport.Spawn.GetFullName. |
| Pacing | PlayTransition callback scheduled after0.75+0.5≈1.25s. Presentation animations have no server acknowledgement. No additional server cooldown exposed. |
| Success | Actual correct world/island physical arrival; music/physics update and map closure are presentation only. |
| Conflicts | Map camera/control state, hatch, race/trading/fishing, location lease; current OC has stronger fail-closed guards. |
| Cancel/failure | Missing LocalData/transition/unlock helper refusal returns without request; missing ordinary FastTravel.Spawn or fishing spawn sends no command. Callback has no explicit error/result surface. |
| Unknown | Decompiled isUnlocked semantics, exact map capability fallback after second world, server-side access checks, stream/arrival tolerances and cancellation. |

## E. Native world trampoline travel

| Field | Evidence |
|---|---|
| Native interface | Physics.hookWorldTrampoline:286-378 registered from WorldTrampoline tag :459-462; PlayWorldTransition callback sends WorldTeleport(worldName). |
| Required account | Catalog world exists and Removed is false; LocalData.WorldsUnlocked[worldName] truthy. |
| Physical requirement | Normal Bounce.Touched from local character; root and humanoid available. |
| UI/state | Shared trampoline u9 debounce; disables player controls and applies native ascent presentation. This is source behavior, not permission to alter physics. |
| Arguments | Native trampoline model.Name world identifier, command WorldTeleport. Distinct from path Teleport and paid UnlockWorld. |
| Pacing | task.wait0.5 after transition call; shared debounce. Full transition timing not audited here. |
| Success | Actual arrival in destination world; no cost/unlock result inferred from transition. |
| Conflicts | Controls disabled during transition, other trampolines, movement/hatch/location tasks. |
| Cancel/failure | No accepted server acknowledgement or explicit cancel exposed. Ineligible/Removed/nonlocal contacts return. |
| Unknown | Server WorldTeleport validation, current availability of each trampoline, exact transition lifecycle and safe cancellation. |

## F. Buying a world

| Field | Evidence |
|---|---|
| Native interface | ClientScript.hookWorldGate:2088-2326 -> Unlock builder -> Remote:FireServer('UnlockWorld',gate.World). |
| Required account | LocalData exists; ItemUtil.GetOwnedAmount(profile,UnlockCost)>=ItemUtil.GetAmount(cost). Native world definition required; separate existing flag checks determine gate display. ClientScript does not expose all server prerequisites. |
| Physical requirement | Model.Activation bound via native Activation. Zen gate World='Minigame Paradise'; Hyperwave gate World='Seven Seas'. Both horizontal radius6.08393955 and vertical<=10. |
| UI/state | Correct World <Order> Unlock UI built. GuiFrame refuses opening while trading. Native cost callback is an atomic request; broader OC guards/reserves are separate. |
| Arguments/cost | Destination name from World attr. Saved permanent costs 1B Coins and2.5B Coins; price not sent in command. No server/world-state edits. |
| Pacing | No native request cooldown/acknowledgement wait shown in cost callback. Existing OC one-request/session controls and backoff remain preservation rules. |
| Success | Correct received WorldsUnlocked[target] flag plus account refresh; balance/deduction separately observed. Client animation destroys cover, removes activation and calls islandDiscovery after requesting, so visuals are insufficient. |
| Conflicts | Protected reserves, other spending, manual purchase, active transaction/hatch/movement. Serialization remains one Brain/scheduler. |
| Cancel/failure | Insufficient funds opens Prompt.fromNotEnough. After request, no client refund/recall established. Timeout is unconfirmed, never replay blindly. |
| Unknown | Server gate prerequisites, price freshness/race, distance enforcement, idempotency, request limits, refund, save and late acknowledgement. |

Minigame Paradise new capabilities are client unlock-description text (:2014-2020): larger Coin/Gem caps, board and minigames. Seven Seas (:2022-2026): fishing, fishing islands and Old Sailor bounties. Catalog cap increases are separately SOURCE_CONFIRMED in Worlds; capability description is not proof every opportunity is currently unlocked/valuable.

## G. Seven Seas fishing island travel

| Field | Evidence |
|---|---|
| Native interface | FishingWorldIslands:27-107,121-137; WorldMap:158-168. |
| Required account | FishingExperience converted through ExperienceUtil/FishingUtil.XP_CONFIG; RequiredLevel controls button visibility. World access must be independently received. This panel's click callback does not recheck level; never equate UI with server eligibility. |
| Physical requirement | IslandTeleport activation opens panel. Per-area Spawn is observed/resolved by DisplayName. |
| UI/state | Locked.Visible/Teleport.Visible reflect fishing level. PlayTransition used for travel. Fishing experience changes update UI. |
| Arguments | Teleport(actual Areas[DisplayName].IslandTeleport.Spawn.GetFullName). Keys starter/blizzard/jungle/lava/atlantis/dream/classic differ from display names. |
| Pacing | Common transition delay; no server rate rule exposed. |
| Success | Actual destination arrival, correct fishing area and unchanged required access; never fake AreasUnlocked. |
| Conflicts | Active cast/reel/fishing state, hatch and travel ownership. Stop/cancel active fishing via its own verified contract before any later approved travel. |
| Cancel/failure | Missing IslandTeleport returns. Reconstructed callback checks v3 but dereferences v4 Spawn unchecked; potential nil failure must not become implementation assumption. |
| Unknown | Server area enforcement, flags vs level, weather/cast cancellation, full fishing-area traversal rules. |

Required levels and mapping are in WORLD_AND_NAVIGATION.md. Seven Seas is not an empty progression world merely because Worlds.Islands={}.

## H. Halloween entry/return (saved current-context lead)

| Field | Evidence |
|---|---|
| Native interface | HalloweenEvent:6-64 full source, returns early in TradingPlaza. |
| Required account | No explicit account unlock/currency prerequisite in this short client module; missing server/event eligibility UNAVAILABLE. |
| Physical requirement | Activation bound to Workspace.HalloweenTeleport and Workspace.HalloweenEvent.Return; radius must use actual Root sizes. |
| UI/state | PlayTransition; no other client activity guard shown. |
| Arguments | Entry Teleport(Workspace.HalloweenEvent.Spawn.GetFullName), return Teleport(Workspace.Worlds['The Overworld'].Spawn.GetFullName). |
| Pacing | Common transition callback timing; no event server rate proved. |
| Success | Actual arrival; event active/expiry independently checked. |
| Conflicts | Existing location/hatch/fishing task; standard farming cannot take location ownership during event. |
| Cancel/failure | No explicit result/cancel exposed. Missing event geometry/catalog produces unavailable. |
| Unknown | Current schedule/expiry, access prerequisites, server travel validation and event activity beyond saved objects. |

Owner reports Halloween. Source module includes matching navigation. Retained Fall catalogs and old generic Event portal do not supersede this evidence or establish active Fall2026 availability.

## I. Approaching facilities and navigation within islands

Native Activation:61-82 binds a model to a callback. Poller :334-384 requires alive/root, model parent, horizontal distance<=Root.Size.Y/2, vertical distance<=10. It selects the first eligible bound model and invokes on change; this is not nearest-by-distance targeting. Root rotation/very thin Size.X is not the activation radius. Bind itself does not navigate or purchase. Sell repeats after>2s; model approach for other facilities normally fires once until target changes.

SOURCE_CONFIRMED entry callbacks: Potions on Zen, Shrines on Zen/Hyperwave, Enchanter on The Void, FishingWorldIslands, GemGenie, Minigames tagged model with Minigame attribute, WorldRewards tagged model. Purchasing/upgrading/claiming from those panels is a different contract. Leaving all activation volumes triggers GuiFrame.Close through ClientScript:3093-3104. That is a UI close event; it may not cancel an already issued purchase/request.

UNAVAILABLE: a safe verified walk/climb/pathfinding route to each interaction after island teleport; exact manual approach time; collision/stuck recovery; ascent prerequisites. No navigation code was implemented. No movement toward individual currency pickups is designed.

## J. Intentional chosen egg location

Source summary from parallel egg/pet audit: Eggs:531-539 annotates Island from tagged scene Egg objects. ClientScript:568-616 initial unlock prompt radius6.5 and one-egg affordable inventory-aware hatch; auto hatch scan :869-885 radius16 with actual local root/unlocked object/UI constraints. Actual owned egg access, hatch capacity/affordability, inventory space, NextEggOpenAt and cancellation are detailed in that audit.

Future coordination is HYPOTHESIS, not implementation permission: choose egg objective -> central scheduler leases intentional location -> supported travel -> manual/verified approach -> stationary hatch/compatible pickup work -> actual account delta -> release/replan. Pickup background may stay compatible at egg only without travel or manual movement. Parent architecture documents existing hatch ownership hooks, so no competing automation loop is needed.

## Owner result checklist

Record the pre-action eligibility snapshot, exact source object/destination, sent command, independent received flag/location/balance delta, timeout/cancel status and later rejoin result. Never publish account identities or inventory details in research. No gameplay actions were sent during this audit.

## Physical chest interaction follow-up

`Client.Effects.PhysicalItem:197–257` polls every 0.5 seconds. With a character root, it selects the nearest registered chest whose model is parented, three-dimensional distance is strictly below 20 studs, and `Opened` and `Animating` are false. It attaches `LootPoolViewer` to the chest's Prompt. The activated callback checks the registry still contains that chest, sends `ClaimChest(model.Name)` at line 248, and detaches the viewer. This caller omits the map quick-collect `true` argument. The callback does not establish reward acceptance or independently recheck distance.

`PhysicalItem.Chest:399–449` reads verified LocalData and computes `Opened = ((Cooldowns[name] or 0) - Time.now()) > 0`. The `Cooldowns` subscription at `PhysicalItem:292–303` updates chest presentation. A new cooldown plus the corresponding received reward/account delta is a meaningful result observation; closing the viewer or beginning an animation is insufficient. Models are chunked (256, 2) and parented into `Rendered.Generic` when visible (`Chest:451–483`), so saved `Rendered.Chests` location parts are not themselves current eligibility. Server proximity, rewards, concurrent-claim handling, cooldown enforcement, and quick-collect authorization remain unavailable.
