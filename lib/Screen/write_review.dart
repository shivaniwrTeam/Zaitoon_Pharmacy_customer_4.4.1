import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:eshop/Helper/Session.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import '../Helper/Color.dart';
import '../Helper/String.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../Provider/UserProvider.dart';
import '../ui/styles/DesignConfig.dart';

class Write_Review extends StatefulWidget {
  BuildContext screenContext;
  String productId;
  String userReview;
  double userStarRating;
  Write_Review(
      this.screenContext, this.productId, this.userReview, this.userStarRating,
      {super.key,});
  @override
  State<Write_Review> createState() => _Write_ReviewState();
}

class _Write_ReviewState extends State<Write_Review> {
  List<File> reviewPhotos = [];
  TextEditingController commentTextController = TextEditingController();
  double curRating = 0.0;
  bool _isNetworkAvail = true;
  @override
  void initState() {
    super.initState();
    commentTextController.text = widget.userReview;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: Platform.isAndroid ? false : true,
      child: Wrap(
        children: [
          Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,),
            child: Column(
              children: [
                bottomSheetHandle(),
                rateTextLabel(),
                ratingWidget(),
                writeReviewLabel(),
                writeReviewField(),
                getImageField(),
                sendReviewButton(widget.productId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget bottomSheetHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: Theme.of(context).colorScheme.lightBlack,),
        height: 5,
        width: MediaQuery.of(context).size.width * 0.3,
      ),
    );
  }

  Widget rateTextLabel() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: getHeading("PRODUCT_REVIEW"),
    );
  }

  Widget ratingWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: RatingBar.builder(
        initialRating: widget.userStarRating,
        minRating: 1,
        itemSize: 32,
        itemPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
        itemBuilder: (context, _) => const Icon(
          Icons.star,
          color: colors.yellow,
        ),
        onRatingUpdate: (rating) {
          curRating = rating;
        },
      ),
    );
  }

  Widget writeReviewLabel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Text(
        getTranslated(context, 'REVIEW_OPINION')!,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
      ),
    );
  }

  Widget writeReviewField() {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
        child: TextField(
          controller: commentTextController,
          style: Theme.of(context).textTheme.titleSmall,
          keyboardType: TextInputType.multiline,
          maxLines: 5,
          decoration: InputDecoration(
            border: OutlineInputBorder(
                borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.lightBlack,),),
            hintText: getTranslated(context, 'REVIEW_HINT_LBL'),
            hintStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
                color:
                    Theme.of(context).colorScheme.lightBlack2.withOpacity(0.7),),
          ),
        ),);
  }

  Widget getImageField() {
    return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
      return Container(
        padding:
            const EdgeInsetsDirectional.only(start: 20.0, end: 20.0, top: 5),
        height: 100,
        child: Row(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primarytheme,
                        borderRadius: BorderRadius.circular(50.0),),
                    child: IconButton(
                        icon: Icon(
                          Icons.camera_alt,
                          color: Theme.of(context).colorScheme.white,
                          size: 25.0,
                        ),
                        onPressed: () {
                          _reviewImgFromGallery(setModalState);
                        },),
                  ),
                  Text(
                    getTranslated(context, 'ADD_YOUR_PHOTOS')!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack,
                        fontSize: 11,),
                  ),
                ],
              ),
            ),
            Expanded(
                child: ListView.builder(
              shrinkWrap: true,
              itemCount: reviewPhotos.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, i) {
                return InkWell(
                  child: Stack(
                    alignment: AlignmentDirectional.topEnd,
                    children: [
                      Image.file(
                        reviewPhotos[i],
                        width: 100,
                        height: 100,
                      ),
                      Container(
                          color: Theme.of(context).colorScheme.black26,
                          child: const Icon(
                            Icons.clear,
                            size: 15,
                          ),),
                    ],
                  ),
                  onTap: () {
                    if (mounted) {
                      setModalState(() {
                        reviewPhotos.removeAt(i);
                      });
                    }
                  },
                );
              },
            ),),
          ],
        ),
      );
    },);
  }

  Future<void> _reviewImgFromGallery(StateSetter setModalState) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        allowMultiple: true,
      );
      if (result != null) {
        reviewPhotos = result.paths.map((path) => File(path!)).toList();
        if (mounted) setModalState(() {});
      } else {}
    } catch (e) {
      setSnackbar(getTranslated(context, "PERMISSION_NOT_ALLOWED")!, context);
    }
  }

  Widget sendReviewButton(var productID) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
            child: MaterialButton(
              height: 45.0,
              textColor: Theme.of(context).colorScheme.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),),
              onPressed: () {
                if (curRating != 0 ||
                    commentTextController.text != '' ||
                    (reviewPhotos.isNotEmpty)) {
                  setRating(curRating, commentTextController.text, reviewPhotos,
                      productID,);
                } else {
                  Navigator.pop(context);
                  setSnackbar(getTranslated(context, 'REVIEW_W')!,
                      widget.screenContext,);
                }
              },
              color: Theme.of(context).colorScheme.primarytheme,
              child: Text(widget.userStarRating == 0.0
                  ? getTranslated(context, 'SEND_REVIEW')!
                  : getTranslated(context, 'UPDATE_REVIEW_LBL')!,),
            ),
          ),
        ),
      ],
    );
  }

  Text getHeading(
    String title,
  ) {
    return Text(
      getTranslated(context, title)!,
      style: Theme.of(context).textTheme.titleLarge!.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.fontColor,),
    );
  }

  Future<void> setRating(
      double rating, String comment, List<File> files, var productID,) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        final request = http.MultipartRequest("POST", setRatingApi);
        request.headers.addAll(headers);
        request.fields[USER_ID] = context.read<UserProvider>().userId;
        request.fields[PRODUCT_ID] = productID;
        if (files.isNotEmpty) {
          for (var i = 0; i < files.length; i++) {
            final mimeType = lookupMimeType(files[i].path);
            final extension = mimeType!.split("/");
            final pic = await http.MultipartFile.fromPath(
              IMGS,
              files[i].path,
              contentType: MediaType('image', extension[1]),
            );
            request.files.add(pic);
          }
        }
        if (comment != "") request.fields[COMMENT] = comment;
        if (rating != 0) request.fields[RATING] = rating.toString();
        final response = await request.send();
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final getdata = json.decode(responseString);
        final bool error = getdata["error"];
        final String? msg = getdata['message'];
        if (!error) {
          Navigator.pop(context);
          setSnackbar(msg!, widget.screenContext);
        } else {
          setSnackbar(msg!, widget.screenContext);
        }
        commentTextController.text = "";
        files.clear();
        reviewPhotos.clear();
      } on TimeoutException catch (_) {
        setSnackbar(
            getTranslated(context, 'somethingMSg')!, widget.screenContext,);
      }
    } else if (mounted) {
      setState(() {
        _isNetworkAvail = false;
      });
    }
  }
}
