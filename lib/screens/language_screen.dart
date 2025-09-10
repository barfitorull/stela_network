import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({Key? key}) : super(key: key);

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String selectedLanguage = 'English';

  final List<Map<String, String>> languages = [
    {'name': 'English', 'code': 'en', 'native': 'English'},
    {'name': 'Romanian', 'code': 'ro', 'native': 'Română'},
    {'name': 'Spanish', 'code': 'es', 'native': 'Español'},
    {'name': 'French', 'code': 'fr', 'native': 'Français'},
    {'name': 'German', 'code': 'de', 'native': 'Deutsch'},
    {'name': 'Italian', 'code': 'it', 'native': 'Italiano'},
    {'name': 'Portuguese', 'code': 'pt', 'native': 'Português'},
    {'name': 'Russian', 'code': 'ru', 'native': 'Русский'},
    {'name': 'Chinese', 'code': 'zh', 'native': '中文'},
    {'name': 'Japanese', 'code': 'ja', 'native': '日本語'},
    {'name': 'Korean', 'code': 'ko', 'native': '한국어'},
    {'name': 'Arabic', 'code': 'ar', 'native': 'العربية'},
    {'name': 'Hindi', 'code': 'hi', 'native': 'हिन्दी'},
    {'name': 'Turkish', 'code': 'tr', 'native': 'Türkçe'},
    {'name': 'Dutch', 'code': 'nl', 'native': 'Nederlands'},
    {'name': 'Polish', 'code': 'pl', 'native': 'Polski'},
    {'name': 'Swedish', 'code': 'sv', 'native': 'Svenska'},
    {'name': 'Norwegian', 'code': 'no', 'native': 'Norsk'},
    {'name': 'Danish', 'code': 'da', 'native': 'Dansk'},
    {'name': 'Finnish', 'code': 'fi', 'native': 'Suomi'},
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32, // Account for padding
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Language',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.language,
                                    color: Colors.orange,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Select Language',
                                        style: TextStyle(
                                          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Choose your preferred language',
                                        style: TextStyle(
                                          color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(
                              height: 400,
                              child: ListView.builder(
                                itemCount: languages.length,
                                itemBuilder: (context, index) {
                                  final language = languages[index];
                                  final isSelected = language['name'] == selectedLanguage;
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                        ? Colors.orange.withOpacity(0.2)
                                        : themeProvider.isDarkMode 
                                          ? const Color(0xFF3A3A3A) 
                                          : const Color(0xFFF5F5F5),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected 
                                          ? Colors.orange 
                                          : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      leading: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Text(
                                            language['code']!.toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.orange,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        language['name']!,
                                        style: TextStyle(
                                          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        language['native']!,
                                        style: TextStyle(
                                          color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      trailing: isSelected 
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: Colors.orange,
                                            size: 24,
                                          )
                                        : null,
                                      onTap: () {
                                        if (language['name'] == 'English') {
                                          setState(() {
                                            selectedLanguage = language['name']!;
                                          });
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Language changed to ${language['name']}',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } else {
                                                                              ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Coming Soon! Only English is available for now.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
} 