import '../models/item.dart';
import '../models/user_profile.dart';

class MockDataService {
  static List<Item> getMockItems() {
    return [
      Item(
        id: '1',
        title: 'Lost Wallet',
        description: 'Black leather wallet lost near cafeteria.',
        category: 'Wallet',
        imageUrl:
            'https://images.unsplash.com/photo-1599231313784-4a25838c1a7f?ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&ixlib=rb-1.2.1&auto=format&fit=crop&w=200&q=80',
        location: 'Cafeteria',
        dateTime: DateTime.now().subtract(const Duration(days: 1)),
        contactMethod: 'In-app chat',
        isFound: false,
        userId: 'u1',
        latitude: 37.4275,
        longitude: -122.1697,
      ),
      Item(
        id: '2',
        title: 'Found Keys',
        description: 'Set of car keys found in parking lot.',
        category: 'Keys',
        imageUrl:
            'https://images.unsplash.com/photo-1568292445831-a0a7f140c85c?ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&ixlib=rb-1.2.1&auto=format&fit=crop&w=200&q=80',
        location: 'Parking Lot',
        dateTime: DateTime.now().subtract(const Duration(hours: 5)),
        contactMethod: 'Phone',
        isFound: true,
        userId: 'u2',
        latitude: 37.4280,
        longitude: -122.1700,
      ),
      Item(
        id: '3',
        title: 'Lost Phone',
        description: 'iPhone 13 with a blue case.',
        category: 'Phone',
        imageUrl:
            'https://images.unsplash.com/photo-1603506941498-5c639152d1ea?ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&ixlib=rb-1.2.1&auto=format&fit=crop&w=200&q=80',
        location: 'Library',
        dateTime: DateTime.now().subtract(const Duration(days: 2)),
        contactMethod: 'Email',
        isFound: false,
        userId: 'u3',
        latitude: 37.4260,
        longitude: -122.1680,
      ),
      Item(
        id: '4',
        title: 'Found Book',
        description: '"The Hobbit" found on a bench.',
        category: 'Book',
        imageUrl:
            'https://images.unsplash.com/photo-1544947950-fa07a98d237f?ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&ixlib=rb-1.2.1&auto=format&fit=crop&w=200&q=80',
        location: 'Main Quad',
        dateTime: DateTime.now().subtract(const Duration(days: 3)),
        contactMethod: 'In-app chat',
        isFound: true,
        userId: 'u4',
        latitude: 37.4270,
        longitude: -122.1710,
      ),
      Item(
        id: '5',
        title: 'Lost ID Card',
        description: 'Student ID card for Jane Doe.',
        category: 'ID Card',
        imageUrl:
            'https://images.unsplash.com/photo-1620336210291-fd30b8b888c7?ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&ixlib=rb-1.2.1&auto=format&fit=crop&w=200&q=80',
        location: 'Library',
        dateTime: DateTime.now().subtract(const Duration(hours: 12)),
        contactMethod: 'Email',
        isFound: false,
        userId: 'u1',
        latitude: 37.4250,
        longitude: -122.1670,
      ),
    ];
  }

  static List<UserProfile> getMockUsers() {
    return [
      UserProfile(
        id: 'u1',
        name: 'Alice Smith',
        email: 'alice@example.com',
        phone: '123-456-7890',
        avatarUrl: 'https://randomuser.me/api/portraits/women/1.jpg',
        role: 'user',
      ),
      UserProfile(
        id: 'u2',
        name: 'Bob Johnson',
        email: 'bob@example.com',
        phone: '987-654-3210',
        avatarUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
        role: 'admin',
      ),
      UserProfile(
        id: 'u3',
        name: 'Charlie Brown',
        email: 'charlie@example.com',
        phone: '555-555-5555',
        avatarUrl: 'https://randomuser.me/api/portraits/men/2.jpg',
        role: 'user',
      ),
      UserProfile(
        id: 'u4',
        name: 'Diana Prince',
        email: 'diana@example.com',
        phone: '111-222-3333',
        avatarUrl: 'https://randomuser.me/api/portraits/women/2.jpg',
        role: 'user',
      ),
    ];
  }
}
