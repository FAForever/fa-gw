--#****************************************************************************
--#**
--#**  File     :  /cdimage/units/UEB5103/UEB5103_script.lua
--#**  Author(s):  John Comes, David Tomandl
--#**
--#**  Summary  :  UEF Quantum Gate Beacon Unit
--#**
--#**  Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
--#****************************************************************************

local TStructureUnit = import('/lua/terranunits.lua').TStructureUnit

UEB5103 = Class(TStructureUnit) {
    FxTransportBeacon = {'/effects/emitters/red_beacon_light_01_emit.bp'},
    FxTransportBeaconScale = 0.4,

    OnStopBeingBuilt = function(self)
        TStructureUnit.OnStopBeingBuilt(self)
        for k, v in self.FxTransportBeacon do
            self.Trash:Add(CreateAttachedEmitter(self, 0, self:GetArmy(), v):ScaleEmitter(self.FxTransportBeaconScale))
        end
    end,
}

TypeClass = UEB5103