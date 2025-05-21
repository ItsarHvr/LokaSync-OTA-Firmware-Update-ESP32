#include <WiFi.h>
#include <esp_now.h>
#include <Update.h>

#define OTA_CHUNK_SIZE 240
#define OTA_COMPLETE_TIMEOUT 10000  // 10 seconds

bool receiving = false;
unsigned long lastChunkTime = 0;
size_t totalWritten = 0;

void onDataRecv(const esp_now_recv_info_t* info, const uint8_t* data, int len) {
  if (len == 0) {
    // End of transmission signal
    Serial.println("📦 Firmware received. Finalizing...");
    if (Update.end()) {
      Serial.println("✅ OTA Success! Restarting...");
      delay(1000);
      ESP.restart();
    } else {
      Serial.printf("❌ OTA finalize failed: %s\n", Update.errorString());
    }
    receiving = false;
    totalWritten = 0;
    return;
  }

  if (!receiving) {
    if (!Update.begin(UPDATE_SIZE_UNKNOWN)) {
      Serial.printf("❌ Update.begin failed: %s\n", Update.errorString());
      return;
    }
    receiving = true;
    totalWritten = 0;
    Serial.println("🚀 OTA started (no ACK mode)");
  }

  size_t written = Update.write((uint8_t*)data, len);
  if (written != (size_t)len) {
    Serial.printf("❌ Write failed at %d bytes\n", totalWritten);
    Update.abort();
    receiving = false;
    return;
  }

  totalWritten += written;
  lastChunkTime = millis();

  Serial.printf("⬇️ Received chunk (%d bytes), total=%d\n", len, totalWritten);
}

void setup() {
  Serial.begin(115200);
  WiFi.mode(WIFI_STA);

  if (esp_now_init() != ESP_OK) {
    Serial.println("❌ ESP-NOW Init failed");
    ESP.restart();
  }

  esp_now_register_recv_cb(onDataRecv);
  Serial.println("📡 Middle Node Ready (no ACK)");
}

void loop() {
  if (receiving && millis() - lastChunkTime > OTA_COMPLETE_TIMEOUT) {
    Serial.println("⏳ OTA timeout. Aborting...");
    Update.abort();
    receiving = false;
    totalWritten = 0;
  }
}
