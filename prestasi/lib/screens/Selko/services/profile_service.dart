
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ============================================================
  /// EMAIL -> UNIVERSITY
  /// ============================================================

  String extractDomainFromEmail(String? email) {
    if (email == null || !email.contains('@')) return "";

    String domain = email.split('@').last.toLowerCase().trim();

    final subDomainsToRemove = [
      'students.',
      'mahasiswa.',
      'student.',
    ];

    for (final sub in subDomainsToRemove) {
      if (domain.startsWith(sub)) {
        domain = domain.replaceFirst(sub, '');
        break;
      }
    }

    return domain;
  }

  Future<String> getUniversityName(String? email) async {
    final domain = extractDomainFromEmail(email);

    if (domain.isEmpty) {
      return "Universitas Tidak Diketahui";
    }

    try {
      final doc =
          await _firestore.collection('universities').doc(domain).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return data['name'] ?? "Universitas Tanpa Nama";
      }

      final parts = domain.split('.');

      if (parts.isNotEmpty &&
          parts.first != 'gmail' &&
          parts.first != 'yahoo') {
        return "Universitas ${parts.first.toUpperCase()}";
      }
    } catch (e) {
      print("Error ambil universitas: $e");
    }

    return "Universitas Belum Diatur";
  }

  /// ============================================================
  /// PROFILE
  /// ============================================================

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      return doc.data();
    } catch (e) {
      print("Error ambil data user: $e");
      return null;
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    required String displayName,
    required String username,
    required String role,
    required String bio,
    required String availabilityStatus,
    required Map<String, dynamic> contact,
  }) async {
    try {
      final docRef = _firestore.collection('users').doc(userId);

      final docSnap = await docRef.get();

      final cleanedUsername =
          username.replaceAll('@', '').trim();

      final Map<String, dynamic> updateData = {
        'displayName': displayName.trim(),
        'username': cleanedUsername,
        'role': role.trim(),
        'bio': bio.trim(),
        'availabilityStatus': availabilityStatus,
        'contact': contact,
      };

      if (!docSnap.exists ||
          !(docSnap.data()?.containsKey('createdAt') ?? false)) {
        updateData['createdAt'] =
            FieldValue.serverTimestamp();
      }

      await docRef.set(
        updateData,
        SetOptions(merge: true),
      );

      if (_auth.currentUser != null &&
          _auth.currentUser!.uid == userId) {
        await _auth.currentUser!
            .updateDisplayName(displayName.trim());
      }

      await logActivity(userId);
    } catch (e) {
      print("Error update profile: $e");
      rethrow;
    }
  }

  /// ============================================================
  /// ACTIVE DAYS
  /// ============================================================

  int calculateActiveDays(
    Timestamp? createdAtTimestamp,
  ) {
    if (createdAtTimestamp == null) {
      return 1;
    }

    final createdAt = createdAtTimestamp.toDate();
    final now = DateTime.now();

    final createdDate = DateTime(
      createdAt.year,
      createdAt.month,
      createdAt.day,
    );

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final difference =
        today.difference(createdDate).inDays;

    return difference < 0 ? 1 : difference + 1;
  }

  /// ============================================================
  /// PROJECT VIEWS
  /// ============================================================

  Stream<int> getTotalProjectViews(String userId) {
  return _firestore
      .collection('projects')
      .where('uid', isEqualTo: userId)
      .snapshots()
        .map((snapshot) {
      int totalViews = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final viewsRaw = data['views'];

        if (viewsRaw is num) {
          totalViews += viewsRaw.toInt();
        } else if (viewsRaw is String) {
          totalViews += int.tryParse(viewsRaw) ?? 0;
        }
      }

      return totalViews;
    });
  }

  /// ============================================================
  /// FOLLOW SYSTEM
  /// ============================================================

  Future<void> toggleFollow({
    required String currentUserId,
    required String targetUserId,
    required bool isFollowing,
  }) async {
    try {
      final targetUserDoc =
          _firestore.collection('users').doc(targetUserId);

      if (isFollowing) {
        await targetUserDoc.update({
          'followers':
              FieldValue.arrayRemove([currentUserId]),
        });
      } else {
        await targetUserDoc.update({
          'followers':
              FieldValue.arrayUnion([currentUserId]),
        });

        await logActivity(currentUserId);
      }
    } catch (e) {
      print("Gagal follow: $e");
    }
  }
  

  /// ============================================================
  /// LIKES
  /// ============================================================

  Stream<int> getTotalUserLikes(String userId) {
    return _firestore
        .collection('projects')
        .where('uid', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      int totalLikes = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (data.containsKey('likes')) {
          final likesRaw = data['likes'];

          if (likesRaw is List) {
            totalLikes += likesRaw.length;
          } else if (likesRaw is num) {
            totalLikes += likesRaw.toInt();
          }
        }
      }

      return totalLikes;
    });
  }

    /// ============================================================
    /// GITHUB CONTRIBUTION SYSTEM
    /// ============================================================

    Future<void> logActivity(String userId) async {
      try {
        final now = DateTime.now();

        final String docId =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('activity')
            .doc(docId);

        Future<void> logActivity(String userId) async {
  try {
    final now = DateTime.now();

    final docId =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('activity')
        .doc(docId);

    await docRef.set({
      'count': FieldValue.increment(1),
      'lastUpdated': Timestamp.now(),
    }, SetOptions(merge: true));
  } catch (e) {
    print("Error log activity: $e");
  }
}
      } catch (e) {
        print("Error log activity: $e");
      }
    }

    Stream<Map<String, int>> getActivityMap(
      String userId,
    ) {
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('activity')
          .snapshots()
          .map((snapshot) {
        final Map<String, int> activityMap = {};

        for (final doc in snapshot.docs) {
          final data = doc.data();

          activityMap[doc.id] =
              ((data['count'] ?? 0) as num).toInt();
        }

        return activityMap;
      });
    }

    Stream<int> getTotalContributions(
      String userId,
    ) {
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('activity')
          .snapshots()
          .map((snapshot) {
        int total = 0;

        for (final doc in snapshot.docs) {
          final data = doc.data();

          total +=
              ((data['count'] ?? 0) as num).toInt();
        }

        return total;
      });
    }

      Future<int> getCurrentStreak(
      String userId,
    ) async {
      try {
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('activity')
            .get();

        final Map<String, int> activity = {};

        for (final doc in snapshot.docs) {
          final data = doc.data();

          activity[doc.id] =
              ((data['count'] ?? 0) as num).toInt();
        }

        int streak = 0;

        DateTime currentDate = DateTime.now();

        while (true) {
          final key =
              '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';

          if ((activity[key] ?? 0) > 0) {
            streak++;
            currentDate =
                currentDate.subtract(const Duration(days: 1));
          } else {
            break;
          }
        }

        return streak;
      } catch (e) {
        print("Error hitung streak: $e");
        return 0;
      }
    }

    /// ============================================================
    /// LONGEST STREAK
    /// ============================================================

    Future<int> getLongestStreak(String userId) async {
      try {
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('activity')
            .get();

        final List<DateTime> dates = [];

        for (final doc in snapshot.docs) {
          final parts = doc.id.split('-');

          if (parts.length == 3) {
            dates.add(
              DateTime(
                int.parse(parts[0]),
                int.parse(parts[1]),
                int.parse(parts[2]),
              ),
            );
          }
        }

        if (dates.isEmpty) return 0;

        dates.sort();

        int longest = 1;
        int current = 1;

        for (int i = 1; i < dates.length; i++) {
          final diff =
              dates[i].difference(dates[i - 1]).inDays;

          if (diff == 1) {
            current++;

            if (current > longest) {
              longest = current;
            }
          } else {
            current = 1;
          }
        }

        return longest;
      } catch (e) {
        print("Error longest streak: $e");
        return 0;
      }
    }

    /// ============================================================
    /// ACTIVE DAYS
    /// ============================================================

    Future<int> getActiveDays(String userId) async {
      try {
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('activity')
            .get();

        return snapshot.docs.length;
      } catch (e) {
        print("Error active days: $e");
        return 0;
      }
    }
  }