-- ===========================================================================
--	Copyright (c) 2018 Firaxis Games
-- ===========================================================================

-- ===========================================================================
-- INCLUDE XP2 FILE
-- ===========================================================================
include("UnitPanel_Expansion2");
print("UnitPanel for BSM")

local XP2_LateInitialize 				= LateInitialize;
local XP2_OnUnitActionClicked 			= OnUnitActionClicked;
local XP2_OnInputHandler 				= OnInputHandler;
local XP2_OnInputActionTriggered 		= OnInputActionTriggered;
local XP2_AddActionToTable 				= AddActionToTable;
local m_bspec 							= false;


-- ===========================================================================

function AddActionToTable( actionsTable:table, action:table, disabled:boolean, toolTipString:string, actionHash:number, callbackFunc:ifunction, callbackVoid1, callbackVoid2, overrideIcon:string)
	
	if ( m_bspec == true ) then
		disabled = true
	end
	
	XP2_AddActionToTable ( actionsTable, action, disabled, toolTipString, actionHash, callbackFunc, callbackVoid1, callbackVoid2, overrideIcon)

end

function OnInputHandler( pInputStruct:table )
	print("OnInputHandler")
	local uiMsg = pInputStruct:GetMessageType();
	-- If not the current turn or current unit is dictated by cursor/touch
	-- hanging over a flag
	if ( m_bspec == true ) and ( uiMsg == MouseEvents.MouseMove ) then	
		InspectWhatsBelowTheCursor();
		return
	end
	XP2_OnInputHandler(pInputStruct)	
end

function OnInputActionTriggered( actionId )
	if ( m_bspec == true ) then
		return
	end
	XP2_OnInputActionTriggered( actionId )
end

function InspectWhatsBelowTheCursor()
	local localPlayerID			:number = Game.GetLocalPlayer();
	if (localPlayerID == -1) then
		return;
	end

	local pPlayerVis	= PlayersVisibility[localPlayerID];
	if (pPlayerVis == nil) then
		return false;
	end

	-- Do not show the combat preview for non-combat units.
	local selectedPlayerUnit	:table	= UI.GetHeadSelectedUnit();
	
	if (selectedPlayerUnit ~= nil) then
		if (selectedPlayerUnit:GetCombat() == 0 and selectedPlayerUnit:GetReligiousStrength() == 0) then
			return;
		end
	end

	local plotId = UI.GetCursorPlotID();
	if (plotId ~= m_plotId) then
		m_plotId = plotId;
		local plot = Map.GetPlotByIndex(plotId);
		if plot ~= nil then
			local bIsVisible	= pPlayerVis:IsVisible(m_plotId);
			
			if (bIsVisible or m_bspec == true) then
				InspectPlot(plot);
			else
				OnShowCombat(false);
			end
		end
	end
end

function ShowHideSelectedUnit()
	g_isOkayToProcess = true;
	local pSelectedUnit :table = UI.GetHeadSelectedUnit();
	if pSelectedUnit ~= nil then
		g_selectedPlayerId				= pSelectedUnit:GetOwner();
		g_UnitId						= pSelectedUnit:GetID();
		m_primaryColor, m_secondaryColor= UI.GetPlayerColors( g_selectedPlayerId );
		Refresh( g_selectedPlayerId, g_UnitId );
	else
		Hide();
	end
end

function OnUnitActionClicked( actionType:number, actionHash:number, currentMode:number )
	if m_bspec == true then
		return
	end
	XP2_OnUnitActionClicked(actionType, actionHash, currentMode)
end

function LateInitialize()
	print("LateInitialize()")
	
	if Game.GetLocalPlayer() == nil or Game.GetLocalPlayer() == -1 then
		return
	end
	if PlayerConfigurations[Game.GetLocalPlayer()] ~= nil then
		if PlayerConfigurations[Game.GetLocalPlayer()]:GetLeaderTypeName() == "LEADER_SPECTATOR" then
			m_bspec = true
			g_isOkayToProcess = false
		end
	end
	XP2_LateInitialize()
end