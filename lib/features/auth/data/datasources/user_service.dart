import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_model.dart';
import '../../../profile/domain/entities/friend_request_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';
  static const String _friendRequestsCollection = 'friend_requests';

  // Получение пользователя по ID
  Future<UserModel?> getUserById(String userId) async {
    final doc = await _firestore.collection(_usersCollection).doc(userId).get();
    return doc.exists ? UserModel.fromMap(doc.data()!) : null;
  }

  // Создание пользователя
  Future<void> createUser(UserModel user) async {
    await _firestore.collection(_usersCollection).doc(user.id).set(user.toMap());
  }

  // Обновление пользователя
  Future<void> updateUser({
    required String userId,
    String? name,
    String? photoUrl,
    UserRole? role,
  }) async {
    final Map<String, dynamic> updates = {};
    
    if (name != null) updates['name'] = name;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (role != null) updates['role'] = role.toString().split('.').last;
    
    updates['updatedAt'] = Timestamp.now();
    
    await _firestore.collection(_usersCollection).doc(userId).update(updates);
  }

  // Стрим пользователя
  Stream<UserModel?> watchUser(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
  }

  // Получение списка пользователей
  Future<List<UserModel>> getUsers({int limit = 20}) async {
    final snapshot = await _firestore
        .collection(_usersCollection)
        .limit(limit)
        .get();
    
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data()))
        .toList();
  }

  // Проверка уникальности ника
  Future<bool> isNicknameUnique(String nickname, {String? excludeUserId}) async {
    var query = _firestore
        .collection(_usersCollection)
        .where('name', isEqualTo: nickname);
    
    final querySnapshot = await query.limit(1).get();
    
    if (querySnapshot.docs.isEmpty) return true;
    
    if (excludeUserId != null && 
        querySnapshot.docs.length == 1 && 
        querySnapshot.docs.first.id == excludeUserId) {
      return true;
    }
    
    return false;
  }

  // Работа с друзьями
  Future<void> addFriend(String userId, String friendId) async {
    if (userId == friendId) {
      throw Exception('Нельзя добавить себя в друзья');
    }

    final batch = _firestore.batch();

    batch.update(_firestore.collection(_usersCollection).doc(userId), {
      'friends': FieldValue.arrayUnion([friendId]),
      'updatedAt': Timestamp.now(),
    });

    batch.update(_firestore.collection(_usersCollection).doc(friendId), {
      'friends': FieldValue.arrayUnion([userId]),
      'updatedAt': Timestamp.now(),
    });

    await batch.commit();
  }

  Future<void> removeFriend(String userId, String friendId) async {
    final batch = _firestore.batch();

    batch.update(_firestore.collection(_usersCollection).doc(userId), {
      'friends': FieldValue.arrayRemove([friendId]),
      'updatedAt': Timestamp.now(),
    });

    batch.update(_firestore.collection(_usersCollection).doc(friendId), {
      'friends': FieldValue.arrayRemove([userId]),
      'updatedAt': Timestamp.now(),
    });

    await batch.commit();
  }

  Future<List<UserModel>> getFriends(String userId) async {
    final userDoc = await _firestore.collection(_usersCollection).doc(userId).get();
    if (!userDoc.exists) return [];

    final user = UserModel.fromMap(userDoc.data()!);
    return await getUsersByIds(user.friends);
  }

  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    
    final users = <UserModel>[];
    
    // Разбиваем на части из-за лимита Firestore whereIn (10)
    for (int i = 0; i < userIds.length; i += 10) {
      final batch = userIds.skip(i).take(10).toList();
      
      final snapshot = await _firestore
          .collection(_usersCollection)
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      
      for (final doc in snapshot.docs) {
        users.add(UserModel.fromMap(doc.data()));
      }
    }
    
    return users;
  }

  // Поиск пользователей с пагинацией
  Future<List<UserModel>> searchUsers({
    String? query,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query queryRef = _firestore.collection(_usersCollection);
      
      if (query != null && query.isNotEmpty) {
        queryRef = queryRef
            .where('displayName', isGreaterThanOrEqualTo: query)
            .where('displayName', isLessThan: query + '\uf8ff');
      }
      
      queryRef = queryRef.limit(limit);
      
      if (lastDocument != null) {
        queryRef = queryRef.startAfterDocument(lastDocument);
      }
      
      final snapshot = await queryRef.get();
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Ошибка при поиске пользователей: $e');
    }
  }

  // Получение друзей пользователя
  Stream<List<UserModel>> watchUserFriends(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .snapshots()
        .asyncMap((userDoc) async {
      if (!userDoc.exists) return <UserModel>[];
      
      final user = UserModel.fromMap(userDoc.data()!);
      if (user.friends.isEmpty) return <UserModel>[];
      
      final friendsSnapshot = await _firestore
          .collection(_usersCollection)
          .where(FieldPath.documentId, whereIn: user.friends)
          .get();
      
      return friendsSnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    });
  }

  // НОВЫЕ МЕТОДЫ ДЛЯ ЗАПРОСОВ ДРУЖБЫ

  // Отправить запрос дружбы
  Future<void> sendFriendRequest(String fromUserId, String toUserId) async {
    if (fromUserId == toUserId) {
      throw Exception('Нельзя отправить запрос дружбы самому себе');
    }

    // Проверяем, не являются ли пользователи уже друзьями
    final fromUser = await getUserById(fromUserId);
    if (fromUser != null && fromUser.friends.contains(toUserId)) {
      throw Exception('Пользователи уже друзья');
    }

    // Проверяем, нет ли уже активного запроса
    final existingRequest = await _firestore
        .collection(_friendRequestsCollection)
        .where('fromUserId', isEqualTo: fromUserId)
        .where('toUserId', isEqualTo: toUserId)
        .where('status', isEqualTo: 'pending')
        .get();

    if (existingRequest.docs.isNotEmpty) {
      throw Exception('Запрос дружбы уже отправлен');
    }

    // Проверяем, нет ли обратного запроса
    final reverseRequest = await _firestore
        .collection(_friendRequestsCollection)
        .where('fromUserId', isEqualTo: toUserId)
        .where('toUserId', isEqualTo: fromUserId)
        .where('status', isEqualTo: 'pending')
        .get();

    if (reverseRequest.docs.isNotEmpty) {
      throw Exception('Этот пользователь уже отправил вам запрос дружбы');
    }

    // Получаем данные пользователей
    final toUser = await getUserById(toUserId);
    if (fromUser == null || toUser == null) {
      throw Exception('Пользователь не найден');
    }

    // Создаем запрос дружбы
    final friendRequest = FriendRequestModel(
      id: '',
      fromUserId: fromUserId,
      toUserId: toUserId,
      fromUserName: fromUser.name,
      toUserName: toUser.name,
      fromUserPhotoUrl: fromUser.photoUrl,
      toUserPhotoUrl: toUser.photoUrl,
      status: FriendRequestStatus.pending,
      createdAt: DateTime.now(),
    );

    await _firestore.collection(_friendRequestsCollection).add(friendRequest.toMap());
  }

  // Принять запрос дружбы
  Future<void> acceptFriendRequest(String requestId) async {
    final requestDoc = await _firestore.collection(_friendRequestsCollection).doc(requestId).get();
    if (!requestDoc.exists) {
      throw Exception('Запрос дружбы не найден');
    }

    final request = FriendRequestModel.fromMap(requestDoc.data()!, requestId);
    
    final batch = _firestore.batch();

    // Обновляем статус запроса
    batch.update(_firestore.collection(_friendRequestsCollection).doc(requestId), {
      'status': 'accepted',
      'respondedAt': Timestamp.now(),
    });

    // Добавляем друг друга в друзья
    batch.update(_firestore.collection(_usersCollection).doc(request.fromUserId), {
      'friends': FieldValue.arrayUnion([request.toUserId]),
      'updatedAt': Timestamp.now(),
    });

    batch.update(_firestore.collection(_usersCollection).doc(request.toUserId), {
      'friends': FieldValue.arrayUnion([request.fromUserId]),
      'updatedAt': Timestamp.now(),
    });

    await batch.commit();
  }

  // Отклонить запрос дружбы
  Future<void> declineFriendRequest(String requestId) async {
    await _firestore.collection(_friendRequestsCollection).doc(requestId).update({
      'status': 'declined',
      'respondedAt': Timestamp.now(),
    });
  }

  // Получить входящие запросы дружбы
  Future<List<FriendRequestModel>> getIncomingFriendRequests(String userId) async {
    final snapshot = await _firestore
        .collection(_friendRequestsCollection)
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => FriendRequestModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Получить исходящие запросы дружбы
  Future<List<FriendRequestModel>> getOutgoingFriendRequests(String userId) async {
    final snapshot = await _firestore
        .collection(_friendRequestsCollection)
        .where('fromUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => FriendRequestModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Проверить статус дружбы между пользователями
  Future<String> getFriendshipStatus(String userId, String otherUserId) async {
    if (userId == otherUserId) return 'self';

    // Проверяем, являются ли друзьями
    final user = await getUserById(userId);
    if (user != null && user.friends.contains(otherUserId)) {
      return 'friends';
    }

    // Проверяем исходящий запрос
    final outgoingRequest = await _firestore
        .collection(_friendRequestsCollection)
        .where('fromUserId', isEqualTo: userId)
        .where('toUserId', isEqualTo: otherUserId)
        .where('status', isEqualTo: 'pending')
        .get();

    if (outgoingRequest.docs.isNotEmpty) {
      return 'request_sent';
    }

    // Проверяем входящий запрос
    final incomingRequest = await _firestore
        .collection(_friendRequestsCollection)
        .where('fromUserId', isEqualTo: otherUserId)
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .get();

    if (incomingRequest.docs.isNotEmpty) {
      return 'request_received';
    }

    return 'none';
  }

  // Отменить отправленный запрос дружбы
  Future<void> cancelFriendRequest(String fromUserId, String toUserId) async {
    final snapshot = await _firestore
        .collection(_friendRequestsCollection)
        .where('fromUserId', isEqualTo: fromUserId)
        .where('toUserId', isEqualTo: toUserId)
        .where('status', isEqualTo: 'pending')
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // Стрим входящих запросов дружбы
  Stream<List<FriendRequestModel>> watchIncomingFriendRequests(String userId) {
    return _firestore
        .collection(_friendRequestsCollection)
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FriendRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Получить количество входящих запросов дружбы
  Future<int> getIncomingRequestsCount(String userId) async {
    final snapshot = await _firestore
        .collection(_friendRequestsCollection)
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .get();

    return snapshot.docs.length;
  }
} 