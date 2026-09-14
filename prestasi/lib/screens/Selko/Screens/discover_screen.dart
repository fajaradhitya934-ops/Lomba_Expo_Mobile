import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:prestasi/screens/Selko/services/social_service.dart';
import 'package:prestasi/screens/Selko/Screens/profile_screen.dart';
import 'package:prestasi/screens/Selko/Screens/add_project_screen.dart';
import 'package:prestasi/screens/Selko/services/profile_service.dart';
import 'package:prestasi/screens/Selko/Screens/notification_screen.dart';
import 'package:prestasi/screens/main_navigation_screen.dart';
import 'package:prestasi/screens/camera/camera_screen.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class DiscoverScreen extends StatefulWidget {
  final bool isDarkMode;
  const DiscoverScreen({super.key, this.isDarkMode = false});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final ScrollController _scrollController = ScrollController();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  String _searchQuery = '';

  final SocialService _socialService = SocialService();
  final Map<String, bool> _isProjectDescriptionExpandedMap = {};
  final Set<String> _activeOverlayProjectIds = {};

  late bool _isDarkMode;
  static const Color primaryColor = Color(0xFF3525CD);

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _logActivity();
  }

  Future<void> _logActivity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await ProfileService().logActivity(user.uid);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DiscoverScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkMode != widget.isDarkMode) {
      setState(() {
        _isDarkMode = widget.isDarkMode;
      });
    }
  }

  Future<void> _launchURL(String urlString) async {
    if (urlString.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Project ini tidak menyertakan Link Demo.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    String formattedUrl = urlString.trim();
    if (!formattedUrl.startsWith('http://') &&
        !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }

    final Uri url = Uri.parse(formattedUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Tidak dapat membuka link';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal membuka link: $urlString'),
              backgroundColor: const Color(0xFFBA1A1A)),
        );
      }
    }
  }

  Future<void> _toggleLikeProject(
      String projectId, String authorId, List currentLikes) async {
    if (_currentUserId.isEmpty || authorId.isEmpty) return;

    final DocumentReference projectRef =
        FirebaseFirestore.instance.collection('projects').doc(projectId);
    final DocumentReference authorRef =
        FirebaseFirestore.instance.collection('users').doc(authorId);

    bool isCurrentlyLiked = currentLikes.contains(_currentUserId);

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      if (isCurrentlyLiked) {
        batch.update(projectRef, {
          'likes': FieldValue.arrayRemove([_currentUserId])
        });
        batch.update(authorRef, {'totalLikes': FieldValue.increment(-1)});
      } else {
        batch.update(projectRef, {
          'likes': FieldValue.arrayUnion([_currentUserId])
        });
        batch.update(authorRef, {'totalLikes': FieldValue.increment(1)});
      }

      await batch.commit();
    } catch (e) {
      debugPrint("Gagal memproses Like: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor =
        _isDarkMode ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC);
    final Color appBarColor =
        _isDarkMode ? const Color(0xFF161B22) : const Color(0xFFFCF8FF);
    final Color cardColor =
        _isDarkMode ? const Color(0xFF161B22) : Colors.white;
    final Color borderStyleColor = _isDarkMode
        ? const Color(0xFF30363D)
        : const Color(0xFFC7C4D8).withValues(alpha: 0.3);

    final Color textColor =
        _isDarkMode ? Colors.white : const Color(0xFF1B1B24);
    final Color textVariantColor = _isDarkMode
        ? Colors.white.withValues(alpha: 0.7)
        : const Color(0xFF464555);

    final user = FirebaseAuth.instance.currentUser;
    final String userDisplayName =
        user?.displayName ?? user?.email?.split('@').first ?? 'User';

    return ScrollConfiguration(
      behavior: AppScrollBehavior(),
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: appBarColor,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(
                  user?.photoURL ??
                      'https://ui-avatars.com/api/?name=$userDisplayName',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  userDisplayName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : primaryColor,
                    letterSpacing: -0.01,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.mail_outline, color: textVariantColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationScreen()),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
      
        floatingActionButton: FloatingActionButton(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    AddProjectScreen(isDarkMode: _isDarkMode)),
          ),
          child: const Icon(Icons.add, size: 24),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: borderStyleColor),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: textVariantColor, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                },
                                style:
                                    GoogleFonts.plusJakartaSans(color: textColor),
                                decoration: InputDecoration(
                                  hintText:
                                      'Cari pengguna lain berdasarkan nama...',
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      color: textVariantColor.withValues(alpha: 0.6)),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  _searchQuery.trim().isEmpty ? 'User Lain' : 'Cari Pengguna Lain',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(
                        child: CircularProgressIndicator(color: primaryColor));

                  var users = snapshot.data!.docs
                      .where((doc) => doc.id != _currentUserId)
                      .toList();

                  if (_searchQuery.trim().isNotEmpty) {
                    users = users.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name =
                          (data['displayName'] ?? '').toString().toLowerCase();
                      return name
                          .contains(_searchQuery.trim().toLowerCase());
                    }).toList();
                  }

                  if (users.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20.0, horizontal: 20.0),
                      child: Text(
                        _searchQuery.trim().isEmpty
                            ? 'Belum ada pengguna lain.'
                            : 'Tidak ada pengguna bernama "$_searchQuery"',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, color: textVariantColor),
                      ),
                    );
                  }

                  return SizedBox(
                    height: 175,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14.0),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final userData =
                            users[index].data() as Map<String, dynamic>;
                        final targetUid = users[index].id;

                        List followersList = userData['followers'] ?? [];
                        bool isFollowing =
                            followersList.contains(_currentUserId);

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileScreen(
                                  userId: targetUid,
                                  isDarkMode: _isDarkMode,
                                  onThemeChanged: (bool newTheme) {
                                    setState(() {
                                      _isDarkMode = newTheme;
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 140,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderStyleColor),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                      alpha: _isDarkMode ? 0.2 : 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundImage: NetworkImage(
                                      userData['photoUrl'] ??
                                          'https://ui-avatars.com/api/?name=Student'),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  userData['displayName'] ?? 'Student',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: textColor),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  userData['role'] ?? 'Developer',
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: textVariantColor,
                                      fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  height: 28,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isFollowing
                                          ? (_isDarkMode
                                              ? const Color(0xFF30363D)
                                              : Colors.grey[300])
                                          : primaryColor,
                                      foregroundColor: isFollowing
                                          ? (_isDarkMode
                                              ? Colors.white
                                              : const Color(0xFF1B1B24))
                                          : Colors.white,
                                      elevation: 0,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                      _socialService.toggleFollow(
                                          currentUserId: _currentUserId,
                                          targetUserId: targetUid,
                                          isFollowing: isFollowing);
                                    },
                                    child: Text(
                                        isFollowing ? 'Following' : 'Follow',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Featured Portfolios',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : primaryColor),
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('projects')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child:
                            CircularProgressIndicator(color: primaryColor));
                  }

                  final projectDocs = snapshot.data?.docs ?? [];

                  if (projectDocs.isEmpty) {
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderStyleColor),
                        ),
                        child: Center(
                          child: Text(
                            'Belum ada projek yang diunggah.',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14, color: textVariantColor),
                          ),
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: projectDocs.map<Widget>((doc) {
                        final Map<String, dynamic> data =
                            doc.data() as Map<String, dynamic>;

                        final String projectId = doc.id;
                        final String projectTitle =
                            data.containsKey('title')
                                ? data['title'].toString()
                                : 'Untitled Project';
                        final String projectDescription =
                            data.containsKey('description')
                                ? data['description'].toString()
                                : 'Belum ada deskripsi proyek.';
                        final String authorId =
                            (data['uid'] ?? '').toString();
                        final String projectAuthor =
                            (data['authorName'] ?? '').toString().isNotEmpty
                                ? data['authorName']
                                : 'Unknown';
                        final String liveDemoUrl =
                            data.containsKey('liveDemo')
                                ? data['liveDemo'].toString()
                                : '';
                        final String projectImage =
                            data.containsKey('projectImage')
                                ? data['projectImage'].toString()
                                : 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe';

                        List<dynamic> projectLikes = [];
                        if (data.containsKey('likes') &&
                            data['likes'] is List) {
                          projectLikes = List.from(data['likes']);
                        }
                        bool isLikedByMe =
                            projectLikes.contains(_currentUserId);

                        bool isExpanded =
                            _isProjectDescriptionExpandedMap[projectId] ??
                                false;
                        List<String> words =
                            projectDescription.split(' ');
                        bool hasManyWords = words.length > 40;
                        String truncatedText = hasManyWords
                            ? '${words.take(40).join(' ')}...'
                            : projectDescription;
                        bool showOverlay =
                            _activeOverlayProjectIds.contains(projectId);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (authorId.isNotEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProfileScreen(
                                          userId: authorId,
                                          isDarkMode: _isDarkMode,
                                          onThemeChanged: (bool newTheme) {
                                            setState(() {
                                              _isDarkMode = newTheme;
                                            });
                                          },
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: borderStyleColor,
                                      child: Text(
                                        projectAuthor.isNotEmpty
                                            ? projectAuthor
                                                .substring(0, 1)
                                                .toUpperCase()
                                            : 'U',
                                        style: GoogleFonts.jetBrainsMono(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: textVariantColor),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        projectAuthor,
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: textColor),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (authorId.isNotEmpty &&
                                        authorId != _currentUserId)
                                      StreamBuilder<DocumentSnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(authorId)
                                            .snapshots(),
                                        builder: (context, userSnap) {
                                          if (!userSnap.hasData)
                                            return const SizedBox();

                                          final targetData = (userSnap.data!.data() as Map<String, dynamic>?) ?? {};
                                          List followersList =
                                              targetData['followers'] ?? [];
                                          bool isFollowing = followersList
                                              .contains(_currentUserId);

                                          return SizedBox(
                                            height: 28,
                                            child: ElevatedButton(
                                              style:
                                                  ElevatedButton.styleFrom(
                                                backgroundColor: isFollowing
                                                    ? borderStyleColor
                                                    : primaryColor,
                                                foregroundColor: isFollowing
                                                    ? textColor
                                                    : Colors.white,
                                                elevation: 0,
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 14),
                                                shape:
                                                    RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    8)),
                                              ),
                                              onPressed: () {
                                                _socialService.toggleFollow(
                                                  currentUserId:
                                                      _currentUserId,
                                                  targetUserId: authorId,
                                                  isFollowing: isFollowing,
                                                );
                                              },
                                              child: Text(
                                                isFollowing
                                                    ? 'Following'
                                                    : 'Follow',
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () => _launchURL(liveDemoUrl),
                                child: Container(
                                  width: double.infinity,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border:
                                        Border.all(color: borderStyleColor),
                                    image: DecorationImage(
                                      image: NetworkImage(projectImage),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(16),
                                      color: showOverlay
                                          ? Colors.black
                                              .withValues(alpha: 0.5)
                                          : Colors.transparent,
                                    ),
                                    child: showOverlay
                                        ? Center(
                                            child: InkWell(
                                              onTap: () =>
                                                  _launchURL(liveDemoUrl),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 20,
                                                    vertical: 10),
                                                decoration: BoxDecoration(
                                                  color: primaryColor,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                              alpha: 0.3),
                                                      blurRadius: 8,
                                                      offset: const Offset(
                                                          0, 4),
                                                    )
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                        Icons.open_in_new,
                                                        color: Colors.white,
                                                        size: 16),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Buka Link',
                                                      style: GoogleFonts
                                                          .plusJakartaSans(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          )
                                        : const SizedBox(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => _toggleLikeProject(
                                            projectId,
                                            authorId,
                                            projectLikes),
                                        child: Icon(
                                            isLikedByMe
                                                ? Icons.favorite_rounded
                                                : Icons
                                                    .favorite_border_rounded,
                                            size: 22,
                                            color: isLikedByMe
                                                ? const Color(0xFFEF4444)
                                                : textVariantColor),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        projectLikes.length.toString(),
                                        style: GoogleFonts.jetBrainsMono(
                                            fontSize: 14,
                                            color: textVariantColor,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    projectTitle.toUpperCase(),
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: _isDarkMode
                                            ? Colors.white
                                            : primaryColor),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isExpanded
                                        ? projectDescription
                                        : truncatedText,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        color: textVariantColor,
                                        height: 1.5),
                                  ),
                                  if (hasManyWords)
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isProjectDescriptionExpandedMap[
                                                  projectId] = !isExpanded;
                                        });
                                      },
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8),
                                        child: Text(
                                          isExpanded
                                              ? "Lihat Lebih Sedikit"
                                              : "Lihat Selengkapnya",
                                          style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}