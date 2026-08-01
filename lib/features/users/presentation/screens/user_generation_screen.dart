import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../bloc/user_management_bloc.dart';
import '../../data/models/user_model.dart';
import '../../../../../core/utils/subscription_helper.dart';

class UserGenerationScreen extends StatefulWidget {
  final String userId;
  const UserGenerationScreen({super.key, required this.userId});

  @override
  State<UserGenerationScreen> createState() => _UserGenerationScreenState();
}

class _UserGenerationScreenState extends State<UserGenerationScreen> {
  bool _isLoadingUser = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserAndNetwork();
  }

  void _fetchUserAndNetwork() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (doc.exists) {
        final userData = doc.data()!;
        final referCode = userData['referCode'] as String?;
        if (referCode != null && referCode.isNotEmpty) {
          if (mounted) {
            context.read<UserManagementBloc>().add(LoadReferralNetworkEvent(referCode));
            setState(() {
              _isLoadingUser = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoadingUser = false;
              _errorMessage = 'User has no refer code.';
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingUser = false;
            _errorMessage = 'User not found.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
          _errorMessage = 'Error fetching user data: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('10-Generation Referral', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF00CED1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingUser
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00CED1)))
          : _errorMessage != null
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)),
                  ),
                )
              : BlocBuilder<UserManagementBloc, UserManagementState>(
                  builder: (context, state) {
                    if (state is ReferralNetworkLoaded) {
                      final generations = state.generations;
                      if (generations.isEmpty || generations.every((gen) => gen.isEmpty)) {
                        return Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Text(
                              'No referral network found.',
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: generations.length,
                        itemBuilder: (context, genIndex) {
                          final genUsers = generations[genIndex];
                          if (genUsers.isEmpty) return const SizedBox();
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                                child: Text(
                                  'Generation ${genIndex + 1} (${genUsers.length} Users)',
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ...genUsers.map((user) => _buildUserTile(user)),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      );
                    } else if (state is UserManagementLoading) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF00CED1)));
                    } else {
                      return const SizedBox();
                    }
                  },
                ),
    );
  }

  Widget _buildUserTile(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, spreadRadius: 1),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: Colors.grey[200],
          backgroundImage: user.profileImageUrl.isNotEmpty ? NetworkImage(user.profileImageUrl) : null,
          child: user.profileImageUrl.isEmpty ? Icon(Icons.person, color: Colors.grey[400]) : null,
        ),
        title: Text(user.name.isNotEmpty ? user.name : 'Unknown User', style: TextStyle(color: Colors.grey[900], fontWeight: FontWeight.bold)),
        subtitle: Text(user.phone, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF00CED1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isVerifiedStatus(user.subscriptionStatus) ? 'Active' : 'Inactive',
            style: TextStyle(
              color: isVerifiedStatus(user.subscriptionStatus) ? Colors.green[700] : Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
