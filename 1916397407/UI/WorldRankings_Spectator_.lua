-- Copyright 2018, Firaxis Games

-- ===========================================================================
-- Includes
-- ===========================================================================
include("WorldRankings_Expansion2.lua");
print("WorldRanking for BSM")

-- ===========================================================================
-- Constants
-- ===========================================================================
-- Track the number of turns till the closest cultural victory
local m_iTurnsTillCulturalVictory:number = -1;
local m_spec_count = 0
local m_major_alive_count = 1
local m_LocalPlayerID = Game.GetLocalPlayer()
local b_spec_send_tourists = false
local m_CultureIM:table 
local m_CultureTeamIM:table 
local m_ReligionIM:table 
local m_ReligionTeamIM:table 
local m_OverallIM:table 

local m_MPHId:string = "619ac86e-d99d-4bf3-b8f0-8c5b8c402176";
local m_MPHEnabled:boolean = false;

local ICON_GENERIC:string = "ICON_VICTORY_GENERIC";
local ICON_UNKNOWN_CIV:string = "ICON_CIVILIZATION_UNKNOWN";
local LOC_UNKNOWN_CIV:string = Locale.Lookup("LOC_WORLD_RANKING_UNMET_PLAYER");
local LOC_UNKNOWN_CIV_COLORED:string = Locale.Lookup("LOC_WORLD_RANKING_UNMET_PLAYER_COLORED");
-- =============================================================================
-- MPH Check
-- =============================================================================
function PreIncludeModCheck()
	-- Mod compatibility
	local activeMods = Modding.GetActiveMods();
	if activeMods ~= nil then
		for _, v in pairs(activeMods) do
			if v.Id == m_MPHId then
				m_MPHEnabled = true;
			end
		end
	end
end
PreIncludeModCheck();
-- ===========================================================================
-- Cached Functions
-- ===========================================================================
BASE_PopulateReligionInstance = PopulateReligionInstance
-- ===========================================================================
-- New Events & Functions
-- ===========================================================================
function test()
	if(Game.IsVictoryEnabled("VICTORY_RELIGIOUS")) then
		-- Gather data
		local religionData:table, totalCivs:number = GatherReligionData();

		-- Sort teams
		table.sort(religionData, function(a, b) return #a.ConvertedCivs > #b.ConvertedCivs; end);

		m_ReligionIM:ResetInstances();
		m_ReligionTeamIM:ResetInstances();

		for i, teamData in ipairs(religionData) do
			if #teamData.PlayerData > 1 then
				-- Display as team
				PopulateReligionTeamInstance(m_ReligionTeamIM:GetInstance(), teamData, totalCivs);
			elseif #teamData.PlayerData > 0 then
				-- Display as single civ
				if teamData.PlayerData[1].ReligionType > 0 then
					PopulateReligionInstance(m_ReligionIM:GetInstance(), teamData.PlayerData[1], totalCivs);
				end
			end
		end
	end
	

end


function OnLocalPlayerTurnBegin()
	local localID = Network.GetLocalPlayerID()
	
	-- New adjusted CV check
	if(Game.IsVictoryEnabled("VICTORY_CULTURE")) then

		-- Gather data
		local cultureData:table = GatherCultureData();

		-- Sort by team
		table.sort(cultureData, function(a, b) return a.BestNumVisitingUs / a.BestNumRequiredTourists > b.BestNumVisitingUs / b.BestNumRequiredTourists; end);

		for i, teamData in ipairs(cultureData) do
			if #teamData.PlayerData > 1 then
				-- Display as team

				for i, playerData in ipairs(teamData.PlayerData) do
					if m_MPHEnabled == true then
						if playerData.NumVisitingUs > playerData.NumRequiredTourists then
							if localID == Network.GetGameHostPlayerID() then
					
								Network.SendChat(".mph_ui_victor_"..playerData.PlayerID.."_reason_"..playerData.PlayerID.."_cultural", -2,-1)
								for _, playerID in ipairs(PlayerManager.GetAliveMajorIDs()) do
									if Players[playerID] ~= nil and  playerID ~= playerData.PlayerID then
										if PlayerConfigurations[playerID]:GetLeaderTypeName() ~= "LEADER_SPECTATOR" and Players[playerID]:GetTeam() ~= Players[playerData.PlayerID]:GetTeam() then
											Network.SendChat(".mph_ui_defeat_"..playerID.."_reason_"..playerData.PlayerID.."_cultural", -2,-1)
										end
										if PlayerConfigurations[playerID]:GetLeaderTypeName() ~= "LEADER_SPECTATOR" and Players[playerID]:GetTeam() == Players[playerData.PlayerID]:GetTeam() then
											Network.SendChat(".mph_ui_victor_"..playerID.."_reason_"..playerData.PlayerID.."_cultural", -2,-1)
										end
									end
								end
								local teamIDs = GetRealAliveMajorTeamIDs()
								local count = 0
								for _, teamID in ipairs(teamIDs) do
									count = count + 1
								end
								if count > 1 then
									Network.SendChat(".mph_ui_teamer_"..playerData.PlayerID.."_reason_"..playerData.PlayerID.."_cultural", -2,-1)
									else
								end
							end
						end
					end	
				end
				
			elseif #teamData.PlayerData > 0 then
				-- Display as single civ
				--PopulateCultureInstance(m_CultureIM:GetInstance(), teamData.PlayerData[1])
				local playerData = teamData.PlayerData[1]				
				if m_MPHEnabled == true then
					if playerData.NumVisitingUs > playerData.NumRequiredTourists then
						if localID == Network.GetGameHostPlayerID() then
					
							Network.SendChat(".mph_ui_victor_"..playerData.PlayerID.."_reason_"..playerData.PlayerID.."_cultural", -2,-1)
									for _, playerID in ipairs(PlayerManager.GetAliveMajorIDs()) do
										if Players[playerID] ~= nil and  playerID ~= playerData.PlayerID then
											if PlayerConfigurations[playerID]:GetLeaderTypeName() ~= "LEADER_SPECTATOR" and Players[playerID]:GetTeam() ~= Players[playerData.PlayerID]:GetTeam() then
												Network.SendChat(".mph_ui_defeat_"..playerID.."_reason_"..playerData.PlayerID.."_cultural", -2,-1)
											end
											if PlayerConfigurations[playerID]:GetLeaderTypeName() ~= "LEADER_SPECTATOR" and Players[playerID]:GetTeam() == Players[playerData.PlayerID]:GetTeam() then
												Network.SendChat(".mph_ui_victor_"..playerID.."_reason_"..playerData.PlayerID.."_cultural", -2,-1)
											end
										end
									end
									local teamIDs = GetRealAliveMajorTeamIDs()
									local count = 0
									for _, teamID in ipairs(teamIDs) do
										count = count + 1
									end
							if count > 1 then
								Network.SendChat(".mph_ui_teamer_"..playerData.PlayerID.."_reason_"..playerData.PlayerID.."_cultural", -2,-1)
								else
							end
						end
					end
				end	
			end
		end
	end
	
	-- New Adjusted RV Check
	if(Game.IsVictoryEnabled("VICTORY_RELIGIOUS")) then
		-- Gather data
		local religionData:table, totalCivs:number = GatherReligionData();

		-- Sort teams
		table.sort(religionData, function(a, b) return #a.ConvertedCivs > #b.ConvertedCivs; end);

		for i, teamData in ipairs(religionData) do
			if #teamData.PlayerData > 1 then
				-- Display as team
				for i, playerData in ipairs(teamData.PlayerData) do
						if m_MPHEnabled == true then
			if #playerData.ConvertedCivs == totalCivs then
				if localID == Network.GetGameHostPlayerID() then
					Network.SendChat(".mph_ui_victor_"..playerData.PlayerID.."_reason_"..playerData.PlayerID.."_religion", -2,-1)
					for _, playerID in ipairs(PlayerManager.GetAliveMajorIDs()) do
						if Players[playerID] ~= nil and  playerID ~= playerData.PlayerID then
							if PlayerConfigurations[playerID]:GetLeaderTypeName() ~= "LEADER_SPECTATOR" and Players[playerID]:GetTeam() ~= Players[playerData.PlayerID]:GetTeam() then
								Network.SendChat(".mph_ui_defeat_"..playerID.."_reason_"..playerData.PlayerID.."_religion", -2,-1)
							end
							if PlayerConfigurations[playerID]:GetLeaderTypeName() ~= "LEADER_SPECTATOR" and Players[playerID]:GetTeam() == Players[playerData.PlayerID]:GetTeam() then
								Network.SendChat(".mph_ui_victor_"..playerID.."_reason_"..playerData.PlayerID.."_religion", -2,-1)
							end
						end
					end
					local teamIDs = GetRealAliveMajorTeamIDs()
					local count = 0
					for _, teamID in ipairs(teamIDs) do
						count = count + 1
					end
					if count > 1 then
						Network.SendChat(".mph_ui_teamer_"..playerData.PlayerID.."_reason_"..playerData.PlayerID.."_religion", -2,-1)
						else
					end
				end
			end
		end	
				end
			elseif #teamData.PlayerData > 0 then
				-- Display as single civ
				if teamData.PlayerData[1].ReligionType > 0 then
		local playerData = teamData.PlayerData[1]					
		if m_MPHEnabled == true then
			if #playerData.ConvertedCivs == totalCivs then
				if localID == Network.GetGameHostPlayerID() then
					Network.SendChat(".mph_ui_victor_"..playerData.PlayerID.."_reason_"..playerData.PlayerID.."_religion", -2,-1)
					for _, playerID in ipairs(PlayerManager.GetAliveMajorIDs()) do
						if Players[playerID] ~= nil and  playerID ~= playerData.PlayerID then
							if PlayerConfigurations[playerID]:GetLeaderTypeName() ~= "LEADER_SPECTATOR" and Players[playerID]:GetTeam() ~= Players[playerData.PlayerID]:GetTeam() then
								Network.SendChat(".mph_ui_defeat_"..playerID.."_reason_"..playerData.PlayerID.."_religion", -2,-1)
							end
							if PlayerConfigurations[playerID]:GetLeaderTypeName() ~= "LEADER_SPECTATOR" and Players[playerID]:GetTeam() == Players[playerData.PlayerID]:GetTeam() then
								Network.SendChat(".mph_ui_victor_"..playerID.."_reason_"..playerData.PlayerID.."_religion", -2,-1)
							end
						end
					end
					local teamIDs = GetRealAliveMajorTeamIDs()
					local count = 0
					for _, teamID in ipairs(teamIDs) do
						count = count + 1
					end
					if count > 1 then
						Network.SendChat(".mph_ui_teamer_"..playerData.PlayerID.."_reason_"..playerData.PlayerID.."_religion", -2,-1)
						else
					end
				end
			end
		end	
	
				end
			end
		end
	end

	
	local spec_count = 0
	local major_alive_count = 0
	for i = 0, 63 do
		if Players[i] ~= nil then
			if PlayerConfigurations[i]:GetLeaderTypeName() == "LEADER_SPECTATOR" then
				spec_count = spec_count + 1
			end
			if Players[i]:IsMajor() == true then
				major_alive_count = major_alive_count + 1
			end
		end
	end
	
	m_major_alive_count = major_alive_count
	m_spec_count = spec_count
end

Events.LocalPlayerTurnBegin.Add(		OnLocalPlayerTurnBegin );

function GetRealAliveMajorTeamIDs()
	local ti = 1;
	local result = {};
	local duplicate_team = {};
	for i,v in ipairs(PlayerManager.GetAliveMajors()) do
		local teamId = v:GetTeam();
		if PlayerConfigurations[v:GetID()]:GetLeaderTypeName() ~= "LEADER_SPECTATOR" then
			if(duplicate_team[teamId] == nil) then
				duplicate_team[teamId] = true;
				result[ti] = teamId;
				ti = ti + 1;
			end
		end
	end

	return result;
end
-- ===========================================================================
-- Overrides
-- ===========================================================================

-- Culture

function GatherCultureData()
	local data:table = {};
	local teamIDs = GetAliveMajorTeamIDs();
	for _, teamID in ipairs(teamIDs) do
		local team = Teams[teamID];
		if (team ~= nil) then
			local teamData:table = { TeamID = teamID, PlayerData = {}, BestNumVisitingUs = 0, BestNumRequiredTourists = 1 };

			-- Add players
			for i, playerID in ipairs(team) do
				if IsAliveAndMajor(playerID) then
					local pPlayer:table = Players[playerID];
					local pPlayerCulture:table = pPlayer:GetCulture();
					if PlayerConfigurations[playerID]:GetLeaderTypeName() == "LEADER_SPECTATOR" then
						if pPlayerCulture:GetStaycationers() > 0 then
							b_spec_send_tourists = true
						end
					end
					local VisitingUs = 0
					
					if b_spec_send_tourists == false then
						VisitingUs = math.floor( pPlayerCulture:GetTouristsTo()* ( (m_major_alive_count) / (m_major_alive_count-m_spec_count) ))
						else
						VisitingUs = pPlayerCulture:GetTouristsTo()
					end
					
					local playerData:table = { 
						PlayerID = playerID, 
						NumRequiredTourists = 0,
						NumStaycationers = pPlayerCulture:GetStaycationers(),
						NumVisitingUs = VisitingUs };

					-- Determine if this player is the closest to cultural victory
					playerData.TurnsTillCulturalVictory = pPlayerCulture.GetTurnsUntilVictory and pPlayerCulture:GetTurnsUntilVictory() or -1;
					if m_iTurnsTillCulturalVictory == -1 or m_iTurnsTillCulturalVictory > playerData.TurnsTillCulturalVictory then
						m_iTurnsTillCulturalVictory = playerData.TurnsTillCulturalVictory;
					end

					-- Determine number of tourist needed for victory
					-- Has to be one more than every other players number of domestic tourists
					for i, player in ipairs(Players) do
						if i ~= playerID and IsAliveAndMajor(i)  and player:GetTeam() ~= teamID then
							local iStaycationers = player:GetCulture():GetStaycationers();
							if iStaycationers >= playerData.NumRequiredTourists then
								playerData.NumRequiredTourists = iStaycationers + 1;
							end
						end
					end

					-- See if this player has the best score for this team
					local currentTeamScore:number = teamData.BestNumVisitingUs / teamData.BestNumRequiredTourists;
					local playerScore:number = playerData.NumVisitingUs / playerData.NumRequiredTourists;
					if currentTeamScore < playerScore or (currentTeamScore == playerScore and teamData.BestNumRequiredTourists < playerData.NumRequiredTourists) then
						teamData.BestNumVisitingUs = playerData.NumVisitingUs;
						teamData.BestNumRequiredTourists = playerData.NumRequiredTourists;
					end

					table.insert(teamData.PlayerData, playerData);
				end
			end

			-- Only add teams with at least one living, major player
			if #teamData.PlayerData > 0 then
				table.insert(data, teamData);
			end
		end
	end

	return data;
end

function PopulateCultureInstance(instance:table, playerData:table)
	local pPlayer:table = Players[playerData.PlayerID];
	local localID = Network.GetLocalPlayerID()
	
	PopulatePlayerInstanceShared(instance, playerData.PlayerID, 7);
	
	instance.VisitingTourists:SetText(playerData.NumVisitingUs .. "/" .. playerData.NumRequiredTourists);
	instance.TouristsFill:SetPercent(playerData.NumVisitingUs / playerData.NumRequiredTourists);
	instance.VisitingUsContainer:SetHide(playerData.PlayerID == m_LocalPlayerID);
	

	local backColor, _ = UI.GetPlayerColors(playerData.PlayerID);
	local brighterBackColor = UI.DarkenLightenColor(backColor,35,255);
	if(playerData.PlayerID == m_LocalPlayerID or m_LocalPlayer == nil or m_LocalPlayer:GetDiplomacy():HasMet(playerData.PlayerID)) then
		instance.DomesticTouristsIcon:SetColor(brighterBackColor);
	else
		instance.DomesticTouristsIcon:SetColor(UI.GetColorValue(1, 1, 1, 0.35));
	end
	instance.DomesticTourists:SetText(playerData.NumStaycationers);

	if(instance.TurnsTillVictory) then
		local iTurnsTillVictory:number = playerData.TurnsTillCulturalVictory;
		if(iTurnsTillVictory > 0 and iTurnsTillVictory >= m_iTurnsTillCulturalVictory) then
			instance.TurnsTillVictory:SetText(Locale.Lookup("LOC_WORLD_RANKINGS_CULTURAL_VICTORY_TURNS", iTurnsTillVictory));
			instance.TurnsTillVictory:SetToolTipString(Locale.Lookup("LOC_WORLD_RANKINGS_CULTURAL_VICTORY_TURNS_TT", iTurnsTillVictory));
			instance.TurnsTillVictory:SetHide(false);
		else
			instance.TurnsTillVictory:SetHide(true);
		end
	end

	if (m_LocalPlayer ~= nil) then
		local pLocalPlayerCulture:table = m_LocalPlayer:GetCulture();
		local VisitingUs = 0
		if b_spec_send_tourists == true then
			VisitingUs = pLocalPlayerCulture:GetTouristsFrom(playerData.PlayerID)
			else
			VisitingUs = math.floor(pLocalPlayerCulture:GetTouristsFrom(playerData.PlayerID) * (m_major_alive_count ) / (m_major_alive_count-m_spec_count))
		end
		instance.VisitingUsTourists:SetText(pLocalPlayerCulture:GetTouristsFrom(playerData.PlayerID));
		instance.VisitingUsTourists:SetToolTipString(pLocalPlayerCulture:GetTouristsFromTooltip(playerData.PlayerID));
		instance.VisitingUsIcon:SetToolTipString(pLocalPlayerCulture:GetTouristsFromTooltip(playerData.PlayerID));
	end
	
	if Players[playerData.PlayerID] ~= nil then
		if PlayerConfigurations[playerData.PlayerID]:GetLeaderTypeName() == "LEADER_SPECTATOR" then
			instance.VisitingTourists:SetText("");
			instance.TouristsFill:SetHide(true);
			if playerData.NumStaycationers == 0 then
				instance.DomesticTourists:SetText("");
				instance.DomesticTouristsIcon:SetHide(true);
				else
				instance.DomesticTouristsIcon:SetHide(false);
			end
		end
	end
	
	if(Game.IsVictoryEnabled("VICTORY_CULTURE")) then
		if m_MPHEnabled == true then
			if playerData.NumVisitingUs > playerData.NumRequiredTourists then
				if localID == Network.GetGameHostPlayerID() then
					Network.SendChat(".mph_ui_victor_"..playerData.PlayerID.."_reason_"..playerData.PlayerID.."_cultural", -2,-1)
					for _, playerID in ipairs(PlayerManager.GetAliveMajorIDs()) do
						if Players[playerID] ~= nil and  playerID ~= playerData.PlayerID then
							if PlayerConfigurations[playerID]:GetLeaderTypeName() ~= "LEADER_SPECTATOR" and Players[playerID]:GetTeam() ~= Players[playerData.PlayerID]:GetTeam() then
								Network.SendChat(".mph_ui_defeat_"..playerID.."_reason_"..playerData.PlayerID.."_cultural", -2,-1)
							end
							if PlayerConfigurations[playerID]:GetLeaderTypeName() ~= "LEADER_SPECTATOR" and Players[playerID]:GetTeam() == Players[playerData.PlayerID]:GetTeam() then
								Network.SendChat(".mph_ui_victor_"..playerID.."_reason_"..playerData.PlayerID.."_cultural", -2,-1)
							end
						end
					end
					local teamIDs = GetRealAliveMajorTeamIDs()
					local count = 0
					for _, teamID in ipairs(teamIDs) do
						count = count + 1
					end
					if count > 1 then
						Network.SendChat(".mph_ui_teamer_"..playerData.PlayerID.."_reason_"..playerData.PlayerID.."_cultural", -2,-1)
						else
					end
				end
			end
		end	
	end
end

-- religion

function PopulateReligionInstance(instance:table, playerData:table, totalCivs:number)

	BASE_PopulateReligionInstance(instance,playerData,totalCivs)

	if(Game.IsVictoryEnabled("VICTORY_RELIGIOUS")) then
		if m_MPHEnabled == true then
			if #playerData.ConvertedCivs == totalCivs then
				if localID == Network.GetGameHostPlayerID() then
					Network.SendChat(".mph_ui_victor_"..playerData.PlayerID.."_reason_"..playerData.PlayerID.."_religion", -2,-1)
					for _, playerID in ipairs(PlayerManager.GetAliveMajorIDs()) do
						if Players[playerID] ~= nil and  playerID ~= playerData.PlayerID then
							if PlayerConfigurations[playerID]:GetLeaderTypeName() ~= "LEADER_SPECTATOR" and Players[playerID]:GetTeam() ~= Players[playerData.PlayerID]:GetTeam() then
								Network.SendChat(".mph_ui_defeat_"..playerID.."_reason_"..playerData.PlayerID.."_religion", -2,-1)
							end
							if PlayerConfigurations[playerID]:GetLeaderTypeName() ~= "LEADER_SPECTATOR" and Players[playerID]:GetTeam() == Players[playerData.PlayerID]:GetTeam() then
								Network.SendChat(".mph_ui_victor_"..playerID.."_reason_"..playerData.PlayerID.."_religion", -2,-1)
							end
						end
					end
					local teamIDs = GetRealAliveMajorTeamIDs()
					local count = 0
					for _, teamID in ipairs(teamIDs) do
						count = count + 1
					end
					if count > 1 then
						Network.SendChat(".mph_ui_teamer_"..playerData.PlayerID.."_reason_"..playerData.PlayerID.."_religion", -2,-1)
						else
					end
				end
			end
		end	
	end	
	
	
end


function GatherReligionData()
	local data:table = {};
	local totalCivs:number = 0;

	local teamIDs = GetAliveMajorTeamIDs();
	for _, teamID in ipairs(teamIDs) do
		local team = Teams[teamID];
		if (team ~= nil) then
			local teamData:table = { TeamID = teamID, PlayerData = {}, ReligionTypes = {}, ConvertedCivs = {} };

			-- Add players
			for i, playerID in ipairs(team) do
				if IsAliveAndMajor(playerID) then
					totalCivs = totalCivs + 1;
					local pPlayer:table = Players[playerID];
					local playerData:table = { PlayerID = playerID, ConvertedCivs = {} };
					
					local pReligion = pPlayer:GetReligion();
					if pReligion ~= nil then
						playerData.ReligionType = pReligion:GetReligionTypeCreated();
						if playerData.ReligionType ~= -1 then
							
							-- Add religion to team religions if unique
							local containsReligion:boolean = false;
							for i, religionType in ipairs(teamData.ReligionTypes) do
								if religionType == playerData.ReligionType then
									containsReligion = true;
								end
							end
							if not containsReligion then
								table.insert(teamData.ReligionTypes, playerData.ReligionType );
							end

							-- Determine which civs our religion has taken over
							for otherID, player in ipairs(Players) do
								if IsAliveAndMajor(otherID) then
									local pOtherReligion = player:GetReligion();
									if pOtherReligion ~= nil then
										local otherReligionType:number = pOtherReligion:GetReligionInMajorityOfCities();
										if otherReligionType == playerData.ReligionType then
											table.insert(playerData.ConvertedCivs, otherID);
											
											-- Add convert civs to team converted civs if unique
											local containsCiv:boolean = false;
											for i, convertedCivID in ipairs(teamData.ConvertedCivs) do
												if convertedCivID == otherID then
													containsCiv = true;
												end
											end
											if not containsCiv then
												table.insert(teamData.ConvertedCivs, otherID );
											end
										end
									end
								end
							end
						end
					end

					table.insert(teamData.PlayerData, playerData);
				end
			end
			
			-- Only add teams with at least one living, major player
			if #teamData.PlayerData > 0 then
				table.insert(data, teamData);
			end
		end
	end
	totalCivs = totalCivs - m_spec_count
	return data, totalCivs;	
end

function GetCivNameAndIcon(playerID:number, bColorUnmetPlayer:boolean)
	local name:string, icon:string;
	local playerConfig:table = PlayerConfigurations[playerID];
	if(playerID == m_LocalPlayerID or playerConfig:IsHuman() or m_LocalPlayer == nil or m_LocalPlayer:GetDiplomacy():HasMet(playerID)) then
		name = Locale.Lookup(playerConfig:GetPlayerName());
		if GameConfiguration.GetValue("CPL_ANONYMOUS") == true then
			name = tostring("Anon_"..playerID)
		end
		if playerID == m_LocalPlayerID or m_LocalPlayer == nil or m_LocalPlayer:GetDiplomacy():HasMet(playerID) then
			icon = "ICON_" .. playerConfig:GetCivilizationTypeName();
		else
			icon = ICON_UNKNOWN_CIV;
		end
	else
		name = bColorUnmetPlayer and LOC_UNKNOWN_CIV_COLORED or LOC_UNKNOWN_CIV;
		icon = ICON_UNKNOWN_CIV;
	end
	return name, icon;
end