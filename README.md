
# 🧠 WashSentinel

**Smart Laundry Security System | IoT + Mobile + Cloud**

---

## Overview

WashSentinel is an **IoT-based laundry security device** designed to prevent theft and unauthorized access in shared laundry spaces such as dorms and laundromats. Each sensor unit uses an **ESP32 microcontroller** and **motion/angle detection** to identify when a washer or dryer is opened unexpectedly, sending instant alerts to a **Flutter mobile app** via **Wi-Fi** and **Firebase Cloud Messaging**.

The goal: eliminate the need to “guard your laundry” by giving users peace of mind through real-time visibility and security.

---

## Features

* **BLE Provisioning:** Seamless Wi-Fi setup through Espressif’s BLE + Security1 protocol.
* **Wi-Fi Connectivity:** Sends alerts and updates via Firebase once connected.
* **Motion Detection:** MPU6050 IMU monitors angular velocity to detect unauthorized openings.
* **Dual Alert System:**

  * Local beeper on device for immediate deterrence.
  * Remote notification to app for real-time user alert.
* **Low-Power Design:** Enters sleep mode until triggered, extending battery life.
* **Failsafe Logic:** Re-alert and power control handled through firmware and app integration.
* **Expandable Architecture:** Supports optional central hub (motherboard) for business-level deployments.

---

## System Architecture

```
[ESP32 Sensor Unit]  <--->  [Flutter Mobile App]  <--->  [Firebase Cloud]
        |                                 |
     BLE Setup                      Realtime Alerts
        |
  Wi-Fi Provisioning
```

---

## Hardware

| Component         | Description                                           |
| ----------------- | ----------------------------------------------------- |
| **ESP32-D0WD-V3** | Dual-core 240 MHz microcontroller with BLE + Wi-Fi    |
| **MPU6050**       | 6-axis accelerometer and gyroscope for motion sensing |
| **Buzzer**        | Audible alert when unauthorized motion is detected    |
| **Power Source**  | Li-ion battery (optimized via sleep mode)             |

---

## Firmware Highlights (ESP32)

* Written in **C++ (Arduino SDK v5.4.1)**
* Handles BLE provisioning, Wi-Fi connection, and IMU-based intrusion logic
* Persistent credential storage in flash memory
* Configurable `/active` and `/armed` states via HTTP endpoints
* Compatible with Firebase Realtime Database for alert synchronization

---

## Mobile App (Flutter)

* Developed with **Flutter + Dart**
* Uses **flutter_reactive_ble** for BLE provisioning
* Displays device status (online/offline, armed/disarmed)
* Sends test alerts and controls buzzer/power remotely
* Integrates **Firebase Authentication + Realtime Database**

---

## Future Expansion

* **Motherboard Hub:** Centralized alert management for institutional laundry rooms
* **QR-Based Setup:** Simplify device pairing via unique QR code
* **Enhanced Alerts:** Add voice output or LED indicators for security escalation
* **Data Analytics Dashboard:** Monitor device uptime and event logs

---

## Getting Started

### Hardware Setup

1. Flash ESP32 with the latest WashSentinel firmware.
2. Power on the device and wait for BLE advertisement (“WashSentinel”).
3. Use the mobile app to provision Wi-Fi credentials.
4. Once connected, the ESP32 automatically sends alerts to Firebase.

### Software Setup

#### ESP32 Firmware

```bash
git clone https://github.com/yourusername/WashSentinel-Firmware.git
```

Flash via Arduino IDE or PlatformIO.
Ensure dependencies:

* `WiFi.h`
* `WiFiProv.h`
* `Wire.h`
* `Firebase_ESP_Client.h`
* `Adafruit_MPU6050.h`

#### Flutter App

```bash
git clone https://github.com/yourusername/WashSentinel-App.git
cd WashSentinel-App
flutter pub get
flutter run
```

---

## Awards & Recognition

🏆 **Invent@SU 2025 — 1st Place Winner ($4,000 Award)**
Developed and presented to a panel of CEOs, engineers, and faculty judges at Syracuse University’s Invent@SU competition.

---

## Contact

For collaboration or press inquiries:
📧 **[contact@washsentinel.com](mailto:contact@washsentinel.com)**
🌐 [LinkedIn](https://linkedin.com/company/washsentinel) | [Invent@SU](https://launchpad.syr.edu)

---

Would you like me to generate a **version tailored for public investors/startup competitions** (more branding + story tone) or keep this **engineering-focused GitHub version** as is?
