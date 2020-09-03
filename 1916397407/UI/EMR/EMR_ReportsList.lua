-- ===========================================================================
--	Even More Reports: ReportsList
--  Author: Faronizer
-- ===========================================================================

function Initialize()
    -- local pReportsListMainStack = ContextPtr:LookUpControl("/InGame/ReportsList/MainStack");
    -- if pReportsListMainStack == nil then return end
    -- Controls.EvenMoreReportsTitle:ChangeParent(pReportsListMainStack)
    -- Controls.EvenMoreReportsStack:ChangeParent(pReportsListMainStack)
    
    LuaEvents.EMR_ReportsList_Initialized()
end

Events.LoadGameViewStateDone.Add(Initialize); 