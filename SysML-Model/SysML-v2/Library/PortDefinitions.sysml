private import 'Generic Item Definitions'::*;

package 'Generic Port Definitions'{

    port def RotatoryMechanicalEnergyFlowPort{
        out : RotatoryMechanicalPower;    
    }
    port def TranslatoryMechanicalEnergyPotentialPort;
    port def SignalPort;
    port def ElectricalEnergyFlowPort;
}