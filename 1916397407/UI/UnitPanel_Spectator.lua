-- ===========================================================================
--	Copyright (c) 2018 Firaxis Games
-- ===========================================================================

-- ===========================================================================
-- INCLUDE XP2 FILE
-- ===========================================================================
include("UnitPanel_Expansion2");
print("UnitPanel for BSM")
g_isOkayToProcess = true;

function OnPlayerTurnDeactivated( ePlayer:number )
	if ePlayer == Game.GetLocalPlayer() then		
		g_isOkayToProcess = false;
	end
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
		g_isOkayToProcess = true;
	end

end


