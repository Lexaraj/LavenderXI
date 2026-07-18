require("modules/module_utils")
require("scripts/globals/conquest")

local m = Module:new("trust_conquest_influence")

m:addOverride("xi.mob.onMobDeath", function(mob, player, optParams)
    -- Run the original onMobDeath logic first
    super(mob, player, optParams)

--    -- Only act when the killer is a player character
--    if not player or not player:isPC() then
--        return
--    end

    -- Skip if in a zone where conquest doesn't apply (cities, etc.)
    local region = mob:getRegionID()
    if region == xi.region.UNKNOWN then
        return
    end

    -- Get the full party including trusts
    local partyWithTrusts = player:getPartyWithTrusts()

    -- Count how many trusts are present
    local trustCount = 0
    for _, member in pairs(partyWithTrusts) do
        if member:isTrust() then
            trustCount = trustCount + 1
        end
    end

    if trustCount == 0 then
        return
    end

    -- Calculate influence to award.
    -- The normal flow gives roughly (expValue * 0.1 * 0.5) influence per kill.
    -- We use a smaller flat contribution per trust so it feels proportional
    -- but doesn't overpower the system. Tune this number to your liking.
    local expReward = mob:getExp()
    local influencePerTrust = math.floor(expReward * 1.0)  -- 10% of mob EXP per trust
    local totalTrustInfluence = influencePerTrust * trustCount

    if totalTrustInfluence <= 0 then
        return
    end

    -- Award influence for the player's nation only — no conquest points
    xi.conquest.addInfluencePoints(totalTrustInfluence, player:getNation(), region)
end)

return m