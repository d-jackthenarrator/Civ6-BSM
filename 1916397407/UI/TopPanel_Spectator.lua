-- ===========================================================================
--	HUD Top of Screen Area 
--	XP2 Override
-- ===========================================================================
include( "TopPanel_Expansion2" );
print("TopPanel for Better Spectator Mod")

-- ===========================================================================
-- Super functions
-- ===========================================================================
XP2_RefreshYields = RefreshYields;
XP2_RefreshResources = RefreshResources;
BASE_RefreshInfluence = RefreshInfluence;
XP2_OnWMDUpdate = OnWMDUpdate

-- ===========================================================================
-- Yield handles
-- ===========================================================================
local m_ScienceYieldButton	:table = nil;
local m_CultureYieldButton	:table = nil;
local m_GoldYieldButton		:table = nil;
local m_TourismYieldButton	:table = nil;
local m_FaithYieldButton	:table = nil;

-- ===========================================================================
--	OVERRIDE
-- ===========================================================================

function RefreshInfluence()
	local bspec = false
	local spec_ID = 0
	local localPlayer = Players[Game.GetLocalPlayer()];
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
			if ( GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID) ~= nil and GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID) ~= 1000 and GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID) ~= Game.GetLocalPlayer()) then
				Controls.Envoys:SetHide(false);
				localPlayer = Players[GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID)]
				else
				Controls.Envoys:SetHide(true);
			end
			else
			BASE_RefreshInfluence()
		end

	if GameCapabilities.HasCapability("CAPABILITY_TOP_PANEL_ENVOYS") or bspec == true then
		
		if (localPlayer == nil) then
			return;
		end

		local playerInfluence	:table	= localPlayer:GetInfluence();
		local influenceBalance	:number	= Round(playerInfluence:GetPointsEarned(), 1);
		local influenceRate		:number = Round(playerInfluence:GetPointsPerTurn(), 1);
		local influenceThreshold:number	= playerInfluence:GetPointsThreshold();
		local envoysPerThreshold:number = playerInfluence:GetTokensPerThreshold();
		local currentEnvoys		:number = playerInfluence:GetTokensToGive();
		
		local sTooltip = "";

		if (currentEnvoys > 0) then
			sTooltip = sTooltip .. Locale.Lookup("LOC_TOP_PANEL_INFLUENCE_TOOLTIP_ENVOYS", currentEnvoys);
			sTooltip = sTooltip .. "[NEWLINE][NEWLINE]";
		end
		sTooltip = sTooltip .. Locale.Lookup("LOC_TOP_PANEL_INFLUENCE_TOOLTIP_POINTS_THRESHOLD", envoysPerThreshold, influenceThreshold);
		sTooltip = sTooltip .. "[NEWLINE][NEWLINE]";
		sTooltip = sTooltip .. Locale.Lookup("LOC_TOP_PANEL_INFLUENCE_TOOLTIP_POINTS_BALANCE", influenceBalance);
		sTooltip = sTooltip .. "[NEWLINE]";
		sTooltip = sTooltip .. Locale.Lookup("LOC_TOP_PANEL_INFLUENCE_TOOLTIP_POINTS_RATE", influenceRate);
		sTooltip = sTooltip .. "[NEWLINE][NEWLINE]";
		sTooltip = sTooltip .. Locale.Lookup("LOC_TOP_PANEL_INFLUENCE_TOOLTIP_SOURCES_HELP");
		
		local meterRatio = influenceBalance / influenceThreshold;
		if (meterRatio < 0) then
			meterRatio = 0;
		elseif (meterRatio > 1) then
			meterRatio = 1;
		end
		Controls.EnvoysMeter:SetPercent(meterRatio);
		Controls.EnvoysNumber:SetText(tostring(currentEnvoys));
		Controls.Envoys:SetToolTipString(sTooltip);
		Controls.EnvoysStack:CalculateSize();
	else
		Controls.Envoys:SetHide(true);
	end
end


function RefreshResources()
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
				RefreshTurnsRemaining();
				RefreshTime();
				m_kResourceIM:ResetInstances();
				else
				XP2_RefreshResources()
				return
			end
			else
			XP2_RefreshResources()
			return
		end


	local localPlayer = Players[localPlayerID];
		m_kResourceIM:ResetInstances(); 
		local pPlayerResources:table	=  localPlayer:GetResources();
		local yieldStackX:number		= Controls.YieldStack:GetSizeX();
		local infoStackX:number		= Controls.StaticInfoStack:GetSizeX();
		local metaStackX:number		= Controls.RightContents:GetSizeX();
		local screenX, _:number = UIManager:GetScreenSizeVal();
		local maxSize:number = screenX - yieldStackX - infoStackX - metaStackX - m_viewReportsX - META_PADDING;
		if (maxSize < 0) then maxSize = 0; end
		local currSize:number = 0;
		local isOverflow:boolean = false;
		local overflowString:string = "";
		local plusInstance:table;
		for resource in GameInfo.Resources() do
			if (resource.ResourceClassType ~= nil and resource.ResourceClassType ~= "RESOURCECLASS_BONUS" and resource.ResourceClassType ~="RESOURCECLASS_LUXURY" and resource.ResourceClassType ~="RESOURCECLASS_ARTIFACT") then

				local stockpileAmount:number = pPlayerResources:GetResourceAmount(resource.ResourceType);
				local stockpileCap:number = pPlayerResources:GetResourceStockpileCap(resource.ResourceType);
				local reservedAmount:number = pPlayerResources:GetReservedResourceAmount(resource.ResourceType);
				local accumulationPerTurn:number = pPlayerResources:GetResourceAccumulationPerTurn(resource.ResourceType);
				local importPerTurn:number = pPlayerResources:GetResourceImportPerTurn(resource.ResourceType);
				local bonusPerTurn:number = pPlayerResources:GetBonusResourcePerTurn(resource.ResourceType);
				local unitConsumptionPerTurn:number = pPlayerResources:GetUnitResourceDemandPerTurn(resource.ResourceType);
				local powerConsumptionPerTurn:number = pPlayerResources:GetPowerResourceDemandPerTurn(resource.ResourceType);
				local totalConsumptionPerTurn:number = unitConsumptionPerTurn + powerConsumptionPerTurn;
				local totalAmount:number = stockpileAmount + reservedAmount;

				if (totalAmount > stockpileCap) then
					totalAmount = stockpileCap;
				end

				local iconName:string = "[ICON_"..resource.ResourceType.."]";

				local totalAccumulationPerTurn:number = accumulationPerTurn + importPerTurn + bonusPerTurn;

				resourceText = iconName .. " " .. stockpileAmount;

				local numDigits:number = 3;
				if (stockpileAmount >= 10) then
					numDigits = 4;
				end
				local guessinstanceWidth:number = math.ceil(numDigits * FONT_MULTIPLIER);

				local tooltip:string = iconName .. " " .. Locale.Lookup(resource.Name);
				if (reservedAmount ~= 0) then
					--instance.ResourceText:SetColor(UI.GetColorValue("COLOR_YELLOW"));
					tooltip = tooltip .. "[NEWLINE]" .. totalAmount .. "/" .. stockpileCap .. " " .. Locale.Lookup("LOC_RESOURCE_ITEM_IN_STOCKPILE");
					tooltip = tooltip .. "[NEWLINE]-" .. reservedAmount .. " " .. Locale.Lookup("LOC_RESOURCE_ITEM_IN_RESERVE");
				else
					--instance.ResourceText:SetColor(UI.GetColorValue("COLOR_WHITE"));
					tooltip = tooltip .. "[NEWLINE]" .. totalAmount .. "/" .. stockpileCap .. " " .. Locale.Lookup("LOC_RESOURCE_ITEM_IN_STOCKPILE");
				end
				if (totalAccumulationPerTurn >= 0) then
					tooltip = tooltip .. "[NEWLINE]" .. Locale.Lookup("LOC_RESOURCE_ACCUMULATION_PER_TURN", totalAccumulationPerTurn);
				else
					tooltip = tooltip .. "[NEWLINE][COLOR_RED]" .. Locale.Lookup("LOC_RESOURCE_ACCUMULATION_PER_TURN", totalAccumulationPerTurn) .. "[ENDCOLOR]";
				end
				if (accumulationPerTurn > 0) then
					tooltip = tooltip .. "[NEWLINE] " .. Locale.Lookup("LOC_RESOURCE_ACCUMULATION_PER_TURN_EXTRACTED", accumulationPerTurn);
				end
				if (importPerTurn > 0) then
					tooltip = tooltip .. "[NEWLINE] " .. Locale.Lookup("LOC_RESOURCE_ACCUMULATION_PER_TURN_FROM_CITY_STATES", importPerTurn);
				end
				if (bonusPerTurn > 0) then
					tooltip = tooltip .. "[NEWLINE] " .. Locale.Lookup("LOC_RESOURCE_ACCUMULATION_PER_TURN_FROM_BONUS_SOURCES", bonusPerTurn);
				end
				if (totalConsumptionPerTurn > 0) then
					tooltip = tooltip .. "[NEWLINE]" .. Locale.Lookup("LOC_RESOURCE_CONSUMPTION", totalConsumptionPerTurn);
					if (unitConsumptionPerTurn > 0) then
						tooltip = tooltip .. "[NEWLINE]" .. Locale.Lookup("LOC_RESOURCE_UNIT_CONSUMPTION_PER_TURN", unitConsumptionPerTurn);
					end
					if (powerConsumptionPerTurn > 0) then
						tooltip = tooltip .. "[NEWLINE]" .. Locale.Lookup("LOC_RESOURCE_POWER_CONSUMPTION_PER_TURN", powerConsumptionPerTurn);
					end
				end

				if (stockpileAmount > 0 or totalAccumulationPerTurn > 0 or totalConsumptionPerTurn > 0) then
					if(currSize + guessinstanceWidth < maxSize and not isOverflow) then
						if (stockpileCap > 0) then
							local instance:table = m_kResourceIM:GetInstance();
							if (totalAccumulationPerTurn > totalConsumptionPerTurn) then
								instance.ResourceVelocity:SetHide(false);
								instance.ResourceVelocity:SetTexture("CityCondition_Rising");
							elseif (totalAccumulationPerTurn < totalConsumptionPerTurn) then
								instance.ResourceVelocity:SetHide(false);
								instance.ResourceVelocity:SetTexture("CityCondition_Falling");
							else
								instance.ResourceVelocity:SetHide(true);
							end

							instance.ResourceText:SetText(resourceText);
							instance.ResourceText:SetToolTipString(tooltip);
							instanceWidth = instance.ResourceText:GetSizeX();
							currSize = currSize + instanceWidth;
						end
					else
						if (not isOverflow) then 
							overflowString = tooltip;
							local instance:table = m_kResourceIM:GetInstance();
							instance.ResourceText:SetText("[ICON_Plus]");
							plusInstance = instance.ResourceText;
						else
							overflowString = overflowString .. "[NEWLINE]" .. tooltip;
						end
						isOverflow = true;
					end
				end
			end
		end

		if (plusInstance ~= nil) then
			plusInstance:SetToolTipString(overflowString);
		end
		
		Controls.ResourceStack:CalculateSize();
		
		if(Controls.ResourceStack:GetSizeX() == 0) then
			Controls.Resources:SetHide(true);
		else
			Controls.Resources:SetHide(false);
		end

	

end


-- ===========================================================================
--	Favor in the top bar should not ship as is.
--	TODO: Remove this implementation
-- ===========================================================================

function OnTurnBegin()	
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
	if ( bspec == true ) then
		if ( bspec == true) then
			if ( GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID) ~= nil and GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID) ~= 1000 and GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID) ~= Game.GetLocalPlayer()) then
				m_ScienceYieldButton	= nil;
				m_CultureYieldButton	= nil;
				m_GoldYieldButton	= nil;
				m_TourismYieldButton	= nil;
				m_FaithYieldButton	= nil;
				m_YieldButtonSingleManager:ResetInstances();
				m_YieldButtonDoubleManager:ResetInstances();
				ContextPtr:RequestRefresh();
				RefreshTurnsRemaining();
				RefreshTime();
				return
			end
		end
	end
	RefreshAll();
end

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
		RefreshTurnsRemaining()
		if ( GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID) ~= nil and GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID) ~= 1000) then
			m_ScienceYieldButton	= nil;
			m_CultureYieldButton	= nil;
				m_GoldYieldButton	= nil;
				m_TourismYieldButton	= nil;
				m_FaithYieldButton	= nil;
				m_YieldButtonSingleManager:ResetInstances();
				m_YieldButtonDoubleManager:ResetInstances();
				ContextPtr:RequestRefresh();
				RefreshAll();
				RefreshInfluence()
				return
		end
	end
end

function RefreshTurnsRemaining()
	local player = ""
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
			if ( GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID) ~= nil and GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID) ~= 1000 and GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID) ~= Game.GetLocalPlayer()) then
				local pPlayerConfig = PlayerConfigurations[GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID)]
				local leaderDesc	:string = pPlayerConfig:GetLeaderName();
				local civDesc		:string = pPlayerConfig:GetCivilizationDescription();
				player = " - "..Locale.Lookup(leaderDesc)
				else
				player = " - Observer #"..spec_ID
			end
		end
	local endTurn = Game.GetGameEndTurn();		-- This EXCLUSIVE, i.e. the turn AFTER the last playable turn.
	local turn = Game.GetCurrentGameTurn();

	if GameCapabilities.HasCapability("CAPABILITY_DISPLAY_NORMALIZED_TURN") then
		turn = (turn - GameConfiguration.GetStartTurn()) + 1; -- Keep turns starting at 1.
		if endTurn > 0 then
			endTurn = endTurn - GameConfiguration.GetStartTurn();
		end
	end

	if endTurn > 0 then
		-- We have a hard turn limit
		Controls.Turns:SetText(tostring(turn) .. "/" .. tostring(endTurn - 1));
	else
		Controls.Turns:SetText(tostring(turn));
	end

	local strDate = Calendar.MakeYearStr(turn);
	Controls.CurrentDate:SetText(strDate..player);
end

function OnWMDUpdate(owner, WMDtype)
	local bspec = false
	local spec_ID = 0
	local eLocalPlayer = Game.GetLocalPlayer();
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
			owner = GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID)
			eLocalPlayer = GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID)
		end
		else
		XP2_OnWMDUpdate(owner, WMDtype)
		return
	end
	
	if ( eLocalPlayer ~= -1 and owner == eLocalPlayer ) then
		local player = Players[owner];
		local playerWMDs = player:GetWMDs();

		for entry in GameInfo.WMDs() do
			if (entry.WeaponType == "WMD_NUCLEAR_DEVICE") then
				local count = playerWMDs:GetWeaponCount(entry.Index);
				Controls.NuclearDevices:SetHide(false);
				Controls.NuclearDeviceCount:SetText(count);

			elseif (entry.WeaponType == "WMD_THERMONUCLEAR_DEVICE") then
				local count = playerWMDs:GetWeaponCount(entry.Index);
				Controls.ThermoNuclearDevices:SetHide(false);
				Controls.ThermoNuclearDeviceCount:SetText(count);
			end
		end

		Controls.YieldStack:CalculateSize();
	end

	OnRefreshYields();	-- Don't directly refresh, call EVENT version so it's queued in the next context update.
end

function RefreshYields()
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
				ePlayer = GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID)
				--m_YieldButtonSingleManager:ResetInstances();
				--m_YieldButtonDoubleManager:ResetInstances();
				ContextPtr:RequestRefresh();
				--m_YieldButtonSingleManager	= InstanceManager:new( "YieldButton_SingleLabel", "Top", Controls.YieldStack );
				--m_YieldButtonDoubleManager	= InstanceManager:new( "YieldButton_DoubleLabel", "Top", Controls.YieldStack );
				else
				XP2_RefreshYields();
				return
			end
			else
			XP2_RefreshYields();
			return
		end
	
	if (ePlayer == -1 or ePlayer ==  1000 or ePlayer == Game.GetLocalPlayer()) then
		m_ScienceYieldButton	= nil;
		m_CultureYieldButton	= nil;
		m_GoldYieldButton	= nil;
		m_TourismYieldButton	= nil;
		m_FaithYieldButton	= nil;
		Controls.YieldStack:CalculateSize();
		Controls.StaticInfoStack:CalculateSize();
		Controls.InfoStack:CalculateSize();
		Controls.YieldStack:RegisterSizeChanged( RefreshResources );
		Controls.StaticInfoStack:RegisterSizeChanged( RefreshResources );
		return
	end
	

	local localPlayer = nil
	localPlayer = Players[ePlayer];

		if (m_ScienceYieldButton == nil) then
			m_ScienceYieldButton = m_YieldButtonSingleManager:GetInstance();
		end
		local playerTechnology		:table	= localPlayer:GetTechs();
		local currentScienceYield	:number = playerTechnology:GetScienceYield();
		m_ScienceYieldButton.YieldPerTurn:SetText( FormatValuePerTurn(currentScienceYield) );	

		m_ScienceYieldButton.YieldBacking:SetToolTipString( GetScienceTooltip() );
		m_ScienceYieldButton.YieldIconString:SetText("[ICON_ScienceLarge]");
		m_ScienceYieldButton.YieldButtonStack:CalculateSize();

		if (m_CultureYieldButton == nil) then
			m_CultureYieldButton = m_YieldButtonSingleManager:GetInstance();
		end
		local playerCulture			:table	= localPlayer:GetCulture();
		local currentCultureYield	:number = playerCulture:GetCultureYield();
		m_CultureYieldButton.YieldPerTurn:SetText( FormatValuePerTurn(currentCultureYield) );	
		m_CultureYieldButton.YieldPerTurn:SetColorByName("ResCultureLabelCS");

		m_CultureYieldButton.YieldBacking:SetToolTipString( GetCultureTooltip() );
		m_CultureYieldButton.YieldBacking:SetColor(UI.GetColorValueFromHexLiteral(0x99fe2aec));
		m_CultureYieldButton.YieldIconString:SetText("[ICON_CultureLarge]");
		m_CultureYieldButton.YieldButtonStack:CalculateSize();

		m_FaithYieldButton = m_FaithYieldButton or m_YieldButtonDoubleManager:GetInstance();
		local playerReligion		:table	= localPlayer:GetReligion();
		local faithYield			:number = playerReligion:GetFaithYield();
		local faithBalance			:number = playerReligion:GetFaithBalance();
		m_FaithYieldButton.YieldBalance:SetText( Locale.ToNumber(faithBalance, "#,###.#") );	
		m_FaithYieldButton.YieldPerTurn:SetText( FormatValuePerTurn(faithYield) );
		m_FaithYieldButton.YieldBacking:SetToolTipString( GetFaithTooltip() );
		m_FaithYieldButton.YieldIconString:SetText("[ICON_FaithLarge]");
		m_FaithYieldButton.YieldButtonStack:CalculateSize();

		m_GoldYieldButton = m_GoldYieldButton or m_YieldButtonDoubleManager:GetInstance();
		local playerTreasury:table	= localPlayer:GetTreasury();
		local goldYield		:number = playerTreasury:GetGoldYield() - playerTreasury:GetTotalMaintenance();
		local goldBalance	:number = math.floor(playerTreasury:GetGoldBalance());
		m_GoldYieldButton.YieldBalance:SetText( Locale.ToNumber(goldBalance, "#,###.#") );
		m_GoldYieldButton.YieldBalance:SetColorByName("ResGoldLabelCS");	
		m_GoldYieldButton.YieldPerTurn:SetText( FormatValuePerTurn(goldYield) );
		m_GoldYieldButton.YieldIconString:SetText("[ICON_GoldLarge]");
		m_GoldYieldButton.YieldPerTurn:SetColorByName("ResGoldLabelCS");	

		m_GoldYieldButton.YieldBacking:SetToolTipString( GetGoldTooltip() );
		m_GoldYieldButton.YieldBacking:SetColorByName("ResGoldLabelCS");
		m_GoldYieldButton.YieldButtonStack:CalculateSize();

		m_TourismYieldButton = m_TourismYieldButton or m_YieldButtonSingleManager:GetInstance();
		local tourismRate = Round(localPlayer:GetStats():GetTourism(), 1);
		local tourismRateTT:string = Locale.Lookup("LOC_WORLD_RANKINGS_OVERVIEW_CULTURE_TOURISM_RATE", tourismRate);
		local tourismBreakdown = localPlayer:GetStats():GetTourismToolTip();
		if(tourismBreakdown and #tourismBreakdown > 0) then
			tourismRateTT = tourismRateTT .. "[NEWLINE][NEWLINE]" .. tourismBreakdown;
		end
		
		m_TourismYieldButton.YieldPerTurn:SetText( tourismRate );	
		m_TourismYieldButton.YieldBacking:SetToolTipString(tourismRateTT);
		m_TourismYieldButton.YieldPerTurn:SetColorByName("ResTourismLabelCS");
		m_TourismYieldButton.YieldBacking:SetColorByName("ResTourismLabelCS");
		m_TourismYieldButton.YieldIconString:SetText("[ICON_TourismLarge]");
		if (tourismRate > 0) then
			m_TourismYieldButton.Top:SetHide(false);
		else
			m_TourismYieldButton.Top:SetHide(true);
		end 

	Controls.YieldStack:SetHide(false);
	Controls.StaticInfoStack:SetHide(false);	
	Controls.YieldStack:CalculateSize();
	Controls.StaticInfoStack:CalculateSize();
	Controls.InfoStack:CalculateSize();

	Controls.YieldStack:RegisterSizeChanged( RefreshResources );
	Controls.StaticInfoStack:RegisterSizeChanged( RefreshResources );
	
end

LuaEvents.DiplomacyRibbon_Click.Add( OnDiplomacyClick );
 Events.GameCoreEventPublishComplete.Add ( OnDiplomacyClick );
