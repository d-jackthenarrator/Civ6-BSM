-- ===========================================================================
--	HUD Partial Screen Hooks BSM
--	Hooks to buttons in the upper right of the main screen HUD.
--	MyScreen left in as sample to wire up subsequent screens.
-- ===========================================================================

local m_isCityStatesUnlocked = false
local m_isEspionageUnlocked = false
-- ===========================================================================
-- INCLUDE XP2 FILE
-- ===========================================================================
include("PartialScreenHooks_Expansion2");
print("PartialScreenHooks for Better Spectator Mod")

BASE_Initialize			= Initialize;
BASE_AddCityStateHook		= AddCityStateHook;
BASE_OnDiplomacyMeet		= OnDiplomacyMeet;
BASE_AddEspionageHook		= AddEspionageHook;
-- ===========================================================================
--	Overrides
-- ===========================================================================

-- ===========================================================================
function AddCityStateHook()


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
			AddScreenHook("CityStates", "LaunchBar_Hook_CityStates", "LOC_PARTIALSCREEN_CITYSTATES_TOOLTIP", OnToggleCityStates );
			return
		end


	BASE_AddCityStateHook()

end

function AddEspionageHook()
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
			AddScreenHook("EspionageOverview", "LaunchBar_Hook_Espionage", "LOC_PARTIALSCREEN_ESPIONAGE_TOOLTIP", OnToggleEspionage );
			return
	end

	BASE_AddEspionageHook()

end

function OnDiplomacyMeet(player1ID:number, player2ID:number)
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
			return
	end

	BASE_OnDiplomacyMeet(player1ID, player2ID)

end



function OnTurnBegin()
	local ePlayer:number = Game.GetLocalPlayer();
	--if ePlayer == -1 then
	--	return;
	--end
	pLocalPlayer = Players[ePlayer];  



	CheckTradeCapacity(pLocalPlayer);
	CheckSpyCapacity(pLocalPlayer);
	CheckCityStatesUnlocked(pLocalPlayer);

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
	if bspec == true then
		--print("Spectator Detected")
		m_isCityStatesUnlocked = true;
		m_isEspionageUnlocked = true;
	end

	Realize();

end

function Initialize()
	BASE_Initialize();

	Events.TurnBegin.Add( OnTurnBegin );
end
Initialize()
