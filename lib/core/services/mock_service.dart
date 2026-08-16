import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'notification_service.dart';
import '../../features/subscription/domain/entities/pricing_config_entity.dart';

class MockUser {
  final String uid;
  final String name;
  final String phone;
  final String role; // 'owner' | 'customer'
  final String fcmToken;

  MockUser({
    required this.uid,
    required this.name,
    required this.phone,
    required this.role,
    this.fcmToken = '',
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'phone': phone,
        'role': role,
        'fcmToken': fcmToken,
      };

  factory MockUser.fromMap(Map<String, dynamic> map) => MockUser(
        uid: map['uid'] ?? '',
        name: map['name'] ?? '',
        phone: map['phone'] ?? '',
        role: map['role'] ?? 'customer',
        fcmToken: map['fcmToken'] ?? '',
      );
}

class MockShop {
  final String id;
  final String name;
  final String category;
  final String ownerId;
  final String address;
  final bool isQueueOpen;
  final int avgServiceTimeMinutes;

  MockShop({
    required this.id,
    required this.name,
    required this.category,
    required this.ownerId,
    required this.address,
    required this.isQueueOpen,
    required this.avgServiceTimeMinutes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'ownerId': ownerId,
        'address': address,
        'isQueueOpen': isQueueOpen,
        'avgServiceTimeMinutes': avgServiceTimeMinutes,
      };

  factory MockShop.fromMap(Map<String, dynamic> map) => MockShop(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        category: map['category'] ?? '',
        ownerId: map['ownerId'] ?? '',
        address: map['address'] ?? '',
        isQueueOpen: map['isQueueOpen'] ?? true,
        avgServiceTimeMinutes: map['avgServiceTimeMinutes'] ?? 10,
      );
}

class MockTicket {
  final String id;
  final String shopId;
  final String customerId;
  final String customerName;
  final int tokenNumber;
  final String status; // 'waiting' | 'in_service' | 'completed' | 'skipped' | 'cancelled'
  final DateTime joinedAt;
  final DateTime? calledAt;

  MockTicket({
    required this.id,
    required this.shopId,
    required this.customerId,
    required this.customerName,
    required this.tokenNumber,
    required this.status,
    required this.joinedAt,
    this.calledAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'shopId': shopId,
        'customerId': customerId,
        'customerName': customerName,
        'tokenNumber': tokenNumber,
        'status': status,
        'joinedAt': joinedAt.toIso8601String(),
        'calledAt': calledAt?.toIso8601String(),
      };

  factory MockTicket.fromMap(Map<String, dynamic> map) => MockTicket(
        id: map['id'] ?? '',
        shopId: map['shopId'] ?? '',
        customerId: map['customerId'] ?? '',
        customerName: map['customerName'] ?? '',
        tokenNumber: map['tokenNumber'] ?? 1,
        status: map['status'] ?? 'waiting',
        joinedAt: DateTime.parse(map['joinedAt']),
        calledAt: map['calledAt'] != null ? DateTime.parse(map['calledAt']) : null,
      );

  MockTicket copyWith({
    String? status,
    DateTime? calledAt,
  }) {
    return MockTicket(
      id: id,
      shopId: shopId,
      customerId: customerId,
      customerName: customerName,
      tokenNumber: tokenNumber,
      status: status ?? this.status,
      joinedAt: joinedAt,
      calledAt: calledAt ?? this.calledAt,
    );
  }
}

class MockDatabaseService {
  static final MockDatabaseService instance = MockDatabaseService._internal();
  MockDatabaseService._internal() {
    _initDefaultData();
  }

  MockUser? currentUser;

  final Map<String, MockUser> _userAccounts = {}; // email/phone lower -> MockUser
  final List<MockShop> _shops = [];
  final Map<String, List<MockTicket>> _queues = {}; // shopId -> List<MockTicket>
  final Map<String, int> _lastTokenCounters = {}; // shopId -> int counter
  final Map<String, Map<String, dynamic>> _subscriptions = {}; // shopId -> subscription map
  final _queueStreamControllers = <String, StreamController<List<MockTicket>>>{};

  void _initDefaultData() {
    _userAccounts['owner@clinic.com'] = MockUser(
      uid: 'user-owner-1',
      name: 'Dr. Rajesh Sharma',
      phone: 'owner@clinic.com',
      role: 'owner',
    );
    _userAccounts['admin@queuetoken.app'] = MockUser(
      uid: 'user-admin-1',
      name: 'Super Admin',
      phone: 'admin@queuetoken.app',
      role: 'admin',
    );

    _loadSavedAccounts();

    const shop1Id = 'shop-101';
    const ownerId = 'user-owner-1';

    _shops.add(MockShop(
      id: shop1Id,
      name: 'Dr. Sharma Clinic',
      category: 'Clinic',
      ownerId: ownerId,
      address: '123 Health Ave, Suite 4',
      isQueueOpen: true,
      avgServiceTimeMinutes: 12,
    ));

    _shops.add(MockShop(
      id: 'shop-102',
      name: 'Urban Cuts Barber',
      category: 'Salon',
      ownerId: 'user-owner-2',
      address: '45 High Street',
      isQueueOpen: true,
      avgServiceTimeMinutes: 20,
    ));

    _shops.add(MockShop(
      id: 'shop-103',
      name: 'QuickFix Electronics',
      category: 'Repair',
      ownerId: 'user-owner-3',
      address: '89 Tech Park',
      isQueueOpen: false,
      avgServiceTimeMinutes: 15,
    ));

    _lastTokenCounters[shop1Id] = 4;
    _queues[shop1Id] = [
      MockTicket(
        id: 't-1',
        shopId: shop1Id,
        customerId: 'cust-1',
        customerName: 'Rahul Verma',
        tokenNumber: 1,
        status: 'completed',
        joinedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        calledAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      MockTicket(
        id: 't-2',
        shopId: shop1Id,
        customerId: 'cust-2',
        customerName: 'Ananya Gupta',
        tokenNumber: 2,
        status: 'in_service',
        joinedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        calledAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      MockTicket(
        id: 't-3',
        shopId: shop1Id,
        customerId: 'cust-3',
        customerName: 'Priya Sharma',
        tokenNumber: 3,
        status: 'waiting',
        joinedAt: DateTime.now().subtract(const Duration(minutes: 20)),
      ),
      MockTicket(
        id: 't-4',
        shopId: shop1Id,
        customerId: 'cust-4',
        customerName: 'Amit Patel',
        tokenNumber: 4,
        status: 'waiting',
        joinedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
    ];
  }

  void registerUserAccount(String email, String name, String role, String uid) async {
    final cleanEmail = email.toLowerCase().trim();
    final user = MockUser(
      uid: uid,
      name: name.isEmpty ? email.split('@').first : name,
      phone: email,
      role: role,
    );
    _userAccounts[cleanEmail] = user;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('saved_user_accounts_json') ?? '{}';
      final Map<String, dynamic> accountsMap = Map<String, dynamic>.from(jsonDecode(savedJson));
      accountsMap[cleanEmail] = user.toMap();
      await prefs.setString('saved_user_accounts_json', jsonEncode(accountsMap));
    } catch (_) {}
  }

  void _loadSavedAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('saved_user_accounts_json');
      if (savedJson != null && savedJson.isNotEmpty) {
        final Map<String, dynamic> accountsMap = jsonDecode(savedJson);
        accountsMap.forEach((email, data) {
          _userAccounts[email] = MockUser.fromMap(Map<String, dynamic>.from(data));
        });
      }
    } catch (_) {}
  }

  MockUser? getUserByEmail(String email) {
    final cleanEmail = email.toLowerCase().trim();
    return _userAccounts[cleanEmail];
  }

  // Auth Operations
  Future<MockUser> signInWithPhone(String phone, String name, String role) async {
    final key = phone.toLowerCase().trim();
    if (_userAccounts.containsKey(key)) {
      final registeredUser = _userAccounts[key]!;
      currentUser = registeredUser;
      return registeredUser;
    }

    final uid = 'user-${const Uuid().v4().substring(0, 8)}';
    final user = MockUser(uid: uid, name: name.isEmpty ? phone.split('@').first : name, phone: phone, role: role);
    _userAccounts[key] = user;
    currentUser = user;
    return user;
  }

  Future<MockUser?> getCurrentUser() async {
    return currentUser;
  }

  Future<void> setUserRole(String role) async {
    if (currentUser != null) {
      currentUser = MockUser(
        uid: currentUser!.uid,
        name: currentUser!.name,
        phone: currentUser!.phone,
        role: role,
        fcmToken: currentUser!.fcmToken,
      );
    }
  }

  // Shop Operations
  Future<List<MockShop>> getShops({String query = ''}) async {
    if (query.isEmpty) return List.unmodifiable(_shops);
    return _shops
        .where((s) => s.name.toLowerCase().contains(query.toLowerCase()) || s.category.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<MockShop?> getShopByOwnerId(String ownerId) async {
    try {
      return _shops.firstWhere((s) => s.ownerId == ownerId);
    } catch (_) {
      return null;
    }
  }

  Future<MockShop?> getShopById(String shopId) async {
    try {
      return _shops.firstWhere((s) => s.id == shopId);
    } catch (_) {
      return null;
    }
  }

  Future<MockShop> createShop(MockShop shop) async {
    final newShop = MockShop(
      id: 'shop-${const Uuid().v4().substring(0, 8)}',
      name: shop.name,
      category: shop.category,
      ownerId: shop.ownerId,
      address: shop.address,
      isQueueOpen: shop.isQueueOpen,
      avgServiceTimeMinutes: shop.avgServiceTimeMinutes,
    );
    _shops.add(newShop);
    _queues[newShop.id] = [];
    _lastTokenCounters[newShop.id] = 0;
    return newShop;
  }

  Future<void> toggleQueueStatus(String shopId, bool isOpen) async {
    final index = _shops.indexWhere((s) => s.id == shopId);
    if (index != -1) {
      final s = _shops[index];
      _shops[index] = MockShop(
        id: s.id,
        name: s.name,
        category: s.category,
        ownerId: s.ownerId,
        address: s.address,
        isQueueOpen: isOpen,
        avgServiceTimeMinutes: s.avgServiceTimeMinutes,
      );
    }
  }

  Future<void> deleteShop(String shopId) async {
    _shops.removeWhere((s) => s.id == shopId);
    _queues.remove(shopId);
    _lastTokenCounters.remove(shopId);
  }

  // Queue Operations
  final _customerActiveTicketsControllers = <String, StreamController<List<MockTicket>>>{};

  Stream<List<MockTicket>> watchShopQueue(String shopId) {
    if (!_queueStreamControllers.containsKey(shopId) || _queueStreamControllers[shopId]!.isClosed) {
      _queueStreamControllers[shopId] = StreamController<List<MockTicket>>.broadcast();
    }
    // Yield current snapshot immediately
    Future.microtask(() {
      if (_queueStreamControllers.containsKey(shopId)) {
        _queueStreamControllers[shopId]!.add(List.unmodifiable(_queues[shopId] ?? []));
      }
    });
    return _queueStreamControllers[shopId]!.stream;
  }

  Stream<List<MockTicket>> watchCustomerActiveTickets(String customerId) {
    if (!_customerActiveTicketsControllers.containsKey(customerId) || _customerActiveTicketsControllers[customerId]!.isClosed) {
      _customerActiveTicketsControllers[customerId] = StreamController<List<MockTicket>>.broadcast();
    }
    Future.microtask(() => _notifyCustomerTicketsChanged(customerId));
    return _customerActiveTicketsControllers[customerId]!.stream;
  }

  void _notifyCustomerTicketsChanged(String customerId) {
    if (_customerActiveTicketsControllers.containsKey(customerId) && !_customerActiveTicketsControllers[customerId]!.isClosed) {
      final activeTickets = <MockTicket>[];
      for (var queue in _queues.values) {
        for (var t in queue) {
          if (t.customerId == customerId && (t.status == 'waiting' || t.status == 'in_service')) {
            activeTickets.add(t);
          }
        }
      }
      _customerActiveTicketsControllers[customerId]!.add(List.unmodifiable(activeTickets));
    }
  }

  void _notifyQueueChanged(String shopId) {
    if (_queueStreamControllers.containsKey(shopId) && !_queueStreamControllers[shopId]!.isClosed) {
      _queueStreamControllers[shopId]!.add(List.unmodifiable(_queues[shopId] ?? []));
    }
    for (var customerId in _customerActiveTicketsControllers.keys) {
      _notifyCustomerTicketsChanged(customerId);
    }
  }

  /// Atomic transaction simulator for joinQueue
  Future<MockTicket> joinQueue(String shopId, String customerId, String customerName) async {
    final shop = await getShopById(shopId);
    if (shop == null || !shop.isQueueOpen) {
      throw Exception('Queue is currently closed.');
    }

    final shopQueue = _queues[shopId] ?? [];
    final alreadyIn = shopQueue.any((t) => t.customerId == customerId && (t.status == 'waiting' || t.status == 'in_service'));
    if (alreadyIn) {
      throw Exception('You already have an active ticket in this queue.');
    }

    final nextTokenNumber = (_lastTokenCounters[shopId] ?? 0) + 1;
    _lastTokenCounters[shopId] = nextTokenNumber;

    final ticket = MockTicket(
      id: 'ticket-${const Uuid().v4().substring(0, 8)}',
      shopId: shopId,
      customerId: customerId,
      customerName: customerName,
      tokenNumber: nextTokenNumber,
      status: 'waiting',
      joinedAt: DateTime.now(),
    );

    shopQueue.add(ticket);
    _queues[shopId] = shopQueue;
    _notifyQueueChanged(shopId);

    return ticket;
  }

  Future<void> updateTicketStatus(String shopId, String ticketId, String newStatus) async {
    final shopQueue = _queues[shopId] ?? [];
    final index = shopQueue.indexWhere((t) => t.id == ticketId);
    if (index != -1) {
      final t = shopQueue[index];
      shopQueue[index] = t.copyWith(
        status: newStatus,
        calledAt: newStatus == 'in_service' ? DateTime.now() : t.calledAt,
      );
      _queues[shopId] = shopQueue;
      _notifyQueueChanged(shopId);

      if (newStatus == 'in_service') {
        final shop = _shops.firstWhere((s) => s.id == shopId, orElse: () => _shops.first);
        NotificationService.instance.showSystemNotification(
          title: '🚨 YOUR TURN NOW! (आपकी बारी!)',
          body: 'Token #${t.tokenNumber} called at ${shop.name}. Step up to counter!',
          hindiVoiceText: 'ध्यान दीजिए! टोकन नंबर ${t.tokenNumber}, ${shop.name} के काउंटर पर पधारें।',
        );
      }
    }
  }

  Future<void> callNextTicket(String shopId) async {
    final shopQueue = _queues[shopId] ?? [];
    
    // Mark current in_service ticket as completed
    final currentInServiceIndex = shopQueue.indexWhere((t) => t.status == 'in_service');
    if (currentInServiceIndex != -1) {
      shopQueue[currentInServiceIndex] = shopQueue[currentInServiceIndex].copyWith(status: 'completed');
    }

    // Call first waiting ticket
    final nextWaitingIndex = shopQueue.indexWhere((t) => t.status == 'waiting');
    MockTicket? calledTicket;
    if (nextWaitingIndex != -1) {
      shopQueue[nextWaitingIndex] = shopQueue[nextWaitingIndex].copyWith(
        status: 'in_service',
        calledAt: DateTime.now(),
      );
      calledTicket = shopQueue[nextWaitingIndex];
    }

    _queues[shopId] = shopQueue;
    _notifyQueueChanged(shopId);

    if (calledTicket != null) {
      final shop = _shops.firstWhere((s) => s.id == shopId, orElse: () => _shops.first);
      NotificationService.instance.showSystemNotification(
        title: '🚨 YOUR TURN NOW! (आपकी बारी!)',
        body: 'Token #${calledTicket.tokenNumber} called at ${shop.name}. Step up to counter!',
        hindiVoiceText: 'ध्यान दीजिए! टोकन नंबर ${calledTicket.tokenNumber}, ${shop.name} के काउंटर पर पधारें।',
      );
    }
  }

  // Subscription Operations
  Map<String, dynamic> getSubscriptionData(String shopId) {
    if (!_subscriptions.containsKey(shopId)) {
      final now = DateTime.now();
      _subscriptions[shopId] = {
        'shopId': shopId,
        'status': 'trial',
        'plan': null,
        'trialEndsAt': now.add(const Duration(days: 30)).toIso8601String(),
        'currentPeriodEnd': null,
        'playPurchaseToken': null,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };
    }
    return _subscriptions[shopId]!;
  }

  Map<String, dynamic> subscribeShop(String shopId, String plan, String? purchaseToken) {
    final now = DateTime.now();
    final days = plan == 'yearly' ? 365 : 30;
    final periodEnd = now.add(Duration(days: days));
    final subData = {
      'shopId': shopId,
      'status': 'active',
      'plan': plan,
      'trialEndsAt': now.subtract(const Duration(days: 1)).toIso8601String(),
      'currentPeriodEnd': periodEnd.toIso8601String(),
      'playPurchaseToken': purchaseToken ?? 'mock-token-${now.millisecondsSinceEpoch}',
      'createdAt': _subscriptions[shopId]?['createdAt'] ?? now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };
    _subscriptions[shopId] = subData;
    return subData;
  }

  PricingConfigEntity _pricingConfig = PricingConfigEntity.defaultConfig();

  PricingConfigEntity getPricingConfig() => _pricingConfig;

  void updatePricingConfig(PricingConfigEntity config) {
    _pricingConfig = config;
  }
}


