import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../service_locator.dart';
import '../../../users/data/models/user_model.dart';
import '../../../users/domain/repositories/user_repository.dart';
import '../../domain/repositories/premium_verify_repository.dart';
import '../../../../core/theme/app_theme.dart';

class PremiumVerificationScreen extends StatefulWidget {
  const PremiumVerificationScreen({super.key});

  @override
  State<PremiumVerificationScreen> createState() => _PremiumVerificationScreenState();
}

class _PremiumVerificationScreenState extends State<PremiumVerificationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  UserModel? _searchedUser;
  bool _isConfirmEnabled = false;

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(() {
      setState(() {
        _isConfirmEnabled = _confirmController.text.trim().toLowerCase() == 'confirm';
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _searchUser() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _searchedUser = null;
      _confirmController.clear();
      _isConfirmEnabled = false;
    });

    try {
      // 1. Try fetching by UID first directly
      final doc = await FirebaseFirestore.instance.collection('users').doc(query).get();
      if (doc.exists) {
        setState(() {
          _searchedUser = UserModel.fromMap(doc.id, doc.data()!);
          _isLoading = false;
        });
        return;
      }

      // 2. Fallback to UserRepository for phone/email/referCode
      final result = await sl<UserRepository>().searchUser(query);
      result.fold(
        (failure) => setState(() {
          _errorMessage = failure.message;
          _isLoading = false;
        }),
        (user) => setState(() {
          _searchedUser = user;
          _isLoading = false;
        }),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyUser() async {
    if (_searchedUser == null) return;
    setState(() => _isSubmitting = true);

    final result = await sl<PremiumVerifyRepository>().directVerifyAndDistribute(_searchedUser!.id);

    result.fold(
      (failure) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${failure.message}'), backgroundColor: AppColors.error),
        );
      },
      (_) {
        setState(() {
          _isSubmitting = false;
          _searchedUser = _searchedUser!.copyWith(subscriptionStatus: 'plan_320');
          _confirmController.clear();
          _isConfirmEnabled = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User verified successfully. 10-generation referral bonus distributed.'),
            backgroundColor: AppColors.success,
          ),
        );
      },
    );
  }

  String _getStatusText(String status) {
    if (status == 'plan_320' || status == 'approved') return 'Verified (Plan 320)';
    return 'Unverified';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Premium Verify'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // ── Search card ───────────────────────────────────────────────────
          _buildCard(
            title: 'Search User',
            icon: Icons.person_search_rounded,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Phone, Email, UID, or Refer Code',
                      prefixIcon: Icon(Icons.search_rounded, size: 18),
                    ),
                    onSubmitted: (_) => _searchUser(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _searchUser,
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Search'),
                  ),
                ),
              ],
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
              ]),
            ),
          ],

          if (_searchedUser != null) ...[
            const SizedBox(height: AppSpacing.lg),

            // ── User detail card ──────────────────────────────────────────
            _buildCard(
              title: 'User Details',
              icon: Icons.person_rounded,
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: _searchedUser!.profileImageUrl.isNotEmpty
                            ? NetworkImage(_searchedUser!.profileImageUrl)
                            : null,
                        backgroundColor: AppColors.surfaceVariant,
                        child: _searchedUser!.profileImageUrl.isEmpty
                            ? const Icon(Icons.person_rounded, size: 28, color: AppColors.textHint)
                            : null,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_searchedUser!.name.isNotEmpty ? _searchedUser!.name : 'Unnamed User',
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: AppSpacing.xs),
                            Text(_searchedUser!.phone,
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            if (_searchedUser!.email.isNotEmpty)
                              Text(_searchedUser!.email,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                          ],
                        ),
                      ),
                      _StatusChip(status: _searchedUser!.subscriptionStatus),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildInfoRow('Status', _getStatusText(_searchedUser!.subscriptionStatus)),
                  _buildInfoRow('Refer Code', _searchedUser!.referCode),
                  _buildInfoRow('Referred By', _searchedUser!.referredBy.isNotEmpty ? _searchedUser!.referredBy : 'None'),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Confirm & verify card ─────────────────────────────────────
            _buildCard(
              title: 'Verify & Distribute Bonus',
              icon: Icons.verified_user_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warningBg,
                      borderRadius: AppRadius.mdAll,
                      border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Warning: Verifying this user will distribute 10-generation referral commissions to their upline network and log income history records.',
                            style: TextStyle(fontSize: 13, color: Colors.brown[800], fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _confirmController,
                    enabled: !_searchedUser!.is320TkPremium,
                    decoration: InputDecoration(
                      labelText: _searchedUser!.is320TkPremium
                          ? 'This user is already verified.'
                          : 'Type "confirm" to unlock verification',
                      prefixIcon: const Icon(Icons.lock_rounded, size: 18),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton.icon(
                    onPressed: (_isConfirmEnabled && !_isSubmitting && !_searchedUser!.is320TkPremium)
                        ? _verifyUser
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.verified_rounded, size: 18),
                    label: Text(
                      _isSubmitting ? 'Verifying…' : 'Verify & Distribute Referral',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            child: Row(children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
            ]),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(children: [
        Text('$label: ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
      ]),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final isPremium = status == 'plan_320' || status == 'approved';
    Color color = isPremium ? Colors.teal[700]! : AppColors.textSecondary;
    Color bg = isPremium ? const Color(0xFFE8F8F5) : AppColors.surfaceVariant;
    String text = isPremium ? 'Verified' : 'Unverified';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.smAll,
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
