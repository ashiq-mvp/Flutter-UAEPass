import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:webview_flutter/webview_flutter.dart';
// import 'package:zikzak_inappwebview/zikzak_inappwebview.dart';

import '../uaepass.dart';
import 'configuration.dart';
import 'helper.dart';

class UaepassLoginView extends StatefulWidget {
  const UaepassLoginView({super.key});

  @override
  State<UaepassLoginView> createState() => _UaepassLoginViewState();
}

class _UaepassLoginViewState extends State<UaepassLoginView> {
  double progress = 0;
  String successUrl = '';
  late WebViewController _controller;
  final MethodChannel channel = const MethodChannel('poc.uaepass/channel1');

  @override
  void initState() {
    super.initState();
    _initializeWebViewController();
    _setupMethodChannel();
  }

  void _initializeWebViewController() {
    _controller = WebViewController()
      ..clearCache()
      ..enableZoom(true)
      ..setBackgroundColor(Colors.transparent)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              this.progress = progress / 100;
            });
          },
          onPageStarted: _onPageStarted,
          onPageFinished: (String url) {
            setState(() {
              progress = 1.0;
            });
          },
          onHttpError: (HttpResponseError error) {
            _showError('HTTP Error: $error');
          },
          onWebResourceError: (WebResourceError error) {
            _showError('Resource Error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  void _setupMethodChannel() {
    channel.setMethodCallHandler((MethodCall call) async {
      final decodedUrl = Uri.decodeFull(successUrl);
      _controller.loadRequest(Uri.parse(decodedUrl));
    });
  }

  Future<void> _onPageStarted(String url) async {
    if (Configuration.app2App && url.contains('uaepass://')) {
      final openUrl = Helper.getUaePassOpenUrl(Uri.parse(url));
      successUrl = openUrl.successUrl;

      await launchUrlString(openUrl.appUrl);
      await _controller.goBack();
    } else if (url.contains('code=')) {
      final code = Uri.parse(url).queryParameters['code'];
      Navigator.pop(context, code);
    } else if (url.contains('cancelled')) {
      if (Uaepass.instance.showMessages) {
        _showError('User cancelled login with UAE Pass');
      }
      Navigator.pop(context);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: Helper.getLoginUrl(),
      builder: (context, AsyncSnapshot<String> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (progress < 1.0) LinearProgressIndicator(value: progress),
              ],
            ),
          ),
        );
      },
    );
  }
}
