import 'package:eshop/Helper/ApiBaseHelper.dart';
import 'package:eshop/Helper/String.dart';
import 'package:eshop/Model/Section_Model.dart';
import 'package:eshop/ui/widgets/ApiException.dart';
import 'package:flutter/material.dart';

class CartProvider extends ChangeNotifier {
  final List<SectionModel> _cartList = [];
  List<SectionModel> get cartList => _cartList;
  bool _isProgress = false;
  get cartIdList => _cartList.map((fav) => fav.varientId).toList();
  get isProgress => _isProgress;
  setProgress(bool progress) {
    _isProgress = progress;
    notifyListeners();
  }

  bool _isProductInCart = false;
  bool get isProductInCart => _isProductInCart;
  void updateIsProductInCart(bool value) {
    _isProductInCart = value;
    notifyListeners();
  }

  removeCartItem(String id, {int? index}) {
    if (index != null) {
      _cartList.removeWhere(
          (item) => item.productList![0].prVarientList![index].id == id,);
    } else {
      _cartList.removeWhere((item) => item.varientId == id);
    }
    notifyListeners();
  }

  void clearCartExcept(SectionModel itemsToKeep) {
    _cartList
        .removeWhere((element) => element.varientId != itemsToKeep.varientId);
    notifyListeners();
  }

  addCartItem(SectionModel? item) {
    if (item != null) {
      _cartList.add(item);
      notifyListeners();
    }
  }

  updateCartItem(String? id, String qty, int index, String vId) {
    final i = _cartList.indexWhere((cp) => cp.id == id && cp.varientId == vId);
    _cartList[i].qty = qty;
    _cartList[i].productList![0].prVarientList![index].cartCount = qty;
    notifyListeners();
  }

  setCartlist(List<SectionModel> cartList) {
    _cartList.clear();
    _cartList.addAll(cartList);
    notifyListeners();
  }
}

Future<Map> getPhonePeDetails({
  required String userId,
  required String type,
  required String mobile,
  String? amount,
  required String orderId,
  required String transationId,
}) async {
  try {
    final responseData = await ApiBaseHelper().postAPICall(
      getPhonePeDetailsApi,
      {
        'type': type,
        'mobile': mobile,
        if (amount != null) 'amount': amount,
        'order_id': orderId,
        'transation_id': transationId,
        'user_id': userId,
      },
    );
    return responseData;
  } on Exception catch (e) {
    throw ApiException('$e$e');
  }
}
