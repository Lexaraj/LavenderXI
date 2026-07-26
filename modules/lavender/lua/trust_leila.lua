-- modules/custom/lua/apururu_custom_behavior.lua
require("modules/module_utils")

local m = Module:new("trust_leila")

m:addOverride("xi.actions.spells.trust.ayame_uc.onMobSpawn", function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)
	
    local lvl = mob:getMainLvl()
	
    if lvl >= 25 then	
		mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.HASSO }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.HASSO })	
	end
	
    if lvl >= 15 then		
		mob:addGambit(ai.t.SELF, { ai.c.HAS_TOP_ENMITY, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.THIRD_EYE })
	end

    if lvl >= 30 then	
		mob:addGambit(ai.t.SELF, { ai.c.TP_LT, 1000 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.MEDITATE })
	end

    if lvl >= 30 then		
		mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BERSERK })
	end

    if lvl >= 70 then	
		mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.WARCRY })
	end

    mob:setTrustTPSkillSettings(ai.tp.OPENER, ai.s.HIGHEST)

	mob:setMobMod(xi.mobMod.TRUST_NO_IDLE_GAMBITS, 1)
	
	mob:setAutoAttackEnabled(true)
	
end)

return m