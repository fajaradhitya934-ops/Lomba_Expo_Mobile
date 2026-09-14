import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifikasi"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text("Belum ada notifikasi"),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {

              final data =
                  docs[index].data() as Map<String, dynamic>;

              final senderName =
                  data['senderName'] ?? 'Someone';

              final type =
                  data['type'] ?? '';

              String text = '';

              if (type == 'follow') {
                text = '$senderName mulai mengikuti Anda';
              }

              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.notifications),
                ),
                title: Text(text),
              );
            },
          );
        },
      ),
    );
  }
}