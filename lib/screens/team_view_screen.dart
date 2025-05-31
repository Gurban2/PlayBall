import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../models/user_team_model.dart';
import '../providers/providers.dart';
import '../utils/constants.dart';
import '../widgets/player_profile_dialog.dart';

class TeamViewScreen extends ConsumerStatefulWidget {
  final String teamId;
  final String teamName;

  const TeamViewScreen({
    super.key,
    required this.teamId,
    required this.teamName,
  });

  @override
  ConsumerState<TeamViewScreen> createState() => _TeamViewScreenState();
}

class _TeamViewScreenState extends ConsumerState<TeamViewScreen> {
  UserTeamModel? _team;
  List<UserModel> _teamMembers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTeamData();
  }

  Future<void> _loadTeamData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final teamService = ref.read(teamServiceProvider);
      final userService = ref.read(userServiceProvider);

      // Получаем команду
      final teamDoc = await teamService.getUserTeamById(widget.teamId);
      if (teamDoc == null) {
        setState(() {
          _error = 'Команда не найдена';
          _isLoading = false;
        });
        return;
      }

      _team = teamDoc;

      // Загружаем участников команды
      final membersFutures = _team!.members
          .map((memberId) => userService.getUserById(memberId))
          .toList();
      
      final membersResults = await Future.wait(membersFutures);
      _teamMembers = membersResults
          .where((member) => member != null)
          .cast<UserModel>()
          .toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки данных: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.teamName),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTeamData,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTeamData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Информация о команде
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // Аватар команды и название
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundColor: AppColors.secondary.withOpacity(0.1),
                                    child: Text(
                                      widget.teamName.isNotEmpty 
                                          ? widget.teamName[0].toUpperCase() 
                                          : 'T',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.teamName,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Участников: ${_teamMembers.length}/6',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _team!.isFull
                                                ? AppColors.success.withOpacity(0.1)
                                                : AppColors.warning.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: _team!.isFull
                                                  ? AppColors.success
                                                  : AppColors.warning,
                                            ),
                                          ),
                                          child: Text(
                                            _team!.isFull ? 'Готова к игре' : 'Неполная команда',
                                            style: TextStyle(
                                              color: _team!.isFull
                                                  ? AppColors.success
                                                  : AppColors.warning,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Статистика команды
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'Создана',
                                      _formatDate(_team!.createdAt),
                                      Icons.calendar_today,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Средний рейтинг',
                                      _calculateAverageRating(),
                                      Icons.star,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),

                      // Состав команды
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.people,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Состав команды',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _teamMembers.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                return _buildMemberTile(_teamMembers[index]);
                              },
                            ),
                          ],
                        ),
                      ),

                      // Кнопка подачи заявки (только для пользователей не в команде)
                      FutureBuilder<bool>(
                        future: _canApplyToTeam(),
                        builder: (context, snapshot) {
                          if (snapshot.data == true) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _showApplicationDialog,
                                  icon: const Icon(Icons.send),
                                  label: const Text('Подать заявку в команду'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
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

  Widget _buildMemberTile(UserModel member) {
    final isTeamOwner = _team?.ownerId == member.id;

    return ListTile(
      onTap: () {
        PlayerProfileDialog.show(context, ref, member.id, playerName: member.name);
      },
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: member.photoUrl != null
            ? NetworkImage(member.photoUrl!)
            : null,
        backgroundColor: AppColors.primary.withOpacity(0.1),
        child: member.photoUrl == null
            ? Text(
                member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 16,
                ),
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              member.name,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
          if (isTeamOwner) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Капитан',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.star, size: 14, color: AppColors.warning),
              const SizedBox(width: 4),
              Text(
                'Рейтинг: ${member.rating.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.sports_volleyball, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                '${member.gamesPlayed} игр',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (member.bio.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              member.bio,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.textSecondary,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  String _calculateAverageRating() {
    if (_teamMembers.isEmpty) return '0.0';
    
    final totalRating = _teamMembers.fold(0.0, (sum, member) => sum + member.rating);
    final averageRating = totalRating / _teamMembers.length;
    
    return averageRating.toStringAsFixed(1);
  }

  Future<bool> _canApplyToTeam() async {
    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null || _team == null) return false;

      // Проверяем, что пользователь не состоит в команде
      if (currentUser.teamId != null) return false;

      // Проверяем, что команда не полная
      if (_team!.isFull) return false;

      // Проверяем, что пользователь не владелец этой команды
      if (_team!.ownerId == currentUser.id) return false;

      // Проверяем, что пользователь не состоит в этой команде
      if (_team!.members.contains(currentUser.id)) return false;

      // Проверяем, что нет активной заявки
      final teamService = ref.read(teamServiceProvider);
      final outgoingApplications = await teamService.getOutgoingTeamApplications(currentUser.id);
      final hasActiveApplication = outgoingApplications.any((app) => app.teamId == _team!.id);

      return !hasActiveApplication;
    } catch (e) {
      return false;
    }
  }

  void _showApplicationDialog() {
    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Заявка в команду "${widget.teamName}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Вы хотите подать заявку на вступление в эту команду?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Сообщение (необязательно):',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: messageController,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: 'Расскажите о себе или почему хотите присоединиться...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _submitApplication(messageController.text.trim());
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

  Future<void> _submitApplication(String message) async {
    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null || _team == null) return;

      final teamService = ref.read(teamServiceProvider);
      await teamService.sendTeamApplication(
        _team!.id,
        currentUser.id,
        message: message.isNotEmpty ? message : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Заявка в команду "${widget.teamName}" отправлена'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Обновляем состояние
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
} 