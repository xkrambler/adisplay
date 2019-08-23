//#include <SPI.h>

// setup
void setup() {

  Serial.begin(115200);
  Serial.println("Test SPI Master READY");

  // setup pins
  pinMode(MISO, OUTPUT);
  pinMode(MOSI, INPUT);
  pinMode(SS, INPUT);
  pinMode(SCK, INPUT);
  pinMode(9, OUTPUT);

  /*
  SPI.beginTransaction(SPISettings(20, MSBFIRST, SPI_MODE3));
  SPI.setClockDivider(SPI_CLOCK_DIV128);
  */

  /*
    SPCR
    | 7    | 6    | 5    | 4    | 3    | 2    | 1    | 0    |
    | SPIE | SPE  | DORD | MSTR | CPOL | CPHA | SPR1 | SPR0 |
  */
  SPCR=0; // reset SPI
  //SPI.setDataMode(SPI_MODE1);
  //SPI.setDataMode(SPI_MODE1);
  //SPI.setBitOrder(MSBFIRST); // MSB LSB
  //SPI.setClockDivider(SPI_CLOCK_DIV16); // DIV16
  //SPCR|=_BV(MSTR);
  //SPCR|=_BV(CPHA); // Samples data on the falling edge of the data clock when 1, rising edge when 0
  SPCR|=_BV(CPOL); // Sets the data clock to be idle when high if set to 1, idle when low if set to 0
  //SPCR|=_BV(DORD); // Sends data least Significant Bit First when 1, most Significant Bit first when 0
  SPCR|=_BV(SPR1); SPCR|=_BV(SPR0); // Sets the SPI speed, 00 is fastest (4MHz) 11 is slowest (250KHz)
  //DDRB |= (1<<5); // DDRB |= (1<<2)|(1<<3)|(1<<5);
  //DDRB |= (1<<2)|(1<<3)|(1<<5);
  //SPCR |= (1<<MSTR);              // Set as Master
  SPCR |= (1<<SPR0)|(1<<SPR1);     // divided clock by 128
  //SPSR = (1<<SPI2X); 
  SPCR|=_BV(SPE); // enable SPI
  SPCR|=_BV(SPIE); // SPI.attachInterrupt();
  //SPCR&=~_BV(SPIE); // SPI.detachInterrupt()


/*


int main (void)
{
    char data;

    DDRB |= (1<<2)|(1<<3)|(1<<5);    // SCK, MOSI and SS as outputs
    DDRB &= ~(1<<4);                 // MISO as input

    SPCR |= (1<<MSTR);               // Set as Master
    SPCR |= (1<<SPR0)|(1<<SPR1);     // divided clock by 128
    SPCR |= (1<<SPE);                // Enable SPI
    
    while(1)
    {
        SPDR = data;                 // send the data
        while(!(SPSR & (1<<SPIF)));  // wait until transmission is complete

        // if you have multiple slaves, this is where you want to switch
    }
}



 

  // SPI setup
  SPCR=0; // reset SPI
  //SPI.setDataMode(SPI_MODE1);
  //SPI.setDataMode(SPI_MODE1);
  //SPI.setBitOrder(MSBFIRST); // MSB LSB
  //SPI.setClockDivider(SPI_CLOCK_DIV16); // DIV16
  //SPCR|=_BV(CPHA); // Samples data on the falling edge of the data clock when 1, rising edge when 0
  SPCR|=_BV(CPOL); // Sets the data clock to be idle when high if set to 1, idle when low if set to 0
  //SPCR|=_BV(DORD); // Sends data least Significant Bit First when 1, most Significant Bit first when 0
  SPCR|=_BV(SPR1); SPCR|=_BV(SPR0); // Sets the SPI speed, 00 is fastest (4MHz) 11 is slowest (250KHz)

  //DDRB |= (1<<5); // DDRB |= (1<<2)|(1<<3)|(1<<5);
  //DDRB |= (1<<2)|(1<<3)|(1<<5);

SPCR |= (1<<MSTR);              // Set as Master
    SPCR |= (1<<SPR0)|(1<<SPR1);     // divided clock by 128

  //SPSR = (1<<SPI2X); 

  SPCR|=_BV(SPE); // enable SPI
  SPCR|=_BV(SPIE); // SPI.attachInterrupt();
  //SPCR&=~_BV(SPIE); // SPI.detachInterrupt()

  // esperar 50ms a recibir el primer paquete
  // (se emite cada ~15ms)
  delay(50);
*/


}


// SPI interrupt routine
ISR(SPI_STC_vect) {
  byte c=SPDR; // leer byte del SPI Data Register
  Serial.print(c, HEX);
}


#define SPI_CLOCK_BIT(delay_usec) digitalWrite(9, LOW); delayMicroseconds(delay_usec); digitalWrite(9, HIGH); delayMicroseconds(delay_usec);
#define SPI_CLOCK() SPI_CLOCK_BIT(50);

/*
#define SPI_BIT_WRITE(b, n) digitalWrite(MOSI, bitRead(b, n)); SPI_CLOCK_BIT(45);

void spiWriteByte(byte b) {
  SPI_BIT_WRITE(b, 7);
  SPI_BIT_WRITE(b, 6);
  SPI_BIT_WRITE(b, 5);
  SPI_BIT_WRITE(b, 4);
  SPI_BIT_WRITE(b, 3);
  SPI_BIT_WRITE(b, 2);
  SPI_BIT_WRITE(b, 1);
  SPI_BIT_WRITE(b, 0);
  digitalWrite(MOSI, LOW);
  delayMicroseconds(2100);
}
*/

void spiClock() {
  //digitalWrite(SS, LOW);
  SPI_CLOCK();
  SPI_CLOCK();
  SPI_CLOCK();
  SPI_CLOCK();
  SPI_CLOCK();
  SPI_CLOCK();
  SPI_CLOCK();
  SPI_CLOCK();
  //digitalWrite(SS, HIGH);
  delayMicroseconds(2100);
}

// main loop
void loop() {

Serial.println("!");

  spiClock();
  spiClock();
  spiClock();
  spiClock();
  spiClock();
  spiClock();
  spiClock();
  spiClock();
  spiClock();
  spiClock();

/*
  spiWriteByte(0x80);
  spiWriteByte(0x5B);
  spiWriteByte(0x1B);
  spiWriteByte(0x9B);
  spiWriteByte(0xBF);
  spiWriteByte(0x86);
  spiWriteByte(0x80);
  spiWriteByte(0x00);
  spiWriteByte(0xB9);
*/

/*
  // SPI 80 5B 1B 9B 9B BF 86 80 00 B9
  int d=2200;
  SPI.transfer(0x80); delayMicroseconds(d);
  SPI.transfer(0x5B); delayMicroseconds(d);
  SPI.transfer(0x1B); delayMicroseconds(d);
  SPI.transfer(0x9B); delayMicroseconds(d);
  SPI.transfer(0xBF); delayMicroseconds(d);
  SPI.transfer(0x86); delayMicroseconds(d);
  SPI.transfer(0x80); delayMicroseconds(d);
  SPI.transfer(0x00); delayMicroseconds(d);
  SPI.transfer(0xB9); delayMicroseconds(d);
*/

  delay(10);

}

