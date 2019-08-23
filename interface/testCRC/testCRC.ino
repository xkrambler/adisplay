byte spipacket1[]={0x80,0x3D,0x1B,0xDC,0xF8,0xFB,0x80,0xC2,0x80,0xFB}; // OK
byte spipacket2[]={0x80,0x5B,0x1B,0xE6,0x9B,0xBF,0x80,0xC2,0x80,0x80}; // OK
byte spipacket3[]={0x80,0x5B,0x1B,0x9B,0x9B,0xBF,0x80,0xF4,0x80,0xCB}; // OK
byte spipacket4[]={0x80,0x2F,0x06,0xBF,0x9B,0xEF,0xB5,0x80,0x80,0x97}; // OK
byte spipacket5[]={0xBA,0xDB,0xAD,0xBA,0xDB,0xAD,0xBA,0xDB,0xAD,0xBD}; // ERROR

// volcar dato hexadecimal formateado
void SerialPrintHex(unsigned char c) {
  if (c<0x10) Serial.print(0);
  Serial.print(c, HEX);
}

// construir CRC del paquete SPI
byte spiCRC(byte p[]) {
  return p[1]^p[2]^p[3]^p[4]^p[5]^p[6]^p[7]^0x40;
}

// validar un paquete SPI
bool spiValidPacket(byte p[]) {
  return (p[0]==0x80 && p[8]==0x80 && p[9]==spiCRC(p)?true:false);
}

// comprobar paquete SPI y mostrar por consola
void testPacket(byte p[]) {
  Serial.print("Packet: ");
  for (byte i=0;i<10;i++) {
    Serial.print(i?" ":"");
    SerialPrintHex(p[i]);
  }
  byte crc=spiCRC(p);
  Serial.print(" CRC: ");
  SerialPrintHex(crc);
  Serial.println(spiValidPacket(p)?" (OK)":" (ERROR)");
}

// setup
void setup() {

  Serial.begin(115200);

  testPacket(spipacket1);
  testPacket(spipacket2);
  testPacket(spipacket3);
  testPacket(spipacket4);
  testPacket(spipacket5);

}

// loop empty
void loop() {}

