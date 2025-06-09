import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/providers.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../shared/widgets/universal_card.dart';
import '../../../../shared/widgets/dialogs/player_profile_dialog.dart';
import '../../../auth/domain/entities/user_model.dart';
import '../../../teams/domain/entities/user_team_model.dart';
import '../../../../shared/widgets/dialogs/unified_dialogs.dart';


class MyTeamScreen extends ConsumerStatefulWidget {
  const MyTeamScreen({super.key});

  @override
  ConsumerState<MyTeamScreen> createState() => _MyTeamScreenState();
}

class _MyTeamScreenState extends ConsumerState<MyTeamScreen> {

  bool _isLoading = true;
  UserTeamModel? _userTeam;
  List<UserModel> _teamMembers = [];
  List<UserTeamModel> _allTeams = [];

  @override
  void initState() {
    super.initState();
    _loadUserTeam();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Функция для обработки ошибок Firebase с кликабельными ссылками
  void _showFirebaseError(String error) {
    // Проверяем, содержит ли ошибка ссылку на создание индекса
    if (error.contains('https://console.firebase.google.com')) {
      final urlMatch = RegExp(r'https://console\.firebase\.google\.com[^\s]+').firstMatch(error);
      final url = urlMatch?.group(0);
      
      if (url != null) {
        if (!mounted) return; // Добавляем проверку mounted
        
        UnifiedDialogs.showCustom(
          context: context,
          title: 'Требуется создать индекс Firestore',
          icon: Icons.error_outline,
          iconColor: AppColors.error,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Для корректной работы приложения необходимо создать индекс в Firebase Firestore.',
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  error,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
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
        );
        return;
      }
    }
    
    // Для обычных ошибок показываем стандартный SnackBar
    if (mounted) {
      ErrorHandler.showError(context, 'Ошибка загрузки: $error');
    }
  }

  Future<void> _loadUserTeam() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        final teamService = ref.read(teamServiceProvider);
        
        // Загружаем команду пользователя используя teamId из профиля
        if (user.teamId != null) {
          final team = await teamService.getUserTeamById(user.teamId!);
          if (team != null) {
            setState(() {
              _userTeam = team;
            });
            
            // Загружаем участников команды
            await _loadTeamMembers();
          }
        }
        
        // Загружаем список друзей
        await _loadFriends();
      }
      
      // Загружаем все команды
      await _loadAllTeams();
    } catch (e) {
      debugPrint('Ошибка загрузки команды: $e');
      if (mounted) {
        _showFirebaseError(e.toString());
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTeamMembers() async {
    if (_userTeam == null) return;

    try {
      final userService = ref.read(userServiceProvider);
      final members = await userService.getUsersByIds(_userTeam!.members);
      setState(() {
        _teamMembers = members;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки участников команды: $e');
    }
  }

  Future<void> _loadFriends() async {
    try {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        final userService = ref.read(userServiceProvider);
        final allFriends = await userService.getFriends(user.id);
        
        // НОВОЕ: Фильтруем только тех друзей, которые не состоят в командах
        // final availableFriends = allFriends.where((friend) => friend.teamId == null).toList();
      }
    } catch (e) {
      debugPrint('Ошибка загрузки друзей: $e');
    }
  }

  Future<void> _loadAllTeams() async {
    try {
      final teamService = ref.read(teamServiceProvider);
      final allTeams = await teamService.getAllUserTeams();
      
      if (mounted) {
        setState(() {
          _allTeams = allTeams;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки всех команд: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.myTeam),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/schedule/schedule_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: _userTeam == null ? _buildCreateTeamView() : _buildTeamView(),
      ),
    );
  }

  Widget _buildCreateTeamView() {
    return SingleChildScrollView(
      padding: AppSizes.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          const SizedBox(height: AppSizes.mediumSpace),
          const Text(
            'У вас пока нет команды',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.extraLargeSpace),
          
          // Список всех команд
          const Text(
            'Все команды',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.mediumSpace),
          
          if (_allTeams.isEmpty)
            const Card(
              child: Padding(
                padding: AppSizes.cardPadding,
                child: Center(
                  child: Text(
                    'Пока нет созданных команд',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            )
          else
            ..._allTeams.map((team) => _buildTeamCard(team)),
        ],
      ),
    );
  }

  Widget _buildTeamView() {
    return SingleChildScrollView(
      padding: AppSizes.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Информация о команде
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Основная информация о команде
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage: _userTeam!.photoUrl != null
                            ? NetworkImage(_userTeam!.photoUrl!)
                            : null,
                        child: _userTeam!.photoUrl == null
                            ? Text(
                                _userTeam!.name.isNotEmpty 
                                    ? _userTeam!.name[0].toUpperCase() 
                                    : 'T',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userTeam!.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '${_userTeam!.members.length}/${_userTeam!.maxMembers} игроков',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _userTeam!.isFull ? AppColors.success : AppColors.warning,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _userTeam!.isFull ? 'Готова' : 'Неполная',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Компактная статистика команды
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildCompactStat('Очки', '${_userTeam!.teamScore}', Icons.stars, AppColors.warning),
                        Container(width: 1, height: 30, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                        _buildCompactStat('Игр', '${_userTeam!.gamesPlayed}', Icons.sports_volleyball, AppColors.primary),
                        Container(width: 1, height: 30, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                        _buildCompactStat('Побед', '${_userTeam!.gamesWon}', Icons.emoji_events, AppColors.success),
                        Container(width: 1, height: 30, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                        _buildCompactStat('Винрейт', '${_userTeam!.winRate.toStringAsFixed(0)}%', Icons.trending_up, AppColors.secondary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppSizes.mediumSpace),
          
          // Баллы команды и управление
          _buildTeamStatsCard(),
          
          const SizedBox(height: AppSizes.largeSpace),
          
          // Участники команды
          const Text(
            'Участники команды',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppSizes.mediumSpace),
          
          // Список участников
          ..._teamMembers.map((member) => _buildMemberCard(member)),
          
          if (_teamMembers.isEmpty)
            const Card(
              child: Padding(
                padding: AppSizes.cardPadding,
                child: Center(
                  child: Text(
                    'Нет участников',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          
          const SizedBox(height: AppSizes.extraLargeSpace),
          
          // Список всех команд
          const Text(
            'Все команды',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.mediumSpace),
          
          if (_allTeams.isEmpty)
            const Card(
              child: Padding(
                padding: AppSizes.cardPadding,
                child: Center(
                  child: Text(
                    'Пока нет созданных команд',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            )
          else
            ..._allTeams.map((team) => _buildTeamCard(team)),
        ],
      ),
    );
  }

  Widget _buildTeamStatsCard() {
    final user = ref.read(currentUserProvider).value;
    final isOwner = user?.id == _userTeam?.ownerId;
    
    // Показываем карточку управления только владельцам команды
    if (!isOwner) {
      return const SizedBox.shrink();
    }
    
    return Card(
      child: Padding(
        padding: AppSizes.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Управление командой',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Кнопки управления для организатора
            ElevatedButton.icon(
              onPressed: _checkTeamReadiness,
              icon: const Icon(Icons.check_circle, size: 20),
              label: const Text('Проверить готовность'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(UserModel member) {
    final isOwner = member.id == _userTeam!.ownerId;
    final accentColor = isOwner ? AppColors.warning : AppColors.primary;
    
    return UniversalCard(
      title: member.name,
      subtitle: '${member.gamesPlayed} игр • ${member.winRate.toStringAsFixed(1)}% побед',
      accentColor: accentColor,
      onTap: () => PlayerProfileDialog.show(context, ref, member.id, playerName: member.name),
      leading: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accentColor.withValues(alpha: 0.1),
          image: member.photoUrl != null 
              ? DecorationImage(
                  image: NetworkImage(member.photoUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: member.photoUrl == null 
            ? Text(
                _getInitials(member.name),
                style: TextStyle(
                  color: accentColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      badge: isOwner ? 'Капитан' : null,
      badgeColor: AppColors.warning,
      trailing: Icon(
        Icons.info_outline,
        size: 16,
        color: accentColor.withValues(alpha: 0.7),
      ),
    );
  }



  Widget _buildCompactStat(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return '?';
  }

  void _showAllTeamsDialog() async {
    if (_allTeams.isEmpty) {
      ErrorHandler.showWarning(context, 'Пока нет созданных команд');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Все команды'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _allTeams.length,
            itemBuilder: (context, index) {
              final team = _allTeams[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: team.photoUrl != null ? NetworkImage(team.photoUrl!) : null,
                    child: team.photoUrl == null 
                        ? Text(
                            team.name.isNotEmpty ? team.name[0].toUpperCase() : 'T',
                            style: const TextStyle(color: AppColors.primary),
                          )
                        : null,
                  ),
                  title: Text(team.name),
                  subtitle: Text('${team.members.length}/${team.maxMembers} игроков'),
                  trailing: team.isFull 
                      ? const Text('Полная', style: TextStyle(color: AppColors.textSecondary))
                      : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: team.isFull 
                      ? null 
                      : () {
                          Navigator.of(context).pop();
                          _showTeamDetailsDialog(team);
                        },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showTeamDetailsDialog(UserTeamModel team) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(team.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: team.photoUrl != null ? NetworkImage(team.photoUrl!) : null,
                child: team.photoUrl == null 
                    ? Text(
                        team.name.isNotEmpty ? team.name[0].toUpperCase() : 'T',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text('Участников: ${team.members.length}/${team.maxMembers}'),
            const SizedBox(height: 8),
            Text('Создана: ${team.createdAt.day}.${team.createdAt.month}.${team.createdAt.year}'),
            if (team.isFull) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Команда заполнена',
                  style: TextStyle(color: AppColors.warning),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
          if (!team.isFull)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _requestToJoinTeam(team);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Подать заявку'),
            ),
        ],
      ),
    );
  }

    void _requestToJoinTeam(UserTeamModel team) {
    // В будущем здесь будет логика подачи заявки на вступление в команду
    ErrorHandler.showWarning(
      context, 
      'Функция подачи заявки на вступление в команду будет добавлена в следующих обновлениях',
    );
  }

  void _showMyTeamMembersDialog(UserTeamModel team) async {
    // Загружаем участников команды, если они еще не загружены
    if (_teamMembers.isEmpty && team.members.isNotEmpty) {
      try {
        final userService = ref.read(userServiceProvider);
        final members = await userService.getUsersByIds(team.members);
        setState(() {
          _teamMembers = members;
        });
      } catch (e) {
        debugPrint('Ошибка загрузки участников команды: $e');
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: team.photoUrl != null ? NetworkImage(team.photoUrl!) : null,
              child: team.photoUrl == null 
                  ? Text(
                      team.name.isNotEmpty ? team.name[0].toUpperCase() : 'T',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                team.name,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Участники команды (${_teamMembers.length}/${team.maxMembers})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _teamMembers.isEmpty
                    ? const Center(
                        child: Text(
                          'Участники не найдены',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _teamMembers.length,
                        itemBuilder: (context, index) {
                          final member = _teamMembers[index];
                          final isOwner = member.id == team.ownerId;
                          
                          return _buildMemberCard(member);
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }



    Widget _buildTeamCard(UserTeamModel team) {
    final user = ref.read(currentUserProvider).value;
    final isMyTeam = _userTeam != null && team.id == _userTeam!.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          backgroundImage: team.photoUrl != null ? NetworkImage(team.photoUrl!) : null,
          child: team.photoUrl == null 
              ? Text(
                  team.name.isNotEmpty ? team.name[0].toUpperCase() : 'T',
                  style: const TextStyle(color: AppColors.primary),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                team.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isMyTeam) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  'Моя команда',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text('${team.members.length}/${team.maxMembers} игроков'),
        trailing: isMyTeam 
            ? const Icon(Icons.people, color: AppColors.primary)
            : team.isFull 
                ? const Text('Полная', style: TextStyle(color: AppColors.textSecondary))
                : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          if (isMyTeam) {
            _showMyTeamMembersDialog(team);
          } else if (!team.isFull) {
            _showTeamDetailsDialog(team);
          }
        },
      ),
    );
  }



  // Проверка готовности команды
  void _checkTeamReadiness() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Проверка готовности команды',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Состав команды: ${_teamMembers.length}/${_userTeam?.maxMembers ?? 6}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              
              if (_teamMembers.isEmpty)
                const Text(
                  '❌ В команде нет участников',
                  style: TextStyle(color: AppColors.error),
                )
              else ...[
                const Text(
                  'Участники команды:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                
                ..._teamMembers.map((member) {
                  final isOwner = member.id == _userTeam?.ownerId;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check, color: AppColors.success, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            member.name,
                            style: TextStyle(
                              fontWeight: isOwner ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isOwner)
                          const Text(
                            'Капитан',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _teamMembers.length >= 6 
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _teamMembers.length >= 6 ? Icons.check_circle : Icons.warning,
                        color: _teamMembers.length >= 6 ? AppColors.success : AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _teamMembers.length >= 6 
                              ? 'Команда готова к игре!'
                              : 'Нужно еще ${6 - _teamMembers.length} игроков',
                          style: TextStyle(
                            color: _teamMembers.length >= 6 ? AppColors.success : AppColors.warning,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
} 