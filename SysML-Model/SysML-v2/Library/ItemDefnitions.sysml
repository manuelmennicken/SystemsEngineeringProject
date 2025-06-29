package 'Generic Item Definitions'{
    item def <RotMechEnergyFlow> RotatoryMechanicalPower{
        attribute Power : ISQ::PowerUnit;
        attribute Torque : ISQ::TorqueUnit;
        attribute Speed : ISQ::SpeedUnit; 
    }
    item def <TransMechEnergyPot> TranslatoryMechanicalPower{
        attribute Force : ISQ::ForceUnit;    
    }

    item def <elecenergy> ElectricalPower;

}