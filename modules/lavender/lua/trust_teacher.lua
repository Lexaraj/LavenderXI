-- modules/custom/lua/trust_teacher.lua
require("modules/module_utils")
require('scripts/zones/Port_Jeuno/Zone')

local m = Module:new("trust_teacher")

-- List the Trust spell IDs you want this NPC to grant.
-- (Trust spell IDs are the same ones used in xi.magic / mob_spell_lists;
--  e.g. Shantotto = 896, Ajido-Marujido = 904, etc.)
local TRUSTS_TO_TEACH = {
    964,
    910,
	977,
	917,
	1005,
	955,
	975,
}

local function onTrigger(player, npc)
    local missing = {}

    for _, spellId in ipairs(TRUSTS_TO_TEACH) do
        if not player:hasSpell(spellId) then
            table.insert(missing, spellId)
        end
    end

    if #missing == 0 then
        player:PrintToPlayer("You already know all the Trusts I have to teach.", 0, npc:getPacketName())
        return
    end

    for _, spellId in ipairs(missing) do
        player:addSpell(spellId, true, true)
        player:messageSpecial(ID.text.YOU_LEARNED_TRUST, 0, spellId)
    end
end

m:addOverride('xi.zones.Port_Jeuno.Zone.onInitialize', function(zone)
    super(zone)
    zone:insertDynamicEntity({
        objtype  = xi.objType.NPC,
        name     = 'Scouting Moogle',
        look     = 981,
        x        = -183.93,
        y        = -5,
        z        = -3.85,
        rotation = 320,
        widescan = 0,
        onTrigger = onTrigger
	})	
end)

return m