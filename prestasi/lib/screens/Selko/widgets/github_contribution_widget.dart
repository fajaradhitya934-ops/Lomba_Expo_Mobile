import 'package:flutter/material.dart';
import '../services/profile_service.dart';

class GithubContributionWidget extends StatelessWidget {
  final String userId;
  final bool isDarkMode;

  const GithubContributionWidget({
    super.key,
    required this.userId,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final profileService = ProfileService();

    return FutureBuilder(
      future: Future.wait([
        profileService.getCurrentStreak(userId),
        profileService.getLongestStreak(userId),
        profileService.getActiveDays(userId),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final currentStreak = snapshot.data![0];
        final longestStreak = snapshot.data![1];
        final activeDays = snapshot.data![2];

        return StreamBuilder<int>(
          stream: profileService.getTotalContributions(userId),
          builder: (context, contributionSnapshot) {
            final totalContributions =
                contributionSnapshot.data ?? 0;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode
                      ? const Color(0xFF30363D)
                      : const Color(0xFFD0D7DE),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    '$totalContributions contributions',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Current Streak',
                          value: '$currentStreak',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Longest Streak',
                          value: '$longestStreak',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _StatCard(
                    title: 'Active Days',
                    value: '$activeDays',
                  ),

                  const SizedBox(height: 24),

                  Container(
                    height: 120,
                    alignment: Alignment.center,
                    child: const Text(
                      'Heatmap akan ditambahkan di tahap berikutnya',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.withOpacity(.08),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(title),
        ],
      ),
    );
  }
}