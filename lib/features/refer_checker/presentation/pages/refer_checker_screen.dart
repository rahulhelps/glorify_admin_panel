import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/refer_checker_repository.dart';
import '../bloc/refer_checker_bloc.dart';
import '../bloc/refer_checker_event.dart';
import '../bloc/refer_checker_state.dart';
import '../widgets/referral_item_card.dart';
import '../widgets/referral_metric_card.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/subscription_helper.dart';
import '../../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ReferCheckerScreen — content widget only (no Scaffold; lives inside AdminShell)
// All Bloc events preserved:
//   SearchMasterUserEvent(query)                        — search bar
//   FilterReferralsEvent(filter, {customDate})          — filter chips
// ─────────────────────────────────────────────────────────────────────────────
class ReferCheckerScreen extends StatelessWidget {
  const ReferCheckerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReferCheckerBloc(repository: ReferCheckerRepository()),
      child: const _ReferCheckerView(),
    );
  }
}

class _ReferCheckerView extends StatefulWidget {
  const _ReferCheckerView();

  @override
  State<_ReferCheckerView> createState() => _ReferCheckerViewState();
}

class _ReferCheckerViewState extends State<_ReferCheckerView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    FocusScope.of(context).unfocus();
    final query = _searchController.text;
    if (query.isNotEmpty) {
      context.read<ReferCheckerBloc>().add(SearchMasterUserEvent(query)); // ✅ preserved
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Search bar ───────────────────────────────────────────────────────
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Email, Phone, or Refer Code…',
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                onPressed: _onSearch,
              ),
            ),
            onSubmitted: (_) => _onSearch(),
          ),
        ),
        // ── Content ──────────────────────────────────────────────────────────
        Expanded(
          child: BlocBuilder<ReferCheckerBloc, ReferCheckerState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              if (state.hasSearched && state.masterUser == null) {
                return Center(
                  child: Text(
                    state.errorMessage.isNotEmpty ? state.errorMessage : 'কোনো ইউজার খুঁজে পাওয়া যায়নি',
                    style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                  ),
                );
              }
              if (state.masterUser != null) {
                return _buildResults(state);
              }
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.manage_search_rounded, size: 64, color: AppColors.border),
                    const SizedBox(height: AppSpacing.md),
                    Text('Search for a user to view their referral tree.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResults(ReferCheckerState state) {
    final total = state.filteredReferrals.length;
    final verified = state.filteredReferrals
        .where((u) => isVerifiedStatus(u.subscriptionStatus))
        .length;
    final unverified = total - verified;

    return Column(
      children: [
        // Master user card
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  backgroundImage: state.masterUser!.profileImageUrl.isNotEmpty
                      ? NetworkImage(state.masterUser!.profileImageUrl)
                      : null,
                  child: state.masterUser!.profileImageUrl.isEmpty
                      ? const Icon(Icons.person_rounded, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(state.masterUser!.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      Text('Code: ${state.masterUser!.referCode}',
                          style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Metrics
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              ReferralMetricCard(title: 'Total Refers', count: total, icon: Icons.group_rounded),
              ReferralMetricCard(title: 'Verified', count: verified, icon: Icons.verified_user_rounded),
              ReferralMetricCard(title: 'Unverified', count: unverified, icon: Icons.person_off_rounded),
            ],
          ),
        ),

        // Filter chips
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('সব রেফার', ReferralFilter.all, state.currentFilter),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('আজকের রেফার', ReferralFilter.today, state.currentFilter),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('গতকালের রেফার', ReferralFilter.yesterday, state.currentFilter),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('গত ৭ দিন', ReferralFilter.last7Days, state.currentFilter),
                const SizedBox(width: AppSpacing.sm),
                _buildCustomDateChip(context, state),
              ],
            ),
          ),
        ),

        // List
        Expanded(
          child: state.filteredReferrals.isEmpty
              ? Center(
                  child: Text('No referrals found for this filter.',
                      style: TextStyle(color: AppColors.textSecondary)),
                )
              : ListView.builder(
                  itemCount: state.filteredReferrals.length,
                  itemBuilder: (context, i) => ReferralItemCard(user: state.filteredReferrals[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, ReferralFilter filter, ReferralFilter currentFilter) {
    final isSelected = filter == currentFilter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        context.read<ReferCheckerBloc>().add(FilterReferralsEvent(filter)); // ✅ preserved
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
        fontSize: 12,
      ),
      backgroundColor: AppColors.surface,
      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
    );
  }

  Widget _buildCustomDateChip(BuildContext context, ReferCheckerState state) {
    final isSelected = state.currentFilter == ReferralFilter.custom;
    final label = isSelected && state.customDate != null
        ? DateFormat('dd MMM yyyy').format(state.customDate!)
        : 'তারিখ নির্বাচন';

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_month_rounded, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
      selected: isSelected,
      onSelected: (_) async {
        final date = await showDatePicker(
          context: context,
          initialDate: state.customDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (date != null && context.mounted) {
          context.read<ReferCheckerBloc>().add(FilterReferralsEvent(ReferralFilter.custom, customDate: date)); // ✅ preserved
        }
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
        fontSize: 12,
      ),
      backgroundColor: AppColors.surface,
      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
    );
  }
}
