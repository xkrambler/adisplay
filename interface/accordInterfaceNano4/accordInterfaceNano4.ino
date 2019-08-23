/*
  Interface Accord v4 02/12/2018
  - Se suprime el Blink LED por causar conflicto con el SPI
  - Se añaden intervalos constantes al muestreo de puertos analógicos y digitales
  - Se trabaja el SPI manualmente por ser el Arduino Nano ATMega328P excesivamente rápido (librería SPI no requerida)
  - Se incluye de nuevo UART
  Ejemplo de paquete:
  - 22º 22º MANUAL A/C OFF: 80 5B 1B 9B 9B BF 86 80 80 B9
*/

#include <SoftwareSerial.h>

SoftwareSerial radioUART(4, 5); // RX, TX

// habilitar por defecto
boolean enabled_analog =false;
boolean enabled_digital=false;
boolean enabled_spi    =true;
boolean enabled_uart   =true;

// general
#define ANALOG_INTERVAL 100
#define DIGITAL_INTERVAL 50
#define SPI_INTERVAL 150
#define SPI_SCK_REPLICA_PIN 9
#define SPI_SCK_BIT(pin, delay_usec) digitalWrite(pin, LOW); delayMicroseconds(delay_usec); digitalWrite(pin, HIGH); delayMicroseconds(delay_usec);
#define SPI_SCK() SPI_SCK_BIT(SPI_SCK_REPLICA_PIN, 55);
#define SPI_PACKET_LEN 10
byte spipacket[SPI_PACKET_LEN];
byte spibuf[SPI_PACKET_LEN];
unsigned int spipackets=0;
unsigned long spimillis_last=micros();
byte spilen=0;

// solicitar byte SPI
void spiByte() {
  SPI_SCK();
  SPI_SCK();
  SPI_SCK();
  SPI_SCK();
  SPI_SCK();
  SPI_SCK();
  SPI_SCK();
  SPI_SCK();
  delayMicroseconds(2100);
}

// solicitar un paquete SPI
void spiRequest() {
  spilen=0;
  for (byte i=0;i<SPI_PACKET_LEN;i++)
    spiByte();
}

// configurar SPI
void spiSetup() {

  // setup pins
  pinMode(MISO, OUTPUT);
  pinMode(MOSI, INPUT);
  pinMode(SS,   INPUT);
  pinMode(SCK,  INPUT);
  pinMode(9,    OUTPUT);

  // SPI setup
  SPCR=0; // reset SPI
  SPCR|=_BV(MSTR); // Set Master
  SPCR|=_BV(CPOL); // Sets the data clock to be idle when high if set to 1, idle when low if set to 0
  //SPCR|=_BV(CPHA); // Samples data on the falling edge of the data clock when 1, rising edge when 0
  //SPCR|=_BV(DORD); // Sends data least Significant Bit First when 1, most Significant Bit first when 0
  //SPCR|=_BV(SPR1); SPCR|=_BV(SPR0); // Sets the SPI speed, 00 is fastest (4MHz) 11 is slowest (250KHz) *** not used in slave mode
  SPCR|=_BV(SPE); // enable SPI
  SPCR|=_BV(SPIE); // enable SPI Interrupts();

}

// reiniciar SPI y esperar unos milisegundos adicionales
void spiReset() {
  Serial.print("SPI_RESET\n");
  delay(10); // 10ms de espera entre resets (evita caer en el mismo punto de sincronización)
}

// setup
void setup() {

  // configurar UART->USB
  Serial.begin(115200);
  Serial.print("OK\n");

  // set the UART data rate
  if (enabled_uart) radioUART.begin(19200);

  // setup SPI
  if (enabled_spi) spiSetup();

}

// construir CRC del paquete SPI
byte spiCRC(byte p[]) {
  return p[1]^p[2]^p[3]^p[4]^p[5]^p[6]^p[7]^0x40;
}

// validar un paquete SPI
bool spiValidPacket(byte p[]) {
  return (p[0]==0x80 && p[8]==0x80 && p[9]==spiCRC(p)?true:false);
}

// interrupción de recepción SPI
ISR(SPI_STC_vect) {

  // leer byte del SPI Data Register
  byte c=SPDR;

  // rellenar buffer y avanzar
  spibuf[spilen++]=c;

  // si buffer completo
  if (spilen >= SPI_PACKET_LEN) {
    // volvemos a empezar
    spilen=0;
    // comprobar si el paquete es válido
    if (spiValidPacket(spibuf)) {
      // copiar buffer a paquete
      for (byte i=0;i<SPI_PACKET_LEN;i++)
        spipacket[i]=spibuf[i];
      // indicamos que hay un nuevo paquete
      spipackets++;
    // en caso contrario, reseteamos el SPI por si está fuera de sincronía
    } else {
      spiReset();
    }
  }

}

// volcar dato hexadecimal formateado
void SerialPrintHex(unsigned char c) {
  if (c<0x10) Serial.print(0);
  Serial.print(c, HEX);
}

// main loop
void loop() {

  // procesar paquetes UART
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

  // procesar paquetes SPI
  if (enabled_spi) {
    static unsigned long spipackets_last;
    if (spipackets_last!=spipackets) {
      spipackets_last=spipackets;
      Serial.print("SPI");
      for (int i=0;i<SPI_PACKET_LEN;i++) {
        Serial.print(" ");
        SerialPrintHex(spipacket[i]);
      }
      Serial.print("\n");
    }
    // solicitar nuevos paquetes al SPI
    static unsigned long millis_spi;
    if (millis()-millis_spi > SPI_INTERVAL) {
      //Serial.print("SPI_REQUEST("); Serial.print(millis_spi); Serial.print(")\n");
      millis_spi=millis();
      spiRequest();
    }
  }

  // enviar datos de los pines analógicos
  if (enabled_analog) {
    static unsigned long millis_analog;
    if (millis()-millis_analog > ANALOG_INTERVAL) {
      millis_analog=millis();
      Serial.print("ANALOG");
      for (int i=0;i<8;i++) {
        Serial.print(" ");
        Serial.print(analogRead(A0+i));
      }
      Serial.print("\n");
    }
  }

  // enviar datos de los pines digitales
  if (enabled_digital) {
    static unsigned long millis_digital;
    if (millis()-millis_digital > DIGITAL_INTERVAL) {
      millis_digital=millis();
      Serial.print("DIGITAL");
      for (int i=0;i<=13;i++) {
        Serial.print(" ");
        Serial.print(digitalRead(i));
      }
      Serial.print("\n");
    }
  }

  // comandos
  while (Serial.available()) {
    boolean enabled=false;
    switch (Serial.read()) {
    case 'p': Serial.print("PONG\n"); break; // ping
    case '0': digitalWrite(Serial.read(), LOW); break;
    case '1': digitalWrite(Serial.read(), HIGH);  break;
    case '2': digitalWrite(Serial.read(), Serial.read()*256+Serial.read()); break;
    case '+': enabled=true;
    case '-':
      switch (Serial.read()) {
      case 'a': enabled_analog =enabled; Serial.print(enabled?"+":"-"); Serial.print("ANALOG\n");  break;
      case 'd': enabled_digital=enabled; Serial.print(enabled?"+":"-"); Serial.print("DIGITAL\n"); break;
      case 's': enabled_spi    =enabled; Serial.print(enabled?"+":"-"); Serial.print("SPI\n");     break;
      case 'u': enabled_uart   =enabled; Serial.print(enabled?"+":"-"); Serial.print("UART\n");     break;
      default: break;
      }
      break;
    }
  }

  // hacer algo de espera no activa
  delay(1);

}

