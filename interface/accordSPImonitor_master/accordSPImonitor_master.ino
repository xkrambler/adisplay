/**
 * Debera recibir: 80 5B 1B 9B 9B BF 86 80 80 B9
 * Recibe:            5B 1B 9B 9B BF 86 80 80 B9 80
*/

// SPI packets
#define SPI_PACKET 10
unsigned char spipacket[SPI_PACKET];
unsigned long spipackets=0;
unsigned long spimillis_last=micros();
unsigned char spibuf[SPI_PACKET];
volatile byte spilen=0;

// setup
void setup() {
  
  Serial.begin(115200);
  Serial.println("SPI Monitor OK!");

  // setup pins
  pinMode(MISO, INPUT);
  pinMode(MOSI, OUTPUT);
  pinMode(SS, OUTPUT);
  pinMode(SCK, OUTPUT);

  digitalWrite(SS, LOW);

  // SPI setup
  /*
    SPCR
    | 7    | 6    | 5    | 4    | 3    | 2    | 1    | 0    |
    | SPIE | SPE  | DORD | MSTR | CPOL | CPHA | SPR1 | SPR0 |
  */
  SPCR=0; // reset SPI
  //SPI.setDataMode(SPI_MODE1);
  //SPI.setBitOrder(MSBFIRST); // MSB LSB
  //SPI.setClockDivider(SPI_CLOCK_DIV16); // DIV16
  SPCR|=_BV(MSTR);
  //SPCR|=_BV(CPHA); // Samples data on the falling edge of the data clock when 1, rising edge when 0
  SPCR|=_BV(CPOL); // Sets the data clock to be idle when high if set to 1, idle when low if set to 0
  //SPCR|=_BV(DORD); // Sends data least Significant Bit First when 1, most Significant Bit first when 0
  SPCR|=_BV(SPR1); SPCR|=_BV(SPR0); // Sets the SPI speed, 00 is fastest (4MHz) 11 is slowest (250KHz)
  SPCR|=_BV(SPE); // enable SPI
  SPCR|=_BV(SPIE); // SPI.attachInterrupt();
  //SPCR&=~_BV(SPIE); // SPI.detachInterrupt()

  // esperar 50ms a recibir el primer paquete
  // (se emite cada ~15ms)
  delay(50);

}

// SPI interrupt routine
ISR(SPI_STC_vect) {
  byte c=SPDR; // leer byte del SPI Data Register
  extern volatile unsigned long timer0_millis; // accedemos al contador de millis directo para evitar retrasos

  Serial.print(c, HEX);
/*
  // si pasan ms de 6ms y tenemos un paquete completo,
  // copiamos el buffer al paquete y comenzamos de nuevo
  if (timer0_millis-spimillis_last>6) {
    spipackets++;
    for (int i=0;i<SPI_PACKET;i++)
      spipacket[i]=spibuf[i];
    spilen=0;
  }

  // verificar buffer
  if (spilen < SPI_PACKET)
    spibuf[spilen++]=c;
  */
  // se resetea cada vez que se recibe un byte
  spimillis_last=timer0_millis;

}

// main loop
void loop() {
  static unsigned long spipackets_last;

  // show packet
  if (spipackets_last!=spipackets) {
    spipackets_last=spipackets;
    for (int i=0;i<SPI_PACKET;i++) {
      if (spipacket[i]<0x10)
        Serial.print("0");
      Serial.print(spipacket[i], HEX);
      Serial.print(" ");
    }
    Serial.print(" packet: ");
    Serial.print(spipackets);
    Serial.println();
  }
  
  delay(1);

}

