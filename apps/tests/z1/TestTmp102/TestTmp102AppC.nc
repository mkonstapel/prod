 
#include "PrintfUART.h"

configuration TestTmp102C {}
implementation {
  components MainC, TestTmp102C as App, LedsC;
  App.Leds -> LedsC;
  App.Boot -> MainC.Boot;
  components new TimerMilliC() as TestTimer;
  App.TestTimer -> TestTimer;
  
  components new SimpleTMP102C() as Temperature;
  App.TempSensor -> Temperature;  
}


