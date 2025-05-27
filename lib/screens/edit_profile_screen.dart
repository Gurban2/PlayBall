import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  final _nameController = TextEditingController();
  
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _selectedPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.getCurrentUserModel();
      if (user != null && mounted) {
        setState(() {
          _currentUser = user;
          _nameController.text = user.name;
          _selectedPhotoUrl = user.photoUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки данных: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _selectPhoto() async {
    // Показываем диалог выбора фото
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Выбрать из галереи'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Сделать фото'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              if (_selectedPhotoUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Удалить фото'),
                  onTap: () {
                    Navigator.pop(context);
                    _removePhoto();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Отмена'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromGallery() async {
    // TODO: Реализовать выбор изображения из галереи
    // Пока что используем заглушку
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Функция выбора фото из галереи будет реализована позже'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    // TODO: Реализовать съемку фото с камеры
    // Пока что используем заглушку
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Функция съемки фото будет реализована позже'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  void _removePhoto() {
    setState(() {
      _selectedPhotoUrl = null;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка: пользователь не найден'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Проверяем уникальность ника, если он изменился
      final newNickname = _nameController.text.trim();
      if (newNickname != _currentUser!.name) {
        final isNicknameUnique = await _firestoreService.isNicknameUnique(
          newNickname, 
          excludeUserId: _currentUser!.id,
        );
        
        if (!isNicknameUnique) {
          setState(() {
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Этот ник уже занят. Выберите другой.'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
      }

      await _firestoreService.updateUser(
        userId: _currentUser!.id,
        name: newNickname,
        photoUrl: _selectedPhotoUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Профиль успешно обновлен!'),
            backgroundColor: AppColors.success,
          ),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.profile);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildPhotoSection() {
    return Card(
      child: Padding(
        padding: AppSizes.cardPadding,
        child: Column(
          children: [
            const Text(
              'Фото профиля',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.mediumSpace),
            
            GestureDetector(
              onTap: _selectPhoto,
              child: Container(
                width: AppSizes.largeAvatarSize,
                height: AppSizes.largeAvatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.1),
                  border: Border.all(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                child: _selectedPhotoUrl != null
                    ? ClipOval(
                        child: Image.network(
                          _selectedPhotoUrl!,
                          width: AppSizes.largeAvatarSize,
                          height: AppSizes.largeAvatarSize,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person,
                              size: AppSizes.largeIconSize,
                              color: AppColors.primary,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.add_a_photo,
                        size: AppSizes.largeIconSize,
                        color: AppColors.primary,
                      ),
              ),
            ),
            const SizedBox(height: AppSizes.smallSpace),
            
            TextButton(
              onPressed: _selectPhoto,
              child: Text(
                _selectedPhotoUrl != null 
                    ? AppStrings.changePhoto 
                    : 'Добавить фото',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Card(
      child: Padding(
        padding: AppSizes.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Личная информация',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.mediumSpace),
            
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: AppStrings.nickname,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
                helperText: 'Ник должен быть уникальным',
              ),
              validator: Validators.validateNickname,
              maxLength: ValidationRules.maxUsernameLength,
            ),
            const SizedBox(height: AppSizes.mediumSpace),
            
            // Email (только для чтения)
            TextFormField(
              initialValue: _currentUser?.email ?? '',
              decoration: const InputDecoration(
                labelText: AppStrings.email,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              enabled: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_currentUser == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: AppSizes.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.statistics,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.mediumSpace),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    AppStrings.gamesPlayed,
                    _currentUser!.gamesPlayed.toString(),
                    Icons.sports_volleyball,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    AppStrings.wins,
                    _currentUser!.wins.toString(),
                    Icons.emoji_events,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.mediumSpace),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    AppStrings.losses,
                    _currentUser!.losses.toString(),
                    Icons.sentiment_dissatisfied,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    AppStrings.rating,
                    _currentUser!.rating.toString(),
                    Icons.star,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.mediumSpace),
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.smallSpace),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: AppSizes.smallSpace),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.editProfile),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    AppStrings.save,
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppSizes.screenPadding,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildPhotoSection(),
                    const SizedBox(height: AppSizes.mediumSpace),
                    _buildPersonalInfoSection(),
                    const SizedBox(height: AppSizes.mediumSpace),
                    _buildStatsSection(),
                    const SizedBox(height: AppSizes.largeSpace),
                  ],
                ),
              ),
            ),
    );
  }
} 