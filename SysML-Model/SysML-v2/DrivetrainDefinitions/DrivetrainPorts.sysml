private import 'Drivetrain Item Definitions'::*;
private import 'Generic Item Definitions'::*;
private import 'Generic Port Definitions'::*;

package 'Drivetrain Port Definitions'{
    port def Flange :> RotatoryMechanicalEnergyFlowPort;
    port def ElectricalPlug :> ElectricalEnergyFlowPort;
}