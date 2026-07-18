-- modules/custom/lua/apururu_custom_behavior.lua
require("modules/module_utils")

local m = Module:new("trust_danica")

m:addOverride("xi.actions.spells.trust.lhe_lhangavo.onMobSpawn", function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)
	
    local lvl = mob:getMainLvl()	
	
	mob:setMobMod(xi.mobMod.H2H_SINGLE_SWING, 1)
	
    if lvl >= 35 then		
		mob:addGambit(ai.t.SELF, { ai.c.HPP_LT, 50 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.CHAKRA })	
	end

    if lvl >= 25 then
		mob:addGambit(ai.t.SELF, { ai.c.ALWAYS, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.FOCUS })
    end

    if lvl >= 30 then
        mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.BERSERK }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BERSERK })
    end	
	
    if lvl >= 70 then
        mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.WARCRY }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.WARCRY })
    end
	
    if lvl >= 5 then		
		mob:addGambit(ai.t.SELF, { ai.c.ALWAYS, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BOOST })
	end	

    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 3000)
	
end)

return m