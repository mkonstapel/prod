interface PWMControl{
  command error_t setPWM(uint8_t duty);
  event void setPWMDone(error_t error);
}


