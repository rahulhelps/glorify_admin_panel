import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerifiedUsersSummaryScreen extends StatelessWidget {
  const VerifiedUsersSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Live real-time stream using whereIn — single indexed query covering verified statuses.
    final Stream<QuerySnapshot> verifiedStream = FirebaseFirestore.instance
        .collection('users')
        .where('subscriptionStatus', whereIn: ['approved', 'plan_320'])
        .orderBy('joinedAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Verified Members', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00CED1),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: verifiedStream,
        builder: (context, snapshot) {
          // ── Loading ──
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00CED1)));
          }

          // ── Error ──
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error loading data:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 15)),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          // ── Summary header counts ──
          int premiumCount = 0;
          for (final doc in docs) {
            final status = (doc['subscriptionStatus'] as String? ?? 'none').toLowerCase();
            if (status == 'plan_320' || status == 'approved') { premiumCount++; }
          }

          return Column(
            children: [
              // ── Stats bar ──
              Container(
                color: const Color(0xFF00CED1),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    _buildStatChip('Total Verified', docs.length.toString(), Colors.white, const Color(0xFF00CED1)),
                    const SizedBox(width: 8),
                    _buildStatChip('Active Plan', premiumCount.toString(), Colors.amber[100]!, Colors.amber[800]!),
                  ],
                ),
              ),

              // ── Empty ──
              if (docs.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_off_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text('No verified members found.',
                            style: TextStyle(fontSize: 16, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final status = data['subscriptionStatus']?.toString() ?? 'none';
                      final name = data['name']?.toString() ?? '';
                      final phone = data['phone']?.toString() ?? '';
                      final email = data['email']?.toString() ?? '';
                      final profileUrl = data['profileImageUrl']?.toString() ?? '';
                      final referCode = data['referCode']?.toString() ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        color: Colors.white,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
                            child: profileUrl.isEmpty
                                ? Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          title: Text(
                            name.isNotEmpty ? name : 'Unknown User',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 3),
                              Text(
                                email.isNotEmpty ? email : phone,
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                              if (referCode.isNotEmpty)
                                Text('Code: $referCode',
                                    style: const TextStyle(
                                        color: Color(0xFF00897B),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                            ],
                          ),
                          trailing: _buildPlanBadge(status),
                          isThreeLine: referCode.isNotEmpty,
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bg.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: bg.withValues(alpha: 0.6)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: fg == const Color(0xFF00CED1) ? Colors.white : fg,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
            Text(label,
                style: TextStyle(
                    color: fg == const Color(0xFF00CED1) ? Colors.white70 : fg,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanBadge(String status) {
    Color bg, fg;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'plan_320':
      case 'approved':
        bg = Colors.amber[50]!;
        fg = Colors.amber[800]!;
        label = 'Verified';
        icon = Icons.star;
        break;
      default:
        bg = Colors.grey[100]!;
        fg = Colors.grey[600]!;
        label = 'None';
        icon = Icons.block;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
