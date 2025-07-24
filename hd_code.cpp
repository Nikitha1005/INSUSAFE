#include <SoftwareSerial.h>
#include <DHT.h>

#define DHTPIN 2
#define DHTTYPE DHT11
#define IR_SENSOR 3

DHT dht(DHTPIN, DHTTYPE);
SoftwareSerial esp(10, 11); // RX, TX

String apiKey = "YOUR_THINGSPEAK_WRITE_KEY";

void setup() {
  Serial.begin(9600);
  esp.begin(9600);
  dht.begin();
  pinMode(IR_SENSOR, INPUT);
}

void loop() {
  float temp = dht.readTemperature();
  int pen = digitalRead(IR_SENSOR);

  String data = "GET /update?api_key=" + apiKey +
                "&field1=" + String(pen) +
                "&field2=" + String(temp) +
                " HTTP/1.1\r\nHost: api.thingspeak.com\r\nConnection: close\r\n\r\n";

  esp.print("AT+CIPSTART=\"TCP\",\"api.thingspeak.com\",80\r\n");
  delay(2000);
  esp.print("AT+CIPSEND="); esp.println(data.length());
  delay(2000);
  esp.print(data);
  delay(20000); // Send every 20s
}
