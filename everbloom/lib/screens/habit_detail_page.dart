import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:everbloom/models/habit.dart';
import 'package:everbloom/services/habit_service.dart';
import 'package:intl/intl.dart';

class HabitDetailPage extends StatefulWidget {
  final Habit habit;
  const HabitDetailPage({super.key, required this.habit});

  @override
  State<HabitDetailPage> createState() => _HabitDetailPageState();
}

class _HabitDetailPageState extends State<HabitDetailPage> {
  final HabitService _habitService = HabitService();
  late Habit _habit;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _habit = widget.habit;
    _loadHabit();
  }

  Future<void> _loadHabit() async {
    final habits = await _habitService.getAllHabits();
    final updated = habits.firstWhere((h) => h.id == _habit.id, orElse: () => _habit);
    setState(() => _habit = updated);
  }

  Color _getColorForDay(DateTime day) {
    final dateKey = _getDateKey(day);
    final status = _habit.calendar[dateKey];
    
    switch (status) {
      case HabitStatus.completed:
        return Colors.green;
      case HabitStatus.missed:
      case HabitStatus.skipped:
        return Colors.red;
      default:
        return Colors.transparent;
    }
  }

  String _getDateKey(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedDays = _habit.calendar.values.where((s) => s == HabitStatus.completed).length;
    final missedDays = _habit.calendar.values.where((s) => s == HabitStatus.missed || s == HabitStatus.skipped).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_habit.title, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(_habit.description, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 20, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(DateFormat.jm().format(_habit.scheduledTime), style: theme.textTheme.bodyMedium),
                        const SizedBox(width: 24),
                        Icon(Icons.timer, size: 20, color: theme.colorScheme.secondary),
                        const SizedBox(width: 8),
                        Text('${_habit.durationMinutes} minutes', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.local_fire_department, color: Colors.orange, size: 32),
                        ),
                        const SizedBox(height: 8),
                        Text('${_habit.currentStreak}', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text('Current Streak', style: theme.textTheme.bodySmall),
                      ],
                    ),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle, color: Colors.green, size: 32),
                        ),
                        const SizedBox(height: 8),
                        Text('$completedDays', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text('Completed', style: theme.textTheme.bodySmall),
                      ],
                    ),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.cancel, color: Colors.red, size: 32),
                        ),
                        const SizedBox(height: 8),
                        Text('$missedDays', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text('Missed', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Progress Calendar', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: (selected, focused) {
                        setState(() {
                          _selectedDay = selected;
                          _focusedDay = focused;
                        });
                      },
                      calendarStyle: CalendarStyle(
                        markerDecoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                        todayDecoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          final color = _getColorForDay(day);
                          if (color != Colors.transparent) {
                            return Center(
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.2),
                                  border: Border.all(color: color, width: 2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(child: Text('${day.day}', style: TextStyle(color: color))),
                              ),
                            );
                          }
                          return null;
                        },
                        todayBuilder: (context, day, focusedDay) {
                          final color = _getColorForDay(day);
                          if (color != Colors.transparent) {
                            return Center(
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.3),
                                  border: Border.all(color: color, width: 2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(child: Text('${day.day}', style: TextStyle(color: color, fontWeight: FontWeight.bold))),
                              ),
                            );
                          }
                          return Center(
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(child: Text('${day.day}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold))),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegend(Colors.green, 'Completed'),
                        const SizedBox(width: 16),
                        _buildLegend(Colors.red, 'Missed/Skipped'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            border: Border.all(color: color, width: 2),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
