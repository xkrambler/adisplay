/*
  Interface Accord v1
  - Primeras pruebas
*/
#include <AltSoftSerial.h>
#include <SPI.h>

boolean enabled_analog=false;
boolean enabled_digital=false;
boolean enabled_uart=true;
boolean enabled_spi=true;

AltSoftSerial uartSerial(8, 9); // RX, TX

// general
#define BLINK_LED 13
#define BLINK_INTERVAL 500
boolean blink_state=false;

// SPI packets
#define SPI_PACKET 10
byte spipacket[SPI_PACKET];
byte spibuf[SPI_PACKET];
unsigned long spipackets=0;
unsigned long spimillis_last=micros();
volatile byte spilen=0;

// setup
void setup() {
  
  // USB serial speed
  Serial.begin(115200);
  Serial.print("OK\n");
  
  // pin de parpadeo
  pinMode(BLINK_LED, OUTPUT);

  // set the UART data rate
  uartSerial.begin(19200);

  // setup pins
  pinMode(MISO, OUTPUT);
  pinMode(MOSI, INPUT);
  pinMode(SS, INPUT);
  pinMode(SCK, INPUT);
 
  // turn on SPI in slave mode + interrupts
  SPCR=_BV(SPE)|_BV(SPIE);

  // esperar 50ms a recibir el primer paquete
  // (se emite cada ~15ms)
  delay(50);

}

// SPI interrupt routine
ISR(SPI_STC_vect) {

  byte c=SPDR; // leer byte del SPI Data Register
  extern volatile unsigned long timer0_millis; // accedemos al contador de millis directo para evitar retrasos

  // si pasan ms de 6ms y tenemos un paquete completo,
  // copiamos el buffer al paquete y comenzamos de nuevo
  if (timer0_millis-spimillis_last>9) {

    // disable interrupt
    SPCR=0;

    // copy buffer
    volatile byte changed=0;
    for (volatile byte i=0;i<SPI_PACKET;i++) {
      if (spipacket[i]!=spibuf[i]) changed++;
      spipacket[i]=0+spibuf[i];
    }
    if (changed) spipackets++;
    spilen=0;

    // turn on SPI in slave mode + interrupts
    SPCR=_BV(SPE)|_BV(SPIE); //|_BV(DORD);

    //SPCR|=_BV(CPHA);
    //SPCR|=_BV(CPOL);
    //SPCR|=;

  }

  // verificar buffer
  if (spilen < SPI_PACKET)
    spibuf[spilen++]=c;
  
  // se resetea cada vez que se recibe un byte
  spimillis_last=timer0_millis;

}

void SerialPrintHex(unsigned char c) {
  if (c<=0x0F) Serial.print(0);
  Serial.print(c, HEX);
}

// main loop
void loop() {

  // parpadear para indicar funcionamiento OK
  /*static unsigned long millis_blink;
  if (millis()-millis_blink > BLINK_INTERVAL) {
    millis_blink=millis();
    //blink_state=!blink_state;
    blink_state^=true;
    digitalWrite(BLINK_LED, (blink_state?LOW:HIGH));
  }*/
  
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
      Serial.print(" ");
      Serial.print(spipackets);
      Serial.print("\n");
    }
  }

/*
  // process UART packets
  if (enabled_uart) {
    if (uartSerial.available()) {
      Serial.print("UART");
      while (uartSerial.available()) {
        Serial.print(" ");
        SerialPrintHex(uartSerial.read());
      }
      Serial.print("\n");
    }
  }
*/

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
  
  delay(10); // por detenerse algo ;)

}

