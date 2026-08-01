import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/recharge_request.dart';
import '../bloc/recharge_request_bloc.dart';
import '../bloc/recharge_request_event.dart';
import '../bloc/recharge_request_state.dart';

class RechargeRequestsScreen extends StatefulWidget {
  const RechargeRequestsScreen({super.key});

  @override
  State<RechargeRequestsScreen> createState() => _RechargeRequestsScreenState();
}

class _RechargeRequestsScreenState extends State<RechargeRequestsScreen> {
  final Set<String> _processingIds = <String>{};
  List<RechargeRequest>? _cachedRequests;

  @override
  void initState() {
    super.initState();
    context.read<RechargeRequestBloc>().add(LoadPendingRechargeRequests());
  }

  void _approveRequest(RechargeRequest request) {
    final cashback = request.amount * 0.02;
    final formattedCashback = (cashback % 1 == 0)
        ? cashback.toStringAsFixed(0)
        : cashback.toStringAsFixed(2);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Recharge?'),
        content: Text(
          'Confirm that you have manually recharged ৳${request.amount.toStringAsFixed(0)} to ${request.phone}.\n\n'
          'User will receive ৳$formattedCashback (2%) cashback in their earning balance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _processingIds.add(request.id);
              });
              context.read<RechargeRequestBloc>().add(ApproveRechargeRequest(request));
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _rejectRequest(RechargeRequest request) {
    final formattedAmount = (request.amount % 1 == 0)
        ? request.amount.toStringAsFixed(0)
        : request.amount.toStringAsFixed(2);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Request?'),
        content: Text(
          'Are you sure you want to reject this request?\n\n'
          '৳$formattedAmount will be refunded back to the user\'s recharge balance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _processingIds.add(request.id);
              });
              context.read<RechargeRequestBloc>().add(RejectRechargeRequest(request));
            },
            child: const Text('Reject & Refund'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Recharge Requests'),
      ),
      body: BlocConsumer<RechargeRequestBloc, RechargeRequestState>(
        listener: (context, state) {
          if (state is RechargeRequestActionSuccess) {
            setState(() {
              _processingIds.clear();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is RechargeRequestActionError) {
            setState(() {
              _processingIds.clear();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is RechargeRequestsError) {
            setState(() {
              _processingIds.clear();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is RechargeRequestsLoaded) {
            setState(() {
              _cachedRequests = state.requests;
              _processingIds.removeWhere((id) => !state.requests.any((r) => r.id == id));
            });
          }
        },
        builder: (context, state) {
          final requests = (state is RechargeRequestsLoaded) ? state.requests : _cachedRequests;

          if (requests == null) {
            if (state is RechargeRequestsError) {
              return Center(
                child: Text(
                  state.message,
                  style: GoogleFonts.inter(color: AppColors.error),
                ),
              );
            }
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (requests.isEmpty) {
            return Center(
              child: Text(
                'No pending recharge requests.',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              return _buildRequestCard(req);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(RechargeRequest req) {
    final isProcessing = _processingIds.contains(req.id);
    final cashback = req.amount * 0.02;
    final formattedCashback = (cashback % 1 == 0)
        ? cashback.toStringAsFixed(0)
        : cashback.toStringAsFixed(2);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.phone_android, size: 20, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        req.phone,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '৳${req.amount.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getOperatorColor(req.operator).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: _getOperatorColor(req.operator).withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    req.operator,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getOperatorColor(req.operator),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    req.connectionType,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  req.userName,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '(UID: ${req.uid})',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(req.submittedAt),
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Potential Cashback Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.percent, size: 14, color: AppColors.success),
                  const SizedBox(width: 6),
                  Text(
                    'User Cashback on Approval: ৳$formattedCashback (2%)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24, color: AppColors.border),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  onPressed: isProcessing ? null : () => _rejectRequest(req),
                  icon: isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
                        )
                      : const Icon(Icons.close, size: 16),
                  label: const Text('Reject'),
                ),
                const SizedBox(width: AppSpacing.md),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isProcessing ? null : () => _approveRequest(req),
                  icon: isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check, size: 16),
                  label: const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getOperatorColor(String operator) {
    switch (operator.toLowerCase()) {
      case 'grameenphone':
        return Colors.blue;
      case 'robi':
        return Colors.red;
      case 'airtel':
        return Colors.deepOrange;
      case 'banglalink':
        return Colors.orange;
      case 'teletalk':
        return Colors.green;
      default:
        return AppColors.primary;
    }
  }
}
