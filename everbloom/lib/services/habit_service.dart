import 'package:everbloom/models/habit.dart';
import 'package:everbloom/services/storage_service.dart';
import 'package:everbloom/services/notification_service.dart';

class HabitService {
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();

  Future<List<Habit>> getAllHabits() async => await _storageService.getHabits();

  Future<void> createHabit(Habit habit) async {
    final habits = await _storageService.getHabits();
    habits.add(habit);
    await _storageService.saveHabits(habits);
    await _notificationService.scheduleHabitNotification(habit);
  }

  Future<void> updateHabit(Habit habit) async {
    final habits = await _storageService.getHabits();
    final index = habits.indexWhere((h) => h.id == habit.id);
    if (index != -1) {
      habits[index] = habit;
      await _storageService.saveHabits(habits);
      await _notificationService.cancelNotification(habit.id.hashCode);
      await _notificationService.scheduleHabitNotification(habit);
    }
  }

  Future<void> deleteHabit(String habitId) async {
    final habits = await _storageService.getHabits();
    habits.removeWhere((h) => h.id == habitId);
    await _storageService.saveHabits(habits);
    await _notificationService.cancelNotification(habitId.hashCode);
  }

  Future<void> markHabitCompleted(String habitId) async {
    final habits = await _storageService.getHabits();
    final index = habits.indexWhere((h) => h.id == habitId);
    if (index != -1) {
      final habit = habits[index];
      final today = _getDateKey(DateTime.now());
      final updatedCalendar = Map<String, HabitStatus>.from(habit.calendar);
      updatedCalendar[today] = HabitStatus.completed;
      habits[index] = habit.copyWith(
        calendar: updatedCalendar,
        currentStreak: _calculateStreak(updatedCalendar),
        updatedAt: DateTime.now(),
      );
      await _storageService.saveHabits(habits);
    }
  }

  Future<void> markHabitSkipped(String habitId) async {
    final habits = await _storageService.getHabits();
    final index = habits.indexWhere((h) => h.id == habitId);
    if (index != -1) {
      final habit = habits[index];
      final today = _getDateKey(DateTime.now());
      final updatedCalendar = Map<String, HabitStatus>.from(habit.calendar);
      updatedCalendar[today] = HabitStatus.skipped;
      habits[index] = habit.copyWith(
        calendar: updatedCalendar,
        updatedAt: DateTime.now(),
      );
      await _storageService.saveHabits(habits);
      await _notificationService.scheduleSkippedTaskReminder(habit);
    }
  }

  Future<void> checkMissedHabits() async {
    final habits = await _storageService.getHabits();
    final today = _getDateKey(DateTime.now());
    bool updated = false;

    for (int i = 0; i < habits.length; i++) {
      final habit = habits[i];
      if (!habit.calendar.containsKey(today)) {
        final now = DateTime.now();
        final scheduledToday = DateTime(
          now.year, now.month, now.day,
          habit.scheduledTime.hour, habit.scheduledTime.minute
        );
        
        if (now.isAfter(scheduledToday.add(Duration(hours: 24)))) {
          final updatedCalendar = Map<String, HabitStatus>.from(habit.calendar);
          updatedCalendar[today] = HabitStatus.missed;
          habits[i] = habit.copyWith(
            calendar: updatedCalendar,
            currentStreak: 0,
            updatedAt: DateTime.now(),
          );
          updated = true;
        }
      }
    }

    if (updated) await _storageService.saveHabits(habits);
  }

  int _calculateStreak(Map<String, HabitStatus> calendar) {
    if (calendar.isEmpty) return 0;
    
    final sortedDates = calendar.keys.toList()..sort((a, b) => b.compareTo(a));
    int streak = 0;
    DateTime? previousDate;

    for (final dateKey in sortedDates) {
      final date = DateTime.parse(dateKey);
      if (calendar[dateKey] == HabitStatus.completed) {
        if (previousDate == null || previousDate.difference(date).inDays == 1) {
          streak++;
          previousDate = date;
        } else {
          break;
        }
      } else {
        break;
      }
    }
    return streak;
  }

  String _getDateKey(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
