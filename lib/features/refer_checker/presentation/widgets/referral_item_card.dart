import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../features/users/data/models/user_model.dart';
import '../../../../core/utils/subscription_helper.dart';

class ReferralItemCard extends StatelessWidget {
  final UserModel user;

  const ReferralItemCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isVerified = isVerifiedStatus(user.subscriptionStatus);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade50,
          backgroundImage: user.profileImageUrl.isNotEmpty 
              ? NetworkImage(user.profileImageUrl) 
              : null,
          radius: 24,
          child: user.profileImageUrl.isEmpty
              ? Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        title: Text(
          user.name.isNotEmpty ? user.name : 'Unknown User',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              user.email.isNotEmpty ? user.email : user.phone,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              'Code: ${user.referCode}',
              style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.w500, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              user.joinedAt != null 
                  ? DateFormat('dd MMM yyyy, hh:mm a').format(user.joinedAt!) 
                  : 'Joined date unknown',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isVerified ? Colors.teal : Colors.transparent,
            border: Border.all(color: isVerified ? Colors.teal : Colors.grey.shade400),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isVerified ? 'Verified' : 'Unverified',
            style: TextStyle(
              color: isVerified ? Colors.white : Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
