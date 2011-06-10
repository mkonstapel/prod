 
#include "amc6821.h"
#include "PrintfUART.h"

module AMC6821P {
  provides{
    interface PWMControl;
  }
  uses{
    interface Resource;
    interface ResourceRequested;
    interface I2CPacket<TI2CBasicAddr> as I2CBasicAddr;    		
    interface Timer<TMilli> as WaitTimer;
  }
}

implementation{


  norace uint8_t amccmd;
  norace uint8_t set_reg[2];
  norace uint8_t pointer[2];
  norace uint8_t buffer[5];
 

  command error_t PWMControl.setPWM(uint8_t Duty){
    error_t error;
    atomic P5DIR |= 0x06;
    pointer[0] = DCYREG_ADDR;
    
    switch(Duty){
      case 0:
        pointer[1] = 0x00; // XXX
        break;
      case 25:
        pointer[1] = DCYREG_25DC;
        break;
      case 50:
        pointer[1] = DCYREG_50DC;
        break;
      case 100:
        pointer[1] = 0xFF; // XXX
        break;
      }
      error = call Resource.request();
      return SUCCESS;
  }
  
  event void Resource.granted(){
    error_t e;
    amccmd = AMC_START;
    set_reg[0] = CONFREG1_ADDR;		
    set_reg[1] = ONLY_PWM_CONFREG1;
    e = call I2CBasicAddr.write((I2C_START | I2C_STOP), AMC6821_ADDRESS, 2, set_reg);
    if (e){
       printfUART("Error setting IC\n");
       call Resource.release();
    }
  }
 
  async event void I2CBasicAddr.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t *data){
    error_t e;
      if(call Resource.isOwner()){
        switch(amccmd){
          case AMC_START:
              amccmd = AMC_PWMSET;
              set_reg[0] = CONFREG2_ADDR;
              set_reg[1] = ONLY_PWM_CONFREG2;
              e = call I2CBasicAddr.write((I2C_START | I2C_STOP), AMC6821_ADDRESS, 2, set_reg);
              if (e){
                printfUART("Error setting PWM\n");
                call Resource.release();
              }
            break;
		   
          case AMC_PWMSET:
              amccmd = AMC_FANSET;
              set_reg[0] = FANREG_ADDR;
              set_reg[1] = PWM_ONLY_FANREG_1KHZ;
              e = call I2CBasicAddr.write((I2C_START | I2C_STOP), AMC6821_ADDRESS, 2, set_reg);  
              if (e){
                printfUART("Error setting Freq\n");
               call Resource.release();
              }
            break;		   
  
          case AMC_FANSET:
              amccmd = AMC_PWMDUTY;
              e = call I2CBasicAddr.write((I2C_START | I2C_STOP),AMC6821_ADDRESS, 2, pointer);
              if (e){
                printfUART("Error changing PWM cycle\n");
                call Resource.release();
                signal PWMControl.setPWMDone(e);
              }
            break;		   

          case AMC_PWMDUTY:
            amccmd = AMC_IDLE;
            // printfUART("Changed duty cycle in AMC\n");
            call Resource.release();
            signal PWMControl.setPWMDone(e);
            break;
        }
      }
  }

  event void WaitTimer.fired(){ }

  async event void I2CBasicAddr.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t *data){ }

  async event void ResourceRequested.requested(){}  
  async event void ResourceRequested.immediateRequested(){}
  
}
