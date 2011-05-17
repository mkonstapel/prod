 
#include "PrintfUART.h"

configuration TestADXL345AppC {}
implementation {
  components MainC, TestADXL345C as App, LedsC;
  App.Leds -> LedsC;
  App.Boot -> MainC.Boot;
  components new TimerMilliC() as TestTimer;
  App.TestTimer -> TestTimer;
  
  components new ADXL345C();
  App.Xaxis -> ADXL345C.X;
  App.Yaxis -> ADXL345C.Y;
  App.Zaxis -> ADXL345C.Z;
  App.AccelControl -> ADXL345C.SplitControl;
}


