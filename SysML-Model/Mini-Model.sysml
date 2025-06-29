package eTruck{

    part def Drivetrain;
    part def Gearbox{
        attribute ratio : ScalarValues::Real;
        attribute eta : ScalarValues::Real;
    }
    part def Wheel{
        attribute radius : ISQ::LengthUnit;
    }

    part Drivetrain{
        part gbx : Gearbox{
            :>> ratio = 7.25;
        }
        part wheel[4] : Wheel{
            :>> radius = 0.376 [SI::m];
        }
    }
}