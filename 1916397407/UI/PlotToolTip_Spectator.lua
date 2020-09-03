-- Copyright 2018, Firaxis Games
-- Adding Zur13 Spy City to BSM 

include("PlotTooltip_Expansion2");
include( "SupportFunctions" );
include( "Civ6Common" );
include( "CitySupport" );
print("PlotToolTip for BSM")

-- ===========================================================================
-- CACHE BASE FUNCTIONS
-- ===========================================================================
XP2_GetDetails = GetDetails;


-- ===========================================================================
function GetDetails(data)
	local details = {};

	details = XP2_GetDetails(data)
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
		if details ~= nil then
			--table.insert(details, Locale.Lookup("LOC_TOOLTIP_CITY_OWNER",szOwnerString, data.OwningCityName));
	
			-- For districts, city center show all building info including Great Works
			-- For wonders, just show Great Work info
			if data.IsCity and data.OwnerCity ~= nil then
				table.insert(details, "------------------");

				local localPlayerID		:number = Game.GetLocalPlayer();
				local pCity				:table =  data.OwnerCity;

				local pBuildQueue		:table  = pCity:GetBuildQueue();
				if pBuildQueue ~= nil then            
					local pct = 0;
					local currentProduction		:string;
					local currentProductionHash :number = pBuildQueue:GetCurrentProductionTypeHash();
					local prodTurnsLeft			:number;
					local progress				:number;
					local prodTypeName			:string;
					local pBuildingDef			:table;
					local pDistrictDef			:table;
					local pUnitDef				:table;
					local pProjectDef			:table;

					-- Attempt to obtain a hash for each item
					if currentProductionHash ~= 0 then
						pBuildingDef = GameInfo.Buildings[currentProductionHash];
						pDistrictDef = GameInfo.Districts[currentProductionHash];
						pUnitDef	 = GameInfo.Units[currentProductionHash];
						pProjectDef	 = GameInfo.Projects[currentProductionHash];
					end

					if( pBuildingDef ~= nil ) then
						currentProduction = pBuildingDef.Name;
						prodTypeName = pBuildingDef.BuildingType;
						prodTurnsLeft = pBuildQueue:GetTurnsLeft(pBuildingDef.BuildingType);
						progress = pBuildQueue:GetBuildingProgress(pBuildingDef.Index);
						pct = progress / pBuildQueue:GetBuildingCost(pBuildingDef.Index);
					elseif ( pDistrictDef ~= nil ) then
						currentProduction = pDistrictDef.Name;
						prodTypeName = pDistrictDef.DistrictType;
						prodTurnsLeft = pBuildQueue:GetTurnsLeft(pDistrictDef.DistrictType);
						progress = pBuildQueue:GetDistrictProgress(pDistrictDef.Index);
						pct = progress / pBuildQueue:GetDistrictCost(pDistrictDef.Index);
					elseif ( pUnitDef ~= nil ) then
						local eMilitaryFormationType = pBuildQueue:GetCurrentProductionTypeModifier();
						currentProduction = pUnitDef.Name;
						prodTypeName = pUnitDef.UnitType;
						prodTurnsLeft = pBuildQueue:GetTurnsLeft(pUnitDef.UnitType, eMilitaryFormationType);
						progress = pBuildQueue:GetUnitProgress(pUnitDef.Index);

						if (eMilitaryFormationType == MilitaryFormationTypes.STANDARD_FORMATION) then
							pct = progress / pBuildQueue:GetUnitCost(pUnitDef.Index);	
						elseif (eMilitaryFormationType == MilitaryFormationTypes.CORPS_FORMATION) then
							pct = progress / pBuildQueue:GetUnitCorpsCost(pUnitDef.Index);
							if (pUnitDef.Domain == "DOMAIN_SEA") then
								-- Concatenanting two fragments is not loc friendly.  This needs to change.
								currentProduction = Locale.Lookup(currentProduction) .. " " .. Locale.Lookup("LOC_UNITFLAG_FLEET_SUFFIX");
							else
								-- Concatenanting two fragments is not loc friendly.  This needs to change.
								currentProduction = Locale.Lookup(currentProduction) .. " " .. Locale.Lookup("LOC_UNITFLAG_CORPS_SUFFIX");
							end
						elseif (eMilitaryFormationType == MilitaryFormationTypes.ARMY_FORMATION) then
							pct = progress / pBuildQueue:GetUnitArmyCost(pUnitDef.Index);
							if (pUnitDef.Domain == "DOMAIN_SEA") then
								-- Concatenanting two fragments is not loc friendly.  This needs to change.
								currentProduction = Locale.Lookup(currentProduction) .. " " .. Locale.Lookup("LOC_UNITFLAG_ARMADA_SUFFIX");
							else
								-- Concatenanting two fragments is not loc friendly.  This needs to change.
								currentProduction = Locale.Lookup(currentProduction) .. " " .. Locale.Lookup("LOC_UNITFLAG_ARMY_SUFFIX");
							end
						end

						progress = pBuildQueue:GetUnitProgress(pUnitDef.Index);
						pct = progress / pBuildQueue:GetUnitCost(pUnitDef.Index);
					elseif (pProjectDef ~= nil) then
						currentProduction = pProjectDef.Name;
						prodTypeName = pProjectDef.ProjectType;
						prodTurnsLeft = pBuildQueue:GetTurnsLeft(pProjectDef.ProjectType);
						progress = pBuildQueue:GetProjectProgress(pProjectDef.Index);
						pct = progress / pBuildQueue:GetProjectCost(pProjectDef.Index);
					end

					if(currentProduction ~= nil) then
						pct = math.clamp(pct, 0, 1);
						if prodTurnsLeft <= 0 then
							pctNextTurn = 0;
						else
							pctNextTurn = (1-pct)/prodTurnsLeft;
						end
						pctNextTurn = pct + pctNextTurn;

						local resProd = "";

					
						--self.m_Instance.CityProductionMeter:SetPercent(pct);
						--self.m_Instance.CityProductionNextTurn:SetPercent(pctNextTurn);

						local productionTip				:string = Locale.Lookup("LOC_CITY_BANNER_PRODUCING", currentProduction);
						local productionTurnsLeftString :string = "";
						if prodTurnsLeft <= 0 then
							--self.m_Instance.CityProdTurnsLeft:SetText("-");
							--productionTurnsLeftString = "  " .. Locale.Lookup("LOC_HUD_CITY_TURNS_UNTIL_COMPLETED", "-"); --LOC_CITY_BANNER_TURNS_LEFT_UNTIL_COMPLETE
							--productionTurnsLeftString = "  " .. Locale.Lookup("LOC_HUD_CITY_TURNS_UNTIL_COMPLETED", "-"); --LOC_CITY_BANNER_TURNS_LEFT_UNTIL_COMPLETE
						else
							productionTurnsLeftString = "  " .. prodTurnsLeft .. " " .. Locale.Lookup("LOC_HUD_CITY_TURNS_UNTIL_COMPLETED", prodTurnsLeft); --LOC_CITY_BANNER_TURNS_LEFT_UNTIL_COMPLETE
							productionTip = productionTip .. "[NEWLINE]" .. " " .. math.floor(pct*100) .. "% " .. productionTurnsLeftString;
							--self.m_Instance.CityProdTurnsLeft:SetText(prodTurnsLeft);
						end
						
						--self.m_Instance.CityProduction:SetToolTipString(productionTip);
						--self.m_Instance.ProductionIndicator:SetHide(false);
						--self.m_Instance.CityProductionProgress:SetHide(false);
						--self.m_Instance.CityProduction:SetColor(0x00FFFFFF);
						
						--if(prodTypeName ~= nil) then
						--	self.m_Instance.CityProductionIcon:SetHide(false);
						--	self.m_Instance.CityProductionIcon:SetIcon("ICON_"..prodTypeName);
						--else
						--	self.m_Instance.CityProductionIcon:SetHide(true);
						--end
					
						resProd = resProd .. productionTip;

						table.insert(details, resProd);
					else
						table.insert(details, Locale.Lookup("LOC_CITY_BANNER_NO_PRODUCTION"));
						--self.m_Instance.CityProduction:SetToolTipString(Locale.Lookup("LOC_CITY_BANNER_NO_PRODUCTION"));
						--self.m_Instance.CityProductionIcon:SetHide(true);
						--self.m_Instance.CityProduction:SetColor(0xFFFFFFFF);
						--self.m_Instance.CityProductionProgress:SetHide(true);
						--self.m_Instance.CityProdTurnsLeft:SetText("");
					end
					
					table.insert(details, "");
				end -- BUILD QUEUE

				-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ POPULATION
				--local pCity				:table = self:GetCity();
				local currentPopulation	:number = pCity:GetPopulation();
				local pCityGrowth		:table  = pCity:GetGrowth();
				local pBuildQueue		:table  = pCity:GetBuildQueue();
				local pCityData         :table  = GetCityData(pCity);
				local foodSurplus		:number = pCityGrowth:GetFoodSurplus();
				local isGrowing			:boolean= pCityGrowth:GetTurnsUntilGrowth() ~= -1;
				local isStarving		:boolean= pCityGrowth:GetTurnsUntilStarvation() ~= -1;

				local iModifiedFood;
				local total :number;

				if pCityData.TurnsUntilGrowth > -1 then
					local growthModifier =  math.max(1 + (pCityData.HappinessGrowthModifier/100) + pCityData.OtherGrowthModifiers, 0); -- This is unintuitive but it's in parity with the logic in City_Growth.cpp
					iModifiedFood = Round(pCityData.FoodSurplus * growthModifier, 2);
					total = iModifiedFood * pCityData.HousingMultiplier;		
				else
					total = pCityData.FoodSurplus;
				end

				local turnsUntilGrowth:number = 0;	-- It is possible for zero... no growth and no starving.
				if isGrowing then
					turnsUntilGrowth = pCityGrowth:GetTurnsUntilGrowth();
				elseif isStarving then
					turnsUntilGrowth = -pCityGrowth:GetTurnsUntilStarvation();	-- Make negative
				end

				--self.m_Instance.CityPopulation:SetText(GetCityPopulationText(self, currentPopulation));

				--if (self.m_Player == Players[localPlayerID]) then			--Only show growth data if the player is you
					--local popTooltip:string = GetPopulationTooltip(self, turnsUntilGrowth, currentPopulation, total);
					--self.m_Instance.CityPopulation:SetToolTipString(popTooltip);
					--if turnsUntilGrowth ~= 0 then
						--self.m_Instance.CityPopTurnsLeft:SetText(turnsUntilGrowth);
					--else
						--self.m_Instance.CityPopTurnsLeft:SetText("-");
					--end
				--end

				local popTooltip:string = Locale.Lookup("LOC_CITY_BANNER_POPULATION") .. ": " .. currentPopulation;
				if turnsUntilGrowth > 0 then
					popTooltip = popTooltip .. "[NEWLINE]  " .. Locale.Lookup("LOC_CITY_BANNER_TURNS_GROWTH", turnsUntilGrowth);
					popTooltip = popTooltip .. "[NEWLINE]  " .. Locale.Lookup("LOC_CITY_BANNER_FOOD_SURPLUS", toPlusMinusString(foodSurplus));
				elseif turnsUntilGrowth == 0 then
					popTooltip = popTooltip .. "[NEWLINE]  " .. Locale.Lookup("LOC_CITY_BANNER_STAGNATE");
				elseif turnsUntilGrowth < 0 then
					popTooltip = popTooltip .. "[NEWLINE]  " .. Locale.Lookup("LOC_CITY_BANNER_TURNS_STARVATION", -turnsUntilGrowth);
				end          
				table.insert(details, popTooltip);
				table.insert(details, "");
				-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ POPULATION END

				-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ YIELDS END
	
				local yieldsLine1 = "";
				local yieldsLine2 = "";

				yieldsLine1 = yieldsLine1 .. "[ICON_Food]"			..toPlusMinusString(pCityData.FoodPerTurn) ;
				yieldsLine1 = yieldsLine1 .. "   [ICON_Production]"	..toPlusMinusString(pCityData.ProductionPerTurn) ;
				yieldsLine1 = yieldsLine1 .. "   [ICON_Gold]"			..toPlusMinusString(pCityData.GoldPerTurn) ;

				yieldsLine2 = yieldsLine2 .. "[ICON_Culture]"	..toPlusMinusString(pCityData.CulturePerTurn) ;
				yieldsLine2 = yieldsLine2 .. "   [ICON_Science]"	..toPlusMinusString(pCityData.SciencePerTurn) ;
				yieldsLine2 = yieldsLine2 .. "   [ICON_Faith]"		..toPlusMinusString(pCityData.FaithPerTurn) ;

				table.insert(details, yieldsLine1);
				table.insert(details, yieldsLine2);

				table.insert(details, "");
				-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ YIELDS END
				
				local cityCulture:table = pCity:GetCulture();
				if cityCulture ~= nil then
					local newGrowthPlot:number = cityCulture:GetNextPlot();
					if newGrowthPlot ~= -1 then
						local turnsRemaining:number = cityCulture:GetTurnsUntilExpansion();
						if turnsRemaining ~= nil and turnsRemaining >= 0 then
							table.insert(details, turnsRemaining .. " " .. Locale.Lookup("LOC_HUD_CITY_TURNS_UNTIL_BORDER_GROWTH", turnsRemaining) );
							--print("turnsRemaining", turnsRemaining);
						end
					end
				end
				--if pCityData.TurnsUntilExpansion ~= nil and pCityData.TurnsUntilExpansion > 0 then
					--table.insert(details, pCityData.TurnsUntilExpansion .. Locale.Lookup("LOC_HUD_CITY_TURNS_UNTIL_BORDER_GROWTH", pCityData.TurnsUntilExpansion));
				--end

			end
		end


	end

	return details;
end