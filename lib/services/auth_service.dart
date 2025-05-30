import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Получение текущего пользователя
  User? get currentUser => _auth.currentUser;

  // Проверка, авторизован ли пользователь
  Future<bool> isUserLoggedIn() async {
    return _auth.currentUser != null;
  }

  // Получение полной модели пользователя
  Future<UserModel?> getCurrentUserModel() async {
    try {
      if (_auth.currentUser == null) return null;
      
      // Используем FirestoreService для получения пользователя с проверкой целостности команды
      final firestoreService = FirestoreService();
      final user = await firestoreService.getUserById(_auth.currentUser!.uid);
      
      if (user != null) {
        // Обновляем время последнего входа
        await _updateLastLogin(_auth.currentUser!.uid);
        return user;
      }
      
      // Если пользователь не найден в Firestore, возвращаем тестовые данные
      return UserModel(
        id: _auth.currentUser!.uid,
        email: _auth.currentUser!.email ?? '',
        name: _auth.currentUser!.displayName ?? 'Пользователь',
        role: UserRole.user,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Ошибка получения данных пользователя: $e');
      
      // Возвращаем тестовые данные в случае ошибки
      if (_auth.currentUser != null) {
        return UserModel(
          id: _auth.currentUser!.uid,
          email: _auth.currentUser!.email ?? '',
          name: _auth.currentUser!.displayName ?? 'Тестовый пользователь',
          role: UserRole.user,
          createdAt: DateTime.now(),
        );
      }
      
      return null;
    }
  }

  // Проверка уникальности ника
  Future<bool> isNicknameUnique(String nickname) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('name', isEqualTo: nickname)
          .limit(1)
          .get();
      
      return querySnapshot.docs.isEmpty;
    } catch (e) {
      debugPrint('Ошибка проверки уникальности ника: $e');
      // В случае ошибки считаем, что ник не уникален (безопасный подход)
      return false;
    }
  }

  // Регистрация по email/password
  Future<UserCredential?> registerWithEmailAndPassword(
    String email, 
    String password, 
    String name,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Создание профиля пользователя в Firestore
      await _createUserProfile(userCredential.user!.uid, email, name);
      
      return userCredential;
    } catch (e) {
      debugPrint('Ошибка регистрации: $e');
      rethrow;
    }
  }

  // Создание профиля пользователя в Firestore
  Future<void> _createUserProfile(String uid, String email, String name) async {
    try {
      final newUser = UserModel(
        id: uid,
        email: email,
        name: name,
        role: UserRole.user,
        createdAt: DateTime.now(),
      );
      
      await _firestore.collection('users').doc(uid).set(newUser.toMap());
    } catch (e) {
      debugPrint('Ошибка создания профиля: $e');
      rethrow;
    }
  }

  // Вход по email/password
  Future<UserCredential?> signInWithEmailAndPassword(
    String email, 
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return userCredential;
    } catch (e) {
      debugPrint('Ошибка входа: $e');
      rethrow;
    }
  }

  // Обновление времени последнего входа
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLogin': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Ошибка обновления времени входа: $e');
    }
  }

  // Выход из аккаунта
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Ошибка выхода: $e');
      rethrow;
    }
  }

  // Обновление профиля пользователя
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? photoUrl,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      
      if (name != null) updates['name'] = name;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      updates['updatedAt'] = Timestamp.now();
      
      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      debugPrint('Ошибка обновления профиля: $e');
      rethrow;
    }
  }

  // Сброс пароля
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Ошибка сброса пароля: $e');
      rethrow;
    }
  }

  // Изменение роли пользователя (только для админов)
  Future<void> changeUserRole(String userId, UserRole newRole) async {
    try {
      // Проверка, что текущий пользователь админ
      final currentUserModel = await getCurrentUserModel();
      if (currentUserModel?.role != UserRole.admin) {
        throw Exception('Недостаточно прав для этой операции');
      }
      
      await _firestore.collection('users').doc(userId).update({
        'role': newRole.toString().split('.').last,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Ошибка изменения роли: $e');
      rethrow;
    }
  }
} 