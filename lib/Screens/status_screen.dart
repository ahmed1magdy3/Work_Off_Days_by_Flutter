import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import '../utils/settings_manager.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  int _workDays = 0;
  int _offDays = 0;

  String _status = '';
  int _daysRemaining = 0;
  String _arabicDate = '';
  String _switchDateArabic = '';
  Map<DateTime, String> _dayStatusMap = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsManager.loadSettings();
    setState(() {
      _startDate = settings['startDate'];
      _endDate = settings['endDate'];
      _workDays = settings['workDays'];
      _offDays = settings['offDays'];
    });

    _calculateStatus();
    await _generateArabicDates();
    _generateCalendarStatus();
  }

  void _calculateStatus() {
    if (_startDate == null) return;

    final now = DateTime.now();
    final daysUntilStart = _startDate!.difference(now).inDays;

    if (daysUntilStart > 0) {
      _status = 'قادم';
      _daysRemaining = daysUntilStart;
    } else {
      final daysPassed = now.difference(_startDate!).inDays;
      final cycleLength = _workDays + _offDays;
      final dayInCycle = daysPassed % cycleLength;

      if (dayInCycle < _workDays) {
        _status = 'شغل';
        _daysRemaining = _workDays - dayInCycle;
      } else {
        _status = 'إجازة';
        _daysRemaining = cycleLength - dayInCycle;
      }
    }
  }

  Future<void> _generateArabicDates() async {
    await initializeDateFormatting('ar');
    final now = DateTime.now();
    _arabicDate = DateFormat.yMMMMEEEEd('ar').format(now);

    if (_status == 'قادم') {
      _switchDateArabic = DateFormat.yMMMMEEEEd('ar').format(_startDate!);
    } else {
      final switchDate = now.add(Duration(days: _daysRemaining));
      _switchDateArabic = DateFormat.yMMMMEEEEd('ar').format(switchDate);
    }
  }

  void _generateCalendarStatus() {
    if (_startDate == null) return;

    _dayStatusMap.clear();
    DateTime today = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final day = DateTime(today.year, today.month, today.day + i);
      final daysSinceStart = day.difference(_startDate!).inDays;

      if (daysSinceStart < 0) {
        _dayStatusMap[day] = 'قبل البداية';
      } else {
        final cycleLength = _workDays + _offDays;
        final dayInCycle = daysSinceStart % cycleLength;
        _dayStatusMap[day] = (dayInCycle < _workDays) ? 'شغل' : 'إجازة';
      }
    }
  }

  String _getRemainingTimeText() {
    if (_endDate == null) return '—';
    final now = DateTime.now();
    final daysRemaining = _endDate!.difference(now).inDays;

    if (daysRemaining <= 14) {
      return '$daysRemaining يوم';
    } else if (daysRemaining <= 90) {
      final weeks = (daysRemaining / 7).floor();
      return '$weeks أسبوع';
    } else {
      final months = ((daysRemaining) / 30).floor();
      return '$months شهر';
    }
  }

  int _getRemainingJnoubCount() {
    if (_endDate == null || _startDate == null) return 0;
    int cycleDays = _workDays + _offDays;
    final remainingDays = _endDate!.difference(DateTime.now()).inDays;
    return (remainingDays / cycleDays).floor();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإجازة إمتى؟')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _startDate == null
            ? const Center(child: Text("لم يتم إعداد البيانات بعد", style: TextStyle(fontSize: 18)))
            : ListView(
          children: [
            _DateCard(text: _arabicDate),
            const SizedBox(height: 30),
            _StatusCard(
              status: _status,
              daysRemaining: _daysRemaining,
              switchDate: _switchDateArabic,
            ),
            const SizedBox(height: 20),
            _JnoubCard(
              monthsText: _getRemainingTimeText(),
              jnoubCount: _getRemainingJnoubCount(),
            ),
            const SizedBox(height: 30),
            const Text(
              'معاينة الجدول لمدة 30 يوم:',
              style: TextStyle(fontSize: 20, color: Colors.tealAccent, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildCalendarPreview(),
            const SizedBox(height: 30),
            const _LegendRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarPreview() {
    final today = DateTime.now();
    final firstDay = DateTime(today.year, today.month, today.day);
    final lastDay = firstDay.add(const Duration(days: 29));

    return TableCalendar(
      locale: 'ar_EG',
      firstDay: firstDay,
      lastDay: lastDay,
      focusedDay: today,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(color: Colors.white),
        leftChevronIcon: Icon(Icons.arrow_back_ios, color: Colors.white),
        rightChevronIcon: Icon(Icons.arrow_forward_ios, color: Colors.white),
      ),
      calendarStyle: const CalendarStyle(
        defaultTextStyle: TextStyle(color: Colors.white),
        weekendTextStyle: TextStyle(color: Colors.white70),
        outsideTextStyle: TextStyle(color: Colors.grey),
      ),
      calendarBuilders: CalendarBuilders(
        todayBuilder: (context, day, _) => _buildDayContainer(day, isToday: true),
        defaultBuilder: (context, day, _) => _buildDayContainer(day),
      ),
      selectedDayPredicate: (_) => false,
      onDaySelected: (_, __) {},
    );
  }

  Widget _buildDayContainer(DateTime day, {bool isToday = false}) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final status = _dayStatusMap[normalizedDay];
    Color bgColor;

    if (status == 'شغل') {
      bgColor = isToday ? Colors.blue[900]! : Colors.blue[700]!;
    } else if (status == 'إجازة') {
      bgColor = isToday ? Colors.green[900]! : Colors.green[700]!;
    } else if (status == 'قبل البداية') {
      bgColor = Colors.grey[600]!;
    } else {
      bgColor = Colors.black;
    }

    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: bgColor,
        shape: isToday ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isToday ? null : BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  final String text;
  const _DateCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[850],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          text,
          style: const TextStyle(fontSize: 22, color: Colors.tealAccent),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String status;
  final int daysRemaining;
  final String switchDate;

  const _StatusCard({required this.status, required this.daysRemaining, required this.switchDate});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    if (status == 'شغل') {
      bgColor = Colors.blueGrey[800]!;
    } else if (status == 'إجازة') {
      bgColor = Colors.green[800]!;
    } else {
      bgColor = Colors.orange[800]!;
    }

    return Card(
      color: bgColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              status == 'قادم' ? "لم تبدأ فترة الشغل بعد" : "اليوم: $status",
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              status == 'قادم'
                  ? "متبقي $daysRemaining يوم على بدء الجدول"
                  : "المتبقي على التبديل: $daysRemaining يوم",
              style: const TextStyle(fontSize: 20, color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Text(
              status == 'قادم'
                  ? "تاريخ البدء: $switchDate"
                  : "تاريخ التبديل: $switchDate",
              style: const TextStyle(fontSize: 20, color: Colors.amberAccent),
            ),
          ],
        ),
      ),
    );
  }
}

class _JnoubCard extends StatelessWidget {
  final String monthsText;
  final int jnoubCount;

  const _JnoubCard({required this.monthsText, required this.jnoubCount});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[850],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'الوقت المتبقي على نهاية الخدمة',
              style: TextStyle(fontSize: 20, color: Colors.tealAccent, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              ' المتبقي: $monthsText',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              ' عدد الجناب المتبقية: $jnoubCount',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: const [
        _LegendItem(color: Colors.blue, label: 'شغل'),
        _LegendItem(color: Colors.green, label: 'إجازة'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}