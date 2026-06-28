import 'package:flutter/material.dart';
import '../widgets/mystic_title_bar.dart';
import '../widgets/settings/settings_tabs.dart';
import '../widgets/mystic_top_status_bar.dart';
import '../widgets/mystic_settings_top_status_bar.dart';
class SettingsMenuScreen extends StatefulWidget {
  final String currentUserId;

  const SettingsMenuScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  State<SettingsMenuScreen> createState() => _SettingsMenuScreenState();
}

class _SettingsMenuScreenState extends State<SettingsMenuScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
children: [
  MysticSettingsTopStatusBar(
  now: DateTime.now(),
),
Padding(
  padding: const EdgeInsets.only(top: 8),
  child: Padding(
  padding: const EdgeInsets.only(top: 30),
  child: MysticTitleBar(
    title: 'Setting',
    onBack: () async {
      if (mounted) {
        Navigator.of(context).pop();
      }
    },
  ),
),
),

  const SizedBox(height: 16),

  SettingsTabs(
    selectedIndex: _selectedTab,
    onChanged: (index) {
      setState(() {
        _selectedTab = index;
      });
    },
  ),

            const SizedBox(height: 24),

            Expanded(
              child: Center(
                child: Text(
                  switch (_selectedTab) {
                    0 => 'Account',
                    1 => 'Sound',
                    _ => 'Others',
                  },
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}