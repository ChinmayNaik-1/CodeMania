import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
        title: const Text('Terms of Service'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Last updated
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.update,
                      size: 16,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Last Updated: January 15, 2026',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Introduction
              Text(
                'Terms of Service',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Welcome to CodeMania! These Terms of Service ("Terms") govern your access to and use of the CodeMania platform. By accessing or using our services, you agree to be bound by these Terms.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 24),

              // Acceptance of Terms
              _SectionHeader(title: '1. Acceptance of Terms'),
              const SizedBox(height: 12),
              Text(
                'By creating an account or using CodeMania, you acknowledge that you have read, understood, and agree to be bound by these Terms and our Privacy Policy. If you do not agree to these Terms, you may not access or use our services.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 24),

              // Eligibility
              _SectionHeader(title: '2. Eligibility'),
              const SizedBox(height: 12),
              Text(
                'You must be at least 13 years old to use CodeMania. By using our services, you represent and warrant that:',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              _BulletList(items: [
                'You are at least 13 years of age',
                'You have the legal capacity to enter into these Terms',
                'You will provide accurate and truthful information',
                'You will not create multiple accounts for unfair advantages',
              ]),

              const SizedBox(height: 24),

              // Account Registration
              _SectionHeader(title: '3. Account Registration and Security'),
              const SizedBox(height: 12),
              Text(
                'To access certain features, you must create an account. You agree to:',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              _BulletList(items: [
                'Provide accurate, current, and complete information',
                'Maintain and update your account information',
                'Keep your password secure and confidential',
                'Notify us immediately of any unauthorized access',
                'Be responsible for all activities under your account',
              ]),

              const SizedBox(height: 24),

              // User Conduct
              _SectionHeader(title: '4. User Conduct'),
              const SizedBox(height: 12),
              Text(
                'You agree not to:',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              _BulletList(items: [
                'Cheat, plagiarize, or submit copied solutions',
                'Use automated tools or bots to gain unfair advantages',
                'Harass, abuse, or harm other users',
                'Upload malicious code or viruses',
                'Violate any applicable laws or regulations',
                'Reverse engineer or attempt to access our source code',
                'Share account credentials with others',
                'Spam or send unsolicited messages',
              ]),

              const SizedBox(height: 24),

              // Content Ownership
              _SectionHeader(title: '5. Content and Intellectual Property'),
              const SizedBox(height: 12),
              _SubSection(
                title: 'Your Content',
                content: 'You retain ownership of code and content you submit. By submitting content, you grant CodeMania a worldwide, non-exclusive, royalty-free license to use, display, and distribute your submissions for platform operation and improvement.',
              ),
              const SizedBox(height: 16),
              _SubSection(
                title: 'Platform Content',
                content: 'All problems, contests, educational materials, and platform features are owned by CodeMania or our licensors. You may not copy, modify, or distribute platform content without permission.',
              ),

              const SizedBox(height: 24),

              // Contest Rules
              _SectionHeader(title: '6. Contests and Competitions'),
              const SizedBox(height: 12),
              Text(
                'When participating in contests:',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              _BulletList(items: [
                'You must follow all contest-specific rules',
                'Submissions must be your own original work',
                'Collaboration is prohibited unless explicitly allowed',
                'We reserve the right to disqualify cheaters',
                'Contest results and rankings are final',
              ]),

              const SizedBox(height: 24),

              // Premium Services
              _SectionHeader(title: '7. Premium Services and Payments'),
              const SizedBox(height: 12),
              Text(
                'Some features require a premium subscription. By purchasing premium services:',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              _BulletList(items: [
                'You agree to pay all applicable fees',
                'Subscriptions automatically renew unless cancelled',
                'Refunds are provided according to our refund policy',
                'We may change pricing with 30 days notice',
                'You are responsible for payment method accuracy',
              ]),

              const SizedBox(height: 24),

              // Termination
              _SectionHeader(title: '8. Termination'),
              const SizedBox(height: 12),
              Text(
                'We reserve the right to suspend or terminate your account at any time for:',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              _BulletList(items: [
                'Violation of these Terms',
                'Fraudulent or illegal activity',
                'Prolonged inactivity',
                'Request by law enforcement',
              ]),
              const SizedBox(height: 12),
              Text(
                'You may delete your account at any time through account settings.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 24),

              // Disclaimer
              _SectionHeader(title: '9. Disclaimer of Warranties'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA116).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFA116).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'CODEMANIA IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND. WE DO NOT GUARANTEE UNINTERRUPTED, ERROR-FREE, OR SECURE SERVICE. YOUR USE IS AT YOUR OWN RISK.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.8),
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Limitation of Liability
              _SectionHeader(title: '10. Limitation of Liability'),
              const SizedBox(height: 12),
              Text(
                'To the maximum extent permitted by law, CodeMania and its affiliates shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use or inability to use our services.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 24),

              // Changes to Terms
              _SectionHeader(title: '11. Changes to Terms'),
              const SizedBox(height: 12),
              Text(
                'We reserve the right to modify these Terms at any time. We will notify users of significant changes via email or platform notification. Continued use after changes constitutes acceptance of the new Terms.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 24),

              // Governing Law
              _SectionHeader(title: '12. Governing Law'),
              const SizedBox(height: 12),
              Text(
                'These Terms are governed by the laws of the jurisdiction in which CodeMania operates, without regard to conflict of law principles. Any disputes shall be resolved through binding arbitration.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 24),

              // Contact
              _SectionHeader(title: '13. Contact Information'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'For questions about these Terms, contact us:',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ContactRow(icon: Icons.email, text: 'legal@codemania.com'),
                    const SizedBox(height: 8),
                    _ContactRow(icon: Icons.language, text: 'www.codemania.com/terms'),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Acceptance footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: const Color(0xFF2563EB),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'By using CodeMania, you agree to these Terms of Service',
                        style: textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF2563EB),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Text(
      title,
      style: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _SubSection extends StatelessWidget {
  const _SubSection({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.8),
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '•  ',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Text(
                  item,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.8),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }
}
