import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';

class AppUpdatesManagementScreen extends StatefulWidget {
  const AppUpdatesManagementScreen({super.key});

  @override
  State<AppUpdatesManagementScreen> createState() => _AppUpdatesManagementScreenState();
}

class _AppUpdatesManagementScreenState extends State<AppUpdatesManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _versionController = TextEditingController();
  final _urlController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentVersion();
  }
  
  Future<void> _fetchCurrentVersion() async {
    try {
      final doc = await FirebaseFirestore.instance.doc('app_settings/version_control').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final currentVersion = data['latest_version'] as String?;
        final currentUrl = data['download_url'] as String?;
        
        setState(() {
          if (currentVersion != null) _versionController.text = currentVersion;
          if (currentUrl != null) _urlController.text = currentUrl;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading active version: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _publishUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final firestore = FirebaseFirestore.instance;
      final newVersion = _versionController.text.trim();
      final newUrl = _urlController.text.trim();
      
      await firestore.runTransaction((transaction) async {
        final docRef = firestore.doc('app_settings/version_control');
        final docSnapshot = await transaction.get(docRef);
        
        // Archive current version if it exists
        if (docSnapshot.exists && docSnapshot.data() != null) {
          final data = docSnapshot.data()!;
          if (data.containsKey('latest_version') && data.containsKey('download_url')) {
            final archiveRef = firestore.collection('version_history').doc();
            transaction.set(archiveRef, {
              'version': data['latest_version'],
              'download_url': data['download_url'],
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
        
        // Overwrite active version doc
        transaction.set(docRef, {
          'latest_version': newVersion,
          'download_url': newUrl,
        });
      });
      
      setState(() {
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Update published successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish update: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _versionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // No Scaffold — lives inside AdminShell. All Firestore operations preserved.
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCurrentUpdateForm(),
          const SizedBox(height: AppSpacing.xl),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Old Updates History / পূর্ববর্তী আপডেটসমূহ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildHistoryList(),
        ],
      ),
    );
  }

  Widget _buildCurrentUpdateForm() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: const Icon(Icons.system_update_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Text('Publish New Update',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _versionController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Build Number / Version',
                hintText: 'Enter Integer only, e.g., 2, 3, 4',
                prefixIcon: Icon(Icons.numbers_rounded, size: 18),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Please enter a build number';
                if (int.tryParse(value.trim()) == null) return 'Please enter a valid integer (e.g. 2, 3)';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Download URL',
                hintText: 'Enter the APK download link',
                prefixIcon: Icon(Icons.link_rounded, size: 18),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Please enter a download URL';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _publishUpdate,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Publish Update', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('version_history')
          .orderBy('updatedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No update history found.', style: TextStyle(color: Colors.grey, fontSize: 16)),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final version = data['version'] ?? 'N/A';
            final url = data['download_url'] ?? 'No URL';
            final timestamp = data['updatedAt'] as Timestamp?;
            
            String formattedDate = 'Unknown date';
            if (timestamp != null) {
              final dateTime = timestamp.toDate();
              formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
            }

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Version / Build: $version',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          formattedDate,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.link, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            url,
                            style: const TextStyle(color: Colors.blue, fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
}
