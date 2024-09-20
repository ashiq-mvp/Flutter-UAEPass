import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher_string.dart';

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
  InAppWebViewController? webViewController;
  PullToRefreshController? pullToRefreshController;
  final MethodChannel channel = const MethodChannel('poc.uaepass/channel1');

  @override
  void initState() {
    super.initState();
    channel.setMethodCallHandler((MethodCall call) async {
      final decoded = Uri.decodeFull(successUrl);
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
      }

      webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(decoded)));
    });
  }

  @override
  void dispose() {
    webViewController?.dispose();
    super.dispose();
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
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(snapshot.data!)),
              initialSettings: InAppWebViewSettings(
                supportZoom: false,
                transparentBackground: true,
                useShouldOverrideUrlLoading: true,
              ),
              onWebViewCreated: (controller) async {
                await InAppWebViewController.clearAllCache();
                webViewController = controller;
              },
              shouldOverrideUrlLoading: (controller, uri) async {
                final url = uri.request.url.toString();
                if (Configuration.app2App &&
                    (url.contains('uaepass://') ||
                        url.contains('uaepass.ae/'))) {
                  final openUrl = Helper.getUaePassOpenUrl(uri.request.url!);
                  successUrl = openUrl.successUrl;
                  // print('success: $successUrl');
                  // print('oepnUrl: ${openUrl.appUrl}');

                  await launchUrlString(openUrl.appUrl);
                  return NavigationActionPolicy.CANCEL;
                }

                if (url.contains('code=')) {
                  final code = Uri.parse(url).queryParameters['code'];
                  Navigator.pop(context, code);
                } else if (url.contains('cancelled')) {
                  if (Uaepass.instance.showMessages) {
                    log('User cancelled login with UAE Pass');
                    // ScaffoldMessenger.of(context)
                    //   ..removeCurrentSnackBar()
                    //   ..showSnackBar(
                    //     const SnackBar(
                    //       content: Text('User cancelled login with UAE Pass'),
                    //     ),
                    //   );
                  }
                  Navigator.pop(context);
                }
                return null;
              },
            ),
          ),
        );
      },
    );
  }
}
