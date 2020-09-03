-- ===========================================================================
--	Even More Reports: ReportScreen
--  Author: Faronizer
-- ===========================================================================
include("ReportScreen")

if not ExposedMembers.EMR then ExposedMembers.EMR = {} end;
local EMR = ExposedMembers.EMR;

local bRiseFall:boolean = Modding.IsModActive("1B28771A-C749-434B-9053-D1380C553DE9");
local bGatheringStorm:boolean = Modding.IsModActive("4873eb62-8ccc-4574-b784-dda455e74e68"); 
local bBetterReportScreen:boolean = Modding.IsModActive("6f2888d4-79dc-415f-a8ff-f9d81d7afb53"); 
local bConciseUI_Core:boolean = Modding.IsModActive("5f504949-398a-4038-a838-43c3acc4dc10");
local bConciseUI_ReportScreen:boolean = Modding.IsModActive("bef43a06-5382-4e8d-87a7-d89e045d8bee"); 

local m_DefaultMainSizeX = Controls.Main:GetSizeX()
local m_ExtendedMainSizeX = 1144
local m_CenterAlignTabsArg = -5

function ViewDemographicsPage()
	ResetTabForNewPageContent();

	local instance:table = m_simpleIM:GetInstance();
	instance.Top:DestroyAllChildren();
	
	instance.Children = {}
	instance.Descend = true
    
    emr_instance = EMR.Demographics.GetInstance();
    emr_instance.DemographicsContainer:ChangeParent(instance.Top);
    EMR.Demographics.UpdateContent();
   
    Controls.Stack:CalculateSize();
	Controls.Scroll:CalculateSize();

	Controls.CollapseAll:SetHide( true );
	Controls.BottomYieldTotals:SetHide( true );
	Controls.BottomResourceTotals:SetHide( true );
    if bBetterReportScreen then
        Controls.BottomPoliciesFilters:SetHide( true );
        Controls.BottomMinorsFilters:SetHide( true );
    end
	Controls.Scroll:SetSizeY( Controls.Main:GetSizeY() - 88);
    
    m_kCurrentTab = #m_tabs.tabControls - 1;
end

function ViewGraphsPage()
    ResetTabForNewPageContent();

	local instance:table = m_simpleIM:GetInstance();
	instance.Top:DestroyAllChildren();
	
	instance.Children = {}
	instance.Descend = true
    
    emr_instance = EMR.Graphs.GetInstance();
    emr_instance.GraphPanel:ChangeParent(instance.Top);
    EMR.Graphs.UpdateContent();
    
    Controls.Stack:CalculateSize();
	Controls.Scroll:CalculateSize();

	Controls.CollapseAll:SetHide( true );
	Controls.BottomYieldTotals:SetHide( true );
	Controls.BottomResourceTotals:SetHide( true );
    if bBetterReportScreen then
        Controls.BottomPoliciesFilters:SetHide( true );
        Controls.BottomMinorsFilters:SetHide( true );
    end
	Controls.Scroll:SetSizeY( Controls.Main:GetSizeY() - 88);
    
    m_kCurrentTab = #m_tabs.tabControls;
end

if not bBetterReportScreen then
    function OpenTab( tabToOpen:number )
        Open();
        m_tabs.SelectTab( tabToOpen );
    end
    
    function AddTabSection( name:string, populateCallback:ifunction )
        local DATA_FIELD_SELECTION:string = "Selection";
        local kTab		:table				= m_tabIM:GetInstance();	
        kTab.Button[DATA_FIELD_SELECTION]	= kTab.Selection;

        local callback	:ifunction	= function()
            if m_tabs.prevSelectedControl ~= nil then
                m_tabs.prevSelectedControl[DATA_FIELD_SELECTION]:SetHide(true);
            end
            kTab.Selection:SetHide(false);
            local k = 1
            for i, control in ipairs(m_tabs.tabControls) do
                if control:GetText() == kTab.Button:GetText() then
                    k = i
                end
            end
            if k < #m_tabs.tabControls - 1 then
                Controls.Main:SetSizeX(m_DefaultMainSizeX)
            else
                Controls.Main:SetSizeX(m_ExtendedMainSizeX)
            end
            m_tabs.CenterAlignTabs(m_CenterAlignTabsArg);
            populateCallback();
        end

        kTab.Button:GetTextControl():SetText( Locale.Lookup(name) );
        kTab.Button:SetSizeToText( 40, 20 );
        kTab.Button:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);

        m_tabs.AddTab( kTab.Button, callback );
    end
end


function InjectReports()
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
    AddTabSection("D-graphics", ViewDemographicsPage);
    AddTabSection("Graphs", ViewGraphsPage);
    if bBetterReportScreen then
        LuaEvents.ReportsList_OpenDemographics.Add(function() Open(#m_tabs.tabControls - 1); end );
        LuaEvents.ReportsList_OpenGraphs.Add(function() Open(#m_tabs.tabControls); end );
        m_tabs.SameSizedTabs(15);
    elseif bConciseUI_ReportScreen then
        LuaEvents.ReportsList_OpenDemographics.Add(function() OpenTab(#m_tabs.tabControls - 1); end );
        LuaEvents.ReportsList_OpenGraphs.Add(function() OpenTab(#m_tabs.tabControls); end );
        m_tabs.SameSizedTabs(-40);
    else
        LuaEvents.ReportsList_OpenDemographics.Add(function() OpenTab(#m_tabs.tabControls - 1); end );
        LuaEvents.ReportsList_OpenGraphs.Add(function() OpenTab(#m_tabs.tabControls); end );
        m_tabs.SameSizedTabs(0);
    end
    m_tabs.CenterAlignTabs(m_CenterAlignTabsArg);
		end
	end

end

Events.LoadGameViewStateDone.Add(InjectReports); 