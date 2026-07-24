-----------------------------------
-- func: trustposition
-- desc: Forces your trusts to immediately reposition per job-position rules.
--
-- Usage:
-- !trustposition
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = ''
}

commandObj.onTrigger = function(player)
    if not xi.trustJobPositioning then
        player:printToPlayer('Trust job positioning module is not loaded.')
        return
    end

    local count = xi.trustJobPositioning.forceReposition(player)

    if count > 0 then
        player:printToPlayer(string.format('Repositioned %d trust(s).', count))
    else
        player:printToPlayer('No engaged trusts needed repositioning.')
    end
end

return commandObj