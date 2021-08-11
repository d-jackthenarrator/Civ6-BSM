-- ===========================================================================
--	CivicsTree Replacement
--	Civilization VI, Firaxis Games
-- ===========================================================================
include("CivicsTree_Expansion2.lua");

-- ===========================================================================
--	Add to base tables
-- ===========================================================================
local XP2_GetCurrentData = GetCurrentData;
local XP2_LateInitialize = LateInitialize;
local XP2_OnShutdown = OnShutdown;

-- ===========================================================================
-- LOCALS
-- ===========================================================================
local m_bspec:boolean	 = false;


-- ===========================================================================
--	OVERRIDE BASE FUNCTIONS
-- ===========================================================================

-- ===========================================================================
--	Fill out live data from base game and then add IsRevealed to items.
-- ===========================================================================
function GetCurrentData( ePlayer:number  )

	local localPlayerID = Game.GetLocalPlayer()
	

	if (m_bspec == true) and localPlayerID ~= nil then
		if ( GameConfiguration.GetValue("OBSERVER_ID_"..localPlayerID) ~= nil and GameConfiguration.GetValue("OBSERVER_ID_"..localPlayerID) ~= 1000)  and GameConfiguration.GetValue("OBSERVER_ID_"..localPlayerID) ~= -1) then
			iPlayer = GameConfiguration.GetValue("OBSERVER_ID_"..localPlayerID)
		end
	end


	local kData:table = XP2_GetCurrentData(iPlayer);

	-- Loop through all items and add an IsRevealed field.	
	local pPlayerCultureManager:table = Players[iPlayer]:GetCulture();
	if (pPlayerCultureManager ~= nil) then
		for type,item in pairs(g_kItemDefaults) do
			kData[DATA_FIELD_LIVEDATA][type]["IsRevealed"] = pPlayerCultureManager:IsCivicRevealed(item.Index);
		end
	end
	return kData;
end

function OnShutdown()
	
	XP2_OnShutdown()
	
	LuaEvents.DiplomacyRibbon_Click.Remove( GetCurrentData );
	
end


function LateInitialize()
	
	XP2_LateInitialize()
	
	if Game.GetLocalPlayer() == -1 or Game.GetLocalPlayer() == nil then
		return
	end

	if PlayerConfigurations[Game.GetLocalPlayer()] ~= nil then
		if PlayerConfigurations[Game.GetLocalPlayer()]:GetLeaderTypeName() == "LEADER_SPECTATOR" then
			m_bspec = true
		end
	end
	
	LuaEvents.DiplomacyRibbon_Click.Add( GetCurrentData );
	
end