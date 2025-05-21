#include <WiFi.h>
#include <esp_now.h>
#include <esp_wifi.h>
#include <Update.h>
#include <DHT.h>

#define DHTPIN 5
#define DHTTYPE DHT22
#define OTA_COMPLETE_TIMEOUT 100000
#define OTA_CHUNK_SIZE 240

DHT dht(DHTPIN, DHTTYPE);
bool receivingFirmware = false;
bool otaError = false;
unsigned long lastChunkTime = 0;
size_t totalWritten = 0;

uint8_t internetNodeMac[6] = {0x14, 0x2B, 0x2F, 0xC1, 0xEB, 0x9C};

uint8_t crc8(const uint8_t* data, size_t len) {
  uint8_t crc = 0x00;
  while (len--) {
    uint8_t extract = *data++;
    for (uint8_t i = 8; i; --i) {
      uint8_t sum = (crc ^ extract) & 0x01;
      crc >>= 1;
      if (sum) crc ^= 0x8C;
      extract >>= 1;
    }
  }
  return crc;
}

void publishESPNow(String prefix, String msg) {
  String full = prefix + msg;
  Serial.println("📤 " + full);
  esp_now_send(internetNodeMac, (uint8_t*)full.c_str(), full.length());
}

void onDataRecv(const esp_now_recv_info_t* info, const uint8_t* data, int len) {
  memcpy(internetNodeMac, info->src_addr, 6);

  bool isBinary = (len > 2);
  if (isBinary) {
    uint8_t receivedCRC = data[len - 1];
    uint8_t calcCRC = crc8(data, len - 1);
    if (receivedCRC != calcCRC) {
      Serial.println("❌ CRC mismatch, chunk ignored");
      return;
    }

    if (!receivingFirmware) {
      if (!Update.begin(UPDATE_SIZE_UNKNOWN)) {
        Serial.println("❌ Update.begin failed");
        return;
      }
      receivingFirmware = true;
      totalWritten = 0;
    }

    size_t written = Update.write((uint8_t*)data, len - 1);
    if (written != len - 1) {
      Serial.println("❌ Update.write failed");
      receivingFirmware = false;
      Update.abort();
      return;
    }
    totalWritten += written;
    lastChunkTime = millis();
    Serial.printf("⬇️ Written %d bytes, total=%d\n", written, totalWritten);
  } else {
    String msg = "";
    for (int i = 0; i < len; i++) msg += (char)data[i];
    Serial.println("📥 Text received: " + msg);
  }
}

void initESPNow() {
  WiFi.mode(WIFI_STA);
  if (esp_now_init() != ESP_OK) {
    Serial.println("❌ ESP-NOW Init Failed");
    ESP.restart();
  }
  esp_now_register_recv_cb(onDataRecv);
  Serial.println("✅ ESP-NOW ready");
}

void setup() {
  Serial.begin(115200);
  dht.begin();
  initESPNow();
  Serial.println("📡 Middle Node Ready");
}

void loop() {
  if (receivingFirmware && millis() - lastChunkTime > OTA_COMPLETE_TIMEOUT) {
    receivingFirmware = false;
    Serial.println("📦 Firmware complete, finalizing...");
    if (Update.end()) {
      Serial.println("✅ Firmware flashed, rebooting...");
      delay(1000);
      ESP.restart();
    } else {
      Serial.printf("❌ Update.end failed: %s\n", Update.errorString());
    }
  }
}
