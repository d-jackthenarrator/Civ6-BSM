-- Copyright 2018, Firaxis Games
include("GovernmentScreen_Expansion2");
print("GovernmentScreen for BSM")

-- ===========================================================================
--	OVERRIDE
--	RETURNS: true if policy is available to the player at this time.
-- ===========================================================================

XP1_PopulateLivePlayerData = PopulateLivePlayerData;
BASE_Initialize = Initialize
-- ===========================================================================
--	DEBUG
--	Toggle these for temporary debugging help.
-- ===========================================================================
local m_debugShowAllPolicies	:boolean = false;		-- (false) When true all policy cards (despite player's progression) will be shown in the catalog
local m_debugShowPolicyIDs		:boolean = false;		-- (false) Show the rowids on policy cards
local m_debugOutputGovInfo		:boolean = false;		-- (false) Output to console information about governments

-- ===========================================================================
--	CONSTANTS	/ DEFINES
-- ===========================================================================

-- Toggle these based on the game engine rules.
local m_isAllowAnythingInWildcardSlot	:boolean = true;	-- Currently engine doesn't allow because on confirmation Culture::CanSlotPolicy() first checks !IsPolicyActive( ePolicy ), which fails.
local m_isAllowWildcardsAnywhere		:boolean = false;	-- ...
local m_isLocalPlayerTurn				:boolean = true;

local COLOR_GOVT_UNSELECTED			:number = UI.GetColorValueFromHexLiteral(0xffe9dfc7); -- Background for unselected background (or forground text color on non-selected).
local COLOR_GOVT_SELECTED			:number = UI.GetColorValueFromHexLiteral(0xff261407); -- Background for selected background (or forground text color on non-selected).
local COLOR_GOVT_LOCKED				:number = UI.GetColorValueFromHexLiteral(0xffAAAAAA);
local DATA_FIELD_CURRENT_FILTER		:string = "_CURRENT_FILTER";
local DATA_FIELD_TOTAL_SLOTS		:string = "_TOTAL_SLOTS";			-- Total slots for a government item in the "tree-like" view


local ROW_INDEX :table = {
	MILITARY = 1,
	ECONOMIC = 2,
	DIPLOMAT = 3, -- yes this is to make the names line up. also required for matching with gamecore.
	WILDCARD = 4
};
local ROW_SLOT_TYPES :table = {};
	ROW_SLOT_TYPES[ROW_INDEX.MILITARY]	= "SLOT_MILITARY";
	ROW_SLOT_TYPES[ROW_INDEX.ECONOMIC]	= "SLOT_ECONOMIC";
	ROW_SLOT_TYPES[ROW_INDEX.DIPLOMAT]	= "SLOT_DIPLOMATIC";
	ROW_SLOT_TYPES[ROW_INDEX.WILDCARD]	= "SLOT_WILDCARD";
local SLOT_ORDER_IN_CATALOG :table = {
	SLOT_MILITARY		= 1,
	SLOT_ECONOMIC		= 2,
	SLOT_DIPLOMATIC		= 3,
	SLOT_GREAT_PERSON	= 4,
	SLOT_WILDCARD		= 5,
};

local EMPTY_POLICY_TYPE				:string = "empty";					-- For a policy slot without a type
local KEY_POLICY_TYPE				:string = "PolicyType";				-- Key on a catalog UI element that holds the PolicyType; so corresponding data can be found
local KEY_POLICY_SLOT				:string = "PolicySlot";
local KEY_DRAG_TARGET_CONTROL		:string = "DragTargetControl";		-- What control should we be testing against as a drag target?
local KEY_LIFTABLE_CONTROL			:string = "LiftableControl";		-- What control is safe to move without futzing up the dragtarget evaluations?
local KEY_ROW_ID					:string = "RowNum";					-- Key on a row UI element to note which row it came from.
local PADDING_POLICY_ROW_ITEM		:number = 3;
local PADDING_POLICY_LIST_HEADER	:number = 50;
local PADDING_POLICY_LIST_BOTTOM	:number = 20;
local PADDING_POLICY_LIST_ITEM		:number = 20;
local PADDING_POLICY_SCROLL_AREA	:number = 10;
local PIC_CARD_SUFFIX_SMALL			:string = "_Small";
local PIC_CARD_TYPE_DIPLOMACY		:string = "Governments_DiplomacyCard";
local PIC_CARD_TYPE_ECONOMIC		:string = "Governments_EconomicCard";
local PIC_CARD_TYPE_MILITARY		:string = "Governments_MilitaryCard";
local PIC_CARD_TYPE_WILDCARD		:string = "Governments_WildcardCard";
local PIC_PERCENT_BRIGHT			:string = "Governments_PercentWhite";
local PIC_PERCENT_DARK				:string = "Governments_PercentBlue";
local PICS_SLOT_TYPE_CARD_BGS		:table  = {
	SLOT_MILITARY		= PIC_CARD_TYPE_MILITARY,
	SLOT_ECONOMIC		= PIC_CARD_TYPE_ECONOMIC,
	SLOT_DIPLOMATIC		= PIC_CARD_TYPE_DIPLOMACY,
	SLOT_WILDCARD		= PIC_CARD_TYPE_WILDCARD,
	SLOT_GREAT_PERSON	= PIC_CARD_TYPE_WILDCARD, -- Great person is also utilized as a wild card.
};

local IMG_POLICYCARD_BY_ROWIDX :table = {};
	IMG_POLICYCARD_BY_ROWIDX[ROW_INDEX.MILITARY] = PIC_CARD_TYPE_MILITARY;
	IMG_POLICYCARD_BY_ROWIDX[ROW_INDEX.ECONOMIC] = PIC_CARD_TYPE_ECONOMIC;
	IMG_POLICYCARD_BY_ROWIDX[ROW_INDEX.DIPLOMAT] = PIC_CARD_TYPE_DIPLOMACY;
	IMG_POLICYCARD_BY_ROWIDX[ROW_INDEX.WILDCARD] = PIC_CARD_TYPE_WILDCARD;
local SCREEN_ENUMS :table = {
		MY_GOVERNMENT	= 1,
		GOVERNMENTS		= 2,
		POLICIES		= 3
}
local SIZE_TAB_BUTTON_TEXT_PADDING			:number = 50;
local SIZE_HERITAGE_BONUS					:number = 48;
local SIZE_GOV_ITEM_WIDTH					:number = 400;
local SIZE_GOV_ITEM_HEIGHT					:number = 152;	-- 238 minus shadow
local SIZE_GOV_DIVIDER_WIDTH				:number = 75;
local SIZE_POLICY_ROW_MIN					:number = 675;
local SIZE_POLICY_ROW_MAX					:number = 1120; -- Evaluated size when in 1080p. Fits 6 cards nicely.
local SIZE_POLICY_CATALOG_MIN				:number = 512+15; -- Half minspec screen + some extra
local SIZE_POLICY_CATALOG_MAX				:number = 1400; -- Selected by me making up a number because unbounded looks goofy in 4k
local SIZE_POLICY_CARD_X					:number = 140;
local SIZE_POLICY_CARD_Y					:number = 150;
local SIZE_MIN_SPEC_X						:number = 1024;
local TXT_GOV_ASSIGN_POLICIES				:string = Locale.Lookup("LOC_GOVT_ASSIGN_ALL_POLICIES");
local TXT_GOV_CONFIRM_POLICIES				:string = Locale.Lookup("LOC_GOVT_CONFIRM_POLICIES");
local TXT_GOV_CONFIRM_GOVERNMENT			:string = Locale.Lookup("LOC_GOVT_CONFIRM_GOVERNMENT");
local TXT_GOV_POPUP_NO						:string = Locale.Lookup("LOC_GOVT_PROMPT_NO");
local TXT_GOV_POPUP_PROMPT_POLICIES_CLOSE	:string = Locale.Lookup("LOC_GOVT_POPUP_PROMPT_POLICIES_CLOSE");
local TXT_GOV_POPUP_PROMPT_POLICIES_CONFIRM	:string = Locale.Lookup("LOC_GOVT_POPUP_PROMPT_POLICIES_CONFIRM");
local TXT_GOV_POPUP_YES						:string = Locale.Lookup("LOC_GOVT_PROMPT_YES");
local MAX_HEIGHT_POLICIES_LIST				:number = 600;
local MAX_HEIGHT_GOVT_DESC					:number = 25;
local MAX_BEFORE_TRUNC_BONUS_TEXT			:number = 219;
local MAX_BEFORE_TRUNC_HERITAGE_BONUS		:number = 225;

-- ===========================================================================
--	GLOBALS
-- ===========================================================================
g_kGovernments = {};
g_kCurrentGovernment = nil;
g_isMyGovtTabDirty = false;
g_isGovtTabDirty = false;
g_isPoliciesTabDirty = false;
m_kUnlockedPolicies = nil;
m_kNewPoliciesThisTurn = nil;

-- ===========================================================================
--	VARIABLES
-- ===========================================================================

local m_TopPanelConsideredHeight:number = 0;
local m_policyCardIM			:table = InstanceManager:new("PolicyCard",					"Content",	Controls.PolicyCatalog);
local m_kGovernmentLabelIM		:table = InstanceManager:new("GovernmentEraLabelInstance",	"Top", 		Controls.GovernmentDividers );
local m_kGovernmentItemIM		:table = InstanceManager:new("GovernmentItemInstance",		"Top", 		Controls.GovernmentScroller );
local m_kPolicyTabButtonIM		:table = InstanceManager:new("PolicyTabButtonInstance",		"Button", 	Controls.FilterStack );

local m_ePlayer					:number	= -1;
local m_kAllPlayerData			:table  = {};		-- Holds copy of player data for all local players
local m_kBonuses				:table	= {}
local m_governmentChangeType	:string = "";		-- The government type proposed being changed to.
local m_isPoliciesChanged		:boolean= false;
local m_kPolicyCatalogData		:table	= {};
local m_kPolicyCatalogOrder		:table  = {};		-- Track order of policies to display
local m_kPolicyFilters			:table	= {};
local m_kPolicyFilterCurrent	:table	= nil;
local m_kUnlockedGovernments	:table  = {};
local m_tabs					:table;
local m_uiGovernments			:table  = {};
local m_width					:number	= SIZE_MIN_SPEC_X;	-- Screen Width (default / min spec)
local m_currentCivicType		:string	= nil;
local m_civicProgress			:number = 0;
local m_civicCost				:number	= 0;
local m_bShowMyGovtInPolicies   :boolean = false;

-- Used to lerp PolicyRows and PolicyContainer when sliding between MyGovt and Policy tabs
local m_AnimRowSize :table = {
	mygovt = 0,
	policy = 0,
}
local m_AnimCatalogSize :table = {
	mygovt = 0,
	policy = 0,
}
local m_AnimCatalogOffset :table = {
	mygovt = 0,
	policy = 0,
}
local m_AnimMyGovtOffset :table = {
	mygovt = 0,
	policy = 0,
}

-- An array of arrays of tables. Contains one entry for each member of ROW_INDEX.
-- m_ActivePolicyRows[ROW_INDEX.MILITARY] is an array of all the slots for the Military row.
-- Each slot is a "SlotData" table containing UI_RowIndex, GC_SlotIndex, and GC_PolicyType.
-- UI_RowIndex is a value from ROW_INDEX matching the row this slot is in. This should not change.
-- GC_SlotIndex is the corresponding GameCore slot index for this slot. This should not change.
-- GC_PolicyType is the string type of the policy card currently in the slot. It is EMPTY_POLICY_TYPE by default.
local m_ActivePolicyRows		:table = {};
local m_ActivePoliciesByType	:table = {}; -- PolicyType string -> SlotData table
local m_ActivePoliciesBySlot	:table = {}; -- (GC Slot Index + 1) -> SlotData table

local m_ActiveCardInstanceArray	:table = {}; -- (GC Slot Index + 1) -> Card/EmptyCard Instance

-- We only track slots so as to not keep instance tables hanging around when they shouldn't.
-- Which slot is currently targetted by a drag & drop?
local m_PrevDropTargetSlot		:number = -1;
-- Which slot is currently hovered? (Stack because multiple things may be moused over, but only one should be on top)
local m_MouseoverStack :table = {};

function PopulateLivePlayerData( ePlayer:number )	
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
			if ( GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID) ~= nil and GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID) ~= 1000) then
				ePlayer = GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID)
			end
		end

	
	if ePlayer == -1 then
		return;
	end

	XP1_PopulateLivePlayerData(ePlayer);

end

function OnLocalPlayerTurnBegin()
	m_isLocalPlayerTurn = true;
	local ePlayer:number = Game.GetLocalPlayer();
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
			if ( GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID) ~= nil and GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID) ~= 1000) then
				ePlayer = GameConfiguration.GetValue("OBSERVER_ID_"..spec_ID)
			end
		end

	if ePlayer ~= m_ePlayer and m_ePlayer ~= -1 then
		SaveLivePlayerData( m_ePlayer );
	end

	m_ePlayer = ePlayer;
	if m_ePlayer ~= -1 then
		RefreshAllData();
	end
end

function Initialize()
	BASE_Initialize();
end

Initialize()

LuaEvents.DiplomacyRibbon_Click.Add( OnLocalPlayerTurnBegin );

