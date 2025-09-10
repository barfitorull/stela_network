import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.dark;
  String? _currentUserId;
  
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;

  ThemeProvider() {
    _loadThemeMode();
    _listenToAuthChanges();
  }

  // Listen to Firebase Auth changes to update current user
  void _listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _currentUserId = user.uid;
        _loadThemeMode(); // Load theme for new user
      } else {
        _currentUserId = null;
        _themeMode = ThemeMode.dark; // Reset to dark for logged out state
        notifyListeners();
      }
    });
  }

  // Dark theme colors
  static const Color darkPrimary = Color(0xFF2D1B69);
  static const Color darkSecondary = Color(0xFF1A1A1A);
  static const Color darkSurface = Color(0xFF2A2A2A);
  static const Color darkText = Colors.white;
  static const Color darkTextSecondary = Colors.white70;

  // Light theme colors
  static const Color lightPrimary = Color(0xFF4A90E2);
  static const Color lightSecondary = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF666666);

  // Get theme data based on mode
  ThemeData getThemeData(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return _getDarkTheme();
      case ThemeMode.light:
        return _getLightTheme();
      default:
        return _getDarkTheme();
    }
  }

  ThemeData _getDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.purple,
      scaffoldBackgroundColor: darkPrimary,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkPrimary,
        foregroundColor: darkText,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: darkText),
        headlineMedium: TextStyle(color: darkText),
        headlineSmall: TextStyle(color: darkText),
        bodyLarge: TextStyle(color: darkText),
        bodyMedium: TextStyle(color: darkTextSecondary),
        bodySmall: TextStyle(color: darkTextSecondary),
      ),
      iconTheme: const IconThemeData(color: darkText),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: Color(0xFF4A90E2),
        unselectedItemColor: Colors.grey,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.green;
          }
          return Colors.grey;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.green.withOpacity(0.3);
          }
          return Colors.grey.withOpacity(0.3);
        }),
      ),
    );
  }

  ThemeData _getLightTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.purple,
      scaffoldBackgroundColor: const Color(0xFF2D1B69),
      appBarTheme: const AppBarTheme(
        backgroundColor: const Color(0xFF2A2A2A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF2A2A2A),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Colors.white),
        headlineMedium: TextStyle(color: Colors.white),
        headlineSmall: TextStyle(color: Colors.white),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        bodySmall: TextStyle(color: Colors.white70),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF2A2A2A),
        selectedItemColor: Color(0xFF4A90E2),
        unselectedItemColor: Colors.grey,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.green;
          }
          return Colors.grey;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.green.withOpacity(0.3);
          }
          return Colors.grey.withOpacity(0.3);
        }),
      ),
    );
  }

  // Toggle theme mode
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _saveThemeMode();
    notifyListeners();
  }
  
  // Set specific theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _saveThemeMode();
    notifyListeners();
  }

  // Load theme mode from shared preferences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeKey = _themeKey;
      
      // If user is logged in, use user-specific key
      if (_currentUserId != null) {
        themeKey = '${_themeKey}_${_currentUserId}';
      }
      
      final themeString = prefs.getString(themeKey);
      if (themeString != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == themeString,
          orElse: () => ThemeMode.dark,
        );
        notifyListeners();
      } else {
        // Default to dark mode for new users
        _themeMode = ThemeMode.dark;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading theme mode: $e');
      // Default to dark mode on error
      _themeMode = ThemeMode.dark;
      notifyListeners();
    }
  }

  // Save theme mode to shared preferences
  Future<void> _saveThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeKey = _themeKey;
      
      // If user is logged in, use user-specific key
      if (_currentUserId != null) {
        themeKey = '${_themeKey}_${_currentUserId}';
      }
      
      await prefs.setString(themeKey, _themeMode.toString());
    } catch (e) {
      print('Error saving theme mode: $e');
    }
  }
} 