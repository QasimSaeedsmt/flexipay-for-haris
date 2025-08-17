// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// class PaymentReminderService {
//   /// Format phone number for WhatsApp
//   String formatPhoneNumber(String phone) {
//     String formatted = phone.replaceAll(RegExp(r'\D'), '');
//     if (formatted.startsWith('0')) {
//       formatted = '92${formatted.substring(1)}';
//     } else if (!formatted.startsWith('92')) {
//       formatted = '92$formatted';
//     }
//     return formatted;
//   }
//
//   /// Message to be sent
//   String buildMessage(String name, String month, double amount) {
//     return 'Dear $name, this is a reminder that your installment for $month is due. '
//         'Please pay Rs. ${amount.toStringAsFixed(2)} at your earliest convenience. Thank you!';
//   }
//
//   /// Send SMS using url_launcher
//   Future<void> sendSmsReminder(String name, String phone, String month, double amount) async {
//     // Just sms URI without body
//     final uri = Uri(
//       scheme: 'sms',
//       path: phone,
//     );
//
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri);
//     } else {
//       debugPrint('❌ Could not launch SMS URI without body: $uri');
//     }
//   }
//
//   /// Send WhatsApp message using wa.me
//   Future<void> sendWhatsappReminder(String name, String phone, String month, double amount) async {
//     final formattedPhone = formatPhoneNumber(phone);
//     final message = Uri.encodeComponent(buildMessage(name, month, amount));
//     final uri = Uri.parse('https://wa.me/$formattedPhone?text=$message');
//
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//     } else {
//       debugPrint('❌ Could not launch WhatsApp URI: $uri');
//     }
//   }
// }
