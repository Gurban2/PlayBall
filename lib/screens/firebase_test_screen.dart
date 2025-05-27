import 'package:flutter/material.dart';
import '../utils/firebase_test.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  
  String _testResults = '';
  bool _isLoading = false;
  bool _networkConnected = false;

  @override
  void initState() {
    super.initState();
    _checkNetworkConnection();
  }

  void _addResult(String result) {
    setState(() {
      _testResults += '${DateTime.now().toString().substring(11, 19)} $result\n';
    });
  }

  Future<void> _checkNetworkConnection() async {
    final connected = await FirebaseTestService.checkNetworkConnection();
    setState(() {
      _networkConnected = connected;
    });
  }

  Future<void> _testFirebaseConnection() async {
    setState(() {
      _isLoading = true;
      _testResults = '';
    });

    try {
      _addResult('🔥 Начинаем тестирование Firebase...');
      await FirebaseTestService.testFirebaseConnection();
      _addResult('✅ Подключение к Firebase успешно!');
      
      await FirebaseTestService.testFirestoreOperations();
      _addResult('✅ Операции с Firestore работают!');
      
    } catch (e) {
      _addResult('❌ Ошибка: $e');
      
      // Предлагаем решения
      if (e.toString().contains('PERMISSION_DENIED')) {
        _addResult('💡 Решение: Проверьте правила безопасности в Firebase Console');
      } else if (e.toString().contains('timeout')) {
        _addResult('💡 Решение: Проверьте интернет-соединение');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testAuth() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addResult('🔐 Тестирование аутентификации...');
      
      // Проверяем текущего пользователя
      final isLoggedIn = await _authService.isUserLoggedIn();
      _addResult('👤 Пользователь авторизован: $isLoggedIn');
      
      if (isLoggedIn) {
        final user = await _authService.getCurrentUserModel();
        _addResult('📧 Email: ${user?.email ?? "Не указан"}');
        _addResult('👤 Имя: ${user?.name ?? "Не указано"}');
      }
      
      _addResult('✅ Тест аутентификации завершен');
      
    } catch (e) {
      _addResult('❌ Ошибка аутентификации: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testFirestore() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addResult('📊 Тестирование Firestore...');
      
      // Получаем активные комнаты
      final activeRooms = await _firestoreService.getActiveRooms();
      _addResult('🏐 Активных комнат: ${activeRooms.length}');
      
      // Получаем запланированные комнаты
      final plannedRooms = await _firestoreService.getPlannedRooms();
      _addResult('📅 Запланированных комнат: ${plannedRooms.length}');
      
      _addResult('✅ Тест Firestore завершен');
      
    } catch (e) {
      _addResult('❌ Ошибка Firestore: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _runFullDiagnostic() async {
    setState(() {
      _isLoading = true;
      _testResults = '';
    });

    try {
      _addResult('🔍 Запуск полной диагностики Firebase...');
      
      // 1. Проверка сети
      _addResult('1️⃣ Проверка сетевого подключения...');
      await _checkNetworkConnection();
      _addResult(_networkConnected ? '✅ Сеть доступна' : '❌ Проблемы с сетью');
      
      // 2. Тест базового подключения
      _addResult('2️⃣ Тест базового подключения к Firebase...');
      await FirebaseTestService.testFirebaseConnection();
      _addResult('✅ Базовое подключение работает');
      
      // 3. Тест операций Firestore
      _addResult('3️⃣ Тест операций Firestore...');
      await FirebaseTestService.testFirestoreOperations();
      _addResult('✅ Операции Firestore работают');
      
      // 4. Тест аутентификации
      _addResult('4️⃣ Тест аутентификации...');
      final isLoggedIn = await _authService.isUserLoggedIn();
      _addResult(isLoggedIn ? '✅ Пользователь авторизован' : 'ℹ️ Пользователь не авторизован');
      
      _addResult('🎉 Полная диагностика завершена успешно!');
      
    } catch (e) {
      _addResult('❌ Ошибка при диагностике: $e');
      
      // Предлагаем сброс соединения при ошибках WebChannel
      if (e.toString().contains('WebChannel') || e.toString().contains('transport')) {
        _addResult('💡 Обнаружена проблема с WebChannel. Попробуйте сбросить соединение.');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetFirestoreConnection() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addResult('🔄 Сброс соединения Firestore...');
      await FirebaseTestService.resetFirestoreConnection();
      _addResult('✅ Соединение сброшено успешно');
      
      // Проверяем соединение после сброса
      _addResult('🔍 Проверка соединения после сброса...');
      await _checkNetworkConnection();
      _addResult(_networkConnected ? '✅ Соединение восстановлено' : '❌ Проблемы остались');
      
    } catch (e) {
      _addResult('❌ Ошибка при сбросе соединения: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _diagnose400Error() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addResult('🔍 Диагностика ошибки 400 Bad Request...');
      await FirebaseTestService.diagnose400Error();
      _addResult('✅ Диагностика завершена - проверьте логи выше');
      
    } catch (e) {
      _addResult('❌ Ошибка при диагностике: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _diagnoseAuthError() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addResult('🔍 Диагностика Firebase Authentication...');
      await FirebaseTestService.diagnoseAuthError();
      _addResult('✅ Диагностика Authentication завершена');
      
    } catch (e) {
      _addResult('❌ Ошибка при диагностике Auth: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Диагностика Firebase'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Индикатор состояния сети
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _networkConnected ? Icons.wifi : Icons.wifi_off,
                  color: _networkConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  _networkConnected ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: _networkConnected ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Заголовок и статус
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Диагностика Firebase',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _networkConnected ? Icons.check_circle : Icons.error,
                          color: _networkConnected ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _networkConnected 
                              ? 'Подключение к Firebase доступно'
                              : 'Проблемы с подключением к Firebase',
                          style: TextStyle(
                            color: _networkConnected ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Кнопки тестирования
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _runFullDiagnostic,
                  icon: const Icon(Icons.medical_services),
                  label: const Text('Полная диагностика'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testFirebaseConnection,
                  icon: const Icon(Icons.cloud),
                  label: const Text('Тест подключения'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testAuth,
                  icon: const Icon(Icons.person),
                  label: const Text('Тест Auth'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testFirestore,
                  icon: const Icon(Icons.storage),
                  label: const Text('Тест Firestore'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _checkNetworkConnection,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Обновить сеть'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _resetFirestoreConnection,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Сброс соединения'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _diagnose400Error,
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Диагностика 400'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _diagnoseAuthError,
                  icon: const Icon(Icons.security),
                  label: const Text('Диагностика Auth'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _testResults = '';
                    });
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Очистить'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Индикатор загрузки
            if (_isLoading)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Выполняется тестирование...'),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Результаты тестирования
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Результаты тестирования:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _testResults.isEmpty 
                                  ? 'Нажмите "Полная диагностика" для комплексной проверки\nили выберите отдельные тесты выше'
                                  : _testResults,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 