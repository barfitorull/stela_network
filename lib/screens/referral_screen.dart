import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/theme_provider.dart';
import '../providers/mining_provider.dart';

class ReferralScreen extends StatefulWidget {
  final String? referralCode;
  final int totalReferrals;
  final int activeReferrals;

  const ReferralScreen({
    Key? key,
    this.referralCode,
    this.totalReferrals = 0,
    this.activeReferrals = 0,
  }) : super(key: key);

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final TextEditingController _referralController = TextEditingController();

  @override
  void dispose() {
    _referralController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Referral System', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2D1B69), Color(0xFF1A1A1A)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Invite Friends & Earn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildReferralContent(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReferralContent() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Referral System',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildReferralCodeSection(themeProvider),
          const SizedBox(height: 16),
          _buildTeamStatsSection(themeProvider),
          const SizedBox(height: 16),
          _buildAddReferralSection(themeProvider),
        ],
      ),
    );
  }

  Widget _buildReferralCodeSection(ThemeProvider themeProvider) {
    final miningProvider = Provider.of<MiningProvider>(context, listen: false);
    final referralCode = miningProvider.referralCode ?? 'Loading...';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Referral Code:',
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  referralCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            if (referralCode != 'Loading...')
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: referralCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Referral code copied: $referralCode',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, color: Colors.purple),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamStatsSection(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Team: ${widget.totalReferrals}/${widget.activeReferrals}',
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Bonus: +${(widget.activeReferrals * 0.20).toStringAsFixed(2)} STC/hr',
          style: const TextStyle(
            color: Colors.purple,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAddReferralSection(ThemeProvider themeProvider) {
    final miningProvider = Provider.of<MiningProvider>(context, listen: false);
    
    if (miningProvider.referredBy != null) {
      // User has a referrer - show "Your Referrer"
      return FutureBuilder<DocumentSnapshot?>(
        future: FirebaseFirestore.instance
            .collection('users')
            .where('referralCode', isEqualTo: miningProvider.referredBy)
            .limit(1)
            .get()
            .then((querySnapshot) => querySnapshot.docs.isNotEmpty 
                ? querySnapshot.docs.first.reference.get() 
                : null),
        builder: (context, snapshot) {
          String referrerDisplay = miningProvider.referredBy!;
          
          if (snapshot.hasData && snapshot.data != null) {
            final userData = snapshot.data!.data() as Map<String, dynamic>?;
            if (userData != null && userData['username'] != null) {
              referrerDisplay = '${miningProvider.referredBy} - ${userData['username']}';
            } else if (userData != null && userData['email'] != null) {
              // Fallback to email if username doesn't exist (for old accounts)
              referrerDisplay = '${miningProvider.referredBy} - ${userData['email']}';
            }
          }
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Referrer',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  referrerDisplay,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else {
      // User doesn't have a referrer - show "Add Referral Code"
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Referral Code',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _referralController,
            decoration: InputDecoration(
              hintText: 'Enter referral code',
              hintStyle: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white54 : Colors.grey,
              ),
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: themeProvider.isDarkMode ? Colors.white30 : Colors.grey,
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.purple),
              ),
            ),
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _addReferralCode(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Add Referral Code'),
            ),
          ),
        ],
      );
    }
  }

  void _addReferralCode() async {
    final code = _referralController.text.trim().toUpperCase();
    if (code.isNotEmpty) {
      try {
        final miningProvider = Provider.of<MiningProvider>(context, listen: false);
        await miningProvider.addReferralCode(code);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'SUCCESS: Referral Code Added: $code',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        _referralController.clear();
        // Force rebuild to show "Your Referrer" instead of "Add Referral Code"
        setState(() {});
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ERROR: Invalid Referral Code',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ERROR: Please enter a referral code',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
} 