import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:everbloom/models/user.dart';
import 'package:everbloom/models/habit.dart';

class StorageService {
  static const String _userKey = 'current_user';
  static const String _habitsKey = 'habits';

  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    return User.fromJson(jsonDecode(userJson));
  }

  Future<void> saveHabits(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    final habitsJson = habits.map((h) => h.toJson()).toList();
    await prefs.setString(_habitsKey, jsonEncode(habitsJson));
  }

  Future<List<Habit>> getHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final habitsJson = prefs.getString(_habitsKey);
    if (habitsJson == null) return [];
    final List<dynamic> decoded = jsonDecode(habitsJson);
    return decoded.map((h) => Habit.fromJson(h)).toList();
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
