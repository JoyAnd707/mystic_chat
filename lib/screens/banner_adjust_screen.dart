import 'dart:io';

import 'package:flutter/material.dart';

class BannerAdjustResult {
  final double scale;
  final double offsetX;
  final double offsetY;

  const BannerAdjustResult({
    required this.scale,
    required this.offsetX,
    required this.offsetY,
  });
}

class BannerAdjustScreen extends StatefulWidget {
  final String imagePath;

  const BannerAdjustScreen({
    super.key,
    required this.imagePath,
  });

  @override
  State<BannerAdjustScreen> createState() => _BannerAdjustScreenState();
}

class _BannerAdjustScreenState extends State<BannerAdjustScreen> {
  final TransformationController _controller = TransformationController();

  void _save() {
    final matrix = _controller.value;

    Navigator.of(context).pop(
      BannerAdjustResult(
        scale: matrix.getMaxScaleOnAxis(),
        offsetX: matrix.storage[12],
        offsetY: matrix.storage[13],
      ),
    );
  }

  void _reset() {
    _controller.value = Matrix4.identity();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Adjust Banner'),
        backgroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: _reset,
            child: const Text('Reset'),
          ),
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRect(
            child: InteractiveViewer(
              transformationController: _controller,
              minScale: 1.0,
              maxScale: 4.0,
              boundaryMargin: const EdgeInsets.all(300),
              child: Image.file(
                File(widget.imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}