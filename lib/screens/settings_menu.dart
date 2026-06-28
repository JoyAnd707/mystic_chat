import 'package:flutter/material.dart';

import '../widgets/settings/settings_tabs.dart';

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
            const SizedBox(height: 70),

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