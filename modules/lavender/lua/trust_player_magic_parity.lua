-----------------------------------
-- Trust / Player Magic Damage Parity Module
--
-- Problem:
--   scripts/globals/spells/damage_spell.lua gates two separate pieces of the
--   magic damage formula behind `caster:isPC()`:
--
--     1. calculateBaseDamage() only allows the modern ("new system") base
--        power (vPC) and 7-bracket stat-differential scaling for PCs.
--        Every other caster (Trusts included) is forced onto the legacy
--        NPC formula: a lower base power value (vNPC) and a cruder stat
--        bonus that hard-caps at 3x the spell's inflexion point.
--
--     2. calculateIfMagicBurst() halves the per-skillchain-tier magic burst
--        bonus for non-PC casters (0.05 vs 0.10 per tier), and this gap
--        widens directly with magic burst tier.
--
--   Together, these make Trusts deal noticeably less magic damage than an
--   equivalent player, especially on magic bursts.
--
-- Fix:
--   Override both functions so that `caster:isTrust()` is treated the same
--   as `caster:isPC()` for these two checks. Every other line is an exact
--   copy of the original logic in scripts/globals/spells/damage_spell.lua -
--   only the gating condition changed. Regular Mobs, Pets, and Automatons
--   are untouched and continue to use the legacy NPC formula as before.
--
-- NOTE: If scripts/globals/spells/damage_spell.lua is ever updated upstream,
-- this module will silently keep using the copied-and-modified logic below
-- instead of picking up any changes to the original function bodies. Re-diff
-- against the current damage_spell.lua after any server update.
-----------------------------------
require('modules/module_utils')
-----------------------------------
local moduleName = 'trust_player_magic_parity'

local m = Module:new(moduleName)

-- Local copy of the column table from damage_spell.lua so indices line up.
local column =
{
    STAT_USED         =  1,
    BONUS_MACC        =  2,
    FORCE_DAY_WEATHER =  3,
    NPC_POWER         =  4,
    NPC_MULTIPLIER    =  5,
    PC_POWER          =  6,
    INFLEXION_POINT   =  7,
    MULTIPLIER_0      =  8,
    MULTIPLIER_50     =  9,
    MULTIPLIER_100    = 10,
    MULTIPLIER_200    = 11,
    MULTIPLIER_300    = 12,
    MULTIPLIER_400    = 13,
    MULTIPLIER_500    = 14,
}

-----------------------------------
-- calculateBaseDamage
-- Only change from the original: the useNewSystem check also accepts Trusts.
-----------------------------------
m:addOverride('xi.spells.damage.calculateBaseDamage', function(caster, target, spellId, spellGroup, skillType, statUsed)
    local spellDamage  = 0
    local useNewSystem = false

    -- Choose system to use. (CHANGED: also allow Trusts to use the new system.)
    if
        xi.spells.damage.pTable[spellId][column.MULTIPLIER_0] > 0 and
        (caster:isPC() or caster:isTrust()) and
        not xi.settings.main.USE_OLD_MAGIC_DAMAGE
    then
        useNewSystem = true
    end

    -----------------------------------
    -- STEP 1: baseSpellDamage (V)
    -----------------------------------
    local baseSpellDamage = xi.spells.damage.pTable[spellId][column.NPC_POWER]

    if useNewSystem then
        baseSpellDamage = xi.spells.damage.pTable[spellId][column.PC_POWER]
    end

    -----------------------------------
    -- STEP 2: statDiffBonus (statDiff * M)
    -----------------------------------
    local statDiffBonus = 0
    local statDiff      = caster:getStat(statUsed) - target:getStat(statUsed)

    if useNewSystem then
        local mTable =
        {
            [1] = {   0,  50 },
            [2] = {  50,  50 },
            [3] = { 100, 100 },
            [4] = { 200, 100 },
            [5] = { 300, 100 },
            [6] = { 400, 100 },
            [7] = { 500, 100 },
        }

        for i = 1, 7 do
            statDiffBonus = statDiffBonus + math.floor(utils.clamp(statDiff - mTable[i][1], 0, mTable[i][2]) * xi.spells.damage.pTable[spellId][column.INFLEXION_POINT + i])
        end
    else
        local spellMultiplier = xi.spells.damage.pTable[spellId][column.NPC_MULTIPLIER]
        local inflexionPoint  = xi.spells.damage.pTable[spellId][column.INFLEXION_POINT]

        local statCap = 3 * inflexionPoint

        statDiff = math.min(statDiff, statCap)

        if statDiff <= 0 then
            statDiffBonus = statDiff
        elseif statDiff <= inflexionPoint then
            statDiffBonus = math.floor(statDiff * spellMultiplier)
        else
            statDiffBonus = math.floor(inflexionPoint * spellMultiplier) + math.floor((statDiff - inflexionPoint) * spellMultiplier / 2)
        end
    end

    -----------------------------------
    -- STEP 3: baseSpellDamageBonus (mDMG)
    -- NOTE: left as caster:isPC() on purpose - these are player Job Point
    -- bonuses. getJobPointLevel() safely returns 0 for non-PC callers
    -- (see CLuaBaseEntity::getJobPointLevel), so this branch is harmless
    -- to leave untouched for Trusts; there's nothing for them to gain here
    -- unless this fork later gives Trusts their own job point levels.
    -----------------------------------
    local baseSpellDamageBonus = 0

    if caster:isPC() then
        if caster:hasStatusEffect(xi.effect.MANAFONT) then
            baseSpellDamageBonus = baseSpellDamageBonus + caster:getJobPointLevel(xi.jp.MANAFONT_EFFECT) * 3
        end

        if caster:hasStatusEffect(xi.effect.MANAWELL) then
            baseSpellDamageBonus = baseSpellDamageBonus + caster:getJobPointLevel(xi.jp.MANAWELL_EFFECT)
        end

        if caster:getMainJob() == xi.job.BLM then
            baseSpellDamageBonus = baseSpellDamageBonus + caster:getJobPointLevel(xi.jp.MAGIC_DMG_BONUS)
        end

        if skillType == xi.skill.NINJUTSU then
            baseSpellDamageBonus = baseSpellDamageBonus + caster:getJobPointLevel(xi.jp.ELEM_NINJITSU_EFFECT) * 2
        end

        if
            (spellGroup == xi.magic.spellGroup.WHITE and caster:hasStatusEffect(xi.effect.RAPTURE)) or
            (spellGroup == xi.magic.spellGroup.BLACK and caster:hasStatusEffect(xi.effect.EBULLIENCE))
        then
            baseSpellDamageBonus = baseSpellDamageBonus + caster:getJobPointLevel(xi.jp.STRATEGEM_EFFECT_III) * 2
        end
    end

    -- Bonus to spell base damage from gear (mob mods / trust-equivalent mods still apply here).
    baseSpellDamageBonus = baseSpellDamageBonus + caster:getMod(xi.mod.MAGIC_DAMAGE)

    -- Bonus to spell base damage from Cascade effect.
    if
        skillType == xi.skill.ELEMENTAL_MAGIC and
        caster:hasStatusEffect(xi.effect.CASCADE)
    then
        baseSpellDamageBonus = baseSpellDamageBonus + math.floor(caster:getTP() / 10)
    end

    -----------------------------------
    -- STEP 4: Spell Damage
    -----------------------------------
    spellDamage = baseSpellDamage + baseSpellDamageBonus + statDiffBonus

    -----------------------------------
    -- STEP 5: Exceptions
    -----------------------------------
    if spellId == xi.magic.spell.DEATH then
        spellDamage = baseSpellDamage + caster:getMP() * 3
    elseif
        (spellId >= xi.magic.spell.GEOHELIX and spellId <= xi.magic.spell.LUMINOHELIX) or
        (spellId >= xi.magic.spell.GEOHELIX_II and spellId <= xi.magic.spell.LUMINOHELIX_II)
    then
        spellDamage = spellDamage + caster:getMod(xi.mod.HELIX_EFFECT)
    elseif spellId == xi.magic.spell.KAUSTRA then
        baseSpellDamage = math.floor(caster:getMainLvl() * 0.67) / 10
        statDiffBonus   = math.floor(statDiffBonus)

        spellDamage = math.floor(baseSpellDamage * (baseSpellDamageBonus + statDiffBonus))
    end

    return utils.clamp(spellDamage, 0, 99999)
end)

-----------------------------------
-- calculateIfMagicBurst
-- Only change from the original: the countBonus check also accepts Trusts.
-----------------------------------
m:addOverride('xi.spells.damage.calculateIfMagicBurst', function(caster, target, spellElement, magicBurstTier)
    if spellElement <= xi.element.NONE then
        return 1
    end

    local rankTable  = { 1.5, 1.15, 0.85, 0.6, 0.5, 0.4, 0.15, 0.05, 0, 0, 0, 0, 0, 0, 0 }

    local resistRank = utils.clamp(target:getMod(xi.data.element.getElementalResistanceRankModifier(spellElement)), -3, 11) + 4
    local countBonus = (caster:isPC() or caster:isTrust()) and 0.1 or 0.05
    local magicBurst = 1.25 + rankTable[resistRank] + countBonus * magicBurstTier

    if target:getMod(xi.mod.SENGIKORI_MB_DMG_DEBUFF) > 0 then
        magicBurst = magicBurst + target:getMod(xi.mod.SENGIKORI_MB_DMG_DEBUFF) / 100
        target:setMod(xi.mod.SENGIKORI_MB_DMG_DEBUFF, 0)
    end

    return magicBurst
end)

return m
