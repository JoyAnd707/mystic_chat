import 'package:flutter/material.dart';

class MysticTitleBar extends StatelessWidget {
  final String title;
  final Future<void> Function()? onBack;

  const MysticTitleBar({
    super.key,
    required this.title,
    this.onBack,
  });

  static const double _resourceBarHeight = 34;
  static const double _barAspect = 2048 / 212;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _resourceBarHeight,
            width: double.infinity,
            child: Container(color: Colors.transparent),
          ),
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final barH = w / _barAspect;

              return SizedBox(
                width: w,
                height: barH,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/ui/TextMessageBarMenu.png',
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.center,
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w300,
                          height: 1.0,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          if (onBack != null) {
                            await onBack!.call();
                            return;
                          }

                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: const SizedBox(
                          width: 72,
                          height: double.infinity,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}