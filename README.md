# RescueEats 🍔🚀

**RescueEats** is a scalable, modern food delivery application built with **Flutter**. It connects customers with restaurants, offering a seamless ordering experience, real-time updates, and a gamified user experience. The app features distinct portals for Customers, Restaurant Owners, and Admins.

---

## ✨ Features

### 👤 Customer App
- **Authentication**: Secure Login & Signup with Email/Password and **Google Sign-In**.
- **Browse Restaurants**: Explore a variety of restaurants and view their menus.
- **Cart & Ordering**: Add items to cart, customize orders, and place orders seamlessly.
- **Gamification**: "Catch Game" to engage users and potentially earn rewards.
- **Profile Management**: Manage user details and settings.
- **Real-time Updates**: (Planned/Implemented) Order status updates via Socket.IO.

### 🏪 Restaurant Owner Portal
- **Restaurant Management**: Create and manage restaurant profile.
- **Menu Management**: Add, edit, and remove menu items with images.
- **Order Management**: View and manage incoming orders.

### 🛡️ Admin Dashboard
- **Overview**: Real-time statistics and trends.
- **User Management**: Manage users and roles.
- **Restaurant Oversight**: Approve and manage restaurant listings.
- **Order Monitoring**: Track all orders across the platform.

---

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (SDK ^3.9.2)
- **Language**: Dart
- **State Management**: [Riverpod](https://riverpod.dev/) (with Code Generation)
- **Routing**: [GoRouter](https://pub.dev/packages/go_router)
- **Networking**: `http`, `socket_io_client`
- **Data Modeling**: `freezed`, `json_serializable`
- **Authentication**: `google_sign_in`, `shared_preferences`
- **UI/UX**: `shimmer`, `cached_network_image`, Custom Theming

---

## 📂 Project Structure

The project follows a feature-first and clean architecture approach:

```
lib/
├── core/                   # Core functionality shared across the app
│   ├── appTheme/           # App-wide themes and colors
│   ├── error/              # Error handling classes
│   ├── model/              # Data models (Freezed/JsonSerializable)
│   ├── services/           # API and external services
│   └── utils/              # Utility functions
├── features/               # Shared feature components & providers
├── screens/                # UI Screens organized by feature
│   ├── admin/              # Admin Dashboard screens
│   ├── auth/               # Authentication screens
│   ├── delivery/           # Delivery related screens
│   ├── home/               # Home screen logic
│   ├── order/              # Cart and Order processing
│   ├── restaurant/         # Restaurant details and management
│   └── user/               # Customer profile and game screens
├── app.dart                # App configuration
└── main.dart               # Entry point
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
- Android Studio / Xcode for emulator or device testing.
- Git installed.

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/ByteNirush/RescueEats-Frontend.git
   cd deliveryApp
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run Code Generation (for Riverpod & Freezed):**
   ```bash
   dart run build_runner build -d
   ```

4. **Run the App:**
   ```bash
   flutter run
   ```

---

## 🧪 Running Tests

To run the test suite:
```bash
flutter test
```

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:
1. Fork the repository.
2. Create a new branch (`git checkout -b feature/YourFeature`).
3. Commit your changes (`git commit -m 'Add some feature'`).
4. Push to the branch (`git push origin feature/YourFeature`).
5. Open a Pull Request.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
