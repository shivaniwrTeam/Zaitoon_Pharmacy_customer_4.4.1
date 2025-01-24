part of '../Cart.dart';

Widget noInternet(BuildContext context,
    {required Animation? buttonSqueezeanimation,
    required AnimationController? buttonController,
    required Widget onNetworkNavigationWidget,
    required Function(bool internetAvailable) onButtonClicked,}) {
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
          try {
            await buttonController?.forward();
          } on TickerCanceled {
      return;

          }
          Future.delayed(const Duration(seconds: 2)).then((_) async {
            final bool _isNetworkAvail = await isNetworkAvailable();
            if (_isNetworkAvail) {
            } else {
              await buttonController?.reverse();
            }
            onButtonClicked.call(_isNetworkAvail);
          });
        },
      ),
    ],),
  );
}

Future<void> _getAddress(BuildContext context,
    {required VoidCallback onComplete,
    required Function(bool hasInternet) onInternetState,}) async {
  final bool _isNetworkAvailable = await isNetworkAvailable();
  if (_isNetworkAvailable) {
    onInternetState.call(true);
    try {
      final parameter = {
        USER_ID: context.read<UserProvider>().userId,
      };
      apiBaseHelper.postAPICall(getAddressApi, parameter).then((getdata) {
        final bool error = getdata["error"];
        if (!error) {
          final data = getdata["data"];
          addressList =
              (data as List).map((data) => User.fromAddress(data)).toList();
          if (addressList.length == 1) {
            selectedAddress = 0;
            selAddress = addressList[0].id;
            if (!ISFLAT_DEL) {
              if (totalPrice < double.parse(addressList[0].freeAmt!)) {
                deliveryCharge = double.parse(addressList[0].deliveryCharge!);
              } else {
                deliveryCharge = 0;
              }
            }
          } else {
            for (int i = 0; i < addressList.length; i++) {
              if (addressList[i].isDefault == "1") {
                selectedAddress = i;
                selAddress = addressList[i].id;
                if (!ISFLAT_DEL) {
                  if (totalPrice < double.parse(addressList[i].freeAmt!)) {
                    deliveryCharge =
                        double.parse(addressList[i].deliveryCharge!);
                  } else {
                    deliveryCharge = 0;
                  }
                }
              }
            }
          }
          if (ISFLAT_DEL) {
            if (originalPrice < double.parse(MIN_AMT!)) {
              deliveryCharge = double.parse(CUR_DEL_CHR!);
            } else {
              deliveryCharge = 0;
            }
          }
        } else {
          if (ISFLAT_DEL) {
            if (originalPrice < double.parse(MIN_AMT!)) {
              deliveryCharge = double.parse(CUR_DEL_CHR!);
            } else {
              deliveryCharge = 0;
            }
          }
        }
        onComplete.call();
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      },);
    } on TimeoutException catch (_) {}
  } else {
    onInternetState.call(false);
  }
}

cartEmpty(BuildContext context) {
  return Center(
    child: SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SvgPicture.asset(
          'assets/images/empty_cart.svg',
          colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.primarytheme, BlendMode.srcIn,),
        ),
        Text(getTranslated(context, 'NO_CART')!,
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                color: Theme.of(context).colorScheme.primarytheme,
                fontWeight: FontWeight.normal,),),
        Container(
          padding: const EdgeInsetsDirectional.only(
              top: 30.0, start: 30.0, end: 30.0,),
          child: Text(getTranslated(context, 'CART_DESC')!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Theme.of(context).colorScheme.lightBlack2,
                    fontWeight: FontWeight.normal,
                  ),),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 28.0),
          child: CupertinoButton(
            child: Container(
                width: deviceWidth! * 0.7,
                height: 45,
                alignment: FractionalOffset.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primarytheme,
                  borderRadius: const BorderRadius.all(Radius.circular(50.0)),
                ),
                child: Text(getTranslated(context, 'SHOP_NOW')!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: Theme.of(context).colorScheme.white,
                        fontWeight: FontWeight.normal,),),),
            onPressed: () {
              Navigator.of(context).popUntil(
                (final Route route) => route.isFirst,
              );
              Dashboard.dashboardScreenKey.currentState?.changeTabPosition(0);
            },
          ),
        ),
      ],),
    ),
  );
}

_imgFromGallery(BuildContext context,
    {required Function(List<File> pickedFiles) onFilePick,}) async {
  try {
    final result = await FilePicker.platform
        .pickFiles(allowMultiple: true, type: FileType.image);
    if (result != null) {
      onFilePick.call(result.paths.map((path) => File(path!)).toList());
    } else {}
  } catch (e) {
    setSnackbar(getTranslated(context, "PERMISSION_NOT_ALLOWED")!, context);
  }
}

void bankTransfer(BuildContext context,
    {required VoidCallback onTapCancel, required VoidCallback onTapDone,}) {
  showGeneralDialog(
      barrierColor: Theme.of(context).colorScheme.black.withOpacity(0.5),
      transitionBuilder: (context, a1, a2, widget) {
        return Transform.scale(
          scale: a1.value,
          child: Opacity(
              opacity: a1.value,
              child: AlertDialog(
                contentPadding: const EdgeInsets.all(0),
                elevation: 2.0,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),),
                content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20.0, 20.0, 0, 2.0),
                        child: Text(
                          getTranslated(context, 'BANKTRAN')!,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(
                                  color:
                                      Theme.of(context).colorScheme.fontColor,),
                        ),
                      ),
                      Divider(color: Theme.of(context).colorScheme.lightBlack),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                        child: Text(getTranslated(context, 'BANK_INS')!,
                            style: Theme.of(context).textTheme.bodySmall,),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 10,),
                        child: Text(
                          getTranslated(context, 'ACC_DETAIL')!,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall!
                              .copyWith(
                                  color:
                                      Theme.of(context).colorScheme.fontColor,),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                        ),
                        child: Text(
                          "${getTranslated(context, 'ACCNAME')!} : ${acName!}",
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                        ),
                        child: Text(
                          "${getTranslated(context, 'ACCNO')!} : ${acNo!}",
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                        ),
                        child: Text(
                          "${getTranslated(context, 'BANKNAME')!} : ${bankName!}",
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                        ),
                        child: Text(
                          "${getTranslated(context, 'BANKCODE')!} : ${bankNo!}",
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${getTranslated(context, 'EXTRADETAIL')!} : ",
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Expanded(
                              child: HtmlWidget(
                                exDetails!,
                                onTapUrl: (String? url) async {
                                  if (await canLaunchUrl(Uri.parse(url!))) {
                                    await launchUrl(Uri.parse(url));
                                    return true;
                                  } else {
                                    throw 'Could not launch $url';
                                  }
                                },
                                onErrorBuilder: (context, element, error) =>
                                    Text('$element error: $error'),
                                onLoadingBuilder:
                                    (context, element, loadingProgress) =>
                                        showCircularProgress(context, true,
                                            Theme.of(context).primaryColor,),
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .titleSmall!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],),
                actions: <Widget>[
                  TextButton(
                      child: Text(getTranslated(context, 'CANCEL')!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.lightBlack,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,),),
                      onPressed: () {
                        onTapCancel.call();
                        Navigator.pop(context);
                      },),
                  TextButton(
                      child: Text(getTranslated(context, 'DONE')!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.fontColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,),),
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<CartProvider>().setProgress(true);
                        onTapDone.call();
                      },),
                ],
              ),),
        );
      },
      barrierLabel: '',
      context: context,
      pageBuilder: (context, animation1, animation2) {
        return const SizedBox.shrink();
      },);
}
