import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/ads_view_bloc.dart';
import '../bloc/ads_view_event.dart';
import '../bloc/ads_view_state.dart';
import '../../domain/entities/ads_view_task.dart';
import '../../../../core/theme/app_theme.dart';

class AdsViewsScreen extends StatefulWidget {
  const AdsViewsScreen({super.key});

  @override
  State<AdsViewsScreen> createState() => _AdsViewsScreenState();
}

class _AdsViewsScreenState extends State<AdsViewsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _rateCtrl = TextEditingController();
  String _dateFilter = 'all';
  final Set<String> _processingTasks = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    context.read<AdsViewBloc>().add(const LoadAdsViewTasks('pending'));
    context.read<AdsViewBloc>().add(LoadGlobalRate());
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _searchCtrl.clear();
    setState(() => _dateFilter = 'all');
    final status = _tabController.index == 0 ? 'pending' : 'approved';
    context.read<AdsViewBloc>().add(LoadAdsViewTasks(status));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  void _applyFilters() {
    context.read<AdsViewBloc>().add(FilterAdsViewTasks(
      query: _searchCtrl.text,
      dateFilter: _dateFilter,
    ));
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  },
                  errorBuilder: (_, e, s) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white54, size: 80),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // No Scaffold — lives inside AdminShell. All Bloc events preserved.
    return BlocConsumer<AdsViewBloc, AdsViewState>(
      listener: (context, state) {
        if (state is AdsViewActionSuccess || state is AdsViewError) {
          setState(() => _processingTasks.clear());
        }
        if (state is AdsViewActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.success),
          );
        } else if (state is AdsViewError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      builder: (context, state) {
        double currentRate = 0.0;
        if (state is AdsViewLoaded) {
          currentRate = state.globalRate;
          if (_rateCtrl.text.isEmpty && currentRate > 0) {
            _rateCtrl.text = currentRate.toStringAsFixed(2);
          }
        }
        return Column(
          children: [
            // Tab bar at top of content area
            Container(
              color: AppColors.surface,
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Pending'),
                  Tab(text: 'Approved'),
                ],
              ),
            ),
            _buildGlobalRateCard(context, currentRate),
            _buildControlBar(context),
            Expanded(child: _buildList(state)),
          ],
        );
      },
    );
  }

  Widget _buildGlobalRateCard(BuildContext context, double currentRate) {
    return Card(
      margin: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll, side: const BorderSide(color: AppColors.border)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.monetization_on_rounded, color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Global Per-Ad Rate', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  Text('Current: ৳$currentRate', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            SizedBox(
              width: 90,
              child: TextField(
                controller: _rateCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Rate',
                  prefixText: '৳ ',
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
              ),
              onPressed: () {
                final rate = double.tryParse(_rateCtrl.text);
                if (rate != null && rate >= 0) {
                  context.read<AdsViewBloc>().add(UpdateGlobalRate(rate)); // ✅ preserved
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid rate')));
                }
              },
              child: const Text('Save', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search Email, Phone...',
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                isDense: true,
              ),
              onChanged: (_) => _applyFilters(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _dateFilter,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Dates', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'today', child: Text('Today', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'yesterday', child: Text('Yesterday', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: '7days', child: Text('Last 7 Days', overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _dateFilter = val);
                  _applyFilters();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(AdsViewState state) {
    if (state is AdsViewLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (state is AdsViewLoaded) {
      final tasks = state.filteredTasks;
      if (tasks.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: AppColors.border),
              const SizedBox(height: AppSpacing.sm),
              const Text('No records found.', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
        itemCount: tasks.length,
        itemBuilder: (context, index) => _buildTaskCard(context, tasks[index], state.globalRate),
      );
    }
    return const SizedBox();
  }

  Widget _buildTaskCard(BuildContext context, AdsViewTask task, double globalRate) {
    final isPending = task.status == 'pending';
    final isProcessing = _processingTasks.contains(task.id);
    final imageUrl = task.imageUrl;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isPending ? AppColors.warningBg : AppColors.successBg,
                  child: Icon(
                    isPending ? Icons.pending_actions_rounded : Icons.check_circle_outline_rounded,
                    color: isPending ? AppColors.warning : AppColors.success,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.userName ?? 'Unknown User',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${task.userEmail ?? 'No Email'}  •  ${task.userPhone ?? 'No Phone'}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text('Ref: ${task.userReferCode ?? 'N/A'}',
                          style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(
                        'Submitted: ${DateFormat('dd MMM yyyy, hh:mm a').format(task.submittedAt)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _buildProofThumbnail(context, imageUrl),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            if (isPending)
              isProcessing
                  ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 4), child: CircularProgressIndicator(color: AppColors.primary)))
                  : Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              elevation: 0,
                            ),
                            onPressed: () {
                              setState(() => _processingTasks.add(task.id));
                              context.read<AdsViewBloc>().add(ApproveAdsViewTask(task, globalRate)); // ✅ preserved
                            },
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              elevation: 0,
                            ),
                            onPressed: () {
                              setState(() => _processingTasks.add(task.id));
                              context.read<AdsViewBloc>().add(RejectAdsViewTask(task)); // ✅ preserved
                            },
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Paid ৳${task.amount.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // TASK 2: Proof image thumbnail widget
  Widget _buildProofThumbnail(BuildContext context, String? imageUrl) {
    return GestureDetector(
      onTap: imageUrl != null && imageUrl.isNotEmpty ? () => _showFullScreenImage(context, imageUrl) : null,
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey[100],
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: imageUrl != null && imageUrl.isNotEmpty
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
                      },
                      errorBuilder: (_, e, s) => Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 28),
                    ),
                    // Zoom hint overlay
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(6)),
                        ),
                        child: const Icon(Icons.zoom_in, color: Colors.white, size: 12),
                      ),
                    ),
                  ],
                )
              : Icon(Icons.image_not_supported_outlined, color: Colors.grey[400], size: 28),
        ),
      ),
    );
  }
}
