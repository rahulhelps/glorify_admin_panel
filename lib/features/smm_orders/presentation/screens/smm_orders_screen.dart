import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/smm_order_bloc.dart';
import '../../data/models/smm_order_model.dart';
import 'smm_order_detail_screen.dart';
import '../../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SmmOrdersScreen — content widget only (no Scaffold; lives inside AdminShell)
// All Bloc events preserved:
//   LoadSmmOrders()   — initState
// Local search/filter state preserved (setState only, no Bloc)
// Navigator.push(SmmOrderDetailScreen) preserved for drill-downs
// ─────────────────────────────────────────────────────────────────────────────
class SmmOrdersScreen extends StatefulWidget {
  const SmmOrdersScreen({super.key});

  @override
  State<SmmOrdersScreen> createState() => _SmmOrdersScreenState();
}

class _SmmOrdersScreenState extends State<SmmOrdersScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String _selectedPlatform = 'All';
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<SmmOrderBloc>().add(LoadSmmOrders()); // ✅ preserved
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<SmmOrderModel> _filterOrders(List<SmmOrderModel> orders,
      {bool applyPlatformFilter = false}) {
    return orders.where((order) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesEmail = order.email.toLowerCase().contains(query);
        final matchesName = order.userName.toLowerCase().contains(query);
        final matchesUid = order.uid.toLowerCase().contains(query);
        if (!matchesEmail && !matchesName && !matchesUid) return false;
      }
      if (applyPlatformFilter && _selectedPlatform != 'All') {
        if (order.type.toLowerCase() != _selectedPlatform.toLowerCase()) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Search bar ───────────────────────────────────────────────────────
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search by Email, Name, or UID…',
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      onPressed: () => setState(() {
                        _searchCtrl.clear();
                        _searchQuery = '';
                      }),
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surfaceVariant,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: AppRadius.lgAll,
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.lgAll,
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.lgAll,
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        // ── Tab bar ──────────────────────────────────────────────────────────
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.pending_actions, size: 16), text: 'Active Requests'),
              Tab(icon: Icon(Icons.history, size: 16), text: 'Action History'),
            ],
          ),
        ),
        // ── Content ──────────────────────────────────────────────────────────
        Expanded(
          child: BlocBuilder<SmmOrderBloc, SmmOrderState>(
            builder: (context, state) {
              if (state is SmmOrderLoading) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              } else if (state is SmmOrderErrorState) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      'Error: ${state.errorMessage}',
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                );
              } else if (state is SmmOrderLoaded) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildActiveTab(state.pendingOrders),
                    _buildHistoryTab(state.historyOrders),
                  ],
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTab(List<SmmOrderModel> allPending) {
    final filtered = _filterOrders(allPending, applyPlatformFilter: true);
    return Column(
      children: [
        _buildPlatformChips(),
        Expanded(child: _buildOrderList(filtered, isActive: true)),
      ],
    );
  }

  Widget _buildHistoryTab(List<SmmOrderModel> allHistory) {
    final filtered = _filterOrders(allHistory, applyPlatformFilter: false);
    return _buildOrderList(filtered, isActive: false);
  }

  Widget _buildPlatformChips() {
    final platforms = ['All', 'Gmail', 'Facebook', 'Instagram'];
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      color: AppColors.surface,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: platforms.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final p = platforms[i];
          final sel = _selectedPlatform == p;
          return Center(
            child: ChoiceChip(
              label: Text(p),
              selected: sel,
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              backgroundColor: AppColors.surfaceVariant,
              labelStyle: TextStyle(
                color: sel ? AppColors.primary : AppColors.textSecondary,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                fontSize: 12,
              ),
              side: BorderSide(color: sel ? AppColors.primary : AppColors.border),
              onSelected: (v) {
                if (v) setState(() => _selectedPlatform = p);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderList(List<SmmOrderModel> orders, {required bool isActive}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 56, color: AppColors.border),
            const SizedBox(height: AppSpacing.md),
            Text(
              isActive ? 'No pending requests.' : 'No action history.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: orders.length,
      itemBuilder: (context, index) => _buildOrderCard(orders[index], isActive: isActive),
    );
  }

  Widget _buildOrderCard(SmmOrderModel order, {required bool isActive}) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: isActive
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SmmOrderDetailScreen(order: order)), // ✅ preserved
                )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              _PlatformBadge(type: order.type),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.userName.isNotEmpty ? order.userName : 'Unknown User',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isActive) _StatusBadge(status: order.status),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('${order.email}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      isActive
                          ? 'Submitted: ${order.submittedAt != null ? DateFormat('MMM dd, yyyy – hh:mm a').format(order.submittedAt!) : 'Unknown'}'
                          : 'Reviewed: ${order.reviewedAt != null ? DateFormat('MMM dd, yyyy – hh:mm a').format(order.reviewedAt!) : 'Unknown'}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                    ),
                    if (!isActive && order.adminNote.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: AppRadius.smAll,
                        ),
                        child: Text(
                          'Note: ${order.adminNote}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isActive)
                const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlatformBadge extends StatelessWidget {
  const _PlatformBadge({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (type.toLowerCase()) {
      case 'gmail':
        color = Colors.redAccent;
        icon = Icons.email_rounded;
        break;
      case 'facebook':
        color = Colors.blue;
        icon = Icons.facebook_rounded;
        break;
      case 'instagram':
        color = Colors.purpleAccent;
        icon = Icons.camera_alt_rounded;
        break;
      default:
        color = AppColors.textSecondary;
        icon = Icons.language_rounded;
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final isApproved = status.toLowerCase() == 'approved';
    final color = isApproved ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.smAll,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(status.toUpperCase(),
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}
