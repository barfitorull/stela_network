import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mining_provider.dart';
import '../providers/theme_provider.dart';

class RankScreen extends StatelessWidget {
  const RankScreen({Key? key}) : super(key: key);

  String _getRankCategory(double balance) {
    if (balance >= 10000000) return 'Stellar';
    if (balance >= 5000000) return 'Astral';
    if (balance >= 1000000) return 'Voyager';
    if (balance >= 100000) return 'Explorer';
    return 'Pioneer';
  }

  List<Color> _getRankGradient(String rank) {
    switch (rank) {
      case 'Stellar':
        return [
          const Color(0xFFFFFFFF), // Alb pur - highlight
          const Color(0xFFE5E4E2), // Platină clasică - reflexie intermediară
          const Color(0xFFC0C0C0), // Gri metalic - gradient end
        ];
      case 'Astral':
        return [
          const Color(0xFFFFEF8A), // Aur strălucitor
          const Color(0xFFFFC300), // Ton mai cald pentru margini
          const Color(0xFFFFD700), // Aur clasic
        ];
      case 'Voyager':
        return [
          const Color(0xFFF5F5F5), // Argint lucios
          const Color(0xFFDCDCDC), // Difuz pentru efect sticlă
          const Color(0xFFB0B0B0), // Gri metalizat
        ];
      case 'Explorer':
        return [
          const Color(0xFFD99156), // Bronz cald
          const Color(0xFFCD7F32), // Ton intermediar de profunzime
          const Color(0xFF8B4513), // Cupru roșcat închis
        ];
      case 'Pioneer':
      default:
        return [
          const Color(0xFF9CAEBB), // Gri-albastru deschis
          const Color(0xFF7A8B8B), // Reflexie rece ușoară
          const Color(0xFF6E7B8B), // Oțel industrial
        ];
    }
  }

  Color _getRankBorderColor(String rank) {
    switch (rank) {
      case 'Stellar':
        return const Color(0xFFE5E4E2); // Platină
      case 'Astral':
        return const Color(0xFFFFD700); // Aur
      case 'Voyager':
        return const Color(0xFFB0B0B0); // Argint
      case 'Explorer':
        return const Color(0xFFCD7F32); // Bronz
      case 'Pioneer':
      default:
        return const Color(0xFF6E7B8B); // Oțel
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Consumer<MiningProvider>(
              builder: (context, miningProvider, child) {
                final currentRank = _getRankCategory(miningProvider.balance);
                final currentRankGradient = _getRankGradient(currentRank);
                final currentRankBorderColor = _getRankBorderColor(currentRank);
                
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current Rank Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Provider.of<ThemeProvider>(context).isDarkMode 
                              ? const Color(0xFF2A2A2A) 
                              : const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: currentRankBorderColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: currentRankGradient,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Current Rank',
                              style: TextStyle(
                                color: Provider.of<ThemeProvider>(context).isDarkMode 
                                    ? Colors.white70 
                                    : Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentRank,
                              style: TextStyle(
                                color: Provider.of<ThemeProvider>(context).isDarkMode 
                                    ? Colors.white 
                                    : Colors.black,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${miningProvider.balance.toStringAsFixed(4)} STC',
                              style: TextStyle(
                                color: Provider.of<ThemeProvider>(context).isDarkMode 
                                    ? Colors.white 
                                    : Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Rank Categories
                      Text(
                        'Rank Categories',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildRankCard(
                        context,
                        'Pioneer',
                        '0 - 100,000 STC',
                        miningProvider.balance >= 0 && miningProvider.balance < 100000,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildRankCard(
                        context,
                        'Explorer',
                        '100,000 - 999,999 STC',
                        miningProvider.balance >= 100000 && miningProvider.balance < 1000000,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildRankCard(
                        context,
                        'Voyager',
                        '1,000,000 - 5,000,000 STC',
                        miningProvider.balance >= 1000000 && miningProvider.balance < 5000000,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildRankCard(
                        context,
                        'Astral',
                        '5,000,000 - 10,000,000 STC',
                        miningProvider.balance >= 5000000 && miningProvider.balance < 10000000,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildRankCard(
                        context,
                        'Stellar',
                        '10,000,000+ STC',
                        miningProvider.balance >= 10000000,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRankCard(BuildContext context, String rank, String range, bool isCurrent) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final rankGradient = _getRankGradient(rank);
    final rankBorderColor = _getRankBorderColor(rank);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? rankBorderColor.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: isCurrent ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: rankGradient,
              ) : null,
              color: isCurrent ? null : Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.star,
              color: isCurrent ? Colors.white : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rank,
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  range,
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: rankBorderColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'CURRENT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
} 