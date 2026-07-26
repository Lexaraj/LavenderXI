-- modules/custom/lua/apururu_custom_behavior.lua
require("modules/module_utils")

local m = Module:new("trust_adrius")

m:addOverride("xi.actions.spells.trust.valaineral.onMobSpawn", function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

	mob:setMobMod(xi.mobMod.CAN_SHIELD_BLOCK, 1)
    mob:setMobMod(xi.mobMod.CAN_PARRY, 3)

    local lvl = mob:getMainLvl()
    local shieldMasteryPower = 0

	if lvl >= 75 then
        shieldMasteryPower = 30
    elseif lvl >= 50 then
        shieldMasteryPower = 20
    elseif lvl >= 25 then
        shieldMasteryPower = 10
    end

    mob:setMod(xi.mod.SHIELD_MASTERY_TP, shieldMasteryPower)
    mob:setMod(xi.mod.SHIELDBLOCKRATE, 35)

    mob:addGambit(ai.t.SELF,   { ai.c.HPP_LT, 75 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })
    mob:addGambit(ai.t.PARTY,  { ai.c.HPP_LT, 50 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })
    mob:addGambit(ai.t.PARTY,  { ai.c.STATUS, xi.effect.SLEEP_I  }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURE })
	
    if lvl >= 10 then
        mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.PROVOKE })
    end

    if lvl >= 15 then	
		mob:addGambit(ai.t.TARGET, { ai.c.READYING_WS, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SHIELD_BASH })
		mob:addGambit(ai.t.TARGET, { ai.c.READYING_MS, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SHIELD_BASH })
		mob:addGambit(ai.t.TARGET, { ai.c.READYING_JA, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SHIELD_BASH })
		mob:addGambit(ai.t.TARGET, { ai.c.CASTING_MA,  0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SHIELD_BASH })
	end

    if lvl >= 30 then
        mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.SENTINEL }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SENTINEL })
    end

    if lvl >= 37 then
		   mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.FLASH    }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.FLASH      })
	end

	if lvl >= 61 then
		mob:addGambit(ai.t.SELF,   { ai.c.NOT_STATUS, xi.effect.REPRISAL }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.REPRISAL   })
	end
	
    if lvl >= 70 then
        mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.DEFENDER }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.DEFENDER })
    end	

    mob:setTrustTPSkillSettings(ai.tp.OPENER, ai.s.HIGHEST)

    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
	
	mob:setMobMod(xi.mobMod.TRUST_NO_IDLE_GAMBITS, 1)

	mob:setAutoAttackEnabled(true)	
	
end)

return m