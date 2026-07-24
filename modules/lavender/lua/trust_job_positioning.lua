-----------------------------------
-- modules/custom/lua/trust_job_positioning.lua
-----------------------------------
require('modules/module_utils')
require('scripts/globals/trust')
-----------------------------------
local m = Module:new('trust_job_positioning')

-- Mirrors the engine's own facing-relative position math (see nearPosition()
-- in src/common/utils.cpp): 0 radians = directly in front of the origin,
-- math.pi = directly behind, +/- math.pi/2 = to a side.
local function getFacingRelativePosition(origin, offsetDistance, relativeRadians)
    local originRadians = math.rad(utils.ffxiRotToDegrees(origin.rot))
    local totalRadians  = originRadians + relativeRadians

    return {
        x = origin.x + math.cos(2 * math.pi - totalRadians) * offsetDistance,
        y = origin.y,
        z = origin.z + math.sin(2 * math.pi - totalRadians) * offsetDistance,
    }
end

-- The engine's own NO_MOVE safety net (trust_controller.cpp, CastingDistance)
-- forcibly repositions a trust if it's more than 15' from its target, ignoring
-- our own positioning entirely. Keep tank-anchored destinations safely inside
-- that so we never end up fighting it. Also doubles as the "leash" distance
-- used to decide whether a caster needs to re-path once already positioned.
local MAX_DISTANCE_FROM_TARGET = 13

local function clampToTargetRange(dest, targetPos, maxDist)
    local dx   = dest.x - targetPos.x
    local dz   = dest.z - targetPos.z
    local dist = math.sqrt(dx * dx + dz * dz)

    if dist > maxDist then
        local scale = maxDist / dist
        dest.x = targetPos.x + dx * scale
        dest.z = targetPos.z + dz * scale
    end

    return dest
end

local DIRECTION = {
    FRONT  = 0,
    BEHIND = math.pi,
    LEFT   = math.pi / 2,  -- flip to -math.pi / 2 if this lands on the wrong side in testing
    RIGHT  = -math.pi / 2,
}

-- Jobs sharing a fanGroup spread out along an arc centered on that group's
-- base direction, instead of all resolving to the same point.
--   spread: angle (radians) between adjacent trusts in the fan
local FAN_GROUPS = {
    rightFlank = { direction = DIRECTION.RIGHT, spread = math.rad(30) },
    leftFlank  = { direction = DIRECTION.LEFT,  spread = math.rad(30) },
}

-- Preferred tank jobs, in priority order. First match found in the party wins.
local TANK_JOB_PRIORITY = { xi.job.PLD, xi.job.NIN, xi.job.WAR, xi.job.MNK }

local function findPartyTank(master)
    local partyMembers = master:getPartyWithTrusts()

    for _, wantedJob in ipairs(TANK_JOB_PRIORITY) do
        for _, member in pairs(partyMembers) do
            if member:getMainJob() == wantedJob then
                return member
            end
        end
    end

    return nil
end

-- anchor: 'tank' or 'target' -- which entity the offset is measured from
-- distance: yalms out from the anchor along the given direction
-- fanGroup: optional -- jobs sharing this key spread across an arc instead
--           of stacking on the same point (see FAN_GROUPS)
-- positionTolerance: how far off-position before we bother re-pathing
-- minRepathInterval: floor on how often we'll issue a new path command (seconds)
local JOB_POSITION_RULES = {
    -- Casters: anchored to the tank
    [xi.job.BLM] = { anchor = 'tank',   direction = DIRECTION.BEHIND,  distance = 13, positionTolerance = 2, minRepathInterval = 10 },
    [xi.job.RDM] = { anchor = 'tank',   direction = DIRECTION.BEHIND,  distance = 13, positionTolerance = 2, minRepathInterval = 10 },
    [xi.job.WHM] = { anchor = 'tank',   direction = DIRECTION.BEHIND,  distance = 13, positionTolerance = 2, minRepathInterval = 10 },
    [xi.job.SMN] = { anchor = 'tank',   direction = DIRECTION.BEHIND,  distance = 13, positionTolerance = 2, minRepathInterval = 10 },
    [xi.job.SCH] = { anchor = 'tank',   direction = DIRECTION.BEHIND,  distance = 13, positionTolerance = 2, minRepathInterval = 10 },
    [xi.job.GEO] = { anchor = 'tank',   direction = DIRECTION.BEHIND,  distance = 13, positionTolerance = 2, minRepathInterval = 10 },

    -- Thief: anchored to the engaged target - Behind for Sneak Attack
    [xi.job.THF] = { anchor = 'target', direction = DIRECTION.BEHIND, distance = 3,  positionTolerance = 2.0, minRepathInterval = 2 },

    -- Right flank: anchored to the engaged target, fanned out so they don't stack
    [xi.job.WAR] = { anchor = 'target', fanGroup = 'rightFlank', distance = 3, positionTolerance = 1.5, minRepathInterval = 2 },
    [xi.job.MNK] = { anchor = 'target', fanGroup = 'rightFlank', distance = 3, positionTolerance = 1.5, minRepathInterval = 2 },
    [xi.job.DRG] = { anchor = 'target', fanGroup = 'rightFlank', distance = 3, positionTolerance = 1.5, minRepathInterval = 2 },
    [xi.job.SAM] = { anchor = 'target', fanGroup = 'rightFlank', distance = 3, positionTolerance = 1.5, minRepathInterval = 2 },
    [xi.job.PUP] = { anchor = 'target', fanGroup = 'rightFlank', distance = 3, positionTolerance = 1.5, minRepathInterval = 2 },

    -- Left flank -- anchored to the engaged target, fanned out so they don't stack
    [xi.job.DRK] = { anchor = 'target', fanGroup = 'leftFlank', distance = 3, positionTolerance = 1.5, minRepathInterval = 2 },
    [xi.job.BLU] = { anchor = 'target', fanGroup = 'leftFlank', distance = 3, positionTolerance = 1.5, minRepathInterval = 2 },
}

-- Resolves the direction (radians) for a fan-grouped rule: finds every
-- currently-alive trust sharing the same fanGroup, sorts them into a stable
-- order, and gives this trust a slot centered on the group's base direction.
local function getFanDirection(mob, master, group)
    local groupInfo = FAN_GROUPS[group]
    local members    = {}

    for _, member in pairs(master:getPartyWithTrusts()) do
        if not member:isPC() and not member:isDead() then
            local memberRule = JOB_POSITION_RULES[member:getMainJob()]
            if memberRule and memberRule.fanGroup == group then
                table.insert(members, member)
            end
        end
    end

    table.sort(members, function(a, b) return a:getID() < b:getID() end)

    local index = 1
    for i, member in ipairs(members) do
        if member:getID() == mob:getID() then
            index = i
            break
        end
    end

    local centerOffset = (#members - 1) / 2
    return groupInfo.direction + (index - 1 - centerOffset) * groupInfo.spread
end

-- Computes and, if warranted, executes a reposition for a single trust.
-- force = true bypasses the leash/enmity checks and always paths immediately
-- (used by the !trustposition failsafe command).
local function repositionTrust(mob, master, target, rule, tank, force)
    if rule.anchor == 'tank' then
        local targetPos       = target:getPos()
        local isNewEngagement = mob:getLocalVar('jobPosTargetID') ~= target:getID()

        local needsReposition = force or isNewEngagement
            or utils.distance(mob:getPos(), targetPos) > MAX_DISTANCE_FROM_TARGET

        if needsReposition then
            local anchor = tank or target
            local dest   = getFacingRelativePosition(anchor:getPos(), rule.distance, rule.direction)
            dest         = clampToTargetRange(dest, targetPos, MAX_DISTANCE_FROM_TARGET)

            if force or utils.distance(mob:getPos(), dest) > rule.positionTolerance then
                mob:pathTo(dest.x, dest.y, dest.z, xi.path.flag.RUN + xi.path.flag.WALLHACK)
            end

            mob:setLocalVar('jobPosTargetID', target:getID())
            return true
        end

        return false
    else
        if not force then
            -- Target-anchored: if we currently hold top enmity, the target is
            -- facing us and our offset would just chase itself.
            local currentTarget = target:getTarget()
            if currentTarget and currentTarget:getID() == mob:getID() then
                return false
            end
        end

        local direction = rule.fanGroup and getFanDirection(mob, master, rule.fanGroup) or rule.direction
        local dest      = getFacingRelativePosition(target:getPos(), rule.distance, direction)

        if force or utils.distance(mob:getPos(), dest) > rule.positionTolerance then
            mob:pathTo(dest.x, dest.y, dest.z, xi.path.flag.RUN + xi.path.flag.WALLHACK)
        end

        return true
    end
end

-- Exposed so scripts/commands/trustposition.lua can trigger an immediate
-- reposition on demand, bypassing throttling entirely.
xi.trustJobPositioning = xi.trustJobPositioning or {}

xi.trustJobPositioning.forceReposition = function(master)
    local tank  = findPartyTank(master)
    local count = 0

    for _, member in pairs(master:getPartyWithTrusts()) do
        if not member:isPC() and not member:isDead() then
            local rule = JOB_POSITION_RULES[member:getMainJob()]
            if rule and not (tank and tank:getID() == member:getID()) then
                local target = member:getTarget()
                if target then
                    if repositionTrust(member, master, target, rule, tank, true) then
                        count = count + 1
                    end
                    member:setLocalVar('jobPosLastCheck', os.time())
                end
            end
        end
    end

    return count
end

m:addOverride('xi.trust.spawn', function(caster, spell)
    local trust = caster:spawnTrust(spell:getID())

    if trust then
        local rule = JOB_POSITION_RULES[trust:getMainJob()]
        if rule then
            trust:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.NO_MOVE)

            trust:addListener('COMBAT_TICK', 'JOB_POSITIONING_CTICK', function(mob, master, target)
                if not target then
                    return
                end

                local now = os.time()
                if now - mob:getLocalVar('jobPosLastCheck') < rule.minRepathInterval then
                    return
                end
                mob:setLocalVar('jobPosLastCheck', now)

                local tank = findPartyTank(master)

                -- Never try to reposition the trust that's actually tanking.
                if tank and tank:getID() == mob:getID() then
                    return
                end

                repositionTrust(mob, master, target, rule, tank, false)
            end)
        end
    end

    return 0
end)

return m