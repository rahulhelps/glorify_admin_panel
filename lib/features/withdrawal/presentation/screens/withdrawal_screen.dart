import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../bloc/withdrawal_bloc.dart';
import '../../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WithdrawalScreen — content widget only (no Scaffold; lives inside AdminShell)
// All Bloc events preserved:
//   LoadWithdrawals()                     — initState
//   ApproveWithdrawalRequested(req.id)    — approve button
//   RejectWithdrawalRequested(req)        — reject button
// ─────────────────────────────────────────────────────────────────────────────
class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<WithdrawalBloc>().add(LoadWithdrawals()); // ✅ preserved
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Withdrawals'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Tab bar ──────────────────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Pending'),
                Tab(text: 'Approved'),
                Tab(text: 'Rejected'),
              ],
            ),
          ),
          // ── Content ──────────────────────────────────────────────────────────
          Expanded(
            child: BlocConsumer<WithdrawalBloc, WithdrawalState>(
              listener: (context, state) {
                if (state is WithdrawalActionSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Action successful'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  context.read<WithdrawalBloc>().add(LoadWithdrawals()); // ✅ preserved
                } else if (state is WithdrawalActionError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
                  );
                }
              },
              buildWhen: (prev, curr) =>
                  curr is WithdrawalLoading ||
                  curr is WithdrawalLoaded ||
                  curr is WithdrawalError,
              builder: (context, state) {
                if (state is WithdrawalLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                } else if (state is WithdrawalLoaded) {
                  final all = state.withdrawals;
                  final pending = all.where((w) => w.status == 'pending').toList();
                  final approved = all.where((w) => w.status == 'approved').toList();
                  final rejected = all.where((w) => w.status == 'rejected').toList();
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(pending, isPending: true),
                      _buildList(approved, isPending: false),
                      _buildList(rejected, isPending: false),
                    ],
                  );
                } else if (state is WithdrawalError) {
                  return Center(child: Text('Error: ${state.message}'));
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List withdrawals, {required bool isPending}) {
    if (withdrawals.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: withdrawals.length,
      itemBuilder: (context, index) {
        final req = withdrawals[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _MethodChip(method: req.paymentMethod),
                    Text(
                      '৳${req.amount}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(req.userName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 2),
                          _UidEmailCell(uid: req.uid),
                        ],
                      ),
                    ),
                    _StatusBadge(status: req.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Account Number', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                          _CopyCell(text: req.accountNumber, fontSize: 13),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Requested', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                        Text(
                          DateFormat('dd MMM yy, hh:mm a').format(req.requestedAt),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isPending) ...[
                  const Divider(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showRejectConfirmDialog(context, req),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
                          ),
                          child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.read<WithdrawalBloc>().add(ApproveWithdrawalRequested(req.id)), // ✅ preserved
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
                          ),
                          child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRejectConfirmDialog(BuildContext context, dynamic req) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Withdrawal?'),
        content: Text('Are you sure you want to reject the withdrawal request for ৳${req.amount}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<WithdrawalBloc>().add(RejectWithdrawalRequested(req)); // ✅ preserved
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 56, color: AppColors.border),
          const SizedBox(height: AppSpacing.md),
          Text('No records found.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
        ],
      ),
    );
  }
}

// ─── Helper widgets ──────────────────────────────────────────────────────────

class _MethodChip extends StatelessWidget {
  const _MethodChip({required this.method});
  final String method;

  @override
  Widget build(BuildContext context) {
    final m = method.toLowerCase();
    Color color = m.contains('bkash')
        ? Colors.pink
        : m.contains('nagad')
            ? Colors.orange
            : m.contains('rocket')
                ? Colors.purple
                : Colors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.smAll,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(method,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _UidEmailCell extends StatelessWidget {
  const _UidEmailCell({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading…', style: TextStyle(fontSize: 11, color: AppColors.textHint));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('UID lookup failed', style: TextStyle(fontSize: 11, color: AppColors.textHint));
        }
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final email = data?['email'] as String? ?? '';
        return _CopyCell(text: email.isNotEmpty ? email : uid, fontSize: 11);
      },
    );
  }
}

class _CopyCell extends StatelessWidget {
  const _CopyCell({required this.text, this.fontSize = 13});
  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'কপি করা হয়েছে!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: const Color(0xFF1E1E24),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 1, milliseconds: 500),
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: fontSize, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.copy_rounded, size: 12, color: AppColors.textHint),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved':
        color = AppColors.success;
        break;
      case 'rejected':
        color = AppColors.error;
        break;
      default:
        color = AppColors.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.smAll,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}


