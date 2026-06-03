import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shared sidebar navigation used by HomeScreen, FriendsScreen, etc.
/// Pass the [activePage] string to highlight the current item.
///
/// Valid activePage values: 'home' | 'problems' | 'contests' | 'friends'
class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key, required this.activePage});

  final String activePage;

  static const _items = [
    (label: 'Home', icon: Icons.home_outlined, page: 'home', route: '/home'),
    (label: 'Problems', icon: Icons.code_outlined, page: 'problems', route: '/problems'),
    (label: 'Contests', icon: Icons.emoji_events_outlined, page: 'contests', route: '/contests'),
    (label: 'Friends', icon: Icons.people_outline, page: 'friends', route: '/friends'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFEDEAF8),
        border: Border(right: BorderSide(color: Color(0xFFE4DFF2))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '<Codemania/>',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1F2148),
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 22),
            ..._items.map((item) {
              final isActive = activePage == item.page;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: isActive ? const Color(0xFF5E2ED5) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => context.go(item.route),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 20,
                            color: isActive
                                ? Colors.white
                                : const Color(0xFF68708D),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            item.label,
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : const Color(0xFF68708D),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
