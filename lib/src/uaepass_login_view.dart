import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'helper.dart';

class UaepassLoginView extends StatefulWidget {
  const UaepassLoginView({super.key});

  @override
  State<UaepassLoginView> createState() => _UaepassLoginViewState();
}

class _UaepassLoginViewState extends State<UaepassLoginView> {
  double progress = 0;
  String successUrl = '';
  WebViewController? _controller;
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
      ..enableZoom(false)
      ..setBackgroundColor(Colors.transparent)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (_controller != null) {
              _controller?.clearCache();
            }
          },
          onProgress: (int progress) {
            setState(() {
              this.progress = progress / 100;
            });
          },
          // onPageStarted: _onPageStarted,
          onPageFinished: (String url) {
            debugPrint('U Service 1 $url');
            final uri = Uri.parse(url);
            final code = uri.queryParameters['code'];
            if (code != null) {
              debugPrint('Fetched code: $code');
              Navigator.pop(context, code);
            } else {
              debugPrint('Code parameter not found.');
            }
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
            debugPrint('U Service ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  void _setupMethodChannel() async {
    // channel.setMethodCallHandler((MethodCall call) async {
    final decodedUrl = Uri.parse(await Helper.getLoginUrl());
    if (kDebugMode) {
      print('U Service: $decodedUrl');
    }
    // _controller!.loadRequest(Uri.parse('https://flutter.dev/'));
    _controller?.loadRequest(decodedUrl);
    // });
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
                if (_controller != null)
                  WebViewWidget(
                    controller: _controller!,
                  ),
                if (progress < 1.0) LinearProgressIndicator(value: progress),
              ],
            ),
          ),
        );
      },
    );
  }
}
