# Phase 1 plan and implemented architecture

1. Inspect existing client data, shared stat helpers, definition tables, and scene gates using Studio read tools. Record uncertainty before defining an adapter.
2. Build AccountStateReader snapshots from LocalData. Keep missing values unavailable, copy received inventory, resolve equipped IDs, and use game helpers for effective stats.
3. Resolve partial user overrides against the single OCConfig. Replace arrays in full, validate types/unknown keys, and reject requests for unimplemented executors.
4. Let OCBrain classify available progression and rank eligible recommendations using actual ownership, access, currency, reserves, and budget. Prerequisites and resource reservations are advisory.
5. Schedule one foreground analysis at a time. Validate completion, reject stale results, and retain a cancelled task's foreground lease until it returns.
6. Provide controls, a scrolling account/goal panel, and bounded diagnostics. Bundle modules into a single client initializer, commit/push, and await owner-run verification before another phase.

## Module boundaries

| Module | Responsibility | Execution and termination |
| --- | --- | --- |
| OCConfig | Sole defaults and category/setting names | Inert data; merged before initialization |
| ConfigResolver | Copy defaults and replace overrides | Throws on unknown keys, wrong types, or malformed arrays; no runtime objects created |
| AccountStateReader | Load observed game modules; read profile, helpers, unlocks, and definitions | Starts on initialization; disabled reader starts no dependency/background work; Destroy disconnects and cancels reader jobs |
| OCBrain | Pure classification, candidate ranking, prerequisite selection, hysteresis | Runs only through enabled analysis; cancellation token checked; returns a recommendation, never performs it |
| TaskScheduler | Priority queue, replacement by ID, one active lease, timeout/completion/cancellation | Pause/Stop clear pending tasks and cancel active token; only task exit releases lease; Destroy cancels remaining scheduler threads |
| OCController | Lifecycle, generation/revision checks, replanning, diagnostics | Start/Resume plan; Pause retains last plan; Stop clears it; account view remains readable; Destroy removes subscriptions and UI |
| AccountPresentation | Deterministic bounded account formatting | Only describes received snapshot fields; never fills in missing values |
| OCInterface | Native runtime GUI and four controls | Disabled UI creates no panel; Destroy removes the hosted panel |
| src/OC.luau | Initialize `(Config)` and return controller | Requires a client environment and LocalPlayer; cleans its previous shared hosted OC instance after successful startup |
| dist/OC.lua | Generated single-file entry | Private function factories replace OC imports; existing game ModuleScript require remains native |

Only `ANALYZE_ACCOUNT` is registered as a foreground task. Independent account observation remains event-driven with a fallback refresh. Phase 1 has no gameplay task module, remote invocation, purchasing, movement, resource consumption, hatching, fishing, Rifts, or event execution.

## Goal eligibility and when a recommendation stops

These are recommendation eligibility/completion rules, not promises that gameplay executes. A candidate disappears on the next fresh snapshot when its condition ceases to hold. Every recommendation stops being planned when its category is disabled or controls are paused/stopped.

| Candidate | Prerequisites/decision | Stops being eligible when |
| --- | --- | --- |
| WAIT_FOR_ACCOUNT | LocalData has not supplied a ready table; explain dependency/account delivery blockers | A ready profile arrives |
| REVIEW_INVENTORY | Game helpers report storage used at/above capacity | Used storage falls below capacity or reader fields become unavailable |
| WAIT_FOR_PET_SYNC | Equipped IDs fail to resolve against received inventory | All equipped IDs resolve |
| EQUIP_EXISTING_PETS / FILL_EQUIP_SLOTS | Received owned pets, active team and game equip limit establish an unused slot | Team has no supported free slot, pets become unavailable, or earnings recommendations disabled |
| SELL_BUBBLES | Numeric received bubble and effective capacity meet configured threshold | Ratio drops below threshold or either field becomes unknown |
| EQUIP_UPGRADE | A better owned currency-only accessible gum/flavor meets base gain threshold | It becomes equipped, loses access/ownership, or improvement is insufficient |
| BUY_UPGRADE / Save for | Accessible unowned nonpremium definition; known balance; reserves and upgrade budget classify consideration vs saving | Owned/equipped/filtered out; savings label changes when budget permits |
| DISCOVER gate island | Scene-present world gate in an unlocked origin world; required island is undiscovered | Island is discovered or gate/world is unavailable |
| UNLOCK_WORLD / Save for world | Gate prerequisite discovered, selected permanent world/scene, known definition cost and spendable balance | World is unlocked, gate disappears, or selection changes |
| EXPLORE island | Next height-ordered undiscovered scene/definition island in an unlocked selected world | Island is discovered or no longer available/selected |
| MASTERY branch | Received numeric branch level and next definition cost; known balance affects rank | Next tier acquired, branch complete, data missing, or branch omitted from priorities |
| REVIEW_AVAILABLE_PROGRESSION | No supported enabled candidate can be established | Any supported candidate becomes eligible |

Candidate titles/reasons expose uncertainty: route reachability and Mastery facility access/benefit are prerequisites for the owner to check, not simulated availability. Progression stage is a heuristic of received world/island/pet/Mastery counts; unknown inputs yield UNDETERMINED. There is no official-level or complete-endgame inference.

## Configuration rules for every setting

Names below are inside their named `_SETTINGS` category. `true` enables, `false` disables. Arrays replace their entire default array, including `{}`. Numeric settings must be finite/nonnegative; entry/queue limits are positive integers. Configuration is fixed for an instance; change it and rerun the loader to apply it. Unknown keys fail before runtime initialization.

### GENERAL_SETTINGS

| Setting | Decision effect | Prerequisite | Stop/limit |
| --- | --- | --- | --- |
| OC_ENABLED | Allows initializer/Start | true | false rejects initialization; no OC reader/task starts |
| AUTO_START | Calls Start after successful setup | OC enabled; reader/scheduler enabled | false leaves controls stopped; manual Start required |
| PROGRESSION_PROFILE | Selects Phase 1 ranking profile | FULL_AUTO_PROGRESSION only | Unsupported values rejected |
| ENABLE_RECOMMENDATIONS | Enables ranked candidate generation | Running controller | false yields RECOMMENDATIONS_DISABLED instead of gameplay candidates |
| REPLAN_COOLDOWN_SECONDS | Coalesces snapshot changes into analysis | Running, enabled scheduler | At most one pending controller replan; Pause/Stop cancels it |
| MINIMUM_OBJECTIVE_HOLD_SECONDS | Keeps a still-eligible previous goal briefly | Same goal still among current candidates | Hold expires, goal loses eligibility, or priority margin exceeded |
| OBJECTIVE_SWITCH_PRIORITY_MARGIN | Sets improvement required to interrupt hold | Valid prior goal during hold | Higher score reaches margin; no hold when prior goal invalid |
| PRIORITIES | Tie-breaks goal families in listed order | Candidates have equal numeric scores | Unknown/omitted families rank last; does not force an ineligible goal |

### ACCOUNT_SETTINGS

| Setting | Decision effect | Prerequisite | Stop/limit |
| --- | --- | --- | --- |
| ENABLE_ACCOUNT_READER | Loads dependencies and publishes snapshots | Existing client module paths | false skips module loads and refresh loop; Start rejects disabled reader |
| MODULE_LOAD_TIMEOUT_SECONDS | Marks a still-loading require as timed out; also limits PlayerGui wait | A dependency/GUI is loading | Timeout reports uncertainty; a late successful module load can recover |
| ACCOUNT_LOAD_TIMEOUT_SECONDS | Reports no ready profile after deadline | Reader started without ready LocalData table | Late real profile clears missing-profile state; never creates one |
| SNAPSHOT_REFRESH_SECONDS | Fallback interval for manual/game changes | Reader enabled | Destroy cancels periodic reader loop |
| MINIMUM_SNAPSHOT_INTERVAL_SECONDS | Coalesces rapid change notifications | LocalData Changed/DataReady/PetsChanged | One pending notification refresh; Destroy cancels it |
| SELECTED_CURRENCIES | Reads those exact top-level numeric keys and makes them available for affordability | Ready profile with corresponding numeric value | Missing/omitted keys are unavailable; omitting a currency prevents its cost eligibility |
| READ_PET_INVENTORY | Reads pet records/team; computes helper limits and resolves IDs | Ready profile and supported helper methods | false skips pet/team reads and disables candidates needing them |
| READ_ITEM_INVENTORY | Reads Powerups/Potions independently of pets | Received table fields | false skips these item reads; other inventories are not invented |
| READ_UPGRADES | Reads owned Gum/Flavors maps | Received ownership tables | false removes ownership eligibility for gum/flavor recommendations |
| READ_MASTERY | Reads MasteryLevels/MasteryUpgrades | Received Mastery fields | false removes Mastery eligibility and classification evidence |
| READ_UNLOCKS | Reads AreasUnlocked/WorldsUnlocked | Received unlock tables | false removes world/access eligibility and classification evidence |

### BRAIN_SETTINGS

| Setting | Decision effect | Prerequisite | Stop/limit |
| --- | --- | --- | --- |
| ENABLE_EARNING_RECOMMENDATIONS | Adds owned pet slot and gum/flavor upgrade candidates | Actual inventory/access/ownership/base stats | false excludes these candidates |
| ENABLE_WORLD_RECOMMENDATIONS | Adds gate/island/world candidates | Both live scene and permanent definitions; received unlocks | false excludes these candidates |
| ENABLE_MASTERY_RECOMMENDATIONS | Adds configured branch next-tier candidates | Known received level, definition tier/currency/balance | false excludes Mastery candidates |
| ENABLE_INVENTORY_RECOMMENDATIONS | Adds full storage and unresolved-equipped-ID blockers | Actual helper limits/ID join | false excludes these blockers |
| SELECTED_UPGRADES | Filters currency-only gum/flavor names before ranking | Accessible supported definition | Empty includes all verified entries; listed names still need access/ownership data |
| SELECTED_WORLDS | Filters permanent world and island recommendations | Scene presence, unlocks/gate prerequisites | Empty includes all supported permanent worlds; no event authorization |
| MASTERY_PRIORITIES | Selects branches and their score order | Definition Levels table and known profile level | Empty produces no Mastery candidates; completed/missing branches excluded |
| MINIMUM_UPGRADE_GAIN_RATIO | Rejects smaller base-stat gains | Known equipped base stat >0 and candidate base stat | Candidate gain below threshold excluded; no invented effective stat forecast |
| MINIMUM_BLOWS_PER_FILL | Detects capacity bottleneck and boosts gum priority | Actual effective capacity and power >0 | Boost ceases when capacity/power ratio reaches threshold |

### RESOURCE_SETTINGS

| Setting | Decision effect | Prerequisite | Stop/limit |
| --- | --- | --- | --- |
| COIN_RESERVE | Subtracts protected Coins before cost ranking | Known Coins balance | Spendable clamped to zero; no spending occurs |
| GEM_RESERVE | Subtracts protected Gems before cost ranking | Known Gems balance | Spendable clamped to zero; no spending occurs |
| TICKET_RESERVE | Subtracts protected Tickets before cost ranking | Known Tickets balance | Spendable clamped to zero; no spending occurs |
| PEARL_RESERVE | Subtracts protected Pearls before cost ranking | Known Pearls balance | Spendable clamped to zero; no spending occurs |
| MAXIMUM_UPGRADE_BALANCE_FRACTION | Labels upgrade as consideration only within this fraction of spendable funds, otherwise savings | Known cost/balance; value in (0,1] | Ownership/access/gain criteria still required; does not apply to world/Mastery budgets |

### TASK_SETTINGS

| Setting | Decision effect | Prerequisite | Stop/limit |
| --- | --- | --- | --- |
| ENABLE_TASK_SCHEDULER | Enables foreground analysis submission/pump | Running control | false rejects Start/submission; no task executes |
| MAXIMUM_PENDING_TASKS | Bounds distinct pending task IDs | Positive integer | Full queue rejects extra submission; duplicate pending ID replaced |
| TASK_TIMEOUT_SECONDS | Cancels active token when task deadline reached | Active task still owns lease | Foreground lease stays held until task returns; timeout is not overlapping execution |

### BUBBLE_SETTINGS

| Setting | Decision effect | Prerequisite | Stop/limit |
| --- | --- | --- | --- |
| ENABLE_BUBBLE_RECOMMENDATIONS | Enables sell and gum/flavor candidates | Received bubble/stat/access fields; earnings toggle also required for upgrades | false excludes all bubble/gum/flavor candidates |
| SELL_AT_CAPACITY_RATIO | Sets numeric full-bubble threshold | Amount/capacity known, effective capacity >0; threshold in (0,1] | Sell candidate disappears below threshold; nothing is sold |
| AUTO_BLOW_BUBBLES | Reserved, no executor | Must remain false in Phase 1 | true rejected before reader/controller setup |
| AUTO_SELL_BUBBLES | Reserved, no executor | Must remain false in Phase 1 | true rejected; sell recommendation is separate |
| AUTO_BUY_GUM | Reserved, no purchase executor | Must remain false in Phase 1 | true rejected; no purchase occurs |
| AUTO_BUY_FLAVORS | Reserved, no purchase executor | Must remain false in Phase 1 | true rejected; no purchase occurs |

### FALL_EVENT_SETTINGS

All settings here reserve names from observed retained Autumn data. Event availability is **not** implemented in Phase 1; this category cannot authorize any execution.

| Setting | Decision effect | Prerequisite | Stop/limit |
| --- | --- | --- | --- |
| ENABLE_FALL_EVENT | Reserved event module switch | Must remain false | true rejected; retained definitions are insufficient to establish active event |
| AUTO_REBIRTH | Reserved reset operation | Must remain false | true rejected; no resource reset |
| AUTO_BUY_REBIRTH_UPGRADES | Reserved purchase operation | Must remain false | true rejected; no purchases |
| AUTO_USE_FALL_ELIXIRS | Reserved consumable operation | Must remain false | true rejected; no consumables used |
| AUTO_BUY_AUTUMN_SHOP_ITEMS | Reserved purchase operation | Must remain false | true rejected; no shop actions |
| SELECTED_EGGS | Holds future selection names only | A future verified event/egg module, absent here | Unused in Phase 1; cannot trigger hatching |
| SELECTED_SHOP_ITEMS | Holds future shop selection names only | A future verified event/shop module, absent here | Unused in Phase 1; cannot trigger purchases |
| LEAF_RESERVE | Holds future Leaves26 reserve only | A future verified spending module, absent here | Unused in Phase 1; no event cost candidates exist |
| REBIRTH_SHARD_RESERVE | Holds future RebirthShards26 reserve only | A future verified spending module, absent here | Unused in Phase 1 |

### PET_SETTINGS

| Setting | Decision effect | Prerequisite | Stop/limit |
| --- | --- | --- | --- |
| SELECTED_PETS | Holds future target names only | A future verified pet action module, absent here | Unused; does not restrict reading actual owned pets |
| AUTO_HATCH | Reserved, no executor | Must remain false | true rejected |
| AUTO_EQUIP | Reserved, no executor | Must remain false | true rejected; team recommendations never apply changes |
| AUTO_DELETE_PETS | Reserved destructive action | Must remain false | true rejected; no pets deleted |
| AUTO_CRAFT_SHINY | Reserved duplicate-consuming action | Must remain false | true rejected; no pets consumed |
| AUTO_FUSE_PETS | Reserved fusion action | Must remain false | true rejected; no pets submitted |

### STATUS_UI_SETTINGS

Display flags affect presentation only; independent ACCOUNT_SETTINGS flags govern reading. Hiding a section does not fabricate/remove account information.

| Setting | Decision effect | Prerequisite | Stop/limit |
| --- | --- | --- | --- |
| ENABLE_STATUS_UI | Creates runtime panel and controls | PlayerGui; client GUI capability | false creates no panel; use returned controller methods |
| SHOW_ACCOUNT_BALANCES | Shows configured currencies and actual bubble stats | UI enabled | false hides balances section; nil displays unavailable |
| SHOW_PROGRESSION | Shows heuristic stage and its count evidence | UI enabled; current plan | false hides stage section |
| SHOW_PREREQUISITES | Shows selected goal blockers/action prerequisites | UI enabled; goal has prerequisites | false hides prerequisite section |
| SHOW_DIAGNOSTICS | Shows reader/controller failures and unavailable fields | UI enabled; diagnostics exist | false hides diagnostics section |
| SHOW_PETS | Shows active IDs, resolved records, and pet inventory | UI enabled; reader pet data | false hides section; missing fields stay unavailable |
| SHOW_INVENTORY | Shows potions/powerups and storage units | UI enabled; reader data | false hides section |
| SHOW_UPGRADES | Shows owned gum/flavors and Mastery upgrades | UI enabled; reader data | false hides section |
| SHOW_MASTERY | Shows received levels and supported next-tier data | UI enabled; reader/definitions | false hides section |
| SHOW_WORLDS | Shows received unlocked worlds and island names | UI enabled; unlock reader | false hides section |
| MAXIMUM_DISPLAY_ENTRIES | Bounds each rendered list | Positive integer | Extra entries explicitly reported; snapshot remains complete |
| PANEL_WIDTH_PIXELS | Sets maximum width | >=280 | Clamped to viewport; no planner effect |
| PANEL_HEIGHT_PIXELS | Sets maximum height | >=280 | Clamped to viewport; scrolling preserves longer content |

### DIAGNOSTIC_SETTINGS

| Setting | Decision effect | Prerequisite | Stop/limit |
| --- | --- | --- | --- |
| ENABLE_CONSOLE_LOGGING | Prints prefixed init/control/dependency/account/goal messages | Runtime print | false suppresses console logging, including PrintAccount |
| LOG_ACCOUNT_DETAILS | Includes bounded pet/item/unlock/upgrade/Mastery sections in automatic account logs | Console logging and ready profile | false logs balances only; unchanged bounded content not repeated |
| LOG_DEPENDENCIES | Prints transitions/errors for each existing game module require | Console logging | false suppresses dependency transition logs; account/UI failures still reported |
| MINIMUM_LOG_INTERVAL_SECONDS | Rate-limits changed ready-account logs | Console logging; pending changed snapshot | Latest snapshot used; Destroy cancels pending account log |
| MAXIMUM_LOG_ENTRIES | Bounds each automatic diagnostic inventory list | Positive integer | Explicit omitted count; PrintAccount(n) can request a larger local listing |

## Deferred scope

No hatching, fishing, minigames, Rifts, world travel, remote contracts, event boards, reward/shop buying, pet management, or irreversible operations are implemented. Auto-Rebirth/Rebirth Upgrades, XL egg hunting, admin-summoned eggs, Shadow Realm, Gem Mine, Fragments, Super Ticket Skip Minigame, Fall Elixirs, Autumn Shops, and Event Board Buying are later scope subject to fresh workspace/API/event verification. A feature name is not evidence of a supported mechanic; no additional speculative config executor is created for an unverified interface.

## Verification boundary

Source/scene inspection establishes adapter paths and intended field semantics. Official Luau compilation, nine offline behavioral tests, and an actual bundle-entry check establish syntax and isolated foundation logic. They do not establish real account data, module require permissions, live game updates, rendering, or user-runtime compatibility. All source files and the rebuilt dist/OC.lua are maintained in the same public OCscript repository. The owner runs that public hosted build using Config + loadstring, sends observations, and explicitly confirms Phase 1 before Phase 2 work begins.
