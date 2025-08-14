import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/settings_manager.dart';
import '../Screens/notifications.dart' as notifications;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime? _startDate;
  int _workDays = 0;
  int _offDays = 0;
  DateTime? _endDate;

  final TextEditingController _workDaysController = TextEditingController();
  final TextEditingController _offDaysController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsManager.loadSettings();
    setState(() {
      _startDate = settings['startDate'];
      _workDays = settings['workDays'];
      _offDays = settings['offDays'];
      _endDate = settings['endDate'];

      _workDaysController.text = _workDays.toString();
      _offDaysController.text = _offDays.toString();
    });
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate() && _startDate != null) {
      final saved = await SettingsManager.saveSettings(
        _startDate!,
        _workDays,
        _offDays,
        _endDate,
      );

      if (saved) {

        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                title: Text('تنبيه'),
                content: Text('لضمان تشغيل الاشعارات بشكل صحيح يجب ضبط التطبيق للعمل بالخلفية من اعدادات البطارية \nواذا واجهت مشكلة اعد تثبيته'),
                actions: <Widget>[
                  TextButton(
                    child: Text('إغلاق'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الإعدادات وتشغيل الإشعارات'),
            backgroundColor: Colors.green,
          ),
        );



        // long loop
        await notifications.scheduleSwitchNotifications(
          startDate: _startDate!,
          workDays: _workDays,
          offDays: _offDays,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('حدث خطأ أثناء حفظ الإعدادات'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime? date,
    required VoidCallback onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        ElevatedButton(
          onPressed: onSelect,
          child: Text(date == null
              ? "اختر التاريخ"
              : DateFormat('yyyy-MM-dd').format(date)),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildDateSelector(
                label: 'تاريخ بداية جنب الشغل',
                date: _startDate,
                onSelect: () => _pickDate(context, true),
              ),
              TextFormField(
                controller: _workDaysController,
                decoration: const InputDecoration(
                  labelText: 'أيام الشغل',
                  border: OutlineInputBorder(),
                  icon: Icon(Icons.work, color: Colors.brown),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                value!.isEmpty ? 'أدخل عدد أيام الشغل' : null,
                onChanged: (value) =>
                _workDays = int.tryParse(value) ?? _workDays,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _offDaysController,
                decoration: const InputDecoration(
                  labelText: 'أيام الإجازة',
                  border: OutlineInputBorder(),
                  icon: Icon(Icons.beach_access_rounded, color: Colors.green),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                value!.isEmpty ? 'أدخل عدد أيام الإجازة' : null,
                onChanged: (value) =>
                _offDays = int.tryParse(value) ?? _offDays,
              ),
              const SizedBox(height: 20),
              _buildDateSelector(
                label: 'تاريخ نهاية الخدمة',
                date: _endDate,
                onSelect: () => _pickDate(context, false),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                onPressed: _saveSettings,
                label: const Text('حفظ وتشغيل الإشعارات'),
                style: ElevatedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
