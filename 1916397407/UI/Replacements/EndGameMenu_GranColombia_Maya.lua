-- Copyright 2020, Firaxis Games
function SetClimateChangeDefeatMovie(forDefeatStyle)
	if(forDefeatStyle) then
		local CLIMATE_CHANGE_LEVEL_THRESHOLD = 8;

		forDefeatStyle.Movie = function() 
			local getClimateChangeLevel = GameClimate and GameClimate.GetClimateChangeLevel;
			if(getClimateChangeLevel and getClimateChangeLevel() >= CLIMATE_CHANGE_LEVEL_THRESHOLD) then
				return "GranColombia_Maya_DefeatClimate.bk2"
			else
				return "Defeat.bk2";
			end		
		end

		forDefeatStyle.SndStart = function()
			local getClimateChangeLevel = GameClimate and GameClimate.GetClimateChangeLevel;
			if(getClimateChangeLevel and getClimateChangeLevel() >= CLIMATE_CHANGE_LEVEL_THRESHOLD) then
				return "Play_Cinematic_Endgame_MegaDefeat";
			else
				return "Play_Cinematic_Endgame_Defeat";
			end			
		end

		forDefeatStyle.SndStop = function()
			local getClimateChangeLevel = GameClimate and GameClimate.GetClimateChangeLevel;
			if(getClimateChangeLevel and getClimateChangeLevel() >= CLIMATE_CHANGE_LEVEL_THRESHOLD) then
				return "Stop_Cinematic_Endgame_MegaDefeat";
			else
				return "Stop_Cinematic_Endgame_Defeat";
			end		
		end
	end
end

SetClimateChangeDefeatMovie(Styles["DEFEAT_DEFAULT"]);
SetClimateChangeDefeatMovie(Styles["GENERIC_DEFEAT"]);
