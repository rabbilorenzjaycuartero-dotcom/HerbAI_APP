import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../core/app_theme.dart';

/// Full-screen in-app view of a herb's source page, so "View source" stays
/// inside HERBAI instead of switching to an external browser.
class SourceWebviewScreen extends StatefulWidget {
  final String url;

  const SourceWebviewScreen({super.key, required this.url});

  static void show(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SourceWebviewScreen(url: url),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<SourceWebviewScreen> createState() => _SourceWebviewScreenState();
}

class _SourceWebviewScreenState extends State<SourceWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          // Without this, some navigations fall through to Android's
          // default handling instead of staying in this WebView, which
          // hands them to the system browser via an external ACTION_VIEW
          // intent -- confirmed on-device (Chrome's IntentDispatcher fired
          // on a tap that should have stayed in-app). Explicitly allowing
          // navigation here keeps it embedded instead.
          onNavigationRequest: (request) => NavigationDecision.navigate,
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Source'),
        backgroundColor: AppTheme.background,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
