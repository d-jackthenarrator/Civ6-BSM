-- ===========================================================================
--	Even More Reports: ReportsList
--  Author: Faronizer
-- ===========================================================================
local bRiseFall:boolean = Modding.IsModActive("1B28771A-C749-434B-9053-D1380C553DE9"); -- Rise & Fall
local bGatheringStorm:boolean = Modding.IsModActive("4873eb62-8ccc-4574-b784-dda455e74e68"); -- Gathering Storm
local bBetterReportScreen:boolean = Modding.IsModActive("6f2888d4-79dc-415f-a8ff-f9d81d7afb53"); -- Better Report Screen
local bRealEraTracker:boolean = Modding.IsModActive("11B9FBBE-25BD-7E24-3909-67A060B2456C"); -- Real Era Tracker

local bBRS_or_RET:boolean = bBetterReportScreen or bRealEraTracker

if bBRS_or_RET then 
    include("ReportsListLoader")
else
    include("ReportsList")
end

local function ContextualClose()
    -- only Better Report Screen closes the ReportsList Panel
    if bBRS_or_RET then Close() end
end

function OnRaiseDemographicsReport() ContextualClose(); LuaEvents.ReportsList_OpenDemographics(); end
function OnRaiseDiplomacyReport() ContextualClose(); LuaEvents.ReportsList_OpenDiplomacy(); end
function OnRaiseGraphsReport() ContextualClose(); LuaEvents.ReportsList_OpenGraphs(); end

function InjectReports() 
    -- pEvenMoreReportsStack = ContextPtr:LookUpControl("../EMR_ReportsList/EvenMoreReportsStack")
    -- if pEvenMoreReportsStack ~= nil then   
        -- AddReport("LOC_EMR_DEMOGRAPHICS", OnRaiseDemographicsReport, pEvenMoreReportsStack);
        -- AddReport("LOC_EMR_DIPLOMACY", OnRaiseDiplomacyReport, pEvenMoreReportsStack);
        -- AddReport("LOC_EMR_GRAPHS", OnRaiseGraphsReport, pEvenMoreReportsStack);
    -- end
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
		if (bspec == true) then
    			AddReport("LOC_EMR_DEMOGRAPHICS", OnRaiseDemographicsReport, Controls.GlobalReportsStack);
    			AddReport("LOC_EMR_DIPLOMACY", OnRaiseDiplomacyReport, Controls.GlobalReportsStack);
    			AddReport("LOC_EMR_GRAPHS", OnRaiseGraphsReport, Controls.GlobalReportsStack);
    			Controls.GlobalTitle:SetHide(false);
			else
			Controls.GlobalTitle:SetHide(true);
		end
	end

end

-- be late to the party
LuaEvents.EMR_ReportsList_Initialized.Add(InjectReports);
-- Events.LoadGameViewStateDone.Add(InjectReports);