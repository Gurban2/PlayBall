import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/providers.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';

class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _numberOfTeamsController = TextEditingController();

  DateTime _startTime = DateTime.now().add(const Duration(hours: 1));
  DateTime _endTime = DateTime.now().add(const Duration(hours: 3));
  bool _isLoading = false;
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  int _activeRoomsCount = 0;

  @override
  void initState() {
    super.initState();
    _maxParticipantsController.text = '12'; // Минимум 12 участников
    _numberOfTeamsController.text = '2'; // Минимум 2 команды
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
    _locationController.dispose();
    _maxParticipantsController.dispose();
    _numberOfTeamsController.dispose();
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
        setState(() {
          _selectedImage = File(image.path);
        });
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
      
      // TODO: Здесь будет загрузка изображения в Firebase Storage
      String? photoUrl;
      if (_selectedImage != null) {
        // Пока оставляем null, позже добавим загрузку в Storage
        photoUrl = null;
      }

      final roomId = await firestoreService.createRoom(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        startTime: _startTime,
        endTime: _endTime,
        organizerId: user.id,
        maxParticipants: int.parse(_maxParticipantsController.text),
        pricePerPerson: 0.0, // Убираем оплату
        numberOfTeams: int.parse(_numberOfTeamsController.text),
        photoUrl: photoUrl,
      );

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
        } else {
          errorMessage = 'Ошибка создания игры: ${e.toString()}';
        }
        
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.createRoom),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppSizes.screenPadding,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Информация о лимите игр
                    Card(
                      color: _activeRoomsCount >= 3 ? AppColors.error.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                      child: Padding(
                        padding: AppSizes.cardPadding,
                        child: Row(
                          children: [
                            Icon(
                              _activeRoomsCount >= 3 ? Icons.warning : Icons.info,
                              color: _activeRoomsCount >= 3 ? AppColors.error : AppColors.primary,
                            ),
                            const SizedBox(width: AppSizes.smallSpace),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Лимит незавершенных игр',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _activeRoomsCount >= 3 ? AppColors.error : AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    'У вас $_activeRoomsCount из 3 разрешенных активных игр',
                                    style: TextStyle(
                                      color: _activeRoomsCount >= 3 ? AppColors.error : AppColors.textSecondary,
                                    ),
                                  ),
                                  if (_activeRoomsCount >= 3)
                                    const Text(
                                      'Завершите или отмените существующие игры для создания новых',
                                      style: TextStyle(
                                        color: AppColors.error,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.mediumSpace),
                    
                    // Поле названия
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.title,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.sports_volleyball),
                      ),
                      validator: Validators.validateTitle,
                      maxLength: ValidationRules.maxTitleLength,
                    ),
                    const SizedBox(height: AppSizes.mediumSpace),
                    
                    // Поле описания
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.description,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      validator: Validators.validateDescription,
                      maxLines: 3,
                      maxLength: ValidationRules.maxDescriptionLength,
                    ),
                    const SizedBox(height: AppSizes.mediumSpace),
                    
                    // Поле места проведения
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.location,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: Validators.validateLocation,
                      maxLength: ValidationRules.maxLocationLength,
                    ),
                    const SizedBox(height: AppSizes.mediumSpace),
                    
                    // Поле количества участников
                    TextFormField(
                      controller: _maxParticipantsController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.maxParticipants,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.people),
                        helperText: 'Минимум 12 участников',
                      ),
                      validator: Validators.validateMaxParticipants,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppSizes.mediumSpace),
                    
                    // Поле количества команд
                    TextFormField(
                      controller: _numberOfTeamsController,
                      decoration: const InputDecoration(
                        labelText: 'Количество команд',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.groups),
                        helperText: 'Минимум 2 команды, по 6 игроков в каждой',
                      ),
                      validator: Validators.validateNumberOfTeams,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppSizes.largeSpace),
                    
                    // Секция добавления фотографии
                    Card(
                      child: Padding(
                        padding: AppSizes.cardPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Фотография игры',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSizes.mediumSpace),
                            
                            if (_selectedImage != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImage!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: AppSizes.mediumSpace),
                            ],
                            
                            ElevatedButton.icon(
                              onPressed: _selectImage,
                              icon: Icon(_selectedImage != null ? Icons.edit : Icons.add_a_photo),
                              label: Text(_selectedImage != null ? 'Изменить фото' : 'Добавить фото'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.largeSpace),
                    
                    // Секция времени проведения
                    Card(
                      child: Padding(
                        padding: AppSizes.cardPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Время проведения',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSizes.mediumSpace),
                            
                            ListTile(
                              leading: const Icon(Icons.access_time),
                              title: const Text(AppStrings.startTime),
                              subtitle: Text(
                                '${_startTime.day}.${_startTime.month}.${_startTime.year} '
                                '${_startTime.hour.toString().padLeft(2, '0')}:'
                                '${_startTime.minute.toString().padLeft(2, '0')}',
                              ),
                              onTap: () => _selectDateTime(true),
                              trailing: const Icon(Icons.edit),
                            ),
                            
                            ListTile(
                              leading: const Icon(Icons.access_time_filled),
                              title: const Text(AppStrings.endTime),
                              subtitle: Text(
                                '${_endTime.day}.${_endTime.month}.${_endTime.year} '
                                '${_endTime.hour.toString().padLeft(2, '0')}:'
                                '${_endTime.minute.toString().padLeft(2, '0')}',
                              ),
                              onTap: () => _selectDateTime(false),
                              trailing: const Icon(Icons.edit),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.largeSpace),
                    
                    // Кнопка создания
                    ElevatedButton(
                      onPressed: (_isLoading || _activeRoomsCount >= 3) ? null : _createRoom,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              AppStrings.createRoom,
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 