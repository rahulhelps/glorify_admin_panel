import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/deposit_bloc.dart';
import '../../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DepositScreen — content widget only (no Scaffold; lives inside AdminShell)
// All Bloc events preserved:
//   LoadPendingDeposits()              — initState
//   ApproveDepositRequested(req)       — approve button
//   RejectDepositRequested(req.id)     — reject button
// ─────────────────────────────────────────────────────────────────────────────
class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DepositBloc>().add(LoadPendingDeposits()); // ✅ preserved
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DepositBloc, DepositState>(
      listener: (context, state) {
        if (state is DepositActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Action successful'), backgroundColor: AppColors.success),
          );
          context.read<DepositBloc>().add(LoadPendingDeposits()); // ✅ preserved
        } else if (state is DepositActionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      buildWhen: (prev, curr) =>
          curr is DepositLoading || curr is DepositLoaded || curr is DepositError,
      builder: (context, state) {
        if (state is DepositLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        } else if (state is DepositLoaded) {
          final list = state.deposits;
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded, size: 56, color: AppColors.border),
                  const SizedBox(height: AppSpacing.md),
                  Text('No pending deposits.', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final req = list[index];
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
                          _MethodBadge(method: req.paymentMethod),
                          Text(
                            '৳${req.amount}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.deposit),
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
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(req.userEmail, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: req.userEmail));
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
                                      child: const Icon(Icons.copy, size: 16, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
                                const Text('Transaction ID', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(req.transactionId, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: req.transactionId));
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
                                      child: const Icon(Icons.copy, size: 16, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Submitted', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                              Text(
                                DateFormat('dd MMM yy, hh:mm a').format(req.submittedAt),
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
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
                              onPressed: () => context.read<DepositBloc>().add(ApproveDepositRequested(req)), // ✅ preserved
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
                  ),
                ),
              );
            },
          );
        } else if (state is DepositError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        return const SizedBox();
      },
    );
  }

  void _showRejectConfirmDialog(BuildContext context, dynamic req) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Deposit?'),
        content: Text('Are you sure you want to reject the deposit request for ৳${req.amount}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<DepositBloc>().add(RejectDepositRequested(req.id)); // ✅ preserved
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}

class _MethodBadge extends StatelessWidget {
  const _MethodBadge({required this.method});
  final String method;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: AppRadius.smAll,
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Text(method, style: TextStyle(color: AppColors.info, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}


