import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../utils/settings_manager.dart';

class PredictScreen extends StatefulWidget {
  const PredictScreen({super.key});

  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen> {
  DateTime? _startDate;
  int _workDays = 0;
  int _offDays = 0;
  DateTime? _selectedDate;

  String _status = '';
  String _message = '';
  String _period = '';
  IconData _icon = Icons.question_mark;
  Color _bgColor = Colors.grey[850]!;
  Color _textColor = Colors.white;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ar').then((_) => _loadSettings());
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsManager.loadSettings();

    setState(() {
      _startDate = settings['startDate'];
      _workDays = settings['workDays'];
      _offDays = settings['offDays'];
      _loading = false;
    });
  }

  void _checkDate(DateTime date) {
    if (_startDate == null) return;

    int daysSinceStart = date.difference(_startDate!).inDays;

    if (daysSinceStart < 0) {
      setState(() {
        _status = 'قبل البداية';
        _message = 'هذا التاريخ يسبق بداية الجدول!';
        _icon = Icons.info_outline;
        _bgColor = Colors.grey[700]!;
        _textColor = Colors.white;
        _period = '';
      });
      return;
    }

    int cycleLength = _workDays + _offDays;
    int dayInCycle = daysSinceStart % cycleLength;
    int cycleStart = daysSinceStart - dayInCycle;
    DateTime periodStart = _startDate!.add(Duration(days: cycleStart));
    DateTime periodEnd = periodStart.add(Duration(days: cycleLength - 1));
    final formatter = DateFormat.yMMMMd('ar');

    if (dayInCycle < _workDays) {
      setState(() {
        _status = 'شغل';
        _message = 'شد حيلك!  شغل 💼💔';
        _icon = Icons.work;
        _bgColor = Colors.blueGrey[900]!;
        _textColor = Colors.white;
        _period = 'فترة الشغل: من ${formatter.format(periodStart)} إلى ${formatter.format(periodStart.add(Duration(days: _workDays - 1)))}';
      });
    } else {
      setState(() {
        _status = 'إجازة';
        _message = 'استمتع!  إجازة 🎉😎';
        _icon = Icons.celebration;
        _bgColor = Colors.green[300]!;
        _textColor = Colors.black;
        _period = 'فترة الإجازة: من ${formatter.format(periodStart.add(Duration(days: _workDays)))} إلى ${formatter.format(periodEnd)}';
      });
    }
  }

  Future<void> _selectDate() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('جارٍ تحميل الإعدادات...')),
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _checkDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('اليوم ده شغل ولا إجازة؟')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('اليوم ده شغل ولا إجازة؟')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Spacer(),

            Center(
              child: ElevatedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_today),
                label: const Text('اختر التاريخ'),
              ),
            ),

            const Spacer(),

            if (_selectedDate != null)
              Card(
                color: _bgColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        'التاريخ المحدد: ${DateFormat.yMMMMEEEEd('ar').format(_selectedDate!)}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.amberAccent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),
                      Icon(_icon, size: 48, color: Colors.amber),
                      const SizedBox(height: 10),
                      Text(
                        _status,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _message,
                        style: TextStyle(
                          fontSize: 20,
                          color: _textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        _period,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.amberAccent,
                        ),
                        textAlign: TextAlign.center,
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
}
