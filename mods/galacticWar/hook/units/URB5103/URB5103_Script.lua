--#****************************************************************************
--#**
--#**  File     :  /cdimage/units/URB5103/URB5103_script.lua
--#**  Author(s):  John Comes, David Tomandl
--#**
--#**  Summary  :  Cybran Quantum Gate Beacon Unit
--#**
--#**  Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
--#****************************************************************************

local CStructureUnit = import('/lua/cybranunits.lua').CStructureUnit

URB5103 = Class(CStructureUnit) {
    FxTransportBeacon = {'/effects/emitters/red_beacon_light_01_emit.bp'},
    FxTransportBeaconScale = 0.4,

    OnStopBeingBuilt = function(self, builder, layer)
        CStructureUnit.OnStopBeingBuilt(self, builder, layer)
        for k, v in self.FxTransportBeacon do
            self.Trash:Add(CreateAttachedEmitter(self, 0, self:GetArmy(), v):ScaleEmitter(self.FxTransportBeaconScale))
        end
    end,
}

TypeClass = URB5103