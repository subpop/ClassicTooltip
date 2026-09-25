-- ClassicTooltip by Link

local version = GetAddOnMetadata("ClassicTooltip", "Version");
local CONFIGVERSION = 1;
ClassicTooltipHelp = {};
ClassicTooltipHelp[1] = "ClassicTooltip reverts the tooltip to the older style.\n\n* Backdrop coloring, instead of coloring the unit's name\n* Less information is displayed on mouseover. For players, the name is on the first line, race and class on the second, and level on the third. No PvP text is displayed anywhere.\n* NPCs have their \"city\" association removed. Elite creatures have the + added after their level."

function CT_OnLoad()
  -- This is the nice deep red that hostile units used to have.
  FACTION_BAR_COLORS[2].r = 0.8;
  FACTION_BAR_COLORS[2].g = 0.0;
  FACTION_BAR_COLORS[2].b = 0.0;
  
  SLASH_CLASSICTOOLTIP1 = "/classictooltip";
	SLASH_CLASSICTOOLTIP2 = "/ct";
	SlashCmdList["CLASSICTOOLTIP"] = CT_SlashCmd;
  
  -- Register for events
  ClassicTooltipFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT");
  ClassicTooltipFrame:RegisterEvent("VARIABLES_LOADED");
  
  DEFAULT_CHAT_FRAME:AddMessage("ClassicTooltip " .. version .. " loaded");
end

function CT_OnEvent(event)
  if (event == "UPDATE_MOUSEOVER_UNIT") then
	  GameTooltip:SetUnit("mouseover");
	elseif (event == "VARIABLES_LOADED") then
	  if (not ClassicTooltipSettings) then
	    ClassicTooltipSettings = {
	      ["Version"] = CONFIGVERSION, -- Int: Internal config version to handle upgrades to the config variable.
	      ["Enabled"] = true,
	      ["ShowGuild"] = false,
	    }
	  end
	  -- Hook the GameTooltip functions
    if(ClassicTooltipSettings.Enabled) then
      CT_SetUnit_Orig = GameTooltip.SetUnit;
      GameTooltip.SetUnit = CT_SetUnit;
      CT_OnHide_Orig = GameTooltip_OnHide;
      GameTooltip_OnHide = CT_OnHide;
      CT_UnitColor_Orig = GameTooltip_UnitColor;
      GameTooltip_UnitColor = CT_UnitColor;
      CT_UnitFrame_OnEnter_Orig = UnitFrame_OnEnter;
      UnitFrame_OnEnter = CT_UnitFrame_OnEnter;
      
      CT_GameTooltip_OnTooltipCleared_Orig = GameTooltip:GetScript("OnTooltipCleared");
      GameTooltip:SetScript("OnTooltipCleared", CT_GameTooltip_OnTooltipCleared);
    end
  end
end

function CT_GameTooltip_OnTooltipCleared()
  GameTooltipStatusBar:Hide();
  CT_GameTooltip_OnTooltipCleared_Orig();
end

function CT_SetUnit(this, unit)
  CT_SetUnit_Orig(this,unit);
  GameTooltipStatusBar:Hide();
  CT_MakeOldTooltip(unit);
end

function CT_OnHide()
  GameTooltipStatusBar:Hide();
  CT_OnHide_Orig();
end

function CT_UnitFrame_OnEnter()
	CT_UnitFrame_OnEnter_Orig();
	CT_MakeOldTooltip(this.unit);
	GameTooltipStatusBar:Show();
end

-- This is where the magic happens
function CT_MakeOldTooltip(unit)
  local name, race, class, level, creaturetype;
  local r = nil;
  local g = nil;
  local b = nil;
  
  -- I think this is a decent way to ignore all non-player-NPC tooltips
  if(not UnitClass(unit)) then
    return;
  end
  
  -- Save off data from the tooltip if we're on an NPC,
  -- since we can't get stuff like NPC description without screenscraping.
  local description = nil;
  if(not UnitIsPlayer(unit) and GameTooltipTextLeft2:GetText() and string.find(GameTooltipTextLeft2:GetText(),"^Level")) then
    -- Assume there is no description
    description = nil;
  else
    description = GameTooltipTextLeft2:GetText();
  end
  
  for i = 1, GameTooltip:NumLines() do
    if(string.find(getglobal("GameTooltipTextLeft"..i):GetText(),"Skinnable")) then
      r,g,b = getglobal("GameTooltipTextLeft"..i):GetTextColor();
    end
  end
  
  -- Now clear the tooltip, so we have a clean slate to drawn on
  GameTooltip:ClearLines();
  
  -- Set the unit's level
  if(UnitLevel(unit) == -1) then
    level = "??";
  else
    level = UnitLevel(unit);
  end
  
  -- Set the unit's name, race and class
  name = UnitName(unit);
  race = UnitRace(unit);
  class = UnitClass(unit);
  
  -- Construct the lines
  GameTooltip:AddLine(name);
  if(UnitIsPlayer(unit)) then
    GameTooltip:AddLine(race .. " " .. class,1,1,1);
    if(ClassicTooltipSettings.ShowGuild and GetGuildInfo(unit)) then
      GameTooltip:AddLine("<" .. GetGuildInfo(unit) .. ">");
    end
    GameTooltip:AddLine("Level " .. level,1,1,1);
  else
    if(description) then
      GameTooltip:AddLine(description,1,1,1);
    end
    
    if(UnitLevel(unit) > 0) then
      -- Add the elite +
      if(UnitClassification(unit) == "elite" or UnitClassification(unit) == "rareelite") then
        level = level .. "+";
      end
    else
      if(UnitClassification(unit) == "worldboss") then
        level = "??+";
      else
        level = "??";
      end
    end
    
    if(UnitIsDead(unit)) then
      GameTooltip:AddLine("Level " .. level .. " Corpse",1,1,1);
      if(r and g and b) then
        GameTooltip:AddLine("Skinnable",r,g,b);
      end
    elseif(UnitReaction(unit,"player") and (UnitReaction(unit,"player") < 5)) then
      local creatureType = UnitCreatureType(unit);
      if(creatureType == "Not specified") then
        creatureType = UnitCreatureFamily(unit);
        --[[
        -- Handle the Ooze case, by adding a "Ooze" type
				if(string.find(UnitName(unit),"Ooze") or string.find(UnitName(unit),"Sludge") or string.find(UnitName(unit),"Slime") or string.find(UnitName(unit),"Sap Beast")) then
					creatureType = "Ooze";
				-- Handle the Zukk'ash insects in Feralas
				elseif(string.find(UnitName(unit),"^Zukk'ash") or string.find(UnitName(unit),"^Centipaar")) then
					creatureType = "Insect";
				elseif(string.find(UnitName(unit), "Constrictor Vine") or string.find(UnitName(unit), "Barbed Lasher")) then
					creatureType = "Plant";
				end]]
			end
			GameTooltip:AddLine("Level " .. level .. " " .. creatureType,1,1,1);
		else
		  GameTooltip:AddLine("Level " .. level,1,1,1);
		end
	end
	if(UnitClass("mouseover")) then
	  GameTooltipStatusBar:Show();
	end
	GameTooltip:SetBackdropColor(GameTooltip_UnitColor(unit));
	GameTooltip:Show();
end

function CT_UnitColor(unit)
	local r, g, b;
	if ( UnitPlayerControlled(unit) ) then
		if ( UnitCanAttack(unit, "player") ) then
			-- Hostile players are red
			if ( not UnitCanAttack("player", unit) ) then
				--[[
				r = 1.0;
				g = 0.5;
				b = 0.5;
				]]
				r = 0.0;
				g = 0.0;
				b = 1.0;
			else
				r = FACTION_BAR_COLORS[2].r;
				g = FACTION_BAR_COLORS[2].g;
				b = FACTION_BAR_COLORS[2].b;
			end
		elseif ( UnitCanAttack("player", unit) ) then
			-- Players we can attack but which are not hostile are yellow
			r = FACTION_BAR_COLORS[4].r;
			g = FACTION_BAR_COLORS[4].g;
			b = FACTION_BAR_COLORS[4].b;
		elseif ( UnitIsPVP(unit) ) then
			-- Players we can assist but are PvP flagged are green
			r = FACTION_BAR_COLORS[6].r;
			g = FACTION_BAR_COLORS[6].g;
			b = FACTION_BAR_COLORS[6].b;
		else
			-- All other players are blue (the usual state on the "blue" server)
			r = 0.0;
			g = 0.0;
			b = 1.0;
		end
	else
		local reaction = UnitReaction(unit, "player");
		if ( reaction ) then
			r = FACTION_BAR_COLORS[reaction].r;
			g = FACTION_BAR_COLORS[reaction].g;
			b = FACTION_BAR_COLORS[reaction].b;
		else
			r = 0.0;
			g = 0.0;
			b = 1.0;
		end
	end
	return r, g, b;
end

function CT_OptionsOnShow()
  if(ClassicTooltipSettings.Enabled) then
    ClassicTooltipOptionsShowGuild:Enable();
    ClassicTooltipOptionsShowGuildText:SetTextColor(1.0,1.0,1.0);
		ClassicTooltipOptionsEnabled:SetChecked(1);
	else
	  ClassicTooltipOptionsShowGuild:Disable();
    ClassicTooltipOptionsShowGuildText:SetTextColor(0.50,0.50,0.50);
		ClassicTooltipOptionsEnabled:SetChecked(0);
	end
	if(ClassicTooltipSettings.ShowGuild) then
	  ClassicTooltipOptionsShowGuild:SetChecked(1);
	else
	  ClassicTooltipOptionsShowGuild:SetChecked(0);
	end
end

function CT_ToggleEnabled()
  ClassicTooltipSettings.Enabled = not ClassicTooltipSettings.Enabled;
  
  if(ClassicTooltipSettings.Enabled) then
    CT_SetUnit_Orig = GameTooltip.SetUnit;
    GameTooltip.SetUnit = CT_SetUnit;
    CT_OnHide_Orig = GameTooltip_OnHide;
    GameTooltip_OnHide = CT_OnHide;
    CT_UnitColor_Orig = GameTooltip_UnitColor;
    GameTooltip_UnitColor = CT_UnitColor;
    CT_UnitFrame_OnEnter_Orig = UnitFrame_OnEnter;
    UnitFrame_OnEnter = CT_UnitFrame_OnEnter;
    
    ClassicTooltipOptionsShowGuild:Enable();
    ClassicTooltipOptionsShowGuildText:SetTextColor(1.0,1.0,1.0);
  else
    GameTooltip.SetUnit = CT_SetUnit_Orig;
    GameTooltip_OnHide = CT_OnHide_Orig;
    GameTooltip_UnitColor = CT_UnitColor_Orig;
    UnitFrame_OnEnter = CT_UnitFrame_OnEnter_Orig;
    
    ClassicTooltipOptionsShowGuild:Disable();
    ClassicTooltipOptionsShowGuildText:SetTextColor(0.50,0.50,0.50);
  end
end

function CT_ToggleGuildEnabled()
  ClassicTooltipSettings.ShowGuild = not ClassicTooltipSettings.ShowGuild;
end

function CT_SlashCmd()
  if(ClassicTooltipOptions:IsVisible()) then
		HideUIPanel(ClassicTooltipOptions);
	else
		ShowUIPanel(ClassicTooltipOptions);
	end
end