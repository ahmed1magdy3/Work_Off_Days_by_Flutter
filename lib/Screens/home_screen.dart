import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'settings_screen.dart';
import 'status_screen.dart';
import 'predict_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const _HomeAppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          children: [
            const _WelcomeSection(),
            const SizedBox(height: 48),

            // ---------------- عرض الله الوطن مكتب الحاسب مع أيقونات ----------------
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                const Text(
                  'اللّٰه',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.mosque, color: Colors.green),

                const Text(
                  'الوطن',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  '🇪🇬',
                  style: TextStyle(fontSize: 22),
                ),
                const Text(
                  'مكتب الحاسب',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.computer, color: Colors.blue),
              ],
            ),


            const SizedBox(height: 32),
            _MainButtons(onNavigate: _navigateTo),
            const SizedBox(height: 32),
            const Spacer(),
            const _SignatureFooter(),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────── AppBar
class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _HomeAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        'أيــــام الجنــــب',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      elevation: 2,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'الإعدادات',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SettingsScreen()),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// ───────────────────────────────────────── Welcome Section
class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection();

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'صباح الخير 🌞';
    } else if (hour >= 12 && hour < 18) {
      return 'مساء الخير ☀️';
    } else {
      return 'مساء الخير 🌙';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Text(
          _getGreeting(),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// ───────────────────────────────────────── Buttons Section
class _MainButtons extends StatelessWidget {
  final void Function(BuildContext, Widget) onNavigate;

  const _MainButtons({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionButton(
          text: "الإجــــــــازة امتـــــــــــي",
          icon: Icons.event_available,
          color: Colors.green,
          onPressed: () => onNavigate(context, const StatusScreen()),
        ),
        const SizedBox(height: 20),
        _ActionButton(
          text: "اليوم الفلاني هيبقي شغل ولا إجازة",
          icon: Icons.help_outline,
          color: Colors.blue,
          onPressed: () => onNavigate(context, const PredictScreen()),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.text,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: color.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────── Signature Footer
class _SignatureFooter extends StatelessWidget {
  const _SignatureFooter();

  Future<void> _launchFacebook() async {
    final Uri url = Uri.parse('https://www.facebook.com/share/1CJ7MjmZfB/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('تعذر فتح الرابط');
    }
  }

  Future<void> _launchWhatsapp() async {
    final Uri url = Uri.parse('https://wa.me/+201553151405');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('تعذر فتح الرابط');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'By: Ahmed Magdy',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _launchWhatsapp,
              child: const Icon(Icons.chat, size: 22, color: Colors.green),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: _launchFacebook,
              child: const Icon(
                Icons.facebook,
                size: 22,
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
