import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/user_management_bloc.dart';
import '../../data/models/user_model.dart';

import 'user_generation_screen.dart';
import 'user_income_history_screen.dart';
import 'user_micro_jobs_screen.dart';

class UserDetailsScreen extends StatefulWidget {
  final UserModel initialUser;

  const UserDetailsScreen({super.key, required this.initialUser});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  late UserModel _user;
  late String _subscriptionStatus;
  late String _accountStatus;
  
  final _formKey = GlobalKey<FormState>();

  // Controllers for Personal Details & Credentials
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _dobCtrl;
  late TextEditingController _referCodeCtrl;
  late TextEditingController _referredByCtrl;

  // Controllers for Balances
  late TextEditingController _totalCtrl;
  late TextEditingController _earningCtrl;
  late TextEditingController _rechargeCtrl;
  late TextEditingController _referralCtrl;
  late TextEditingController _voucherCtrl;
  late TextEditingController _withdrawnCtrl;

  // Controllers / Flags for Status & Flags
  late TextEditingController _rankCountCtrl;
  late TextEditingController _deviceInfoCtrl;
  late TextEditingController _fcmTokenCtrl;
  late bool _isActive;
  late bool _isBlocked;
  late bool _isSuspended;
  late bool _bonusDistributed;
  late bool _hasWithdrawnBefore;
  late bool _verificationBannerShown;

  @override
  void initState() {
    super.initState();
    _user = widget.initialUser;
    _initControllers();
  }

  String _formatDateOfBirth(String raw) {
    if (raw.isEmpty) return '';
    // Handle serialized Timestamp string e.g. Timestamp(seconds=1125633600, nanoseconds=0)
    if (raw.contains('Timestamp') && raw.contains('seconds=')) {
      try {
        final match = RegExp(r'seconds=(\d+)').firstMatch(raw);
        if (match != null) {
          final sec = int.parse(match.group(1)!);
          final dt = DateTime.fromMillisecondsSinceEpoch(sec * 1000);
          return DateFormat('d MMMM yyyy').format(dt);
        }
      } catch (_) {}
    }
    final dt = DateTime.tryParse(raw);
    if (dt != null) {
      return DateFormat('d MMMM yyyy').format(dt);
    }
    return raw;
  }

  void _initControllers() {
    _subscriptionStatus = _toDropdownSafeValue(_user.subscriptionStatus);
    _accountStatus = _toAccountStatusSafeValue(_user.status);

    _nameCtrl = TextEditingController(text: _user.name);
    _phoneCtrl = TextEditingController(text: _user.phone);
    _emailCtrl = TextEditingController(text: _user.email);
    _bioCtrl = TextEditingController(text: _user.bio);
    _dobCtrl = TextEditingController(text: _formatDateOfBirth(_user.dateOfBirth));
    _referCodeCtrl = TextEditingController(text: _user.referCode);
    _referredByCtrl = TextEditingController(text: _user.referredBy);

    final bal = _user.balance;
    _totalCtrl = TextEditingController(text: bal['total']?.toString() ?? '0');
    _earningCtrl = TextEditingController(text: bal['earning']?.toString() ?? '0');
    _rechargeCtrl = TextEditingController(text: (bal['recharge_balance'] ?? bal['recharge'])?.toString() ?? '0');
    _referralCtrl = TextEditingController(text: bal['referral']?.toString() ?? '0');
    _voucherCtrl = TextEditingController(text: bal['voucher']?.toString() ?? '0');
    _withdrawnCtrl = TextEditingController(text: bal['withdrawn']?.toString() ?? '0');

    _rankCountCtrl = TextEditingController(text: _user.rankCount?.toString() ?? '0');
    _deviceInfoCtrl = TextEditingController(text: _user.deviceInfo);
    _fcmTokenCtrl = TextEditingController(text: _user.fcmToken);

    _isActive = _user.isActive;
    _isBlocked = _user.isBlocked;
    _isSuspended = _user.isSuspended;
    _bonusDistributed = _user.bonusDistributed;
    _hasWithdrawnBefore = _user.hasWithdrawnBefore;
    _verificationBannerShown = _user.verificationBannerShown;
  }

  String _toDropdownSafeValue(String? raw) {
    final s = (raw ?? 'none').toLowerCase().trim();
    if (s == 'plan_320' || s == 'approved' || s == 'verified') return 'plan_320';
    return 'none';
  }

  String _toAccountStatusSafeValue(String? raw) {
    final s = (raw ?? 'active').toLowerCase().trim();
    if (s == 'blocked' || s == 'suspended' || s == 'inactive') return s;
    return 'active';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _bioCtrl.dispose();
    _dobCtrl.dispose();
    _referCodeCtrl.dispose();
    _referredByCtrl.dispose();

    _totalCtrl.dispose();
    _earningCtrl.dispose();
    _rechargeCtrl.dispose();
    _referralCtrl.dispose();
    _voucherCtrl.dispose();
    _withdrawnCtrl.dispose();

    _rankCountCtrl.dispose();
    _deviceInfoCtrl.dispose();
    _fcmTokenCtrl.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final updatedBalance = {
        'total': num.tryParse(_totalCtrl.text) ?? (_user.balance['total'] ?? 0),
        'earning': num.tryParse(_earningCtrl.text) ?? 0,
        'recharge_balance': num.tryParse(_rechargeCtrl.text) ?? 0,
        'referral': num.tryParse(_referralCtrl.text) ?? 0,
        'voucher': num.tryParse(_voucherCtrl.text) ?? 0,
        'withdrawn': num.tryParse(_withdrawnCtrl.text) ?? 0,
      };

      final updatedUser = _user.copyWith(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        dateOfBirth: _dobCtrl.text.trim(),
        referCode: _referCodeCtrl.text.trim(),
        referredBy: _referredByCtrl.text.trim(),
        subscriptionStatus: _subscriptionStatus,
        balance: updatedBalance,
        status: _accountStatus,
        isActive: _isActive,
        isBlocked: _isBlocked,
        isSuspended: _isSuspended,
        deviceInfo: _deviceInfoCtrl.text.trim(),
        rankCount: num.tryParse(_rankCountCtrl.text) ?? 0,
        bonusDistributed: _bonusDistributed,
        hasWithdrawnBefore: _hasWithdrawnBefore,
        verificationBannerShown: _verificationBannerShown,
        fcmToken: _fcmTokenCtrl.text.trim(),
      );

      context.read<UserManagementBloc>().add(UpdateUserEvent(updatedUser));
    }
  }

  void _copyToClipboard(String text, String label) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF00CED1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('User Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00CED1),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            tooltip: 'Delete User',
            onPressed: () => _showDeleteConfirmation(context, _user.id, _user.name, isMainProfile: true),
          ),
        ],
      ),
      body: BlocConsumer<UserManagementBloc, UserManagementState>(
        listener: (context, state) {
          if (state is UserUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
            );
            setState(() {
              _user = state.updatedUser;
              _subscriptionStatus = _toDropdownSafeValue(_user.subscriptionStatus);
              _accountStatus = _toAccountStatusSafeValue(_user.status);
            });
          } else if (state is UserUpdateFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Update failed: ${state.message}'), backgroundColor: Colors.red),
            );
          } else if (state is UserDeletionSuccess) {
            Navigator.of(context, rootNavigator: true).pop();
            if (state.isMainProfile) {
              Navigator.of(context).popUntil((route) => route.isFirst);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User permanently deleted.'), backgroundColor: Colors.red),
              );
            }
          } else if (state is UserDeletionFailure) {
            if (state.isMainProfile) {
              Navigator.of(context).popUntil((route) => route.isFirst);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deletion failed: ${state.message}'), backgroundColor: Colors.red),
              );
            }
          }
        },
        builder: (context, state) {
          if (state is UserManagementLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00CED1)));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 48.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Plan / Verification Status'),
                  const SizedBox(height: 12),
                  _buildSubscriptionSelector(),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Personal Details'),
                  const SizedBox(height: 12),
                  _buildPersonalDetailsGrid(),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Referral Information'),
                  const SizedBox(height: 12),
                  _buildReferralGrid(),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Financial Balances'),
                  const SizedBox(height: 12),
                  _buildBalanceGrid(),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Account Status & Flags'),
                  const SizedBox(height: 12),
                  _buildStatusAndFlagsSection(),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Raw Document Fields'),
                  const SizedBox(height: 12),
                  _buildRawDocumentCard(),
                  const SizedBox(height: 32),

                  _buildSaveButton(),
                  const SizedBox(height: 32),

                  _buildSectionTitle('Additional Information & Actions'),
                  const SizedBox(height: 12),
                  _buildNavigationButtons(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader() {
    final bool isUserVerified = _user.isVerified;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 1),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isUserVerified 
                        ? [const Color(0xFF00CED1), const Color(0xFF00E676)]
                        : [Colors.grey[400]!, Colors.grey[600]!],
                  ),
                ),
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _user.profileImageUrl.isNotEmpty ? NetworkImage(_user.profileImageUrl) : null,
                  child: _user.profileImageUrl.isEmpty ? Icon(Icons.person, size: 36, color: Colors.grey[400]) : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _user.name.isNotEmpty ? _user.name : 'Unnamed User',
                      style: TextStyle(color: Colors.grey[900], fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    _buildStatusBadge(),
                    const SizedBox(height: 6),
                    Text(
                      _user.joinedAt != null 
                          ? 'Joined: ${DateFormat('MMM dd, yyyy  hh:mm a').format(_user.joinedAt!)}' 
                          : 'Joined: N/A',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    if (_user.lastLoginAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Last Login: ${DateFormat('MMM dd, yyyy  hh:mm a').format(_user.lastLoginAt!)}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (_user.bio.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.format_quote, size: 18, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _user.bio,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _copyToClipboard(_user.id, 'User UID'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00CED1).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF00CED1).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fingerprint, size: 16, color: Color(0xFF00CED1)),
                        const SizedBox(width: 6),
                        Text(
                          'UID: ${_user.id}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0097A7)),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.copy, size: 14, color: Color(0xFF00CED1)),
                      ],
                    ),
                  ),
                ),
              ),
              if (_user.deviceInfo.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.devices, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        _user.deviceInfo,
                        style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final bool isUserVerified = _user.isVerified;

    Color bgColor = isUserVerified ? const Color(0xFFE8F8F5) : Colors.grey.withValues(alpha: 0.12);
    Color borderColor = isUserVerified ? const Color(0xFF00CED1) : Colors.grey;
    Color textColor = isUserVerified ? const Color(0xFF00897B) : Colors.grey[700]!;
    String text = isUserVerified ? 'Verified User' : 'Unverified User';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUserVerified ? Icons.check_circle : Icons.cancel_outlined,
            size: 13,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            text.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(color: Colors.grey[800], fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSubscriptionSelector() {
    return DropdownButtonFormField<String>(
      initialValue: _subscriptionStatus,
      decoration: InputDecoration(
        labelText: 'Account Verification Plan',
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00CED1)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dropdownColor: Colors.white,
      style: TextStyle(color: Colors.grey[900], fontWeight: FontWeight.w600, fontSize: 14),
      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00CED1)),
      items: const [
        DropdownMenuItem(
          value: 'none',
          child: Row(
            children: [
              Icon(Icons.block, color: Colors.grey, size: 18),
              SizedBox(width: 8),
              Text('Unverified User'),
            ],
          ),
        ),
        DropdownMenuItem(
          value: 'plan_320',
          child: Row(
            children: [
              Icon(Icons.verified, color: Color(0xFF00CED1), size: 18),
              SizedBox(width: 8),
              Text('Verified User (Plan 320)'),
            ],
          ),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _subscriptionStatus = value;
          });
        }
      },
    );
  }

  Widget _buildPersonalDetailsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildTextField('Name', _nameCtrl, icon: Icons.person)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField('Phone', _phoneCtrl, icon: Icons.phone)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTextField('Email', _emailCtrl, icon: Icons.email)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField('Date of Birth', _dobCtrl, icon: Icons.cake, isRequired: false)),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField('Bio', _bioCtrl, icon: Icons.edit_note, isRequired: false),
      ],
    );
  }

  Widget _buildReferralGrid() {
    return Row(
      children: [
        Expanded(child: _buildTextField('Refer Code', _referCodeCtrl, icon: Icons.qr_code)),
        const SizedBox(width: 12),
        Expanded(child: _buildTextField('Referred By', _referredByCtrl, icon: Icons.person_pin, isRequired: false)),
      ],
    );
  }

  Widget _buildBalanceGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.3,
      children: [
        _buildTextField('Total Balance', _totalCtrl, isNumber: true, icon: Icons.account_balance, color: Colors.blueGrey, readOnly: true),
        _buildTextField('Earning Balance', _earningCtrl, isNumber: true, icon: Icons.monetization_on, color: Colors.green),
        _buildTextField('Recharge Balance', _rechargeCtrl, isNumber: true, icon: Icons.bolt, color: Colors.teal),
        _buildTextField('Referral Earnings', _referralCtrl, isNumber: true, icon: Icons.group_add, color: Colors.orange),
        _buildTextField('Voucher Balance', _voucherCtrl, isNumber: true, icon: Icons.card_giftcard, color: Colors.purple),
        _buildTextField('Total Withdrawn', _withdrawnCtrl, isNumber: true, icon: Icons.money_off, color: Colors.red),
      ],
    );
  }

  Widget _buildStatusAndFlagsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _accountStatus,
                  decoration: InputDecoration(
                    labelText: 'Account Status',
                    labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                    prefixIcon: const Icon(Icons.shield_outlined, color: Colors.indigo, size: 18),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'blocked', child: Text('Blocked')),
                    DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                    DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _accountStatus = val;
                        if (val == 'blocked') _isBlocked = true;
                        if (val == 'suspended') _isSuspended = true;
                        if (val == 'active') {
                          _isBlocked = false;
                          _isSuspended = false;
                          _isActive = true;
                        }
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _buildTextField(
                  'Rank Count',
                  _rankCountCtrl,
                  isNumber: true,
                  icon: Icons.military_tech,
                  color: Colors.amber[800],
                  isRequired: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            'Device Info',
            _deviceInfoCtrl,
            icon: Icons.smartphone,
            color: Colors.blueGrey,
            isRequired: false,
          ),
          const Divider(height: 24),
          SwitchListTile(
            title: const Text('Account Is Active', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Toggles general account activity and login access', style: TextStyle(fontSize: 12)),
            value: _isActive,
            activeThumbColor: const Color(0xFF00CED1),
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => setState(() => _isActive = val),
          ),
          SwitchListTile(
            title: const Text('Account Is Blocked', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Block user from making requests or accessing the app', style: TextStyle(fontSize: 12)),
            value: _isBlocked,
            activeThumbColor: Colors.redAccent,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => setState(() => _isBlocked = val),
          ),
          SwitchListTile(
            title: const Text('Account Is Suspended', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Temporary suspension of user features', style: TextStyle(fontSize: 12)),
            value: _isSuspended,
            activeThumbColor: Colors.orange,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => setState(() => _isSuspended = val),
          ),
          const Divider(height: 20),
          SwitchListTile(
            title: const Text('Bonus Distributed', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Marks if multi-generation signup bonus has been credited', style: TextStyle(fontSize: 12)),
            value: _bonusDistributed,
            activeThumbColor: const Color(0xFF00CED1),
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => setState(() => _bonusDistributed = val),
          ),
          SwitchListTile(
            title: const Text('First Withdrawal Done', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Tracks whether user has made at least one successful withdrawal', style: TextStyle(fontSize: 12)),
            value: _hasWithdrawnBefore,
            activeThumbColor: const Color(0xFF00CED1),
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => setState(() => _hasWithdrawnBefore = val),
          ),
          SwitchListTile(
            title: const Text('Verification Banner Shown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Tracks popup/banner notification status for the user', style: TextStyle(fontSize: 12)),
            value: _verificationBannerShown,
            activeThumbColor: const Color(0xFF00CED1),
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => setState(() => _verificationBannerShown = val),
          ),
          const Divider(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTextField(
                  'FCM Token',
                  _fcmTokenCtrl,
                  icon: Icons.token,
                  color: Colors.indigo,
                  isRequired: false,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: IconButton(
                  icon: const Icon(Icons.copy, color: Color(0xFF00CED1)),
                  tooltip: 'Copy FCM Token',
                  onPressed: () => _copyToClipboard(_fcmTokenCtrl.text, 'FCM Token'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRawDocumentCard() {
    final entries = _user.rawMap.entries.toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: const Icon(Icons.data_object, color: Color(0xFF00CED1)),
        title: const Text('View All Raw Document Keys & Values', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text('${entries.length} raw fields found in Firestore', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        '${e.key}: ',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                      ),
                      Expanded(
                        child: SelectableText(
                          '${e.value}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    IconData? icon,
    Color? color,
    bool readOnly = false,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: TextStyle(color: readOnly ? Colors.grey[600] : Colors.grey[900], fontWeight: FontWeight.w600, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
        prefixIcon: icon != null ? Icon(icon, color: color ?? Colors.grey[500], size: 18) : null,
        filled: true,
        fillColor: readOnly ? Colors.grey[100] : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00CED1), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      validator: isRequired
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Required';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _saveProfile,
      icon: const Icon(Icons.save, color: Colors.white),
      label: const Text(
        'SAVE & UPDATE USER PROFILE',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.1),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: const Color(0xFF00CED1),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Column(
      children: [
        _buildNavButton(
          title: '10 Generation Refer List',
          subtitle: 'View full 10 level downline network',
          icon: Icons.account_tree,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => UserGenerationScreen(userId: _user.id)));
          },
        ),
        const SizedBox(height: 10),
        _buildNavButton(
          title: 'User Income History',
          subtitle: 'View all credit / debit transactions & commissions',
          icon: Icons.history,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => UserIncomeHistoryScreen(userId: _user.id)));
          },
        ),
        const SizedBox(height: 10),
        _buildNavButton(
          title: 'User Micro Jobs Progress',
          subtitle: 'Check job submissions and completion records',
          icon: Icons.work_outline,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => UserMicroJobsScreen(userId: _user.id)));
          },
        ),
      ],
    );
  }

  Widget _buildNavButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00CED1).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF00CED1), size: 20),
        ),
        title: Text(title, style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String uid, String name, {bool isMainProfile = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            const SizedBox(width: 10),
            Text('Confirm Deletion', style: TextStyle(color: Colors.grey[900])),
          ],
        ),
        content: Text(
          'Are you sure you want to completely delete $name? This action is irreversible and will wipe all related data.',
          style: TextStyle(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('CANCEL', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<UserManagementBloc>().add(
                CascadeDeleteUserEvent(
                  targetUid: uid,
                  isMainProfile: isMainProfile,
                  initialReferCodeForRefresh: isMainProfile ? null : _user.referCode,
                ),
              );
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
