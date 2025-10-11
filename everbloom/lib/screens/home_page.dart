import 'package:flutter/material.dart';
import 'package:everbloom/models/habit.dart';
import 'package:everbloom/services/habit_service.dart';
import 'package:everbloom/screens/add_habit_page.dart';
import 'package:everbloom/screens/habit_list_page.dart';
import 'package:everbloom/widgets/habit_card.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HabitService _habitService = HabitService();
  List<Habit> _allHabits = [];
  List<Habit> _todayHabits = [];
  bool _isLoading = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _loadTodayHabits();
  }

  Future<void> _loadTodayHabits() async {
    setState(() => _isLoading = true);
    await _habitService.checkMissedHabits();
    final habits = await _habitService.getAllHabits();
    final today = _getDateKey(DateTime.now());
    setState(() {
      _allHabits = habits;
      _todayHabits = habits.where((h) => h.calendar[today] == null || h.calendar[today] == HabitStatus.skipped).toList();
      _isLoading = false;
    });
  }

  String _getDateKey(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Color _getCombinedColorForDay(DateTime day) {
    if (_allHabits.isEmpty) return Colors.transparent;
    final key = _getDateKey(day);
    bool anyCompleted = false;
    bool anyMissedOrSkipped = false;
    for (final habit in _allHabits) {
      final status = habit.calendar[key];
      if (status == HabitStatus.completed) {
        anyCompleted = true;
        break;
      } else if (status == HabitStatus.missed || status == HabitStatus.skipped) {
        anyMissedOrSkipped = true;
      }
    }
    if (anyCompleted) return Colors.green;
    if (anyMissedOrSkipped) return Colors.red;
    return Colors.transparent;
  }

  Future<void> _completeHabit(Habit habit) async {
    await _habitService.markHabitCompleted(habit.id);
    _loadTodayHabits();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🎉 Great job! ${habit.title} completed'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _skipHabit(Habit habit) async {
    await _habitService.markHabitSkipped(habit.id);
    _loadTodayHabits();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⏰ Task postponed. We\'ll remind you later!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today\'s Habits', style: theme.textTheme.titleLarge),
            Text(DateFormat('EEEE, MMM d').format(DateTime.now()), style: theme.textTheme.bodySmall),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_list),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const HabitListPage()));
              _loadTodayHabits();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTodayHabits,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('This Month', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          TableCalendar(
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            focusedDay: _focusedDay,
                            availableGestures: AvailableGestures.horizontalSwipe,
                            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: false),
                            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                            onDaySelected: (selected, focused) {
                              setState(() {
                                _selectedDay = selected;
                                _focusedDay = focused;
                              });
                            },
                            calendarStyle: CalendarStyle(
                              todayDecoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              selectedDecoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            calendarBuilders: CalendarBuilders(
                              defaultBuilder: (context, day, focusedDay) {
                                final color = _getCombinedColorForDay(day);
                                if (color != Colors.transparent) {
                                  return Center(
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.18),
                                        border: Border.all(color: color, width: 2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${day.day}',
                                          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return null;
                              },
                              todayBuilder: (context, day, focusedDay) {
                                final color = _getCombinedColorForDay(day);
                                if (color != Colors.transparent) {
                                  return Center(
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.25),
                                        border: Border.all(color: color, width: 2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${day.day}',
                                          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return Center(
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${day.day}',
                                        style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _LegendDot(color: Colors.green, label: 'Any habit completed'),
                              const SizedBox(width: 12),
                              _LegendDot(color: Colors.red, label: 'All missed/skipped'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_todayHabits.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text('All caught up! 🎉', style: theme.textTheme.headlineSmall),
                          const SizedBox(height: 8),
                          Text('No pending habits for today', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                        ],
                      ),
                    )
                  else ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text('Today', style: theme.textTheme.titleMedium),
                    ),
                    for (final habit in _todayHabits)
                      HabitCard(
                        habit: habit,
                        onComplete: () => _completeHabit(habit),
                        onSkip: () => _skipHabit(habit),
                      ),
                  ],
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddHabitPage()));
          _loadTodayHabits();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Habit'),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.25),
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
