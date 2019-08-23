unsigned char test[]={
  0x10, 0x02, 0x17, 0x34, 0x20, 0x20, 0x42, 0x41, 0x53, 0x53, 
  0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x2B, 0x33, 0x00, 0x00, 
  0x00, 0x02, 0x11, 0x00, 0x00, 0x00, 0x10, 0x03, 0x38, 0x10, 
  0x02, 0x15, 0x30, 0x01, 0x00, 0x00, 0x22, 0x0B, 0x01, 0x02, 
  0xFF, 0x91, 0x30, 0x40, 0x02, 0x43, 0x55, 0x41, 0x52, 0x45, 
  0x4E, 0x54, 0x41, 0x10, 0x03, 0x1A, 0x10, 0x02, 0x15, 0x30, 
  0x01, 0x00, 0x00, 0x22, 0x0B, 0x01, 0x02, 0xFF, 0x91, 0x30, 
  0x40, 0x03, 0x43, 0x55, 0x41, 0x52, 0x45, 0x4E, 0x54, 0x41, 
  0x10, 0x03, 0x1A, 0x10, 0x02, 0x15, 0x30, 0x01, 0x00, 0x00, 
  0x22, 0x0B, 0x01, 0x02, 0xFF, 0x91, 0x30, 0x40, 0x03, 0x43, 
  0x55, 0x41, 0x52, 0x45, 0x4E, 0x54, 0x41, 0x10, 0x03, 0x1A, 
  0x10, 0x02, 0x15, 0x30, 0x01, 0x00, 0x00, 0x22, 0x0B, 0x01, 
  0x03, 0xFF, 0x91, 0x30, 0x40, 0x03, 0x43, 0x55, 0x41, 0x52, 
  0x45, 0x4E, 0x54, 0x41, 0x10, 0x03, 0x1A, 0x10, 0x02, 0x15, 
  0x30, 0x01, 0x00, 0x00, 0x22, 0x0B, 0x01, 0x03, 0xFF, 0x91, 
  0x30, 0x40, 0x03, 0x43, 0x55, 0x41, 0x52, 0x45, 0x4E, 0x54, 
  0x41, 0x10, 0x03, 0x1A, 0x10, 0x02, 0x15, 0x30, 0x01, 0x00, 
  0x00, 0x22, 0x0B, 0x01, 0x03, 0xFF, 0x91, 0x30, 0x40, 0x03, 
  0x43, 0x55, 0x41, 0x52, 0x45, 0x4E, 0x54, 0x41, 0x10, 0x03, 
  0x1A, 0x10, 0x02, 0x08, 0x30, 0x00, 0x00, 0x00, 0x00, 0x00, 
  0xFF, 0xFF, 0x10, 0x03, 0x2B, 0x10, 0x02, 0x09, 0x32, 0x00, 
  0x00, 0x00, 0x02, 0x03, 0x00, 0x00, 0xBE, 0x10, 0x03, 0x96, 
  0x10, 0x02, 0x08, 0x30, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 
  0xFF, 0x10, 0x03, 0x2B, 0x10, 0x02, 0x05, 0x3A, 0x01, 0x17, 
  0x01, 0x04, 0x10, 0x03, 0x3F, 0x10, 0x02, 0x08, 0x30, 0x00, 
  0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0x10, 0x03, 0x2B, 0x10, 
  0x02, 0x15, 0x30, 0x01, 0x00, 0x00, 0x22, 0x0B, 0x01, 0x03, 
  0xFF, 0x91, 0x30, 0x40, 0x03, 0x43, 0x55, 0x41, 0x52, 0x45, 
  0x4E, 0x54, 0x41, 0x10, 0x03, 0x1A
};

void setup() {
  Serial.begin(19200);
}

void loop() {
  int i;
  for (i=0;i<sizeof(test);i++) {
    Serial.write(test[i]);
    delay(1+test[i]/10);
  }
  delay(500);
}
