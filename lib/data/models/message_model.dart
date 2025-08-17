class MessageLogModel {
  final String customerId;
  final String itemName;
  final String method; // 'WhatsApp' or 'SMS'
  final String month;
  final DateTime sentAt;

  MessageLogModel({
    required this.customerId,
    required this.itemName,
    required this.method,
    required this.month,
    required this.sentAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'itemName': itemName,
      'method': method,
      'month': month,
      'sentAt': sentAt.toIso8601String(),
    };
  }

  factory MessageLogModel.fromMap(Map<String, dynamic> map) {
    return MessageLogModel(
      customerId: map['customerId'],
      itemName: map['itemName'],
      method: map['method'],
      month: map['month'],
      sentAt: DateTime.parse(map['sentAt']),
    );
  }
}
