// As long as Arduino receives char '1' via serial communication, 
// keep the digital pins on HIGH.
// Switch pins to LOW if no char '1' is received within 'durRecvChar' milliseconds
// or if any char other than '1' is received.

const int pinOut1 = 13;
const int pinOut2 = 52;
const int pinOut3 = 53;
const int durRecvChar = 500; // how many msec to wait without serial communication before switching off TTL

boolean TTLisON = false;
char receivedChar;
boolean newData = false;
unsigned long t0 = millis(); // will store time char is received

void setup() {
  pinMode(pinOut1, OUTPUT);
  digitalWrite(pinOut1, LOW);
  pinMode(pinOut2, OUTPUT);
  digitalWrite(pinOut2, LOW);
  pinMode(pinOut3, OUTPUT);
  digitalWrite(pinOut3, LOW);
  // Open serial communications and wait for port to open:
  // This requires RX and TX channels (pins 0 and 1)
  // wait for serial port to connect. Needed for native USB port only
  Serial.begin(14400); //115200
  while (!Serial) {
    ;
  }
  // Confirm connection
  Serial.println("#Arduino online");
}

void loop() {
  newData = false;
  recvOneChar();


  if (newData == true && receivedChar == '1') {

    digitalWrite(pinOut1, HIGH);
    digitalWrite(pinOut2, HIGH);
    digitalWrite(pinOut3, HIGH);
    //Serial.println("LED turned on");
    newData = false;
    TTLisON = true;
  }
  else if (newData == true && receivedChar == '0') {
    digitalWrite(pinOut1, LOW);
    digitalWrite(pinOut2, LOW);
    digitalWrite(pinOut3, LOW);
    //Serial.println("LED turned off");
    newData = false;
    TTLisON = false;
  }
  else if (newData == true && (receivedChar != '0' && receivedChar != '1')) {
    digitalWrite(pinOut1, LOW);
    digitalWrite(pinOut2, LOW);
    digitalWrite(pinOut3, LOW);
    //Serial.println("LED turned off");
    newData = false;
    TTLisON = false;
  }

  if (TTLisON == true && ((millis()-t0) >= durRecvChar)) {
    digitalWrite(pinOut1, LOW);
    digitalWrite(pinOut2, LOW);
    digitalWrite(pinOut3, LOW);
    TTLisON = false;
  }

}


void recvOneChar() {
    // while (Serial.available()<1) {
    // //delayMicroseconds(1)
    // }
    if (Serial.available() > 0) {
        receivedChar = Serial.read();
        newData = true;
        t0 = millis();
    }
}