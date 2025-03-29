// This file is .ino file of OTA-WiFi.ino.bin firmware we used to test the OTA via GitHuB. This firmware will not work on any other Network. 
#include <WiFi.h>
#include <PubSubClient.h>
#include <HTTPClient.h>
#include <Update.h>

const char* ssid = "INDOMIE AYAM BAWANG";
const char* password = "agustus2023";
const char* mqtt_server = "192.168.1.9";  // Change this to your EMQX server IP
const int mqtt_port = 1883;

const char* topic_ota = "OTA/Node-DHT";     // OTA update commands

WiFiClient wifiClient;
PubSubClient client(wifiClient);

// Function to download and apply firmware update
void performOTAUpdate(String firmwareURL) {
    HTTPClient http;
    http.begin(firmwareURL);
    int httpCode = http.GET();

    if (httpCode == HTTP_CODE_OK) {
        int contentLength = http.getSize();
        if (contentLength <= 0) {
            Serial.println("Invalid content length");
            return;
        }

        bool canBegin = Update.begin(contentLength);
        if (!canBegin) {
            Serial.println("Not enough space for OTA update");
            return;
        }

        WiFiClient* stream = http.getStreamPtr();
        size_t written = Update.writeStream(*stream);
        if (written == contentLength) {
            Serial.println("Firmware written successfully!");
        } else {
            Serial.println("Firmware update failed!");
            return;
        }

        if (Update.end()) {
            Serial.println("Update complete! Restarting...");
            ESP.restart();
        } else {
            Serial.println("Update failed!");
        }
    } else {
        Serial.println("Failed to download firmware!");
    }

    http.end();
}

// Callback for incoming MQTT messages
void callback(char* topic, byte* payload, unsigned int length) {
    String message;
    for (int i = 0; i < length; i++) {
        message += (char)payload[i];
    }

    Serial.print("Message received on topic: ");
    Serial.println(topic);
    Serial.print("Payload: ");
    Serial.println(message);

    // If OTA update message received
    if (String(topic) == topic_ota) {
        Serial.println("Starting OTA update...");
        performOTAUpdate(message);
    }
}

void setupWiFi() {
    Serial.print("Connecting to WiFi...");
    WiFi.begin(ssid, password);
    while (WiFi.status() != WL_CONNECTED) {
        delay(1000);
        Serial.print(".");
    }
    Serial.println("\nWiFi connected!");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
}

void reconnectMQTT() {
    while (!client.connected()) {
        Serial.print("Connecting to MQTT Broker...");
        if (client.connect("ESP32_OTA_Wifi")) {
            Serial.println("Connected!");
            client.subscribe(topic_ota);  // Listen for OTA updates
        } else {
            Serial.print("Failed, rc=");
            Serial.print(client.state());
            Serial.println(" Retrying in 5 seconds...");
            delay(5000);
        }
    }
}

void setup() {
    Serial.begin(115200);
    setupWiFi();
    client.setServer(mqtt_server, mqtt_port);
    client.setCallback(callback);
    reconnectMQTT();
}

void loop() {
    if (!client.connected()) {
        reconnectMQTT();
    }
    client.loop();
    delay(5000);

}
