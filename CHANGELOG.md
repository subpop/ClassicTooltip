# ClassicTooltip Changelog

## 2.2.0

- Rebuilt for modern Classic clients: Mists of Pandaria Classic, and Classic
  Era.
- Replaced the standalone options frame with a native Settings panel.
  Type /ct to jump straight to it (/ct status prints diagnostics).
- No more overriding Blizzard's tooltip functions: formatting is applied
  through secure post-hooks (TooltipDataProcessor, SetUnit, and
  OnTooltipSetUnit together), so other tooltip add-ons play nicer.
- Backdrop coloring instead of name coloring, as before: solid fills in
  a muted 2007-hue palette (brick red, amber, mustard, forest green,
  steel blue), re-applied on show and on the next frame so client-side
  backdrop passes cannot wipe them.
- The 2.x reaction palette is hardcoded again (including the signature
  deep-red hostile override) instead of inheriting the modern client's
  brighter colors, and it only ever tints this add-on's tooltip instead
  of changing FACTION_BAR_COLORS for the whole UI.
- Faithful 2007 tooltip content: white name, "race class" display names,
  level with elite "+", NPC descriptions, literal "Skinnable" on corpses.
  No PvP text, no city association. Removed the myAddons dependency and
  the legacy XML frame.

## Earlier history

- September 2026 - Link Dupont
  - 2.2.0: rebuilt for modern Classic (Cataclysm / Mists). Settings panel
    replaces the old options frame, secure post-hooks replace the global
    function overrides, hostile red is local to the tooltip backdrop, and
    the myAddons dependency plus XML frame are gone.
- Friday January 12, 2007 - Link Dupont
  - Updated Interface number to 20003
- Thursday October 13, 2006 - Link Dupont
  - Migrated to the TOC method for myAddons.
- Wednesday October 11, 2006 - Link Dupont
  - Updated Interface number to 11200; confirmed functionality.
  - Updated author, email and website in myAddons array.
  - Released 1.12.0.
- Sunday June 4, 2006 - Link Dupont
  - Updated Interface number to 11000; confirmed functionality.
  - Removed extra padding on the bottom of Player toolips.
  - Released 1.10.0.
- Wednesday October 13, 2005 - Link Dupont
  - Updated Interface number to 1800; confirmed functionality.
  - Released 1.8.0.
- Tuesday September 27, 2005 - Link Dupont
  - Added Centipaar bugs to the insect CreatureType fix.
- Saturday September 24, 2005 - Link Dupont
  - Added likely fix for the Lua popup errors that occasionally appear.
  - Added Barbed Lasher to the list of fixed creature types.
  - Reworked Revert function to use GameTooltip:AddLine. This should play better with addons that inject bits of data into the tooltip that way.
  - Added "Skinnable".
  - Released 1.7.1.
- Tuesday September 13, 2005 - Link Dupont
  - Updated Interface number to 1700.
  - Hooked event handler functions using the new GetScript functions, fixing a stack overflow caused by the old method.
  - Added hooks for TargetFrameHealthBar and TargetFrameManaBar, so the mouse-over now shows the Classic tooltip.
  - Added "fix" for the line 3 being odd colors.
  - Released 1.7.0.
- Monday September 5, 2005 - Link Dupont
  - Fixed CreatureType case for "Constrictor Vine". Is now of type "Vine".
- Sunday September 4, 2005 - Link Dupont
  - Fixed a tooltip error when UnitLevel() was less than 0 but not a worldboss. This should fix the "Rexxar" bug.
  - Released 0.3.1.
- Thursday September 1, 2005 - Link Dupont
  - Added CreatureType cases for Oozes/Sludges/Slimes, so instead of "Not specified" it now displays "Ooze".
  - Added CreatureType case for Zukk'ash insects in Feralas, now "Insect" instead of "Not specified".
- Monday August 22, 2005 - Link Dupont
  - Added fix for item comparison tooltips by ignoring all non-(N)PC tooltips.
  - Released 0.3.
- Friday August 19, 2005 - Link Dupont
  - Added fix for bag item tooltips when vendor windows are open (don't call ClassicTooltip_Revert if event == "TOOLTIP_ADD_MONEY", since we'll never get that event on player & NPC tooltips, which is all I care about modifying).
  - Added fix for "worldboss" NPCs (those who's level registers as -1 and who's unit classification is "worldboss"). I don't remember how those were handled prior to the new tooltips. If anyone else does, or has a screenshot, I'd be very grateful. For now, its Level = "??+". Kinda lame, but I can't think of anything better.
- Thursday August 18, 2005 - Link Dupont
  - Re-wrote the ClassicTooltip_Revert function to better handle the tooltip data.
  - There should be no visible changes (aside from the extra line being gone in PartyFrames). The new function is easier to understand, and does things in a more logical manner.
  - Released 0.2.
- Wednesday August 17, 2005 - Link Dupont
  - Added a slash-command to toggle display on/off. Only available in pre-1.0 & BETA/UNSTABLE releases.
  - Added myAddons support.
- Sunday August 14, 2005 - Link Dupont
  - Released 0.1, first public release.
