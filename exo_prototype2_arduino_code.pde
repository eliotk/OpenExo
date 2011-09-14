#include <Servo.h>

const int analogInPin = A0;  // Analog input pin that the potentiometer is attached to - "sensorValue"
const int analogOutPin = 11; // Analog output pin that the LED is attached to
const int buttonPin = 2;
const int brakePin = 12;
const int powerKillPin = 8;

const int fsrReadingMin = 0;
const int fsrReadingMax = 400;
const int fsrReadingFirmPresh = fsrReadingMin+140;

int sensorValue = 0;        // value read from the pot
int outputValue = 0;        // value output to the PWM (analog out)

int buttonState = 0; 


// ideal is 450
int hipCenteredPosition = 350;

const int numReadings = 10;

int readings[numReadings];      // the readings from the analog input
int index = 0;                  // the index of the current reading
int total = 0;                  // the running total
int average = 0;                // the average

int fsrReading = 0;
Servo motorHip;
int motorHipPin = 11;

int fsrAnalogPin = 5;

// MODE SETUP
int mode = 3;
// MODE POT SWITCH
int modePotPin = 4;
int modeReading; 

void setup() {
  // initialize serial communications at 9600 bps:
  Serial.begin(9600); 
  pinMode(buttonPin, INPUT); 
  pinMode(8, INPUT); 
  
  // we're setting brake pin as input to avoid any digital writing for now
  pinMode(brakePin, INPUT);  
    for (int thisReading = 0; thisReading < numReadings; thisReading++)
      readings[thisReading] = 0;
  
  pinMode(motorHipPin, OUTPUT);
  motorHip.attach(motorHipPin,1000,2000);
  motorHip.write(93);
}

void loop() { 
  modeReading = analogRead(modePotPin);
  buttonState = digitalRead(buttonPin);
  // Serial.println(modeReading); 

  if( modeReading > 1010 && modeReading < 1024) {
    mode = 2;
  } else if( modeReading > 80 && modeReading < 120 ) {
    mode = 1;
  } else if( modeReading > 30 && modeReading < 65 ) {
    mode = 3;
  } else {
    mode = 0;
  }
  
    // what are we doing
    switch(mode) {
      case 0:
      break;
      case 1:
           standup();
      break;
      case 2:           
           checkKillButtonState();
           walk();
      break;
      case 3:
           // make sure brake is off
           brake(0);
           sitDown();
      break;
    }

  // read the analog in value:
  sensorValue = analogRead(analogInPin);


  fsrReading = analogRead(fsrAnalogPin); 

  total= total - readings[index];        
  // read from the sensor:  
  readings[index] = sensorValue;
   total= total + readings[index];      
  // advance to the next position in the array:  
  index = index + 1;                    

  // if we're at the end of the array...
  if (index >= numReadings)              
    // ...wrap around to the beginning:
    index = 0;                          

  // calculate the average:
  average = total / numReadings;          
  
  // map it to the range of the analog out:
  // outputValue = map(sensorValue, 0, 1023, 0, 255);  
  outputValue = average / 4;
}

void brake(int mode) {
  if( mode == 1 ) {
    // brake on
    analogWrite(brakePin, LOW);
  } else {
    // brake off
    pinMode(brakePin, INPUT);
  }
}

void walk() { 
  Serial.print("pot pos: " );
  Serial.println(sensorValue);
  
  Serial.print("\t fsr reading: " );
  Serial.println(fsrReading);
   
  // wait 10 milliseconds before the next loop
  // for the analog-to-digital converter to settle
  // after the last reading:
  delay(10);
  
    if( fsrReading > fsrReadingMin ) {
      brake(0);
      // let's map that reading to speed
      if( sensorValue <  hipCenteredPosition+300 ) {
        // move forward
        outputValue = map(fsrReading, fsrReadingMin, fsrReadingMax, 93,180);  
      } else {
        outputValue = 93;
        // brake(1); 
      }
    } else {
      // let's see where we are, if this is walking we want to come back down to standing
      if( sensorValue < (hipCenteredPosition-30)  ) {
        // we need to moveforward
        outputValue = 160; 
      } else if( sensorValue > (hipCenteredPosition+30) ) {
        // move backward
        outputValue = 20;
      } else {
        outputValue = 93;
        brake(1);
      }
    }

  motorHip.write(outputValue);
}

void sitDown() {
    // make sure we have a firm presh to initiate slight push out on hip  
    if( fsrReading > fsrReadingMin && sensorValue < (hipCenteredPosition+100)) {
        pinMode(powerKillPin, INPUT);
        // outputValue = 93;
        outputValue = map(fsrReading, fsrReadingMin, fsrReadingMax, 93,180);  
        motorHip.write(outputValue);
          
    } else {
        // let gravity do the rest
        analogWrite(powerKillPin, LOW);
        outputValue = 93;  
        motorHip.write(outputValue);
     }
    Serial.println(sensorValue);     
}

void standup() {
  // outputValue = 93;  
    if( fsrReading > fsrReadingMin ) {
      Serial.println("here");
      pinMode(powerKillPin, INPUT); 
      Serial.println(fsrReading);
      // let's map that reading to speed
      if( sensorValue >  hipCenteredPosition+50 ) {
        // pinMode(powerKillPin, INPUT);
        // stand up
        // outputValue = 10; 
        outputValue = map(fsrReading, fsrReadingMin, fsrReadingMax, 70,0);
      } else {
        outputValue = 93;
      }
      motorHip.write(outputValue);  
    } else {
      analogWrite(powerKillPin, LOW);
    } 
 
     motorHip.write(outputValue);    
}

void checkKillButtonState() {
  if (buttonState == HIGH) {     
    analogWrite(8, LOW);
  } 
  else {
    pinMode(8, INPUT);
  }
}
