 
#include "Timer.h"
#include "PrintfUART.h"

module TestZ1DUTC {
  uses {
    interface Leds;
    interface Boot;
    interface Timer<TMilli> as TestTimer;	
    interface Read<uint16_t> as Temperature;
    interface Read<uint16_t> as Humidity;
  
  }
}
implementation {  

  uint8_t pass;

  void printTitles(){
    printfUART("\n\n");
  	printfUART("   ###############################\n");
  	printfUART("   #           TEST SHT11        #\n");
  	printfUART("   ###############################\n");
  	printfUART("\n");
  }

  event void Boot.booted() {
    printfUART_init();
	printTitles();
	call TestTimer.startPeriodic(1024);
  }
  
  event void TestTimer.fired(){
    pass++;
    if (pass % 2 == 0){ 
      call Temperature.read();
    } else {
      call Humidity.read();
    }
  }

  event void Temperature.readDone(error_t error, uint16_t data){
    uint16_t temp;
    if (error == SUCCESS){
     call Leds.led2Toggle();
     temp = (data/10) -400;
    	printfUART("Temp: %d.%d\n", temp/10, temp>>2);
    }
  }

  event void Humidity.readDone(error_t error, uint16_t data){
    uint16_t hum;
    if (error == SUCCESS){
        hum = data*0.0367;
        hum -= 2.0468;
        if (hum>100) hum = 100;
	call Leds.led2Toggle();
    	printfUART("Hum: %d\n", hum);
    }
  }

  
}





