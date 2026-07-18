-----------------------------------
-- Trust AoE Song Range Fix
--
-- Problem:
--   Self-centered AoE Bard songs (Minuets, Madrigals, Marches, Minnes,
--   Mambos, Preludes, Auras, etc.) are supposed to only affect party/
--   alliance members standing within the spell's AoE radius of the
--   caster. Real players are correctly range-checked by the engine
--   (CTargetFind::validEntity, src/map/ai/helpers/targetfind.cpp), but
--   Trusts are waved through unconditionally as long as they share the
--   caster's allegiance - regardless of how far away they actually are.
--
-- Fix:
--   Every Bard enhancing song funnels through the single shared
--   function xi.spells.enhancing.useEnhancingSong(caster, target, spell),
--   which is called once per resolved AoE target (see
--   CBattleEntity::SpellFinished in src/map/entities/battle_entity.cpp).
--   This module overrides that one shared function and adds a distance
--   check that only applies to Trust targets (real players already went
--   through a correct check, so they're left alone). If a Trust is
--   outside the spell's actual radius, the song is treated as having no
--   effect on it - same message the game already uses when a song
--   doesn't take (see the original function's own "no effect" case).
--
--   This is a pure Lua module: no engine/core files are touched, and it
--   doesn't duplicate or reimplement any of the song potency/duration
--   math, so it can't drift out of sync with that logic upstream.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/spells/enhancing_song')
-----------------------------------
local m = Module:new('trust_aoe_song_range_fix')

m:addOverride('xi.spells.enhancing.useEnhancingSong', function(caster, target, spell)
    -- Only step in for Trusts on AoE songs; everything else keeps
    -- retail/original behavior untouched.
    if
        target:isTrust() and
        spell:isAoE() > 0 and
        caster:checkDistance(target) > spell:getRadius()
    then
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
        return 0
    end

    return super(caster, target, spell)
end)

return m