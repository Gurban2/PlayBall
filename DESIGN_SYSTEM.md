# 🎨 Система дизайна PlayBall - Material Design 3

Этот документ описывает систему дизайна приложения PlayBall, основанную на Material Design 3.

## 📋 Содержание

- [Обзор](#обзор)
- [Цветовая схема](#цветовая-схема)
- [Типография](#типография)
- [Компоненты](#компоненты)
- [Анимации](#анимации)
- [Использование](#использование)

## 🌟 Обзор

Система дизайна PlayBall построена на принципах Material Design 3 и включает:

- **Мягкие адаптивные цвета** - сбалансированная палитра с хорошей читаемостью
- **Современные компоненты** - улучшенные виджеты с анимациями
- **Консистентная типография** - единообразный стиль текста
- **Плавные анимации** - улучшенный пользовательский опыт
- **Доступность** - высокий контраст и поддержка различных возможностей пользователей

## 🎨 Цветовая схема

### Основные цвета

```dart
// Светлая тема
Primary: #6366F1 (индиго) - основной цвет приложения
Secondary: #8B5CF6 (фиолетовый) - вторичные элементы
Tertiary: #06B6D4 (голубой) - акцентные элементы
Error: #EF4444 (красный) - ошибки
Success: #10B981 (зеленый) - успешные операции
Warning: #F59E0B (желтый) - предупреждения
Surface: #FCFCFD (очень светлый) - поверхности карточек
Background: #FEFEFE (белый) - основной фон

// Темная тема
Primary: #A5B4FC (светлый индиго) - основной цвет
Secondary: #C4B5FD (светлый фиолетовый) - вторичные элементы
Tertiary: #67E8F9 (светлый голубой) - акцентные элементы
Error: #FCA5A5 (светлый красный) - ошибки
Surface: #1F2937 (темно-серый) - поверхности карточек
Background: #111827 (очень темный) - основной фон
onSurface: #F9FAFB (светлый текст) - текст на поверхностях
onBackground: #F9FAFB (светлый текст) - текст на фоне
```

### Принципы цветовой схемы

- **Мягкость**: цвета не слишком яркие и не вызывают усталость глаз
- **Контрастность**: достаточный контраст для читаемости (WCAG AA)
- **Согласованность**: все цвета гармонично сочетаются между собой
- **Адаптивность**: автоматическое переключение между светлой и темной темами

### Семантические цвета

- **Success**: `AppTheme.successColor` (#10B981) - зеленый для успешных операций
- **Warning**: `AppTheme.warningColor` (#F59E0B) - желтый для предупреждений
- **Error**: `colorScheme.error` (#EF4444) - красный для ошибок
- **Info**: `colorScheme.primary` (#6366F1) - индиго для информационных сообщений

## 📝 Типография

### Иерархия текста

```dart
// Дисплейные стили (большие заголовки)
displayLarge: 57px, Regular
displayMedium: 45px, Regular
displaySmall: 36px, Regular

// Заголовки
headlineLarge: 32px, SemiBold
headlineMedium: 28px, SemiBold
headlineSmall: 24px, SemiBold

// Заголовки среднего размера
titleLarge: 22px, SemiBold
titleMedium: 16px, SemiBold
titleSmall: 14px, SemiBold

// Лейблы
labelLarge: 14px, SemiBold
labelMedium: 12px, SemiBold
labelSmall: 11px, SemiBold

// Тело текста
bodyLarge: 16px, Regular (line-height: 1.5)
bodyMedium: 14px, Regular (line-height: 1.4)
bodySmall: 12px, Regular (line-height: 1.3)
```

## 🧩 Компоненты

### EnhancedButton

Улучшенная кнопка с анимациями и тактильной обратной связью.

```dart
EnhancedButton(
  text: 'Создать игру',
  icon: Icons.add,
  type: ButtonType.primary, // primary | secondary | tertiary
  size: ButtonSize.medium,  // small | medium | large
  isLoading: false,
  isFullWidth: false,
  onPressed: () => {},
)
```

**Типы кнопок:**
- `primary` - основная кнопка (заливка)
- `secondary` - вторичная кнопка (контур)
- `tertiary` - текстовая кнопка

**Размеры:**
- `small` - 36px высота
- `medium` - 48px высота (по умолчанию)
- `large` - 56px высота

### EnhancedCard

Анимированная карточка с hover эффектами.

```dart
EnhancedCard(
  onTap: () => {},
  hasHoverEffect: true,
  padding: EdgeInsets.all(16),
  margin: EdgeInsets.all(8),
  elevation: 1,
  child: YourContent(),
)
```

### EnhancedTextField

Улучшенное поле ввода с анимациями.

```dart
EnhancedTextField(
  label: 'Email',
  hint: 'example@mail.com',
  prefixIcon: Icons.email,
  suffixIcon: Icons.visibility,
  isRequired: true,
  keyboardType: TextInputType.emailAddress,
  onChanged: (value) => {},
)
```

### StatsCard

Статистическая карточка с анимациями.

```dart
StatsCard(
  title: 'Игры сыграны',
  value: '42',
  icon: Icons.sports_volleyball,
  color: Theme.of(context).colorScheme.primary,
  subtitle: '+5 за неделю',
  onTap: () => {},
)
```

### EnhancedLoadingIndicator

Анимированный индикатор загрузки.

```dart
EnhancedLoadingIndicator(
  style: LoadingStyle.circular, // circular | pulse | dots
  message: 'Загружаем данные...',
  color: Theme.of(context).colorScheme.primary,
  size: 40.0,
)
```

## 🎭 Анимации

### Утилиты анимаций

Библиотека `AnimationUtils` предоставляет готовые анимации:

```dart
// Появление снизу
AnimationUtils.slideUpAnimation(
  child: widget,
  controller: controller,
  delay: Duration(milliseconds: 100),
)

// Исчезновение
AnimationUtils.fadeAnimation(
  child: widget,
  controller: controller,
  delay: Duration.zero,
)

// Масштабирование
AnimationUtils.scaleAnimation(
  child: widget,
  controller: controller,
  curve: Curves.elasticOut,
)

// Комбинированная анимация
AnimationUtils.enhancedEntryAnimation(
  child: widget,
  controller: controller,
  delay: Duration(milliseconds: 200),
)

// Анимация для списков
AnimationUtils.staggeredListAnimation(
  child: widget,
  index: index,
  controller: controller,
)
```

### Preset анимации

```dart
// Длительности
AnimationUtils.fastDuration     // 150ms
AnimationUtils.normalDuration   // 300ms
AnimationUtils.slowDuration     // 500ms

// Кривые
AnimationUtils.fastOut    // Curves.fastOutSlowIn
AnimationUtils.elastic    // Curves.elasticOut
AnimationUtils.bounce     // Curves.bounceOut
AnimationUtils.smooth     // Curves.easeInOut
```

## 📱 Адаптивность

### Breakpoints

```dart
// Мобильные устройства
mobile: < 600px

// Планшеты
tablet: 600px - 1024px

// Десктоп
desktop: > 1024px
```

### Отступы

```dart
// Стандартные отступы
xs: 4px
sm: 8px
md: 16px
lg: 24px
xl: 32px
xxl: 48px
```

## 🔧 Использование

### Применение темы

```dart
// В main.dart
MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.system,
  // ...
)
```

### Получение цветов

```dart
final colorScheme = Theme.of(context).colorScheme;

// Основные цвета
colorScheme.primary
colorScheme.secondary
colorScheme.surface
colorScheme.background

// Дополнительные цвета
AppTheme.successColor
AppTheme.warningColor
```

### Получение стилей текста

```dart
final textTheme = Theme.of(context).textTheme;

// Использование стилей
Text(
  'Заголовок',
  style: textTheme.headlineMedium?.copyWith(
    fontWeight: FontWeight.bold,
    color: colorScheme.primary,
  ),
)
```

## 🚀 Демонстрация

Для просмотра всех компонентов и их возможностей используйте `DesignDemoScreen`:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const DesignDemoScreen(),
  ),
);
```

Демо-экран включает:
- Все типы кнопок
- Карточки с анимациями
- Поля ввода
- Индикаторы загрузки
- Демонстрацию анимаций
- Тестирование уведомлений

## 📋 Checklist для разработчиков

При создании нового UI компонента убедитесь:

- [ ] Использованы цвета из `Theme.of(context).colorScheme`
- [ ] Применены стили текста из `textTheme`
- [ ] Добавлены соответствующие анимации
- [ ] Компонент адаптивен под разные размеры экрана
- [ ] Соблюдены принципы доступности
- [ ] Добавлена тактильная обратная связь (где уместно)
- [ ] Компонент протестирован в светлой и темной темах

## 🎯 Лучшие практики

1. **Консистентность** - используйте готовые компоненты из системы дизайна
2. **Производительность** - избегайте лишних перестроений виджетов
3. **Доступность** - добавляйте семантические метки и поддержку screen readers
4. **Анимации** - используйте умеренно, не перегружайте интерфейс
5. **Цвета** - всегда используйте цвета из темы для поддержки темного режима

## 🔄 Обновления

Система дизайна будет развиваться по мере роста приложения. Основные области для будущих обновлений:

- Динамические цвета (Material You)
- Дополнительные компоненты
- Улучшенные анимации
- Поддержка больших экранов
- Темы для брендинга

---

*Создано для PlayBall App с ❤️* 