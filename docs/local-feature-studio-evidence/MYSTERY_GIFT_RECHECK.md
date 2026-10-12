# Mystery gift representation recheck

Read date: 2026-10-11. Studio: `681d6e17-4b4e-443e-8997-73c126b5e682`, label `85896571713843 Bubble Gum Simulator INFINITY.rbxl`. Four complete modules read; only two complete semantic modules and relevant complete caller functions retained here. This is saved client source evidence, not live owner verification.

## Confirmed native contract

- `ReplicatedStorage.Client.Effects.PhysicalItem:49-90`: Gift takes (giftId, powerupName, position). It clones `Assets.Powerups[powerupName]`, uses BasePart properties, assigns the unique ID to the clone.Name, and stores the Gift component by ID.
- `PhysicalItem:92-107`: `GetActiveObjects("Gift")` counts all registered gifts. This is the native guard used by Inventory.
- `PhysicalItem:109-122`: `GetActiveGifts()` returns a map keyed by the loaded spawned instance, valued by its Gift component. Loaded/unloaded callbacks at 134-175 maintain this visible subset.
- `PhysicalItem.Gift:60`: component fields include Model, InRange, Animating and HitCount; no Name/item-type field is set anywhere in the fully reviewed module.
- `StarterPlayer.StarterPlayerScripts.ClientScript:1894-1905`: public `Remote.Event("RenderGifts")` callback receives a map keyed by gift ID, with values read as Name and Position. This is the demonstrated public identity source. The callback forwards those fields to PhysicalItem.Gift.
- `PhysicalItem:185-192,275-285`: manual activation calls Hit(self) only when component.InRange is true. Range is horizontal distance <=15.
- `PhysicalItem.Gift:206-270`: Hit(self) guards Animating and >0.05 seconds since prior animation; it increments HitCount, and eighth hit defers Collect(self).
- `PhysicalItem.Gift:156-184`: Collect checks Animating, waits 0.1 seconds, sends ClaimGift with Model.Name, animates and destroys after 0.5 seconds. Client-side disappearance alone is not proof of server reward receipt.
- `ReplicatedStorage.Client.Gui.Frames.Inventory:207-272`: auto opening waits for all registered gifts to finish, hits loaded component values, and sends UseGift(name, min(owned, MaxSpawnableLimit)). Its native loop is not an OC implementation instruction.

## Demonstrated initial-delivery adapter mismatches (corrected in follow-up)

The initial build a4e17c439309 required component.Model:IsA("Model") and component.Name == "Mystery Box". The native object is a BasePart and component.Name is absent. The initial CanOpen flag only checks class-level Hit availability, so it could consume a box even though it can never recognize the spawned gift. Count derived from GetActiveGifts is also only the loaded subset; absence after unloading must not acknowledge completion.

A supported fail-closed correction can subscribe to the existing RenderGifts signal through the normal dependency cache. Retain only validated string ID -> string Name identity from that payload, require exactly one new ordinary ID after the request, and combine it with the public loaded instance->component registry. Never infer item type from model.Name (which is ID), asset geometry, missing component fields, or private closures. Unknown/missed identity remains manual/unconfirmed, with no automatic next box.

Normalize the adapter output to GiftRecords[id] = {Id=id, Name=verifiedEventName, Model=instance, Component=component}. Require component.Model == instance, instance:IsA("BasePart"), parent in workspace, Hit function, exact component.InRange == true, <=15 horizontal range, correct retained pending ID and no ambiguity. Use GetActiveObjects("Gift") for total GiftCount and zero-before/zero-after guards. A public event observer adds no automation loop; disconnect it on normal reader lifecycle cleanup. Do not resend uncertain pending after reload.

The native eighth Hit schedules deferred work whose Collect method has no OC cancellation token. OC can prevent new hits after Pause; it cannot claim already authorized native effects are synchronously cancelled by Pause. Report this lifecycle limit explicitly.

## Targeted synthetic fixture (native data design)

Native-equivalent fixture:

```lua
local part = {
    Name = "native-gift-id-1",
    ClassName = "Part",
    Parent = renderedGifts,
    IsA = function(_, kind) return kind == "Part" or kind == "BasePart" end,
    IsDescendantOf = function(_, ancestor) return ancestor == workspace end,
    GetPivot = function() return { Position = Vector3.new(0, 0, 0) } end,
}
local component = {
    Model = part, InRange = true, Animating = false,
    AnimationId = 0, LastAnimation = 0, HitCount = 0,
    -- No Name field.
}
component.Hit = function(self) assert(self == component) hits += 1 end
local loadedActive = { [part] = component }
local renderPayload = {
    ["native-gift-id-1"] = { Name = "Mystery Box", Position = Vector3.new(0, 0, 0) },
}
```

The offline harness must supply its usual Instance/typeof shim for this synthetic part; an ordinary Lua table is not a real Roblox Instance. Assert independently:

1. Model rejection from the old adapter is reproduced; corrected adapter accepts BasePart with no component.Name only with matching public identity.
2. The normalized record keeps unique ID and ordinary item name distinct.
3. Missing/malformed event identity yields no ordinary record or Hit.
4. A non-ordinary public event name, mismatched component.Model, ambiguous new ordinary IDs, old baseline ID, or InRange false yields no Hit.
5. Exact retained ordinary pending ID receives only self as argument; a nearby unrelated gift receives none.
6. GetActiveObjects total=1 while GetActiveGifts is empty does not permit a new box or mark pending complete.
7. Total=0 and previously correlated ID absent permits disappearance acknowledgement only; consumption plus observed reward remains required.
8. Reload after uncertain dispatch retains the single barrier. A missed render identity does not trigger a second box.
9. Pause prevents a new Hit; no assertion claims cancelling the native deferred Collect callback already scheduled by hit eight.

## Saved evidence

- PhysicalItem.source.txt: all 305 returned lines, Base64 line 4 explicitly omitted.
- PhysicalItem.Gift.source.txt: all 299 returned lines, Base64 line 4 explicitly omitted.
- ClientScript.RenderGifts.source.txt: returned lines 1890-1905 from a full module read.
- Inventory.AutoMysteryBox.source.txt: returned lines 162-272 from a full module read.

The source-inspection batch used no Studio execution, inputs, mutations or play-state changes. The subsequent authorized local corrections, build and tests are documented in ../LOCAL_FEATURES_STUDIO_RECHECK.md. No GitHub operations occurred.

