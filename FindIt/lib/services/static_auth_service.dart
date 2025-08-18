import '../models/item.dart';

class StaticAuthService {
  // Static user storage (in real app, this would be Firebase)
  static final List<Map<String, dynamic>> _users = [
    {
      'id': 'u1',
      'name': 'Alice Smith',
      'email': 'alice@example.com',
      'password': 'password123',
      'phone': '123-456-7890',
      'avatarUrl': 'https://randomuser.me/api/portraits/women/1.jpg',
      'role': 'user',
    },
    {
      'id': 'u2',
      'name': 'Bob Johnson',
      'email': 'bob@example.com',
      'password': 'password123',
      'phone': '987-654-3210',
      'avatarUrl': 'https://randomuser.me/api/portraits/men/1.jpg',
      'role': 'admin',
    },
    {
      'id': 'u3',
      'name': 'Carol Wilson',
      'email': 'carol@example.com',
      'password': 'password123',
      'phone': '555-123-4567',
      'avatarUrl': 'https://randomuser.me/api/portraits/women/2.jpg',
      'role': 'user',
    },
    {
      'id': 'u4',
      'name': 'David Brown',
      'email': 'david@example.com',
      'password': 'password123',
      'phone': '444-987-6543',
      'avatarUrl': 'https://randomuser.me/api/portraits/men/2.jpg',
      'role': 'user',
    },
    {
      'id': 'u5',
      'name': 'Emma Davis',
      'email': 'emma@example.com',
      'password': 'password123',
      'phone': '333-456-7890',
      'avatarUrl': 'https://randomuser.me/api/portraits/women/3.jpg',
      'role': 'moderator',
    },
  ];

  // Static items storage
  static final List<Map<String, dynamic>> _items = [
    {
      'id': '1',
      'title': 'Lost Wallet',
      'description':
          'Black leather wallet lost near cafeteria. Contains student ID and some cash.',
      'category': 'Wallet',
      'imageUrl':
          'https://images.unsplash.com/photo-1599231313784-4a25838c1a7f?ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&ixlib=rb-1.2.1&auto=format&fit=crop&w=200&q=80',
      'location': 'Cafeteria',
      'dateTime': DateTime.now().subtract(const Duration(days: 1)),
      'contactMethod': 'In-app chat',
      'isFound': false,
      'userId': 'u1',
      'latitude': 37.4275,
      'longitude': -122.1697,
    },
    {
      'id': '2',
      'title': 'Found Keys',
      'description':
          'Set of car keys found in parking lot. Has a red keychain.',
      'category': 'Keys',
      'imageUrl':
          'https://images.unsplash.com/photo-1568292445831-a0a7f140c85c?ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&ixlib=rb-1.2.1&auto=format&fit=crop&w=200&q=80',
      'location': 'Parking Lot',
      'dateTime': DateTime.now().subtract(const Duration(hours: 5)),
      'contactMethod': 'Phone',
      'isFound': true,
      'userId': 'u2',
      'latitude': 37.4280,
      'longitude': -122.1700,
    },
    {
      'id': '3',
      'title': 'Lost Phone',
      'description': 'iPhone 13 with a blue case. Last seen in the library.',
      'category': 'Phone',
      'imageUrl':
          'https://images.unsplash.com/photo-1603506941498-5c639152d1ea?ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&ixlib=rb-1.2.1&auto=format&fit=crop&w=200&q=80',
      'location': 'Library',
      'dateTime': DateTime.now().subtract(const Duration(days: 2)),
      'contactMethod': 'Email',
      'isFound': false,
      'userId': 'u1',
      'latitude': 37.4260,
      'longitude': -122.1680,
    },
    {
      'id': '4',
      'title': 'Found Laptop',
      'description': 'MacBook Pro found in the computer lab. Please identify.',
      'category': 'Electronics',
      'imageUrl':
          'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&ixlib=rb-1.2.1&auto=format&fit=crop&w=200&q=80',
      'location': 'Computer Lab',
      'dateTime': DateTime.now().subtract(const Duration(hours: 3)),
      'contactMethod': 'In-app chat',
      'isFound': true,
      'userId': 'u2',
      'latitude': 37.4270,
      'longitude': -122.1690,
    },
    {
      'id': '5',
      'title': 'Lost Backpack',
      'description': 'Blue Jansport backpack with textbooks inside.',
      'category': 'Bag',
      'imageUrl':
          'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&ixlib=rb-1.2.1&auto=format&fit=crop&w=200&q=80',
      'location': 'Student Center',
      'dateTime': DateTime.now().subtract(const Duration(days: 3)),
      'contactMethod': 'Phone',
      'isFound': false,
      'userId': 'u1',
      'latitude': 37.4290,
      'longitude': -122.1710,
    },
    {
      'id': '6',
      'title': 'Found Watch',
      'description': 'Silver analog watch found near the fountain.',
      'category': 'Jewelry',
      'imageUrl':
          'https://images.unsplash.com/photo-1524592094714-0f0654e20314?ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&ixlib=rb-1.2.1&auto=format&fit=crop&w=200&q=80',
      'location': 'Fountain',
      'dateTime': DateTime.now().subtract(const Duration(hours: 8)),
      'contactMethod': 'Email',
      'isFound': true,
      'userId': 'u2',
      'latitude': 37.4265,
      'longitude': -122.1695,
    },
  ];

  // Current logged in user
  static Map<String, dynamic>? _currentUser;

  // Get current user
  static Map<String, dynamic>? get currentUser => _currentUser;

  // Get current user ID
  static String? get currentUserId => _currentUser?['id'];

  // Sign in
  static Future<bool> signIn(String email, String password) async {
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // Simulate network delay

    final user = _users.firstWhere(
      (u) => u['email'] == email && u['password'] == password,
      orElse: () => {},
    );

    if (user.isNotEmpty) {
      _currentUser = user;
      return true;
    }
    return false;
  }

  // Sign up
  static Future<bool> signUp(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // Simulate network delay

    // Check if email already exists
    if (_users.any((u) => u['email'] == email)) {
      return false;
    }

    // Create new user
    final newUser = {
      'id': 'u${_users.length + 1}',
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'avatarUrl': 'https://randomuser.me/api/portraits/lego/1.jpg',
      'role': 'user',
    };

    _users.add(newUser);
    _currentUser = newUser;
    return true;
  }

  // Sign out
  static Future<void> signOut() async {
    await Future.delayed(
      const Duration(milliseconds: 300),
    ); // Simulate network delay
    _currentUser = null;
  }

  // Get user profile
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    await Future.delayed(
      const Duration(milliseconds: 200),
    ); // Simulate network delay
    return _users.firstWhere((u) => u['id'] == userId, orElse: () => {});
  }

  // Get all items
  static Future<List<Item>> getAllItems() async {
    await Future.delayed(
      const Duration(milliseconds: 300),
    ); // Simulate network delay
    return _items
        .map(
          (item) => Item(
            id: item['id'],
            title: item['title'],
            description: item['description'],
            category: item['category'],
            imageUrl: item['imageUrl'],
            location: item['location'],
            dateTime: item['dateTime'],
            contactMethod: item['contactMethod'],
            isFound: item['isFound'],
            userId: item['userId'],
            latitude: item['latitude'],
            longitude: item['longitude'],
          ),
        )
        .toList();
  }

  // Get items by user
  static Future<List<Item>> getUserItems(String userId) async {
    await Future.delayed(
      const Duration(milliseconds: 200),
    ); // Simulate network delay
    return _items
        .where((item) => item['userId'] == userId)
        .map(
          (item) => Item(
            id: item['id'],
            title: item['title'],
            description: item['description'],
            category: item['category'],
            imageUrl: item['imageUrl'],
            location: item['location'],
            dateTime: item['dateTime'],
            contactMethod: item['contactMethod'],
            isFound: item['isFound'],
            userId: item['userId'],
            latitude: item['latitude'],
            longitude: item['longitude'],
          ),
        )
        .toList();
  }

  // Add new item
  static Future<bool> addItem(Item item) async {
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // Simulate network delay

    final newItem = {
      'id': '${_items.length + 1}',
      'title': item.title,
      'description': item.description,
      'category': item.category,
      'imageUrl': item.imageUrl,
      'location': item.location,
      'dateTime': item.dateTime,
      'contactMethod': item.contactMethod,
      'isFound': item.isFound,
      'userId': item.userId,
      'latitude': item.latitude,
      'longitude': item.longitude,
    };

    _items.add(newItem);
    return true;
  }

  // Search items
  static Future<List<Item>> searchItems(String query, String? category) async {
    await Future.delayed(
      const Duration(milliseconds: 200),
    ); // Simulate network delay

    List<Map<String, dynamic>> filteredItems = List.from(_items);

    // Filter by category
    if (category != null && category != 'All') {
      filteredItems = filteredItems
          .where((item) => item['category'] == category)
          .toList();
    }

    // Filter by search query
    if (query.isNotEmpty) {
      filteredItems = filteredItems.where((item) {
        return item['title'].toLowerCase().contains(query.toLowerCase()) ||
            item['description'].toLowerCase().contains(query.toLowerCase());
      }).toList();
    }

    return filteredItems
        .map(
          (item) => Item(
            id: item['id'],
            title: item['title'],
            description: item['description'],
            category: item['category'],
            imageUrl: item['imageUrl'],
            location: item['location'],
            dateTime: item['dateTime'],
            contactMethod: item['contactMethod'],
            isFound: item['isFound'],
            userId: item['userId'],
            latitude: item['latitude'],
            longitude: item['longitude'],
          ),
        )
        .toList();
  }

  // Update user profile
  static Future<bool> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await Future.delayed(
      const Duration(milliseconds: 400),
    ); // Simulate network delay

    final userIndex = _users.indexWhere((u) => u['id'] == userId);
    if (userIndex != -1) {
      _users[userIndex].addAll(data);
      if (_currentUser?['id'] == userId) {
        _currentUser = _users[userIndex];
      }
      return true;
    }
    return false;
  }
}
