// As long as Arduino receives char '1' via serial communication, 
// keep on emitting a TTL pulse at frequency 'ttl_freq', 
// with HIGH state lasting 'ttl_durHigh' microseconds.
// Switch pins to LOW if no char '1' is received within 'durRecvChar' milliseconds
// or if any char other than '1' is received.

const double ttl_freq    = 30; // Hz, TTL pulse frequency

const double ttl_durCycle = 1000000/ttl_freq; // us, TTL cycle duration
const double ttl_durHigh  = 2000; // us, TTL pulse HIGH state duration
const double ttl_durLow   = ttl_durCycle - ttl_durHigh; // us, TTL pulse LOW state duration

const int pinOut1 = 13;
const int pinOut2 = 52;
const int pinOut3 = 53;
const int durRecvChar = 500; // how many msec to wait without serial communication before switching off TTL

boolean TTLisON = false; // when TTLisON true, the TTL will cycle through its high and low states; when false TTL will stay Low.
char receivedChar;
char lastReceivedChar;
boolean newData = false;
unsigned long t_cycle  = micros(); // will store start of each cycle
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
  Serial.begin(115200); //115200
  while (!Serial) {
    ;
  }
  // Confirm connection
  Serial.println("#Arduino online");
}

void loop() {
  newData = false;
  recvOneChar(); 

  if (newData == true) {
    lastReceivedChar = receivedChar;
    newData = false;
    if (lastReceivedChar == '1') {
      // Start or reset timer for char received:
      t_serial = millis();
    }
    else if (lastReceivedChar != '1'){
      TTLisON = false;  
    }
  } 

  if (lastReceivedChar == '1' && ((millis()-t_serial) < durRecvChar)) {
    TTLisON = true;
  }
  else {
    TTLisON = false;
  }

  if (TTLisON == true) {
    
    while ((micros()-t_cycle) < ttl_durCycle) {
      ; // do nothing, just wait
    }
    t_cycle = micros();
    digitalWrite(pinOut1, HIGH);
    digitalWrite(pinOut2, HIGH);
    digitalWrite(pinOut3, HIGH);
    //Serial.println("LED turned on");
    delayMicroseconds(ttl_durHigh);
    digitalWrite(pinOut1, LOW);
    digitalWrite(pinOut2, LOW);
    digitalWrite(pinOut3, LOW);

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
        // t_serial = millis();
    }
}