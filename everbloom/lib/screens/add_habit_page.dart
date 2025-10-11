import 'package:flutter/material.dart';
import 'package:everbloom/models/habit.dart';
import 'package:everbloom/services/habit_service.dart';
import 'package:everbloom/services/storage_service.dart';
import 'package:intl/intl.dart';

class AddHabitPage extends StatefulWidget {
  final Habit? habit;
  const AddHabitPage({super.key, this.habit});

  @override
  State<AddHabitPage> createState() => _AddHabitPageState();
}

class _AddHabitPageState extends State<AddHabitPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final HabitService _habitService = HabitService();
  
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _durationMinutes = 30;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.habit != null) {
      _titleController.text = widget.habit!.title;
      _descriptionController.text = widget.habit!.description;
      _selectedTime = TimeOfDay(hour: widget.habit!.scheduledTime.hour, minute: widget.habit!.scheduledTime.minute);
      _durationMinutes = widget.habit!.durationMinutes;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final storageService = StorageService();
    var user = await storageService.getUser();
    if (user == null) {
      user = await storageService.getUser();
    }

    final now = DateTime.now();
    final scheduledDateTime = DateTime(now.year, now.month, now.day, _selectedTime.hour, _selectedTime.minute);

    final habit = Habit(
      id: widget.habit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'default_user',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      scheduledTime: scheduledDateTime,
      durationMinutes: _durationMinutes,
      currentStreak: widget.habit?.currentStreak ?? 0,
      createdAt: widget.habit?.createdAt ?? now,
      updatedAt: now,
      calendar: widget.habit?.calendar ?? {},
    );

    if (widget.habit != null) {
      await _habitService.updateHabit(habit);
    } else {
      await _habitService.createHabit(habit);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit != null ? 'Edit Habit' : 'Create New Habit'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Habit Details', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Habit Name',
                  hintText: 'e.g., Morning Meditation',
                  prefixIcon: const Icon(Icons.star),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
                validator: (val) => val?.isEmpty ?? true ? 'Please enter a habit name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'What does this habit involve?',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
                maxLines: 3,
                validator: (val) => val?.isEmpty ?? true ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 24),
              Text('Schedule', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: theme.colorScheme.primary),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Scheduled Time', style: theme.textTheme.bodySmall),
                          Text(_selectedTime.format(context), style: theme.textTheme.titleMedium),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timer, color: theme.colorScheme.primary),
                        const SizedBox(width: 16),
                        Text('Duration: $_durationMinutes minutes', style: theme.textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _durationMinutes.toDouble(),
                      min: 5,
                      max: 120,
                      divisions: 23,
                      label: '$_durationMinutes min',
                      onChanged: (val) => setState(() => _durationMinutes = val.toInt()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveHabit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(widget.habit != null ? 'Update Habit' : 'Create Habit', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
