import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../providers/providers.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../models/user_model.dart';
import '../models/room_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
  final _numberOfTeamsController = TextEditingController();
  final _team1NameController = TextEditingController();
  final _team2NameController = TextEditingController();

  DateTime _startTime = DateTime.now().add(const Duration(hours: 1));
  DateTime _endTime = DateTime.now().add(const Duration(hours: 3));
  GameMode _selectedGameMode = GameMode.friendly;
  bool _isLoading = false;
  Uint8List? _selectedImageBytes;
  final ImagePicker _imagePicker = ImagePicker();
  int _activeRoomsCount = 0;
  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _maxParticipantsController.text = '12'; // Минимум 12 участников
    _numberOfTeamsController.text = '2'; // Минимум 2 команды
    _team1NameController.text = 'Команда 1';
    _team2NameController.text = 'Команда 2';
    _loadActiveRoomsCount();
  }

  Future<void> _loadActiveRoomsCount() async {
    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.value;
    
    if (user != null) {
      final firestoreService = ref.read(firestoreServiceProvider);
      final count = await firestoreService.getOrganizerActiveRoomsCount(user.id);
      if (mounted) {
        setState(() {
          _activeRoomsCount = count;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxParticipantsController.dispose();
    _numberOfTeamsController.dispose();
    _team1NameController.dispose();
    _team2NameController.dispose();
    super.dispose();
  }

  Future<void> _selectImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        if (mounted) {
          setState(() {
            _selectedImageBytes = bytes;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка выбора изображения: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _selectDateTime(bool isStartTime) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStartTime ? _startTime : _endTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isStartTime ? _startTime : _endTime),
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
            if (_endTime.isBefore(_startTime)) {
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.value;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка: пользователь не найден'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (user.role == UserRole.user) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Только организаторы могут создавать комнаты'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_endTime.isBefore(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Время окончания должно быть позже времени начала'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      
      // Сначала создаем комнату без фото, чтобы получить roomId
      final roomId = await firestoreService.createRoom(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _selectedLocation ?? '',
        startTime: _startTime,
        endTime: _endTime,
        organizerId: user.id,
        maxParticipants: int.parse(_maxParticipantsController.text),
        pricePerPerson: 0.0, // Убираем оплату
        numberOfTeams: 2, // Фиксированное количество команд
        gameMode: _selectedGameMode,
        photoUrl: null, // Пока без фото
        teamNames: [
          _team1NameController.text.trim(),
          _team2NameController.text.trim(),
        ],
      );
      
      // Если есть изображение, загружаем его в Storage и обновляем комнату
      // ВРЕМЕННО ОТКЛЮЧЕНО - TODO: Включить после настройки Firebase Storage
      /*
      if (_selectedImageBytes != null) {
        try {
          final storageService = ref.read(storageServiceProvider);
          final photoUrl = await storageService.uploadRoomImage(_selectedImageBytes!, roomId);
          
          // Обновляем комнату с URL фотографии
          await firestoreService.updateRoom(roomId: roomId, photoUrl: photoUrl);
        } catch (e) {
          // Если загрузка фото не удалась, показываем предупреждение, но комната уже создана
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Комната создана, но фото не загружено: ${e.toString()}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
      */

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Игра успешно создана!'),
            backgroundColor: AppColors.success,
          ),
        );
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
        } else if (e.toString().contains('уже запланирована игра на это время')) {
          // Показываем popup для конфликтов локаций
          _showLocationConflictDialog(e.toString().replaceFirst('Exception: ', ''));
        } else {
          errorMessage = 'Ошибка создания игры: ${e.toString()}';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  void _showLocationConflictDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_amber,
                  color: AppColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Конфликт локации',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Попробуйте выбрать другое время или локацию',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Понятно',
                style: TextStyle(fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Изменить время',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Создать игру'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
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
                                const Text(
                                  'Основная информация',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                              validator: Validators.validateTitle,
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
                              validator: Validators.validateDescription,
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
                                  Row(
                                    children: [
                                      Expanded(
                                        child: RadioListTile<GameMode>(
                                          title: const Text('Дружественный', style: TextStyle(fontSize: 13)),
                                          value: GameMode.friendly,
                                          groupValue: _selectedGameMode,
                                          onChanged: (GameMode? value) {
                                            setState(() {
                                              _selectedGameMode = value!;
                                            });
                                          },
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                      Expanded(
                                        child: RadioListTile<GameMode>(
                                          title: const Text('Турнир', style: TextStyle(fontSize: 13)),
                                          value: GameMode.tournament,
                                          groupValue: _selectedGameMode,
                                          onChanged: (GameMode? value) {
                                            setState(() {
                                              _selectedGameMode = value!;
                                            });
                                          },
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
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
                                    controller: _maxParticipantsController,
                                    decoration: const InputDecoration(
                                      labelText: 'Игроки',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    validator: Validators.validateMaxParticipants,
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

                    // Карточка команд
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
                                const Text(
                                  'Названия команд',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                if (value == null || value.trim().isEmpty) {
                                  return 'Введите название первой команды';
                                }
                                if (value.trim().length > 20) {
                                  return 'Название не должно превышать 20 символов';
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
                                if (value == null || value.trim().isEmpty) {
                                  return 'Введите название второй команды';
                                }
                                if (value.trim().length > 20) {
                                  return 'Название не должно превышать 20 символов';
                                }
                                if (value.trim() == _team1NameController.text.trim()) {
                                  return 'Названия команд должны быть разными';
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
                                const Text(
                                  'Время проведения',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                            'Начало',
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
                                            'Окончание',
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
                          backgroundColor: AppColors.primary,
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
    );
  }
} 