# Community-Centric Rabies Intelligence System (CRIS)

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Google Maps](https://img.shields.io/badge/Google_Maps_API-4285F4?style=for-the-badge&logo=google-maps&logoColor=white)
![License: MIT](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)

A next-generation mobile and geospatial intelligence platform designed for real-time rabies surveillance, incident mapping, and vaccination tracking.

---

## 📌 Overview

**CRIS** bridges the gap between community-level incident reporting and public health administration. By combining mobile reporting forms with spatial analytics and heatmaps, CRIS enables healthcare officers and community members to track rabies vectors in real time, identify high-risk bite clusters, and streamline immunization campaigns.

> 📍 **Objective:** Accelerate rabies response times, optimize vaccine distribution, and provide actionable spatial insights for public health authorities.

---

## 🔥 Key Features

| Feature | Description |
| :--- | :--- |
| **🚨 Real-Time Case Reporting** | Mobile forms for reporting animal bite incidents, patient demographics, and vector health statuses. |
| **🗺️ Geospatial Analytics** | Live heatmaps and interactive maps powered by Google Maps API to visualize bite hot-spots. |
| **💉 Vaccination Tracking** | Comprehensive log for community mass immunization drives and domestic animal coverage. |
| **🛡️ Admin & Control Portal** | Verification workflows for health officials to process inbound reports and manage health records. |
| **⚡ Local Tunneling Support** | Native alignment with tools like `ngrok` for rapid physical mobile device testing against local backends. |

---

## 🛠️ Tech Stack

### Client & Geospatial
- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **Mapping & GIS:** Google Maps SDK, QGIS Spatial Analytics

### Backend & Cloud Infrastructure
- **Database & Auth:** Google Firebase (Cloud Firestore, Firebase Authentication, Cloud Storage)
- **Tunneling:** ngrok (Local API forwarding)

---

## 📂 Project Structure

```text
CRIS_APP/
 ├── 📱 android/              # Native Android configuration files
 ├── 🍎 ios/                  # Native iOS configuration files
 ├── 📦 lib/                  # Main application source code
 │    ├── 🧩 models/          # Data structures (Incidents, Vaccination Records, Markers)
 │    ├── 🖼️ screens/         # UI Components (Dashboards, Map Analytics, Incident Forms)
 │    ├── ⚙️ services/        # Firebase integrations & REST API client logic
 │    └── 🚀 main.dart        # Main entry point
 ├── 🎨 assets/               # Branding assets, vector icons, and custom map styling
 └── 📄 pubspec.yaml          # Project dependencies and configurations
