-- Forged Alliance Forever coop mod_info.lua file
--
-- Documentation for the extended FAF mod_info.lua format can be found here:
-- https://github.com/FAForever/fa/wiki/mod_info.lua-documentation
name = "FAF Galactic War support mod"
version = 2
_faf_modname ='galactic_war'
copyright = "Forged Alliance Forever Community"
description = "Support mod for Galactic War"
author = "Forged Alliance Forever Community"
url = "http://www.faforever.com"
uid = "804f1e70-fe75-438f-a96f-7e423e4b8e2a"
selectable = false
exclusive = false
ui_only = false
conflicts = {}
mountpoints = {
    lua = '/lua',
    units = '/units',
    ['mods/galacticWar/hook'] = '/schook'
}
