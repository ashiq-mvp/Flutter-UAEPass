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
  late final WebViewController _controller;
  final MethodChannel channel = const MethodChannel('poc.uaepass/channel1');

  @override
  void initState() {
    super.initState();
    channel.setMethodCallHandler((MethodCall call) async {
      final decoded = Uri.decodeFull(successUrl);
      _controller = WebViewController()
        ..clearCache()
        ..enableZoom(true)
        ..setBackgroundColor(Colors.transparent)
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {},
            onPageStarted: (String url) async {
              if (Configuration.app2App && url.contains('uaepass://')) {
                final openUrl = Helper.getUaePassOpenUrl(Uri.parse(url));
                successUrl = openUrl.successUrl;

                await launchUrlString(openUrl.appUrl);
                // return NavigationActionPolicy.CANCEL;
                await _controller.goBack();
              } else if (url.contains('code=')) {
                final code = Uri.parse(url).queryParameters['code'];
                Navigator.pop(context, code);
              } else if (url.contains('cancelled')) {
                if (Uaepass.instance.showMessages) {
                  ScaffoldMessenger.of(context)
                    ..removeCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('User cancelled login with UAE Pass'),
                      ),
                    );
                }
                Navigator.pop(context);
              }
            },
            onPageFinished: (String url) {},
            onHttpError: (HttpResponseError error) {},
            onWebResourceError: (WebResourceError error) {},
            onNavigationRequest: (NavigationRequest request) {
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(decoded));
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: Helper.getLoginUrl(),
      builder: (context, AsyncSnapshot<String> snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }
        return Scaffold(
          // appBar: AppBar(
          //   backgroundColor: const Color(0xFF55C9B2),
          //   foregroundColor: Colors.black,
          //   title: const Text('UAE Pass'),
          //   automaticallyImplyLeading: false,
          // ),
          body: SafeArea(
            child: WebViewWidget(controller: _controller),
          ),
        );
      },
    );
  }
}
