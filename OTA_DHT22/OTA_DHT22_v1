#include <WiFi.h>
#include <PubSubClient.h>
#include <DHT.h>
#include <HTTPClient.h>
#include <Update.h>

#define DHTPIN 5
#define DHTTYPE DHT22

const char* ssid = "INDOMIE AYAM BAWANG"; // Change this to your Local SSID
const char* password = "agustus2023"; // Change this to your WiFi/SSID password
const char* mqtt_server = "192.168.1.9";  // Change this to your EMQX server IP
const int mqtt_port = 1883;

const char* topic_dht = "sensor/DHT22";     // Publishing DHT22 data
const char* topic_ota = "OTA/Node-DHT";     // OTA update commands

WiFiClient wifiClient;
PubSubClient client(wifiClient);
DHT dht(DHTPIN, DHTTYPE);

// Function to download and apply firmware update
void performOTAUpdate(String firmwareURL) {
    HTTPClient http;
    
    Serial.print("Downloading firmware from: ");
    Serial.println(firmwareURL);

    http.begin(firmwareURL);
    http.addHeader("User-Agent", "ESP32");  // Some servers require a user-agent

    int httpCode = http.GET();

    Serial.print("HTTP Response code: ");
    Serial.println(httpCode);

    // Handle redirects (302, 303)
    if (httpCode == 302 || httpCode == 303) {
        String newURL = http.getLocation(); // Get the redirected URL
        Serial.print("Redirected to: ");
        Serial.println(newURL);

        http.end(); // Close previous connection
        http.begin(newURL); // Open new connection
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
        if (client.connect("ESP32_OTA_DHT")) {
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
    dht.begin();
}

void loop() {
    if (!client.connected()) {
        reconnectMQTT();
    }
    client.loop();

    float temperature = dht.readTemperature();
    float humidity = dht.readHumidity();

    if (!isnan(temperature) && !isnan(humidity)) {
        Serial.print("Temperature: ");
        Serial.print(temperature);
        Serial.print("°C | Humidity: ");
        Serial.print(humidity);
        Serial.println(" %");

        char tempStr[8], humStr[8];
        dtostrf(temperature, 6, 2, tempStr);
        dtostrf(humidity, 6, 2, humStr);
        client.publish(topic_dht, (String(tempStr) + "," + String(humStr)).c_str());
    } else {
        Serial.println("Failed to read DHT sensor!");
    }

    delay(5000);
}
