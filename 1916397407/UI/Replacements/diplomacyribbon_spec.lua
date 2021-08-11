-- Copyright 2018-2019, Firaxis Games.

include("DiplomacyRibbon_Expansion2.lua");
include("GameCapabilities");
include("CongressButton");
UIEvents = ExposedMembers.LuaEvents;

print("Diplomacy Ribbon for Better Spectator Mod")
local b_hide = false
local b_hide_2 = true
local b_score = false
local b_trees = false
local b_era = false
local b_army = false
local b_yield = false
local b_teamer = false
local bspec_game = false
local bspec_loc = false
local bspec_loc_id = -1
local m_first_spec_id = -1
local g_stamp = nil
local g_lasttime = 0


-- ===========================================================================
--	MEMBERS
-- ===========================================================================
local m_kLeaderIM			:table = InstanceManager:new("LeaderInstance", "LeaderContainer", Controls.LeaderStack);
local m_leadersMet			:number = 0;		-- Number of leaders in the ribbon
local m_kCongressButtonIM	:table = nil;
local m_oCongressButton		:object = nil;
local m_congressButtonWidth	:number = 0;
local m_uiLeadersByID		:table = {};		-- map of (entire) leader controls based on player id
local m_uiLeadersByPortrait	:table = {};		-- map of leader portraits based on player id
local m_ribbonStats			:number = -1;		-- From Options menu, enum of how this should display.

XP2_LateInitialize = LateInitialize
XP2_UpdateLeaders = UpdateLeaders
XP2_FinishAddingLeader = FinishAddingLeader
XP2_UpdateStatValues = UpdateStatValues
XP2_OnShutdown = OnShutdown

-- =========================================================================== 
--	NEW FUNCTION
-- =========================================================================== 
function OnTimePasses()

	RealizeSize();
	if bspec_loc == false then
		b_hide = false
		b_hide_2 = true
		return
	end

	local currentTime = Automation.GetTime() 
	if math.floor(currentTime - g_lasttime) > 20 then
		if b_hide == true then
			b_hide = false
			b_hide_2 = true
			else
			b_hide = true
			b_hide_2 = false
		end
		g_lasttime = currentTime
		UpdateLeaders()
	end
		
end

function OnScoreMouseClick()
	UI.PlaySound("Play_UI_Click");
	if b_score == true then
		b_score = false
		else
		b_score = true
		b_trees = false
		b_eras = false
		b_army = false
		b_yield = false
	end
	UpdateLeaders()
end



function OnTreesMouseClick()
	UI.PlaySound("Play_UI_Click");
	if b_trees == true then
		b_trees = false
		else
		b_score = false
		b_trees = true
		b_eras = false
		b_army = false
		b_yield = false
	end
	UpdateLeaders()
end



function OnErasMouseClick()
	UI.PlaySound("Play_UI_Click");
	if b_eras == true then
		b_eras = false
		else
		b_score = false
		b_trees = false
		b_eras = true
		b_army = false
		b_yield = false
	end
	UpdateLeaders()
end



function OnArmyMouseClick()
	UI.PlaySound("Play_UI_Click");
	if b_army == true then
		b_army = false
		else
		b_score = false
		b_trees = false
		b_eras = false
		b_army = true
		b_yield = false
	end
	UpdateLeaders()
end


function OnYieldMouseClick()
	UI.PlaySound("Play_UI_Click");
	if b_yield == true then
		b_yield = false
		else
		b_score = false
		b_trees = false
		b_eras = false
		b_army = false
		b_yield = true
	end
	UpdateLeaders()
end


-- ===========================================================================
--	OVERRIDE
-- ===========================================================================

function OnShutdown()
	XP2_OnShutdown();
	Events.GameCoreEventPublishComplete.Remove ( OnTimePasses );
end

function LateInitialize()

	bspec_loc = false
	if Game.GetLocalPlayer() == -1 or Game.GetLocalPlayer() == nil then
		return
	end

	if PlayerConfigurations[Game.GetLocalPlayer()] ~= nil then
		if PlayerConfigurations[Game.GetLocalPlayer()]:GetLeaderTypeName() == "LEADER_SPECTATOR" then
			bspec_loc = true
			bspec_loc_id = Game.GetLocalPlayer()
		end
	end
	
	for i = 0, PlayerManager.GetWasEverAliveMajorsCount() -1 do
		if Players[i]:IsAlive() == true and PlayerConfigurations[i] ~= nil then
			if PlayerConfigurations[Game.GetLocalPlayer()]:GetLeaderTypeName() == "LEADER_SPECTATOR" and m_first_spec_id == -1 then
				m_first_spec_id = i
				bspec_game = true
				break
			end 
		end
	end

	XP2_LateInitialize();

	if HasCapability("CAPABILITY_WORLD_CONGRESS") then
		m_kCongressButtonIM = InstanceManager:new("CongressButton", "Top", Controls.LeaderStack);
	end
	
	if bspec_loc == true then
		Events.GameCoreEventPublishComplete.Add ( OnTimePasses );
	end
end


function OnLeaderClicked(playerID : number )
	-- Send an event to open the leader in the diplomacy view (only if they met)
	local pWorldCongress:table = Game.GetWorldCongress();
	local localPlayerID:number = Game.GetLocalPlayer();

	if ( bspec_loc == true ) then
		UIEvents.UIDoObserverPlayer(playerID)
		LuaEvents.DiplomacyRibbon_Click()
		GameConfiguration.SetValue("OBSERVER_ID_"..bspec_loc_id, playerID)
		return
	end



	if localPlayerID == -1 or localPlayerID == 1000 then
		return;
	end

	if playerID == localPlayerID or Players[localPlayerID]:GetDiplomacy():HasMet(playerID) then
		if pWorldCongress:IsInSession() then
			LuaEvents.DiplomacyActionView_OpenLite(playerID);
		else
			LuaEvents.DiplomacyRibbon_OpenDiplomacyActionView(playerID);
		end
	end
end

function UpdateLeaders()
	if Game.GetLocalPlayer() == -1 then
		return
	end
	-- Check for teamers
	b_teamer = false
	local max_team = 0
	
	for i = 0, PlayerManager.GetWasEverAliveMajorsCount() -1 do
		if Players[i]:IsAlive() == true then
			if Players[i]:GetTeam() ~= i then
				b_teamer = true
			end
			if Players[i]:GetTeam() > max_team then
				max_team = Players[i]:GetTeam()
			end
		end
	end

	if b_teamer == false and bspec_game == false then
		XP2_UpdateLeaders()
		return
	end
	

	if m_kCongressButtonIM then
		if Game.GetEras():GetCurrentEra() >= GlobalParameters.WORLD_CONGRESS_INITIAL_ERA then		
			m_kCongressButtonIM:ResetInstances();
			m_oCongressButton = CongressButton:GetInstance( m_kCongressButtonIM );
			m_congressButtonWidth = m_oCongressButton.Top:GetSizeX();
		end
	end
	
	ResetLeaders();	

	m_ribbonStats = Options.GetUserOption("Interface", "RibbonStats");

	-- Add entries for everyone we know (Majors only)
	local kPlayers		:table = PlayerManager.GetAliveMajors();
	local kMetPlayers	:table = {};
	local kUniqueLeaders:table = {};

	local localPlayerID:number = Game.GetLocalPlayer();
	if localPlayerID ~= -1 then
		local localPlayer	:table = Players[localPlayerID];
		local localDiplomacy:table = localPlayer:GetDiplomacy();
		--table.sort(kPlayers, function(a:table,b:table) return localDiplomacy:GetMetTurn(a:GetID()) < localDiplomacy:GetMetTurn(b:GetID()) end);	
		--AddLeader("ICON_"..PlayerConfigurations[localPlayerID]:GetLeaderTypeName(), localPlayerID, {});		--First, add local player.
		kMetPlayers, kUniqueLeaders = GetMetPlayersAndUniqueLeaders();										--Fill table for other players.
	else
		-- No local player so assume it's auto-playing; show everyone.
		for _, pPlayer in ipairs(kPlayers) do
			local playerID:number = pPlayer:GetID();
			kMetPlayers[ playerID ] = true;
			if (kUniqueLeaders[playerID] == nil) then
				kUniqueLeaders[playerID] = true;
			else
				kUniqueLeaders[playerID] = false;
			end	
		end
	end
	
	local sortedPlayers = {}
	local m_spec_team = nil
	local first_team = 0
	local b_first_added = false
	local loc_team = nil
	
	if b_teamer == true then
		loc_team = Players[Game.GetLocalPlayer()]:GetTeam()
		
		if bspec_game == true then
			m_spec_team = Players[m_first_spec_id]:GetTeam()	
			
			if bspec_loc == true then
				loc_team = nil
				
				for i = 0, max_team do
					if b_first_added == false then
						for _, pPlayer in ipairs(kPlayers) do
							if pPlayer:GetTeam() == i and i ~= m_spec_team then
								table.insert(sortedPlayers, pPlayer)
								b_first_added = true
								first_team = i
							end
						end
					end	
				end

				table.insert(sortedPlayers, Players[m_first_spec_id] )	


				for i = first_team+1,max_team do
					for _, pPlayer in ipairs(kPlayers) do
						if pPlayer:GetTeam() == i and i ~= m_spec_team then
							table.insert(sortedPlayers, pPlayer)
						end
					end
				end	
				
				else -- Teamer with Spec but bot from a Spec
				
				table.insert(sortedPlayers, Players[Game:GetLocalPlayer()] )
				loc_team = Players[Game.GetLocalPlayer()]:GetTeam()
				
				for i = 0, PlayerManager.GetWasEverAliveMajorsCount() -1 do
					if Players[i]:IsAlive() == true and Players[i]:GetTeam() == loc_team and i ~= Game.GetLocalPlayer() then
						table.insert(sortedPlayers, Players[i] )	
					end
				end
				
				table.insert(sortedPlayers, Players[m_first_spec_id] )

				for i = 0, PlayerManager.GetWasEverAliveMajorsCount() -1 do
					if Players[i]:GetTeam() ~= loc_team and PlayerConfigurations[i]:GetLeaderTypeName() ~= "LEADER_SPECTATOR" and Players[i]:IsAlive() == true then
						table.insert(sortedPlayers, Players[i] )	
					end
				end
			end

			else -- Teamer with no Spec
		
			table.insert(sortedPlayers, Players[Game:GetLocalPlayer()] )
				
			for i = 0, PlayerManager.GetWasEverAliveMajorsCount() -1 do
				if Players[i]:IsAlive() == true and Players[i]:GetTeam() == loc_team and i ~= Game.GetLocalPlayer() then
					table.insert(sortedPlayers, Players[i] )	
				end
			end

			for i = 0, PlayerManager.GetWasEverAliveMajorsCount() -1 do
				if Players[i]:GetTeam() ~= loc_team and Players[i]:IsAlive() == true then
					table.insert(sortedPlayers, Players[i] )	
				end
			end
		end
		
		else -- FFA with spec
		if bspec_loc == true then
			table.insert(sortedPlayers, Players[m_first_spec_id] )
			else
			table.insert(sortedPlayers, Players[Game:GetLocalPlayer()] )
		end
		
		for i = 0, PlayerManager.GetWasEverAliveMajorsCount() -1 do
			if PlayerConfigurations[i]:GetLeaderTypeName() ~= "LEADER_SPECTATOR" and Players[i]:IsAlive() == true and i ~= Game:GetLocalPlayer() then
				table.insert(sortedPlayers, Players[i] )	
			end
		end
		
	end

	--Then, add the leader icons.
	for _, pPlayer in ipairs(sortedPlayers) do
		local playerID:number = pPlayer:GetID();
		if(playerID ~= localPlayerID) then
			local isMet			:boolean = kMetPlayers[playerID];
			local pPlayerConfig	:table = PlayerConfigurations[playerID];
			local isHumanMP		:boolean = (GameConfiguration.IsAnyMultiplayer() and pPlayerConfig:IsHuman());
			if (isMet or isHumanMP) then
				local leaderName:string = pPlayerConfig:GetLeaderTypeName();
				local isMasked	:boolean = (isMet==false) and isHumanMP;	-- Multiplayer human but haven't met
				local isUnique	:boolean = kUniqueLeaders[leaderName];
				local iconName	:string = "ICON_LEADER_DEFAULT";
				
				-- If in an MP game and a player leaves the name returned will be NIL.				
				if isMet and (leaderName ~= nil) then
					iconName = "ICON_"..leaderName;
				end
				

				AddLeader(iconName, playerID, { 
					isMasked=isMasked,
					isUnique=isUnique
					}
				);
			end
			else
			AddLeader("ICON_"..PlayerConfigurations[localPlayerID]:GetLeaderTypeName(), localPlayerID, {})
		end
	end

	RealizeSize();


end

-- ===========================================================================
--	Add a leader (from right to left)
--	iconName,	What icon to draw for the leader portrait
--	playerID,	gamecore's player ID
--	kProps,		(optional) properties about the leader
--					isUnique, no other leaders are like this one
--					isMasked, even if stats are show, hide their values.
-- ===========================================================================


function HideSpecInfo(toogle:boolean,uiLeader:table)
	uiLeader.Data:SetHide( toogle )
	uiLeader.Data0:SetHide( toogle )
	uiLeader.Data1:SetHide( toogle )
	uiLeader.Data2:SetHide( toogle )
	uiLeader.Data3:SetHide( toogle )
	uiLeader.Data4:SetHide( toogle )
	uiLeader.Data5:SetHide( toogle)
	uiLeader.Data6:SetHide( toogle )
	uiLeader.Data7:SetHide( toogle )
	uiLeader.Data8:SetHide( toogle )
	uiLeader.SpecControl_1:SetHide( toogle )
	uiLeader.SpecControl_2:SetHide( toogle )
	uiLeader.SpecControl_3:SetHide( toogle )
	uiLeader.SpecControl_4:SetHide( toogle )
	uiLeader.SpecControl_5:SetHide( toogle )
	uiLeader.CultureButton:SetHide( toogle )
	uiLeader.CultureMeter:SetHide( toogle )
	uiLeader.CultureHookWithMeter:SetHide( toogle )
	uiLeader.CultureText:SetHide( toogle )
	uiLeader.CultureTurnsLeft:SetHide( toogle )
	uiLeader.ScienceButton:SetHide( toogle )
	uiLeader.ScienceMeter:SetHide( toogle )
	uiLeader.ScienceHookWithMeter:SetHide( toogle )
	uiLeader.ScienceText:SetHide(toogle )
	uiLeader.ScienceTurnsLeft:SetHide( toogle )
	
	uiLeader.Governement:SetHide( toogle )
	uiLeader.Cities:SetHide( toogle )
	uiLeader.CurrentAge:SetHide( toogle )
	uiLeader.CurrentAge0:SetHide( toogle )
	uiLeader.EraScore:SetHide( toogle )
	uiLeader.EraScore0:SetHide( toogle )
	
	uiLeader.LandUnit:SetHide( toogle )
	uiLeader.NavyUnit:SetHide( toogle )
	uiLeader.AirUnit:SetHide( toogle )
	uiLeader.Strategic1:SetHide( toogle)
	uiLeader.Nukes:SetHide( toogle )
	
	uiLeader.FaithperTurn:SetHide( toogle )
	uiLeader.GoldperTurn:SetHide( toogle )
end


function FinishAddingLeader( playerID:number, uiLeader:table, kProps:table)	

	if bspec_game == false then
		HideSpecInfo(true,uiLeader)
		XP2_FinishAddingLeader(playerID,uiLeader,kProps)
		return
	end

	local isMasked:boolean = false;
	if kProps.isMasked then	isMasked = kProps.isMasked; end

	local bmasterspec = false
	local bIsSpec = false

	if playerID == m_first_spec_id then
		bmasterspec = true
		bIsSpec = true
	end
	
	if PlayerConfigurations[playerID] ~= nil then
		if PlayerConfigurations[playerID]:GetLeaderTypeName() == "LEADER_SPECTATOR" then
			bIsSpec = true
		end
	end

	

	if bspec_loc == false and bIsSpec == true then
		uiLeader.LeaderContainer:SetHide(true)
	end
	
	if bspec_loc == false then
		HideSpecInfo(true,uiLeader)
		XP2_FinishAddingLeader(playerID,uiLeader,kProps)
		return
	end
	
	-- Show fields for enabled victory types.	
	local isHideScore	:boolean = isMasked or b_hide or ( (not Game.IsVictoryEnabled("VICTORY_SCORE")					or not GameCapabilities.HasCapability("CAPABILITY_DISPLAY_SCORE")) ) or bIsSpec ;
	local isHideMilitary:boolean = isMasked or b_hide or ( (not Game.IsVictoryEnabled("VICTORY_CONQUEST")				or not GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS")) ) or bIsSpec ;
	local isHideScience	:boolean = isMasked or b_hide or ( (not GameCapabilities.HasCapability("CAPABILITY_SCIENCE")	or not GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS")) ) or bIsSpec ;
	local isHideCulture :boolean = isMasked or b_hide or ( (not GameCapabilities.HasCapability("CAPABILITY_CULTURE")	or not GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS")) ) or bIsSpec ; 
	local isHideGold	:boolean = isMasked or b_hide or ( (not GameCapabilities.HasCapability("CAPABILITY_GOLD")	or not GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS"))) or bIsSpec ;
	local isHideFaith	:boolean = isMasked or b_hide or ( (not GameCapabilities.HasCapability("CAPABILITY_RELIGION")	or not GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS")) ) or bIsSpec  ;
	local isHideFavor	:boolean = isMasked or b_hide or (not Game.IsVictoryEnabled("VICTORY_DIPLOMATIC")) or bIsSpec  ;		--TODO: Change to capability check when favor is added to capability system.
	local isHideSciCul = isMasked or b_hide_2 or bIsSpec;
	local isHidePhase1	= isMasked or not bmasterspec


	
	if PlayerConfigurations[playerID] ~= nil then
		if PlayerConfigurations[playerID]:GetCivilizationTypeName() ~= nil then
			local str = ""
			str = PlayerConfigurations[playerID]:GetCivilizationTypeName()
			str = "ICON_"..str
			uiLeader.Logo:SetIcon(str)
			local primaryColor, secondaryColor  = UI.GetPlayerColors( playerID );
			if primaryColor == nil then
					primaryColor = UI.GetColorValueFromHexLiteral(0xff99aaaa);
					UI.DataError("NIL primary color; likely player object not ready... using default color.");
			end
			if secondaryColor == nil then
					secondaryColor = UI.GetColorValueFromHexLiteral(0xffaa9999);
					UI.DataError("NIL secondary color; likely player object not ready... using default color.");
			end
			uiLeader.LogoCircle:SetColor(primaryColor);
			uiLeader.Logo:SetColor(secondaryColor);	
			uiLeader.LogoContainer:SetHide(not bspec_loc or bIsSpec)	
		end
	end
	
	
	
	uiLeader.Favor:SetHide( isHideFavor );								   									
	uiLeader.Score:SetHide( isHideScore );
	uiLeader.Military:SetHide( isHideMilitary );
	uiLeader.Science:SetHide( isHideScience );
	uiLeader.Culture:SetHide( isHideCulture );
	uiLeader.Gold:SetHide( isHideGold );
	uiLeader.Faith:SetHide( isHideFaith );
	uiLeader.Data:SetHide( true )
	if GameConfiguration.GetValue("MPH_ON") ~= nil then
		if GameConfiguration.GetValue("MPH_ON") == true then
			uiLeader.Data:SetHide( false )
		end
		else
		uiLeader.Data:SetHide( true )
	end

	uiLeader.Data0:SetHide( true )
	uiLeader.Data1:SetHide( true )
	uiLeader.Data2:SetHide( true )
	uiLeader.Data3:SetHide( true )
	uiLeader.Data4:SetHide( true )
	uiLeader.Data5:SetHide( true )
	uiLeader.Data6:SetHide( true )
	uiLeader.Data7:SetHide( true )
	uiLeader.Data8:SetHide( not bIsSpec )
	uiLeader.SpecControl_1:SetHide( isHidePhase1 or not bspec_loc)
	if uiLeader.SpecControl_1 ~= nil then
		uiLeader.SpecControl_1:RegisterCallback( Mouse.eLClick, OnScoreMouseClick)
		if b_score == true then
			uiLeader.SpecControl_1:SetText("[COLOR_Green]Score[ENDCOLOR]")
			else
			uiLeader.SpecControl_1:SetText("Score")
		end
	end
	uiLeader.SpecControl_2:SetHide( isHidePhase1  or not bspec_loc)
	if uiLeader.SpecControl_2 ~= nil then
		uiLeader.SpecControl_2:RegisterCallback( Mouse.eLClick, OnTreesMouseClick)
		if b_trees == true then
			uiLeader.SpecControl_2:SetText("[COLOR_Green]Techs[ENDCOLOR]")
			else
			uiLeader.SpecControl_2:SetText("Techs")
		end
	end
	uiLeader.SpecControl_3:SetHide( isHidePhase1  or not bspec_loc)
	if uiLeader.SpecControl_3 ~= nil then
		uiLeader.SpecControl_3:RegisterCallback( Mouse.eLClick, OnErasMouseClick)
		if b_eras == true then
			uiLeader.SpecControl_3:SetText("[COLOR_Green]Eras[ENDCOLOR]")
			else
			uiLeader.SpecControl_3:SetText("Eras")
		end
	end
	uiLeader.SpecControl_4:SetHide( isHidePhase1  or not bspec_loc)
	if uiLeader.SpecControl_4 ~= nil then
		uiLeader.SpecControl_4:RegisterCallback( Mouse.eLClick, OnArmyMouseClick)
		if b_army == true then
			uiLeader.SpecControl_4:SetText("[COLOR_Green]Army[ENDCOLOR]")
			else
			uiLeader.SpecControl_4:SetText("Army")
		end
	end
	uiLeader.SpecControl_5:SetHide( isHidePhase1  or not bspec_loc)
	if uiLeader.SpecControl_5 ~= nil then
		uiLeader.SpecControl_5:RegisterCallback( Mouse.eLClick, OnYieldMouseClick)
		if b_yield == true then
			uiLeader.SpecControl_5:SetText("[COLOR_Green]Yield[ENDCOLOR]")
			else
			uiLeader.SpecControl_5:SetText("Yield")
		end
	end
	uiLeader.Data8:SetText( "  Observer ")

	uiLeader.CultureButton:SetHide( isHideSciCul )
	uiLeader.CultureMeter:SetHide( isHideSciCul )
	uiLeader.CultureHookWithMeter:SetHide( isHideSciCul )
	uiLeader.CultureText:SetHide( isHideSciCul )
	uiLeader.CultureTurnsLeft:SetHide( isHideSciCul )
	uiLeader.ScienceButton:SetHide( isHideSciCul )
	uiLeader.ScienceMeter:SetHide( isHideSciCul )
	uiLeader.ScienceHookWithMeter:SetHide( isHideSciCul )
	uiLeader.ScienceText:SetHide(isHideSciCul )
	uiLeader.ScienceTurnsLeft:SetHide( isHideSciCul )
	
	uiLeader.Governement:SetHide( true )
	uiLeader.Cities:SetHide( true )
	uiLeader.CurrentAge:SetHide( true )
	uiLeader.CurrentAge0:SetHide( true )
	uiLeader.EraScore:SetHide( true )
	uiLeader.EraScore0:SetHide( true )
	
	uiLeader.LandUnit:SetHide( true )
	uiLeader.NavyUnit:SetHide( true )
	uiLeader.AirUnit:SetHide( true )
	uiLeader.Strategic1:SetHide( true )
	uiLeader.Nukes:SetHide( true )
	
	uiLeader.FaithperTurn:SetHide( true )
	uiLeader.GoldperTurn:SetHide( true )
	
	if b_score == true then
		uiLeader.Favor:SetHide( false or bIsSpec);								   									
		uiLeader.Score:SetHide( false or bIsSpec);
		uiLeader.Military:SetHide( false or bIsSpec);
		uiLeader.Science:SetHide( false or bIsSpec);
		uiLeader.Culture:SetHide( false or bIsSpec);
		uiLeader.Gold:SetHide( false or bIsSpec);
		uiLeader.Faith:SetHide( false or bIsSpec);
		
		uiLeader.CultureButton:SetHide( true )
		uiLeader.CultureMeter:SetHide( true )
		uiLeader.CultureHookWithMeter:SetHide( true )
		uiLeader.CultureText:SetHide( true )
		uiLeader.CultureTurnsLeft:SetHide( true )
		uiLeader.ScienceButton:SetHide( true )
		uiLeader.ScienceMeter:SetHide( true )
		uiLeader.ScienceHookWithMeter:SetHide( true )
		uiLeader.ScienceText:SetHide(true )
		uiLeader.ScienceTurnsLeft:SetHide( true )
		
		uiLeader.Governement:SetHide( true )
		uiLeader.Cities:SetHide( true )
		uiLeader.CurrentAge:SetHide( true )
		uiLeader.CurrentAge0:SetHide( true )
		uiLeader.EraScore:SetHide( true )
		uiLeader.EraScore0:SetHide( true )
		
		uiLeader.LandUnit:SetHide( true )
		uiLeader.NavyUnit:SetHide( true )
		uiLeader.AirUnit:SetHide( true )
		uiLeader.Strategic1:SetHide( true )
		uiLeader.Nukes:SetHide( true )
		
		uiLeader.FaithperTurn:SetHide( true )
		uiLeader.GoldperTurn:SetHide( true )
	end
	
	if b_trees == true then
		uiLeader.Favor:SetHide( true );								   									
		uiLeader.Score:SetHide( true );
		uiLeader.Military:SetHide( true );
		uiLeader.Science:SetHide( true );
		uiLeader.Culture:SetHide( true );
		uiLeader.Gold:SetHide( true );
		uiLeader.Faith:SetHide( true );
		
		uiLeader.CultureButton:SetHide( false or bIsSpec)
		uiLeader.CultureMeter:SetHide( false or bIsSpec)
		uiLeader.CultureHookWithMeter:SetHide( false or bIsSpec)
		uiLeader.CultureText:SetHide( false or bIsSpec)
		uiLeader.CultureTurnsLeft:SetHide( false or bIsSpec)
		uiLeader.ScienceButton:SetHide( false or bIsSpec)
		uiLeader.ScienceMeter:SetHide( false or bIsSpec)
		uiLeader.ScienceHookWithMeter:SetHide( false or bIsSpec)
		uiLeader.ScienceText:SetHide(false or bIsSpec)
		uiLeader.ScienceTurnsLeft:SetHide( false or bIsSpec)
		
		uiLeader.Governement:SetHide( true )
		uiLeader.Cities:SetHide( true )
		uiLeader.CurrentAge:SetHide( true )
		uiLeader.CurrentAge0:SetHide( true )
		uiLeader.EraScore:SetHide( true )
		uiLeader.EraScore0:SetHide( true )
		
		uiLeader.LandUnit:SetHide( true )
		uiLeader.NavyUnit:SetHide( true )
		uiLeader.AirUnit:SetHide( true )
		uiLeader.Strategic1:SetHide( true )
		uiLeader.Nukes:SetHide( true )
		
		uiLeader.FaithperTurn:SetHide( true )
		uiLeader.GoldperTurn:SetHide( true )
	end
	
	if b_eras == true then
		uiLeader.Favor:SetHide( true );								   									
		uiLeader.Score:SetHide( true );
		uiLeader.Military:SetHide( true );
		uiLeader.Science:SetHide( true );
		uiLeader.Culture:SetHide( true );
		uiLeader.Gold:SetHide( true );
		uiLeader.Faith:SetHide( true );
		
		uiLeader.CultureButton:SetHide( true )
		uiLeader.CultureMeter:SetHide( true )
		uiLeader.CultureHookWithMeter:SetHide( true )
		uiLeader.CultureText:SetHide( true )
		uiLeader.CultureTurnsLeft:SetHide( true )
		uiLeader.ScienceButton:SetHide( true )
		uiLeader.ScienceMeter:SetHide( true )
		uiLeader.ScienceHookWithMeter:SetHide( true )
		uiLeader.ScienceText:SetHide(true )
		uiLeader.ScienceTurnsLeft:SetHide( true )
		
		uiLeader.Governement:SetHide( false or bIsSpec)
		uiLeader.Cities:SetHide( false or bIsSpec)
		uiLeader.CurrentAge:SetHide( false or bIsSpec)
		uiLeader.CurrentAge0:SetHide( false or bIsSpec)
		uiLeader.EraScore:SetHide( false or bIsSpec)
		uiLeader.EraScore0:SetHide( false or bIsSpec)
		
	uiLeader.LandUnit:SetHide( true )
	uiLeader.NavyUnit:SetHide( true )
	uiLeader.AirUnit:SetHide( true )
	uiLeader.Strategic1:SetHide( true )
	uiLeader.Nukes:SetHide( true )
	
		uiLeader.FaithperTurn:SetHide( true )
	uiLeader.GoldperTurn:SetHide( true )
	end
	
	if b_army == true then
		uiLeader.Favor:SetHide( true );								   									
		uiLeader.Score:SetHide( true );
		uiLeader.Military:SetHide( false  or bIsSpec);
		uiLeader.Science:SetHide( true );
		uiLeader.Culture:SetHide( true );
		uiLeader.Gold:SetHide( true );
		uiLeader.Faith:SetHide( true );
		
		uiLeader.CultureButton:SetHide( true )
		uiLeader.CultureMeter:SetHide( true )
		uiLeader.CultureHookWithMeter:SetHide( true )
		uiLeader.CultureText:SetHide( true )
		uiLeader.CultureTurnsLeft:SetHide( true )
		uiLeader.ScienceButton:SetHide( true )
		uiLeader.ScienceMeter:SetHide( true )
		uiLeader.ScienceHookWithMeter:SetHide( true )
		uiLeader.ScienceText:SetHide(true )
		uiLeader.ScienceTurnsLeft:SetHide( true )
		
		uiLeader.Governement:SetHide( true )
		uiLeader.Cities:SetHide( true )
		uiLeader.CurrentAge:SetHide( true )
		uiLeader.CurrentAge0:SetHide( true )
		uiLeader.EraScore:SetHide( true )
		uiLeader.EraScore0:SetHide( true )
		
			uiLeader.LandUnit:SetHide( false  or bIsSpec)
	uiLeader.NavyUnit:SetHide( false  or bIsSpec)
	uiLeader.AirUnit:SetHide( false  or bIsSpec)
	uiLeader.Strategic1:SetHide( false  or bIsSpec)
	uiLeader.Nukes:SetHide( false  or bIsSpec)
	
	uiLeader.FaithperTurn:SetHide( true )
	uiLeader.GoldperTurn:SetHide( true )
	end
	
	if b_yield == true then
		uiLeader.Favor:SetHide( true );								   									
		uiLeader.Score:SetHide( true );
		uiLeader.Military:SetHide( true );
		uiLeader.Science:SetHide( false  or bIsSpec)
		uiLeader.Culture:SetHide( false  or bIsSpec)
		uiLeader.Gold:SetHide( true );
		uiLeader.Faith:SetHide( true );
		
		uiLeader.CultureButton:SetHide( true )
		uiLeader.CultureMeter:SetHide( true )
		uiLeader.CultureHookWithMeter:SetHide( true )
		uiLeader.CultureText:SetHide( true )
		uiLeader.CultureTurnsLeft:SetHide( true )
		uiLeader.ScienceButton:SetHide( true )
		uiLeader.ScienceMeter:SetHide( true )
		uiLeader.ScienceHookWithMeter:SetHide( true )
		uiLeader.ScienceText:SetHide(true )
		uiLeader.ScienceTurnsLeft:SetHide( true )
		
		uiLeader.Governement:SetHide( true )
		uiLeader.Cities:SetHide( true )
		uiLeader.CurrentAge:SetHide( true )
		uiLeader.CurrentAge0:SetHide( true )
		uiLeader.EraScore:SetHide( true )
		uiLeader.EraScore0:SetHide( true )
		
	uiLeader.LandUnit:SetHide( true )
	uiLeader.NavyUnit:SetHide( true )
	uiLeader.AirUnit:SetHide( true )
	uiLeader.Strategic1:SetHide( true )
	uiLeader.Nukes:SetHide( true )
	
		uiLeader.FaithperTurn:SetHide( false  or bIsSpec)
		uiLeader.GoldperTurn:SetHide( false  or bIsSpec)
	end
	
	UpdateStatValues( playerID, uiLeader );
end

function UpdateStatValues( playerID:number, uiLeader:table )	
	XP2_UpdateStatValues( playerID, uiLeader );
	local namestr = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName())
	local team_id = PlayerConfigurations[playerID]:GetTeam()
	local teamstr = ""
	if team_id ~= nil and PlayerConfigurations[playerID]:GetLeaderTypeName() ~= "LEADER_SPECTATOR" then
		team_id = team_id + 1
		local team_name = GameConfiguration.GetValue("BSM_TEAM"..tostring(team_id))
		if team_name ~= nil then
			team_name = string.sub(tostring(team_name),1,7)
			teamstr = tostring(team_name).."[NEWLINE]"
		end
	end
	if namestr ~= nil then
		if string.len(namestr) > 8  then
			namestr = string.sub(namestr,1,7).."."
		end
		if teamstr ~= "" then
			namestr = teamstr..namestr
		end
		uiLeader.Name:SetText(tostring(namestr))
	end

	local data = GameConfiguration.GetValue("GAP_"..playerID)
	if data ~= nil then
		data = tostring(data)
		data = " L: "..string.sub(data,1,3)
		else
		data = " L: na  "
	end
	if Network.GetGameHostPlayerID() ~= nil then
		if Network.GetGameHostPlayerID() == playerID then
			data = " Host"
		end
	end
	if playerID ~= Game.GetLocalPlayer() then
		if Network.GetPingTime( playerID ) ~= nil and Network.GetPingTime( playerID ) ~= -1 then
			data = data.." P:"..Network.GetPingTime( playerID )
		end
	end
	
	if uiLeader.FaithperTurn:IsVisible() then 
		local playerReligion		:table	= Players[playerID]:GetReligion();
		local faithYield			:number = playerReligion:GetFaithYield();
		local playerTreasury:table	= Players[playerID]:GetTreasury();
		faithYield = math.floor(faithYield)
		local goldYield = playerTreasury:GetGoldYield() - playerTreasury:GetTotalMaintenance()
		goldYield = math.floor(goldYield)
		uiLeader.FaithperTurn:SetText("[ICON_Faith]"..tostring(faithYield)); 
		uiLeader.GoldperTurn:SetText("[ICON_Gold]"..tostring(goldYield)); 
	end
	
	if uiLeader.Governement:IsVisible() then 
		local govType:string = "";
  		local eSelectePlayerGovernment :number = Players[playerID]:GetCulture():GetCurrentGovernment();
  		if eSelectePlayerGovernment ~= -1 then
    			govType = Locale.Lookup(GameInfo.Governments[eSelectePlayerGovernment].Name);
 			else
   			govType = Locale.Lookup("LOC_GOVERNMENT_ANARCHY_NAME" );
  		end
		if string.len(govType) > 8 then
			govType = string.sub(govType,1,7).."."
		end
		uiLeader.Governement:SetText(tostring(govType)); 
	end
	
	if uiLeader.Cities:IsVisible() then 
	  	local cities = Players[playerID]:GetCities();
		local str = ""
  		local numCities = 0;
  		local ERD_Total_Population = 0;
  		for i,city in cities:Members() do
			ERD_Total_Population = ERD_Total_Population + city:GetPopulation();
    			numCities = numCities + 1;
  		end
		str = numCities .. "[ICON_Housing] ".. ERD_Total_Population .. " [ICON_Citizen]"
		uiLeader.Cities:SetText(str); 
	end
	
	if uiLeader.CurrentAge:IsVisible() then 
	  	local pGameEras:table = Game.GetEras();
	  	if pGameEras:HasHeroicGoldenAge(playerID) then
			sEras = Locale.Lookup("LOC_ERA_PROGRESS_HEROIC_AGE");
	  		elseif pGameEras:HasGoldenAge(playerID) then
			sEras = Locale.Lookup("LOC_ERA_PROGRESS_GOLDEN_AGE");
	  		elseif pGameEras:HasDarkAge(playerID) then
			sEras = Locale.Lookup("LOC_ERA_PROGRESS_DARK_AGE");
	  		else
			sEras = Locale.Lookup("LOC_ERA_PROGRESS_NORMAL_AGE");
	  	end
		if string.len(sEras) > 9 then
			sEras = string.sub(sEras,1,4)..". age"
		end
		uiLeader.CurrentAge:SetText(sEras); 
	end
	
	if uiLeader.EraScore:IsVisible() then 
		local gameEras = Game.GetEras();
		local score	= gameEras:GetPlayerCurrentScore(playerID);
		local isFinalEra:boolean = gameEras:GetCurrentEra() == gameEras:GetFinalEra();
		local baseline = gameEras:GetPlayerThresholdBaseline(playerID);
		local darkAgeThreshold = gameEras:GetPlayerDarkAgeThreshold(playerID);
		local goldenAgeThreshold = gameEras:GetPlayerGoldenAgeThreshold(playerID);
		local ageIconName = "[ICON_GLORY_NORMAL_AGE]";
		local str = ""
		if score >= darkAgeThreshold then
		--We are working towards, or scored Golden age
			ageIconName = gameEras:HasDarkAge(playerID) and "[ICON_GLORY_GOLDEN_AGE]" or "[ICON_GLORY_SUPER_GOLDEN_AGE]";
			else
			ageIconName = "[ICON_GLORY_DARK_AGE]";
		end
		str = ageIconName .. score
		if isFinalEra == false then
			str = str.." / " .. (score > darkAgeThreshold and goldenAgeThreshold or darkAgeThreshold)
		end
		uiLeader.EraScore:SetText(str); 
	end
	
	if uiLeader.LandUnit:IsVisible() then 
		local unit_land = 0
		local unit_sea = 0
		local unit_air = 0
		local pUnits = Players[playerID]:GetUnits()
		for k,kUnit in pUnits:Members() do
			if ( GameInfo.Units[kUnit:GetUnitType()].Domain == "DOMAIN_AIR" ) then
				unit_air = unit_air + 1
			elseif ( GameInfo.Units[kUnit:GetUnitType()].Domain == "DOMAIN_SEA" ) then
				unit_sea = unit_sea + 1
			elseif ( GameInfo.Units[kUnit:GetUnitType()].Domain == "DOMAIN_LAND" ) then
				unit_land = unit_land + 1
			else
				print("GameInfo.Units[kUnit:GetUnitType()].Domain",GameInfo.Units[kUnit:GetUnitType()].Domain)
			end
		end
		uiLeader.LandUnit:SetText("Land: ".. tostring(unit_land))
		uiLeader.NavyUnit:SetText("Navy: ".. tostring(unit_sea))
		uiLeader.AirUnit:SetText("Air: ".. tostring(unit_air))
	end
	
	if uiLeader.Nukes:IsVisible() then 
		local playerWMDs  = Players[playerID]:GetWMDs()
		local str = ""
		for entry in GameInfo.WMDs() do
			if (entry.WeaponType == "WMD_NUCLEAR_DEVICE") then
				local count = playerWMDs:GetWeaponCount(entry.Index);
				str = count.." [ICON_Nuclear]"

			elseif (entry.WeaponType == "WMD_THERMONUCLEAR_DEVICE") then
				local count = playerWMDs:GetWeaponCount(entry.Index);
				str = str.." "..count.." [ICON_ThermoNuclear]"
			end
		end
		uiLeader.Nukes:SetText(str)
	end
	
	if uiLeader.Strategic1:IsVisible() then 
		local pPlayerResources = Players[playerID]:GetResources();
		local count = 0
		local str = ""
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
				count = count + 1
				if count % 2 == 0 then
					str = str..resourceText.."[NEWLINE]"
					else
					str = str..resourceText.." "
				end
			end
		end
		uiLeader.Strategic1:SetText(str)
	end
	
	if uiLeader.Data:IsVisible() then 
		uiLeader.Data:SetText(tostring(data)); 	
	end

	local localPlayer = Players[playerID]
	if localPlayer ~= nil  then
		local pPlayerCulture	:table	= localPlayer:GetCulture();
		local currentCivicID    :number = pPlayerCulture:GetProgressingCivic();

		if(currentCivicID >= 0) then
			local civicProgress	:number = pPlayerCulture:GetCulturalProgress(currentCivicID);
			local civicCost		:number	= pPlayerCulture:GetCultureCost(currentCivicID);	
			uiLeader.CultureMeter:SetPercent(civicProgress/civicCost);
		else
			uiLeader.CultureMeter:SetPercent(0);
		end

		local CivicInfo:table = GameInfo.Civics[currentCivicID];
		if (CivicInfo ~= nil) then
			local civictextureString = "ICON_" .. CivicInfo.CivicType;
			local civictextureOffsetX, civictextureOffsetY, civictextureSheet = IconManager:FindIconAtlas(civictextureString,38);
			if civictextureSheet ~= nil then
				uiLeader.CultureIcon:SetTexture(civictextureOffsetX, civictextureOffsetY, civictextureSheet);
				local namestr = Locale.Lookup(GameInfo.Civics[currentCivicID].Name )
				if namestr ~= nil then
					if string.len(namestr) > 10 then
						namestr = string.sub(namestr,1,9).."."
						end
						uiLeader.CultureText:SetText( namestr)
				end
				
				uiLeader.CultureTurnsLeft:SetText( "[ICON_Turn] "..pPlayerCulture:GetTurnsLeft())
			end
		end
	end
	if ( localPlayer ~= nil ) then
		local playerTechs		:table	= localPlayer:GetTechs();
		local currentTechID		:number = playerTechs:GetResearchingTech();

		if(currentTechID >= 0) then
			local progress			:number = playerTechs:GetResearchProgress(currentTechID);
			local cost				:number	= playerTechs:GetResearchCost(currentTechID);
	
			uiLeader.ScienceMeter:SetPercent(progress/cost);
		else
			uiLeader.ScienceMeter:SetPercent(0);
		end

		local techInfo:table = GameInfo.Technologies[currentTechID];
		if (techInfo ~= nil) then
			local textureString = "ICON_" .. techInfo.TechnologyType;
			local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas(textureString,38);
			if textureSheet ~= nil then
				uiLeader.ResearchIcon:SetTexture(textureOffsetX, textureOffsetY, textureSheet);
				local namestr = Locale.Lookup(GameInfo.Technologies[currentTechID].Name )
				if namestr ~= nil then
					if string.len(namestr) > 10 then
						namestr = string.sub(namestr,1,9).."."
						end
						uiLeader.ScienceText:SetText( namestr)
				end

				uiLeader.ScienceTurnsLeft:SetText( "[ICON_Turn] "..playerTechs:GetTurnsLeft())
			end
		end
	end

end
