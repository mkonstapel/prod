 
#include "tsl2563.h"
#include "PrintfUART.h"

module TSLP {
  provides{
    interface SplitControl as TSLSwitch;
    interface Read<uint16_t> as Light;
  }
  uses {
    interface Resource;
    interface ResourceRequested;
    interface I2CPacket<TI2CBasicAddr> as I2CBasicAddr;    		
    interface Timer<TMilli> as TimeoutTimer;
    interface Leds;	
  }
}

implementation
{
  enum {
    S_STARTED,
    S_STOPPED,
  };

  norace uint8_t state = S_STOPPED;
  norace uint8_t tsl2563cmd;
  norace uint8_t set_reg[4];
  norace uint8_t pointer;
  norace error_t error_return= FAIL;
  norace uint16_t reading[2];
  norace uint16_t lux;
  
  uint16_t calculatelux(){
    uint32_t ch0, ch1 = 0;
    uint32_t aux = (1<<14);
    uint32_t ratio;
    uint32_t lratio;
    uint32_t tmp=0;

    ch0 = (reading[0]*aux) >> 10;
    ch1 = (reading[1]*aux) >> 10;
    ratio = (ch1 << 10)/ch0;
    lratio = (ratio+1) >> 1;

    if ((lratio >= 0) && (lratio <= K1T))
      tmp = (ch0*B1T) - (ch1*M1T);
    else if (lratio <= K2T)
      tmp = (ch0*B2T) - (ch1*M2T);
    else if (lratio <= K3T)
      tmp = (ch0*B3T) - (ch1*M3T);
    else if (lratio <= K4T)
      tmp = (ch0*B4T) - (ch1*M4T);
    else if (lratio <= K5T)
      tmp = (ch0*B5T) - (ch1*M5T);
    else if (lratio <= K6T)
      tmp = (ch0*B6T) - (ch1*M6T);
    else if (lratio <= K7T)
      tmp = (ch0*B7T) - (ch1*M7T);
    else if (lratio > K8T)
      tmp = (ch0*B8T) - (ch1*M8T);

    if (tmp < 0) tmp = 0;
    
    tmp += (1<<13);
    return (tmp >> 14);
  }

  task void signalEvent(){
    if (error_return == SUCCESS){
      if(call TimeoutTimer.isRunning()) call TimeoutTimer.stop();
    }
    if(call Resource.isOwner()) call Resource.release();	
    switch(tsl2563cmd){
      case TSLCMD_START:
        signal TSLSwitch.startDone(error_return);
        break;

      case TSLCMD_STOP:
        signal TSLSwitch.stopDone(error_return);
        break;

      case TSLCMD_READ:
        signal Light.readDone(error_return, lux);
        break;
    }
  }

  command error_t TSLSwitch.start(){
    error_t e = FAIL;
    error_return = FAIL;
    call TimeoutTimer.startOneShot(1024);
    // if(state != S_STARTED){
      tsl2563cmd = TSLCMD_START;
      e = call Resource.request();
      if(e == SUCCESS) return SUCCESS;
    // }
    return e;
  }
  
  command error_t TSLSwitch.stop(){
    error_t e = FAIL;
    error_return = FAIL;
    call TimeoutTimer.startOneShot(1024);
    // if(state != S_STOPPED){
      tsl2563cmd = TSLCMD_STOP;
      e = call Resource.request();
      if (e == SUCCESS) return SUCCESS;
    // }
    return e;
  }

  command error_t Light.read(){
    error_t e = FAIL;
    error_return = FAIL;
    call TimeoutTimer.startOneShot(1024);
    if (state == S_STARTED){
      tsl2563cmd = TSLCMD_READ;
      e = call Resource.request();
      if (e == SUCCESS) return SUCCESS;
    }
    return e;
  }
  
  event void Resource.granted(){
    error_t e;
      switch(tsl2563cmd){
        case TSLCMD_START:
          // printfUART("Turning sensor on\n");
          set_reg[0] = 0x3;		
          e = call I2CBasicAddr.write((I2C_START | I2C_STOP), TSL2563_ADDRESS, 1, set_reg);
          if (e != SUCCESS){
            printfUART("Error Start:RS\n");
            post signalEvent();
          }
          break;

        case TSLCMD_STOP:
          // printfUART("Turning sensor off\n");
          set_reg[0] = 0x0;		
          e = call I2CBasicAddr.write((I2C_START | I2C_STOP), TSL2563_ADDRESS, 1, set_reg);		  
          if (e != SUCCESS){
            printfUART("Error Stop:RS\n");
            post signalEvent();
          }
          break;

        case TSLCMD_READ:
          set_reg[0] = 0xAC;		
          e = call I2CBasicAddr.write((I2C_START | I2C_STOP), TSL2563_ADDRESS, 1, set_reg);		  
          if (e != SUCCESS){
            printfUART("Error Read:RS\n");
            post signalEvent();
          }
          break;
      }
  }
 
  async event void I2CBasicAddr.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t *data){
    error_t e;
      if(call Resource.isOwner()){
        switch(tsl2563cmd){

          case TSLCMD_START:
            if (error == SUCCESS){
              state = S_STARTED;
              error_return = SUCCESS;
              printfUART("Sensor on\n");
            }
            post signalEvent();
            break;
		   
          case TSLCMD_READ:
            if (error == SUCCESS){
              e = call I2CBasicAddr.read((I2C_START | I2C_STOP), TSL2563_ADDRESS, 4, set_reg);  
              if (e != SUCCESS){
                printfUART("Error Read:RD\n");
                post signalEvent();
              }
            }
            break;		   
  
          case TSLCMD_STOP:
            if (error == SUCCESS){
              state = S_STOPPED;
               error_return = SUCCESS;
            }
            post signalEvent();			  
            break;		   
        }
      } 
 }
 
  async event void I2CBasicAddr.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t *data){
    if ((call Resource.isOwner()) && (state == S_STARTED)){
      switch(tsl2563cmd){
        case TSLCMD_READ:
          if(error == SUCCESS){
            reading[0] = (data[1] << 8) + data[0];
            reading[1] = (data[3] << 8) + data[2];
            lux = calculatelux();
            error_return = SUCCESS;
          } else{
            lux = 0;
          }
          post signalEvent();
          break;
       }
     }
  }

  event void TimeoutTimer.fired(){
    // if(call Resource.isOwner()) call Resource.release();
    printfUART("TSL: timeout\n");
    post signalEvent();
  }

  default event void Light.readDone(error_t error, uint16_t data){
    return;
  }

  async event void ResourceRequested.requested(){}  
  async event void ResourceRequested.immediateRequested(){}
  
}
