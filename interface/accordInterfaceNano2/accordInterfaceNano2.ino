/*
  Interface Accord v2 22/07/2017
  - Todo operativo
*/
#include <AltSoftSerial.h>
#include <SPI.h>

AltSoftSerial radioUART(8, 9); // RX, TX

boolean enabled_analog=false;
boolean enabled_digital=false;
boolean enabled_uart=true;
boolean enabled_spi=true;
boolean enabled_blink=false;

// general
#define BLINK_LED 13
#define BLINK_INTERVAL 500
boolean blink_state=false;

// SPI packets
#define SPI_PACKET 10
byte spipacket[SPI_PACKET];
byte spibuf[SPI_PACKET];
unsigned int spipackets=0;
unsigned long spimillis_last=micros();
byte spilen=0;

// volcar dato hexadecimal por puerto USB
void SerialPrintHex(unsigned char c) {
  if (c<=0x0F) Serial.print(0);
  Serial.print(c, HEX);
}

// setup SPI
void SPIsetup() {

  // setup pins
  //pinMode(MISO, OUTPUT);
  pinMode(MOSI, INPUT);
  pinMode(SCK, INPUT);
  pinMode(SS, INPUT);
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
  //SPCR|=_BV(CPHA); // Samples data on the falling edge of the data clock when 1, rising edge when 0
  SPCR|=_BV(CPOL); // Sets the data clock to be idle when high if set to 1, idle when low if set to 0
  //SPCR|=_BV(DORD); // Sends data least Significant Bit First when 1, most Significant Bit first when 0
  //SPCR|=_BV(SPR1); SPCR|=_BV(SPR0); // Sets the SPI speed, 00 is fastest (4MHz) 11 is slowest (250KHz)
  SPCR|=_BV(SPE); // enable SPI
  SPCR|=_BV(SPIE); // SPI.attachInterrupt();
  //SPCR&=~_BV(SPIE); // SPI.detachInterrupt()
}

// setup
void setup() {
  
  // USB serial speed
  Serial.begin(115200);
  Serial.print("OK\n");
  
  // pin de parpadeo
  if (enabled_blink) pinMode(BLINK_LED, OUTPUT);

  // set the UART data rate
  if (enabled_uart) radioUART.begin(19200);

  // setup SPI
  if (enabled_spi) SPIsetup();

  // esperar 50ms a recibir el primer paquete
  // (se emite cada ~15ms)
  delay(50);

}

int last=0;

// SPI interrupt routine
ISR(SPI_STC_vect) {

  extern volatile unsigned long timer0_millis; // accedemos al contador de millis directo para evitar retrasos

  // 22º 22º MANUAL A/C OFF
  // 80 5B 1B 9B 9B BF 86 80 80 B9
  byte c=SPDR; // leer byte del SPI Data Register

  // si pasan mas de 8ms, se considera nuevo paquete
  if (timer0_millis-spimillis_last > 5) spilen=0;

  // rellenar buffer y avanzar
  spibuf[spilen++]=c;

  //SerialPrintHex(c);
  //if (++last>=10){ timer0_millis=0; last=0; Serial.print(" "); Serial.print(spilen); Serial.println(); }

  // buffer completo
  if (spilen >= SPI_PACKET) {

    // reiniciamos el puntero del buffer
    spilen=0;
    // verificamos el buffer
    
    if (spibuf[0]==0x80) {
      // copiar buffer a paquete
      for (byte i=0;i<SPI_PACKET;i++)
        spipacket[i]=spibuf[i%SPI_PACKET];
      // indicamos que hay un nuevo paquete
      spipackets++;
    } else {
      Serial.print("*RESET*");
      // reseteamos SPI si nos encontramos un paquete erroneo
      SPIsetup();
      //spimillis_last=timer0_millis+1;
    }
  }

  // se resetea cada vez que salimos de la interrupcion
  spimillis_last=timer0_millis;

}

// main loop
void loop() {
  
  // parpadear para indicar funcionamiento OK (OJO: Si no es ATmega2560, comentar, interfiere con SPI)
  if (enabled_blink) {
    static unsigned long millis_blink;
    if (millis()-millis_blink > BLINK_INTERVAL) {
      millis_blink=millis();
      //blink_state=!blink_state;
      blink_state^=true;
      digitalWrite(BLINK_LED, (blink_state?LOW:HIGH));
    }
  }

  // process SPI packets
  if (enabled_spi) {
    static unsigned long spipackets_last;
    if (spipackets_last!=spipackets) {
      spipackets_last=spipackets;
      Serial.print("SPI");
      for (int i=0;i<SPI_PACKET;i++) {
        Serial.print(" ");
        SerialPrintHex(spipacket[i]);
      }
      //Serial.print(" (");
      //Serial.print(spipackets);
      Serial.print("\n");
    }
  }

  // process UART packets
  if (enabled_uart) {
    if (radioUART.available()) {
      Serial.print("UART");
      while (radioUART.available()) {
        Serial.print(" ");
        SerialPrintHex(radioUART.read());
      }
      Serial.print("\n");
    }
  }

  // enviar datos de los pines analógicos
  if (enabled_analog) {
    Serial.print("ANALOG");
    for (int i=0;i<8;i++) {
      Serial.print(" ");
      Serial.print(analogRead(A0+i));
    }
    Serial.print("\n");
  }

  // enviar datos de los pines digitales
  if (enabled_digital) {
    Serial.print("DIGITAL");
    for (int i=0;i<=13;i++) {
      Serial.print(" ");
      Serial.print(digitalRead(i));
    }
    Serial.print("\n");
  }

  // comandos
  while (Serial.available()) {
    boolean enabled=false;
    switch (Serial.read()) {
    case 'p': Serial.print("PONG\n"); break; // ping
    case '0': digitalWrite(Serial.read(), HIGH); break;
    case '1': digitalWrite(Serial.read(), LOW);  break;
    case '2': digitalWrite(Serial.read(), Serial.read()*256+Serial.read()); break;
    case '+': enabled=true;
    case '-':
      switch (Serial.read()) {
      case 'a': enabled_analog=enabled;  Serial.print(enabled?"+":"-"); Serial.print("ANALOG\n");  break;
      case 'd': enabled_digital=enabled; Serial.print(enabled?"+":"-"); Serial.print("DIGITAL\n"); break;
      case 'u': enabled_uart=enabled;    Serial.print(enabled?"+":"-"); Serial.print("UART\n");    break;
      case 's': enabled_spi=enabled;     Serial.print(enabled?"+":"-"); Serial.print("SPI\n");     break;
      default: break;
      }
      break;
    //case 's': Sound(20*serialbyte(),serialbyte(),piezoPin); break;
    //case 't': setTime(serialbyte(),serialbyte(),serialbyte(),serialbyte(),serialbyte(),1970+serialbyte()); break;
    }
  }

  // hacer algo de espera activa
  delay(1);

}

