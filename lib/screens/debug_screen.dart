import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/mining_provider.dart';
import '../providers/theme_provider.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({Key? key}) : super(key: key);

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  Map<String, dynamic>? _firestoreData;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final miningProvider = Provider.of<MiningProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        title: const Text('Debug ReferredBy'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Provider Data
            _buildSection(
              'MiningProvider Data',
              [
                'User ID: ${miningProvider.currentUserId ?? "NULL"}',
                'ReferredBy: ${miningProvider.referredBy ?? "NULL"}',
                'ReferralCode: ${miningProvider.referralCode ?? "NULL"}',
                'Balance: ${miningProvider.balance}',
                'IsMining: ${miningProvider.isMining}',
              ],
              Colors.blue,
            ),
            
            const SizedBox(height: 20),
            
            // Firestore Data
            _buildSection(
              'Firestore Data',
              _firestoreData != null 
                ? [
                    'ReferredBy: ${_firestoreData!['referredBy'] ?? "NULL"}',
                    'ReferralCode: ${_firestoreData!['referralCode'] ?? "NULL"}',
                    'Balance: ${_firestoreData!['balance'] ?? "NULL"}',
                    'IsMining: ${_firestoreData!['isMining'] ?? "NULL"}',
                    'UpdatedAt: ${_firestoreData!['updatedAt'] ?? "NULL"}',
                    'DebugReferredBy: ${_firestoreData!['debugReferredBy'] ?? "NULL"}',
                  ]
                : ['Click "Load Firestore Data" to see current data'],
              Colors.green,
            ),
            
            const SizedBox(height: 20),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _loadFirestoreData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Load Firestore Data'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _debugReferredBy,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Debug ReferredBy'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Test Add Referral
            if (miningProvider.referredBy == null) ...[
              _buildSection(
                'Test Add Referral',
                ['User has no referredBy - can test adding one'],
                Colors.purple,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isLoading ? null : _testAddReferral,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Test Add Referral Code'),
              ),
            ] else ...[
              _buildSection(
                'Current ReferredBy Status',
                ['User already has referredBy: ${miningProvider.referredBy}'],
                Colors.green,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              item,
              style: const TextStyle(fontSize: 12),
            ),
          )),
        ],
      ),
    );
  }

  Future<void> _loadFirestoreData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user logged in')),
        );
        return;
      }
      
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (doc.exists) {
        setState(() {
          _firestoreData = doc.data();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Firestore data loaded')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User document not found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _debugReferredBy() async {
    setState(() => _isLoading = true);
    
    try {
      final miningProvider = Provider.of<MiningProvider>(context, listen: false);
      await miningProvider.debugReferredBy();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debug completed - check console')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testAddReferral() async {
    setState(() => _isLoading = true);
    
    try {
      final miningProvider = Provider.of<MiningProvider>(context, listen: false);
      
      // Test with a dummy referral code
      await miningProvider.addReferralCode('TEST123');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test referral code added')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

