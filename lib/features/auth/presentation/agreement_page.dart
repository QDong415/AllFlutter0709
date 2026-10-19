import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 协议网页，对齐 Android `WebViewActivity`。
class AgreementPage extends StatefulWidget {
  const AgreementPage({super.key, required this.title, required this.url});

  final String title;
  final String url;

  /// 推进协议页。
  static Future<void> open(
    BuildContext context, {
    required String title,
    required String url,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AgreementPage(title: title, url: url),
      ),
    );
  }

  @override
  State<AgreementPage> createState() => _AgreementPageState();
}

class _AgreementPageState extends State<AgreementPage> {
  late final WebViewController _controller;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _loading = false);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
