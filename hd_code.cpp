#include <ESP8266WiFi.h>
#include <ThingSpeak.h>
#include <DHT.h>

#define DHTPIN D2     // Digital pin connected to the DHT sensor
#define DHTTYPE DHT11 // DHT 11
#define IRPIN D1      // Digital pin for IR sensor

const char* ssid = "YourWiFiSSID";
const char* password = "YourWiFiPassword";
const char* thingspeakApiKey = "YourThingSpeakAPIKey";

unsigned long channelID = 123456; // Your ThingSpeak channel ID
unsigned int tempField = 1;
unsigned int presenceField = 2;

WiFiClient client;
DHT dht(DHTPIN, DHTTYPE);

void setup() {
  Serial.begin(115200);
  pinMode(IRPIN, INPUT);
  dht.begin();
  
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("WiFi connected");
  
  ThingSpeak.begin(client);
}

void loop() {
  // Read temperature from DHT11
  float temp = dht.readTemperature();
  
  // Read IR sensor (0 = pen present, 1 = pen not present)
  int penPresent = digitalRead(IRPIN) == LOW ? 1 : 0;
  
  if (isnan(temp)) {
    Serial.println("Failed to read from DHT sensor!");
  } else {
    Serial.print("Temperature: ");
    Serial.print(temp);
    Serial.println(" °C");
    
    Serial.print("Pen present: ");
    Serial.println(penPresent ? "Yes" : "No");
    
    // Send data to ThingSpeak
    ThingSpeak.setField(tempField, temp);
    ThingSpeak.setField(presenceField, penPresent);
    
    int statusCode = ThingSpeak.writeFields(channelID, thingspeakApiKey);
    
    if(statusCode == 200) {
      Serial.println("Data push to ThingSpeak successful");
    } else {
      Serial.println("Problem pushing to ThingSpeak. HTTP error code " + String(statusCode));
    }
  }
  
  // Check for temperature threshold (2-8°C for insulin storage)
  if(temp > 8.0 || temp < 2.0) {
    // This would trigger a Firebase Cloud Message via your backend
    // In a real implementation, you'd call a web service here
    Serial.println("ALERT: Temperature out of range!");
  }
  
  delay(30000); // Wait 30 seconds between measurements
}
