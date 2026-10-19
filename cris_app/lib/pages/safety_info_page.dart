import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import '../theme.dart';

class SafetyInfoPage extends StatefulWidget {
  const SafetyInfoPage({super.key});

  @override
  State<SafetyInfoPage> createState() => _SafetyInfoPageState();
}

class _SafetyInfoPageState extends State<SafetyInfoPage> {
  late final PdfControllerPinch _pdfController;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfControllerPinch(
      document: PdfDocument.openAsset(
        'assets/documents/Rabies-Hiligaynon-and-Karay-a-1.pdf',
      ),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Safety Information',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_isReady)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PdfViewPinch(
              controller: _pdfController,
              onDocumentLoaded: (doc) {
                setState(() {
                  _totalPages = doc.pagesCount;
                  _isReady = true;
                });
              },
              onPageChanged: (page) {
                setState(() => _currentPage = page);
              },
              builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                options: const DefaultBuilderOptions(),
                errorBuilder: (_, error) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Could not load the infographic.',
                          style: TextStyle(fontSize: 15, color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          error.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                documentLoaderBuilder: (_) => const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 12),
                      Text(
                        'Loading infographic…',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                pageLoaderBuilder: (_) => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),
          ),

          // ── Page navigation bar ───────────────────────────────
          if (_isReady)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    color: AppColors.primary,
                    onPressed: _currentPage > 1
                        ? () => _pdfController.previousPage(
                            curve: Curves.easeInOut,
                            duration: const Duration(milliseconds: 300),
                          )
                        : null,
                  ),
                  Text(
                    'Page $_currentPage of $_totalPages',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    color: AppColors.primary,
                    onPressed: _currentPage < _totalPages
                        ? () => _pdfController.nextPage(
                            curve: Curves.easeInOut,
                            duration: const Duration(milliseconds: 300),
                          )
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
