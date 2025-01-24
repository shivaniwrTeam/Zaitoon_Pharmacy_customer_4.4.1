import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:eshop/Provider/CartProvider.dart';
import 'package:eshop/Provider/UserProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_paystack/flutter_paystack.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../Helper/Color.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import '../Helper/cart_var.dart';
import '../Model/Model.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/widgets/AppBtn.dart';
import '../ui/widgets/PaymentRadio.dart';
import '../ui/widgets/SimBtn.dart';
import '../ui/widgets/SimpleAppBar.dart';
import '../ui/widgets/Stripe_Service.dart';
import '../utils/blured_router.dart';
import 'HomePage.dart';

class Payment extends StatefulWidget {
  final Function update;
  final String? msg;
  static route(RouteSettings settings) {
    final Map? arguments = settings.arguments as Map?;
    return BlurredRouter(
      builder: (context) {
        return Payment(
          arguments?['update'],
          arguments?['msg'],
        );
      },
    );
  }

  const Payment(this.update, this.msg, {super.key});
  @override
  State<StatefulWidget> createState() {
    return StatePayment();
  }
}

List<Model> timeSlotList = [];
String? allowDay;
bool codAllowed = true;
String? bankName;
String? bankNo;
String? acName;
String? acNo;
String? exDetails;

class StatePayment extends State<Payment> with TickerProviderStateMixin {
  bool _isLoading = true;
  String? startingDate;
  late bool cod;
  late bool paypal;
  late bool razorpay;
  late bool paumoney;
  late bool paystack;
  late bool flutterwave;
  late bool instamojo;
  late bool stripe;
  late bool phonepe;
  late bool paytm = true;
  late bool gpay = false;
  late bool bankTransfer = true;
  late bool midTrans;
  late bool myfatoorah;
  List<RadioModel> timeModel = [];
  List<RadioModel> payModel = [];
  List<RadioModel> timeModelList = [];
  List<String?> paymentMethodList = [];
  List<String> paymentIconList = [
    if (Platform.isIOS) 'assets/images/applepay.svg' else 'assets/images/gpay.svg',
    'assets/images/cod_payment.svg',
    'assets/images/paypal.svg',
    'assets/images/payu.svg',
    'assets/images/rozerpay.svg',
    'assets/images/paystack.svg',
    'assets/images/flutterwave.svg',
    'assets/images/stripe.svg',
    'assets/images/paytm.svg',
    'assets/images/banktransfer.svg',
    'assets/images/midtrans.svg',
    'assets/images/myfatoorah.svg',
    'assets/images/instamojo.svg',
    'assets/images/phonepe.svg',
  ];
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;
  final plugin = PaystackPlugin();
  @override
  void initState() {
    super.initState();
    _getdateTime();
    timeSlotList.length = 0;
    Future.delayed(Duration.zero, () {
      paymentMethodList = [
        if (Platform.isIOS) getTranslated(context, 'APPLEPAY') else getTranslated(context, 'GPAY'),
        getTranslated(context, 'COD_LBL'),
        getTranslated(context, 'PAYPAL_LBL'),
        getTranslated(context, 'PAYUMONEY_LBL'),
        getTranslated(context, 'RAZORPAY_LBL'),
        getTranslated(context, 'PAYSTACK_LBL'),
        getTranslated(context, 'FLUTTERWAVE_LBL'),
        getTranslated(context, 'STRIPE_LBL'),
        getTranslated(context, 'PAYTM_LBL'),
        getTranslated(context, 'BANKTRAN'),
        getTranslated(context, 'MIDTRANS_LBL'),
        getTranslated(context, 'MY_FATOORAH_LBL'),
        getTranslated(context, 'INSTAMOJO_LBL'),
        getTranslated(context, 'PHONEPE_LBL'),
      ];
    });
    if (widget.msg != '') {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => setSnackbar(widget.msg!, context));
    }
    buttonController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this,);
    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(CurvedAnimation(
      parent: buttonController!,
      curve: const Interval(
        0.0,
        0.150,
      ),
    ),);
  }

  @override
  void dispose() {
    buttonController!.dispose();
    super.dispose();
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {
      return;

    }
  }

  Widget noInternet(BuildContext context) {
    return SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        noIntImage(),
        noIntText(context),
        noIntDec(context),
        AppBtn(
          title: getTranslated(context, 'TRY_AGAIN_INT_LBL'),
          btnAnim: buttonSqueezeanimation,
          btnCntrl: buttonController,
          onBtnSelected: () async {
            _playAnimation();
            Future.delayed(const Duration(seconds: 2)).then((_) async {
              _isNetworkAvail = await isNetworkAvailable();
              if (_isNetworkAvail) {
                _getdateTime();
              } else {
                await buttonController!.reverse();
                if (mounted) setState(() {});
              }
            });
          },
        ),
      ],),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: Platform.isAndroid ? false : true,
      child: Scaffold(
        appBar: getSimpleAppBar(
            getTranslated(context, 'PAYMENT_METHOD_LBL')!, context,),
        body: _isNetworkAvail
            ? _isLoading
                ? getProgress(context)
                : Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 5,),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Consumer<UserProvider>(
                                    builder: (context, userProvider, _) {
                                  return Card(
                                    elevation: 0,
                                    child: userProvider.curBalance != "0" &&
                                            userProvider
                                                .curBalance.isNotEmpty &&
                                            userProvider.curBalance != ""
                                        ? Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8.0,),
                                            child: CheckboxListTile(
                                              dense: true,
                                              contentPadding:
                                                  const EdgeInsets.all(0),
                                              value: isUseWallet,
                                              onChanged: (bool? value) {
                                                if (mounted) {
                                                  setState(() {
                                                    isUseWallet = value;
                                                    if (value!) {
                                                      if ((isStorePickUp ==
                                                                  "false"
                                                              ? (totalPrice +
                                                                  deliveryCharge)
                                                              : totalPrice) <=
                                                          double.parse(
                                                              userProvider
                                                                  .curBalance,)) {
                                                        remWalBal = double.parse(
                                                                userProvider
                                                                    .curBalance,) -
                                                            (isStorePickUp ==
                                                                    "false"
                                                                ? (totalPrice +
                                                                    deliveryCharge)
                                                                : totalPrice);
                                                        usedBalance =
                                                            (isStorePickUp ==
                                                                    "false"
                                                                ? (totalPrice +
                                                                    deliveryCharge)
                                                                : totalPrice);
                                                        paymentMethod =
                                                            "Wallet";
                                                        isPayLayShow = false;
                                                      } else {
                                                        remWalBal = 0;
                                                        usedBalance = double
                                                            .parse(userProvider
                                                                .curBalance,);
                                                        isPayLayShow = true;
                                                      }
                                                      totalPrice = (isStorePickUp ==
                                                              "false"
                                                          ? ((totalPrice +
                                                                  deliveryCharge) -
                                                              usedBalance)
                                                          : (totalPrice -
                                                              usedBalance));
                                                    } else {
                                                      totalPrice = totalPrice +
                                                          (isStorePickUp ==
                                                                  "false"
                                                              ? (usedBalance -
                                                                  deliveryCharge)
                                                              : usedBalance);
                                                      remWalBal = double.parse(
                                                          userProvider
                                                              .curBalance,);
                                                      paymentMethod = null;
                                                      selectedMethod = null;
                                                      usedBalance = 0;
                                                      isPayLayShow = true;
                                                    }
                                                    widget.update();
                                                  });
                                                }
                                              },
                                              title: Text(
                                                getTranslated(
                                                    context, 'USE_WALLET',)!,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium!
                                                    .copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .fontColor,),
                                              ),
                                              subtitle: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8.0,),
                                                child: Text(
                                                  isUseWallet!
                                                      ? getTranslated(context,
                                                              'REMAIN_BAL',)! +
                                                          " : " +
                                                          '${getPriceFormat(context, remWalBal)!} '
                                                      : "${getTranslated(context, 'TOTAL_BAL')!} : ${getPriceFormat(context, double.parse(userProvider.curBalance))!}",
                                                  style: TextStyle(
                                                      fontSize: 15,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .black,),
                                                ),
                                              ),
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  );
                                },),
                                if (context
                                        .read<CartProvider>()
                                        .cartList[0]
                                        .productList![0]
                                        .productType !=
                                    'digital_product')
                                  isTimeSlot! &&
                                          (isLocalDelCharge == null ||
                                              isLocalDelCharge!) &&
                                          IS_LOCAL_ON != '0'
                                      ? Card(
                                          elevation: 0,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(
                                                  getTranslated(context,
                                                      'PREFERED_TIME',)!,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium!
                                                      .copyWith(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .fontColor,),
                                                ),
                                              ),
                                              const Divider(),
                                              Container(
                                                height: 90,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,),
                                                child: ListView.builder(
                                                    shrinkWrap: true,
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    itemCount:
                                                        int.parse(allowDay!),
                                                    itemBuilder:
                                                        (context, index) {
                                                      return dateCell(index);
                                                    },),
                                              ),
                                              const Divider(),
                                              ListView.builder(
                                                  shrinkWrap: true,
                                                  physics:
                                                      const NeverScrollableScrollPhysics(),
                                                  itemCount: timeModel.length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    return timeSlotItem(index);
                                                  },),
                                            ],
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                if (isPayLayShow!) Card(
                                        elevation: 0,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                getTranslated(
                                                    context, 'SELECT_PAYMENT',)!,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium!
                                                    .copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .fontColor,),
                                              ),
                                            ),
                                            const Divider(),
                                            ListView.builder(
                                                shrinkWrap: true,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                itemCount:
                                                    paymentMethodList.length,
                                                itemBuilder: (context, index) {
                                                  if (index == 1 &&
                                                      cod &&
                                                      context
                                                              .read<
                                                                  CartProvider>()
                                                              .cartList[0]
                                                              .productList![0]
                                                              .productType !=
                                                          'digital_product') {
                                                    return paymentItem(index);
                                                  } else if (index == 2 &&
                                                      paypal) {
                                                    return paymentItem(index);
                                                  } else if (index == 3 &&
                                                      paumoney) {
                                                    return paymentItem(index);
                                                  } else if (index == 4 &&
                                                      razorpay) {
                                                    return paymentItem(index);
                                                  } else if (index == 5 &&
                                                      paystack) {
                                                    return paymentItem(index);
                                                  } else if (index == 6 &&
                                                      flutterwave) {
                                                    return paymentItem(index);
                                                  } else if (index == 7 &&
                                                      stripe) {
                                                    return paymentItem(index);
                                                  } else if (index == 8 &&
                                                      paytm) {
                                                    return paymentItem(index);
                                                  } else if (index == 0 &&
                                                      gpay) {
                                                    return paymentItem(index);
                                                  } else if (index == 9 &&
                                                      bankTransfer) {
                                                    return paymentItem(index);
                                                  } else if (index == 10 &&
                                                      midTrans) {
                                                    return paymentItem(index);
                                                  } else if (index == 11 &&
                                                      myfatoorah) {
                                                    return paymentItem(index);
                                                  } else if (index == 12 &&
                                                      instamojo) {
                                                    return paymentItem(index);
                                                  } else if (index == 13 &&
                                                      phonepe) {
                                                    return paymentItem(index);
                                                  } else {
                                                    return const SizedBox
                                                        .shrink();
                                                  }
                                                },),
                                          ],
                                        ),
                                      ) else const SizedBox.shrink(),
                              ],
                            ),
                          ),
                        ),
                        SimBtn(
                          width: 0.8,
                          height: 35,
                          title: getTranslated(context, 'DONE'),
                          onBtnSelected: () {
                            if (paymentMethod == null ||
                                paymentMethod!.isEmpty) {
                              setSnackbar(getTranslated(context, 'payWarning')!,
                                  context,);
                            } else if (context
                                        .read<CartProvider>()
                                        .cartList[0]
                                        .productList![0]
                                        .productType !=
                                    'digital_product' &&
                                isTimeSlot! &&
                                (isLocalDelCharge == null ||
                                    isLocalDelCharge!) &&
                                int.parse(allowDay!) > 0 &&
                                (selDate == null || selDate!.isEmpty) &&
                                IS_LOCAL_ON != '0') {
                              setSnackbar(
                                  getTranslated(context, 'dateWarning')!,
                                  context,);
                            } else if (context
                                        .read<CartProvider>()
                                        .cartList[0]
                                        .productList![0]
                                        .productType !=
                                    'digital_product' &&
                                isTimeSlot! &&
                                (isLocalDelCharge == null ||
                                    isLocalDelCharge!) &&
                                timeSlotList.isNotEmpty &&
                                (selTime == null || selTime!.isEmpty) &&
                                IS_LOCAL_ON != '0') {
                              setSnackbar(
                                  getTranslated(context, 'timeWarning')!,
                                  context,);
                            } else {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ],
                    ),
                  )
            : noInternet(context),
      ),
    );
  }

  dateCell(int index) {
    final DateTime today = DateTime.parse(startingDate!);
    return InkWell(
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: selectedDate == index
                ? Theme.of(context).colorScheme.primarytheme
                : null,),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('EEE').format(today.add(Duration(days: index))),
              style: TextStyle(
                  color: selectedDate == index
                      ? Theme.of(context).colorScheme.white
                      : Theme.of(context).colorScheme.lightBlack2,),
            ),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Text(
                DateFormat('dd').format(today.add(Duration(days: index))),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selectedDate == index
                        ? Theme.of(context).colorScheme.white
                        : Theme.of(context).colorScheme.lightBlack2,),
              ),
            ),
            Text(
              DateFormat('MMM').format(today.add(Duration(days: index))),
              style: TextStyle(
                  color: selectedDate == index
                      ? Theme.of(context).colorScheme.white
                      : Theme.of(context).colorScheme.lightBlack2,),
            ),
          ],
        ),
      ),
      onTap: () {
        final DateTime date = today.add(Duration(days: index));
        if (mounted) selectedDate = index;
        selectedTime = null;
        selTime = null;
        selDate = DateFormat('yyyy-MM-dd').format(date);
        timeModel.clear();
        final DateTime cur = DateTime.now();
        final DateTime tdDate = DateTime(cur.year, cur.month, cur.day);
        if (date == tdDate) {
          if (timeSlotList.isNotEmpty) {
            for (int i = 0; i < timeSlotList.length; i++) {
              final DateTime cur = DateTime.now();
              final String time = timeSlotList[i].lastTime!;
              final DateTime last = DateTime(
                  cur.year,
                  cur.month,
                  cur.day,
                  int.parse(time.split(':')[0]),
                  int.parse(time.split(':')[1]),
                  int.parse(time.split(':')[2]),);
              if (cur.isBefore(last)) {
                timeModel.add(RadioModel(
                    isSelected: i == selectedTime ? true : false,
                    name: timeSlotList[i].name,
                    img: '',),);
              }
            }
          }
        } else {
          if (timeSlotList.isNotEmpty) {
            for (int i = 0; i < timeSlotList.length; i++) {
              timeModel.add(RadioModel(
                  isSelected: i == selectedTime ? true : false,
                  name: timeSlotList[i].name,
                  img: '',),);
            }
          }
        }
        setState(() {});
      },
    );
  }

  Future<void> _getdateTime() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      timeSlotList.clear();
      try {
        final parameter = {
          TYPE: PAYMENT_METHOD,
          USER_ID: context.read<UserProvider>().userId,
        };
        apiBaseHelper.postAPICall(getSettingApi, parameter).then(
            (getdata) async {
          final bool error = getdata["error"];
          if (!error) {
            final data = getdata["data"];
            final timeSlot = data["time_slot_config"];
            allowDay = timeSlot["allowed_days"];
            isTimeSlot =
                timeSlot["is_time_slots_enabled"] == "1" ? true : false;
            startingDate = timeSlot["starting_date"];
            codAllowed = data["is_cod_allowed"] == 1 ? true : false;
            final timeSlots = data["time_slots"];
            timeSlotList = (timeSlots as List)
                .map((timeSlots) => Model.fromTimeSlot(timeSlots))
                .toList();
            if (timeSlotList.isNotEmpty) {
              for (int i = 0; i < timeSlotList.length; i++) {
                if (selectedDate != null) {
                  final DateTime today = DateTime.parse(startingDate!);
                  final DateTime date = today.add(Duration(days: selectedDate!));
                  final DateTime cur = DateTime.now();
                  final DateTime tdDate = DateTime(cur.year, cur.month, cur.day);
                  if (date == tdDate) {
                    final DateTime cur = DateTime.now();
                    final String time = timeSlotList[i].lastTime!;
                    final DateTime last = DateTime(
                        cur.year,
                        cur.month,
                        cur.day,
                        int.parse(time.split(':')[0]),
                        int.parse(time.split(':')[1]),
                        int.parse(time.split(':')[2]),);
                    if (cur.isBefore(last)) {
                      timeModel.add(RadioModel(
                          isSelected: i == selectedTime ? true : false,
                          name: timeSlotList[i].name,
                          img: '',),);
                    }
                  } else {
                    timeModel.add(RadioModel(
                        isSelected: i == selectedTime ? true : false,
                        name: timeSlotList[i].name,
                        img: '',),);
                  }
                } else {
                  timeModel.add(RadioModel(
                      isSelected: i == selectedTime ? true : false,
                      name: timeSlotList[i].name,
                      img: '',),);
                }
              }
            }
            final payment = data["payment_method"];
            log("payments $payment");
            cod = codAllowed
                ? payment["cod_method"] == "1"
                    ? true
                    : false
                : false;
            paypal = payment["paypal_payment_method"] == "1" ? true : false;
            paumoney =
                payment["payumoney_payment_method"] == "1" ? true : false;
            flutterwave =
                payment["flutterwave_payment_method"] == "1" ? true : false;
            razorpay = payment["razorpay_payment_method"] == "1" ? true : false;
            paystack = payment["paystack_payment_method"] == "1" ? true : false;
            stripe = payment["stripe_payment_method"] == "1" ? true : false;
            paytm = payment["paytm_payment_method"] == "1" ? true : false;
            instamojo =
                payment["instamojo_payment_method"] == "1" ? true : false;
            bankTransfer =
                payment["direct_bank_transfer"] == "1" ? true : false;
            midTrans = payment['midtrans_payment_method'] == '1' ? true : false;
            myfatoorah =
                payment['myfaoorah_payment_method'] == '1' ? true : false;
            phonepe = payment['phonepe_payment_method'] == '1' ? true : false;
            if (myfatoorah) {
              myfatoorahToken = payment['myfatoorah_token'];
              myfatoorahPaymentMode = payment['myfatoorah_payment_mode'];
              myfatoorahSuccessUrl = payment['myfatoorah__successUrl'];
              myfatoorahErrorUrl = payment['myfatoorah__errorUrl'];
              myfatoorahLanguage = payment['myfatoorah_language'];
              myfatoorahCountry = payment['myfatoorah_country'];
            }
            if (midTrans) {
              midTranshMerchandId = payment['midtrans_merchant_id'];
              midtransPaymentMethod = payment['midtrans_payment_method'];
              midtransPaymentMode = payment['midtrans_payment_mode'];
              midtransServerKey = payment['midtrans_server_key'];
              midtrashClientKey = payment['midtrans_client_key'];
            }
            if (razorpay) razorpayId = payment["razorpay_key_id"];
            if (paystack) {
              paystackId = payment["paystack_key_id"];
              await plugin.initialize(publicKey: paystackId!);
            }
            if (stripe) {
              stripeId = payment['stripe_publishable_key'];
              stripeSecret = payment['stripe_secret_key'];
              stripeCurCode = payment['stripe_currency_code'];
              stripeMode = payment['stripe_mode'] ?? 'test';
              StripeService.secret = stripeSecret;
              StripeService.init(stripeId, stripeMode);
            }
            if (paytm) {
              paytmMerId = payment['paytm_merchant_id'];
              paytmMerKey = payment['paytm_merchant_key'];
              payTesting = payment['paytm_payment_mode'] == 'sandbox';
            }
            if (bankTransfer) {
              bankName = payment['bank_name'];
              bankNo = payment['bank_code'];
              acName = payment['account_name'];
              acNo = payment['account_number'];
              exDetails = payment['notes'];
            }
            if (phonepe) {
              phonePeMode = payment["phonepe_payment_mode"] ?? '';
              phonePeMerId = payment["phonepe_marchant_id"] ?? '';
              phonePeAppId = payment["phonepe_app_id"] ?? '';
            }
            for (int i = 0; i < paymentMethodList.length; i++) {
              payModel.add(RadioModel(
                  isSelected: i == selectedMethod ? true : false,
                  name: paymentMethodList[i],
                  img: paymentIconList[i],),);
            }
          } else {}
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        },);
      } on TimeoutException catch (_) {}
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
  }

  Widget timeSlotItem(int index) {
    return InkWell(
      onTap: () {
        if (mounted) {
          setState(() {
            selectedTime = index;
            selTime = timeModel[selectedTime!].name;
            for (final element in timeModel) {
              element.isSelected = false;
            }
            timeModel[index].isSelected = true;
            widget.update();
          });
        }
      },
      child: RadioItem(timeModel[index]),
    );
  }

  Widget paymentItem(int index) {
    return InkWell(
      onTap: () {
        if (mounted) {
          setState(() {
            if (IS_SHIPROCKET_ON == "1") {
              if (isUseWallet == true) {
                totalPrice = totalPrice + (usedBalance - deliveryCharge);
                isUseWallet = false;
                usedBalance = 0;
              }
              if (index == 1 && cod) {
                deliveryCharge = codDeliverChargesOfShipRocket;
              } else {
                deliveryCharge = prePaidDeliverChargesOfShipRocket;
              }
            }
            selectedMethod = index;
            paymentMethod = paymentMethodList[selectedMethod!];
            for (final element in payModel) {
              element.isSelected = false;
            }
            payModel[index].isSelected = true;
            widget.update();
          });
        }
      },
      child: RadioItem(payModel[index]),
    );
  }
}
