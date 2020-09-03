-- ==============================================================================
--	Even More Reports: Diplomacy (based on "HellBlazers World Info Interface")
--  Authors: Sam Batista, Faronizer
-- ==============================================================================
include("InstanceManager");
include("PopupDialog")
include("SupportFunctions" );
include("CitySupport");
include("Civ6Common");

if not ExposedMembers.EMR then ExposedMembers.EMR = {} end;
if not ExposedMembers.EMR.Diplomacy then ExposedMembers.EMR.Diplomacy = {} end;
local EMR = ExposedMembers.EMR.Diplomacy;

local m_DiplomacyIM = InstanceManager:new("DiplomacyInstance", "DiplomacyContainer", nil);	
local m_CurrentInstance = nil

local function GetInstance()
    m_CurrentInstance = m_DiplomacyIM:GetInstance();
    return m_CurrentInstance
end

local function BuildInstanceForControl(pInstanceTable, pControl)
    ContextPtr:BuildInstanceForControl("DiplomacyInstance", pInstanceTable, pControl);
end

-- ===========================================================================
--	CONSTANTS
-- ===========================================================================

local LOC_UNKNOWN_CIV:string = Locale.Lookup("LOC_WORLD_RANKING_UNMET_PLAYER");
local LOC_UNKNOWN_CIV_COLORED:string = Locale.Lookup("LOC_WORLD_RANKING_UNMET_PLAYER_COLORED");
local ICON_UNKNOWN_LEADER:string = "ICON_LEADER_UNKNOWN";
local ICON_UNKNOWN_CIV:string = "ICON_CIVILIZATION_UNKNOWN";
local DEFAULT_DIPLO_HEIGHT:number = 180;
local MAX_DIPLO_HEIGHT:number = 250;

local m_CivInfoIM			:table = InstanceManager:new("CivInstance",	"Content", nil);

-- ===========================================================================
--	PLAYER VARIABLES
-- ===========================================================================
local m_LocalPlayer:table;
local m_LocalPlayerID:number;
local m_PlayerCivicEras = {};
local m_PlayerTechEras = {};
local m_Eras = {};

-- ===========================================================================
--	Called every time screen is shown
-- ===========================================================================
function UpdatePlayerData()
	m_LocalPlayerID = Game.GetLocalPlayer();
	if m_LocalPlayerID ~= -1 then
		m_LocalPlayer = Players[m_LocalPlayerID];
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
		if (bspec == true) then
			if ( GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID) ~= nil and GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID) ~= 1000) then
				m_LocalPlayerID = GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID)
				m_LocalPlayer = Players[m_LocalPlayerID];
			end
		end
	end
end

-- ===========================================================================
--	Called every time screen is shown
-- ===========================================================================
function UpdateContent()
	local Controls = m_CurrentInstance
	local localPlayerID = Game.GetLocalPlayer();
	local m_LocalPlayer = Players[Game.GetLocalPlayer()];
    	local m_HideUnmetCivs = GameConfiguration.GetValue("EMR_PARAM_HIDE_UNMET_CIVS")
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
			if ( GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID) ~= nil and GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID) ~= 1000) then
				m_LocalPlayerID = GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID)
				localPlayerID = m_LocalPlayerID
				m_LocalPlayer = Players[m_LocalPlayerID];
				m_HideUnmetCivs = false
			end
		end
	end
    local gameEras:table = Game.GetEras();

    if m_HideUnmetCivs == nil then m_HideUnmetCivs = true end
 
	--clear any old instances
    m_CurrentInstance.CivStack:DestroyAllChildren();
    -- m_CivInfoIM:DestroyInstances();
   
	-- loop thru all players in the game
	local players = Game.GetPlayers();
	for i, player in ipairs(players) do
		-- get a new instance
		local PlayerID = player:GetID();
		local playerConfig = PlayerConfigurations[PlayerID]
		if ((player:IsAlive() == true and player:IsMajor() == true and (m_LocalPlayer:GetDiplomacy():HasMet(PlayerID) or not m_HideUnmetCivs)) or (localPlayerID == PlayerID)) and playerConfig:GetLeaderTypeName() ~= "LEADER_SPECTATOR" then
			local inst = m_CivInfoIM:GetInstance(m_CurrentInstance.CivStack);
			local playerCulture	:table	= player:GetCulture();

			if inst["w_Stack"] ~= nil then
				inst["w_Stack"]:ResetInstances();
			else
				inst["w_Stack"] = InstanceManager:new("WonderInstance", "Content", inst.WondersStack);
			end

			if inst["d_Stack"] ~= nil then
				inst["d_Stack"]:ResetInstances();
			else
				inst["d_Stack"] = InstanceManager:new("DiploInstance", "Content", inst.DiploStack);
			end

			--set the civ icon for this palyer
			local civName:string, civLeaderName:string, civIcon:string, civPortrait:string = GetCivNameAndIcon(PlayerID, true);
			--print("-----------------------------------------------------------------------------");
			--print("CivLeaderName: " .. tostring(civLeaderName)); --ICON_CIVILIZATION_UNKNOWN
			--print("CivName: " .. tostring(civName));
			
			--set civ leader, civ icon, civ name and leader name
			inst.Portrait:SetIcon(civPortrait);
			inst.CivIcon:SetIcon(civIcon);
			inst.CivLeaderName:SetText(civLeaderName);
			inst.CivName:SetText(civName);

			--set the civic and tech era
			local civicEra = Locale.Lookup('LOC_EMR_CIVIC_ERA') .. " " .. Locale.Lookup('LOC_' .. GameInfo.Eras[m_PlayerCivicEras[PlayerID]].EraType .. "_NAME");
			local techEra = Locale.Lookup('LOC_EMR_TECH_ERA') .. " " .. Locale.Lookup('LOC_' .. GameInfo.Eras[m_PlayerTechEras[PlayerID]].EraType .. "_NAME");
			inst.CivCivicEra:SetText(civicEra);
			inst.CivTechEra:SetText(techEra);
			
			--set the era age type
			if gameEras:HasHeroicGoldenAge(PlayerID) then
				inst.EraAgeType:SetText(Locale.Lookup("LOC_ERA_PROGRESS_HEROIC_AGE"));
			elseif gameEras:HasGoldenAge(PlayerID) then
				inst.EraAgeType:SetText(Locale.Lookup("LOC_ERA_PROGRESS_GOLDEN_AGE"));
			elseif gameEras:HasDarkAge(PlayerID) then
				inst.EraAgeType:SetText(Locale.Lookup("LOC_ERA_PROGRESS_DARK_AGE"));
			else
				inst.EraAgeType:SetText(Locale.Lookup("LOC_ERA_PROGRESS_NORMAL_AGE"));
			end

			--set the Governement
			inst.CivGovernment:SetText(Locale.Lookup("LOC_" .. GameInfo.Governments[playerCulture:GetCurrentGovernment()].GovernmentType .. "_NAME"));

			--set the wonders
			--loop thru this players cites checking for wonders
			local playerCities:table = player:GetCities();
			for i, city in playerCities:Members() do              
  				local cityData = GetCityData( city );

				local isHasWonders :boolean = (table.count(cityData.Wonders) > 0)
				if isHasWonders then
					
					for _, wonder in ipairs(cityData.Wonders) do
						local WonderInst = inst["w_Stack"]:GetInstance();
						WonderInst.WonderName:SetText(wonder.Name);
					end
				end
				inst.WondersStack:CalculateSize();
			end
			
			local p_Wars = {};
			local p_Suezerain = {};
			local p_Allied = {};
			local p_Friends = {};
			local p_Denounced = {};

			--set diplomatic states for each civ (only shows if local player has met BOTH civs or city states)
			for ii, OtherPlayer in ipairs(players) do
				local OtherPlayerID = OtherPlayer:GetID();
				local localPlayerDiplomacy = player:GetDiplomacy();

				if (OtherPlayer:IsAlive() and ((player:GetDiplomacy():HasMet(OtherPlayerID)) and (m_LocalPlayer:GetDiplomacy():HasMet(OtherPlayerID))) or not m_HideUnmetCivs) or (localPlayerID == OtherPlayerID) then
					-- local player has met both players, show any states between them
					if (not OtherPlayer:IsBarbarian()) and (not OtherPlayer:IsFreeCities()) then
						local playerConfig:table = PlayerConfigurations[OtherPlayerID];
						local civLeaderName = Locale.Lookup(playerConfig:GetPlayerName());
						local civName = Locale.Lookup("LOC_" .. playerConfig:GetCivilizationTypeName() .. "_NAME");
						local iPlayerDiploState = player:GetDiplomaticAI():GetDiplomaticStateIndex(OtherPlayerID);
						local eState = GameInfo.DiplomaticStates[iPlayerDiploState].Hash;
						local isPlayersAtWar = player:GetDiplomacy():IsAtWarWith(OtherPlayerID)
						local strInfo = "";

						--print("Civ State: " .. tostring(civName) .. " " ..  tostring(eState));

						-- check if players are at war
						if isPlayersAtWar then
                            strInfo = Locale.Lookup('LOC_EMR_AT_WAR') .. " " .. civName;
							-- strInfo = Locale.Lookup('LOC_EMR_AT_WAR') .. " " .. civName .. " (" .. civLeaderName .. ")";
							if (not OtherPlayer:IsMajor()) then
								strInfo = Locale.Lookup('LOC_EMR_AT_WAR') .. " " .. civName;
							end
							-- print(strInfo);
							table.insert(p_Wars, strInfo);
						end

						-- if this is not a mojor it must be a CS get influence
						if (not OtherPlayer:IsMajor()) then
							local pPlayerInfluence:table = OtherPlayer:GetInfluence();
							local suzerainID = pPlayerInfluence:GetSuzerain();

							-- check if this player is the suzerain of this CS
							if PlayerID == suzerainID then
								strInfo = Locale.Lookup('LOC_EMR_SUEZERAIN') .. " " .. civName;
								-- print(strInfo);
								table.insert(p_Suezerain, strInfo);
							end
						end

						if (OtherPlayer:IsMajor()) then
							if (eState == DiplomaticStates.ALLIED) then
								-- strInfo = Locale.Lookup('LOC_EMR_ALLIED') .. " " .. civName .. " (" .. civLeaderName .. ")";
								strInfo = Locale.Lookup('LOC_EMR_ALLIED') .. " " .. civName
                                -- print(strInfo);
								table.insert(p_Allied, strInfo);
							end

							if (eState == DiplomaticStates.DECLARED_FRIEND) then
								local iFriendshipTurn = localPlayerDiplomacy:GetDeclaredFriendshipTurn(OtherPlayerID);
								local iRemainingTurns = iFriendshipTurn + Game.GetGameDiplomacy():GetDenounceTimeLimit() - Game.GetCurrentGameTurn();
								-- strInfo = Locale.Lookup('LOC_EMR_FRIENDS') .. " " .. civName .. " (" .. civLeaderName .. ") " .. tostring(iRemainingTurns) .. " " .. Locale.Lookup('LOC_EMR_TURNS');
                                strInfo = Locale.Lookup('LOC_EMR_FRIENDS') .. " " .. civName .. " (" .. tostring(iRemainingTurns) .. " " .. Locale.Lookup('LOC_EMR_TURNS') .. ")";
								table.insert(p_Friends, strInfo);
							end

							if (eState == DiplomaticStates.DENOUNCED) then
								-- print("DENOUNCED: " .. PlayerID .. " " .. OtherPlayerID);
								local PlayerDiplomacy = player:GetDiplomacy();
								local iOurDenounceTurn = PlayerDiplomacy:GetDenounceTurn(OtherPlayerID);
								local iTheirDenounceTurn = Players[OtherPlayerID]:GetDiplomacy():GetDenounceTurn(PlayerID);
								
								if (iOurDenounceTurn >= iTheirDenounceTurn) then  
				    				iRemainingTurns = iOurDenounceTurn + Game.GetGameDiplomacy():GetDenounceTimeLimit() - Game.GetCurrentGameTurn();
				    				--strInfo = Locale.Lookup('LOC_EMR_DENOUNCED') .. " " .. civName .. " (" .. civLeaderName .. ") " .. tostring(iRemainingTurns) .. " " .. Locale.Lookup('LOC_EMR_TURNS');
									strInfo = Locale.Lookup('LOC_EMR_DENOUNCED') .. " " .. civName .. " (" .. tostring(iRemainingTurns) .. " " .. Locale.Lookup('LOC_EMR_TURNS') .. ")";
                                    -- print(strInfo);
									table.insert(p_Denounced, strInfo);
				    			else
				    				iRemainingTurns = iTheirDenounceTurn + Game.GetGameDiplomacy():GetDenounceTimeLimit() - Game.GetCurrentGameTurn();
				    				-- strInfo = Locale.Lookup('LOC_EMR_DENOUNCED_BY') .. " " .. civName .. " (" .. civLeaderName .. ") " .. tostring(iRemainingTurns) .. " " .. Locale.Lookup('LOC_EMR_TURNS');
                                    strInfo = Locale.Lookup('LOC_EMR_DENOUNCED_BY') .. " " .. civName .. " (" .. tostring(iRemainingTurns) .. " " .. Locale.Lookup('LOC_EMR_TURNS') .. ")";
									-- print(strInfo);
									table.insert(p_Denounced, strInfo);
				    			end
							end
						end
					end
				end
			end

			for key, value in pairs(p_Wars) do
				local DiploInst = inst["d_Stack"]:GetInstance();
				DiploInst.DiploState:SetText("[COLOR_Civ6Red][ICON_BULLET]" .. value .. "[ENDCOLOR]");
			end
			
			for key, value in pairs(p_Denounced) do
				local DiploInst = inst["d_Stack"]:GetInstance();
				DiploInst.DiploState:SetText("[COLOR_Civ6Yellow][ICON_BULLET]" .. value .. "[ENDCOLOR]");
			end

			for key, value in pairs(p_Friends) do
				local DiploInst = inst["d_Stack"]:GetInstance();
				DiploInst.DiploState:SetText("[COLOR_Civ6Green][ICON_BULLET]" .. value .. "[ENDCOLOR]");
			end

			for key, value in pairs(p_Allied) do
				local DiploInst = inst["d_Stack"]:GetInstance();
				DiploInst.DiploState:SetText("[COLOR_Green][ICON_BULLET]" .. value .. "[ENDCOLOR]");
			end

			for key, value in pairs(p_Suezerain) do
				local DiploInst = inst["d_Stack"]:GetInstance();
				DiploInst.DiploState:SetText("[COLOR_Civ6LightBlue][ICON_BULLET]" .. value .. "[ENDCOLOR]");
			end

			inst.DiploStack:ReprocessAnchoring();
			inst.DiploStack:CalculateSize();

			local WonderStackHeight = inst.WondersStack:GetSizeY()+inst.WondersStack:GetOffsetY();
			local DiploStackHeight = inst.DiploStack:GetSizeY()+inst.DiploStack:GetOffsetY();
			local instHeight = inst.Content:GetSizeY();
			local BiggestStack = WonderStackHeight;

			if DiploStackHeight > WonderStackHeight then
				BiggestStack = DiploStackHeight;
			end

			if (BiggestStack > MAX_DIPLO_HEIGHT) then
				inst.Content:SetSizeY(MAX_DIPLO_HEIGHT);
				instHeight = inst.Content:GetSizeY();
			end
			
			if (instHeight < DEFAULT_DIPLO_HEIGHT) then
				-- inst.Content:SetSizeY(DEFAULT_DIPLO_HEIGHT);
			end
		end
	end

	Controls.GlobalDiploScrollPanel:ReprocessAnchoring();
	Controls.GlobalDiploScrollPanel:CalculateSize();
    
end

-- ===========================================================================
function OnResearchComplete(ePlayer:number, eTech:number)
		--check if the current tech completed era is above our current stored era
	if (m_Eras[m_PlayerTechEras[ePlayer]] == nil) then
		m_PlayerTechEras[ePlayer] = GameInfo.Technologies[eTech].EraType;
	elseif (m_Eras[GameInfo.Technologies[eTech].EraType] > m_Eras[m_PlayerTechEras[ePlayer]]) then
		m_PlayerTechEras[ePlayer] = GameInfo.Technologies[eTech].EraType;
	end
end

-- ===========================================================================
function OnCivicComplete(ePlayer:number, eTech:number)

	--check if the current civic completed era is above our current stored era
	if (m_Eras[m_PlayerCivicEras[ePlayer]] == nil) then
		m_PlayerCivicEras[ePlayer] = GameInfo.Civics[eTech].EraType;
	elseif (m_Eras[GameInfo.Civics[eTech].EraType] > m_Eras[m_PlayerCivicEras[ePlayer]]) then
		m_PlayerCivicEras[ePlayer] = GameInfo.Civics[eTech].EraType;
	end
end

-- ===========================================================================
function PopulateEras()
	for row in GameInfo.Eras() do
		m_Eras[row.EraType] = row.ChronologyIndex;
	end

	-- loop thru players and initilize tech and civic era
	local players = Game.GetPlayers();
	for i, player in ipairs(players) do
		local playerCulture	:table	= player:GetCulture();
		local playerTech	:table	= player:GetTechs();
		local civicDone = false;
		local techDone = false;

		for civic in GameInfo.Civics() do
			if playerCulture:HasCivic(civic.Index) then
				OnCivicComplete(player:GetID(), civic.Index)
				civicDone = true;
			end
		end

		for tech in GameInfo.Technologies() do
			if playerTech:HasTech(tech.Index) then
				OnResearchComplete(player:GetID(), tech.Index)
				techDone = true;
			end
		end

		if civicDone == false then
			m_PlayerCivicEras[player:GetID()] = 0;
		end

		if techDone == false then
			m_PlayerTechEras[player:GetID()] = 0;
		end
	end
end

-- ===========================================================================
function makeIdx(pOneID:number, pTwoID:number)
	local playerConfig:table = PlayerConfigurations[pOneID];
	local player2Config:table = PlayerConfigurations[pTwoID];

	local civName = Locale.Lookup("LOC_" .. playerConfig:GetCivilizationTypeName() .. "_NAME");
	local civName2 = Locale.Lookup("LOC_" .. player2Config:GetCivilizationTypeName() .. "_NAME");
	--print(civName..civName2)
	return civName..civName2;
end
-- ===========================================================================
function format_int(number)

  local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')

  -- reverse the int-string and append a comma to all blocks of 3 digits
  int = int:reverse():gsub("(%d%d%d)", "%1,")

  -- reverse the int-string back remove an optional comma and put the 
  -- optional minus and fractional part back
  return minus .. int:reverse():gsub("^,", "") .. fraction
end

-- ===========================================================================
function GetCivNameAndIcon(playerID:number, bColorUnmetPlayer:boolean)
	local civname:string, leadername:string, icon:string, portrait:string;
	local m_LocalPlayer = Players[Game.GetLocalPlayer()];
	local m_LocalPlayerID = Game.GetLocalPlayer();
	local bspec = false
	local spec_ID = 0
	local m_HideUnmetCivs = GameConfiguration.GetValue("EMR_PARAM_HIDE_UNMET_CIVS")
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
			if ( GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID) ~= nil and GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID) ~= 1000) then
				m_LocalPlayerID = GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID)
				localPlayerID = m_LocalPlayerID
				m_LocalPlayer = Players[m_LocalPlayerID];
				m_HideUnmetCivs = false
			end
		end
	end
    
    if m_HideUnmetCivs == nil then m_HideUnmetCivs = true end
	local playerConfig:table = PlayerConfigurations[playerID];

	if(playerID == m_LocalPlayerID or playerConfig:IsHuman() or m_LocalPlayer == nil or m_LocalPlayer:GetDiplomacy():HasMet(playerID)) or not m_HideUnmetCivs then
		leadername = Locale.Lookup(playerConfig:GetPlayerName());
		civname = Locale.Lookup("LOC_" .. playerConfig:GetCivilizationTypeName() .. "_NAME");

		if playerID == m_LocalPlayerID or m_LocalPlayer == nil or m_LocalPlayer:GetDiplomacy():HasMet(playerID) or not m_HideUnmetCivs then
			portrait = "ICON_" .. playerConfig:GetLeaderTypeName();
			icon = "ICON_" .. playerConfig:GetCivilizationTypeName();
		else
			portrait = ICON_UNKNOWN_LEADER;
			icon = ICON_UNKNOWN_CIV;
		end
	else
		--print("Unmet civ");
		leadername = bColorUnmetPlayer and LOC_UNKNOWN_CIV_COLORED or LOC_UNKNOWN_CIV;
		portrait = ICON_UNKNOWN_CIV;
		icon = ICON_UNKNOWN_CIV;
	end
	return civname, leadername, icon, portrait;
end

function ColorIcon(PlayerID, cControlIcon, cControlBacking)
	--print(PlayerID, cControlIcon, cControlBacking);
	local civName:string, civIcon:string = GetCivNameAndIcon(PlayerID, true);
	--print("CivName=".. civName);
	--print("CivIcon=".. civIcon);

	if (civIcon == "ICON_CIVILIZATION_UNKNOWN") then
		--print("Unmet civ x");
		cControlBacking:SetColor(0xFF9E9382);
		cControlIcon:SetColor(0xFFFFFFFF);
		local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas(civIcon, 36);
		cControlIcon:SetTexture(textureOffsetX, textureOffsetY, textureSheet);
	else
		
		local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas(civIcon, 36);
		local backColor, frontColor = UI.GetPlayerColors(PlayerID);
		cControlIcon:SetTexture(textureOffsetX, textureOffsetY, textureSheet);
		cControlIcon:SetColor(frontColor);
		cControlBacking:SetColor(backColor);
	end
end

-- ===========================================================================
--	INIT
-- ===========================================================================
function Initialize()
    PopulateEras();
	EMR.GetInstance = GetInstance
    EMR.BuildInstanceForControl = BuildInstanceForControl
    EMR.UpdateContent = UpdateContent
    
    Events.CivicCompleted.Add( OnCivicComplete );
	Events.ResearchCompleted.Add( OnResearchComplete );
end
Initialize();
