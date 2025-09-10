import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Menu', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF2D1B69), const Color(0xFF1A1A1A)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Privacy', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                // Privacy Policy Card
                InkWell(
                  onTap: () => _showPrivacyDialog(context),
                  child: _buildCard(themeProvider, 'Privacy Policy', 'How we use your data', Icons.privacy_tip, Colors.blue),
                ),
                const SizedBox(height: 16),
                // Terms Card  
                InkWell(
                  onTap: () => _showTermsDialog(context),
                  child: _buildCard(themeProvider, 'Terms & Conditions', 'App usage terms', Icons.gavel, Colors.orange),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(ThemeProvider theme, String title, String subtitle, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: theme.isDarkMode ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(color: theme.isDarkMode ? Colors.white70 : Colors.grey, fontSize: 14)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: theme.isDarkMode ? Colors.white70 : Colors.grey, size: 16),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        title: Text('Privacy Policy', style: TextStyle(color: theme.isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: RichText(
              textAlign: TextAlign.justify,
              text: TextSpan(
                style: TextStyle(color: theme.isDarkMode ? Colors.white70 : Colors.black87, fontSize: 14, height: 1.4),
                children: [
                  TextSpan(text: 'Stela Network operates the mobile application Stela Network, which allows users to mine virtual tokens named STC Tokens, with the option to convert them into \$STC in the future.\n\n'),
                  TextSpan(text: 'Your privacy is important to us. This Privacy Policy explains how we collect, use, and protect your personal information.\n\n'),
                  TextSpan(text: '1. Information We Collect\n', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: 'We collect the following categories of information when you use the App:\n\n'),
                  TextSpan(text: 'a. Personal Information\n', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: '• Email address (via Firebase Authentication)\n• Referral code / inviter ID\n• User-generated username or nickname\n\n'),
                  TextSpan(text: 'b. Usage Information\n', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: '• Total STC Tokens mined\n• Time spent in-app\n• Referral activity\n• Bonus/mining activity (ads watched, boosters used)\n\n'),
                  TextSpan(text: 'c. Device Information\n', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: '• Device model, OS version, and language\n• Anonymous device identifiers (for analytics or fraud prevention)\n\n'),
                  TextSpan(text: 'd. Advertising Data\n', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: '• Ad interaction data (if you watch rewarded ads)\n• Ad ID (used for frequency capping and rewards)\n\n'),
                  TextSpan(text: '2. How We Use Your Information\n', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: 'We use your information to:\n• Create and manage your account\n• Track mining activity and token balances\n• Attribute referral bonuses\n• Improve app functionality and user experience\n• Show rewarded ads for mining speed bonuses (if applicable)\n• Prevent fraud and abuse of the mining system\n• Communicate important updates via email (rarely)\n\n'),
                  TextSpan(text: '3. Sharing Your Information\n', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: 'We do not sell your personal data.\n\nWe may share limited, anonymized data with the following third-party services:\n• Firebase Authentication & Firestore (Google LLC) – to manage your account and balances securely\n• AdMob (Google LLC) – to deliver rewarded ads\n• Firebase Analytics – to understand app usage and improve performance\n\nAll third-party tools used are GDPR and CCPA compliant.\n\n'),
                  TextSpan(text: '4. Your Rights and Choices\n', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: 'You have the following rights regarding your data:\n• Access – You may request a copy of the data we store about you.\n• Deletion – You can request permanent deletion of your account and data.\n• Correction – You can request to update inaccurate information.\n• Opt-out – You can opt out of analytics or advertising personalization.\n\nTo exercise your rights, contact us at: '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () async {
                        final Uri emailUri = Uri.parse('mailto:support@stela.network');
                        try {
                          await launchUrl(emailUri, mode: LaunchMode.externalApplication);
                        } catch (e) {}
                      },
                      child: Text(
                        'support@stela.network',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  TextSpan(text: '\n\n'),
                  TextSpan(text: '5. Data Retention\n', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: 'We retain user account and mining data as long as the account is active. If you delete your account, all personal data will be permanently erased within 30 days.\n\n'),
                  TextSpan(text: '6. Data Security\n', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: 'We use industry-standard encryption and Firebase security rules to protect your data. We do not store passwords or sensitive data locally.\n\n'),
                  TextSpan(text: '7. Children\'s Privacy\n', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: 'This app is intended for users 13 years and older. We do not knowingly collect personal information from children under 13.\n\n'),
                  TextSpan(text: '8. Changes to This Policy\n', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: 'We may update this Privacy Policy as the application evolves. The latest version will always be available at '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () async {
                        final Uri webUri = Uri.parse('https://www.stela.network/policy.html');
                        try {
                          await launchUrl(webUri, mode: LaunchMode.externalApplication);
                        } catch (e) {}
                      },
                      child: Text(
                        'www.stela.network/policy.html',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  TextSpan(text: ' and inside the app.\n\n'),
                  TextSpan(text: '9. Contact Us\n', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: 'For any questions regarding privacy or data protection, please contact:\n\nStela Network Team\nEmail: '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () async {
                        final Uri emailUri = Uri.parse('mailto:support@stela.network');
                        try {
                          await launchUrl(emailUri, mode: LaunchMode.externalApplication);
                        } catch (e) {}
                      },
                      child: Text(
                        'support@stela.network',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  TextSpan(text: '\nWebsite: '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () async {
final Uri webUri = Uri.parse('https://stela.network');                        try {
                          await launchUrl(webUri, mode: LaunchMode.externalApplication);
                        } catch (e) {}
                      },
                      child: Text(
                        'www.stela.network',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: theme.isDarkMode ? Colors.blue[300] : Colors.blue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        title: Text('Terms & Conditions', style: TextStyle(color: theme.isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: RichText(
              textAlign: TextAlign.justify,
              text: TextSpan(
                style: TextStyle(color: theme.isDarkMode ? Colors.white70 : Colors.black87, fontSize: 14, height: 1.4),
                children: [
                  TextSpan(text: 'Last updated: August 2025\n\n'),
                  TextSpan(text: 'Welcome to Stela Network. By accessing or using our mobile application, you agree to be bound by these Terms and Conditions. If you do not agree with any part of the terms, please do not use the app.\n\n'),
                  TextSpan(text: '1. Overview\n', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: 'Stela Network is a mobile application that allows users to virtually mine STC tokens. These tokens have no monetary value within the app but may be converted to \$STC tokens in the future, subject to availability and the terms set by the developers.\n\n'),
                  TextSpan(text: '2. Eligibility\n', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: 'You must be at least 13 years old to use this app. By using the app, you represent and warrant that you meet this age requirement and that you agree to abide by all applicable local, national, and international laws.\n\n'),
                  TextSpan(text: '3. Virtual Mining System\n', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: '• Users can mine STC tokens through virtual mining mechanisms including manual tapping, referrals, and watching advertisements.\n• The mining system may include temporary multipliers or bonuses.\n• The rate of mining and total supply may be changed or limited by the app at any time.\n• Virtual tokens mined in the app do not represent a financial asset and have no real-world value until and unless officially converted to \$STC by the developers.\n\n'),
                  TextSpan(text: '4. Conversion to \$STC Tokens\n', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: '• The conversion from STC (virtual) to \$STC (real token) is not guaranteed and will be available only when officially activated.\n• The team reserves the right to set terms, eligibility, and conversion rates.\n• Abuse of the system, including creating fake accounts or exploiting bugs, will result in loss of eligibility.\n\n'),
                  TextSpan(text: '5. Accounts and Data\n', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: '• Users must register an account (via Firebase Authentication) to track mining progress and access features.\n• Each user is responsible for maintaining the confidentiality of their credentials.\n• Multiple accounts or automated activity is prohibited and may result in a permanent ban.\n\n'),
                  TextSpan(text: '6. Advertisements and Monetization\n', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: 'The app may show third-party ads to generate revenue and support the mining ecosystem. By using the app, you agree to view ads as a part of your mining activity.\n\n'),
                  TextSpan(text: '7. Referral Program\n', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: 'Users may increase their mining rate through the referral system. Any abuse of the referral system (self-referrals, bots, etc.) will lead to disqualification from bonuses or account termination.\n\n'),
                  TextSpan(text: '8. Intellectual Property\n', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: 'All logos, designs, content, and functionalities of the app are property of Stela Network and may not be copied, reused, or modified without permission.\n\n'),
                  TextSpan(text: '9. Disclaimer\n', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: '• The app is provided "as is" without warranty of any kind.\n• We do not guarantee profits, token value, or market success.\n• Mining tokens does not imply ownership or guarantee of future gains.\n\n'),
                  TextSpan(text: '10. Termination\n', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: 'We reserve the right to suspend or terminate your access to the app at any time, with or without notice, for any violation of these Terms or illegal activity.\n\n'),
                  TextSpan(text: '11. Changes to Terms\n', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: 'We may update these Terms and Conditions at any time. Continued use of the app after changes implies acceptance of the new terms.\n\n'),
                  TextSpan(text: '12. Contact\n', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: 'If you have questions about these Terms, please contact us at:\nEmail: '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () async {
                        final Uri emailUri = Uri.parse('mailto:support@stela.network');
                        try {
                          await launchUrl(emailUri, mode: LaunchMode.externalApplication);
                        } catch (e) {}
                      },
                      child: Text(
                        'support@stela.network',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: theme.isDarkMode ? Colors.blue[300] : Colors.blue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}