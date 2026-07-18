-----------------------------------
-- modules/custom/lua/signet_conquest_bonus.lua
--
-- Makes the Signet buff itself boost Conquest Points earned from exp,
-- turning the core's 10% (nation owns region) / 15% (region not owned)
-- into 50% / 55% for as long as Signet is active.
--
-- How it works:
--   conquest_system.cpp::AddConquestPoints already computes:
--     percentage = (owned ? 0.10 : 0.15) + getMod(Mod::CONQUEST_BONUS) / 100.0
--   Mod::CONQUEST_BONUS is a normal entity modifier -- nothing currently
--   grants it. We add it directly to the Signet effect's onEffectGain/
--   onEffectLose, the same way the base effect already grants/removes
--   its DEF and EVA latents. No timers, no polling, no core edits.
-----------------------------------
require('modules/module_utils')
-----------------------------------
local m = Module:new('signet_conquest_bonus')

-- +40 brings the core's 10%/15% up to 50%/55%.
-- (Change this single value to tune the bonus.)
local CONQUEST_BONUS_AMOUNT = 90

m:addOverride('xi.effects.signet.onEffectGain', function(target, effect)
    super(target, effect)

    target:addMod(xi.mod.CONQUEST_BONUS, CONQUEST_BONUS_AMOUNT)
end)

m:addOverride('xi.effects.signet.onEffectLose', function(target, effect)
    super(target, effect)

    target:delMod(xi.mod.CONQUEST_BONUS, CONQUEST_BONUS_AMOUNT)
end)

return m
