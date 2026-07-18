-----------------------------------
-- Trusts count toward exp party-split (alliance-wide)
-----------------------------------
require('modules/module_utils')
-----------------------------------
local m = Module:new('trust_exp_split')

m:addOverride('xi.mob.onMobDeathEx', function(mob, player, isKiller, isWeaponSkillKill)
    super(mob, player, isKiller, isWeaponSkillKill)

    if isKiller then
        local trustCount = 0
        local seenIDs = {}

        for _, member in pairs(player:getPartyWithTrusts()) do
            if member:isTrust() then
                local id = member:getID()

                if not seenIDs[id] then
                    seenIDs[id] = true
                    trustCount = trustCount + 1
                end
            end
        end

        if player:getAllianceSize() > 1 then
            for _, allianceMember in pairs(player:getAlliance()) do
                for _, member in pairs(allianceMember:getPartyWithTrusts()) do
                    if member:isTrust() then
                        local id = member:getID()

                        if not seenIDs[id] then
                            seenIDs[id] = true
                            trustCount = trustCount + 1
                        end
                    end
                end
            end
        end

        if trustCount > 0 then
            mob:addExpPartySize(trustCount)
        end
    end
end)

return m