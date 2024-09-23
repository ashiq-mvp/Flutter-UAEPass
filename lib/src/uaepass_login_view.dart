import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  // InAppWebViewController? webViewController;
  // PullToRefreshController? pullToRefreshController;
  final MethodChannel channel = const MethodChannel('poc.uaepass/channel1');
  WebViewController? _controller;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: Helper.getLoginUrl(),
      builder: (context, AsyncSnapshot<String> snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }
        // _controller?.loadRequest(Uri.parse(snapshot.data!));
        return Scaffold(
            // appBar: AppBar(
            //   backgroundColor: const Color(0xFF55C9B2),
            //   foregroundColor: Colors.black,
            //   title: const Text('UAE Pass'),
            //   automaticallyImplyLeading: false,
            // ),
            body: SafeArea(
          child: WebViewWidget(
              controller: WebViewController()
                ..clearCache()
                ..enableZoom(false)
                ..setJavaScriptMode(JavaScriptMode.unrestricted)
                ..setNavigationDelegate(
                  NavigationDelegate(
                    onProgress: (int progress) {},
                    onPageStarted: (String endUrl) {
                      final cookieManager = WebViewCookieManager();

                      cookieManager.clearCookies();
                      final uri = Uri.dataFromString(endUrl);
                      if (endUrl.contains('error=')) {
                        switch (uri.queryParameters['error'].toString()) {
                          case "cancelled":
                            return Navigator.of(context).pop();
                          case "cancelledOnApp":
                            return Navigator.of(context).pop();
                        }
                        return Navigator.of(context).pop();
                      }
                      if (endUrl.contains('code=')) {
                        // state = uri.queryParameters['state']!;
                        final code = uri.queryParameters['code']!;

                        return Navigator.of(context).pop(code);
                      } else if (endUrl == "https://selfcare.uaepass.ae/" ||
                          endUrl.contains("https://ercweb.mvp-apps.ae/auth")) {
                        return Navigator.of(context).pop();
                      }
                    },
                    onPageFinished: (String url) {},
                    onHttpError: (HttpResponseError error) {},
                    onWebResourceError: (error) {},
                    onNavigationRequest: (NavigationRequest request) async {
                      final url = request.url.toString();
                      if (Configuration.app2App &&
                          (url.contains('uaepass://') ||
                              url.contains('uaepass.ae/'))) {
                        final openUrl =
                            await Helper.getUaePassOpenUrl(Uri.parse(url));
                        successUrl = openUrl.successUrl;
                        // print('success: $successUrl');
                        // print('oepnUrl: ${openUrl.appUrl}');

                        await launchUrlString(openUrl.appUrl);
                        return NavigationDecision.navigate;
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
                      return NavigationDecision.navigate;
                    },
                  ),
                )
                ..loadRequest(
                  Uri.parse(
                    usePassBaseUrl,
                  ),
                )

              /*InAppWebView(
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
            */
              ),
        ));
      },
    );
  }
}

String get usePassBaseUrl {
  // if (server == Build.testing) {
  //   return "https://stg-id.uaepass.ae/idshub/authorize?response_type=code&client_id=sandbox_stage&scope=urn:uae:digitalid:profile:general&state=https://emiratesrc.ae&redirect_uri=https://www.emiratesrc.ae/social_sup/Social_sup.asmx/uae_pass_redirect&acr_values=urn:safelayer:tws:policies:authentication:level:low";
  // }
  return "https://id.uaepass.ae/idshub/authorize?response_type=code&client_id=rcuae_web_prod&scope=urn:uae:digitalid:profile:general&state=https://emiratesrc.ae&redirect_uri=http://www.emiratesrc.ae/social_sup/Social_sup.asmx/uae_pass_redirect&acr_values=urn:safelayer:tws:policies:authentication:level:low";
}
