import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:eshop/Helper/Color.dart';
import 'package:eshop/Helper/String.dart';
import 'package:eshop/Provider/CartProvider.dart';
import 'package:eshop/Provider/SettingProvider.dart';
import 'package:eshop/Provider/UserProvider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/cart_var.dart';
import '../Model/Section_Model.dart';
import '../app/routes.dart';
import '../ui/styles/DesignConfig.dart';
import 'HomePage.dart';

class PaypalWebview extends StatefulWidget {
  final String? url;
  final String? from;
  final String? msg;
  final String? amt;
  final String? orderId;
  const PaypalWebview(
      {super.key, this.url, this.from, this.msg, this.amt, this.orderId,});
  @override
  State<StatefulWidget> createState() {
    return StatePayPalWebview();
  }
}

class StatePayPalWebview extends State<PaypalWebview> {
  String message = "";
  bool isloading = true;
  late final WebViewController _controller;
  DateTime? currentBackPressTime;
  late UserProvider userProvider;
  @override
  void initState() {
    webViewInitiliased();
    super.initState();
  }

  webViewInitiliased() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }
    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);
    controller
      ..loadRequest(Uri.parse(widget.url!))
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('Toaster', onMessageReceived: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message.message)),
        );
      },)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (String url) {
          print('******URL*****$url');
          setState(() {
            isloading = false;
          });
        },
        onNavigationRequest: (request) async {
          print('******request url ******${request.url}');
          if (request.url.startsWith(PAYPAL_RESPONSE_URL) ||
              request.url.startsWith(FLUTTERWAVE_RES_URL)) {
            if (mounted) {
              setState(() {
                isloading = true;
              });
            }
            final String responseurl = request.url;
            if (responseurl.contains("Failed") ||
                responseurl.contains("failed")) {
              if (mounted) {
                setState(() {
                  isloading = false;
                  message = "Transaction Failed";
                });
              }
              Timer(const Duration(seconds: 1), () {
                Navigator.pop(context);
              });
            } else if (responseurl.contains("Completed") ||
                responseurl.contains("completed") ||
                responseurl.toLowerCase().contains("success")) {
              if (mounted) {
                setState(() {
                  if (mounted) {
                    setState(() {
                      message = "Transaction Successfull";
                    });
                  }
                });
              }
              final List<String> testdata = responseurl.split("&");
              for (final String data in testdata) {
                if (data.split("=")[0].toLowerCase() == "tx" ||
                    data.split("=")[0].toLowerCase() == "transaction_id") {
                  userProvider.setCartCount("0");
                  if (widget.from == "order") {
                    if (request.url.startsWith(PAYPAL_RESPONSE_URL)) {
                      Navigator.pushNamedAndRemoveUntil(context,
                          Routers.orderSuccessScreen, (route) => route.isFirst,);
                    } else {
                      final String txid = data.split("=")[1];
                      AddTransaction(txid, widget.orderId!, SUCCESS,
                          'Order placed successfully', true,);
                    }
                  } else if (widget.from == "wallet") {
                    if (request.url.startsWith(FLUTTERWAVE_RES_URL)) {
                      setSnackbar('Transaction Successful', context);
                      if (mounted) {
                        setState(() {
                          isloading = false;
                        });
                      }
                      Timer(const Duration(seconds: 1), () {
                        Navigator.pop(context);
                      });
                    } else {
                      Navigator.of(context).pop();
                    }
                  }
                  break;
                }
              }
            }
            if (request.url.startsWith(PAYPAL_RESPONSE_URL) &&
                widget.orderId != null &&
                (responseurl.contains('Canceled-Reversal') ||
                    responseurl.contains('Denied') ||
                    responseurl.contains('Failed'))) {
              deleteOrder();
            }
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),);
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    userProvider = Provider.of<UserProvider>(context);
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          titleSpacing: 0,
          leading: Builder(builder: (BuildContext context) {
            return Container(
              margin: const EdgeInsets.all(10),
              child: Card(
                elevation: 0,
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () {
                    final DateTime now = DateTime.now();
                    if (currentBackPressTime == null ||
                        now.difference(currentBackPressTime!) >
                            const Duration(seconds: 2)) {
                      currentBackPressTime = now;
                      setSnackbar(
                          "Don't press back while doing payment!\n ${getTranslated(context, 'EXIT_WR')!}",
                          context,);
                    }
                    if (widget.from == "order" && widget.orderId != null) {
                      deleteOrder();
                    }
                    Navigator.pop(context);
                  },
                  child: Center(
                    child: Icon(
                      Icons.keyboard_arrow_left,
                      color: Theme.of(context).colorScheme.primarytheme,
                    ),
                  ),
                ),
              ),
            );
          },),
          title: Text(
            appName,
            style: TextStyle(
              color: Theme.of(context).colorScheme.fontColor,
            ),
          ),
        ),
        body: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) {
                final DateTime now = DateTime.now();
                if (currentBackPressTime == null ||
                    now.difference(currentBackPressTime!) >
                        const Duration(seconds: 2)) {
                  currentBackPressTime = now;
                  setSnackbar(
                      "Don't press back while doing payment!\n ${getTranslated(context, 'EXIT_WR')!}",
                      context,);
                } else {
                  if (widget.from == "order" && widget.orderId != null) {
                    deleteOrder();
                  }
                  if (didPop) {
                    return;
                  }
                  Navigator.pop(context, 'true');
                }
              }
            },
            child: Stack(
              children: <Widget>[
                WebViewWidget(controller: _controller),
                if (isloading) Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primarytheme,
                        ),
                      ) else const SizedBox(),
                if (message.trim().isEmpty) const SizedBox.shrink() else Center(
                        child: Container(
                            color: Theme.of(context).colorScheme.primarytheme,
                            padding: const EdgeInsets.all(5),
                            margin: const EdgeInsets.all(5),
                            child: Text(
                              message,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.white,),
                            ),),),
              ],
            ),),);
  }

  Future<void> sendRequest(String txnId, String payMethod) async {
    final String orderId =
        "wallet-refill-user-${context.read<UserProvider>().userId}-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(900) + 100}";
    try {
      final parameter = {
        USER_ID: context.read<UserProvider>().userId,
        AMOUNT: widget.amt,
        TRANS_TYPE: WALLET,
        TYPE: CREDIT,
        MSG: (widget.msg == '' || widget.msg!.isEmpty)
            ? "Added through wallet"
            : widget.msg,
        TXNID: txnId,
        ORDER_ID: orderId,
        STATUS: "Success",
        PAYMENT_METHOD: payMethod.toLowerCase(),
      };
      apiBaseHelper.postAPICall(addTransactionApi, parameter).then((getdata) {
        final bool error = getdata["error"];
        if (!error) {
          final UserProvider userProvider = Provider.of<UserProvider>(context);
          userProvider.setBalance(
              double.parse(getdata["new_balance"]).toStringAsFixed(2),);
        }
        if (mounted) {
          setState(() {
            isloading = false;
          });
        }
        Navigator.of(context).pop();
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      },);
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      setState(() {
        isloading = false;
      });
    }
  }

  Future<void> deleteOrder() async {
    try {
      final parameter = {
        ORDER_ID: widget.orderId,
      };
      apiBaseHelper.postAPICall(deleteOrderApi, parameter).then((getdata) {
        if (mounted) {
          setState(() {
            isloading = false;
          });
        }
        Navigator.of(context).pop();
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      },);
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      setState(() {
        isloading = false;
      });
    }
  }

  Future<void> placeOrder(String tranId) async {
    setState(() {
      isloading = true;
    });
    final SettingProvider settingsProvider =
        Provider.of<SettingProvider>(context, listen: false);
    final String? mob = await settingsProvider.getPrefrence(MOBILE);
    String? varientId;
    String? quantity;
    final List<SectionModel> cartList = context.read<CartProvider>().cartList;
    for (final SectionModel sec in cartList) {
      varientId =
          varientId != null ? "$varientId,${sec.varientId!}" : sec.varientId;
      quantity = quantity != null ? "$quantity,${sec.qty!}" : sec.qty;
    }
    String payVia;
    payVia = "Flutterwave";
    final request = http.MultipartRequest("POST", placeOrderApi);
    request.headers.addAll(headers);
    try {
      request.fields[USER_ID] = context.read<UserProvider>().userId;
      request.fields[MOBILE] = mob!;
      request.fields[PRODUCT_VARIENT_ID] = varientId!;
      request.fields[QUANTITY] = quantity!;
      request.fields[TOTAL] = originalPrice.toString();
      request.fields[DEL_CHARGE] = deliveryCharge.toString();
      request.fields[TAX_PER] = taxPersontage.toString();
      request.fields[FINAL_TOTAL] = usedBalance > 0
          ? totalPrice.toString()
          : isStorePickUp == "false"
              ? (totalPrice + deliveryCharge).toString()
              : totalPrice.toString();
      request.fields[PAYMENT_METHOD] = payVia;
      request.fields[ISWALLETBALUSED] = isUseWallet! ? "1" : "0";
      request.fields[WALLET_BAL_USED] = usedBalance.toString();
      if (IS_LOCAL_PICKUP == "1") {
        request.fields[LOCAL_PICKUP] = isStorePickUp == "true" ? "1" : "0";
      }
      if (IS_LOCAL_PICKUP != "1" || isStorePickUp != "true") {
        request.fields[ADD_ID] = selAddress!;
      }
      if (isTimeSlot!) {
        request.fields[DELIVERY_TIME] = selTime ?? 'Anytime';
        request.fields[DELIVERY_DATE] = selDate ?? '';
      }
      if (isPromoValid!) {
        request.fields[PROMOCODE] = promocode!;
        request.fields[PROMO_DIS] = promoAmount.toString();
      }
      if (prescriptionImages.isNotEmpty) {
        for (var i = 0; i < prescriptionImages.length; i++) {
          final mimeType = lookupMimeType(prescriptionImages[i].path);
          final extension = mimeType!.split("/");
          final pic = await http.MultipartFile.fromPath(
            DOCUMENT,
            prescriptionImages[i].path,
            contentType: MediaType('image', extension[1]),
          );
          request.files.add(pic);
        }
      }
      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      if (response.statusCode == 200) {
        final getdata = json.decode(responseString);
        final bool error = getdata["error"];
        final String? msg = getdata["message"];
        if (!error) {
          final String orderId = getdata["order_id"].toString();
          AddTransaction(tranId, orderId, SUCCESS, msg, true);
        } else {
          setSnackbar(msg!, context);
        }
        if (mounted) {
          setState(() {
            isloading = false;
          });
        }
      }
    } on TimeoutException catch (_) {
      if (mounted) {
        setState(() {
          isloading = false;
        });
      }
    }
  }

  Future<void> AddTransaction(String tranId, String orderID, String status,
      String? msg, bool redirect,) async {
    try {
      final parameter = {
        USER_ID: context.read<UserProvider>().userId,
        ORDER_ID: orderID,
        TYPE: paymentMethod,
        TXNID: tranId,
        AMOUNT: usedBalance > 0
            ? totalPrice.toString()
            : isStorePickUp == "false"
                ? (totalPrice + deliveryCharge).toString()
                : totalPrice.toString(),
        STATUS: status,
        MSG: msg,
      };
      apiBaseHelper.postAPICall(addTransactionApi, parameter).then((getdata) {
        final DateTime now = DateTime.now();
        currentBackPressTime = now;
        final bool error = getdata["error"];
        final String? msg1 = getdata["message"];
        if (!error) {
          if (redirect) {
            userProvider.setCartCount("0");
            promoAmount = 0;
            remWalBal = 0;
            usedBalance = 0;
            paymentMethod = '';
            isPromoValid = false;
            isUseWallet = false;
            isPayLayShow = true;
            selectedMethod = null;
            totalPrice = 0;
            originalPrice = 0;
            taxPersontage = 0;
            deliveryCharge = 0;
            Navigator.pushNamedAndRemoveUntil(
                context, Routers.orderSuccessScreen, (route) => route.isFirst,);
          }
        } else {
          setSnackbar(msg1!, context);
        }
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      },);
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg')!, context);
    }
  }
}
