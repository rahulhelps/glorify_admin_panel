import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/dashboard_bloc.dart';
import '../../../../features/users/presentation/bloc/user_management_bloc.dart';
import 'verified_users_summary_screen.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/presentation/widgets/admin_shell.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DashboardScreen — content widget only (no Scaffold; lives inside AdminShell)
// ─────────────────────────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(SubscribeToCounts());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchCtrl.text.trim();
    if (query.isNotEmpty) {
      context.read<UserManagementBloc>().add(SearchUserEvent(query));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildWelcomeBanner(),
              const SizedBox(height: AppSpacing.md),
              _buildInlineSearch(),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionTitle('Overview'),
              const SizedBox(height: AppSpacing.md),
              if (state is DashboardLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (state is DashboardLoaded)
                _buildKpiGrid(context, state)
              else
                const SizedBox(),
              const SizedBox(height: AppSpacing.xl),
              _buildSectionTitle('Quick Navigation'),
              const SizedBox(height: AppSpacing.md),
              _buildQuickNavGrid(context),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }

  // ── Welcome banner ─────────────────────────────────────────────────────────
  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.lgAll,
        boxShadow: AppShadows.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, Admin 👋',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Here\'s what\'s happening with Glorify Digital today.',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.admin_panel_settings, color: AppColors.primary, size: 32),
          ),
        ],
      ),
    );
  }

  // ── Inline search ──────────────────────────────────────────────────────────
  Widget _buildInlineSearch() {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Search user by Email, Phone, UID or Refer Code...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.textHint),
                ),
                onSubmitted: (_) => _performSearch(),
              ),
            ),
            ElevatedButton(
              onPressed: _performSearch,
              child: const Text('Search'),
            ),
          ],
        ),
      ),
    );
  }

  // ── KPI Card Grid ──────────────────────────────────────────────────────────
  Widget _buildKpiGrid(BuildContext context, DashboardLoaded state) {
    final kpis = [
      _KpiData(
        label: 'Total Users',
        count: state.totalUsers,
        icon: Icons.people_alt_rounded,
        color: const Color(0xFF3B82F6),
        section: 'Dashboard',
        isAlert: false,
        onTapOverride: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const VerifiedUsersSummaryScreen()));
        },
      ),
      _KpiData(
        label: 'Verified Members',
        count: state.verifiedUsers,
        icon: Icons.verified_rounded,
        color: AppColors.primary,
        section: 'Premium Verify',
        isAlert: false,
        onTapOverride: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const VerifiedUsersSummaryScreen()));
        },
      ),
      _KpiData(
        label: 'Pending Withdrawals',
        count: state.pendingWithdrawals,
        icon: Icons.money_off_rounded,
        color: AppColors.withdrawal,
        section: 'Withdrawals',
        isAlert: state.pendingWithdrawals > 0,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: kpis.length,
      itemBuilder: (ctx, i) => _KpiCard(
        data: kpis[i],
        onTap: kpis[i].onTapOverride ?? () => AdminShell.of(context)?.navigateTo(kpis[i].section),
      ),
    );
  }

  // ── Quick nav tiles ────────────────────────────────────────────────────────
  Widget _buildQuickNavGrid(BuildContext context) {
    final tiles = [
      _QuickNavTile('Withdrawals', Icons.money_off, AppColors.withdrawal, 'Withdrawals'),
      _QuickNavTile('Micro Jobs', Icons.work_history_rounded, const Color(0xFF0EA5E9), 'Micro Jobs'),
      _QuickNavTile('Home Notice', Icons.campaign, AppColors.warning, 'Home Notice'),
      _QuickNavTile('Premium Verify', Icons.verified_user, AppColors.primary, 'Premium Verify'),
      _QuickNavTile('Refer Checker', Icons.group_add, const Color(0xFF10B981), 'Refer Checker'),
      _QuickNavTile('Drive Offers', Icons.local_offer, const Color(0xFFF97316), 'Drive Offers'),
      _QuickNavTile('Drive Requests', Icons.electrical_services, const Color(0xFFEAB308), 'Drive Requests'),
      _QuickNavTile('Recharge Requests', Icons.bolt, const Color(0xFF06B6D4), 'Recharge Requests'),
      _QuickNavTile('Notifications', Icons.notifications_active, AppColors.warning, 'Notifications'),
      _QuickNavTile('App Updates', Icons.system_update_alt, AppColors.info, 'App Updates'),
      _QuickNavTile('App Limits', Icons.rule, const Color(0xFF64748B), 'App Limits'),
      _QuickNavTile('Subscription', Icons.card_membership, AppColors.subscription, 'Subscription'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final double childAspectRatio = constraints.maxWidth >= 900
            ? 2.4
            : (constraints.maxWidth >= 600 ? 1.8 : 1.3);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: tiles.length,
          itemBuilder: (ctx, i) => _QuickNavCard(
            tile: tiles[i],
            onTap: () => AdminShell.of(context)?.navigateTo(tiles[i].section),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI Card data model
// ─────────────────────────────────────────────────────────────────────────────
class _KpiData {
  const _KpiData({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.section,
    required this.isAlert,
    this.onTapOverride,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final String section;
  final bool isAlert;
  final VoidCallback? onTapOverride;
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI Card widget
// ─────────────────────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data, required this.onTap});

  final _KpiData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.lgAll,
            border: Border.all(
              color: data.isAlert ? data.color.withOpacity(0.4) : AppColors.border,
              width: data.isAlert ? 1.5 : 1,
            ),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: data.color.withOpacity(0.1),
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Icon(data.icon, color: data.color, size: 20),
                  ),
                  if (data.isAlert)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: AppRadius.smAll,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.circle, color: AppColors.error, size: 6),
                          const SizedBox(width: 4),
                          Text(
                            'Action',
                            style: GoogleFonts.inter(
                              color: AppColors.error,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${data.count}',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: data.isAlert ? data.color : AppColors.textPrimary,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick nav tile model
// ─────────────────────────────────────────────────────────────────────────────
class _QuickNavTile {
  const _QuickNavTile(this.label, this.icon, this.color, this.section);
  final String label;
  final IconData icon;
  final Color color;
  final String section;
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick nav card
// ─────────────────────────────────────────────────────────────────────────────
class _QuickNavCard extends StatelessWidget {
  const _QuickNavCard({required this.tile, required this.onTap});

  final _QuickNavTile tile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: tile.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(tile.icon, color: tile.color, size: 18),
              ),
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  tile.label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
