-- ===========================================================================
--	TechTree Replacement
--	Civilization VI, Firaxis Games
-- ===========================================================================
include("TechTree_Expansion2");
print("TechTree For Better Spectator Mod")
-- ===========================================================================
--	GLOBALS
--	May be augmented or redefinied in a MOD's replacement file(s).
-- ===========================================================================
DATA_FIELD_PLAYERINFO	= "_PLAYERINFO";-- Holds a table with summary information on that player.


-- ===========================================================================
--	MEMBERS / VARIABLES
-- ===========================================================================
local m_kMarkerIM			:table = InstanceManager:new( "PlayerMarkerInstance",	"Top",		Controls.TimelineScrollbar );

local m_ePlayer				:number= -1;
local m_kCurrentData		:table = {};				-- Current set of data.


XP2_GetCurrentData = GetCurrentData

-- ===========================================================================
-- Overrides
-- ===========================================================================
function GetCurrentData( ePlayer:number, eCompletedTech:number )
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

			if ( GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID) ~= nil and GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID) ~= 1000) then
				ePlayer = GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID);
			end

	end

	local kData:table = XP2_GetCurrentData(ePlayer, eCompletedTech );

	return kData;
end


function OnDiplomacyClick()
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

			if ( GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID) ~= nil and GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID) ~= 1000 and GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID) ~= m_ePlayer) then
				debugShowAllMarkers		= true;
				LateInitialize()
				m_ePlayer = GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID);
				Resize();
				m_kCurrentData = GetCurrentData( m_ePlayer );
				View( m_kCurrentData );
			end

	end
	
end

LuaEvents.DiplomacyRibbon_Click.Add( OnDiplomacyClick );
Events.GameCoreEventPublishComplete.Add ( OnDiplomacyClick );