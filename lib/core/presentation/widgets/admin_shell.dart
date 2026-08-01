import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../features/users/presentation/bloc/user_management_bloc.dart';
import '../../../features/users/presentation/screens/user_details_screen.dart';

// ── Section screens ───────────────────────────────────────────────────────────
import '../../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../../features/subscription/presentation/screens/subscription_screen.dart';
import '../../../features/subscription/presentation/screens/premium_verification_screen.dart';
import '../../../features/deposit/presentation/screens/deposit_screen.dart';
import '../../../features/withdrawal/presentation/screens/withdrawal_screen.dart';
import '../../../features/smm_orders/presentation/screens/smm_orders_screen.dart';
import '../../../features/smm_notices/presentation/screens/smm_notices_config_screen.dart';
import '../../../features/micro_jobs/presentation/screens/global_micro_job_hub_screen.dart';
import '../../../features/home_notice/presentation/screens/home_notice_config_screen.dart';
import '../../../features/refer_checker/presentation/pages/refer_checker_screen.dart';
import '../../../features/ads_views/presentation/screens/ads_view_screen.dart';
import '../../../features/ads_views/presentation/screens/ads_view_settings_screen.dart';
import '../../../features/notifications/presentation/screens/notification_manager_screen.dart';
import '../../../features/app_updates/presentation/screens/app_updates_management_screen.dart';
import '../../../features/app_limits/presentation/screens/app_limits_screen.dart';

import '../../theme/app_theme.dart';
import 'admin_nav_item.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Navigation destination model
// ─────────────────────────────────────────────────────────────────────────────
class _NavDestination {
  const _NavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.section,
    this.badgeKey,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String section;
  final String? badgeKey; // key into DashboardLoaded pending counts
}

// ─────────────────────────────────────────────────────────────────────────────
// Navigation sections
// ─────────────────────────────────────────────────────────────────────────────
const _kSections = <String, List<_NavDestination>>{
  'Home': [
    _NavDestination(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
      section: 'Dashboard',
    ),
  ],
  'Users': [
    _NavDestination(
      icon: Icons.verified_user_outlined,
      activeIcon: Icons.verified_user,
      label: 'Premium Verify',
      section: 'Premium Verify',
    ),
    _NavDestination(
      icon: Icons.group_add_outlined,
      activeIcon: Icons.group_add,
      label: 'Refer Checker',
      section: 'Refer Checker',
    ),
  ],
  'Finance': [
    _NavDestination(
      icon: Icons.card_membership_outlined,
      activeIcon: Icons.card_membership,
      label: 'Subscriptions',
      section: 'Subscriptions',
      badgeKey: 'pendingSubscriptions',
    ),
    _NavDestination(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet,
      label: 'Deposits',
      section: 'Deposits',
      badgeKey: 'pendingDeposits',
    ),
    _NavDestination(
      icon: Icons.money_off_outlined,
      activeIcon: Icons.money_off,
      label: 'Withdrawals',
      section: 'Withdrawals',
      badgeKey: 'pendingWithdrawals',
    ),
  ],
  'SMM': [
    _NavDestination(
      icon: Icons.shopping_cart_outlined,
      activeIcon: Icons.shopping_cart,
      label: 'SMM Orders',
      section: 'SMM Orders',
      badgeKey: 'pendingSmmOrders',
    ),
    _NavDestination(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'SMM Config',
      section: 'SMM Config',
    ),
  ],
  'Content': [
    _NavDestination(
      icon: Icons.work_history_outlined,
      activeIcon: Icons.work_history_rounded,
      label: 'Micro Jobs',
      section: 'Micro Jobs',
    ),
    _NavDestination(
      icon: Icons.ondemand_video_outlined,
      activeIcon: Icons.ondemand_video,
      label: 'Ads Views',
      section: 'Ads Views',
    ),
  ],
  'System': [
    _NavDestination(
      icon: Icons.notifications_active_outlined,
      activeIcon: Icons.notifications_active,
      label: 'Notifications',
      section: 'Notifications',
    ),
  ],
  'Settings': [
    _NavDestination(
      icon: Icons.campaign_outlined,
      activeIcon: Icons.campaign,
      label: 'Home Notice',
      section: 'Home Notice',
    ),
    _NavDestination(
      icon: Icons.smart_toy_outlined,
      activeIcon: Icons.smart_toy,
      label: 'Ads Settings',
      section: 'Ads Settings',
    ),
    _NavDestination(
      icon: Icons.system_update_alt_outlined,
      activeIcon: Icons.system_update_alt,
      label: 'App Updates',
      section: 'App Updates',
    ),
    _NavDestination(
      icon: Icons.rule_outlined,
      activeIcon: Icons.rule,
      label: 'App Limits',
      section: 'App Limits',
    ),
  ],
};

// Flat ordered list for IndexedStack
final List<_NavDestination> _kAllDestinations = [
  ..._kSections['Home']!,
  ..._kSections['Users']!,
  ..._kSections['Finance']!,
  ..._kSections['SMM']!,
  ..._kSections['Content']!,
  ..._kSections['System']!,
  ..._kSections['Settings']!,
];

// ─────────────────────────────────────────────────────────────────────────────
// AdminShell
// ─────────────────────────────────────────────────────────────────────────────
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => AdminShellState();

  /// Allow child widgets to navigate to a section by label.
  static AdminShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<AdminShellState>();
}

class AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Initialise each section widget once (IndexedStack keeps them alive).
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DashboardScreen(),        // 0  Dashboard
      const PremiumVerificationScreen(), // 1 Premium Verify
      const ReferCheckerScreen(),      // 2  Refer Checker
      const SubscriptionScreen(),      // 3  Subscriptions
      const DepositScreen(),           // 4  Deposits
      const WithdrawalScreen(),        // 5  Withdrawals
      const SmmOrdersScreen(),         // 6  SMM Orders
      const SmmNoticesConfigScreen(),  // 7  SMM Config
      const GlobalMicroJobHubScreen(), // 8  Micro Jobs
      const AdsViewsScreen(),          // 9  Ads Views
      const NotificationManagerScreen(), // 10 Notifications
      const HomeNoticeConfigScreen(),  // 11 Home Notice
      const AdsViewSettingsScreen(),   // 12 Ads Settings
      const AppUpdatesManagementScreen(), // 13 App Updates
      const AppLimitsScreen(),         // 14 App Limits
    ];
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Navigate to a named section.
  void navigateTo(String section) {
    final idx = _kAllDestinations.indexWhere((d) => d.section == section);
    if (idx >= 0) setState(() => _selectedIndex = idx);
  }

  int _getBadgeCount(DashboardState dashState, String? key) {
    if (key == null || dashState is! DashboardLoaded) return 0;
    switch (key) {
      case 'pendingSubscriptions':
        return dashState.pendingSubscriptions;
      case 'pendingDeposits':
        return dashState.pendingDeposits;
      case 'pendingWithdrawals':
        return dashState.pendingWithdrawals;
      case 'pendingSmmOrders':
        return dashState.pendingSmmOrders;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // ── Global user search result listener (moved from DashboardScreen) ──
        BlocListener<UserManagementBloc, UserManagementState>(
          listener: (context, state) {
            if (state is UserSearchFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
              );
            } else if (state is UserSearchSuccess) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserDetailsScreen(initialUser: state.user),
                ),
              );
              // Exact same reset call as the old dashboard:
              context.read<UserManagementBloc>().add(ResetSearchEvent());
            }
          },
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppColors.background,
            drawer: isWide ? null : _buildDrawer(context),
            body: Row(
              children: [
                if (isWide) _buildSidebar(context),
                Expanded(
                  child: SafeArea(
                    child: _buildMain(context, isWide),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Sidebar (wide screens) ─────────────────────────────────────────────────
  Widget _buildSidebar(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, dashState) {
        return Container(
          width: 220,
          decoration: const BoxDecoration(
            color: AppColors.sidebarBg,
            border: Border(right: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSidebarHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: _buildNavItems(context, dashState, isExpanded: true),
                ),
              ),
              _buildSidebarFooter(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xl, AppSpacing.md, AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Golden Power',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Admin Panel',
                  style: GoogleFonts.inter(
                    color: AppColors.sidebarSectionLabel,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItems(BuildContext context, DashboardState dashState, {required bool isExpanded}) {
    final widgets = <Widget>[];
    int flatIndex = 0;

    for (final entry in _kSections.entries) {
      widgets.add(AdminNavSectionLabel(label: entry.key, isExpanded: isExpanded));
      for (final dest in entry.value) {
        final idx = flatIndex;
        final badge = _getBadgeCount(dashState, dest.badgeKey);
        widgets.add(
          AdminNavItem(
            icon: dest.icon,
            label: dest.label,
            isSelected: _selectedIndex == idx,
            badgeCount: badge > 0 ? badge : null,
            isExpanded: isExpanded,
            onTap: () {
              setState(() => _selectedIndex = idx);
              if (Scaffold.of(context).isDrawerOpen || !isExpanded) {
                Navigator.of(context).pop();
              }
            },
          ),
        );
        flatIndex++;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }

  Widget _buildSidebarFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF243144))),
      ),
      child: InkWell(
        onTap: () => _showLogoutDialog(context),
        borderRadius: AppRadius.mdAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Logout',
                style: GoogleFonts.inter(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Drawer (narrow/mobile) ─────────────────────────────────────────────────
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.sidebarBg,
      width: 240,
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, dashState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DrawerHeader(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
                decoration: const BoxDecoration(color: AppColors.sidebarBg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Golden Power Admin', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                    Text('Management Panel', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildNavItems(context, dashState, isExpanded: true),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showLogoutDialog(context);
                  },
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  label: const Text('Logout'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Main content area ──────────────────────────────────────────────────────
  Widget _buildMain(BuildContext context, bool isWide) {
    final currentDest = _kAllDestinations[_selectedIndex];

    return Column(
      children: [
        _buildTopBar(context, isWide, currentDest.label),
        Expanded(
          child: IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, bool isWide, String pageTitle) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          // Hamburger on mobile
          if (!isWide) ...[
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.textSecondary),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              tooltip: 'Menu',
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          // Page title
          Text(
            pageTitle,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          // Logout button
          Tooltip(
            message: 'Logout',
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, size: 20),
              color: AppColors.textSecondary,
              onPressed: () => _showLogoutDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  // ── Logout dialog ──────────────────────────────────────────────────────────
  void _showLogoutDialog(BuildContext context) {
    // Exact same Bangla text + AuthBloc.add(LogoutRequested()) as original dashboard:
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('লগআউট করবেন?'),
        content: const Text('আপনি কি নিশ্চিত যে লগআউট করতে চান?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(LogoutRequested());
            },
            child: const Text('লগআউট'),
          ),
        ],
      ),
    );
  }
}
