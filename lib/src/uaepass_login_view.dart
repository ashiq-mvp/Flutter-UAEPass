import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../uaepass.dart';
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
  final WebViewCookieManager cookieManager = WebViewCookieManager();
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
          onPageStarted: (String url) async {
            if (_controller != null) {
              _controller?.clearCache();
            }
            final bool hadCookies = await cookieManager.clearCookies();
            String message = 'There were cookies. Now, they are gone!';
            if (!hadCookies) {
              message = 'There are no cookies.';
            }
            debugPrint(message);
          },
          onProgress: (int progress) {
            setState(() {
              this.progress = progress / 100;
            });
          },
          // onPageStarted: _onPageStarted,
          onPageFinished: (String url) {
            debugPrint('onPageFinished $url');
            final uri = Uri.parse(url);
            final code = uri.queryParameters['code'];

            if (code != null) {
              debugPrint('Fetched code: $code');
              Navigator.pop(context, code);
            } else if (url.contains('canceled')) {
              debugPrint('User Canceled');
              Navigator.pop(context);
            }
            setState(() {
              progress = 1.0;
            });
          },
          onHttpError: (HttpResponseError error) {
            debugPrint('HTTP Error: $error');
            _showError('HTTP Error: $error');
          },
          onWebResourceError: (error) {
            debugPrint(
              'On Web Resource Error code: ${error.errorCode},  Error description: ${error.description}, Error errorType: ${error.errorType}, Error isfromMainFrame: ${error.isForMainFrame}, URL: ${error.url}',
            );
            _showError('Resource Error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) async {
            final uri = Uri.parse(request.url);
            final code = uri.queryParameters['code'];
            debugPrint('onNavigationRequest ${request.url}');
            if (code != null) {
              debugPrint('onNavigationRequest CODE $code');
              Navigator.pop(context, code);
            }

            // else if (request.url.contains('cancelled')) {
            //   return NavigationDecision.prevent;
            // }
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  Future<void> _setupMethodChannel() async {
    final getUrl = Uri.parse(await Helper.getLoginUrl());

    await cookieManager.setCookie(
      WebViewCookie(
        name: Uaepass.instance.appScheme,
        value: 'bar',
        domain: getUrl.host,
        path: getUrl.path,
      ),
    );
    // channel.setMethodCallHandler((MethodCall call) async {

    if (kDebugMode) {
      print('U Service: $getUrl');
    }
    // _controller!.loadRequest(Uri.parse('https://flutter.dev/'));
    _controller?.loadRequest(getUrl);
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
          appBar: AppBar(
            toolbarHeight: 40,
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: IconButton(
                onPressed: () {
                  if (_controller != null) {
                    _controller?.goBack();
                    if (Navigator.canPop(context)) Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.cancel, color: Colors.red),
              ),
            ),
          ),
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
