// This file is .ino file of ESP32-Universal-Test_Firmware.ino.bin firmware file.
// That firmware (.bin) file will run on most ESP32 as tests for it's LED, ADC, and Touch sensor.
#include <Arduino.h>
// Define test GPIOs
#define TEST_LED 2       // Most ESP32 boards have a built-in LED on GPIO 2
#define TEST_ADC 34      // GPIO 34 is an ADC pin
#define TEST_TOUCH 4     // GPIO 4 is a touch sensor input

void setup() {
    Serial.begin(115200);
    Serial.println("\n🔧 ESP32 Simple Test Firmware 🔧");

    // 1️⃣ Blink LED Setup
    pinMode(TEST_LED, OUTPUT);
    Serial.println("✅ LED Test: Blinking GPIO 2...");

    // 2️⃣ ADC Test
    pinMode(TEST_ADC, INPUT);
    Serial.println("✅ ADC Test: Reading from GPIO 34...");

    // 3️⃣ Touch Sensor Test
    Serial.println("✅ Touch Sensor Test: Touch GPIO 4 to test...");

    // 4️⃣ Display Chip Info
    Serial.println("\n🔍 ESP32 Chip Information:");
    Serial.printf("Chip Model: %s\n", ESP.getChipModel());
    Serial.printf("Chip Cores: %d\n", ESP.getChipCores());
    Serial.printf("Revision: %d\n", ESP.getChipRevision());
    Serial.printf("Flash Size: %d bytes\n", ESP.getFlashChipSize());

    delay(2000);
}

void loop() {
    // 1️⃣ Blink LED Test
    digitalWrite(TEST_LED, HIGH);
    delay(500);
    digitalWrite(TEST_LED, LOW);
    delay(500);

    // 2️⃣ ADC Read Test
    int adcValue = analogRead(TEST_ADC);
    Serial.print("📊 ADC (GPIO 34) Value: ");
    Serial.println(adcValue);

    // 3️⃣ Touch Sensor Test
    int touchValue = touchRead(TEST_TOUCH);
    Serial.print("✋ Touch Sensor (GPIO 4) Value: ");
    Serial.println(touchValue);

    delay(1000);
}
