-- modules/custom/always_pop_lottery_nm.lua
require("scripts/globals/mobs")

local m = Module:new("always_pop_lottery_nm")

m:addOverride("xi.mob.phOnDespawn", function(ph, nmId, chance, cooldown, params)
    -- Force every lottery-spawn roll to succeed
    return super(ph, nmId, 100, cooldown, params)
end)

return m