-- Forged Alliance Forever coop mod_info.lua file
--
-- Documentation for the extended FAF mod_info.lua format can be found here:
-- https://github.com/FAForever/fa/wiki/mod_info.lua-documentation
name = "FAF Galactic War support mod"
version = 5
_faf_modname ='galactic_war'
copyright = "Forged Alliance Forever Community"
description = "Support mod for Galactic War"
author = "Forged Alliance Forever Community"
url = "http://www.faforever.com"
uid = "62049b1d-cac4-4e26-bba1-106f6434abdc"
selectable = false
exclusive = false
ui_only = false
conflicts = {}
mountpoints = {
    lua = '/lua',
    units = '/units',
    ['mods/galacticWar/hook'] = '/schook'
}
