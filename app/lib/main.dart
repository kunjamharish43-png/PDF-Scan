import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:share_plus/share_plus.dart';

void main() => runApp(const NeoApp());

class NeoApp extends StatelessWidget {
  const NeoApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Neo AI Scanner Pro',
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const HomeScreen(),
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> _images = [];
  String? _pdfPath;
  bool _busy = false;

  void _msg(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  /// Features 1-6, 15, 16-20, 29-35 ka bada hissa ML Kit ke built-in scanner UI me aata hai:
  /// auto edge detection, auto capture, manual capture, crop, rotate, filters, page reorder/delete.
  Future<void> _scan({required int pageLimit}) async {
    if (!Platform.isAndroid) {
      _msg('Ye feature sirf Android par chalta hai');
      return;
    }
    setState(() => _busy = true);
    DocumentScanner? scanner;
    try {
      scanner = DocumentScanner(
        options: DocumentScannerOptions(
          documentFormats: {DocumentFormat.jpeg, DocumentFormat.pdf},
          mode: ScannerMode.full,
          pageLimit: pageLimit,
          isGalleryImport: true,
        ),
      );
      final result = await scanner.scanDocument();
      final imgs = result.images ?? [];
      if (imgs.isEmpty && result.pdf == null) {
        _msg('Koi page scan nahi hua');
      } else {
        setState(() {
          _images = imgs;
          _pdfPath = result.pdf?.uri;
        });
      }
    } catch (e) {
      // User ne cancel kiya ho ya permission na mili ho
      _msg('Scan nahi ho paya: $e');
    } finally {
      await scanner?.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sharePdf() async {
    final p = _pdfPath;
    if (p == null) return _msg('Pehle kuch scan karo');
    final path = p.startsWith('file://') ? Uri.parse(p).toFilePath() : p;
    if (!File(path).existsSync()) return _msg('PDF file nahi mili');
    await Share.shareXFiles([XFile(path)], text: 'Scanned document');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Neo AI Scanner Pro')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.icon(
              onPressed: _busy ? null : () => _scan(pageLimit: 1),
              icon: const Icon(Icons.document_scanner),
              label: const Text('Single page'),
            ),
            FilledButton.icon(
              onPressed: _busy ? null : () => _scan(pageLimit: 50),
              icon: const Icon(Icons.collections),
              label: const Text('Multi page'),
            ),
            OutlinedButton.icon(
              onPressed: _pdfPath == null ? null : _sharePdf,
              icon: const Icon(Icons.share),
              label: const Text('Share PDF'),
            ),
          ]),
        ),
        if (_busy) const LinearProgressIndicator(),
        Expanded(
          child: _images.isEmpty
              ? const Center(child: Text('Abhi koi scan nahi hai'))
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8),
                  itemCount: _images.length,
                  itemBuilder: (_, i) {
                    final path = _images[i].startsWith('file://')
                        ? Uri.parse(_images[i]).toFilePath()
                        : _images[i];
                    return Image.file(File(path), fit: BoxFit.cover);
                  },
                ),
        ),
      ]),
    );
  }
}
