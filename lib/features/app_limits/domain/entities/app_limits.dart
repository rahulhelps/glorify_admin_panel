class AppLimits {
  final int firstTimeWithdrawal;
  final int maxDeposit;
  final int maxWithdrawal;
  final int minDeposit;
  final int minWithdrawal;

  const AppLimits({
    required this.firstTimeWithdrawal,
    required this.maxDeposit,
    required this.maxWithdrawal,
    required this.minDeposit,
    required this.minWithdrawal,
  });

  factory AppLimits.fromMap(Map<String, dynamic> map) {
    return AppLimits(
      firstTimeWithdrawal: (map['firstTimeWithdrawal'] as num?)?.toInt() ?? 20,
      maxDeposit: (map['maxDeposit'] as num?)?.toInt() ?? 25000,
      maxWithdrawal: (map['maxWithdrawal'] as num?)?.toInt() ?? 10000,
      minDeposit: (map['minDeposit'] as num?)?.toInt() ?? 10,
      minWithdrawal: (map['minWithdrawal'] as num?)?.toInt() ?? 100,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstTimeWithdrawal': firstTimeWithdrawal,
      'maxDeposit': maxDeposit,
      'maxWithdrawal': maxWithdrawal,
      'minDeposit': minDeposit,
      'minWithdrawal': minWithdrawal,
    };
  }
}
