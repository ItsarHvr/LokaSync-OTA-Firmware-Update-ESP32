#include <WiFi.h>
#include <PubSubClient.h>
#include <DHT.h>
#include <HTTPClient.h>
#include <Update.h>

#define DHTPIN 5
#define DHTTYPE DHT22
#define MAX_SSID 3
#define LOG_BUFFER 256

// WiFi list
const char* ssidList[MAX_SSID] = {"INDOMIE AYAM BAWANG", "ANGGREK 08", "INDOMIE SOTO"};
const char* passList[MAX_SSID] = {"agustus2023", "15052804", "123443211234"};

// MQTT config
const char* mqtt_server = "192.168.1.3";
const int mqtt_port = 1883;
const char* topic_dht = "sensor/DHT22";
const char* topic_ota = "OTA/Node-DHT";
const char* topic_log = "log/Node-DHT";

WiFiClient wifiClient;
PubSubClient client(wifiClient);
DHT dht(DHTPIN, DHTTYPE);

unsigned long lastLogTime = 0;

void publishLog(String msg) {
  char logMsg[LOG_BUFFER];
  snprintf(logMsg, LOG_BUFFER, "[%lu] %s", millis(), msg.c_str());
  Serial.println(logMsg);
  if (client.connected()) {
    client.publish(topic_log, logMsg);
  }
}

void connectToWiFi() {
  for (int i = 0; i < MAX_SSID; i++) {
    WiFi.begin(ssidList[i], passList[i]);
    Serial.printf("Trying WiFi: %s\n", ssidList[i]);

    for (int j = 0; j < 10; j++) {
      if (WiFi.status() == WL_CONNECTED) {
        Serial.println("✅ WiFi connected");
        return;
      }
      delay(500);
    }
  }
  Serial.println("❌ WiFi failed, restarting...");
  delay(3000);
  ESP.restart();
}

void reconnectMQTT() {
  int attempts = 0;
  while (!client.connected() && attempts < 5) {
    String clientId = "ESP32_Node_DHT_" + String(random(0xffff), HEX);
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

  // Handle HTTP Redirect
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
    publishLog("❌ Failed to download firmware (bad HTTP code)");
    http.end();
    return;
  }

  int contentLength = http.getSize();
  if (contentLength <= 0) {
    publishLog("❌ Invalid content length!");
    http.end();
    return;
  }

  snprintf(logMsg, sizeof(logMsg), "📦 Firmware size: %d bytes (%.2f KB)", contentLength, contentLength / 1024.0);
  publishLog(logMsg);

  if (!Update.begin(contentLength)) {
    publishLog("❌ Not enough space for OTA update!");
    http.end();
    return;
  }

  stream = http.getStreamPtr();

  unsigned long downloadStart = millis();
  size_t written = Update.writeStream(*stream);
  unsigned long downloadTime = millis() - downloadStart;

  if (written != contentLength) {
    snprintf(logMsg, sizeof(logMsg), "❌ Download mismatch: got %d bytes, expected %d", written, contentLength);
    publishLog(logMsg);
    http.end();
    return;
  }

  snprintf(logMsg, sizeof(logMsg), "⏬ Download completed in %.2f seconds", downloadTime / 1000.0);
  publishLog(logMsg);

  float downloadSpeed = (contentLength / 1024.0) / (downloadTime / 1000.0);
  snprintf(logMsg, sizeof(logMsg), "🚀 Download speed: %.2f KB/s", downloadSpeed);
  publishLog(logMsg);

  unsigned long flashStart = millis();
  if (!Update.end()) {
    snprintf(logMsg, sizeof(logMsg), "❌ Flash failed: %s", Update.errorString());
    publishLog(logMsg);
    http.end();
    return;
  }
  unsigned long flashTime = millis() - flashStart;
  snprintf(logMsg, sizeof(logMsg), "🔥 Firmware flash completed in %.2f seconds", flashTime / 1000.0);
  publishLog(logMsg);

  unsigned long totalTime = millis() - otaStart;
  snprintf(logMsg, sizeof(logMsg), "✅ OTA update complete in %.2f seconds", totalTime / 1000.0);
  publishLog(logMsg);

  http.end();
  delay(1000);  // Allow logs to be sent
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
  dht.begin();
  connectToWiFi();
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
  reconnectMQTT();
  publishLog("🔋 Node-DHT booted and ready");
}

void loop() {
  if (!client.connected()) reconnectMQTT();
  client.loop();

  static unsigned long lastSensorTime = 0;
  if (millis() - lastSensorTime > 5000) {
    lastSensorTime = millis();

    float temp = dht.readTemperature();
    float hum = dht.readHumidity();

    if (!isnan(temp) && !isnan(hum)) {
      // ✅ Serial Monitor print
      Serial.printf("🌡️  Temp: %.2f °C | 💧 Hum: %.2f %%\n", temp, hum);

      // ✅ MQTT publish
      String payload = String(temp, 2) + "," + String(hum, 2);
      client.publish(topic_dht, payload.c_str());
    } else {
      publishLog("❌ DHT read failed");
    }
  }
}
