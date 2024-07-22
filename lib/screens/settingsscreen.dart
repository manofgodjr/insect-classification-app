import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'English'; // Default language
  bool _isDarkMode = false; // Dark mode state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Dropdown to select language
            DropdownButton<String>(
              value: _selectedLanguage,
              items: const [
                DropdownMenuItem(
                  value: 'Eng',
                  child: Text('English'),
                ),
                DropdownMenuItem(
                  value: 'Yrb',
                  child: Text('Yoruba'),
                ),
                // Add more languages as needed
              ],
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
              },
            ),
            const SizedBox(height: 20),
            // Switch to toggle dark mode
            Switch(
              value: _isDarkMode,
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                  // Apply dark mode theme based on the state
                  final brightness = value ? Brightness.dark : Brightness.light;
                  final theme = ThemeData(brightness: brightness);
                  // Set the app's theme (context is available)
                });
              },
            ),
            const Text('Dark Mode'),
          ],
        ),
      ),
    );
  }
}
