--#****************************************************************************
--#**
--#**  File     :  /cdimage/units/XSB5103/XSB5103_script.lua
--#**  Author(s):  speed2
--#**
--#**  Summary  :  Seraphim Quantum Gate Beacon Unit
--#**
--#**
--#****************************************************************************

local SStructureUnit = import('/lua/seraphimunits.lua').SStructureUnit

XSB5103 = Class(SStructureUnit) {
    FxTransportBeacon = {'/effects/emitters/red_beacon_light_01_emit.bp'},
    FxTransportBeaconScale = 0.4,

    OnStopBeingBuilt = function(self)
        SStructureUnit.OnStopBeingBuilt(self)
        for k, v in self.FxTransportBeacon do
            self.Trash:Add(CreateAttachedEmitter(self, 0, self:GetArmy(), v):ScaleEmitter(self.FxTransportBeaconScale))
        end
    end,
}

TypeClass = XSB5103