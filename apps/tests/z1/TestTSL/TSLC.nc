 
#include "PrintfUART.h"

configuration TSLC {
  provides {
    interface Read<uint16_t> as Light;
    interface SplitControl as TSLSwitch;
  }
}
  
implementation {
 
  components TSLP;
  Light = TSLP.Light;
  TSLSwitch = TSLP.TSLSwitch;
  
  components new Msp430I2CB1C() as I2C;
  TSLP.Resource -> I2C;
  TSLP.ResourceRequested -> I2C;
  TSLP.I2CBasicAddr -> I2C; 

  components new TimerMilliC() as TimeoutTimer;
  TSLP.TimeoutTimer -> TimeoutTimer;


}


