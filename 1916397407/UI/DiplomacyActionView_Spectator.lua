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
local LEADERTEXT_PADDING_X		:number		= 40;
local LEADERTEXT_PADDING_Y		:number		= 40;
local SELECTION_PADDING_Y		:number		= 20;

local OVERVIEW_MODE = 0;
local CONVERSATION_MODE = 1;
local CINEMA_MODE = 2;
local DEAL_MODE = 3;
local SIZE_BUILDING_ICON	:number = 32;
local SIZE_UNIT_ICON		:number = 32;
local INTEL_NO_SUB_PANEL			= -1;
local INTEL_ACCESS_LEVEL_PANEL		= 0;
local INTEL_RELATIONSHIP_PANEL		= 1;
local INTEL_GOSSIP_HISTORY_PANEL	= 2;
local INTEL_AGENDA_PANEL			= 3;

local DIPLOMACY_RIBBON_OFFSET			= 64;
local MAX_BEFORE_TRUNC_BUTTON_INST		= 280;
local PADDING_FOR_SCROLLPANEL			= 220;

local TEAM_RIBBON_SIZE				:number = 53;
local TEAM_RIBBON_SMALL_SIZE		:number = 30;
local TEAM_RIBBON_PREFIX			:string = "ICON_TEAM_RIBBON_";

local VOICEOVER_SUPPORT: table = {"KUDOS", "WARNING", "DECLARE_WAR_FROM_HUMAN", "DECLARE_WAR_FROM_AI", "FIRST_MEET", "DEFEAT","ENRAGED"};

--This is the multiplier for the portion of the screen which the conversation control should cover.
local CONVO_X_MULTIPLIER	= .328;

-- Recall global
local ms_IntelOverviewOtherRelationshipsIM	:table = InstanceManager:new( "IntelOverviewOtherRelationshipsInstance", "Top" );
local ms_RelationshipIconsIM		:table	= InstanceManager:new( "RelationshipIcon",  "Background" );
ms_LocalPlayer = nil;
ms_LocalPlayerID = -1;
ms_SelectedPlayerID = -1;
ms_SelectedPlayer = nil;


-- ===========================================================================
function OnDiplomacyStatement(fromPlayer : number, toPlayer : number, kVariants : table)
	local bspec = false
	local tospec = false
	if (Game:GetProperty("SPEC_NUM") ~= nil) then
		for k = 1, Game:GetProperty("SPEC_NUM") do
			if ( Game:GetProperty("SPEC_ID_"..k)~= nil) then
				if Game.GetLocalPlayer() == Game:GetProperty("SPEC_ID_"..k) then
					bspec = true
				end
			end
		end
		for k = 1, Game:GetProperty("SPEC_NUM") do
			if ( Game:GetProperty("SPEC_ID_"..k)~= nil) then
				if toPlayer == Game:GetProperty("SPEC_ID_"..k) then
					tospec = true
				end
			end
		end
	end
	if (bspec == true) then
		if (tospec == true) then
			if (Players[fromPlayer]:IsHuman() == false) then
				print("Killed an AI pop-up!")
				DiplomacyManager.CloseSession( kVariants.SessionID );
				return;
			end
		end
	end	

	BASE_OnDiplomacyStatement(fromPlayer,toPlayer,kVariants)
	
end

function AddOverviewOtherRelationships(overviewInstance:table)
	print("AddOverviewOtherRelationships")
	ms_IntelOverviewOtherRelationshipsIM:ResetInstances();

	local overviewOtherRelationshipsInst:table = ms_IntelOverviewOtherRelationshipsIM:GetInstance(overviewInstance.IntelOverviewStack);

	--Set data for relationship area
	local pLocalPlayerDiplomacy:table = ms_LocalPlayer:GetDiplomacy();
	
	ms_RelationshipIconsIM:ResetInstances();

	-- Get who the selected player has met
	local selectedPlayerDiplomacy = ms_SelectedPlayer:GetDiplomacy();
	local aPlayers = PlayerManager.GetAliveMajors();
	for _, pPlayer in ipairs(aPlayers) do
		local playerID :number = pPlayer:GetID();
		if (pPlayer:IsMajor() and playerID ~= ms_LocalPlayerID and playerID ~= ms_SelectedPlayer:GetID() and selectedPlayerDiplomacy:HasMet(playerID)) then
			local playerConfig		:table = PlayerConfigurations[playerID];
			local leaderTypeName	:string = playerConfig:GetLeaderTypeName();
			if (leaderTypeName ~= nil) then
				local relationshipIcon	:table = ms_RelationshipIconsIM:GetInstance(overviewOtherRelationshipsInst.RelationshipsStack);
				local iPlayerDiploState	:number= pPlayer:GetDiplomaticAI():GetDiplomaticStateIndex(ms_SelectedPlayer:GetID());				
				local kRelationship		:table = GameInfo.DiplomaticStates[iPlayerDiploState];
				local isRelationHidden	:boolean = true;

				-- If a state other than neutral exsits, then look up the corresponding 
				-- relationship rules for AI or human, based on the players.
				if (kRelationship.Hash ~= DiplomaticStates.NEUTRAL) then
					local isHuman		:boolean= not (ms_SelectedPlayer:IsAI() or pPlayer:IsAI());
					local relationType	:string = kRelationship.StateType;
					local isValid		:boolean= (isHuman and Relationship.IsValidWithHuman( relationType )) or (not isHuman and Relationship.IsValidWithAI( relationType ));
					if isValid then
						relationshipIcon.Status:SetToolTipString( Locale.Lookup(kRelationship.Name) );
						relationshipIcon.Status:SetVisState( iPlayerDiploState );
						isRelationHidden = false;
					end
				end
				relationshipIcon.Status:SetHide( isRelationHidden );

				if( pLocalPlayerDiplomacy:HasMet(playerID) ) then
					relationshipIcon.Icon:SetTexture(IconManager:FindIconAtlas("ICON_" .. playerConfig:GetLeaderTypeName(), 32));
					-- Tool tip
					local leaderDesc :string = playerConfig:GetLeaderName();
					relationshipIcon.Background:LocalizeAndSetToolTip("LOC_DIPLOMACY_DEAL_PLAYER_PANEL_TITLE", leaderDesc, playerConfig:GetCivilizationDescription());
					
					-- Show team ribbon for ourselves and civs we've met
					local teamID:number = playerConfig:GetTeam();


					if Teams[teamID] ~= nil then

						if #Teams[teamID] > 1 then

							local teamRibbonName:string = TEAM_RIBBON_PREFIX .. tostring(teamID);
							relationshipIcon.TeamRibbon:SetIcon(teamRibbonName, TEAM_RIBBON_SMALL_SIZE);
							relationshipIcon.TeamRibbon:SetHide(false);
							relationshipIcon.TeamRibbon:SetColor(GetTeamColor(teamID));
							else
							-- Hide team ribbon if team only contains one player
							relationshipIcon.TeamRibbon:SetHide(true);
						end
						else
						-- Hide team ribbon if team only contains one player
						relationshipIcon.TeamRibbon:SetHide(true);						
					end
				else
					-- IF the local player has not met the civ that this civ has a relationship, do not reveal that information through this icon.  Instead, set to generic leader and "Unmet Civ"
					relationshipIcon.Icon:SetTexture(IconManager:FindIconAtlas("ICON_LEADER_DEFAULT", 32));
					relationshipIcon.Background:LocalizeAndSetToolTip("LOC_DIPLOPANEL_UNMET_PLAYER");
					relationshipIcon.TeamRibbon:SetHide(true);
				end
			end				
		end
	end

	overviewOtherRelationshipsInst.RelationshipsStack:CalculateSize();

	--IF this civ hasn't met anyone but you, hide the relationship stack
	if ( overviewOtherRelationshipsInst.RelationshipsStack:GetSizeY() == 0) then
		overviewOtherRelationshipsInst.Top:SetHide(true);
	else
		overviewOtherRelationshipsInst.Top:SetHide(false);
	end

	return not overviewOtherRelationshipsInst.Top:IsHidden();
	
end
