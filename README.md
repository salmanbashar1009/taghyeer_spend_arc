# 💰 SpendArc - Advanced Expense Tracking Application

![Flutter](https://img.shields.io/badge/Flutter-3.9.2-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-67.3%25-blue?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)
![Build](https://img.shields.io/badge/Build-Active-success)

A powerful and intuitive expense tracking application built with Flutter. SpendArc helps you manage your spending efficiently with real-time sync, offline support, and beautiful analytics visualization powered by custom GLSL shaders.

---

## 📋 Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Dependencies](#dependencies)
- [Getting Started](#getting-started)
- [Building & Running](#building--running)
- [Platform Support](#platform-support)
- [Contributing](#contributing)

---

## ✨ Features

### Core Features
- **📱 Transaction Management**
  - Add new transactions with detailed information
  - Delete transactions easily
  - View transaction history
  - Real-time transaction updates

- **📊 Analytics Dashboard**
  - Visual spending analytics with custom GLSL shader effects
  - Beautiful glow effects for spending visualization
  - Particle field animations for immersive UI
  - Real-time analytics updates

- **🔄 Real-time Synchronization**
  - Sync transactions with remote server
  - Automatic sync shimmer animation effects
  - Seamless data synchronization across devices
  - Conflict resolution for offline changes

- **📴 Offline-First Architecture**
  - Full offline functionality with SQLite local database
  - Automatic data syncing when connection restored
  - No data loss during offline periods
  - Background sync capabilities

- **🎯 Multiple Pages & Navigation**
  - **Dashboard Page**: Main hub with overview and sync status
  - **Transactions Page**: Comprehensive transaction history
  - **Analytics Page**: Advanced spending analytics with visualizations

### Visual Effects
- **Custom GLSL Shaders** for:
  - Spending Glow Effects (`spending_glow.frag`)
  - Sync Shimmer Animation (`sync_shimmer.frag`)
  - Particle Field Background (`particle_field.frag`)

- **Material 3 Design**
  - Modern UI with Material You design principles
  - Light and Dark theme support
  - Adaptive color schemes

---

## 🛠️ Tech Stack

### Language & Framework
| Technology | Version | Usage |
|-----------|---------|-------|
| **Dart** | 3.9.2+ | Primary programming language (67.3%) |
| **Flutter** | Latest | Cross-platform mobile framework |
| **C++** | - | Native performance (16%) |
| **CMake** | - | Build configuration (12.7%) |
| **Swift** | - | iOS integration (1.3%) |
| **GLSL** | - | Custom shader effects (0.9%) |
| **C** | - | Low-level operations (0.9%) |

### Core Dependencies

#### State Management & Architecture
- **[flutter_bloc](https://pub.dev/packages/flutter_bloc)** (v9.1.1) - BLoC pattern state management
- **[equatable](https://pub.dev/packages/equatable)** (v2.0.8) - Equality comparison for objects

#### Functional Programming
- **[fpdart](https://pub.dev/packages/fpdart)** (v1.2.0) - Functional programming utilities & Either monad

#### Dependency Injection
- **[get_it](https://pub.dev/packages/get_it)** (v9.2.1) - Service locator & dependency injection

#### Database & Local Storage
- **[sqflite](https://pub.dev/packages/sqflite)** (v2.4.2) - SQLite database for local persistence

#### Routing & Navigation
- **[go_router](https://pub.dev/packages/go_router)** (v17.2.3) - Declarative routing

#### Connectivity
- **[connectivity_plus](https://pub.dev/packages/connectivity_plus)** (v7.1.1) - Network connectivity monitoring

#### Utilities
- **[path](https://pub.dev/packages/path)** (v1.9.1) - File path operations
- **[uuid](https://pub.dev/packages/uuid)** (v4.5.3) - Unique identifier generation
- **[cupertino_icons](https://pub.dev/packages/cupertino_icons)** (v1.0.8) - iOS-style icons

#### Development Dependencies
- **[flutter_test](https://pub.dev/packages/flutter_test)** - Testing framework
- **[flutter_lints](https://pub.dev/packages/flutter_lints)** (v5.0.0) - Lint rules
- **[mocktail](https://pub.dev/packages/mocktail)** (v1.0.5) - Mocking library for tests
- **[bloc_test](https://pub.dev/packages/bloc_test)** (v10.0.0) - BLoC testing utilities

---

## 🏗️ Architecture

SpendArc follows **Clean Architecture** principles with **BLoC** pattern for state management:

```
lib/
├── core/                          # Core functionality
│   ├── di/                        # Dependency injection setup
│   ├── error/                     # Error handling
│   ├── network/                   # Network utilities
│   ├── offline/                   # Offline storage logic
│   ├── router/                    # Navigation setup
│   └── usecases/                  # Base use case classes
│
├── features/
│   └── transactions/              # Transaction feature module
│       ├── data/                  # Data layer
│       │   ├── data_sources/      # Local & remote data sources
│       │   ├── models/            # Data models
│       │   └── repositories/      # Repository implementations
│       ├── domain/                # Domain layer (business logic)
│       │   ├── entities/          # Core entities
│       │   ├── repositories/      # Repository interfaces
│       │   └── usecases/          # Business use cases
│       └── presentation/          # Presentation layer (UI)
│           ├── bloc/              # BLoC state management
│           ├── pages/             # Full pages/screens
│           └── widgets/           # Reusable widgets
│
└── main.dart                      # App entry point
```

### Layer Descriptions

**Domain Layer** (Business Logic)
- Contains entities like `TransactionEntity`
- Defines repository interfaces
- Implements use cases: `AddTransaction`, `GetTransactions`, `DeleteTransaction`, `SyncTransactions`

**Data Layer** (Data Management)
- Implements repositories defined in domain
- Contains data sources:
  - `TransactionLocalDataSource` - SQLite operations
  - `TransactionRemoteDataSource` - API calls
- Models for serialization/deserialization

**Presentation Layer** (UI)
- BLoC state management with `TransactionBloc`
- Events: `FetchTransactionsEvent`, `AddTransactionEvent`, `DeleteTransactionEvent`, `SyncTransactionsEvent`
- States: Loading, Success, Error states
- Pages: Dashboard, Transactions, Analytics
- Custom widgets for UI components

---

## 📁 Project Structure

```
taghyeer_spend_arc/
├── lib/                           # Dart source code
│   ├── main.dart                  # Application entry point
│   ├── core/                      # Core utilities & setup
│   └── features/                  # Feature modules
├── shaders/                       # GLSL shader files
│   ├── spending_glow.frag         # Glow effect for spending viz
│   ├── sync_shimmer.frag          # Shimmer animation for sync
│   └── particle_field.frag        # Particle background effect
├── android/                       # Android-specific code
├── ios/                           # iOS-specific code
├── linux/                         # Linux desktop support
├── macos/                         # macOS desktop support
├── windows/                       # Windows desktop support
├── web/                           # Web platform support
├── test/                          # Unit & widget tests
├── pubspec.yaml                   # Flutter dependencies
├── pubspec.lock                   # Locked dependency versions
├── analysis_options.yaml          # Dart analyzer configuration
└── README.md                      # This file
```

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: 3.9.2 or higher
- **Dart SDK**: Latest version
- **Platform SDKs**: 
  - iOS: Xcode 14+
  - Android: Android Studio with SDK 21+

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/salmanbashar1009/taghyeer_spend_arc.git
   cd taghyeer_spend_arc
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run code generation** (if needed)
   ```bash
   flutter pub run build_runner build
   ```

---

## 🔨 Building & Running

### Run the app in development mode
```bash
flutter run
```

### Run with specific device
```bash
flutter run -d <device-id>
```

### Build for specific platform

**Android APK:**
```bash
flutter build apk --release
```

**Android App Bundle:**
```bash
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

**Web:**
```bash
flutter build web --release
```

**Desktop (Windows/macOS/Linux):**
```bash
flutter build windows
flutter build macos
flutter build linux
```

### Run tests
```bash
flutter test
```

### Run with coverage
```bash
flutter test --coverage
```

---

## 📱 Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| **Android** | ✅ Supported | SDK 21+ |
| **iOS** | ✅ Supported | iOS 11.0+ |
| **Web** | ✅ Supported | Modern browsers |
| **Windows** | ✅ Supported | Windows 10+ |
| **macOS** | ✅ Supported | macOS 10.14+ |
| **Linux** | ✅ Supported | Ubuntu 18.04+ |

---

## 🧪 Testing

The project includes comprehensive testing setup:

### Test Dependencies
- `flutter_test` - Core testing framework
- `mocktail` - Mocking for unit tests
- `bloc_test` - BLoC-specific testing utilities

### Running Tests
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/path/to/test.dart

# Run with verbose output
flutter test -v

# Generate coverage report
flutter test --coverage
```

---

## 🎨 Custom Shaders

SpendArc includes three custom GLSL fragment shaders for enhanced visual effects:

### 1. Spending Glow (`spending_glow.frag`)
Provides a radiant glow effect for spending visualizations

### 2. Sync Shimmer (`sync_shimmer.frag`)
Animates a shimmer effect during data synchronization

### 3. Particle Field (`particle_field.frag`)
Creates a particle field background for immersive UI

These shaders are compiled at runtime and used in custom widgets.

---

## 🔐 Offline Support

The app includes robust offline functionality:

- **Local Database**: SQLite for persistent local storage
- **Automatic Sync**: Syncs when connection is restored
- **Conflict Resolution**: Handles sync conflicts gracefully
- **Network Monitoring**: Uses `connectivity_plus` to detect connection changes

---

## 📡 API Integration

The app features dual data source architecture:

- **Local Data Source**: SQLite database for offline-first approach
- **Remote Data Source**: API integration for cloud sync
- **Repository Pattern**: Abstraction layer for data operations

---

## 🎯 Use Cases

Core business logic implemented as use cases:

1. **AddTransaction** - Add new spending transaction
2. **GetTransactions** - Retrieve transaction history
3. **DeleteTransaction** - Remove transaction record
4. **SyncTransactions** - Synchronize with remote server

---

## 🔄 State Management

Uses **Flutter BLoC** pattern with:
- `TransactionBloc` - Main business logic component
- Event-driven architecture
- Immutable state classes
- Reactive programming with streams

---

## 📊 Analytics

The analytics page displays:
- Spending patterns and trends
- Category-wise breakdown
- Monthly/weekly statistics
- Custom visualizations with shader effects

---

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style
- Follow Dart style guide
- Use meaningful variable names
- Add documentation comments
- Run `flutter analyze` before committing

---

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 👨‍💻 Author

**Salman Bashar**
- GitHub: [@salmanbashar1009](https://github.com/salmanbashar1009)

---

## 🐛 Troubleshooting

### Common Issues

**Issue: Flutter not found**
```bash
flutter doctor
flutter pub get
```

**Issue: Build errors on iOS**
```bash
cd ios
rm -rf Pods Pod.lock
pod install
cd ..
flutter clean
flutter pub get
flutter run
```

**Issue: Android build failures**
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📞 Support

For issues and questions:
- Open an issue on [GitHub Issues](https://github.com/salmanbashar1009/taghyeer_spend_arc/issues)
- Check existing issues for solutions
- Provide detailed error messages and steps to reproduce

---

## 🙏 Acknowledgments

- Flutter and Dart communities
- All package maintainers used in this project
- Contributors and testers

---

**Happy Spending! 💸**
