// As long as Arduino receives char '1' via serial communication, 
// keep on emitting a TTL pulse at frequency 'ttl_freq', 
// with HIGH state lasting 'ttl_durHigh' milliseconds.
// Switch pins to LOW if no char '1' is received within 'durRecvChar' milliseconds
// or if any char other than '1' is received.

const unsigned long ttl_freq    = 50; // Hz, TTL pulse frequency

const int           ttl_durHigh =  2; // ms, TTL pulse HIGH state duration
const unsigned long ttl_durLow  = 1000/ttl_freq - ttl_durHigh;

const int pinOut1 = 13;
const int pinOut2 = 52;
const int pinOut3 = 53;
const int durRecvChar = 500; // how many msec to wait without serial communication before switching off TTL

boolean TTLisON = false; // when TTLisON true, the TTL will cycle through its high and low states; when false TTL will stay Low.
char receivedChar;
boolean newData = false;
unsigned long t_low    = millis(); // will store onset time Low state (==offset High state)
unsigned long t_serial = millis(); // will store time char is received


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
    // Start or reset timer for char received:
    t_serial = millis();
    newData = false;
  }
  if (((millis()-t_serial) < durRecvChar)) {
    TTLisON = true;
  }
  else {
    TTLisON = false;
  }

  if (TTLisON == true) {
    
    while ((millis()-t_low) < ttl_durLow) {
      ; // do nothing, just wait
    }
    digitalWrite(pinOut1, HIGH);
    digitalWrite(pinOut2, HIGH);
    digitalWrite(pinOut3, HIGH);
    //Serial.println("LED turned on");
    delay(ttl_durHigh);
    digitalWrite(pinOut1, LOW);
    digitalWrite(pinOut2, LOW);
    digitalWrite(pinOut3, LOW);
    // delay(ttl_durLow);
    t_low = millis();

  }
  else { // if (TTLisON == false)
    digitalWrite(pinOut1, LOW);
    digitalWrite(pinOut2, LOW);
    digitalWrite(pinOut3, LOW);
  }
}

void recvOneChar() {
    // while (Serial.available()<1) {
    // //delayMicroseconds(1)
    // }
    if (Serial.available() > 0) {
        receivedChar = Serial.read();
        newData = true;
        t_serial = millis();
    }
}