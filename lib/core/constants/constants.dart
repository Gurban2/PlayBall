import 'package:flutter/material.dart';

// Цвета приложения
class AppColors {
  static const Color primary = Color(0xFF424242);
  static const Color secondary = Color(0xFF616161);
  static const Color accent = Color(0xFF757575);
  static const Color background = Color(0xFFF5F5F5);
  static const Color card = Colors.white;
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color text = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF757575);
  static const Color divider = Color(0xFFBDBDBD);
  static const Color warning = Color(0xFFFFB300);
  
  // Дополнительные темно-серые оттенки
  static const Color darkGrey = Color(0xFF303030);
  static const Color mediumGrey = Color(0xFF424242);
  static const Color lightGrey = Color(0xFF757575);
  
  // Роли пользователей
  static const Color userRole = Color(0xFF66BB6A);
  static const Color organizerRole = Color(0xFF424242);
  static const Color adminRole = Color(0xFF303030);
}

// Стили шрифтов для важных названий
class AppTextStyles {
  // Константы для шрифтов
  static const String notoSansSymbolsFont = 'NotoSansSymbols';

  // Заголовки - важные названия (используем системный Roboto)
  static const TextStyle heading1 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
    letterSpacing: 0.5,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
    letterSpacing: 0.3,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Color.fromARGB(255, 231, 231, 231),
    letterSpacing: 0.2,
  );
  
  // Заголовки для AppBar
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 0.5,
  );
  
  // Названия команд и игр
  static const TextStyle teamName = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
    letterSpacing: 0.3,
  );
  
  static const TextStyle gameName = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
    letterSpacing: 0.2,
  );
  
  // Обычный текст
  static const TextStyle bodyText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.text,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  // Стиль с символьным шрифтом
  static const TextStyle symbolText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    fontFamily: notoSansSymbolsFont,
    color: AppColors.text,
  );
}

// Строковые константы
class AppStrings {
  // Общие
  static const String appName = 'PlayBall';
  static const String loading = 'Загрузка...';
  static const String error = 'Ошибка';
  static const String success = 'Успешно';
  static const String ok = 'OK';
  static const String cancel = 'Отмена';
  static const String save = 'Сохранить';
  static const String delete = 'Удалить';
  static const String edit = 'Редактировать';
  static const String confirm = 'Подтвердить';
  
  // Аутентификация
  static const String login = 'Войти';
  static const String register = 'Регистрация';
  static const String email = 'Email';
  static const String password = 'Пароль';
  static const String confirmPassword = 'Подтвердите пароль';
  static const String name = 'Имя';
  static const String nickname = 'Ник';
  static const String forgotPassword = 'Забыли пароль?';
  static const String noAccount = 'Нет аккаунта?';
  static const String hasAccount = 'Уже есть аккаунт?';
  static const String resetPassword = 'Сбросить пароль';
  static const String logout = 'Выйти';
  
  // Профиль
  static const String profile = 'Профиль';
  static const String changePhoto = 'Изменить фото';
  static const String statistics = 'Статистика';
  static const String gamesPlayed = 'Игр сыграно';
  static const String wins = 'Победы';
  static const String losses = 'Поражения';
  static const String winRate = 'Процент побед';
  static const String rating = 'Рейтинг';
  
  // Комнаты и игры
  static const String rooms = 'Комнаты';
  static const String createRoom = 'Создать игру';
  static const String joinRoom = 'Присоединиться';
  static const String leaveRoom = 'Покинуть игру';
  static const String title = 'Название';
  static const String description = 'Описание';
  static const String location = 'Место проведения';
  static const String startTime = 'Время начала';
  static const String endTime = 'Время окончания';
  static const String maxParticipants = 'Максимум участников';
  static const String pricePerPerson = 'Цена за участие';
  static const String participants = 'Участники';
  static const String organizer = 'Организатор';
  static const String noParticipants = 'Нет участников';
  static const String gameDetails = 'Детали игры';
  static const String status = 'Статус';
  static const String planned = 'Запланирована';
  static const String active = 'Активная';
  static const String completed = 'Завершена';
  static const String cancelled = 'Отменена';
  static const String startGame = 'Начать игру';
  static const String endGame = 'Завершить игру';
  static const String cancelGame = 'Отменить игру';
  
  // Команды
  static const String teams = 'Команды';
  static const String createTeam = 'Создать команду';
  static const String joinTeam = 'Присоединиться к команде';
  static const String leaveTeam = 'Покинуть команду';
  static const String teamMembers = 'Участники команды';
  static const String noTeams = 'Нет команд';
  static const String selectTeam = 'Выбрать команду';
  
  // Режимы игры
  static const String normalMode = 'Обычный';
  static const String teamFriendlyMode = 'Команды';
  static const String tournamentMode = 'Турнир';
  static const String gameMode = 'Режим игры';
  
  // Постоянные команды пользователей
  static const String myTeam = 'Моя команда';
  static const String createMyTeam = 'Создать команду';
  static const String teamName = 'Название команды';
  static const String addFriend = 'Добавить друга';
  static const String removeMember = 'Исключить игрока';
  static const String confirmRemoveMember = 'Вы действительно хотите исключить этого игрока из команды?';
  static const String teamAvatar = 'Аватар команды';
  static const String selectTeamAvatar = 'Выбрать аватар команды';
  
  // Результаты и статистика
  static const String results = 'Результаты';
  static const String winner = 'Победитель';
  static const String score = 'Счет';
  static const String leaderboard = 'Рейтинг игроков';
  static const String matchHistory = 'История матчей';
  static const String noGamesPlayed = 'Нет сыгранных игр';
  
  // Уведомления
  static const String notifications = 'Уведомления';
  static const String noNotifications = 'Нет уведомлений';
  static const String newGame = 'Новая игра';
  static const String gameChanged = 'Изменения в игре';
  static const String gameStarting = 'Игра скоро начнется';
  
  // Админ-панель
  static const String adminPanel = 'Панель администратора';
  static const String users = 'Пользователи';
  static const String changeRole = 'Изменить роль';
  static const String userRole = 'Игрок';
  static const String organizerRole = 'Организатор';
  static const String adminRole = 'Администратор';
  
  // Новые строковые константы
  static const String settings = 'Настройки';
  
  // Строки для UI
  static const String welcome = 'Добро пожаловать в PlayBall';
  static const String noData = 'Нет данных';
  
  // Тексты подтверждений
  static const String confirmStartEarly = 'Вы действительно хотите начать игру раньше?';
  static const String confirmEndEarly = 'Вы действительно хотите закончить игру раньше?';
  static const String locationConflict = 'Зал занят другой игрой. Дождитесь своего времени';
  
  // Доступные локации
  static const List<String> availableLocations = [
    '102school',
    '276school', 
    '3school',
  ];
}

// Маршруты приложения
class AppRoutes {
  static const String welcome = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String schedule = '/schedule';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String room = '/room';
  static const String createRoom = '/create-room';
  static const String gameDetails = '/game-details';
  static const String team = '/team';
  static const String matchHistory = '/match-history';
  static const String leaderboard = '/leaderboard';
  static const String notifications = '/notifications';
  static const String adminPanel = '/admin-panel';
  static const String organizerDashboard = '/organizer-dashboard';
  static const String stats = '/stats';

  
  // Новые маршруты для команд
  static const String myTeam = '/my-team';
  static const String createMyTeam = '/create-my-team';

}

// Константы для Firestore
class FirestorePaths {
  static const String usersCollection = 'users';
  static const String roomsCollection = 'rooms';
  static const String teamsCollection = 'teams';
  static const String userTeamsCollection = 'user_teams';
  static const String notificationsCollection = 'notifications';
  static const String friendRequestsCollection = 'friend_requests';
  static const String teamInvitationsCollection = 'team_invitations';
  static const String teamApplicationsCollection = 'team_applications';
}

// Размеры элементов интерфейса
class AppSizes {
  static const double smallSpace = 8.0;
  static const double mediumSpace = 16.0;
  static const double largeSpace = 24.0;
  static const double extraLargeSpace = 32.0;
  
  static const double buttonHeight = 52.0;
  static const double buttonRadius = 8.0;
  
  static const double cardRadius = 12.0;
  static const double cardElevation = 2.0;
  
  static const double smallIconSize = 16.0;
  static const double mediumIconSize = 24.0;
  static const double largeIconSize = 32.0;
  
  static const double smallAvatarSize = 40.0;
  static const double mediumAvatarSize = 64.0;
  static const double largeAvatarSize = 120.0;
  
  static const EdgeInsets screenPadding = EdgeInsets.all(8.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(8.0);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(vertical: 8.0);
}

// Константы для анимаций
class AppAnimations {
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration longDuration = Duration(milliseconds: 500);
}

// Константы для правил валидации
class ValidationRules {
  static const int minPasswordLength = 6;
  static const int maxUsernameLength = 30;
  static const int minUsernameLength = 3;
  static const int maxTitleLength = 50;
  static const int maxDescriptionLength = 500;
  static const int maxLocationLength = 100;
  static const int minParticipants = 12;
  static const int maxParticipantsLimit = 30;
  static const double maxPrice = 10000.0;
  static const int maxActiveRoomsPerOrganizer = 3;
} 