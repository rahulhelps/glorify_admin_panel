import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TransactionInvoiceModel {
  final String id;
  final String uid;
  final String userEmail;
  final String userPhone;
  final String userName;
  final double amount;
  final String status;
  final String paymentMethod;
  final String transactionId;
  final String invoiceType;
  final DateTime? createdAt;
  final Map<String, dynamic> rawMap;

  TransactionInvoiceModel({
    required this.id,
    required this.uid,
    this.userEmail = '',
    this.userPhone = '',
    this.userName = '',
    required this.amount,
    required this.status,
    this.paymentMethod = '',
    this.transactionId = '',
    this.invoiceType = '',
    this.createdAt,
    this.rawMap = const {},
  });

  factory TransactionInvoiceModel.fromFirestore(
    DocumentSnapshot doc, {
    String invoiceType = '',
  }) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return TransactionInvoiceModel.fromMap(doc.id, map, invoiceType: invoiceType);
  }

  factory TransactionInvoiceModel.fromMap(
    String id,
    Map<String, dynamic> map, {
    String invoiceType = '',
  }) {
    // ── Parse amount ─────────────────────────────────────────────────────────
    double parsedAmount = 0.0;
    final rawAmount = map['amount'] ??
        map['totalAmount'] ??
        map['price'] ??
        map['payableAmount'] ??
        map['fee'];
    if (rawAmount != null) {
      if (rawAmount is num) {
        parsedAmount = rawAmount.toDouble();
      } else if (rawAmount is String) {
        parsedAmount = double.tryParse(rawAmount.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
      }
    }

    // ── Parse timestamp ──────────────────────────────────────────────────────
    DateTime? parsedDate;
    final rawDate = map['createdAt'] ??
        map['timestamp'] ??
        map['date'] ??
        map['created_at'] ??
        map['paymentDate'] ??
        map['requestedAt'] ??
        map['updatedAt'];

    if (rawDate != null) {
      if (rawDate is Timestamp) {
        parsedDate = rawDate.toDate();
      } else if (rawDate is DateTime) {
        parsedDate = rawDate;
      } else if (rawDate is String) {
        parsedDate = DateTime.tryParse(rawDate);
      } else if (rawDate is int) {
        // Epoch milliseconds or seconds
        parsedDate = rawDate > 100000000000
            ? DateTime.fromMillisecondsSinceEpoch(rawDate)
            : DateTime.fromMillisecondsSinceEpoch(rawDate * 1000);
      }
    }

    // ── Parse status ─────────────────────────────────────────────────────────
    final rawStatus = (map['status'] ??
            map['paymentStatus'] ??
            map['invoiceStatus'] ??
            map['state'] ??
            'pending')
        .toString()
        .trim();

    return TransactionInvoiceModel(
      id: id,
      uid: (map['uid'] ?? map['userId'] ?? map['user_id'] ?? '').toString().trim(),
      userEmail: (map['userEmail'] ?? map['email'] ?? map['user_email'] ?? map['customerEmail'] ?? '')
          .toString()
          .trim(),
      userPhone: (map['userPhone'] ??
              map['phone'] ??
              map['phoneNumber'] ??
              map['user_phone'] ??
              map['customerPhone'] ??
              '')
          .toString()
          .trim(),
      userName: (map['userName'] ?? map['name'] ?? map['customerName'] ?? map['user_name'] ?? '')
          .toString()
          .trim(),
      amount: parsedAmount,
      status: rawStatus,
      paymentMethod: (map['paymentMethod'] ??
              map['method'] ??
              map['gateway'] ??
              map['provider'] ??
              map['channel'] ??
              map['payment_method'] ??
              '')
          .toString()
          .trim(),
      transactionId: (map['transactionId'] ??
              map['trxId'] ??
              map['trxID'] ??
              map['txId'] ??
              map['invoiceId'] ??
              map['orderId'] ??
              map['transaction_id'] ??
              '')
          .toString()
          .trim(),
      invoiceType: invoiceType.isNotEmpty
          ? invoiceType
          : (map['invoiceType'] ?? map['type'] ?? '').toString().trim(),
      createdAt: parsedDate,
      rawMap: map,
    );
  }

  // ── Helper Getters ──────────────────────────────────────────────────────────
  String get formattedAmount {
    if (amount == amount.truncateToDouble()) {
      return '৳${amount.toInt()}';
    }
    return '৳${amount.toStringAsFixed(2)}';
  }

  String get formattedDate {
    if (createdAt == null) return 'N/A';
    return DateFormat('dd MMM yyyy, hh:mm a').format(createdAt!);
  }

  String get shortDate {
    if (createdAt == null) return 'N/A';
    return DateFormat('dd MMM yy').format(createdAt!);
  }

  String get normalizedStatus {
    final s = status.toLowerCase();
    if (s == 'completed' || s == 'approved' || s == 'success' || s == 'paid' || s == 'active') {
      return 'completed';
    }
    if (s == 'pending' || s == 'processing' || s == 'initiated' || s == 'waiting') {
      return 'pending';
    }
    if (s == 'failed' || s == 'rejected' || s == 'cancelled' || s == 'declined' || s == 'expired') {
      return 'failed';
    }
    return s;
  }

  bool get isCompleted => normalizedStatus == 'completed';
  bool get isPending => normalizedStatus == 'pending';
  bool get isFailed => normalizedStatus == 'failed';

  TransactionInvoiceModel copyWith({
    String? userEmail,
    String? userPhone,
    String? userName,
  }) {
    return TransactionInvoiceModel(
      id: id,
      uid: uid,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      userName: userName ?? this.userName,
      amount: amount,
      status: status,
      paymentMethod: paymentMethod,
      transactionId: transactionId,
      invoiceType: invoiceType,
      createdAt: createdAt,
      rawMap: rawMap,
    );
  }
}
