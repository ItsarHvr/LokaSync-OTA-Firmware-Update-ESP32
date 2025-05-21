#include <WiFi.h>
#include <esp_now.h>
#include <esp_wifi.h>
#include <Update.h>
#include <DHT.h>
#include "mbedtls/base64.h"

#define DHTPIN 5
#define DHTTYPE DHT22
#define OTA_COMPLETE_TIMEOUT 10000
#define OTA_CHUNK_SIZE 240

DHT dht(DHTPIN, DHTTYPE);

bool receivingFirmware = false;
unsigned long lastChunkTime = 0;
size_t totalWritten = 0;

uint8_t internetNodeMac[6] = {0x14, 0x2B, 0x2F, 0xC1, 0xEB, 0x9C};  // Adjust if needed

void sendACK(bool success) {
  const char* ack = success ? "ACK OK" : "ACK FAIL";
  esp_now_send(internetNodeMac, (uint8_t*)ack, strlen(ack));
}

bool decodeBase64(String input, uint8_t* output, size_t* outputLen) {
  int ret = mbedtls_base64_decode(
    output, *outputLen, outputLen,
    (const uint8_t*)input.c_str(), input.length()
  );
  return ret == 0;
}

void onDataRecv(const esp_now_recv_info_t* info, const uint8_t* data, int len) {
  memcpy(internetNodeMac, info->src_addr, 6);

  // Convert data into a String
  String base64Chunk = "";
  for (int i = 0; i < len; i++) base64Chunk += (char)data[i];

  uint8_t binChunk[OTA_CHUNK_SIZE];
  size_t binLen = sizeof(binChunk);
  if (!decodeBase64(base64Chunk, binChunk, &binLen)) {
    Serial.println("❌ Base64 decode failed!");
    sendACK(false);
    return;
  }

  if (!receivingFirmware) {
    if (!Update.begin(UPDATE_SIZE_UNKNOWN)) {
      Serial.println("❌ Update.begin failed");
      sendACK(false);
      return;
    }
    receivingFirmware = true;
    totalWritten = 0;
  }

  size_t written = Update.write(binChunk, binLen);
  if (written != binLen) {
    Serial.printf("❌ Update.write failed: %s\n", Update.errorString());
    Update.abort();
    receivingFirmware = false;
    sendACK(false);
    return;
  }

  totalWritten += written;
  lastChunkTime = millis();
  Serial.printf("⬇️ Written %d bytes, total=%d\n", written, totalWritten);
  sendACK(true);
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
