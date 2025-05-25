import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = packageInfo.version;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _version = 'Unknown';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'About',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Logo
                  Center(
                    child: Theme.of(context).brightness == Brightness.light
                        ? Image.asset(
                            'assets/icons/icon_blynd_light.png',
                            height: 120,
                          )
                        : Image.asset(
                            'assets/icons/icon_blynd_dark.png',
                            height: 120,
                          ),
                  ),
                  const SizedBox(height: 24),

                  // App Version
                  _buildInfoSection(
                    context,
                    icon: Iconsax.code,
                    title: 'Version',
                    content: _version,
                  ),
                  const SizedBox(height: 24),

                  // About App
                  _buildInfoSection(
                    context,
                    icon: Iconsax.info_circle,
                    title: 'About BLYND',
                    content:
                        'BLYND is a social media platform designed to connect people through shared interests and meaningful conversations. Our mission is to create a safe and engaging space for users to express themselves and build genuine connections.',
                  ),
                  const SizedBox(height: 24),

                  // Features
                  _buildInfoSection(
                    context,
                    icon: Iconsax.star,
                    title: 'Features',
                    content:
                        '• Share moments through posts\n• Connect with like-minded people\n• Engage in meaningful conversations\n• Customize your profile\n• Dark mode support\n• Privacy-focused design',
                  ),
                  const SizedBox(height: 24),

                  // Contact
                  _buildInfoSection(
                    context,
                    icon: Iconsax.message,
                    title: 'Contact Us',
                    content:
                        'For support or inquiries:\nEmail: support@blynd.com\nWebsite: www.blynd.com',
                  ),
                  const SizedBox(height: 24),

                  // Credits
                  _buildInfoSection(
                    context,
                    icon: Iconsax.heart,
                    title: 'Credits',
                    content:
                        'Made with ❤️ by the BLYND team.\nSpecial thanks to our amazing community!',
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoSection(
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
