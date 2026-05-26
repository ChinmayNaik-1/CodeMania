import 'package:codemania/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F2FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFF6429D8),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: const Text(
                'Season 3 is LIVE! Compete now for exciting prizes.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            _TopNavBar(
              isAuthenticated: authState.user != null,
              onLogin: () => context.go('/login'),
              onSignup: () => context.go('/register'),
              onDashboard: () {
                if (authState.user?.isAdmin == true) {
                  context.go('/admin');
                } else {
                  context.go('/home');
                }
              },
            ),
            const _HeroSection(),
            const _StatsSection(),
            const _FeatureSection(),
            const _ContestSection(),
            const _FooterSection(),
          ],
        ),
      ),
    );
  }
}

class _TopNavBar extends StatelessWidget {
  const _TopNavBar({
    required this.isAuthenticated,
    required this.onLogin,
    required this.onSignup,
    required this.onDashboard,
  });

  final bool isAuthenticated;
  final VoidCallback onLogin;
  final VoidCallback onSignup;
  final VoidCallback onDashboard;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 980;

    return Container(
      height: 76,
      color: const Color(0xFFF9F8FF),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Row(
            children: [
              const Text(
                '<Codemania/>',
                style: TextStyle(
                  color: Color(0xFF171E37),
                  fontWeight: FontWeight.w800,
                  fontSize: 38,
                  letterSpacing: -0.4,
                ),
              ),
              const Spacer(),
              if (!isCompact)
                Wrap(
                  spacing: 8,
                  children: const [
                    _NavTextButton('Challenges'),
                    _NavTextButton('Leaderboard'),
                    _NavTextButton('Community'),
                  ],
                ),
              const Spacer(),
              if (isAuthenticated)
                FilledButton(
                  onPressed: onDashboard,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6429D8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                  ),
                  child: const Text('Go to Dashboard'),
                )
              else
                FilledButton(
                  onPressed: onSignup,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6429D8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 14),
                  ),
                  child: const Text('Join Free'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTextButton extends StatelessWidget {
  const _NavTextButton(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => context.go('/login'),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF1C2340),
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final titleSize = width < 640 ? 46.0 : (width < 1024 ? 62.0 : 84.0);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(42),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE4DCF2),
                  Color(0xFFF2F0FA),
                  Color(0xFFDCCEF6),
                ],
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
            child: Column(
              children: [
                Text(
                  'Code. Compete. Rise to\nthe Top.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: titleSize,
                    height: 0.96,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF121A38),
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Join the ultimate coding competition platform. Challenge yourself, compete with\nothers, and climb the leaderboard.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF4F5C73),
                    fontSize: 18,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton(
                      onPressed: () => context.go('/login'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6429D8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 16),
                      ),
                      child: const Text('Start Coding'),
                    ),
                    OutlinedButton(
                      onPressed: () => context.go('/login'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E2540),
                        side: const BorderSide(color: Color(0xFFD1C8EA)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 16),
                      ),
                      child: const Text('View Leaderboard'),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Container(
                  width: width < 800 ? double.infinity : 700,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDFDFF),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFE7E1F4)),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Global Leaderboard',
                            style: TextStyle(
                              color: Color(0xFF1D2340),
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          Icon(Icons.workspace_premium_rounded,
                              color: Color(0xFF7E59E2), size: 18),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Color(0xFFEAE4F6)),
                      const _LeaderRow(
                          rank: 1,
                          name: 'AlexDev',
                          score: '2450',
                          active: true),
                      const _LeaderRow(
                          rank: 2,
                          name: 'ByteMaster',
                          score: '2380',
                          active: false),
                      const _LeaderRow(
                          rank: 3,
                          name: 'CodeNinja',
                          score: '2315',
                          active: false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({
    required this.rank,
    required this.name,
    required this.score,
    required this.active,
  });

  final int rank;
  final String name;
  final String score;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Text(
            '$rank',
            style: TextStyle(
              color: active ? const Color(0xFF6429D8) : const Color(0xFF7B879F),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                  color: Color(0xFF1E2540), fontWeight: FontWeight.w600),
            ),
          ),
          if (active)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6429D8),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                score,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            )
          else
            Text(
              score,
              style: const TextStyle(
                  color: Color(0xFF4F5C73), fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 980;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: isCompact
              ? const Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    _StatCard('Coders', '12,000+'),
                    _StatCard('Problems', '600+'),
                    _StatCard('Contests', 'Weekly'),
                  ],
                )
              : const Row(
                  children: [
                    Expanded(child: _StatCard('Coders', '12,000+')),
                    SizedBox(width: 14),
                    Expanded(child: _StatCard('Problems', '600+')),
                    SizedBox(width: 14),
                    Expanded(child: _StatCard('Contests', 'Weekly')),
                  ],
                ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.title, this.value);

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFF),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE7E1F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF727F95))),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF151D37),
              fontWeight: FontWeight.w800,
              fontSize: 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureSection extends StatelessWidget {
  const _FeatureSection();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      color: const Color(0xFFEDEAF7),
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            children: [
              const Text(
                'FEATURES',
                style: TextStyle(
                  color: Color(0xFF6A43D6),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Why Codemania?',
                style: TextStyle(
                  color: Color(0xFF1A2038),
                  fontWeight: FontWeight.w800,
                  fontSize: 42,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Everything you need to improve your coding skills and compete with the best.',
                style: TextStyle(color: Color(0xFF5A6881), fontSize: 16),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _FeatureCard(
                    title: 'Live Contests',
                    subtitle:
                        'Participate in thrilling live coding competitions and test your skills under pressure.',
                    icon: Icons.bolt_outlined,
                    width: width < 560 ? width - 56 : 405,
                  ),
                  _FeatureCard(
                    title: 'Real-time Leaderboard',
                    subtitle:
                        'Track your progress, earn badges, and see where you stand globally as you solve.',
                    icon: Icons.bar_chart_rounded,
                    width: width < 560 ? width - 56 : 405,
                  ),
                  _FeatureCard(
                    title: 'Multi-language',
                    subtitle:
                        'Write code in your favorite programming language with our versatile online compiler.',
                    icon: Icons.code_rounded,
                    width: width < 560 ? width - 56 : 405,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.width,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3DCF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF6A43D6), size: 24),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1B2342),
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF5E6B81), height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _ContestSection extends StatelessWidget {
  const _ContestSection();

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 980;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            children: [
              const Text(
                'Upcoming Contest',
                style: TextStyle(
                  color: Color(0xFF1B2342),
                  fontWeight: FontWeight.w800,
                  fontSize: 34,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE0D3F8), Color(0xFFD5C2F9)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFCDB9F1)),
                ),
                child: isCompact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              _PillLabel('Algorithms'),
                              SizedBox(width: 8),
                              _PillLabel('Rated'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Codemania Weekly Challenge #42',
                            style: TextStyle(
                              color: Color(0xFF1C2442),
                              fontWeight: FontWeight.w800,
                              fontSize: 28,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'STARTS IN  02 : 14 : 30',
                            style: TextStyle(
                              color: Color(0xFF4F5C73),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => context.go('/login'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF6429D8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 16),
                            ),
                            child: const Text('Join Contest'),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _PillLabel('Algorithms'),
                                    SizedBox(width: 8),
                                    _PillLabel('Rated'),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Codemania Weekly Challenge #42',
                                  style: TextStyle(
                                    color: Color(0xFF1C2442),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 30,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'STARTS IN  02 : 14 : 30',
                                  style: TextStyle(
                                    color: Color(0xFF4F5C73),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton(
                            onPressed: () => context.go('/login'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF6429D8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 16),
                            ),
                            child: const Text('Join Contest'),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillLabel extends StatelessWidget {
  const _PillLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF7452DD),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _FooterSection extends StatelessWidget {
  const _FooterSection();

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 760;

    return Container(
      width: double.infinity,
      color: const Color(0xFFE4E8F0),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: isCompact
              ? const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '<Codemania/>',
                      style: TextStyle(
                        color: Color(0xFF1A1F36),
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text('Terms',
                            style: TextStyle(color: Color(0xFF5A6780))),
                        SizedBox(width: 18),
                        Text('Privacy',
                            style: TextStyle(color: Color(0xFF5A6780))),
                        SizedBox(width: 18),
                        Text('Contact',
                            style: TextStyle(color: Color(0xFF5A6780))),
                      ],
                    ),
                  ],
                )
              : const Row(
                  children: [
                    Text(
                      '<Codemania/>',
                      style: TextStyle(
                        color: Color(0xFF1A1F36),
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                      ),
                    ),
                    Spacer(),
                    Text('Terms', style: TextStyle(color: Color(0xFF5A6780))),
                    SizedBox(width: 18),
                    Text('Privacy', style: TextStyle(color: Color(0xFF5A6780))),
                    SizedBox(width: 18),
                    Text('Contact', style: TextStyle(color: Color(0xFF5A6780))),
                  ],
                ),
        ),
      ),
    );
  }
}
