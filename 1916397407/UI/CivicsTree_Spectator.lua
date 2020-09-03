-- ===========================================================================
--	CivicsTree Replacement
--	Civilization VI, Firaxis Games
-- ===========================================================================
include("CivicsTree_Expansion2.lua");

-- ===========================================================================
--	Add to base tables
-- ===========================================================================
local XP2_GetCurrentData = GetCurrentData;


-- ===========================================================================
--	OVERRIDE BASE FUNCTIONS
-- ===========================================================================

-- ===========================================================================
--	Fill out live data from base game and then add IsRevealed to items.
-- ===========================================================================
function GetCurrentData( ePlayer:number  )
	local iPlayer = ePlayer
	local bspec = false
	local spec_ID = 0
	if (Game:GetProperty("SPEC_NUM") ~= nil) then
		for k = 1, Game:GetProperty("SPEC_NUM") do
			if ( Game:GetProperty("SPEC_ID_"..k)~= nil) then
				if Game.GetLocalPlayer() == Game:GetProperty("SPEC_ID_"..k) then
					bspec = true
					spec_ID = k
				end
			end
		end
	end
	if (bspec == true) then
		if (bspec == true) then
			if ( GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID) ~= nil and GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID) ~= 1000) then
				iPlayer = GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID)
			end
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

LuaEvents.DiplomacyRibbon_Click.Add( GetCurrentData );