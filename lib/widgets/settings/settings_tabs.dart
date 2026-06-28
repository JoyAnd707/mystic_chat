import 'package:flutter/material.dart';

enum SettingsTab {
  account,
  sound,
  others,
}

class SettingsTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const SettingsTabs({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _SettingsTabButton(
              tab: SettingsTab.account,
              selected: selectedIndex == 0,
              onTap: () => onChanged(0),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SettingsTabButton(
              tab: SettingsTab.sound,
              selected: selectedIndex == 1,
              onTap: () => onChanged(1),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SettingsTabButton(
              tab: SettingsTab.others,
              selected: selectedIndex == 2,
              onTap: () => onChanged(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTabButton extends StatelessWidget {
  final SettingsTab tab;
  final bool selected;
  final VoidCallback onTap;

  const _SettingsTabButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

String get _assetPath {
  switch (tab) {
    case SettingsTab.account:
      return selected
          ? 'assets/ui/settings/tabs/AccountOn.png'
          : 'assets/ui/settings/tabs/AccountOff.png';

    case SettingsTab.sound:
      return selected
          ? 'assets/ui/settings/tabs/SoundOn.png'
          : 'assets/ui/settings/tabs/SoundOff.png';

    case SettingsTab.others:
      return selected
          ? 'assets/ui/settings/tabs/OthersOn.png'
          : 'assets/ui/settings/tabs/OtherOff.png';
  }
}

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 54,
        child: Image.asset(
          _assetPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}