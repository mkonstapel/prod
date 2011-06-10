 
#include "PrintfUART.h"

configuration AMC6821C {
  provides {
    interface PWMControl;
  }
}
  
implementation {
 
  components AMC6821P;
  PWMControl = AMC6821P.PWMControl;
 
  components new TimerMilliC() as WaitTimer;
  AMC6821P.WaitTimer -> WaitTimer;

  components new Msp430I2CB1C() as I2C;
  AMC6821P.Resource -> I2C;
  AMC6821P.ResourceRequested -> I2C;
  AMC6821P.I2CBasicAddr -> I2C; 
}


