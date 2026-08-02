import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';

class GlobalMicroJobHubScreen extends StatefulWidget {
  const GlobalMicroJobHubScreen({super.key});

  @override
  State<GlobalMicroJobHubScreen> createState() => _GlobalMicroJobHubScreenState();
}

class _GlobalMicroJobHubScreenState extends State<GlobalMicroJobHubScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String? _searchedUid;
  String _directSearchText = '';
  bool _isSearchingUser = false;
  bool _userNotFound = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchCtrl.text.trim();
    setState(() {
      _directSearchText = query.toLowerCase();
    });

    if (query.isEmpty) {
      setState(() {
        _searchedUid = null;
        _userNotFound = false;
        _isSearchingUser = false;
      });
      return;
    }

    setState(() {
      _isSearchingUser = true;
      _userNotFound = false;
      _searchedUid = null;
    });

    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('users').where('email', isEqualTo: query).limit(1).get(),
        FirebaseFirestore.instance.collection('users').where('phone', isEqualTo: query).limit(1).get(),
        FirebaseFirestore.instance.collection('users').where('referCode', isEqualTo: query).limit(1).get(),
      ]);

      String? foundUid;
      for (final snapshot in results) {
        if (snapshot.docs.isNotEmpty) {
          foundUid = snapshot.docs.first.id;
          break;
        }
      }

      setState(() {
        if (foundUid != null) {
          _searchedUid = foundUid;
          _userNotFound = false;
        } else {
          // If no specific user is matched, we still keep direct text search for titles/descriptions
          _searchedUid = null;
          _userNotFound = false;
        }
        _isSearchingUser = false;
      });
    } catch (e) {
      setState(() {
        _isSearchingUser = false;
        _userNotFound = false;
      });
    }
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() {
      _searchedUid = null;
      _directSearchText = '';
      _userNotFound = false;
      _isSearchingUser = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Micro Jobs Management'),
        elevation: 0,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // ── Search Bar ───────────────────────────────────────────────────
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextFormField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search by Email, Phone, Refer Code, or Job Title...',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textHint),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textHint),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textSecondary),
                          onPressed: _clearSearch,
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
                onChanged: (val) {
                  setState(() {
                    _directSearchText = val.trim().toLowerCase();
                  });
                },
                onFieldSubmitted: (_) => _performSearch(),
              ),
            ),

            // ── Tab Bar ──────────────────────────────────────────────────────
            Container(
              color: AppColors.surface,
              child: TabBar(
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.work_outline_rounded, size: 18),
                    text: 'Micro Job Posts',
                  ),
                  Tab(
                    icon: Icon(Icons.assignment_turned_in_outlined, size: 18),
                    text: 'Micro Job Submissions',
                  ),
                ],
              ),
            ),

            // ── Tab Views ────────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                children: [
                  MicroJobPostsTab(
                    searchedUid: _searchedUid,
                    directSearchText: _directSearchText,
                    isSearchingUser: _isSearchingUser,
                    userNotFound: _userNotFound,
                    onSearch: _performSearch,
                  ),
                  MicroJobSubmissionsTab(
                    searchedUid: _searchedUid,
                    directSearchText: _directSearchText,
                    isSearchingUser: _isSearchingUser,
                    userNotFound: _userNotFound,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Micro Job Posts Tab (with Status Filter & Premium Job Cards)
// ─────────────────────────────────────────────────────────────────────────────
class MicroJobPostsTab extends StatefulWidget {
  final String? searchedUid;
  final String directSearchText;
  final bool isSearchingUser;
  final bool userNotFound;
  final VoidCallback? onSearch;

  const MicroJobPostsTab({
    super.key,
    required this.searchedUid,
    required this.directSearchText,
    required this.isSearchingUser,
    required this.userNotFound,
    this.onSearch,
  });

  @override
  State<MicroJobPostsTab> createState() => _MicroJobPostsTabState();
}

class _MicroJobPostsTabState extends State<MicroJobPostsTab> {
  String _selectedStatus = 'All'; // 'All', 'Pending', 'Active', 'Paused', 'Rejected'

  final List<String> _statusOptions = ['All', 'Pending', 'Active', 'Paused', 'Rejected'];

  @override
  Widget build(BuildContext context) {
    if (widget.isSearchingUser) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (widget.userNotFound) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off_rounded, size: 48, color: AppColors.textHint),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'User not found!',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'No user matches your email/phone/refer code query.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    Query collection = FirebaseFirestore.instance.collection('job_posts');
    if (widget.searchedUid != null) {
      collection = collection.where('userId', isEqualTo: widget.searchedUid);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: collection.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Error loading jobs: ${snapshot.error}',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          );
        }

        final rawDocs = snapshot.data?.docs ?? [];
        if (rawDocs.isEmpty) {
          return _buildEmptyState(
            title: 'No Job Posts Found',
            subtitle: widget.searchedUid != null
                ? 'This user has not posted any micro jobs yet.'
                : 'There are no micro job posts in the database.',
            icon: Icons.work_off_outlined,
          );
        }

        // Sort by createdAt descending
        final sortedDocs = List<DocumentSnapshot>.from(rawDocs);
        sortedDocs.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>? ?? {};
          final dataB = b.data() as Map<String, dynamic>? ?? {};
          final dateA = _parseDate(dataA['createdAt']);
          final dateB = _parseDate(dataB['createdAt']);
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA);
        });

        // Compute counts for status chips
        int totalCount = 0;
        int pendingCount = 0;
        int activeCount = 0;
        int pausedCount = 0;
        int rejectedCount = 0;

        for (final doc in sortedDocs) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final s = (data['status'] ?? 'pending').toString().toLowerCase().trim();
          totalCount++;
          if (s == 'pending') pendingCount++;
          if (s == 'active' || s == 'approved') activeCount++;
          if (s == 'paused') pausedCount++;
          if (s == 'rejected') rejectedCount++;
        }

        // Filter list based on selectedStatus & directSearchText
        final filteredDocs = sortedDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final status = (data['status'] ?? 'pending').toString().toLowerCase().trim();

          // 1. Status Filter
          if (_selectedStatus != 'All') {
            final target = _selectedStatus.toLowerCase();
            if (target == 'active' && !(status == 'active' || status == 'approved')) {
              return false;
            } else if (target != 'active' && status != target) {
              return false;
            }
          }

          // 2. Direct Search Filter
          if (widget.directSearchText.isNotEmpty) {
            final jobName = (data['jobName'] ?? '').toString().toLowerCase();
            final posterName = (data['posterName'] ?? data['postedBy'] ?? '').toString().toLowerCase();
            final desc = (data['jobDescription'] ?? data['description'] ?? '').toString().toLowerCase();
            final id = doc.id.toLowerCase();
            final query = widget.directSearchText;

            if (!jobName.contains(query) &&
                !posterName.contains(query) &&
                !desc.contains(query) &&
                !id.contains(query)) {
              return false;
            }
          }

          return true;
        }).toList();

        return Column(
          children: [
            // ── Status Filter Ribbon ─────────────────────────────────────────
            _buildStatusFilterRibbon(
              totalCount: totalCount,
              pendingCount: pendingCount,
              activeCount: activeCount,
              pausedCount: pausedCount,
              rejectedCount: rejectedCount,
            ),

            // ── Job Cards List ───────────────────────────────────────────────
            Expanded(
              child: filteredDocs.isEmpty
                  ? _buildEmptyState(
                      title: 'No Matching Job Posts',
                      subtitle: _selectedStatus != 'All'
                          ? 'No job posts with status "$_selectedStatus".'
                          : 'No job posts matched your search query.',
                      icon: Icons.search_off_rounded,
                      actionButton: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedStatus = 'All';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Show All Jobs'),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final doc = filteredDocs[index];
                        final data = doc.data() as Map<String, dynamic>? ?? {};

                        return _PremiumJobPostCard(
                          docId: doc.id,
                          data: data,
                          onActionTap: () => _showAdminActionBottomSheet(context, doc, data),
                          onEditTap: () => _showEditJobPostDialog(context, doc, data),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // ── Horizontally Scrollable Filter Ribbon ──────────────────────────────────
  Widget _buildStatusFilterRibbon({
    required int totalCount,
    required int pendingCount,
    required int activeCount,
    required int pausedCount,
    required int rejectedCount,
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
          children: _statusOptions.map((status) {
            final isSelected = _selectedStatus.toLowerCase() == status.toLowerCase();
            int count = totalCount;
            Color themeColor = AppColors.primary;

            if (status == 'Pending') {
              count = pendingCount;
              themeColor = AppColors.warning;
            } else if (status == 'Active') {
              count = activeCount;
              themeColor = AppColors.success;
            } else if (status == 'Paused') {
              count = pausedCount;
              themeColor = Colors.blueGrey;
            } else if (status == 'Rejected') {
              count = rejectedCount;
              themeColor = AppColors.error;
            }

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedStatus = status;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? themeColor : themeColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? themeColor : themeColor.withValues(alpha: 0.25),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: themeColor.withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(status),
                            size: 13,
                            color: isSelected ? Colors.white : themeColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : themeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$count',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : themeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'paused':
        return Icons.pause_circle_outline_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.all_inclusive_rounded;
    }
  }

  // ── Admin Actions Bottom Sheet ─────────────────────────────────────────────
  void _showAdminActionBottomSheet(
      BuildContext context, DocumentSnapshot doc, Map<String, dynamic> data) {
    final jobName = data['jobName'] ?? 'Untitled Job';
    final currentStatus = (data['status'] ?? 'pending').toString().toLowerCase().trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
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

                // Job Title Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage Job Post',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            jobName,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(status: currentStatus),
                  ],
                ),
                const Divider(height: 24, color: AppColors.divider),

                // Action 1: Approve & Set Active
                _buildActionTile(
                  sheetContext: sheetContext,
                  title: 'Approve & Set Active',
                  subtitle: 'Make this job live and visible to users',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.success,
                  isCurrent: currentStatus == 'active' || currentStatus == 'approved',
                  onTap: () => _updateJobStatus(context, sheetContext, doc.id, 'active', 'Job approved and activated!'),
                ),

                // Action 2: Mark as Pending
                _buildActionTile(
                  sheetContext: sheetContext,
                  title: 'Mark as Pending',
                  subtitle: 'Set this job back under review',
                  icon: Icons.hourglass_top_rounded,
                  color: AppColors.warning,
                  isCurrent: currentStatus == 'pending',
                  onTap: () => _updateJobStatus(context, sheetContext, doc.id, 'pending', 'Job marked as pending!'),
                ),

                // Action 3: Pause Job
                _buildActionTile(
                  sheetContext: sheetContext,
                  title: 'Pause Job',
                  subtitle: 'Temporarily halt user submissions for this job',
                  icon: Icons.pause_circle_outline_rounded,
                  color: Colors.blueGrey,
                  isCurrent: currentStatus == 'paused',
                  onTap: () => _updateJobStatus(context, sheetContext, doc.id, 'paused', 'Job paused!'),
                ),

                // Action 4: Reject Job
                _buildActionTile(
                  sheetContext: sheetContext,
                  title: 'Reject Job Post',
                  subtitle: 'Mark this job as rejected',
                  icon: Icons.cancel_outlined,
                  color: AppColors.error,
                  isCurrent: currentStatus == 'rejected',
                  onTap: () => _updateJobStatus(context, sheetContext, doc.id, 'rejected', 'Job rejected!'),
                ),

                const SizedBox(height: AppSpacing.xs),
                const Divider(height: 16, color: AppColors.divider),

                // Action 5: Edit Job Details
                _buildActionTile(
                  sheetContext: sheetContext,
                  title: 'Edit Full Job Details',
                  subtitle: 'Edit title, reward, limit, link, or description',
                  icon: Icons.edit_note_rounded,
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showEditJobPostDialog(context, doc, data);
                  },
                ),

                // Action 6: Delete Job Post
                _buildActionTile(
                  sheetContext: sheetContext,
                  title: 'Delete Job Post',
                  subtitle: 'Permanently remove this job document',
                  icon: Icons.delete_forever_rounded,
                  color: AppColors.error,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _confirmDeleteJob(context, doc.id, jobName);
                  },
                ),

                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionTile({
    required BuildContext sheetContext,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isCurrent = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isCurrent ? color.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isCurrent ? Border.all(color: color.withValues(alpha: 0.3)) : null,
      ),
      child: ListTile(
        onTap: isCurrent ? null : onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Row(
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isCurrent ? color : AppColors.textPrimary,
              ),
            ),
            if (isCurrent) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'CURRENT',
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
        ),
        trailing: isCurrent
            ? Icon(Icons.check_rounded, color: color, size: 18)
            : const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 18),
      ),
    );
  }

  Future<void> _updateJobStatus(
    BuildContext rootContext,
    BuildContext sheetContext,
    String docId,
    String newStatus,
    String successMessage,
  ) async {
    Navigator.pop(sheetContext);

    // Show loading overlay
    showDialog(
      context: rootContext,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(width: 16),
                Text('Updating status...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await FirebaseFirestore.instance.collection('job_posts').doc(docId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (rootContext.mounted) {
        Navigator.pop(rootContext); // Dismiss loading
        ScaffoldMessenger.of(rootContext).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(successMessage),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (rootContext.mounted) {
        Navigator.pop(rootContext); // Dismiss loading
        ScaffoldMessenger.of(rootContext).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _confirmDeleteJob(BuildContext context, String docId, String jobName) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Text('Delete Job Post?', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "$jobName"? This action cannot be undone.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await FirebaseFirestore.instance.collection('job_posts').doc(docId).delete();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Job post deleted successfully.'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting job post: $e'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  // ── Edit Job Post Dialog ───────────────────────────────────────────────────
  void _showEditJobPostDialog(
      BuildContext context, DocumentSnapshot doc, Map<String, dynamic> data) {
    final jobNameCtrl = TextEditingController(text: data['jobName']?.toString() ?? '');
    final posterNameCtrl = TextEditingController(
        text: (data['posterName'] ?? data['postedBy'] ?? '').toString());
    final limitCtrl = TextEditingController(text: data['totalJobLimit']?.toString() ?? '0');
    final amountCtrl = TextEditingController(text: data['perJobAmount']?.toString() ?? '0');
    final descCtrl = TextEditingController(
        text: (data['jobDescription'] ?? data['description'] ?? '').toString());
    final linkCtrl = TextEditingController(
        text: (data['jobLink'] ?? data['link'] ?? '').toString());
    final imageCtrl = TextEditingController(
        text: (data['featureImage'] ?? data['imageUrl'] ?? '').toString());

    String currentStatus = (data['status'] ?? 'pending').toString().toLowerCase().trim();
    if (!['pending', 'active', 'paused', 'rejected'].contains(currentStatus)) {
      currentStatus = 'pending';
    }

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Edit Job Post', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: jobNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Job Title',
                          prefixIcon: Icon(Icons.work_outline_rounded, size: 18),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: posterNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Poster Name / User',
                          prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: limitCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Total Job Limit',
                                prefixIcon: Icon(Icons.people_outline_rounded, size: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: TextField(
                              controller: amountCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Reward (৳)',
                                prefixIcon: Icon(Icons.payments_outlined, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: linkCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Job Link / URL',
                          prefixIcon: Icon(Icons.link_rounded, size: 18),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: imageCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Feature Image URL',
                          prefixIcon: Icon(Icons.image_outlined, size: 18),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: descCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Job Description',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        initialValue: currentStatus,
                        items: const [
                          DropdownMenuItem(value: 'active', child: Text('Active (Approved)')),
                          DropdownMenuItem(value: 'pending', child: Text('Pending Review')),
                          DropdownMenuItem(value: 'paused', child: Text('Paused')),
                          DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => currentStatus = val);
                        },
                        decoration: const InputDecoration(
                          labelText: 'Job Status',
                          prefixIcon: Icon(Icons.flag_outlined, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    try {
                      final int limit = int.tryParse(limitCtrl.text.trim()) ?? (data['totalJobLimit'] ?? 0);
                      final double amount = double.tryParse(amountCtrl.text.trim()) ?? (data['perJobAmount'] ?? 0.0);

                      await FirebaseFirestore.instance.collection('job_posts').doc(doc.id).update({
                        'jobName': jobNameCtrl.text.trim(),
                        'posterName': posterNameCtrl.text.trim(),
                        'postedBy': posterNameCtrl.text.trim(),
                        'jobDescription': descCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'jobLink': linkCtrl.text.trim(),
                        'featureImage': imageCtrl.text.trim(),
                        'totalJobLimit': limit,
                        'perJobAmount': amount,
                        'status': currentStatus,
                        'updatedAt': FieldValue.serverTimestamp(),
                      });

                      if (context.mounted) {
                        Navigator.pop(dialogCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Job post updated successfully!'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error updating job: $e'),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Empty State Widget ─────────────────────────────────────────────────────
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

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is int) {
      return raw > 100000000000
          ? DateTime.fromMillisecondsSinceEpoch(raw)
          : DateTime.fromMillisecondsSinceEpoch(raw * 1000);
    }
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Redesigned Premium Job Card
// ─────────────────────────────────────────────────────────────────────────────
class _PremiumJobPostCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onActionTap;
  final VoidCallback onEditTap;

  const _PremiumJobPostCard({
    required this.docId,
    required this.data,
    required this.onActionTap,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final jobName = data['jobName']?.toString().trim() ?? 'Untitled Job';
    final posterName = (data['posterName'] ?? data['postedBy'] ?? 'Unknown Poster').toString().trim();
    final featureImage = (data['featureImage'] ?? data['imageUrl'] ?? '').toString().trim();
    final status = (data['status'] ?? 'pending').toString().toLowerCase().trim();
    final completedCount = (data['completedCount'] as num?)?.toInt() ?? 0;
    final totalJobLimit = (data['totalJobLimit'] as num?)?.toInt() ?? 0;
    final perJobAmount = (data['perJobAmount'] as num?)?.toDouble() ?? 0.0;
    final jobDescription = (data['jobDescription'] ?? data['description'] ?? '').toString().trim();
    final jobLink = (data['jobLink'] ?? data['link'] ?? '').toString().trim();
    final createdAt = _formatDate(data['createdAt']);

    final progressPercent = totalJobLimit > 0
        ? (completedCount / totalJobLimit).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header: Thumbnail + Title + Status Badge ─────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 48,
                    height: 48,
                    color: AppColors.primary.withValues(alpha: 0.1),
                    child: featureImage.isNotEmpty
                        ? Image.network(
                            featureImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.work_outline_rounded,
                              size: 24,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(
                            Icons.work_outline_rounded,
                            size: 24,
                            color: AppColors.primary,
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Job Name & ID
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jobName,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            'ID: ${docId.length > 8 ? "${docId.substring(0, 8)}..." : docId}',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textHint),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: docId));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Copied Job ID "$docId"')),
                              );
                            },
                            child: const Icon(Icons.copy_rounded, size: 11, color: AppColors.textHint),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Status Badge
                _StatusBadge(status: status),
              ],
            ),

            const Divider(height: 20, color: AppColors.divider),

            // ── Grid / Detail Badges ─────────────────────────────────────────
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                // Poster
                _buildInfoBadge(
                  icon: Icons.person_outline_rounded,
                  label: 'Poster',
                  value: posterName,
                  valueColor: AppColors.textPrimary,
                ),

                // Reward Amount
                _buildInfoBadge(
                  icon: Icons.payments_outlined,
                  label: 'Reward',
                  value: '৳${perJobAmount.toStringAsFixed(perJobAmount.truncateToDouble() == perJobAmount ? 0 : 2)}',
                  valueColor: AppColors.success,
                  isBold: true,
                ),

                // Date
                _buildInfoBadge(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: createdAt,
                  valueColor: AppColors.textSecondary,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Progress Bar: Completed / Total Limit ────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.donut_large_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Task Progress',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$completedCount / $totalJobLimit Completed',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressPercent,
                      minHeight: 6,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progressPercent >= 1.0 ? AppColors.success : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Job Description (if available) ───────────────────────────────
            if (jobDescription.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  jobDescription,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            // ── Job Link (if available) ──────────────────────────────────────
            if (jobLink.isNotEmpty) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: jobLink));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Copied link: "$jobLink"'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          jobLink,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy_rounded, size: 12, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),

            // ── Admin Actions Bottom Controls ────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: Text(
                      'Manage Status',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    onPressed: onActionTap,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                  label: Text(
                    'Edit',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  onPressed: onEditTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return 'N/A';
    DateTime? date;
    if (raw is Timestamp) date = raw.toDate();
    if (raw is DateTime) date = raw;
    if (raw is int) {
      date = raw > 100000000000
          ? DateTime.fromMillisecondsSinceEpoch(raw)
          : DateTime.fromMillisecondsSinceEpoch(raw * 1000);
    }
    if (raw is String) date = DateTime.tryParse(raw);
    if (date == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(date);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dynamic Status Badge Widget
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    Color bg;
    Color fg;
    IconData icon;

    if (s == 'active' || s == 'approved') {
      bg = AppColors.successBg;
      fg = AppColors.success;
      icon = Icons.check_circle_rounded;
    } else if (s == 'pending') {
      bg = AppColors.warningBg;
      fg = AppColors.warning;
      icon = Icons.hourglass_top_rounded;
    } else if (s == 'paused') {
      bg = AppColors.surfaceVariant;
      fg = Colors.blueGrey;
      icon = Icons.pause_circle_outline_rounded;
    } else {
      bg = AppColors.errorBg;
      fg = AppColors.error;
      icon = Icons.cancel_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
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
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Micro Job Submissions Tab
// ─────────────────────────────────────────────────────────────────────────────
class MicroJobSubmissionsTab extends StatelessWidget {
  final String? searchedUid;
  final String directSearchText;
  final bool isSearchingUser;
  final bool userNotFound;

  const MicroJobSubmissionsTab({
    super.key,
    required this.searchedUid,
    required this.directSearchText,
    required this.isSearchingUser,
    required this.userNotFound,
  });

  @override
  Widget build(BuildContext context) {
    if (isSearchingUser) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (userNotFound) {
      return const Center(
        child: Text('User not found in system!', style: TextStyle(fontSize: 16)),
      );
    }

    Query collection = FirebaseFirestore.instance.collection('job_submissions');
    if (searchedUid != null) {
      collection = collection.where('submittedBy', isEqualTo: searchedUid);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: collection.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.assignment_late_outlined, size: 48, color: AppColors.textHint),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'No Submissions Found',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs.where((doc) {
          if (directSearchText.isEmpty) return true;
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final title = (data['jobTitle'] ?? '').toString().toLowerCase();
          final user = (data['submittedByName'] ?? data['submittedBy'] ?? '').toString().toLowerCase();
          final proof = (data['proofText'] ?? '').toString().toLowerCase();
          return title.contains(directSearchText) ||
              user.contains(directSearchText) ||
              proof.contains(directSearchText);
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            final jobTitle = data['jobTitle'] ?? 'No Title';
            final submittedByName = data['submittedByName'] ?? data['submittedBy'] ?? 'Unknown User';
            final proofText = data['proofText'] ?? 'No proof provided';
            final status = (data['status'] ?? 'pending').toString().toLowerCase();
            final rewardAmount = (data['rewardAmount'] ?? data['reward'] ?? 0.0);

            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.sm,
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
                            jobTitle,
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                        _StatusBadge(status: status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Submitted By: ',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        Text(
                          '$submittedByName',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        const Spacer(),
                        Text(
                          'Reward: ৳$rewardAmount',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Proof Details:',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            proofText,
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.rate_review_rounded, size: 18),
                        label: const Text('Review Submission'),
                        onPressed: () => _showReviewDialog(context, doc),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showReviewDialog(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    String currentStatus = (data['status'] ?? 'pending').toString().toLowerCase();
    final proofCtrl = TextEditingController(text: data['proofText']?.toString());
    final rewardCtrl = TextEditingController(text: (data['rewardAmount'] ?? data['reward'] ?? '0').toString());

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Review Submission'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: proofCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Proof Text'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: rewardCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Reward Amount (৳)'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: ['pending', 'approved', 'rejected'].contains(currentStatus) ? currentStatus : 'pending',
                      items: const [
                        DropdownMenuItem(value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'approved', child: Text('Approved')),
                        DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => currentStatus = val);
                      },
                      decoration: const InputDecoration(labelText: 'Decision Status'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    try {
                      final double reward = double.tryParse(rewardCtrl.text.trim()) ?? 0.0;

                      await FirebaseFirestore.instance.collection('job_submissions').doc(doc.id).update({
                        'proofText': proofCtrl.text.trim(),
                        'rewardAmount': reward,
                        'reward': reward,
                        'status': currentStatus,
                        'reviewedAt': FieldValue.serverTimestamp(),
                      });

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Submission decision saved!'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Save Decision'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
