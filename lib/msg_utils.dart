import 'package:flexipay/permission_utils.dart';
import 'package:flexipay/string_resources.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dialog_utils.dart';

class MessageUtils{
  static String _generateInstallmentMessage({
    required String customerName,
    required String installmentMonth,
    required double amount,
  }) {
    return 'Hello $customerName,\n\n'
        'This is a friendly reminder that your monthly installment for $installmentMonth is now due. '
        'The payable amount is Rs. ${amount.toStringAsFixed(0)}.\n\n'
        'Please make the payment at your earliest convenience.\n\n'
        'If you have already completed the payment, kindly disregard this message.\n\n'
        'Thank you for your continued trust.\n\n'
        'Best regards,\n'
        'Haris Hussain';
  }

  /// Launches WhatsApp with pre-filled message
  static Future<void> sendWhatsAppMessage({
    required String phoneNumber,
    required String customerName,
    required String installmentMonth,
    required double amount,
    required BuildContext context,
  }) async {
    final message = _generateInstallmentMessage(
      customerName: customerName,
      installmentMonth: installmentMonth,
      amount: amount,
    );

    final encodedMessage = Uri.encodeComponent(message);

    // Remove any '+' from the number to avoid issues
    final cleanPhone = phoneNumber.replaceAll('+', '');

    final Uri whatsappUri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMessage');

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      // WhatsApp not available
      _showWhatsAppNotInstalledDialog(context);
    }
  }

  static void _showWhatsAppNotInstalledDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('WhatsApp Not Installed'),
        content: Text('WhatsApp is not installed on this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
  // void sendWhatsAppMessage({
  //   required String phoneNumber,
  //   required String customerName,
  //   required String installmentMonth,
  //   required double amount,
  //   required BuildContext? context,
  // }) async {
  //   final String message =
  //       'Hello $customerName,\n\n'
  //       'This is a friendly reminder that your monthly installment for $installmentMonth is now due. '
  //       'The payable amount is Rs. ${amount.toStringAsFixed(0)}.\n\n'
  //       'Please make the payment at your earliest convenience.\n\n'
  //       'If you have already completed the payment, kindly disregard this message.\n\n'
  //       'Thank you for your continued trust.\n\n'
  //       'Best regards,\n'
  //       'Haris Hussain';
  //
  //   final String encodedMessage = Uri.encodeComponent(message);
  //   final String whatsappUrl = 'intent://send?phone=$phoneNumber&text=$encodedMessage#Intent;scheme=smsto;package=com.whatsapp;end';
  //
  //   final Uri uri = Uri.parse(whatsappUrl);
  //
  //   if (await canLaunchUrl(uri)) {
  //     await launchUrl(uri, mode: LaunchMode.externalApplication);
  //   } else {
  //     if (context != null) {
  //       // Show dialog or snackbar that WhatsApp is not installed
  //       showDialog(
  //         context: context,
  //         builder: (_) => AlertDialog(
  //           title: Text('WhatsApp Not Installed'),
  //           content: Text('WhatsApp is not installed on this device.'),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.pop(context),
  //               child: Text('OK'),
  //             ),
  //           ],
  //         ),
  //       );
  //     }
  //   }
  // }

  void sendMessage({
    required String number,
    required String customerName,
    required String installmentMonth,
    required double amount,
    required BuildContext? context,
  }) async {
    final String message =
        'Hello $customerName,\n\n'
        'This is a friendly reminder that your monthly installment for $installmentMonth is now due. '
        'The payable amount is Rs. ${amount.toStringAsFixed(0)}.\n\n'
        'Please make the payment at your earliest convenience.\n\n'
        'If you have already completed the payment, kindly disregard this message.\n\n'
        'Thank you for your continued trust.\n\n'
        'Best regards,\n'
        'Haris Hussain';


    final String encodedMessage = Uri.encodeComponent(message);
    final Uri smsUri = Uri.parse('sms:$number?body=$encodedMessage');

    bool isSmsPermissionGranted =
    await PermissionUtils.requestPermission(Permission.sms, context);

    if (isSmsPermissionGranted) {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        if (context != null) {
          DialogUtils.showInfoDialog(
            context,
            title: "SMS Not Supported",
            message: "Your device doesn't support SMS or no messaging app is available.",
          );
        }
        throw '${StringResources.COULD_NOT_LAUNCH} $smsUri';
      }
    } else {
      throw StringResources.NO_PERMISSION_GIVEN;
    }
  }

}