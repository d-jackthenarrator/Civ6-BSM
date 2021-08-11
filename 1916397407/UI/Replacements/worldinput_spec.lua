--[[
-- Copyright (c) 2018 Firaxis Games
--]]
-- ===========================================================================
-- INCLUDE XP2 FILE
-- ===========================================================================
include("WorldInput_Expansion2");

local m_bspec 							= false;
local XP2_OnMouseSelectionUnitMoveEnd 				= OnMouseSelectionUnitMoveEnd;
local XP2_Initialize 								= Initialize;
-- ===========================================================================
--	CACHE BASE FUNCTIONS
-- ===========================================================================

function OnMouseSelectionUnitMoveEnd( pInputStruct:table )	
	print("OnMouseSelectionUnitMoveEnd")
	if m_bspec == true then
		local pSelectedUnit:table = UI.GetHeadSelectedUnit();
		if pSelectedUnit ~= nil then		
			UnitMovementCancel();	
		end
		g_isMouseDownInWorld = false;
	
	
	
		return true;
	end
	
	XP2_OnMouseSelectionUnitMoveEnd(pInputStruct)

end

function Initialize()
	if Game.GetLocalPlayer() == nil or Game.GetLocalPlayer() == -1 then
		return
	end
	if PlayerConfigurations[Game.GetLocalPlayer()] ~= nil then
		if PlayerConfigurations[Game.GetLocalPlayer()]:GetLeaderTypeName() == "LEADER_SPECTATOR" then
			m_bspec = true
		end
	end
	print("WorldInput for BSM",m_bspec)
	XP2_Initialize()
end

Initialize()