#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <Wire.h>
#include <DHT.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include "MAX30105.h"
#include "spo2_algorithm.h"

/* WIFI */
#define WIFI_SSID "YOUR WIFI_SSID"
#define WIFI_PASSWORD "YOUR WIFI_PASSWORD"

/* FIREBASE */
#define API_KEY "your API_KEY"
#define DATABASE_URL "your DATABASE_URL"

/* FIREBASE */
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

void setup()
{

Serial.begin(115200);
delay(2000);

Serial.println("SafeSense System Start");

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

auth.user.email = "";
auth.user.password = "";

Firebase.begin(&config, &auth);
Firebase.reconnectWiFi(true);

Serial.println("Firebase started");

/* I2C */

Wire.begin();

/* DHT */

dht.begin();

/* MPU6050 */

if (!mpu.begin(0x68))
{
Serial.println("MPU6050 not detected");
}
else
{
Serial.println("MPU6050 Ready");
}

/* MAX30102 */

if (!particleSensor.begin(Wire, I2C_SPEED_FAST))
{
Serial.println("MAX30102 not detected");
}
else
{
Serial.println("MAX30102 Ready");
}

particleSensor.setup();
particleSensor.setPulseAmplitudeRed(0x0A);
particleSensor.setPulseAmplitudeGreen(0);

}

void loop()
{

/* TEMPERATURE + HUMIDITY */

float temperature = dht.readTemperature();
float humidity = dht.readHumidity();

/* MPU6050 */

sensors_event_t a, g, temp;
mpu.getEvent(&a, &g, &temp);

float ax = a.acceleration.x;
float ay = a.acceleration.y;
float az = a.acceleration.z;

/* FALL DETECTION */

float totalAcc = sqrt(ax*ax + ay*ay + az*az);

bool fallDetected = false;

if(totalAcc > 20)
fallDetected = true;

/* MAX30102 */

for (byte i = 0 ; i < BUFFER_SIZE ; i++)
{
while (particleSensor.available() == false)
particleSensor.check();

redBuffer[i] = particleSensor.getRed();
irBuffer[i] = particleSensor.getIR();

particleSensor.nextSample();
}

maxim_heart_rate_and_oxygen_saturation(
irBuffer,
BUFFER_SIZE,
redBuffer,
&spo2,
&validSPO2,
&heartRate,
&validHeartRate
);

/* SEND TO FIREBASE */

if (Firebase.ready())
{

Firebase.RTDB.setFloat(&fbdo,"SafeSense/temperature",temperature);
Firebase.RTDB.setFloat(&fbdo,"SafeSense/humidity",humidity);

Firebase.RTDB.setFloat(&fbdo,"SafeSense/accX",ax);
Firebase.RTDB.setFloat(&fbdo,"SafeSense/accY",ay);
Firebase.RTDB.setFloat(&fbdo,"SafeSense/accZ",az);

Firebase.RTDB.setBool(&fbdo,"SafeSense/fall",fallDetected);

if(validHeartRate)
Firebase.RTDB.setInt(&fbdo,"SafeSense/heartRate",heartRate);

if(validSPO2)
Firebase.RTDB.setInt(&fbdo,"SafeSense/spo2",spo2);

Serial.println("Data sent to Firebase");

}

delay(5000);

}