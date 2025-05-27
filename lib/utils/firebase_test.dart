import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirebaseTestService {
  static Future<void> testFirebaseConnection() async {
    try {
      // Проверяем инициализацию Firebase
      debugPrint('🔥 Проверка инициализации Firebase...');
      final app = Firebase.app();
      debugPrint('✅ Firebase инициализирован: ${app.name}');
      
      // Проверяем подключение к Firestore с улучшенными настройками
      debugPrint('📊 Проверка подключения к Firestore...');
      final firestore = FirebaseFirestore.instance;
      
      // Настраиваем Firestore для предотвращения WebChannel ошибок
      firestore.settings = const Settings(
        persistenceEnabled: false,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        sslEnabled: true,
      );
      
      // Принудительно включаем сеть и ждем готовности
      try {
        await firestore.enableNetwork();
        debugPrint('📡 Firestore сеть включена принудительно');
        
        // Ждем немного для стабилизации соединения
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        debugPrint('⚠️ Предупреждение при включении сети: $e');
      }
      
      // Тестируем подключение с простым чтением (менее нагружает API)
      debugPrint('🔍 Тестирование чтения из Firestore...');
      try {
        await firestore.collection('test').doc('connection').get().timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            throw Exception('Таймаут при чтении из Firestore (8 секунд)');
          },
        );
        debugPrint('✅ Чтение из Firestore работает');
      } catch (e) {
        if (e.toString().contains('400') || e.toString().contains('Bad Request')) {
          debugPrint('🚫 Ошибка 400 Bad Request - проблема с запросом к Firestore');
          debugPrint('💡 Возможные причины:');
          debugPrint('   1. Неправильные правила безопасности');
          debugPrint('   2. Проблемы с аутентификацией');
          debugPrint('   3. Неверная конфигурация проекта');
          throw Exception('Firestore API вернул ошибку 400. Проверьте правила безопасности.');
        }
        rethrow;
      }
      
      // Только если чтение прошло успешно, пробуем запись
      debugPrint('📝 Тестирование записи в Firestore...');
      try {
        await firestore.collection('test').doc('connection').set({
          'timestamp': FieldValue.serverTimestamp(),
          'message': 'Тестовое подключение успешно!',
          'userAgent': 'Flutter Web App',
          'testType': 'basic_connection',
          'apiTest': true,
        }).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Таймаут при записи в Firestore (10 секунд)');
          },
        );
        debugPrint('✅ Запись в Firestore работает');
      } catch (e) {
        if (e.toString().contains('400') || e.toString().contains('Bad Request')) {
          debugPrint('🚫 Ошибка 400 при записи - проблема с Write API');
          debugPrint('💡 Решения:');
          debugPrint('   1. Разверните правила безопасности: deploy_firestore_rules.bat');
          debugPrint('   2. Проверьте настройки проекта в Firebase Console');
          debugPrint('   3. Убедитесь, что Firestore включен в проекте');
          throw Exception('Firestore Write API недоступен. Проверьте правила безопасности.');
        }
        rethrow;
      }
      
      debugPrint('✅ Firestore работает корректно');
      
      // Проверяем Firebase Auth
      debugPrint('🔐 Проверка Firebase Auth...');
      final auth = FirebaseAuth.instance;
      
      // Проверяем конфигурацию Authentication
      try {
        // Пытаемся получить список провайдеров (это проверит конфигурацию)
        await auth.fetchSignInMethodsForEmail('test@example.com').timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw Exception('Таймаут при проверке Auth конфигурации');
          },
        );
        debugPrint('✅ Firebase Auth конфигурация корректна');
      } catch (e) {
        if (e.toString().contains('configuration-not-found')) {
          debugPrint('❌ Firebase Auth не настроен в проекте');
          debugPrint('💡 Решение: Включите Authentication в Firebase Console');
          debugPrint('   1. Откройте https://console.firebase.google.com/project/volleyball-a7d8d/authentication');
          debugPrint('   2. Нажмите "Начать работу"');
          debugPrint('   3. Включите Email/Password в Sign-in method');
          throw Exception('Firebase Auth не настроен. Включите Authentication в Firebase Console.');
        } else {
          debugPrint('⚠️ Предупреждение при проверке Auth: $e');
        }
      }
      
      debugPrint('✅ Firebase Auth готов к работе');
      debugPrint('👤 Текущий пользователь: ${auth.currentUser?.email ?? "Не авторизован"}');
      
      debugPrint('🎉 Все сервисы Firebase работают корректно!');
      
    } catch (e) {
      debugPrint('❌ Ошибка при тестировании Firebase: $e');
      
      // Улучшенная диагностика ошибок
      if (e.toString().contains('PERMISSION_DENIED')) {
        debugPrint('🔒 Проблема с правами доступа к Firestore.');
        debugPrint('💡 Решение: Разверните правила безопасности командой: deploy_firestore_rules.bat');
      } else if (e.toString().contains('400') || e.toString().contains('Bad Request')) {
        debugPrint('🚫 Ошибка 400 Bad Request от Firestore API.');
        debugPrint('💡 Решения:');
        debugPrint('   1. Разверните правила безопасности: deploy_firestore_rules.bat');
        debugPrint('   2. Проверьте, что Firestore включен в Firebase Console');
        debugPrint('   3. Убедитесь, что проект volleyball-a7d8d существует');
        debugPrint('   4. Проверьте API ключи в firebase_options.dart');
      } else if (e.toString().contains('UNAVAILABLE') || e.toString().contains('WebChannel')) {
        debugPrint('🌐 Проблема с сетевым подключением к Firebase.');
        debugPrint('💡 Решения:');
        debugPrint('   1. Проверьте интернет-соединение');
        debugPrint('   2. Отключите VPN если используется');
        debugPrint('   3. Проверьте настройки брандмауэра');
        debugPrint('   4. Попробуйте перезапустить приложение');
      } else if (e.toString().contains('timeout')) {
        debugPrint('⏰ Превышено время ожидания подключения к Firebase.');
        debugPrint('💡 Решение: Проверьте скорость интернет-соединения');
      } else if (e.toString().contains('transport errored')) {
        debugPrint('🚫 Ошибка транспорта WebChannel.');
        debugPrint('💡 Решения:');
        debugPrint('   1. Очистите кэш браузера');
        debugPrint('   2. Попробуйте другой браузер');
        debugPrint('   3. Перезапустите приложение');
      }
      
      rethrow;
    }
  }
  
  static Future<void> testFirestoreOperations() async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Настраиваем таймауты и отключаем persistence
      firestore.settings = const Settings(
        persistenceEnabled: false,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        sslEnabled: true,
      );
      
      // Принудительно включаем сеть перед операциями
      try {
        await firestore.enableNetwork();
        // Ждем стабилизации соединения
        await Future.delayed(const Duration(milliseconds: 1000));
      } catch (e) {
        debugPrint('⚠️ Предупреждение при включении сети: $e');
      }
      
      // Сначала проверяем доступность API простым чтением
      debugPrint('🔍 Проверка доступности Firestore API...');
      try {
        await firestore.collection('test_rooms').limit(1).get().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw Exception('API недоступен - таймаут при проверке');
          },
        );
        debugPrint('✅ Firestore API доступен');
      } catch (e) {
        if (e.toString().contains('400')) {
          debugPrint('🚫 Firestore API вернул ошибку 400');
          debugPrint('💡 Скорее всего проблема с правилами безопасности');
          throw Exception('Firestore API недоступен (400). Разверните правила безопасности.');
        }
        rethrow;
      }
      
      // Тест записи с улучшенной обработкой ошибок
      debugPrint('📝 Тестирование записи в Firestore...');
      DocumentReference? docRef;
      try {
        docRef = await firestore.collection('test_rooms').add({
          'title': 'Тестовая комната',
          'description': 'Это тестовая комната для проверки Firestore',
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'active',
          'testId': DateTime.now().millisecondsSinceEpoch,
          'webChannelTest': true,
          'apiVersion': 'v1',
        }).timeout(
          const Duration(seconds: 12),
          onTimeout: () {
            throw Exception('Таймаут при записи в Firestore. Возможны проблемы с Write API.');
          },
        );
        
        debugPrint('✅ Запись в Firestore успешна. ID документа: ${docRef.id}');
      } catch (e) {
        if (e.toString().contains('400') || e.toString().contains('Bad Request')) {
          debugPrint('🚫 Ошибка 400 при записи в test_rooms');
          debugPrint('💡 Проблема с Write API или правилами безопасности');
          throw Exception('Write API недоступен. Проверьте правила Firestore.');
        }
        rethrow;
      }
      
      // Тест чтения с таймаутом
      debugPrint('📖 Тестирование чтения из Firestore...');
      final snapshot = await firestore
          .collection('test_rooms')
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get()
          .timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw Exception('Таймаут при чтении из Firestore. Проверьте сетевое подключение.');
        },
      );
      
      debugPrint('✅ Чтение из Firestore успешно. Найдено документов: ${snapshot.docs.length}');
      
      // Показываем данные последних документов
      for (var doc in snapshot.docs) {
        final data = doc.data();
        debugPrint('📄 Документ ${doc.id}: ${data['title'] ?? 'Без названия'}');
      }
      
      // Тест удаления тестового документа (если он был создан)
      debugPrint('🗑️ Удаление тестового документа...');
      try {
        await docRef.delete().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw Exception('Таймаут при удалении документа');
          },
        );
        debugPrint('✅ Тестовый документ удален');
      } catch (e) {
        debugPrint('⚠️ Не удалось удалить тестовый документ: $e');
        // Не прерываем тест из-за ошибки удаления
      }
          
    } catch (e) {
      debugPrint('❌ Ошибка при тестировании операций Firestore: $e');
      
      // Дополнительная диагностика
      if (e.toString().contains('indexes')) {
        debugPrint('📇 Возможно, нужно создать индексы в Firestore Console.');
      } else if (e.toString().contains('400') || e.toString().contains('Bad Request')) {
        debugPrint('🚫 Ошибка 400 Bad Request от Firestore.');
        debugPrint('💡 Критические действия:');
        debugPrint('   1. ОБЯЗАТЕЛЬНО разверните правила: deploy_firestore_rules.bat');
        debugPrint('   2. Проверьте, что Firestore включен в проекте');
        debugPrint('   3. Убедитесь в правильности API ключей');
      } else if (e.toString().contains('WebChannel') || e.toString().contains('transport')) {
        debugPrint('🚫 Проблема с WebChannel транспортом.');
        debugPrint('💡 Попробуйте:');
        debugPrint('   1. Перезапустить приложение');
        debugPrint('   2. Очистить кэш браузера');
        debugPrint('   3. Проверить настройки сети');
      }
      
      rethrow;
    }
  }
  
  /// Проверка сетевого подключения к Firebase с улучшенной диагностикой
  static Future<bool> checkNetworkConnection() async {
    try {
      debugPrint('🌐 Проверка сетевого подключения к Firebase...');
      
      final firestore = FirebaseFirestore.instance;
      
      // Настраиваем Firestore для минимальных сетевых операций
      firestore.settings = const Settings(
        persistenceEnabled: false,
        cacheSizeBytes: 1048576, // 1MB кэш для тестирования
        sslEnabled: true,
      );
      
      // Принудительно включаем сеть
      await firestore.enableNetwork();
      
      // Простой тест подключения с очень коротким таймаутом
      await firestore.collection('_test_connection').doc('ping').get().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Нет подключения к Firebase (таймаут 5 сек)');
        },
      );
      
      debugPrint('✅ Сетевое подключение к Firebase работает');
      return true;
    } catch (e) {
      debugPrint('❌ Проблема с сетевым подключением: $e');
      
      if (e.toString().contains('400') || e.toString().contains('Bad Request')) {
        debugPrint('🚫 API вернул ошибку 400 - проблема с конфигурацией');
        debugPrint('💡 Рекомендации:');
        debugPrint('   1. Разверните правила Firestore');
        debugPrint('   2. Проверьте настройки проекта');
        debugPrint('   3. Убедитесь, что Firestore включен');
      } else if (e.toString().contains('WebChannel') || e.toString().contains('transport')) {
        debugPrint('🚫 Обнаружена проблема с WebChannel транспортом');
        debugPrint('💡 Рекомендации:');
        debugPrint('   1. Перезапустите приложение');
        debugPrint('   2. Проверьте стабильность интернет-соединения');
        debugPrint('   3. Попробуйте другой браузер');
      }
      
      return false;
    }
  }
  
  /// Принудительная очистка соединений Firestore
  static Future<void> resetFirestoreConnection() async {
    try {
      debugPrint('🔄 Сброс соединения Firestore...');
      final firestore = FirebaseFirestore.instance;
      
      // Отключаем сеть
      await firestore.disableNetwork();
      debugPrint('📴 Сеть Firestore отключена');
      
      // Ждем дольше для полной очистки соединений
      await Future.delayed(const Duration(seconds: 2));
      
      // Включаем сеть заново
      await firestore.enableNetwork();
      debugPrint('📡 Сеть Firestore включена заново');
      
      // Ждем стабилизации
      await Future.delayed(const Duration(seconds: 1));
      
      // Настраиваем заново с оптимальными параметрами
      firestore.settings = const Settings(
        persistenceEnabled: false,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        sslEnabled: true,
      );
      
      debugPrint('✅ Соединение Firestore сброшено успешно');
    } catch (e) {
      debugPrint('❌ Ошибка при сбросе соединения: $e');
    }
  }
  
  /// Диагностика ошибок Firebase Authentication
  static Future<void> diagnoseAuthError() async {
    try {
      debugPrint('🔍 Диагностика Firebase Authentication...');
      
      final auth = FirebaseAuth.instance;
      
      debugPrint('📋 Проверка конфигурации Authentication:');
      debugPrint('   App: ${Firebase.app().name}');
      debugPrint('   Project ID: ${Firebase.app().options.projectId}');
      
      // Проверяем доступность Authentication API
      try {
        await auth.fetchSignInMethodsForEmail('test@example.com').timeout(
          const Duration(seconds: 3),
        );
        debugPrint('✅ Authentication API доступен');
      } catch (e) {
        if (e.toString().contains('configuration-not-found')) {
          debugPrint('❌ Authentication не настроен в проекте');
          debugPrint('💡 КРИТИЧНО: Включите Authentication в Firebase Console:');
          debugPrint('   1. https://console.firebase.google.com/project/volleyball-a7d8d/authentication');
          debugPrint('   2. Нажмите "Начать работу"');
          debugPrint('   3. Включите Email/Password в Sign-in method');
        } else if (e.toString().contains('auth/invalid-api-key')) {
          debugPrint('❌ Неверный API ключ для Authentication');
          debugPrint('💡 Проверьте API ключ в firebase_options.dart');
        } else {
          debugPrint('❌ Другая ошибка Authentication: $e');
        }
      }
      
      // Проверяем текущего пользователя
      final currentUser = auth.currentUser;
      if (currentUser != null) {
        debugPrint('👤 Текущий пользователь:');
        debugPrint('   Email: ${currentUser.email}');
        debugPrint('   UID: ${currentUser.uid}');
        debugPrint('   Verified: ${currentUser.emailVerified}');
      } else {
        debugPrint('👤 Пользователь не авторизован');
      }
      
    } catch (e) {
      debugPrint('❌ Ошибка при диагностике Authentication: $e');
    }
  }

  /// Специальная диагностика ошибок 400 Bad Request
  static Future<void> diagnose400Error() async {
    try {
      debugPrint('🔍 Диагностика ошибки 400 Bad Request...');
      
      // Проверяем базовую конфигурацию Firebase
      final app = Firebase.app();
      final options = app.options;
      
      debugPrint('📋 Конфигурация Firebase:');
      debugPrint('   Project ID: ${options.projectId}');
      debugPrint('   API Key: ${options.apiKey.substring(0, 10)}...');
      debugPrint('   Auth Domain: ${options.authDomain}');
      
      // Проверяем доступность проекта
      final firestore = FirebaseFirestore.instance;
      
      debugPrint('🔍 Проверка доступности проекта...');
      try {
        // Пытаемся получить настройки проекта
        await firestore.collection('_system').doc('test').get().timeout(
          const Duration(seconds: 3),
        );
        debugPrint('✅ Проект доступен');
      } catch (e) {
        if (e.toString().contains('400')) {
          debugPrint('❌ Проект недоступен (400)');
          debugPrint('💡 Возможные причины:');
          debugPrint('   1. Неправильный Project ID в firebase_options.dart');
          debugPrint('   2. Firestore не включен в проекте');
          debugPrint('   3. Неверные API ключи');
          debugPrint('   4. Проект не существует или удален');
        } else {
          debugPrint('⚠️ Другая ошибка при проверке проекта: $e');
        }
      }
      
    } catch (e) {
      debugPrint('❌ Ошибка при диагностике: $e');
    }
  }
} 