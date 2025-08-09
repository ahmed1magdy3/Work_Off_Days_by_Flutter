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
  static final DateTime? _defaultEndDate = null;

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

      if (endDateString != null && endDateString.isNotEmpty) {
        try {
          endDate = DateTime.parse(endDateString);
        } catch (e) {
          print('Error parsing end date: $e');
          endDate = _defaultEndDate;
        }
      } else {
        endDate = _defaultEndDate;
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
      DateTime? endDate, // Made nullable
      ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      List<Future> futures = [
        prefs.setString(_startDateKey, startDate.toIso8601String()),
        prefs.setInt(_workDaysKey, workDays),
        prefs.setInt(_offDaysKey, offDays),
      ];

      // Only save end date if it's not null
      if (endDate != null) {
        futures.add(prefs.setString(_endDateKey, endDate.toIso8601String()));
      } else {
        futures.add(prefs.remove(_endDateKey));
      }

      await Future.wait(futures);

      print('Settings saved successfully:');
      print('Start date: $startDate');
      print('Work days: $workDays');
      print('Off days: $offDays');
      print('End date: $endDate');

      return true;
    } catch (e) {
      print('Error saving settings: $e');
      return false;
    }
  }

  /// Save settings with non-nullable endDate (for backward compatibility)
  static Future<bool> saveSettingsWithEndDate(
      DateTime startDate,
      int workDays,
      int offDays,
      DateTime endDate,
      ) async {
    return await saveSettings(startDate, workDays, offDays, endDate);
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
      print('All settings cleared');
      return true;
    } catch (e) {
      print('Error clearing settings: $e');
      return false;
    }
  }

  /// Validate input values
  static bool validateSettings(int workDays, int offDays) {
    final isValid = workDays > 0 &&
        offDays > 0 &&
        workDays <= 365 &&
        offDays <= 365;

    print('Validating settings: workDays=$workDays, offDays=$offDays, valid=$isValid');
    return isValid;
  }

  /// Get current cycle information
  static Map<String, dynamic> getCurrentCycleInfo(
      DateTime startDate,
      int workDays,
      int offDays,
      ) {
    final now = DateTime.now();
    final cycleLength = workDays + offDays;
    final daysSinceStart = now.difference(startDate).inDays;
    final currentCycleNumber = (daysSinceStart / cycleLength).floor();
    final dayInCurrentCycle = daysSinceStart % cycleLength;

    final currentCycleStart = startDate.add(Duration(days: currentCycleNumber * cycleLength));
    final currentOffStart = currentCycleStart.add(Duration(days: workDays));
    final currentOffEnd = currentOffStart.add(Duration(days: offDays));

    final isWorkPeriod = dayInCurrentCycle < workDays;
    final isOffPeriod = !isWorkPeriod;

    return {
      'cycleLength': cycleLength,
      'daysSinceStart': daysSinceStart,
      'currentCycleNumber': currentCycleNumber,
      'dayInCurrentCycle': dayInCurrentCycle,
      'currentCycleStart': currentCycleStart,
      'currentOffStart': currentOffStart,
      'currentOffEnd': currentOffEnd,
      'isWorkPeriod': isWorkPeriod,
      'isOffPeriod': isOffPeriod,
      'daysUntilNextOff': isWorkPeriod ? (workDays - dayInCurrentCycle) : 0,
      'daysUntilWork': isOffPeriod ? (cycleLength - dayInCurrentCycle) : 0,
    };
  }

  /// Debug method to print all settings
  static Future<void> debugPrintSettings() async {
    try {
      final settings = await loadSettings();
      print('=== Current Settings ===');
      print('Start Date: ${settings['startDate']}');
      print('Work Days: ${settings['workDays']}');
      print('Off Days: ${settings['offDays']}');
      print('End Date: ${settings['endDate']}');

      if (settings['startDate'] != null) {
        final cycleInfo = getCurrentCycleInfo(
          settings['startDate'],
          settings['workDays'],
          settings['offDays'],
        );
        print('=== Cycle Information ===');
        cycleInfo.forEach((key, value) {
          print('$key: $value');
        });
      }

      print('========================');
    } catch (e) {
      print('Error in debugPrintSettings: $e');
    }
  }
}