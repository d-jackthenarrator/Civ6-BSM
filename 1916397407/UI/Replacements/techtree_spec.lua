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
--	CAHED FUNCTION
-- ===========================================================================

local XP2_GetCurrentData = GetCurrentData;
local XP2_LateInitialize = LateInitialize;
local XP2_OnShutdown = OnShutdown;

-- ===========================================================================
-- LOCALS
-- ===========================================================================
local m_bspec:boolean	 = false;
local m_kMarkerIM			:table = InstanceManager:new( "PlayerMarkerInstance",	"Top",		Controls.TimelineScrollbar );

local m_ePlayer				:number= -1;
local m_kCurrentData		:table = {};				-- Current set of data.


-- ===========================================================================
-- Overrides
-- ===========================================================================
function GetCurrentData( ePlayer:number, eCompletedTech:number )
	local localPlayerID = Game.GetLocalPlayer()
	

	if (m_bspec == true) and localPlayerID ~= nil then
		if ( GameConfiguration.GetValue("OBSERVER_ID_"..localPlayerID) ~= nil and GameConfiguration.GetValue("OBSERVER_ID_"..localPlayerID) ~= 1000)  and GameConfiguration.GetValue("OBSERVER_ID_"..localPlayerID) ~= -1) then
			ePlayer = GameConfiguration.GetValue("OBSERVER_ID_"..localPlayerID)
		end
	end

	local kData:table = XP2_GetCurrentData(ePlayer, eCompletedTech );

	return kData;
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
	
	LuaEvents.DiplomacyRibbon_Click.Add( OnDiplomacyClick );
	Events.GameCoreEventPublishComplete.Add ( OnDiplomacyClick );
	
end

function OnShutdown()
	
	XP2_OnShutdown()
	
	LuaEvents.DiplomacyRibbon_Click.Remove( OnDiplomacyClick );
	Events.GameCoreEventPublishComplete.Remove ( OnDiplomacyClick );
	
end

-- ===========================================================================
-- New Function
-- ===========================================================================

function OnDiplomacyClick()
	local localPlayerID = Game.GetLocalPlayer()
	if (m_bspec == true) and localPlayerID ~= nil then

			if ( GameConfiguration.GetValue("OBSERVER_ID_"..localPlayerID ) ~= nil and GameConfiguration.GetValue("OBSERVER_ID_"..localPlayerID ) ~= 1000 and GameConfiguration.GetValue("OBSERVER_ID_"..localPlayerID ) ~= m_ePlayer) then
				debugShowAllMarkers		= true;
				LateInitialize()
				m_ePlayer = GameConfiguration.GetValue("OBSERVER_ID_"..localPlayerID );
				Resize();
				m_kCurrentData = GetCurrentData( m_ePlayer );
				View( m_kCurrentData );
			end
	end	
end