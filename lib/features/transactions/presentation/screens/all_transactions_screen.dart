import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/transaction_invoice_model.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedStatusFilter = 'All'; // 'All', 'Pending', 'Completed', 'Rejected'

  // Cache to avoid refetching user data for UIDs multiple times
  static final Map<String, Map<String, String>> _userCache = {};

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      final query = _searchController.text.trim().toLowerCase();
      if (query != _searchQuery) {
        setState(() {
          _searchQuery = query;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Stream builder helper ──────────────────────────────────────────────────
  Stream<List<TransactionInvoiceModel>> _getInvoicesStream(
      String collectionName, String invoiceType) {
    return _firestore
        .collection(collectionName)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return TransactionInvoiceModel.fromFirestore(doc, invoiceType: invoiceType);
      }).toList();

      // Sort by createdAt descending in memory (handles missing/varying timestamp keys safely)
      list.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return list;
    });
  }

  // ── Filter transactions by search query ───────────────────────────────────
  List<TransactionInvoiceModel> _filterBySearch(List<TransactionInvoiceModel> list) {
    if (_searchQuery.isEmpty) return list;

    return list.where((item) {
      final email = item.userEmail.toLowerCase();
      final phone = item.userPhone.toLowerCase();
      final name = item.userName.toLowerCase();
      final uid = item.uid.toLowerCase();
      final trxId = item.transactionId.toLowerCase();
      final docId = item.id.toLowerCase();

      // Check cached user info if available
      final cached = _userCache[item.uid];
      final cachedEmail = cached?['email']?.toLowerCase() ?? '';
      final cachedPhone = cached?['phone']?.toLowerCase() ?? '';
      final cachedName = cached?['name']?.toLowerCase() ?? '';

      return email.contains(_searchQuery) ||
          phone.contains(_searchQuery) ||
          name.contains(_searchQuery) ||
          uid.contains(_searchQuery) ||
          trxId.contains(_searchQuery) ||
          docId.contains(_searchQuery) ||
          cachedEmail.contains(_searchQuery) ||
          cachedPhone.contains(_searchQuery) ||
          cachedName.contains(_searchQuery);
    }).toList();
  }

  // ── Filter transactions by status ──────────────────────────────────────────
  List<TransactionInvoiceModel> _filterByStatus(List<TransactionInvoiceModel> list) {
    if (_selectedStatusFilter == 'All') return list;

    final targetStatus = _selectedStatusFilter.toLowerCase();
    return list.where((item) {
      if (targetStatus == 'pending') {
        return item.isPending;
      } else if (targetStatus == 'completed') {
        return item.isCompleted;
      } else if (targetStatus == 'rejected' || targetStatus == 'failed') {
        return item.isFailed;
      } else {
        return item.normalizedStatus.toLowerCase() == targetStatus ||
            item.status.toLowerCase() == targetStatus;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('All Transactions'),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header Controls (Search & Filter) ──────────────────────────────
          _buildHeaderControls(),

          // ── Tab Bar ────────────────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
              unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
              tabs: const [
                Tab(
                  icon: Icon(Icons.account_balance_wallet_outlined, size: 20),
                  text: 'Deposit',
                ),
                Tab(
                  icon: Icon(Icons.card_membership_outlined, size: 20),
                  text: 'Subscriptions',
                ),
              ],
            ),
          ),

          // ── Tab Views ──────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionStreamView(
                  collectionName: 'deposit_invoices',
                  invoiceType: 'Deposit',
                  icon: Icons.south_west_rounded,
                  themeColor: AppColors.deposit,
                ),
                _buildTransactionStreamView(
                  collectionName: 'payment_invoices',
                  invoiceType: 'Subscription',
                  icon: Icons.north_east_rounded,
                  themeColor: AppColors.subscription,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header controls widget (Search + Dropdown) ─────────────────────────────
  Widget _buildHeaderControls() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Search input field
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by email, phone, UID, or TrxID...',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textHint),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textHint),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textSecondary),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    fillColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.mdAll,
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.mdAll,
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.mdAll,
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Filter Dropdown
              Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                  borderRadius: AppRadius.mdAll,
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStatusFilter,
                    icon: const Icon(Icons.filter_list_rounded, size: 18, color: AppColors.textSecondary),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'All',
                        child: Row(
                          children: [
                            Icon(Icons.list_alt_rounded, size: 16, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text('All Status'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Pending',
                        child: Row(
                          children: [
                            Icon(Icons.hourglass_top_rounded, size: 16, color: AppColors.warning),
                            SizedBox(width: 8),
                            Text('Pending'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Completed',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.success),
                            SizedBox(width: 8),
                            Text('Completed'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Rejected',
                        child: Row(
                          children: [
                            Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Rejected'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedStatusFilter = val;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stream tab view ────────────────────────────────────────────────────────
  Widget _buildTransactionStreamView({
    required String collectionName,
    required String invoiceType,
    required IconData icon,
    required Color themeColor,
  }) {
    return StreamBuilder<List<TransactionInvoiceModel>>(
      stream: _getInvoicesStream(collectionName, invoiceType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Failed to load $invoiceType invoices',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        final rawList = snapshot.data ?? [];
        if (rawList.isEmpty) {
          return _buildEmptyState(
            title: 'No $invoiceType Invoices Found',
            subtitle: 'There are no records in the "$collectionName" collection yet.',
            icon: Icons.receipt_long_outlined,
          );
        }

        // 1. Search filter first to compute accurate summary metrics for current search
        final searchFilteredList = _filterBySearch(rawList);

        // Calculate summary metrics
        final totalAmount = searchFilteredList.fold<double>(0.0, (acc, i) => acc + i.amount);
        final totalCount = searchFilteredList.length;
        final completedCount = searchFilteredList.where((i) => i.isCompleted).length;
        final pendingCount = searchFilteredList.where((i) => i.isPending).length;
        final rejectedCount = searchFilteredList.where((i) => i.isFailed).length;

        // 2. Status filter for displayed list
        final displayedList = _filterByStatus(searchFilteredList);

        if (displayedList.isEmpty) {
          return Column(
            children: [
              _buildSummaryRibbon(
                totalCount: totalCount,
                totalAmount: totalAmount,
                completedCount: completedCount,
                pendingCount: pendingCount,
                rejectedCount: rejectedCount,
                themeColor: themeColor,
              ),
              Expanded(
                child: _buildEmptyState(
                  title: 'No Matching Transactions',
                  subtitle: _selectedStatusFilter != 'All'
                      ? 'No transactions found with status "$_selectedStatusFilter".'
                      : 'No records matched your search query "$_searchQuery".',
                  icon: Icons.search_off_rounded,
                  actionButton: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedStatusFilter = 'All';
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Reset All Filters'),
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            // ── Interactive Summary Ribbon ───────────────────────────────────
            _buildSummaryRibbon(
              totalCount: totalCount,
              totalAmount: totalAmount,
              completedCount: completedCount,
              pendingCount: pendingCount,
              rejectedCount: rejectedCount,
              themeColor: themeColor,
            ),

            // ── Transactions List ────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: displayedList.length,
                itemBuilder: (context, index) {
                  final transaction = displayedList[index];

                  // In-item filter validation guard
                  final status = transaction.normalizedStatus.toLowerCase();
                  final filter = _selectedStatusFilter.toLowerCase();
                  if (filter != 'all' && filter != status) {
                    if (filter == 'completed' && !transaction.isCompleted) return const SizedBox.shrink();
                    if (filter == 'pending' && !transaction.isPending) return const SizedBox.shrink();
                    if ((filter == 'rejected' || filter == 'failed') && !transaction.isFailed) return const SizedBox.shrink();
                  }

                  return _TransactionCard(
                    transaction: transaction,
                    onTap: () => _showTransactionDetailsModal(context, transaction),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Summary Ribbon Widget (Interactive Chips) ──────────────────────────────
  Widget _buildSummaryRibbon({
    required int totalCount,
    required double totalAmount,
    required int completedCount,
    required int pendingCount,
    required int rejectedCount,
    required Color themeColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Total Volume (Informational summary)
            _buildSummaryMetric(
              label: 'Total Volume',
              value: '৳${totalAmount.toStringAsFixed(totalAmount.truncateToDouble() == totalAmount ? 0 : 2)}',
              icon: Icons.payments_rounded,
              color: themeColor,
              isSelected: false,
              isStaticBadge: true,
              onTap: null,
            ),
            const SizedBox(width: AppSpacing.sm + 4),

            // All / Total Records Chip
            _buildSummaryMetric(
              label: 'Total Records',
              value: '$totalCount',
              icon: Icons.receipt_rounded,
              color: AppColors.primary,
              isSelected: _selectedStatusFilter.toLowerCase() == 'all',
              onTap: () {
                setState(() {
                  _selectedStatusFilter = 'All';
                });
              },
            ),
            const SizedBox(width: AppSpacing.sm + 4),

            // Completed Chip
            _buildSummaryMetric(
              label: 'Completed',
              value: '$completedCount',
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
              isSelected: _selectedStatusFilter.toLowerCase() == 'completed',
              onTap: () {
                setState(() {
                  _selectedStatusFilter = 'Completed';
                });
              },
            ),
            const SizedBox(width: AppSpacing.sm + 4),

            // Pending Chip
            _buildSummaryMetric(
              label: 'Pending',
              value: '$pendingCount',
              icon: Icons.hourglass_bottom_rounded,
              color: AppColors.warning,
              isSelected: _selectedStatusFilter.toLowerCase() == 'pending',
              onTap: () {
                setState(() {
                  _selectedStatusFilter = 'Pending';
                });
              },
            ),

            // Rejected / Failed Chip (Always accessible for filtering)
            const SizedBox(width: AppSpacing.sm + 4),
            _buildSummaryMetric(
              label: 'Rejected',
              value: '$rejectedCount',
              icon: Icons.cancel_rounded,
              color: AppColors.error,
              isSelected: _selectedStatusFilter.toLowerCase() == 'rejected',
              onTap: () {
                setState(() {
                  _selectedStatusFilter = 'Rejected';
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Interactive Summary Metric Chip ────────────────────────────────────────
  Widget _buildSummaryMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isSelected,
    bool isStaticBadge = false,
    VoidCallback? onTap,
  }) {
    final activeBgColor = isSelected ? color : color.withValues(alpha: 0.08);
    final activeBorderColor = isSelected ? color : color.withValues(alpha: 0.25);
    final activeTextColor = isSelected ? Colors.white : AppColors.textSecondary;
    final activeValueColor = isSelected ? Colors.white : (color == AppColors.primary ? AppColors.textPrimary : color);
    final activeIconColor = isSelected ? Colors.white : color;

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: activeBgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: activeBorderColor,
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: activeIconColor),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: activeTextColor,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: activeValueColor,
            ),
          ),
          if (isSelected && !isStaticBadge) ...[
            const SizedBox(width: 4),
            const Icon(Icons.check_rounded, size: 12, color: Colors.white),
          ],
        ],
      ),
    );

    if (isStaticBadge || onTap == null) {
      return child;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: child,
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────
  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? actionButton,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.textHint),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            if (actionButton != null) ...[
              const SizedBox(height: AppSpacing.lg),
              actionButton,
            ],
          ],
        ),
      ),
    );
  }

  // ── Details Modal Bottom Sheet ─────────────────────────────────────────────
  void _showTransactionDetailsModal(
      BuildContext context, TransactionInvoiceModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TransactionDetailsModal(transaction: item),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Transaction Card Widget
// ─────────────────────────────────────────────────────────────────────────────
class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.transaction,
    required this.onTap,
  });

  final TransactionInvoiceModel transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Row: Amount & Status Badge ──────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getTypeColor(transaction.invoiceType).withValues(alpha: 0.12),
                          borderRadius: AppRadius.mdAll,
                        ),
                        child: Icon(
                          transaction.invoiceType.toLowerCase() == 'deposit'
                              ? Icons.account_balance_wallet_rounded
                              : Icons.card_membership_rounded,
                          size: 18,
                          color: _getTypeColor(transaction.invoiceType),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        transaction.formattedAmount,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  _TransactionStatusBadge(status: transaction.status),
                ],
              ),
              const Divider(height: 20, color: AppColors.divider),

              // ── User Information (Direct / Auto Resolved) ──────────────────
              _UserDetailSection(
                uid: transaction.uid,
                initialEmail: transaction.userEmail,
                initialPhone: transaction.userPhone,
                initialName: transaction.userName,
              ),

              const SizedBox(height: AppSpacing.sm),

              // ── Footer Row: Date & Payment Details ─────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Payment method / Trx ID
                  Expanded(
                    child: Row(
                      children: [
                        if (transaction.paymentMethod.isNotEmpty) ...[
                          _PaymentMethodTag(method: transaction.paymentMethod),
                          const SizedBox(width: 6),
                        ],
                        if (transaction.transactionId.isNotEmpty)
                          Flexible(
                            child: _CopyTag(
                              text: transaction.transactionId,
                              prefix: 'Trx: ',
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Timestamp
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        transaction.formattedDate,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    if (type.toLowerCase() == 'deposit') return AppColors.deposit;
    return AppColors.subscription;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User Detail Section (Resolves user info via uid if needed)
// ─────────────────────────────────────────────────────────────────────────────
class _UserDetailSection extends StatelessWidget {
  const _UserDetailSection({
    required this.uid,
    required this.initialEmail,
    required this.initialPhone,
    required this.initialName,
  });

  final String uid;
  final String initialEmail;
  final String initialPhone;
  final String initialName;

  @override
  Widget build(BuildContext context) {
    // If we already have email or phone, render directly
    if (initialEmail.isNotEmpty || initialPhone.isNotEmpty) {
      return _buildContent(
        email: initialEmail,
        phone: initialPhone,
        name: initialName,
        uid: uid,
      );
    }

    if (uid.isEmpty) {
      return const Text(
        'No User ID or Contact Info',
        style: TextStyle(fontSize: 12, color: AppColors.textHint),
      );
    }

    // If cached, return immediately
    if (_AllTransactionsScreenState._userCache.containsKey(uid)) {
      final cached = _AllTransactionsScreenState._userCache[uid]!;
      return _buildContent(
        email: cached['email'] ?? '',
        phone: cached['phone'] ?? '',
        name: cached['name'] ?? '',
        uid: uid,
      );
    }

    // Otherwise lookup from users collection
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Text(
                'Resolving UID: $uid',
                style: const TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ],
          );
        }

        String email = '';
        String phone = '';
        String name = '';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          email = data['email']?.toString() ?? '';
          phone = data['phone']?.toString() ?? '';
          name = data['name']?.toString() ?? '';

          _AllTransactionsScreenState._userCache[uid] = {
            'email': email,
            'phone': phone,
            'name': name,
          };
        }

        return _buildContent(email: email, phone: phone, name: name, uid: uid);
      },
    );
  }

  Widget _buildContent({
    required String email,
    required String phone,
    required String name,
    required String uid,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            if (name.isNotEmpty) ...[
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (email.isNotEmpty)
              Flexible(
                child: _CopyInlineText(text: email, icon: Icons.email_outlined),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (phone.isNotEmpty) ...[
              _CopyInlineText(text: phone, icon: Icons.phone_outlined),
              const SizedBox(width: 12),
            ],
            if (uid.isNotEmpty)
              Flexible(
                child: _CopyInlineText(
                  text: uid,
                  labelPrefix: 'UID: ',
                  icon: Icons.fingerprint_rounded,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline Copy Text Widget
// ─────────────────────────────────────────────────────────────────────────────
class _CopyInlineText extends StatelessWidget {
  const _CopyInlineText({
    required this.text,
    this.labelPrefix = '',
    this.icon,
  });

  final String text;
  final String labelPrefix;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied "$text" to clipboard'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: AppRadius.smAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: AppColors.textHint),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                '$labelPrefix$text',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.copy_rounded, size: 10, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment Method Tag
// ─────────────────────────────────────────────────────────────────────────────
class _PaymentMethodTag extends StatelessWidget {
  const _PaymentMethodTag({required this.method});
  final String method;

  @override
  Widget build(BuildContext context) {
    final m = method.toLowerCase();
    Color color = Colors.indigo;
    if (m.contains('bkash')) color = Colors.pink;
    if (m.contains('nagad')) color = Colors.orange;
    if (m.contains('rocket')) color = Colors.purple;
    if (m.contains('upay')) color = Colors.teal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        method.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Copy Tag (e.g. TrxID)
// ─────────────────────────────────────────────────────────────────────────────
class _CopyTag extends StatelessWidget {
  const _CopyTag({required this.text, this.prefix = ''});
  final String text;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied "$text"'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                '$prefix$text',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.copy_rounded, size: 9, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Badge Widget
// ─────────────────────────────────────────────────────────────────────────────
class _TransactionStatusBadge extends StatelessWidget {
  const _TransactionStatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    Color bg;
    Color fg;
    IconData icon;

    if (s == 'completed' || s == 'approved' || s == 'success' || s == 'paid' || s == 'active') {
      bg = AppColors.successBg;
      fg = AppColors.success;
      icon = Icons.check_circle_rounded;
    } else if (s == 'pending' || s == 'processing' || s == 'initiated' || s == 'waiting') {
      bg = AppColors.warningBg;
      fg = AppColors.warning;
      icon = Icons.hourglass_top_rounded;
    } else {
      bg = AppColors.errorBg;
      fg = AppColors.error;
      icon = Icons.cancel_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.smAll,
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Details Modal Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _TransactionDetailsModal extends StatelessWidget {
  const _TransactionDetailsModal({required this.transaction});
  final TransactionInvoiceModel transaction;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${transaction.invoiceType} Invoice Details',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  _TransactionStatusBadge(status: transaction.status),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Document ID: ${transaction.id}',
                style: const TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
              const Divider(height: 24, color: AppColors.divider),

              // Overview Key-Values
              _buildDetailRow('Amount', transaction.formattedAmount, isBold: true),
              _buildDetailRow('Status', transaction.status),
              _buildDetailRow('Date', transaction.formattedDate),
              _buildDetailRow('User UID', transaction.uid, canCopy: true),
              if (transaction.userEmail.isNotEmpty)
                _buildDetailRow('User Email', transaction.userEmail, canCopy: true),
              if (transaction.userPhone.isNotEmpty)
                _buildDetailRow('User Phone', transaction.userPhone, canCopy: true),
              if (transaction.paymentMethod.isNotEmpty)
                _buildDetailRow('Payment Method', transaction.paymentMethod),
              if (transaction.transactionId.isNotEmpty)
                _buildDetailRow('Transaction / TrxID', transaction.transactionId, canCopy: true),

              const SizedBox(height: AppSpacing.md),
              Text(
                'Raw Document Fields',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Raw JSON viewer
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                  borderRadius: AppRadius.mdAll,
                  border: Border.all(color: AppColors.border),
                ),
                child: SelectableText(
                  const JsonEncoder.withIndent('  ').convert(
                    transaction.rawMap.map((key, value) {
                      if (value is Timestamp) {
                        return MapEntry(key, value.toDate().toIso8601String());
                      }
                      return MapEntry(key, value);
                    }),
                  ),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, bool canCopy = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (canCopy) ...[
                  const SizedBox(width: 6),
                  Builder(
                    builder: (ctx) => InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: value));
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Copied "$value"')),
                        );
                      },
                      child: const Icon(Icons.copy_rounded, size: 13, color: AppColors.primary),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
