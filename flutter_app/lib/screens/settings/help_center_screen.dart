import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Help Center'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Search for help...',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Getting Started
              Text(
                'Getting Started',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _HelpCard(
                children: [
                  _HelpItem(
                    icon: Icons.account_circle,
                    title: 'Creating Your Account',
                    description: 'Learn how to sign up and set up your profile',
                  ),
                  Divider(height: 1, color: colorScheme.outline.withOpacity(0.3)),
                  _HelpItem(
                    icon: Icons.code,
                    title: 'Your First Problem',
                    description: 'Step-by-step guide to solving problems',
                  ),
                  Divider(height: 1, color: colorScheme.outline.withOpacity(0.3)),
                  _HelpItem(
                    icon: Icons.emoji_events,
                    title: 'Joining Contests',
                    description: 'How to participate in coding competitions',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Account & Settings
              Text(
                'Account & Settings',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _HelpCard(
                children: [
                  _HelpItem(
                    icon: Icons.lock,
                    title: 'Account Security',
                    description: 'Password reset and security settings',
                  ),
                  Divider(height: 1, color: colorScheme.outline.withOpacity(0.3)),
                  _HelpItem(
                    icon: Icons.edit,
                    title: 'Update Profile Information',
                    description: 'Change username, email, and preferences',
                  ),
                  Divider(height: 1, color: colorScheme.outline.withOpacity(0.3)),
                  _HelpItem(
                    icon: Icons.delete,
                    title: 'Delete Account',
                    description: 'Permanently remove your account and data',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Problems & Submissions
              Text(
                'Problems & Submissions',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _HelpCard(
                children: [
                  _HelpItem(
                    icon: Icons.question_answer,
                    title: 'Understanding Problem Difficulty',
                    description: 'Easy, Medium, Hard - what they mean',
                  ),
                  Divider(height: 1, color: colorScheme.outline.withOpacity(0.3)),
                  _HelpItem(
                    icon: Icons.play_arrow,
                    title: 'Submitting Your Code',
                    description: 'How to test and submit solutions',
                  ),
                  Divider(height: 1, color: colorScheme.outline.withOpacity(0.3)),
                  _HelpItem(
                    icon: Icons.check_circle,
                    title: 'Submission Verdicts',
                    description: 'Accepted, Wrong Answer, TLE explained',
                  ),
                  Divider(height: 1, color: colorScheme.outline.withOpacity(0.3)),
                  _HelpItem(
                    icon: Icons.language,
                    title: 'Supported Languages',
                    description: 'Available programming languages',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Contests
              Text(
                'Contests',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _HelpCard(
                children: [
                  _HelpItem(
                    icon: Icons.access_time,
                    title: 'Contest Schedule',
                    description: 'Finding and tracking upcoming contests',
                  ),
                  Divider(height: 1, color: colorScheme.outline.withOpacity(0.3)),
                  _HelpItem(
                    icon: Icons.leaderboard,
                    title: 'Contest Scoring',
                    description: 'How rankings and points are calculated',
                  ),
                  Divider(height: 1, color: colorScheme.outline.withOpacity(0.3)),
                  _HelpItem(
                    icon: Icons.rule,
                    title: 'Contest Rules',
                    description: 'Important guidelines and regulations',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Premium Features
              Text(
                'Premium Features',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _HelpCard(
                children: [
                  _HelpItem(
                    icon: Icons.workspace_premium,
                    title: 'Premium Benefits',
                    description: 'What you get with CodeMania Premium',
                  ),
                  Divider(height: 1, color: colorScheme.outline.withOpacity(0.3)),
                  _HelpItem(
                    icon: Icons.payment,
                    title: 'Billing & Payments',
                    description: 'Subscription management and refunds',
                  ),
                  Divider(height: 1, color: colorScheme.outline.withOpacity(0.3)),
                  _HelpItem(
                    icon: Icons.cancel,
                    title: 'Cancel Subscription',
                    description: 'How to cancel your premium plan',
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Contact Support
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2563EB).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.support_agent,
                      size: 48,
                      color: const Color(0xFF2563EB),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Still Need Help?',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Our support team is here to help you',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Open feedback/contact form
                        },
                        icon: const Icon(Icons.email),
                        label: const Text('Contact Support'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quick Links
              Text(
                'Quick Links',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _HelpCard(
                children: [
                  _QuickLinkItem(
                    icon: Icons.description,
                    title: 'Documentation',
                    url: 'docs.codemania.com',
                  ),
                  Divider(height: 1, color: colorScheme.outline.withOpacity(0.3)),
                  _QuickLinkItem(
                    icon: Icons.forum,
                    title: 'Community Forum',
                    url: 'forum.codemania.com',
                  ),
                  Divider(height: 1, color: colorScheme.outline.withOpacity(0.3)),
                  _QuickLinkItem(
                    icon: Icons.video_library,
                    title: 'Video Tutorials',
                    url: 'youtube.com/codemania',
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

class _HelpCard extends StatelessWidget {
  const _HelpCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  const _HelpItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () {
        // Navigate to help article
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLinkItem extends StatelessWidget {
  const _QuickLinkItem({
    required this.icon,
    required this.title,
    required this.url,
  });

  final IconData icon;
  final String title;
  final String url;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () {
        // Open external link
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    url,
                    style: textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new,
              color: colorScheme.onSurface.withOpacity(0.4),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
