import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (!mounted) return;
      
      // Успешный вход, перенаправление на главный экран
      context.go(AppRoutes.home);
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка входа: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _navigateToRegister() {
    context.go(AppRoutes.register);
  }

  void _resetPassword() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Введите email для сброса пароля';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      await _authService.resetPassword(email);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Инструкции по сбросу пароля отправлены на ваш email'),
          backgroundColor: AppColors.success,
        ),
      );
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка сброса пароля: ${e.toString()}';
        _isLoading = false;
      });
    }
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
                  
                  // Ссылка "Забыли пароль"
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      child: const Text(AppStrings.forgotPassword),
                    ),
                  ),
                  
                  const SizedBox(height: AppSizes.mediumSpace),
                  
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
                  
                  // Кнопка входа
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
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
                            AppStrings.login,
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                  
                  const SizedBox(height: AppSizes.largeSpace),
                  
                  // Ссылка на регистрацию
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(AppStrings.noAccount),
                      TextButton(
                        onPressed: _isLoading ? null : _navigateToRegister,
                        child: const Text(AppStrings.register),
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