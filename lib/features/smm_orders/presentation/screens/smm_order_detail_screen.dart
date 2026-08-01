import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../data/models/smm_order_model.dart';
import '../bloc/smm_order_bloc.dart';

class SmmOrderDetailScreen extends StatefulWidget {
  final SmmOrderModel order;

  const SmmOrderDetailScreen({super.key, required this.order});

  @override
  State<SmmOrderDetailScreen> createState() => _SmmOrderDetailScreenState();
}

class _SmmOrderDetailScreenState extends State<SmmOrderDetailScreen> {
  final TextEditingController _adminNoteCtrl = TextEditingController();

  @override
  void dispose() {
    _adminNoteCtrl.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard!'), duration: const Duration(seconds: 1)),
    );
  }

  void _handleApprove() {
    FocusScope.of(context).unfocus();
    context.read<SmmOrderBloc>().add(ApproveSmmOrder(widget.order.id));
  }

  void _handleReject() {
    FocusScope.of(context).unfocus();
    final note = _adminNoteCtrl.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide an Admin Note for rejection.'), backgroundColor: Colors.orange),
      );
      return;
    }
    context.read<SmmOrderBloc>().add(RejectSmmOrder(widget.order.id, note));
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Order Details', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocConsumer<SmmOrderBloc, SmmOrderState>(
        listener: (context, state) {
          if (state is SmmOrderActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          } else if (state is SmmOrderActionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Action failed: ${state.message}'), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is SmmOrderActionLoading;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(order),
                    const SizedBox(height: 24),
                    const Text('Account Credentials', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildCredentialCard('Username', order.username),
                    _buildCredentialCard('Email', order.email),
                    _buildCredentialCard('Password', order.password),
                    _buildCredentialCard('2FA Code', order.twoFA),
                    const SizedBox(height: 32),
                    const Text('Admin Feedback / Note', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _adminNoteCtrl,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter reason for rejection or custom approval note...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.cyanAccent)),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleReject,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                              foregroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.redAccent)),
                            ),
                            child: const Text('REJECT ASSET', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleApprove,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent.withValues(alpha: 0.2),
                              foregroundColor: Colors.greenAccent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.greenAccent)),
                            ),
                            child: const Text('APPROVE ASSET', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              if (isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(SmmOrderModel order) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            child: const Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.userName.isNotEmpty ? order.userName : 'Unknown User',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Platform: ${order.type.toUpperCase()}',
                  style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  order.submittedAt != null ? DateFormat('MMM dd, yyyy - hh:mm a').format(order.submittedAt!) : 'Date unknown',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialCard(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: ListTile(
          title: Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
          subtitle: Text(
            value.isNotEmpty ? value : 'N/A',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.copy, color: Colors.cyanAccent),
            onPressed: value.isNotEmpty ? () => _copyToClipboard(value, label) : null,
          ),
        ),
      ),
    );
  }
}
