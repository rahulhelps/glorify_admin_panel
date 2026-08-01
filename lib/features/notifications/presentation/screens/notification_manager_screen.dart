import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/notification_repository.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';
import '../../../../core/theme/app_theme.dart';

class NotificationManagerScreen extends StatelessWidget {
  const NotificationManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationBloc(
        notificationRepository: NotificationRepository(),
      ),
      child: const _NotificationManagerView(),
    );
  }
}

class _NotificationManagerView extends StatefulWidget {
  const _NotificationManagerView();

  @override
  State<_NotificationManagerView> createState() => _NotificationManagerViewState();
}

class _NotificationManagerViewState extends State<_NotificationManagerView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Broadcast Controllers
  final TextEditingController _broadcastTitleCtrl = TextEditingController();
  final TextEditingController _broadcastMsgCtrl = TextEditingController();

  // Specific User Controllers
  final TextEditingController _searchUserCtrl = TextEditingController();
  final TextEditingController _targetTitleCtrl = TextEditingController();
  final TextEditingController _targetMsgCtrl = TextEditingController();
  bool _isLoadingSearch = false;

  Map<String, dynamic>? _selectedUser;
  String? _selectedUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _broadcastTitleCtrl.dispose();
    _broadcastMsgCtrl.dispose();
    _searchUserCtrl.dispose();
    _targetTitleCtrl.dispose();
    _targetMsgCtrl.dispose();
    super.dispose();
  }

  void _sendBroadcastNotification() {
    final title = _broadcastTitleCtrl.text.trim();
    final message = _broadcastMsgCtrl.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields.'), backgroundColor: Colors.red));
      return;
    }

    context.read<NotificationBloc>().add(SendGlobalNotificationEvent(title, message));
  }

  Future<void> _searchUser() async {
    final query = _searchUserCtrl.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoadingSearch = true;
      _selectedUser = null;
      _selectedUserId = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').where(
        Filter.or(
          Filter('phone', isEqualTo: query),
          Filter('email', isEqualTo: query),
        ),
      ).limit(1).get();

      if (snapshot.docs.isNotEmpty) {
        if (mounted) {
          setState(() {
            _selectedUserId = snapshot.docs.first.id;
            _selectedUser = snapshot.docs.first.data();
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not found.'), backgroundColor: Colors.orange));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoadingSearch = false);
    }
  }

  void _sendTargetNotification() {
    if (_selectedUserId == null || _selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please search and select a user first.'), backgroundColor: Colors.red));
      return;
    }

    final title = _targetTitleCtrl.text.trim();
    final message = _targetMsgCtrl.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields.'), backgroundColor: Colors.red));
      return;
    }

    context.read<NotificationBloc>().add(SendTargetedNotificationEvent(
      userId: _selectedUserId!,
      title: title,
      body: message,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationBloc, NotificationState>(
      listener: (context, state) {
        if (state is NotificationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.success,
          ));
          _broadcastTitleCtrl.clear();
          _broadcastMsgCtrl.clear();
          _targetTitleCtrl.clear();
          _targetMsgCtrl.clear();
          setState(() {
            _selectedUser = null;
            _selectedUserId = null;
            _searchUserCtrl.clear();
          });
        } else if (state is NotificationFailure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: ${state.error}'),
            backgroundColor: AppColors.error,
          ));
        }
      },
      builder: (context, state) {
        final isSending = state is NotificationSending;
        // No Scaffold — lives inside AdminShell. All Bloc events preserved.
        return Column(
          children: [
            Container(
              color: AppColors.surface,
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'সবাইকে পাঠান (Broadcast)'),
                  Tab(text: 'নির্দিষ্ট ইউজার (Target)'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBroadcastTab(isSending),
                  _buildTargetTab(isSending),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBroadcastTab(bool isSending) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.info),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('This notification will be sent to ALL active users of the app.',
                      style: TextStyle(color: AppColors.info)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildTextField('শিরোনাম (Title)', _broadcastTitleCtrl, Icons.title),
          const SizedBox(height: AppSpacing.md),
          _buildTextField('বার্তা (Message)', _broadcastMsgCtrl, Icons.message, maxLines: 4),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: isSending ? null : _sendBroadcastNotification, // ✅ preserved
              icon: isSending ? const SizedBox() : const Icon(Icons.campaign_rounded),
              label: isSending
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Broadcast Notification', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetTab(bool isSending) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField('সার্চ User (Phone or Email)', _searchUserCtrl, Icons.search),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoadingSearch ? null : _searchUser,
                  child: _isLoadingSearch
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Search'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_selectedUser != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.sm,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.surfaceVariant,
                    child: Icon(Icons.person_rounded, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedUser!['name'] ?? 'Unknown User',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(_selectedUser!['phone'] ?? 'No Phone',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              (_selectedUser!['fcmToken']?.toString().isNotEmpty ?? false)
                                  ? Icons.check_circle_rounded
                                  : Icons.warning_rounded,
                              color: (_selectedUser!['fcmToken']?.toString().isNotEmpty ?? false)
                                  ? AppColors.success
                                  : AppColors.warning,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              (_selectedUser!['fcmToken']?.toString().isNotEmpty ?? false)
                                  ? 'FCM Token Available'
                                  : 'No FCM Token (Device Offline)',
                              style: TextStyle(
                                color: (_selectedUser!['fcmToken']?.toString().isNotEmpty ?? false)
                                    ? AppColors.success
                                    : AppColors.warning,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.error),
                    onPressed: () => setState(() {
                      _selectedUser = null;
                      _selectedUserId = null;
                      _searchUserCtrl.clear();
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildTextField('শিরোনাম (Title)', _targetTitleCtrl, Icons.title),
            const SizedBox(height: AppSpacing.md),
            _buildTextField('বার্তা (Message)', _targetMsgCtrl, Icons.message, maxLines: 4),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: isSending ? null : _sendTargetNotification, // ✅ preserved
                icon: isSending ? const SizedBox() : const Icon(Icons.send_rounded),
                label: isSending
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Send Target Notification', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
      ),
    );
  }
}
