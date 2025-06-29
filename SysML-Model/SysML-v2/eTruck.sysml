private import 'Generic Item Definitions'::*;
private import 'Generic Port Definitions'::*;
private import 'Drivetrain Item Definitions'::*;

private import 'Drivetrain Definition Package'::*; 


part eTruck{
    part cabin;
    part TMS;
    part powertrain{
        part Drivetrain{
            part gbx : Gearbox{
                part PlanetaryStage1 : NonshiftableSpurGearStage;
                part PlanetaryStage2 : NonshiftableSpurGearStage;
            }
            part Differential;
        }
        part EDMLeft : ElectricDriveUnit;
        part EDMRight : ElectricDriveUnit;
        part PCU;
        part Battery : TractionBattery_2out;
    }
    part chassis;
    part AuxiliaryUnitDrive;
    part Trailer;
    part WHeel;
    part VCU;
}