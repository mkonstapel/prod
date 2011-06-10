 
#include "Timer.h"
#include "PrintfUART.h"

module TestZ1DUTC {
  uses {
    interface Leds;
    interface Boot;
    interface Timer<TMilli> as TestTimer;
    interface Read<uint16_t> as Light;
    interface PWMControl;
  }
}
implementation {  

  uint8_t pwminc = 0;

  void printTitles(){
    printfUART("\n\n");
    printfUART("   ###############################\n");
    printfUART("   #         AMC PWM TEST        #\n");
    printfUART("   ###############################\n");
    printfUART("\n");
  }
 
  event void Boot.booted() {
    printfUART_init();
    printTitles();
    call TestTimer.startPeriodic(1024);
  }  
  
  event void TestTimer.fired(){
    call Light.read();
    call Leds.led2Toggle();
  }

  event void Light.readDone(error_t error, uint16_t data){
    if (error == SUCCESS){
      printfUART("Light [%d]\n", data);
      if (data < 100) call PWMControl.setPWM(100);
       else call PWMControl.setPWM(0);
    }
  }
  
  event void PWMControl.setPWMDone(error_t error){
    if (error == SUCCESS){
      call Leds.led0Toggle();
    }
  }

}

