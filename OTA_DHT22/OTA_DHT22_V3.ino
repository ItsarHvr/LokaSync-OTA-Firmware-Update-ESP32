#include <WiFi.h>
#include <PubSubClient.h>
#include <DHT.h>
#include <HTTPClient.h>
#include <Update.h>
#include <ArduinoJson.h>

#define DHTPIN 5
#define DHTTYPE DHT22
#define MAX_SSID 3

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

void publishJsonLog(const char* type, const char* message, JsonObject data = JsonObject()) {
  StaticJsonDocument<512> doc;
  doc["timestamp"] = millis();
  doc["type"] = type;
  doc["message"] = message;
  if (!data.isNull()) {
    doc["data"] = data;
  }

  char buffer[512];
  serializeJson(doc, buffer);
  Serial.println(buffer);
  if (client.connected()) {
    client.publish(topic_log, buffer);
  }
}

void connectToWiFi() {
  for (int i = 0; i < MAX_SSID; i++) {
    WiFi.begin(ssidList[i], passList[i]);
    Serial.printf("Trying WiFi: %s\n", ssidList[i]);

    for (int j = 0; j < 10; j++) {
      if (WiFi.status() == WL_CONNECTED) {
        publishJsonLog("system", "✅ WiFi connected");
        return;
      }
      delay(500);
    }
  }
  publishJsonLog("system", "❌ WiFi failed, restarting...");
  delay(3000);
  ESP.restart();
}

void reconnectMQTT() {
  int attempts = 0;
  while (!client.connected() && attempts < 5) {
    String clientId = "ESP32_Node_DHT_" + String(random(0xffff), HEX);
    if (client.connect(clientId.c_str())) {
      publishJsonLog("system", "✅ MQTT connected");
      client.subscribe(topic_ota);
    } else {
      attempts++;
      delay(3000);
    }
  }
  if (!client.connected()) {
    publishJsonLog("system", "❌ MQTT failed, restarting...");
    ESP.restart();
  }
}

void performOTAUpdate(String firmwareURL) {
  HTTPClient http;
  WiFiClient* stream;

  publishJsonLog("ota", "🔄 OTA update started");

  http.begin(firmwareURL);
  http.addHeader("User-Agent", "ESP32");
  int httpCode = http.GET();

  if (httpCode == 302 || httpCode == 303) {
    String redirectURL = http.getLocation();
    publishJsonLog("ota", "🔁 Redirected", [redirectURL](JsonObject obj) {
      obj["redirectURL"] = redirectURL;
    });
    http.end();
    http.begin(redirectURL);
    httpCode = http.GET();
  }

  if (httpCode != HTTP_CODE_OK) {
    publishJsonLog("ota", "❌ Failed to download firmware (bad HTTP code)");
    http.end();
    return;
  }

  int contentLength = http.getSize();
  if (contentLength <= 0) {
    publishJsonLog("ota", "❌ Invalid content length!");
    http.end();
    return;
  }

  StaticJsonDocument<64> meta;
  meta["size_kb"] = contentLength / 1024.0;
  publishJsonLog("ota", "📦 Firmware size OK", meta.as<JsonObject>());

  if (!Update.begin(contentLength)) {
    publishJsonLog("ota", "❌ Not enough space for OTA update!");
    http.end();
    return;
  }

  stream = http.getStreamPtr();
  size_t written = Update.writeStream(*stream);

  if (written != contentLength) {
    StaticJsonDocument<64> mismatch;
    mismatch["written"] = written;
    mismatch["expected"] = contentLength;
    publishJsonLog("ota", "❌ Download mismatch", mismatch.as<JsonObject>());
    http.end();
    return;
  }

  publishJsonLog("ota", "✅ Download complete");

  if (!Update.end()) {
    publishJsonLog("ota", "❌ Flash failed");
    http.end();
    return;
  }

  publishJsonLog("ota", "✅ OTA update complete");
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
  dht.begin();
  connectToWiFi();
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
  reconnectMQTT();
  publishJsonLog("system", "🔋 Node-DHT booted and ready");
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
      StaticJsonDocument<128> data;
      data["temperature"] = temp;
      data["humidity"] = hum;

      char payload[128];
      serializeJson(data, payload);
      client.publish(topic_dht, payload);

      publishJsonLog("sensor", "✅ Temperature and Humidity sent", data.as<JsonObject>());
    } else {
      publishJsonLog("sensor", "❌ DHT read failed");
    }
  }
}
