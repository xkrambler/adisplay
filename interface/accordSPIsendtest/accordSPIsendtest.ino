#include <SPI.h>

void setup() {
  
  Serial.begin(19200);

  digitalWrite(SS, HIGH);  // ensure SS stays high for now

  // Put SCK, MOSI, SS pins into output mode
  // also put SCK, MOSI into LOW state, and SS into HIGH state.
  // Then put SPI hardware into Master mode and turn SPI on
  SPI.begin();
  
  SPI.setDataMode(SPI_MODE3);
  SPI.setBitOrder(MSBFIRST);
  
  // Slow down the master a bit
  SPI.setClockDivider(SPI_CLOCK_DIV128);

}

void loop() {

  unsigned int i=0;
  
  while (true) {
    
    i++;
    
    Serial.print("OK: ");
    Serial.print(i);
    Serial.println("!");
  
    // send 22º 22º MANUAL A/C OFF
    // 80 5B 1B 9B 9B BF 86 80 80 B9
    int d=50;
    SPI.transfer(0x80); delayMicroseconds(d);
    SPI.transfer(0x5B); delayMicroseconds(d);
    SPI.transfer(0x1B); delayMicroseconds(d);
    SPI.transfer(0x9B); delayMicroseconds(d);
    SPI.transfer(0x9B); delayMicroseconds(d);
    SPI.transfer(0xBF); delayMicroseconds(d);
    SPI.transfer(0x86); delayMicroseconds(d);
    SPI.transfer(0x80); delayMicroseconds(d);
    SPI.transfer(0x80); delayMicroseconds(d);
    SPI.transfer(0xB9); delayMicroseconds(d);
  
  
  /*
  SPI B9 80 5B 1B 9B 9B BF 86 80 00 (30)
SPI B9 80 5B 1B 9B 9B BF 86 80 00 (31)
SPI B9 80 5B 1B 9B 9B BF 86 80 00 (32)
SPI B9 80 5B 1B 9B 9B BF 86 80 00 (33)
SPI B9 80 5B 1B 9B 9B BF 86 80 00 (34)
SPI B9 80 5B 1B 9B 9B BF 86 80 00 (35)
SPI B9 80 5B 1B 9B 9B BF 86 80 00 (36)
SPI B9 80 5B 1B 9B 9B BF 86 80 00 (37
  */
  
    delay(100);
    //delay(13);
    
  }

}

