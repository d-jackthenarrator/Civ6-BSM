------------------------------------------------------------------------------
--	FILE:	 Spectator_UI.lua
--	AUTHOR:  D. / Jack The Narrator, Firaxis
--	PURPOSE: Add an Observer
-------------------------------------------------------------------------------


UIEvents = ExposedMembers.LuaEvents;
local bFirst = true
local g_version = "v1.14"
local b_congress = false
local b_IsSpec = false
local WORLD_CONGRESS_STAGE_1:number = DB.MakeHash("TURNSEG_WORLDCONGRESS_1");
local WORLD_CONGRESS_STAGE_2:number = DB.MakeHash("TURNSEG_WORLDCONGRESS_2");
print("-- Init D. Better Spectator Mod",g_version," UI --");
-- =========================================================================== 
--	Send Status message
-- =========================================================================== 
function StatusMessage( str:string, fDisplayTime:number, type:number)
	LuaEvents.StatusMessage(str, fDisplayTime, type)
end

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
						StatusMessage(tmp_string , 60, ReportingStatusTypes.DEFAULT )
						UserConfiguration.SetValue("QuickMovement", 1)
						UserConfiguration.SetValue("QuickCombat", 1)
						StatusMessage( "Click on a leader's icon to switch views!", 60, ReportingStatusTypes.DEFAULT )
						UI.RequestPlayerOperation(1000, PlayerOperations.START_OBSERVER_MODE, nil)
						bspec = true
					end
				end
				if bspec == false then
					local tmp_string = "Better Spectator Mod"..g_version..": This game is being observed by "..Game:GetProperty("SPEC_NUM").." Observer(s)"
					StatusMessage(tmp_string, 60, ReportingStatusTypes.DEFAULT )	
				end
				UIEvents.UICleanBoost()
				else
				local tmp_string = "Better Spectator Mod "..g_version..": No Observer in this game!"
				StatusMessage(tmp_string, 60, ReportingStatusTypes.DEFAULT )
				
			end
		end
	end
	
	
end


Events.LoadScreenClose.Add( OnLoadScreenClose );

-- ===========================================================================
--	Call to Script Observer Switch
-- ===========================================================================

function OnLocalPlayerTurnBegin()

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
				GPData()
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
	local bspec = false
	if (Game:GetProperty("SPEC_NUM") ~= nil) then
		for k = 1, Game:GetProperty("SPEC_NUM") do
			if ( Game:GetProperty("SPEC_ID_"..k)~= nil) then
				if Game.GetLocalPlayer() == Game:GetProperty("SPEC_ID_"..k) then
					bspec = true
				end
			end
		end
	end
	--if (Game:GetProperty("SPEC_ID") ~= nil) then
		if ( bspec == true and Players[playerID]:IsMajor() == true and GameConfiguration.GetStartTurn() ~=  Game.GetCurrentGameTurn()) then
			local pPlayer = Players[playerID];
			local pCity = pPlayer:GetCities():FindID(cityID);
			local msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has founded a new city named "..Locale.Lookup(pCity:GetName())
			StatusMessage( msg, 5, ReportingStatusTypes.DEFAULT )
		end
	--end

end

Events.CityAddedToMap.Add( OnCityAddedToMap );

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
	local bspec = false
	if (Game:GetProperty("SPEC_NUM") ~= nil) then
		for k = 1, Game:GetProperty("SPEC_NUM") do
			if ( Game:GetProperty("SPEC_ID_"..k)~= nil) then
				if Game.GetLocalPlayer() == Game:GetProperty("SPEC_ID_"..k) then
					bspec = true
				end
			end
		end
	end
	--if (Game:GetProperty("SPEC_ID") ~= nil) then
		if ( bspec == true and Players[playerID]:IsMajor() == true) then
			local msg =""
			local dur = 5
			if (itemID == 301278043 and itemID_2 == -1593446804) then
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has found a Goody Hut and received a Civic Boost!"
				elseif (itemID == -1068790248) then
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has found a Goody Hut and received a Tech Boost!"
				elseif (itemID == 1623514478 and itemID_2 == -897059678) then
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has found a Goody Hut and received a XP Boost!"
				elseif (itemID == 1623514478 and itemID_2 == -945185595) then
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has found a Goody Hut and received a Free Scout!"
				elseif (itemID == 1892398955 and itemID_2 == 1038837136) then
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has found a Goody Hut and received a Population Boost"
				elseif (itemID == 1623514478 and itemID_2 == 1721956964) then
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has found a Goody Hut and was healed!"
				elseif (itemID == 1892398955 and itemID_2 == -317814676) then
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has found a Goody Hut and received a Free Worker!"
				dur = 15
				elseif (itemID == -2010932837) then
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has found a Goody Hut and received some Gold!"
				elseif (itemID == 301278043 and itemID_2 == 2109989822) then
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has found a Goody Hut and received a Relic!"
				dur = 15
				elseif (itemID == 392580697 and itemID_2 == 1171999597) then
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has found a Goody Hut and received a Free Envoy!"
				elseif (itemID == 392580697 and itemID_2 == -842336157) then
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has found a Goody Hut and received a Diplomatic Boost!"
				else
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has found a Goody Hut!"
				print("Goody hut mistery",itemID, itemID_2)
			end
			StatusMessage( msg, dur, ReportingStatusTypes.DEFAULT )
		end
	--end
end

Events.GoodyHutReward.Add(			OnGoodyHutReward );

function OnPantheonFounded(player, belief)

	local bspec = false
	if (Game:GetProperty("SPEC_NUM") ~= nil) then
		for k = 1, Game:GetProperty("SPEC_NUM") do
			if ( Game:GetProperty("SPEC_ID_"..k)~= nil) then
				if Game.GetLocalPlayer() == Game:GetProperty("SPEC_ID_"..k) then
					bspec = true
				end
			end
		end
	end

	if ( bspec == true and Players[player]:IsMajor() == true) then
		local msg =""
		local dur = 15
		msg = Locale.Lookup(PlayerConfigurations[player]:GetPlayerName()).." has chosen a pantheon: "..Locale.Lookup(GameInfo.Beliefs[belief].Name)
		StatusMessage( msg, dur, ReportingStatusTypes.DEFAULT )
	end
end

Events.PantheonFounded.Add(OnPantheonFounded)

function OnBuildingAddedToMap( plotX:number, plotY:number, buildingType:number, playerType:number, pctComplete:number, bPillaged:number )
	local bspec = false
	if (Game:GetProperty("SPEC_NUM") ~= nil) then
		for k = 1, Game:GetProperty("SPEC_NUM") do
			if ( Game:GetProperty("SPEC_ID_"..k)~= nil) then
				if Game.GetLocalPlayer() == Game:GetProperty("SPEC_ID_"..k) then
					bspec = true
				end
			end
		end
	end

	if ( bspec == true and Players[playerType]:IsMajor() == true and GameInfo.Buildings[buildingType].IsWonder == true) then
		local msg =""
		local dur = 15
		msg = Locale.Lookup(PlayerConfigurations[playerType]:GetPlayerName()).." has started to build: "..Locale.Lookup(GameInfo.Buildings[buildingType].Name)
		StatusMessage( msg, dur, ReportingStatusTypes.DEFAULT )
	end
end

Events.BuildingAddedToMap.Add( OnBuildingAddedToMap );

function OnGovernmentChanged( player:number )

	local bspec = false
	if (Game:GetProperty("SPEC_NUM") ~= nil) then
		for k = 1, Game:GetProperty("SPEC_NUM") do
			if ( Game:GetProperty("SPEC_ID_"..k)~= nil) then
				if Game.GetLocalPlayer() == Game:GetProperty("SPEC_ID_"..k) then
					bspec = true
				end
			end
		end
	end

	if ( bspec == true and Players[player]:IsMajor() == true and GameConfiguration.GetStartTurn() ~=  Game.GetCurrentGameTurn()) then
		local govType:string = "";
  		local eSelectePlayerGovernment :number = Players[player]:GetCulture():GetCurrentGovernment();
  		if eSelectePlayerGovernment ~= -1 then
    			govType = Locale.Lookup(GameInfo.Governments[eSelectePlayerGovernment].Name);
 			else
   			govType = Locale.Lookup("LOC_GOVERNMENT_ANARCHY_NAME" );
  		end
		local msg =""
		local dur = 15
		msg = Locale.Lookup(PlayerConfigurations[player]:GetPlayerName()).." is now in: "..govType
		StatusMessage( msg, dur, ReportingStatusTypes.DEFAULT )
	end
end

Events.GovernmentChanged.Add( OnGovernmentChanged );

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
	local bspec = false
	if (Game:GetProperty("SPEC_NUM") ~= nil) then
		for k = 1, Game:GetProperty("SPEC_NUM") do
			if ( Game:GetProperty("SPEC_ID_"..k)~= nil) then
				if Game.GetLocalPlayer() == Game:GetProperty("SPEC_ID_"..k) then
					bspec = true
				end
			end
		end
	end
	--if (Game:GetProperty("SPEC_ID") ~= nil) then
		if ( bspec == true and Players[playerID]:IsMajor() == true) then
			local pPlayer = Players[playerID];
			local pUnit = pPlayer:GetUnits():FindID(unitID);
			local unitTypeName = UnitManager.GetTypeName(pUnit);
			local unitGreatPerson = pUnit:GetGreatPerson()
			local msg = ""
			local dur = 5
			if (unitTypeName == "UNIT_GALLEY" and bGalley == false) then
				unitName = Locale.Lookup(GameInfo.Units[unitTypeName].Name)
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has built the first "..unitName
				dur = 15
				StatusMessage( msg, dur, ReportingStatusTypes.DEFAULT )
				bGalley = true
			end
			if (unitTypeName == "UNIT_KNIGHT" and bKnight == false) then
				unitName = Locale.Lookup(GameInfo.Units[unitTypeName].Name)
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has trained the first "..unitName
				dur = 15
				StatusMessage( msg, dur, ReportingStatusTypes.DEFAULT )
				bKnight = true
			end
			if (unitTypeName == "UNIT_SWORDSMAN" and bSword == false) then
				unitName = Locale.Lookup(GameInfo.Units[unitTypeName].Name)
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has trained the first "..unitName
				dur = 15
				StatusMessage( msg, dur, ReportingStatusTypes.DEFAULT )
				bSword = true
			end
			if (unitTypeName == "UNIT_CROSSBOWMAN" and bCross == false) then
				unitName = Locale.Lookup(GameInfo.Units[unitTypeName].Name)
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has trained the first "..unitName
				dur = 15
				StatusMessage( msg, dur, ReportingStatusTypes.DEFAULT )
				bCross = true
			end
			if (unitTypeName == "UNIT_MUSKETMAN" and bMusket == false) then
				unitName = Locale.Lookup(GameInfo.Units[unitTypeName].Name)
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has trained the first "..unitName
				dur = 15
				StatusMessage( msg, dur, ReportingStatusTypes.DEFAULT )
				bMusket = true
			end
			if (unitTypeName == "UNIT_BOMBARD" and bBombard == false) then
				unitName = Locale.Lookup(GameInfo.Units[unitTypeName].Name)
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has built the first "..unitName
				dur = 15
				StatusMessage( msg, dur, ReportingStatusTypes.DEFAULT )
				bBombard = true
			end
			if (unitTypeName == "UNIT_FIELD_CANNON" and bField == false) then
				unitName = Locale.Lookup(GameInfo.Units[unitTypeName].Name)
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has built the first "..unitName
				dur = 15
				StatusMessage( msg, dur, ReportingStatusTypes.DEFAULT )
				bField = true
			end
			if (unitTypeName == "UNIT_TANK" and bTank == false) then
				unitName = Locale.Lookup(GameInfo.Units[unitTypeName].Name)
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has built the first "..unitName
				dur = 15
				StatusMessage( msg, dur, ReportingStatusTypes.DEFAULT )
				bTank = true
			end
			if (unitTypeName == "UNIT_CARAVEL" and bCara == false) then
				unitName = Locale.Lookup(GameInfo.Units[unitTypeName].Name)
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has built the first "..unitName
				dur = 15
				StatusMessage( msg, dur, ReportingStatusTypes.DEFAULT )
				bCara = true
			end
			if (unitTypeName == "UNIT_FRIGATE" and bFrigate == false) then
				unitName = Locale.Lookup(GameInfo.Units[unitTypeName].Name)
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has built the first "..unitName
				dur = 15
				StatusMessage( msg, dur, ReportingStatusTypes.DEFAULT )
				bFrigate = true
			end
			if (unitTypeName == "UNIT_BATTLESHIP" and bBattleship == false) then
				unitName = Locale.Lookup(GameInfo.Units[unitTypeName].Name)
				msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has built the first "..unitName
				dur = 15
				StatusMessage( msg, dur, ReportingStatusTypes.DEFAULT )
				bBattleship = true
			end
			if ( unitGreatPerson ~= nil ) then
				local individual = unitGreatPerson:GetIndividual();
				if ( individual > 1) then
					if  GameInfo.GreatPersonIndividuals[individual] ~= nil then
						personName = Locale.Lookup(GameInfo.GreatPersonIndividuals[individual].Name);
						msg = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()).." has recruited "..personName
						dur = 15
						StatusMessage( msg, dur, ReportingStatusTypes.DEFAULT )
					end  
				end
			end
			
		end
	--end
end
Events.UnitAddedToMap.Add(			OnUnitAddedToMap );

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
	--print("	GPData()")
	local bspec = false
	if (Game:GetProperty("SPEC_NUM") ~= nil) then
		for k = 1, Game:GetProperty("SPEC_NUM") do
			if ( Game:GetProperty("SPEC_ID_"..k)~= nil) then
				if Game.GetLocalPlayer() == Game:GetProperty("SPEC_ID_"..k) then
					bspec = true
				end
			end
		end
	end

	if ( bspec == true) then
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
			
			local personName:string = "";
			if  GameInfo.GreatPersonIndividuals[entry.Individual] ~= nil then
				personName = Locale.Lookup(GameInfo.GreatPersonIndividuals[entry.Individual].Name);
			end  

			--print("GPData", entry.Individual, entry.Class, entry.Era, entry.Claimant, personName)

			if (bHypatia == false and entry.Individual == 130 and entry.Claimant == nil) then
				msg = personName.." is now available!"
				dur = 15
				StatusMessage( msg, dur, ReportingStatusTypes.DEFAULT )
				bHypatia = true
			end
			if (bNewton == false and entry.Individual == 135 and entry.Claimant == nil) then
				msg = personName.." is now available!"
				dur = 15
				StatusMessage( msg, dur, ReportingStatusTypes.DEFAULT )
				bNewton = true
			end
			if (bElCid == false and entry.Individual == 60 and entry.Claimant == nil) then
				msg = personName.." is now available!"
				dur = 15
				StatusMessage( msg, dur, ReportingStatusTypes.DEFAULT )
				bElCid = true
			end
			if (bBonaparte == false and entry.Individual == 64 and entry.Claimant == nil) then
				msg = personName.." is now available!"
				dur = 15
				StatusMessage( msg, dur, ReportingStatusTypes.DEFAULT )
				bBonaparte = true
			end
			if (bEinstein == false and entry.Individual == 64 and entry.Claimant == nil) then
				msg = personName.." is now available!"
				dur = 15
				StatusMessage( msg, dur, ReportingStatusTypes.DEFAULT )
				bEinstein = true
			end
			if (bBreedlove == false and entry.Individual == 89 and entry.Claimant == nil) then
				msg = personName.." is now available!"
				dur = 15
				StatusMessage( msg, dur, ReportingStatusTypes.DEFAULT )
				bBreedlove = true
			end
			if (bDuilius == false and entry.Individual == 1 and entry.Claimant == nil) then
				msg = personName.." is now available!"
				dur = 15
				StatusMessage( msg, dur, ReportingStatusTypes.DEFAULT )
				bDuilius = true
			end
			if (bCruz == false and entry.Individual == 7 and entry.Claimant == nil) then
				msg = personName.." is now available!"
				dur = 15
				StatusMessage( msg, dur, ReportingStatusTypes.DEFAULT )
				bCruz = true
			end
			if (bGoddard == false and entry.Individual == 49 and entry.Claimant == nil) then
				msg = personName.." is now available!"
				dur = 15
				StatusMessage( msg, dur, ReportingStatusTypes.DEFAULT )
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
				StatusMessage( msg, dur, ReportingStatusTypes.DEFAULT )
				bKorolev  = true
			end
			if (bBraun == false and entry.Individual == 55 and entry.Claimant == nil) then
				msg = personName.." is now available!"
				dur = 15
				StatusMessage( msg, dur, ReportingStatusTypes.DEFAULT )
				bBraun  = true
			end
			if (bBentz == false and entry.Individual == 91 and entry.Claimant == nil) then
				msg = personName.." is now available!"
				dur = 15
				StatusMessage( msg, dur, ReportingStatusTypes.DEFAULT )
				bBentz  = true
			end

	end
	end

end
