import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/user_provider.dart';
import 'providers/settings_provider.dart';
import 'services/notification_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/post_item_screen.dart';
import 'screens/map_screen.dart';
import 'screens/chat_screen_new.dart';
import 'screens/notifications_screen_new.dart';
import 'screens/profile_screen.dart';
import 'services/fcm_service.dart';
import 'services/notification_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize FCM and notification services
  final fcmService = FCMService();
  final notificationManager = NotificationManager();
  await fcmService.initialize();
  await notificationManager.initialize();

  runApp(const FindItApp());
}

class FindItApp extends StatelessWidget {
  const FindItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'FindIt - Lost & Found',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Check if we have data yet
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is signed in
        if (snapshot.hasData) {
          // Initialize user data when authenticated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<UserProvider>().initializeUser();
            NotificationService().start();
          });
          return const MainNavigation();
        }

        // User is not signed in
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NotificationService().stop();
        });
        return const LoginScreen();
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final NotificationManager _notificationManager = NotificationManager();

  void _onItemTapped(int index) {
    print('Tab tapped: $index'); // Debug print
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToHome() {
    setState(() {
      _selectedIndex = 0; // Navigate to home tab
    });
  }

  List<Widget> get _screens => [
    const HomeScreen(),
    const PostItemScreen(),
    const MapScreen(),
    const ChatScreen(),
    NotificationsScreen(onBrowseItems: _navigateToHome),
    const ProfileScreen(),
  ];

  List<BottomNavigationBarItem> _buildBottomNavigationBarItems() {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.add_circle_outline),
        label: 'Post',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.map_outlined),
        label: 'Map',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.chat_bubble_outline),
        label: 'Chat',
      ),
      BottomNavigationBarItem(
        icon: NotificationIcon(notificationManager: _notificationManager),
        label: 'Alerts',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        label: 'Profile',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    print('Building MainNavigation with index: $_selectedIndex'); // Debug print
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: _buildBottomNavigationBarItems(),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedFontSize: 12,
        unselectedFontSize: 10,
        selectedIconTheme: const IconThemeData(size: 24),
        unselectedIconTheme: const IconThemeData(size: 20),
      ),
    );
  }
}

class NotificationIcon extends StatelessWidget {
  final NotificationManager notificationManager;

  const NotificationIcon({super.key, required this.notificationManager});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: notificationManager.getUnreadCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        return Stack(
          children: [
            const Icon(Icons.notifications_none),
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
