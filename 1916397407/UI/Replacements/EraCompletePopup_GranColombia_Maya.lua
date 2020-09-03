--[[
-- Created by Arthur Gould, January 24, 2020
-- Copyright (c) Firaxis Games
--]]
-- ===========================================================================
-- Base File
-- ===========================================================================
include("EraCompletePopup");

function RealizeColorKey( fadeTime:number )	
	local CLIMATE_CHANGE_LEVEL_THRESHOLD = 8;
	local DISASTER_COLORKEY_INTENSITY = 0.65;
	local getClimateChangeLevel = GameClimate and GameClimate.GetClimateChangeLevel;
	local localPlayerID:number = Game.GetLocalPlayer();
	if (localPlayerID ~= nil) then
		if(getClimateChangeLevel and getClimateChangeLevel() >= CLIMATE_CHANGE_LEVEL_THRESHOLD) then		
			Events.EnableColorKey("DISASTER_COLORKEY", DISASTER_COLORKEY_INTENSITY, fadeTime);
			WorldView.PlayEffectAtXY("APOCALYPSE_SCREEN_VFX", 0, 0, true); 
		else
			local gameEras:table = Game.GetEras(); 
			if (gameEras ~= nil) then				
				if (gameEras:HasGoldenAge(localPlayerID)) then
					Events.EnableColorKey("golden_age_colorkey", .3, fadeTime);
				elseif (gameEras:HasDarkAge(localPlayerID)) then
					Events.EnableColorKey("dark_age_colorkey", .5, fadeTime);
				else
					Events.DisableColorKey( fadeTime );
				end
			end
		end
	end
end

RealizeColorKey( 0 );	
