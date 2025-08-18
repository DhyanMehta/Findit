# FindIt - Firebase Authentication System

This project now includes a complete Firebase authentication system with dynamic sign-in, sign-up, and user data storage in Firestore.

## Features Implemented

### 🔐 Authentication Features

- **Sign Up**: Create new accounts with email, password, name, and phone
- **Sign In**: Authenticate existing users
- **Sign Out**: Secure logout functionality
- **Password Reset**: Forgot password functionality via email
- **Email Verification**: Automatic email verification for new users

### 👤 User Management

- **User Profiles**: Store and retrieve user data in Firestore
- **Profile Editing**: Update name, phone, and avatar
- **User Provider**: State management for user data throughout the app

### 🏗️ Architecture

- **Firebase Authentication**: Secure user authentication
- **Cloud Firestore**: User data storage and retrieval
- **Provider Pattern**: State management for user data
- **Responsive UI**: Beautiful, modern authentication screens

## File Structure

```
lib/
├── main.dart                           # App entry point with Provider setup
├── firebase_options.dart               # Firebase configuration
├── models/
│   └── user_model.dart                 # User data model for Firestore
├── services/
│   └── firebase_auth_service.dart      # Firebase authentication service
├── providers/
│   └── user_provider.dart              # User state management
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart          # Sign-in screen
│   │   └── signup_screen.dart         # Sign-up screen
│   ├── edit_profile_screen.dart       # Profile editing screen
│   └── profile_screen.dart            # User profile display
└── ... (other screens)
```

## Firebase Setup Required

### 1. Firebase Console Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing one
3. Enable Authentication:
   - Go to Authentication > Sign-in method
   - Enable "Email/Password" provider
4. Enable Firestore Database:
   - Go to Firestore Database
   - Create database in test mode (or production with rules)

### 2. Firebase Configuration

- Ensure `firebase_options.dart` is properly configured for your project
- Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

### 3. Firestore Security Rules

Add these rules to your Firestore database:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read and write their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Usage Examples

### Sign Up New User

```dart
await _authService.signUpWithEmailAndPassword(
  email: 'user@example.com',
  password: 'securePassword',
  name: 'John Doe',
  phone: '+1234567890',
);
```

### Sign In Existing User

```dart
await _authService.signInWithEmailAndPassword(
  email: 'user@example.com',
  password: 'securePassword',
);
```

### Update User Profile

```dart
final userProvider = context.read<UserProvider>();
await userProvider.updateProfile(
  name: 'Updated Name',
  phone: '+0987654321',
);
```

### Access User Data

```dart
// In any widget with Provider
final userProvider = context.watch<UserProvider>();
Text('Welcome, ${userProvider.displayName}!');
```

## Key Components

### 1. FirebaseAuthService

- Handles all Firebase Authentication operations
- Creates and manages user documents in Firestore
- Provides error handling with user-friendly messages

### 2. UserModel

- Structured data model for user information
- Includes serialization for Firestore storage
- Supports avatar URLs, verification status, and user roles

### 3. UserProvider

- Manages user state throughout the app
- Provides loading states and error handling
- Automatically syncs with Firebase Authentication changes

### 4. Authentication Screens

- **LoginScreen**: Clean, modern sign-in interface
- **SignupScreen**: Comprehensive registration form
- **EditProfileScreen**: User profile management

## Security Features

1. **Email Verification**: New users receive verification emails
2. **Secure Password Storage**: Firebase handles password hashing
3. **Authentication State Persistence**: Users stay logged in between sessions
4. **Firestore Security Rules**: Users can only access their own data
5. **Input Validation**: Client-side form validation for better UX

## Error Handling

The system includes comprehensive error handling for:

- Network connectivity issues
- Invalid credentials
- Email already in use
- Weak passwords
- Account not found
- Email not verified

## Testing

To test the authentication system:

1. **Sign Up**: Create a new account
2. **Email Verification**: Check your email for verification link
3. **Sign In**: Log in with your credentials
4. **Profile Management**: Edit your profile information
5. **Sign Out**: Test logout functionality
6. **Password Reset**: Test forgot password feature

## Next Steps

You can extend this system by adding:

1. **Social Authentication** (Google, Apple, Facebook)
2. **Profile Image Upload** with Firebase Storage
3. **Phone Number Authentication**
4. **Two-Factor Authentication**
5. **User Role Management**
6. **Account Deletion** with confirmation

## Dependencies

The following Firebase packages are used:

- `firebase_core`: Firebase initialization
- `firebase_auth`: Authentication services
- `cloud_firestore`: Database operations
- `provider`: State management

## Support

If you encounter any issues:

1. Check Firebase Console for authentication logs
2. Verify Firestore security rules are correctly set
3. Ensure all required permissions are granted
4. Check network connectivity for Firebase operations

This authentication system provides a solid foundation for your FindIt app with secure user management and modern UI/UX patterns.
