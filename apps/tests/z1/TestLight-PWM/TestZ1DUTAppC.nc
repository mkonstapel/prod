 
#include "PrintfUART.h"

configuration TestZ1DUTAppC {}
implementation {
  components MainC, TestZ1DUTC as App, LedsC;
  App.Leds -> LedsC;
  App.Boot -> MainC.Boot;
  
  components new TimerMilliC() as TestTimer;
  App.TestTimer -> TestTimer;

  components AMC6821C;
  App.PWMControl -> AMC6821C.PWMControl;

  components TSLC;
  App.Light -> TSLC.Light;

}


