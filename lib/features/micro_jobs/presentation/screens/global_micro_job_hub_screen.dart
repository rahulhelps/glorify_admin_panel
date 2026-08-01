import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';

class GlobalMicroJobHubScreen extends StatefulWidget {
  const GlobalMicroJobHubScreen({super.key});

  @override
  State<GlobalMicroJobHubScreen> createState() => _GlobalMicroJobHubScreenState();
}

class _GlobalMicroJobHubScreenState extends State<GlobalMicroJobHubScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String? _searchedUid;
  bool _isSearchingUser = false;
  bool _userNotFound = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchCtrl.text.trim();
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
          _searchedUid = null;
          _userNotFound = true;
        }
        _isSearchingUser = false;
      });
    } catch (e) {
      setState(() {
        _isSearchingUser = false;
        _userNotFound = true;
      });
    }
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() {
      _searchedUid = null;
      _userNotFound = false;
      _isSearchingUser = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // No Scaffold — lives inside AdminShell. All Firestore operations preserved.
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Search bar
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
            child: TextFormField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search user by Email, Phone, or Refer Code...',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: _clearSearch,
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
              onFieldSubmitted: (_) => _performSearch(),
            ),
          ),
          // Tab bar
          Container(
            color: AppColors.surface,
            child: const TabBar(
              tabs: [
                Tab(text: 'Micro Job Posts'),
                Tab(text: 'Micro Job Submissions'),
              ],
            ),
          ),
          // Tab view
          Expanded(
            child: TabBarView(
              children: [
                MicroJobPostsTab(
                  searchedUid: _searchedUid,
                  isSearchingUser: _isSearchingUser,
                  userNotFound: _userNotFound,
                  onSearch: _performSearch,
                ),
                MicroJobSubmissionsTab(
                  searchedUid: _searchedUid,
                  isSearchingUser: _isSearchingUser,
                  userNotFound: _userNotFound,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MicroJobPostsTab extends StatelessWidget {
  final String? searchedUid;
  final bool isSearchingUser;
  final bool userNotFound;
  final VoidCallback? onSearch;

  const MicroJobPostsTab({
    super.key,
    required this.searchedUid,
    required this.isSearchingUser,
    required this.userNotFound,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    if (isSearchingUser) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00CED1)));
    }
    if (userNotFound) {
      return const Center(child: Text('এই ইউজারের কোনো ডাটা পাওয়া যায়নি!', style: TextStyle(fontSize: 16)));
    }

    Query collection = FirebaseFirestore.instance.collection('job_posts');
    if (searchedUid != null) {
      collection = collection.where('userId', isEqualTo: searchedUid);
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
          return const Center(child: Text('এই ইউজারের কোনো ডাটা পাওয়া যায়নি!', style: TextStyle(fontSize: 16)));
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final jobId = doc.id;
            
            final jobName = data['jobName'] ?? 'No Title';
            final postedBy = data['postedBy'] ?? 'Unknown';
            final totalJobLimit = data['totalJobLimit'] ?? 0;
            final perJobAmount = data['perJobAmount'] ?? 0.0;
            final status = data['status'] ?? 'pending';

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            jobName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Posted By: $postedBy'),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Limit: $totalJobLimit'),
                        Text('Amount: $perJobAmount'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00CED1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Modify Post'),
                        onPressed: () => _showModifyPostDialog(context, doc),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'inactive':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showModifyPostDialog(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final jobNameCtrl = TextEditingController(text: data['jobName']?.toString());
    final postedByCtrl = TextEditingController(text: data['postedBy']?.toString());
    final limitCtrl = TextEditingController(text: data['totalJobLimit']?.toString());
    final amountCtrl = TextEditingController(text: data['perJobAmount']?.toString());
    final descCtrl = TextEditingController(text: data['description']?.toString());
    String currentStatus = data['status'] ?? 'pending';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Modify Job Post'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: jobNameCtrl,
                      decoration: const InputDecoration(labelText: 'Job Name'),
                    ),
                    TextField(
                      controller: postedByCtrl,
                      decoration: const InputDecoration(labelText: 'Posted By'),
                    ),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    TextField(
                      controller: limitCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Total Job Limit'),
                    ),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Per Job Amount'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: ['active', 'inactive', 'pending'].contains(currentStatus) ? currentStatus : 'pending',
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Active')),
                        DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                        DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => currentStatus = val);
                      },
                      decoration: const InputDecoration(labelText: 'Status'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00CED1)),
                  onPressed: () async {
                    try {
                      final int limit = int.tryParse(limitCtrl.text.trim()) ?? (data['totalJobLimit'] ?? 0);
                      final double amount = double.tryParse(amountCtrl.text.trim()) ?? (data['perJobAmount'] ?? 0.0);

                      await FirebaseFirestore.instance.collection('job_posts').doc(doc.id).update({
                        'jobName': jobNameCtrl.text.trim(),
                        'postedBy': postedByCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'totalJobLimit': limit,
                        'perJobAmount': amount,
                        'status': currentStatus,
                      });
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Post updated successfully!'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }
}

class MicroJobSubmissionsTab extends StatelessWidget {
  final String? searchedUid;
  final bool isSearchingUser;
  final bool userNotFound;

  const MicroJobSubmissionsTab({
    super.key,
    required this.searchedUid,
    required this.isSearchingUser,
    required this.userNotFound,
  });

  @override
  Widget build(BuildContext context) {
    if (isSearchingUser) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00CED1)));
    }
    if (userNotFound) {
      return const Center(child: Text('এই ইউজারের কোনো ডাটা পাওয়া যায়নি!', style: TextStyle(fontSize: 16)));
    }

    Query collection = FirebaseFirestore.instance.collection('job_submissions');
    if (searchedUid != null) {
      collection = collection.where('submittedBy', isEqualTo: searchedUid);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: collection.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00CED1)));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('এই ইউজারের কোনো ডাটা পাওয়া যায়নি!', style: TextStyle(fontSize: 16)));
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            final jobTitle = data['jobTitle'] ?? 'No Title';
            final submittedByName = data['submittedByName'] ?? 'Unknown User';
            final proofText = data['proofText'] ?? 'No proof provided';
            final status = data['status'] ?? 'pending';

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            jobTitle,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Submitted By: $submittedByName'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Proof:\n$proofText',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00CED1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.rate_review, size: 18),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showReviewDialog(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    String currentStatus = data['status'] ?? 'pending';
    final proofCtrl = TextEditingController(text: data['proofText']?.toString());
    final rewardCtrl = TextEditingController(text: data['rewardAmount']?.toString() ?? '0');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Review Submission'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: proofCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Proof Text (Editable)'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: rewardCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Reward Amount'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: ['pending', 'approved', 'rejected'].contains(currentStatus) ? currentStatus : 'pending',
                      items: const [
                        DropdownMenuItem(value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'approved', child: Text('Approved')),
                        DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => currentStatus = val);
                      },
                      decoration: const InputDecoration(labelText: 'Status'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00CED1)),
                  onPressed: () async {
                    try {
                      final double reward = double.tryParse(rewardCtrl.text.trim()) ?? 0.0;

                      await FirebaseFirestore.instance.collection('job_submissions').doc(doc.id).update({
                        'proofText': proofCtrl.text.trim(),
                        'rewardAmount': reward,
                        'status': currentStatus,
                      });
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Submission updated successfully!'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: const Text('Save Decision', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
