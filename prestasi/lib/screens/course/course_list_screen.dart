Widget _buildNode(
  BuildContext context,
  String title,
  String type,
) {
  IconData icon;

  switch (type) {
    case 'quiz':
      icon = Icons.quiz;
      break;

    case 'boss':
      icon = Icons.emoji_events;
      break;

    default:
      icon = Icons.menu_book;
  }

  return GestureDetector(
    onTap: () {
      if (type == 'module') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ModuleDetailScreen(
              ...
            ),
          ),
        );
      }

      if (type == 'quiz') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuizScreen(
              ...
            ),
          ),
        );
      }
    },
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: const Color(0xFF69F0AE),
            child: Icon(
              icon,
              size: 35,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}