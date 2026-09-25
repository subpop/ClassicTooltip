-- ClassicTooltip 2.2.0 by Link Dupont
--
-- Reverts unit tooltips to the circa-1.0 style:
--   * Backdrop coloring instead of coloring the unit's name
--   * Compact lines: players get name / race class / level,
--     NPCs get name / description / level with the classic "+" for elites.
--   * No PvP text, no city association.
--
-- Modernized for Cataclysm Classic and Mists of Pandaria Classic:
-- no global function overrides, no XML frame. Formatting is applied via
-- secure post-hooks and configured through the game's Settings panel.

local ADDON_NAME = ...;

-- ---------------------------------------------------------------------------
-- Saved variables / settings state
-- ---------------------------------------------------------------------------

ClassicTooltipSettings = ClassicTooltipSettings or {};

local function CT_GetSettings()
	if (ClassicTooltipSettings["Enabled"] == nil) then
		ClassicTooltipSettings["Enabled"] = true;
	end
	if (ClassicTooltipSettings["ShowGuild"] == nil) then
		ClassicTooltipSettings["ShowGuild"] = false;
	end
	return ClassicTooltipSettings;
end

local function CT_GetVersion()
	if (C_AddOns and C_AddOns.GetAddOnMetadata) then
		return C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version");
	elseif (GetAddOnMetadata) then
		return GetAddOnMetadata(ADDON_NAME, "Version");
	end
	return "2.2.0";
end

-- The 2.x-era reaction palette, hardcoded. The modern client's
-- FACTION_BAR_COLORS are brighter/pastel (that neon green came from there),
-- so we keep our own copy of the circa-2007 values, including the add-on's
-- signature deep-red hostile override. Everything stays local so nothing
-- leaks into the rest of the UI (the 2.x versions mutated the global).
local CT_CLASSIC_COLORS = {
	[1] = { r = 1.0, g = 0.0, b = 0.0 }, -- hated
	[2] = { r = 0.8, g = 0.0, b = 0.0 }, -- hostile (the classic deep red)
	[3] = { r = 1.0, g = 0.5, b = 0.0 }, -- unfriendly
	[4] = { r = 1.0, g = 1.0, b = 0.0 }, -- neutral
	[5] = { r = 0.0, g = 1.0, b = 0.0 }, -- friendly
	[6] = { r = 0.0, g = 1.0, b = 0.0 }, -- honored
	[7] = { r = 0.0, g = 0.0, b = 1.0 }, -- revered
	[8] = { r = 0.0, g = 0.0, b = 1.0 }, -- exalted
};

local CT_FALLBACK_BLUE = { r = 0.0, g = 0.0, b = 1.0 };

local function CT_FactionColor(index)
	local c = CT_CLASSIC_COLORS[index];
	if (c) then
		return c.r, c.g, c.b;
	end
	return CT_FALLBACK_BLUE.r, CT_FALLBACK_BLUE.g, CT_FALLBACK_BLUE.b;
end

-- Classic backdrop color for a unit. Same rules as the 2.x CT_UnitColor,
-- but returned for our own use instead of overriding GameTooltip_UnitColor.
local function CT_UnitColor(unit)
	local r, g, b;
	if (UnitPlayerControlled(unit)) then
		if (UnitCanAttack(unit, "player")) then
			-- Hostile players are red
			if (not UnitCanAttack("player", unit)) then
				r = CT_FALLBACK_BLUE.r;
				g = CT_FALLBACK_BLUE.g;
				b = CT_FALLBACK_BLUE.b;
			else
				r, g, b = CT_FactionColor(2);
			end
		elseif (UnitCanAttack("player", unit)) then
			-- Players we can attack but which are not hostile are yellow
			r, g, b = CT_FactionColor(4);
		elseif (UnitIsPVP(unit)) then
			-- Players we can assist but are PvP flagged are green
			r, g, b = CT_FactionColor(6);
		else
			-- All other players are blue (the usual state on the "blue" server)
			r, g, b = CT_FALLBACK_BLUE.r, CT_FALLBACK_BLUE.g, CT_FALLBACK_BLUE.b;
		end
	else
		local reaction = UnitReaction(unit, "player");
		if (reaction) then
			r, g, b = CT_FactionColor(reaction);
		else
			r, g, b = CT_FALLBACK_BLUE.r, CT_FALLBACK_BLUE.g, CT_FALLBACK_BLUE.b;
		end
	end
	return r, g, b;
end

-- ---------------------------------------------------------------------------
-- Tooltip helpers (all guarded: modern clients rename/remove tooltip parts)
-- ---------------------------------------------------------------------------

local function CT_LeftLine(tooltip, i)
	if (not tooltip or not tooltip.GetName) then
		return nil;
	end
	local line = _G[tooltip:GetName() .. "TextLeft" .. i];
	if (not line) then
		return nil;
	end
	return line;
end

local function CT_LeftLineText(tooltip, i)
	local line = CT_LeftLine(tooltip, i);
	if (line and line.GetText) then
		return line:GetText();
	end
	return nil;
end

-- Classic backdrop tint: solid fills in a muted middle palette. The 2.x
-- rendering path (tint multiplied over the texture) assumed the light 2007
-- backdrop, but the modern atlas is much darker, so faithful tints render
-- near-black. Fills replace the dark texture entirely and read clearly,
-- while the palette below keeps the 2007 hues restrained (no neon).
-- Applied on every unit tooltip (handler, OnShow, deferred), and the
-- default UI restores the atlas on hide, so nothing leaks.
-- Forward declaration: defined further below, used by the tint path.
local CT_ResolveUnit;

-- Middle-muted solids: 2007 hues at clearly readable brightness.
-- e.g. hostile red (0.8,0,0) -> brick red, neutral (1,1,0) -> olive
-- mustard, friendly green (0,1,0) -> forest green, blue (0,0,1) -> steel.
local function CT_MuteColor(r, g, b)
	return r * 0.42, g * 0.42, b * 0.55;
end

local function CT_ApplyFill(tooltip, r, g, b)
	local center = tooltip.NineSlice and tooltip.NineSlice.Center;
	if (center and center.SetColorTexture) then
		local mr, mg, mb = CT_MuteColor(r, g, b);
		center:SetColorTexture(mr, mg, mb, 1);
		if (center.SetVertexColor) then
			center:SetVertexColor(1, 1, 1, 1);
		end
		return true;
	end
	return false;
end

local function CT_SetBackdrop(tooltip, r, g, b)
	-- Fill first (deterministic middle-muted solid on every client),
	-- legacy backdrop color next, vertex tint as the last resort.
	if (CT_ApplyFill(tooltip, r, g, b)) then
		return;
	end
	if (tooltip.SetBackdropColor) then
		local mr, mg, mb = CT_MuteColor(r, g, b);
		tooltip:SetBackdropColor(mr, mg, mb);
		return;
	end
	local nineSlice = tooltip.NineSlice;
	if (nineSlice and nineSlice.SetCenterColor) then
		nineSlice:SetCenterColor(r, g, b, 1);
	end
end

local function CT_SetStatusBar(tooltip, show)
	local bar = _G[tooltip:GetName() .. "StatusBar"];
	if (not bar and tooltip == GameTooltip) then
		bar = _G["GameTooltipStatusBar"];
	end
	if (bar) then
		if (show) then
			bar:Show();
		else
			bar:Hide();
		end
	end
end

-- Snapshot the bits of the default tooltip we want to carry over before we
-- rebuild it: the NPC description line and any "Skinnable" line + its color.
local function CT_Snapshot(tooltip, unit)
	local snapshot = { description = nil, skinnable = nil, r = nil, g = nil, b = nil };
	if (UnitIsPlayer(unit)) then
		return snapshot;
	end
	local second = CT_LeftLineText(tooltip, 2);
	if (second and not second:match("^Level")) then
		snapshot.description = second;
	end
	local i = 1;
	while (i <= 30) do
		local line = CT_LeftLine(tooltip, i);
		if (not line) then
			break;
		end
		local text = line.GetText and line:GetText();
		if (text and text:find("Skinnable", 1, true)) then
			-- No break: the 2.x loop kept overwriting, so the last
			-- matching line's color wins.
			snapshot.skinnable = true;
			if (line.GetTextColor) then
				snapshot.r, snapshot.g, snapshot.b = line:GetTextColor();
			end
		end
		i = i + 1;
	end
	return snapshot;
end

local function CT_LevelText(unit)
	local level = UnitLevel(unit);
	if (level == nil or level < 0) then
		return "??";
	end
	return tostring(level);
end

local function CT_CreatureType(unit)
	local creatureType = UnitCreatureType(unit);
	if (creatureType == nil or creatureType == "" or creatureType == "Not specified") then
		creatureType = UnitCreatureFamily(unit);
	end
	return creatureType or "";
end

-- This is where the magic happens. Rebuilds a populated unit tooltip in the
-- classic layout. Assumes the caller already resolved a valid unit.
local function CT_RebuildTooltip(tooltip, unit, snapshot)
	tooltip:ClearLines();

	local name = UnitName(unit) or UNKNOWN or "Unknown";
	local level = CT_LevelText(unit);

	-- Explicit white: tooltip lines recycle FontStrings, so without a color
	-- the name would keep Blizzard's reaction coloring.
	tooltip:AddLine(name, 1, 1, 1);

	if (UnitIsPlayer(unit)) then
		-- First returns are the display names ("Worgen Druid"), matching the
		-- 2.x code. (The second returns are file names like "DRUID".)
		local race = UnitRace(unit) or "";
		local classDisplay = UnitClass(unit) or "";
		tooltip:AddLine((race .. " " .. classDisplay):gsub("^%s+", ""), 1, 1, 1);
		local settings = CT_GetSettings();
		if (settings["ShowGuild"]) then
			local guildName = GetGuildInfo(unit);
			if (guildName) then
				tooltip:AddLine("<" .. guildName .. ">");
			end
		end
		tooltip:AddLine("Level " .. level, 1, 1, 1);
	else
		if (snapshot.description) then
			tooltip:AddLine(snapshot.description, 1, 1, 1);
		end

		local classification = UnitClassification(unit);
		if (UnitLevel(unit) and UnitLevel(unit) > 0) then
			-- Add the elite +
			if (classification == "elite" or classification == "rareelite") then
				level = level .. "+";
			end
		else
			if (classification == "worldboss") then
				level = "??+";
			else
				level = "??";
			end
		end

		if (UnitIsDead(unit)) then
			tooltip:AddLine("Level " .. level .. " Corpse", 1, 1, 1);
			-- The 2.x code printed the literal word with the skinnable
			-- line's color, so we do the same.
			if (snapshot.skinnable) then
				if (snapshot.r and snapshot.g and snapshot.b) then
					tooltip:AddLine("Skinnable", snapshot.r, snapshot.g, snapshot.b);
				else
					tooltip:AddLine("Skinnable");
				end
			end
		else
			local reaction = UnitReaction(unit, "player");
			if (reaction and reaction < 5) then
				tooltip:AddLine("Level " .. level .. " " .. CT_CreatureType(unit), 1, 1, 1);
			else
				tooltip:AddLine("Level " .. level, 1, 1, 1);
			end
		end
	end

	CT_SetStatusBar(tooltip, true);
	CT_SetBackdrop(tooltip, CT_UnitColor(unit));
	tooltip:Show();
end

-- Re-apply only the backdrop tint. Rebuilding lines here is unnecessary;
-- the OnTooltipSetUnit handler already did that. This runs on OnShow, the
-- last moment before the tooltip is visible, so a client-side backdrop
-- style pass can no longer wipe our color.
local function CT_TintBackdrop(tooltip, hint)
	if (not tooltip or tooltip ~= GameTooltip) then
		return;
	end
	if (not CT_GetSettings()["Enabled"]) then
		return;
	end
	local unit = CT_ResolveUnit(tooltip, hint);
	if (not unit) then
		return;
	end
	CT_SetBackdrop(tooltip, CT_UnitColor(unit));
end

-- Deferred re-tint: runs after the current frame's synchronous work,
-- including any client-side backdrop style pass that runs after our
-- handlers, so our color is applied last. One-shot, no repeating timer.
local function CT_ScheduleTint()
	if (C_Timer and C_Timer.After) then
		C_Timer.After(0, function()
			CT_TintBackdrop(GameTooltip, nil);
		end);
	end
end

CT_ResolveUnit = function(tooltip, hint)
	if (hint and UnitExists(hint)) then
		return hint;
	end
	if (tooltip and tooltip.GetUnit) then
		local a, b = tooltip:GetUnit();
		if (b and UnitExists(b)) then
			return b;
		end
		if (a and UnitExists(a)) then
			return a;
		end
	end
	return nil;
end

-- Entry point for all hooks. Formatting only applies to real unit tooltips,
-- so items, spells, currencies, etc. pass through untouched.
local CT_Applying = false;

local function CT_ApplyClassic(tooltip, hint)
	if (CT_Applying) then
		return;
	end
	if (not tooltip or tooltip ~= GameTooltip) then
		return;
	end
	if (not CT_GetSettings()["Enabled"]) then
		return;
	end
	local unit = CT_ResolveUnit(tooltip, hint);
	if (not unit) then
		return;
	end

	local snapshot = CT_Snapshot(tooltip, unit);
	CT_Applying = true;
	local ok, err = pcall(CT_RebuildTooltip, tooltip, unit, snapshot);
	CT_Applying = false;
	if (not ok and err) then
		geterrorhandler()(err);
	else
		CT_ScheduleTint();
	end
end

-- ---------------------------------------------------------------------------
-- Hook installation. All three paths funnel into CT_ApplyClassic, which is
-- idempotent (re-running it on our own output rebuilds the same lines), so
-- installing every available path is safe and maximizes client coverage:
-- TooltipDataProcessor is the modern pipeline, while SetUnit and
-- OnTooltipSetUnit cover clients where the processor never fires.
-- ---------------------------------------------------------------------------

local CT_Hooks = { processor = false, setUnit = false, onSetUnit = false };

local function CT_InstallHooks()
	if (TooltipDataProcessor
		and TooltipDataProcessor.AddTooltipPostCall
		and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit) then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
			CT_ApplyClassic(tooltip, nil);
		end);
		CT_Hooks.processor = true;
	end

	if (GameTooltip and type(GameTooltip.SetUnit) == "function") then
		hooksecurefunc(GameTooltip, "SetUnit", function(tooltip, unit)
			CT_ApplyClassic(tooltip, unit);
		end);
		CT_Hooks.setUnit = true;
	end

	if (GameTooltip and GameTooltip.HookScript) then
		GameTooltip:HookScript("OnTooltipSetUnit", function(tooltip)
			CT_ApplyClassic(tooltip, nil);
		end);
		CT_Hooks.onSetUnit = true;
		GameTooltip:HookScript("OnShow", function(tooltip)
			CT_TintBackdrop(tooltip, nil);
			CT_ScheduleTint();
		end);
		GameTooltip:HookScript("OnTooltipCleared", function(tooltip)
			CT_SetStatusBar(tooltip, false);
		end);
	end
end

-- ---------------------------------------------------------------------------
-- Settings panel (replaces the old ClassicTooltipOptions XML frame)
-- ---------------------------------------------------------------------------

local CT_SettingsCategory = nil;

local function CT_RegisterSettings()
	if (type(Settings) ~= "table") then
		return;
	end
	if (type(Settings.RegisterVerticalLayoutCategory) ~= "function"
		or type(Settings.RegisterAddOnSetting) ~= "function"
		or type(Settings.CreateCheckbox) ~= "function"
		or type(Settings.RegisterAddOnCategory) ~= "function") then
		return;
	end
	CT_GetSettings();

	local category = Settings.RegisterVerticalLayoutCategory("ClassicTooltip");
	local varType = (Settings.VarType and Settings.VarType.Boolean) or type(true);

	local enabledSetting = Settings.RegisterAddOnSetting(category,
		"ClassicTooltip_Enabled", "Enabled",
		ClassicTooltipSettings, varType,
		"Use Classic tooltips", true);
	if (enabledSetting) then
		Settings.CreateCheckbox(category, enabledSetting,
			"Reformat unit tooltips into the circa-1.0 style with backdrop coloring and compact lines.");
	end

	local guildSetting = Settings.RegisterAddOnSetting(category,
		"ClassicTooltip_ShowGuild", "ShowGuild",
		ClassicTooltipSettings, varType,
		"Display guild name", false);
	if (guildSetting) then
		Settings.CreateCheckbox(category, guildSetting,
			"Show the player's guild name in brackets on the classic tooltip.");
	end

	-- NOTE: RegisterAddOnCategory returns nothing in this client; the
	-- category object itself carries the ID (category:GetID()).
	Settings.RegisterAddOnCategory(category);
	CT_SettingsCategory = category;
end

local function CT_MaybeRegisterSettings()
	if (CT_SettingsCategory) then
		return;
	end
	pcall(CT_RegisterSettings);
end

local function CT_SlashCmd(msg)
	if (msg and msg:lower() == "status") then
		local settings = CT_GetSettings();
		local unit = CT_ResolveUnit(GameTooltip, nil);
		DEFAULT_CHAT_FRAME:AddMessage("ClassicTooltip " .. CT_GetVersion()
			.. " | Enabled=" .. tostring(settings["Enabled"])
			.. " ShowGuild=" .. tostring(settings["ShowGuild"])
			.. " | hooks processor/setunit/onsetunit="
			.. tostring(CT_Hooks.processor) .. "/"
			.. tostring(CT_Hooks.setUnit) .. "/"
			.. tostring(CT_Hooks.onSetUnit)
			.. " | GameTooltip unit=" .. tostring(unit));
		return;
	end
	CT_MaybeRegisterSettings();
	if (CT_SettingsCategory and Settings and Settings.OpenToCategory) then
		local getID = CT_SettingsCategory.GetID;
		if (getID) then
			local id = getID(CT_SettingsCategory);
			if (id) then
				Settings.OpenToCategory(id);
				return;
			end
		end
	end
	DEFAULT_CHAT_FRAME:AddMessage("ClassicTooltip: the Settings panel is unavailable on this client.");
end

-- ---------------------------------------------------------------------------
-- Initialization
-- ---------------------------------------------------------------------------

local function CT_Initialize()
	CT_GetSettings();
	CT_InstallHooks();
	CT_MaybeRegisterSettings();

	SLASH_CLASSICTOOLTIP1 = "/classictooltip";
	SLASH_CLASSICTOOLTIP2 = "/ct";
	SlashCmdList["CLASSICTOOLTIP"] = CT_SlashCmd;

	DEFAULT_CHAT_FRAME:AddMessage("ClassicTooltip " .. CT_GetVersion() .. " loaded. Type /ct to configure.");
end

local CT_Loader = CreateFrame("Frame");
CT_Loader:RegisterEvent("ADDON_LOADED");
CT_Loader:SetScript("OnEvent", function(_, event, addonName)
	if (event == "ADDON_LOADED" and addonName == ADDON_NAME) then
		CT_Initialize();
	end
	-- The Settings UI can load after us; retry registration then.
	if (event == "ADDON_LOADED") then
		CT_MaybeRegisterSettings();
	end
end);
