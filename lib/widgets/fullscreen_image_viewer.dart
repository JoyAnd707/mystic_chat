import 'package:flutter/material.dart';

import '../audio/sfx.dart';

void openFullscreenImageViewer(BuildContext context, String url) {
  Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 12,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  Sfx.I.playCloseImage();
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  '[ + ]',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
    ),
  );
}