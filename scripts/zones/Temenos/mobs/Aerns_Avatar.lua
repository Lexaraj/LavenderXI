-----------------------------------
-- Area: Temenos
--  Mob: Aerns_Avatar
-----------------------------------
---@type TMobEntity
local entity = {}

entity.onMobSpawn = function(mob)
    mob:addImmunity(xi.immunity.STUN)
end

return entity
