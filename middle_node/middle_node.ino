// Middle Node: Receives firmware via ESP-NOW, flashes, and can forward to edge nodes
#include <WiFi.h>
#include <esp_now.h>
#include <esp_wifi.h>
#include <DHT.h>
#include <Update.h>

#define DHTPIN 5
#define DHTTYPE DHT22
#define LOG_BUFFER 256
#define OTA_COMPLETE_TIMEOUT 10000
#define OTA_CHUNK_SIZE 240
#define ENABLE_FORWARDING false // Set true if you want to forward to edge nodes

// Edge node MACs (add more if needed)
uint8_t edgePeers[][6] = {
  {0xCC, 0xDB, 0xA7, 0x16, 0xCF, 0xA5}
};
const size_t NUM_EDGE_PEERS = sizeof(edgePeers) / sizeof(edgePeers[0]);
uint8_t crc8(const uint8_t* data, size_t len) {
  uint8_t crc = 0x00;
  while (len--) {
    uint8_t extract = *data++;
    for (uint8_t tempI = 8; tempI; tempI--) {
      uint8_t sum = (crc ^ extract) & 0x01;
      crc >>= 1;
      if (sum) crc ^= 0x8C;
      extract >>= 1;
    }
  }
  return crc;
}
// ...existing includes and defines...
DHT dht(DHTPIN, DHTTYPE);

bool otaInProgress = false;
bool receivingFirmware = false;
bool otaError = false; // <-- NEW: track OTA error state
unsigned long lastChunkTime = 0;
size_t totalWritten = 0;

uint8_t internetNodeMac[6];

void publishESPNow(String prefix, String msg) {
  String full = prefix + msg;
  Serial.println("📤 " + full);
  esp_now_send(internetNodeMac, (uint8_t*)full.c_str(), full.length());
}

void sendSensorData() {
  float t = dht.readTemperature();
  float h = dht.readHumidity();
  if (isnan(t) || isnan(h)) {
    publishESPNow("LOG:", "❌ DHT read failed");
    return;
  }
  char payload[64];
  snprintf(payload, sizeof(payload), "DATA:{\"temp\":%.2f,\"hum\":%.2f}", t, h);
  publishESPNow("", String(payload));
}

void forwardChunkToPeers(const uint8_t* data, size_t len) {
  for (size_t i = 0; i < NUM_EDGE_PEERS; i++) {
    esp_now_send(edgePeers[i], data, len);
    delay(10); // more reliable, less aggressive
  }
}

void finalizeOTA() {
  publishESPNow("LOG:", "📦 Firmware complete, finalizing...");
  Serial.printf("Finalizing OTA. Update.hasError()=%d\n", Update.hasError());
  if (Update.end()) {
    publishESPNow("LOG:", "✅ Firmware flashed! Restarting...");
    Serial.println("✅ Firmware flashed! Restarting...");
    delay(1000);
    ESP.restart();
  } else {
    String err = Update.errorString();
    publishESPNow("LOG:", "❌ Update.end() failed: " + err);
    Serial.printf("❌ Update.end() failed: %s\n", err.c_str());
  }
  otaInProgress = false;
  receivingFirmware = false;
  otaError = false;
  totalWritten = 0;
}

void abortOTA() {
  publishESPNow("LOG:", "❌ OTA aborted due to error. Awaiting new firmware push.");
  Serial.println("❌ OTA aborted due to error. Awaiting new firmware push.");
  otaInProgress = false;
  receivingFirmware = false;
  otaError = true;
  totalWritten = 0;
  Update.abort();
}

void onDataRecv(const esp_now_recv_info_t* info, const uint8_t* incomingData, int len) {
  memcpy(internetNodeMac, info->src_addr, 6);

  // Detect binary OTA or text
  bool isBinary = false;
  for (int i = 0; i < len; i++) {
    if (incomingData[i] < 32 || incomingData[i] > 126) {
      isBinary = true;
      break;
    }
  }

if (isBinary) {
    if (len < 2) return; // too short to be valid
    uint8_t receivedCRC = incomingData[len - 1];
    uint8_t calcCRC = crc8(incomingData, len - 1);
    if (receivedCRC != calcCRC) {
      publishESPNow("LOG:", "❌ CRC mismatch, chunk dropped");
      Serial.printf("❌ CRC mismatch: got %02X, expected %02X\n", receivedCRC, calcCRC);
      // Optionally: count errors, abort if too many, or just ignore this chunk
      return;
    }
    // If previous OTA failed, ignore until new session
    if (otaError) {
      Serial.println("Ignoring chunk: OTA previously aborted, waiting for new session.");
      return;
    }
    otaInProgress = true;
    if (!receivingFirmware) {
      bool ok = Update.begin(UPDATE_SIZE_UNKNOWN);
      Serial.printf("Update.begin() called, result=%d, free heap=%u\n", ok, ESP.getFreeHeap());
      if (!ok) {
        publishESPNow("LOG:", "❌ Update.begin failed");
        Serial.printf("❌ Update.begin failed: %s\n", Update.errorString());
        abortOTA();
        return;
      }
      receivingFirmware = true;
      totalWritten = 0;
    }
    size_t written = Update.write((uint8_t*)incomingData, len - 1); // Only write data, not CRC
    Serial.printf("Update.write(len=%d) returned %d, error=%s, free heap=%u\n", len, written, Update.errorString(), ESP.getFreeHeap());
    if (written != len) {
      publishESPNow("LOG:", "❌ Chunk write failed");
      Serial.printf("❌ Chunk write failed: written=%d, expected=%d, error=%s\n", written, len, Update.errorString());
      abortOTA();
      return;
    }
    totalWritten += written;
    Serial.printf("⬇️  Written chunk (%d bytes), totalWritten=%d\n", len, totalWritten);
    lastChunkTime = millis();
  } else {
    String msg = "";
    for (int i = 0; i < len; i++) msg += (char)incomingData[i];
    Serial.println("📥 Received msg: " + msg);
    // If you want to allow a remote reset of OTA error, you could check for a special command here.
  }
}

void initESPNow() {
  WiFi.mode(WIFI_STA);
  if (esp_now_init() != ESP_OK) {
    Serial.println("❌ ESP-NOW Init Failed");
    ESP.restart();
  }
  esp_now_register_recv_cb(onDataRecv);
  for (size_t i = 0; i < NUM_EDGE_PEERS; i++) {
    esp_now_peer_info_t peerInfo = {};
    memcpy(peerInfo.peer_addr, edgePeers[i], 6);
    peerInfo.channel = 0;
    peerInfo.encrypt = false;
    if (!esp_now_is_peer_exist(edgePeers[i])) {
      esp_now_add_peer(&peerInfo);
    }
  }
  Serial.println("✅ ESP-NOW initialized");
}

void setup() {
  Serial.begin(115200);
  dht.begin();
  initESPNow();
  Serial.println("📡 Middle Node Ready");
}

unsigned long lastSensorTime = 0;

void loop() {
  if (!otaInProgress && millis() - lastSensorTime > 5000) {
    lastSensorTime = millis();
    sendSensorData();
  }
  if (receivingFirmware && millis() - lastChunkTime > OTA_COMPLETE_TIMEOUT) {
    receivingFirmware = false;
    Serial.println("📦 Firmware streaming done!");
    publishESPNow("LOG:", "📦 Firmware complete, finalizing...");
    finalizeOTA();
  }
}