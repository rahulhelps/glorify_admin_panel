import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../features/users/presentation/bloc/user_management_bloc.dart';
import '../../../features/users/presentation/screens/user_details_screen.dart';

// ── Section screens ───────────────────────────────────────────────────────────
import '../../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../../features/premium_verify/presentation/screens/premium_verification_screen.dart';
import '../../../features/refer_checker/presentation/pages/refer_checker_screen.dart';
import '../../../features/withdrawal/presentation/screens/withdrawal_screen.dart';
import '../../../features/micro_jobs/presentation/screens/global_micro_job_hub_screen.dart';
import '../../../features/drive_offers/presentation/screens/drive_offers_screen.dart';
import '../../../features/drive_requests/presentation/screens/drive_requests_screen.dart';
import '../../../features/recharge_requests/presentation/screens/recharge_requests_screen.dart';
import '../../../features/notifications/presentation/screens/notification_manager_screen.dart';
import '../../../features/home_notice/presentation/screens/home_notice_config_screen.dart';
import '../../../features/app_updates/presentation/screens/app_updates_management_screen.dart';
import '../../../features/app_limits/presentation/screens/app_limits_screen.dart';
import '../../../features/subscription/presentation/screens/subscription_screen.dart';

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
      icon: Icons.money_off_outlined,
      activeIcon: Icons.money_off,
      label: 'Withdrawals',
      section: 'Withdrawals',
      badgeKey: 'pendingWithdrawals',
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
      icon: Icons.local_offer_outlined,
      activeIcon: Icons.local_offer,
      label: 'Drive Offers',
      section: 'Drive Offers',
    ),
  ],
  'Requests': [
    _NavDestination(
      icon: Icons.electrical_services_outlined,
      activeIcon: Icons.electrical_services,
      label: 'Drive Requests',
      section: 'Drive Requests',
    ),
    _NavDestination(
      icon: Icons.bolt_outlined,
      activeIcon: Icons.bolt,
      label: 'Recharge Requests',
      section: 'Recharge Requests',
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
    _NavDestination(
      icon: Icons.card_membership_outlined,
      activeIcon: Icons.card_membership,
      label: 'Subscription',
      section: 'Subscription',
    ),
  ],
};

// Flat ordered list for IndexedStack
final List<_NavDestination> _kAllDestinations = [
  ..._kSections['Home']!,
  ..._kSections['Users']!,
  ..._kSections['Finance']!,
  ..._kSections['Content']!,
  ..._kSections['Requests']!,
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

  Widget _getScreenForSection(String section) {
    switch (section) {
      case 'Dashboard':
        return const DashboardScreen();
      case 'Premium Verify':
        return const PremiumVerificationScreen();
      case 'Refer Checker':
        return const ReferCheckerScreen();
      case 'Withdrawals':
        return const WithdrawalScreen();
      case 'Micro Jobs':
        return const GlobalMicroJobHubScreen();
      case 'Drive Offers':
        return const DriveOffersScreen();
      case 'Drive Requests':
        return const DriveRequestsScreen();
      case 'Recharge Requests':
        return const RechargeRequestsScreen();
      case 'Notifications':
        return const NotificationManagerScreen();
      case 'Home Notice':
        return const HomeNoticeConfigScreen();
      case 'App Updates':
        return const AppUpdatesManagementScreen();
      case 'App Limits':
        return const AppLimitsScreen();
      case 'Subscription':
        return const SubscriptionScreen();
      default:
        return const DashboardScreen();
    }
  }

  /// Navigate to a named section.
  void navigateTo(String section) {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
    if (section == 'Dashboard' || section == 'Home') {
      setState(() => _selectedIndex = 0);
      return;
    }
    final dest = _kAllDestinations.firstWhere(
      (d) => d.section == section || d.label == section,
      orElse: () => _kAllDestinations.first,
    );
    if (dest.section != 'Dashboard') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _getScreenForSection(dest.section),
        ),
      );
    }
  }

  int _getBadgeCount(DashboardState dashState, String? key) {
    if (key == null || dashState is! DashboardLoaded) return 0;
    switch (key) {
      case 'pendingWithdrawals':
        return dashState.pendingWithdrawals;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // ── Global user search result listener ──
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
              if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                Navigator.of(context).pop();
              }
              if (dest.section == 'Dashboard') {
                setState(() => _selectedIndex = 0);
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _getScreenForSection(dest.section),
                  ),
                );
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
    return Column(
      children: [
        _buildTopBar(context, isWide, 'Dashboard'),
        const Expanded(
          child: DashboardScreen(),
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
