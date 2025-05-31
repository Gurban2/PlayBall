import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_team_model.dart';
import '../models/user_model.dart';
import '../providers/providers.dart';
import '../utils/constants.dart';
import '../widgets/player_card.dart';
import '../widgets/team_member_card.dart';

class MyTeamScreen extends ConsumerStatefulWidget {
  const MyTeamScreen({super.key});

  @override
  ConsumerState<MyTeamScreen> createState() => _MyTeamScreenState();
}

class _MyTeamScreenState extends ConsumerState<MyTeamScreen> {
  final TextEditingController _teamNameController = TextEditingController();
  bool _isLoading = false;
  bool _isCreatingTeam = false;
  UserTeamModel? _userTeam;
  List<UserModel> _teamMembers = [];
  List<UserModel> _friends = [];

  @override
  void initState() {
    super.initState();
    _loadUserTeam();
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  // Функция для обработки ошибок Firebase с кликабельными ссылками
  void _showFirebaseError(String error) {
    // Проверяем, содержит ли ошибка ссылку на создание индекса
    if (error.contains('https://console.firebase.google.com')) {
      final urlMatch = RegExp(r'https://console\.firebase\.google\.com[^\s]+').firstMatch(error);
      final url = urlMatch?.group(0);
      
      if (url != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Требуется создать индекс Firestore'),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Не удалось открыть ссылку: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Открыть Firebase Console'),
              ),
            ],
          ),
        );
        return;
      }
    }
    
    // Для обычных ошибок показываем стандартный SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ошибка загрузки: $error')),
    );
  }

  Future<void> _loadUserTeam() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        final teamService = ref.read(teamServiceProvider);
        
        // Загружаем команду пользователя
        final team = await teamService.getUserTeam(user.id);
        
        if (team != null) {
          setState(() {
            _userTeam = team;
            _teamNameController.text = team.name;
          });
          
          // Загружаем участников команды
          await _loadTeamMembers();
        }
        
        // Загружаем список друзей
        await _loadFriends();
      }
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
        final availableFriends = allFriends.where((friend) => friend.teamId == null).toList();
        
        setState(() {
          _friends = availableFriends;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки друзей: $e');
    }
  }

  Future<void> _createTeam() async {
    if (_teamNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название команды')),
      );
      return;
    }

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    // НОВОЕ: Проверка роли - только организаторы могут создавать команды
    if (user.role != UserRole.organizer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Только организаторы могут создавать команды'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isCreatingTeam = true;
    });

    try {
      final teamService = ref.read(teamServiceProvider);
      
      final newTeam = UserTeamModel(
        id: '', // Будет сгенерирован в Firestore
        name: _teamNameController.text.trim(),
        ownerId: user.id,
        members: [user.id], // Организатор автоматически добавляется
        createdAt: DateTime.now(),
      );

      await teamService.createUserTeam(newTeam);
      await _loadUserTeam(); // Перезагружаем данные
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Команда создана успешно!')),
        );
      }
    } catch (e) {
      debugPrint('Ошибка создания команды: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка создания команды: $e')),
        );
      }
    } finally {
      setState(() {
        _isCreatingTeam = false;
      });
    }
  }

  Future<void> _addFriendToTeam(UserModel friend) async {
    if (_userTeam == null || _userTeam!.isFull) return;

    // НОВОЕ: Проверяем, что друг не состоит в другой команде
    if (friend.teamId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${friend.name} уже состоит в команде "${friend.teamName}". Игрок может быть только в одной команде.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final teamService = ref.read(teamServiceProvider);
      final updatedMembers = [..._userTeam!.members, friend.id];
      
      await teamService.updateUserTeam(
        _userTeam!.id,
        {'members': updatedMembers},
      );
      
      await _loadUserTeam(); // Перезагружаем данные
      await _loadFriends(); // Перезагружаем список доступных друзей
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${friend.name} добавлен в команду')),
        );
      }
    } catch (e) {
      debugPrint('Ошибка добавления друга в команду: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка добавления в команду: $e')),
        );
      }
    }
  }

  Future<void> _removeMemberFromTeam(UserModel member) async {
    if (_userTeam == null || member.id == _userTeam!.ownerId) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.removeMember),
        content: Text(AppStrings.confirmRemoveMember),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text(AppStrings.removeMember),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final teamService = ref.read(teamServiceProvider);
        final updatedMembers = _userTeam!.members.where((id) => id != member.id).toList();
        
        await teamService.updateUserTeam(
          _userTeam!.id,
          {'members': updatedMembers},
        );
        
        await _loadUserTeam(); // Перезагружаем данные
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${member.name} исключен из команды')),
          );
        }
      } catch (e) {
        debugPrint('Ошибка исключения игрока: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка исключения игрока: $e')),
          );
        }
      }
    }
  }

  Future<void> _updateTeamAvatar() async {
    if (_userTeam == null) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _isLoading = true;
        });

        final storageService = ref.read(storageServiceProvider);
        final imageBytes = await image.readAsBytes();
        
        final photoUrl = await storageService.uploadTeamAvatar(
          _userTeam!.id,
          imageBytes,
        );

        final teamService = ref.read(teamServiceProvider);
        await teamService.updateUserTeam(
          _userTeam!.id,
          {'photoUrl': photoUrl},
        );

        await _loadUserTeam(); // Перезагружаем данные

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Аватар команды обновлен')),
          );
        }
      }
    } catch (e) {
      debugPrint('Ошибка обновления аватара: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления аватара: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.myTeam),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _userTeam == null ? _buildCreateTeamView() : _buildTeamView(),
    );
  }

  Widget _buildCreateTeamView() {
    final user = ref.read(currentUserProvider).value;
    final isOrganizer = user?.role == UserRole.organizer;

    return Padding(
      padding: AppSizes.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.groups,
            size: 80,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSizes.largeSpace),
          const Text(
            'У вас пока нет команды',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.mediumSpace),
          Text(
            isOrganizer 
                ? 'Создайте команду, чтобы участвовать в дружеских матчах и турнирах'
                : 'Только организаторы могут создавать команды. Вы можете присоединиться к существующей команде.',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.extraLargeSpace),
          if (isOrganizer) ...[
            TextField(
              controller: _teamNameController,
              decoration: const InputDecoration(
                labelText: AppStrings.teamName,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
              ),
              maxLength: 30,
            ),
            const SizedBox(height: AppSizes.largeSpace),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCreatingTeam ? null : _createTeam,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isCreatingTeam
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        AppStrings.createMyTeam,
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Для создания команды необходимо получить роль организатора',
                      style: TextStyle(
                        color: AppColors.warning,
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
            child: Padding(
              padding: AppSizes.cardPadding,
              child: Column(
                children: [
                  Row(
                    children: [
                      // Аватар команды
                      GestureDetector(
                        onTap: _updateTeamAvatar,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 40,
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
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSizes.mediumSpace),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userTeam!.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_userTeam!.members.length}/${_userTeam!.maxMembers} игроков',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppSizes.largeSpace),
          
          // Участники команды
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Участники команды',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!_userTeam!.isFull)
                TextButton.icon(
                  onPressed: _showAddFriendDialog,
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text(AppStrings.addFriend),
                ),
            ],
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
        ],
      ),
    );
  }

  Widget _buildMemberCard(UserModel member) {
    final isOwner = member.id == _userTeam!.ownerId;
    
    return TeamMemberCard(
      member: member,
      isOwner: isOwner,
      onTap: () => _showMemberProfile(member),
      onRemove: isOwner ? null : () => _removeMemberFromTeam(member),
    );
  }

  void _showMemberProfile(UserModel member) {
    // Показываем профиль участника команды
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(member.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: member.photoUrl != null 
                    ? NetworkImage(member.photoUrl!) 
                    : null,
                child: member.photoUrl == null 
                    ? Text(
                        _getInitials(member.name),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            _buildProfileRow('Рейтинг', member.rating.toStringAsFixed(1)),
            _buildProfileRow('Игр сыграно', member.gamesPlayed.toString()),
            _buildProfileRow('Процент побед', '${member.winRate.toStringAsFixed(1)}%'),
            if (member.bio.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'О себе:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(member.bio),
            ],
          ],
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

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
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

  void _showAddFriendDialog() {
    // Фильтруем друзей, которые еще не в команде
    final availableFriends = _friends
        .where((friend) => !_userTeam!.members.contains(friend.id))
        .toList();

    if (availableFriends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нет доступных друзей для добавления в команду'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.addFriend),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableFriends.length,
            itemBuilder: (context, index) {
              final friend = availableFriends[index];
              return PlayerCard(
                player: friend,
                compact: true,
                onTap: () {
                  Navigator.of(context).pop();
                  _addFriendToTeam(friend);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
        ],
      ),
    );
  }
} 