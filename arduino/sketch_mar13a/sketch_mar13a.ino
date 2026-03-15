#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <Wire.h>
#include <DHT.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include "MAX30105.h"
#include "spo2_algorithm.h"

/* WIFI */
#define WIFI_SSID "TOPNETD989728F"
#define WIFI_PASSWORD "856E9F3C33"

/* FIREBASE */
#define API_KEY "AIzaSyBPmCVN4pjcT8yCeIJaZuapndeiE6PoYcw"
#define DATABASE_URL "https://safesense-df3ee-default-rtdb.europe-west1.firebasedatabase.app/"

/* Firebase */
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

/* DHT */
#define DHTPIN 4
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);

/* MPU6050 */
Adafruit_MPU6050 mpu;

/* MAX30102 */
MAX30105 particleSensor;

#define BUFFER_SIZE 100
uint32_t irBuffer[BUFFER_SIZE];
uint32_t redBuffer[BUFFER_SIZE];

int32_t spo2;
int8_t validSPO2;

int32_t heartRate;
int8_t validHeartRate;

/* MOVING AVERAGE */
#define FILTER_SIZE 5

int hrBuffer[FILTER_SIZE];
int spo2Buffer[FILTER_SIZE];
int filterIndex = 0;

/* LOW PASS FILTER */

float filteredHR = 0;
float filteredSPO2 = 0;
float alpha = 0.3;

/* AVERAGE FUNCTION */

int average(int *buffer)
{
  int sum = 0;
  for(int i=0;i<FILTER_SIZE;i++)
  sum += buffer[i];

  return sum/FILTER_SIZE;
}

void setup()
{

Serial.begin(115200);
delay(2000);

/* WIFI */

WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

Serial.print("Connecting WiFi");

while (WiFi.status() != WL_CONNECTED)
{
delay(500);
Serial.print(".");
}

Serial.println("\nWiFi Connected");

/* FIREBASE */

config.api_key = API_KEY;
config.database_url = DATABASE_URL;

auth.user.email = "selmichaima04@gmail.com";
auth.user.password = "chmayadodo2004";

Firebase.begin(&config,&auth);
Firebase.reconnectWiFi(true);

Serial.println("Firebase Ready");

/* I2C */

Wire.begin();

/* DHT */

dht.begin();

/* MPU6050 */

if(!mpu.begin(0x68))
{
Serial.println("MPU6050 not detected");
}
else
{
Serial.println("MPU6050 Ready");
}

/* MAX30102 */

if(!particleSensor.begin(Wire,I2C_SPEED_FAST))
{
Serial.println("MAX30102 not detected");
while(1);
}

particleSensor.setup();
particleSensor.setPulseAmplitudeRed(0x0A);
particleSensor.setPulseAmplitudeGreen(0);

}

/* LOOP */

void loop()
{

/* DHT DATA */

float temperature = dht.readTemperature();
float humidity = dht.readHumidity();

/* MPU6050 DATA */

sensors_event_t a,g,temp;
mpu.getEvent(&a,&g,&temp);

float ax = a.acceleration.x;
float ay = a.acceleration.y;
float az = a.acceleration.z;

/* FALL DETECTION */

float totalAcc = sqrt(ax*ax + ay*ay + az*az);

bool fallDetected = false;

if(totalAcc > 20)
fallDetected = true;

/* MAX30102 READING */

for(byte i=0;i<BUFFER_SIZE;i++)
{
while(particleSensor.available()==false)
particleSensor.check();

redBuffer[i] = particleSensor.getRed();
irBuffer[i] = particleSensor.getIR();

particleSensor.nextSample();
}

/* FINGER DETECTION */

if(irBuffer[BUFFER_SIZE-1] < 50000)
{
Serial.println("No finger detected");
delay(2000);
return;
}

/* CALCULATE HR + SPO2 */

maxim_heart_rate_and_oxygen_saturation(
irBuffer,
BUFFER_SIZE,
redBuffer,
&spo2,
&validSPO2,
&heartRate,
&validHeartRate
);

/* MOVING AVERAGE */

hrBuffer[filterIndex] = heartRate;
spo2Buffer[filterIndex] = spo2;

filterIndex++;

if(filterIndex >= FILTER_SIZE)
filterIndex = 0;

int avgHR = average(hrBuffer);
int avgSPO2 = average(spo2Buffer);

/* LOW PASS FILTER */

filteredHR = alpha * avgHR + (1-alpha)*filteredHR;
filteredSPO2 = alpha * avgSPO2 + (1-alpha)*filteredSPO2;

/* SERIAL OUTPUT */

Serial.println("\nSensor Data");

Serial.print("Temperature: ");
Serial.println(temperature);

Serial.print("Humidity: ");
Serial.println(humidity);

Serial.print("AX: ");
Serial.println(ax);

Serial.print("AY: ");
Serial.println(ay);

Serial.print("AZ: ");
Serial.println(az);

Serial.print("HeartRate: ");
Serial.println(filteredHR);

Serial.print("SpO2: ");
Serial.println(filteredSPO2);

/* SEND DATA TO FIREBASE */

if(Firebase.ready())
{

Firebase.RTDB.setFloat(&fbdo,"SafeSense/temperature",temperature);
Firebase.RTDB.setFloat(&fbdo,"SafeSense/humidity",humidity);

Firebase.RTDB.setFloat(&fbdo,"SafeSense/accX",ax);
Firebase.RTDB.setFloat(&fbdo,"SafeSense/accY",ay);
Firebase.RTDB.setFloat(&fbdo,"SafeSense/accZ",az);

Firebase.RTDB.setBool(&fbdo,"SafeSense/fall",fallDetected);

Firebase.RTDB.setFloat(&fbdo,"SafeSense/heartRate",filteredHR);
Firebase.RTDB.setFloat(&fbdo,"SafeSense/spo2",filteredSPO2);

Serial.println("Data sent to Firebase");

}

delay(5000);

}