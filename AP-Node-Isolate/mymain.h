// mymain.h

#ifndef MYMAIN_H
#define MYMAIN_H

#include <WebServer.h>
extern WebServer server;

// GPIO Definitions
#define TEST_LED 2
#define TEST_ADC 34
#define TEST_TOUCH 4

unsigned long previousMillis = 0;
const long blinkInterval = 5000;
bool ledState = false;

void MySetup(WebServer &srv) {
  Serial.begin(115200);
  Serial.println("\n🔧 ESP32 Universal Test Firmware (OTA Enabled)");

  // LED Pin Setup
  pinMode(TEST_LED, OUTPUT);
  digitalWrite(TEST_LED, LOW);

  // ADC & Touch Setup
  pinMode(TEST_ADC, INPUT);  // optional for ADC
  // touch pins don't need pinMode

  Serial.println("✅ Test Pins Setup Complete");
}

void MyLoop(WebServer &srv) {
  // Blink LED (non-blocking)
  unsigned long currentMillis = millis();
  if (currentMillis - previousMillis >= blinkInterval) {
    previousMillis = currentMillis;
    ledState = !ledState;
    digitalWrite(TEST_LED, ledState);
  }

  // Read ADC
  int adcValue = analogRead(TEST_ADC);
  Serial.print("📊 ADC (GPIO 34): ");
  Serial.println(adcValue);

  // Read Touch
  int touchValue = touchRead(TEST_TOUCH);
  Serial.print("✋ Touch (GPIO 4): ");
  Serial.println(touchValue);

  delay(1000);
}

#endif
