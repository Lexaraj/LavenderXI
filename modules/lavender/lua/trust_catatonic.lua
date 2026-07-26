-- modules/custom/lua/apururu_custom_behavior.lua
require("modules/module_utils")

local m = Module:new("trust_catatonic")

m:addOverride("xi.actions.spells.trust.iron_eater.onMobSpawn", function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)	

    local lvl = mob:getMainLvl()
	
    if lvl >= 10 then
		mob:addGambit(ai.t.MASTER, { ai.c.HPP_LT, 50 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.PROVOKE })
    end
	
    if lvl >= 15 then
        mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.BERSERK }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BERSERK })
    end	
	
    if lvl >= 35 then
        mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.WARCRY }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.WARCRY })
    end

    if lvl >= 45 then
        mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.AGGRESSOR }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.AGGRESSOR })
    end	

    if lvl >= 50 then
        mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.HASSO }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.HASSO })
    end	

    if lvl >= 60 then
        mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.MEDITATE }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.MEDITATE })
    end	
	
    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 3000)

	mob:setMobMod(xi.mobMod.TRUST_NO_IDLE_GAMBITS, 1)

	mob:setAutoAttackEnabled(true)
	

	
end)

return m