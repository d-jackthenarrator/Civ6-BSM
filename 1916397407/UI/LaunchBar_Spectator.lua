-- ===========================================================================
--	HUD's Launch Bar XP2
--	Copyright (c) 2018-2019 Firaxis Games
-- ===========================================================================

include("LaunchBar_Expansion2");
print("LaunchBar for BSM")

------------------------------------------------------------

local m_GovernorsInstance		:table = {};
local m_HistorianInstance		:table = {};

------------------------------------------------------------

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
		if (bspec == true) then
			if ( GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID) == nil or GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID) == 1000 or GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID) == Game.GetLocalPlayer()) then
				Controls.GovernmentButton:SetHide(true);
				Controls.GovernmentBolt:SetHide(true);
				Controls.GreatWorksBolt:SetHide(true);
				Controls.GreatWorksButton:SetHide(true);
				else
				Controls.GovernmentButton:SetHide(false);
				Controls.GovernmentBolt:SetHide(false);
				Controls.GreatWorksBolt:SetHide(false);
				Controls.GreatWorksButton:SetHide(false);
			end
		end
	end
end

LuaEvents.DiplomacyRibbon_Click.Add( OnDiplomacyClick );
 Events.GameCoreEventPublishComplete.Add ( OnDiplomacyClick );