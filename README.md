# LokaSync Android App

This app is used to monitor some IoT nodes in real-time. Currently, we've connected two nodes: **an ESP32 with a DHT11 sensor (node 1)** and an **ESP32 with a TDS sensor (node 2)**. This app is built with Flutter and is **still in the development phase**. Actually, the main purpose of this app is to monitor the status of updated firmware in IoT devices (ESP32), whether it's success or failure.

## Usage

### Clone this repository

```bash
git clone https://github.com/ItsarHvr/LokaSync-OTA.git
```

### Run with Flutter

- **Make sure you've setup Flutter and Android Studio** correctly. Refer to the official documentation: "[Set up Flutter](https://docs.flutter.dev/get-started/install)".
- Optionally, if you will run this app android emu, you can **enable VM acceleration** to boost the emu performance.
- Or, if you will run this app in physical device, don't forget to **enable USB debugging**.
- If no issues found, then run with the following commands.

```bash
# First, make sure you're in the `android-dev` branch.
git checkout android-dev

# [Optional] Check for available emulators
flutter emulators

# [Optional] Check for available devices
flutter devices

# Run the app
flutter run
```

### Run natively in IOS/Android

- Currently, we're only provide an APK file for Android, so sorry for IOS users.
- Like other APK files, just download the APK and install it on your emulator or real phone. Calm down, we're not putting shellcode, backdoor, or anything malicious code inside the APK file. 😅

## TODO

- [X] Login Page
- [ ] Registration Page
- [ ] Reset Password Page
- [ ] Home Page
- [ ] Monitoring Page
- [ ] Profile Page

## Credits

- Thanks to ChatGPT for the background and logo.
- Thanks to GitHub Copilot for helped me a lot during development phase.
