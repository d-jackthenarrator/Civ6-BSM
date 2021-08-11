-- Copyright 2017-2019, Firaxis Games
include("TeamSupport");
include("DiplomacyRibbonSupport");
print("LeaderIcon for BSM")						   

-- ===========================================================================
--	Class Table
-- ===========================================================================
LeaderIcon = {
	playerID = -1,
	TEAM_RIBBON_PREFIX	= "ICON_TEAM_RIBBON_"
}

local m_bspec = false
-- ===========================================================================
function LeaderIcon:GetInstance(instanceManager:table, uiNewParent:table)
	local instance:table = instanceManager:GetInstance(uiNewParent);
	return LeaderIcon:AttachInstance(instance);
end

-- ===========================================================================
--	Essentially the "new"
-- ===========================================================================
function LeaderIcon:AttachInstance( instance:table )
	if instance == nil then
		UI.DataError("NIL instance passed into LeaderIcon:AttachInstance.  Setting the value to the ContextPtr's 'Controls'.");
		instance = Controls;

	end
	setmetatable(instance, {__index = self });
	self.Controls = instance;
	self:Reset();
	return instance;
end


-- ===========================================================================
function LeaderIcon:UpdateIcon(iconName: string, playerID: number, isUniqueLeader: boolean, ttDetails: string)
	
	LeaderIcon.playerID = playerID;

	local pPlayer:table = Players[playerID];
	local pPlayerConfig:table = PlayerConfigurations[playerID];
	local localPlayerID:number = Game.GetLocalPlayer();

	-- Display the civ colors/icon for duplicate civs
	if isUniqueLeader == false and (playerID == localPlayerID or Players[localPlayerID]:GetDiplomacy():HasMet(playerID)) then
		local backColor, frontColor  = UI.GetPlayerColors( playerID );
		self.Controls.CivIndicator:SetHide(false);
		self.Controls.CivIndicator:SetColor(backColor);
		self.Controls.CivIcon:SetHide(false);
		self.Controls.CivIcon:SetColor(frontColor);
		self.Controls.CivIcon:SetIcon("ICON_"..pPlayerConfig:GetCivilizationTypeName());
	else
		self.Controls.CivIcon:SetHide(true);
		self.Controls.CivIndicator:SetHide(true);
	end
	
	-- Set leader portrait and hide overlay if not local player
	self.Controls.Portrait:SetIcon(iconName);
	self.Controls.YouIndicator:SetHide(playerID ~= localPlayerID);

	-- Set the tooltip
	local tooltip:string = self:GetToolTipString(playerID);
	if (ttDetails ~= nil and ttDetails ~= "") then
		tooltip = tooltip .. "[NEWLINE]" .. ttDetails;
	end
	self.Controls.Portrait:SetToolTipString(tooltip);

	self:UpdateTeamAndRelationship(playerID);
end

-- ===========================================================================
function LeaderIcon:UpdateIconSimple(iconName: string, playerID: number, isUniqueLeader: boolean, ttDetails: string)

	LeaderIcon.playerID = playerID;

	local localPlayerID:number = Game.GetLocalPlayer();

	self.Controls.Portrait:SetIcon(iconName);
	self.Controls.YouIndicator:SetHide(playerID ~= localPlayerID);

	-- Display the civ colors/icon for duplicate civs
	if isUniqueLeader == false and (playerID ~= -1 and Players[localPlayerID]:GetDiplomacy():HasMet(playerID)) then
		local backColor, frontColor = UI.GetPlayerColors( playerID );
		self.Controls.CivIndicator:SetHide(false);
		self.Controls.CivIndicator:SetColor(backColor);
		self.Controls.CivIcon:SetHide(false);
		self.Controls.CivIcon:SetColor(frontColor);
		self.Controls.CivIcon:SetIcon("ICON_"..PlayerConfigurations[playerID]:GetCivilizationTypeName());
	else
		self.Controls.CivIcon:SetHide(true);
		self.Controls.CivIndicator:SetHide(true);
	end

	if playerID < 0 then
		self.Controls.TeamRibbon:SetHide(true);
		self.Controls.Relationship:SetHide(true);
		self.Controls.Portrait:SetToolTipString("");
		return;
	end

	-- Set the tooltip
	local tooltip:string = self:GetToolTipString(playerID);
	if (ttDetails ~= nil and ttDetails ~= "") then
		tooltip = tooltip .. "[NEWLINE]" .. ttDetails;
	end
	self.Controls.Portrait:SetToolTipString(tooltip);

	self:UpdateTeamAndRelationship(playerID);
end

-- ===========================================================================
--	playerID, Index of the player to compare a relationship.  (May be self.)
-- ===========================================================================
function LeaderIcon:UpdateTeamAndRelationship( playerID: number)

	local localPlayerID	:number = Game.GetLocalPlayer();
	if localPlayerID == PlayerTypes.NONE or playerID == PlayerTypes.OBSERVER then return; end		--  Local player is auto-play.

	-- Don't even attempt it, just hide the icon if this game mode doesn't have the capabilitiy.
	if GameCapabilities.HasCapability("CAPABILITY_DISPLAY_HUD_RIBBON_RELATIONSHIPS") == false then
		self.Controls.Relationship:SetHide( true );
		return;
	end
	
	-- Nope, autoplay or observer
	if playerID < 0 then 
		UI.DataError("Invalid playerID="..tostring(playerID).." to check against for UpdateTeamAndRelationship().");
		return; 
	end	
	
	if PlayerConfigurations[Game.GetLocalPlayer()] ~= nil then
		if PlayerConfigurations[Game.GetLocalPlayer()]:GetLeaderTypeName() == "LEADER_SPECTATOR" then
			m_bspec = true
		end
	end
	
	if (m_bspec == true) and Game.GetLocalPlayer() ~= nil then
		if (GameConfiguration.GetValue("OBSERVER_ID_"..Game.GetLocalPlayer()) ~= nil) and (GameConfiguration.GetValue("OBSERVER_ID_"..Game.GetLocalPlayer()) ~= 1000)  and (GameConfiguration.GetValue("OBSERVER_ID_"..Game.GetLocalPlayer()) ~= -1) then
			localPlayerID = GameConfiguration.GetValue("OBSERVER_ID_"..Game.GetLocalPlayer())
		end
	end
			
	local pPlayer		:table = Players[playerID];
	local pPlayerConfig	:table = PlayerConfigurations[playerID];	
	local isHuman		:boolean = pPlayerConfig:IsHuman();
	local isSelf		:boolean = (playerID == localPlayerID);
	local isMet			:boolean = Players[localPlayerID]:GetDiplomacy():HasMet(playerID);

	-- Team Ribbon
	local isTeamRibbonHidden:boolean = true;
	if(isSelf or isMet) then
		-- Show team ribbon for ourselves and civs we've met
		local teamID:number = pPlayerConfig:GetTeam();
		if Teams[teamID] ~= nil then
			if #Teams[teamID] > 1 then
				local teamRibbonName:string = self.TEAM_RIBBON_PREFIX .. tostring(teamID);
				self.Controls.TeamRibbon:SetIcon(teamRibbonName);
				self.Controls.TeamRibbon:SetColor(GetTeamColor(teamID));
				isTeamRibbonHidden = false;
			end
		end
	end
	self.Controls.TeamRibbon:SetHide(isTeamRibbonHidden);

	-- Relationship status (Humans don't show anything, unless we are at war)
	local eRelationship :number = pPlayer:GetDiplomaticAI():GetDiplomaticStateIndex(localPlayerID);
	local relationType	:string = GameInfo.DiplomaticStates[eRelationship].StateType;
	local isValid		:boolean= (isHuman and Relationship.IsValidWithHuman( relationType )) or (not isHuman and Relationship.IsValidWithAI( relationType ));
	if isValid then		
		self.Controls.Relationship:SetVisState(eRelationship);
		if (GameInfo.DiplomaticStates[eRelationship].Hash ~= DiplomaticStates.NEUTRAL) then
			self.Controls.Relationship:SetToolTipString(Locale.Lookup(GameInfo.DiplomaticStates[eRelationship].Name));
		end
	end
	self.Controls.Relationship:SetHide( not isValid );
end

-- ===========================================================================
--	Resets the view of attached controls
-- ===========================================================================
function LeaderIcon:Reset()
	if self.Controls == nil then
		UI.DataError("Attempting to call Reset() on a nil LeaderIcon.");
		return;
	end
	self.Controls.TeamRibbon:SetHide(true);
 	self.Controls.Relationship:SetHide(true);
 	self.Controls.YouIndicator:SetHide(true);
end

------------------------------------------------------------------
function LeaderIcon:RegisterCallback(event: number, func: ifunction)
	self.Controls.SelectButton:RegisterCallback(event, func);
end

------------------------------------------------------------------
function LeaderIcon:GetToolTipString(playerID:number)

	local result:string = "";
	local pPlayerConfig:table = PlayerConfigurations[playerID];

	if pPlayerConfig and pPlayerConfig:GetLeaderTypeName() then
		local isHuman		:boolean = pPlayerConfig:IsHuman();
		local leaderDesc	:string = pPlayerConfig:GetLeaderName();
		local civDesc		:string = pPlayerConfig:GetCivilizationDescription();
		local localPlayerID	:number = Game.GetLocalPlayer();
		
		if localPlayerID==PlayerTypes.NONE or localPlayerID==PlayerTypes.OBSERVER  then
			return "";
		end		

		if GameConfiguration.IsAnyMultiplayer() and isHuman then
			if(playerID ~= localPlayerID and not Players[localPlayerID]:GetDiplomacy():HasMet(playerID)) then
				result = Locale.Lookup("LOC_DIPLOPANEL_UNMET_PLAYER") .. " (" .. pPlayerConfig:GetPlayerName() .. ")";
			else
				result = Locale.Lookup("LOC_DIPLOMACY_DEAL_PLAYER_PANEL_TITLE", leaderDesc, civDesc) .. " (" .. pPlayerConfig:GetPlayerName() .. ")";
			end
		else
			if(playerID ~= localPlayerID and not Players[localPlayerID]:GetDiplomacy():HasMet(playerID)) then
				result = Locale.Lookup("LOC_DIPLOPANEL_UNMET_PLAYER");
			else
				result = Locale.Lookup("LOC_DIPLOMACY_DEAL_PLAYER_PANEL_TITLE", leaderDesc, civDesc);
			end
		end
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

	if bspec == true then

		local govType:string = "";
  		local eSelectePlayerGovernment :number = Players[playerID]:GetCulture():GetCurrentGovernment();
  		if eSelectePlayerGovernment ~= -1 then
    			govType = Locale.Lookup(GameInfo.Governments[eSelectePlayerGovernment].Name);
 			else
   			govType = Locale.Lookup("LOC_GOVERNMENT_ANARCHY_NAME" );
  		end
  		local cities = Players[playerID]:GetCities();
  		local numCities = 0;
  		local ERD_Total_Population = 0;
  		for i,city in cities:Members() do
			ERD_Total_Population = ERD_Total_Population + city:GetPopulation();
    			numCities = numCities + 1;
  		end


		local pPlayerCulture:table = Players[playerID]:GetCulture();
		local culture_num = 0
		for k = 0, 58 do
			if (pPlayerCulture:HasCivic(k) == true) then
				culture_num = culture_num + 1
			end	
		end
		local pPlayerTechs:table = Players[playerID]:GetTechs();
		local tech_num = 0
		for k = 0, 73 do
			if (pPlayerTechs:HasTech(k) == true) then
				tech_num = tech_num + 1

			end	
		end
		local unit_num = 0
		local unit_str = 0
		if Players[playerID]:GetUnits() ~= nil then
			if Players[playerID]:GetUnits():GetCount() ~= nil then
				unit_num = Players[playerID]:GetUnits():GetCount()
			end
		end

  		local playerTreasury:table	= Players[playerID]:GetTreasury();
 	 	local goldBalance	:number = math.floor(playerTreasury:GetGoldBalance());
  		local goldYield	:number = math.floor((playerTreasury:GetGoldYield() - playerTreasury:GetTotalMaintenance()));


	  	local pGameEras:table = Game.GetEras();
		local score	= pGameEras:GetPlayerCurrentScore(playerID);
		local detailsString = "Current Era Score: ".. score;
		local isFinalEra:boolean = pGameEras:GetCurrentEra() == pGameEras:GetFinalEra();

		if not isFinalEra then
			detailsString = detailsString .. Locale.Lookup("LOC_DARK_AGE_THRESHOLD_TEXT", pGameEras:GetPlayerDarkAgeThreshold(playerID));
			detailsString = detailsString .. Locale.Lookup("LOC_GOLDEN_AGE_THRESHOLD_TEXT", pGameEras:GetPlayerGoldenAgeThreshold(playerID));
		end
	  	if pGameEras:HasHeroicGoldenAge(playerID) then
			sEras = " ("..Locale.Lookup("LOC_ERA_PROGRESS_HEROIC_AGE").." [ICON_GLORY_SUPER_GOLDEN_AGE])";
	  		elseif pGameEras:HasGoldenAge(playerID) then
			sEras = " ("..Locale.Lookup("LOC_ERA_PROGRESS_GOLDEN_AGE").." [ICON_GLORY_GOLDEN_AGE])";
	  		elseif pGameEras:HasDarkAge(playerID) then
			sEras = " ("..Locale.Lookup("LOC_ERA_PROGRESS_DARK_AGE").." [ICON_GLORY_DARK_AGE])";
	  		else
			sEras = " ("..Locale.Lookup("LOC_ERA_PROGRESS_NORMAL_AGE").." [ICON_GLORY_NORMAL_AGE])";
	  	end
		local sEras_2 = ""
		local activeCommemorations = pGameEras:GetPlayerActiveCommemorations(playerID);
		for i,activeCommemoration in ipairs(activeCommemorations) do
			local commemorationInfo = GameInfo.CommemorationTypes[activeCommemoration];
			if (commemorationInfo ~= nil) then
	  			if pGameEras:HasHeroicGoldenAge(playerID) then
					sEras_2 = sEras_2.."[NEWLINE]"..Locale.Lookup(commemorationInfo.GoldenAgeBonusDescription)
	  				elseif pGameEras:HasGoldenAge(playerID) then
					sEras_2 = sEras_2.."[NEWLINE]"..Locale.Lookup(commemorationInfo.GoldenAgeBonusDescription)
	  				elseif pGameEras:HasDarkAge(playerID) then
					sEras_2 = sEras_2.."[NEWLINE]"..Locale.Lookup(commemorationInfo.DarkAgeBonusDescription)
	  				else
					sEras_2 = sEras_2.."[NEWLINE]"..Locale.Lookup(commemorationInfo.NormalAgeBonusDescription)
	  			end
				
			end
		end

		result = result
		.."[NEWLINE]"..sEras
		..sEras_2
		.."[NEWLINE]"..detailsString
		.."[NEWLINE] "
		.."[NEWLINE]"..Locale.Lookup("LOC_DIPLOMACY_INTEL_GOVERNMENT").." "..Locale.ToUpper(govType)
		.."[NEWLINE]"..Locale.Lookup("LOC_PEDIA_CONCEPTS_PAGEGROUP_CITIES_NAME").. ": " .. "[COLOR_FLOAT_PRODUCTION]" .. numCities .. "[ENDCOLOR] [ICON_Housing]    ".. Locale.Lookup("LOC_DEAL_CITY_POPULATION_TOOLTIP", ERD_Total_Population) .. " [ICON_Citizen]"
		.."[NEWLINE] "
		.."[NEWLINE][ICON_Capital] "..Locale.Lookup("LOC_WORLD_RANKINGS_OVERVIEW_DOMINATION_SCORE", Players[playerID]:GetScore())
		.."[NEWLINE][ICON_Favor]  "..Locale.Lookup("LOC_DIPLOMATIC_FAVOR_NAME") .. ": [COLOR_Red]" .. Players[playerID]:GetFavor().."[ENDCOLOR]"
		.."[NEWLINE][ICON_Gold] "..Locale.Lookup("LOC_YIELD_GOLD_NAME")..": "..goldBalance.."   ( " .. "[COLOR_GoldMetalDark]" .. (goldYield>0 and "+" or "") .. (goldYield>0 and goldYield or "-?") .. "[ENDCOLOR]  )"
		.."[NEWLINE]"..Locale.Lookup("LOC_WORLD_RANKINGS_OVERVIEW_SCIENCE_SCIENCE_RATE", "[COLOR_FLOAT_SCIENCE]" .. Round(Players[playerID]:GetTechs():GetScienceYield(),1) .. "[ENDCOLOR]").."     Technologies know: "..tech_num
    		.."[NEWLINE]"..Locale.Lookup("LOC_WORLD_RANKINGS_OVERVIEW_CULTURE_CULTURE_RATE", "[COLOR_FLOAT_CULTURE]" .. Round(Players[playerID]:GetCulture():GetCultureYield(),1) .. "[ENDCOLOR]").."       Civics known: "..culture_num
    		.."[NEWLINE]"..Locale.Lookup("LOC_WORLD_RANKINGS_OVERVIEW_CULTURE_TOURISM_RATE", "[COLOR_Tourism]" .. Round(Players[playerID]:GetStats():GetTourism(),1) .. "[ENDCOLOR]")
    		.."[NEWLINE]"..Locale.Lookup("LOC_WORLD_RANKINGS_OVERVIEW_RELIGION_FAITH_RATE", Round(Players[playerID]:GetReligion():GetFaithYield(),1))
    		.."[NEWLINE][ICON_Strength] "..Locale.Lookup("LOC_WORLD_RANKINGS_OVERVIEW_DOMINATION_MILITARY_STRENGTH", "[COLOR_FLOAT_MILITARY]" .. Players[playerID]:GetStats():GetMilitaryStrengthWithoutTreasury() .. "[ENDCOLOR]").."      # Units: "..unit_num
	;
	
		local tooltip = "";
		local canTrade = false;
	
		local MAX_WIDTH = 4;
		local pLuxuries = "";
		local pStrategics = "";
		local pLuxNum = 0;
		local pStratNum = 0;
		local minAmount = 0;
		local pForDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING, Game.GetLocalPlayer(), playerID);
		local pPlayerResources = DealManager.GetPossibleDealItems(playerID, Game.GetLocalPlayer(), DealItemTypes.RESOURCES, pForDeal);
		local pLocalPlayerResources = Players[Game.GetLocalPlayer()]:GetResources();
	
		if (pPlayerResources ~= nil) then
			for i,entry in ipairs(pPlayerResources) do 
				local resource = GameInfo.Resources[entry.ForType];
				local amount = entry.MaxAmount;
				local amountString = (playerID ~= Game.GetLocalPlayer()) and 
								(pLocalPlayerResources:HasResource(entry.ForType) and "[COLOR_ModStatusGreenCS]" .. amount .. "[ENDCOLOR]" or "[COLOR_ModStatusRedCS]" .. amount .. "[ENDCOLOR]") or
								 amount;
				local showResource = true or not pLocalPlayerResources:HasResource(entry.ForType);
				if (resource.ResourceClassType == "RESOURCECLASS_STRATEGIC") then
					if (amount > minAmount and showResource) then
						pStrategics = ((pStratNum - MAX_WIDTH)%(MAX_WIDTH) == 0) and (pStrategics .. "[NEWLINE]" .. "[ICON_"..resource.ResourceType.."]".. amountString .. "  ") 
						or (pStrategics .. "[ICON_"..resource.ResourceType.."]".. amountString .. "  ");
						pStratNum = pStratNum + 1;
					end
				elseif (resource.ResourceClassType == "RESOURCECLASS_LUXURY") then
					if (amount > minAmount and showResource) then
						pLuxuries = ((pLuxNum - MAX_WIDTH)%(MAX_WIDTH) == 0) and (pLuxuries .. "[NEWLINE]" .. "[ICON_"..resource.ResourceType.."]" .. amountString .. "  ") 
						or (pLuxuries .. "[ICON_"..resource.ResourceType.."]" .. amountString .. "  ");
						pLuxNum = pLuxNum + 1;
					end
				end
			end
		end
	
		if (minAmount > 0) then
			tooltip = Locale.Lookup("LOC_HUD_REPORTS_TAB_RESOURCES") .. " (> " .. minAmount .. ") :";
		end
	
		tooltip = pStratNum > 0 and (tooltip .. "[NEWLINE]Tradeable Strategics:" .. pStrategics) or (tooltip .. "");
		tooltip = pLuxNum > 0  and (tooltip .. "[NEWLINE]Tradeable Luxuries:" .. pLuxuries) or (tooltip .. "");
	
		if (pStratNum > 0 or pLuxNum > 0) then
				result = result
				.."[NEWLINE]"..tooltip	
		else
				result = result
		end



	end
	return result;
end

-- ===========================================================================
function LeaderIcon:AppendTooltip( extraText:string )
	if extraText == nil or extraText == "" then return; end		--Ignore blank
	local tooltip:string = self:GetToolTipString(self.playerID) .. "[NEWLINE]" .. extraText;
	self.Controls.Portrait:SetToolTipString(tooltip);
end