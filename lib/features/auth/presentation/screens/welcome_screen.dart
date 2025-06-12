import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/providers.dart';
import '../../../../shared/widgets/enhanced_animations.dart';
import '../../domain/entities/user_model.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));
    
    _slideController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          AppStrings.appName,
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          userAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
            error: (error, stack) => _buildAuthButton(context, 'Войти', AppRoutes.login),
            data: (user) {
              if (user == null) {
                return _buildAuthButton(context, 'Войти', AppRoutes.login);
              } else {
                return _buildUserMenu(context, user);
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E3C72),
              Color(0xFF2A5298),
              Color(0xFF6DD5FA),
              Color(0xFFFFE000),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Декоративные элементы
            ..._buildFloatingElements(),
            
            // Основной контент
            SingleChildScrollView(
              child: Column(
                children: [
                  // Hero Section
                  _buildHeroSection(userAsync),
                  
                  // Action Cards Section
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildActionSection(context, userAsync),
                  ),
                  
                  // Features Section
                  _buildFeaturesSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthButton(BuildContext context, String text, String route) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextButton(
        onPressed: () => context.push(route),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(
          text,
          style: GoogleFonts.rajdhani(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildUserMenu(BuildContext context, UserModel user) {
    return PopupMenuButton<String>(
      icon: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B35).withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      onSelected: (value) {
        switch (value) {
          case 'profile':
            context.push(AppRoutes.profile);
            break;
          case 'logout':
            _logout(context, ref);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              const Icon(Icons.person, color: Color(0xFFFF6B35)),
              const SizedBox(width: 8),
              Text('Привет, ${user.name}!', style: GoogleFonts.rajdhani()),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout, color: Color(0xFFFF6B35)),
              const SizedBox(width: 8),
              Text('Выйти', style: GoogleFonts.rajdhani()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(AsyncValue<UserModel?> userAsync) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      width: double.infinity,
      child: Stack(
        children: [
          // Анимированная иконка волейбола
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                                 PulsingWidget(
                   duration: const Duration(seconds: 2),
                   minScale: 1.0,
                   maxScale: 1.15,
                   child: Container(
                     padding: const EdgeInsets.all(20),
                     decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       gradient: RadialGradient(
                         colors: [
                           Colors.orange.withOpacity(0.8),
                           Colors.deepOrange.withOpacity(0.6),
                           Colors.transparent,
                         ],
                       ),
                       boxShadow: [
                         BoxShadow(
                           color: Colors.orange.withOpacity(0.6),
                           blurRadius: 30,
                           spreadRadius: 10,
                         ),
                       ],
                     ),
                     child: const Icon(
                       Icons.sports_volleyball,
                       size: 120,
                       color: Colors.white,
                     ),
                   ),
                 ),
                
                const SizedBox(height: 30),
                
                Text(
                  'Добро пожаловать в',
                  style: GoogleFonts.rajdhani(
                    fontSize: 24,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                Text(
                  'PlayBall!',
                  style: GoogleFonts.orbitron(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(2, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 15),
                
                Text(
                  'Организуй и участвуй в волейбольных играх\nс друзьями и новыми знакомыми',
                  style: GoogleFonts.rajdhani(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                userAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (error, stack) => const SizedBox.shrink(),
                  data: (user) {
                    if (user == null) {
                      return _buildAuthButtons();
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPowerButton('Войти', Icons.login, () => context.push(AppRoutes.login)),
        const SizedBox(width: 20),
        _buildPowerButton('Регистрация', Icons.person_add, () => context.push(AppRoutes.register), 
          isSecondary: true),
      ],
    );
  }

  Widget _buildPowerButton(String text, IconData icon, VoidCallback onPressed, {bool isSecondary = false}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: isSecondary 
          ? null
          : const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)]),
        border: isSecondary ? Border.all(color: Colors.white, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: isSecondary 
              ? Colors.white.withOpacity(0.3)
              : const Color(0xFFFF6B35).withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary ? Colors.transparent : Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: GoogleFonts.rajdhani(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionSection(BuildContext context, AsyncValue<UserModel?> userAsync) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Что ты хочешь сделать?',
            style: GoogleFonts.orbitron(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          _buildSportyActionCard(
            title: 'Посмотреть игры',
            subtitle: 'Найди игру своей мечты!',
            icon: Icons.sports_volleyball,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
            ),
            onTap: () => context.push(AppRoutes.home),
          ),
          
          const SizedBox(height: 20),
          
          userAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => const SizedBox.shrink(),
            data: (user) {
              if (user?.role == UserRole.organizer || user?.role == UserRole.admin) {
                return Column(
                  children: [
                    _buildSportyActionCard(
                      title: 'Создать игру',
                      subtitle: 'Организуй эпичную битву!',
                      icon: Icons.add_circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                      ),
                      onTap: () => context.push(AppRoutes.createRoom),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          _buildSportyActionCard(
            title: 'О приложении',
            subtitle: 'Узнай больше о PlayBall',
            icon: Icons.info_outline,
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

        Widget _buildSportyActionCard({
     required String title,
     required String subtitle,
     required IconData icon,
     required Gradient gradient,
     required VoidCallback onTap,
   }) {
     return SlideInWidget(
       duration: const Duration(milliseconds: 800),
       delay: const Duration(milliseconds: 200),
       beginOffset: const Offset(0.3, 0),
       child: Container(
         height: 120,
         decoration: BoxDecoration(
           gradient: gradient,
           borderRadius: BorderRadius.circular(20),
           boxShadow: [
             BoxShadow(
               color: Colors.black.withOpacity(0.2),
               blurRadius: 15,
               offset: const Offset(0, 8),
             ),
           ],
         ),
         child: Material(
           color: Colors.transparent,
           child: InkWell(
             onTap: onTap,
             borderRadius: BorderRadius.circular(20),
             child: Stack(
               children: [
                 // Декоративные элементы
                 Positioned(
                   top: -30,
                   right: -30,
                   child: Container(
                     width: 100,
                     height: 100,
                     decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       color: Colors.white.withOpacity(0.1),
                     ),
                   ),
                 ),
                 
                 // Основной контент
                 Padding(
                   padding: const EdgeInsets.all(20),
                   child: Row(
                     children: [
                       Container(
                         padding: const EdgeInsets.all(16),
                         decoration: BoxDecoration(
                           color: Colors.white.withOpacity(0.2),
                           borderRadius: BorderRadius.circular(16),
                           border: Border.all(
                             color: Colors.white.withOpacity(0.3),
                             width: 2,
                           ),
                         ),
                         child: Icon(icon, size: 32, color: Colors.white),
                       ),
                       
                       const SizedBox(width: 20),
                       
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             Text(
                               title,
                               style: GoogleFonts.orbitron(
                                 fontSize: 20,
                                 fontWeight: FontWeight.bold,
                                 color: Colors.white,
                               ),
                             ),
                             const SizedBox(height: 4),
                             Text(
                               subtitle,
                               style: GoogleFonts.rajdhani(
                                 fontSize: 16,
                                 color: Colors.white.withOpacity(0.9),
                                 fontWeight: FontWeight.w500,
                               ),
                             ),
                           ],
                         ),
                       ),
                       
                       Container(
                         padding: const EdgeInsets.all(8),
                         decoration: BoxDecoration(
                           color: Colors.white.withOpacity(0.2),
                           borderRadius: BorderRadius.circular(12),
                         ),
                         child: const Icon(
                           Icons.arrow_forward_ios,
                           color: Colors.white,
                           size: 16,
                         ),
                       ),
                     ],
                   ),
                 ),
               ],
             ),
           ),
         ),
       ),
     );
   }

  Widget _buildFeaturesSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Text(
              'Возможности PlayBall',
              style: GoogleFonts.orbitron(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3748),
              ),
            ),
            
            const SizedBox(height: 30),
            
            Row(
              children: [
                Expanded(child: _buildFeatureItem(
                  icon: Icons.schedule,
                  title: 'Планирование',
                  description: 'Создавай игры заранее',
                  color: const Color(0xFFFF6B35),
                )),
                Expanded(child: _buildFeatureItem(
                  icon: Icons.group,
                  title: 'Команды',
                  description: 'Играй с друзьями',
                  color: const Color(0xFF11998E),
                )),
              ],
            ),
            
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(child: _buildFeatureItem(
                  icon: Icons.location_on,
                  title: 'Локации',
                  description: 'Находи игры рядом',
                  color: const Color(0xFF667EEA),
                )),
                Expanded(child: _buildFeatureItem(
                  icon: Icons.notifications,
                  title: 'Уведомления',
                  description: 'Не пропускай игры',
                  color: const Color(0xFFE53E3E),
                )),
              ],
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          
          const SizedBox(height: 15),
          
          Text(
            title,
            style: GoogleFonts.orbitron(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 5),
          
          Text(
            description,
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              color: const Color(0xFF718096),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingElements() {
    return List.generate(20, (index) {
      final icons = [
        Icons.sports_volleyball, 
        Icons.sports_tennis, 
        Icons.sports_soccer,
        Icons.sports_basketball,
        Icons.sports_handball,
      ];
      
      return Positioned(
        left: (index * 47) % MediaQuery.of(context).size.width,
        top: (index * 73) % MediaQuery.of(context).size.height,
        child: FloatingIcon(
          icon: icons[index % icons.length],
          delay: Duration(milliseconds: index * 100),
          color: Colors.white,
          size: 15 + (index % 4) * 8,
        ),
      );
    });
  }

  void _logout(BuildContext context, WidgetRef ref) async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
      if (context.mounted) {
        context.go(AppRoutes.welcome);
      }
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.showError(context, 'Ошибка выхода: ${e.toString()}');
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'О приложении PlayBall',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PlayBall - это приложение для организации волейбольных игр.',
              style: GoogleFonts.rajdhani(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'Возможности:',
              style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...['• Создание и планирование игр', '• Поиск игр рядом с вами', '• Формирование команд', '• Уведомления о играх', '• Статистика и рейтинги']
                .map((text) => Text(text, style: GoogleFonts.rajdhani())),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Закрыть',
              style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
} 