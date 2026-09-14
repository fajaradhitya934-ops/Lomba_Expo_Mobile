  import 'package:flutter/material.dart';
  import '../mini_status_card.dart';

  class HomeMiniStats extends StatelessWidget {
    final int totalPhotos;
    final int todayPoints;

    const HomeMiniStats({
      super.key,
      required this.totalPhotos,
      required this.todayPoints,
    });

    @override
    Widget build(BuildContext context) {
      return Row(
        children: [
          MiniStatusCard(value: "$totalPhotos", label: "Foto terkirim"),
          const SizedBox(width: 16),
          MiniStatusCard(value: "+$todayPoints", label: "Poin hari ini"),
        ],
      );
    }
  }