import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; 
import 'package:url_launcher/url_launcher.dart'; 
import 'package:prestasi/screens/Selko/services/profile_service.dart'; 
import 'package:prestasi/screens/Selko/Screens/edit_profile_screen.dart'; 
import 'package:prestasi/screens/Selko/Screens/edit_project_screen.dart';
import 'package:prestasi/screens/login_screen.dart';
import 'package:prestasi/screens/Selko/Screens/notification_screen.dart';
import 'package:prestasi/screens/Selko/services/profile_photo_service.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; 
  final bool isDarkMode; 
  final ValueChanged<bool> onThemeChanged; 

  const ProfileScreen({
    super.key, 
    this.userId, 
    this.isDarkMode = false, 
    required this.onThemeChanged,
  });


  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService =
      ProfileService();

  final ProfilePhotoService _photoService =
      ProfilePhotoService();

  int _tahunTerpilih = DateTime.now().year;
  bool _isBioExpanded = false;

  static const Color primaryColor = Color(0xFF3525CD);
  static const Color githubGreen = Color(0xFF2EA44F);

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      await launchUrl(url,
          mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint(
        "Tidak bisa membuka tautan: $urlString. Error: $e",
      );
      try {
        await launchUrl(
          url,
          mode: LaunchMode.platformDefault,
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Silakan login terlebih dahulu")),
      );
    }

    final String targetUserId = widget.userId ?? currentUser.uid;
    final bool isMe = targetUserId == currentUser.uid;

    final Color bgColor = widget.isDarkMode ? const Color(0xFF0D1117) : const Color(0xFFFCF8FF); 
    final Color cardColor = widget.isDarkMode ? const Color(0xFF161B22) : Colors.white;
    final Color borderStyleColor = widget.isDarkMode ? const Color(0xFF30363D) : const Color(0xFFC7C4D8).withOpacity(0.3);

    final Color textColor = widget.isDarkMode ? Colors.white : Colors.black;
    final Color textVariantColor = widget.isDarkMode ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7);

    final int tahunSekarang = _tahunTerpilih;
    final DateTime awalTahun = DateTime(tahunSekarang, 1, 1);
    final int offsetMingguPertama = awalTahun.weekday % 7; 
    
    const int totalMinggu = 54;
    const int totalKotakGithub = totalMinggu * 7; 
    const double ukuranKotak = 11.5;
    const double gapKotak = 3.0;
    const double lebarPerMinggu = ukuranKotak + gapKotak;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        automaticallyImplyLeading: !isMe,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(targetUserId).snapshots(),
          builder: (context, snapshot) {
            final userData = snapshot.data?.data() as Map<String, dynamic>?;
            final String username = userData?['username'] ?? 'user';
            return Text(
              username.startsWith('@') ? username : '@$username',
              style: GoogleFonts.plusJakartaSans(
                color: textColor, 
                fontWeight: FontWeight.bold, 
                fontSize: 18,
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.lightbulb : Icons.lightbulb_outline, 
              color: widget.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
            ),
            onPressed: () {
              widget.onThemeChanged(!widget.isDarkMode);
            },
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: textColor),
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(isDarkMode: widget.isDarkMode),
                ),
              ).then((_) {
                setState(() {});
              });
            },
          ),
          PopupMenuButton<String>(
  icon: Icon(Icons.more_vert, color: textColor),
  onSelected: (value) async {
    if (value == 'logout') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari akun ini?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await FirebaseAuth.instance.signOut();

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            ),
            (route) => false,
          );
        }
      }
    }
  },
  itemBuilder: (context) => [
    const PopupMenuItem(
      value: 'logout',
      child: Row(
        children: [
          Icon(Icons.logout, color: Colors.red),
          SizedBox(width: 8), 
          Text('Logout'),
        ],
      ),
    ),
  ],
),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(targetUserId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          final String namaUser = userData?['displayName'] ?? "Nama Pengguna";
          final String role = userData?['role'] ?? ""; 
          final String bio = userData?['bio'] ?? "Belum ada bio.";
          final String availability = userData?['availabilityStatus'] ?? "Available";
          
          List followersList = userData?['followers'] ?? [];
          bool isFollowing = followersList.contains(currentUser.uid);

          final Timestamp? createdAt = userData?['createdAt'] as Timestamp?;

          String formattedJoinDate = "-"; 
          if (createdAt != null) {
            formattedJoinDate = DateFormat('dd MMMM yyyy', 'id_ID').format(createdAt.toDate());
          } else {
            formattedJoinDate = DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now());
          }

          final contact = userData?['contact'] as Map<String, dynamic>? ?? {};
          final String whatsapp = contact['whatsappNumber'] ?? '';
          final String email = contact['emailAddress'] ?? '';
          final String github = contact['githubUrl'] ?? '';
          final String optionalLink = contact['kaggleUrl'] ?? contact['optionalLink'] ?? contact['optionalUrl'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
  child: Stack(
    alignment: Alignment.bottomCenter,
    clipBehavior: Clip.none,
    children: [

      GestureDetector(
  onTap: isMe
      ? () async {

          print('=== FOTO DIKLIK ===');

          await _photoService
              .pickAndUploadProfilePhoto();

          print('=== UPLOAD SELESAI ===');

        }
      : null,
  child: Container(
    width: 96,
    height: 96,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: cardColor,
        width: 4,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 6,
        ),
      ],
      image: DecorationImage(
        image: NetworkImage(
          (userData?['photoURL'] != null &&
                  userData!['photoURL']
                      .toString()
                      .isNotEmpty)
              ? userData['photoURL']
              : 'https://ui-avatars.com/api/?name=?&background=EAEAEA&color=BCBCBC&size=150',
        ),
        fit: BoxFit.cover,
      ),
    ),
  ),
),

      if (isMe)
        Positioned(
          right: 0,
          top: 65,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.camera_alt,
              color: Colors.white,
              size: 14,
            ),
          ),
        ),

      Positioned(
        bottom: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: availability == 'Busy'
                ? const Color(0xFFEF4444)
                : const Color(0xFF22C55E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cardColor,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                availability,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
),
                if (!isMe) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      width: 130,
                      height: 32,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFollowing ? borderStyleColor : primaryColor,
                          foregroundColor: isFollowing ? textColor : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () {
                          _profileService.toggleFollow(
                            currentUserId: currentUser.uid,
                            targetUserId: targetUserId,
                            isFollowing: isFollowing,
                          );
                        },
                        child: Text(
                          isFollowing ? 'Following' : 'Follow',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    namaUser, 
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ),
                const SizedBox(height: 12),
                if (role.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.terminal_rounded, size: 16, color: textColor),
                      const SizedBox(width: 8),
                      Text(role, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: textVariantColor)),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                FutureBuilder<String>(
                  future: _profileService.getUniversityName(userData?['email'] ?? email),
                  builder: (context, uniSnapshot) {
                    String univName = "Memuat nama kampus...";
                    if (uniSnapshot.connectionState == ConnectionState.done) {
                      univName = uniSnapshot.data ?? "Universitas Tidak Diketahui";
                    }
                    return Row(
                      children: [
                        Icon(Icons.school_outlined, size: 16, color: textColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            univName, 
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textVariantColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bio,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textVariantColor, height: 1.4),
                      maxLines: _isBioExpanded ? null : 3,
                      overflow: _isBioExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    ),
                    if (bio.length > 250)
                      GestureDetector(
                        onTap: () => setState(() => _isBioExpanded = !_isBioExpanded),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _isBioExpanded ? "Lihat Lebih Sedikit" : "Lihat Selengkapnya",
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: primaryColor),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                  .collection('projects')
                   .where('uid', isEqualTo: targetUserId)
                   .snapshots(),
                  builder: (context, projSnap) {
                    final int totalProjects = projSnap.data?.docs.length ?? 0;
                    final int totalFollowers = followersList.length;
                    
                    return StreamBuilder<int>(
                      stream: _profileService.getTotalUserLikes(targetUserId),
                      builder: (context, likeSnap) {
                        final int totalLikes = likeSnap.data ?? 0;
                        
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildMetricItem(totalProjects.toString(), 'Projects', textColor),
                            Container(height: 24, width: 1, color: borderStyleColor),
                            _buildMetricItem(totalFollowers.toString(), 'Followers', textColor), 
                            Container(height: 24, width: 1, color: borderStyleColor),
                            _buildMetricItem(totalLikes >= 1000 ? '${(totalLikes / 1000).toStringAsFixed(1)}K' : totalLikes.toString(), 'Likes', textColor),
                          ],
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),

                // CONTACT CARD
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderStyleColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: const Color(0xFF25D366).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.chat_outlined, color: Color(0xFF25D366), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('WHATSAPP', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: textVariantColor, fontWeight: FontWeight.bold)),
                              Text(
                                whatsapp.isNotEmpty ? '+62 $whatsapp' : '(------)',
                                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (whatsapp.isNotEmpty && !isMe)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              ),
                              onPressed: () {
                                String cleanNumber = whatsapp.trim();
                                if (cleanNumber.startsWith('0')) cleanNumber = cleanNumber.substring(1);
                                String pesanTeks = "Halo $namaUser, saya melihat profil Anda di aplikasi Prestasi.";
                                _launchURL('https://wa.me/62$cleanNumber?text=${Uri.encodeComponent(pesanTeks)}');
                              },
                              child: Text('Chat Now', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                        ],
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Colors.black12)),
                      InkWell(
                        onTap: email.isNotEmpty ? () => _launchURL('mailto:$email') : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.mail_outline, color: Colors.blue, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('EMAIL UTAMA', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: textVariantColor, fontWeight: FontWeight.bold)),
                                    Text(
                                      email.isNotEmpty ? email : '(------)',
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Colors.black12)),
                      InkWell(
                        onTap: github.isNotEmpty ? () {
                          String targetUrl = github.startsWith('http') ? github : 'https://github.com/$github';
                          _launchURL(targetUrl);
                        } : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.code_rounded, color: Colors.purple, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('GITHUB PROFILE', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: textVariantColor, fontWeight: FontWeight.bold)),
                                    Text(
                                      github.isNotEmpty ? github : '(------)',
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (optionalLink.isNotEmpty) ...[
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Colors.black12)),
                        InkWell(
                          onTap: () {
                            String targetUrl = optionalLink.startsWith('http') ? optionalLink : 'https://$optionalLink';
                            _launchURL(targetUrl);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.link_rounded, color: Colors.orange, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('LINK OPSIONAL / PORTFOLIO', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: textVariantColor, fontWeight: FontWeight.bold)),
                                      Text(
                                        optionalLink,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ACTIVITY SECTION
                Text('Activity', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)), 
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderStyleColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Kontribusi tahun berjalan',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.isDarkMode ? const Color(0xFF21262D) : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: borderStyleColor),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _tahunTerpilih,
                                dropdownColor: cardColor,
                                icon: Icon(Icons.arrow_drop_down, color: textColor, size: 18),
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                                isDense: true,
                                onChanged: (int? newValue) {
                                  if (newValue != null) {
                                    setState(() { _tahunTerpilih = newValue; });
                                  }
                                },
                                items: List.generate((DateTime.now().year - 2026) + 1, (index) {
                                  return 2026 + index;
                                }).map<DropdownMenuItem<int>>((int value) {
                                  return DropdownMenuItem<int>(value: value, child: Text(value.toString()));
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 20, right: 6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 13), 
                                  Text('Mon', style: GoogleFonts.plusJakartaSans(fontSize: 9, color: textVariantColor)),
                                  const SizedBox(height: 13), 
                                  Text('Wed', style: GoogleFonts.plusJakartaSans(fontSize: 9, color: textVariantColor)),
                                  const SizedBox(height: 13), 
                                  Text('Fri', style: GoogleFonts.plusJakartaSans(fontSize: 9, color: textVariantColor)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    const SizedBox(width: totalMinggu * lebarPerMinggu, height: 16),
                                    ...List.generate(12, (index) {
                                      final List<String> namaBulan = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                                      final DateTime bulanTarget = DateTime(tahunSekarang, index + 1, 1);
                                      final int jarakHariDariAwal = bulanTarget.difference(awalTahun).inDays + offsetMingguPertama;
                                      final double letakKolomMinggu = (jarakHariDariAwal / 7).floorToDouble();

                                      return Positioned(
                                        left: letakKolomMinggu * lebarPerMinggu,
                                        child: Text(
                                          namaBulan[index], 
                                          style: GoogleFonts.plusJakartaSans(fontSize: 10, color: textVariantColor, fontWeight: FontWeight.w600),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  height: (ukuranKotak * 7) + (gapKotak * 6), 
                                  width: totalMinggu * lebarPerMinggu, 
                                  child: GridView.builder(
                                    scrollDirection: Axis.horizontal, 
                                    physics: const NeverScrollableScrollPhysics(), 
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 7,       
                                      crossAxisSpacing: gapKotak,     
                                      mainAxisSpacing: gapKotak,      
                                      childAspectRatio: 1.0,   
                                    ),
                                    itemCount: totalKotakGithub, 
                                    itemBuilder: (context, idx) {
                                      if (idx < offsetMingguPertama) return const SizedBox.shrink(); 

                                      final int urutanHari = idx - offsetMingguPertama;
                                      final DateTime targetDate = awalTahun.add(Duration(days: urutanHari));

                                      if (targetDate.year > tahunSekarang) return const SizedBox.shrink();

                                      Color boxColor = widget.isDarkMode ? const Color(0xFF161B22) : const Color(0xFFEBEDF0);
                                      final DateTime activeStartDate = createdAt?.toDate() ?? DateTime.now();
                                      final DateTime today = DateTime.now();

                                      if (!targetDate.isBefore(DateTime(activeStartDate.year, activeStartDate.month, activeStartDate.day)) && 
                                          !targetDate.isAfter(DateTime(today.year, today.month, today.day))) {
                                        boxColor = githubGreen;
                                      }

                                      return Container(
                                        decoration: BoxDecoration(
                                          color: boxColor,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Aktif sejak: $formattedJoinDate', 
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: textVariantColor, fontWeight: FontWeight.w500),
                          ),
                          Row(
                            children: [
                              Text('Less ', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: textVariantColor)),
                              ...(widget.isDarkMode 
                                ? [0xFF161B22, 0xFF0E4429, 0xFF006D32, 0xFF26A641] 
                                : [0xFFEBEDF0, 0xFF9BE9A8, 0xFF40C463, 0xFF216E39]
                              ).map((c) {
                                return Container(margin: const EdgeInsets.symmetric(horizontal: 1.5), width: 10, height: 10, color: Color(c));
                              }),
                              Text(' More', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: textVariantColor)),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // GALLERY TAB SYSTEM
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: textColor, width: 2))), 
                        child: Icon(Icons.grid_view_rounded, color: textColor), 
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
    .collection('projects')
    .where('uid', isEqualTo: targetUserId)
    .snapshots(), 
                  builder: (context, projectSnapshot) {
  if (projectSnapshot.connectionState == ConnectionState.waiting) {
    return const Center(
      child: CircularProgressIndicator(color: primaryColor),
    );
  }

  print('TARGET USER ID = $targetUserId');
  print('CURRENT USER ID = ${FirebaseAuth.instance.currentUser?.uid}');
  print('PROJECT COUNT = ${projectSnapshot.data?.docs.length}');

  final projects = projectSnapshot.data?.docs ?? [];
                    if (projects.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: Text("Belum ada project yang diunggah", style: GoogleFonts.plusJakartaSans(color: textVariantColor))),
                      );
                    }

                   return Center(
  child: SizedBox(
    width: 280,
    child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: projects.length,
      itemBuilder: (context, index) {
  final doc = projects[index];

  final project =
      doc.data() as Map<String, dynamic>;

  final String projectId = doc.id;

  final String imgUrl =
      project['projectImage'] ??
      'https://via.placeholder.com/150';

        return GestureDetector(
          onTap: () {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    builder: (_) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imgUrl,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 16),

              Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Expanded(
      child: Text(
        project['title'] ?? '',
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    if (project['uid'] ==
        FirebaseAuth.instance.currentUser?.uid)
      PopupMenuButton<String>(
        onSelected: (value) async {

  if (value == 'edit') {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProjectScreen(
          projectId: projectId,
          projectData: project,
        ),
      ),
    );
  }

  if (value == 'delete') {

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Project'),
        content: const Text(
          'Yakin ingin menghapus project ini?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .delete();

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
},
       itemBuilder: (context) => const [
  PopupMenuItem(
    value: 'edit',
    child: Text('Edit Project'),
  ),
  PopupMenuItem(
    value: 'delete',
    child: Text('Hapus Project'),
  ),
],
      ),
  ],
),

              const SizedBox(height: 12),

              Text(
                project['description'] ?? '',
                style: const TextStyle(fontSize: 15),
              ),

              const SizedBox(height: 16),

StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('projects')
      .doc(projectId)
      .snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const SizedBox();
    }

    final data =
        snapshot.data!.data() as Map<String, dynamic>;

    final List likes =
        List.from(data['likes'] ?? []);

    final currentUid =
        FirebaseAuth.instance.currentUser?.uid;

    final isLiked =
        likes.contains(currentUid);

    return Row(
      children: [
        GestureDetector(
          onTap: () async {
            if (currentUid == null) return;

            final docRef = FirebaseFirestore.instance
                .collection('projects')
                .doc(projectId);

            if (isLiked) {
              await docRef.update({
                'likes':
                    FieldValue.arrayRemove([currentUid]),
              });
            } else {
              await docRef.update({
                'likes':
                    FieldValue.arrayUnion([currentUid]),
              });
            }
          },
          child: Icon(
            isLiked
                ? Icons.favorite
                : Icons.favorite_border,
            color: Colors.red,
          ),
        ),

        const SizedBox(width: 8),

        Text(
          '${likes.length} Likes',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  },
),

const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final url = project['liveDemo'] ?? '';

                    if (url.toString().isNotEmpty) {
                      _launchURL(url);
                    }
                  },
                  child: const Text('Buka Demo'),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    },
  );
},
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderStyleColor),
              image: DecorationImage(
                image: NetworkImage(imgUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      }, // itemBuilder
    ), // GridView.builder
  ), // SizedBox
); // Center
                  },
                ),
                const SizedBox(height: 100), 
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget _buildMetricItem(String val, String label, Color textThemeColor) {
    return Column(
      children: [
        Text(val, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: textThemeColor)), 
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.jetBrainsMono(fontSize: 12, color: textThemeColor)),
      ],
    );
  }
}
