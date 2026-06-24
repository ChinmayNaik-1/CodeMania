import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
        title: const Text('Privacy Policy'),
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
                'Introduction',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'CodeMania ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our competitive programming platform.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 24),

              // Information We Collect
              _SectionHeader(title: 'Information We Collect'),
              const SizedBox(height: 12),
              _SubSection(
                title: '1. Personal Information',
                content: 'When you create an account, we collect:\n• Email address\n• Username\n• Profile information (optional)\n• Authentication credentials',
              ),
              const SizedBox(height: 16),
              _SubSection(
                title: '2. Usage Data',
                content: 'We automatically collect certain information when you use our platform:\n• Problem submissions and solutions\n• Contest participation and results\n• Activity logs and timestamps\n• Device information and IP address',
              ),
              const SizedBox(height: 16),
              _SubSection(
                title: '3. Cookies and Tracking',
                content: 'We use cookies and similar technologies to:\n• Maintain your session\n• Remember your preferences\n• Analyze platform usage\n• Improve user experience',
              ),

              const SizedBox(height: 24),

              // How We Use Your Information
              _SectionHeader(title: 'How We Use Your Information'),
              const SizedBox(height: 12),
              _BulletList(items: [
                'Provide and maintain our competitive programming platform',
                'Process your submissions and calculate rankings',
                'Send notifications about contests and important updates',
                'Improve platform performance and user experience',
                'Detect and prevent fraudulent activities',
                'Respond to your support requests',
                'Comply with legal obligations',
              ]),

              const SizedBox(height: 24),

              // Data Sharing
              _SectionHeader(title: 'Data Sharing and Disclosure'),
              const SizedBox(height: 12),
              Text(
                'We do not sell your personal information. We may share your information in the following circumstances:',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              _BulletList(items: [
                'With your consent or at your direction',
                'With service providers who help us operate the platform',
                'To comply with legal obligations or protect rights',
                'In connection with business transfers or acquisitions',
                'Public leaderboards and contest results (using your username)',
              ]),

              const SizedBox(height: 24),

              // Data Security
              _SectionHeader(title: 'Data Security'),
              const SizedBox(height: 12),
              Text(
                'We implement industry-standard security measures to protect your information, including:\n\n• Encrypted data transmission (SSL/TLS)\n• Secure authentication systems\n• Regular security audits\n• Access controls and monitoring\n\nHowever, no method of transmission over the internet is 100% secure, and we cannot guarantee absolute security.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 24),

              // Your Rights
              _SectionHeader(title: 'Your Rights and Choices'),
              const SizedBox(height: 12),
              Text(
                'You have the right to:',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 12),
              _BulletList(items: [
                'Access and review your personal information',
                'Correct inaccurate or incomplete information',
                'Request deletion of your account and data',
                'Opt-out of marketing communications',
                'Export your data in a portable format',
                'Object to certain data processing activities',
              ]),

              const SizedBox(height: 24),

              // Data Retention
              _SectionHeader(title: 'Data Retention'),
              const SizedBox(height: 12),
              Text(
                'We retain your information for as long as necessary to provide our services and comply with legal obligations. When you delete your account, we will remove your personal information, though some data may be retained for legitimate business purposes or legal requirements.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 24),

              // Children's Privacy
              _SectionHeader(title: "Children's Privacy"),
              const SizedBox(height: 12),
              Text(
                'CodeMania is intended for users aged 13 and older. We do not knowingly collect personal information from children under 13. If you believe we have collected information from a child under 13, please contact us immediately.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 24),

              // International Users
              _SectionHeader(title: 'International Users'),
              const SizedBox(height: 12),
              Text(
                'Your information may be transferred to and processed in countries other than your country of residence. By using CodeMania, you consent to the transfer of your information to our servers and those of our service providers.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 24),

              // Changes to Policy
              _SectionHeader(title: 'Changes to This Privacy Policy'),
              const SizedBox(height: 12),
              Text(
                'We may update this Privacy Policy from time to time. We will notify you of significant changes by posting the new policy on this page and updating the "Last Updated" date. Your continued use of CodeMania after changes constitutes acceptance of the updated policy.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 24),

              // Contact
              _SectionHeader(title: 'Contact Us'),
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
                      'If you have questions about this Privacy Policy, please contact us:',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ContactRow(icon: Icons.email, text: 'privacy@codemania.com'),
                    const SizedBox(height: 8),
                    _ContactRow(icon: Icons.language, text: 'www.codemania.com/privacy'),
                    const SizedBox(height: 8),
                    _ContactRow(icon: Icons.location_on, text: 'CodeMania Inc., 123 Code Street, Tech City, TC 12345'),
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
