//Library
#include "MQ7.h"
#include <MQ135.h>
#include <MQUnifiedsensor.h>


//Blynk
#define BLYNK_TEMPLATE_ID           "TMPL_B2TeIG5"                      //change with your
#define BLYNK_DEVICE_NAME           "Quickstart Template"               //change with your
#define BLYNK_AUTH_TOKEN            "ATHkhXhhwZzsq-anFiXaHH0V1BfDZBD8"  //change with your

#define BLYNK_PRINT Serial

#include <WiFi.h>
#include <WiFiClient.h>
#include <BlynkSimpleEsp32.h>

//library MQ135
#define Board ("ESP-32")
#define pin (33)              //PIN for MQ135
#define type ("MQ-135")
#define Voltage_Resolution (5)
#define ADC_Bit_Resolution (12)
#define RatioMQ135CleanAir 3.6//RS / R0 = 3.6 ppm 

#define MQ2pin (32)         //MQ2 Pin

#define A_PIN 35            //pin mq7
#define VOLTAGE 5 

#define Buzzer 12            //pin For buzzer
#define RELAY_PIN  27        //pin for relay

//koneksi ke wifi dan blynk
char auth[] = BLYNK_AUTH_TOKEN;
char ssid[] = "ssid";         //change with your
char pass[] = "password";     //change with your

//variabel 
float sensorValue2;  //variable to store sensor value
float CO2;
float CO;

MQUnifiedsensor MQ135(Board, Voltage_Resolution, ADC_Bit_Resolution, pin, type);
MQ7 mq7(A_PIN, VOLTAGE);

BlynkTimer timer;

//fungsi untuk blynk
void sendSensor()
{
  
   sensorValue2 = analogRead(MQ2pin); // read analog input pin 0  

   MQ135.update();          // Update data, the arduino will read the voltage from the analog pin
   MQ135.readSensor();      // Sensor will read PPM concentration using the model, a and b values set previously or from the setup
   CO2 = MQ135.readSensor();
   CO = mq7.readPpm();
   
   if((sensorValue2 > 1000)||(CO2> 100)||(CO > 100))
    {
    Blynk.logEvent("gas", "GAS Berbahaya Terdeteksi");
    }
  Blynk.virtualWrite(V6, CO);
  Blynk.virtualWrite(V7, sensorValue2);
  Blynk.virtualWrite(V8, CO2);
}

void setup()
{
  
  Serial.begin(9600); // sets the serial port to 9600
  
  Serial.println("Gas sensor warming up!");
  pinMode(MQ2pin, INPUT);
  
  Serial.println("Calibrating MQ7");
  mq7.calibrate();    // calculates R0
  Serial.println("Calibration done!");
  
  pinMode (Buzzer, OUTPUT);
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, HIGH);
  MQ135.setRegressionMethod(1); //_PPM =  a*ratio^b
  MQ135.setA(110.47); MQ135.setB(-2.862); // Configure the equation to to calculate CO2 concentration
  MQ135.init(); 

  
  Serial.print("Calibrating please wait.");
  float calcR0 = 0;
  for(int i = 1; i<=10; i ++)
  {
    MQ135.update(); // Update data, the arduino will read the voltage from the analog pin
    calcR0 += MQ135.calibrate(RatioMQ135CleanAir);
    Serial.print(".");
  }
  MQ135.setR0(calcR0/10);
  Serial.println("  done!.");
  
  Blynk.begin(auth, ssid, pass);
  timer.setInterval(1000L, sendSensor);
  delay(20000);
}


void loop(){
  Blynk.run();
    digitalWrite(RELAY_PIN, HIGH);
  Serial.print("Gas Value: ");
  Serial.println(sensorValue2);
  Serial.print("CO (ppm) = "); 
  Serial.println(mq7.readPpm());


  MQ135.update(); // Update data, the arduino will read the voltage from the analog pin
  MQ135.readSensor(); // Sensor will read PPM concentration using the model, a and b values set previously or from the setup
  CO2 = MQ135.readSensor();
  Serial.print("Co2: ");
  Serial.println(CO2);
  
   if((sensorValue2 > 1000)||(CO2> 100)||(CO > 100))
  {
  Serial.print(" | Smoke detected!");
  digitalWrite(Buzzer, HIGH);
  delay(5000);
  digitalWrite(Buzzer, LOW);
  delay(1000);


  digitalWrite(RELAY_PIN, LOW);  // turn off fan 10 seconds
  delay(10000);
  }
  
  Serial.println("");
  delay(1000);
  timer.run();
}
