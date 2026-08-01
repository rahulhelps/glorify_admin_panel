class SmmNoticeModel {
  final String title;
  final String price;
  final String reviewTime;
  final String notice;
  final String todayPassword;
  final bool isActive;
  final List<String> rules;

  SmmNoticeModel({
    required this.title,
    required this.price,
    required this.reviewTime,
    required this.notice,
    required this.todayPassword,
    required this.isActive,
    required this.rules,
  });

  factory SmmNoticeModel.fromMap(Map<String, dynamic> map) {
    return SmmNoticeModel(
      title: map['title'] ?? '',
      price: map['price']?.toString() ?? '',
      reviewTime: map['reviewTime'] ?? '',
      notice: map['notice'] ?? '',
      todayPassword: map['todayPassword'] ?? '',
      isActive: map['isActive'] ?? false,
      rules: List<String>.from(map['rules'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'price': price,
      'reviewTime': reviewTime,
      'notice': notice,
      'todayPassword': todayPassword,
      'isActive': isActive,
      'rules': rules,
    };
  }

  SmmNoticeModel copyWith({
    String? title,
    String? price,
    String? reviewTime,
    String? notice,
    String? todayPassword,
    bool? isActive,
    List<String>? rules,
  }) {
    return SmmNoticeModel(
      title: title ?? this.title,
      price: price ?? this.price,
      reviewTime: reviewTime ?? this.reviewTime,
      notice: notice ?? this.notice,
      todayPassword: todayPassword ?? this.todayPassword,
      isActive: isActive ?? this.isActive,
      rules: rules ?? this.rules,
    );
  }
}
