// Central utility for checking user verification status across the admin panel.
//
// Supported [subscriptionStatus] values:
// - `"approved"`  → Legacy verified member (treat as ৳320 Premium Plan)
// - `"plan_250"`  → New ৳250 Basic Plan member
// - `"plan_320"`  → New ৳320 Full Premium Plan member
// - `"none"` / null / any other → Unverified

const _kVerifiedStatuses = {'approved', 'plan_250', 'plan_320'};

/// Returns `true` if the raw [subscriptionStatus] string represents an active,
/// verified subscription (legacy or new).
bool isVerifiedStatus(String? status) {
  if (status == null) return false;
  return _kVerifiedStatuses.contains(status.toLowerCase().trim());
}

/// Returns a human-readable plan label for the given [subscriptionStatus].
String planLabel(String? status) {
  switch (status?.toLowerCase().trim()) {
    case 'plan_320':
      return '৳৩২০ ফুল প্রিমিয়াম প্ল্যান';
    case 'plan_250':
      return '৳২৫০ বেসিক প্ল্যান';
    case 'approved':
      return '৳৩২০ ফুল প্রিমিয়াম প্ল্যান (Legacy)';
    default:
      return 'Unverified / No Active Plan';
  }
}

/// Normalises a raw [subscriptionStatus] value for storage/display.
/// Legacy `"approved"` is kept as-is so old documents are not corrupted.
/// Unknown values are coerced to `"none"`.
String normaliseStatus(String? status) {
  final s = status?.toLowerCase().trim() ?? 'none';
  return _kVerifiedStatuses.contains(s) ? s : 'none';
}
