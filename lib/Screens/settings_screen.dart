import 'package:flutter/material.dart';
import '../utils/settings_manager.dart';
import 'package:intl/intl.dart';
import 'notifications.dart';

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
      helpText: 'اختر تاريخ بداية الجنب',
      confirmText: 'موافق',
      cancelText: 'إلغاء',
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
      helpText: 'اختر تاريخ انتهاء الخدمة',
      confirmText: 'موافق',
      cancelText: 'إلغاء',
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _saveSettings() async {
    // التأكد من قراءة القيم من التكست فيلد قبل الحفظ
    final workDaysText = _workDaysController.text.trim();
    final offDaysText = _offDaysController.text.trim();

    if (workDaysText.isEmpty || offDaysText.isEmpty) {
      _showSnackBar('يجب إدخال عدد أيام الشغل والإجازة', Colors.red);
      return;
    }

    final workDaysParsed = int.tryParse(workDaysText);
    final offDaysParsed = int.tryParse(offDaysText);

    if (workDaysParsed == null || offDaysParsed == null) {
      _showSnackBar('يجب إدخال أرقام صحيحة فقط', Colors.red);
      return;
    }

    // تحديث المتغيرات بالقيم الجديدة
    _workDays = workDaysParsed;
    _offDays = offDaysParsed;

    if (_startDate == null) {
      _showSnackBar('يجب إدخال تاريخ البداية على الأقل', Colors.red);
      return;
    }

    if (!SettingsManager.validateSettings(_workDays, _offDays)) {
      _showSnackBar(
        'عدد الأيام يجب أن يكون أكبر من 0 وأقل من أو يساوي 365',
        Colors.red,
      );
      return;
    }

    if (_endDate != null && _startDate!.isAfter(_endDate!)) {
      _showSnackBar('تاريخ البداية يجب أن يكون قبل تاريخ الانتهاء', Colors.red);
      return;
    }

    try {
      // Use the updated saveSettings method
      final success = await SettingsManager.saveSettings(
        _startDate!,
        _workDays,
        _offDays,
        _endDate, // Can be null now
      );

      if (success) {
        // إلغاء جميع الإشعارات السابقة
        await NotificationService.cancelAllNotifications();

        print('Scheduling notifications with:');
        print('Start date: $_startDate');
        print('Work days: $_workDays');
        print('Off days: $_offDays');
        print('End date: $_endDate');

        // جدولة إشعارات جديدة
        await NotificationService.scheduleEndOfOffNotification(
          id: 100,
          startDate: _startDate!,
          workDays: _workDays,
          offDays: _offDays,
          title: "استعد!",
          body: "بكرة شغل! جهز دماغك من دلوقتي 💼",
        );

        _showSnackBar('تم حفظ الإعدادات وجدولة الإشعارات بنجاح ✅', Colors.green);

        // Debug print settings
        await SettingsManager.debugPrintSettings();

        // تحديث واجهة المستخدم
        setState(() {});

        await Future.delayed(Duration(seconds: 1));
        Navigator.pop(context, true);
      } else {
        _showSnackBar('حدث خطأ أثناء الحفظ', Colors.red);
      }
    } catch (e) {
      print('Error saving settings: $e');
      _showSnackBar('حدث خطأ غير متوقع أثناء الحفظ', Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _resetSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد إعادة التعيين'),
        content: Text('هل أنت متأكد من إعادة تعيين جميع الإعدادات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('تأكيد', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _startDate = null;
        _endDate = null;
        _workDays = 6;
        _offDays = 6;
        _workDaysController.text = '6';
        _offDaysController.text = '6';
      });

      await NotificationService.cancelAllNotifications();
      _showSnackBar('تم إعادة تعيين الإعدادات', Colors.orange);
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
      appBar: AppBar(
        title: const Text("الإعدادات"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetSettings,
            tooltip: 'إعادة تعيين',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.settings, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          "الإعدادات الحالية:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    Divider(),
                    SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.play_arrow,
                      "تاريخ البداية:",
                      _startDate != null ? dateFormat.format(_startDate!) : 'غير محدد',
                    ),
                    _buildInfoRow(
                      Icons.stop,
                      "تاريخ الانتهاء:",
                      _endDate != null ? dateFormat.format(_endDate!) : 'غير محدد',
                    ),
                    _buildInfoRow(
                      Icons.work,
                      "عدد أيام الشغل:",
                      '${_workDaysController.text.isNotEmpty ? _workDaysController.text : _workDays} أيام',
                    ),
                    _buildInfoRow(
                      Icons.beach_access,
                      "عدد أيام الإجازة:",
                      '${_offDaysController.text.isNotEmpty ? _offDaysController.text : _offDays} أيام',
                    ),
                    if (_startDate != null && _endDate != null)
                      _buildInfoRow(
                        Icons.calendar_today,
                        "إجمالي أيام الخدمة:",
                        '${_endDate!.difference(_startDate!).inDays} يوم',
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            _buildDateButton(
              icon: Icons.calendar_today,
              label: _startDate == null
                  ? 'اختر تاريخ بداية الجنب'
                  : 'تاريخ بداية الجنب: ${dateFormat.format(_startDate!)}',
              onPressed: _pickStartDate,
              color: Colors.green,
            ),

            SizedBox(height: 12),

            _buildDateButton(
              icon: Icons.event,
              label: _endDate == null
                  ? 'اختر تاريخ انتهاء الخدمة (اختياري)'
                  : 'تاريخ انتهاء الخدمة: ${dateFormat.format(_endDate!)}',
              onPressed: _pickEndDate,
              color: Colors.orange,
            ),

            if (_endDate != null) ...[
              SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _endDate = null;
                  });
                  _showSnackBar('تم حذف تاريخ الانتهاء', Colors.orange);
                },
                icon: Icon(Icons.clear, color: Colors.red),
                label: Text('حذف تاريخ الانتهاء', style: TextStyle(color: Colors.red)),
              ),
            ],

            SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'أيام الشغل',
                      prefixIcon: Icon(Icons.work, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      helperText: 'أدخل رقم من 1 إلى 365',
                    ),
                    keyboardType: TextInputType.number,
                    controller: _workDaysController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'مطلوب';
                      }
                      final parsed = int.tryParse(value);
                      if (parsed == null || parsed <= 0 || parsed > 365) {
                        return 'رقم غير صحيح';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'أيام الإجازة',
                      prefixIcon: Icon(Icons.beach_access, color: Colors.green),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      helperText: 'أدخل رقم من 1 إلى 365',
                    ),
                    keyboardType: TextInputType.number,
                    controller: _offDaysController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'مطلوب';
                      }
                      final parsed = int.tryParse(value);
                      if (parsed == null || parsed <= 0 || parsed > 365) {
                        return 'رقم غير صحيح';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: Icon(Icons.save),
              label: Text('حفظ الإعدادات'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[800]),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(
        label,
        style: TextStyle(fontSize: 16),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}