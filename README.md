# CipherTask - Secure Encrypted To-Do System

A secure task management application built with Flutter following the **Strict MVVM Architectural Pattern**. This project focuses on mobile secure data storage, secure communication, and biometric authentication.

## 👥 Team Roles & Responsibilities

| Member | Role | Responsibilities |
| :--- | :--- | :--- |
| **M1** | Lead Architect & DB Engineer | Project Setup, MVVM structure, SQLCipher implementation, To-Do CRUD services. |
| **M2** | Security & Cryptography Lead | EncryptionService (AES-256), Key Management with FlutterSecureStorage. |
| **M3** | Auth & Biometrics Specialist | Biometric Auth (local_auth), SessionService (2-min inactivity timer). |
| **M4** | Backend & Network (SSL) | User Registration, real Email OTP MFA integration, Transport Security. |
| **M5** | UI/UX & Integration | View implementation (Login, Register, List), Privacy Obfuscation (FLAG_SECURE). |

## 🛡️ Key Security Features

- **Database Encryption:** Local database encrypted using **SQLCipher** with a hardware-backed key.
- **Hardware-Backed Key Storage:** Encryption keys are generated on first run and stored in **Android Keystore / iOS Keychain**.
- **AES-256 Field Encryption:** Sensitive "Secret Notes" are encrypted using AES-256 before being saved to the database.
- **Biometric Authentication:** Supports Fingerprint/FaceID login (only after the first password login).
- **Automatic Session Timeout:** App auto-locks after 2 minutes of inactivity.
- **Privacy Shield:** Prevents screenshots and obfuscates content in the "Recent Apps" switcher.
- **Real MFA:** Registration requires verification via a 6-digit OTP sent to a real email address.

## 🚀 Getting Started

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/Aiene03/CipherTask.git
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Run the application:**
    ```bash
    flutter run
    ```

## 📂 Project Structure (Strict MVVM)

- `lib/models/`: Data Layer (POJOs)
- `lib/views/`: UI Layer (Screens & Widgets)
- `lib/viewmodels/`: Logic Layer (State Management)
- `lib/services/`: Data & Security Services
- `lib/utils/`: Helpers & Constants
