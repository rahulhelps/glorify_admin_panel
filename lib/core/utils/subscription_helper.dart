// Central utility for checking user verification status across the admin panel.
//
// Supported [subscriptionStatus] values:
// - `"approved"`  → Legacy verified member (treat as Plan 320)
// - `"plan_320"`  → Plan 320 Verified member
// - `"none"` / null / any other → Unverified

const _kVerifiedStatuses = {'approved', 'plan_320'};

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
      return 'Verified User (Premium)';
    case 'approved':
      return 'Verified User';
    default:
      return 'Unverified User';
  }
}

/// Normalises a raw [subscriptionStatus] value for storage/display.
/// Legacy `"approved"` is kept as-is so old documents are not corrupted.
/// Unknown values are coerced to `"none"`.
String normaliseStatus(String? status) {
  final s = status?.toLowerCase().trim() ?? 'none';
  return _kVerifiedStatuses.contains(s) ? s : 'none';
}
