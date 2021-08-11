-- ===========================================================================
--	HUD's Launch Bar XP2
--	Copyright (c) 2018-2019 Firaxis Games
-- ===========================================================================

include("LaunchBar_Expansion2");
print("LaunchBar for BSM")


local XP2_Unsubscribe = Unsubscribe
local XP2_Subscribe = Subscribe
------------------------------------------------------------

local m_GovernorsInstance		:table = {};
local m_HistorianInstance		:table = {};

------------------------------------------------------------

function OnDiplomacyClick()
	if Game.GetLocalPlayer() == -1 or Game.GetLocalPlayer() == nil then
		return
	end

	if PlayerConfigurations[Game.GetLocalPlayer()] ~= nil then
		if PlayerConfigurations[Game.GetLocalPlayer()]:GetLeaderTypeName() == "LEADER_SPECTATOR" then
			m_bspec = true
		end
	end
	
	if (m_bspec ==  true) then
			if ( GameConfiguration.GetValue("OBSERVER_ID_"..Game.GetLocalPlayer()) == nil or GameConfiguration.GetValue("OBSERVER_ID_"..Game.GetLocalPlayer()) == 1000 or GameConfiguration.GetValue("OBSERVER_ID_"..Game.GetLocalPlayer()) == Game.GetLocalPlayer()) then
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

function Subscribe()
XP2_Subscribe()
LuaEvents.DiplomacyRibbon_Click.Add( OnDiplomacyClick );
Events.GameCoreEventPublishComplete.Add ( OnDiplomacyClick );
end

function Unsubscribe()
XP2_Unsubscribe()
LuaEvents.DiplomacyRibbon_Click.Remove( OnDiplomacyClick );
Events.GameCoreEventPublishComplete.Remove ( OnDiplomacyClick );
end