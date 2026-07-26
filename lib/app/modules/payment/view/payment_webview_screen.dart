import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/modules/payment/controller/payment_url_controller.dart';

class PaymentView extends StatefulWidget {
  final Map<String, dynamic> paymentData;

  static const String routeName = '/payment-webview-screen';

  const PaymentView({super.key, required this.paymentData});

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  late WebViewController _controller;
  String _currentUrl = '';
  String _pageTitle = '';

  final PaymentURLController paymentURLController = PaymentURLController();

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(LightThemeColors.whiteColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('Page start loading: $url');
            setState(() {
              _currentUrl = url;
              _pageTitle = '';
            });
          },
          onPageFinished: (String url) async {
            debugPrint('Page finished loading: $url');
            final title = await _controller.getTitle();
            if (!mounted) return;
            setState(() {
              _currentUrl = url;
              _pageTitle = title ?? '';
            });
            if (url.contains("boosts/callback?sessionId")) {
              debugPrint(
                'Confirmed payment hoye geche............................',
              );
              final bool isSuccess = await paymentURLController.paymentUrl(url);
              if (isSuccess) {
                //Get.to(MainButtonNavbarScreen());
                // await confirmPayment('${widget.paymentData['reference']}');
                // Navigator.pushNamed(context, '/payment-success-screen'); // Adjust route name if needed
              }
              debugPrint('::::::::::::: if condition ::::::::::::::::');
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentData['link'] ?? ''));
  }

  String _displayHost() {
    final uri = Uri.tryParse(_currentUrl);
    if (uri == null || uri.host.isEmpty) {
      return widget.paymentData['link'] ?? '';
    }
    return uri.host;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: const Color(0xff2B2B2B),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.shield_outlined,
                              color: Colors.white70,
                              size: 14,
                            ),
                            widthBox4,
                            Text(
                              _displayHost(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        if (_pageTitle.isNotEmpty)
                          Text(
                            _pageTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: WebViewWidget(controller: _controller),
            ),
            Container(
              color: const Color(0xff2B2B2B),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () async {
                      if (await _controller.canGoBack()) {
                        await _controller.goBack();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                    onPressed: () async {
                      if (await _controller.canGoForward()) {
                        await _controller.goForward();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () async {
                      final url = _currentUrl.isNotEmpty
                          ? _currentUrl
                          : (widget.paymentData['link'] ?? '');
                      if (url.isNotEmpty) {
                        await Share.share(url);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: () => _controller.reload(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
