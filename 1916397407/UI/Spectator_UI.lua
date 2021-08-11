------------------------------------------------------------------------------
--	FILE:	 Spectator_UI.lua
--	AUTHOR:  D. / Jack The Narrator, Firaxis
--	PURPOSE: Add an Observer
-------------------------------------------------------------------------------


UIEvents = ExposedMembers.LuaEvents;
local bFirst = true
local g_version = "v1.15"
local b_congress = false
local b_IsSpec = false
local WORLD_CONGRESS_STAGE_1:number = DB.MakeHash("TURNSEG_WORLDCONGRESS_1");
local WORLD_CONGRESS_STAGE_2:number = DB.MakeHash("TURNSEG_WORLDCONGRESS_2");
print("-- Init D. Better Spectator Mod",g_version," UI --");


-- ===========================================================================
--	OnLoadScreenClose() - initialize
-- ===========================================================================

function OnLoadScreenClose()

	if (Game:GetProperty("SPEC_INIT") ~= nil) then
		if (Game:GetProperty("SPEC_INIT") == true) then
			if ( Game:GetProperty("SPEC_NUM") ~= nil) then
				local bspec = false
				for k =1, Game:GetProperty("SPEC_NUM") do
					if ( Game.GetLocalPlayer() == Game:GetProperty("SPEC_ID_"..k)) then
						local tmp_string = "Better Spectator Mod "..g_version..": Welcome Home, Observer! #"..k
						UserConfiguration.SetValue("QuickMovement", 1)
						UserConfiguration.SetValue("QuickCombat", 1)
						UI.RequestPlayerOperation(1000, PlayerOperations.START_OBSERVER_MODE, nil)
						bspec = true
					end
				end
				if bspec == false then
					local tmp_string = "Better Spectator Mod"..g_version..": This game is being observed by "..Game:GetProperty("SPEC_NUM").." Observer(s)"
				end
				UIEvents.UICleanBoost()
				else
				local tmp_string = "Better Spectator Mod "..g_version..": No Observer in this game!"
				
			end
		end
	end
	
	
end


Events.LoadScreenClose.Add( OnLoadScreenClose );

-- ===========================================================================
--	Call to Script Observer Switch
-- ===========================================================================

function OnLocalPlayerTurnBegin()
	if UI.IsInGame() == false then
		return;
	end	
	local turnSegment = Game.GetCurrentTurnSegment();
	if b_IsSpec == true then
		UI.DeselectAllUnits();
	end
	if turnSegment == WORLD_CONGRESS_STAGE_1 then
		b_congress = true	
	elseif turnSegment == WORLD_CONGRESS_STAGE_2 then
		b_congress = true
	else
		b_congress = false
	end

	if (Game:GetProperty("SPEC_INIT") ~= nil) then
		if (Game:GetProperty("SPEC_INIT") == true) then
			if (Game:GetProperty("SPEC_NUM") ~= nil) then
				local specid = 1000;
				for k = 1, Game:GetProperty("SPEC_NUM") do
					if ( Game:GetProperty("SPEC_ID_"..k)~= nil) then
						if ( Game.GetLocalPlayer() == Game:GetProperty("SPEC_ID_"..k)) then
							b_IsSpec = true
							if (GameConfiguration.GetValue("BSM_SP") == nil) then
								if b_congress == false then
									UI.RequestAction(ActionTypes.ACTION_ENDTURN, { REASON = "UserForced" } );
								end
								else
								if (GameConfiguration.GetValue("BSM_SP") == true) then
									if b_congress == false then
										UI.RequestAction(ActionTypes.ACTION_ENDTURN, { REASON = "UserForced" } );
									end
								end
							end
							specid = Game:GetProperty("SPEC_ID")
							if ( Game:GetProperty("SPEC_LAST_ID") ~= nil) then
								specid = Game:GetProperty("SPEC_LAST_ID")
							end
							if GameConfiguration.GetValue("OBSERVER_ID_"..k) ~= nil then
								specid = GameConfiguration.GetValue("OBSERVER_ID_"..k)
							end
							if Game.GetCurrentGameTurn() > 50 and GameConfiguration.GetValue("GAME_NO_BARBARIANS") == true then
								UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.START_OBSERVER_MODE, nil)
								else
								UIEvents.UIDoObserverPlayer(specid)
							end
						end
					end
				end
			end
		end
	end


end

Events.LocalPlayerTurnBegin.Add(		OnLocalPlayerTurnBegin );


function OnTurnEnd()
	if UI.IsInGame() == false then
		return;
	end	
	if GameConfiguration.GetValue("GAME_NO_BARBARIANS") == false then
		UIEvents.UIUndoObserver("OnTurnEnd")
	end
end

Events.TurnEnd.Add(		OnTurnEnd );

-- ===========================================================================
--	Notification
-- ===========================================================================

-- New Cities
function OnCityAddedToMap( playerID: number, cityID : number, cityX : number, cityY : number )
	if playerID == nil or Game.GetLocalPlayer() == nil then
		return
	end
	
	local pPlayer : object = Players[playerID];
	if pPlayer == nil or pPlayer:IsMajor() == false then
		return 
	end

	local cityCount = 0
	for _,pCity : object in pPlayer:GetCities():Members() do
		cityCount = cityCount + 1
	end
	local msgString = "Title"
	local sumString = "Details"
	if cityCount == 1 and GameConfiguration.GetStartTurn() ~=  Game.GetCurrentGameTurn() then
		msgString = Locale.Lookup("LOC_BSM_NOTIFICATION_DELAYED_B1_MESSAGE");
		sumString = Locale.Lookup("LOC_BSM_NOTIFICATION_DELAYED_B1_SUMMARY");
		NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.PLAYER_MET, msgString, sumString, cityX, cityY);
	elseif cityCount == 2 then
		msgString = Locale.Lookup("LOC_BSM_NOTIFICATION_B2_MESSAGE");
		sumString = Locale.Lookup("LOC_BSM_NOTIFICATION_B2_SUMMARY");
		NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.PLAYER_MET, msgString, sumString, cityX, cityY);
	elseif cityCount == 3 then
		msgString = Locale.Lookup("LOC_BSM_NOTIFICATION_B3_MESSAGE");
		sumString = Locale.Lookup("LOC_BSM_NOTIFICATION_B3_SUMMARY");
		NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.PLAYER_MET, msgString, sumString, cityX, cityY);
	elseif cityCount == 10 then
		msgString = Locale.Lookup("LOC_BSM_NOTIFICATION_B10_MESSAGE");
		sumString = Locale.Lookup("LOC_BSM_NOTIFICATION_B10_SUMMARY");
		NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.PLAYER_MET, msgString, sumString, cityX, cityY);
	elseif cityCount == 20 then
		msgString = Locale.Lookup("LOC_BSM_NOTIFICATION_B20_MESSAGE");
		sumString = Locale.Lookup("LOC_BSM_NOTIFICATION_B20_SUMMARY");
		NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.PLAYER_MET, msgString, sumString, cityX, cityY);
	end
end


-- Goody Huts
function OnGoodyHutReward(playerID, unitID, itemID, itemID_2)
	-- Known ItemID list
	-- 301278043 	-1593446804 civic boost
	-- -1068790248	tech boost
	-- 1623514478	-897059678	xp
	-- 1892398955	1038837136 +1 population
	-- 1623514478	-945185595	free scout
	-- 301278043	2109989822 relic
	-- -2010932837	gold
	-- 1892398955	-317814676 free worker
	if playerID == nil or Players[playerID] == nil then
		return
	end
	if ( Players[playerID]:IsMajor() == true) then
			local sumString =""
			local msgString = Locale.Lookup("LOC_BSM_NOTIFICATION_GOODY_MESSAGE" );
			local notificationType = NotificationTypes.DEFAULT
			local pPlayer	:table = Players[playerID];
			local pUnit		:table = pPlayer:GetUnits():FindID(unitID);		
			
			if (itemID == 301278043 and itemID_2 == -1593446804) then
				sumString = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has found a Goody Hut and received a Civic Boost!"
				elseif (itemID == -1068790248) then
				sumString = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has found a Goody Hut and received a Tech Boost!"
				elseif (itemID == 1623514478 and itemID_2 == -897059678) then
				sumString = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has found a Goody Hut and received a XP Boost!"
				elseif (itemID == 1623514478 and itemID_2 == -945185595) then
				sumString = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has found a Goody Hut and received a Free Scout!"
				elseif (itemID == 1892398955 and itemID_2 == 1038837136) then
				sumString = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has found a Goody Hut and received a Population Boost"
				elseif (itemID == 1623514478 and itemID_2 == 1721956964) then
				sumString = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has found a Goody Hut and was healed!"
				elseif (itemID == 1892398955 and itemID_2 == -317814676) then
				sumString = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has found a Goody Hut and received a Free Worker!"
				elseif (itemID == -2010932837) then
				sumString = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has found a Goody Hut and received some Gold!"
				elseif (itemID == 301278043 and itemID_2 == 2109989822) then
				sumString = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has found a Goody Hut and received a Relic!"
				notificationType = NotificationTypes.RELIC_CREATED
				elseif (itemID == 392580697 and itemID_2 == 1171999597) then
				sumString = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has found a Goody Hut and received a Free Envoy!"
				elseif (itemID == 392580697 and itemID_2 == -842336157) then
				sumString = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has found a Goody Hut and received a Diplomatic Boost!"
				else
				sumString = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has found a Goody Hut!"
				print("Goody hut mistery",itemID, itemID_2)
			end
			if sumString ~= "" then
				NotificationManager.SendNotification(Game.GetLocalPlayer(), notificationType, msgString, sumString, pUnit:GetX(), pUnit:GetY());
			end
	end
end

function OnUnitCaptured( currentUnitOwner, unit, owningPlayer, capturingPlayer )
	local pPlayer	:table = Players[currentUnitOwner];
	local pUnit		:table = pPlayer:GetUnits():FindID(unitID);		
	local	msgString = Locale.Lookup("LOC_BSM_NOTIFICATION_SETTLER_MESSAGE");
	local 	sumString = Locale.Lookup("LOC_NOTIFICATION_SETTLER_SUMMARY");
	if pUnit ~= nil and pUnit:GetName() == "LOC_UNIT_SETTLER_NAME" then
		NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.SPY_ENEMY_CAPTURED, msgString, sumString, pUnit:GetX(), pUnit:GetY());
	end	
end

function OnPantheonFounded(player, belief)

	if ( bspec == true and Players[player]:IsMajor() == true) then
		local msg =""
		local msgString = Locale.Lookup("LOC_BSM_NOTIFICATION_PANTHEON_MESSAGE" );
		msg = Locale.Lookup(PlayerConfigurations[player]:GetPlayerName()).." has chosen a pantheon: "..Locale.Lookup(GameInfo.Beliefs[belief].Name)
		local pCapital = Players[player]:GetCities():GetCapitalCity();
		NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.CHOOSE_PANTHEON, msgString, msg, pCapital:GetX(), pCapital:GetY());
	end
end



function OnBuildingAddedToMap( plotX:number, plotY:number, buildingType:number, playerType:number, pctComplete:number, bPillaged:number )

	if ( Players[playerType]:IsMajor() == true and GameInfo.Buildings[buildingType].IsWonder == true) then
		local msgString = Locale.Lookup("LOC_BSM_NOTIFICATION_WONDER_STARTED_MESSAGE" );
		local msg = ""
		msg = Locale.Lookup(PlayerConfigurations[playerType]:GetPlayerName()).." has started to build: "..Locale.Lookup(GameInfo.Buildings[buildingType].Name)
		NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.WONDER_COMPLETED, msgString, msg, plotX, plotY);
	end
end



function OnGovernmentChanged( player:number )

	if ( Players[player]:IsMajor() == true and GameConfiguration.GetStartTurn() ~=  Game.GetCurrentGameTurn() and PlayerConfigurations[player]:GetLeaderTypeName() ~= "LEADER_SPECTATOR") then
		local govType:string = "";
  		local eSelectePlayerGovernment :number = Players[player]:GetCulture():GetCurrentGovernment();
  		if eSelectePlayerGovernment ~= -1 then
    			govType = Locale.Lookup(GameInfo.Governments[eSelectePlayerGovernment].Name);
 			else
   			govType = Locale.Lookup("LOC_GOVERNMENT_ANARCHY_NAME" );
  		end
		msg = Locale.Lookup(PlayerConfigurations[player]:GetPlayerName()).." is now in: "..govType
		local msgString = Locale.Lookup("LOC_BSM_NOTIFICATION_GOV_CHANGE_MESSAGE" );
		local pCapital = Players[player]:GetCities():GetCapitalCity();
		
		NotificationManager.SendNotification(Game.GetLocalPlayer(),NotificationTypes.CONSIDER_GOVERNMENT_CHANGE, msgString, msg, pCapital:GetX(), pCapital:GetY());
	end
end



local bKnight = false
local bGalley = false
local bSword = false
local bCross = false
local bBombard = false
local bMusket = false
local bField = false
local bTank = false
local bCara = false
local bFrigate = false
local bBattleship = false
-- Great People


function OnUnitAddedToMap(playerID, unitID, x, y)
	if playerID == nil or Players[playerID] == nil then
		return
	end
		if ( Players[playerID]:IsMajor() == true) then
			local pPlayer = Players[playerID];
			local pUnit = pPlayer:GetUnits():FindID(unitID);
			if pUnit == nil then
				return
			end
			local unitTypeName = UnitManager.GetTypeName(pUnit);
			local msg = ""
			local msgString = Locale.Lookup("LOC_BSM_NOTIFICATION_FIRST_UNIT_MESSAGE" );
			if (unitTypeName == "UNIT_GALLEY" and bGalley == false) then
				unitName = Locale.Lookup(GameInfo.Units[unitTypeName].Name)
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has built the first "..unitName
				NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.BARBARIANS_SIGHTED, msgString, msg, pUnit:GetX(), pUnit:GetY());
				bGalley = true
			end
			if (unitTypeName == "UNIT_KNIGHT" and bKnight == false) then
				unitName = Locale.Lookup(GameInfo.Units[unitTypeName].Name)
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has trained the first "..unitName
				NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.BARBARIANS_SIGHTED, msgString, msg, pUnit:GetX(), pUnit:GetY());	
				bKnight = true
			end
			if (unitTypeName == "UNIT_SWORDSMAN" and bSword == false) then
				unitName = Locale.Lookup(GameInfo.Units[unitTypeName].Name)
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has trained the first "..unitName
				NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.BARBARIANS_SIGHTED, msgString, msg, pUnit:GetX(), pUnit:GetY());
				bSword = true
			end
			if (unitTypeName == "UNIT_CROSSBOWMAN" and bCross == false) then
				unitName = Locale.Lookup(GameInfo.Units[unitTypeName].Name)
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has trained the first "..unitName
				NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.BARBARIANS_SIGHTED, msgString, msg, pUnit:GetX(), pUnit:GetY());
				bCross = true
			end
			if (unitTypeName == "UNIT_MUSKETMAN" and bMusket == false) then
				unitName = Locale.Lookup(GameInfo.Units[unitTypeName].Name)
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has trained the first "..unitName
				NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.BARBARIANS_SIGHTED, msgString, msg, pUnit:GetX(), pUnit:GetY());
				bMusket = true
			end
			if (unitTypeName == "UNIT_BOMBARD" and bBombard == false) then
				unitName = Locale.Lookup(GameInfo.Units[unitTypeName].Name)
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has built the first "..unitName
				NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.BARBARIANS_SIGHTED, msgString, msg, pUnit:GetX(), pUnit:GetY());
				bBombard = true
			end
			if (unitTypeName == "UNIT_FIELD_CANNON" and bField == false) then
				unitName = Locale.Lookup(GameInfo.Units[unitTypeName].Name)
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has built the first "..unitName
				NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.BARBARIANS_SIGHTED, msgString, msg, pUnit:GetX(), pUnit:GetY());
				bField = true
			end
			if (unitTypeName == "UNIT_TANK" and bTank == false) then
				unitName = Locale.Lookup(GameInfo.Units[unitTypeName].Name)
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has built the first "..unitName
				NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.BARBARIANS_SIGHTED, msgString, msg, pUnit:GetX(), pUnit:GetY());
				bTank = true
			end
			if (unitTypeName == "UNIT_CARAVEL" and bCara == false) then
				unitName = Locale.Lookup(GameInfo.Units[unitTypeName].Name)
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has built the first "..unitName
				NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.BARBARIANS_SIGHTED, msgString, msg, pUnit:GetX(), pUnit:GetY());
				bCara = true
			end
			if (unitTypeName == "UNIT_FRIGATE" and bFrigate == false) then
				unitName = Locale.Lookup(GameInfo.Units[unitTypeName].Name)
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has built the first "..unitName
				NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.BARBARIANS_SIGHTED, msgString, msg, pUnit:GetX(), pUnit:GetY());
				bFrigate = true
			end
			if (unitTypeName == "UNIT_BATTLESHIP" and bBattleship == false) then
				unitName = Locale.Lookup(GameInfo.Units[unitTypeName].Name)
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has built the first "..unitName
				NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.BARBARIANS_SIGHTED, msgString, msg, pUnit:GetX(), pUnit:GetY());
				bBattleship = true
			end

		end	


end


local bHypatia = false
local bNewton = false
local bKwolek = false -- Doesn t exist ?
local bSagan = false
local bEinstein = false
local bElCid = false
local bBonaparte = false
local bBreedlove = false
local bDuilius = false
local bCruz = false
local bGoddard = false
local bKorolev = false
local bBraun = false
local bBentz = false


function GPData()

	local pGreatPeople	:table  = Game.GetGreatPeople();
	if pGreatPeople == nil then
		UI.DataError("GreatPeoplePopup received NIL great people object.");
		return;
	end
	local displayPlayerID = Game.GetLocalPlayer()
	local pTimeline:table = nil;

	pTimeline = pGreatPeople:GetTimeline();
	
	for i,entry in ipairs(pTimeline) do
		--print("	GPData() Timeline", entry.Claimant)
		-- don't add unclaimed great people to the previously recruited tab

			local claimantName :string = nil;
			if (entry.Claimant ~= nil) then
				claimantName = Locale.Lookup(PlayerConfigurations[entry.Claimant]:GetCivilizationShortDescription());
			end

			local canRecruit			:boolean = false;
			local canReject				:boolean = false;
			local canPatronizeWithFaith :boolean = false;
			local canPatronizeWithGold	:boolean = false;
			local actionCharges			:number = 0;
			local patronizeWithGoldCost	:number = nil;		
			local patronizeWithFaithCost:number = nil;
			local recruitCost			:number = entry.Cost;
			local rejectCost			:number = nil;
			local earnConditions		:string = nil;
			local msg = ""
			local dur = 5
			if (entry.Individual ~= nil) then
				local individualInfo = GameInfo.GreatPersonIndividuals[entry.Individual];
				actionCharges = individualInfo.ActionCharges;
			end
			local msgString = Locale.Lookup("LOC_BSM_NOTIFICATION_STRONG_GP_MESSAGE" );
			local personName:string = "";
			if  GameInfo.GreatPersonIndividuals[entry.Individual] ~= nil then
				personName = Locale.Lookup(GameInfo.GreatPersonIndividuals[entry.Individual].Name);
			end  


			if (bHypatia == false and entry.Individual == 130 and entry.Claimant == nil) then
				msg = personName.." is now available!"
				dur = 15
				NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.CHOOSE_RELIGION, msgString, msg);
				bHypatia = true
			end
			if (bNewton == false and entry.Individual == 135 and entry.Claimant == nil) then
				msg = personName.." is now available!"
				dur = 15
				NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.CHOOSE_RELIGION, msgString, msg);
				bNewton = true
			end
			if (bElCid == false and entry.Individual == 60 and entry.Claimant == nil) then
				msg = personName.." is now available!"
				dur = 15
				NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.CHOOSE_RELIGION, msgString, msg);
				bElCid = true
			end
			if (bBonaparte == false and entry.Individual == 64 and entry.Claimant == nil) then
				msg = personName.." is now available!"
				dur = 15
				NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.CHOOSE_RELIGION, msgString, msg);
				bBonaparte = true
			end
			if (bEinstein == false and entry.Individual == 64 and entry.Claimant == nil) then
				msg = personName.." is now available!"
				dur = 15
				NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.CHOOSE_RELIGION, msgString, msg);
				bEinstein = true
			end
			if (bBreedlove == false and entry.Individual == 89 and entry.Claimant == nil) then
				msg = personName.." is now available!"
				dur = 15
				NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.CHOOSE_RELIGION, msgString, msg);
				bBreedlove = true
			end
			if (bDuilius == false and entry.Individual == 1 and entry.Claimant == nil) then
				msg = personName.." is now available!"
				dur = 15
				NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.CHOOSE_RELIGION, msgString, msg);
				bDuilius = true
			end
			if (bCruz == false and entry.Individual == 7 and entry.Claimant == nil) then
				msg = personName.." is now available!"
				dur = 15
				NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.CHOOSE_RELIGION, msgString, msg);
				bCruz = true
			end
			if (bGoddard == false and entry.Individual == 49 and entry.Claimant == nil) then
				msg = personName.." is now available!"
				dur = 15
				NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.CHOOSE_RELIGION, msgString, msg);
				bGoddard = true
			end
			--if (bKwolek == false and entry.Individual == 49 and entry.Claimant == nil) then
			--	msg = personName.." is now available!"
			--	dur = 15
			--	StatusMessage( msg, dur, ReportingStatusTypes.DEFAULT )
			--	bKwolek = true
			--end
			if (bKorolev == false and entry.Individual == 52 and entry.Claimant == nil) then
				msg = personName.." is now available!"
				dur = 15
				NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.CHOOSE_RELIGION, msgString, msg);
				bKorolev  = true
			end
			if (bBraun == false and entry.Individual == 55 and entry.Claimant == nil) then
				msg = personName.." is now available!"
				dur = 15
				NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.CHOOSE_RELIGION, msgString, msg);
				bBraun  = true
			end
			if (bBentz == false and entry.Individual == 91 and entry.Claimant == nil) then
				msg = personName.." is now available!"
				dur = 15
				NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.CHOOSE_RELIGION, msgString, msg);
				bBentz  = true
			end

	end

end



function OnLocalPlayerTurnBeginNotification()
	GPData()	
end

function Initialize()

	if Game.GetLocalPlayer() == nil or Players[Game.GetLocalPlayer()] == nil then
		return
	end
	
	if PlayerConfigurations[Game.GetLocalPlayer()]:GetLeaderTypeName() == "LEADER_SPECTATOR" then
		-- only subscribe for Spectators
		Events.CityAddedToMap.Add( 									OnCityAddedToMap );
		Events.UnitAddedToMap.Add(									OnUnitAddedToMap );
		Events.GovernmentChanged.Add( 								OnGovernmentChanged );
		Events.BuildingAddedToMap.Add( 								OnBuildingAddedToMap );
		Events.PantheonFounded.Add(									OnPantheonFounded)
		Events.GoodyHutReward.Add(									OnGoodyHutReward );
		Events.LocalPlayerTurnBegin.Add(							OnLocalPlayerTurnBeginNotification );
		Events.UnitCaptured.Add(									OnUnitCaptured);
	end

end

Initialize()
