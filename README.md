<div align="center">

# 📱 Intelligent Bike Parking & Anti‑Theft App

Smart mobility for cyclists, powered by Flutter, FastAPI, and ESP32 provisioning.

</div>

## Table of contents

1. [Overview](#overview)
2. [Core features](#core-features)
3. [System architecture](#system-architecture)
4. [BLE + Wi-Fi provisioning flow](#ble--wi-fi-provisioning-flow)
5. [Getting started](#getting-started)
6. [Configuration reference](#configuration-reference)
7. [Project structure](#project-structure)
8. [Development tooling](#development-tooling)
9. [Roadmap](#roadmap)
10. [Contributing](#contributing)

## Overview

The Intelligent Bike Parking & Anti-Theft App delivers a seamless experience for riders and parking agents. Cyclists can monitor their bikes in real time, provision ESP32-based hardware over BLE, discover secure parking, and manage payments. Agents can list parking slots, administer bookings, and keep the fleet organised.

The mobile app is built with **Flutter (Dart 3.8)** for iOS/Android, backed by **FastAPI** services, Firebase messaging, and embedded ESP32 firmware.

## Core features

### For bike owners

- 🔐 **Anti-theft monitoring** – Motion and tamper events trigger push notifications.
- 📍 **Live GPS tracking** – View current position, route history, and geo-fencing alerts.
- 📡 **BLE provisioning** – Connect to ESP32 hardware, scan for Wi-Fi, and push credentials securely.
- 🅿️ **Smart parking discovery** – Reserve verified parking slots and manage active bookings.
- � **Payments (WIP)** – Stripe integration for future pay-per-use parking.

### For parking agents

- 🗂️ **Parking inventory** – Publish slots, adjust availability, and review requests.
- 📊 **Operational dashboards** – Occupancy trends, earnings summaries, and customer insights.
- 🔔 **Real-time notifications** – Booking updates and maintenance alerts sent via Firebase Cloud Messaging.

### Hardware integration

- � **Wi-Fi / LTE backhaul** – ESP32 communicates telemetry to FastAPI endpoints.
- 🔋 **Solar-powered enclosure** – Sustains long-term deployments with minimal maintenance.
- 🛰️ **GPS + sensors** – Location, heartbeat, vibration, and mode data exposed to the app.

## System architecture

```
┌──────────────────────────┐
│ Flutter Mobile App       │
│  • Owners & Agents       │
│  • BLE Provisioning      │
│  • Maps & Telemetry UI   │
└────────────┬─────────────┘
						 │ HTTPS / WebSockets
┌────────────▼─────────────┐
│ FastAPI Backend           │
│  • Auth & JWT             │
│  • Parking + Booking APIs │
│  • Telemetry ingestion    │
└────────────┬─────────────┘
						 │ MQTT / REST
┌────────────▼─────────────┐
│ ESP32 Device              │
│  • BLE provisioning svc   │
│  • Wi-Fi connectivity     │
│  • GPS / Sensors          │
│  • Solar + Battery Mgmt   │
└──────────────────────────┘
```

## BLE + Wi-Fi provisioning flow

1. **Scan & pair** – The app searches for ESP32 devices broadcasting the provisioning service (`0000ffff-0000-1000-8000-00805f9b34fb`).
2. **Discover endpoints** – `Esp32ProvisioningService` caches provisioning characteristics, falling back to UUID heuristics when descriptors are missing.
3. **Wi-Fi network scan** – Users trigger a scan, displaying RSSI, security mode, and channel info for nearby access points.
4. **Credential delivery** – Pick a broadcast network or enter hidden SSIDs manually; credentials are sent via BLE with automatic “apply” requests.
5. **Fallback compatibility** – If the provisioning firmware lacks custom endpoints, the app reverts to the legacy BLE characteristic write to keep older hardware functional.

See `lib/services/esp32_provisioning_service.dart` and `lib/users/Wifiprovisioningpage.dart` for reference implementations.

## Getting started

### Prerequisites

- **Flutter 3.24+** (Dart 3.8.x) – confirm with `flutter --version`.
- **Android Studio / Xcode** – platform SDKs and emulators.
- **Firebase project** with Cloud Messaging enabled (copy generated `google-services.json` & `GoogleService-Info.plist`).
- **FastAPI backend** running locally or remotely (see project docs for endpoints).
- **ESP32 provisioning firmware** built with ESP-IDF Wi-Fi provisioning service.

### Clone & install dependencies

```powershell
git clone https://github.com/CO3302Group3/User_and_Agent_App_Flutter.git
cd User_and_Agent_App_Flutter
flutter pub get
```

### Configure environment

1. Update the values referenced in `analysis_options.yaml`, `JWT_TOKEN_IMPLEMENTATION.md`, and `IP_CONFIG_IMPLEMENTATION.md` to match your environment.
2. Replace placeholder Firebase files in `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`.
3. Review `lib/firebase_options.dart` to ensure it aligns with the Firebase project.
4. Provide backend URLs, tokens, and BLE advertisement names where required (see `RUNTIME_CONFIG_GUIDE.md`).

### Run the app

```powershell
flutter run --flavor development
```

> Tip: use `flutter analyze` and `flutter test` to keep the project green before pushing changes.

## Configuration reference

| File / Guide | Purpose |
| --- | --- |
| `IP_CONFIG_IMPLEMENTATION.md` | Backend IP/domain configuration, environment switching |
| `JWT_TOKEN_IMPLEMENTATION.md` | Token generation, refresh logic, and secure storage strategy |
| `RUNTIME_CONFIG_GUIDE.md` | Manual overrides for runtime constants and secrets |
| `firebase.json`, `firebase_options.dart` | Firebase project bindings |

## Project structure

```
lib/
	main.dart                    # App bootstrap & routing
	services/
		esp32_provisioning_service.dart  # BLE + Wi-Fi provisioning logic
		bluetooth_service.dart           # Legacy BLE utilities
		auth_service.dart, token_service.dart, ...
	users/                     # Rider-facing screens (status, provisioning, parking)
	Agents/                    # Agent workflows (dashboard, management)
assets/
	animations/, icons/, images/       # Lottie animations & static assets
android/, ios/, web/, linux/, macos/, windows/  # Flutter platform scaffolding
docs & guides (root)          # Implementation notes for networking/auth
```

## Development tooling

- `flutter analyze` – Static analysis with strict linting (see `analysis_options.yaml`).
- `flutter test` – Widget/unit test runner (expand coverage under `test/`).
- `flutter pub run flutter_launcher_icons:main` – Generate platform icons.
- `dart pub outdated` – Identify dependency upgrades.

## Roadmap

- [ ] Finish payment handling and receipts via Stripe.
- [ ] Harden BLE connection retries and background scanning.
- [ ] Extend agent analytics dashboard with exportable reports.
- [ ] Automate telemetry ingestion tests against the FastAPI backend.
- [ ] Document OTA firmware update process for ESP32 devices.

## Contributing

1. Fork the repository and create a feature branch.
2. Keep PRs focused, with passing analyzer/tests.
3. Update documentation when behaviour changes (README, guides, inline docs).
4. Request reviews from at least one teammate before merging to `main`.

_This project is currently maintained by CO3302 Group 3. Usage outside the module should be coordinated with the maintainers._
