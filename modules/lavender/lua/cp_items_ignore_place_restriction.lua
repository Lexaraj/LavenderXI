-----------------------------------------------------------------------------------------------
-- Module: cp_items_ignore_place_restriction
--
-- Removes the `place` (1st/2nd place) purchase restriction from Conquest Point shop items
-- sold by regional/city Conquest Overseer NPCs -- for both home-nation and foreign purchases.
-- Nothing else about the shops changes.
--
-- BACKGROUND
-- scripts/globals/conquest.lua's overseerInvNation tables tag some items with a `place` field
-- (1 or 2). Vanilla xi.conquest.overseerOnEventUpdate() computes a `rankCheck` flag from three
-- separate conditions:
--   1. Foreign-nation gate (applies to EVERY item, place-restricted or not): blocked unless
--      YOUR OWN nation's GetNationRank() currently outranks that guard nation's.
--   2. Foreign-nation + place-restricted item: blocked outright, regardless of anyone's rank.
--   3. Home-nation + place-restricted item: blocked unless your own nation's GetNationRank()
--      is 1st or 2nd.
-- Conditions #2 and #3 both hinge entirely on `stock.place ~= nil`. Condition #1 never looks
-- at `place` at all.
--
-- IMPLEMENTATION
-- Rather than duplicating the item catalog and overriding xi.conquest.overseerOnEventUpdate
-- (the approach used by earlier versions of this module), this version reaches into the real,
-- live overseerInvNation / overseerInvCommon tables -- which are `local` to conquest.lua and
-- normally unreachable from a module -- via LuaJIT's debug library, walking the upvalue chain:
-- xi.conquest.overseerOnEventUpdate -> (local upvalue) getStock -> (local upvalues)
-- overseerInvNation / overseerInvCommon. It then simply deletes the `place` field from every
-- catalog entry that has one, in place.
--
-- Once that's done, conditions #2 and #3 can never trigger again (stock.place is nil
-- everywhere), and the ORIGINAL, completely unmodified vanilla functions handle everything
-- correctly on their own -- including condition #1, which is untouched and still fully
-- enforced: a `place`-tagged item bought from a foreign nation still requires your nation to
-- currently outrank theirs, and still costs the normal foreign-purchase markup, exactly like
-- any ordinary item.
--
-- This means no function overrides at all are needed for the purchase-completion side of
-- this fix, and there's no separate catalog to hand-maintain -- it always reflects whatever
-- the live overseerInvNation/overseerInvCommon tables actually contain at load time, so it
-- stays correct even if LSB's item catalog changes upstream.
--
-- Example: Mercenary Captain's Kukri is Windurst's own catalog entry with `place = 2`. This
-- module lets Windurst buy it regardless of Windurst's own placing, AND lets a foreign
-- (e.g. San d'Oria) player buy it too, provided San d'Oria currently outranks Windurst -- the
-- same condition that already governs every other Windurst item bought by a foreigner.
--
-- NOT changed:
--   - Condition #1 above (the foreign-nation-outrank check).
--   - The personal Conquest Rank requirement (`stock.rank`), the level/job equip check, the CP
--     cost (including the foreign-purchase markup), and every other conquest system (signets,
--     Expeditionary Force, supply runs, homepoint, teleports).
--
-- STILL UNRESOLVED: menu visibility for foreign viewers
-- Earlier testing in this project found that `place`-restricted items don't appear at all in
-- the shop dialogue when viewed by a player of a different nation (ordinary items do). Neither
-- this module nor its predecessor could locate what controls that -- every server-side value
-- fed into the dialogue-opening event was checked and none of them encode relative nation
-- ranking. This module only guarantees the *purchase* succeeds once an item is selectable; it
-- does not address why a foreign viewer might not see it in the list to begin with. If that
-- turns out to be a hardcoded client behavior or a C++-only code path, no Lua module can affect
-- it.
-----------------------------------------------------------------------------------------------

local moduleName = 'cp_items_ignore_place_restriction'

local function findUpvalue(func, name)
    local i = 1
    while true do
        local upvalueName, upvalueValue = debug.getupvalue(func, i)
        if upvalueName == nil then
            return nil
        end

        if upvalueName == name then
            return upvalueValue
        end

        i = i + 1
    end
end

local function stripPlaceRestrictions()
    local baseOverseerOnEventUpdate = xi.conquest.overseerOnEventUpdate
    if baseOverseerOnEventUpdate == nil then
        print(string.format('[%s] xi.conquest.overseerOnEventUpdate not found; skipping.', moduleName))
        return
    end

    local getStock = findUpvalue(baseOverseerOnEventUpdate, 'getStock')
    if getStock == nil then
        print(string.format('[%s] Could not locate getStock() -- conquest.lua may have changed upstream. Skipping.', moduleName))
        return
    end

    local overseerInvNation = findUpvalue(getStock, 'overseerInvNation')
    local overseerInvCommon = findUpvalue(getStock, 'overseerInvCommon')

    local strippedCount = 0

    if overseerInvNation ~= nil then
        for _, nationStock in pairs(overseerInvNation) do
            for _, entry in pairs(nationStock) do
                if entry.place ~= nil then
                    entry.place = nil
                    strippedCount = strippedCount + 1
                end
            end
        end
    end

    if overseerInvCommon ~= nil then
        for _, entry in pairs(overseerInvCommon) do
            if entry.place ~= nil then
                entry.place = nil
                strippedCount = strippedCount + 1
            end
        end
    end

    print(string.format('[%s] Removed the `place` restriction from %d Conquest Point item(s).', moduleName, strippedCount))
end

stripPlaceRestrictions()

-- No xi.* functions are overridden, so this intentionally has no `overrides` field.
return { name = moduleName }
