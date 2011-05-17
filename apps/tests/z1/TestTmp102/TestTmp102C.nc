 
 #include "Timer.h"
 #include "PrintfUART.h"

module TestTmp102C {
  uses {
    interface Leds;
    interface Boot;
    interface Timer<TMilli> as TestTimer;	
    interface Read<uint16_t> as TempSensor;
  
  }
}
implementation {  

  void printTitles(){
    printfUART("\n\n");
    printfUART("   ###############################\n");
    printfUART("   #                             #\n");
    printfUART("   #          TMP102 TEST        #\n");
    printfUART("   #                             #\n");
    printfUART("   ###############################\n");
    printfUART("\n");
  }

  event void Boot.booted() {
    printfUART_init();
    printTitles();
    call TestTimer.startPeriodic(1024);
  }
  
  event void TestTimer.fired(){
    call TempSensor.read();
  }

  event void TempSensor.readDone(error_t error, uint16_t data){
    if (error == SUCCESS){
      call Leds.led2Toggle();
      if (data > 2047) data -= (1<<12);
      data *=0.625; 
      printfUART("Temp: %2d.%1.2d\n", data/10, data>>2);
    }
  }
  
}





