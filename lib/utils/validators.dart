import 'constants.dart';

class Validators {
  // Валидация email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email не может быть пустым';
    }
    
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );
    
    if (!emailRegExp.hasMatch(value)) {
      return 'Введите корректный email';
    }
    
    return null;
  }
  
  // Валидация пароля
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Пароль не может быть пустым';
    }
    
    if (value.length < ValidationRules.minPasswordLength) {
      return 'Пароль должен содержать минимум ${ValidationRules.minPasswordLength} символов';
    }
    
    return null;
  }
  
  // Валидация подтверждения пароля
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Подтверждение пароля не может быть пустым';
    }
    
    if (value != password) {
      return 'Пароли не совпадают';
    }
    
    return null;
  }
  
  // Валидация имени пользователя
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Имя не может быть пустым';
    }
    
    if (value.length < ValidationRules.minUsernameLength) {
      return 'Имя должно содержать минимум ${ValidationRules.minUsernameLength} символа';
    }
    
    if (value.length > ValidationRules.maxUsernameLength) {
      return 'Имя должно содержать максимум ${ValidationRules.maxUsernameLength} символов';
    }
    
    return null;
  }
  
  // Валидация ника пользователя (более строгие правила)
  static String? validateNickname(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ник не может быть пустым';
    }
    
    if (value.length < ValidationRules.minUsernameLength) {
      return 'Ник должен содержать минимум ${ValidationRules.minUsernameLength} символа';
    }
    
    if (value.length > ValidationRules.maxUsernameLength) {
      return 'Ник должен содержать максимум ${ValidationRules.maxUsernameLength} символов';
    }

    // Проверяем, что ник содержит только допустимые символы
    final nicknameRegExp = RegExp(r'^[a-zA-Z0-9а-яА-Я_-]+$');
    if (!nicknameRegExp.hasMatch(value)) {
      return 'Ник может содержать только буквы, цифры, дефис и подчеркивание';
    }

    // Проверяем, что ник не состоит только из цифр
    final onlyDigitsRegExp = RegExp(r'^\d+$');
    if (onlyDigitsRegExp.hasMatch(value)) {
      return 'Ник не может состоять только из цифр';
    }
    
    return null;
  }
  
  // Валидация названия комнаты
  static String? validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Название не может быть пустым';
    }
    
    if (value.length > ValidationRules.maxTitleLength) {
      return 'Название должно содержать максимум ${ValidationRules.maxTitleLength} символов';
    }
    
    return null;
  }
  
  // Валидация описания
  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Описание не может быть пустым';
    }
    
    if (value.length > ValidationRules.maxDescriptionLength) {
      return 'Описание должно содержать максимум ${ValidationRules.maxDescriptionLength} символов';
    }
    
    return null;
  }
  
  // Валидация места проведения
  static String? validateLocation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Место проведения не может быть пустым';
    }
    
    if (value.length > ValidationRules.maxLocationLength) {
      return 'Место проведения должно содержать максимум ${ValidationRules.maxLocationLength} символов';
    }
    
    return null;
  }
  
  // Валидация максимального количества участников
  static String? validateMaxParticipants(String? value) {
    if (value == null || value.isEmpty) {
      return 'Укажите максимальное количество участников';
    }
    
    final intValue = int.tryParse(value);
    if (intValue == null) {
      return 'Введите корректное число';
    }
    
    if (intValue < ValidationRules.minParticipants) {
      return 'Минимальное количество участников - ${ValidationRules.minParticipants}';
    }
    
    if (intValue > ValidationRules.maxParticipantsLimit) {
      return 'Максимальное количество участников - ${ValidationRules.maxParticipantsLimit}';
    }
    
    return null;
  }
  
  // Валидация количества команд
  static String? validateNumberOfTeams(String? value) {
    if (value == null || value.isEmpty) {
      return 'Укажите количество команд';
    }
    
    final intValue = int.tryParse(value);
    if (intValue == null) {
      return 'Введите корректное число';
    }
    
    if (intValue < 2) {
      return 'Минимальное количество команд - 2';
    }
    
    if (intValue > 10) {
      return 'Максимальное количество команд - 10';
    }
    
    return null;
  }
  
  // Валидация цены
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Укажите цену';
    }
    
    final doubleValue = double.tryParse(value);
    if (doubleValue == null) {
      return 'Введите корректное число';
    }
    
    if (doubleValue < 0) {
      return 'Цена не может быть отрицательной';
    }
    
    if (doubleValue > ValidationRules.maxPrice) {
      return 'Максимальная цена - ${ValidationRules.maxPrice}';
    }
    
    return null;
  }
  
  // Валидация даты и времени
  static String? validateDateTime(DateTime? value) {
    if (value == null) {
      return 'Выберите дату и время';
    }
    
    final now = DateTime.now();
    if (value.isBefore(now)) {
      return 'Дата и время не могут быть в прошлом';
    }
    
    return null;
  }
  
  // Валидация времени окончания
  static String? validateEndTime(DateTime? endTime, DateTime? startTime) {
    if (endTime == null) {
      return 'Выберите время окончания';
    }
    
    if (startTime == null) {
      return 'Сначала выберите время начала';
    }
    
    if (endTime.isBefore(startTime) || endTime.isAtSameMomentAs(startTime)) {
      return 'Время окончания должно быть позже времени начала';
    }
    
    return null;
  }
} 