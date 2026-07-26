-- modules/custom/lua/apururu_custom_behavior.lua
require("modules/module_utils")

local m = Module:new("trust_gandus")

m:addOverride("xi.actions.spells.trust.robel-akbel.onMobSpawn", function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)
	
	mob:addMod(xi.mod.MPP, 20)
	
    mob:addGambit(ai.t.TARGET, { ai.c.MB_AVAILABLE, 0 }, { ai.r.MA, ai.s.MB_ELEMENT, xi.magic.spellFamily.NONE })

    mob:addGambit(ai.t.TARGET, { ai.c.NOT_SC_AVAILABLE, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.NONE }, 20)

	mob:setMobMod(xi.mobMod.TRUST_NO_IDLE_GAMBITS, 1)

    mob:setAutoAttackEnabled(false)

end)

return m