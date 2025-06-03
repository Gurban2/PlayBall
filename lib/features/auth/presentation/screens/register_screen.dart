import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/datasources/auth_service.dart';
import '../../../../core/providers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/utils/validators.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Проверяем уникальность ника
      final isNicknameUnique = await _authService.isNicknameUnique(_nameController.text.trim());
      if (!isNicknameUnique) {
        setState(() {
          _errorMessage = 'Этот ник уже занят. Выберите другой.';
          _isLoading = false;
        });
        return;
      }

      await _authService.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
      
      if (!mounted) return;
      
      // Очищаем провайдеры для обновления данных нового пользователя
      ref.invalidate(currentUserProvider);
      ref.invalidate(activeRoomsProvider);
      ref.invalidate(plannedRoomsProvider);
      ref.invalidate(userRoomsProvider);
      
      // Показываем сообщение об успешной регистрации
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Регистрация успешна! Теперь войдите в свой аккаунт'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 3),
        ),
      );
      
      // Выходим из только что созданного аккаунта и перенаправляем на вход
      await _authService.signOut();
      if (!mounted) return;
      context.go('${AppRoutes.login}?email=${Uri.encodeComponent(_emailController.text.trim())}');
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка регистрации: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _navigateToLogin() {
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSizes.screenPadding,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Логотип или изображение
                  const Icon(
                    Icons.sports_volleyball,
                    size: 80,
                    color: AppColors.primary,
                  ),
                  
                  const SizedBox(height: AppSizes.largeSpace),
                  
                  // Название приложения
                  const Text(
                    AppStrings.appName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  
                  const SizedBox(height: AppSizes.extraLargeSpace),
                  
                  // Информационное сообщение
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
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'После регистрации вы будете перенаправлены на страницу входа',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSizes.mediumSpace),
                  
                  // Поле для ника
                  TextFormField(
                    controller: _nameController,
                    validator: Validators.validateNickname,
                    decoration: const InputDecoration(
                      labelText: AppStrings.nickname,
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                      helperText: 'Ник должен быть уникальным',
                    ),
                  ),
                  
                  const SizedBox(height: AppSizes.mediumSpace),
                  
                  // Поле для email
                  TextFormField(
                    controller: _emailController,
                    validator: Validators.validateEmail,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: AppStrings.email,
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  
                  const SizedBox(height: AppSizes.mediumSpace),
                  
                  // Поле для пароля
                  TextFormField(
                    controller: _passwordController,
                    validator: Validators.validatePassword,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: AppStrings.password,
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  
                  const SizedBox(height: AppSizes.mediumSpace),
                  
                  // Поле для подтверждения пароля
                  TextFormField(
                    controller: _confirmPasswordController,
                    validator: (value) => Validators.validateConfirmPassword(
                      value, 
                      _passwordController.text,
                    ),
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: AppStrings.confirmPassword,
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  
                  const SizedBox(height: AppSizes.largeSpace),
                  
                  // Сообщение об ошибке
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.mediumSpace),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                  // Кнопка регистрации
                  ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      padding: AppSizes.buttonPadding,
                      minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            AppStrings.register,
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                  
                  const SizedBox(height: AppSizes.largeSpace),
                  
                  // Ссылка на вход
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(AppStrings.hasAccount),
                      TextButton(
                        onPressed: _isLoading ? null : _navigateToLogin,
                        child: const Text(AppStrings.login),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 