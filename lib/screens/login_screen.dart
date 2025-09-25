import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/mining_provider.dart';
import '../providers/theme_provider.dart';
import '../services/password_storage_service.dart';
import 'main_tabs.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginScreen extends StatefulWidget {
  final bool cameFromLogout;
  
  const LoginScreen({Key? key, this.cameFromLogout = false}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _referralCodeController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isRegistering = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  /// Generează un cod de referral unic
  String _generateReferralCode() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  /// Generează un username automat unic
  Future<String> _generateUniqueUsername() async {
    final random = Random();
    String username;
    bool isUnique = false;
    int attempts = 0;
    
    do {
      // Generează un număr între 1000 și 9999
      final number = random.nextInt(9000) + 1000;
      username = 'stelaminer$number';
      
      // Verifică dacă username-ul există deja
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();
      
      isUnique = querySnapshot.docs.isEmpty;
      attempts++;
      
      // Previne loop infinit
      if (attempts > 10) {
        username = 'stelaminer${DateTime.now().millisecondsSinceEpoch}';
        break;
      }
    } while (!isUnique);
    
    print('🔐 DEBUG: Generated username: $username');
    return username;
  }

  // Update live stats for total users
  Future<void> _updateLiveStatsTotalUsers() async {
    try {
      final statsRef = FirebaseFirestore.instance.collection('liveStats').doc('stats');
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final statsDoc = await transaction.get(statsRef);
        final currentUsers = statsDoc.exists ? (statsDoc.data()?['totalUsers'] ?? 0) : 0;
        final newUsers = currentUsers + 1;
        transaction.set(statsRef, {'totalUsers': newUsers}, SetOptions(merge: true));
        print('📊 Live stats updated: totalUsers = $newUsers');
      });
    } catch (e) {
      print('❌ Error updating live stats totalUsers: $e');
    }
  }

  /// Afișează dialog-ul pentru salvarea parolei
  Future<bool?> _showPasswordSaveDialog() async {
    print('🔐 DEBUG: _showPasswordSaveDialog called');
    print('🔐 DEBUG: Context mounted: ${mounted}');
    if (!mounted) {
      print('🔐 DEBUG: Context not mounted, returning null');
      return null;
    }
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        print('🔐 DEBUG: Building dialog...');
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        return AlertDialog(
          backgroundColor: themeProvider.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        title: Text(
          'Save password?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          'Would you like to save your password securely for future logins?\n\n'
          'Your password will be encrypted and stored locally on your device.',
          style: TextStyle(
            fontSize: 16,
            color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'No, thank you',
              style: TextStyle(
                fontSize: 16,
                color: themeProvider.isDarkMode ? Colors.grey : Colors.black54,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Yes, save',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    });
  }

  Future<void> _login() async {
    print('🔐 DEBUG: _login called');
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('🔐 DEBUG: Attempting Firebase login...');
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      print('🔐 DEBUG: Firebase login successful');

      // Check if password is saved for this email
      final email = _emailController.text.trim();
      print('🔐 DEBUG: Checking saved password for: $email');
      final savedPassword = await PasswordStorageService.getPassword(email);
      print('🔐 DEBUG: Saved password found: ${savedPassword != null}');
      
      // If password is not saved, ask user if they want to save it
      if (savedPassword == null && mounted) {
        print('🔐 DEBUG: No saved password, showing dialog...');
        final shouldSavePassword = await _showPasswordSaveDialog();
        print('🔐 DEBUG: User response: $shouldSavePassword');
        if (shouldSavePassword == true) {
          print('🔐 DEBUG: Saving password...');
          await PasswordStorageService.savePassword(
            email,
            _passwordController.text.trim(),
          );
          print('🔐 DEBUG: Password saved successfully');
        }
      } else {
        print('🔐 DEBUG: Password already saved or context not mounted');
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainTabs()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Login failed';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Încarcă parola salvată pentru email-ul introdus
  Future<void> _loadSavedPassword() async {
    print('🔐 DEBUG: _loadSavedPassword called');
    final email = _emailController.text.trim();
    print('🔐 DEBUG: Email: $email');
    if (email.isNotEmpty) {
      print('🔐 DEBUG: Looking for saved password...');
      final savedPassword = await PasswordStorageService.getPassword(email);
      print('🔐 DEBUG: Saved password found: ${savedPassword != null}');
      if (savedPassword != null && mounted) {
        print('🔐 DEBUG: Setting password field...');
        setState(() {
          _passwordController.text = savedPassword;
        });
        print('🔐 DEBUG: Password field set');
      }
    }
  }

  Future<void> _register() async {
    print('🚀 DEBUG: Starting registration process...');
    print('🚀 DEBUG: _register called');
    print('🚀 DEBUG: Email: ${_emailController.text.trim()}');
    print('🚀 DEBUG: Password length: ${_passwordController.text.length}');
    
    // Basic validation
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields';
      });
      return;
    }
    
    // Check password length
    if (_passwordController.text.trim().length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get referral code if provided (validation will be done in updateReferrals)
      String? referredBy = null;
      if (_referralCodeController.text.trim().isNotEmpty) {
        referredBy = _referralCodeController.text.trim().toUpperCase();
        print('🔍 DEBUG: Referral code provided: $referredBy');
      } else {
        print('No referral code provided');
      }

      // Create account only after validation
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Ask user if they want to save password IMMEDIATELY after account creation
      print('🔐 DEBUG: About to show password save dialog...');
      print('🔐 DEBUG: Context mounted: ${mounted}');
      
      if (mounted) {
        print('🔐 DEBUG: Context is mounted, showing dialog...');
        try {
          final shouldSavePassword = await _showPasswordSaveDialog();
          print('🔐 DEBUG: User response: $shouldSavePassword');
          if (shouldSavePassword == true) {
            print('🔐 DEBUG: Saving password...');
            await PasswordStorageService.savePassword(
              _emailController.text.trim(),
              _passwordController.text.trim(),
            );
            print('🔐 DEBUG: Password saved successfully');
          }
        } catch (e) {
          print('🔐 DEBUG: Error showing dialog: $e');
        }
      } else {
        print('🔐 DEBUG: Context not mounted, skipping dialog');
      }

      // Create user document in Firestore
      final user = userCredential.user;
      if (user != null) {
        print('Creating user document for UID: ${user?.uid}');
        
        // Generate a unique username
        final username = await _generateUniqueUsername();

        // CRITICAL FIX: For NEW users (registration), ALWAYS generate referral code
        // This is a NEW user registration, so we MUST generate a referral code
        final referralCode = _generateReferralCode();
        print('🔍 DEBUG: Generated referral code for NEW user during registration: $referralCode');

        // Create user document with default values
        final userData = {
          'balance': 0.0,
          'isMining': false,
          'miningRate': 0.20,
          'baseMiningRate': 0.20,
          'activeAdBoosts': 0,
          'activeReferrals': 0,
          'totalReferrals': 0,
          'totalMiningSessions': 0,
          'boostersRemaining': 10, // Start with max boosters
          'sessionStartTime': null,
          'lastMiningUpdate': null,
          'lastBoosterTime': null,
          'referralCode': referralCode, // Generated referral code
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'email': user.email,
          'username': username, // Add username to document
        };
        
        // CRITICAL FIX: For NEW user registration, set referredBy to null initially
        // This is a fresh registration, so referredBy will be set later if user provided referral code
        userData['referredBy'] = null; // New user starts with no referrer
        print('🔍 DEBUG: New user registration - setting referredBy to null initially');
        
        print('🔍 DEBUG: Creating new user document with referredBy: ${userData['referredBy']}');

        // CRITICAL FIX: For NEW user registration, always create new document
        // This is a fresh registration, so we create the document with the generated referral code
        await FirebaseFirestore.instance.collection('users').doc(user?.uid).set(userData);
        print('🔍 DEBUG: New user document created with referral code: $referralCode');
        
        // CRITICAL: Wait for Firebase to fully sync the document
        print('🔍 DEBUG: Waiting for Firebase document sync...');
        await Future.delayed(const Duration(milliseconds: 1500));
        
        // CRITICAL: Verify the document was saved correctly by reading from SERVER
        print('🔍 DEBUG: Verifying document from SERVER (bypassing cache)...');
        final verifyDoc = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get(const GetOptions(source: Source.server));
        if (verifyDoc.exists) {
          final savedReferralCode = verifyDoc.data()?['referralCode'];
          print('🔍 DEBUG: SERVER verification - saved referral code: $savedReferralCode');
          
          // CRITICAL: Double-check that the referral code matches what we saved
          if (savedReferralCode == referralCode) {
            print('✅ CRITICAL: Referral code confirmed on server!');
          } else {
            print('❌ CRITICAL: Referral code mismatch! Expected: $referralCode, Got: $savedReferralCode');
          }
        } else {
          print('⚠️ WARNING: Document not found on server after save!');
        }
        
        print('User document created and verified successfully');

        // CRITICAL FIX: If user was referred, process the referral bonus AFTER document creation
        if (referredBy != null) {
          try {
            print('Processing referral bonus for code: $referredBy');
            final functions = FirebaseFunctions.instance;
            final result = await functions.httpsCallable('updateReferrals').call({
              'referralCode': referredBy,
            });
            
            if (result.data['success'] == true) {
              print('Referral bonus processed successfully');
              print('Bonus applied: ${result.data['bonusApplied']} STC');
              print('New balance: ${result.data['newBalance']} STC');
              
              // CRITICAL: Update the user document with the new balance and referredBy immediately
              await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
                'balance': result.data['newBalance'],
                'referredBy': referredBy, // CRITICAL: Set referredBy field
                'updatedAt': FieldValue.serverTimestamp(),
              });
              print('User balance updated in Firestore: ${result.data['newBalance']} STC');
              print('User referredBy updated in Firestore: $referredBy');
              
              // CRITICAL: Wait a moment for Firestore to sync
              await Future.delayed(const Duration(milliseconds: 500));
              print('Waited for Firestore sync');
            } else {
              print('Referral processing failed: ${result.data['message']}');
            }
          } catch (e) {
            print('Error processing referral: $e');
            // Don't fail registration if referral processing fails
          }
        }

        // Save FCM token for push notifications
        try {
          final messaging = FirebaseMessaging.instance;
          String? token = await messaging.getToken();
          if (token != null) {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
              'fcmToken': token,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            print('FCM token saved for new user');
          }
        } catch (e) {
          print('Error saving FCM token: $e');
          // Don't fail registration if FCM token saving fails
        }
        
        // Update live stats - increment total users
        await _updateLiveStatsTotalUsers();
        
        print('✅ DEBUG: User document created successfully');
      }



              // CRITICAL FIX: Force MiningProvider initialization and referral bonus check before navigation
        if (mounted && user != null) {
          print('🔐 DEBUG: Forcing MiningProvider initialization...');
          final miningProvider = Provider.of<MiningProvider>(context, listen: false);
          
          // CRITICAL: Set referredBy in MiningProvider before initialization
          if (referredBy != null) {
            print('🔐 DEBUG: Setting referredBy in MiningProvider: $referredBy');
            // We need to ensure MiningProvider knows about referredBy
            // This will be loaded from Firestore during initialization
          }
          
          await miningProvider.initialize(user.uid);
          print('🔐 DEBUG: MiningProvider initialized successfully');
          
          // CRITICAL: Force refresh to ensure UI is updated with referral code and referredBy
          print('🔐 DEBUG: Force refreshing user data from server...');
          await miningProvider.forceRefreshUserData();
          print('🔐 DEBUG: Force refresh completed');
          
          // CRITICAL: Force another refresh to ensure referral code is loaded
          print('🔐 DEBUG: Second refresh to ensure referral code...');
          await Future.delayed(const Duration(milliseconds: 500));
          await miningProvider.forceRefreshUserData();
          print('🔐 DEBUG: Second refresh completed');
          
          // CRITICAL: Third refresh with additional delay to ensure complete sync
          print('🔐 DEBUG: Third refresh with extended delay...');
          await Future.delayed(const Duration(milliseconds: 1000));
          await miningProvider.forceRefreshUserData();
          print('🔐 DEBUG: Third refresh completed');
          
          // CRITICAL: Verify referral code is loaded in MiningProvider
          print('🔐 DEBUG: MiningProvider referral code after refresh: ${miningProvider.referralCode}');
          print('🔐 DEBUG: MiningProvider referredBy after refresh: ${miningProvider.referredBy}');
          
          print('🔐 DEBUG: Navigating to MainTabs...');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainTabs()),
          );
        } else {
          print('🔐 DEBUG: Context not mounted or user is null for navigation');
        }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message ?? 'Registration failed';
        });
      }
    } catch (e) {
      print('Registration error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Registration failed: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Afișează dialog pentru resetarea parolei
  Future<void> _showForgotPasswordDialog() async {
    final TextEditingController emailController = TextEditingController();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: themeProvider.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          title: Text(
            'Reset Password',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your email address and we\'ll send you a password reset link.',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: themeProvider.isDarkMode ? Colors.grey : Colors.black54,
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF4A90E2)),
                  ),
                ),
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter your email address'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Password reset email sent to $email',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                } on FirebaseAuthException catch (e) {
                  String message = 'Failed to send reset email';
                  if (e.code == 'user-not-found') {
                    message = 'No account found with this email';
                  } else if (e.code == 'invalid-email') {
                    message = 'Invalid email address';
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                foregroundColor: Colors.white,
              ),
              child: const Text('Send Reset Email'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2D1B69), // Dark purple
              Color(0xFF1A1A1A), // Dark gray
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 100,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'assets/logo_contur.png',
                    width: 110,
                    height: 110,
                    color: Colors.white,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                  const SizedBox(height: 16),
                  // Welcome text
                  const Text(
                    'Welcome to',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Stela Network',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '|STELLAR CRYPTO MINING|',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 48),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF4A90E2)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) {
                      // Load saved password when email changes
                      _loadSavedPassword();
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: const OutlineInputBorder(),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF4A90E2)),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    obscureText: _obscurePassword,
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () {
                            print('🔘 DEBUG: Login button pressed');
                            _login();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A90E2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Login'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () {
                            print('🔘 DEBUG: Register button pressed');
                            _register();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Register'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Forgot Password Link
                  TextButton(
                    onPressed: _isLoading ? null : _showForgotPasswordDialog,
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}