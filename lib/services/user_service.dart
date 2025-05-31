import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

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
} 