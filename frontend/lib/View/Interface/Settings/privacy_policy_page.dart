// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.poppins(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.colorScheme.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              icon: Iconsax.shield_tick,
              title: 'Introduction',
              content:
                  'At BLYND, we take your privacy seriously. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              icon: Iconsax.data,
              title: 'Information We Collect',
              content:
                  '• Personal Information (name, email, profile picture)\n• User Content (posts, comments, likes)\n• Device Information\n• Usage Data\n• Location Information (optional)',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              icon: Iconsax.folder_open,
              title: 'How We Use Your Information',
              content:
                  '• To provide and maintain our Service\n• To notify you about changes\n• To provide customer support\n• To monitor usage of our Service\n• To detect, prevent and address technical issues',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              icon: Iconsax.share,
              title: 'Information Sharing',
              content:
                  'We may share your information with:\n• Service Providers\n• Business Partners\n• Law Enforcement (when required by law)\n\nWe will never sell your personal information to third parties.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              icon: Iconsax.security,
              title: 'Data Security',
              content:
                  'We implement appropriate technical and organizational security measures to protect your data. However, no method of transmission over the internet is 100% secure.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              icon: Iconsax.user_tick,
              title: 'Your Rights',
              content:
                  'You have the right to:\n• Access your data\n• Correct your data\n• Delete your data\n• Object to processing\n• Data portability',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              icon: Iconsax.message_question,
              title: 'Contact Us',
              content:
                  'If you have any questions about this Privacy Policy, please contact us at:\nEmail: privacy@blynd.com\nAddress: [Your Address]',
            ),
            const SizedBox(height: 24),
            Text(
              'Last updated: ${DateTime.now().year}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: theme.colorScheme.primary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: theme.colorScheme.primary.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
