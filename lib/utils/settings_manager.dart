import 'package:shared_preferences/shared_preferences.dart';

class SettingsManager {
  // Keys for SharedPreferences
  static const String _startDateKey = 'start_date';
  static const String _workDaysKey = 'work_days';
  static const String _offDaysKey = 'off_days';
  static const String _endDateKey = 'end_date';

  // Default values
  static const int _defaultWorkDays = 6;
  static const int _defaultOffDays = 6;
  static final DateTime _defaultStartDate = DateTime(2025, 7, 13);
  static final DateTime? _defaultEndDate = null;//DateTime(2026, 10, 1);

  /// Load all settings from SharedPreferences
  static Future<Map<String, dynamic>> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load start date
      final startDateString = prefs.getString(_startDateKey);
      DateTime startDate;

      if (startDateString != null) {
        startDate = DateTime.parse(startDateString);
      } else {
        startDate = _defaultStartDate;
        await _saveDefaultSettings(prefs, startDate);
      }

      // Load work and off days
      final workDays = prefs.getInt(_workDaysKey) ?? _defaultWorkDays;
      final offDays = prefs.getInt(_offDaysKey) ?? _defaultOffDays;

      // Load end date
      final endDateString = prefs.getString(_endDateKey);
      DateTime? endDate;

      if (endDateString != null) {
        endDate = DateTime.parse(endDateString);
      } else {
        endDate = _defaultEndDate;

        if (endDate != null) {
          await prefs.setString(_endDateKey, endDate!.toIso8601String());
        } else {
          await prefs.remove(_endDateKey); // أو تجاهل الحفظ لو null
        }
      }


      return {
        'startDate': startDate,
        'workDays': workDays,
        'offDays': offDays,
        'endDate': endDate,
      };
    } catch (e) {
      print('Error loading settings: $e');
      return {
        'startDate': _defaultStartDate,
        'workDays': _defaultWorkDays,
        'offDays': _defaultOffDays,
        'endDate': _defaultEndDate,
      };
    }
  }

  /// Save settings to SharedPreferences
  static Future<bool> saveSettings(
      DateTime startDate,
      int workDays,
      int offDays,
      DateTime endDate,
      ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await Future.wait([
        prefs.setString(_startDateKey, startDate.toIso8601String()),
        prefs.setInt(_workDaysKey, workDays),
        prefs.setInt(_offDaysKey, offDays),
        prefs.setString(_endDateKey, endDate.toIso8601String()),
      ]);

      return true;
    } catch (e) {
      print('Error saving settings: $e');
      return false;
    }
  }

  /// Save default settings on first run
  static Future<void> _saveDefaultSettings(
      SharedPreferences prefs,
      DateTime startDate,
      ) async {
    List<Future> futures = [
      prefs.setString(_startDateKey, startDate.toIso8601String()),
      prefs.setInt(_workDaysKey, _defaultWorkDays),
      prefs.setInt(_offDaysKey, _defaultOffDays),
    ];

    if (_defaultEndDate != null) {
      futures.add(
        prefs.setString(_endDateKey, _defaultEndDate!.toIso8601String()),
      );
    }

    await Future.wait(futures);
  }


  /// Clear all settings (useful for testing or reset)
  static Future<bool> clearSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_startDateKey),
        prefs.remove(_workDaysKey),
        prefs.remove(_offDaysKey),
        prefs.remove(_endDateKey),
      ]);
      return true;
    } catch (e) {
      print('Error clearing settings: $e');
      return false;
    }
  }

  /// Validate input values
  static bool validateSettings(int workDays, int offDays) {
    return workDays > 0 && offDays > 0 && workDays <= 365 && offDays <= 365;
  }
}
