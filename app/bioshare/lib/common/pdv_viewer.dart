import 'package:bioshare/models/theme_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

// common components
import 'package:bioshare/app/app_bar.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MyPdfViewer extends StatefulWidget {
  final String pdfPath;
  final String title;
  const MyPdfViewer({
    required this.pdfPath,
    required this.title,
    super.key,
  });

  @override
  State<MyPdfViewer> createState() => _MyPdfViewerState();
}

class _MyPdfViewerState extends State<MyPdfViewer> {
  PDFViewController? _controller;
  int? pages = 0;
  int? currentPage = 0;
  bool isReady = false;
  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: CustomAppBar(title: widget.title),
      ),
      body: Stack(
        children: [
          Selector<ThemeModel, Brightness>(
              selector: (context, themeProvider) => themeProvider.brightness,
              builder: (context, b, child) {
                return PDFView(
                  nightMode: b == Brightness.dark,
                  filePath: widget.pdfPath,
                  swipeHorizontal: true,
                  fitPolicy: FitPolicy.WIDTH,
                  preventLinkNavigation: true,
                  onViewCreated: (c) => setState(() => _controller = c),
                  onRender: (p) {
                    setState(() {
                      pages = p;
                      isReady = true;
                    });
                  },
                  onPageChanged: (int? page, int? total) {
                    setState(() => currentPage = page);
                  },
                  onLinkHandler: (String? uri) async {
                    if (uri == null) return;
                    final Uri url = Uri.parse(uri);
                    await launchUrl(url);
                  },
                );
              }),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left,
                      size: 32,
                      color: currentPage! + 1 != 1
                          ? Theme.of(context).colorScheme.onBackground
                          : Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                    ),
                    onPressed: currentPage! + 1 != 1
                        ? () {
                            final page = currentPage == 0 ? pages! : currentPage! - 1;
                            _controller!.setPage(page);
                          }
                        : null,
                  ),
                  Text("Strona ${currentPage! + 1} z $pages"),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      size: 32,
                      color: currentPage! + 1 != pages
                          ? Theme.of(context).colorScheme.onBackground
                          : Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                    ),
                    onPressed: currentPage! + 1 != pages
                        ? () {
                            final page = currentPage == pages! - 1 ? 0 : currentPage! + 1;
                            _controller!.setPage(page);
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
