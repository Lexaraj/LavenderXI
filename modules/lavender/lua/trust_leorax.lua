-- modules/custom/lua/apururu_custom_behavior.lua
require("modules/module_utils")

local m = Module:new("trust_leorax")

m:addOverride("xi.actions.spells.trust.maximilian.onMobSpawn", function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:addMobMod(xi.mobMod.CAN_PARRY, 3)
    mob:setMobMod(xi.mobMod.DUAL_WIELD, 0)

    local lvl = mob:getMainLvl()

    if lvl >= 24 then
		mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.COPY_IMAGE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.UTSUSEMI_ICHI })
	end

    if lvl >= 5 then
        mob:addGambit(ai.t.TARGET, { ai.c.NOT_PT_HAS_TANK, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.PROVOKE })
    end
	
    if lvl >= 15 then
        mob:addGambit(ai.t.SELF, { { ai.c.PT_HAS_TANK, 0 }, { ai.c.NOT_STATUS, xi.effect.BERSERK } }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BERSERK })
    end	

    if lvl >= 24 then
        mob:addGambit(ai.t.SELF, { { ai.c.NOT_PT_HAS_TANK, 0 }, { ai.c.NOT_STATUS, xi.effect.BERSERK } }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BERSERK })
    end

    if lvl >= 35 then
        mob:addGambit(ai.t.SELF, { { ai.c.ALWAYS, 0 }, { ai.c.NOT_STATUS, xi.effect.WARCRY } }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.WARCRY })
    end

    mob:addGambit(ai.t.TARGET,  { ai.c.NOT_HAS_TOP_ENMITY, 0 }, { ai.r.MA, ai.s.HIGHEST,  xi.magic.spellFamily.HOJO     }, 30)
    mob:addGambit(ai.t.TARGET,  { ai.c.NOT_HAS_TOP_ENMITY, 0 }, { ai.r.MA, ai.s.HIGHEST,  xi.magic.spellFamily.KURAYAMI }, 30)


    mob:setTrustTPSkillSettings(ai.tp.OPENER, ai.s.HIGHEST)

    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)	
	
end)

return m