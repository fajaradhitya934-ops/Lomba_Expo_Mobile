import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SocialService {
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

Future<void> toggleFollow({
required String currentUserId,
required String targetUserId,
required bool isFollowing,
}) async {
try {
print("=== FOLLOW DEBUG ===");
  final currentUserRef =
      _firestore.collection('users').doc(currentUserId);

  final targetUserRef =
      _firestore.collection('users').doc(targetUserId);

  if (isFollowing) {
    // UNFOLLOW

    await currentUserRef.update({
      'following': FieldValue.arrayRemove([targetUserId])
    });

    await targetUserRef.update({
      'followers': FieldValue.arrayRemove([currentUserId])
    });

    print("UNFOLLOW SUCCESS");
  } else {
    // FOLLOW

    await currentUserRef.update({
      'following': FieldValue.arrayUnion([targetUserId])
    });

    await targetUserRef.update({
      'followers': FieldValue.arrayUnion([currentUserId])
    });

    print("MEMBUAT NOTIFIKASI...");

    await _firestore
    .collection('users')
    .doc(targetUserId)
    .collection('notifications')
    .add({
  'senderId': currentUserId,
  'senderName':
      FirebaseAuth.instance.currentUser?.displayName ?? 'Someone',
  'type': 'follow',
  'isRead': false,
  'createdAt': FieldValue.serverTimestamp(),
});

    print("NOTIFIKASI BERHASIL DISIMPAN");
  }

  print("FOLLOW SUCCESS");
} catch (e, stackTrace) {
  print("FOLLOW ERROR: $e");
  print(stackTrace);
}

}
}
