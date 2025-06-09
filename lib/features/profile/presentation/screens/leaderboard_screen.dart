import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/user_model.dart';
import '../../../auth/data/datasources/user_service.dart';
import '../../../../shared/widgets/dialogs/player_profile_dialog.dart';
import '../../../../core/providers.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> with TickerProviderStateMixin {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  
  List<UserModel> _allPlayers = [];
  List<UserModel> _filteredPlayers = [];
  bool _isLoading = true;
  String _errorMessage = '';
  
  // Категории рейтинга
  late TabController _tabController;
  final List<String> _categories = ['Общий', 'Винрейт', 'Игры', 'Очки'];
  int _selectedCategory = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadPlayers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final players = await _userService.getUsers(limit: 100);
      
      // Фильтруем только игроков с играми
      final activePlayers = players.where((player) => 
        player.gamesPlayed > 0
      ).toList();

      setState(() {
        _allPlayers = activePlayers;
        _filteredPlayers = List.from(activePlayers);
        _isLoading = false;
      });
      
      _sortPlayers();
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки рейтинга: $e';
        _isLoading = false;
      });
    }
  }

  void _sortPlayers() {
    List<UserModel> sortedPlayers = List.from(_filteredPlayers);
    
    switch (_selectedCategory) {
      case 0: // Общий (по рейтингу)
        sortedPlayers.sort((a, b) => b.calculatedRating.compareTo(a.calculatedRating));
        break;
      case 1: // Винрейт
        sortedPlayers.sort((a, b) => b.winRate.compareTo(a.winRate));
        break;
      case 2: // Игры
        sortedPlayers.sort((a, b) => b.gamesPlayed.compareTo(a.gamesPlayed));
        break;
      case 3: // Очки
        sortedPlayers.sort((a, b) => b.totalScore.compareTo(a.totalScore));
        break;
    }
    
    setState(() {
      _filteredPlayers = sortedPlayers;
    });
  }

  void _filterPlayers(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredPlayers = List.from(_allPlayers);
      });
    } else {
      setState(() {
        _filteredPlayers = _allPlayers.where((player) => 
          player.name.toLowerCase().contains(query.toLowerCase())
        ).toList();
      });
    }
    _sortPlayers();
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252639),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterPlayers,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Поиск игроков...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.7)),
                  onPressed: () {
                    _searchController.clear();
                    _filterPlayers('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF252639),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (index) {
          setState(() {
            _selectedCategory = index;
          });
          _sortPlayers();
        },
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.6),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
        tabs: _categories.map((category) => Tab(text: category)).toList(),
      ),
    );
  }

  Widget _buildTopThree() {
    if (_filteredPlayers.length < 3) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 2-е место
          Expanded(child: _buildPodiumPlace(_filteredPlayers[1], 2, 60)),
          const SizedBox(width: 8),
          // 1-е место
          Expanded(child: _buildPodiumPlace(_filteredPlayers[0], 1, 80)),
          const SizedBox(width: 8),
          // 3-е место
          Expanded(child: _buildPodiumPlace(_filteredPlayers[2], 3, 60)),
        ],
      ),
    );
  }

  Widget _buildPodiumPlace(UserModel player, int place, double avatarSize) {
    Color placeColor;
    IconData placeIcon;
    
    switch (place) {
      case 1:
        placeColor = const Color(0xFFFFD700); // Золото
        placeIcon = Icons.emoji_events;
        break;
      case 2:
        placeColor = const Color(0xFFC0C0C0); // Серебро
        placeIcon = Icons.emoji_events;
        break;
      case 3:
        placeColor = const Color(0xFFCD7F32); // Бронза
        placeIcon = Icons.emoji_events;
        break;
      default:
        placeColor = Colors.grey;
        placeIcon = Icons.emoji_events;
    }

    return GestureDetector(
      onTap: () => _showPlayerProfile(player),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF252639),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: placeColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: placeColor, width: 3),
                    gradient: player.photoUrl == null
                        ? const LinearGradient(
                            colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                          )
                        : null,
                  ),
                  child: player.photoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            player.photoUrl!,
                            width: avatarSize,
                            height: avatarSize,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                                _buildDefaultAvatar(avatarSize),
                          ),
                        )
                      : _buildDefaultAvatar(avatarSize),
                ),
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: placeColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      placeIcon,
                      size: 16,
                      color: place == 1 ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              player.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _getStatValue(player),
              style: TextStyle(
                color: placeColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
        ),
      ),
      child: Icon(
        Icons.person,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }

  String _getStatValue(UserModel player) {
    switch (_selectedCategory) {
      case 0: // Общий рейтинг
        return '⭐ ${player.calculatedRating.toStringAsFixed(1)}';
      case 1: // Винрейт
        return '${player.winRate.toStringAsFixed(1)}%';
      case 2: // Игры
        return '${player.gamesPlayed} игр';
      case 3: // Очки
        return '${player.totalScore} очков';
      default:
        return '';
    }
  }

  Widget _buildPlayersList() {
    final playersToShow = _filteredPlayers.length > 3 
        ? _filteredPlayers.skip(3).toList() 
        : _filteredPlayers;
    
    if (playersToShow.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Игроки не найдены',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: playersToShow.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final player = playersToShow[index];
        final actualPosition = index + 4; // +3 для топ-3 + 1 для нумерации с 1
        
        return _buildPlayerCard(player, actualPosition);
      },
    );
  }

  Widget _buildPlayerCard(UserModel player, int position) {
    return GestureDetector(
      onTap: () => _showPlayerProfile(player),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF252639),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            // Позиция
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$position',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Аватар
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
              ),
              child: player.photoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        player.photoUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                            _buildDefaultAvatar(48),
                      ),
                    )
                  : _buildDefaultAvatar(48),
            ),
            const SizedBox(width: 12),
            
            // Информация об игроке
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    player.experienceLevel,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            // Статистика
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _getStatValue(player),
                  style: const TextStyle(
                    color: Color(0xFF4A90E2),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${player.wins}W/${player.losses}L',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPlayerProfile(UserModel player) {
    PlayerProfileDialog.show(
      context,
      ref,
      player.id,
      playerName: player.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1B2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Рейтинг игроков',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadPlayers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4A90E2),
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadPlayers,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A90E2),
                          ),
                          child: const Text(
                            'Повторить',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF4A90E2),
                  backgroundColor: const Color(0xFF252639),
                  onRefresh: _loadPlayers,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildSearchBar(),
                        _buildCategoryTabs(),
                        const SizedBox(height: 16),
                        if (_filteredPlayers.length >= 3) _buildTopThree(),
                        const SizedBox(height: 16),
                        _buildPlayersList(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }
} 