 
#include "PrintfUART.h"

configuration TestZ1DUTAppC {}
implementation {
  components MainC, TestZ1DUTC as App, LedsC;
  App.Leds -> LedsC;
  App.Boot -> MainC.Boot;
  components new TimerMilliC() as TestTimer;
  App.TestTimer -> TestTimer;
  
  components new SensirionSht11C() as Temperature;
  App.Temperature -> Temperature.Temperature;  

  components new SensirionSht11C() as Humidity;
  App.Humidity -> Humidity.Humidity;  

}


