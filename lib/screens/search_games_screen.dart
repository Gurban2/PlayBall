import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../utils/constants.dart';
import '../models/room_model.dart';
import '../providers/providers.dart';

class SearchGamesScreen extends ConsumerStatefulWidget {
  const SearchGamesScreen({super.key});

  @override
  ConsumerState<SearchGamesScreen> createState() => _SearchGamesScreenState();
}

class _SearchGamesScreenState extends ConsumerState<SearchGamesScreen> {
  final _searchController = TextEditingController();
  String _selectedLocation = 'Все города';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedLevel = 'Любой уровень';
  Timer? _debounceTimer;
  bool _isSearching = false;
  bool _showFilters = true;

  final List<String> _locations = [
    'Все города',
    ...AppStrings.availableLocations,
  ];

  final List<String> _levels = [
    'Любой уровень',
    'Начинающий',
    'Средний',
    'Продвинутый',
    'Профессиональный',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _navigateToRoomDetails(String roomId) {
    // Проверяем, авторизован ли пользователь
    final user = ref.read(currentUserProvider).value;
    if (user == null) {
      // Если не авторизован, показываем диалог с предложением войти
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

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedLocation = 'Все города';
      _selectedDate = null;
      _selectedTime = null;
      _selectedLevel = 'Любой уровень';
      _isSearching = false;
    });
    _debounceTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon:
                Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          // Закрываем фильтры при клике в сторону
          if (_showFilters) {
            setState(() {
              _showFilters = false;
            });
          }
          // Убираем фокус с текстового поля
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            // Панель фильтров
            if (_showFilters)
              Container(
                padding: AppSizes.screenPadding,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Поиск по названию
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Поиск игр...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        // Отменяем предыдущий таймер
                        _debounceTimer?.cancel();

                        // Показываем индикатор загрузки
                        setState(() {
                          _isSearching = true;
                        });

                        // Устанавливаем новый таймер с задержкой 500мс
                        _debounceTimer =
                            Timer(const Duration(milliseconds: 500), () {
                          setState(() {
                            _isSearching = false;
                          });
                        });
                      },
                    ),
                    const SizedBox(height: AppSizes.mediumSpace),

                    // Фильтры
                    Row(
                      children: [
                        // Локация
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedLocation,
                            decoration: const InputDecoration(
                              labelText: 'Город',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 13),
                            isExpanded: true,
                            items: _locations.map((location) {
                              return DropdownMenuItem(
                                value: location,
                                child: Text(
                                  location,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedLocation = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: AppSizes.smallSpace),

                        // Уровень
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedLevel,
                            decoration: const InputDecoration(
                              labelText: 'Уровень',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.trending_up),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 13),
                            isExpanded: true,
                            items: _levels.map((level) {
                              return DropdownMenuItem(
                                value: level,
                                child: Text(
                                  level,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedLevel = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.mediumSpace),

                    // Дата и время
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectDate,
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _selectedDate != null
                                  ? '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}'
                                  : 'Выбрать дату',
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.smallSpace),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectTime,
                            icon: const Icon(Icons.access_time),
                            label: Text(
                              _selectedTime != null
                                  ? '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                                  : 'Выбрать время',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.smallSpace),

                    // Кнопка очистки фильтров
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.clear_all, size: 16),
                          label: const Text('Очистить фильтры'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Результаты поиска
            Expanded(
              child: _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Widget _buildSearchResults() {
    final roomsAsync = ref.watch(roomsProvider);

    return roomsAsync.when(
      data: (rooms) {
        // TODO: Применить фильтры
        final filteredRooms = _applyFilters(rooms);

        if (filteredRooms.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: AppSizes.mediumSpace),
                Text(
                  'Игры не найдены',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  'Попробуйте изменить фильтры поиска',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: AppSizes.screenPadding,
          itemCount: filteredRooms.length,
          itemBuilder: (context, index) {
            final room = filteredRooms[index];
            return _buildGameCard(room);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Ошибка: $error'),
      ),
    );
  }

  List<RoomModel> _applyFilters(List<RoomModel> rooms) {
    return rooms.where((room) {
      // Фильтр по названию
      if (_searchController.text.isNotEmpty) {
        if (!room.title
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) &&
            !room.description
                .toLowerCase()
                .contains(_searchController.text.toLowerCase())) {
          return false;
        }
      }

      // Фильтр по локации
      if (_selectedLocation != 'Все города') {
        if (!room.location
            .toLowerCase()
            .contains(_selectedLocation.toLowerCase())) {
          return false;
        }
      }

      // Фильтр по дате
      if (_selectedDate != null) {
        if (room.startTime.day != _selectedDate!.day ||
            room.startTime.month != _selectedDate!.month ||
            room.startTime.year != _selectedDate!.year) {
          return false;
        }
      }

      // Фильтр по времени
      if (_selectedTime != null) {
        final roomTime = TimeOfDay.fromDateTime(room.startTime);
        if (roomTime.hour != _selectedTime!.hour) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Widget _buildGameCard(RoomModel room) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _navigateToRoomDetails(room.id),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок и статус
              Row(
                children: [
                  Expanded(
                    child: Text(
                      room.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: room.status == RoomStatus.active
                          ? AppColors.primary
                          : room.status == RoomStatus.planned
                              ? AppColors.secondary
                              : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      room.status == RoomStatus.active
                          ? 'Активна'
                          : room.status == RoomStatus.planned
                              ? 'Запланирована'
                              : 'Завершена',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Информация об игре
              Row(
                children: [
                  // Локация
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            room.location,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Участники
                  _buildParticipantsDisplay(room),
                ],
              ),
              const SizedBox(height: 6),

              // Время и режим игры
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    '${room.startTime.day}.${room.startTime.month}.${room.startTime.year} '
                    '${room.startTime.hour}:${room.startTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    _getGameModeDisplayName(room.gameMode),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGameModeDisplayName(GameMode gameMode) {
    switch (gameMode) {
      case GameMode.normal:
        return AppStrings.normalMode;
      case GameMode.team_friendly:
        return AppStrings.teamFriendlyMode;
      case GameMode.tournament:
        return AppStrings.tournamentMode;
    }
  }

  // Функция для получения количества команд в командном режиме
  Future<int> _getTeamsCount(String roomId) async {
    try {
      final teamService = ref.read(teamServiceProvider);
      final teams = await teamService.getTeamsForRoom(roomId);
      return teams.length;
    } catch (e) {
      return 0;
    }
  }

  // Функция для отображения участников или команд в зависимости от режима
  Widget _buildParticipantsDisplay(RoomModel room) {
    if (room.isTeamMode) {
      // Для командного режима показываем команды
      return FutureBuilder<int>(
        future: _getTeamsCount(room.id),
        builder: (context, snapshot) {
          final teamsCount = snapshot.data ?? 0;
          return Row(
            children: [
              Icon(
                Icons.groups,
                size: 12,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 4),
              Text(
                '$teamsCount/${room.numberOfTeams} команд',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          );
        },
      );
    } else {
      // Для обычного режима показываем игроков
      return Row(
        children: [
          Icon(
            Icons.people,
            size: 12,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 4),
          Text(
            '${room.participants.length}/${room.maxParticipants}',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }
  }
}
