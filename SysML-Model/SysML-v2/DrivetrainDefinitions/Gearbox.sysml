private import 'Generic Item Definitions'::*;
private import 'Drivetrain Item Definitions'::*;
private import 'Generic Port Definitions'::*;
private import 'Drivetrain Port Definitions'::*;


package 'Drivetrain Definition Package'{

    part def Gearbox{
        port P_Drive_in : Flange;
        port P_Drive_out : Flange;
        port P_Support_out : TranslatoryMechanicalEnergyPotentialPort;

        attribute ratio : ScalarValues::Real;
        attribute eta : ScalarValues::Real;
    }

    part def PlanetaryGearstage :> Gearbox;
    part def NonshiftableSpurGearStage :> Gearbox;

    part def TractionBattery{
        attribute SoC : ScalarValues::Real;
        attribute Np : ScalarValues::Real; //Number of parallel cells
        attribute Ns : ScalarValues::Real; //Number of seriell cells
        attribute cap : ISQ::EnergyUnit; //Capacity of each cell
        attribute P_Charging_max : ISQ::PowerUnit;  
    }

    part def TractionBattery_2out :> TractionBattery{
        port P_out_1 : ElectricalPlug;
        port P_out_2 : ElectricalPlug;
    }


    part def RotationalSensor;
    part def SummingGearStage{
        port P_Drive_in : Flange;
        port P_Drive_in2 : Flange;
        port P_Drive_out : Flange;
    }
    part def ElectricMotor{
        port P_el_in : ElectricalPlug;
        port P_Drive_out : Flange;
    }

    part def ElectricDriveUnit{
        part inverter : TractionInverter;
        part engine : ElectricEngine;
    }

    part def TractionInverter{
        port P_el_in : ElectricalPlug;
        port P_el_out : ElectricalPlug;
    }
    part def ElectricEngine;
    part def PMSM :> ElectricEngine; 

    calc def EfficiencyModel{       
        out eta_out : ScalarValues::Real;
    }

    calc def EfficiencyConstant :> EfficiencyModel{
         attribute eta : ScalarValues::Real;     
         out :>> eta_out = eta;   
    }

    calc def EfficiencyTable{
        attribute table = "asdasda";
    }
}