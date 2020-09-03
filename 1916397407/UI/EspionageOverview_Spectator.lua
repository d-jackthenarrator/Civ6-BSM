--[[
-- Created by Keaton VanAuken on Nov 29 2017
-- Copyright (c) Firaxis Games
--]]
-- ===========================================================================
-- INCLUDE BASE FILE
-- ===========================================================================
include("EspionageOverview_Expansion1");
print("EspionageOverview for BSM")

-- Cached functions

BASE_RefreshOperatives = RefreshOperatives
BASE_RefreshMissionHistory = RefreshMissionHistory
BASE_PopulateTabs = PopulateTabs

-- ===========================================================================
--	MEMBERS
-- ===========================================================================

local m_AnimSupport:table; -- AnimSidePanelSupport

local m_OperativeIM:table		= InstanceManager:new("OperativeInstance", "Top", Controls.OperativeStack);
local m_CityIM:table			= InstanceManager:new("CityInstance", "CityGrid", Controls.CityActivityStack);
local m_CityDistrictIM:table	= InstanceManager:new("CityDistrictInstance", "DistrictIcon");
local m_EnemyOperativeIM:table	= InstanceManager:new("EnemyOperativeInstance", "GridButton", Controls.CapturedEnemyOperativeStack);
local m_MissionHistoryIM:table	= InstanceManager:new("MissionHistoryInstance", "Top", Controls.MissionHistoryStack);

-- A table of tabs indexed by EspionageTabs enum
local m_tabs:table = nil;
local m_selectedTab:number = -1;

-- Overrides

function RefreshOperatives()
	m_OperativeIM:ResetInstances();
	local localPlayerID = nil
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
				localPlayerID = GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID)
				m_OperativeIM = InstanceManager:new("OperativeInstance", "Top", Controls.OperativeStack);
				Controls.OperativeStack:DestroyAllChildren()
				else
				BASE_RefreshOperatives()
				return
			end
			else
			BASE_RefreshOperatives()
			return
		end

	m_OperativeIM:ResetInstances();
	local idleSpies:table = {};
	local activeSpies:table = {};
	local travellingSpies:table = {};

	-- Track the number of spies for display in the header
	local numberOfSpies:number = 0;

	-- Sort spies
	local localPlayerUnits:table = Players[localPlayerID]:GetUnits();
	for i, unit in localPlayerUnits:Members() do
		local unitInfo:table = GameInfo.Units[unit:GetUnitType()];
		if unitInfo.Spy then
			local operationType:number = unit:GetSpyOperation();
			if operationType == -1 then
				table.insert(idleSpies, unit);
			else
				table.insert(activeSpies, unit);
			end

			numberOfSpies = numberOfSpies + 1;
		end
	end

	-- Display idle spies
	for i, spy in ipairs(idleSpies) do
		AddOperative(spy);
	end

	-- Display active spies
	for i, spy in ipairs(activeSpies) do
		AddOperative(spy);
	end

	-- Display captured spies
	-- Loop through all players to see if they have any of our captured spies
	local players:table = Game.GetPlayers();
	for i, player in ipairs(players) do
		local playerDiplomacy:table = player:GetDiplomacy();
		local numCapturedSpies:number = playerDiplomacy:GetNumSpiesCaptured();
		for i=0,numCapturedSpies-1,1 do
			local spyInfo:table = playerDiplomacy:GetNthCapturedSpy(player:GetID(), i);
			if spyInfo and spyInfo.OwningPlayer == localPlayerID then
				AddCapturedOperative(spyInfo, player:GetID());
				numberOfSpies = numberOfSpies + 1;
			end
		end
	end

	-- Display travelling spies
	local playerDiplomacy:table = Players[localPlayerID]:GetDiplomacy();
	if playerDiplomacy then
		local numSpiesOffMap:number = playerDiplomacy:GetNumSpiesOffMap();
		for i=0,numSpiesOffMap-1,1 do
			local spyOffMapInfo:table = playerDiplomacy:GetNthOffMapSpy(localPlayerID, i);
			if spyOffMapInfo and spyOffMapInfo.ReturnTurn ~= -1 then
				AddOffMapOperative(spyOffMapInfo);
				numberOfSpies = numberOfSpies + 1;
			end
		end
	end

	-- Display a messsage if we have no spies
	Controls.NoOperativesLabel:SetHide(numberOfSpies ~= 0);

	-- Update spy count and capcity
	local playerDiplomacy:table = Players[localPlayerID]:GetDiplomacy();
	Controls.OperativeHeader:SetText(Locale.Lookup("LOC_ESPIONAGEOVERVIEW_OPERATIVES_SUBHEADER", numberOfSpies, playerDiplomacy:GetSpyCapacity()));

	Controls.OperativeStack:CalculateSize();
	Controls.OperativeScrollPanel:CalculateSize();

end


-- ===========================================================================
function RefreshMissionHistory()
	m_EnemyOperativeIM:ResetInstances();

	local localPlayerID = nil;
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
				localPlayerID = GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID)
				m_MissionHistoryIM = InstanceManager:new("MissionHistoryInstance", "Top", Controls.MissionHistoryStack);
				Controls.MissionHistoryStack:DestroyAllChildren()
				else
				BASE_RefreshMissionHistory()
				return
			end
			else
			BASE_RefreshMissionHistory()
			return
		end


	-- Update captured enemy operative info
	local haveCapturedEnemyOperative:boolean = false;
	local localPlayer:table = Players[localPlayerID];
	local playerDiplomacy:table = localPlayer:GetDiplomacy();
	local numCapturedSpies:number = playerDiplomacy:GetNumSpiesCaptured();
	for i=0,numCapturedSpies-1,1 do
		local spyInfo:table = playerDiplomacy:GetNthCapturedSpy(localPlayer:GetID(), i);
		if spyInfo then
			haveCapturedEnemyOperative = true;
			AddCapturedEnemyOperative(spyInfo);
		end
	end

	-- Hide captured enemy operative info if we have no captured enemy operatives
	if haveCapturedEnemyOperative then
		Controls.CapturedEnemyOperativeContainer:SetHide(false);
	else
		Controls.CapturedEnemyOperativeContainer:SetHide(true);
	end

	-- Update mission history
	m_MissionHistoryIM:ResetInstances();

	if playerDiplomacy then
		-- Add information for last 10 missions
		local recentMissions:table = playerDiplomacy:GetRecentMissions(localPlayerID, 10, 0);
		if recentMissions then
			-- Hide no missions label
			Controls.NoRecentMissonsLabel:SetHide(true);

			for i,mission in pairs(recentMissions) do
				AddMissionHistoryInstance(mission);
			end
		else
			-- Show no missions label
			Controls.NoRecentMissonsLabel:SetHide(false);
		end
	end

	-- Show a message if we have no history or enemy operatives to display
	Controls.NoHistoryLabel:SetHide(m_EnemyOperativeIM.m_iAllocatedInstances ~= 0 or m_MissionHistoryIM.m_iAllocatedInstances ~= 0);

	ResizeMissionHistoryScrollPanel();

	Controls.MissionHistoryScrollPanel:CalculateSize();
end

function OnDiplomacyClick()
	RefreshMissionHistory()
	RefreshOperatives()
end

function PopulateTabs()
	local localPlayerID:number = Game.GetLocalPlayer();
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
				localPlayerID = GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID)
				else
				BASE_PopulateTabs()
				return
			end
			else
			BASE_PopulateTabs()
			return
		end



	-- Grab player and diplomacy for local player
	local pPlayer:table = Players[localPlayerID];
	local pPlayerDiplomacy:table = nil;
	if pPlayer then
		pPlayerDiplomacy = pPlayer:GetDiplomacy();
	end

	if m_tabs == nil then
		m_tabs = CreateTabs( Controls.TabContainer, 42, 34, UI.GetColorValueFromHexLiteral(0xFF331D05) );
	end

	-- Operatives Tab
	if not m_tabs.OperativesTabAdded then
		m_tabs.AddTab( Controls.OperativesTabButton,		OnSelectOperativesTab );
		Controls.OperativesTabButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
		m_tabs.OperativesTabAdded = true;
	end

	-- City Activity Tab
	if not m_tabs.CityActivityTabAdded then
		m_tabs.AddTab( Controls.CityActivityTabButton,		OnSelectCityActivityTab );
		Controls.CityActivityTabButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
		Controls.CityActivityTabButton:SetDisabled(true)
		Controls.CityActivityTabButton:SetHide(true)
		m_tabs.CityActivityTabAdded = true;
	end
		
	-- Mission History Tab
	-- Only show mission history if we have any mission history or captured enemy operatives
	local shouldShowMissionHistory:boolean = false;
	if pPlayerDiplomacy then
		local firstMission = pPlayerDiplomacy:GetMission(localPlayerID, 0);
		if firstMission ~= 0 then
			-- We have a mission so show history
			shouldShowMissionHistory = true;
		end

		local numCapturedSpies:number = pPlayerDiplomacy:GetNumSpiesCaptured();
		if numCapturedSpies > 0 then
			-- Show mission history if we have captured enemy spies
			shouldShowMissionHistory = true;
		end
	end

	if shouldShowMissionHistory then
		if not m_tabs.MissionHistoryTabAdded then
			Controls.MissionHistoryTabButton:SetHide(false);
			m_tabs.AddTab( Controls.MissionHistoryTabButton,	OnSelectMissionHistoryTab );
			Controls.MissionHistoryTabButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
			m_tabs.MissionHistoryTabAdded = true;
		end
	else
		Controls.MissionHistoryTabButton:SetHide(true);
	end

	m_tabs.EvenlySpreadTabs();
	m_tabs.CenterAlignTabs(-25);	-- Use negative to create padding as value represents amount to overlap
end

LuaEvents.DiplomacyRibbon_Click.Add( OnDiplomacyClick );
Events.GameCoreEventPublishComplete.Add ( OnDiplomacyClick );

function AddCapturedOperative(spy:table, playerCapturedBy:number)
	local operativeInstance:table = m_OperativeIM:GetInstance();
	local localPlayerID:number = Game.GetLocalPlayer()
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
				localPlayerID = GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID)
			end
		end

	-- Adjust texture offset
	operativeInstance.Top:SetTextureOffsetVal(0, 146);

	-- Operative Name
	operativeInstance.OperativeName:SetText(Locale.ToUpper(spy.Name));

	-- Operative Rank
	operativeInstance.OperativeRank:SetText(Locale.Lookup(GetSpyRankNameByLevel(spy.Level)));

	-- Update information about the player who captured the spy
	local capturingPlayerConfig:table = PlayerConfigurations[playerCapturedBy];
	if capturingPlayerConfig then
		local backColor:number, frontColor:number  = UI.GetPlayerColors( playerCapturedBy );
		local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas("ICON_" .. capturingPlayerConfig:GetCivilizationTypeName(),22);
		operativeInstance.CapturingCivIconBack:SetColor(backColor);
		operativeInstance.CapturingCivIconFront:SetColor(frontColor);
		operativeInstance.CapturingCivIconFront:SetTexture(textureOffsetX, textureOffsetY, textureSheet);
		operativeInstance.CapturingCivName:SetText(Locale.Lookup(capturingPlayerConfig:GetPlayerName()));
		TruncateStringWithTooltip(operativeInstance.AskForTradeButton, MAX_BEFORE_TRUNC_ASK_FOR_TRADE, Locale.Lookup("LOC_ESPIONAGEOVERVIEW_ASK_FOR_TRADE"));
		
		-- Show the ask trade button, if there is no pending deal.
		local atWarWith:boolean = Players[localPlayerID]:GetDiplomacy():IsAtWarWith(playerCapturedBy);
		if atWarWith then
			operativeInstance.AskForTradeButton:SetDisabled(true);
			operativeInstance.AskForTradeButton:SetToolTipString(Locale.Lookup("LOC_DIPLOPANEL_AT_WAR"));
		elseif DealManager.HasPendingDeal(localPlayerID, playerCapturedBy) then
			operativeInstance.AskForTradeButton:SetDisabled(true);
			operativeInstance.AskForTradeButton:SetToolTipString(Locale.Lookup("LOC_DIPLOMACY_ANOTHER_DEAL_WITH_PLAYER_PENDING"));
		else
			operativeInstance.AskForTradeButton:SetDisabled(false);
			operativeInstance.AskForTradeButton:RegisterCallback( Mouse.eLClick, function() OnAskForOperativeTradeClicked(playerCapturedBy, spy.NameIndex); end );
			operativeInstance.AskForTradeButton:SetToolTipString("");
		end
	else
		UI.DataError("Could not find player configuration for player ID: " .. tostring(playerCapturedBy));
	end

	operativeInstance.CityBanner:SetHide(true);
	operativeInstance.AwaitingAssignmentStack:SetHide(true);
	operativeInstance.ActiveMissionContainer:SetHide(true);
	operativeInstance.TravellingContainer:SetHide(true);
	operativeInstance.CapturedContainer:SetHide(false);
end

------------------------------------------------------------------------------------------------
function AddCapturedEnemyOperative(spyInfo:table)
	local enemyOperativeInstance:table = m_EnemyOperativeIM:GetInstance();
	local localPlayerID:number = Game.GetLocalPlayer()
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
				localPlayerID = GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID)
			end
		end

	-- Update spy name
	local spyName:string = Locale.ToUpper(spyInfo.Name);
	enemyOperativeInstance.SpyName:SetText(spyName);

	-- Update owning civ spy icon
	local backColor:number, frontColor:number  = UI.GetPlayerColors( spyInfo.OwningPlayer );
	enemyOperativeInstance.SpyIconBack:SetColor(backColor);
	enemyOperativeInstance.SpyIconFront:SetColor(frontColor);

	-- Update owning civ name
	local owningPlayerConfig:table = PlayerConfigurations[spyInfo.OwningPlayer];
	enemyOperativeInstance.CivName:SetText(Locale.Lookup(owningPlayerConfig:GetCivilizationDescription()));

	local pLocalPlayerDiplo:table = Players[localPlayerID]:GetDiplomacy();
	if pLocalPlayerDiplo and not pLocalPlayerDiplo:IsAtWarWith(spyInfo.OwningPlayer) then
		-- If we're not at war with the spies owner allow trading for that spy
		enemyOperativeInstance.OfferTradeText:SetHide(false);
		enemyOperativeInstance.GridButton:SetDisabled(false);
		enemyOperativeInstance.GridButton:RegisterCallback( Mouse.eLClick, function() OnAskForEnemyOperativeTradeClicked(spyInfo.OwningPlayer, spyInfo.NameIndex); end );
		enemyOperativeInstance.GridButton:SetToolTipString("");
	else
		enemyOperativeInstance.OfferTradeText:SetHide(true);
		enemyOperativeInstance.GridButton:SetDisabled(true);
		enemyOperativeInstance.GridButton:ClearCallback( Mouse.eLClick );
		enemyOperativeInstance.GridButton:SetToolTipString(Locale.Lookup("LOC_ESPIONAGE_SPY_TRADE_DISABLED_AT_WAR", spyName, Locale.Lookup(owningPlayerConfig:GetCivilizationShortDescription())));
	end

	Controls.CapturedEnemyOperativeStack:CalculateSize();
end