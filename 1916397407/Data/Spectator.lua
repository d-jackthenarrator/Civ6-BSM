------------------------------------------------------------------------------
--	FILE:	 Spectator.lua
--	AUTHOR:  D. / Jack The Narrator
--	PURPOSE: Gameplay script - Add an Spectator to the game in a non-disruptive manner
-------------------------------------------------------------------------------
-- logs
-- v0.1 	added Observer Support
-- v0.2 	added Mod basic UI
--		Spectator players now default movement to quick combat/movement to not delay the MP games
-- v0.3 	New Implementation
-- v0.4 	Congress integrated
-- v0.41	Fixed a typo in the congress code
-- v0.42 	Now can follow the scores and process of players
-- v0.43	Now with correct GS banner
-- v0.44	fix
-- v0.5		Now includes City-State Panel
-- v0.6		Now have icons
--		Better unit handling
--		Permanent visibility on cities
--		Can see unit flgs during the turn changes
-- v0.7		working on one way visiblity / GetOwner plot
--		Introduce jump observer
-- v0.8		Observer now goes back to the previous player after the tunr completes
--		Add resources icons again (different technique)
-- v0.9		Add Tech/Civic View
--		Kill the delegation and other stupid auto popup from aI to the Observer
--		Recall Observer onpromotion and unitkilled event (test)
--		Added strategic resources / yields
-- v0.91	Corrected toppanel glitches
--		Added the great work panel
--		banner production and food growth
-- v0.92	Corrected more glitcjes
--		Governement panel
--		Governor panel
--		Added hook for world tracker to update quickly	
-- v0.93	Moved UI Observer storage to GameConfiguration for easier bouncing on the UI side
-- v0.94	Added Unit support
--		Added diplomacy info when switching players
--		Added era score mouse over on diplomacy ribbon
-- v0.95	Dedications added to leader tootip
--		Cleaned up the Observer view
--		Working spy screen
--		Put the view point
-- v0.96	Display loyalty (to do)
--		Detailled scores on top
--		Now would pick the name not the coded code for leaders/cities
--		Goody Hut notifications
--		Great People Notifications
--		First important unit notifications
--		Added Tech #, Civivc #, unit # in the tooltip to help comparing
-- v0.97	Improve chat visibility while being player 1000
--		Extended visibility to adjacent tiles (so that 3d models don t disappear close to the city border)
--		Added Envoy supports in Top Panel
--		to do add ranking on top panel?
--		to do improve/add more notifications
--		Imporved resources / flags refresh
--		Added Multi-Observer supports
--		Add reports supports (bugged)
--		Added Graphs Reports from EMR
-- v0.98	Fixed the techtree
--		Fixed a bug notifying GP to non spectators
-- v0.99	Fixed a bug with game with open slots
-- v1.00	Added A tick-box for Single Player Auto-End Turn
--		Spectator can now votes in congress (temp fix) Need Firaxis solution
-- v1.01	Removed some trails to clean up the lua.log
--		Change the logic so that spectator votes can be manualy inputed
-- v1.02	Improve Ribbon sorting, tied it to MP Helper
-- v1.03	Correctly Reanchor Congress
--		Display pings & Lag when used with MP Helper
--		Fixed tooltip for all observer
--		Added Nukes to the HUD
-- v1.04	PLayers would have their portrait on the left even in Teamers
--			Spec now get 4 tabs triggered by mouseover on their spec panel
-- v1.05	Added a Yield button
--			Several minors visual tweaks
--			When used with Multiplayer Helper you no longer need to allow duplicate leader for multi-observers
--			Tech/Score view is changing every 20 secs (from 5 previously)
--			Auto-end of turn for spec can be changed in-game
--			Code cleanup
-- v1.06	Adjusted the Score screen for Religious and Cultural Victory to ignore the Observers
--		Added MPH hooks to display victory screen if MPH is used
-- v1.07	Emergency New Frontier Pass path
--		More fixes will come later
-- v1.08	Improved the Diplomacy Ribbon code
--		Spectator now sees the Civ Colour/Logo to help viewers identify the teams
-- v1.09	Ruleset Based
-- v1.10	Remove Ruleset to allow NFP / Ethiopia compatibility.
--		Only top 4 slots can be Observers
-- v1.11	Support for the Gaul Patch
-- v1.12	Added Tournament support with MPH
--		Fixed some database errors and other minors glitches	


---------------------------------------------------------------------------------
ExposedMembers.LuaEvents = LuaEvents

local bLaunch = false;
local spec_num = 0
local g_version = "v1.12"

function Spec_Script_Init()
		local currentTurn = Game.GetCurrentGameTurn();
		local bSpectator = false;
		local iNumMajCivs = 0;
		local MajorList = {};
		local spec_i = nil;
		spec_num = 0
		iNumMajCivs = PlayerManager.GetAliveMajorsCount();
		MajorList = PlayerManager.GetAliveMajorIDs();
		print("Turn ",currentTurn,": Local player Leader:", PlayerConfigurations[Game.GetLocalPlayer()]:GetLeaderTypeName()," ID:",Game.GetLocalPlayer());
		for i = 1, iNumMajCivs do
			local sPlayerLeaderName = PlayerConfigurations[MajorList[i]]:GetLeaderTypeName();
			local sPlayerCivName = PlayerConfigurations[MajorList[i]]:GetCivilizationTypeName();
			if (sPlayerLeaderName=="LEADER_SPECTATOR") then
				print("Turn ",currentTurn,": A Spectator Civ Has Been Detected! ID:",MajorList[i]);
				spec_i = MajorList[i];
				spec_num = spec_num + 1;
				local pPlayer = Players[spec_i];
				local pVis = PlayersVisibility[spec_i];
				print(GameConfiguration.GetValue("GAME_NO_BARBARIANS"))
				if (pVis ~= nil) then
					for iPlotIndex = 0, Map.GetPlotCount()-1, 1 do
						local pPlot = Map.GetPlotByIndex(iPlotIndex)
						if (pPlot:IsNaturalWonder() == false) then
							pVis:ChangeVisibilityCount(iPlotIndex, 0); 
						end
					end
				end
				if (bLaunch == true) then
 					if (pPlayer ~= nil) then
    						local pPlayerUnits:table = pPlayer:GetUnits();
						print("Deleting units on init");
    						if (pPlayerUnits) then
      							for i, pUnit in pPlayerUnits:Members() do
          							pPlayer:GetUnits():Destroy(pUnit)
      							end
    						end
  					end
				end
			
				Game:SetProperty("SPEC_ID",spec_i)
				Game:SetProperty("SPEC_ID_"..spec_num,spec_i)
				Game:SetProperty("SPEC_INIT",true)
 	 		end

		end

		if spec_num > 0 then
			Game:SetProperty("SPEC_NUM",spec_num)
		end

		print("Turn ",currentTurn,": Grant Access to other civs");
		if ( Game:GetProperty("SPEC_NUM") ~= nil and bLaunch == true) then
			for k = 1, spec_num do
			for i = 1, iNumMajCivs do
				local pPlayerCulture:table = Players[MajorList[i]]:GetCulture()
				if ( i~= Game:GetProperty("SPEC_ID_"..k)) then
					Players[Game:GetProperty("SPEC_ID_"..k)]:GetDiplomacy():SetHasMet(MajorList[i])
					--Players[Game:GetProperty("SPEC_ID_"..k)]:GetDiplomacy():SetHasDelegationAt(MajorList[i],true)
					--Players[Game:GetProperty("SPEC_ID_"..k)]:GetDiplomacy():SetHasEmbassyAt(MajorList[i],true)
					Players[Game:GetProperty("SPEC_ID_"..k)]:GetDiplomacy():SetVisibilityOn(MajorList[i],true)
					--Players[Game:GetProperty("SPEC_ID")]:GetDiplomacy():SetPermanentAlliance(MajorList[i])
					Players[Game:GetProperty("SPEC_ID_"..k)]:GetDiplomacy():RecheckVisibilityOnAll()
					--print(Players[i]:GetEras():GetEra())		
				end
				--print("GameInfo.Civics[DIPLOMATIC_SERVICE].Index",GameInfo.Civics["CIVIC_DIPLOMATIC_SERVICE"].Index)
				--pPlayerCulture:ReverseBoost(GameInfo.Civics["CIVIC_DIPLOMATIC_SERVICE"].Index)
				local pPlayerTechs:table = Players[MajorList[i]]:GetTechs();
				pPlayerTechs:ReverseBoost(GameInfo.Technologies["TECH_WRITING"].Index)
			end
			pPlayerCulture = Players[Game:GetProperty("SPEC_ID_"..k)]:GetCulture()
			pPlayerCulture:SetCivic(GameInfo.Civics["CIVIC_CODE_OF_LAWS"].Index,true)
			end
		end
		
		
end

function CleanBoost()
	if ( Game:GetProperty("SPEC_ID") ~= nil ) then
		local iNumMajCivs = PlayerManager.GetAliveMajorsCount();
		local MajorList = PlayerManager.GetAliveMajorIDs();
		for i = 1, iNumMajCivs do
			local pPlayerTechs:table = Players[MajorList[i]]:GetTechs();
			pPlayerTechs:ReverseBoost(GameInfo.Technologies["TECH_WRITING"].Index)
		end
	end
end

LuaEvents.UICleanBoost.Add ( CleanBoost );

function DoObserver(id)
	if ( Game:GetProperty("SPEC_NUM") ~= nil ) then
		for k =1, Game:GetProperty("SPEC_NUM") do
			if ( Game.GetLocalPlayer() == Game:GetProperty("SPEC_ID_"..k)) then
				--print("Turning to observer")
				PlayerManager.SetLocalObserverTo(1000);
			end
		end
	end
end

LuaEvents.UIDoObserver.Add ( DoObserver );

function DoObserverPlayer(id:number)
	local currentTurn = Game.GetCurrentGameTurn();
	local bspec = false
	if ( Game:GetProperty("SPEC_NUM") ~= nil ) then
		for k =1, Game:GetProperty("SPEC_NUM") do
			if Game:GetProperty("SPEC_ID_"..k) == id then
				bspec = true
			end
		end
		if bspec == false then
			PlayerManager.SetLocalObserverTo(id);
			else		
			PlayerManager.SetLocalObserverTo(1000)
		end
		Game:SetProperty("SPEC_LAST_ID",id)
	end
	--print("Turned to Observer: Turn:",currentTurn,"PlayerID:",id)
	
end

LuaEvents.UIDoObserverPlayer.Add ( DoObserverPlayer );


function UndoObserver(id)
	if ( Game:GetProperty("SPEC_NUM") ~= nil ) then
		for k =1, Game:GetProperty("SPEC_NUM") do
			if ( Game.GetLocalPlayer() == Game:GetProperty("SPEC_ID_"..k)) then
				--print("Turning to spectator")
				PlayerManager.SetLocalObserverTo(Game.GetLocalPlayer());
			end
		end
	end
end

LuaEvents.UIUndoObserver.Add ( UndoObserver );



-------------------------------------------------------------------------------
function OnCityBuilt( playerID: number, cityID : number, cityX : number, cityY : number )	
	--print("New city found by player", playerID, "X",cityX,"Y",cityY)
	if ( Game:GetProperty("SPEC_NUM") ~= nil ) then
		for k =1, Game:GetProperty("SPEC_NUM") do
			if (Game:GetProperty("SPEC_ID_"..k) ~= nil) then
				local pVis = PlayersVisibility[Game:GetProperty("SPEC_ID_"..k)];
				for iPlotIndex = 0, Map.GetPlotCount()-1, 1 do
					local pPlot = Map.GetPlotByIndex(iPlotIndex)
					local pPlot_Owner = pPlot:GetOwner()
					if (pPlot_Owner ~=nil ) then
						if (Players[pPlot_Owner] ~= nil) then
							if (Players[pPlot_Owner]:IsMajor() == true) then
								pVis:ChangeVisibilityCount(iPlotIndex, 2); 
								for j = 0, 5 do
									local pAdjacentPlot = Map.GetAdjacentPlot(pPlot:GetX(),pPlot:GetY(),j)
									if pAdjacentPlot ~= nil then
										--print("gameplay",pAdjacentPlot:GetIndex())
										pVis:ChangeVisibilityCount(pAdjacentPlot:GetIndex(),2);
									end
								end
							end
						end
					end
				end
			end
		end
	end
end



function OnTurnStarted()
	local currentTurn = Game.GetCurrentGameTurn();
	local tmpspecid = nil
	local tmpspeclast = nil
	local bspec = false
	if Game:GetProperty("SPEC_ID") ~= nil then
		tmpspecid = Game:GetProperty("SPEC_ID")
		if Game:GetProperty("SPEC_LAST_ID") ~= nil then
			tmpspeclast =  Game:GetProperty("SPEC_LAST_ID")
			if  Game:GetProperty("SPEC_LAST_ID") == Game.GetLocalPlayer() then
				bspec = true
			end
		end
	end
	Game:SetProperty("SPEC_LAST_ID",id)
	--print("Turned to Observer: Turn:",currentTurn,"Spec ID:",tmpspecid,"Last Observed ID:",tmpspeclast,"IsLocalObserver?",bspec)
end

function OnPlayerTurnActivated()

end


--------------------------------------------------------------------------------

function Initialize()
	print("-- Init D. Better Spectator Mod "..g_version.." --");
	local currentTurn = Game.GetCurrentGameTurn();
	bLaunch = false;

	if currentTurn == GameConfiguration.GetStartTurn() then
		bLaunch = true;
	end

	Spec_Script_Init();
	GameEvents.CityBuilt.Add(OnCityBuilt )
	GameEvents.PlayerTurnStarted.Add(OnPlayerTurnActivated);

end


Initialize();
