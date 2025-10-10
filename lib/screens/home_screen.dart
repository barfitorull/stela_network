import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:stela_network/providers/mining_provider.dart';
import 'package:stela_network/providers/theme_provider.dart';
import 'package:stela_network/providers/admin_provider.dart';
import 'package:stela_network/services/admob_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'admin_login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  Timer? _cooldownTimer;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  bool _isTeamExpanded = false;
  
  // Admin access
  int _adminTapCount = 0;
  Timer? _adminTapTimer;

  @override
  void initState() {
    super.initState();
    _startCooldownTimer();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Load ads
    _loadAds();
    
    // Start periodic refresh for team data
    _startTeamDataRefreshTimer();
    
    // Load initial team data after a short delay to ensure provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<MiningProvider>(context, listen: false);
      
      // Wait for provider to be fully initialized
      int attempts = 0;
      while (provider.referralCode == null && attempts < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      
      if (provider.referralCode != null) {
        print('🎯 HomeScreen: Referral code loaded: ${provider.referralCode}');
        _loadInitialTeamData(provider.referralCode!);
      } else {
        print('🎯 HomeScreen: Referral code still null after waiting');
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _adminTapTimer?.cancel();
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // Admin access function
  void _handleAdminTap() {
    _adminTapCount++;
    _adminTapTimer?.cancel();
    
    if (_adminTapCount >= 7) {
      // Open admin login
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
      );
      _adminTapCount = 0;
    } else {
      // Reset counter after 3 seconds
      _adminTapTimer = Timer(const Duration(seconds: 3), () {
        _adminTapCount = 0;
      });
    }
  }

  void _startCooldownTimer() {
    _cooldownTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          // This will trigger rebuild and update countdown
        });
      }
    });
  }

  void _startTeamDataRefreshTimer() {
    // Refresh team data every 10 minutes for real-time updates
    Timer.periodic(const Duration(minutes: 10), (timer) {
      if (mounted) {
        final provider = Provider.of<MiningProvider>(context, listen: false);
        if (provider.referralCode != null) {
          _forceRefreshTeamData(provider.referralCode!);
        }
      }
    });
  }

  void _loadAds() async {
    try {
      await AdMobService.loadInterstitialAd();
      await AdMobService.loadRewardedAd();
      print('✅ Ads loaded successfully');
    } catch (e) {
      print('❌ Error loading ads: $e');
    }
  }

  // Load initial team data when screen loads
  void _loadInitialTeamData(String referralCode) async {
    if (referralCode.isNotEmpty && !_teamMembersCache.containsKey(referralCode)) {
      await _loadTeamMembers(referralCode);
      if (mounted) {
        setState(() {});
      }
    }
  }

  // Clear cache when team is expanded to get fresh data
  void _refreshTeamData(String referralCode) async {
    _teamMembersCache.remove(referralCode);
    _cacheTimestamps.remove(referralCode);
    
    // Load fresh data
    await _loadTeamMembers(referralCode);
    
    if (mounted) {
      setState(() {}); // Trigger rebuild
    }
  }

  // Force refresh team data (clear cache and reload)
  void _forceRefreshTeamData(String referralCode) async {
    _teamMembersCache.remove(referralCode);
    _cacheTimestamps.remove(referralCode);
    
    // Load fresh data
    await _loadTeamMembers(referralCode);
    
    if (mounted) {
      setState(() {}); // Trigger rebuild
    }
  }

  // Cache for team members to avoid repeated queries
  Map<String, List<Map<String, dynamic>>> _teamMembersCache = {};
  Map<String, DateTime> _cacheTimestamps = {};

  // Load team members from Firestore with caching
  Future<List<Map<String, dynamic>>> _loadTeamMembers(String referralCode) async {
    if (referralCode.isEmpty) return [];
    
    // Check cache first (cache for 2 seconds for real-time updates)
    final now = DateTime.now();
    if (_teamMembersCache.containsKey(referralCode)) {
      final cacheTime = _cacheTimestamps[referralCode];
      if (cacheTime != null && now.difference(cacheTime).inMinutes < 15) {
        return _teamMembersCache[referralCode]!;
      }
    }
    
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('referredBy', isEqualTo: referralCode)
          .get();
      
      final teamMembers = <Map<String, dynamic>>[];
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final email = data['email'] as String? ?? 'Unknown';
        final username = data['username'] as String? ?? 'Unknown';
        final isMining = data['isMining'] as bool? ?? false;
        final lastMiningUpdate = data['lastMiningUpdate'] as int?;
        final lastAppActivity = data['lastAppActivity'] as int?;
        
        // Determine if member is active (currently mining)
        final isActive = isMining;
        
        // Create display name: email - username
        final displayName = '$email - $username';
        
        teamMembers.add({
          'email': email,
          'username': username,
          'displayName': displayName,
          'isActive': isActive,
        });
      }
      
      // CRITICAL: Update provider with local activeReferrals and totalReferrals count
      final provider = Provider.of<MiningProvider>(context, listen: false);
      final activeCount = teamMembers.where((member) => member['isActive'] == true).length;
      final totalCount = teamMembers.length;
      provider.updateReferralsFromTeam(activeCount, totalCount);
      
      
      // Cache the result
      _teamMembersCache[referralCode] = teamMembers;
      _cacheTimestamps[referralCode] = now;
      
      return teamMembers;
    } catch (e) {
      print('Error loading team members: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MiningProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF2D1B69), // Dark purple
                  const Color(0xFF1A1A1A), // Dark gray
                ],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 32, // Account for padding
                      ),
                      child: Column(
                        children: [
                          // Header
                          _buildHeader(),
                          const SizedBox(height: 24),
                          
                          // Balance Card
                          _buildBalanceCard(provider),
                          const SizedBox(height: 24),
                          
                          // Mining Controls
                          _buildMiningControls(provider),
                          const SizedBox(height: 24),
                          
                          // Booster Section
                          _buildBoosterSection(provider),
                          const SizedBox(height: 24),
                          
                          // Super Booster Section
                          _buildSuperBoosterSection(provider),
                          const SizedBox(height: 24),
                          
                          // Referral Section
                          _buildReferralSection(provider),
                          const SizedBox(height: 24),
                          
                          // Community Section
                          _buildCommunitySection(),
                          
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final miningProvider = Provider.of<MiningProvider>(context, listen: false);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Stela Network',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () async {
                final Uri url = Uri.parse('https://stela.network');
                await launchUrl(url, mode: LaunchMode.externalApplication);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Access',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceCard(MiningProvider provider) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: provider.isMining 
            ? LinearGradient(
                colors: [
                  const Color(0xFFFFD700).withOpacity(0.1),
                  const Color(0xFFFFD700).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
                          : LinearGradient(
                colors: [
                  themeProvider.isDarkMode ? Color(0xFF2A2A2A) : Color(0xFFE0E0E0),
                  themeProvider.isDarkMode ? Color(0xFF2A2A2A) : Color(0xFFE0E0E0)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: provider.isMining ? const Color(0xFFFFD700) : Colors.grey.withOpacity(0.3),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: provider.isMining 
                ? const Color(0xFFFFD700).withOpacity(0.3)
                : const Color(0xFF4A90E2).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'BALANCE',
            style: TextStyle(
              color: provider.isMining ? Colors.white70 : (themeProvider.isDarkMode ? Colors.white70 : Colors.black),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${provider.balance.toStringAsFixed(4)} STC',
            style: TextStyle(
              color: provider.isMining ? Colors.white : (themeProvider.isDarkMode ? Colors.white : Colors.black),
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem('Mining Rate', '${provider.miningRate.toStringAsFixed(2)} STC/hr'),
              _buildInfoItem('Active Referrals', '${provider.activeReferrals}/${provider.totalReferrals}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final provider = Provider.of<MiningProvider>(context);
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: provider.isMining ? Colors.white70 : (themeProvider.isDarkMode ? Colors.white70 : Colors.grey),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: provider.isMining ? Colors.white : (themeProvider.isDarkMode ? Colors.white : Colors.black),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMiningControls(MiningProvider provider) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: provider.isMining ? Colors.green : Colors.grey.withOpacity(0.3),
          width: 2.0,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MINING',
                style: TextStyle(
                  color: provider.isMining ? Colors.green : Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: provider.isMining ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  provider.isMining ? 'ACTIVE' : 'INACTIVE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              if (!provider.isMining) {
                // Show interstitial ad BEFORE starting mining
                AdMobService.showInterstitialAdForMining(
                  onAdCompleted: () {
                    // User watched the entire ad - NOW start mining
                    provider.startMining();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Mining started! +${provider.miningRate.toStringAsFixed(2)} STC/hr',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode ? Colors.black : Colors.white,
                            ),
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  onAdFailed: () {
                    // Ad failed to load - start mining anyway
                    provider.startMining();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Mining started! +${provider.miningRate.toStringAsFixed(2)} STC/hr',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode ? Colors.black : Colors.white,
                            ),
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                );
              }
            },
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    themeProvider.isDarkMode ? Color(0xFF2A2A2A) : Color(0xFFE0E0E0),
                    themeProvider.isDarkMode ? Color(0xFF3A3A3A) : Color(0xFFF0F0F0)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: provider.isMining ? Colors.green : Colors.grey.withOpacity(0.3),
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (provider.isMining ? Colors.green : Colors.grey).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Timer circle
                  if (provider.isMining)
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: CircularProgressIndicator(
                        value: _getTimerProgress(),
                        strokeWidth: 6,
                        backgroundColor: Colors.grey.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                  // Logo
                  provider.isMining 
                    ? _buildAnimatedLogo()
                    : _buildStaticLogo(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            provider.isMining ? _getCountdownText() : 'START MINING',
            style: TextStyle(
              color: provider.isMining ? Colors.green : (themeProvider.isDarkMode ? Colors.grey : Colors.black),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoosterSection(MiningProvider provider) {
    final canUse = provider.boostersRemaining > 0 && _canUseBooster(provider);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canUse ? Colors.orange : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BOOSTER',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: canUse ? Colors.orange : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  canUse ? 'AVAILABLE' : _getBoosterCooldownText(provider),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '+ 2 STC/hr MINING RATE',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Boosters remaining: ${provider.boostersRemaining}/10',
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: canUse ? () => _useBooster(provider) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canUse ? Colors.orange : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'BOOST',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuperBoosterSection(MiningProvider provider) {
    // Super booster disponibil DOAR când boostere normale s-au terminat
    final isSuperBoosterUnlocked = provider.boostersRemaining == 0;
    final canUseSuperBooster = isSuperBoosterUnlocked && provider.superBoostersRemaining > 0 && _canUseBooster(provider);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canUseSuperBooster ? Colors.red : (isSuperBoosterUnlocked ? Colors.red.withOpacity(0.3) : Colors.grey.withOpacity(0.3)),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SUPER BOOSTER',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: canUseSuperBooster ? Colors.red : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  canUseSuperBooster ? 'AVAILABLE' : (isSuperBoosterUnlocked ? _getBoosterCooldownText(provider) : 'LOCKED'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '+ 4 STC/hr MINING RATE',
            style: TextStyle(
              color: Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSuperBoosterUnlocked 
                        ? 'Super Boosters: ${provider.superBoostersRemaining}/10' 
                        : 'Unlock by using all normal boosters',
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: canUseSuperBooster ? () => _useSuperBooster(provider) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canUseSuperBooster ? Colors.red : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'SUPER BOOST',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReferralSection(MiningProvider provider) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REFERRAL',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
                     const SizedBox(height: 16),
           // Your Referral Code section (permanent)
           Row(
             children: [
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       'Your Referral Code',
                       style: TextStyle(
                         color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                         fontSize: 14,
                       ),
                     ),
                     const SizedBox(height: 8),
                     if (provider.referralCode != null)
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                         decoration: BoxDecoration(
                           color: Colors.purple,
                           borderRadius: BorderRadius.circular(8),
                         ),
                         child: Text(
                           'Code: ${provider.referralCode}',
                           style: const TextStyle(
                             color: Colors.white,
                             fontSize: 12,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                       ),
                   ],
                 ),
               ),
                               if (provider.referralCode != null) ...[
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () {
                      // Copy code functionality
                      Clipboard.setData(ClipboardData(text: provider.referralCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Referral code copied: ${provider.referralCode}',
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
                    icon: const Icon(
                      Icons.copy,
                      color: Colors.purple,
                      size: 24,
                    ),
                  ),
                ],
             ],
           ),
           const SizedBox(height: 20),
           // Divider
           Divider(
             color: Colors.purple.withOpacity(0.3),
             thickness: 1,
             height: 1,
           ),
           const SizedBox(height: 20),
           // My Team section (permanent)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Team: ${provider.totalReferrals ?? 0}/${provider.activeReferrals}',
                        style: TextStyle(
                          color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bonus: +${(provider.activeReferrals * 0.20).toStringAsFixed(2)} STC/hr',
                        style: const TextStyle(
                          color: Colors.purple,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                                 IconButton(
                   onPressed: () {
                     final wasExpanded = _isTeamExpanded;
                     setState(() {
                       _isTeamExpanded = !_isTeamExpanded;
                     });
                     // Refresh team data when expanding
                     if (!wasExpanded) {
                       _refreshTeamData(provider.referralCode ?? '');
                     }
                   },
                                     icon: Icon(
                     _isTeamExpanded ? Icons.expand_less : Icons.expand_more,
                     color: Colors.purple,
                     size: 28,
                   ),
                ),
              ],
            ),
            // Expanded team list
            if (_isTeamExpanded) ...[
              const SizedBox(height: 12),
              _buildTeamList(provider),
            ],
                       const SizedBox(height: 20),
            // Divider
            Divider(
              color: Colors.purple.withOpacity(0.3),
              thickness: 1,
              height: 1,
            ),
            const SizedBox(height: 20),
            // Invite People to Join section
            Row(
             children: [
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       'Invite People to Join',
                       style: TextStyle(
                         color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                         fontSize: 14,
                       ),
                     ),
                     const SizedBox(height: 8),
                     Text(
                       'Share and earn together!',
                       style: TextStyle(
                         color: themeProvider.isDarkMode ? Colors.white54 : Colors.grey,
                         fontSize: 12,
                       ),
                     ),
                   ],
                 ),
               ),
               const SizedBox(width: 16),
               IconButton(
                 onPressed: () => _shareApp(provider),
                 icon: const Icon(
                   Icons.share,
                   color: Colors.purple,
                   size: 24,
                 ),
               ),
             ],
           ),
        ],
      ),
    );
  }

  bool _canUseBooster(MiningProvider provider) {
    if (provider.lastBoosterTime == null) return true;
    
    final timeSinceLastBooster = DateTime.now().difference(provider.lastBoosterTime!);
    return timeSinceLastBooster.inSeconds >= 10;
  }

  String _getBoosterCooldownText(MiningProvider provider) {
    if (provider.lastBoosterTime == null) return 'AVAILABLE';
    
    final timeSinceLastBooster = DateTime.now().difference(provider.lastBoosterTime!);
    final remainingSeconds = 10 - timeSinceLastBooster.inSeconds;
    
    if (remainingSeconds <= 0) return 'AVAILABLE';
    
    return '${remainingSeconds}s';
  }

  Future<void> _useSuperBooster(MiningProvider provider) async {
    // Check if mining is active BEFORE showing ad
    if (!provider.isMining) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Start mining first to use super boosters!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode ? Colors.black : Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return; // Exit early - don't show ad
    }
    
    // Show rewarded ad for SUPER booster (ads already preloaded in initState)
    AdMobService.showRewardedAdForBooster(
      onRewarded: () async {
        try {
          await provider.useSuperBooster();
          // Reload ad for next use
          _loadAds();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Super Booster activated! +0.40 STC/hr',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode ? Colors.black : Colors.white,
                  ),
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      onFailed: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Ad not available. Please try again later.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
    );
  }

  Future<void> _useBooster(MiningProvider provider) async {
    // Check if mining is active BEFORE showing ad
    if (!provider.isMining) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Start mining first to use boosters!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode ? Colors.black : Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return; // Exit early - don't show ad
    }
    
    // Show rewarded ad for booster (ads already preloaded in initState)
    AdMobService.showRewardedAdForBooster(
      onRewarded: () async {
        try {
          await provider.useBooster();
          // Reload ad for next use
          _loadAds();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Booster activated! +0.20 STC/hr',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode ? Colors.black : Colors.white,
                  ),
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      onFailed: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Ad not available. Please try again later.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
    );
  }

  Widget _buildAnimatedLogo() {
    return Consumer<MiningProvider>(
      builder: (context, provider, child) {
        if (provider.isMining) {
          _rotationController.repeat();
          _pulseController.repeat(reverse: true);
        } else {
          _rotationController.stop();
          _pulseController.stop();
        }
        
        return AnimatedBuilder(
          animation: Listenable.merge([_rotationController, _pulseController]),
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationController.value * 2 * 3.14159,
              child: Transform.scale(
                scale: 0.9 + (_pulseController.value * 0.1),
                child: GestureDetector(
                  onTap: _handleAdminTap,
                  child: const Image(
                    image: AssetImage('assets/stela_app_logo.png'),
                    width: 100,
                    height: 100,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStaticLogo() {
    return const Image(
      image: AssetImage('assets/stela_app_logo.png'),
      width: 100,
      height: 100,
    );
  }

  double _getTimerProgress() {
    // Get session start time from provider
    final sessionStartTime = context.read<MiningProvider>().sessionStartTime;
    if (sessionStartTime == null) return 0.0;
    
    final now = DateTime.now();
    final elapsed = now.difference(sessionStartTime).inSeconds;
    final totalSessionSeconds = 24 * 60 * 60; // 24 hours in seconds
    final progress = (elapsed / totalSessionSeconds).clamp(0.0, 1.0);
    return progress;
  }

  String _getCountdownText() {
    final sessionStartTime = context.read<MiningProvider>().sessionStartTime;
    print('🔍 DEBUG: sessionStartTime = $sessionStartTime');
    if (sessionStartTime == null) return '00:00:00';
    
    final now = DateTime.now();
    final elapsed = now.difference(sessionStartTime).inSeconds;
    final totalSessionSeconds = 24 * 60 * 60; // 24 hours in seconds
    final remainingSeconds = totalSessionSeconds - elapsed;
    
    if (remainingSeconds <= 0) return '00:00:00';
    
    final hours = (remainingSeconds / 3600).floor();
    final minutes = ((remainingSeconds % 3600) / 60).floor();
    final seconds = remainingSeconds % 60;
    
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildCommunitySection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'COMMUNITY',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Join Stela Community!',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialIcon(
                Icons.close_rounded, // X icon (stylized X logo)
                'X',
                'https://x.com/StelaNetwork',
                Colors.black,
              ),
              _buildSocialIcon(
                Icons.telegram,
                'Telegram',
                'https://t.me/stela_network',
                const Color(0xFF0088CC), // Telegram blue
              ),
              _buildSocialIcon(
                Icons.discord,
                'Discord',
                'https://discord.gg/xHw8a43S',
                const Color(0xFF5865F2), // Discord purple
              ),
              _buildSocialIcon(
                Icons.facebook,
                'Facebook',
                'https://www.facebook.com/groups/788622600217668/',
                const Color(0xFF1877F2), // Facebook blue
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, String label, String url, Color color) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return GestureDetector(
      onTap: () async {
        final Uri uri = Uri.parse(url);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: label == 'X' 
              ? _buildXLogo()
              : Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white70 : Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Custom X logo widget
  Widget _buildXLogo() {
    return Image.asset(
      'assets/x_logo.png',
      width: 24,
      height: 24,
    );
  }

  // Share app function
  void _shareApp(MiningProvider provider) async {
    // Wait for referral code to be loaded
    if (provider.referralCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please wait, loading your referral code...',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    final referralCode = provider.referralCode!;
    final shareText = '''🚀 STELA NETWORK - Revolutionary Mining App!

💰 Use my code $referralCode and get 10 STC bonus instantly! Mine STC tokens automatically 24/7 and earn passive income while you sleep. Build your team, invite friends and multiply your earnings together.

⚡ Join the future of mining today!''';

    // Detect platform and set appropriate store link
    final storeLink = Theme.of(context).platform == TargetPlatform.iOS 
        ? 'https://apps.apple.com/app/stela-network/id123456789' // Replace with actual App Store link
        : 'https://play.google.com/store/apps/details?id=com.stelanetwork.app'; // Replace with actual Play Store link

    final fullShareText = '$shareText\n\n$storeLink';

    try {
      await Share.share(fullShareText, subject: 'Join STELA NETWORK!');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error sharing: $e',
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

    // Build team list widget
  Widget _buildTeamList(MiningProvider provider) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    // Use cached data if available, otherwise show loading
    if (_teamMembersCache.containsKey(provider.referralCode ?? '')) {
      final teamMembers = _teamMembersCache[provider.referralCode ?? '']!;
      
      if (teamMembers.isEmpty) {
        return Text(
          'No team members yet',
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Team members list
          ...teamMembers.map((member) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    member['displayName'] as String? ?? member['email'] as String,
                    style: TextStyle(
                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.black,
                      fontSize: 12,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: member['isActive'] as bool ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    member['isActive'] as bool ? 'ACTIVE' : 'INACTIVE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
          // Ping Inactive Members button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  // Call Cloud Function to ping inactive members
                  final functions = FirebaseFunctions.instance;
                  final result = await functions.httpsCallable('pingInactiveMembers').call();
                  
                  if (mounted) {
                    // Check if it's an error response
                    if (result.data['success'] == false) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result.data['error'] ?? 'Ping failed',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result.data['message'] ?? 'Ping sent successfully!',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    String errorMessage = 'Error: ${e.toString()}';
                    
                    // Handle specific cooldown error
                    if (e.toString().contains('cooldown')) {
                      errorMessage = e.toString().replaceAll('Error: ', '');
                    }
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Ping Inactive Members',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // Show loading only if no cached data
      return const Center(child: CircularProgressIndicator());
    }
  }
 } 