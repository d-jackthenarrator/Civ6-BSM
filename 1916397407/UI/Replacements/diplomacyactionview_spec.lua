-- Copyright 2018, Firaxis Games

-- ===========================================================================
--	INCLUDE XP2 Functionality
-- ===========================================================================
include("DiplomacyActionView_Expansion2.lua");

print("Diplomacy ActionView for Better Spectator")
-- ===========================================================================
--	CACHE FUNCTIONS
--	Do not make cache functions local so overriden functions can check these names.
-- ===========================================================================
BASE_OnDiplomacyStatement = OnDiplomacyStatement;

-- ===========================================================================
--	CONSTANTS
-- ===========================================================================

-- ===========================================================================
function OnDiplomacyStatement(fromPlayer : number, toPlayer : number, kVariants : table)
	local bspec = false
	local tospec = false
	if Game.GetLocalPlayer() == -1 or Game.GetLocalPlayer() == nil or fromPlayer == nil or toPlayer == nil then
		return
	end

	if PlayerConfigurations[fromPlayer] ~= nil then
		if PlayerConfigurations[fromPlayer]:GetLeaderTypeName() == "LEADER_SPECTATOR" then
			bspec = true
		end
	end
	
	if PlayerConfigurations[toPlayer] ~= nil then
		if PlayerConfigurations[toPlayer]:GetLeaderTypeName() == "LEADER_SPECTATOR" then
			tospec = true
		end
	end
	
	if (tospec == true) then
		if (Players[fromPlayer]:IsAlive()) then
			print("Killed an AI pop-up!")
			DiplomacyManager.CloseSession( kVariants.SessionID );
			return;
		end
	end	
	
	if (bspec == true) then
		if (Players[toPlayer]:IsHuman() == true) then
			print("Killed an AI pop-up!")
			DiplomacyManager.CloseSession( kVariants.SessionID );
			return;
		end
	end	

	BASE_OnDiplomacyStatement(fromPlayer,toPlayer,kVariants)
	
end
