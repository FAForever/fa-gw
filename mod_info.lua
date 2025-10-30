-- Forged Alliance Forever coop mod_info.lua file
--
-- Documentation for the extended FAF mod_info.lua format can be found here:
-- https://github.com/FAForever/fa/wiki/mod_info.lua-documentation
name = "FAF Galactic War support mod"
version = 3
_faf_modname ='galactic_war'
copyright = "Forged Alliance Forever Community"
description = "Support mod for Galactic War"
author = "Forged Alliance Forever Community"
url = "http://www.faforever.com"
uid = "c4491442-67e2-446a-abfd-bd5f82647415"
selectable = false
exclusive = false
ui_only = false
conflicts = {}
mountpoints = {
    lua = '/lua',
    units = '/units',
    ['mods/galacticWar/hook'] = '/schook'
}
