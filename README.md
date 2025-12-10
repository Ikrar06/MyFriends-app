# MyFriends App

MyFriends is a contact management application built with Flutter. This app helps you organize your contacts into groups and includes an emergency SOS feature for quick notifications.

## About This Project

This is a Flutter-based mobile application created as the final project for Mobile Programming Class C, Informatics Engineering Department, Hasanuddin University. The app provides an easy way to manage contacts, organize them into groups, and send emergency notifications when needed.

### Project Team - Group 5

- IKRAR GEMPUR TIRANI (D121231015)
- MUH. GEMILANG NUGRAHA ISMAJAYA (D121231030)
- MUHAMMAD IRGI ABAYL MARZUKU (D121231102)

## Features

### Contact Management
- Add, edit, and delete contacts
- Store contact information including name, phone number, email, and photo
- Mark contacts as emergency contacts
- Search and filter contacts
- View detailed contact information
- Call, SMS, and email directly from the app

### Group Organization
- Create and manage contact groups
- Add multiple contacts to groups
- Color-coded groups for easy identification
- View all members in a group
- Smart member selection that shows which contacts are already added

### Emergency SOS
- Quick emergency notification feature
- Send SOS alerts to all emergency contacts
- One-tap slide button for activation
- Sends notifications via Firebase Cloud Messaging

### User Interface
- Clean and modern design
- Minimalist interface with consistent styling
- Poppins font family throughout the app
- Responsive layouts for different screen sizes
- Light grey background for reduced eye strain

## Technology Stack

### Frontend
- Flutter SDK
- Dart programming language
- Provider for state management

### Backend Services
- Firebase Authentication for user login
- Cloud Firestore for data storage
- Firebase Cloud Messaging for notifications
- Firebase Storage for profile photos

### Key Packages
- `provider` - State management
- `firebase_core` - Firebase initialization
- `firebase_auth` - User authentication
- `cloud_firestore` - Database operations
- `firebase_messaging` - Push notifications
- `firebase_storage` - File storage
- `cached_network_image` - Image caching
- `url_launcher` - Phone/SMS/Email actions
- `image_picker` - Photo selection
- `flutter_launcher_icons` - App icon generation

## Project Structure

```
lib/
├── models/           # Data models (Contact, Group, User)
├── providers/        # State management providers
├── screens/          # App screens
│   ├── auth/        # Login and registration
│   ├── contact/     # Contact management screens
│   ├── group/       # Group management screens
│   ├── home/        # Home screen
│   └── onboarding/  # First-time user experience
├── services/        # Firebase and other services
├── routes/          # App navigation
└── widgets/         # Reusable UI components
```

## Getting Started

### Prerequisites

Before running this project, make sure you have:
- Flutter SDK installed (version 3.0 or higher)
- Android Studio or VS Code with Flutter extensions
- A Firebase project set up
- An Android or iOS device/emulator

### Installation Steps

1. Clone this repository
```bash
git clone https://github.com/Ikrar06/MyFriends-app.git
cd myfriends_app
```

2. Install dependencies
```bash
flutter pub get
```

3. Set up Firebase
- Create a new Firebase project at https://console.firebase.google.com
- Add your Android/iOS app to the Firebase project
- Download and add the configuration files:
  - Android: `google-services.json` to `android/app/`
  - iOS: `GoogleService-Info.plist` to `ios/Runner/`

4. Enable Firebase services
- Enable Authentication (Email/Password)
- Create a Firestore database
- Enable Firebase Storage
- Set up Firebase Cloud Messaging

5. Run the app
```bash
flutter run
```

## Firebase Setup

### Firestore Collections

The app uses these Firestore collections:

**users**
- userId (document ID)
- email
- displayName
- createdAt
- fcmToken

**contacts**
- contactId (document ID)
- userId
- nama (name)
- nomor (phone number)
- email
- photoUrl
- isEmergency
- createdAt
- updatedAt

**groups**
- groupId (document ID)
- userId
- nama (name)
- colorHex
- contactIds (array)
- createdAt
- updatedAt

### Security Rules

Make sure to set up proper security rules in Firestore to protect user data.

## Design System

The app follows a consistent design system:

- **Font**: Poppins (all text)
- **Primary Color**: #FE7743 (orange)
- **Background**: #F5F5F5 (light grey)
- **Title Size**: 36px
- **Card Border Radius**: 20px
- **Button Border Radius**: 12px
- **Horizontal Padding**: 24px

## Development Notes

### State Management
The app uses the Provider package for state management. Main providers:
- `ContactProvider` - Manages contact data and operations
- `GroupProvider` - Manages group data and operations
- `AuthProvider` - Handles authentication state

### Navigation
Routes are defined in `lib/routes/app_routes.dart` for easy navigation management.

### Firebase Integration
All Firebase operations are handled through service classes in `lib/services/`:
- `auth_service.dart` - Authentication operations
- `contact_service.dart` - Contact CRUD operations
- `group_service.dart` - Group CRUD operations
- `notification_service.dart` - FCM notifications

## Testing

Run tests using:
```bash
flutter test
```

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Known Issues

- SOS notifications require all users to have the app installed
- Profile photos require internet connection to display
- Some features may not work offline

## Future Improvements

- Offline mode with local storage
- Contact backup and restore
- Group messaging
- Contact sharing
- Dark mode support
- Multi-language support

## Contributing

This is a learning project. Feel free to fork and experiment with your own features.

## License

This project is created for educational purposes.

## Contact

Group 5 - Mobile Programming Class C
Informatics Engineering, Hasanuddin University

Project Repository: https://github.com/Ikrar06/MyFriends-app

## Acknowledgments

- Flutter documentation and community
- Firebase documentation
- Google Fonts (Poppins font)
- All open source packages used in this project
