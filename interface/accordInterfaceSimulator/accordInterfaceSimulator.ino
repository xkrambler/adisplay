boolean enabled_analog=false;
boolean enabled_digital=false;
boolean enabled_uart=true;
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
  
  // pin de parpadeo
  pinMode(BLINK_LED, OUTPUT);

  // esperar 50ms a recibir el primer paquete
  // (se emite cada ~15ms)
  delay(50);

  // listo para iniciar el bucle general
  Serial.print("OK\n");

}

// main loop
void loop() {
  
  // millis directo
  extern volatile unsigned long timer0_millis;

  // parpadear para indicar funcionamiento OK (OJO: Si no es ATmega2560, comentar, interfiere con SPI)
  static unsigned long millis_blink;
  if (millis()-millis_blink > BLINK_INTERVAL) {
    millis_blink=millis();
    //blink_state=!blink_state;
    blink_state^=true;
    digitalWrite(BLINK_LED, (blink_state?LOW:HIGH));
  }


  Serial.print("UART 10 02 05 3A 01 17 02 04 10 03 3C\n"); // reloj
  Serial.print("UART 10 02 17 34 20 20 42 41 53 53 20 20 20 20 20 20 20 43 00 00 00 02 11 00 00 00 10 03 43\n"); delay(350); // menu
  Serial.print("UART 10 02 15 30 01 00 00 01 86 01 00 FF FF FF 7F 00 00 00 00 00 00 00 00 00 10 03\n");
  Serial.print("UART 31 10 02 15 30 01 00 00 01 87 01 00\n");
  Serial.print("SPI 80 5B 1B 9B 9B BF 80 80 80 BF\n"); delay(450);
  Serial.print("UART FF FF FF 7F 00 00 00 00 00 00 00 00 00 10 03\n");
  Serial.print("UART 30 10 02 15 30 01 00 00 01 88 01 00 FF FF FF 7F 00\n");
  Serial.print("SPI 80 26 1B 9B 9B BF 86 80 80 C4\n"); delay(250);
  Serial.print("UART 00 00 00 00 00 00\n");
  Serial.print("UART 00 00 10 03 3F\n");
  Serial.print("UART 10 02 15 30 01 00 00 22 11 01 01 FF 91 60 40 03 4D 41 58 49 4D 41 46 4D 10 03 53\n"); // radio MAXIMAFM
  Serial.print("SPI 80 5B 1B 9B 9B BF C8 80 80 F7\n"); delay(450);
  Serial.print("UART 10 02 15 30 01 00 00 01 89 01 00 FF FF FF 7F 00 00 00 00 00 00 00\n");
  Serial.print("UART 00 00 10 03 3E 10 02 15 30 01 00 00\n");
  Serial.print("SPI 80 5B 1B 9B 9B BF 80 F8 80 C7\n"); delay(350);
  Serial.print("UART 01 8A 01 00 FF FF FF 7F 00 00 00 00 00\n");
  Serial.print("UART 00 00 00 00 10 03 3D\n");
  Serial.print("UART 10 02 10 10 30 03 10 10 03 43 11 05 FF 01 FF 73 FF F2 40 00 00 10 03 4B\n"); // timming 2:40
  Serial.print("UART 10 02 17 34 48 6F 6C 65 20 2D 20 56 69 6F 6C 65 74 20 20 20 00 00 00 00 00 00 10 03 3E\n"); delay(550); // usb
  Serial.print("SPI 80 5B 1B 9B 9B BF 80 F4 80 CB\n"); delay(150);
  Serial.print("UART 10 02 10 10 30 03 10 10 03 43 11 05 FF 01 FF 73 FF F2 41 00 00 10 03 4A\n"); // timming 2:41

  // retraso (ms)
  delay(150);

  //delay(10000); // para probar el timeout

}

