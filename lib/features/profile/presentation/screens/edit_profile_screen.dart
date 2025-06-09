import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/providers.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../auth/domain/entities/user_model.dart';
import '../widgets/photo_upload_widget.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  
  bool _isLoading = false;
  UserModel? _currentUser;
  PlayerStatus _selectedStatus = PlayerStatus.lookingForGame;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.value;
    
    if (user != null) {
      setState(() {
        _currentUser = user;
        _nameController.text = user.name;
        _bioController.text = user.bio;
        _selectedStatus = user.status;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userService = ref.read(userServiceProvider);
      
      await userService.updateUser(
        userId: _currentUser!.id,
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        status: _selectedStatus,
      );

      if (mounted) {
        ErrorHandler.showSuccess(context, 'Профиль успешно обновлен!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Ошибка сохранения: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onPhotoUploaded(String photoUrl) {
    // Фото уже загружено через PhotoUploadWidget, просто показываем успех
    ErrorHandler.showSuccess(context, 'Фото профиля обновлено!');
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать профиль'),
        backgroundColor: AppColors.darkGrey,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Сохранить',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Загрузка фото
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              'Фото профиля',
                              style: AppTextStyles.heading3,
                            ),
                            const SizedBox(height: 16),
                            PhotoUploadWidget(
                              currentPhotoUrl: _currentUser!.photoUrl,
                              userId: _currentUser!.id,
                              onPhotoUploaded: _onPhotoUploaded,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Основная информация
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
                            Text(
                              'Основная информация',
                              style: AppTextStyles.heading3,
                            ),
                            const SizedBox(height: 20),
                            
                            // Имя
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Имя',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Введите ваше имя';
                                }
                                if (value.trim().length < 2) {
                                  return 'Имя должно содержать минимум 2 символа';
                                }
                                return null;
                              },
                              maxLength: 50,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Email (только для отображения)
                            TextFormField(
                              initialValue: _currentUser!.email,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email),
                                enabled: false,
                                helperText: 'Email нельзя изменить',
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Статус
                            Text(
                              'Статус доступности',
                              style: AppTextStyles.bodyText.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: PlayerStatus.values.map((status) {
                                  return RadioListTile<PlayerStatus>(
                                    title: Text(_getStatusDisplayName(status)),
                                    subtitle: Text(_getStatusDescription(status)),
                                    value: status,
                                    groupValue: _selectedStatus,
                                    onChanged: (PlayerStatus? value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedStatus = value;
                                        });
                                      }
                                    },
                                    activeColor: AppColors.primary,
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Описание
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
                            Text(
                              'О себе',
                              style: AppTextStyles.heading3,
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _bioController,
                              decoration: const InputDecoration(
                                labelText: 'Расскажите о себе',
                                hintText: 'Например: играю волейбол 5 лет, люблю командную игру...',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.edit_note),
                                alignLabelWithHint: true,
                              ),
                              maxLines: 4,
                              maxLength: 500,
                              validator: (value) {
                                if (value != null && value.length > 500) {
                                  return 'Описание не должно превышать 500 символов';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Кнопка сохранения (дублирующая)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveProfile,
                        icon: _isLoading 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isLoading ? 'Сохранение...' : 'Сохранить изменения'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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

  String _getStatusDisplayName(PlayerStatus status) {
    switch (status) {
      case PlayerStatus.lookingForGame:
        return 'Ищу игру';
      case PlayerStatus.unavailable:
        return 'Недоступен';
      case PlayerStatus.freeTonight:
        return 'Свободен сегодня вечером';
    }
  }

  String _getStatusDescription(PlayerStatus status) {
    switch (status) {
      case PlayerStatus.lookingForGame:
        return 'Активно ищу игры и готов присоединиться';
      case PlayerStatus.unavailable:
        return 'Временно не играю в волейбол';
      case PlayerStatus.freeTonight:
        return 'Свободен и готов поиграть сегодня';
    }
  }
} 