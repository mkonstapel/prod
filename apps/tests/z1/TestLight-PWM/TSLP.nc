 
#include "tsl2563.h"
#include "PrintfUART.h"

module TSLP {
  provides{
    interface Read<uint16_t> as Light;
  }
  uses {
    interface I2CPacket<TI2CBasicAddr> as I2CBasicAddr;    
    interface Resource;
    interface ResourceRequested;
    interface Timer<TMilli> as TimerUp;		
    interface Timer<TMilli> as TimeoutTimer;
    interface Leds;	
  }
}

implementation {

  norace uint8_t state = TSLCMD_IDLE;
  norace uint8_t pointer;
  norace uint8_t setreg;
  norace uint16_t lightBuff[4];
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
    signal Light.readDone(SUCCESS, lux);
  }

  command error_t Light.read(){
    atomic P5DIR |= 0x06;
    state = TSLCMD_START;
    call TimeoutTimer.startOneShot(1024);
    call TimerUp.startOneShot(100);
    return SUCCESS;
  }

  event void TimerUp.fired(){
    call Resource.request();
  }
  
  event void Resource.granted(){
    error_t error;
    pointer = 0xAC;		
    setreg = 0x3;		
    error = call I2CBasicAddr.write((I2C_START | I2C_STOP), TSL2563_ADDRESS, 1, &setreg);
    if (error){
      printfUART("Error write:RS\n");
      call Resource.release();
      signal Light.readDone(error, 0xFFFF);
    }
  }
 

  async event void I2CBasicAddr.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t *data){
    error_t e;
    if(call Resource.isOwner()){
      if(state == TSLCMD_START){
        state = TSLCMD_READ;
        e = call I2CBasicAddr.write((I2C_START | I2C_STOP), TSL2563_ADDRESS, 1, &pointer);		  
      } else if (state == TSLCMD_READ){
        e = call I2CBasicAddr.read((I2C_START | I2C_STOP), TSL2563_ADDRESS, 4, &lightBuff);  
      }
      if (e){
        printfUART("Error Read:RD\n");
        call Resource.release();
        signal Light.readDone(error, 0xFFFF);
      }
    } 
  }
 
  async event void I2CBasicAddr.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t *data){
    if (call Resource.isOwner()){
      uint16_t tmp;
      state = TSLCMD_IDLE;
      for(tmp=0;tmp<0xffff;tmp++);	//delay
      call Resource.release();
      reading[0] = (data[1] << 8) + data[0];
      reading[1] = (data[3] << 8) + data[2];
      lux = calculatelux();
      post signalEvent();
      call TimeoutTimer.stop();
    }
  }

  event void TimeoutTimer.fired(){
    printfUART("TSL: timeout\n");
  }

  default event void Light.readDone(error_t error, uint16_t data){
    return;
  }

  async event void ResourceRequested.requested(){}  
  async event void ResourceRequested.immediateRequested(){}
  
}
