-- ===========================================================================
--	Even More Reports Screen (based on ReportScreen from Better Report Screen)
-- ===========================================================================
print("Even More Reports ");

include("CitySupport");
include("Civ6Common");
include("InstanceManager");
include("SupportFunctions");
include("TabSupport");

-- exposing functions and variables
if not ExposedMembers.EMR then ExposedMembers.EMR = {} end;
local EMR = ExposedMembers.EMR;

-- ===========================================================================
-- Rise & Fall check
-- ===========================================================================

local bIsRiseFall:boolean = Modding.IsModActive("1B28771A-C749-434B-9053-D1380C553DE9"); -- Rise & Fall
local bIsGatheringStorm:boolean = Modding.IsModActive("4873eb62-8ccc-4574-b784-dda455e74e68"); -- Gathering Storm


-- ===========================================================================
--	DEBUG
--	Toggle these for temporary debugging help.
-- ===========================================================================
local m_debugNumResourcesStrategic	:number = 0;			-- (0) number of extra strategics to show for screen testing.
local m_debugNumBonuses				:number = 0;			-- (0) number of extra bonuses to show for screen testing.
local m_debugNumResourcesLuxuries	:number = 0;			-- (0) number of extra luxuries to show for screen testing.


-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local DARKEN_CITY_INCOME_AREA_ADDITIONAL_Y		:number = 6;
local DATA_FIELD_SELECTION						:string = "Selection";
local SIZE_HEIGHT_BOTTOM_YIELDS					:number = 135;
local SIZE_HEIGHT_PADDING_BOTTOM_ADJUST			:number = 85;	-- (Total Y - (scroll area + THIS PADDING)) = bottom area
local INDENT_STRING								:string = "      ";
local TOOLTIP_SEP								:string = "-------------------";
local TOOLTIP_SEP_NEWLINE						:string = "[NEWLINE]"..TOOLTIP_SEP.."[NEWLINE]";

-- Mapping of unit type to cost.
local UnitCostMap:table = {};
do
	for row in GameInfo.Units() do
		UnitCostMap[row.UnitType] = row.Maintenance;
	end
end

--BRS !! Added function to sort out tables for units
-- Infixo: this is only used by Upgrade Callback; parent will be used a flag; must be set to nil when leaving report screen
local tUnitSort = { type = "", group = "", parent = nil };

-- Infixo: this is an iterator to replace pairs
-- it sorts t and returns its elements one by one
function spairs( t, order_function )
	local keys:table = {}; -- actual table of keys that will bo sorted
	for key,_ in pairs(t) do table.insert(keys, key); end
	
	if order_function then
		table.sort(keys, function(a,b) return order_function(t, a, b) end)
	else
		table.sort(keys)
	end
	-- iterator here
	local i:number = 0;
	return function()
		i = i + 1;
		if keys[i] then
			return keys[i], t[keys[i]]
		end
	end
end
-- !! end of function

-- ===========================================================================
--	VARIABLES
-- ===========================================================================

m_simpleIM							= InstanceManager:new("SimpleInstance",			"Top",		Controls.Stack);				-- Non-Collapsable, simple
m_tabIM								= InstanceManager:new("TabInstance",			"Button",	Controls.TabContainer);
m_strategicResourcesIM				= InstanceManager:new("ResourceAmountInstance",	"Info",		Controls.StrategicResources);
m_bonusResourcesIM					= InstanceManager:new("ResourceAmountInstance",	"Info",		Controls.BonusResources);
m_luxuryResourcesIM					= InstanceManager:new("ResourceAmountInstance",	"Info",		Controls.LuxuryResources);
local m_groupIM				:table  = InstanceManager:new("GroupInstance",			"Top",		Controls.Stack);				-- Collapsable


m_kCityData = nil;
m_tabs = nil;
m_kResourceData = nil;
local m_kCityTotalData		:table = nil;
local m_kUnitData			:table = nil;	-- TODO: Show units by promotion class
local m_kDealData			:table = nil;
local m_uiGroups			:table = nil;	-- Track the groups on-screen for collapse all action.

local m_isCollapsing		:boolean = true;
--BRS !! new variables
local m_kCurrentDeals	:table = nil;
local m_kUnitDataReport	:table = nil;
local m_kPolicyData		:table = nil;
local m_kMinorData		:table = nil;
local m_kModifiers		:table = nil; -- to calculate yield per pop and other modifier-ralated effects on the city level
local m_kModifiersUnits	:table = nil; -- to show various abilities and effects
-- !!
-- Remember last tab variable: ARISTOS
m_kCurrentTab = 1;
-- !!

-- ===========================================================================
-- Time helpers and debug routines
-- ===========================================================================
local fStartTime1:number = 0.0
local fStartTime2:number = 0.0
function Timer1Start()
	fStartTime1 = Automation.GetTime()
	--print("Timer1 Start", fStartTime1)
end
function Timer2Start()
	fStartTime2 = Automation.GetTime()
	--print("Timer2 Start() (start)", fStartTime2)
end
function Timer1Tick(txt:string)
	print("Timer1 Tick", txt, string.format("%5.3f", Automation.GetTime()-fStartTime1))
end
function Timer2Tick(txt:string)
	print("Timer2 Tick", txt, string.format("%5.3f", Automation.GetTime()-fStartTime2))
end

-- debug routine - prints a table (no recursion)
function dshowtable(tTable:table)
	if tTable == nil then print("dshowtable: table is nil"); return; end
	for k,v in pairs(tTable) do
		print(k, type(v), tostring(v));
	end
end

-- debug routine - prints a table, and tables inside recursively (up to 5 levels)
function dshowrectable(tTable:table, iLevel:number)
	local level:number = 0;
	if iLevel ~= nil then level = iLevel; end
	for k,v in pairs(tTable) do
		print(string.rep("---:",level), k, type(v), tostring(v));
		if type(v) == "table" and level < 5 then dshowrectable(v, level+1); end
	end
end

-- ===========================================================================
-- Updated functions from Civ6Common, to include rounding to 1 decimal digit
-- ===========================================================================
function toPlusMinusString( value:number )
	if value == 0 then return "0"; end
	return Locale.ToNumber(math.floor((value*10)+0.5)/10, "+#,###.#;-#,###.#");
end

function toPlusMinusNoneString( value:number )
	if value == 0 then return " "; end
	return Locale.ToNumber(math.floor((value*10)+0.5)/10, "+#,###.#;-#,###.#");
end


-- ===========================================================================
--	Single exit point for display
-- ===========================================================================
function Close()
	if not ContextPtr:IsHidden() then
		UI.PlaySound("UI_Screen_Close");
	end

	UIManager:DequeuePopup(ContextPtr);
	LuaEvents.ReportScreen_Closed();
	--print("Closing... current tab is:", m_kCurrentTab);
	tUnitSort.parent = nil; -- unit upgrades off the report screen should not call re-sort
end


-- ===========================================================================
--	UI Callback
-- ===========================================================================
function OnCloseButton()
	Close();
end

-- ===========================================================================
--	Single entry point for display
-- ===========================================================================
function Open( tabToOpen:number )
	--print("FUN Open()", tabToOpen);
	UIManager:QueuePopup( ContextPtr, PopupPriority.Medium );
	Controls.ScreenAnimIn:SetToBeginning();
	Controls.ScreenAnimIn:Play();
	UI.PlaySound("UI_Screen_Open");
	LuaEvents.EMRScreen_Opened();

	-- To remember the last opened tab when the report is re-opened: ARISTOS
	if tabToOpen ~= nil then m_kCurrentTab = tabToOpen; end
	m_tabs.SelectTab( m_kCurrentTab );
end


-- ===========================================================================
--	UI Callback
--	Collapse all the things!
-- ===========================================================================
function OnCollapseAllButton()
	if m_uiGroups == nil or table.count(m_uiGroups) == 0 then
		return;
	end

	for i,instance in ipairs( m_uiGroups ) do
		if instance["isCollapsed"] ~= m_isCollapsing then
			instance["isCollapsed"] = m_isCollapsing;
			instance.CollapseAnim:Reverse();
			RealizeGroup( instance );
		end
	end
	Controls.CollapseAll:LocalizeAndSetText(m_isCollapsing and "LOC_HUD_REPORTS_EXPAND_ALL" or "LOC_HUD_REPORTS_COLLAPSE_ALL");
	m_isCollapsing = not m_isCollapsing;
end

-- ===========================================================================
--	Set a group to it's proper collapse/open state
--	Set + - in group row
-- ===========================================================================
function RealizeGroup( instance:table )
	local v :number = (instance["isCollapsed"]==false and instance.RowExpandCheck:GetSizeY() or 0);
	instance.RowExpandCheck:SetTextureOffsetVal(0, v);

	instance.ContentStack:CalculateSize();	
	instance.CollapseScroll:CalculateSize();
	
	local groupHeight	:number = instance.ContentStack:GetSizeY();
	instance.CollapseAnim:SetBeginVal(0, -(groupHeight - instance["CollapsePadding"]));
	instance.CollapseScroll:SetSizeY( groupHeight );				

	instance.Top:ReprocessAnchoring();
end

-- ===========================================================================
--	Callback
--	Expand or contract a group based on its existing state.
-- ===========================================================================
function OnToggleCollapseGroup( instance:table )
	instance["isCollapsed"] = not instance["isCollapsed"];
	instance.CollapseAnim:Reverse();
	RealizeGroup( instance );
end

-- ===========================================================================
--	Toggle a group expanding / collapsing
--	instance,	A group instance.
-- ===========================================================================
function OnAnimGroupCollapse( instance:table)
		-- Helper
	function lerp(y1:number,y2:number,x:number)
		return y1 + (y2-y1)*x;
	end
	local groupHeight	:number = instance.ContentStack:GetSizeY();
	local collapseHeight:number = instance["CollapsePadding"]~=nil and instance["CollapsePadding"] or 0;
	local startY		:number = instance["isCollapsed"]==true  and groupHeight or collapseHeight;
	local endY			:number = instance["isCollapsed"]==false and groupHeight or collapseHeight;
	local progress		:number = instance.CollapseAnim:GetProgress();
	local sizeY			:number = lerp(startY,endY,progress);
		
	instance.CollapseAnim:SetSizeY( groupHeight );		-- BRS added, INFIXO CHECK
	instance.CollapseScroll:SetSizeY( sizeY );	
	instance.ContentStack:ReprocessAnchoring();	
	instance.Top:ReprocessAnchoring()

	Controls.Stack:CalculateSize();
	Controls.Scroll:CalculateSize();			
end


-- ===========================================================================
function SetGroupCollapsePadding( instance:table, amount:number )
	instance["CollapsePadding"] = amount;
end


-- ===========================================================================
function ResetTabForNewPageContent()
	m_uiGroups = {};
	m_simpleIM:ResetInstances();
	m_groupIM:ResetInstances();
	m_isCollapsing = true;
	Controls.CollapseAll:LocalizeAndSetText("LOC_HUD_REPORTS_COLLAPSE_ALL");
	Controls.Scroll:SetScrollValue( 0 );	
end


-- ===========================================================================
--	Instantiate a new collapsable row (group) holder & wire it up.
--	ARGS:	(optional) isCollapsed
--	RETURNS: New group instance
-- ===========================================================================
function NewCollapsibleGroupInstance( isCollapsed:boolean )
	if isCollapsed == nil then
		isCollapsed = false;
	end
	local instance:table = m_groupIM:GetInstance();	
	instance.ContentStack:DestroyAllChildren();
	instance["isCollapsed"]		= isCollapsed;
	instance["CollapsePadding"] = nil;				-- reset any prior collapse padding

	--BRS !! added
	instance["Children"] = {}
	instance["Descend"] = false
	-- !!

	instance.CollapseAnim:SetToBeginning();
	if isCollapsed == false then
		instance.CollapseAnim:SetToEnd();
	end	

	instance.RowHeaderButton:RegisterCallback( Mouse.eLClick, function() OnToggleCollapseGroup(instance); end );			
  	instance.RowHeaderButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);

	instance.CollapseAnim:RegisterAnimCallback(               function() OnAnimGroupCollapse( instance ); end );

	table.insert( m_uiGroups, instance );

	return instance;
end


-- ===========================================================================
--	debug - Create a test page.
-- ===========================================================================
function ViewTestPage()

	ResetTabForNewPageContent();

	local instance:table = NewCollapsibleGroupInstance();	
	instance.RowHeaderButton:SetText( "Test City Icon 1" );

	-- RealizeGroup( instance );
	Controls.Scroll:SetSizeY( Controls.Main:GetSizeY() - SIZE_HEIGHT_PADDING_BOTTOM_ADJUST );
end

-- ===========================================================================
--	Pages
-- ===========================================================================
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
	Controls.Scroll:SetSizeY(Controls.Main:GetSizeY() - 88);
    
    m_kCurrentTab = 1
end

function ViewDiplomacyPage()
    ResetTabForNewPageContent();

	local instance:table = m_simpleIM:GetInstance();
	instance.Top:DestroyAllChildren();
	
	instance.Children = {}
	instance.Descend = true
    
    emr_instance = EMR.Diplomacy.GetInstance();
    emr_instance.DiplomacyContainer:ChangeParent(instance.Top);
    EMR.Diplomacy.UpdateContent();
    
    Controls.Stack:CalculateSize();
	Controls.Scroll:CalculateSize();

	Controls.CollapseAll:SetHide( true );
	Controls.Scroll:SetSizeY( Controls.Main:GetSizeY() - 88);
    
    m_kCurrentTab = 2
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
	Controls.Scroll:SetSizeY( Controls.Main:GetSizeY() - 88);
    
    m_kCurrentTab = 3
end


-- ===========================================================================
-- Helper Functions
-- ===========================================================================

-- helper to get Category out of Civ Type; categories are: CULTURAL, INDUSTRIAL, MILITARISTIC, etc.
function GetCityStateCategory(sCivType:string)
	for row in GameInfo.TypeProperties() do
		if row.Type == sCivType and row.Name == "CityStateCategory" then return row.Value; end
	end
	print("ERROR: GetCityStateCategory() no City State category for", sCivType);
	return "UNKNOWN";
end

-- helper to get a Leader for a Minor; assumes only 1 leader per Minor
function GetCityStateLeader(sCivType:string)
	for row in GameInfo.CivilizationLeaders() do
		if row.CivilizationType == sCivType then return row.LeaderType; end
	end
	print("ERROR: GetCityStateLeader() no City State leader for", sCivType);
	return "UNKNOWN";
end

-- helper to get a Trait for a Minor Leader; assumes only 1 trait per Minor Leader
function GetCityStateTrait(sLeaderType:string)
	for row in GameInfo.LeaderTraits() do
		if row.LeaderType == sLeaderType then return row.TraitType; end
	end
	print("ERROR: GetCityStateTrait() no Trait for", sLeaderType);
	return "UNKNOWN";
end


-- ===========================================================================
-- Tabs
-- ===========================================================================
function AddTabSection( name:string, populateCallback:ifunction )
	local kTab		:table				= m_tabIM:GetInstance();	
	kTab.Button[DATA_FIELD_SELECTION]	= kTab.Selection;

	local callback	:ifunction	= function()
		if m_tabs.prevSelectedControl ~= nil then
			m_tabs.prevSelectedControl[DATA_FIELD_SELECTION]:SetHide(true);
		end
		kTab.Selection:SetHide(false);
		Timer1Start();
		populateCallback();
		Timer1Tick("Section "..Locale.Lookup(name).." populated");
	end

	kTab.Button:GetTextControl():SetText( Locale.Lookup(name) );
	kTab.Button:SetSizeToText( 0, 20 ); -- default 40,20
    kTab.Button:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);

	m_tabs.AddTab( kTab.Button, callback );
end

-- ===========================================================================
--	UI Callback
-- ===========================================================================
function OnInputHandler( pInputStruct:table )
	local uiMsg :number = pInputStruct:GetMessageType();
	if uiMsg == KeyEvents.KeyUp then 
		local uiKey = pInputStruct:GetKey();
		if uiKey == Keys.VK_ESCAPE then
			if ContextPtr:IsHidden()==false then
				Close();
				return true;
			end
		end		
	end
	return false;
end

function OnInputActionTriggered( actionId )
	if actionId == Input.GetActionId("ToggleEMR") then
		print(".....Detected F9.....")
		if ContextPtr:IsHidden() then Open(); else Close(); end
	end
end

-- ===========================================================================
function Resize()
	local topPanelSizeY:number = 30;

	x,y = UIManager:GetScreenSizeVal();
	Controls.Main:SetSizeY( y - topPanelSizeY );
	Controls.Main:SetOffsetY( topPanelSizeY * 0.5 );
end

-- ===========================================================================
--	Game Event Callback
-- ===========================================================================
function OnLocalPlayerTurnEnd()
	if(GameConfiguration.IsHotseat()) then
		Close();
	end
end

-- ===========================================================================
function LateInitialize()
	Resize();

	
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
			m_tabs = CreateTabs( Controls.TabContainer, 42, 34, 0xFF331D05 );
   			 AddTabSection("LOC_EMR_DEMOGRAPHICS", ViewDemographicsPage);
    			AddTabSection("LOC_EMR_DIPLOMACY", ViewDiplomacyPage);
    			AddTabSection("LOC_EMR_GRAPHS", ViewGraphsPage);
      
    			LuaEvents.ReportsList_OpenDemographics.Add(function() Open(1); end );
    			LuaEvents.ReportsList_OpenDiplomacy.Add(function() Open(2); end );
    			LuaEvents.ReportsList_OpenGraphs.Add(function() Open(3); end );

			m_tabs.SameSizedTabs(40);
			m_tabs.CenterAlignTabs(-10);
		end
	end

end

-- ===========================================================================
--	UI Event
-- ===========================================================================
function OnInit( isReload:boolean )
	LateInitialize();
	if isReload then		
		if ContextPtr:IsHidden() == false then
			Open();
		end
	end
	m_tabs.AddAnimDeco(Controls.TabAnim, Controls.TabArrow);	
end

-- ===========================================================================
function Initialize()
	-- UI Callbacks
	ContextPtr:SetInitHandler( OnInit );
	ContextPtr:SetInputHandler( OnInputHandler, true );

	Controls.CloseButton:RegisterCallback( Mouse.eLClick, OnCloseButton );
	Controls.CloseButton:RegisterCallback(	Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.CollapseAll:RegisterCallback( Mouse.eLClick, OnCollapseAllButton );
	Controls.CollapseAll:RegisterCallback(	Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	
	Events.LocalPlayerTurnEnd.Add( OnLocalPlayerTurnEnd );
	Events.InputActionTriggered.Add( OnInputActionTriggered );
end
Initialize();

