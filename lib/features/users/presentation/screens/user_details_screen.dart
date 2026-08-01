import 'package:flutter/material.dart';
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
  
  final _formKey = GlobalKey<FormState>();

  // Controllers for Credentials
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _referCodeCtrl;
  late TextEditingController _referredByCtrl;

  // Controllers for Balances
  late TextEditingController _totalCtrl;
  late TextEditingController _earningCtrl;
  late TextEditingController _referralCtrl;
  late TextEditingController _voucherCtrl;
  late TextEditingController _withdrawnCtrl;

  @override
  void initState() {
    super.initState();
    _user = widget.initialUser;
    _initControllers();
  }

  void _initControllers() {
    // _toDropdownSafeValue maps 'approved' → 'plan_320' so the dropdown
    // never receives a value that has no matching DropdownMenuItem.
    _subscriptionStatus = _toDropdownSafeValue(_user.subscriptionStatus);

    _phoneCtrl = TextEditingController(text: _user.phone);
    _emailCtrl = TextEditingController(text: _user.email);
    _referCodeCtrl = TextEditingController(text: _user.referCode);
    _referredByCtrl = TextEditingController(text: _user.referredBy);

    _totalCtrl = TextEditingController(text: _user.balance['total']?.toString() ?? '0');
    _earningCtrl = TextEditingController(text: _user.balance['earning']?.toString() ?? '0');
    _referralCtrl = TextEditingController(text: _user.balance['referral']?.toString() ?? '0');
    _voucherCtrl = TextEditingController(text: _user.balance['voucher']?.toString() ?? '0');
    _withdrawnCtrl = TextEditingController(text: _user.balance['withdrawn']?.toString() ?? '0');
  }

  // Converts any raw Firestore subscriptionStatus into one of the three values
  // the dropdown knows about: 'none', 'plan_250', or 'plan_320'.
  // Legacy 'approved' users are displayed as 'plan_320' (৳320 Premium).
  String _toDropdownSafeValue(String? raw) {
    final s = (raw ?? 'none').toLowerCase().trim();
    if (s == 'plan_320' || s == 'approved') return 'plan_320';
    if (s == 'plan_250') return 'plan_250';
    return 'none';
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _referCodeCtrl.dispose();
    _referredByCtrl.dispose();
    _totalCtrl.dispose();
    _earningCtrl.dispose();
    _referralCtrl.dispose();
    _voucherCtrl.dispose();
    _withdrawnCtrl.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final updatedBalance = {
        'total': num.tryParse(_totalCtrl.text) ?? 0,
        'earning': num.tryParse(_earningCtrl.text) ?? 0,
        'referral': num.tryParse(_referralCtrl.text) ?? 0,
        'voucher': num.tryParse(_voucherCtrl.text) ?? 0,
        'withdrawn': num.tryParse(_withdrawnCtrl.text) ?? 0,
      };

      final updatedUser = _user.copyWith(
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        referCode: _referCodeCtrl.text.trim(),
        referredBy: _referredByCtrl.text.trim(),
        subscriptionStatus: _subscriptionStatus,
        balance: updatedBalance,
      );

      context.read<UserManagementBloc>().add(UpdateUserEvent(updatedUser));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light mode background
      appBar: AppBar(
        title: const Text('User Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00CED1),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.white),
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
            });
          } else if (state is UserUpdateFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Update failed: ${state.message}'), backgroundColor: Colors.red),
            );
          } else if (state is UserDeletionSuccess) {
            Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading dialog
            
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
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  
                  _buildSectionTitle('Subscription Management'),
                  const SizedBox(height: 12),
                  _buildSubscriptionSelector(),
                  const SizedBox(height: 24),
                  
                  _buildSectionTitle('Credentials'),
                  const SizedBox(height: 12),
                  _buildCredentialsGrid(),
                  const SizedBox(height: 24),
                  
                  _buildSectionTitle('Financial Balance'),
                  const SizedBox(height: 12),
                  _buildBalanceGrid(),
                  const SizedBox(height: 32),
                  
                  _buildSaveButton(),
                  const SizedBox(height: 40),
                  
                  _buildSectionTitle('Additional Information'),
                  const SizedBox(height: 12),
                  _buildNavigationButtons(),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 1),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFF00CED1), Colors.blue]),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[200],
              backgroundImage: _user.profileImageUrl.isNotEmpty ? NetworkImage(_user.profileImageUrl) : null,
              child: _user.profileImageUrl.isEmpty ? Icon(Icons.person, size: 40, color: Colors.grey[400]) : null,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user.name.isNotEmpty ? _user.name : 'Unknown User',
                  style: TextStyle(color: Colors.grey[900], fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildStatusBadge(),
                const SizedBox(height: 8),
                Text(
                  _user.joinedAt != null 
                      ? 'Joined: ${DateFormat('MMM dd, yyyy').format(_user.joinedAt!)}' 
                      : 'Joined: N/A',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    Color borderColor;
    Color textColor;
    String text;

    if (_user.subscriptionStatus == 'plan_320' || _user.subscriptionStatus == 'approved') {
      bgColor = Colors.amber.withOpacity(0.1);
      borderColor = Colors.amber;
      textColor = Colors.amber[800]!;
      text = _user.subscriptionStatus == 'approved'
          ? '৳৩২০ ফুল প্রিমিয়াম প্ল্যান (Legacy)'
          : '৳৩২০ ফুল প্রিমিয়াম প্ল্যান';
    } else if (_user.subscriptionStatus == 'plan_250') {
      bgColor = Colors.blue.withOpacity(0.1);
      borderColor = Colors.blue;
      textColor = Colors.blue[800]!;
      text = '৳২৫০ বেসিক প্ল্যান';
    } else {
      bgColor = Colors.grey.withOpacity(0.1);
      borderColor = Colors.grey;
      textColor = Colors.grey[700]!;
      text = 'Unverified / No Active Plan';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(color: Colors.grey[800], fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSubscriptionSelector() {
    return DropdownButtonFormField<String>(
      value: _subscriptionStatus, // always 'none', 'plan_250', or 'plan_320'
      decoration: InputDecoration(
        labelText: 'Plan Status',
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
      items: [
        DropdownMenuItem(
          value: 'none',
          child: Row(
            children: [
              Icon(Icons.block, color: Colors.grey[600], size: 18),
              const SizedBox(width: 8),
              Text('Unverified / No Active Plan', style: TextStyle(color: Colors.grey[700])),
            ],
          ),
        ),
        DropdownMenuItem(
          value: 'plan_250',
          child: Row(
            children: [
              Icon(Icons.star_half, color: Colors.blue[600], size: 18),
              const SizedBox(width: 8),
              Text('৳২৫০ বেসিক প্ল্যান', style: TextStyle(color: Colors.blue[800])),
            ],
          ),
        ),
        DropdownMenuItem(
          value: 'plan_320',
          child: Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              Text('৳৩২০ ফুল প্রিমিয়াম প্ল্যান', style: TextStyle(color: Colors.amber[800])),
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

  Widget _buildCredentialsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.5,
      children: [
        _buildTextField('Phone', _phoneCtrl, icon: Icons.phone),
        _buildTextField('Email', _emailCtrl, icon: Icons.email),
        _buildTextField('Refer Code', _referCodeCtrl, icon: Icons.code),
        _buildTextField('Referred By', _referredByCtrl, icon: Icons.person_add),
      ],
    );
  }

  Widget _buildBalanceGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.5,
      children: [
        _buildTextField('Total Balance', _totalCtrl, isNumber: true, icon: Icons.lock, color: Colors.grey, readOnly: true),
        _buildTextField('Earning', _earningCtrl, isNumber: true, icon: Icons.monetization_on, color: Colors.green),
        _buildTextField('Referral', _referralCtrl, isNumber: true, icon: Icons.group_add, color: Colors.orange),
        _buildTextField('Voucher', _voucherCtrl, isNumber: true, icon: Icons.card_giftcard, color: Colors.purple),
        _buildTextField('Withdrawn', _withdrawnCtrl, isNumber: true, icon: Icons.money_off, color: Colors.red),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, IconData? icon, Color? color, bool readOnly = false}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: TextStyle(color: readOnly ? Colors.grey[600] : Colors.grey[900], fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        prefixIcon: icon != null ? Icon(icon, color: color ?? Colors.grey[500], size: 18) : null,
        filled: true,
        fillColor: readOnly ? Colors.grey[100] : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00CED1)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required';
        }
        return null;
      },
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _saveProfile,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: const Color(0xFF00CED1),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: const Text(
        'SAVE & UPDATE PROFILE',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Column(
      children: [
        _buildNavButton(
          title: 'Check 10-Generation Referral',
          icon: Icons.account_tree,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => UserGenerationScreen(userId: _user.id)));
          },
        ),
        const SizedBox(height: 12),
        _buildNavButton(
          title: 'Check Income History',
          icon: Icons.history,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => UserIncomeHistoryScreen(userId: _user.id)));
          },
        ),
        const SizedBox(height: 12),
        _buildNavButton(
          title: 'Check Micro Jobs',
          icon: Icons.work,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => UserMicroJobsScreen(userId: _user.id)));
          },
        ),
      ],
    );
  }

  Widget _buildNavButton({required String title, required IconData icon, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF00CED1).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF00CED1)),
      ),
      title: Text(title, style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
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
