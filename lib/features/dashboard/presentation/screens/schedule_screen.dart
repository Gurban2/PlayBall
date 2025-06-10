import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/providers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../shared/widgets/universal_card.dart';
import '../../../../shared/widgets/navigation/game_nav_bar.dart';
import '../../../rooms/domain/entities/room_model.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> 
    with WidgetsBindingObserver {
  GameNavTab _activeTab = GameNavTab.all;
  String _sortBy = 'Время начала';
  bool _sortAscending = true;
  bool _showSortOptions = false;
  bool _showSearchField = false;
  
  // Добавляем контроллер для поиска
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    
    // Подписываемся на изменения состояния приложения
    WidgetsBinding.instance.addObserver(this);
    
    // Подписываемся на изменения поискового запроса
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    
    // Обновляем данные при инициализации
    // ignore: unused_result
    ref.refresh(activeRoomsProvider);
    // ignore: unused_result
    ref.refresh(plannedRoomsProvider);
    // ignore: unused_result
    ref.refresh(userRoomsProvider);
  }

  @override
  void dispose() {
    // Отписываемся от изменений состояния приложения
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Обновляем данные при возвращении в приложение
    if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 Приложение возобновлено - обновляем расписание');
      _refreshAllData();
    }
  }

  /// Обновляет все данные на экране
  void _refreshAllData() {
    // ignore: unused_result
    ref.refresh(activeRoomsProvider);
    // ignore: unused_result
    ref.refresh(plannedRoomsProvider);
    // ignore: unused_result
    ref.refresh(userRoomsProvider);
  }

  // Функция для обработки ошибок Firebase с кликабельными ссылками
  void _showFirebaseError(String error) {
    // Проверяем, содержит ли ошибка ссылку на создание индекса
    if (error.contains('https://console.firebase.google.com')) {
      final urlMatch = RegExp(r'https://console\.firebase\.google\.com[^\s]+').firstMatch(error);
      final url = urlMatch?.group(0);
      
      if (url != null) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Требуется создать индекс Firestore'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Для корректной работы расписания необходимо создать индекс в Firebase Firestore.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Нажмите кнопку ниже, чтобы открыть Firebase Console и создать индекс:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    error,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'NotoSansSymbols',
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Закрыть'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  } catch (e) {
                    if (mounted) {
                      ErrorHandler.showError(context, 'Не удалось открыть ссылку: $e');
                    }
                  }
                  if (mounted) Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Открыть Firebase Console'),
              ),
            ],
          ),
        );
        return;
      }
    }
    
    // Для обычных ошибок показываем стандартное сообщение
    if (mounted) {
      ErrorHandler.showError(context, 'Ошибка загрузки: $error');
    }
  }

  void _navigateToRoomDetails(String roomId) {
    final user = ref.read(currentUserProvider).value;
    if (user == null) {
      _showLoginDialog();
    } else {
      context.push('${AppRoutes.room}/$roomId');
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Требуется авторизация'),
        content: const Text(
          'Чтобы присоединиться к игре, необходимо войти в аккаунт.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push(AppRoutes.login);
            },
            child: const Text('Войти'),
          ),
        ],
      ),
    );
  }

  Future<List<RoomModel>> _filterAndSortRooms(List<RoomModel> rooms) async {
    List<RoomModel> filteredRooms = [...rooms];
    
    // Фильтрация по поисковому запросу
    if (_searchQuery.isNotEmpty) {
      final List<RoomModel> searchResults = [];
      
      for (final room in filteredRooms) {
        // Поиск по названию
        if (room.title.toLowerCase().contains(_searchQuery)) {
          searchResults.add(room);
          continue;
        }
        
        // Поиск по описанию
        if (room.description.toLowerCase().contains(_searchQuery)) {
          searchResults.add(room);
          continue;
        }
        
        // Поиск по имени организатора
        try {
          final userService = ref.read(userServiceProvider);
          final organizer = await userService.getUserById(room.organizerId);
          if (organizer != null && organizer.name.toLowerCase().contains(_searchQuery)) {
            searchResults.add(room);
            continue;
          }
        } catch (e) {
          debugPrint('Ошибка загрузки организатора: $e');
        }
      }
      
      filteredRooms = searchResults;
    }
    
    // Сортировка
    switch (_sortBy) {
      case 'Время начала':
        filteredRooms.sort((a, b) => _sortAscending 
            ? a.startTime.compareTo(b.startTime)
            : b.startTime.compareTo(a.startTime));
        break;
      case 'Название':
        filteredRooms.sort((a, b) => _sortAscending 
            ? a.title.compareTo(b.title)
            : b.title.compareTo(a.title));
        break;
      case 'Локация':
        filteredRooms.sort((a, b) => _sortAscending 
            ? a.location.compareTo(b.location)
            : b.location.compareTo(a.location));
        break;
      case 'Участники':
        filteredRooms.sort((a, b) => _sortAscending 
            ? a.participants.length.compareTo(b.participants.length)
            : b.participants.length.compareTo(a.participants.length));
        break;
      case 'Цена':
        filteredRooms.sort((a, b) => _sortAscending 
            ? a.pricePerPerson.compareTo(b.pricePerPerson)
            : b.pricePerPerson.compareTo(a.pricePerPerson));
        break;
      case 'Тип игры':
        filteredRooms.sort((a, b) => _sortAscending 
            ? a.gameMode.toString().compareTo(b.gameMode.toString())
            : b.gameMode.toString().compareTo(a.gameMode.toString()));
        break;
    }
    
    return filteredRooms;
  }

  @override
  Widget build(BuildContext context) {
    final activeRoomsAsync = ref.watch(activeRoomsProvider);
    final plannedRoomsAsync = ref.watch(plannedRoomsProvider);
    final completedRoomsAsync = ref.watch(userRoomsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkGrey.withValues(alpha: 0.5),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/schedule/schedule_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
            child: Column(
              children: [
            // Новый Game Navigation Bar
            GameNavBar(
              activeTab: _activeTab,
              onTabChanged: (tab) {
                setState(() {
                  _activeTab = tab;
                });
              },
              onNotificationsPressed: () {
                context.push('/notifications');
              },
              onSearchPressed: () {
                setState(() {
                  _showSearchField = !_showSearchField;
                  if (!_showSearchField) {
                    _searchController.clear();
                  }
                });
              },
              onSortPressed: () {
                setState(() {
                  _showSortOptions = !_showSortOptions;
                });
              },
              showSortOptions: _showSortOptions,
            ),
            
            // Полоса разделитель
                Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.4),
            ),
            
            // Поисковое поле (если активно)
            if (_showSearchField) _buildSearchSection(),
            
            // Панель сортировки (если активна)  
            if (_showSortOptions) _buildSortOptionsSection(),
            
            // Содержимое
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_showSortOptions) {
                    setState(() {
                      _showSortOptions = false;
                    });
                  }
                },
                child: _buildCurrentTabContent(activeRoomsAsync, plannedRoomsAsync, completedRoomsAsync),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent(
    AsyncValue<List<RoomModel>> activeRoomsAsync,
    AsyncValue<List<RoomModel>> plannedRoomsAsync,
    AsyncValue<List<RoomModel>> completedRoomsAsync,
  ) {
    switch (_activeTab) {
      case GameNavTab.all:
        return _buildAllGamesContent(activeRoomsAsync, plannedRoomsAsync);
      case GameNavTab.live:
        return _buildGamesList(activeRoomsAsync, 'Нет активных игр');
      case GameNavTab.upcoming:
        return _buildGamesList(plannedRoomsAsync, 'Нет запланированных игр');
      case GameNavTab.finished:
        return _buildFinishedGamesContent(completedRoomsAsync);
    }
  }

  Widget _buildAllGamesContent(
    AsyncValue<List<RoomModel>> activeRoomsAsync,
    AsyncValue<List<RoomModel>> plannedRoomsAsync,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок "Обычные игры"
          const Text(
            'Обычные игры',
                                style: TextStyle(
              fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
          const SizedBox(height: 8),
          
          // Список обычных игр
          _buildNormalGamesList(activeRoomsAsync, plannedRoomsAsync),
          
          const SizedBox(height: 24),
          
          // Заголовок "Командные игры"
          const Text(
            'Командные игры',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          
          // Список командных игр
          _buildTeamGamesList(activeRoomsAsync, plannedRoomsAsync),
        ],
      ),
    );
  }

  Widget _buildNormalGamesList(
    AsyncValue<List<RoomModel>> activeRoomsAsync,
    AsyncValue<List<RoomModel>> plannedRoomsAsync,
  ) {
    return activeRoomsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Ошибка: $error', style: const TextStyle(color: Colors.white)),
      ),
      data: (activeRooms) {
        return plannedRoomsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Ошибка: $error', style: const TextStyle(color: Colors.white)),
          ),
          data: (plannedRooms) {
            final allRooms = [...activeRooms, ...plannedRooms];
            final normalGames = allRooms
                .where((room) => room.isNormalMode)
                .toList();
            
            return FutureBuilder<List<RoomModel>>(
              future: _filterAndSortRooms(normalGames),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Ошибка: ${snapshot.error}', 
                        style: const TextStyle(color: Colors.white)),
                  );
                }
                
                final filteredAndSortedRooms = snapshot.data ?? [];
                
                if (filteredAndSortedRooms.isEmpty) {
                  return const Center(
                    child: Text(
                      'Нет обычных игр',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }
                
                return Column(
                  children: filteredAndSortedRooms
                      .map((room) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: UniversalCard(
                              title: room.title,
                              subtitle: '${room.location} • ${room.participants.length}/${room.maxParticipants}',
                              onTap: () => _navigateToRoomDetails(room.id),
                              accentColor: _getGameStatusColor(room),
                            ),
                          ))
                      .toList(),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTeamGamesList(
    AsyncValue<List<RoomModel>> activeRoomsAsync,
    AsyncValue<List<RoomModel>> plannedRoomsAsync,
  ) {
    return activeRoomsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Ошибка: $error', style: const TextStyle(color: Colors.white)),
      ),
      data: (activeRooms) {
        return plannedRoomsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Ошибка: $error', style: const TextStyle(color: Colors.white)),
          ),
          data: (plannedRooms) {
            final allRooms = [...activeRooms, ...plannedRooms];
            final teamGames = allRooms
                .where((room) => room.isTeamMode)
                .toList();
            
            return FutureBuilder<List<RoomModel>>(
              future: _filterAndSortRooms(teamGames),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Ошибка: ${snapshot.error}', 
                        style: const TextStyle(color: Colors.white)),
                  );
                }
                
                final filteredAndSortedRooms = snapshot.data ?? [];
                
                if (filteredAndSortedRooms.isEmpty) {
                  return const Center(
                    child: Text(
                      'Нет командных игр',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }
                
                return Column(
                  children: filteredAndSortedRooms
                      .map((room) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: UniversalCard(
                              title: room.title,
                              subtitle: '${room.location} • ${room.participants.length}/${room.maxParticipants}',
                              onTap: () => _navigateToRoomDetails(room.id),
                              accentColor: _getGameStatusColor(room),
                            ),
                          ))
                      .toList(),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFinishedGamesContent(AsyncValue<List<RoomModel>> completedRoomsAsync) {
    return completedRoomsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Ошибка: $error', style: const TextStyle(color: Colors.white)),
      ),
      data: (completedRooms) {
        final finishedGames = completedRooms
            .where((room) => room.status == RoomStatus.completed)
            .toList();
        
        if (finishedGames.isEmpty) {
          return const Center(
            child: Text(
              'Нет завершенных игр',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: finishedGames.length,
          itemBuilder: (context, index) {
            final room = finishedGames[index];
            return UniversalCard(
              title: room.title,
              subtitle: '${room.location} • Завершена',
              onTap: () => _navigateToRoomDetails(room.id),
              accentColor: AppColors.textSecondary,
            );
          },
        );
      },
    );
  }

  Color _getGameStatusColor(RoomModel room) {
    switch (room.status) {
      case RoomStatus.active:
        return AppColors.error; // Красный для активных
      case RoomStatus.planned:
        return AppColors.primary; // Синий для запланированных
      case RoomStatus.completed:
        return AppColors.textSecondary; // Серый для завершенных
      case RoomStatus.cancelled:
        return AppColors.warning; // Желтый для отмененных
    }
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: AppColors.darkGrey.withValues(alpha: 0.9),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Поиск игр...',
          hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 18),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                  onPressed: () {
                    _searchController.clear();
                  },
                  iconSize: 18,
                  padding: const EdgeInsets.all(8),
                )
              : null,
          filled: true,
          fillColor: Colors.black.withValues(alpha: 0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildSortOptionsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.sort, color: AppColors.primary, size: 16),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300, width: 0.5),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _sortBy,
                  isExpanded: true,
                  icon: const Icon(Icons.expand_more, size: 14),
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                  items: ['Время начала', 'Название', 'Локация', 'Участники', 'Цена', 'Тип игры']
                      .map((sortOption) => DropdownMenuItem(
                            value: sortOption,
                            child: Text(sortOption),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300, width: 0.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<bool>(
                value: _sortAscending,
                icon: const Icon(Icons.expand_more, size: 14),
                style: const TextStyle(fontSize: 12, color: Colors.black),
                items: [
                  const DropdownMenuItem<bool>(
                    value: true,
                    child: Text('↑'),
                  ),
                  const DropdownMenuItem<bool>(
                    value: false,
                    child: Text('↓'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _sortAscending = value!;
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              setState(() {
                _sortBy = 'Время начала';
                _sortAscending = true;
              });
            },
            child: Container(
              height: 28,
              width: 28,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.refresh, size: 14, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              setState(() {
                _showSortOptions = false;
              });
            },
            child: Container(
              height: 28,
              width: 28,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesList(AsyncValue<List<RoomModel>> roomsAsync, String emptyMessage) {
    return roomsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[800]?.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _showFirebaseError(error.toString()),
                      child: const Text(
                        'Ошибка загрузки. Нажмите для подробностей.',
                        style: TextStyle(
                          color: Colors.orange,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (roomsAsync == ref.read(activeRoomsProvider)) {
                          // ignore: unused_result
                          ref.refresh(activeRoomsProvider);
                        } else {
                          // ignore: unused_result
                          ref.refresh(plannedRoomsProvider);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            ),
            data: (rooms) {
              return FutureBuilder<List<RoomModel>>(
                future: _filterAndSortRooms(rooms),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey[800]?.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                            const SizedBox(height: 16),
                            Text(
                              'Ошибка обработки данных: ${snapshot.error}',
                              style: const TextStyle(color: Colors.orange),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  final sortedRooms = snapshot.data ?? [];
              
                  if (sortedRooms.isEmpty) {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey[800]?.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.sports_volleyball_outlined,
                              size: 64,
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty ? 'Ничего не найдено' : emptyMessage,
                              style: const TextStyle(color: Colors.white),
                            ),
                            if (_sortBy != 'Время начала' || !_sortAscending || _searchQuery.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty 
                                    ? 'Попробуйте изменить поисковый запрос'
                                    : 'Попробуйте изменить сортировку',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }
                  
                  return RefreshIndicator(
                    onRefresh: () async {
                      if (roomsAsync == ref.read(activeRoomsProvider)) {
                        // ignore: unused_result
                        ref.refresh(activeRoomsProvider);
                      } else {
                        // ignore: unused_result
                        ref.refresh(plannedRoomsProvider);
                      }
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: sortedRooms.length,
                      itemBuilder: (context, index) {
                        return _buildEnhancedRoomCard(sortedRooms[index]);
                      },
                    ),
                  );
                },
              );
            },
    );
  }

  Widget _buildMyGames() {
    return Consumer(
      builder: (context, ref, child) {
        final userRoomsAsync = ref.watch(userRoomsProvider);
        return userRoomsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[800]?.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _showFirebaseError(error.toString()),
                    child: const Text(
                      'Ошибка загрузки. Нажмите для подробностей.',
                      style: TextStyle(
                        color: Colors.orange,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // ignore: unused_result
                      ref.refresh(userRoomsProvider);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          ),
          data: (userRooms) {
            if (userRooms.isEmpty) {
              return Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[800]?.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sports_volleyball_outlined,
                        size: 64,
                        color: Colors.orange,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Вы еще не участвуете в играх',
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Присоединяйтесь к играм или создайте свою!',
                        style: TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            
            return RefreshIndicator(
              onRefresh: () async {
                // ignore: unused_result
                ref.refresh(userRoomsProvider);
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: userRooms.length,
                itemBuilder: (context, index) {
                  return _buildEnhancedRoomCard(userRooms[index]);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEnhancedRoomCard(RoomModel room) {
    final statusColor = _getStatusColor(room.status);
    final isActive = room.status == RoomStatus.active;
    final isToday = _isSameDay(room.startTime, DateTime.now());
    final accentColor = isActive ? const Color(0xFFFF00C7) : statusColor;
    
    return UniversalCard(
      title: room.title,
      subtitle: room.location,
      accentColor: accentColor,
      onTap: () => _navigateToRoomDetails(room.id),
      badge: isToday ? 'Today' : null,
      badgeColor: AppColors.warning,
      trailing: Text(
        _formatTime(room.startTime),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: accentColor,
          height: 0.8,
        ),
      ),
    );
  }

  // Новый метод для форматирования времени
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(RoomStatus status) {
    switch (status) {
      case RoomStatus.planned:
        return AppColors.secondary;
      case RoomStatus.active:
        return AppColors.primary;
      case RoomStatus.completed:
        return AppColors.success;
      case RoomStatus.cancelled:
        return AppColors.error;
    }
  }

  // Функция для проверки, является ли дата сегодняшней
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
} 