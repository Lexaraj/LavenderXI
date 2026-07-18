#include "map/utils/moduleutils.h"

#include "entities/mob_entity.h"
#include "lua/lua_base_entity.h"

#include <algorithm>

class TrustExpSplitModule : public CPPModule
{
    // mob:addExpPartySize(amount)
    static void addExpPartySize(CLuaBaseEntity* PLuaBaseEntity, uint8 amount)
    {
        CBaseEntity* PEntity = PLuaBaseEntity->GetBaseEntity();

        if (auto* PMob = dynamic_cast<CMobEntity*>(PEntity))
        {
            PMob->m_HiPartySize = static_cast<uint8>(std::min<int>(255, PMob->m_HiPartySize + amount));
        }
    }

    void OnInit() override
    {
        lua["CBaseEntity"]["addExpPartySize"] = &TrustExpSplitModule::addExpPartySize;
    }
};

REGISTER_CPP_MODULE(TrustExpSplitModule);