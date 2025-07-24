import 'package:flutter/material.dart';
import '../utils/settings_manager.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  int _workDays = 6;
  int _offDays = 6;

  final _workDaysController = TextEditingController();
  final _offDaysController = TextEditingController();

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

      _workDaysController.text = _workDays.toString();
      _offDaysController.text = _offDays.toString();
    });
  }

  Future<void> _pickStartDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickEndDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _saveSettings() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب إدخال تاريخي البداية والانتهاء')),
      );
      return;
    }

    if (!SettingsManager.validateSettings(_workDays, _offDays)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عدد الأيام يجب أن يكون أكبر من 0 وأقل من أو يساوي 365')),
      );
      return;
    }

    final success = await SettingsManager.saveSettings(
      _startDate!,
      _workDays,
      _offDays,
      _endDate!,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الإعدادات بنجاح')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء الحفظ')),
      );
    }
  }

  @override
  void dispose() {
    _workDaysController.dispose();
    _offDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd('ar');
    return Scaffold(
      appBar: AppBar(title: const Text("الإعدادات")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("📌 الإعدادات الحالية:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("تاريخ البداية: ${_startDate != null ? dateFormat.format(_startDate!) : 'غير محدد'}"),
                    Text("تاريخ الانتهاء: ${_endDate != null ? dateFormat.format(_endDate!) : 'غير محدد'}"),
                    Text("عدد أيام الشغل: $_workDays"),
                    Text("عدد أيام الإجازة: $_offDays"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _pickStartDate,
              child: Text(
                _startDate == null
                    ? 'اختر تاريخ بداية الجنب'
                    : 'اختر تاريخ بداية الجنب   ${dateFormat.format(_startDate!)}',
              ),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _pickEndDate,
              child: Text(
                _endDate == null
                    ? 'اختر تاريخ انتهاء الخدمة'
                    : 'اختر تاريخ انتهاء الخدمة   ${dateFormat.format(_endDate!)}',
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              decoration: const InputDecoration(labelText: 'عدد أيام الشغل'),
              keyboardType: TextInputType.number,
              controller: _workDaysController,
              onChanged: (value) => _workDays = int.tryParse(value) ?? _workDays,
            ),
            const SizedBox(height: 10),

            TextField(
              decoration: const InputDecoration(labelText: 'عدد أيام الإجازة'),
              keyboardType: TextInputType.number,
              controller: _offDaysController,
              onChanged: (value) => _offDays = int.tryParse(value) ?? _offDays,
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}
