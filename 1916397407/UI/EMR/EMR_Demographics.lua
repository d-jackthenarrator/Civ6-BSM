-- ==============================================================================
--	Even More Reports: Demographics (based on "HellBlazers World Info Interface")
--  Authors: Sam Batista, Faronizer, D. / Jack The Narrator
-- ==============================================================================
include("InstanceManager");
include("PopupDialog")
include("SupportFunctions");

if not ExposedMembers.EMR then ExposedMembers.EMR = {} end;
if not ExposedMembers.EMR.Demographics then ExposedMembers.EMR.Demographics = {} end;
local EMR = ExposedMembers.EMR.Demographics;

local m_DemographicsIM = InstanceManager:new("DemographicsInstance", "DemographicsContainer", nil);	
local m_CurrentInstance = nil

local function GetInstance()
    m_CurrentInstance = m_DemographicsIM:GetInstance();
    return m_CurrentInstance
end

local function BuildInstanceForControl(pInstanceTable, pControl)
    ContextPtr:BuildInstanceForControl("DemographicsInstance", pInstanceTable, pControl);
end

-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local LOC_UNKNOWN_CIV:string = Locale.Lookup("LOC_WORLD_RANKING_UNMET_PLAYER");
local LOC_UNKNOWN_CIV_COLORED:string = Locale.Lookup("LOC_WORLD_RANKING_UNMET_PLAYER_COLORED");
local ICON_UNKNOWN_CIV:string = "ICON_CIVILIZATION_UNKNOWN";

local YIELD_FONT_ICONS:table = {
	YIELD_FOOD				= "[ICON_FoodLarge]",
	YIELD_PRODUCTION		= "[ICON_ProductionLarge]",
	YIELD_GOLD				= "[ICON_GoldLarge]",
	YIELD_SCIENCE			= "[ICON_ScienceLarge]",
	YIELD_CULTURE			= "[ICON_CultureLarge]",
	YIELD_FAITH				= "[ICON_FaithLarge]",
	YIELD_TOURISM			= "[ICON_TourismLarge]"
};

-- ===========================================================================
--	PLAYER VARIABLES
-- ===========================================================================
local m_LocalPlayer:table;
local m_LocalPlayerID:number;

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
	local DemoData :table = {};
	local localPlayerID = Game.GetLocalPlayer();
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
			end
		end
	end
	local Best :table = {
			Pop = 0,
			PopID = 0,
			Crop = 0,
			CropID = 0,
		  	Prod = 0;
		  	ProdID = 0,
		  	GNP = 0,
		  	GNPID = 0,
		  	Military = 0,
		  	MilitaryID = 0,
		  	Faith = 0,
		  	FaithID = 0,
		  	Tourism = 0,
		  	TourismID = 0,
		  	Happy = -10000,
		  	HappyID = 0,
		  	Culture = 0,
		  	CultureID = 0,
		  	Science = 0,
		  	ScienceID = 0
	};

	local Worst :table = {
			Pop = 10000000000000,
			PopID = 0,
			Crop = 10000,
			CropID = 0,
		  	Prod = 10000;
		  	ProdID = 0,
		  	GNP = 10000,
		  	GNPID = 0,
		  	Military = 10000,
		  	MilitaryID = 0,
		  	Faith = 10000,
		  	FaithID = 0,
		  	Tourism = 10000,
		  	TourismID = 0,
		  	Happy = 10000,
		  	HappyID = 0,
		  	Culture = 10000,
		  	CultureID = 0,
		  	Science = 10000,
		  	ScienceID = 0
	};

	local RankData :table = {
		  	Pop = 1,
		  	Crop = 1,
		  	Prod = 1,
		  	GNP = 1,
		  	Military = 1,
		  	Faith = 1,
		  	Tourism = 1,
		  	Happy = 1,
		  	Culture = 1,
		  	Science = 1
	};

	--print("Local Player: " .. localPlayerID);
	
	local players = Game.GetPlayers();

	local players = Game.GetPlayers();
	for i, player in ipairs(players) do
			
		local playerID = player:GetID();
		local playerCities = players[i]:GetCities();
		local playerConfig:table = PlayerConfigurations[playerID];
		local playerData :table = {
		  	Pop = 0,
		  	Crop = 0,
		  	Prod = 0,
		  	GNP = 0,
		  	Military = 0,
		  	Faith = 0,
		  	Tourism = 0,
		  	Happy = 60,
		  	Culture = 0,
		  	Science = 0
		};
		
		 if (player:IsAlive() == true and player:IsMajor() == true and playerConfig:GetLeaderTypeName() ~= "LEADER_SPECTATOR") then
			for ii, city in playerCities:Members() do

				local cityID		:number = city:GetID();

				local cityPop		:number = city:GetPopulation();
				local cityProd		:number = Round(city:GetYield(YieldTypes.PRODUCTION),1);
				local cityFaith		:number = Round(city:GetYield(YieldTypes.FAITH), 1);
				local cityGold		:number = Round(city:GetYield(YieldTypes.GOLD), 1);
				local cityFood		:number = Round(city:GetYield(YieldTypes.FOOD), 1);
				local pCityGrowth	:table = city:GetGrowth();

				playerData.Pop = playerData.Pop + math.floor(math.pow((cityPop),2.8))*1000;

				playerData.Crop = playerData.Crop + cityFood;

				playerData.Prod = playerData.Prod + cityProd;

				playerData.Faith = playerData.Faith + cityFaith;

				playerData.GNP = playerData.GNP + cityGold;

				playerData.Happy = playerData.Happy + ((pCityGrowth:GetAmenities() - pCityGrowth:GetAmenitiesNeeded())*3);
				
			end

			if (playerData.Happy > 100) then
				playerData.Happy = 100;
			end

			if (playerData.Happy < 0) then
				playerData.Happy = 0;
			end

			playerData.Tourism = player:GetStats():GetTourism();
			playerData.Military = player:GetStats():GetMilitaryStrengthWithoutTreasury();
			
			playerData.Science = Round((100/68) * player:GetStats():GetNumTechsResearched());
			playerData.Culture = player:GetCategoryScore(0);
			--print("Civics: " .. playerData.Culture);

			--check to see if anything is better than the best
			if (playerData.Pop >= Best.Pop) then
				Best.Pop = playerData.Pop;
				Best.PopID = playerID;
			end
			if (playerData.Crop >= Best.Crop) then
				Best.Crop = playerData.Crop;
				Best.CropID = playerID;
			end
			if (playerData.Prod >= Best.Prod) then
				Best.Prod = playerData.Prod;
				Best.ProdID = playerID;
			end
			if (playerData.GNP >= Best.GNP) then
				Best.GNP = playerData.GNP;
				Best.GNPID = playerID;
			end
			if (playerData.Faith >= Best.Faith) then
				Best.Faith = playerData.Faith;
				Best.FaithID = playerID;
			end
			if (playerData.Tourism >= Best.Tourism) then
				Best.Tourism = playerData.Tourism;
				Best.TourismID = playerID;
			end
			if (playerData.Military >= Best.Military) then
				Best.Military = playerData.Military;
				Best.MilitaryID = playerID;
			end
			if (playerData.Happy >= Best.Happy) then
				Best.Happy = playerData.Happy;
				Best.HappyID = playerID;
			end
			if (playerData.Science >= Best.Science) then
				Best.Science = playerData.Science;
				Best.ScienceID = playerID;
			end
			if (playerData.Culture >= Best.Culture) then
				Best.Culture = playerData.Culture;
				Best.CultureID = playerID;
			end

			--check to see if anything is worse than the worst
			if (playerData.Pop < Worst.Pop) then
				Worst.Pop = playerData.Pop;
				Worst.PopID = playerID;
			end
			if (playerData.Crop < Worst.Crop) then
				Worst.Crop = playerData.Crop;
				Worst.CropID = playerID;
			end
			if (playerData.Prod < Worst.Prod) then
				Worst.Prod = playerData.Prod;
				Worst.ProdID = playerID;
			end
			if (playerData.GNP < Worst.GNP) then
				Worst.GNP = playerData.GNP;
				Worst.GNPID = playerID;
			end
			if (playerData.Faith < Worst.Faith) then
				Worst.Faith = playerData.Faith;
				Worst.FaithID = playerID;
			end
			if (playerData.Tourism < Worst.Tourism) then
				Worst.Tourism = playerData.Tourism;
				Worst.TourismID = playerID;
			end
			if (playerData.Military < Worst.Military) then
				Worst.Military = playerData.Military;
				Worst.MilitaryID = playerID;
			end
			if (playerData.Happy < Worst.Happy) then
				Worst.Happy = playerData.Happy;
				Worst.HappyID = playerID;
			end
			if (playerData.Science < Worst.Science) then
				Worst.Science = playerData.Science;
				Worst.ScienceID = playerID;
			end
			if (playerData.Culture < Worst.Culture) then
				Worst.Culture = playerData.Culture;
				Worst.CultureID = playerID;
			end

			DemoData[playerID] = {
				Population = playerData.Pop,
				Crop = playerData.Crop,
				Production = playerData.Prod,
				GNP = playerData.GNP,
				Faith = playerData.Faith,
				Tourism = playerData.Tourism,
				Military = playerData.Military,
				Happy = playerData.Happy,
				Science = playerData.Science,
				Culture = playerData.Culture
			};
		end
	end

	-- set the values for the current player
	Controls.ValuePop:SetText(format_int(DemoData[localPlayerID].Population));
	Controls.ValueProd:SetText(DemoData[localPlayerID].Production);
	Controls.ValueFaith:SetText(DemoData[localPlayerID].Faith);
	Controls.ValueGNP:SetText(DemoData[localPlayerID].GNP);
	Controls.ValueTour:SetText(DemoData[localPlayerID].Tourism);
	Controls.ValueCrop:SetText(DemoData[localPlayerID].Crop);
	Controls.ValueArmy:SetText(DemoData[localPlayerID].Military);
	Controls.ValueHappy:SetText(DemoData[localPlayerID].Happy.. "%");
	Controls.ValueTech:SetText(DemoData[localPlayerID].Science.. "%");
	Controls.ValueCivics:SetText(DemoData[localPlayerID].Culture.. "%");

	-- set the details for best demos
	Controls.BestPop:SetText("[COLOR_Civ6Green]" .. format_int(Best.Pop) .. "[ENDCOLOR]");
	ColorIcon(Best.PopID, Controls.CivIconBestPop, Controls.CivIconBackingBestPop)

	Controls.BestProd:SetText("[COLOR_Civ6Green]" .. Best.Prod .. "[ENDCOLOR]");
	ColorIcon(Best.ProdID, Controls.CivIconBestProd, Controls.CivIconBackingBestProd)

	Controls.BestFaith:SetText("[COLOR_Civ6Green]" .. Best.Faith .. "[ENDCOLOR]");
	ColorIcon(Best.FaithID, Controls.CivIconBestFaith, Controls.CivIconBackingBestFaith)

	Controls.BestGNP:SetText("[COLOR_Civ6Green]" .. Best.GNP .. "[ENDCOLOR]");
	ColorIcon(Best.GNPID, Controls.CivIconBestGNP, Controls.CivIconBackingBestGNP)

	Controls.BestTour:SetText("[COLOR_Civ6Green]" .. Best.Tourism .. "[ENDCOLOR]");
	ColorIcon(Best.TourismID, Controls.CivIconBestTour, Controls.CivIconBackingBestTour)

	Controls.BestCrop:SetText("[COLOR_Civ6Green]" .. Best.Crop .. "[ENDCOLOR]");
	ColorIcon(Best.CropID, Controls.CivIconBestCrop, Controls.CivIconBackingBestCrop)

	Controls.BestArmy:SetText("[COLOR_Civ6Green]" .. Best.Military .. "[ENDCOLOR]");
	ColorIcon(Best.MilitaryID, Controls.CivIconBestArmy, Controls.CivIconBackingBestArmy)

	Controls.BestHappy:SetText("[COLOR_Civ6Green]" .. Best.Happy.. "%" .. "[ENDCOLOR]");
	ColorIcon(Best.HappyID, Controls.CivIconBestHappy, Controls.CivIconBackingBestHappy)
	
	Controls.BestTech:SetText("[COLOR_Civ6Green]" .. Best.Science.. "%" .. "[ENDCOLOR]");
	ColorIcon(Best.ScienceID, Controls.CivIconBestTech, Controls.CivIconBackingBestTech)
	
	Controls.BestCivics:SetText("[COLOR_Civ6Green]" .. Best.Culture.. "%" .. "[ENDCOLOR]");
	ColorIcon(Best.CultureID, Controls.CivIconBestCivics, Controls.CivIconBackingBestCivics)

	-- set the details for worse demos
	Controls.WorstPop:SetText("[COLOR_Civ6Red]" .. format_int(Worst.Pop) .. "[ENDCOLOR]");
	ColorIcon(Worst.PopID, Controls.CivIconWorstPop, Controls.CivIconBackingWorstPop)

	Controls.WorstProd:SetText("[COLOR_Civ6Red]" .. Worst.Prod .. "[ENDCOLOR]");
	ColorIcon(Worst.ProdID, Controls.CivIconWorstProd, Controls.CivIconBackingWorstProd)

	Controls.WorstFaith:SetText("[COLOR_Civ6Red]" .. Worst.Faith .. "[ENDCOLOR]");
	ColorIcon(Worst.FaithID, Controls.CivIconWorstFaith, Controls.CivIconBackingWorstFaith)

	Controls.WorstGNP:SetText("[COLOR_Civ6Red]" .. Worst.GNP .. "[ENDCOLOR]");
	ColorIcon(Worst.GNPID, Controls.CivIconWorstGNP, Controls.CivIconBackingWorstGNP)

	Controls.WorstTour:SetText("[COLOR_Civ6Red]" .. Worst.Tourism .. "[ENDCOLOR]");
	ColorIcon(Worst.TourismID, Controls.CivIconWorstTour, Controls.CivIconBackingWorstTour)

	Controls.WorstCrop:SetText("[COLOR_Civ6Red]" .. Worst.Crop .. "[ENDCOLOR]");
	ColorIcon(Worst.CropID, Controls.CivIconWorstCrop, Controls.CivIconBackingWorstCrop)

	Controls.WorstArmy:SetText("[COLOR_Civ6Red]" .. Worst.Military .. "[ENDCOLOR]");
	ColorIcon(Worst.MilitaryID, Controls.CivIconWorstArmy, Controls.CivIconBackingWorstArmy)

	Controls.WorstHappy:SetText("[COLOR_Civ6Red]" .. Worst.Happy.. "%" .. "[ENDCOLOR]");
	ColorIcon(Worst.HappyID, Controls.CivIconWorstHappy, Controls.CivIconBackingWorstHappy)

	Controls.WorstTech:SetText("[COLOR_Civ6Red]" .. Worst.Science.. "%" .. "[ENDCOLOR]");
	ColorIcon(Worst.ScienceID, Controls.CivIconWorstTech, Controls.CivIconBackingWorstTech)

	Controls.WorstCivics:SetText("[COLOR_Civ6Red]" .. Worst.Culture.. "%" .. "[ENDCOLOR]");
	ColorIcon(Worst.CultureID, Controls.CivIconWorstCivics, Controls.CivIconBackingWorstCivics)

	local AvgData :table = {
	  	Pop = 0,
	  	Crop = 0,
	  	Prod = 0,
	  	GNP = 0,
	  	Military = 0,
	  	Faith = 0,
	  	Tourism = 0,
	  	Happy = 0,
	  	Culture = 0,
	  	Science = 0
	};

	local playerCount = 0;

	-- set the ranks
	for i, player in ipairs(players) do
		local playerID = player:GetID();
		local playerConfig:table = PlayerConfigurations[playerID];
		if (player:IsAlive() == true and player:IsMajor() == true and playerConfig:GetLeaderTypeName() ~= "LEADER_SPECTATOR") then
			
			--print("Rank: PlayerID: " .. playerID);
			--print("Rank: Local PlayerID: " .. localPlayerID);
		
			if (playerID ~= localPlayerID) then
				if DemoData[playerID].Population >= DemoData[localPlayerID].Population then
					RankData.Pop = RankData.Pop + 1;
				end

				if DemoData[playerID].Production >= DemoData[localPlayerID].Production then
					RankData.Prod = RankData.Prod + 1;
				end

				if DemoData[playerID].GNP >= DemoData[localPlayerID].GNP then
					RankData.GNP = RankData.GNP + 1;
				end

				if DemoData[playerID].Faith >= DemoData[localPlayerID].Faith then
					RankData.Faith = RankData.Faith + 1;
				end

				if DemoData[playerID].Tourism >= DemoData[localPlayerID].Tourism then
					RankData.Tourism = RankData.Tourism + 1;
				end

				if DemoData[playerID].Crop >= DemoData[localPlayerID].Crop then
					RankData.Crop = RankData.Crop + 1;
				end

				if DemoData[playerID].Military >= DemoData[localPlayerID].Military then
					RankData.Military = RankData.Military + 1;
				end

				if DemoData[playerID].Happy >= DemoData[localPlayerID].Happy then
					RankData.Happy = RankData.Happy + 1;
				end

				if DemoData[playerID].Science >= DemoData[localPlayerID].Science then
					RankData.Science = RankData.Science + 1;
				end

				if DemoData[playerID].Culture >= DemoData[localPlayerID].Culture then
					RankData.Culture = RankData.Culture + 1;
				end
			end

			AvgData.Pop = AvgData.Pop + DemoData[playerID].Population;
			AvgData.Crop = AvgData.Crop + DemoData[playerID].Crop;
			AvgData.Prod = AvgData.Prod + DemoData[playerID].Production;
			AvgData.GNP = AvgData.GNP + DemoData[playerID].GNP;
			AvgData.Military = AvgData.Military + DemoData[playerID].Military;
			AvgData.Faith = AvgData.Faith + DemoData[playerID].Faith;
			AvgData.Tourism = AvgData.Tourism + DemoData[playerID].Tourism;
			AvgData.Happy = AvgData.Happy + DemoData[playerID].Happy;
			AvgData.Culture = AvgData.Culture + DemoData[playerID].Culture;
			AvgData.Science = AvgData.Science + DemoData[playerID].Science;

			playerCount = playerCount +1
		end
	end

	--print("Count is: " .. playerCount);
	-- set the averages
	local AvgHappy = "";

	Controls.AvgPop:SetText("[COLOR_Civ6Yellow]" .. format_int(Round((AvgData.Pop/playerCount),0)) .. "[ENDCOLOR]");
	Controls.AvgProd:SetText("[COLOR_Civ6Yellow]" .. Round((AvgData.Prod/playerCount),1) .. "[ENDCOLOR]");
	Controls.AvgGNP:SetText("[COLOR_Civ6Yellow]" .. Round((AvgData.GNP/playerCount),1) .. "[ENDCOLOR]");
	Controls.AvgFaith:SetText("[COLOR_Civ6Yellow]" .. Round((AvgData.Faith/playerCount),1) .. "[ENDCOLOR]");
	Controls.AvgTour:SetText("[COLOR_Civ6Yellow]" .. Round((AvgData.Tourism/playerCount),1) .. "[ENDCOLOR]");
	Controls.AvgCrop:SetText("[COLOR_Civ6Yellow]" .. Round((AvgData.Crop/playerCount),1) .. "[ENDCOLOR]");
	Controls.AvgArmy:SetText("[COLOR_Civ6Yellow]" .. Round((AvgData.Military/playerCount),0) .. "[ENDCOLOR]");
	Controls.AvgHappy:SetText("[COLOR_Civ6Yellow]" .. Round((AvgData.Happy/playerCount),0) .. "%" .. "[ENDCOLOR]");
	Controls.AvgTech:SetText("[COLOR_Civ6Yellow]" .. Round((AvgData.Science/playerCount),0) .. "%" .. "[ENDCOLOR]");
	Controls.AvgCivics:SetText("[COLOR_Civ6Yellow]" .. Round((AvgData.Culture/playerCount),0) .. "%" .. "[ENDCOLOR]");

	-- set the local players ranks
	Controls.RankPop:SetText(RankData.Pop);
	Controls.RankProd:SetText(RankData.Prod);
	Controls.RankGNP:SetText(RankData.GNP);
	Controls.RankFaith:SetText(RankData.Faith);
	Controls.RankTour:SetText(RankData.Tourism);
	Controls.RankCrop:SetText(RankData.Crop);
	Controls.RankArmy:SetText(RankData.Military);
	Controls.RankHappy:SetText(RankData.Happy);
	Controls.RankTech:SetText(RankData.Science);
	Controls.RankCivics:SetText(RankData.Culture);
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
function GetPlayerNameAndIcon(playerID:number, bColorUnmetPlayer:boolean)
	local name:string, icon:string;
	local m_LocalPlayer = Players[Game.GetLocalPlayer()]
	local m_LocalPlayerID = Game.GetLocalPlayer();
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
				m_LocalPlayer = Players[m_LocalPlayerID];
				m_HideUnmetCivs = false
			end
		end
	end
    if m_HideUnmetCivs == nil then m_HideUnmetCivs = true end

	local playerConfig:table = PlayerConfigurations[playerID];
	
	if(playerID == m_LocalPlayerID or playerConfig:IsHuman() or m_LocalPlayer == nil or m_LocalPlayer:GetDiplomacy():HasMet(playerID)) or not m_HideUnmetCivs then
		name = Locale.Lookup(playerConfig:GetPlayerName());
		
		if playerID == m_LocalPlayerID or m_LocalPlayer == nil or m_LocalPlayer:GetDiplomacy():HasMet(playerID) or not m_HideUnmetCivs then
			icon = "ICON_" .. playerConfig:GetCivilizationTypeName();
		else
			icon = ICON_UNKNOWN_CIV;
		end
	else
		--print("Unmet civ");
		name = bColorUnmetPlayer and LOC_UNKNOWN_CIV_COLORED or LOC_UNKNOWN_CIV;
		icon = ICON_UNKNOWN_CIV;
	end
	return name, icon;
end

function ColorIcon(PlayerID, cControlIcon, cControlBacking)
	--print(PlayerID, cControlIcon, cControlBacking);
    local civName:string = PlayerConfigurations[PlayerID]:GetCivilizationDescription()
	local playerName:string, civIcon:string = GetPlayerNameAndIcon(PlayerID, true);
	--print("CivName=".. civName);
	--print("CivIcon=".. civIcon);

    
	if (civIcon == "ICON_CIVILIZATION_UNKNOWN") then
		--print("Unmet civ x");
		--cControlBacking:SetColor(0xFF9E9382);
		--cControlIcon:SetColor(0xFFFFFFFF);
        cControlIcon:SetColor(1, 1, 1, 0.95);
        cControlBacking:SetColor(1, 1, 1, 0);
		local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas(civIcon, 36);
		cControlIcon:SetTexture(textureOffsetX, textureOffsetY, textureSheet);
	else
		cControlIcon:SetToolTipString(Locale.Lookup(playerName) .. " (" .. Locale.Lookup(civName) .. ")");
		local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas(civIcon, 36);
		local backColor, frontColor = UI.GetPlayerColors(PlayerID);
		cControlIcon:SetTexture(textureOffsetX, textureOffsetY, textureSheet);
		cControlIcon:SetColor(frontColor);
		cControlBacking:SetColor(backColor);
	end
    -- cControlIcon:SetColor(0, 0, 0, 1);
    -- cControlBacking:SetColor(1, 1, 1, 1);
end


-- ===========================================================================
--	INIT
-- ===========================================================================
function Initialize()
	EMR.GetInstance = GetInstance
    EMR.BuildInstanceForControl = BuildInstanceForControl
    EMR.UpdateContent = UpdateContent
end
Initialize();

