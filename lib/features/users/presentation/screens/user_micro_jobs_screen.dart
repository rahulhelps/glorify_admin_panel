import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserMicroJobsScreen extends StatefulWidget {
  final String userId;
  const UserMicroJobsScreen({super.key, required this.userId});

  @override
  State<UserMicroJobsScreen> createState() => _UserMicroJobsScreenState();
}

class _UserMicroJobsScreenState extends State<UserMicroJobsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _jobPosts = [];
  List<Map<String, dynamic>> _jobSubmissions = [];

  @override
  void initState() {
    super.initState();
    _fetchMicroJobs();
  }

  void _fetchMicroJobs() async {
    setState(() => _isLoading = true);
    try {
      final postsQuery1 = await FirebaseFirestore.instance.collection('job_posts').where('userId', isEqualTo: widget.userId).get();
      final postsQuery2 = await FirebaseFirestore.instance.collection('job_posts').where('postedBy', isEqualTo: widget.userId).get();
      final submissionsQuery = await FirebaseFirestore.instance.collection('job_submissions').where('submittedBy', isEqualTo: widget.userId).get();

      final postsMap = <String, Map<String, dynamic>>{};
      for (var doc in postsQuery1.docs) {
        postsMap[doc.id] = {'id': doc.id, ...doc.data()};
      }
      for (var doc in postsQuery2.docs) {
        postsMap[doc.id] = {'id': doc.id, ...doc.data()};
      }

      if (mounted) {
        setState(() {
          _jobPosts = postsMap.values.toList();
          _jobSubmissions = submissionsQuery.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showEditJobPostDialog(Map<String, dynamic> job) {
    final statusCtrl = TextEditingController(text: job['status']?.toString() ?? 'active');
    final limitCtrl = TextEditingController(text: job['totalJobLimit']?.toString() ?? '0');
    final amountCtrl = TextEditingController(text: job['perJobAmount']?.toString() ?? '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Edit Job Post', style: TextStyle(color: Colors.grey[900])),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: statusCtrl, decoration: const InputDecoration(labelText: 'Status (active/paused)')),
            TextField(controller: limitCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Job Limit')),
            TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Per Job Amount')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: Colors.grey[600]))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00CED1), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance.collection('job_posts').doc(job['id']).update({
                  'status': statusCtrl.text,
                  'totalJobLimit': int.tryParse(limitCtrl.text) ?? 0,
                  'perJobAmount': double.tryParse(amountCtrl.text) ?? 0.0,
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job post updated!'), backgroundColor: Colors.green));
                  _fetchMicroJobs();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditJobSubmissionDialog(Map<String, dynamic> sub) {
    final statusCtrl = TextEditingController(text: sub['status']?.toString() ?? 'pending');
    final rewardCtrl = TextEditingController(text: sub['reward']?.toString() ?? '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Edit Job Submission', style: TextStyle(color: Colors.grey[900])),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: statusCtrl, decoration: const InputDecoration(labelText: 'Status (pending/approved/rejected)')),
            TextField(controller: rewardCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reward')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: Colors.grey[600]))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00CED1), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance.collection('job_submissions').doc(sub['id']).update({
                  'status': statusCtrl.text,
                  'reward': double.tryParse(rewardCtrl.text) ?? 0.0,
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission updated!'), backgroundColor: Colors.green));
                  _fetchMicroJobs();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Micro Jobs', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF00CED1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00CED1)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_jobPosts.isEmpty && _jobSubmissions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        'No micro-jobs or submissions found.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ),
                  if (_jobPosts.isNotEmpty) ...[
                    Text('Job Posts', style: TextStyle(color: Colors.grey[800], fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ..._jobPosts.map((job) => _buildJobPostTile(job)),
                    const SizedBox(height: 24),
                  ],
                  if (_jobSubmissions.isNotEmpty) ...[
                    Text('Submissions', style: TextStyle(color: Colors.grey[800], fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ..._jobSubmissions.map((sub) => _buildJobSubmissionTile(sub)),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildJobPostTile(Map<String, dynamic> job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, spreadRadius: 1),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(job['jobName'] ?? 'Unknown Job', style: TextStyle(color: Colors.grey[900], fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'Status: ${job['status']} | Limit: ${job['totalJobLimit']} | Amount: ৳${job['perJobAmount']}',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
        trailing: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF00CED1).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF00CED1)),
            onPressed: () => _showEditJobPostDialog(job),
          ),
        ),
      ),
    );
  }

  Widget _buildJobSubmissionTile(Map<String, dynamic> sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, spreadRadius: 1),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text('Job ID: ${sub['jobId']}', style: TextStyle(color: Colors.grey[900], fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'Status: ${sub['status']} | Reward: ৳${sub['reward']}',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
        trailing: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF00CED1).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF00CED1)),
            onPressed: () => _showEditJobSubmissionDialog(sub),
          ),
        ),
      ),
    );
  }
}
