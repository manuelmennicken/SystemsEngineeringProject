package 'Drivetrain Item Definitions'{
    item Signal_Battery{
        attribute SoC : ScalarValues::Real;
        attribute P_El : ISQ::EnergyUnit;
        attribute  P_Charging_max : ISQ::EnergyUnit;
    }

    item Signal_EDM{
        attribute omega : ISQ::SpeedUnit;
    }

    item def Signal_PCU{
        attribute M_target : ISQ::TorqueUnit;
    }

    item def Signal_RotSensor{
        attribute omega : ISQ::SpeedUnit;
    }

    item def Signal_TCU{
        attribute GearSignal : ScalarValues::Real;
    }
}