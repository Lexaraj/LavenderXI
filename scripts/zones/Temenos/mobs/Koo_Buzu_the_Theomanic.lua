-----------------------------------
-- Area: Temenos (Central Temenos 4th Floor)
--  Mob: Koo Buzu the Theomanic
-----------------------------------
mixins = { require('scripts/mixins/job_special') }
-----------------------------------
---@type TMobEntity
local entity = {}

local callPetParams =
{
    dieWithOwner = true,
    superLink = true,
    inactiveTime = 3000,
    maxSpawns = 1,
}

entity.onMobInitialize = function(mob)
    xi.pet.setMobPet(mob, 1, 'Yagudos_Elemental')
    mob:setMobMod(xi.mobMod.ASTRAL_PET_OFFSET, 2)
end

entity.onMobSpawn = function(mob)
    mob:setMobMod(xi.mobMod.BASE_DAMAGE_MULTIPLIER, 200)

    mob:setMod(xi.mod.REGAIN, 150)

    mob:setMod(xi.mod.PARALYZE_RES_RANK, 4)
    mob:setMod(xi.mod.BIND_RES_RANK, 4)
    mob:setMod(xi.mod.SILENCE_RES_RANK, 4)
    mob:setMod(xi.mod.SLOW_RES_RANK, 4)
    mob:setMod(xi.mod.POISON_RES_RANK, 4)
    mob:setMod(xi.mod.LIGHT_SLEEP_RES_RANK, 4)
    mob:setMod(xi.mod.DARK_SLEEP_RES_RANK, 4)
    mob:setMod(xi.mod.BLIND_RES_RANK, 4)

    mob:timer(10000, function(mobArg)
        xi.mob.callPets(mobArg, mobArg:getID() + 1, callPetParams)
    end)
end

return entity
