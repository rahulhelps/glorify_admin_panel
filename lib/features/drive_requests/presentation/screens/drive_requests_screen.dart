import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/drive_request.dart';
import '../bloc/drive_request_bloc.dart';
import '../bloc/drive_request_event.dart';
import '../bloc/drive_request_state.dart';

class DriveRequestsScreen extends StatefulWidget {
  const DriveRequestsScreen({super.key});

  @override
  State<DriveRequestsScreen> createState() => _DriveRequestsScreenState();
}

class _DriveRequestsScreenState extends State<DriveRequestsScreen> {
  final Set<String> _processingIds = <String>{};
  List<DriveRequest>? _cachedRequests;

  @override
  void initState() {
    super.initState();
    context.read<DriveRequestBloc>().add(LoadPendingDriveRequests());
  }

  void _approveRequest(DriveRequest request) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Request?'),
        content: const Text('Confirm that you have manually recharged this number before approving.'),
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
              context.read<DriveRequestBloc>().add(ApproveDriveRequest(request));
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _rejectRequest(String requestId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Request?'),
        content: const Text('This will refund the balance to the user. Are you sure?'),
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
                _processingIds.add(requestId);
              });
              context.read<DriveRequestBloc>().add(RejectDriveRequest(requestId));
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
        title: const Text('Drive Requests'),
      ),
      body: BlocConsumer<DriveRequestBloc, DriveRequestState>(
        listener: (context, state) {
          if (state is DriveRequestActionSuccess) {
            setState(() {
              _processingIds.clear();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.success),
            );
          } else if (state is DriveRequestActionError) {
            setState(() {
              _processingIds.clear();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          } else if (state is DriveRequestsError) {
            setState(() {
              _processingIds.clear();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          } else if (state is DriveRequestsLoaded) {
            setState(() {
              _cachedRequests = state.requests;
              _processingIds.removeWhere((id) => !state.requests.any((r) => r.id == id));
            });
          }
        },
        builder: (context, state) {
          final requests = (state is DriveRequestsLoaded) ? state.requests : _cachedRequests;

          if (requests == null) {
            if (state is DriveRequestsError) {
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
                'No pending drive requests.',
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

  Widget _buildRequestCard(DriveRequest req) {
    final isProcessing = _processingIds.contains(req.id);

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
                  child: Text(
                    req.packageDetails,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
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
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.phone_android, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  req.targetNumber,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '৳${req.offerPrice.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'User ID: ${req.userId}',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(req.createdAt),
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
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
                  onPressed: isProcessing ? null : () => _rejectRequest(req.id),
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
