import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stripe_payment/stripe_payment.dart';
import 'package:http/http.dart' as http;

class StripeTransactionResponse {
  String message;
  bool success;
  StripeTransactionResponse({this.message, this.success});
}

class StripeService {
  static String apiBase = 'https://api.stripe.com/v1';
  static String paymentApiUrl = '${StripeService.apiBase}/payment_intents';
  static Uri paymentApiUri = Uri.parse(paymentApiUrl);
  static String secret =
      'sk_test_51I9Lq7G5A1MRmS3bH5nhbFWysCbSi91Cpi8EaGL299fJcFCke6yo62BpqcNOJ2z4cxg9ZWkY75CwZnTUfJ22R0kJ00ejPzpF1p';
  static Map<String, String> headers = {
    'Authorization': 'Bearer ${StripeService.secret}',
    'Content-type': 'application/x-www-form-urlencoded'
  };
  static init() {
    StripePayment.setOptions(StripeOptions(
        publishableKey:
            'pk_test_51I9Lq7G5A1MRmS3bBS02oiRN1FEMnOrmGPUMov7XrTlt4Vq240oKz0iCMDWHsZw95JVgiUCd2SGAMYL1lyzq4vL6000DwgNJre',
        merchantId: 'test', //in real application it's want to pass arguments..
        androidPayMode: 'test')); //also for this..
  }

  static Future<Map<String, dynamic>> createPaymentIntent(
      String amount, String currency) async {
    try {
      Map<String, dynamic> body = {"amount": amount, "currency": currency};
      var response =
          await http.post(paymentApiUri, headers: headers, body: body);
      return jsonDecode(response.body);
    } catch (error) {
      print('error occured in the payment intent $error');
    }
    return null;
  }

  static Future<StripeTransactionResponse> payWithNewCard(
      {String amount, String currency}) async {
    try {
      var paymentMethod = await StripePayment.paymentRequestWithCardForm(
          CardFormPaymentRequest());
      var paymentIntent =
          await StripeService.createPaymentIntent(amount, currency);
      var response = await StripePayment.confirmPaymentIntent(PaymentIntent(
          clientSecret: paymentIntent['client_secret'],
          paymentMethodId: paymentMethod.id));
      if (response.status == 'succeeded') {
        return StripeTransactionResponse(
            message: 'Transaction successful', success: true);
      } else {
        return StripeTransactionResponse(
            message: 'Transaction failed', success: false);
      }
    } on PlatformException catch (error) {
      return StripeService.getErrorAndAnalyze(error);
    } catch (error) {
      return StripeTransactionResponse(
          message: 'Transaction failed : $error', success: false);
    }
  }

  static getErrorAndAnalyze(err) {
    String message = 'Something went wrong';
    if (err.code == 'cancelled') {
      message = 'Transaction canceled';
    }
    return StripeTransactionResponse(message: message, success: false);
  }
}
