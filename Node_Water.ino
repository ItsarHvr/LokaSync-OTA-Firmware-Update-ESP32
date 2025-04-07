#include <OneWire.h>
#include <DallasTemperature.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <HTTPClient.h>
#include <Update.h>

#define TdsSensorPin 34
#define VREF 3.3              // Analog reference voltage(Volt) of the ADC
#define SCOUNT  30            // Number of samples for averaging

#define ONE_WIRE_BUS 4        // DS18B20 data pin connected to GPIO4 (D4)

const char* ssid = "ANGGREK 08"; // Change this to your Local SSID
const char* password = "15052804"; // Change this to your WiFi/SSID password
const char* mqtt_server = "192.168.1.9";  // Change this to your EMQX server IP
const int mqtt_port = 1883;
const char* mqtt_topic_temp = "sensor/temperature";
const char* mqtt_topic_tds = "sensor/tds";
const char* mqtt_topic_ota = "OTA/Water_Node";

WiFiClient espClient;
PubSubClient client(espClient);
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);

int analogBuffer[SCOUNT];
int analogBufferTemp[SCOUNT];
int analogBufferIndex = 0;

float averageVoltage = 0;
float tdsValue = 0;
float temperature = 0;

void setup_wifi() {
  delay(10);
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());
}

void performOTAUpdate(String firmwareURL) {
  HTTPClient http;

  Serial.print("Downloading firmware from: ");
  Serial.println(firmwareURL);

  http.begin(firmwareURL);
  http.addHeader("User-Agent", "ESP32");

  int httpCode = http.GET();

  Serial.print("HTTP Response code: ");
  Serial.println(httpCode);

  if (httpCode == 302 || httpCode == 303) {
    String newURL = http.getLocation();
    Serial.print("Redirected to: ");
    Serial.println(newURL);

    http.end();
    http.begin(newURL);
    httpCode = http.GET();
    Serial.print("New HTTP Response code: ");
    Serial.println(httpCode);
  }

  if (httpCode == HTTP_CODE_OK) {
    int contentLength = http.getSize();
    if (contentLength <= 0) {
      Serial.println("❌ Invalid content length!");
      return;
    }

    bool canBegin = Update.begin(contentLength);
    if (!canBegin) {
      Serial.println("❌ Not enough space for OTA update!");
      return;
    }

    WiFiClient* stream = http.getStreamPtr();
    size_t written = Update.writeStream(*stream);
    if (written == contentLength) {
      Serial.println("✅ Firmware written successfully!");
    } else {
      Serial.println("❌ Firmware update failed!");
      return;
    }

    if (Update.end()) {
      Serial.println("✅ Update complete! Restarting...");
      ESP.restart();
    } else {
      Serial.println("❌ Update failed!");
    }
  } else {
    Serial.println("❌ Failed to download firmware! Check URL and internet.");
  }

  http.end();
}

void callback(char* topic, byte* payload, unsigned int length) {
  String message;
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }

  Serial.print("Message received on topic: ");
  Serial.println(topic);
  Serial.print("Payload: ");
  Serial.println(message);

  if (String(topic) == mqtt_topic_ota) {
    Serial.println("Starting OTA update...");
    performOTAUpdate(message);
  }
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    if (client.connect("ESP32Client")) {
      Serial.println("connected");
      client.subscribe(mqtt_topic_ota);
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
      delay(5000);
    }
  }
}

void setup() {
  Serial.begin(115200);
  setup_wifi();
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
  sensors.begin();
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  sensors.requestTemperatures();
  temperature = sensors.getTempCByIndex(0);

  int analogValue = analogRead(TdsSensorPin);
  analogBuffer[analogBufferIndex] = analogValue;
  analogBufferIndex++;
  if (analogBufferIndex == SCOUNT) analogBufferIndex = 0;

  for (int i = 0; i < SCOUNT; i++) {
    analogBufferTemp[i] = analogBuffer[i];
  }

  for (int i = 0; i < SCOUNT - 1; i++) {
    for (int j = i + 1; j < SCOUNT; j++) {
      if (analogBufferTemp[i] > analogBufferTemp[j]) {
        int temp = analogBufferTemp[i];
        analogBufferTemp[i] = analogBufferTemp[j];
        analogBufferTemp[j] = temp;
      }
    }
  }

  int median = analogBufferTemp[SCOUNT / 2];
  float voltage = median * (VREF / 4095.0);
  float compensationCoefficient = 1.0 + 0.02 * (temperature - 25.0);
  float compensationVoltage = voltage / compensationCoefficient;
  tdsValue = (133.42 * pow(compensationVoltage, 3) - 255.86 * pow(compensationVoltage, 2) + 857.39 * compensationVoltage) * 0.5;

  Serial.print("Temperature: ");
  Serial.print(temperature);
  Serial.print(" °C | TDS Value: ");
  Serial.print(tdsValue);
  Serial.println(" ppm");

  char tempStr[8];
  dtostrf(temperature, 6, 2, tempStr);
  client.publish(mqtt_topic_temp, tempStr);

  char tdsStr[8];
  dtostrf(tdsValue, 6, 2, tdsStr);
  client.publish(mqtt_topic_tds, tdsStr);

  delay(2000);
}
