import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../screens/login_screen.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Menu',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAccountCard(
                          'Change Password',
                          'Update your account password',
                          Icons.lock,
                          Colors.blue,
                          () => _showChangePasswordDialog(context),
                        ),
                        const SizedBox(height: 16),
                        _buildAccountCard(
                          'Your Info',
                          'Update your personal information',
                          Icons.person,
                          Colors.orange,
                          () => _showYourInfoDialog(context),
                        ),
                        const SizedBox(height: 16),
                        _buildAccountCard(
                          'Phone Number',
                          'Update your phone number',
                          Icons.phone,
                          Colors.green,
                          () => _showPhoneNumberDialog(context),
                        ),
                        const SizedBox(height: 16),
                        _buildAccountCard(
                          'Delete Account',
                          'Permanently delete your account',
                          Icons.delete_forever,
                          Colors.red,
                          () => _showDeleteAccountDialog(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: themeProvider.isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
          title: Text(
            'Change Password',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  labelStyle: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: themeProvider.isDarkMode ? Colors.white30 : Colors.grey,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: themeProvider.isDarkMode ? Colors.white30 : Colors.grey,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  labelStyle: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: themeProvider.isDarkMode ? Colors.white30 : Colors.grey,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    // Re-authenticate user
                    final credential = EmailAuthProvider.credential(
                      email: user.email!,
                      password: currentPasswordController.text,
                    );
                    await user.reauthenticateWithCredential(credential);
                    
                    // Update password
                    await user.updatePassword(newPasswordController.text);
                    
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Password updated successfully!',
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error: ${e.toString()}',
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
              },
              child: const Text('Update Password'),
            ),
          ],
        );
      },
    );
  }

  void _showYourInfoDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    final cityController = TextEditingController();
    final countryController = TextEditingController();
    final postalCodeController = TextEditingController();
    final dateOfBirthController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: themeProvider.isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
          title: Text(
            'Your Information',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: firstNameController,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    labelStyle: TextStyle(
                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: themeProvider.isDarkMode ? Colors.white30 : Colors.grey,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    labelStyle: TextStyle(
                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: themeProvider.isDarkMode ? Colors.white30 : Colors.grey,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Email',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    labelStyle: TextStyle(
                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                    ),
                    hintStyle: TextStyle(
                      color: themeProvider.isDarkMode ? Colors.white30 : Colors.grey,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: themeProvider.isDarkMode ? Colors.white30 : Colors.grey,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    labelStyle: TextStyle(
                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: themeProvider.isDarkMode ? Colors.white30 : Colors.grey,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: cityController,
                        decoration: InputDecoration(
                          labelText: 'City',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          labelStyle: TextStyle(
                            color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: themeProvider.isDarkMode ? Colors.white30 : Colors.grey,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        style: TextStyle(
                          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: postalCodeController,
                        decoration: InputDecoration(
                          labelText: 'Postal Code',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          labelStyle: TextStyle(
                            color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: themeProvider.isDarkMode ? Colors.white30 : Colors.grey,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        style: TextStyle(
                          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: countryController,
                  decoration: InputDecoration(
                    labelText: 'Country',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    labelStyle: TextStyle(
                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: themeProvider.isDarkMode ? Colors.white30 : Colors.grey,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dateOfBirthController,
                  keyboardType: TextInputType.datetime,
                  decoration: InputDecoration(
                    labelText: 'Date of Birth (DD/MM/YYYY)',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    labelStyle: TextStyle(
                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: themeProvider.isDarkMode ? Colors.white30 : Colors.grey,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (firstNameController.text.trim().isEmpty || lastNameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please fill in your first and last name!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode ? Colors.black : Colors.white,
                        ),
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  return;
                }
                
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    // Update display name
                    await user.updateDisplayName('${firstNameController.text.trim()} ${lastNameController.text.trim()}');
                    
                    // Update email if changed
                    if (emailController.text.trim() != user.email) {
                      await user.updateEmail(emailController.text.trim());
                    }
                    
                    // Store user data in Firestore
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                      'firstName': firstNameController.text.trim(),
                      'lastName': lastNameController.text.trim(),
                      'email': emailController.text.trim(),
                      'address': addressController.text.trim(),
                      'city': cityController.text.trim(),
                      'country': countryController.text.trim(),
                      'postalCode': postalCodeController.text.trim(),
                      'dateOfBirth': dateOfBirthController.text.trim(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));
                    
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Personal information updated successfully!',
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error: ${e.toString()}',
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
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update Info'),
            ),
          ],
        );
      },
    );
  }

  void _showPhoneNumberDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final phoneController = TextEditingController();
    
    // Country codes with flags and formats - ALPHABETICAL ORDER
    final List<Map<String, String>> countries = [
      {'code': 'AE', 'flag': '🇦🇪', 'dialCode': '+971', 'format': '5X XXX XXXX'},
      {'code': 'AR', 'flag': '🇦🇷', 'dialCode': '+54', 'format': '9XX XXX XXXX'},
      {'code': 'AT', 'flag': '🇦🇹', 'dialCode': '+43', 'format': '6XX XXX XXX'},
      {'code': 'AU', 'flag': '🇦🇺', 'dialCode': '+61', 'format': '04XX XXX XXX'},
      {'code': 'BD', 'flag': '🇧🇩', 'dialCode': '+880', 'format': '1XXX-XXXXXX'},
      {'code': 'BE', 'flag': '🇧🇪', 'dialCode': '+32', 'format': '4XX XXX XXX'},
      {'code': 'BG', 'flag': '🇧🇬', 'dialCode': '+359', 'format': '8XX XXX XXX'},
      {'code': 'BR', 'flag': '🇧🇷', 'dialCode': '+55', 'format': '(11) 9XXXX-XXXX'},
      {'code': 'CA', 'flag': '🇨🇦', 'dialCode': '+1', 'format': '(XXX) XXX-XXXX'},
      {'code': 'CH', 'flag': '🇨🇭', 'dialCode': '+41', 'format': '7X XXX XXXX'},
      {'code': 'CL', 'flag': '🇨🇱', 'dialCode': '+56', 'format': '9XXXX XXXX'},
      {'code': 'CN', 'flag': '🇨🇳', 'dialCode': '+86', 'format': '1XX XXXX XXXX'},
      {'code': 'CO', 'flag': '🇨🇴', 'dialCode': '+57', 'format': '3XX XXX XXXX'},
      {'code': 'CZ', 'flag': '🇨🇿', 'dialCode': '+420', 'format': '6XX XXX XXX'},
      {'code': 'DE', 'flag': '🇩🇪', 'dialCode': '+49', 'format': '01XX XXXXXXX'},
      {'code': 'DK', 'flag': '🇩🇰', 'dialCode': '+45', 'format': 'XX XX XX XX'},
      {'code': 'EG', 'flag': '🇪🇬', 'dialCode': '+20', 'format': '1XX XXX XXXX'},
      {'code': 'ES', 'flag': '🇪🇸', 'dialCode': '+34', 'format': '6XX XXX XXX'},
      {'code': 'FI', 'flag': '🇫🇮', 'dialCode': '+358', 'format': '4X XXX XXXX'},
      {'code': 'FR', 'flag': '🇫🇷', 'dialCode': '+33', 'format': '0X XX XX XX XX'},
      {'code': 'GB', 'flag': '🇬🇧', 'dialCode': '+44', 'format': '07XXX XXXXXX'},
      {'code': 'GR', 'flag': '🇬🇷', 'dialCode': '+30', 'format': '6XX XXX XXXX'},
      {'code': 'HR', 'flag': '🇭🇷', 'dialCode': '+385', 'format': '9X XXX XXX'},
      {'code': 'HU', 'flag': '🇭🇺', 'dialCode': '+36', 'format': '20 XXX XXXX'},
      {'code': 'ID', 'flag': '🇮🇩', 'dialCode': '+62', 'format': '8XX XXX XXX'},
      {'code': 'IE', 'flag': '🇮🇪', 'dialCode': '+353', 'format': '8X XXX XXXX'},
      {'code': 'IL', 'flag': '🇮🇱', 'dialCode': '+972', 'format': '5X XXX XXXX'},
      {'code': 'IN', 'flag': '🇮🇳', 'dialCode': '+91', 'format': '9XXXX XXXXX'},
      {'code': 'IT', 'flag': '🇮🇹', 'dialCode': '+39', 'format': '3XX XXX XXXX'},
      {'code': 'JP', 'flag': '🇯🇵', 'dialCode': '+81', 'format': '90-XXXX-XXXX'},
      {'code': 'KR', 'flag': '🇰🇷', 'dialCode': '+82', 'format': '10-XXXX-XXXX'},
      {'code': 'MX', 'flag': '🇲🇽', 'dialCode': '+52', 'format': '55 XXXX XXXX'},
      {'code': 'MY', 'flag': '🇲🇾', 'dialCode': '+60', 'format': '1X-XXX XXXX'},
      {'code': 'NL', 'flag': '🇳🇱', 'dialCode': '+31', 'format': '06 XXXXXXXX'},
      {'code': 'NO', 'flag': '🇳🇴', 'dialCode': '+47', 'format': 'XXX XX XXX'},
      {'code': 'NZ', 'flag': '🇳🇿', 'dialCode': '+64', 'format': '2X XXX XXXX'},
      {'code': 'PE', 'flag': '🇵🇪', 'dialCode': '+51', 'format': '9XX XXX XXX'},
      {'code': 'PH', 'flag': '🇵🇭', 'dialCode': '+63', 'format': '9XX XXX XXXX'},
      {'code': 'PL', 'flag': '🇵🇱', 'dialCode': '+48', 'format': 'XXX XXX XXX'},
      {'code': 'PT', 'flag': '🇵🇹', 'dialCode': '+351', 'format': '9XX XXX XXX'},
      {'code': 'RO', 'flag': '🇷🇴', 'dialCode': '+40', 'format': '07XX XXX XXX'},
      {'code': 'RU', 'flag': '🇷🇺', 'dialCode': '+7', 'format': '9XX XXX XX XX'},
      {'code': 'SA', 'flag': '🇸🇦', 'dialCode': '+966', 'format': '5X XXX XXXX'},
      {'code': 'SE', 'flag': '🇸🇪', 'dialCode': '+46', 'format': '7X XXX XXXX'},
      {'code': 'SG', 'flag': '🇸🇬', 'dialCode': '+65', 'format': '9XXX XXXX'},
      {'code': 'SK', 'flag': '🇸🇰', 'dialCode': '+421', 'format': '9XX XXX XXX'},
      {'code': 'TH', 'flag': '🇹🇭', 'dialCode': '+66', 'format': '8X XXX XXXX'},
      {'code': 'TR', 'flag': '🇹🇷', 'dialCode': '+90', 'format': '5XX XXX XXXX'},
      {'code': 'UA', 'flag': '🇺🇦', 'dialCode': '+380', 'format': 'XX XXX XXXX'},
      {'code': 'US', 'flag': '🇺🇸', 'dialCode': '+1', 'format': '(XXX) XXX-XXXX'},
      {'code': 'VN', 'flag': '🇻🇳', 'dialCode': '+84', 'format': '9X XXX XXXX'},
      {'code': 'ZA', 'flag': '🇿🇦', 'dialCode': '+27', 'format': '7X XXX XXXX'},
    ];
    
    String selectedCountry = 'US';
    String selectedDialCode = '+1';
    String selectedFormat = '(XXX) XXX-XXXX';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: themeProvider.isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
          title: Text(
            'Update Phone Number',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Country Code Dropdown
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: themeProvider.isDarkMode ? Colors.white30 : Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCountry,
                        isExpanded: true,
                        dropdownColor: themeProvider.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                        ),
                        style: TextStyle(
                          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                        ),
                        items: countries.map((country) {
                          return DropdownMenuItem<String>(
                            value: country['code'],
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                children: [
                                  Text(country['flag']!),
                                  const SizedBox(width: 8),
                                  Text('${country['code']} (${country['dialCode']})'),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedCountry = value;
                              final country = countries.firstWhere((c) => c['code'] == value);
                              selectedDialCode = country['dialCode']!;
                              selectedFormat = country['format']!;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Phone Number Field
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: selectedFormat,
                      labelStyle: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                      ),
                      hintStyle: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.white30 : Colors.grey,
                        fontSize: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: themeProvider.isDarkMode ? Colors.white30 : Colors.grey,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    style: TextStyle(
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (phoneController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please enter a phone number!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode ? Colors.black : Colors.white,
                        ),
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  return;
                }
                
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Phone number format: $selectedDialCode ${phoneController.text.trim()}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode ? Colors.black : Colors.white,
                          ),
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error: ${e.toString()}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode ? Colors.black : Colors.white,
                        ),
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: themeProvider.isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
          title: Text(
            'Delete Account',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This action cannot be undone. All your data will be permanently deleted.',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Enter your password to confirm',
                  labelStyle: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: themeProvider.isDarkMode ? Colors.white30 : Colors.grey,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    // Re-authenticate user
                    final credential = EmailAuthProvider.credential(
                      email: user.email!,
                      password: passwordController.text,
                    );
                    await user.reauthenticateWithCredential(credential);
                    
                    // Delete account
                    await user.delete();
                    
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Account deleted successfully!',
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error: ${e.toString()}',
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
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete Account'),
            ),
          ],
        );
      },
    );
  }
}
