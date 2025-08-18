# FindIt - Lost & Found Community App

A modern Flutter application that helps users find lost items and return found items to their rightful owners. Built with static storage for immediate functionality, ready for Firebase integration.

## ✨ Features

### 🔐 Authentication System
- **User Registration**: Create new accounts with email, password, name, and phone
- **User Login**: Secure authentication with static storage
- **User Profiles**: Manage personal information and view posting history

### 📱 Core Functionality
- **Post Items**: Create lost/found item posts with images, descriptions, and location
- **Real-time Feed**: Live updates of all posted items with search and filtering
- **Item Management**: Edit, delete, and manage your posted items
- **Contact System**: Built-in messaging system for item owners and finders

### 🗺️ Location Services
- **GPS Integration**: Get current location for item posting
- **Map View**: Visual representation of lost/found items
- **Location Tracking**: Store coordinates for each item

### 📊 Data Management
- **Static Storage**: Local data management for immediate functionality
- **Image Support**: Item photo uploads (placeholder implementation)
- **Search & Filter**: Advanced search with category filtering and sorting

### 🎨 Modern UI/UX
- **Material Design 3**: Beautiful, modern interface
- **Responsive Design**: Works seamlessly across all screen sizes
- **Dark/Light Theme**: Adaptive theming system
- **Smooth Animations**: Engaging user interactions

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Android Studio / VS Code
- Android/iOS device or emulator

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/FindIt-master.git
cd FindIt-master
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the App
```bash
flutter run
```

## 📱 App Flow

### Authentication Flow
1. **Launch**: App starts with login screen
2. **Login**: Use demo credentials or create new account
3. **Home**: Navigate to main feed after successful authentication

### Item Management Flow
1. **Post Item**: Fill form with item details, location, and photo
2. **Home Feed**: View all items with search and filtering
3. **Item Details**: Tap items to view full details
4. **Contact**: Message item owners/finders directly

### Navigation
- **Home**: Browse all lost/found items
- **Post**: Create new item posts
- **Map**: View items on interactive map
- **Chat**: Manage conversations
- **Notifications**: View app alerts
- **Profile**: Manage account and view posts

## 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── item.dart            # Item data structure
│   └── user_profile.dart    # User profile structure
├── screens/                  # UI screens
│   ├── auth/                # Authentication screens
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── home_screen.dart     # Main feed
│   ├── post_item_screen.dart # Item creation
│   ├── map_screen.dart      # Map view
│   ├── chat_screen.dart     # Messaging
│   ├── notifications_screen.dart # Alerts
│   ├── profile_screen.dart  # User profile
│   └── item_details_screen.dart # Item details
└── services/                 # Business logic
    └── static_auth_service.dart # Static data management
```

## 🔧 Configuration

### Demo Credentials
- **Email**: `alice@example.com`
- **Password**: `password123`

### Static Data
The app includes pre-populated data for immediate testing:
- Sample users (Alice Smith, Bob Johnson)
- Sample items (Lost Wallet, Found Keys, Lost Phone)
- Mock conversations and notifications

## 🎯 Current Status

### ✅ Implemented
- Complete authentication system with static storage
- Real-time item posting and management
- Advanced search and filtering
- Interactive map with item markers
- Modern, responsive UI design
- Chat and notification systems
- User profile management
- Location services integration

### 🔄 Ready for Firebase Integration
- Static storage service can be easily replaced
- All Firebase dependencies are commented out
- Data models are Firebase-compatible
- Authentication flow is Firebase-ready

### 📋 Planned Features
- Item claiming system
- User ratings and reviews
- Advanced search algorithms
- Push notifications
- Image upload to cloud storage
- Social sharing integration

## 🚀 Firebase Integration (Future)

When ready to integrate Firebase:

1. **Uncomment Firebase imports** in all files
2. **Replace StaticAuthService** with FirebaseService
3. **Configure Firebase project** and add credentials
4. **Update firebase_options.dart** with real API keys
5. **Deploy Firestore security rules**

## 🐛 Troubleshooting

### Common Issues
- **Build Errors**: Run `flutter clean` and `flutter pub get`
- **Location Issues**: Grant location permissions in device settings
- **Image Loading**: Check internet connection for placeholder images

### Performance Tips
- Use release mode for production: `flutter run --release`
- Optimize images before posting
- Clear app cache if experiencing slowdowns

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For support and questions:
- Create an issue in the GitHub repository
- Contact the development team

---

**Note**: This is a production-ready implementation with static storage. The app is fully functional and ready for Firebase integration when needed. All features work seamlessly with the current static data management system.
