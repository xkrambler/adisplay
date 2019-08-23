//#include <SPI.h>

boolean enabled_analog=false;
boolean enabled_digital=false;
boolean enabled_uart=false;
boolean enabled_spi=true;
  
// general
#define BLINK_LED 13
#define BLINK_INTERVAL 500
boolean blink_state=false;

// volcar dato hexadecimal por puerto USB
void SerialPrintHex(unsigned char c) {
  if (c<=0x0F) Serial.print(0);
  Serial.print(c, HEX);
}

// setup
void setup() {
  
  // USB serial speed
  Serial.begin(115200);
  Serial.print("OK\n");
  
  // pin de parpadeo
  pinMode(BLINK_LED, OUTPUT);

}

// main loop
void loop() {

  // parpadear para indicar funcionamiento OK
  static unsigned long millis_blink;
  if (millis()-millis_blink > BLINK_INTERVAL) {
    millis_blink=millis();
    //blink_state=!blink_state;
    blink_state^=true;
    digitalWrite(BLINK_LED, (blink_state?LOW:HIGH));
  }

  // process UART packets
  Serial.print("UART");
  Serial.print(" ");

  //(10)(02)(15)0(01)(00)(00)"(0B)(01)(01)(FF)(91)`@(02)MAXIMAFM(10)(03)H]
  SerialPrintHex(0x10);
  Serial.print("10021548010000");
  SerialPrintHex('"');
  Serial.print("0B0101FF91");
  SerialPrintHex('`');
  SerialPrintHex('@');
  Serial.print("02");
  SerialPrintHex('M');
  SerialPrintHex('A');
  SerialPrintHex('X');
  SerialPrintHex('I');
  SerialPrintHex('M');
  SerialPrintHex('A');
  SerialPrintHex('F');
  SerialPrintHex('M');
  SerialPrintHex(0x10);
  SerialPrintHex(0x03);
  SerialPrintHex('H');
  SerialPrintHex(']');
  Serial.print("\n");

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
  
  delay(150); // por detenerse algo ;)

}

