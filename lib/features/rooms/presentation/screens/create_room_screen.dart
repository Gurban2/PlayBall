import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/providers.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/services/s3_upload_service.dart';
import '../../domain/entities/room_model.dart';
import '../../../auth/domain/entities/user_model.dart';
import '../../../../shared/widgets/dialogs/unified_dialogs.dart';

class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _maxTeamsController = TextEditingController();
  final _team1NameController = TextEditingController();
  final _team2NameController = TextEditingController();

  DateTime _startTime = DateTime.now().add(const Duration(hours: 1));
  DateTime _endTime = DateTime.now().add(const Duration(hours: 3));
  GameMode _selectedGameMode = GameMode.normal;
  bool _isLoading = false;



  String? _selectedLocation;
  String? _userTeamName; // Название команды пользователя
  String? _userTeamId; // ID команды пользователя

  // Простые валидаторы
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите название игры';
    }
    if (value.trim().length < 3) {
      return 'Название должно содержать минимум 3 символа';
    }
    return null;
  }

  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите описание игры';
    }
    return null;
  }

  static String? validateMaxParticipants(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите количество участников';
    }
    final participants = int.tryParse(value);
    if (participants == null || participants < 12 || participants > 24) {
      return 'От 12 до 24 участников';
    }
    return null;
  }

  static String? validateMaxTeams(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите количество команд';
    }
    final teams = int.tryParse(value);
    if (teams == null || teams < 2 || teams > 4) {
      return 'От 2 до 4 команд';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _maxParticipantsController.text = '12'; // Минимум 12 участников
    _maxTeamsController.text = '2'; // Минимум 2 команды
    _team1NameController.text = 'Команда 1';
    _team2NameController.text = 'Команда 2';
    _loadActiveRoomsCount();
    _loadUserTeamInfo(); // Загружаем информацию о команде пользователя
  }

  Future<void> _loadActiveRoomsCount() async {
    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.value;
    
    if (user != null) {
      // Active rooms count logic removed
    }
  }

  Future<void> _loadUserTeamInfo() async {
    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.value;
    
    debugPrint('🔍 _loadUserTeamInfo: Начинаем загрузку данных команды');
    debugPrint('👤 Пользователь: ${user?.name} (ID: ${user?.id})');
    
    if (user != null) {
      final teamService = ref.read(teamServiceProvider);
      try {
        final teamInfo = await teamService.getUserTeamInfo(user.id);
        debugPrint('📊 Данные команды получены: $teamInfo');
        
        if (mounted) {
          setState(() {
            _userTeamName = teamInfo['name'];
            _userTeamId = teamInfo['id'];
          });
          debugPrint('✅ Состояние обновлено: teamName = $_userTeamName, teamId = $_userTeamId');
        }
      } catch (e) {
        debugPrint('❌ Ошибка загрузки данных команды: $e');
      }
    } else {
      debugPrint('❌ Пользователь не найден');
    }
  }

  void _updateRoomTitleBasedOnMode(GameMode mode) {
    String currentTitle = _titleController.text;
    
    // Убираем старые суффиксы, если они есть
    currentTitle = currentTitle
        .replaceAll(' - Команды', '')
        .replaceAll(' - Турнир', '')
        .trim();
    
    // Добавляем новый суффикс в зависимости от режима
    switch (mode) {
      case GameMode.normal:
        _titleController.text = currentTitle;
        break;
      case GameMode.team_friendly:
        _titleController.text = currentTitle.isEmpty ? '' : '$currentTitle - Команды';
        break;
      case GameMode.tournament:
        // Турнирный режим временно отключен
        _titleController.text = currentTitle;
        break;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxParticipantsController.dispose();
    _maxTeamsController.dispose();
    _team1NameController.dispose();
    _team2NameController.dispose();
    super.dispose();
  }



  Future<void> _selectDateTime(bool isStartTime) async {
    final DateTime initialDate = isStartTime ? _startTime : _endTime;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (pickedTime != null) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          if (isStartTime) {
            _startTime = newDateTime;
            // Автоматически обновляем время окончания, если оно меньше нового времени начала
            if (_endTime.isBefore(_startTime.add(const Duration(hours: 1)))) {
              _endTime = _startTime.add(const Duration(hours: 2));
            }
          } else {
            _endTime = newDateTime;
          }
        });
      }
    }
  }

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ErrorHandler.required(context, 'Локация');
      return;
    }

    // Валидация времени - проверяем только что время окончания позже времени начала
    if (_endTime.isBefore(_startTime) || _endTime.isAtSameMomentAs(_startTime)) {
      ErrorHandler.validation(context, 'Время окончания должно быть позже времени начала');
      return;
    }

    // Проверяем конфликт времени
    final conflict = await ref.read(roomServiceProvider).checkLocationConflict(
      location: _selectedLocation!,
      startTime: _startTime,
      endTime: _endTime,
    );
    
    if (conflict) {
      _showConflictDialog();
      return;
    }

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    if (user.role == UserRole.user) {
      ErrorHandler.permissionDenied(context);
      return;
    }

    // Проверяем наличие и размер команды у организатора для командного режима
    if (_selectedGameMode == GameMode.team_friendly) {
      final userTeam = await ref.read(teamServiceProvider).getUserTeam(user.id);
      
      if (!mounted) return;
      if (userTeam == null) {
        ErrorHandler.showError(context, 'Для создания командной игры у вас должна быть своя команда. Создайте команду в разделе "Моя команда" в профиле.');
        return;
      }
      
      if (userTeam.members.length < 6) {
        ErrorHandler.showError(context, 'Для командной игры команда должна состоять из 6 игроков. В вашей команде: ${userTeam.members.length}/6');
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final teamService = ref.read(teamServiceProvider);
      
      // Сначала создаем комнату без фото, чтобы получить roomId
      final roomId = await ref.read(roomServiceProvider).createRoom(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _selectedLocation ?? '',
        startTime: _startTime,
        endTime: _endTime,
        organizerId: user.id,
        maxParticipants: _selectedGameMode.isTeamMode 
            ? int.parse(_maxTeamsController.text) * 6 // Автоматически рассчитываем участников (6 игроков на команду)
            : int.parse(_maxParticipantsController.text),
        pricePerPerson: 0.0, // Убираем оплату
        numberOfTeams: _selectedGameMode.isTeamMode 
            ? int.parse(_maxTeamsController.text)
            : 2, // Для обычного режима всегда 2 команды
        gameMode: _selectedGameMode,
        photoUrl: null, // Пока без фото
        teamNames: _selectedGameMode == GameMode.normal 
            ? [
                _team1NameController.text.trim(),
                _team2NameController.text.trim(),
              ]
            : _selectedGameMode == GameMode.team_friendly
                ? [
                    _userTeamName!,
                    'Команда 2',
                  ]
                : [ // GameMode.tournament
                    'Участник 1',
                    'Участник 2',
                  ],
      );
      
      // Загрузка изображений комнат готова к использованию через S3
      // TODO: Добавить UI для выбора изображения и использовать:
      // final photoUrl = await S3UploadService.uploadRoomImage(imageBytes, roomId);

              if (mounted) {
          ErrorHandler.gameCreated(context);
        }
      
      if (mounted) {
        context.go('${AppRoutes.room}/$roomId');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        String errorMessage = 'Ошибка создания игры';
        if (e.toString().contains('Превышен лимит незавершенных игр')) {
          errorMessage = e.toString().replaceFirst('Exception: ', '');
          // Обновляем счетчик активных комнат
          _loadActiveRoomsCount();
          
          // Показываем обычный SnackBar для лимита игр
          ErrorHandler.showError(context, errorMessage);
        } else if (e.toString().contains('уже запланирована игра на это время')) {
          // Показываем popup для конфликтов локаций
          _showLocationConflictDialog(e.toString().replaceFirst('Exception: ', ''));
        } else {
          errorMessage = 'Ошибка создания игры: ${e.toString()}';
          
          ErrorHandler.showError(context, errorMessage);
        }
      }
    }
  }

  void _showLocationConflictDialog(String message) {
    UnifiedDialogs.showWarning(
      context: context,
      title: 'Конфликт локации',
      message: message,
      confirmText: 'Изменить время',
      cancelText: 'Понятно',
      additionalInfo: 'Попробуйте выбрать другое время или локацию',
    );
  }

  void _showConflictDialog() {
    UnifiedDialogs.showInfo(
      context: context,
      title: 'Конфликт времени',
      message: 'В выбранной локации уже запланирована игра на это время. Выберите другое время или локацию.',
      icon: Icons.warning,
      iconColor: AppColors.warning,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Отладочная информация
    debugPrint('🏗️ Build: _userTeamName = $_userTeamName, _userTeamId = $_userTeamId');
    debugPrint('🎮 Build: _selectedGameMode = $_selectedGameMode');
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/schedule/schedule_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Основная карточка создания игры
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Заголовок
                            Row(
                              children: [
                                Icon(Icons.sports_volleyball, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Основная информация',
                                  style: AppTextStyles.heading3,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Название игры
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Название',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: validateTitle,
                              maxLength: 30,
                            ),
                            
                            const SizedBox(height: 12),

                            // Описание
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Описание',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: validateDescription,
                              maxLines: 2,
                              maxLength: 100,
                            ),
                            const SizedBox(height: 12),

                            // Режим игры
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Режим игры',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _buildGameModeChip(GameMode.normal, 'Обычный'),
                                      _buildGameModeChip(GameMode.team_friendly, 'Команды'),
                                      // Турнирный режим временно отключен
                                      // _buildGameModeChip(GameMode.tournament, 'Турнир'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Локация и участники в одной строке
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedLocation,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedLocation = newValue;
                                      });
                                    },
                                    items: AppStrings.availableLocations.map<DropdownMenuItem<String>>((String location) {
                                      return DropdownMenuItem<String>(
                                        value: location,
                                        child: Text(location),
                                      );
                                    }).toList(),
                                    decoration: const InputDecoration(
                                      labelText: 'Локация',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    validator: (value) => value == null ? 'Выберите локацию' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 100,
                                  child: TextFormField(
                                    controller: _selectedGameMode.isTeamMode 
                                        ? _maxTeamsController 
                                        : _maxParticipantsController,
                                    decoration: InputDecoration(
                                      labelText: _selectedGameMode.isTeamMode ? 'Команды' : 'Игроки',
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    validator: _selectedGameMode.isTeamMode 
                                        ? validateMaxTeams 
                                        : validateMaxParticipants,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Карточка команд - только для обычного режима
                    if (_selectedGameMode == GameMode.normal) ...[
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.groups, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Названия команд',
                                    style: AppTextStyles.heading3,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Название первой команды
                              TextFormField(
                                controller: _team1NameController,
                                decoration: const InputDecoration(
                                  labelText: 'Название первой команды',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  prefixIcon: Icon(Icons.group_outlined),
                                ),
                                validator: (value) {
                                  if (_selectedGameMode == GameMode.normal) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Введите название первой команды';
                                    }
                                    if (value.trim().length > 20) {
                                      return 'Название не должно превышать 20 символов';
                                    }
                                  }
                                  return null;
                                },
                                maxLength: 20,
                              ),
                              const SizedBox(height: 12),

                              // Название второй команды
                              TextFormField(
                                controller: _team2NameController,
                                decoration: const InputDecoration(
                                  labelText: 'Название второй команды',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  prefixIcon: Icon(Icons.group),
                                ),
                                validator: (value) {
                                  if (_selectedGameMode == GameMode.normal) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Введите название второй команды';
                                    }
                                    if (value.trim().length > 20) {
                                      return 'Название не должно превышать 20 символов';
                                    }
                                    if (value.trim() == _team1NameController.text.trim()) {
                                      return 'Названия команд должны быть разными';
                                    }
                                  }
                                  return null;
                                },
                                maxLength: 20,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 16),

                    // Карточка времени
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.schedule, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Время проведения',
                                  style: AppTextStyles.heading3,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectDateTime(true),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Время начала',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_startTime.day}.${_startTime.month} ${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectDateTime(false),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Время окончания',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_endTime.day}.${_endTime.month} ${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Информация о длительности матча
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Время проведения игры',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Игра автоматически начинается в указанное время начала и завершается в указанное время окончания.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.primary.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Кнопка создания
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createRoom,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkGrey,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Создать игру',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildGameModeChip(GameMode mode, String label) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: _selectedGameMode == mode ? Colors.white : Colors.black87,
        ),
      ),
      selected: _selectedGameMode == mode,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.grey.shade200,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedGameMode = mode;
            _updateRoomTitleBasedOnMode(mode);
          });
        }
      },
    );
  }
} 