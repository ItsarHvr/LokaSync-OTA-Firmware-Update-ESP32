#include <WiFi.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <PubSubClient.h>
#include <HTTPClient.h>
#include <Update.h>

#define ONE_WIRE_BUS 4
#define TdsSensorPin 34
#define VREF 3.3
#define SCOUNT 30
#define MAX_SSID 3
#define LOG_BUFFER 256

const char* ssidList[MAX_SSID] = {"INDOMIE AYAM BAWANG", "ANGGREK 08", "INDOMIE SOTO"};
const char* passList[MAX_SSID] = {"agustus2023", "15052804", "123443211234"};

const char* mqtt_server = "192.168.1.9";
const int mqtt_port = 1883;

const char* topic_temp = "sensor/temperature";
const char* topic_tds = "sensor/tds";
const char* topic_ota = "OTA/Water_Node";
const char* topic_log = "log/Water_Node";

WiFiClient wifiClient;
PubSubClient client(wifiClient);
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);

int analogBuffer[SCOUNT];
int analogBufferTemp[SCOUNT];
int analogBufferIndex = 0;

float temperature = 0;
float tdsValue = 0;
char logBuffer[LOG_BUFFER];

void publishLog(const String& msg) {
  snprintf(logBuffer, LOG_BUFFER, "[%lu] %s", millis(), msg.c_str());
  Serial.println(logBuffer);
  if (client.connected()) {
    client.publish(topic_log, logBuffer);
  }
}

void connectToWiFi() {
  WiFi.mode(WIFI_STA);
  for (int i = 0; i < MAX_SSID; i++) {
    WiFi.disconnect(true);
    delay(100);
    WiFi.begin(ssidList[i], passList[i]);
    Serial.printf("🔍 Trying WiFi: %s\n", ssidList[i]);

    for (int j = 0; j < 15; j++) {
      if (WiFi.status() == WL_CONNECTED) {
        Serial.println("✅ WiFi connected");
        Serial.print("📡 IP Address: "); Serial.println(WiFi.localIP());
        return;
      }
      delay(500);
      Serial.print(".");
    }
    Serial.println("\n❌ Failed to connect");
  }

  Serial.println("🚨 Restarting after WiFi fail");
  delay(2000);
  ESP.restart();
}

void reconnectMQTT() {
  int attempts = 0;
  while (!client.connected() && attempts < 5) {
    String clientId = "ESP32_Water_Node_" + String(random(0xffff), HEX);
    if (client.connect(clientId.c_str())) {
      publishLog("✅ MQTT connected");
      client.subscribe(topic_ota);
    } else {
      Serial.print(".");
      attempts++;
      delay(3000);
    }
  }
  if (!client.connected()) {
    publishLog("❌ MQTT failed, restarting...");
    ESP.restart();
  }
}

void performOTAUpdate(String firmwareURL) {
  HTTPClient http;
  WiFiClient* stream;
  char logMsg[256];

  publishLog("🔄 OTA update started");
  snprintf(logMsg, sizeof(logMsg), "Requesting: %s", firmwareURL.c_str());
  publishLog(logMsg);

  unsigned long otaStart = millis();

  http.begin(firmwareURL);
  http.addHeader("User-Agent", "ESP32");
  int httpCode = http.GET();

  snprintf(logMsg, sizeof(logMsg), "HTTP Response Code: %d", httpCode);
  publishLog(logMsg);

  if (httpCode == 302 || httpCode == 303) {
    String redirectURL = http.getLocation();
    snprintf(logMsg, sizeof(logMsg), "🔁 Redirected to: %s", redirectURL.c_str());
    publishLog(logMsg);

    http.end();
    http.begin(redirectURL);
    httpCode = http.GET();
    snprintf(logMsg, sizeof(logMsg), "New HTTP Response Code: %d", httpCode);
    publishLog(logMsg);
  }

  if (httpCode != HTTP_CODE_OK) {
    publishLog("❌ Failed to download firmware");
    http.end();
    return;
  }

  int contentLength = http.getSize();
  if (contentLength <= 0) {
    publishLog("❌ Invalid content length");
    http.end();
    return;
  }

  snprintf(logMsg, sizeof(logMsg), "📦 Firmware size: %d bytes (%.2f KB)", contentLength, contentLength / 1024.0);
  publishLog(logMsg);

  if (!Update.begin(contentLength)) {
    publishLog("❌ Not enough space for OTA update");
    http.end();
    return;
  }

  stream = http.getStreamPtr();

  unsigned long downloadStart = millis();
  size_t written = Update.writeStream(*stream);
  unsigned long downloadTime = millis() - downloadStart;

  if (written != contentLength) {
    snprintf(logMsg, sizeof(logMsg), "❌ Write mismatch: %d vs %d", written, contentLength);
    publishLog(logMsg);
    http.end();
    return;
  }

  snprintf(logMsg, sizeof(logMsg), "⏬ Download completed in %.2f seconds", downloadTime / 1000.0);
  publishLog(logMsg);

  float downloadSpeed = (contentLength / 1024.0) / (downloadTime / 1000.0);
  snprintf(logMsg, sizeof(logMsg), "🚀 Speed: %.2f KB/s", downloadSpeed);
  publishLog(logMsg);

  unsigned long flashStart = millis();
  if (!Update.end()) {
    snprintf(logMsg, sizeof(logMsg), "❌ Flash failed: %s", Update.errorString());
    publishLog(logMsg);
    http.end();
    return;
  }

  unsigned long flashTime = millis() - flashStart;
  snprintf(logMsg, sizeof(logMsg), "🔥 Flash completed in %.2f seconds", flashTime / 1000.0);
  publishLog(logMsg);

  unsigned long totalTime = millis() - otaStart;
  snprintf(logMsg, sizeof(logMsg), "✅ OTA done in %.2f seconds", totalTime / 1000.0);
  publishLog(logMsg);

  http.end();
  delay(1000);
  ESP.restart();
}

void callback(char* topic, byte* payload, unsigned int length) {
  String msg;
  for (int i = 0; i < length; i++) msg += (char)payload[i];
  if (String(topic) == topic_ota) {
    performOTAUpdate(msg);
  }
}

void setup() {
  Serial.begin(115200);
  connectToWiFi();
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
  reconnectMQTT();
  sensors.begin();
  publishLog("💧 Water_Node ready");
}

void loop() {
  if (!client.connected()) reconnectMQTT();
  client.loop();

  sensors.requestTemperatures();
  temperature = sensors.getTempCByIndex(0);

  int analogValue = analogRead(TdsSensorPin);
  analogBuffer[analogBufferIndex] = analogValue;
  analogBufferIndex++;
  if (analogBufferIndex == SCOUNT) analogBufferIndex = 0;

  memcpy(analogBufferTemp, analogBuffer, sizeof(analogBuffer));
  std::sort(analogBufferTemp, analogBufferTemp + SCOUNT);

  int median = analogBufferTemp[SCOUNT / 2];
  float voltage = median * (VREF / 4095.0);
  float compensation = 1.0 + 0.02 * (temperature - 25.0);
  float compVoltage = voltage / compensation;

  tdsValue = (133.42 * pow(compVoltage, 3) - 255.86 * pow(compVoltage, 2) + 857.39 * compVoltage) * 0.5;

  char tempStr[8], tdsStr[8];
  dtostrf(temperature, 6, 2, tempStr);
  dtostrf(tdsValue, 6, 2, tdsStr);

  client.publish(topic_temp, tempStr);
  client.publish(topic_tds, tdsStr);

  Serial.printf("🌡️  Temp: %s °C | 💧 TDS: %s ppm\n", tempStr, tdsStr);

  delay(5000);
}
