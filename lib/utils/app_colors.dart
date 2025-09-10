import 'package:flutter/material.dart';

class AppColors {
  static bool _isDarkMode = true;
  
  static void setDarkMode(bool isDark) {
    _isDarkMode = isDark;
  }
  
  static Color get cardColor => _isDarkMode 
      ? const Color(0xFF2A2A2A) 
      : const Color(0xFFE0E0E0);
  
  static Color get textColor => _isDarkMode 
      ? Colors.white 
      : Colors.black;
  
  static Color get textSecondaryColor => _isDarkMode 
      ? Colors.white70 
      : Colors.grey;
  
  static Color get iconColor => _isDarkMode 
      ? Colors.white 
      : Colors.black;
} 