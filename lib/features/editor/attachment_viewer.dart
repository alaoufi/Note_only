import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/note_attachment.dart';

/// عارض الصور داخل التطبيق: ملء الشاشة مع تكبير/تصغير وتنقّل بين الصور،
/// وزرّ إرسال/مشاركة (واتساب، مدير الملفات، …). يفتح «داخل الملاحظة» بأمان.
class AttachmentViewer extends StatefulWidget {
  final List<NoteAttachment> images;
  final int initialIndex;

  const AttachmentViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<AttachmentViewer> createState() => _AttachmentViewerState();
}

class _AttachmentViewerState extends State<AttachmentViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.images.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    final a = widget.images[_index];
    if (a.path.isEmpty || !File(a.path).existsSync()) return;
    await SharePlus.instance.share(
      ShareParams(files: [XFile(a.path, mimeType: 'image/jpeg')]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.images.length;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(total > 1 ? '${_index + 1} / $total' : 'صورة'),
        actions: [
          IconButton(
            tooltip: 'إرسال',
            icon: const Icon(Icons.share),
            onPressed: _share,
          ),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: total,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) {
          final a = widget.images[i];
          final exists = a.path.isNotEmpty && File(a.path).existsSync();
          if (!exists) {
            return const Center(
              child: Icon(Icons.broken_image_outlined,
                  size: 64, color: Colors.white38),
            );
          }
          return InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: Center(
              child: Image.file(File(a.path), fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }
}
